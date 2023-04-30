local key = ModPath .. '	' .. RequiredScript
if _G[key] then return else _G[key] = true end

local fs_original_playerdriving_enter = PlayerDriving.enter
function PlayerDriving:enter(state_data, enter_data)
	self._was_unarmed = enter_data and enter_data.was_unarmed -- asap!

	fs_original_playerdriving_enter(self, state_data, enter_data)
end

local mvec3_add = mvector3.add
local trick_pos = Vector3(0, 0, 2)
local fs_original_playerdriving_update = PlayerDriving.update
function PlayerDriving:update(t, dt)
	mvec3_add(self._m_pos, trick_pos)
	self:_upd_nav_data()

	fs_original_playerdriving_update(self, t, dt)
end

if not FullSpeedSwarm.settings.optimized_inputs or _G.IS_VR then
	return
end

local fs_original_playerdriving_init = PlayerDriving.init
function PlayerDriving:init(...)
	fs_original_playerdriving_init(self, ...)

	self.fs_wanted_pressed = clone(self.fs_wanted_pressed)
	self.fs_wanted_pressed.vehicle_change_camera = 'btn_vehicle_change_camera'
	self.fs_wanted_pressed.vehicle_rear_camera = 'btn_vehicle_rear_camera_press'
	self.fs_wanted_pressed.vehicle_shooting_stance = 'btn_vehicle_shooting_stance'
	self.fs_wanted_pressed.vehicle_exit = 'btn_vehicle_exit_press'

	self.fs_wanted_released = clone(self.fs_wanted_released)
	self.fs_wanted_released.vehicle_rear_camera = 'btn_vehicle_rear_camera_release'
	self.fs_wanted_released.vehicle_exit = 'btn_vehicle_exit_release'
end

local fs_original_playerdriving_getinput = PlayerDriving._get_input
function PlayerDriving:_get_input(t, dt)
	if self.fs_heavy_use > 0 then
		self._get_input = PlayerDriving.super.fs_get_input
		return PlayerDriving.super.fs_get_input(self, t, dt)
	else
		return fs_original_playerdriving_getinput(self, t, dt)
	end
end
