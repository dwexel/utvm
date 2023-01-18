assert(graphicsState)

local cpml = require("lib.cpml")
local updateArrows = tiny.system({
	input = "",
	arrows = {},
	arrowHeight = 0.3
})
updateArrows.updateSystem = true
updateArrows.processPlaying = true


function updateArrows:update(dt)
	local gs = graphicsState
	if gs.updateArrowsFlag then
		gs.updateArrowsFlag = false

		local current = levelPos[playerPos]			
		local c = cpml.vec3(current)

		-- 2 targets for 2 arrows
		for i = 1, 2 do
			local target = levelPos[current.cons[i]]
			target = cpml.vec3(target)
			local v = (target - c):normalize()
			local f = c + (v * 0.1)
			self.arrows[i]:lookAtFrom({f.x, f.y, self.arrowHeight}, target)

			self.arrows[i].point_i = current.cons[i]
		end
	end
end

return updateArrows