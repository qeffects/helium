local path   = string.sub(..., 1, string.len(...) - string.len(".core.layout"))

local layout = {}
layout.__index = layout
local element = require(path..'core.element')

local function layout_new(type, x, y, w, h)
    local ctx = element.getContext()

    --The output will be in pixel numbers regardless of inputs
    if x <= 1 or not x then
        x = ctx.view.x * (x or 0)
    end

    if y <= 1 then
        y = ctx.view.y * (y or 0)
    end

    if w <= 1 then
        w = ctx.view.w * (w or 1)
    end

    if h <= 1 then
        h = ctx.view.h * (h or 1)
    end

    return setmetatable({
        x = x,
        y = y,
        w = w,
        h = h
    }, layout)
end


--Sets mode for the proceding operations
function layout.mode()

end

--Sets padding for the next operations
function layout.pad()

end

--Sets margins for the proceding operations
function layout.margin()

end

function layout.offset()

end

function layout:draw()

end

layout(0,0,1,1)

return layout
