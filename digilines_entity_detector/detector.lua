local function get_radius(radius)
	local r = tonumber(radius)
	if not r then return "5" end
	if r > 10 then return "10" end
	if r < 0 then return "5" end
	return radius
end

minetest.register_node("digilines_entity_detector:entity_detector", {
	groups = {cracky=2},

	tiles = {"digilines_entity_detector.png"},

	description = "entity detector",

	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("pos1", "0,0,0")
		meta:set_string("radius", "5")
		meta:set_string("filters", "__builtin:item,")
		meta:set_string("formspec", "size[10,5]".."field[1,1;3,3;channel;Channel;${channel}]"..
		"field[4,1;2,3;radius;Radius;${radius}]"..
		"field[6,1;3,3;filters;Filters;${filters}]".."button_exit[2,3;1,1;close;Save]")
	end,

	on_receive_fields = function(pos, formname, fields, player)
		player = player:get_player_name()
		if minetest.is_protected(pos, player) and not minetest.check_player_privs(player, {protection_bypass=true}) then
			return
		end
		local meta = minetest.get_meta(pos)
		if fields.channel then meta:set_string("channel", fields.channel) end
		if fields.radius then meta:set_string("radius", get_radius(fields.radius)) end
		if fields.filters then meta:set_string("filters", fields.filters:gsub(" ", "")) end
	end,

	digiline = {
		receptor = {}
	}
})

minetest.register_craft({
	output = "digilines_entity_detector:entity_detector",
	recipe = {
		{"mesecons_gamecompat:steel_ingot", "digilines:wire_std_00000000", "mesecons_gamecompat:steel_ingot"},
		{"mesecons_gamecompat:steel_ingot", "mesecons_microcontroller:microcontroller0000", "mesecons_gamecompat:steel_ingot"},
		{"mesecons_gamecompat:steel_ingot", "digilines:wire_std_00000000", "mesecons_gamecompat:steel_ingot"},
	}
})

function convert_filters(filters)
	for i = 1, #filters do
		local filter = filters[1]
		filters[filter] = true
		table.remove(filters, 1)
	end
	return filters
end

minetest.register_abm({
	nodenames = {"digilines_entity_detector:entity_detector"},
	interval = 1,
	chance = 1,
	action = function(pos)
		local meta = minetest.get_meta(pos)
		local r = meta:get_string("radius")
		r = tonumber(r)
		if not r or r > 10 or r < 0 then
			return
		end
		local channel = meta:get_string("channel")
		local filters = convert_filters(meta:get_string("filters"):split(","))
		local entities = {}
		local objs = minetest.get_objects_inside_radius(pos, r)
		for _, obj in ipairs(objs) do
			if not obj:is_player() then
				local name = obj:get_entity_name()
				if not filters[name] then
					table.insert(entities, name)
				end
			end
		end
		if #entities > 0 then
			digiline:receptor_send(pos, digiline.rules.default, channel, entities)
		end
	end
})
