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
		damn stil...

	mod 
		non-clearing canvas
		non depth testing
		scramble verts in memory
		wireframe mode
		draw each mesh with only one color


	use spritebatch to make it all
		glitter
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

	pick test
		have a "blocking" color for picktesting
		use blendmode clear
		use sorting for draw order
		the clicktest might be mushy I should still try and figure out special canvases

	structure
		types are self - reminders

		
	make shit make sense or else u are doomed
		"stuff?" are you serious my brotha
		
		ok something to think about: what thing is a thing part of.
			for serious
				have a strong organization

	file for entities?
	save data component

	have a draw order component - 
		either on the systems or on entities
		separate drawIndex and updateIndex

	I like how the camera system basically extends the camera
]]

-- local models = [[
-- 	-- code here 
-- 	return {rat, globe, car, walls, fish, burger}
-- ]]

-- models = loadstring(models)()
-- world:add(unpack(models))


------------------------------------------------
-- top
------------------------------------------------


local world


local lg = love.graphics
local g3d = require("lib/g3d")
local inspect = require("lib.inspect")

cpml = require("lib.cpml")
tiny = require("lib.tiny")


-------------------------------------------------
-- local helpers
-------------------------------------------------


local utils = require("stuff.utils")
local types = require("stuff.types")

local loadPositions = utils.loadPositions
local newBillboard = types.newBillboard
local newSB = types.newSB
local newArrow = types.newArrow
local newTween = types.newTween


local _ts = require("stuff.test_shaders")
local _bb = require("stuff.bb_shader")

local shaders = {
	defaultShader = g3d.shader,
	defaultbbShader = _bb,
	solidColorShader = _ts.model,
	solidColorbbShader = _ts.billboard,
}

_ts = nil
_bb = nil


-- generic callbacks
local callbacks = {
	printName = function(self)
		local name = self.name or "no name, "..tostring(self)
		print("self = "..name)
	end
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

gamestates = {PLAY = 1, PAUSED = 2}
gamestate = 1

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
-- local systems 
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
		e:setQuaternionRotation(tw.initial:lerp(tw.final, tw.t))
	else 
		tw.finished = true
		if type(tw.initial) == "cdata" then
			-- e:setQuaternionRotation(tw.final)
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
	arrows = {},
	arrowHeight = 0.3
})
updateArrows.updateSystem = true
updateArrows.processPlaying = true

function updateArrows:onAddToWorld(world)
	self.arrows[1] = newArrow()
	self.arrows[2] = newArrow()
	world:add(unpack(self.arrows))
end

function updateArrows:update(dt)
	if self.input then
		if self.input == "o" then

			local current = levelPos[playerPos]
			print(current)
			local c = cpml.vec3(current)

			-- 2 targets for 2 arrows
			for i = 1, 2 do
				local target = levelPos[current.cons[i]]
				target = cpml.vec3(target)

				local v = (target - c):normalize()
				local f = c + (v * 0.1)
				self.arrows[i]:lookAtFrom({f.x, f.y, self.arrowHeight}, target)

				-- local v = (target - cam):normalize()
				-- local f = cam + (v * 0.1)
				-- self.arrows[i]:lookAtFrom({f.x, f.y, arrowHeight}, target)
				-- self.arrows[i]:lookAtFrom({cam.x, cam.y, arrowHeight}, target)


				-- update callback
				self.arrows[i].point_i = current.cons[i]
			end
		end
		self.input = nil
	end
end

local drawMenu = require("systems.drawMenu")
local getClickable = require("systems.getClickable")
local drawWrap = require("systems.drawWrap")
local drawModels = require("systems.drawModels")
local drawModelsID = require("systems.drawModelsID")

-----------------------------------------
-- driver
-----------------------------------------



function love.load()
	graphicsState.camera.r = 4.6

	local rat = g3d.newModel("assets/rat.obj", "assets/Tex_Rat.png", {0,0,0,1})
	rat.clickable = callbacks.printName
	rat.name = "rat"

	local globe = g3d.newModel("assets/sphere.obj", "assets/earth.png", {-1.3, -2.3, 0}, nil, 0.5):compress()
	globe.spinning = true
	globe.clickable = callbacks.printName
	globe.name = "globe"

	local car = g3d.newModel("assets/car.obj", "assets/1377 car.png", {2,-1,0}, {0,0.5,0}, 0.05):compress()
	car.clickable = callbacks.printName
	car.name = "car"

	-- local walls = g3d.newModel("assets/level.obj", "assets/alexander ross.png"):compress()
	local walls = g3d.newModel("assets/level2.obj", "assets/alexander ross.png"):compress()

	local fish = g3d.newModel("assets/Goldfish.obj", "assets/1377 car.png", {-0.1, -0.6, 0.2}, nil, 0.5):compress()
	fish.tween = newTween(2, cpml.quat.new(), cpml.quat.from_angle_axis(2, 0,0,1))
	fish.clickable = callbacks.printName
	fish.name = "fish"

	local burger = newSB("assets/burger.png", {0.5,0,2})


	-- -3.5, -4.8, 0.3
	local campfire = g3d.newModel("assets/campfire.obj", "assets/campfire.png", {-3.5, -4.8, 0.1}, nil, 0.4):compress()
	campfire.clickable = callbacks.printName
	campfire.name = "campfire"

	local door = g3d.newModel("assets/door.obj", "assets/campfire.png", {-1.1, -5.5, 0})
	
	local tracks = {
		font = lg.newFont("assets/owl-font.otf", 22)
	}

	local pauseUI = {
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
				fn = function() lg.setWireframe() end
			},
		},

		font = lg.newFont(20),
		x = 500,
		y = 500
	}

	world = tiny.world(
		pauseUI, tracks,
		door, rat, globe, car, walls, fish, burger, campfire, 

		spin,
		updateTweens,
		updateArrows
	)

	for _, path in pairs(love.filesystem.getDirectoryItems("systems")) do
		path = path:gsub("%.lua$", "")
		world:addSystem(require("systems."..path))	
	end

	world:refresh()

	-- gets reference
	local draw2D = require("systems.draw2D")
	local drawMenu = drawMenu
	sortSystems(draw2D, drawMenu)

	-- path locations
	local nodes = loadPositions("assets/path.obj")

	-- spawnPoint index
	local si = -1

	-- billboard image
	local bi = lg.newImage("assets/1377 car.png")

	for i, v in ipairs(nodes) do
		world:addEntity(newBillboard(bi, v))
		if v.isSpawnPoint then
			si = i
		end			
	end

	-- local sp = nodes[si]
	-- for _, i in ipairs(sp.cons) do
	-- 	world:addEntity(newBillboard(bi, nodes[i]))
	-- end

	graphicsState.camera.position = nodes[si]
	levelPos = nodes
	playerPos = si
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

	drawMenu.input = key
	updateArrows.input = key

	if key == "p" then
		local cam = graphicsState.camera.position
		print(inspect(cam))
		-- fish:lookAt(cam.position, nil)
	end
end


local function pickTest(x, y)
	assert(getClickable)

	getClickable:update()
	local len = #getClickable.entities
	for i, e in pairs(getClickable.entities) do
		e.ID = i / len
	end

	graphicsState.updateCanvasFlag = true
	drawModels.active = false
	drawModelsID.active = true
	graphicsState.shader = shaders.solidColorShader
	graphicsState.bbShader = shaders.solidColorbbShader

	coroutine.yield()

	drawModels.active = true
	drawModelsID.active = false
	graphicsState.shader = shaders.defaultShader
	graphicsState.bbShader = shaders.defaultbbShader

	print(assert(graphicsState.canvas))
	local data = graphicsState.canvas:newImageData()
	-- quietly failing here?
	print(data)

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
	assert(type(entity.clickable) == "function")
	entity:clickable()
end

function love.mousepressed(x, y, button, istouch, presses)
	-- create a coroutine
	local pt = coroutine.create(pickTest)
	coroutine.resume(pt, x, y)
	-- resume the coroutine after all draw operations
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