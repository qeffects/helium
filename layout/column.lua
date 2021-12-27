local path   = string.sub(..., 1, string.len(...) - string.len(".column"))
local layout = require(path..'.layout')
---@class Column
local column = {}
column.__index = column

---@return layout
function column.new()
	local self = setmetatable({}, column)
	
	return layout(self, self.draw)
end

function column:draw(x, y, width, height, children, hpad, vpad, alignX)
	local carriagePos = 0
	if children then
		for i, e in ipairs(children) do
			local _, h = e:getSize()
			e:draw(x, y+carriagePos+vpad)
			carriagePos = carriagePos + h + vpad
		end
	end
end

return column