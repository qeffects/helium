local path = string.sub(..., 1, string.len(...) - string.len(".hooks.onLoad"))
local context = require(path.. ".core.stack")

---Sets a callback on a load event for the current element (can have multiple)
---@param callback function
return function (callback)
	local activeContext = context.getContext()

	if not activeContext.element.callbacks['onLoad'] then
		activeContext.element.callbacks.onLoad = {}
	end
	
	activeContext.element.callbacks.onLoad[#activeContext.element.callbacks.onLoad+1] = callback
end