local lg = love.graphics

local drawMenu = tiny.processingSystem({
	input = "",
	c = 1
})

local static = {}

drawMenu.drawSystem = true
drawMenu.processPaused = true
drawMenu.filter = tiny.requireAny("menu")

function drawMenu:preProcess(dt)
	lg.setColor(1, 1, 1)
	lg.rectangle("fill", 100, 100, 100, 100)

	if self.inputQueue == "up" then
		self.c = self.c - 1
		if self.c < 1 then 
			self.c = 2 
		end
	elseif self.inputQueue == "down" then
		self.c = self.c + 1
		if self.c > 2 then 
			self.c = 1 
		end
	end

	self.inputQueue = ""
end

function drawMenu:process(e, dt)
	local s = "%s"..table.concat(e.menu, "\n%s")
	for i = 1, #e.menu do static[i] = "" end
	static[self.c] = ">"
	s = s:format(unpack(static))
	lg.setFont(e.font)
	lg.print(s, e.x, e.y)
end

return drawMenu