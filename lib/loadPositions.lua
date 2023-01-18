--[[
	node:
		x, y, z
		list of connections (indices)
		is spawn point? t/f
]]

return function(path)
	local result = {}
	for line in love.filesystem.lines(path) do
		local words = {}
		for word in line:gmatch "([^%s]+)" do
			table.insert(words, word)
		end
		if words[1] == "v" then
			local x, y, z, sp = tonumber(words[2]), tonumber(words[3]), tonumber(words[4]), tonumber(words[5])
			local point = {x, y, z}
			point.cons = {} -- conections
			table.insert(result, point)
			if sp == 1 then 
				point.isSpawnPoint = true
			end
		elseif words[1] == "l" then
			p1, p2 = tonumber(words[2]), tonumber(words[3])
			table.insert(result[p1].cons, p2)
			table.insert(result[p2].cons, p1)
		end
	end
	return result
end

