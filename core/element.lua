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
	local ctx = setmetatable({view = elem.view, element = elem}, context)

	return ctx
end

function context:bubbleUpdate()
	self.element.settings.pendingUpdate  = true
	self.element.settings.needsRendering = true

	if self.parentCtx then
		self.parentCtx:bubbleUpdate()
	end
end

function context:set()
	if activeContext then
		self.parentCtx = activeContext

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

---@class element
local element = {}
element.__index = element

setmetatable(element,{
		__call = function(cls, ...)
			local self
			local func, loader = ...
			if type(func)=='function' then
				self = setmetatable({}, element)
				self.parentFunc = func
				self.classless  = true
			end

			if loader then
				local function f(newFunc)
					self:reLoader(newFunc)
				end
				loader(f)
			end

			self:new()

			return self
		end
	})

--Dummy functions
function element:renderer() print('no renderer') end

function element:updater() end

function element:constructor() end


--Control functions
--The new function that should be used for element creation
function element:new()
	local dimensions
	--save the parameters
	self.parameters = {}

	--The element canvas
	self.canvas = nil

	--Internal settings
	self.settings = {
		isSetup              = false,
		pendingUpdate        = true,
		needsRendering       = true,
		calculatedDimensions = true,
		inserted             = false
	}

	self.baseState = {}

	self.baseView = {
		x = 0,
		y = 0,
		w = 10,
		h = 10,
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
			end
		end
	})

	--Context makes sure element internals don't have to worry about absolute coordinates
	self.inputContext = helium.input.newContext(self)
	self.context = context.new(self)

	if self.classless then
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
	end
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
	self.inputContext:destroy()

	self.parentFunc = newFunc
	self.renderer = self.parentFunc(self.parameters,self.state,self.view)
	self.context:bubbleUpdate()

	self.inputContext:unset()
end

--Called once dimensions are validated
function element:setup()
	self.state = setmetatable({},{
			__index = function(t, index)
				return self.baseState[index]
			end,
			__newindex = function(t, index, val)
				if self.baseState[index] ~= val then
					self.baseState[index] = val
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

	self.canvas = love.graphics.newCanvas(self.view.w*1.25, self.view.h*1.25)

	self.quad = love.graphics.newQuad(0, 0, self.view.w, self.view.h, self.view.w*1.25, self.view.h*1.25)

	if self.classless then
		self.inputContext:set()
		
		self.renderer = self.parentFunc(self.parameters,self.state,self.view)

		self.inputContext:unset()
	end

	self.settings.isSetup = true
end

function element:classlessRender()

	self.inputContext:set()
	if type(self.renderer)=='function' then
		local status, err = pcall(self.renderer)

		if not status then
			love.graphics.setColor(1,0,0)
			love.graphics.rectangle('line',0,0,self.view.w,self.view.h)
			love.graphics.setColor(1,1,1)
			love.graphics.printf("Error: "..err,0,0,self.view.w)
		end

	elseif type(self.renderer)=='string' then
		love.graphics.setColor(1,0,0)
		love.graphics.rectangle('line',0,0,self.view.w,self.view.h)
		love.graphics.setColor(1,1,1)
		love.graphics.printf("Error: "..self.renderer,0,0,self.view.w)
	end
	self.inputContext:unset()

end

function element:renderWrapper()
	local cnvs = love.graphics.getCanvas()
	love.graphics.setCanvas({self.canvas, stencil = true})

	love.graphics.clear()

	if self.classless and self.parameters then
		self:classlessRender()
		self.settings.pendingUpdate = false
	else
		self:renderer()
	end

	love.graphics.setCanvas(cnvs)
end

function element:externalRender()
	self.context:set()

	if self.settings.needsRendering then
		self:renderWrapper()
		self.settings.needsRendering = false
	end

	love.graphics.setColor(1,1,1)
	love.graphics.draw(self.canvas, self.quad, self.view.x, self.view.y)

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
end

--External functions
--Acts as the entrypoint for beginning rendering
---@param params any
---@param x number
---@param y number
---@param w number
---@param h number
function element:draw(params, x, y, w, h)
	if not self.view.lock then
		self.view.x = x or self.view.x
		self.view.y = y or self.view.y
		self.view.w = w or self.view.w
		self.view.h = h or self.view.h
	end

	if params then
		if type(params)=='table' and self.baseParams then
			helium.utils.tableMerge(params, self.parameters)
		elseif self.baseParams==nil then
			self.baseParams = params
		else
			self.parameters = params
		end

	end

	if not self.settings.isSetup then
		self:setup()
	end

	if activeContext then
		self:externalRender()
	elseif not self.settings.inserted then
		self.settings.inserted = true
		table.insert(helium.elementBuffer, self)
	end
end

function element:undraw()
	self.settings.remove  = true
	self.settings.isSetup = false
end

return element
