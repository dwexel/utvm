assert(player)
assert(level)

local updatePlayerPos = tiny.system({
	input = ""
})
updatePlayerPos.updateSystem = true
updatePlayerPos.processPlaying = true

function updatePlayerPos:update(dt)
	local d = 0

	if self.input == "w" then 
		d = 1 
	elseif self.input == "s" then
		d = -1
	end

	-- if self.inputQueue ~= 0 then
	-- 	player.pos = level.wrap(player.pos + self.inputQueue)
	-- 	local cam = graphicsState.camera
	-- 	-- view vector
	-- 	local vx = cam.target[1]-cam.position[1]
	-- 	local vy = cam.target[2]-cam.position[2]
	-- 	-- local nextPosition = level.positions[1]
	-- 	local dx = -cam.position[1]
	-- 	local dy = -cam.position[2]
	-- 	local dot = dotProduct(vx,vy, dx,dy)
	-- 	if dot < 0 then
	-- 		print("away from origin")
	-- 	else
	-- 		print("towards origin")
	-- 	end
	-- 	self.inputQueue = 0
	-- end
end

return updatePlayerPos

