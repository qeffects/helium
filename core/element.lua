--[[--------------------------------------------------
	Helium UI by qfx (qfluxstudios@gmail.com)
	Copyright (c) 2021 Elmārs Āboliņš
	https://github.com/qeffects/helium
----------------------------------------------------]]
local path = string.sub(..., 1, string.len(...) - string.len(".core.element"))
local helium = require(path .. ".dummy")
local context = require(path.. ".core.stack")
local scene = require(path.. ".core.scene")

local currentCanvasID

---@class Element
local element = {
	typeName = 'HeliumElement'
}
element.__index = element

local type,pcall = type,pcall
setmetatable(element, {
		__call = function(cls, func, param, w, h, id, flags)
			local self
			
			--Make the object inherit class
			self = setmetatable({}, element)
			self.parentFunc = func

			self:new(param,nil, w, h, id, flags)
			self:createProxies()
			local cx = context.getContext()
			if cx then
				self:setup()
				self.settings.isSetup = true
			end
			---@type Element
			return self
		end
	})

--Control functions
--The new function that should be used for element creation
function element:new(param, immediate, w, h, id, flags)
	self.parameters = {}
	self.baseParams = param
	self.flags = flags or {}
	self.id = id

	--Internal state callbacks
	self.callbacks = {}

	--Internal settings
	self.settings = {
		isSetup              = false,
		pendingUpdate        = true,
		needsRendering       = true,
		active               = true,
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
		--Which canvas is it assigned to
		currentCanvasIndex   = nil,
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
		offsetX = 0,
		offsetY = 0,
		scaledX = 0,
		scaledY = 0,
	}

	self.size = setmetatable({}, {__index = function(t, index)
		return self.baseView[index]
	end,})

	self.view = self.baseView
end

function element:reassignCanvas()
	self.settings.failedCanvas = false
	self.settings.hasCanvas = false

	self.canvas = nil
	self.quad = nil
	self.interQuad = nil
	self.deferResize = nil

	self.context:bubbleUpdate()
end

function element:forceRerender()
	self.settings.pendingUpdate = true
	self.settings.needsRendering = true
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

	if self.callbacks.onSizeChange then
		self.context:setLogic()
		for i, cb in ipairs(self.callbacks.onSizeChange) do
			cb(self.view.w, self.view.h)
		end
		self.context:unset()
	end
end

function element:posChange(i, v)
	self.baseView[i] = v
		--defer resize

	if not self.deferRepos then
		self.deferRepos = true
	end
	
	if self.callbacks.onPosChange then
		self.context:setLogic()
		for i, cb in ipairs(self.callbacks.onPosChange) do
			cb(self.view.x, self.view.y)
		end
		self.context:unset()
	end
end

function element:onUpdate()
	if self.callbacks.onUpdate then
		self.context:setLogic()
		for i, cb in ipairs(self.callbacks.onUpdate) do
			cb()
		end
		self.context:unset()
	end
end

function element:onLoad()
	if self.callbacks.onLoad then
		self.context:setLogic()
		for i, cb in ipairs(self.callbacks.onLoad) do
			cb()
		end
		self.context:unset()
	end
end

function element:onDestroy()
	if self.callbacks.onDestroy then
		self.context:setLogic()
		for i, cb in ipairs(self.callbacks.onDestroy) do
			cb()
		end
		self.context:unset()
	end
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

	self.canvas, self.quad, self.settings.currentCanvasIndex = scene.activeScene.atlas:assign(self)

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

--Returns the proxied parameter table
function element:getParam()
	return self.parameters
end

function element:setSize(w, h)
	local w, h = w or self.view.w, h or self.view.h 

	self.view.w = math.max(w, self.view.minW)
	self.view.h = math.max(h, self.view.minH)
end

function element:setMinSize(w, h)
	self.view.minW = w or self.view.minW
	self.view.minH = h or self.view.minH
	self.view.w = math.max(self.view.w, w, self.view.minW)
	self.view.h = math.max(self.view.h, h, self.view.minH)
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
	self:onLoad()
end

local setColor, rectangle, setFont, printf = love.graphics.setColor, love.graphics.rectangle, love.graphics.setFont, love.graphics.printf
local calcT

function element:internalRender()
	if self.settings.testRenderPasses > 0 and selfRenderTime and not helium.conf.MANUAL_CACHING then
		calcT = love.timer.getTime()
	end

	self.renderer()

	if self.settings.testRenderPasses > 0 and selfRenderTime and not helium.conf.MANUAL_CACHING then
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
	local scaleX, scaleY = helium.scene.activeScene.scaleX, helium.scene.activeScene.scaleY
	if not self.settings.active then
		return
	end

	local oldScX, oldScY, oldScW, oldScH = lg.getScissor()
	local cnvs = getCanvas()
	love.graphics.push('all')

	if not self.settings.isSetup then
		self:setup()
		self.settings.isSetup = true
	end

	local oldCanvasId
	if self.settings.hasCanvas then
		if self.settings.currentCanvasIndex == currentCanvasID then
			--problem lol
			self.settings.renderingParentCanvasIndex = currentCanvasID
			self:reassignCanvas()
		else
			oldCanvasId = currentCanvasID
			currentCanvasID = self.settings.currentCanvasIndex
		end
	end

	if self.settings.needsRendering then
		local sx, sy = lg.transformPoint(0, 0)
		self.view.offsetX, self.view.offsetY = lg.transformPoint(self.view.x, self.view.y)

		self.view.scaledX  = self.view.offsetX - sx
		self.view.scaledY  = self.view.offsetY - sy
		
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
			local w, h = self.view.w, self.view.h
			if not cnvs then
				w = w*scaleX
				h = h*scaleY
			end
			lg.push()
			lg.translate(self.view.x, self.view.y)
			local x, y = lg.transformPoint(0, 0)
			lg.intersectScissor(x, y, w, h)
			self:renderWrapper()
			lg.pop()
		end
	end
	lg.setScissor(oldScX, oldScY, oldScW, oldScH)

	setCanvas(cnvs)

	if self.settings.hasCanvas then
		lg.translate(self.view.x, self.view.y)
		setColor(1, 1, 1, 1)
		lg.setBlendMode('alpha','premultiplied')
		draw(self.canvas, self.quad, 0, 0)
		lg.setBlendMode('alpha','alphamultiply')
	end

	love.graphics.pop()
	currentCanvasID = oldCanvasId
end

function element:externalUpdate()
	if not self.settings.active then
		return
	end
	self.context:set()
	self.context:zIndex()
	if ((not self.settings.failedCanvas
		and self.settings.testRenderPasses == 0
		and scene.activeScene.cached
		and not helium.conf.MANUAL_CACHING)
		or self.settings.forcedCanvas)
		and not self.settings.hasCanvas then

		self:createCanvas()

		self.settings.pendingUpdate = true
	end

	if self.settings.pendingUpdate then
		self:onUpdate()
		self.settings.needsRendering = true
		self.settings.pendingUpdate  = false
	end

	if self.deferResize then
		self.settings.pendingUpdate = true
		self.settings.needsRendering = true
		self.context:sizeChanged()
		if self.settings.hasCanvas then 
			scene.activeScene.atlas:unassign(self)
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

	self.context:unset()
	return self.settings.remove
end

local insert = table.insert

---External functions
---Acts as the entrypoint for beginning rendering
---@param x number
---@param y number
function element:draw(x, y, w, h)
	if x then self.view.x = x end
	if y then self.view.y = y end
	if w then self.view.w = w end
	if h then self.view.h = h end

	if not self.settings.active then
		self:redraw()
	end

	local cx = context.getContext()
	if cx then
		if cx:childRender(self) then
			self:externalUpdate()
			self:externalRender()
		end
	elseif not self.settings.inserted then
		self.settings.inserted = true
		insert(scene.activeScene.buffer, self)
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

function element:getView()
	return self.view.x, self.view.y, self.view.w, self.view.h
end

---Destroys this element
function element:destroy()
	self.settings.remove  = true
	self.settings.inserted  = false
	self.settings.active  = false
	self.settings.firstDraw = true
	self.settings.isSetup = false
	self:onDestroy()
	self.context:destroy()
end

function element:redraw()
	self.settings.active  = true
	self.context:redraw()
end

---Stops rendering, updates and draw
function element:undraw()
	self.settings.active  = false
	self.context:undraw()
end

return element
