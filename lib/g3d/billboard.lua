-- local newMatrix = require(g3d.path .. "/matrices")

-- local square_verts = {
-- 	{ 1,  1, 0, 1,0},
-- 	{-1, -1, 0, 0,1},
-- 	{ 1, -1, 0, 0,0},
-- 	{ 1,  1, 0, 1,0},
-- 	{-1,  1, 0, 1,1},
-- 	{-1, -1, 0, 0,1},
-- }

-- for i = 1, #square_verts do
-- 	square_verts[i][1] = square_verts[i][1] * 0.1
-- 	square_verts[i][2] = square_verts[i][2] * 0.1
-- 	square_verts[i][3] = square_verts[i][3] * 0.1
-- end


-- local bb = {}
-- bb.__index = bb

-- bb.vertexFormat = {
-- 	{"VertexPosition", "float", 3},
-- 	{"VertexTexCoord", "float", 2}
-- }

-- bb.shader = love.graphics.newShader[[
-- 	#ifdef VERTEX
-- 		uniform mat4 modelMatrix;
-- 		uniform mat4 viewMatrix;
-- 		uniform mat4 projectionMatrix;
-- 		uniform bool isCanvasEnabled;
-- 		vec4 position(mat4 transform_projection, vec4 vertexPosition)
-- 		{
-- 			mat4 modelView = viewMatrix * modelMatrix;
-- 			modelView[0] = vec4(1, 0, 0, 0);
-- 			modelView[1] = vec4(0, 1, 0, 0);
-- 			modelView[2] = vec4(0, 0, 1, 0);
-- 			vec4 screenPosition = projectionMatrix * modelView * vertexPosition;
-- 			if (isCanvasEnabled) {
-- 				screenPosition.y *= -1.0;
-- 			}
-- 			return screenPosition;
-- 		}
-- 	#endif	
-- ]]

-- function newBillboard(texture, translation)
-- 	assert(type(texture) == "userdata", "wrong type")

-- 	local self = setmetatable({}, bb)

-- 	self.isBillboard = true
-- 	self.mesh = love.graphics.newMesh(billboard.vertexFormat, square_verts, "triangles", "static")
-- 	self.mesh:setTexture(texture)
-- 	self.matrix = g3d.newMatrix()

-- 	self:setTransform(translation or {0,0,0}, {0,0,0}, {1,1,1})

-- 	return self
-- end

-- function bb:setTransform(translation, rotation, scale)
--     self.translation = translation or self.translation
--     self.rotation = rotation or self.rotation
--     self.scale = scale or self.scale
--     self:updateMatrix()
-- end

-- function bb:updateMatrix()
--     self.matrix:setTransformationMatrix(self.translation, self.rotation, self.scale)
-- end

-- function bb:draw()
-- 	love.graphics.setShader(self.shader)
-- 	self.shader:send("modelMatrix", self.matrix)

-- 	-- ahhhhhhhhhhhhhhhhhhhhhhhhh


-- end

-- return newBillboard
