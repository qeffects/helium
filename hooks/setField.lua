--Exposes anything you want to the external element object
--Keep in mind setting a field from outside, unless it is a state object won't do anything
local path = string.sub(..., 1, string.len(...) - string.len(".hooks.setField"))
local context = require(path.. ".core.stack")

return function(field, value)
	local activeContext = context.getContext()

	if activeContext.element[field] then
		error('callback with name '..field..' would interfere with internal fields')
	end
	
	activeContext.element[field] = value
end