
local eventmgr = import("events")()
local AddPrefabPostInit = import("events")("AddPrefabPostInit")
local AddPlayerPostInit = import("events")("AddPlayerPostInit")
local AddPrefabPostInitAny = import("events")("AddPrefabPostInitAny")

-- todo
local AddClassPostConstruct
local AddUserCommand

this = this or {}

------------------------------------------------------------
-- trigger
------------------------------------------------------------

eventmgr.on('SpawnPrefabFromSim', function (inst, prefab)
	eventmgr.emit('AddPrefabPostInit', inst, name)
	eventmgr.emit('AddPrefabPostInitAny', inst, name)
	AddPrefabPostInit.emit(prefab, inst);
	AddPrefabPostInitAny.emit('', inst);

	if inst and inst:HasTag("player") then
		eventmgr.emit('AddPlayerPostInit', inst, name)
		AddPlayerPostInit.emit('', inst);
	end
end)


AddPrefabPostInit.on('world', function (wrld)
  wrld:ListenForEvent("playeractivated", _f(function (world, player)
	trace("[test]", 111, wrld, world, player)
  	eventmgr.emit('playeractivated', player, world)
  end))
  wrld:ListenForEvent("playerdeactivated", _f(function (world, player)
	trace("[test]", 222, wrld, world, player)
  	eventmgr.emit('playerdeactivated', player, world)
  end))
end)

AddPrefabPostInit.on('world', function (inst) 
	eventmgr.emit('TheWorld', inst)

	-- local utils = import("utils")
	local timer = reload("timer")(TheWorld)
	timer.removeTimer(this.timer_second)
	this.timer_second = timer.setInterval(function (elapse_sec)
		eventmgr.emit('timer_second', elapse_sec)
	end, 1)


end)





-- AddPrefabPostInit.on('world', function (inst) 
-- 	-- print(222, "....bbb.......", inst)
-- end)

-- AddPrefabPostInitAny.on('', function (inst) 
-- 	-- print(333, "......ccc.....", inst)
-- end)

-- AddPlayerPostInit.on('', function (inst) 
-- 	-- print(444, ".....ddd......", inst)
-- end)
