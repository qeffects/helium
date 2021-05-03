local path = string.sub(..., 1, string.len(...) - string.len(".shell.button"))
local state = require(path.. ".hooks.state")
local input = require(path.. ".core.input")

return function(onClick, onRelease, onEnter, onExit, startOn, x, y, w, h)
	local checkbox = state {
		down = false,
		toggled = not not startOn,
		over = false,
	}
	input('clicked', function(x, y, w, h)
		if onClick then
			onClick(x, y, w, h)
		end

		checkbox.down = true
		
		return function(x, y, w, h)
			if onRelease then
				onRelease(x, y, w, h)
			end
			checkbox.toggled = not checkbox.toggled
			checkbox.down = false
		end
	end)

	input('hover', function(x, y, w, h) 
		if onEnter then
			onEnter(x, y, w, h)
		end

		checkbox.over = true

		return function(x, y, w, h)
			if onExit then
				onExit(x, y, w, h)
			end

			checkbox.over = false
		end
	end)

	return checkbox
end