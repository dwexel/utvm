-- assert(graphicsState)


-- local function pickTest(x, y, getClickableSystem)
-- 	assert(getClickableSystem)

-- 	getClickableSystem:update()
-- 	local len = #getClickableSystem.entities
-- 	for i, e in pairs(getClickableSystem.entities) do
-- 		e.ID = i / len
-- 	end

-- 	graphicsState.updateCanvasFlag = true
-- 	drawModels.active = false
-- 	drawID.active = true
-- 	graphicsState.shader = shaders.solidColorShader
-- 	graphicsState.bbShader = shaders.solidColorbbShader

-- 	coroutine.yield()
	
-- 	drawModels.active = true
-- 	drawID.active = false
-- 	graphicsState.shader = shaders.defaultShader
-- 	graphicsState.bbShader = shaders.defaultbbShader
-- 	local data = graphicsState.canvas:newImageData()
-- 	local r, g, b, a = data:getPixel(x, y)

-- 	if r == 0 then
-- 		return
-- 	end

-- 	local min = math.huge
-- 	local en_i = -1

-- 	for i, e in ipairs(getClickableSystem.entities) do
-- 		local d = math.abs(e.ID - r)
-- 		if d < min then
-- 			min = d
-- 			en_i = i
-- 		end
-- 		-- clear ID
-- 		e.ID = nil
-- 	end

-- 	local entity = getClickableSystem.entities[en_i]

-- 	-- do callback
-- 	assert(type(entity.onClick) == "function")
-- 	entity:onClick()
-- end

-- return pickTest