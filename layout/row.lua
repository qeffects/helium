local path   = string.sub(..., 1, string.len(...) - string.len(".row"))
local layout = require(path..'.layout')

---@class Row
local row = {}
row.__index = row

---@return layout
function row.new()
	local self = setmetatable({}, row)
	
	return layout(self, self.draw)
end

function row:draw(x, y, width, height, children, hpad, vpad, alignX)
	local carriagePos = 0
	if children then
		for i, e in ipairs(children) do
			local w, _ = e:getSize()
			e:draw(x+carriagePos, y+vpad)
			carriagePos = carriagePos + w + hpad
		end
	end
end

return row
