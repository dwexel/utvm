local lg = love.graphics


-- private, statically allocated
local t = {}
local s = ""
local menu_i = 1
local execute = false

local drawMenu = tiny.processingSystem({input = ""})
drawMenu.drawSystem = true
drawMenu.processPaused = true
drawMenu.filter = tiny.requireAny("menu")



function drawMenu:preProcess(dt)
	lg.setColor(1, 1, 1)
	lg.rectangle("fill", 100, 100, 100, 100)

	local key = self.input
	
	if key == "up" or key == "w" then
		menu_i = menu_i - 1
	elseif key == "down" or key == "s" then
		menu_i = menu_i + 1
	end

	if key == "return" then
		execute = true
	end

	self.input = ""
end

function drawMenu:process(e, dt)
	if execute then
		e.menu[menu_i].fn()
		execute = false
	end

	s = ""
	t = {}

	for i, item in ipairs(e.menu) do
		s = s.."%s"..item.label.."\n"
		t[i] = ""
	end

	t[menu_i] = ">"
	s = s:format(unpack(t))
	lg.setFont(e.font)
	lg.print(s, e.x, e.y)
end

return drawMenu