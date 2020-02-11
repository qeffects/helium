local utils = {}

function utils.ArrayRemove(t, fnKeep)
	local j, n = 1, #t;

	for i=1,n do
		if fnKeep(t, i, j) then
			-- Move i's kept value to j's position, if it's not already there.
			if i ~= j then
				t[j] = t[i];
				--t[i] = nil;
			end
			j = j + 1; -- Increment position of where we'll place the next kept value.
		end --else
		t[i] = nil; -- in both if cases you nil it sooooo
		--end
	end

	return t;
end

function utils.tableMerge(t, bt)
	for k, v in pairs(t) do
		if v ~= bt[k] then
			bt[k] = v
		end
	end
end

return utils