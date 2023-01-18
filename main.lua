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
			how would this work?
			have to make a different batch for each item, then move them around? no...
			would have to remove and add them each frame.

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
		think of them as helpers rather than the end-all of entities


	be aware
		when using cpml with g3d, must be aware of whether ffi is being used by cpml
		of how positions are stored - plain table? c struct?


	ideas
		some kind of asset loading system would be cool
		make types a folder?
		move callbakc components to types file?

	-- local models = [[
	-- 	-- code here 
	-- 	return {rat, globe, car, walls, fish, burger}
	-- 

	-- models = loadstring(models)()
	-- world:add(unpack(models))

	timer system, that calls a function when timer is done

	all callbacks are called with self and world as arguments
]]


local world
local lg = love.graphics
g3d = require("lib/g3d")
tiny = require("lib.tiny")
cpml = require("lib.cpml")


-- utility

local inspect = require("lib.inspect")
local loadPositions = require("lib.loadPositions")


local _bb = require("lib.bb_shader")
local _ts = require("lib.test_shaders")
local shaders = {
	defaultShader = g3d.shader,
	defaultbbShader = _bb,
	solidColorShader = _ts.model,
	solidColorbbShader = _ts.billboard,
}
_ts = nil
_bb = nil

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

local function sortSystems(before, after)
	if after.index < before.index then
		world:setSystemIndex(after, before.index+1)
		-- world:setSystemIndex(before, after.index)
	end
end







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
-- and types
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


-- local updatePlayerPos = require("systems.updatePlayerPos")
local updateTweens    = require("systems.updateTweens")
local updateArrows    = require("systems.updateArrows")
local getClickable    = require("systems.getClickable")

local draw2D          = require("systems.draw2D")
local drawMenu        = require("systems.drawMenu")
local renderTarget    = require("systems.renderTarget")

local updateCamera    = require("systems.updateCamera")
local drawModels      = require("systems.drawModels")
local drawID          = require("systems.drawID")
local drawWrap        = require("systems.drawWrap")


local types, callbacks = unpack(require("lib.types"))
local newBillboard     = types.newBillboard
local newTween         = types.newTween
local newArrow         = types.newArrow


local startTween   = callbacks.startTween
local moveToPlayer = callbacks.moveToPlayer
local printName    = callbacks.printName




-----------------------------------------
-- driver
-----------------------------------------


function love.load()
	graphicsState.camera.r = 4.6

	local rat = g3d.newModel("assets/rat.obj", "assets/Tex_Rat.png", {0,0,0,1})
		rat.onClick = printName
		rat.name = "rat"

	local globe = g3d.newModel("assets/sphere.obj", "assets/earth.png", {-1.3, -2.3, 0}, nil, 0.5):compress()
		globe.spinning = true
		globe.onClick = moveToPlayer

		-- globe.onClick = printName
		-- globe.tween = newTween(3, cpml.vec3(0,0,0), cpml.vec3(1, 1, 0))

	local car = g3d.newModel("assets/car.obj", "assets/1377 car.png", {2,-1,0}, {0,0.5,0}, 0.05):compress()
		car.onClick = printName
		car.name = "car"

	local walls = g3d.newModel("assets/level.obj", "assets/alexander ross.png"):compress()
	
	local fish = g3d.newModel("assets/Goldfish.obj", "assets/1377 car.png", {-0.1, -0.6, 0.2}, nil, 0.5):compress()
		-- fish.color = {1, 0.5, 0.6}
		fish.name = "fish"
		fish.onClick = startTween
		local i = cpml.quat.new()
		local f = cpml.quat.from_angle_axis(2, 0,0,1)
			fish:setQuaternionRotation(i)
			fish.tween = newTween(2, i, f)

	local burger = types.newSB("assets/burger.png", {0.5,0,2})
	updateArrows.arrows[1] = newArrow()
	updateArrows.arrows[2] = newArrow()


	world = tiny.world(
		ui, rat, globe, car, walls, fish, burger, 
		updateArrows.arrows[1],
		updateArrows.arrows[2],

		draw2D,
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

	world:setSystemIndex(draw2D, #world.systems)
	world:setSystemIndex(drawMenu, #world.systems)

	local nodes = loadPositions("assets/path.obj")

	-- spawnPoint index
	local si = -1
	for i, v in ipairs(nodes) do
		if v.isSpawnPoint then si = i end
	end

	-- local bi = lg.newImage("assets/1377 car.png")
	-- for _, i in ipairs(nodes[si].cons) do
	-- 	world:addEntity(newBillboard(bi, nodes[i]))
	-- end

	-- have to copy values.
	graphicsState.camera.position[1] = nodes[si][1]
	graphicsState.camera.position[2] = nodes[si][2]
	graphicsState.camera.position[3] = nodes[si][3]

	levelPos = nodes
	playerPos = si

	graphicsState.updateArrowsFlag = true
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

	-- send inputs 
	drawMenu.input = key

	if key =="o" then
		graphicsState.updateArrowsFlag = true
	end


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

	if r == 0 then
		return
	end

	local min = math.huge
	local en_i = -1

	for i, e in ipairs(getClickable.entities) do
		local d = math.abs(e.ID - r)
		if d < min then
			min = d
			en_i = i
		end
		-- clear ID
		e.ID = nil
	end

	local entity = getClickable.entities[en_i]

	-- do callback
	assert(type(entity.onClick) == "function")
	entity:onClick(world)
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