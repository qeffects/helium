local path = string.sub(..., 1, string.len(...) - string.len(".hooks.state"))
local context = require(path.. ".core.stack")

---Creates a new 'state' object that will update the current element whenever a field is changed
---Can also assign a callback to be executed whenever a new state is achieved
---@generic T : table
---@param base T
---@return T
return function (base)
	base = base or {}
	local callbacks = {}
	local proxy = {}
	local fakeBase = {
		callback = function(callback)
			table.insert(callbacks, callback)
		end
	}
	local activeContext = context.getContext()
	return setmetatable(proxy,{
			__index = function(t, index)
				local f = fakeBase[index] ~= nil and fakeBase[index] or base[index]
				return f
			end,
			__newindex = function(t, index, val)
				if not (fakeBase[index] == val) then
					fakeBase[index] = val
					activeContext:bubbleUpdate()
					for i, e in ipairs(callbacks) do
						e(t)
					end
				end
			end
		})
end