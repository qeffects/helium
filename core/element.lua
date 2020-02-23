--[[ Element superclass ]]
--[[ Love is currently a hard dependency, although not in many places ]]
local path = string.sub(..., 1, string.len(...) - string.len(".core.element"))
local helium = require(path .. ".dummy")

---@class context
local context = {}
context.__index = context

local activeContext

---@param elem element
function context.new(elem)
	local ctx = setmetatable({view = elem.view, element = elem, childrenContexts={}}, context)

	return ctx
end

function context:bubbleUpdate()
	self.element.settings.pendingUpdate  = true
	self.element.settings.needsRendering = true

	if self.parentCtx and self.parentCtx~=self then
		self.parentCtx:bubbleUpdate()
	end
end

function context:set()
	if activeContext then
		if not self.parentCtx and activeContext~=self then
			self.parentCtx = activeContext
			activeContext.childrenContexts[#activeContext.childrenContexts] = self
		end

		self.absX      = self.parentCtx.absX + self.view.x
		self.absY      = self.parentCtx.absY + self.view.y

		activeContext  = self
	else
		self.absX      = self.view.x
		self.absY      = self.view.y

		activeContext  = self
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
	self.elem:undraw()
	for i=1,#self.childrenContexts do
		self.childrenContexts[i]:destroy()
	end
end

---@class element
local element = {}
element.__index = element

function element.newProxy(base)
	local base = base or {}
	local fakeBase = {}
	local activeContext = activeContext
	return setmetatable({},{
			__index = function(t, index)
				return fakeBase[index] or base[index]
			end,
			__newindex = function(t, index, val)
				if fakeBase[index] ~= val then
					fakeBase[index] = val
					activeContext:bubbleUpdate()
				end
			end
		})
end

local type,pcall = type,pcall
setmetatable(element,{
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

--Dummy functions
function element:renderer() print('no renderer') end

--Control functions
--The new function that should be used for element creation
function element:new(w, h, param)
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
		calculatedDimensions = true,
		firstDraw            = true,
		--Stabilize the internal canvas, draw it twice on first load
		stabilize            = true,
		inserted             = false
	}

	self.baseState = {}

	self.baseView = {
		x = 0,
		y = 0,
		w = w or 10,
		h = h or 10,
	}

	self.view = setmetatable({},{
		__index = function(t, index)
			return self.baseView[index]
		end,
		__newindex = function(t, index, val)
			if self.baseView[index] ~= val then
				self.baseView[index] = val
				self.context:bubbleUpdate()
				self:updateInputCtx()
				if self.view.onChange then
					self.view.onChange()
				end
			end
		end
	})

	--Context makes sure element internals don't have to worry about absolute coordinates
	self.inputContext = helium.input.newContext(self)
	self.context = context.new(self)

	self.classlessFuncs = {}
		
	--Allows manipulation of the arbitrary state
	self.classlessFuncs.getState = function ()
		return self.state
	end
	
	--Allows manipulation of rendering width height, relative X and relative Y
	self.classlessFuncs.getView = function ()
		self.settings.restrictView = true
		return self.view
	end

	self:setup()
	self.settings.isSetup = true
end

function element:updateInputCtx()
	self.inputContext:update()
	if self.settings.canvasW then
		if self.settings.canvasW < self.view.w or self.settings.canvasH < self.view.h then
			self.settings.canvasW = self.view.w*1.25
			self.settings.canvasH = self.view.h*1.25

			self.canvas = love.graphics.newCanvas(self.view.w*1.25, self.view.h*1.25)
		end
	
		self.quad = love.graphics.newQuad(0, 0, self.view.w, self.view.h, self.settings.canvasW, self.settings.canvasH)
	end
end


--Hotswapping code

function element:reLoader(newFunc)
	self.inputContext:set()
	self.context:set()
	self.inputContext:destroy()

	self.parentFunc = newFunc

	if type(self.parentFunc)=='function' then
		self.renderer = self.parentFunc(self.parameters,self.state,self.view)
	else
		self.renderer = self.parentFunc
	end

	self.context:unset()
	self.inputContext:unset()
	self.context:bubbleUpdate()
end

local newCanvas,newQuad = love.graphics.newCanvas,love.graphics.newQuad
--Called once dimensions are validated
function element:setup()
	self.state = setmetatable({},{
			__index = function(t, index)
				return self.baseState[index]
			end,
			__newindex = function(t, index, val)
				if self.baseState[index] ~= val then
					self.baseState[index] = val
					if self.baseState.onUpdate then
						self.baseState.onUpdate()
					end
					self.context:bubbleUpdate()
				end
			end
		})

	self.parameters = setmetatable({},{
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


	self.settings.canvasW = self.view.w*1.25
	self.settings.canvasH = self.view.h*1.25

	self.canvas = newCanvas(self.view.w*1.25, self.view.h*1.25)
	self.quad = newQuad(0, 0, self.view.w, self.view.h, self.view.w*1.25, self.view.h*1.25)

	self.context:set()
	self.inputContext:set()	
	self.renderer = self.parentFunc(self.parameters,self.state,self.view)
	self.inputContext:unset()
	self.inputContext:afterLoad()
	self.context:unset()

	self.settings.isSetup = true
end

local setColor,rectangle,setFont,printf = love.graphics.setColor,love.graphics.rectangle,love.graphics.setFont,love.graphics.printf
function element:classlessRender()

	self.inputContext:set()
	if type(self.renderer)=='function' then
		love.graphics.push()
		love.graphics.origin()
		local status, err = pcall(self.renderer)
		love.graphics.pop()

		if not status then
			if helium.conf.HARD_ERROR then
				error(status)
			end
			setColor(1,0,0)
			rectangle('line',0,0,self.view.w,self.view.h)
			setColor(1,1,1)
			printf("Error: "..err,0,0,self.view.w)
		end

	elseif type(self.renderer)=='string' then
		if helium.conf.HARD_ERROR then
			error(self.renderer)
		end
		setColor(1,0,0)
		rectangle('line',0,0,self.view.w,self.view.h)
		setColor(1,1,1)
		printf("Error: "..self.renderer,0,0,self.view.w)
	end

	self.inputContext:unset()
end

local getCanvas,setCanvas,clear = love.graphics.getCanvas,love.graphics.setCanvas,love.graphics.clear
function element:renderWrapper()
	local cnvs = getCanvas()
	setCanvas({self.canvas, stencil = true})

	clear()

	if self.parameters then
		self:classlessRender()
		self.settings.pendingUpdate = false
	end

	setCanvas(cnvs)
end

local draw = love.graphics.draw
function element:externalRender()
	self.context:set()

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

	self.context:unset()
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
function element:draw(x, y)
	if not self.view.lock then
		if x then self.view.x = x end
		if y then self.view.y = y end
	end

	if self.settings.firstDraw then
		self.settings.remove = false
		if self.baseState.onFirstDraw then
			self.baseState.onFirstDraw()
		end
		self.settings.firstDraw = false
	end

	if not self.settings.isSetup then
		self.inputContext:unsuspend()
		self.settings.isSetup = true
	end

	if activeContext then
		self:externalRender()
	elseif not self.settings.inserted then
		self.settings.inserted = true
		insert(helium.elementBuffer, self)
	end
end

function element:undraw()
	if self.baseState.onDestroy then
		self.baseState.onDestroy()
	end
	self.settings.remove  = true
	self.settings.firstDraw = true
	self.settings.isSetup = false
	self.inputContext:set()
	self.inputContext:suspend()
	self.inputContext:unset()
end

return element
