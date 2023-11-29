function check_pos(pos)
	if type(pos) ~= "table" then
		return nil
	end
	if type(tonumber(pos.x)) == nil or type(tonumber(pos.y)) == nil or type(tonumber(pos.z)) == nil then
		return nil
	end
	return true
end

function get_players(pos1, pos2)
	local objs = minetest.get_objects_in_area(pos1, pos2)
	local players = {}
	for idx, obj in ipairs(objs) do
		if obj:is_player() then
			table.insert(players, obj:get_player_name())
		end
	end
	return players
end

function on_digiline_receive(pos, node, channel, msg)
	local meta = minetest.get_meta(pos)
	local me_channel = meta:get_string("channel")
	if type(msg) ~= "table" then
		return
	end
	local command = msg.command
	if not command then return end
	local pos1 = msg.pos1
	local pos2 = msg.pos2

	local check = check_pos(pos1) and check_pos(pos2)
	if msg.command:lower() ~= "get" or me_channel ~= channel or not check then
		return
	end

	local players = get_players(pos1, pos2)
	digiline:receptor_send(pos, digiline.rules.default, me_channel, players)
end

minetest.register_node("digilines_extended_player_detector:player_detector",{
	groups = {cracky=2, digiline_receiver=1},

	description = "extended player detector",

	tiles = {"digilines_extended_player_detector.png"},

	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec", "size[10,5]".."field[1,1;3,3;channel;Channel;${channel}]".."button_exit[4,1.5;1,1;close;Save]")
	end,

	on_receive_fields = function(pos, formname, fields, player)
		player = player:get_player_name()
		if minetest.is_protected(pos, player) and not minetest.check_player_privs(player, {protection_bypass=true}) then
			return
		end
		local meta = minetest.get_meta(pos)
		if fields.channel then meta:set_string("channel", fields.channel) end
	end,

	digiline = {
		receptor = {},
		effector = {
			action = on_digiline_receive
		}
	}

})