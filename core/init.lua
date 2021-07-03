local path = ...

---@class __HELIUM_CORE
---@field atlas any
---@field element any
---@field events any
---@field input any
---@field scene any
---@field stack any
return {
	atlas   = require(path..'.atlas'),
	element = require(path..'.element'),
	events  = require(path..'.events'),
	input   = require(path..'.input'),
	scene   = require(path..'.scene'),
	stack   = require(path..'.stack'),
}