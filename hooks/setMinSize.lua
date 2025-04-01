local path = string.sub(..., 1, string.len(...) - string.len(".hooks.setMinSize"))
local stack = require(path..'.core.stack')

--Sets the computed/minimum size of an element to be used with layout calculations and rendering
return function(w, h)
    local currentStack = stack.getContext()
    currentStack.element:setMinSize(w, h)
end