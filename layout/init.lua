local path   = string.sub(..., 1, string.len(...) - string.len(".layout"))

local layout = {}
local layouts = {}
layouts.column = require(path..'.layout.column')
layouts.row = require(path..'.layout.row')
layout.__index = layout
local element = require(path..'.core.element')
local stack = require(path..'.core.stack')

--Start prep phase
function layout.type(type)
	local curStack = stack.getContext()
	curStack:startDeferingChildren()

	local self = {
		vars = {
			type = type or 'column',
			offLeft = 0,
			offTop = 0,
			width   = 1,
			hpad    = 3,
			vpad    = 3,
			height  = 1,
			alignX  = 'left', --options: left, center, right
			alignY  = 'top', --options: top, center, bottom
			--flowDir = 'rtl', --options: rtl/ttb
		},
		stack = curStack
	}
	
	return setmetatable(self, layout)
end

function layout:alignVert(pos)
	self.vars.alignY = pos

	return self
end

function layout:alignHoriz(pos)
	self.vars.alignX = pos
	
	return self
end

--Sets up the box of the layout
function layout:width(w)
	self.vars.width = w
	
	return self
end

function layout:height(h)
	self.vars.height = h

	return self
end

function layout:left(x)
	self.vars.offLeft = x

	return self
end

function layout:right(x)
	self.vars.offRight = x
	
	return self
end

function layout:top(y)
	self.vars.offTop = y

	return self
end

function layout:bottom(y)
	self.vars.offBot = y

	return self
end

function layout:vPadding(px)
	self.vars.vpad = px

	return self
end

function layout:hPadding(px)
	self.vars.hpad = px

	return self
end

--Schemes: left + right = width ignored
--top + bottom = height ignored
--top px + bottom relative works
--left relative + bottom px works 
function layout:draw()
	local stack = self.stack
	local children = stack:stopDeferingChildren()
	local height, width, x, y, _, marginV, marginH
	local maxW, maxH = stack:normalizeSize(1,1)

	if self.vars.offTop and self.vars.offBot then
		marginV = stack:normY(self.vars.offTop) + stack:normY(self.vars.offBot)
		height = stack:normY(1) - marginV
	elseif self.vars.offTop then
		y = stack:normY(self.vars.offTop)
		height = math.min(stack:normY(self.vars.height), maxH-y)
	elseif self.vars.offBot then
		y = stack:normY(self.vars.offBot)
		height = math.min(stack:normY(self.vars.height), maxH-y)
		y = 0
	end

	if self.vars.offLeft and self.vars.offRight then
		marginH = stack:normX(self.vars.offLeft) + stack:normX(self.vars.offRight)
		width = stack:normX(1) - marginH
	elseif self.vars.offLeft then
		x = stack:normX(self.vars.offLeft)
		width = math.min(stack:normX(self.vars.width), maxW-x)
	elseif self.vars.offRight then
		x = stack:normX(self.vars.offRight)
		height = math.min(stack:normX(self.vars.width), maxW-x)
		x = 0
	end

	layouts[self.vars.type](
		x,
		y,
		width,
		height,
		children,
		self.vars.hpad,
		self.vars.vpad,
		self.vars.alignX,
		self.vars.alignY
	)
end


setmetatable(layout, {__call = function(s, type) return layout.type(type) end })
return layout
