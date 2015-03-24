proc(_player_can_open,@network,@player){
	@uuid = pinfo(player(),20)
	@networks = import('AR.AngelGates.Networks')
	@members = @networks[@network]['members']
	if(has_permission(@player,'AngelGates.Admin') || has_permission(@player,'AngelGates.Override'),return(true))
	switch(@networks[@network]['type'],
		'private',
			if(@networks[@network]['owner'] == @uuid){
				return(true)
			}else{
				return(false)
			},
		'admin',
			if(@networks[@network]['owner'] == @uuid){
				return(true)
			}
			if(array_contains(@members,@player)){
				return(true)
			}
			if(array_contains(@members,@player)){
				return(true)
			}
			if(array_contains_ic(@members,'everyone')){
				return(true)
			}else{
				return(false)
			},
		'special',
			if(@networks[@network]['owner'] == @uuid){
				return(true)
			}
			if(array_contains(@members,@player)){
				return(true)
			}
			if(array_contains_ic(@members,'everyone')){
				return(true)
			}else{
				return(false)
			},
		'town',
			if(@networks[@network]['owner'] == @uuid){
				return(true)
			}
	)
}

proc(_sign_rest,@gatename,@network){
	@networks = import('AR.AngelGates.Networks')
	@gate = @networks[@network]['gates'][@gatename]
	@nettype = @networks[@network]['type']
	switch(@nettype,
		'private',
			@nettype = color(6).'Private Network',
		'admin',
			@nettype = color(2).'Staff Network',
		'special',
			@nettype = color(3).'Special Network',
		'town',
			@nettype = 'Town Network'
	)
	foreach(@gate['schematic']['shape'],@yindex,@row){
		foreach(@gate['schematic']['shape'][@yindex],@xindex,@character){
			if(@character == '-'){
				switch(@gate['rightdirection'],
					'+x',
					@frontface = '+z',
					'+z',
					@frontface = '-x',
					'-x',
					@frontface = '-z',
					'-z',
					@frontface = '+x'
				)
				@targetblock = _loc_mod(_loc_mod(_loc_mod(@gate['topleftblock'],@gate['rightdirection'],@xindex),'-y',@yindex),@frontface,1)
				if(split(':',get_block_at(@targetblock))[0] == '68'){
					@networks[@network]['gates'][@gatename]['sign'] = @targetblock
					x_run_on_main_thread_later(closure(set_sign_text(@targetblock,array(
						@nettype,
						@network,
						@gatename,
						color('l').'~x~'
					))))
				}
			}
		}
	}
}

proc(_add_button,@gatename,@network){
	@networks = import('AR.AngelGates.Networks')
	@gate = @networks[@network]['gates'][@gatename]
	if(array_index_exists(@gate,'button')){
		x_run_on_main_thread_later(closure(set_block_at(@gate['button'],'143:'.@buttonface)))
	}else{
		foreach(@gate['schematic']['shape'],@yindex,@row){
			foreach(@row,@xindex,@character){
				if(@character == '-'){
					@block = _loc_mod(_loc_mod(@gate['topleftblock'],@gate['rightdirection'],@xindex),'-y',@yindex)
					switch(@gate['rightdirection'],
						'+x',
						@frontface = '+z'
						@buttonface = '3',
						'+z',
						@frontface = '-x'
						@buttonface = '2',
						'-x',
						@frontface = '-z'
						@buttonface = '4',
						'-z',
						@frontface = '+x'
						@buttonface = '1'
					)
					@block = _loc_mod(@block,@frontface,1)
					@networks[@network]['gates'][@gatename]['button'] = @block
					if(split(':',get_block_at(@block))[0] == 0){
						x_run_on_main_thread_later(closure(set_block_at(@block,'143:'.@buttonface)))
					}
				}
			}
		}
	}
}

proc(_open_gate,@gatename,@network,@destination,@opener){
	if(array_index_exists(import('AR.AngelGates.ActiveGates'),@network.'.'.@gatename)){
		die()
	}
	import('AR.AngelGates.ActiveGates')[@network.'.'.@gatename] = associative_array(
		'destination':@destination,
		'closing_at':time() + 15000,
		'just_arrived':array(),
		'opened_by': @opener
	)
	@gate = import('AR.AngelGates.Networks')[@network]['gates'][@gatename]
	set_interval('200','0',closure(
		if(!array_index_exists(import('AR.AngelGates.ActiveGates'),@network.'.'.@gatename)){
			clear_task()
			die()
		}
		foreach(@gate['schematic']['shape'],@yindex,@row){
			foreach(@row,@xindex,@character){
				if(@character == '+'){
					@block = _loc_mod(_loc_mod(@gate['topleftblock'],@gate['rightdirection'],@xindex),'-y',@yindex)
					@blockcenter = _loc_center(@block)
					switch(@gate['schematic']['type'],
						'drip',
							@dripcenter = @blockcenter[]
							@dripcenter['1'] = @gate['topleftblock']['1']
							@dripcenter['y'] = @gate['topleftblock']['y']
							set_timeout(rand(0,199),closure(
								play_effect(_loc_mod(_loc_mod(@dripcenter,z,rand(-4,5) * .1),x,rand(-4,5) * .1),@gate['schematic']['particles']['particle'],@gate['schematic']['particles']['array'])
							))
						,
						'random',
							play_effect(@blockcenter,@gate['schematic']['particles']['particle'],@gate['schematic']['particles']['array'])
					)
					#broadcast(players_in_radius(@blockcenter,1))
					foreach(players_in_radius(@blockcenter,1),@player){
						if(!array_contains(import('AR.AngelGates.ActiveGates')[@network.'.'.@gatename]['just_arrived'],@player)){
							@destgate = import('AR.AngelGates.Networks')[@network]['gates'][@destination][]
							@width = array_size(@destgate['schematic']['shape'][0])
							@height = array_size(@destgate['schematic']['shape'])
							@target = _loc_mod(
								_loc_mod(
									_loc_center(@destgate['topleftblock']),
									@destgate['rightdirection'],
									(@width - 1) / 2
								),
								'-y',
								@height - 1
							)
							switch(@destgate['rightdirection'],
								'+z',pfacing(@player,1),
								'-x',pfacing(@player,2),
								'-z',pfacing(@player,3),
								'+x',pfacing(@player,0)
							)
							set_ploc(@player,@target)
							array_push(import('AR.AngelGates.ActiveGates')[@network.'.'.@destination]['just_arrived'],@player)
							set_timeout(2000,closure(
								try(array_remove_values(import('AR.AngelGates.ActiveGates')[@network.'.'.@destination]['just_arrived'],@player))
							))
							if(import('AR.AngelGates.ActiveGates')[@network.'.'.@gatename]['opened_by'] == @player){
								import('AR.AngelGates.ActiveGates')[@network.'.'.@gatename]['closing_at'] = time() + 1000
							}
						}
					}
				}
			}
		}
		if(time() > import('AR.AngelGates.ActiveGates')[@network.'.'.@gatename]['closing_at']){
			clear_task() #not working for some reason
			_close_gate(@gatename,@network)
		}
	))
	_open_gate(@destination,@network,@gatename)
}

proc(_close_gate,@gatename,@network){
	@destination = import('AR.AngelGates.ActiveGates')[@network.'.'.@gatename]['destination']
	array_remove(import('AR.AngelGates.ActiveGates'),@network.'.'.@gatename)
	if(array_index_exists(import('AR.AngelGates.ActiveGates'),@network.'.'.@destination)){
		_close_gate(@destination,@network)
	}
	_sign_rest(@gatename,@network)
}

proc(_create_gate,@gatename,@network,@topleftblock,@schematic,@type,@rightdirection){
	@uuid = pinfo(player(),20)
	@networks = import('AR.AngelGates.Networks')
	if(array_index_exists(@networks,@network)){
		if(@networks[@network]['owner'] != @uuid){
			die(color(c).'That network name is taken.')
		}
		if(!array_contains(@schematic['nettypes'],@networks[@network]['type'])){
			die(color(c).'That is the wrong kind of gate for that network.')
		}
	}else{
		@nettype = @schematic['nettypes'][0]
		@netsused = 0
		foreach(@networks,@netname,@netarray){
			if(@netarray['owner'] == @uuid && @netarray['type'] == @nettype){
				inc(@netsused)
			}
		}
		if(@nettype == 'private' || @nettype == 'special'){
			@max = _has_num_permission(player(),'AngelGates.'.@nettype,10)
			if(@max > @netsused){
				_create_network(@network,@uuid,@nettype)
			}else{
				die('You have no unused '.@nettype.' networks.')
			}
		}else if(@nettype == 'admin'){
			if(has_permission('AngelGates.Admin')){
				_create_network(@network,@uuid,@nettype)
			}else{
				die('That type of gate is reserved for server use.')
			}
		}else{
			die('That type of gate is not configured or invalid.')
		}
	}
	if(array_index_exists(@networks[@network]['gates'],@gatename)){
		_remove_gate(@gatename,@network,false)
		msg('This gate already existed on this network and has been unlinked and retired.')
	}
	@networks[@network]['gates'][@gatename] = array(
		'topleftblock':@topleftblock,
		'schematic':@schematic,
		'type':'obsidian4x5',
		'rightdirection':@rightdirection,
		'blocks':array(),
	)
	@gate = @networks[@network]['gates'][@gatename]
	foreach(@gate['schematic']['shape'],@yindex,@row){
		foreach(@row,@xindex,@character){
			if(array_contains(array('0','1','2','3','4','5','6','7','8','9'),@character)){
				@block = _loc_mod(_loc_mod(@gate['topleftblock'],@gate['rightdirection'],@xindex),'-y',@yindex)
				array_push(@networks[@network]['gates'][@gatename]['blocks'],_loc_normalize(@block))
			}
		}
	}
	_add_button(@gatename,@network)
	_sign_rest(@gatename,@network)
	store_value('AR.AngelGates.Networks',@networks)
	msg('Gate Creation Successful!')
}

proc(_remove_gate,@gatename,@network,@clearnet){
	if(@clearnet === '', @clearnet = true)
	@uuid = pinfo(player(),20)
	@networks = import('AR.AngelGates.Networks')
	if(!array_index_exists(@networks,@network)){
		die(color(c).'No such network exists.')
	}
	if(@networks[@network]['owner'] != @uuid && !has_permission('AngelGates.Admin')){
		die(color(c).'That gate does not belong to you.')
	}
	@gate = @networks[@network]['gates'][@gatename]
	foreach(@gate['schematic']['shape'],@yindex,@row){
		foreach(@gate['schematic']['shape'][@yindex],@xindex,@character){
			if(@character == '-'){
				switch(@gate['rightdirection'],
					'+x',
					@frontface = '+z',
					'+z',
					@frontface = '-x',
					'-x',
					@frontface = '-z',
					'-z',
					@frontface = '+x'
				)
				@targetblock = _loc_mod(_loc_mod(_loc_mod(@gate['topleftblock'],@gate['rightdirection'],@xindex),'-y',@yindex),@frontface,1)
				if(split(':',get_block_at(@targetblock))[0] == '68'){
					x_run_on_main_thread_later(closure(break_block(@targetblock)))
				}
				if(split(':',get_block_at(@targetblock))[0] == '143'){
					x_run_on_main_thread_later(closure(set_block_at(@targetblock,0)))
				}
			}
		}
	}
	array_remove(@networks[@network]['gates'],@gatename)
	if(array_size(@networks[@network]['gates']) == 0 && @clearnet){
		_remove_network(@network)
	}
	store_value('AR.AngelGates.Networks',@networks)
	msg('Gate '.@gatename.' removed.')
}

proc(_create_network,@network,@owner,@nettype){
	@networks = import('AR.AngelGates.Networks')
	if(array_index_exists(@networks,@network)){
		die(color(c).'A network already exists with that name.')
	}
	@networks[@network] = associative_array(
		'owner':@owner,
		'gates':associative_array(),
		'members':array(),
		'type':@nettype
	)
	store_value('AR.AngelGates.Networks',@networks)
	msg('Network Creation Successful!')
}

proc(_remove_network,@network){
	@uuid = pinfo(player(),20)
	@networks = import('AR.AngelGates.Networks')
	if(!array_index_exists(@networks,@network)){
		die(color(c).'No such network exists.')
	}
	if(@networks[@network]['owner'] != @uuid && !has_permission('AngelGates.Admin')){
		die(color(c).'That network does not belong to you.')
	}
	array_remove(@networks,@network)
	store_value('AR.AngelGates.Networks',@networks)
	msg('Network removed.')
}
