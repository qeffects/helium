--Builds the element stack basically

local path = string.sub(..., 1, string.len(...) - string.len(".core.stack"))
local helium = require(path .. ".dummy")

---@class context
local context = {}
context.__index = context

local activeContext

---@param elem element
function context.new(elem)
    local ctx = setmetatable({
        view = elem.view,
        element = elem,
        childrenContexts = {},
        inputContext = helium.input.newContext(elem)
    }, context)

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
    
    self.inputContext:set()
end

function context:unset()
	self.inputContext:unset()
    self.inputContext:afterLoad()

    if self.parentCtx then
        activeContext = self.parentCtx
    else
        activeContext = nil
    end
end

function context:unsuspend()
    self.inputContext:unsuspend()
end

function context:destroy()
    self.elem:undraw()
    for i=1,#self.childrenContexts do
        self.childrenContexts[i]:destroy()
    end
end

function context:suspend()
	self.inputContext:set()
	self.inputContext:suspend()
	self.inputContext:unset()
end

--Function meant for external context capture
function context.getContext()
    return activeContext
end


return context