--[[--------------------------------------------------
	Helium UI by qfx (qfluxstudios@gmail.com)
	Copyright (c) 2019 Elmārs Āboliņš
	gitlab.com/project link here
----------------------------------------------------]]
local path     = ...
local helium   = require(path..".dummy")
helium.conf    = require(path..".conf")
helium.utils   = require(path..".utils")
helium.element = require(path..".core.element")
helium.input   = require(path..".core.input")
helium.loader  = require(path..".loader")
helium.elementBuffer = {}
helium.__index = helium
setmetatable(helium, {__call = function(s,chunk)
	return function(param,w,h)
		return helium.element(chunk,nil,w,h,param)
	end
end})

function helium.render()
	--We don't want any side effects affecting internal rendering
	love.graphics.reset()

	for i, e in ipairs(helium.elementBuffer) do
		e:externalRender()
	end
end

function helium.update(dt)
	if helium.conf.HOTSWAP then
		helium.loader.update(dt)
	end

	for i = #helium.elementBuffer, 1, -1 do
		if helium.elementBuffer[i]:externalUpdate() then
			table.remove(helium.elementBuffer,i)
		end
	end
end

--[[
	A user doesn't have to use this particular love.run

	helium.render()
	helium.update(dt)

	Need to be called either through love.update and love.draw respectively
	or put in to your custom love.run

	And for inputs to work the love.event part needs to look something like this:

	for name, a,b,c,d,e,f in love.event.poll() do
		if name == "quit" then
			if not love.quit or not love.quit() then
				return a
			end
		end

		if not(helium.eventHandlers[name]) or not(helium.eventHandlers[name](a, b, c, d, e, f)) then
			love.handlers[name](a, b, c, d, e, f)
		end
	end
]]
if helium.conf.AUTO_RUN then
	function love.run()
		if love.load then love.load(love.arg.parseGameArguments(arg), arg) end

		-- We don't want the first frame's dt to include time taken by love.load.
		if love.timer then love.timer.step() end

		local dt = 0

		-- Main loop time.
		return function()
			-- Process events.
			if love.event then
				love.event.pump()
				for name, a,b,c,d,e,f in love.event.poll() do
					if name == "quit" then
						if not love.quit or not love.quit() then
							return a or 0
						end
					end

					if not(helium.input.eventHandlers[name]) or not(helium.input.eventHandlers[name](a, b, c, d, e, f)) then
						love.handlers[name](a, b, c, d, e, f)
					end
				end
			end


			-- Update dt, as we'll be passing it to update
			if love.timer then dt = love.timer.step() end

			-- Call update and draw
			if love.update then love.update(dt) end -- will pass 0 if love.timer is disabled
			helium.update(dt)

			if love.graphics and love.graphics.isActive() then
				love.graphics.origin()
				love.graphics.clear(love.graphics.getBackgroundColor())

				if love.draw then love.draw() end
				helium.render()

				love.graphics.present()
			end

			if love.timer then love.timer.sleep(0.001) end
		end
	end
end

--Typescript
helium.helium = helium
return helium