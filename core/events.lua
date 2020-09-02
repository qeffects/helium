local eventClass = {}
eventClass.__index = eventClass

function eventClass.new()
	local self = {
		eventSubs = {}
	}

	return setmetatable(self, eventClass)
end

function eventClass:sub(name, func)
	local sub = { func = func }

	self:provideQueue(name)
	self.eventSubs[name][func] = func

	return sub
end

function eventClass:push(name, event)
	if self.eventSubs[name] then
		table.insert(self.eventSubs[name].queue, event)
	end
end

function eventClass:flush(name)

end

function eventClass:flushAll()
	for i, subs in pairs(self.eventSubs) do
		local assembledEvent = {}
		
		for i, e in ipairs(subs.queue) do

		end
	end
end

function eventClass:provideQueue(name)
	if not self.eventSubs[name] then
		self.eventSubs[name] = {
			queue = {}
		}
	end
end

function eventClass:unsub(name, event)
	self.eventSubs[name][event] = nil
end

return eventClass