local lg = love.graphics

local drawMenu = tiny.processingSystem({input = ""})

-- private
local t = {}
local s = ""
local c = 1
local execute = false

drawMenu.drawSystem = true
drawMenu.processPaused = true
drawMenu.filter = tiny.requireAny("menu")

function drawMenu:preProcess(dt)
	lg.setColor(1, 1, 1)
	lg.rectangle("fill", 100, 100, 100, 100)

	local i = self.input
	
	if i == "up" or i == "w" then
		c = c - 1
		if c < 1 then 
			c = 2 
		end
	elseif i == "down" or i == "s" then
		c = c + 1
		if c > 2 then 
			c = 1 
		end
	end

	if i == "return" then
		execute = true
	end

	self.input = ""
end

function drawMenu:process(e, dt)
	if execute then
		e.menu[c].fn()
		execute = false
	end


	s = ""
	t = {}
	for i, v in ipairs(e.menu) do
		s = s.."%s"..v.label.."\n"
		t[i] = ""
	end
	t[c] = ">"
	s = s:format(unpack(t))
	lg.setFont(e.font)
	lg.print(s, e.x, e.y)
end

return drawMenu