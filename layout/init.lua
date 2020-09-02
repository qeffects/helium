local path   = string.sub(..., 1, string.len(...) - string.len(".core.layout"))

local layout = {}
layout.__index = layout
local element = require(path..'core.element')
local stack = require(path..'core.stack')

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

    return 
end

layout(0,0,1,1)

--Start prep phase
function layout.type(type)
	local self = {
		vars = {
			type = type or 'flow',
			offLeft = 0,
			offTop = 0,
			width   = 1,
			height  = 1,
			alignX  = 'left', --options: left, center, right
			alignY  = 'top', --options: top, center, bottom
			flowDir = 'rtl' --options: rtl/ttb
		}
	}


	
	return setmetatable(self, layout)
end

function layout:alignVert(pos)
	self.vars.alignY = pos
end

function layout:alignHoriz(pos)
	self.vars.alignX = pos
end

function layout:width(w)
	self.vars.width = w
end

function layout:height(h)
	self.vars.height = h
end

function layout:left(x)
	self.vars.offTop = x
end

function layout:right(x)
	self.vars.offRight = x
end

function layout:top(y)
	self.vars.offTop = y
end

function layout:bottom(y)
	self.vars.offBot = y
end



setmetatable(layout, {__call = function(s, type) return layout.type(type) end }
return layout
