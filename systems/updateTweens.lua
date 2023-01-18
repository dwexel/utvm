assert(cpml)

local updateEntityFromTween = tiny.processingSystem()
updateEntityFromTween.updateSystem = true
updateEntityFromTween.processPlaying = true
updateEntityFromTween.filter = tiny.requireAll("tween")

-- function updateEntityFromTween:onModify(dt)
-- 	print('modified')
-- end

function updateEntityFromTween:process(e, dt)
	local tw = e.tween
	if not tw.finished and tw.t < tw.endTime then
		tw.t = tw.t + dt
		if tw.type == "q" then
			local q = cpml.quat.slerp(tw.initial, tw.final, tw.t/tw.endTime)
			e:setQuaternionRotation(q)
		elseif tw.type == "v" then
			local v = cpml.vec3.lerp(tw.initial, tw.final, tw.t/tw.endTime)
			e:setTranslation(v)
		end
	else
		tw.finished = true
	end
end

return updateEntityFromTween