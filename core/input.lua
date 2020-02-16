local path   = string.sub(..., 1, string.len(...) - string.len(".core.input"))
local helium = require(path .. ".dummy")

local input={
	eventHandlers = {},
	subscriptions = {},
	activeEvents  = {}
}
input.__index = input

local dummyfunc = function() end
---@class subscription
local subscription   = {}
subscription.__index = subscription

---@class inputContext
local context   = {}
context.__index = context

local activeContext

--[[Event types
	###SIMPLE EVENTS###
	mousepressed,--press started
	mousereleased,--press released after an event inside started

	mousepressed_outside --mousepressed outside of the subscription
	mousereleased_outside --mousereleased outside of the subscription

	keypressed,--key pressed
	keyreleased,--key released

	###COMPLEX EVENTS###
		dragged,
		clicked,
		hover,


]]
function input.newContext(element)
	local ctx = setmetatable({elem = element, subs = {}, childContexts={}}, context)

	return ctx
end

function context:set()
	if activeContext then
		if not self.parentCtx then
			activeContext.childContexts[#activeContext.childContexts+1] = self
			self.parentCtx = activeContext
		end
		self.absX      = self.parentCtx.absX + self.elem.view.x
		self.absY      = self.parentCtx.absY + self.elem.view.y
		activeContext  = self
	else
		self.absX     = self.elem.view.x
		self.absY     = self.elem.view.y
		activeContext = self
	end
end

function context:update()
	if self.parentCtx then
		self.absX      = self.parentCtx.absX + self.elem.view.x
		self.absY      = self.parentCtx.absY + self.elem.view.y
	end
	for i, e in ipairs(self.childContexts) do
		e:update()
	end
	for i, sub in ipairs(self.subs) do
		sub:contextUpdate(self.absX,self.absY,self)
	end
end

function context:unset()
	if self.parentCtx then
		activeContext = self.parentCtx
	else
		activeContext = nil
	end
end

function context:destroy()
	for i, e in ipairs(self.subs) do
		e:destroy()
	end
	for i, e in ipairs(self.childContexts) do
		e:destroy()
	end
end

---@param x number
---@param y number
---@param w number
---@param h number
---@param eventType string
---@param callback function
---@param doff boolean
---@return subscription
function subscription.create(x, y, w, h, eventType, callback, doff)
	local sub
	if activeContext then
		local wratio,hratio,xratio,yratio
		if x<=1 and x~=0 then
			xratio = x
			x = activeContext.elem.view.w * x
		end
		
		if y<=1 and y~=0 then
			yratio = y
			y = activeContext.elem.view.h * y
		end
		
		if w<=1 and w~=0 then
			wratio = w
			w = activeContext.elem.view.w * w
		end

		if h<=1 and h~=0 then
			hratio = h
			h = activeContext.elem.view.h * h
		end

		sub = setmetatable({
			x         = activeContext.absX + x,
			y         = activeContext.absY + y,
			w         = w,
			h         = h,
			wratio = wratio,
			hratio = hratio,
			xratio = xratio,
			yratio = yratio,
			ix        = x,
			iy        = y,
			eventType = eventType,
			active    = doff or true,
			callback  = callback
		},subscription)

		activeContext.subs[#activeContext.subs+1] = sub
	else
		sub = setmetatable({
			x         = x,
			y         = y,
			w         = w,
			h         = h,
			eventType = eventType,
			active    = doff or true,
			callback  = callback
		},subscription)
	end

	if not input.subscriptions[eventType] then
		input.subscriptions[eventType] = {}
	end

	table.insert(input.subscriptions[eventType],sub)

	return sub
end

function subscription:off()
	self.active = false
end

function subscription:on()
	self.active = true
end

function subscription:destroy()
	self.destroyStat = true
	self.active = false
end

function subscription:contextUpdate(absX, absY,activeContext)
	if self.xratio then
		self.x = absX + activeContext.elem.view.w * self.xratio
	else
		self.x = absX + self.ix
	end
	if self.yratio then
		self.y = absY + activeContext.elem.view.h * self.yratio
	else
		self.y = absY + self.iy
	end
	if self.hratio then
		self.h = activeContext.elem.view.h * self.hratio
	end
	if self.wratio then
		self.w = activeContext.elem.view.w * self.wratio
	end
end

function subscription:update(x, y, w, h)
	self.x = x or self.x
	self.y = y or self.y
	self.w = w or self.w
	self.h = h or self.h
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

input.subscribe = subscription.create

--Since the introduction of the relative subscriptions, there is more utility in ommiting coordinates by default
input.sub = function(eventType, callback, cbOff, x, y, w, h)
	x = x or 0
	y = y or 0
	w = w or 1
	h = h or 1

	subscription.create(x,y,w,h,eventType,callback,cbOff)
end

function input.eventHandlers.mousereleased(x, y, btn)
	local captured = false
	if input.subscriptions.mousereleased then
		for index, sub in ipairs(input.subscriptions.mousereleased) do
			--local succ = sub:checkInside(x, y)

			if sub.active and sub:checkInside(x, y) then -- succ and sub:check
				sub:emit(x, y, btn)
				captured = true
			end

		end
	end
	if input.subscriptions.mousereleased_outside then
		for index, sub in ipairs(input.subscriptions.mousereleased_outside) do
			--local succ = sub:checkOutside(x, y)

			if sub.active and sub:checkOutside(x, y) then -- succ and sub.active then
				sub:emit(x, y, btn)
				captured = true
			end

		end
	end

	if input.subscriptions.clicked then
		for index, sub in ipairs(input.subscriptions.clicked) do
			if sub.currentEvent then
				sub.currentEvent = false
				captured         = true
				if sub.cleanUp then
					sub.cleanUp(x, y, btn)
				end
			end
		end
	end	
	
	if input.subscriptions.dragged then
		for index, sub in ipairs(input.subscriptions.dragged) do
			if sub.currentEvent then
				sub.currentEvent = false
				captured         = true
				if sub.cleanUp then
					sub.cleanUp(x, y)
				end
			end
		end
	end

	return captured
end



function input.eventHandlers.mousepressed(x, y, btn)
	local captured = false
	if input.subscriptions.mousepressed then
		for index, sub in ipairs(input.subscriptions.mousepressed) do
			--local succ = sub:checkInside(x, y)

			if sub.active and sub:checkInside(x, y) then -- succ and sub:check
				sub:emit(x, y, btn)
				captured = true
			end

		end
	end
	if input.subscriptions.mousepressed_outside then
		for index, sub in ipairs(input.subscriptions.mousepressed_outside) do
			--local succ = sub:checkOutside(x, y)

			if sub.active and sub:checkOutside(x, y) then -- succ and sub.active then
				sub:emit(x, y, btn)
				captured = true
			end

		end
	end
	if input.subscriptions.clicked then
		for index, sub in ipairs(input.subscriptions.clicked) do
			local succ = sub:checkInside(x, y)

			if succ and sub.active then
				sub.cleanUp      = sub:emit(x, y, btn) or dummyfunc
				sub.currentEvent = true
				captured         = true
			end

		end
	end
	
	if input.subscriptions.dragged then
		for index, sub in ipairs(input.subscriptions.dragged) do
			--local succ = sub:checkInside(x, y)

			if sub.active and sub:checkInside(x, y) then -- succ and sub:check
				sub.currentEvent = true
				captured         = true
			end

		end
	end

	return captured
end

function input.eventHandlers.keypressed(btn)
	local captured = false
	if input.subscriptions.keypressed then
		for index, sub in ipairs(input.subscriptions.keypressed) do
			if sub.active then -- ==true then
				sub:emit( btn)
				captured = true
			end

		end
	end

	return captured
end

function input.eventHandlers.keyreleased(btn)
	local captured = false
	if input.subscriptions.keyreleased then
		for index, sub in ipairs(input.subscriptions.keyreleased) do
			if sub.active then
				sub:emit(btn)
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

			if sub.active and not sub.currentEvent and succ then
				sub.cleanUp      = sub:emit(x, y) or dummyfunc
				sub.currentEvent = true
				captured         = true
			elseif sub.currentEvent and not succ then
				sub.currentEvent = false
				captured         = true
				if sub.cleanUp then
					sub.cleanUp(x, y)
				end
			end
		end
	end

	
	if input.subscriptions.dragged then
		for index, sub in ipairs(input.subscriptions.dragged) do
			if sub.active and sub.currentEvent then
				if not sub.cleanUp then
					sub.cleanUp  = sub:emit(x, y, dx, dy) or dummyfunc
				else
					sub:emit(x, y, dx, dy)
				end
				--sub.currentEvent = true -- checked in the condition so must be true
				captured         = true
			end

		end
	end

	return captured
end

return input