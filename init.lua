--[[--------------------------------------------------
	Helium UI by qfx (qfluxstudios@gmail.com)
	Copyright (c) 2019 Elmārs Āboliņš
	gitlab.com/project link here
----------------------------------------------------]]
local path     = ...
local helium   = require(path..".dummy")

local defaultConf = require(path..".conf")
helium.conf = {}
if HELIUM_CONFIG then
	for i, e in pairs(defaultConf) do
		helium.conf[i] = HELIUM_CONFIG[i] or e
	end
else
	helium.conf = defaultConf
end

helium.utils   = require(path..".utils")
helium.scene   = require(path..".core.scene")
helium.element = require(path..".core.element")
helium.input   = require(path..".core.input")
helium.loader  = require(path..".loader")
helium.stack   = require(path..".core.stack")
helium.atlas   = require(path..".core.atlas")
helium.__index = helium

function helium.setBench(time)
	helium.benchNum = time
	helium.element.setBench(time)
	helium.atlas.setBench(time)
end

setmetatable(helium, {__call = function(s, chunk)
	return setmetatable({
		draw = function (param, inputs, x, y, w, h)
		end
	}, 
	{__call = function(s, param, w, h)
		return helium.element(chunk, param, w, h)
	end,})
end})

--Typescript
helium.helium = helium
return helium