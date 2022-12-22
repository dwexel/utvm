assert(graphicsState)

local lg = love.graphics
local gs = graphicsState
local renderOnce = tiny.system()

renderOnce.drawSystem = true
renderOnce.active = false

function renderOnce:render()
	self.active = true
end

function renderOnce:preWrap(dt)
	print("here")
end

function renderOnce:postWrap(dt)
	print("here too")
	self.active = false
end


return renderOnce