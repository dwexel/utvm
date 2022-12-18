--[[
	split code up into the smallest parts

	g3d camera only uses the "look_at" code to move - i want to learn more

	export properties:
		axes:
			x > forward
			z > up


	globals
		player info
		level info
		graphics state info


	probs
		billboards not scaling! why!	
	

	mod 
		non-clearing canvas
		non depth testing
		scramble verts in memory
		wireframe mode

	todo
		use a load level system

	use spritebatch to make it all
		glitter

	have some kind of, recursive function to create a table of positions based on what each vertex is connected to	
		could use a shader to make atlas animations


	globals are good when used sparingly

	i am going in the right direction with the input system.
	it would be cool if I could systematize it more
]]


local world
local lg = love.graphics
local width, height = love.graphics.getDimensions()
g3d = require("lib/g3d")
tiny = require("lib.tiny")

local function loadPositions(path)
	local result = {}
	-- how does this work exactly.
	local connections = {}
	for line in love.filesystem.lines(path) do
		local words = {}
		for word in line:gmatch "([^%s]+)" do
			table.insert(words, word)
		end
		if words[1] == "v" then
			table.insert(result, {tonumber(words[2]), tonumber(words[3]), tonumber(words[4])})
		elseif words[1] == "l" then
			print(line)
		end
	end
	return result
end

local square_verts = {
	{ 1,  1, 0, 1,0},
	{-1, -1, 0, 0,1},
	{ 1, -1, 0, 0,0},
	{ 1,  1, 0, 1,0},
	{-1,  1, 0, 1,1},
	{-1, -1, 0, 0,1},
}

local billboard = {
	vertexFormat = {
		{"VertexPosition", "float", 3},
		{"VertexTexCoord", "float", 2}
	}
}

billboard.shader = love.graphics.newShader[[
	#ifdef VERTEX
		uniform mat4 modelMatrix;
		uniform mat4 viewMatrix;
		uniform mat4 projectionMatrix;
		uniform bool isCanvasEnabled;
		vec4 position(mat4 transform_projection, vec4 vertexPosition)
		{
			mat4 modelView = viewMatrix * modelMatrix;
			modelView[0] = vec4(1, 0, 0, 0);
			modelView[1] = vec4(0, 1, 0, 0);
			modelView[2] = vec4(0, 0, 1, 0);
			vec4 screenPosition = projectionMatrix * modelView * vertexPosition;
			if (isCanvasEnabled) {
				screenPosition.y *= -1.0;
			}
			return screenPosition;
		}
	#endif	
]]

for i = 1, #square_verts do
	square_verts[i][1] = square_verts[i][1] * 0.1
	square_verts[i][2] = square_verts[i][2] * 0.1
	square_verts[i][3] = square_verts[i][3] * 0.1
end

function newBillboard(tex, pos)
	assert(type(tex) == "userdata", "wrong type")

	local self = setmetatable({}, g3d.modelMT)
	self.isBillboard = true
	self.mesh = love.graphics.newMesh(billboard.vertexFormat, square_verts, "triangles", "static")
	self.mesh:setTexture(tex)
	self.matrix = g3d.newMatrix()
   self:setTransform(pos or {0,0,0}, {0,0,0}, {1,1,1})

	return self
end

local gamestates = {PLAY = 1, PAUSED = 2}
local gamestate = 1

function gamestates:switch()
	if gamestate == gamestates.PAUSED then 
		gamestate = gamestates.PLAY
		return
	end
	if gamestate == gamestates.PLAY then
		gamestate = gamestates.PAUSED
		return 
	end
end

local function dotProduct(a1,a2, b1,b2)
    return a1*b1 + a2*b2
end

local function newSB(tex, pos)
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



---------------------------------------
-- globals
---------------------------------------

level = {
	positions = nil
}

function level.wrap(i)
	if i > #level.positions then
		i = 1
	elseif i < 1 then
		i = #level.positions
	end
	return i
end

player = {
	pos = 1
}

graphicsState = {
	shader = g3d.shader,
	camera = g3d.camera,
	billboardShader = billboard.shader
}

do
	local gs = graphicsState
	gs.camera.r = 0
	gs.shader:send("viewMatrix", gs.camera.viewMatrix)
	gs.shader:send("projectionMatrix", gs.camera.projectionMatrix)
	gs.billboardShader:send("viewMatrix", gs.camera.viewMatrix)
	gs.billboardShader:send("projectionMatrix", gs.camera.projectionMatrix)
end


inputQueue = ""


-----------------------------------------
-- systems
-----------------------------------------


local spin = tiny.processingSystem()
spin.updateSystem = true
spin.processPlaying = true
spin.filter = tiny.requireAll("spinning")

local a = 0
local twoPI = 2*math.pi
function spin:process(e, dt)
	a = (a + dt/2) % twoPI
	e:setRotation(0, 0, a)
end




local updatePlayerPos = require("systems.updatePlayerPos")
local renderTarget = require("systems.renderTarget")
local drawMenu = require("systems.drawMenu")

-----------------------------------------
-- driver
-----------------------------------------


function love.load()
	local globe = g3d.newModel("assets/sphere.obj", "assets/earth.png", {0, 0, 0}, nil, 0.5):compress()
	globe.spinning = true

	local car = g3d.newModel("assets/car.obj", "assets/1377 car.png", {2, -1, 0}, {0, 0.5, 0}, 0.05):compress()
	local level_background = g3d.newModel("assets/boo.obj", "assets/alexander ross.png"):compress()
	
	-- exported at 0.1 
	fish = g3d.newModel("assets/Goldfish.obj", "assets/1377 car.png", {-0.5, -4, 0.2}, nil, 0.5):compress()
	fish.color = {1, 0.5, 0.6}

	local burger = newSB(lg.newImage("assets/burger.png"), {0.5, 0, 2})


	local ui = {
		menu = {"resume", "exit"},
		font = lg.newFont(20),
		x = 500, 
		y = 500
	}

	world = tiny.world(
		car,
		globe,
		level_background,
		fish,
		burger,
		ui,

		spin,

		updatePlayerPos,
		renderTarget,
		drawMenu,

		require("systems.updateCamera"),
		require("systems.drawModels")

	)

	level.positions = loadPositions("assets/positions.obj")
	local bi = lg.newImage("assets/1377 car.png")
	for _, v in ipairs(level.positions) do
		world:addEntity(newBillboard(bi, v))
	end
end


local playingFilter = tiny.requireAll("updateSystem", "processPlaying")
local pausedFilter = tiny.requireAll("updatesytem", "processPaused")

local drawPlayingFilter = tiny.requireAll("drawSystem", tiny.rejectAny("processPaused"))
local drawPausedFilter = tiny.requireAll("drawSystem")

function love.update(dt)
	if gamestate == gamestates.PLAY then
		world:update(dt, playingFilter)
	elseif gamestate == gamestates.PAUSED then
		world:update(dt, pausedFilter)
	end
end

function love.draw()
	if gamestate == gamestates.PLAY then
		world:update(nil, drawPlayingFilter)
	elseif gamestate == gamestates.PAUSED then
		world:update(nil, drawPausedFilter)
	end
end

function love.keypressed(key, scancode, isrepeat)
	if key == "escape" then
		gamestates.switch()
	elseif key == "q" then
		love.event.quit()
	end

	updatePlayerPos.input = key
	renderTarget.input = key
	drawMenu.input = key


	-- inputQueue = key

	-- if key == "w" then
	-- 	updatePlayerPos.inputQueue = 1
	-- elseif key == "s" then
	-- 	updatePlayerPos.inputQueue = -1
	-- end

	-- if key == "p" then
	-- 	local p = graphicsState.camera.position
	-- 	fish:lookAt(p, nil)
	-- 	print(table.concat(p, ", "))
	-- end

	-- local n = tonumber(key)
	-- if n then
	-- 	renderTarget.mode = n
	-- end

	-- drawMenu.inputQueue = key
end

function love.resize(w, h)
	width, height = w, h

	local gs = graphicsState
   gs.camera.aspectRatio = love.graphics.getWidth()/love.graphics.getHeight()
   gs.camera.updateProjectionMatrix()
	gs.shader:send("projectionMatrix", gs.camera.projectionMatrix)
	gs.billboardShader:send("projectionMatrix", gs.camera.projectionMatrix)

end