local path = string.sub(..., 1, string.len(...) - string.len(".shell.input"))
local state = require(path.. ".hooks.state")
local input = require(path.. ".core.input")
local utf8 = require("utf8")

---@class textState
---@param focused boolean @indicates whether this element is currently focused
---@param text string @current state of the input string
---@param over boolean @indicates whether the mouse is over this field

---Textinput element wrapper
---@param onChange function|nil
---@param onFinish function|nil
---@param startStr function|nil
---@param onEnter function|nil
---@param onExit function|nil
---@param x number|nil
---@param y number|nil
---@param w number|nil
---@param h number|nil
---@return textState
return function(onChange, onFinish, startStr, onEnter, onExit, x, y, w, h)
	local textState = state {
		focused = false,
		text = startStr or '',
		over = false
	}
	local keyInput, textInput

	keyInput = input('keypressed', function(key)
		if key == 'backspace' then
			local byteoffset = utf8.offset(textState.text, -1)

			if byteoffset then
				textState.text = string.sub(textState.text, 1, byteoffset - 1)
			end

			if onChange then
				onChange(textState.text)
			end
		end
		if key == 'return' then
			textState.focused = false
			keyInput:off()
			textInput:off()
			if onFinish then
				onFinish(textState.text)
			end
		end
	end, false)

	textInput = input('textinput', function(text)
		textState.text = textState.text .. text
		if onChange then
			onChange(textState.text)
		end
	end, false)

	input('mousepressed', function()
		textState.focused = true
		keyInput:on()
		textInput:on()
	end)

	input('mousepressed_outside', function()
		textState.focused = false
		keyInput:off()
		textInput:off()
		if onFinish then
			onFinish(textState.text)
		end
	end)

	input('hover', function(x, y, w, h) 
		if onEnter then
			onEnter(x, y, w, h)
		end

		textState.over = true

		return function(x, y, w, h)
			if onExit then
				onExit(x, y, w, h)
			end

			textState.over = false
		end
	end)

	return textState
end