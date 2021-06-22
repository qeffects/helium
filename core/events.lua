--[[--------------------------------------------------
	Helium UI by qfx (qfluxstudios@gmail.com)
	Copyright (c) 2021 Elmārs Āboliņš
	https://github.com/qeffects/helium
----------------------------------------------------]]
local eventClass = {}
eventClass.__index = eventClass

function eventClass.new()
	local self = {
		eventSubs = {}
	}

	return setmetatable(self, eventClass)
end

function eventClass:newQueue(name)
	self.eventSubs[name] = {}
end

--Data is the individualized table to pass to each subscriber (or middleware)
function eventClass:sub(name, func, data)
	self.eventSubs[name][func] = {func = func, data = data}
	
	return func
end

function eventClass:unsub(name, func)
	self.eventSubs[name][func] = nil
end

function eventClass:push(name, evntData)
	local pushData = evntData
	for i, e in pairs(self.eventSubs[name]) do
		if self.eventSubs[name].beforeEach then
			pushData = self.eventSubs[name].beforeEach(e.data, evntData) or evntData
		end

		e.func(pushData)
	end
end


return eventClass