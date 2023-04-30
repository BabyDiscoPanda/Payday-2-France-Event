local key = ModPath .. '	' .. RequiredScript
if _G[key] then return else _G[key] = true end

if not FullSpeedSwarm.settings.optimized_inputs then
	return
end

core:module('CoreControllerManager')

function ControllerManager:update(t, dt)
	for _, controller in ipairs(self.__really_active) do
		controller:update(t, dt)
	end

	self:check_connect_change()
end

function ControllerManager:check_connect_change()
	if self._default_controller_list then
		local connected
		for _, controller in ipairs(self._default_controller_list) do
			connected = controller:connected()
			if not connected then
				break
			end
		end

		if not Global.controller_manager.default_controller_connected ~= not connected then
			self:default_controller_connect_change(connected)
			Global.controller_manager.default_controller_connected = connected
		end
	end
end
