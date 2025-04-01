local path = string.sub(..., 1, string.len(...) - string.len(".hooks.setCaching"))
---@type context
local context = require(path.. ".core.stack")
local helium = require(path.. ".dummy")

return function ()
	local activeContext = context.getContext()
	
	if not helium.conf.MANUAL_CACHING then
		error('use setCaching only with manual caching enabled, check your configs')
	end
	activeContext.element:createCanvas()
	activeContext.element.settings.forcedCanvas = true
	activeContext.element.settings.pendingUpdate = true
end