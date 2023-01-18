assert(g3d)
local lg = love.graphics

local square_verts = {
	{ 1,  1, 0, 1,0},
	{-1, -1, 0, 0,1},
	{ 1, -1, 0, 0,0},
	{ 1,  1, 0, 1,0},
	{-1,  1, 0, 1,1},
	{-1, -1, 0, 0,1},
}

for i = 1, #square_verts do
	square_verts[i][1] = square_verts[i][1] * 0.1
	square_verts[i][2] = square_verts[i][2] * 0.1
end

local bbVertexFormat = {
	{"VertexPosition", "float", 3},
	{"VertexTexCoord", "float", 2}
}



---------------------------------
-- entity generators
---------------------------------


local types = {}

function types.newSB(tex, pos)
	assert(type(tex) == "string", "wrong type")
	tex = lg.newImage(tex)
	local sb = lg.newSpriteBatch(tex, 100, "static")
	local matrix_scale = 0.001
	local pic_scale = 1
	local w, h = tex:getWidth(), tex:getHeight()

	for i = 0, 10, 2 do
		for j = 0, 10, 2 do
			sb:add(i*w, j*h)
		end
	end

	local defaultRotation = {math.pi/2, 0, math.pi/2}
	local self = setmetatable({}, g3d.modelMT)
	self.isSpriteBatch = true
	self.matrix = g3d.newMatrix()
	self.matrix:setTransformationMatrix(pos, defaultRotation, {-matrix_scale, -matrix_scale, matrix_scale})
	self.mesh = sb
	return self
end



function types.newBillboard(tex, pos)
	assert(type(tex) == "userdata", "wrong type")

	local self = setmetatable({}, g3d.modelMT)
	self.isBillboard = true
	self.mesh = love.graphics.newMesh(bbVertexFormat, square_verts, "triangles", "static")
	self.mesh:setTexture(tex)
	self.matrix = g3d.newMatrix()
   self:setTransform(pos or {0,0,0}, {0,0,0}, {1,1,1})

	return self
end

function types.newArrow()
	local self = g3d.newModel(square_verts, "assets/arrow2.png", nil, nil, 0.4)

	self.point_i = nil
	self.onClick = function(self)
		assert(playerPos)
		assert(levelPos)
		assert(graphicsState)

		playerPos = self.point_i
		graphicsState.camera.position[1] = levelPos[playerPos][1]
		graphicsState.camera.position[2] = levelPos[playerPos][2]

		graphicsState.updateArrowsFlag = true
	end

	return self
end

-- local tweenTypes = {QUAT = 1}

function types.newTween(endTime, initialObject, finalObject)
	assert(endTime)

	return {
		t = 0,
		endTime = endTime,
		finished = true,
		initial = initialObject,
		final = finalObject
	}
end






return types