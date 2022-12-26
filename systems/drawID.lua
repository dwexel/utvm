assert(graphicsState)

local lg = love.graphics
local drawID = tiny.processingSystem()
drawID.drawSystem = true
drawID.active = false
drawID.filter = tiny.requireAll("mesh")

function drawID:preProcess()
	graphicsState.shader:send("viewMatrix", graphicsState.camera.viewMatrix)
	graphicsState.bbShader:send("viewMatrix", graphicsState.camera.viewMatrix)
end

function drawID:process(e)
	if e.ID then
		lg.setColor(e.ID, e.ID, e.ID)
	else
		-- lg.setBlendMode("replace")
		lg.setColor(0,0,0,1)
		-- lg.setBlendMode("alpha")
	end

	if e.isBillboard then
		e:draw(graphicsState.bbShader)
	else
		e:draw(graphicsState.shader)
	end
	lg.setColor(1, 1, 1)
end

return drawID