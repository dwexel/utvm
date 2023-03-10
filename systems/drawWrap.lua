assert(graphicsState)

local lg = love.graphics
local gs = graphicsState

local drawWrap = tiny.system({
	coroutine = nil
})
drawWrap.drawSystem = true
drawWrap.active = true

-- function drawWrap:preWrap()
-- 	lg.setColor(1, 1, 1)
-- end

-- called after all things have been drawn
function drawWrap:postWrap()
	if self.coroutine then
		coroutine.resume(self.coroutine)
		self.coroutine = nil
	end
end

return drawWrap