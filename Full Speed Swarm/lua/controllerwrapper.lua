local key = ModPath .. '	' .. RequiredScript
if _G[key] then return else _G[key] = true end

if not FullSpeedSwarm.settings.optimized_inputs then
	return
end

function ControllerWrapper:fs_get_input_released(connection_name)
	return self.fs_released[connection_name]
end

function ControllerWrapper:fs_reset_cache(check_time)
	-- qued
end

function ControllerWrapper:fs_prepare_for_heavy_use()
	local result = ControllerWrapper.super.fs_prepare_for_heavy_use(self)

	if result == 2 then
		self.get_input_released = self.fs_get_input_released
		self.reset_cache = self.fs_reset_cache
	end

	return result
end
