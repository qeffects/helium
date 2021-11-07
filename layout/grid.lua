--my copy of the cssssss grids
local path   = string.sub(..., 1, string.len(...) - string.len(".grid"))
local layout = require(path..'.layout')

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
	colSpacing = 20,
	rowSpacing = 20,
	verticalStretchMode = 'stretch',
	horizontalStretchMode = 'stretch',
	verticalAlignMode = 'center',
	horizontalAlignMode = 'center',
	rows = {5,5},
	columns = {1,3,1},
	layout = {
		{'sidebar','content','sidebar2'},
		{'sidebar','content','sidebar2'},
	}
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

function grid:draw(xRoot, yRoot, width, height, children)
	-- Either of these means no named layout
	local fullyAutoLayout = false
	local autoCols = false
	local autoRows = false
	local equalRows = false
	local equalCols = false

	local vertValueToPixels = 0
	local horValueToPixels = 0

	local XIndexes = {}
	local YIndexes = {}

	if self.gridLayout.columns then
		if not self.gridLayout.rows then
			autoRows = true
		else
			if type(self.gridLayout.rows)=="table" then
				local total = 0
				
				for i, col in ipairs(self.gridLayout.rows) do
					YIndexes[i] = {}

					YIndexes[i].start = total
					total = total + col
					YIndexes[i].finish = total
				end
				
				vertValueToPixels = height/total
			else
				vertValueToPixels = height/self.gridLayout.rows
				
				for y = 1, self.gridLayout.rows do
					YIndexes[y] = {}
					YIndexes[y].start = y-1
					YIndexes[y].finish = y
				end
				
				equalRows = true
			end
		end
		if type(self.gridLayout.columns)=="table" then
			local total = 0
			
			for i, col in ipairs(self.gridLayout.columns) do
				XIndexes[i] = {}

				XIndexes[i].start = total
				total = total + col
				XIndexes[i].finish = total
			end
			
			horValueToPixels = width/total
		else
			horValueToPixels = width/self.gridLayout.columns

			for x = 1, self.gridLayout.columns do
				XIndexes[x] = {}
				XIndexes[x].start = x-1
				XIndexes[x].finish = x
			end

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
				
				vertValueToPixels = (height)/total
			else
				vertValueToPixels = (height)/self.gridLayout.rows
				equalRows = true
			end
		end
	end

	if (not autoRows) and (not autoCols) then

		if self.gridLayout.layout then
			local layout = {}
			--flip layout table
			for x = 1, #self.gridLayout.layout[1] do
				layout[x] = {}
			end 

			for x = 1, #self.gridLayout.layout do
				for y = 1, #self.gridLayout.layout[x] do
					layout[y][x] = self.gridLayout.layout[x][y]
				end 
			end

			local layoutDepth, layoutWidth = #self.gridLayout.layout, #layout
			if type(self.gridLayout.rows) == "table" then
				if not #self.gridLayout.rows == layoutDepth then
					error('Layout table doesnt match row number')
				end
			else
				if not self.gridLayout.rows == layoutDepth then
					error('Layout table doesnt match row number')
				end
			end
			if type(self.gridLayout.columns) == "table" then
				if not #self.gridLayout.columns == layoutWidth then
					error('Layout table doesnt match column number')
				end
			else
				if not self.gridLayout.columns == layoutWidth then
					error('Layout table doesnt match column number')
				end
			end
			-- {x, y, width, height}
			local fields = {

			}

			for x = 1, #layout do
				for y = 1, #layout[x] do
					if not fields[layout[x][y]] then	
						local finishedRow = false
						local finishedCol = false
						local curField = layout[x][y]
						fields[curField] = {}

						fields[curField].x = XIndexes[x].start
						fields[curField].y = YIndexes[y].start
						fields[curField].finX = XIndexes[x].finish
						fields[curField].finY = YIndexes[y].finish

						local parseX, parseY = x+1, y+1
						while not finishedRow do
							if layout[x][parseY] and layout[x][parseY] == curField then
								fields[curField].finY = YIndexes[parseY].finish
							else
								finishedRow = true
							end
							parseY = parseY + 1
						end

						while not finishedCol do
							if layout[parseX] and layout[parseX][y] == curField then
								fields[curField].finX = XIndexes[parseX].finish
							else
								finishedCol = true
							end
							parseX = parseX + 1
						end

						fields[curField].h = fields[curField].finY - fields[curField].y
						fields[curField].w = fields[curField].finX - fields[curField].x
					end
				end
			end

			for i, field in pairs(fields) do
				for y, elem in ipairs(children) do
					if elem.flags[i] then
						field.element = elem
					end
				end
			end

			for i, field in pairs(fields) do
				if field.element then
					local containerWidth = (field.w*horValueToPixels)-(self.gridLayout.colSpacing)
					local containerHeight = (field.h*vertValueToPixels)-(self.gridLayout.rowSpacing)

					local containerX = ((field.x)*horValueToPixels)+(self.gridLayout.colSpacing/2)
					local containerY = ((field.y)*vertValueToPixels)+(self.gridLayout.rowSpacing/2)

					local w, h = field.element:getSize()
					local x, y 

					if self.gridLayout.horizontalStretchMode =='stretch' then
						w = containerWidth
						x = containerX
					else
						x = alignHandlerX(self.gridLayout.horizontalAlignMode, containerX, containerWidth, w)
					end

					if self.gridLayout.verticalStretchMode =='stretch' then
						h = containerHeight
						y = containerY
					else
						y = alignHandlerY(self.gridLayout.verticalAlignMode, containerY, containerHeight, h)
					end

					field.element:draw(x+xRoot, y+yRoot, w, h)
				end
			end
		else
			error('please provide a layout table')
		end
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
					x = xRoot
				else
					x = alignHandlerX(self.gridLayout.horizontalAlignMode, xRoot, width, w)
				end

				if self.gridLayout.verticalStretchMode =='stretch' then
					h = rowSize
					y = carriagePos
				else
					y = alignHandlerY(self.gridLayout.verticalAlignMode, carriagePos, rowSize, h)
				end

				e:draw(x, y + yRoot, w, h)

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
					x = colDrawStart
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
