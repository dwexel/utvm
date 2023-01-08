assert(graphicsState)

local lg = love.graphics
local drawModelsID = tiny.processingSystem()
drawModelsID.drawSystem = true
drawModelsID.active = false
drawModelsID.filter = tiny.requireAll("mesh")

function drawModelsID:preProcess()
	graphicsState.shader:send("viewMatrix", graphicsState.camera.viewMatrix)
	graphicsState.bbShader:send("viewMatrix", graphicsState.camera.viewMatrix)
end

function drawModelsID:process(e)
	if e.ID then
		lg.setColor(e.ID, e.ID, e.ID)
	else
		lg.setColor(0,0,0,1)
	end

	if e.isBillboard then
		e:draw(graphicsState.bbShader)
	else
		e:draw(graphicsState.shader)
	end
	lg.setColor(1, 1, 1)
end

return drawModelsID