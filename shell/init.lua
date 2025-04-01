local path = ...

---@class __HELIUM_SHELL
---@field button any
---@field checkbox any
---@field input any
---@field slider any
return {
	button   = require(path..'.button'),
	checkbox = require(path..'.checkbox'),
	input    = require(path..'.input'),
	slider   = require(path..'.slider'),
}