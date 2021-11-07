local path   = string.sub(..., 1, string.len(...) - string.len(".layout.layout"))

---@class layout
---@field protected vars table
---@field protected type function
local layout = {}
local layouts = {}
layout.__index = layout
local element = require(path..'.core.element')
local stack = require(path..'.core.stack')

--Start prep phase
function layout.type(binder, callback)
	local curStack = stack.getContext()
	curStack:startDeferingChildren()

	local self = {
		vars = {
			width   = 1,
			hpad    = 3,
			vpad    = 3,
			height  = 1,
		},
		stack = curStack,
		binder = binder,
		callback = callback,
	}
	
	return setmetatable(self, layout)
end

---Aligns the container vertically
---@param pos 'left'|'center'|'right'
function layout:alignVert(pos)
	self.vars.alignY = pos

	return self
end

---Aligns the container horizontally
---@param pos 'top'|'center'|'bottom'
function layout:alignHoriz(pos)
	self.vars.alignX = pos
	
	return self
end

---Sets up the width of the box of the layout
---@param w number width in pixels or absolute 0-1
function layout:width(w)
	self.vars.width = w
	
	return self
end

---Sets up the height of the box of the layout
---@param h number width in pixels or absolute 0-1
function layout:height(h)
	self.vars.height = h

	return self
end
---Offset from the left
---@param x number offset in pixels or absolute 0-1
function layout:left(x)
	self.vars.offLeft = x

	return self
end

---Offset from the right
---@param x number offset in pixels or absolute 0-1
function layout:right(x)
	self.vars.offRight = x
	
	return self
end

---Offset from the top
---@param y number offset in pixels or absolute 0-1
function layout:top(y)
	self.vars.offTop = y

	return self
end

---Offset from the bottom
---@param y number offset in pixels or absolute 0-1
function layout:bottom(y)
	self.vars.offBot = y

	return self
end

---Padding for the elements vertically
---@param px number offset in pixels
function layout:vPadding(px)
	self.vars.vpad = px

	return self
end

---Padding for the elements horizontally
---@param px number offset in pixels
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
		y = stack:normY(self.vars.offTop)
	elseif self.vars.offBot then
		y = stack:normY(self.vars.offBot)
		height = math.min(stack:normY(self.vars.height), maxH-y)
		y = maxH - height - y
	else 
		y = stack:normY(self.vars.offTop or 0)
		height = math.min(stack:normY(self.vars.height), maxH-y)
	end

	if self.vars.offLeft and self.vars.offRight then
		marginH = stack:normX(self.vars.offLeft) + stack:normX(self.vars.offRight)
		width = stack:normX(1) - marginH
		x = stack:normX(self.vars.offLeft)
	elseif self.vars.offRight then
		x = stack:normX(self.vars.offRight)
		width = math.min(stack:normX(self.vars.width), maxW-x)
		x = maxW - width -h
	else
		x = stack:normX(self.vars.offLeft or 0)
		width = math.min(stack:normX(self.vars.width), maxW-x)
	end

	return self.callback(self.binder, x, y, width, height, children, self.vars.hpad, self.vars.vpad)
end


setmetatable(layout, {__call = function(s, binder, callback) return layout.type(binder, callback) end })
return layout