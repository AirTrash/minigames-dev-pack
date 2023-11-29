function check_pos(pos)
	if type(pos) ~= "table" then
		return nil
	end
	if type(tonumber(pos.x)) == nil or type(tonumber(pos.y)) == nil or type(tonumber(pos.z)) == nil then
		return nil
	end
	return true
end

function get_entities(pos1, pos2)
	local objs = minetest.get_objects_in_area(pos1, pos2)
	local list_entities = {}
	for idx, entity in ipairs(objs) do
		if not entity:is_player() then
			table.insert(list_entities, entity:get_entity_name())
		end
	end
	return list_entities
end

function get_entities_with_filter(pos1, pos2, filter)
	local objs = minetest.get_objects_in_area(pos1, pos2)
	local list_entities = {}
	for idx, entity in ipairs(objs) do
		if not entity:is_player() then
			local name = entity:get_entity_name()
			if not filter[name] then
				table.insert(list_entities, name)
			end
		end
	end
	return list_entities
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

	local entities = {"error with msg.filter"}
	if not msg.filter then
		entities = get_entities(pos1, pos2)
	elseif type(msg.filter) == "table" then
		entities = get_entities_with_filter(pos1, pos2, msg.filter)
	end

	digiline:receptor_send(pos, digiline.rules.default, me_channel, entities)
end

minetest.register_node("digilines_entity_detector:extended_entity_detector",{
	groups = {cracky=2, digiline_receiver=1},

	description = "extended entity detector",

	tiles = {"digilines_entity_detector_extended.png"},

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