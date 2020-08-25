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
			local func, param, w, h = ...
			
			self = setmetatable({}, element)
			self.parentFunc = func

			self:new(param,nil, w, h)
			self:createProxies(param)

			return self
		end
	})

--Control functions
--The new function that should be used for element creation
function element:new(param, immediate, w, h)
	self.parameters = {}

	self.baseParams = param

	--Internal settings
	self.settings = {
		isSetup              = false,
		pendingUpdate        = true,
		needsRendering       = true,
		remove               = false,
		--Unused for now?
		calculatedDimensions = true,
		--Is this the first render
		firstDraw            = true,
		--Has it been inserted in to the buffer
		inserted             = false,
		--Whether this element is created and drawn instantly (and doesn't need a canvas)
		immediate            = immediate or false,
		--Whether this element has a canvas assigned
		hasCanvas            = false,
		--Current test render passes to be benchmarked
		testRenderPasses     = 20,
		--
		failedCanvas         = false
	}

	self.renderBench = {

	}

	self.baseView = {
		x = 0,
		y = 0,
		w = w or 10,
		h = h or 10,
		minW = w or 10,
		minH = h or 10,
	}
	
	self.view = self.baseView

end

function element:createProxies()
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

	--Context makes sure element internals don't have to worry about absolute coordinates
	self.context = context.new(self)
end

--Random coefficients, if these reach 1.5 then canvas is made
local childrenNum = 5
local selfRenderTime = false
local screenSize = 1/50
local coefficient = 1000000

function element.setBench(time)
	selfRenderTime = time
end

function element:calculateCanvasCoeficient(selfTime)
	local sW, sH = love.graphics.getDimensions()
	local areaBelow = (sW * sH) * screenSize
	local area = self.view.h * self.view.w

	local areaCoef = 1 - (area/areaBelow)
	local childCoef = self.context:getChildrenCount()/childrenNum
	local sizeCoef = selfTime/selfRenderTime
	
	return (areaCoef+childCoef+sizeCoef)>coefficient
end

local newCanvas, newQuad = love.graphics.newCanvas, love.graphics.newQuad
function element:createCanvas()
	self.settings.canvasW = self.view.w*1.25
	self.settings.canvasH = self.view.h*1.25

	self.canvas = newCanvas(self.view.w*1.25, self.view.h*1.25)
	self.quad = newQuad(0, 0, self.view.w, self.view.h, self.view.w*1.25, self.view.h*1.25)
end

function element:setParam(p)
	self.baseParams = p
	self.context:bubbleUpdate()
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

local dummy = function() end
--Immediate mode code(don't call directly)
function element.immediate(param, func, x, y, w, h)
	--Need to capture this by the current parent context
	--Todo:
	local ctx = context.getContext()
	if ctx then
		local self = setmetatable({}, element)
		self = element:new(param, true)
	else
		error("Can't render immediate outside of persistent")
	end
end

--Called once dimensions are validated
function element:setup()
	self.context:set()
	self.renderer = self.parentFunc(self.parameters, self.view.w, self.view.h)
	self.context:unset()

	self.settings.isSetup = true
end

local setColor, rectangle, setFont, printf = love.graphics.setColor, love.graphics.rectangle, love.graphics.setFont, love.graphics.printf
function element:errorRender(msg)
	setColor(1, 0, 0)
	rectangle('line', 0, 0, self.view.w, self.view.h)
	setColor(1, 1, 1)
	printf("Error: "..msg, 0, 0, self.view.w)
end

local calcT

function element:internalRender()
	if self.settings.testRenderPasses > 0 and selfRenderTime then
		calcT = love.timer.getTime()
	end

	local status, err = pcall(self.renderer)
	if self.settings.testRenderPasses > 0 and selfRenderTime then
		self.settings.testRenderPasses = self.settings.testRenderPasses-1
		local selfTime = love.timer.getTime()-calcT
		table.insert(self.renderBench, self.context:endSelfRender(selfTime))
	end

	if not status then
		if helium.conf.HARD_ERROR then
			error(status)
		end
		self:errorRender(status)
	end
end

local draw = love.graphics.draw
local getCanvas, setCanvas, clear = love.graphics.getCanvas, love.graphics.setCanvas, love.graphics.clear
function element:renderWrapper()
	self.context:set()

	if self.parameters then
		self:internalRender()
	end

	self.context:unset()
end

function element:externalRender()
	local cnvs = getCanvas()
	love.graphics.push('all')
	love.graphics.translate(self.view.x, self.view.y)

	if not self.settings.isSetup then
		self:setup()
		self.settings.isSetup = true
	end

	if self.settings.needsRendering then
		if self.settings.hasCanvas then
			setCanvas(self.canvas)
			love.graphics.clear(0,0,0,0)
			love.graphics.push('all')
			love.graphics.origin()

			self:renderWrapper()
			self.settings.needsRendering = false

			love.graphics.pop()
		else
			self:renderWrapper()
		end
	end

	setCanvas(cnvs)

	if self.settings.hasCanvas then
		setColor(1,1,1,1)
		draw(self.canvas, self.quad, 0, 0)
		setColor(0,1,0,0.5)
		love.graphics.rectangle('line', 1, 1, self.view.w-1, self.view.h-1)
	end

	love.graphics.pop()
end

function element:externalUpdate()
	if not self.settings.failedCanvas and self.settings.testRenderPasses == 0 and not self.settings.hasCanvas then
		local avg, sum = 0, 0

		for i, e in ipairs(self.renderBench) do
			sum = sum + e
		end

		avg = sum/#self.renderBench

		if self:calculateCanvasCoeficient(avg) then
			love.graphics.push()
			love.graphics.origin()
			self:createCanvas()
			love.graphics.pop()
			self.settings.hasCanvas = true
			self.settings.pendingUpdate = true
		else
			self.settings.failedCanvas = true
		end
	end

	if self.settings.pendingUpdate then
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
		self.settings.firstDraw = false
	end

	if context.getContext() then
		self:externalUpdate()
		self:externalRender()
	elseif not self.settings.inserted then
		self.settings.inserted = true
		insert(helium.elementBuffer, self)
	end
end

function element:destroy()
	self.settings.remove  = true
	self.settings.firstDraw = true
	self.settings.isSetup = false
	self.context:destroy()
end

return element
