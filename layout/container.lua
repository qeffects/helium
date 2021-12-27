local path   = string.sub(..., 1, string.len(...) - string.len(".container"))
local layout = require(path..'.layout')

---@class Container
local container = {}
container.__index = container

---Positions an element within a container
---@param halign "'left'"|"'center'"|"'right'"|"'stretch'"
---@param valign "'top'"|"'center'"|"'bottom'"|"'stretch'"
---@return layout
function container.new(halign, valign)
	local self = setmetatable({
		halign = halign or 'left',
		valign = valign or 'top',
	}, container)
	
	return layout(self, self.draw)
end

local function alignLeft(x, wroot, wchild)
	return x
end

local function alignCenter(x, wroot, wchild)
	return x+(wroot/2-wchild/2)
end

local function alignRight(x, wroot, wchild)
	return x+(wroot-wchild)
end


local function alignHandlerX(mode, x, wr, wc)
	if mode == 'center' then
		return alignCenter(x, wr, wc)
	elseif mode == 'right' then
		return alignRight(x, wr, wc)
	else
		return alignLeft(x)
	end
end

local function alignHandlerY(mode, y, hr, hc)
	if mode == 'center' then
		return alignCenter(y, hr, hc)
	elseif mode == 'bottom' then
		return alignRight(y, hr, hc)
	else
		return alignLeft(y)
	end
end

function container:draw(x, y, width, height, children, hpad, vpad, alignX)
	local w, h = children[1]:getSize()
	local x, y 

	if self.halign =='stretch' then
		w = width
		x = x
	else
		x = alignHandlerX(self.halign, containerX, containerWidth, w)
	end

	if self.valign =='stretch' then
		h = h
		y = y
	else
		y = alignHandlerY(self.valign, containerY, containerHeight, h)
	end

	children[1]:draw(x, y, w, h)
end

return container