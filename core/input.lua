--[[--------------------------------------------------
	Helium UI by qfx (qfluxstudios@gmail.com)
	Copyright (c) 2021 Elmārs Āboliņš
	https://github.com/qeffects/helium
----------------------------------------------------]]
local path   = string.sub(..., 1, string.len(...) - string.len(".core.input"))
local stack = require(path .. ".core.stack")
local helium = require(path .. ".dummy")

local input = {
	eventHandlers = {},
	subscriptions = setmetatable({}, {__index = function (t, index)
		return helium.scene.activeScene and helium.scene.activeScene.subscriptions[index] or nil
	end,
	__newindex = function(t, index, val)
		helium.scene.activeScene.subscriptions[index] = val
	end}),
	activeEvents  = {}
}
input.__index = input

--Middle man functions
local orig = {
	mousepressed = love.handlers['mousepressed'],
	mousereleased = love.handlers['mousereleased'],
	textinput = love.handlers['textinput'],
	keypressed = love.handlers['keypressed'],
	keyreleased = love.handlers['keyreleased'],
	mousemoved = love.handlers['mousemoved']
}
if helium.conf.AUTO_INPUT_SUB then
	love.handlers['mousepressed'] = function(x, y, btn, d, e, f)
		if not input.eventHandlers.mousepressed(x, y, btn, d, e ,f) then
			orig.mousepressed(x, y, btn, d, e, f)
		end
	end
	love.handlers['mousereleased'] = function(x, y, btn, d, e, f)
		if not input.eventHandlers.mousereleased(x, y, btn, d, e ,f) then
			orig.mousereleased(x, y, btn, d, e, f)
		end
	end
	love.handlers['keypressed'] = function(key, b, c, d, e, f)
		if not input.eventHandlers.keypressed(key, b, c, d, e, f) then
			orig.keypressed(key, b, c, d, e, f)
		end
	end
	love.handlers['keyreleased'] = function(key, b, c, d, e, f)
		if not input.eventHandlers.keyreleased(key, b, c, d, e, f) then
			orig.keyreleased(key, b, c, d, e, f)
		end
	end
	love.handlers['textinput'] = function(text, b, c, d, e, f)
		if not input.eventHandlers.textinput(text, b, c, d, e, f) then
			orig.textinput(text, b, c, d, e, f)
		end
	end
	love.handlers['mousemoved'] = function(x, y, dx, dy, e, f)
		if not input.eventHandlers.mousemoved(x, y, dx, dy, e, f) then
			orig.mousemoved(x, y, dx, dy, e, f)
		end
	end
	love.handlers['filedropped'] = function(file, y, dx, dy, e, f)
		if not input.eventHandlers.filedropped(file, y, dx, dy, e, f) then
			orig.filedropped(file, y, dx, dy, e, f)
		end
	end
end

local function sortFunc(t1, t2)
	if t1 == t2 then
		return false
	end
	return t1.stack.temporalZ.z > t2.stack.temporalZ.z
end 

function input.sortZ()
	for i, subs in pairs(input.subscriptions) do
		table.sort(subs, sortFunc)
	end
end

local dummyfunc = function() end
---@class subscription
local subscription   = {}
subscription.__index = subscription

function input.unload()
	input.subscriptions = {}
	input.activeEvents = {}
end

--[[Event types
	###SIMPLE EVENTS###
	mousepressed,--press started
	mousereleased,--press released after an event inside started

	mousepressed_outside --mousepressed outside of the subscription
	mousereleased_outside --mousereleased outside of the subscription

	keypressed,--key pressed
	keyreleased,--key released

	textinput, --same as love

	###COMPLEX EVENTS###
		dragged,
		clicked,
		hover,


]]
---@param x number
---@param y number
---@param w number
---@param h number
---@param eventType string
---@param callback function
---@param doff boolean
---@return subscription
function subscription.create(x, y, w, h, eventType, callback, doff)
	local stack = stack.getContext()
	local xn, yn = stack:normalizePos(x, y)
	local wn, hn = stack:normalizeSize(w, h)

	local sub = setmetatable({
		x         = xn,
		y         = yn,
		w         = wn,
		h         = hn,
		origX     = x,
		origY     = y,
		origW     = w,
		origH     = h,
		eventType = eventType,
		active    = true,
		stack     = stack,
		callback  = callback
	},subscription)

	sub.onSizeChange = stack:onSizeChange(function()
		sub.w, sub.h = sub.stack:normalizeSize(sub.origW, sub.origH)
	end)
	
	sub.onPosChange = stack:onPosChange(function()
		sub.x, sub.y = sub.stack:normalizePos(sub.origX, sub.origY)
	end)

	if doff == false then
		sub:off()
	end

	if not input.subscriptions[eventType] then
		input.subscriptions[eventType] = {}
	end

	table.insert(input.subscriptions[eventType], 1, sub)

	input.sortZ()

	return sub
end

function subscription:off()
	self.active = false
end

function subscription:on()
	self.active = true
end

function subscription:remove()
	--input.subscriptions[self.eventType][self] = nil
	input.sortZ()
end

function subscription:emit(...)
	return self.callback(...)
end

function subscription:checkInside(x, y)
	return x>self.x and x<self.x+self.w and y>self.y and y<self.y+self.h
end

function subscription:checkOutside(x, y)
	return not (x>self.x and x<self.x+self.w and y>self.y and y<self.y+self.h)
end

---@alias InputMouseClickSubscriptionCallback fun(x:number, y:number, mouseButton:string)
---@alias InputMouseClickComplexSubscriptionCallback fun(x:number, y:number, mouseButton:string):fun(x:number, y:number)|nil
---@alias InputMouseMoveComplexSubscriptionCallback fun(x:number, y:number, dx:number, dy:number):fun(x:number, y:number)|nil
---@alias InputKeyPressSubscriptionCallback fun(key:KeyConstant|string, scancode:Scancode|string)
---@alias InputTextInputSubscriptionCallback fun(text:string)

input.subscribe = subscription.create
---@overload fun(self:any, eventType: "'mousepressed'"|"'mousereleased'"|"'mousepressed_outside'"|"'mousereleased_outside'", callback: InputMouseClickSubscriptionCallback, cbOff: boolean, x: number|nil, y:number|nil, w: number|nil, h:number|nil)
---@overload fun(self:any, eventType: "'clicked'", callback: InputMouseClickComplexSubscriptionCallback, cbOff: boolean, x:number|nil, y:number|nil, w:number|nil, h:number|nil)
---@overload fun(self:any, eventType: "'hover'"|"'dragged'", callback: InputMouseMoveComplexSubscriptionCallback, cbOff: boolean, x:number|nil, y:number|nil, w:number|nil, h:number|nil)
---@overload fun(self:any, eventType: "'keypressed'"|"'keyreleased'", callback: InputKeyPressSubscriptionCallback, cbOff: boolean)
---@overload fun(self:any, eventType: "'textinput'", callback: InputTextInputSubscriptionCallback, cbOff: boolean)
input.__call = function(self, eventType, callback, cbOff, x, y, w, h)
	x = x or 0
	y = y or 0
	w = w or 1
	h = h or 1
	
	return subscription.create(x,y,w,h,eventType,callback,cbOff)
end

--Since the introduction of the relative subscriptions, there is more utility in ommiting coordinates by default
setmetatable(input, input)

function input.eventHandlers.mousereleased(x, y, btn)
	local captured = false
	if input.subscriptions.clicked then
		for index, sub in ipairs(input.subscriptions.clicked) do
			if sub.currentEvent and sub.active and sub.stack.element.settings.active then
				sub.currentEvent = false
				captured         = true
				if sub.cleanUp then
					sub.cleanUp(x-sub.x, y-sub.y, btn)
				end
			end
		end
	end	
	
	if input.subscriptions.dragged then
		for index, sub in ipairs(input.subscriptions.dragged) do
			if sub.currentEvent and sub.active and sub.stack.element.settings.active then
				sub.currentEvent = false
				captured         = true
				if sub.cleanUp then
					sub.cleanUp(x-sub.x, y-sub.y)
				end
			end
		end
	end

	if input.subscriptions.mousereleased then
		for index, sub in ipairs(input.subscriptions.mousereleased) do
			if sub.active and sub.stack.element.settings.active and sub:checkInside(x, y) then
				sub:emit(x-sub.x, y-sub.y, btn)
				captured = true
			end

		end
	end

	if input.subscriptions.mousereleased_outside then
		for index, sub in ipairs(input.subscriptions.mousereleased_outside) do
			if sub.active and sub.stack.element.settings.active and sub:checkOutside(x, y) then
				sub:emit(x-sub.x, y-sub.y, btn)
				captured = true
			end

		end
	end

	return captured
end

function input.eventHandlers.mousepressed(x, y, btn)
	local captured = false

	if input.subscriptions.clicked then
		for index, sub in ipairs(input.subscriptions.clicked) do
			local succ = sub:checkInside(x, y)

			if succ and sub.active and sub.stack.element.settings.active then
				sub.cleanUp      = sub:emit(x-sub.x, y-sub.y, btn) or dummyfunc
				sub.currentEvent = true
				return true
			end

		end
	end
	
	if input.subscriptions.dragged then
		for index, sub in ipairs(input.subscriptions.dragged) do
			if sub.active and sub.stack.element.settings.active and sub:checkInside(x, y) then 
				sub.currentEvent = true
				return true
			end

		end
	end

	if input.subscriptions.mousepressed then
		for index, sub in ipairs(input.subscriptions.mousepressed) do
			if sub.active and sub.stack.element.settings.active and sub:checkInside(x, y) then 
				sub:emit(x-sub.x, y-sub.y, btn)
				return true
			end

		end
	end

	if input.subscriptions.mousepressed_outside then
		for index, sub in ipairs(input.subscriptions.mousepressed_outside) do
			if sub.active and sub.stack.element.settings.active and sub:checkOutside(x, y) then
				sub:emit(x-sub.x, y-sub.y, btn)
				return true
			end

		end
	end
	return captured
end

function input.eventHandlers.keypressed(btn, btncode)
	local captured = false
	if input.subscriptions.keypressed then
		for index, sub in ipairs(input.subscriptions.keypressed) do
			if sub.active and sub.stack.element.settings.active then
				sub:emit(btn, btncode)
				captured = true
			end

		end
	end

	return captured
end

function input.eventHandlers.filedropped(file)
	local captured = false
	if input.subscriptions.filedropped then
		for index, sub in ipairs(input.subscriptions.filedropped) do
			if sub.active and sub.stack.element.settings.active then
				sub:emit(file)
				captured = true
			end

		end
	end

	return captured
end

function input.eventHandlers.keyreleased(btn, btncode)
	local captured = false
	if input.subscriptions.keyreleased then
		for index, sub in ipairs(input.subscriptions.keyreleased) do
			if sub.active and sub.stack.element.settings.active then
				sub:emit(btn, btncode)
				captured = true
			end
		end
	end

	return captured
end

function input.eventHandlers.textinput(text)
	local captured = false
	if input.subscriptions.textinput then
		for index, sub in ipairs(input.subscriptions.textinput) do
			if sub.active and sub.stack.element.settings.active then
				sub:emit(text)
				captured = true
			end
		end
	end

	return captured
end

function input.eventHandlers.mousemoved(x, y, dx, dy)
	local captured = false

	if input.subscriptions.hover then
		for index, sub in ipairs(input.subscriptions.hover) do
			local succ = sub:checkInside(x, y)

			if sub.active and sub.stack.element.settings.active and not sub.currentEvent and succ then
				sub.cleanUp      = sub:emit(x-sub.x, y-sub.y, dx, dy) or dummyfunc
				sub.currentEvent = true
				return true
			elseif sub.currentEvent and not succ then
				sub.currentEvent = false
				if sub.cleanUp then
					sub.cleanUp(x-sub.x, y-sub.y)
				end
				return true
			end
		end
	end

	
	if input.subscriptions.dragged then
		for index, sub in ipairs(input.subscriptions.dragged) do
			if sub.active and sub.stack.element.settings.active and sub.currentEvent then
				if not sub.cleanUp then
					sub.cleanUp  = sub:emit(x-sub.x, y-sub.y, dx, dy) or dummyfunc
				else
					sub:emit(x-sub.x, y-sub.y, dx, dy)
				end

				return true
			end

		end
	end

	return captured
end

--Typescript
input.default = input
return input