--[[--------------------------------------------------
	Helium UI by qfx (qfluxstudios@gmail.com)
	Copyright (c) 2019 Elmārs Āboliņš
	gitlab.com/project link here
----------------------------------------------------]]
local path = ...
local helium  = require(path..".dummy")
helium.utils = require(path..".utils")
helium.element = require(path..".core.element")
helium.input = require(path..".core.input")
helium.elementBuffer = {}

function helium.render()
	for i, e in ipairs(helium.elementBuffer) do
		e:externalRender()
	end
end

function helium.update()
	local remove = false

	for i, e in ipairs(helium.elementBuffer) do
		if e.settings.remove then
			remove = true
		else
			e:externalUpdate()
		end
	end

	if remove then
		helium.utils.ArrayRemove(helium.elementBuffer, function(t, i)
			--returns false or (true if nil)
			return (not t[i].settings.remove)
		end)
	end

end

--[[
	A user doesn't have to use this particular love.run

	*.element.bufferUpdate()
	*.draw()

	Need to be called either through love.update and love.draw respectively
	or put in to your custom love.run

	And for inputs to work the love.event part needs to look something like this:

	for name, a,b,c,d,e,f in love.event.poll() do
		if name == "quit" then
			if not love.quit or not love.quit() then
				return a
			end
		end

		if not(gui.eventHandlers[name]) or not(helium.eventHandlers[name](a, b, c, d, e, f)) then
			love.handlers[name](a, b, c, d, e, f)
		end
	end
]]
function love.run()

	if love.math then
		love.math.setRandomSeed(os.time())
	end

	if love.load then love.load(arg) end

	-- We don't want the first frame's dt to include time taken by love.load.
	if love.timer then love.timer.step() end

	local dt = 0

	-- Main loop time.
	while true do
		-- Process events.
		if love.event then
			love.event.pump()
			for name, a,b,c,d,e,f in love.event.poll() do
				if name == "quit" then
					if not love.quit or not love.quit() then
						return a
					end
				end

				if not(helium.input.eventHandlers[name]) or not(helium.input.eventHandlers[name](a, b, c, d, e, f)) then
					love.handlers[name](a, b, c, d, e, f)
				end
			end
		end


		-- Update dt, as we'll be passing it to update
		if love.timer then
			love.timer.step()
			dt = love.timer.getDelta()
		end

		-- Call update and draw
		if love.update then love.update(dt) end -- will pass 0 if love.timer is disabled
		helium.update()

		if love.graphics and love.graphics.isActive() then
			love.graphics.clear(love.graphics.getBackgroundColor())
			love.graphics.origin()
			if love.draw then love.draw() end
			helium.render()
			love.graphics.present()
		end


		if love.timer then love.timer.sleep(0.00001) end
	end

end

return helium