local updateCamera = tiny.system(graphicsState.camera)
updateCamera.updateSystem = true
updateCamera.processPlaying = true

function updateCamera:update(dt)
	local kd = love.keyboard.isDown
	local ix, iy = 0, 0
	local speed = 2

	if kd("a") then ix = -dt elseif kd("d") then ix = dt end
	self.r = (self.r - ix*speed) % (math.pi*2)
	self.lookInDirection(nil,nil,nil, self.r)

	-- snap to positions
	-- self.position[1] = levelPos[playerPos][1]
	-- self.position[2] = levelPos[playerPos][2]
	-- self.position[3] = levelPos[playerPos][3]

	-- move based on look direction
	if kd("w") then iy = -dt elseif kd("s") then iy = dt end
	local lx = math.cos(self.r) * -iy
	local ly = math.sin(self.r) * -iy
	self.position[1] = self.position[1] + lx	
	self.position[2] = self.position[2] + ly
end

return updateCamera