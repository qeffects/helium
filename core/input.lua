local path   = string.sub(..., 1, string.len(...) - string.len(".core.input"))
local helium = require(path .. ".dummy")

local input={
	eventHandlers = {},
	subscriptions = {},
	activeEvents  = {}
}
input.__index = input

local windowMachine = {}
windowMachine.__index = windowMachine
local windowCurrent = false

--Go forward
windowMachine.push = function(window)
	windowMachine[#windowMachine+1] = window
	windowCurrent = #windowMachine
end

--Go a level back
windowMachine.pop = function()
	windowMachine[#windowMachine] = nil
	if windowCurrent>1 then
		windowCurrent = windowCurrent-1
	else
		windowCurrent = false
	end
end

windowMachine.get = function()
	if windowCurrent then
		return windowMachine[windowCurrent]
	end
end

local activeWindow
local windowStack = {}

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
	self.activeWindow = windowMachine.get()

	if activeContext and activeContext~=self then
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
	else
		self.absX = self.elem.view.x
		self.absY = self.elem.view.y
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

function context:afterLoad()
	--If i created window, pop it
	if self.window then 
		windowMachine.pop()
	end
end

function context:unsuspend()
	for i, e in ipairs(self.subs) do
		e:unsuspend()
	end
	for i, e in ipairs(self.childContexts) do
		e:unsuspend()
	end
end

function context:suspend()
	for i, e in ipairs(self.subs) do
		e:suspend()
	end
	for i, e in ipairs(self.childContexts) do
		e:suspend()
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
			active    = true,
			callback  = callback
		},subscription)

		if doff == false then
			sub:off()
		end

		if activeContext.window or activeContext.activeWindow then
			sub.parentWindow = activeContext.window or activeContext.activeWindow
		end
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

	input.subscriptions[eventType][#input.subscriptions[eventType]+1] = sub

	return sub
end

function subscription:off()
	self.active = false
end

function subscription:on()
	self.active = true
end

function subscription:suspend()
	self.destroyStat = true
	self.preActive = self.active
	self.active = false
end

function subscription:unsuspend()
	self.active = self.preActive
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
---@param eventType string
---@param callback function
---@param cbOff boolean
---@param x number
---@param y number
---@param w number
---@param h number
input.__call = function(self, eventType, callback, cbOff, x, y, w, h)
	x = x or 0
	y = y or 0
	w = w or 1
	h = h or 1
	
	return subscription.create(x,y,w,h,eventType,callback,cbOff)
end

--Will block ui clicks from going through it
input.window = function(x,y,w,h)
	x = x or 0
	y = y or 0
	w = w or 1
	h = h or 1

	activeContext.window = subscription.create(x,y,w,h,'window',nil,false)
	windowMachine.push(activeContext.window)
	windowStack[#windowStack+1] = activeContext.window
	return activeContext.window
end

--Run once per applicable event
--The windows should be basically pre sorted, so if something is a hit on a lower window
--And is on a higher one too, the lower one is discarded 
local hits = {}
input.checkWindows = function(x,y)
	local hit = false
	for i = 1, #windowStack do
		if windowStack[i]:checkInside(x,y) and windowStack[i].active then
			hit = windowStack[i]
		end
	end
	--Returns latest hit
	return hit
end

--Run per sub
function input.checkSub(sub,hit)
	if sub.parentWindow and sub.parentWindow == hit then
		return true
	elseif not hit then
		return true
	end
	return false
end

--Since the introduction of the relative subscriptions, there is more utility in ommiting coordinates by default
setmetatable(input, input)

function input.eventHandlers.mousereleased(x, y, btn)
	local captured = false
	local hit = input.checkWindows(x, y)
	if input.subscriptions.mousereleased then
		for index, sub in ipairs(input.subscriptions.mousereleased) do
			--local succ = sub:checkInside(x, y)

			if sub.active and sub:checkInside(x, y) and input.checkSub(sub,hit) then -- succ and sub:check
				sub:emit(x, y, btn)
				captured = true
			end

		end
	end
	if input.subscriptions.mousereleased_outside then
		for index, sub in ipairs(input.subscriptions.mousereleased_outside) do
			--local succ = sub:checkOutside(x, y)

			if sub.active and sub:checkOutside(x, y) and input.checkSub(sub,hit) then -- succ and sub.active then
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
	local hit = input.checkWindows(x, y)
	if input.subscriptions.mousepressed then
		for index, sub in ipairs(input.subscriptions.mousepressed) do
			--local succ = sub:checkInside(x, y)

			if sub.active and sub:checkInside(x, y) and input.checkSub(sub,hit) then -- succ and sub:check
				sub:emit(x, y, btn)
				captured = true
			end

		end
	end
	if input.subscriptions.mousepressed_outside then
		for index, sub in ipairs(input.subscriptions.mousepressed_outside) do
			--local succ = sub:checkOutside(x, y)

			if sub.active and sub:checkOutside(x, y) and input.checkSub(sub,hit) then -- succ and sub.active then
				sub:emit(x, y, btn)
				captured = true
			end

		end
	end
	if input.subscriptions.clicked then
		for index, sub in ipairs(input.subscriptions.clicked) do
			local succ = sub:checkInside(x, y)

			if succ and sub.active and input.checkSub(sub,hit) then
				sub.cleanUp      = sub:emit(x, y, btn) or dummyfunc
				sub.currentEvent = true
				captured         = true
			end

		end
	end
	
	if input.subscriptions.dragged then
		for index, sub in ipairs(input.subscriptions.dragged) do
			--local succ = sub:checkInside(x, y)

			if sub.active and sub:checkInside(x, y) and input.checkSub(sub,hit) then -- succ and sub:check
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
				sub.cleanUp      = sub:emit(x, y, dx, dy) or dummyfunc
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

--Typescript
input.default = input
return input