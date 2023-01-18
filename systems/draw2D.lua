local lg = love.graphics

local draw2D = tiny.system()
draw2D.drawSystem = true
draw2D.processPaused = true
draw2D.filter = tiny.requireAny("menu")

--[[
	I want to draw a rectangle over the screen
	I want everything drawn under it to have its colors multiplied by it

	why is alpha not working?
]]
	

function draw2D:update(dt)



	-- lg.setColor(1, 0.5, 0.2, 0.5)
	-- lg.rectangle("fill", 500, 400, 100, 200)
	-- lg.setColor(1, 1, 1, 1)


	lg.setBlendMode("multiply", "premultiplied")

	local w, h = lg.getDimensions()
	lg.setColor(0.5, 0.5, 0.3, 0.5)
	lg.rectangle("fill", 0,0, w,h)
	lg.setColor(1, 1, 1, 1)


	lg.setBlendMode("alpha", "alphamultiply")


end


return draw2D