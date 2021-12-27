local path = string.sub(..., 1, string.len(...) - string.len(".hooks.context"))
local context = require(path.. ".core.stack")

local c = {}

---Creates a context, that will be available to ALL nodes below this element
---@param name string the name of this context to be referenced later
---@param base table the table to be used as the base of this new context
---@return table
function c.use(name, base)
	base = base or {}
	local fakeBase = {}
	local activeContext = context.getContext()
	local indexMappings = {}

	local ctx = setmetatable({},{
		__index = function(t, index)
			--Capturing contexts where this index is used
			if not indexMappings[index] then
				indexMappings[index] = {}
			end

			local c = context.getContext()
			indexMappings[index][c] = c
			
			return fakeBase[index] or base[index]
		end,
		__newindex = function(t, index, val)
			if fakeBase[index] ~= val then
				if indexMappings[index] then
					for i, cctx in pairs(indexMappings[index]) do
						cctx:bubbleUpdate()
					end
				end
				fakeBase[index] = val
				activeContext:bubbleUpdate()
			end
		end
	})
	
	activeContext.attachedState[name] = ctx

	return ctx
end

---Gets the context with 'name', if it was initialized
---@param name string
---@return table|nil
function c.get(name)
	local activeContext = context.getContext()

	return activeContext:findAttachedState(name)
end

return c