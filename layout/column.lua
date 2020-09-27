return function(x, y, width, height, children, hpad, vpad, alignX)
	local carriagePos = 0
	if children then
		for i, e in ipairs(children) do
			local _, h = e:getSize()
			e:draw(x, y+carriagePos+vpad)
			carriagePos = carriagePos + h + vpad
		end
	end
	print('finished layout')
end