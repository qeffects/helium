local path = string.sub(..., 1, string.len(...) - string.len(".shell.button"))
local state = require(path.. ".control.state")
local input = require(path.. ".core.input")

return function(onClick, onRelease, onEnter, onExit, x, y, w, h)
	local button = {}
	input('clicked')

	return button
end