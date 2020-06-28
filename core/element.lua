--[[ Element superclass ]]
--[[ Love is currently a hard dependency, although not in many places ]]
local path = string.sub(..., 1, string.len(...) - string.len(".core.element"))
local helium = require(path .. ".dummy")
local context = require(path.. ".core.stack")

---@class element
local element = {}
element.__index = element

local type,pcall = type,pcall
setmetatable(element, {
		__call = function(cls, ...)
			local self
			local func, loader, w, h, param = ...
			
			self = setmetatable({}, element)
			self.parentFunc = func

			if loader then
				local function f(newFunc)
					self:reLoader(newFunc)
				end
				loader(f)
			end

			self:new(w, h, param)

			return self
		end
	})

--Control functions
--The new function that should be used for element creation
function element:new(param)
	local dimensions
	--save the parameters
	self.parameters = {}

	--The element canvas
	self.baseParams = param

	--Internal settings
	self.settings = {
		isSetup              = false,
		pendingUpdate        = true,
		needsRendering       = true,
		--Unused for now?
		calculatedDimensions = true,
		--Is this the first render
		firstDraw            = true,
		--Stabilize the internal canvas, draw it twice on first load
		stabilize            = true,
		--Has it been inserted in to the buffer
		inserted             = false,
		--Whether this element is created and drawn instantly (and doesn't need a canvas)
		immediate            = false,
		--Render this element in the external buffer with absolute coordinates
		absolutePosition     = false,
	}

	self.baseState = {}

	self.baseView = {
		x = 0,
		y = 0,
		w = 10,
		h = 10,
		minW = 10,
		minH = 10,
	}

	self.view = setmetatable({}, {
		__index = function(t, index)
			return self.baseView[index]
		end,
		__newindex = function(t, index, val)
			if self.baseView[index] ~= val then
				self.baseView[index] = val
				self.context:bubbleUpdate()
				self:updateInputCtx()
			end
		end
	})

	--Context makes sure element internals don't have to worry about absolute coordinates
	self.context = context.new(self)
end

function element:setCalculatedSize(w, h)
	self.view.minW = w or self.view.minW
	self.view.minH = h or self.view.minH
	self.view.w = math.max(self.view.minW, self.view.w)
	self.view.h = math.max(self.view.minH, self.view.h)
end

function element:updateInputCtx()
	self.context.inputContext:update()
	if self.settings.canvasW then
		--If canvas too small make a bigger one
		if self.settings.canvasW < self.view.w or self.settings.canvasH < self.view.h then
			self.settings.canvasW = self.view.w*1.25
			self.settings.canvasH = self.view.h*1.25

			self.canvas = love.graphics.newCanvas(self.view.w*1.25, self.view.h*1.25)
		--If canvas too big make a smaller one
		elseif self.settings.canvasW > self.view.w*1.50 or self.settings.canvasH > self.view.h*1.50 then
			self.settings.canvasW = self.view.w*1.25
			self.settings.canvasH = self.view.h*1.25
			
			self.canvas = love.graphics.newCanvas(self.view.w*1.25, self.view.h*1.25)
		end
	
		self.quad = love.graphics.newQuad(0, 0, self.view.w, self.view.h, self.settings.canvasW, self.settings.canvasH)
	end
end

--Immediate mode code(don't call directly)
function element.immediate(param, func, x, y, w, h)

end


--Hotswapping code

function element:reLoader(newFunc)
	self.context:set()

	self.parentFunc = newFunc

	if type(self.parentFunc) == 'function' then
		self.renderer = self.parentFunc(self.parameters, self.state, self.view)
	else
		self.renderer = self.parentFunc
	end

	self.context:unset()
	self.context:bubbleUpdate()
end

local newCanvas,newQuad = love.graphics.newCanvas,love.graphics.newQuad
--Called once dimensions are validated
function element:setup()

	self.parameters = setmetatable({}, {
			__index = function(t, index)
				return self.baseParams[index]
			end,
			__newindex = function(t, index, val)
				if self.baseParams[index] ~= val then
					self.baseParams[index] = val
					self.context:bubbleUpdate()
				end
			end
		})

	self.context:set()
	self.renderer = self.parentFunc(self.parameters, self.view.w, self.view.h)
	self.context:unset()

	self.settings.canvasW = self.view.w*1.25
	self.settings.canvasH = self.view.h*1.25

	self.canvas = newCanvas(self.view.w*1.25, self.view.h*1.25)
	self.quad = newQuad(0, 0, self.view.w, self.view.h, self.view.w*1.25, self.view.h*1.25)

	self.settings.isSetup = true
end

local setColor,rectangle,setFont,printf = love.graphics.setColor,love.graphics.rectangle,love.graphics.setFont,love.graphics.printf
function element:errorRender(msg)
	setColor(1, 0, 0)
	rectangle('line', 0, 0, self.view.w, self.view.h)
	setColor(1, 1, 1)
	printf("Error: "..msg, 0, 0, self.view.w)
end

function element:internalRender()

	if type(self.renderer) == 'function' then
		love.graphics.push()
		love.graphics.origin()
		local status, err = pcall(self.renderer)
		love.graphics.pop()

		if not status then
			if helium.conf.HARD_ERROR then
				error(status)
			end
			self:errorRender(status)
		end

	elseif type(self.renderer) == 'string' then
		if helium.conf.HARD_ERROR then
			error(self.renderer)
		end
		self:errorRender(self.renderer)
	end
end

local getCanvas,setCanvas,clear = love.graphics.getCanvas,love.graphics.setCanvas,love.graphics.clear
function element:renderWrapper()
	if not self.settings.isSetup then
		self:setup()
		self.settings.isSetup = true
	end

	self.context:set()
	local cnvs = getCanvas()
	setCanvas({self.canvas, stencil = true})

	clear()

	if self.parameters then
		self:internalRender()
		self.settings.pendingUpdate = false
	end

	setCanvas(cnvs)
	self.context:unset()
end

local draw = love.graphics.draw
function element:externalRender()
	if self.settings.stabilize and not self.settings.needsRendering then
		self.settings.stabilize = false
		self.settings.needsRendering = true
	end

	if self.settings.needsRendering then
		self:renderWrapper()
		self.settings.needsRendering = false
	end

	setColor(1,1,1)
	draw(self.canvas, self.quad, self.view.x, self.view.y)
end

function element:externalUpdate()
	if self.settings.pendingUpdate then
		if self.updater then
			self:updater()
		end

		self.settings.needsRendering = true
		self.settings.pendingUpdate  = false
	end

	return self.settings.remove
end

local insert = table.insert

--External functions
--Acts as the entrypoint for beginning rendering
---@param x number
---@param y number
function element:draw(x, y, w, h)
	if not self.view.lock then
		if x then self.view.x = x end
		if y then self.view.y = y end
		if w then self.view.w = self.view.minW<=w and w or self.view.minW end
		if h then self.view.h = self.view.minH<=h and h or self.view.minH end
	end

	if self.settings.firstDraw then
		self.settings.remove = false
		if self.baseState.onFirstDraw then
			self.baseState.onFirstDraw()
		end
		self.settings.firstDraw = false
	end

	if context.getContext() then
		self:externalRender()
	elseif not self.settings.inserted then
		self.settings.inserted = true
		insert(helium.elementBuffer, self)
	end
end

function element:destroy()
	if self.baseState.onDestroy then
		self.baseState.onDestroy()
	end
	self.settings.remove  = true
	self.settings.firstDraw = true
	self.settings.isSetup = false
	self.context:destroy()
end

return element
