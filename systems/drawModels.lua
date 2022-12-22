assert(graphicsState)

local gs = graphicsState

local drawModels = tiny.processingSystem()
drawModels.drawSystem = true
drawModels.filter = tiny.requireAny("mesh")

function drawModels:preProcess()
	-- send camera matrix before drawing models
	love.graphics.circle("fill", 100, 100, 10)
	graphicsState.shader:send("viewMatrix", graphicsState.camera.viewMatrix)
	graphicsState.billboardShader:send("viewMatrix", graphicsState.camera.viewMatrix)
end

function drawModels:process(e)
	if e.isBillboard then
		e:draw(graphicsState.billboardShader)
	else
		e:draw(graphicsState.shader)
	end
end

return drawModels