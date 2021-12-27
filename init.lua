--[[--------------------------------------------------
	Helium UI by qfx (qfluxstudios@gmail.com)
	Copyright (c) 2019 Elmārs Āboliņš
	https://github.com/qeffects/helium
----------------------------------------------------]]
local path     = ...

---@class __HELIUM
---@field private scene any
---@field private element any
---@field private atlas any
---@field private stack any
---@field private input any
local helium   = require(path..'.dummy')
helium.__index = helium

---@type __HELIUM_CONFIG
local defaultConf = require(path..".conf")
helium.conf = {}

if HELIUM_CONFIG then
	for i, e in pairs(defaultConf) do
		helium.conf[i] = HELIUM_CONFIG[i] or e
	end
else
	helium.conf = defaultConf
end

if helium.conf.LOAD_HOOKS then
	---@type __HELIUM_HOOKS
	helium.hooks = require(path..'.hooks')
end

if helium.conf.LOAD_SHELL then
	---@type __HELIUM_SHELL
	helium.shell = require(path..'.shell')
end

if helium.conf.LOAD_LAYOUT then
	---@type __HELIUM_LAYOUT
	helium.layout = require(path..'.layout')
end

helium.core = require(path..'.core')

helium.scene   = require(path..".core.scene")
helium.element = require(path..".core.element")
helium.input   = require(path..".core.input")
helium.stack   = require(path..".core.stack")
helium.atlas   = require(path..".core.atlas")

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
	{__call = function(s, param, w, h, flags)
		return helium.element(chunk, param, w, h, flags)
	end,})
end})

return helium