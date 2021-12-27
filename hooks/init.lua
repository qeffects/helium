local path = ...

---@class __HELIUM_HOOKS
---@field callback any
---@field context any
---@field onDestroy any
---@field onLoad any
---@field onPosChange any
---@field onSizeChange any
---@field onUpdate any
---@field setMinSize any
---@field setPos any
---@field setSize any
---@field state any
return {
	callback     = require(path..'.callback'),
	context      = require(path..'.context'),
	onDestroy    = require(path..'.onDestroy'),
	onLoad       = require(path..'.onLoad'),
	onPosChange  = require(path..'.onPosChange'),
	onSizeChange = require(path..'.onSizeChange'),
	onUpdate     = require(path..'.onUpdate'),
	setMinSize   = require(path..'.setMinSize'),
	setCaching   = require(path..'.setCaching'),
	setPos       = require(path..'.setPos'),
	setSize      = require(path..'.setSize'),
	state        = require(path..'.state'),
}