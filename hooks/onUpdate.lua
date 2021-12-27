local path = string.sub(..., 1, string.len(...) - string.len(".hooks.onUpdate"))
local context = require(path.. ".core.stack")

---Sets a callback on any updatefor the current element (can have multiple)
---Use this to get logic outside of rendering function
---@param callback function
return function (callback)
	local activeContext = context.getContext()

	if not activeContext.element.callbacks['onUpdate'] then
		activeContext.element.callbacks.onUpdate = {}
	end
	
	activeContext.element.callbacks.onUpdate[#activeContext.element.callbacks.onUpdate+1] = callback
end