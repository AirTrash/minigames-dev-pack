local modname = "digilines_commandblock"

local S = minetest.get_translator("digilines_commandblock")

local function parse_pos(param, idx, pos)
	local names = {"x", "y", "z"}
	local idx2 = param:find("}", idx) or 0
	local parampos = param:sub(idx + 1, idx2 - 1)
	parampos = parampos:split(" ")
	if #parampos ~= 4 then
		return pos, false
	end

	local newpos = {}
	local r = tonumber(parampos[4])
	if not r then
		return pos, false
	end
	for i = 1, 3 do
		cord = tonumber(parampos[i])
		if not cord then
			return pos, false
		end
		newpos[names[i]] = cord
	end

	return newpos, r
end

local function parse_param(param, players, pos, owner)
	local nidx, fidx, ridx = param:find("@nearest"), param:find("@farthest"), param:find("@random")
	local idx1, idx2 = 1, 1
	if nidx then
		idx1 = nidx
		idx2 = idx1 + 8
	elseif fidx then
		idx1 = fidx
		idx2 = idx1 + 9
	elseif ridx then
		idx1 = ridx
		idx2 = idx1 + 7
	else
		return param
	end
	local r = false
	if param:sub(idx2, idx2) == "{" then
		pos, r = parse_pos(param, idx2, pos)
		local idx3 = param:find("}", idx2)
		if idx3 == nil then
			return param
		end
		local newparam = param:sub(1, idx2 - 1)
		newparam = newparam .. param:sub(idx3 + 1)
		param = newparam
	end

	local farthest, nearest = "", ""
	local nearest = farthest
	local min = math.huge
	local max = -1
	local to_random = {}
	for _, player in pairs(players) do
		local distance = vector.distance(pos, player:get_pos())
		if r == false or distance <= r then
			if distance < min then
				min = distance
				nearest = player:get_player_name()
			end
			if distance > max then
				max = distance
				farthest = player:get_player_name()
			end
			if ridx then
				table.insert(to_random, player:get_player_name())
			end
		end
	end
	if nidx then
		return param:gsub("@nearest", nearest)
	elseif fidx then
		return param:gsub("@farthest", farthest)
	elseif ridx then
		if #to_random == 0 then
			return param:gsub("@random", "")
		end
		return param:gsub("@random", to_random[math.random(#to_random)])
	end
	return param
end

local function parse_params(param, owner, pos)
	if not (param:find("@nearest") or param:find("@farthest") or param:find("@random")) then
		return param
	end

	local players = minetest.get_connected_players()
	if #players == 0 then
		param = param:gsub("@nearest", "")
		param = gsub("@random", "")
		param = gsub("@farthest", "")
		return param
	end

	local new_param = parse_param(param, players, pos, owner)
	while new_param ~= param do
		param = new_param
		new_param = parse_param(param, players, pos, owner)
	end
	return param
end

local function command_execute(owner, player, msg, pos)
	if type(msg) ~= "string" then
		minetest.chat_send_player(owner, "type msg or msg element is not string")
		return
	end
	local idx = msg:find(" ")
	local cmd, params = msg, ""
	if idx then
		cmd = msg:sub(1, idx - 1)
		params = msg:sub(idx + 1)
	end

	local cmdt = minetest.chatcommands[cmd]
	if not cmdt then
		minetest.chat_send_player(owner, "The command "..cmd.." does not exist")
		return
	end
	local has_privs, missing_privs = minetest.check_player_privs(owner, cmdt.privs)
	if not has_privs then
		minetest.chat_send_player(owner, "You dont have permissions for "..cmd)
		minetest.chat_send_player(owner, "missing privs: "..table.concat(missing_privs, ", "))
		return
	end

	params = parse_params(params, owner, pos)
	cmdt.func(player, params)
end

local function on_digiline_receive(pos, node, channel, msg)
	local meta = minetest.get_meta(pos)
	local owner = meta:get_string("owner")
	local await_channel = meta:get_string("channel")

	if not owner or owner == "" or not channel then
		return
	end
	if await_channel ~= channel then
		return
	end
	local player = owner
	if meta:get_string("mode") ~= "owner" then
		player = "not exist player"
	end
	if type(msg) == "string" then
		command_execute(owner, player, msg, pos)
	elseif type(msg) == "table" then
		for i = 1, #msg do
			command_execute(owner, player, msg[i], pos)
		end
	end
end

local function get_next_mode(meta)
	local mode = meta:get_string("mode")
	if mode == "owner" then
		return "fake player"
	else
		return "owner"
	end
end

minetest.register_node(modname..":commandblock", {
	description = S("digilines command block"),

	groups = {cracky = 2, digiline_receiver = 1},

	tiles = {"digiline_commandblock.png"},

	after_place_node = function(pos, placer, itemstack, pointed_thing)
		local name = placer:get_player_name()
		local meta = minetest.get_meta(pos)
		
		meta:set_string("owner", name)
		meta:set_string("infotext", "owner: "..name)
		meta:set_string("mode", "owner")
		local formspec = "size[10, 5]".."field[1,1;3,3;channel;channel;cmdblock]".."button_exit[4,1.5;1,1;close;Set]".."button[5,1.5;3,1;mode;mode: owner]".."label[0.5,2.5;you can use:]".."label[2,2.5;@nearest]".."label[3.2,2.5;@farthest]".."label[4.4,2.5;@random]"
		meta:set_string("formspec", formspec.."label[0.5,3;or:]".."label[1,3;@nearest{x y z radius}]".."label[3.5,3;@farthest{x y z radius}]".."label[6,3;@random{x y z radius}]".."label[0.5,4;for example: digiline_send('cmdblock', 'teleport @nearest{0 0 0 100} @random')]")
		meta:set_string("channel", "cmdblock")
	end,
	on_receive_fields = function(pos, formname, fields, player)
		player = player:get_player_name()
		if minetest.is_protected(pos, player) and not minetest.check_player_privs(player, {protection_bypass=true}) then
			return
		end
		local meta = minetest.get_meta(pos)
		if fields.channel then
			local formspec = "size[10, 5]"..string.format("field[1,1;3,3;channel;channel;%s]", fields.channel).."button_exit[4,1.5;1,1;close;Set]".."button_exit[5,1.5;3,1;mode;mode: "..meta:get_string("mode").."]".."label[0.5,2.5;you can use:]".."label[2,2.5;@nearest]".."label[3.2,2.5;@farthest]".."label[4.4,2.5;@random]"
			meta:set_string("formspec", formspec.."label[0.5,3;or:]".."label[1,3;@nearest{x y z radius}]".."label[3.5,3;@farthest{x y z radius}]".."label[6,3;@random{x y z radius}]".."label[0.5,4;for example: digiline_send('cmdblock', 'teleport @nearest{0 0 0 100} @random')]")
			meta:set_string("channel", fields.channel)
		end
		if fields.mode then
			local mode = get_next_mode(meta)
			meta:set_string("mode", mode)
			local formspec = "size[10, 5]"..string.format("field[1,1;3,3;channel;channel;%s]", meta:get_string("channel")).."button_exit[4,1.5;1,1;close;Set]".."button_exit[5,1.5;3,1;mode;mode: "..mode.."]".."label[0.5,2.5;you can use:]".."label[2,2.5;@nearest]".."label[3.2,2.5;@farthest]".."label[4.4,2.5;@random]"
			meta:set_string("formspec", formspec.."label[0.5,3;or:]".."label[1,3;@nearest{x y z radius}]".."label[3.5,3;@farthest{x y z radius}]".."label[6,3;@random{x y z radius}]".."label[0.5,4;for example: digiline_send('cmdblock', 'teleport @nearest{0 0 0 100} @random')]")		
		end
	end,
	digiline = {
		receptor = {},
		effector = {
			action = on_digiline_receive
		}
	}
})
