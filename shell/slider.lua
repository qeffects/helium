local path = string.sub(..., 1, string.len(...) - string.len(".shell.button"))
local state = require(path.. ".hooks.state")
local input = require(path.. ".core.input")

local function clamp(num, min, max)
	local min, max = min or 0, max or 1
	return math.max(math.min(num, 1), 0)
end

local function round(num)
	return math.floor(num+0.5)
end

local function calcPercent(min, val, max)
	return clamp((val-min)/(max - min))
end

local function mapToValueRange(pct, minVal, maxVal, divider)
	return (round(((maxVal-minVal)*pct) / divider) * divider)+minVal
end

local function mapCoordToVal(minCoord, maxCoord, minVal, maxVal, divider, coord)
	return mapToValueRange(calcPercent(minCoord, coord, maxCoord), minVal, maxVal, divider)
end

---@class SliderValuesTable
---@field value number @Starting value of the slider
---@field divider number @The divider (rounding) for your slider
---@field min number @The minimum slider number
---@field max number @The maximum slider number

---@class SliderStateTable
---@field value number @Current value of the slider
---@field divisions number @Current divisions of the slider
---@field min number @Min value of the slider
---@field max number @Max value of the slider

---@class HandleStateTable
---@field down boolean @Whether the mouse is pressing the handle
---@field over boolean @Whether the mouse is over the handle
---@field x number @X position of the handle
---@field y number @Y position of the handle

---Sets up a slider for your element
---@param values SliderValuesTable
---@param w number
---@param h number
---@param onChange fun(sliderValue:number)
---@param onFinish fun(sliderValue:number)
---@param onClick fun()
---@param onRelease fun()
---@param onEnter fun()
---@param onExit fun()
---@param x any
---@param y any
---@return SliderStateTable
---@return HandleStateTable
return function(values, w, h, onChange, onFinish, onClick, onRelease, onEnter, onExit, x, y)
	local vertical = h > w
	local originx, originy = x or 0, y or 0
	local slider = state {
		value = values.value or ((values.max - values.min)/2)+values.min or 0,
		divisions = values.divider or 1,
		min = values.min or 0,
		max = values.max or values.value or 0,
	}
	local handle = state {
		x = 0,
		y = 0,
		over = false,
		down = false,
	}

	if vertical then
		handle.y = calcPercent(slider.min, slider.value, slider.max) * h + originy
	else
		handle.x = calcPercent(slider.min, slider.value, slider.max) * w + originx
	end

	input('dragged', function(x, y, dx, dy)
		if vertical then
			slider.value = mapCoordToVal(originy, h, slider.min, slider.max, slider.divisions, y)
			handle.y = calcPercent(slider.min, slider.value, slider.max) * h + originy
		else
			slider.value = mapCoordToVal(originx, w, slider.min, slider.max, slider.divisions, x)
			handle.x = calcPercent(slider.min, slider.value, slider.max) * w + originx
		end

		if onChange then
			onChange(slider.value)
		end

		handle.down = true

		return function(x, y)
			handle.down = false
			if vertical then
				slider.value = mapCoordToVal(originy, h, slider.min, slider.max, slider.divisions, y)
				handle.y = calcPercent(slider.min, slider.value, slider.max) * h + originy
			else
				slider.value = mapCoordToVal(originx, w, slider.min, slider.max, slider.divisions, x)
				handle.x = calcPercent(slider.min, slider.value, slider.max) * w + originx
			end

			if onFinish then
				onFinish(slider.value)
			end
		end
	end, nil, originx, originy )


	input('hover', function(x, y, w, h) 
		if onEnter then
			onEnter(x, y, w, h)
		end

		handle.over = true

		return function(x, y, w, h)
			if onExit then
				onExit(x, y, w, h)
			end

			handle.over = false
		end
	end, nil, originx, originy )

	return slider, handle
end