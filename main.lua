--[[
	split code up into the smallest parts

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
		draw each mesh with only one color


	use spritebatch to make it all
		glitter

	have some kind of, recursive function to create a table of positions based on what each vertex is connected to	
		could use a shader to make atlas animations



	thoughts
		globals are good when used sparingly

		i am going in the right direction with the input system.
		it would be cool if I could systemetize it more

		it would be cool if tiny ecs had a way to implement a system that could get called when-needed,
		rather than every frame. I guess that's just the observer pattern


	todo:
		split pixel code and vertex code


	related:
		use system indexes to set order
		maybe using flags is convoluted



	use loadstring to load levels?
		evaluates in a global context! that's ok...

	coroutines exist
		use them for the picking function
	

	leverage love graphics state more
		can use custom shaders to draw to multiple canvases at once?


	it would be cool to make the picking as modular as possible




	new systems might help!
	help 
	help!


]]



local world
local lg = love.graphics
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

for i = 1, #square_verts do
	square_verts[i][1] = square_verts[i][1] * 0.1
	square_verts[i][2] = square_verts[i][2] * 0.1
end

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

function newSB(tex, pos)
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

local testShaders = require("test_shaders")


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
	-- active state, always have value
	shader = nil,
	bbShader = nil,
	camera = nil,


	-- library
	defaultShader = g3d.shader,
	defaultbbShader = billboard.shader,
	solidColor = testShaders.model,
	solidColorbb = testShaders.billboard,
	canvas = lg.newCanvas(),

	-- flag
	updateCanvasFlag = false,
	-- drawColorsFlag = false
}




do
	local gs = graphicsState
	gs.camera = g3d.camera
	gs.camera.r = 0

	gs.defaultShader:send("projectionMatrix", gs.camera.projectionMatrix)
	gs.defaultbbShader:send("projectionMatrix", gs.camera.projectionMatrix)
	gs.solidColor:send("projectionMatrix", gs.camera.projectionMatrix)
	gs.solidColorbb:send("projectionMatrix", gs.camera.projectionMatrix)

	gs.shader = gs.defaultShader
	gs.bbShader = gs.defaultbbShader
end



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


local updateTweens = tiny.processingSystem()
updateTweens.updateSystem = true
updateTweens.processPlaying = true
updateTweens.filter = tiny.requireAll("tween")
-- requiring a tween component

function updateTweens:process(e, dt)
	local tween = e.tween
	if tween.t < tween.endTime then
		tween.t = tween.t + dt
	else 
		tween.finished = true
	end
end


local intp = tiny.processingSystem()
intp.updateSystem = true
intp.processPlaying = true
intp.filter = tiny.requireAll("tween", "mesh")

function intp:process(e, dt)
	if not e.tween.finished then

	end
end




local getClickable = require("systems.getClickable")
local updatePlayerPos = require("systems.updatePlayerPos")
local drawMenu = require("systems.drawMenu")

local renderTarget = require("systems.renderTarget")
local updateCamera = require("systems.updateCamera")
local drawModels = require("systems.drawModels")
local drawID = require("systems.drawID")

local drawWrap = require("systems.drawWrap")

-----------------------------------------
-- driver
-----------------------------------------


function love.load()	
	local ui = {
		menu = {
			{
				label = "resume",
				fn = function() gamestates:switch() end
			},
			{
				label = "quit",
				fn = love.event.quit
			},
			{
				label = "wireframe",
				fn = function() lg.setWireframe(true) end
			},
		},

		font = lg.newFont(20),
		x = 500, 
		y = 500
	}

	local rat = g3d.newModel("assets/rat.obj", "assets/Tex_Rat.png")
	rat.clickable = true

	local globe = g3d.newModel("assets/sphere.obj", "assets/earth.png", {0,-1,0}, nil, 0.5):compress()
	globe.spinning = true
	globe.clickable = true

	local car = g3d.newModel("assets/car.obj", "assets/1377 car.png", {2,-1,0}, {0,0.5,0}, 0.05):compress()
	car.clickable = true

	local walls = g3d.newModel("assets/level.obj", "assets/alexander ross.png"):compress()

	-- still	
	fish = g3d.newModel("assets/Goldfish.obj", "assets/1377 car.png", {-0.5,-4,0.2}, nil, 0.5):compress()
	fish.color = {1, 0.5, 0.6}
	fish.clickable = true

	local burger = newSB("assets/burger.png", {0.5,0,2})
	
	world = tiny.world(
		ui,
		rat,
		globe,
		car,
		walls,
		fish,
		burger,

		spin,
		updatePlayerPos,
		drawMenu,
		getClickable,
		renderTarget,
		updateCamera,
		drawModels,
		drawID,
		drawWrap
	)

	-- local models = [[
	-- 	-- code here 
	-- 	return {rat, globe, car, walls, fish, burger}
	-- ]]

	-- models = loadstring(models)()
	-- world:add(unpack(models))


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
	drawMenu.input = key



	if key == "p" then
		local cam = graphicsState.camera
		fish:lookAt(cam.position, nil)
		print("position = "..table.concat(cam.position, ", "))
		print("rotation = "..cam.r)
	end
end

local function pickTest(x, y)

	getClickable:update()
	local len = #getClickable.entities
	for i, e in pairs(getClickable.entities) do
		e.ID = i / len
	end

	graphicsState.updateCanvasFlag = true
	drawModels.active = false
	drawID.active = true
	graphicsState.shader = graphicsState.solidColor
	graphicsState.bbShader = graphicsState.solidColorbb

	coroutine.yield()

	drawModels.active = true
	drawID.active = false
	graphicsState.shader = graphicsState.defaultShader
	graphicsState.bbShader = graphicsState.defaultbbShader

	-- print(x, y)

	local data = graphicsState.canvas:newImageData()
	local r, g, b, a = data:getPixel(x, y)
	print(r, g, b, a)
	

end


function love.mousepressed(x, y, button, istouch, presses)
	local pt = coroutine.create(pickTest)
	coroutine.resume(pt, x, y)
	drawWrap.coroutine = pt
end

function love.resize(w, h)
	local gs = graphicsState
   gs.camera.aspectRatio = w/h
   gs.camera.updateProjectionMatrix()
	gs.shader:send("projectionMatrix", gs.camera.projectionMatrix)
	gs.billboardShader:send("projectionMatrix", gs.camera.projectionMatrix)
end