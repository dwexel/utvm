--[[
	split code up into the smallest parts

	g3d camera only uses the "look_at" code to move - i want to learn more

	export properties:
		axes:
			x > forward
			z > up


	probs
		billboards not scaling! why!	
		if you wanted to use spritebatches, maybe give them a defferent vertex format

	
	mod 
		non-clearing canvas
		non depth testing

	
	use a load level system
	use love filesystem to get a bunch of modules

	use spritebatch to make it all
		glitter

]]


local world
local lg = love.graphics
local width, height = love.graphics.getDimensions()
local g3d = require("lib/g3d")
tiny = require("lib.tiny")

-- using this one for now instead of g3d
-- local defaultShader = love.graphics.newShader[[
-- 	#ifdef VERTEX
-- 		uniform mat4 model;
-- 		uniform mat4 projection;
-- 		uniform mat4 view;
-- 		vec4 position(mat4 transform_projection, vec4 vertex_position)
-- 		{
-- 			return projection * view * model * vertex_position;
-- 		}
-- 	#endif
-- ]]

local function loadPositions(path)
	local result = {}
    for line in love.filesystem.lines(path) do
    	local x, y, z = line:match("^v ([^%s]+) ([^%s]+) ([^%s]+)")
    	if x then
    		table.insert(result, {x, y, z})
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
	vertexFormat = 	{
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

billboard.new = function(tex, pos)
	if type(tex) == "string" then error("wrong type") end

	local self = setmetatable({}, g3d.modelMT)
	self.mesh = love.graphics.newMesh(billboard.vertexFormat, square_verts, "triangles", "static")
	self.mesh:setTexture(tex)
	self.matrix = g3d.newMatrix()
	self.isBillboard = true
   self:setTransform(pos or {0,0,0}, {0,0,0}, {1, 1, 1})

	return self
end


-- local pickTest = {active = false, canvas = lg.newCanvas()}
local pickTest = {}
pickTest.shader = love.graphics.newShader[[
	#ifdef VERTEX
		uniform mat4 model;
		uniform mat4 projection;
		uniform mat4 view;
			vec4 position(mat4 transform_projection, vec4 vertex_position)
			{
				vec4 v = projection * view * model * vertex_position;
				v.y *= -1.0;
				return v;
			}
	#endif
	#ifdef PIXEL
		vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc) { return color; }
	#endif
]]

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


local level = {
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

local function dotProduct(a1,a2, b1,b2)
    return a1*b1 + a2*b2
end

local player = {
	pos = 1
}

local drawMenu

-----------------------------------------
-- systems
-----------------------------------------

graphicsState = tiny.system({
	shader = g3d.shader,
	-- shader = defaultShader, 
	camera = g3d.camera,
})

function graphicsState:onAddToWorld()
	-- manage camera manually
	self.camera = g3d.camera
	self.camera.r = 0

	self.shader:send("viewMatrix", self.camera.viewMatrix)
	self.shader:send("projectionMatrix", self.camera.projectionMatrix)

	billboard.shader:send("viewMatrix", self.camera.viewMatrix)
	billboard.shader:send("projectionMatrix", self.camera.projectionMatrix)
end

renderTarget = tiny.system({canvas = lg.newCanvas()})
renderTarget.drawSystem = true
renderTarget.modes = {NORMAL, CANVAS}
renderTarget.mode = 1

-- called on each system before update is called on any system
function renderTarget:preWrap(dt)
	if self.mode == 2 then
		lg.setCanvas({self.canvas, depth = true})
		lg.clear()
	end
end

function renderTarget:postWrap(dt)
	if self.mode == 2 then
		lg.setCanvas()
		lg.draw(self.canvas, 0,0,0, 0.5)
	end
end

drawModels = tiny.processingSystem()
drawModels.drawSystem = true
drawModels.filter = tiny.requireAny("mesh")

function drawModels:preProcess()
	lg.circle("fill", 100, 100, 10)
	graphicsState.shader:send("viewMatrix", graphicsState.camera.viewMatrix)
	billboard.shader:send("viewMatrix", graphicsState.camera.viewMatrix)
end

function drawModels:process(e)
	if e.isBillboard then
		e:draw(billboard.shader)
	else
		e:draw(graphicsState.shader)
	end
end
-- combine these?
updateCamera = tiny.system(graphicsState.camera)
updateCamera.updateSystem = true
updateCamera.processPlaying = true

function updateCamera:update(dt)
	local kd = love.keyboard.isDown
	local ix, iy = 0, 0
	local speed = 2

	if kd("a") then ix = -dt elseif kd("d") then ix = dt end
	self.r = (self.r - ix*speed) % (math.pi*2)
	self.lookInDirection(nil,nil,nil, self.r)
	-- self.lookAtFrom(nil,nil,nil, 0,0,0)

	-- snap to positions
	-- self.position[1] = level.positions[player.pos][1]
	-- self.position[2] = level.positions[player.pos][2]
	-- self.position[3] = level.positions[player.pos][3]

	-- move based on look direction
	if kd("w") then iy = -dt elseif kd("s") then iy = dt end
	local lx = math.cos(self.r) * -iy
	local ly = math.sin(self.r) * -iy
	self.position[1] = self.position[1] + lx	
	self.position[2] = self.position[2] + ly
end

updatePlayerPos = tiny.system(player)
updatePlayerPos.updateSystem = true
updatePlayerPos.processPlaying = true
updatePlayerPos.inputQueue = 0

function updatePlayerPos:update(dt)
	if self.inputQueue ~= 0 then
		-- get index of next position
		-- local nextp = level.wrap(self.pos + self.inputQueue)
		player.pos = level.wrap(self.pos + self.inputQueue)
		local cam = graphicsState.camera

		-- view vector
		local vx = cam.target[1]-cam.position[1]
		local vy = cam.target[2]-cam.position[2]

		-- vector to next position
		-- local nextPosition = level.positions[1]

		local dx = -cam.position[1]
		local dy = -cam.position[2]

		local dot = dotProduct(vx,vy, dx,dy)
		if dot < 0 then
			print("away from origin")
		else
			print("towards origin")
		end

		self.inputQueue = 0
	end
end

-- routeInput = tiny.processingSystem({
-- 	inputQueue = ""
-- })
-- routeInput.updateSystem = true
-- routeInput.processPlaying = true
-- routeInput.processPaused = true
-- routeInput.filter = tiny.requireAny("menu")

-- function



-----------------------------------------
-- driver
-----------------------------------------


function love.load()
	local globe = g3d.newModel("assets/sphere.obj", "assets/earth.png", {0, 0, 0}, nil, 0.5)
	globe.spinning = true
	local car = g3d.newModel("assets/car.obj", "assets/1377 car.png", {2, -1, 0}, {0, 0.5, 0}, 0.05)
	car:compress()
	local level_background = g3d.newModel("assets/boo.obj", "assets/alexander ross.png")
	level_background:compress()

	-- exported at 0.1 
	fish = g3d.newModel("assets/Goldfish.obj", "assets/1377 car.png", {-0.5, -4, 0.2}, nil, 0.5)
	fish:compress()
	fish.color = {1, 0.5, 0.6}

	drawMenu = require("systems.drawMenu")

	local ui = {
		menu = {"resume", "exit"},
		font = lg.newFont(20),

		text = "hello", 
		x = 500, 
		y = 500
	}

	world = tiny.world(
		globe,
		car,
		bb,
		level_background,
		fish,
		ui,

		updateCamera,
		updatePlayerPos,
		
		graphicsState,
		renderTarget,

		drawModels,
		drawMenu
	)

	-- damn, how do I make sure they're in order?
	-- set vertex attributes in blender?
	level.positions = loadPositions("assets/positions.obj")
	local bi = lg.newImage("assets/1377 car.png")
	for _, v in ipairs(level.positions) do
		world:addEntity(billboard.new(bi, v))
	end




	-- local index = world:setSystemIndex(input, 1)
end


local playFilter = tiny.requireAll("updateSystem", "processPlaying")
local pauseFilter = tiny.requireAll("updatesytem", "processPaused")

local drawPlayingFilter = tiny.requireAll("drawSystem", tiny.rejectAny("processPaused"))
local drawPausedFilter = tiny.requireAll("drawSystem")

function love.update(dt)
	if gamestate == gamestates.PLAY then
		world:update(dt, playFilter)
	elseif gamestate == gamestates.PAUSED then
		world:update(dt, pauseFilter)
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

	if key == "w" then
		updatePlayerPos.inputQueue = 1
	elseif key == "s" then
		updatePlayerPos.inputQueue = -1
	end

	if key == "p" then
		local p = graphicsState.camera.position
		fish:lookAt(p, nil)
		print(table.concat(p, ", "))
	end

	local n = tonumber(key)
	if n then
		renderTarget.mode = n
	end


	-- only will update if paused
	drawMenu.inputQueue = key

end

function love.resize(w, h)
	width, height = w, h
   graphicsState.camera.aspectRatio = love.graphics.getWidth()/love.graphics.getHeight()
   graphicsState.camera.updateProjectionMatrix()
end