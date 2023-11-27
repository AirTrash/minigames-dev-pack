local S = minetest.get_translator("tp_stick")

local function get_stick(params)
	local stick = ItemStack("tp_stick:tp_stick")
	local meta = stick:get_meta()

	meta:set_string("params", table.concat(params, " "))
	if #params == 9 then
		meta:set_string("description", table.concat({params[1], params[2], params[3]}, " ").." area mode")
	else
		meta:set_string("description", table.concat({params[1], params[2], params[3]}, " "))
	end

	return stick
end

minetest.register_chatcommand("tp_stick", {
	params = S("<target_pos> optional: <area_pos1> <area_pos2>").." "..S("or <player_recivier>").." "..S("<target_pos> optional: <area_pos1> <area_pos2>"),
	description = S("get tp_stick for teleport to target pos.").."\n"
	..S("if you specified an area for teleport, then teleport will be carried out only from this area").."\n"
	..S("for example: tp_stick user 1 1 1 0 0 0 10 10 10 - give to the user stick for teleport to 1 1 1 if the entity is in the area between 0 0 0 and 10 10 10"),

	privs = {teleport=true, give=true, bring=true},

	func = function(name, args)
		local args = args:split(" ")
		local receivier = ""
		local k = 0
		if #args == 4 or #args == 10 then
			receivier = args[1]
			table.remove(args, 1)
			k = 1
		else
			receivier = name
		end

		if #args ~= 3 and #args ~= 9 then
			minetest.chat_send_player(name, S("Incorrect syntax"))
			return
		end

		local player= minetest.get_player_by_name(receivier)
		if not player then
			minetest.chat_send_player(name, receivier.." "..S("not online"))
			return
		end

		
		for i = 1, #args do
			local num = tonumber(args[i])
			if not num then
				minetest.chat_send_player(name, S("Param ") .. i + k .. S(" not number"))
				return
			end
			args[i] = num
		end

		local inv = player:get_inventory()
		local stick = get_stick(args)
		inv:add_item("main", stick)
	end
})

local function convertToNum(t)
	for i = 1, #t do
		local num = tonumber(t[i])
		if not num then
			return false
		end
		t[i] = num
	end
	return t
end

local function convertToPos(cords)
	local names = {"x", "y", "z"}
	for i = 1, 3 do
		local cord = cords[1]
		table.remove(cords, 1)
		cords[names[i]] = cord
	end
	return cords
end

local function checkInArea(target, pos1, pos2)
	local names = {"x", "y", "z"}
	for _, name in pairs(names) do
		local min_pos, max_pos = math.min(pos1[name], pos2[name]), math.max(pos1[name], pos2[name])
		local cord = target[name]
		if max_pos < cord or cord < min_pos then
			return false
		end
	end
	return true
end

local function tp(itemstack, ref, ref_pos)
	local meta = itemstack:get_meta()
	local params = meta:get_string("params")
	local cords = convertToNum(params:split(" "))
	if not cords or #cords < 3 then
		return S("Incorrect tp_stick metadata")
	end
	
	local target = convertToPos({cords[1], cords[2], cords[3]})
	if #cords < 9 then
		ref:set_pos(target)
		return
	end
	local pos1, pos2 = convertToPos({cords[4], cords[5], cords[6]}), convertToPos({cords[7], cords[8], cords[9]})
	if checkInArea(ref_pos, pos1, pos2) then
		ref:set_pos(target)
		return nil
	else
		return S("The entity is not in the teleport area")
	end

end

minetest.register_craftitem("tp_stick:tp_stick", {
	description = "teleport stick",

	inventory_image = "default_stick.png",

	on_use = function(itemstack, user, pointed_thing)
		if not user or not pointed_thing.ref or not pointed_thing.ref then
			return
		end

		local result = tp(itemstack, pointed_thing.ref, pointed_thing.ref:get_pos())
		if result then
			minetest.chat_send_player(user:get_player_name(), result)
		end
	end	
})