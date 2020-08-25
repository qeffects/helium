local atlas = {}
local atlases = {}
atlas.__index = atlas
local BLOCK_SIZE = 10

function atlas.init()
	local w, h = love.graphics.getDimensions()

	
end

function atlas.onscreenchange(newW,newH)

end

function atlas.new(w, h)
	local tiles = {}

	local ymax = math.floor(h/BLOCK_SIZE)
	for y = 1, ymax do
		tiles[y] = {}
		tiles[y].empty = ymax
		for x = 1, math.floor(w/BLOCK_SIZE) do
			tiles[y][x] = {
				taken = false
			}
		end
	end

	local self = {
		w = w,
		h = h,
		ideal_area = w*h,
		canvas = love.graphics.newCanvas(w, h),
		users = {},
		tiles = tiles,
	}

	return setmetatable(self, atlas)
end

function atlas:assignElement(elW, elH, element)
	local tileSizeY, tileSizeW = math.ceil(elH/BLOCK_SIZE), math.ceil(elW/BLOCK_SIZE)

end

--Work only with rounded values inside here
function atlas:find(sizeY, sizeX)
	for y = 1, #self.tiles do
		local skipUntilX=0
		if self.tiles[y].empty > sizeY then
			for x = 1, #self.tiles[1] do
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
end

function atlas:slice(startY, startX, sizeY, sizeX)
	for y = startY, startY+sizeY do
		for x = startX, sizeX do
			if self.tiles[y][x].taken then
				return false, y, x
			end
		end
	end
	return true
end

function atlas:unassignElement(element)

end

return atlas