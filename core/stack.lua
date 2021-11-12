--[[--------------------------------------------------
	Helium UI by qfx (qfluxstudios@gmail.com)
	Copyright (c) 2021 Elmārs Āboliņš
	https://github.com/qeffects/helium
----------------------------------------------------]]
local path = string.sub(..., 1, string.len(...) - string.len(".core.stack"))
local helium = require(path .. ".dummy")
local event = require(path..'.core.events')

---@class context
---@field element Element
local context = {
	type = 'context'
}
context.__index = context

local activeContext
local currentTemporalZ = 0

---@param elem Element
function context.new(elem)
    local ctx = setmetatable({
		capturedChilds = {},
        view = elem.view,
        element = elem,
        childrenContexts = {},
		childRenderTime = 0,
		deferChildren = false,
		events = event.new(),
		attachedState = {},
		temporalZ = {z = nil},
	}, context)
	
	ctx.events:newQueue('resize')
	ctx.events:newQueue('poschange')

    return ctx
end

function context:bubbleUpdate()
	if self.element.settings.pendingUpdate then
		return;
	end
    self.element.settings.pendingUpdate  = true
    self.element.settings.needsRendering = true

	if self.parentCtx and self.parentCtx~=self then
        self.parentCtx:bubbleUpdate()
    end
end

function context:set()
    if activeContext then
		local scaleX, scaleY = helium.scene.activeScene.scaleX, helium.scene.activeScene.scaleY
        if not self.parentCtx and activeContext~=self then
            self.parentCtx = activeContext
            activeContext.childrenContexts[#activeContext.childrenContexts+1] = self
        end

        self.absX      = self.parentCtx.absX + self.view.x
        self.absY      = self.parentCtx.absY + self.view.y
		
		if self.parentCtx.element.settings.hasCanvas then
			self.offsetX   = self.parentCtx.offsetX + self.view.x * scaleX
			self.offsetY   = self.parentCtx.offsetY + self.view.y * scaleY
		else
			self.offsetX   = self.view.offsetX
			self.offsetY   = self.view.offsetY
		end

        activeContext  = self
    else
        self.absX      = self.view.x
		self.absY      = self.view.y
		
		self.offsetX   = self.view.offsetX
		self.offsetY   = self.view.offsetY

        activeContext  = self
    end
end


function context:setLogic()
    if activeContext then
        if not self.parentCtx and activeContext~=self then
            self.parentCtx = activeContext
            activeContext.childrenContexts[#activeContext.childrenContexts+1] = self
        end

        activeContext  = self
    else
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

function context:zIndex()
	currentTemporalZ = currentTemporalZ+1
	self.temporalZ.z = currentTemporalZ
end

function context:startSelfRender()
	self.childRenderTime = 0
end

function context:passTimeTo(time)
	self.childRenderTime = self.childRenderTime + time
end

function context:endSelfRender(time)
	if self.parentCtx then
		self.parentCtx:passTimeTo(time)
	end
	return time-self.childRenderTime
end

function context:destroy()
    for i = 1, #self.childrenContexts do
        self.childrenContexts[i].element:destroy()
    end
end

function context:undraw()
    for i = 1, #self.childrenContexts do
        self.childrenContexts[i].element:undraw()
    end
end

function context:redraw()
    for i = 1, #self.childrenContexts do
        self.childrenContexts[i].element:redraw()
    end
end

function context:getCanvasIndex(forCanvas)
	if self.parentCtx then
		if self.element.settings.hasCanvas then
			return self.parentCtx:getCanvasIndex() == 1 and 2 or 1
		else
			if forCanvas then
				if self.element.settings.renderingParentCanvasIndex then
					return self.element.settings.renderingParentCanvasIndex == 1 and 2 or 1
				end
				return self.parentCtx:getCanvasIndex() == 1 and 2 or 1
			end
		end
	else
		--No parent path (element becomes the first one cached)
		return self.element.settings.hasCanvas and 1 or nil
	end
end

function context:getChildrenCount()
	return #self.childrenContexts
end

function context:startDeferingChildren()
	self.deferChildren = true
	self.capturedChilds = {}
end

function context:childRender(el)
	if self.deferChildren then
		self.capturedChilds[#self.capturedChilds+1] = el
		
		return false
	else
		return true
	end
end

function context:stopDeferingChildren()
	self.deferChildren = false

	return self.capturedChilds
end

function context:normalizePos(x, y)
	local xPX, yPX

	if x<=1 and x~=0 then
		xPX = self.element.view.w * x
	end
	
	if y<=1 and y~=0 then
		yPX = self.element.view.h * y
	end

	return ((xPX or x) + self.offsetX), ((yPX or y) + self.offsetY)
end

function context:normY(y)
	local yPX

	if y<=1 and y~=0 then
		yPX = self.element.view.h * y
	end

	return (yPX or y)
end

function context:normX(x)
	local xPX

	if x<=1 and x~=0 then
		xPX = self.element.view.w * x
	end

	return (xPX or x)
end

function context:normalizeSize(w, h)
	local wPX, hPX

	if w<=1 and w~=0 then
		wPX = self.element.view.w * w
	end

	if h<=1 and h~=0 then
		hPX = self.element.view.h * h
	end

	return (wPX or w)*helium.scene.activeScene.scaleX, (hPX or h)*helium.scene.activeScene.scaleY
end

function context:normalizeSizeUnscaled(w, h)
	local wPX, hPX

	if w<=1 and w~=0 then
		wPX = self.element.view.w * w
	end

	if h<=1 and h~=0 then
		hPX = self.element.view.h * h
	end

	return (wPX or w), (hPX or h)
end

function context:findAttachedState(name)
	if self.attachedState and self.attachedState[name] then
		return self.attachedState[name]
	elseif self.parentCtx then
		return self.parentCtx:findAttachedState(name)
	else
		return nil
	end
end

local scalePropogator = function(elem)
	elem.element:forceRerender()
	elem:scaleChanged()
	elem:sizeChanged()
	elem:posChanged(false)
end

--To be used by the element
function context:scaleChanged()
	self.element:forceRerender()
	self:sizeChanged()
	self:posChanged(false)
	self:doOnEveryChild(scalePropogator)
end

function context:sizeChanged()
	if self.parentCtx then
		self.absX      = self.parentCtx.absX + self.view.x
		self.absY      = self.parentCtx.absY + self.view.y
	else
		self.absX      = self.view.x
		self.absY      = self.view.y
	end

	self.events:push('resize')
end

local posPropogator = function(elem)
	elem:posChanged()
end

function context:posChanged(onevery)
	onevery = not onevery==nil and onevery or true
	if self.parentCtx then
		self.absX      = self.parentCtx.absX + self.view.x
		self.absY      = self.parentCtx.absY + self.view.y
	else
		self.absX      = self.view.x
		self.absY      = self.view.y
	end

	if onevery then
		self:doOnEveryChild(posPropogator)
	end

	self.events:push('poschange')
end

--Event subscriptions
function context:onSizeChange(callback)
	return self.events:sub('resize', callback)
end

function context:onPosChange(callback)
	return self.events:sub('poschange', callback)
end

function context:offSizeChange(callback)
	self.events:unsub('resize', callback)
end

function context:offPosChange(callback)
	self.events:unsub('poschange', callback)
end

function context:doOnEveryChild(func)
	for i, e in ipairs(self.childrenContexts) do
		e:onEveryChild(func)
	end
end

function context:onEveryChild(func)
	func(self)
	for i, e in ipairs(self.childrenContexts) do
		e:onEveryChild(func)
	end
end

--Function meant for external context capture
function context.getContext()
    return activeContext
end

function context.newFrame()
	currentTemporalZ = 0
end

function context.unload()
	activeContext = nil
end

return context