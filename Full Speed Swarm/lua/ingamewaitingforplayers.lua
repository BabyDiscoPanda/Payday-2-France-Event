local key = ModPath .. '	' .. RequiredScript
if _G[key] then return else _G[key] = true end

local fs_original_ingamewaitingforplayersstate_atexit = IngameWaitingForPlayersState.at_exit
function IngameWaitingForPlayersState:at_exit(...)
	if not managers.mutators:are_mutators_enabled() then
		managers.mutators.update = function() end
	end

	if FullSpeedSwarm.settings.optimized_inputs then
		self._controller:set_enabled(false)
	end

	return fs_original_ingamewaitingforplayersstate_atexit(self, ...)
end
