local lg = love.graphics

local renderTarget = tiny.system({
	input = "",
	canvas = lg.newCanvas()
})

renderTarget.drawSystem = true
renderTarget.modes = {NORMAL, CANVAS}
renderTarget.mode = 1

-- called on each system before update is called on any system
function renderTarget:preWrap(dt)
	local n = tonumber(self.input)
	if n then 
		self.mode = n
	end


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

return renderTarget