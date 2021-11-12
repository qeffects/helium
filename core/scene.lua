--[[--------------------------------------------------
	Helium UI by qfx (qfluxstudios@gmail.com)
	Copyright (c) 2021 Elmārs Āboliņš
	https://github.com/qeffects/helium
----------------------------------------------------]]

local path  = string.sub(..., 1, string.len(...) - string.len(".core.scene"))

local atlas  = require(path..'.core.atlas')
local helium = require(path..'.dummy')
local input  = require(path..'.core.input')

---@class scene
local scene = {
	activeScene = nil
}
scene.__index = scene

---comment
---@param cached boolean @whether to enable caching on this scene
---@return scene
function scene.new(cached)
	---@type scene
	local self = {
		atlas = cached and atlas.create() or nil,
		cached = cached or false,
		subscriptions = {},
		buffer = {},
		scaleX = 1,
		scaleY = 1,
	}
	local newScene = setmetatable(self, scene)
	newScene:activate()

	return newScene
end

local skipframes = 10
function scene.bench()
	if skipframes == 0 then
		local startTime = love.timer.getTime()
		
		for i = 1, 20 do
			love.graphics.print(i,-100,-100)
		end
		
		helium.setBench((love.timer.getTime()-startTime)/5)
	elseif skipframes>0 then
		skipframes = skipframes - 1
	end
end

function scene:setPixelScale(x, y)
	if self.scaleX == x and self.scaleY == (y or x) then
		return
	end
	self.scaleX = x
	self.scaleY = y or x

	for i, elem in ipairs(self.buffer) do
		elem.context:scaleChanged()
	end
end

---Activates this scene
function scene:activate()
	scene.activeScene = self
end

---Keeps the scene in memory with potentially the atlas
function scene:deactivate()
	scene.activeScene = nil
end

---Recreates this scene 
function scene:reload()
	self.atlas = self.cached and atlas.create() or nil
	self.ioSubscriptions = {}
	self.buffer = {}
end

---Nukes the scene and it's elements and atlases and subscriptions from memory
---To achieve same state as after creation, use reload
function scene:unload()
	self.atlas = nil
	self.buffer = nil
	self.ioSubscriptions = nil
end

---Draws this scene and it's elements
function scene:draw()
	helium.stack.newFrame()
	if not helium.benchNum then
		scene.bench()
	end
	
	love.graphics.push("all")
	love.graphics.setColor(1,1,1,1)
	for i, e in ipairs(self.buffer) do
		e:externalRender()
	end
	love.graphics.pop()

end

function scene:resize(nw, nh)
	if self.atlas then
		self.atlas:onresize(nw, nh)
	end
end

function scene:drawAtlases(x, y)
	if self.atlas then
		love.graphics.push()
		local aw = self.atlas.atlases[1].canvas:getWidth()
		local ah = self.atlas.atlases[1].canvas:getHeight()
		love.graphics.print('Atlas 1:', x, y)
		love.graphics.print('Atlas 2:', x+aw*0.45, y)
		love.graphics.translate(0,20)
		love.graphics.scale(0.45)
		love.graphics.draw(self.atlas.atlases[1].canvas, x, y)
		love.graphics.draw(self.atlas.atlases[2].canvas, x+aw, y)
		love.graphics.rectangle('line', x, y, aw, ah)
		love.graphics.rectangle('line', x+aw, y, aw, ah)
		love.graphics.pop()
	end
end

function scene:drawInputBoxes()
	for i, list in pairs(self.subscriptions) do
		for ind, sub in ipairs(list) do
			if sub.x then
				love.graphics.setColor(1,1,0)
				love.graphics.rectangle('line', sub.x, sub.y, sub.w, sub.h)
			end
		end
	end
end

---Updates this scene and it's elements
function scene:update()
	for i = 1, #self.buffer do
		if self.buffer[i]:externalUpdate() then
			table.remove(self.buffer, i)
		end
	end
end

return scene