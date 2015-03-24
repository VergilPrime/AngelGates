@time = time()

_load('AR.AngelGates.Networks')

export('AR.AngelGates.ActiveGates',associative_array())

@networks = import('AR.AngelGates.Networks')
export('AR.AngelGates.Blocks',array())
export('AR.AngelGates.Signs',array())
export('AR.AngelGates.Buttons',array())
export('AR.AngelGates.Schematics',associative_array())

foreach(yml_decode(read('./SchemList.yml'))['GateSchematics'],@filename){
	if(reg_count('.yml',@filename)){
		import('AR.AngelGates.Schematics')[replace(@filename,'.yml','')] = yml_decode(read('../GateSchematics/'.@filename))
	}
}



###Gate Creation###

bind(sign_changed,null,null,@e){
	if(@e['text'][0] != '[AG]', die())
	if(@e['text'][1] == '', die(color(c).'No network specified on line 2.'))
	if(reg_count(' ',@e['text'][1]),die(color(c).'There can be no spaces in network names'))
	if(@e['text'][2] == '', die(color(c).'No gate name specified on line 2.'))
	if(reg_count(' ',@e['text'][2]),die(color(c).'There can be no spaces in gate names'))
	if(split(':',get_block_at(@e['location']))[0] == 68){#if it's on a wall
		@schematics = import('AR.AngelGates.Schematics')
		x_new_thread('AngelGates.'.@e['player'],closure(
			foreach(@schematics,@schemname,@schematic){
				@height = array_size(@schematic['shape'])
				@width = array_size(@schematic['shape'][0])
				switch(split(':',get_block_at(@e['location']))[1],
					2,
						@signblock = _loc_mod(@e['location'],'z',1)
						@rightdirection = '-x',
					3,
						@signblock = _loc_mod(@e['location'],'-z',1)
						@rightdirection = '+x',
					4,
						@signblock = _loc_mod(@e['location'],'x',1)
						@rightdirection = '+z',
					5,
						@signblock = _loc_mod(@e['location'],'-x',1)
						@rightdirection = '-z',
				)
				foreach(@schematic['shape'],@yindex,@row){
					foreach(@row,@xindex,@character){
						if(@character == '-'){
							@signdepth = @yindex
							break(2)
						}
					}
				}
				@topleftblock = _loc_mod(@signblock,'y',@signdepth)
				@fail = false
				foreach(cslice(0,@height - 1),@yfromtop){
					foreach(cslice(0,@width - 1),@xfromleft){
						if(@schematic['shape'][@yfromtop][@xfromleft] == 'x'){
							continue()
						}else{
							@expected = @schematic['materials'][@schematic['shape'][@yfromtop][@xfromleft]]
							@realblock = split(':',get_block_at(_loc_mod(_loc_mod(@topleftblock,@rightdirection,@xfromleft),'-y',@yfromtop)))[0]
							if(@realblock != @expected){
								@fail = true
								break()
							}
						}
					}
				}
				if(!@fail){
					_create_gate(strip_colors(@e['text'][2]),strip_colors(@e['text'][1]),@topleftblock,@schematic,@schemname,@rightdirection)
					break()
				}else{
					@fail = false
					@topleftblock = _loc_mod(_loc_mod(@signblock,'y',@signdepth),@rightdirection,(@width - 1) * -1)
					foreach(cslice(0,@height - 1),@yfromtop){
						foreach(cslice(0,@width - 1),@xfromleft){
							if(@schematic['shape'][@yfromtop][@xfromleft] == 'x'){
								continue()
							}else{
								@expected = @schematic['materials'][@schematic['shape'][@yfromtop][@xfromleft]]
								@realblock = split(':',get_block_at(_loc_mod(_loc_mod(@topleftblock,@rightdirection,@xfromleft),'-y',@yfromtop)))[0]
								if(@realblock != @expected){
									@fail = true
									break()
								}
							}
						}
					}
					if(!@fail){
						_create_gate(strip_colors(@e['text'][2]),strip_colors(@e['text'][1]),@topleftblock,@schematic,@schemname,@rightdirection)
						break()
					}
					@fail = false
				}
			}
		))
	}
}

bind(block_break,null,null,@e){
	@location = _loc_normalize(@e['location'])
	@networks = import('AR.AngelGates.Networks')
	foreach(@networks,@netname,@network){
		foreach(@network['gates'],@gatename,@gate){
			if(_loc_normalize(@gate['sign']) == @location){
				cancel()
				die()
			}
			if(_loc_normalize(@gate['button']) == @location){
				cancel()
				die()
			}
			if(array_contains(@gate['blocks'],@location)){
				cancel()
				die()
			}
		}
	}
}

bind(block_burn,null,null,@e){

}

bind(entity_explode,null,null,@e){
	
}

bind(piston_extend,null,null,@e){

}

bind(piston_retract,null,null,@e){

}
###

bind(player_interact,null,null,@e){
	if(!array_index_exists(@e,'location'),die())
	@location = _loc_normalize(@e['location'])
	@networks = import('AR.AngelGates.Networks')
	foreach(@networks,@netname,@network){
		foreach(@network['gates'],@gatename,@gate){
			if(_loc_normalize(@gate['sign']) == @location){
				if(!_player_can_open(@netname,player())){
					die()
				}
				if(is_null(import('AR.'.@gatename.'.Gatelist'))){
					export('AR.'.@gatename.'.Gatelist',array())
					@gatelist = import('AR.'.@gatename.'.Gatelist')
					foreach(@networks[@netname]['gates'],@gatename2,@gate){
						if(@gatename != @gatename2){
							array_push(@gatelist,@gatename2)
						}
					}
					if(array_size(@gatelist) < 1, die())
					array_sort(@gatelist, 'REGULAR')
					switch(@networks[@netname]['type'],
						'private',
							@color = color(6),
						'admin',
							@color = color(2),
						'special',
							@color = color(3),
						'town',
							@color = color('r')
					)
					@signtext = array(@color.@netname)
					if(array_size(@gatelist) >= 3){
						@signtext[1] = @gatelist[array_size(@gatelist) - 1]
						@signtext[2] = color('l').@gatelist[0]
						@signtext[3] = @gatelist[1]
					}
					if(array_size(@gatelist) == 2){
						@signtext[1] = @gatelist[1]
						@signtext[2] = color('l').@gatelist[0]
						@signtext[3] = @gatelist[1]
					}
					if(array_size(@gatelist) == 1){
						@signtext[1] = ''
						@signtext[2] = color('l').@gatelist[0]
						@signtext[3] = ''
					}
					set_sign_text(@location,@signtext)
					if(array_size(@gatelist) == 0){
						die()
					}
					set_sign_text(@location,@signtext)
				}else{
					@signtext = get_sign_text(@location)
					@gatelist = import('AR.'.@gatename.'.Gatelist')
					if(@e['button'] == 'right'){
					 if(array_size(@gatelist) == 0,die())
						@topgate = @gatelist[0]
						array_push(@gatelist, @topgate)
						array_remove(@gatelist,0)
						if(array_size(@gatelist) >= 3){
							@signtext[1] = @gatelist[array_size(@gatelist) - 1]
							@signtext[2] = color('l').@gatelist[0]
							@signtext[3] = @gatelist[2]
						}
						if(array_size(@gatelist) == 2){
							@signtext[1] = @gatelist[1]
							@signtext[2] = color('l').@gatelist[0]
							@signtext[3] = @gatelist[1]
						}
						if(array_size(@gatelist) == 1){
							die()
						}
						set_sign_text(@location,@signtext)
					}else{
						@bottomgate = @gatelist[array_size(@gatelist) - 1]
						array_remove(@gatelist,array_size(@gatelist) - 1)
						array_insert(@gatelist, @bottomgate, 0)
						if(array_size(@gatelist) >= 3){
							@signtext[1] = @gatelist[array_size(@gatelist) - 1]
							@signtext[2] = color('l').@gatelist[0]
							@signtext[3] = @gatelist[2]
						}
						if(array_size(@gatelist) == 2){
							@signtext[1] = @gatelist[1]
							@signtext[2] = color('l').@gatelist[0]
							@signtext[3] = @gatelist[1]
						}
						if(array_size(@gatelist) == 1){
							die()
						}
						set_sign_text(@location,@signtext)
					}
				}
			}
			if(_loc_normalize(@gate['button']) == @location){
				if(!_player_can_open(@netname,player())){
					die()
				}
				if(is_null(import('AR.'.@gatename.'.Gatelist'))){
					msg('Select a destination gate using the sign first.')
				}else if(array_size(import('AR.'.@gatename.'.Gatelist')) == 0){
					die()
				}else{
					@destination = import('AR.'.@gatename.'.Gatelist')[0]
					export('AR.'.@gatename.'.Gatelist',null)
					_open_gate(@gatename,@netname,@destination,player())
				}
			}
		}
	}
}

_vergil_out('AngelGates main.ms loaded '.(time() - @time).'ms')
