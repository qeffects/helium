--Allows to expose a function to outside the element simply
local path = string.sub(..., 1, string.len(...) - string.len(".hooks.callback"))
local context = require(path.. ".core.stack")

---Creates a callback on the 'name' field for the current element
---@param name string
---@param callback function
return function (name, callback)
	local activeContext = context.getContext()

	if activeContext.element[name] then
		error('callback with name '..name..' would interfere with internal fields')
	end
	
	activeContext.element[name] = callback
end