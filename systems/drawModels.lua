assert(graphicsState)

local drawModels = tiny.processingSystem()
drawModels.drawSystem = true
drawModels.filter = tiny.requireAny("mesh")

function drawModels:preProcess()
	-- love.graphics.circle("fill", 100, 100, 10)
	graphicsState.shader:send("viewMatrix", graphicsState.camera.viewMatrix)
	graphicsState.bbShader:send("viewMatrix", graphicsState.camera.viewMatrix)
end

function drawModels:process(e)
	if e.isBillboard then
		e:draw(graphicsState.bbShader)
	else
		e:draw(graphicsState.shader)
	end
end

return drawModels