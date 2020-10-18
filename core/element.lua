--[[ Element superclass ]]
--[[ Love is currently a hard dependency, although not in many places ]]
local path = string.sub(..., 1, string.len(...) - string.len(".core.element"))
local helium = require(path .. ".dummy")
local context = require(path.. ".core.stack")

---@class Element
local element = {}
element.__index = element

local type,pcall = type,pcall
setmetatable(element, {
		__call = function(cls, ...)
			local self
			local func, param, w, h = ...
			
			--Make the object inherit class
			self = setmetatable({}, element)
			self.parentFunc = func

			self:new(param,nil, w, h)
			self:createProxies()

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
		minW = w or 0,
		minH = h or 0,
	}

	self.size = setmetatable({}, {__index = function(t, index)
		return self.baseView[index]
	end,})

	self.view = self.baseView
end

function element:sizeChange(i, v)
	local increase = self.baseView[i] < v

	if i == 'w' then
		self.baseView.w = math.max(self.baseView.minW, v)
	else
		self.baseView.h = math.max(self.baseView.minH, v)
	end
	
	--defer resize
	if self.deferResize then
		if not self.deferResize.increased then
			self.deferResize.increased = increase
		end
	else
		self.deferResize = { increased = increase }
	end
end

function element:posChange(i, v)
	self.baseView[i] = v
		--defer resize

	if not self.deferRepos then
		self.deferRepos = true
	end
end

function element:onUpdate()

end

function element:onDraw()

end

function element:onLoad()

end

function element:onDestroy()

end

function element:createProxies()
	self.view = setmetatable({}, {
		__index = function(t, index)
			return self.baseView[index]
		end,
		__newindex = function(t, index, val)
			if self.baseView[index] ~= val then
				if index=='w' or index=='h' then
					self:sizeChange(index, val)
				else
					self:posChange(index, val)
				end
				self.context:bubbleUpdate()
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

local selfRenderTime
function element.setBench(time)
	selfRenderTime = time
end

local newCanvas, newQuad = love.graphics.newCanvas, love.graphics.newQuad
function element:createCanvas()

	self.canvas, self.quad = helium.atlas.assign(self)

	if not self.canvas then
		self.settings.failedCanvas = true
		self.settings.hasCanvas = false
		return
	end

	self.settings.canvasW = self.view.w
	self.settings.canvasH = self.view.h
	self.settings.hasCanvas = true
end

function element:setParam(p)
	self.baseParams = p
	self.context:bubbleUpdate()
end

function element:setCalculatedSize(w, h)
	self.view.minW = w or self.view.minW
	self.view.minH = h or self.view.minH
	self.view.w = w or self.view.minW
	self.view.h = h or self.view.minH
end

local dummy = function() end
--Immediate mode code(don't call directly)
function element.immediate(param, func, x, y, w, h)
	--Need to capture this by the current parent context
	--Todo:
	local ctx = context.getContext()
	if ctx then
		local self = setmetatable({}, element)
		self = self:new(param, true)
	else
		error("Can't render immediate outside of persistent")
	end
end

--Called once dimensions are validated
function element:setup()
	self.context:set()
	self.renderer = self.parentFunc(self.parameters, self.size)
	self.context:unset()

	self.settings.isSetup = true
end

local setColor, rectangle, setFont, printf = love.graphics.setColor, love.graphics.rectangle, love.graphics.setFont, love.graphics.printf
local calcT

function element:internalRender()
	if self.settings.testRenderPasses > 0 and selfRenderTime then
		calcT = love.timer.getTime()
	end

	self.renderer()

	if self.settings.testRenderPasses > 0 and selfRenderTime then
		self.settings.testRenderPasses = self.settings.testRenderPasses-1
		local selfTime = love.timer.getTime()-calcT
		table.insert(self.renderBench, selfTime)
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
local lg = love.graphics
function element:externalRender()
	local cnvs = getCanvas()
	love.graphics.push('all')

	if not self.settings.isSetup then
		self:setup()
		self.settings.isSetup = true
	end

	if self.settings.needsRendering then
		if self.settings.hasCanvas then
			setCanvas(self.canvas)
			--need scissors
			local ox, oy, w, h = self.quad:getViewport()
			lg.push('all')
			lg.origin()
			lg.translate(ox, oy)
			lg.setScissor(ox, oy, w, h)
			lg.clear(0,0,0,0)
			
			self:renderWrapper()
			
			self.settings.needsRendering = false
			lg.pop()
		else
			lg.translate(self.view.x, self.view.y)
			local x, y = lg.transformPoint(0, 0)
			lg.intersectScissor(x, y, self.view.w, self.view.h)
			
			self:renderWrapper()
		end
	end
	--lg.setScissor()

	setCanvas(cnvs)

	if self.settings.hasCanvas then
		lg.translate(self.view.x, self.view.y)
		setColor(1, 1, 1, 1)
		draw(self.canvas, self.quad, 0, 0)
	end

	lg.setScissor()
	love.graphics.pop()
end

function element:externalUpdate()
	self.context:zIndex()
	if not self.settings.failedCanvas and self.settings.testRenderPasses == 0 and not self.settings.hasCanvas then
		self:createCanvas()

		self.settings.pendingUpdate = true
	end

	if self.settings.pendingUpdate then
		self.settings.needsRendering = true
		self.settings.pendingUpdate  = false
	end

	if self.deferResize then
		self.context:sizeChanged()
		if self.settings.hasCanvas then 
			helium.atlas.unassign(self)
			self.settings.hasCanvas = false
			self.settings.testRenderPasses = 15
			self.canvas = nil
			self.quad = nil
			self.interQuad = nil
			self.deferResize = nil
		end
	end

	if self.deferRepos then
		self.context:posChanged()
		self.deferRepos = false
	end

	return self.settings.remove
end

local insert = table.insert

--External functions
--Acts as the entrypoint for beginning rendering
---@param x number
---@param y number
function element:draw(x, y, w, h)
	if x then self.view.x = x end
	if y then self.view.y = y end
	if w then self.view.w = w end
	if h then self.view.h = h end

	local cx = context.getContext()
	if cx then
		if cx:childRender(self) then
			self:externalUpdate()
			self:externalRender()
		end
	elseif not self.settings.inserted then
		self.settings.inserted = true
		insert(helium.elementInsertionQueue, self)
	end

	if self.settings.firstDraw then
		self.settings.remove = false
		self.settings.firstDraw = false
		if cx then
			self.settings.testRenderPasses = self.settings.testRenderPasses+5
		end
	end
end

function element:getSize()
	return self.view.w, self.view.h
end

function element:destroy()
	self.settings.remove  = true
	self.settings.firstDraw = true
	self.settings.isSetup = false
	self.context:destroy()
end

return element
