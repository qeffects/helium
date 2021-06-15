local path = string.sub(..., 1, string.len(...) - string.len(".hooks.onPosChange"))
local context = require(path.. ".core.stack")

---@alias PosChangeCallback fun(x: number, y:number)

---Sets a callback on a position change event for the current element (can have multiple)
---@param callback PosChangeCallback
return function (callback)
	local activeContext = context.getContext()

	if not activeContext.element.callbacks['onPosChange'] then
		activeContext.element.callbacks.onPosChange = {}
	end
	
	activeContext.element.callbacks.onPosChange[#activeContext.element.callbacks.onPosChange+1] = callback
end