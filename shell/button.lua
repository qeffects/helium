local path = string.sub(..., 1, string.len(...) - string.len(".shell.button"))
local state = require(path.. ".hooks.state")
local input = require(path.. ".core.input")

---@class buttonState
---@param down boolean @indicates whether this element is currently being pressed
---@param over boolean @indicates whether the mouse is over this button

---Creates a simple button wrapper, sets up all the callbacks and state for you
---@param onClick function|nil
---@param onRelease function|nil
---@param onEnter function|nil
---@param onExit function|nil
---@param x number|nil
---@param y number|nil
---@param w number|nil
---@param h number|nil
---@return buttonState
return function(onClick, onRelease, onEnter, onExit, x, y, w, h)
	local button = state {
		down = false,
		over = false,
	}
	input('clicked', function(x, y, w, h)
		if onClick then
			onClick(x, y, w, h)
		end

		button.down = true
		
		return function(x, y, w, h)
			if onRelease then
				onRelease(x, y, w, h)
			end
			button.down = false
		end
	end)

	input('hover', function(x, y, w, h) 
		if onEnter then
			onEnter(x, y, w, h)
		end

		button.over = true

		return function(x, y, w, h)
			if onExit then
				onExit(x, y, w, h)
			end

			button.over = false
		end
	end)

	return button
end