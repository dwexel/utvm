assert(graphicsState)

local lg = love.graphics
local gs = graphicsState
local renderTarget = tiny.system()
renderTarget.drawSystem = true
renderTarget.active = true


-- called on each system before update is called on any system
function renderTarget:preWrap(dt)
	if gs.updateCanvasFlag then
		lg.setCanvas({gs.canvas, depth = true})
		lg.clear()
	end
end

function renderTarget:postWrap(dt)
	if gs.canvas then
		lg.setCanvas()
		lg.setBlendMode("alpha", "premultiplied")
		lg.draw(gs.canvas, 0,0,0, 0.5)
		lg.setBlendMode("alpha")
	end

	gs.updateCanvasFlag = false	
end

return renderTarget