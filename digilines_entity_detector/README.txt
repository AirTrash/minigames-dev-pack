-------------------detector_v2--------------------
how to use: send a table like this:
{
	command = "get",
	pos1={x = 1, y = 1, z = 1},
	pos2={x = 5, y = 5, z = 5}
}
a table list with entities will be sent back via the seted channel



You can also pass an additional filter parameter in the table like this:
{
	["mod2:eintity_1"] = true,
	["mod1:entity_2"] = true
}
entities specified in this table will not be added to the response table

for example:
{
	command="get",
	pos1={x=-12, y=7, z=16},
	pos2={x=-6, y=11, z=10},
	filter={
		["__builtin:item"]=false, -- P.s. __builtin:item - dropped item
	}
}
-------------------detector-----------------------
