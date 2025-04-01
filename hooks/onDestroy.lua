local path = string.sub(..., 1, string.len(...) - string.len(".hooks.onDestroy"))
local context = require(path.. ".core.stack")

---Sets a callback on a destructionevent for the current element (can have multiple)
---@param callback function
return function (callback)
	local activeContext = context.getContext()

	if not activeContext.element.callbacks['onDestroy'] then
		activeContext.element.callbacks.onDestroy = {}
	end
	
	activeContext.element.callbacks.onDestroy[#activeContext.element.callbacks.onDestroy+1] = callback
end