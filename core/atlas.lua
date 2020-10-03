local atlas = {}
local createdAtlas
local intermediaryCanvas
atlas.__index = atlas
local BLOCK_SIZE = 5

function atlas.load()
	if not createdAtlas then
		atlas.init()
	end
end

function atlas.getRatio()
	return createdAtlas.taken_area/createdAtlas.ideal_area
end

function atlas.getFreeArea()
	return createdAtlas.ideal_area - createdAtlas.taken_area
end

local sw, sh = love.graphics.getDimensions()
function atlas.init()

	createdAtlas = atlas.new(sw*2, sh)
	intermediaryCanvas = love.graphics.newCanvas(sw, sh)
	atlas.createdAtlas = createdAtlas
	atlas.interCanvas = intermediaryCanvas
end

function atlas.assign(element)
	local elW = element.view.w
	local elH = element.view.h
	local canvas, quad, interQuad = createdAtlas:assignElement(element)
	if not canvas and createdAtlas.ideal_area < createdAtlas.taken_area*4 then
		--print('refragmenting ;3')
		createdAtlas:refragment()
		canvas, quad, interQuad = createdAtlas:assignElement(element)
		if not canvas then
			--print('ran out of space')
		end
	else
		--print('wont refragment', createdAtlas.ideal_area, createdAtlas.taken_area)
	end
	return canvas, quad, interQuad
end

function atlas.unassign(element)
	createdAtlas:unassignElement(element)
end

function atlas.unassignAll()
	createdAtlas.users = {}
	createdAtlas:unMarkTiles(1, 1, createdAtlas.tileW, createdAtlas.tileH)
	createdAtlas.taken_area = 0
end

function atlas.onscreenchange(newW, newH)

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
		if self.users[element] then
			--update by reference owo
			self.users[element].quad:setViewport((x-1)*BLOCK_SIZE, (y-1)*BLOCK_SIZE, elW, elH)
			self.users[element].interQuad:setViewport(0, 0, elW, elH)
			quad = self.users[element].quad
			iquad = self.users[element].interQuad
		else
			quad = love.graphics.newQuad((x-1)*BLOCK_SIZE, (y-1)*BLOCK_SIZE, elW, elH, self.w, self.h)
			iquad = love.graphics.newQuad(0, 0, elW, elH, sw, sh)
		end

		self.users[element] = {
			element = element,
			x = x,
			y = y,
			w = tileSizeX,
			h = tileSizeY,
			quad = quad,
			interQuad = iquad
		}

		self:markTiles(x, y, tileSizeX, tileSizeY)
		self.taken_area = self.taken_area + ((tileSizeY*BLOCK_SIZE)*(tileSizeX*BLOCK_SIZE))

		return self.canvas, self.users[element].quad, iquad
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
	self:unMarkTiles(user.x, user.y, user.w, user.h)
	self.taken_area = self.taken_area - ((user.w*BLOCK_SIZE)*(user.h*BLOCK_SIZE))
	self.users[element] = nil
end

return atlas