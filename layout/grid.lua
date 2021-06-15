local column = require "helium.layout.column"
--my copy of the cssssss grids
local path   = string.sub(..., 1, string.len(...) - string.len(".grid"))
local layout = require(path..'.init')

---@class GridCell
---@field name string @Will find the element with the relevant flag

---@alias GridRow GridCell[]

---@class HGridCell
---@field width number @Determines how wide this column will be

---@class WGridCell
---@field height string @Determines how high this column will be

---@alias HGridRow number[]|number|nil @Width of the row in cells

---@alias WGridCol number[]|number|nil @Width of the row in cells

---@alias GridLayout GridRow[]

---@class GridConfig
---@field layout GridLayout|nil @preconfigured layout table
---@field rows HGridRow|number|nil @set these instead of layout if you just want a regularly spaced 'table'
---@field columns WGridCol|number|nil @set these instead of layout if you just want a regularly spaced 'table' leave empty to flow in as many elements as you have
---@field verticalStretchMode "'stretch'"|"'normal'" 
---@field horizontalStretchMode "'stretch'"|"'normal'"
---@field horizontalAlignMode "'left'"|"'center'"|"'right'"
---@field verticalAlignMode "'top'"|"'center'"|"'bottom'"
---@field rowSpacing number @size in pixels to space the rows
---@field colSpacing number @size in pixels to space the columns
---@field rowSizeMode "'relative'"|"'absolute'" 
---@field colSizeMode "'relative'"|"'absolute'"

---@type GridConfig
local preconfiguredGrid = {
	colSpacing = 3,
	rowSpacing = 3,
	verticalStretchMode = 'normal',
	horizontalStretchMode = 'normal',
	verticalAlignMode = 'center',
	horizontalAlignMode = 'center',
	--rows = {1, 1, 1, 1},
	columns = {1, 1, 1, 1},
	--[[layout = {
		{'header', 'header', 'header'},
		{'sidebar','content','content'},
		{'sidebar','content','content'},
	}]]
}

---@class grid
---@field gridLayout GridConfig
local grid = {}
grid.__index = grid

---@param gridLayout GridConfig
---@return layout
function grid.new(gridLayout)
	local gridLayout = gridLayout or preconfiguredGrid
	local self = setmetatable({
		gridLayout = gridLayout
	}, grid)

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

function grid:draw(xRoot, yRoot, width, height, children, hpad, vpad)
	-- Either of these means no named layout
	local fullyAutoLayout = false
	local autoCols = false
	local autoRows = false
	local equalRows = false
	local equalCols = false

	local vertValueToPixels = 0
	local horValueToPixels = 0

	local finalLayout = {}

	if self.gridLayout.columns then
		if not self.gridLayout.rows then
			autoRows = true
		else
			if type(self.gridLayout.rows)=="table" then
				local total = 0
				
				for i, col in ipairs(self.gridLayout.rows) do
					total = total + col
				end
				
				vertValueToPixels = (height-(self.gridLayout.rowSpacing*total))/total
			else
				vertValueToPixels = (height-(self.gridLayout.rowSpacing*self.gridLayout.rows))/self.gridLayout.rows
				equalRows = true
			end
		end
		if type(self.gridLayout.columns)=="table" then
			local total = 0
			
			for i, col in ipairs(self.gridLayout.columns) do
				total = total + col
			end
			
			horValueToPixels = width/total
		else
			horValueToPixels = width/self.gridLayout.columns
			equalCols = true
		end
	else
		if not self.gridLayout.rows then
			fullyAutoLayout = true
			autoRows = true
		else
			autoCols = true
			if type(self.gridLayout.rows)=="table" then
				local total = 0
				
				for i, col in ipairs(self.gridLayout.rows) do
					total = total + col
				end
				
				vertValueToPixels = (height-(self.gridLayout.rowSpacing*total))/total
			else
				vertValueToPixels = (height-(self.gridLayout.rowSpacing*self.gridLayout.rows))/self.gridLayout.rows
				equalRows = true
			end
		end
	end

	print(horValueToPixels, width)

	if (not autoRows) and (not autoCols) then

	elseif fullyAutoLayout then--one element per width, vertically down
		local carriagePos = 0
		if children then
			for i, e in ipairs(children) do
				local w, h = e:getSize()

				if self.gridLayout.horizontalStretchMode =='stretch' then
					w = width
					e:draw(xRoot, yRoot+carriagePos, w)
				else
					local x = alignHandlerX(self.gridLayout.horizontalAlignMode, xRoot, width, w)
					e:draw(x, yRoot+carriagePos)
				end

				carriagePos = carriagePos + self.gridLayout.rowSpacing + h
			end
		end
	elseif autoCols then--one element per width, rows spaced
		local carriagePos = 0
		local row = 1
		local lastRowSize = 1

		if children then
			for i, e in ipairs(children) do
				local w, h = e:getSize()
				local rowSize
				local x, y

				if equalRows then
					rowSize = 1 * vertValueToPixels
				else
					rowSize = (self.gridLayout.rows[row] or lastRowSize)*vertValueToPixels
				end

				rowSize = math.max(h, rowSize)

				if self.gridLayout.horizontalStretchMode =='stretch' then
					w = width
				else
					x = alignHandlerX(self.gridLayout.horizontalAlignMode, xRoot, width, w)
				end

				if self.gridLayout.verticalStretchMode =='stretch' then
					h = rowSize
				else
					y = alignHandlerY(self.gridLayout.verticalAlignMode, carriagePos, rowSize, h)
				end

				e:draw(x, y, w, h)

				carriagePos = carriagePos + self.gridLayout.rowSpacing + rowSize
				row = row + 1
			end
		end
	elseif autoRows then--flow the elements freely vertically, space columns according to layout
		local carriagePos = 0
		local row = 1
		local colDrawStart = 0

		local currentRowMax = 1

		local currentCol = 1

		local rowWidth

		if equalCols then
			rowWidth = self.gridLayout.columns
		else
			rowWidth = #self.gridLayout.columns
		end
		 

		if children then
			for i, e in ipairs(children) do
				local w, h = e:getSize()
				local colSize
				local x, y

				if equalCols then
					colSize = 1 * horValueToPixels
				else
					colSize = self.gridLayout.columns[currentCol] * horValueToPixels
				end

				currentRowMax = math.max(currentRowMax, h)

				if self.gridLayout.horizontalStretchMode =='stretch' then
					w = colSize
				else
					x = alignHandlerX(self.gridLayout.horizontalAlignMode, colDrawStart, colSize, w)
				end

				e:draw(x, yRoot+carriagePos, w, h)

				colDrawStart = colDrawStart + colSize + self.gridLayout.colSpacing

				if currentCol == rowWidth then
					carriagePos = carriagePos + self.gridLayout.rowSpacing + currentRowMax
					currentCol = 0
					currentRowMax = 0
					colDrawStart = 0
				end
				currentCol = currentCol + 1
			end
		end
	end
end

return grid