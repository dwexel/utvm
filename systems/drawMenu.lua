-- spin = tiny.processingSystem()
-- spin.isUpdateSystem = true
-- spin.isPlaySystem = true
-- spin.filter = tiny.requireAll("spinning")

-- local a = 0
-- function spin:process(e, dt)
-- 	a = (a + dt/2) % (2*math.pi)
-- 	e:setRotation(0, a, 0)
-- end

----------------------------------------------------
-- draw systems
----------------------------------------------------



local lg = love.graphics

-- menu processing
drawMenu = tiny.processingSystem({
	static = {},
	inputQueue = "",
	c = 1,
})

drawMenu.drawSystem = true
drawMenu.processPaused = true
drawMenu.filter = tiny.requireAny("menu")

function drawMenu:preProcess(dt)
	lg.setColor(1, 1, 1)
	lg.rectangle("fill", 100, 100, 100, 100)

	if self.inputQueue == "up" then
		self.c = self.c - 1
		if self.c < 1 then self.c = 2 end
	elseif self.inputQueue == "down" then
		self.c = self.c + 1
		if self.c > 2 then self.c = 1 end
	end

	self.inputQueue = ""
end

function drawMenu:process(e, dt)
	local s = "%s"..table.concat(e.menu, "\n%s")
	for i = 1, #e.menu do drawMenu.static[i] = "" end
	drawMenu.static[self.c] = ">"
	s = s:format(unpack(drawMenu.static))
	lg.setFont(e.font)
	lg.print(s, e.x, e.y)
end



-- drawUI = tiny.processingSystem()
-- drawUI.isDrawSystem = true
-- drawUI.filter = tiny.requireAll("text", "x", "y")
-- function drawUI:process(e, dt)
-- 	love.graphics.print(e.text, e.x, e.y)
-- end


return drawMenu