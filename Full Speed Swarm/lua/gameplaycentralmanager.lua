local key = ModPath .. '	' .. RequiredScript
if _G[key] then return else _G[key] = true end

function GamePlayCentralManager:set_flashlights_on(flashlights_on)
	if self._flashlights_on == flashlights_on then
		return
	end

	self._flashlights_on = flashlights_on
	local weapons = World:find_units('all', 13)
	for _, weapon in ipairs(weapons) do
		local wbase = weapon:base()
		if wbase and wbase.flashlight_state_changed then
			wbase:flashlight_state_changed()
		end
	end
end
