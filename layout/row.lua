return function(x, y, width, height, children, hpad, vpad, alignX)
	local carriagePos = 0
	if children then
		for i, e in ipairs(children) do
			local w, _ = e:getSize()
			e:draw(x+carriagePos+hpad, y+vpad)
			carriagePos = carriagePos + w + vpad
		end
	end
end