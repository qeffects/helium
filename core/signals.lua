--Internal event/zone/perf-log system
local signals = {}
signals.__index = signals

function signals.newController()
    return setmetatable({
        stack = {},
        
        eventSubs = {},
        zoneSubs = {},

        startTime = 0,
        totalTime = 0
    }, signals)
end

function signals:push(name)
    self.stack[#self.stack+1] = {name = name}

    self.startTime = love.timer.getTime()

    if self.zoneSubs[name] then
        for i, e in ipairs(self.zoneSubs[name]) do
            if e.on and e.func() then

            end
        end
    end
end

function signals:pop()
    local name = self.stack[#self.stack].name

    if self.zoneSubs[name] then
        for i, e in ipairs(self.zoneSubs[name]) do
            if not e.on and e.func() then

            end
        end
    end

    self.totalTime = love.timer.getTime() - self.startTime
    self.stack[#self.stack] = nil
end

function signals:emitEvent(name, content)
    if self.eventSubs[name] then
        for i,e in ipairs(self.eventSubs[name]) do
            e.func(content)
        end
    end
end

function signals:onEvent(func, event)
    if not self.eventSubs[event] then
        self.eventSubs[event] = {}
    end
    self.eventSubs[event][#self.eventSubs[event]+1] = {func = func}

end

--on - true when new zone is pushed
-- false when zone is popped
function signals:onSignal(func, name, on)
    if not self.zoneSubs[name] then
        self.zoneSubs[name] = {}
    end
    self.zoneSubs[name][#self.zoneSubs[name]+1] = {func = func, on = on}

end

return signals