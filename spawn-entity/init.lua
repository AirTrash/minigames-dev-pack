local S = minetest.get_translator("spawn_entity")

minetest.register_chatcommand("spawn-entity", {
	description = S("spawn entity x y z"),

	params = "<name> <x> <y> <z>",

	privs = {give = true},

	func = function(player, param)
		local args = param:split(" ")
		if tostring(args[1]) == nil then
			minetest.chat_send_player(player, S("param 1 not string"))
			return
		end
		for i = 2, 4 do
			if type(tonumber(args[i])) ~= "number" then
				minetest.chat_send_player(player, S("param ")..tostring(i)..S(" not number"))
				return
			end
			args[i] = tonumber(args[i])
		end
		local entities = minetest.registered_entities
		for _, entity in pairs(entities) do
			if entity.name == args[1] then
				minetest.add_entity({x = args[2], y = args[3], z = args[4]}, args[1])
				minetest.chat_send_player(player, S("entity")..' "'..args[1]..'" '..S("spawned at").." "..args[2].." "..args[3].." "..args[4])
				return
			end
		end
		minetest.chat_send_player(player, S("entity")..' "'..args[1]..'" '..S("is not registered"))
	end,
	})
