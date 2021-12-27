local path = string.sub(..., 1, string.len(...) - string.len(".hooks.state"))
local context = require(path.. ".core.stack")

---Creates a new 'state' object that will update the current element whenever a field is changed
---@generic T : table
---@param base T
---@return T
return function (base)
	base = base or {}
	local fakeBase = {}
	local activeContext = context.getContext()
	return setmetatable({},{
			__index = function(t, index)
				local f = fakeBase[index] ~= nil and fakeBase[index] or base[index]
				return f
			end,
			__newindex = function(t, index, val)
				if fakeBase[index] ~= val then
					fakeBase[index] = val
					activeContext:bubbleUpdate()
				end
			end
		})
end