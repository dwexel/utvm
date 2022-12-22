assert(graphicsState)

local lg = love.graphics
local gs = graphicsState
local renderTarget = tiny.system()
renderTarget.drawSystem = true
renderTarget.active = true



-- called on each system before update is called on any system
function renderTarget:preWrap(dt)
	if gs.canvas and gs.updateCanvasFlag then

		lg.setCanvas({gs.canvas, depth = true})
		lg.clear()
	end
end

function renderTarget:postWrap(dt)
	if gs.updateCanvasFlag then
		gs.updateCanvasFlag = false
	end

	if gs.canvas then
		lg.setCanvas()
		lg.draw(gs.canvas, 0,0,0, 0.5)
	end
end

return renderTarget