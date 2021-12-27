local path = string.sub(..., 1, string.len(...) - string.len(".hooks.onSizeChange"))
local context = require(path.. ".core.stack")

---@alias SizeChangeCallback fun(w: number, h:number)

---Sets a callback on a size change event for the current element (can have multiple)
---@param callback SizeChangeCallback
return function (callback)
	local activeContext = context.getContext()

	if not activeContext.element.callbacks['onSizeChange'] then
		activeContext.element.callbacks.onSizeChange = {}
	end
	
	activeContext.element.callbacks.onSizeChange[#activeContext.element.callbacks.onSizeChange+1] = callback
end