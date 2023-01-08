assert(cpml)
local mat4 = cpml.mat4

local lg = love.graphics
local defaultFont = lg.getFont()

local drawTracks = tiny.processingSystem()
drawTracks.drawSystem = true
drawTracks.filter = tiny.requireAll("font", tiny.rejectAny("menu"))

local zero_vector = {0,0,0,1}
local win

function drawTracks:process(e, dt)
	lg.setFont(e.font)
	lg.print("fhjdklflahjfkdlsa", 100, 100)
	lg.setFont(defaultFont)

	-- project from world position to screen position

	local gs = graphicsState

	-- gs.camera.position[1] = 10
	-- gs.camera.position[2] = 10

	local view = mat4(gs.camera.viewMatrix)

	-- print("----------------")
	-- print(view)


	-- local proj = mat4(gs.camera.projectionMatrix)

	-- local mat = proj * view
	-- local x, y, z = mat[13], mat[14], mat[15]
	-- lg.circle("fill", win.x, win.y, 50)
end

return drawTracks