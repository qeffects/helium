
local path = string.sub(..., 1, string.len(...) - string.len(".loader"))
local helium = require(path..'.dummy')
local elements = {}
local debugLoader = {}
--Return level: 1--string; 2--chunk; 3--return value; default: element factory
local function loader(path)
	local succ = true

	--File string
	local fileContents, err = love.filesystem.read(path)
	
	if fileContents==nil then
		print('Error loading ',path,':',tostring(err),', will continue watching!')
		succ = false
	end

	local t, lastLoaded
	if succ then
		t = love.filesystem.getInfo(path)
		lastLoaded = t['modtime']
	end

	--Chunk
	local status, err
	if succ then
		status, err = pcall(loadstring,fileContents)
	end

	if status==false or status==nil then
		print('Error compiling ',path,':',tostring(err),', will continue watching!')
		succ = false
	end

	--Return values
	local ret
	if succ then
		succ, ret = pcall(err,path)
		if not succ then
			print('Error calling ',path,':',tostring(ret))
		end
	end

	return fileContents, err, ret, lastLoaded
end

debugLoader.loader = function(path,returnLevel)
	local level = returnLevel or 6
	if elements[path] then
		return elements[path][level]
	end

	local setfuncs = {}

	local fileContents, func, ret, lastLoaded = loader(path)
	local reloader = function(setFunc)
		setfuncs[#setfuncs+1] = setFunc
	end

	local factory = function(param,w,h)
		return helium.element(ret, reloader, w, h, param)
	end

	elements[path] = {fileContents, func, ret, path, lastLoaded, factory, setfuncs = setfuncs}
	return elements[path][level]
end

local counter = 0
function debugLoader.update(dt)
	counter = counter+dt
	if counter>2 then
		for ind, elem in pairs(elements) do
			--Get the current last save time
			local t = love.filesystem.getInfo(elem[4])
			local ll = t['modtime']
			if ll ~= elem[5] then
				--If last save time differs then start reload sequence
				local _, _, ret, lastLoaded = loader(elem[4])


				local setfuncs = {}
				
				local reloader = function(setFunc)
					setfuncs[#setfuncs+1] = setFunc
				end

				local factory = function()
					return helium.element(ret, reloader)
				end

				elem[5] = lastLoaded

				elem[6] = factory

				for i, func in ipairs(elem.setfuncs) do
					func(ret)
				end
			end
		end
		counter = 0
	end
end

if helium.conf.PURE_G then
	HeliumLoader = debugLoader.loader
end

return debugLoader