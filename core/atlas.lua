--[[--------------------------------------------------
	Helium UI by qfx (qfluxstudios@gmail.com)
	Copyright (c) 2021 Elmārs Āboliņš
	https://github.com/qeffects/helium
----------------------------------------------------]]
local path   = string.sub(..., 1, string.len(...) - string.len(".core.atlas"))
local helium = require(path..'.dummy')
local atlas = {}
atlas.__index = atlas
---@class atlases
local atlases ={}
atlases.__index = atlases
local BLOCK_SIZE = 5
local coefficient = 1.5
local selfRenderTime = false
local sw, sh = love.graphics.getDimensions()

function atlases.create()
	local self = {
		atlases = {}
	}
	self.atlases[1] = atlas.new(sw*1.10, sh*1.10)
	self.atlases[2] = atlas.new(sw*1.10, sh*1.10)

	return setmetatable(self, atlases)
end

function atlases.setBench(time)
	selfRenderTime = time
end

function atlases:getRatio(index)
	return self.atlases[index].taken_area/self.atlases[index].ideal_area
end

function atlases:getFreeArea(index)
	return self.atlases[index].ideal_area - self.atlases[index].taken_area
end

function atlases:assign(element)
	local avg, sum, canvasID = 0, 0, element.context:getCanvasIndex(true) or 1

	if not helium.conf.MANUAL_CACHING then
		for i, e in ipairs(element.renderBench) do
			sum = sum + e
		end

		avg = sum/#element.renderBench
	
		local areaBelow = self:getFreeArea(canvasID)
		local area = element.view.h*element.view.w

		local areaCoef = (2-(self:getRatio(canvasID)) )-(area/(areaBelow/(4+3*self:getRatio(canvasID))))
		local speedCoef = avg/selfRenderTime
	
		if not ((areaCoef+speedCoef)>coefficient) then
			return 
		end
	end

	local elW = element.view.w
	local elH = element.view.h
	local canvas, quad = self.atlases[canvasID]:assignElement(element)
	if not canvas and self.atlases[canvasID].ideal_area < self.atlases[canvasID].taken_area*4 then
		--print('refragmenting ;3')
		self.atlases[canvasID]:refragment()
		canvas, quad = self.atlases[canvasID]:assignElement(element)
		if not canvas then
			--print('ran out of space')
		end
	else
		--print('wont refragment', createdAtlas.ideal_area, createdAtlas.taken_area)
	end
	return canvas, quad, canvasID
end

function atlases:unassign(element)
	local canvasID = element.context:getCanvasIndex(true) or 1
	self.atlases[canvasID]:unassignElement(element)
end

function atlases:unassignAll()
	self.atlases[1].users = {}
	self.atlases[2].users = {}

	self.atlases[1]:unMarkTiles(1, 1, self.atlases[1].tileW, self.atlases[1].tileH)
	self.atlases[2]:unMarkTiles(1, 1, self.atlases[2].tileW, self.atlases[2].tileH)

	self.atlases[1].taken_area = 0
	self.atlases[2].taken_area = 0
end

function atlases:onresize(newW, newH)
	for i, e in ipairs(self.atlases[1].users) do
		e:reassignCanvas()
	end

	for i, e in ipairs(self.atlases[2].users) do
		e:reassignCanvas()
	end

	self.atlases[1] = atlas.new(newW*1.10, newH*1.10)
	self.atlases[2] = atlas.new(newW*1.10, newH*1.10)
end

function atlas.new(w, h)
	local tiles = {}

	local ymax = math.floor(h/BLOCK_SIZE)
	local xmax = math.floor(w/BLOCK_SIZE)
	for y = 1, ymax do
		tiles[y] = {}
		tiles[y].empty = xmax
		for x = 1, xmax do
			tiles[y][x] = {
				taken = false
			}
		end
	end

	local self = {
		w = w,
		h = h,
		tileW = xmax,
		tileH = ymax,
		ideal_area = w*h,
		taken_area = 0,
		canvas = love.graphics.newCanvas(w, h),
		users = {},
		tiles = tiles,
	}

	return setmetatable(self, atlas)
end

function atlas:assignElement(element)
	local elH, elW = element.view.h, element.view.w
	local tileSizeY, tileSizeX = math.ceil(elH/BLOCK_SIZE), math.ceil(elW/BLOCK_SIZE)

	local t, y, x = self:find(tileSizeY, tileSizeX)

	if t then
		local quad, iquad
		--Refragmenting path
		if self.users[element] and self.users[element].quad and self.users[element].interQuad then
			--update by reference owo
			self.users[element].quad:setViewport((x-1)*BLOCK_SIZE, (y-1)*BLOCK_SIZE, elW, elH)
			quad = self.users[element].quad
		else
			quad = love.graphics.newQuad((x-1)*BLOCK_SIZE, (y-1)*BLOCK_SIZE, elW, elH, self.w, self.h)
		end

		self.users[element] = {
			element = element,
			x = x,
			y = y,
			w = tileSizeX,
			h = tileSizeY,
			quad = quad,
		}

		self:markTiles(x, y, tileSizeX, tileSizeY)
		self.taken_area = self.taken_area + ((tileSizeY*BLOCK_SIZE)*(tileSizeX*BLOCK_SIZE))

		return self.canvas, self.users[element].quad
	else
		print('failed to allocate :X')
		return false
	end
end

local function sortFunc(el1, el2)
	return el1.view.h > el2.view.h
end

function atlas:refragment()
	self:unMarkTiles(1, 1, self.tileW-1, self.tileH-1)
	self.taken_area = 0

	local elementArray = {}
	
	for i, e in pairs(self.users) do
		i.settings.needsRendering = true
		table.insert(elementArray, i)
	end

	--self.users = {}
	love.graphics.setCanvas(self.canvas)
	love.graphics.clear(0,0,0,0)
	love.graphics.setCanvas()
	--Should be sorted large to small
	table.sort(elementArray, sortFunc)

	for index, element in ipairs(elementArray) do
		self:assignElement(element)
	end
end

function atlas:markTiles(x, y, w, h)
	for y = y, y+h do
		self.tiles[y].empty = self.tiles[y].empty - w
		
		for x = x, x+w do
			self.tiles[y][x].taken = true
		end
	end
end

function atlas:unMarkTiles(x, y, w, h)
	for y = y, y+h do
		self.tiles[y].empty = self.tiles[y].empty + w
		
		for x = x, x+w do
			self.tiles[y][x].taken = false
		end
	end
end

--Work only with rounded values inside here
function atlas:find(sizeY, sizeX)
	local maxX, maxY = #self.tiles[1], #self.tiles

	for y = 1, #self.tiles-(sizeY+1) do
		local skipUntilX=0
		if self.tiles[y].empty > sizeY then
			for x = 1, #self.tiles[1]-sizeX do
				if not self.tiles[y][x].taken and x>skipUntilX then
					local result, y, x = self:slice(y, x, sizeY, sizeX)

					if result then 
						return true, y, x
					else
						skipUntilX = x
					end
				end
			end
		end
	end

	return false
end

function atlas:slice(startY, startX, sizeY, sizeX)
	for y = startY, startY+sizeY do
		for x = startX, startX+sizeX do
			if self.tiles[y][x].taken then
				return false, y, x
			end
		end
	end
	return true, startY, startX
end

function atlas:unassignElement(element)
	local user = self.users[element]
	if user then
		self:unMarkTiles(user.x, user.y, user.w, user.h)
		self.taken_area = self.taken_area - ((user.w*BLOCK_SIZE)*(user.h*BLOCK_SIZE))
		self.users[element] = nil
	end
end

return atlases