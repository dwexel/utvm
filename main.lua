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


	use loadstring to load levels? evaluates in a global context! that's ok...


	leverage love graphics state more?
	can use custom shaders to draw to multiple canvases at once
	have a "blocking" color for picktesting
	use sorting for draw order


	if might be alright tohave a library of types, but at the same time, i should avoid doing oop stuff
		because "tag" components aren't great


	when using cpml with g3d, must be aware of whether ffi is being used by cpml
]]

	-- level global var...
	-- using plain tables for position
	-- troubles may arise


local world
local lg = love.graphics
g3d = require("lib/g3d")
tiny = require("lib.tiny")
cpml = require("lib.cpml")

local inspect = require("lib.inspect")

-- must get index in table of the spawn point
-- must sort the table somehow..?
-- no, have some kind of node representation
-- but, that can also be iterated easily

--[[
	node:
		x, y, z
		list of connections (indices)
		is spawn point? t/f
]]

local function loadPositions(path)
	local result = {}

	for line in love.filesystem.lines(path) do
		local words = {}
		for word in line:gmatch "([^%s]+)" do
			table.insert(words, word)
		end

		if words[1] == "v" then
			local x, y, z, sp = tonumber(words[2]), tonumber(words[3]), tonumber(words[4]), tonumber(words[5])
			local point = {x, y, z}
			point.con = {} -- conections

			table.insert(result, point)
			if sp == 1 then 
				point.isSpawnPoint = true
			end

		elseif words[1] == "l" then
			p1, p2 = tonumber(words[2]), tonumber(words[3])

			table.insert(result[p1].con, p2)
			table.insert(result[p2].con, p1)
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

local function newTween(endTime, initial, final)
	assert(endTime)
	-- have different types?
	return {
		t = 0,
		endTime = endTime,
		finished = false,
		initial = initial,
		final = final
	}
end

local _ts = require("test_shaders")

local shaders = {
	defaultShader = g3d.shader,
	defaultbbShader = billboard.shader,
	solidColorShader = _ts.model,
	solidColorbbShader = _ts.billboard,
}

_ts = nil

---------------------------------------
-- globals
---------------------------------------


levelPos = {} -- table
playerPos = -1 -- table index

graphicsState = {
	-- active state, always have value
	shader = nil,
	bbShader = nil,
	camera = nil,
	
	-- does not always have to have a value
	canvas = lg.newCanvas(),

	-- flags
	updateCanvasFlag = false,
}

do
	local gs = graphicsState
	gs.camera = g3d.camera
	gs.camera.r = 0

	shaders.defaultShader:send("projectionMatrix", gs.camera.projectionMatrix)
	shaders.defaultbbShader:send("projectionMatrix", gs.camera.projectionMatrix)
	shaders.solidColorShader:send("projectionMatrix", gs.camera.projectionMatrix)
	shaders.solidColorbbShader:send("projectionMatrix", gs.camera.projectionMatrix)

	gs.shader = shaders.defaultShader
	gs.bbShader = shaders.defaultbbShader
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

function updateTweens:process(e, dt)
	local tw = e.tween
	if not tw.finished and tw.t < tw.endTime then
		tw.t = tw.t + dt
		-- maybe could do this with components
	else 
		tw.finished = true
		if type(tw.initial) == "cdata" then
			-- e:setQuaternionRotation(tw.initial:lerp(tw.final, tw.t))
			e:setQuaternionRotation(tw.final)
		end
	end
end


local tweenRotation = tiny.processingSystem()
tweenRotation.updateSystem = true
tweenRotation.processPlaying = true
tweenRotation.filter = tiny.requireAll("tween", "mesh", "quat")

function tweenRotation:process(e, dt)
	-- print(e)
	-- if not e.tween.finished then
	-- end
end


local updateArrows = tiny.system({
	input = "",
	arrow = nil,
})
updateArrows.updateSystem = true
updateArrows.processPlaying = true

local arrowHeight = 0.3

function updateArrows:update(dt)
	if self.input then
		if self.input == "o" then
			assert(playerPos)
			assert(levelPos)

			--first pos

			local p = levelPos[playerPos]
			local t = levelPos[p.con[1]]
			local c = graphicsState.camera.position

			t = cpml.vec3(t)
			c = cpml.vec3(c)

			local v = (t - c):normalize()
			local f = c + (v * 0.1)

			print(f)
			self.arrow:lookAtFrom({f.x, f.y, arrowHeight}, t)

			-- local t = graphicsState.camera.position
			-- self.arrow:lookAt({t[1], t[2], 0})

		end
		self.input = nil
	end
end




local getClickable    = require("systems.getClickable")
local updatePlayerPos = require("systems.updatePlayerPos")
local drawMenu        = require("systems.drawMenu")
local renderTarget    = require("systems.renderTarget")
local updateCamera    = require("systems.updateCamera")
local drawModels      = require("systems.drawModels")
local drawID          = require("systems.drawID")
local drawWrap        = require("systems.drawWrap")

-----------------------------------------
-- driver
-----------------------------------------

local fish
local rat

function love.load()
	graphicsState.camera.r = 4.6

	rat = g3d.newModel("assets/rat.obj", "assets/Tex_Rat.png", {0,0,0,1})
	rat.clickable = true
	-- rat.tween = newTween(2)
	local globe = g3d.newModel("assets/sphere.obj", "assets/earth.png", {-1.3, -2.3, 0}, nil, 0.5):compress()
	globe.spinning = true
	globe.clickable = true
	local car = g3d.newModel("assets/car.obj", "assets/1377 car.png", {2,-1,0}, {0,0.5,0}, 0.05):compress()
	car.clickable = true
	local walls = g3d.newModel("assets/level.obj", "assets/alexander ross.png"):compress()
	fish = g3d.newModel("assets/Goldfish.obj", "assets/1377 car.png", {-0.1, -0.6, 0.2}, nil, 0.5):compress()
	-- fish.color = {1, 0.5, 0.6}
	fish.clickable = true
	local initial = cpml.quat.new()
	local final = cpml.quat.from_angle_axis(2, 0,0,1)
	-- fish:setQuaternionRotation(final)
	fish.tween = newTween(2, initial, final)
	local burger = newSB("assets/burger.png", {0.5,0,2})


	local arrow = g3d.newModel(square_verts, "assets/arrow2.png", nil, nil, 0.4)
	updateArrows.arrow = arrow

	world = tiny.world(
		ui, rat, globe, car, walls, fish, burger,  arrow,

		spin,
		updateTweens,
		updatePlayerPos,
		updateCamera,
		updateArrows,

		renderTarget,
		drawModels,
		drawID,
		getClickable,
		drawMenu,
		drawWrap
	)

	local nodes = loadPositions("assets/path.obj")

	-- spawnPoint index
	local si = -1

	-- billboard image
	local bi = lg.newImage("assets/1377 car.png")

	for i, v in ipairs(nodes) do
		if v.isSpawnPoint then
			si = i
		end			
	end

	local sp = nodes[si]
	for _, i in ipairs(sp.con) do
		world:addEntity(newBillboard(bi, nodes[i]))
	end

	graphicsState.camera.position = nodes[si]
	levelPos = nodes
	playerPos = si


	-- local models = [[
	-- 	-- code here 
	-- 	return {rat, globe, car, walls, fish, burger}
	-- ]]

	-- models = loadstring(models)()
	-- world:add(unpack(models))
	
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
	updateArrows.input = key


	if key == "p" then
		local cam = graphicsState.camera
		-- fish:lookAt(cam.position, nil)
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
	graphicsState.shader = shaders.solidColorShader
	graphicsState.bbShader = shaders.solidColorbbShader
	coroutine.yield()

	drawModels.active = true
	drawID.active = false
	graphicsState.shader = shaders.defaultShader
	graphicsState.bbShader = shaders.defaultbbShader
	local data = graphicsState.canvas:newImageData()
	local r, g, b, a = data:getPixel(x, y)
	print(x, y)
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
	gs.bbShader:send("projectionMatrix", gs.camera.projectionMatrix)
end

function love.quit()
	print("quitting")
end