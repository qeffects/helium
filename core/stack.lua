--Builds the element stack basically

local path = string.sub(..., 1, string.len(...) - string.len(".core.stack"))
local helium = require(path .. ".dummy")
local event = require(path..'.core.events')

---@class context
local context = {}
context.__index = context

local activeContext
local currentTemporalZ = 0

---@param elem element
function context.new(elem)
    local ctx = setmetatable({
        view = elem.view,
        element = elem,
        childrenContexts = {},
		childRenderTime = 0,
		deferChildren = false,
		events = event.new(),
		capturedChilds = {},
		temporalZ = {z = nil},
	}, context)
	
	ctx.events:newQueue('resize')
	ctx.events:newQueue('poschange')

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
		
		self.offsetX   = self.view.x +self.parentCtx.offsetX
		self.offsetY   = self.view.y +self.parentCtx.offsetY

        activeContext  = self
    else
        self.absX      = self.view.x
		self.absY      = self.view.y
		
		self.offsetX   = 0
		self.offsetY   = 0

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
    self.elem:undraw()
    for i = 1, #self.childrenContexts do
        self.childrenContexts[i]:destroy()
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

	return (xPX or x) + self.absX, (yPX or y) + self.absY
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

	return wPX or w, hPX or h
end

--To be used by the element
function context:sizeChanged()
	self.events:push('resize')
end

function context:posChanged()
	if self.parentCtx then
		self.absX      = self.parentCtx.absX + self.view.x
		self.absY      = self.parentCtx.absY + self.view.y
	else
		self.absX      = self.view.x
		self.absY      = self.view.y
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