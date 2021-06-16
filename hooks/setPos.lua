local path = string.sub(..., 1, string.len(...) - string.len(".hooks.setPos"))
local stack = require(path..'.core.stack')

--Sets the relative position
return function(x, y)
    local currentStack = stack.getContext()
	currentStack.element.view.x = x or currentStack.element.view.x
	currentStack.element.view.y = y or currentStack.element.view.y
end