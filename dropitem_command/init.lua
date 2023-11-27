local S = minetest.get_translator("drop_item")

local function parse_params(params)
	params = params:split(" ")
	if #params < 4 then
		return S("E: count of params < 4")
	end
	local names = {"x", "y", "z"}
	local pos = {}
	local idx = #params - 2
	for i = 1, 3 do
		local cord = tonumber(params[idx])
		if not cord then
			return S("E: cord").."["..i.."]"..S(" not number, cord: ")..params[idx]
		end
		table.remove(params, idx)
		pos[names[1]] = cord
		table.remove(names, 1)
	end
	return table.concat(params, " "), pos
end

minetest.register_chatcommand("drop_item", {
	privs = {
		give = true
	},
	params = "<itemstring> <x> <y> <z>",
	description = S("drops an item at coordinates, for example /drop_item default:stick 1 2 3"),
	func = function (name, param)
		local param, pos = parse_params(param)
		if not pos then
			minetest.chat_send_player(name, param)
			return
		end
		local itemstack = ItemStack(param)
		minetest.item_drop(itemstack, nil, pos)
	end
})
