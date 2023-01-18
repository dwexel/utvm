
assert(cpml)


local updateTweens = tiny.processingSystem()
updateTweens.updateSystem = true
updateTweens.processPlaying = true
updateTweens.filter = tiny.requireAll("tween")

function updateTweens:process(e, dt)
	local tw = e.tween
	if not tw.finished and tw.t < tw.endTime then
		tw.t = tw.t + dt
		
		-- catch cpml quat
		if type(tw.initial) == "cdata" then
			local q = cpml.quat.slerp(tw.initial, tw.final, tw.t/tw.endTime)
			-- local q = tw.initial:slerp(tw.final, tw.t)
			-- print(tw.initial, tw.final, tw.t)
			e:setQuaternionRotation(q)
		end
	else
		tw.finished = true
	end
end

return updateTweens