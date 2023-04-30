local key = ModPath .. '	' .. RequiredScript
if _G[key] then return else _G[key] = true end

if _G.IS_VR then
	return
end

local math_abs = math.abs
local math_clamp = math.clamp
local math_lerp = math.lerp
local math_pow = math.pow
local math_step = math.step
local mvec3_add = mvector3.add
local mvec3_neg = mvector3.negate
local mvec3_rot = mvector3.rotate_with
local mvec3_set = mvector3.set
local mrot_lookat = mrotation.set_look_at
local mrot_mul = mrotation.multiply
local mrot_set = mrotation.set_yaw_pitch_roll
local mrot_set_zero = mrotation.set_zero

local mvec1 = Vector3()
local mvec2 = Vector3()
local mvec3 = Vector3()
local mrot1 = Rotation()
local mrot2 = Rotation()
local mrot3 = Rotation()
local mrot4 = Rotation()

local fs_original_fpcameraplayerbase_init = FPCameraPlayerBase.init
function FPCameraPlayerBase:init(...)
	self.fs_clbk = callback(self, self, '_update_rot')
	fs_original_fpcameraplayerbase_init(self, ...)
end

local fs_original_fpcameraplayerbase_setparentunit = FPCameraPlayerBase.set_parent_unit
function FPCameraPlayerBase:set_parent_unit(...)
	fs_original_fpcameraplayerbase_setparentunit(self, ...)
	self.fs_parent_camera_ext = self._parent_unit:camera()
	self.fs_parent_inventory_ext = self._parent_unit:inventory()
	self.fs_parent_base_ext = self._parent_unit:base()
	self.fs_parent_controller = self.fs_parent_base_ext:controller()
end

local ids_fire = Idstring('fire')
function FPCameraPlayerBase:update(unit, t, dt)
	if self._tweak_data.aim_assist_use_sticky_aim then
		self:_update_aim_assist_sticky(t, dt)
	end

	self.fs_parent_controller:get_input_axis_clbk('look', self.fs_clbk)

	self:_update_stance(t, dt)
	self:_update_movement(t, dt)

	local parent_unit_camera = self.fs_parent_camera_ext
	if managers.player:current_state() ~= 'driving' then
		local output_data = self._output_data
		parent_unit_camera:set_position(output_data.position)
		parent_unit_camera:set_rotation(output_data.rotation)
	else
		self:_set_camera_position_in_vehicle()
	end

	local fov = self._fov
	if fov.dirty then
		parent_unit_camera:set_FOV(fov.fov)
		fov.dirty = nil
	end

	if alive(self._light) then
		local weapon = self.fs_parent_inventory_ext:equipped_unit()
		if weapon then
			local object = weapon:get_object(ids_fire)
			local obj_rot = object:rotation()
			local x, y, z = obj_rot:x(), obj_rot:y(), obj_rot:z()
			local pos = object:position() + y * 10 + z * -2

			self._light:set_position(pos)
			self._light:set_rotation(Rotation(z, x, y))
			World:effect_manager():move_rotate(self._light_effect, pos, Rotation(x, -y, -z))
		end
	end
end

function FPCameraPlayerBase:_calculate_soft_velocity_overshot(dt)
	local stick_input = self._input.look
	if not stick_input then
		return
	end

	local vel_overshot = self._vel_overshot
	local target_yaw, target_pitch, final_yaw, final_pitch
	local uses_keyboard = self._tweak_data.uses_keyboard
	local mul = uses_keyboard and 0.002 / dt or 0.4
	local step_v = uses_keyboard and 120 * dt or 2
	local diff_clamp = 40

	do
	local stick_input_x, input_yaw = stick_input.x
	if stick_input_x >= 0 then
		input_yaw = vel_overshot.yaw_pos
	else
		stick_input_x = -stick_input_x
		input_yaw = vel_overshot.yaw_neg
	end
	stick_input_x = math_pow(math_clamp(mul * stick_input_x, 0, 1), 1.5)
	input_yaw = input_yaw * stick_input_x
	target_yaw = math_step(vel_overshot.target_yaw, input_yaw, step_v)
	end

	do
	local last_yaw = vel_overshot.last_yaw
	local diff = math_abs(target_yaw - last_yaw)
	local diff_ratio = diff / diff_clamp
	local diff_ratio_clamped = math_clamp(diff_ratio, 0, 1)
	local step_amount = math_lerp(3, 180, diff_ratio_clamped) * dt
	final_yaw = math_step(last_yaw, target_yaw, step_amount)
	vel_overshot.target_yaw = target_yaw
	vel_overshot.last_yaw = final_yaw
	end

	do
	local stick_input_y, input_pitch = stick_input.y
	if stick_input_y >= 0 then
		input_pitch = vel_overshot.pitch_pos
	else
		stick_input_y = -stick_input_y
		input_pitch = vel_overshot.pitch_neg
	end
	stick_input_y = math_pow(math_clamp(mul * stick_input_y, 0, 1), 1.5)
	input_pitch = input_pitch * stick_input_y
	target_pitch = math_step(vel_overshot.target_pitch, input_pitch, step_v)
	end

	do
	local last_pitch = vel_overshot.last_pitch
	local diff = math_abs(target_pitch - last_pitch)
	local diff_ratio = diff / diff_clamp
	local diff_ratio_clamped = math_clamp(diff_ratio, 0, 1)
	local step_amount = math_lerp(3, 180, diff_ratio_clamped) * dt
	final_pitch = math_step(last_pitch, target_pitch, step_amount)
	vel_overshot.target_pitch = target_pitch
	vel_overshot.last_pitch = final_pitch
	end

	mrot_set(vel_overshot.rotation, final_yaw, final_pitch, -final_yaw)

	local pivot = vel_overshot.pivot
	local new_root = mvec3
	mvec3_set(new_root, pivot)
	mvec3_neg(new_root)
	mvec3_rot(new_root, vel_overshot.rotation)
	mvec3_add(new_root, pivot)
	mvec3_set(vel_overshot.translation, new_root)
end

if not FullSpeedSwarm.settings.optimized_inputs then
	return -- because get_input_axis_clbk()
end

function FPCameraPlayerBase:_update_rot(axis, unscaled_axis, look_multiplier)
	if self._animate_pitch then
		self:animate_pitch_upd()
	end

	local managers_player = managers.player
	local t = managers_player:player_timer():time()
	local dt = t - (self._last_rot_t or t)
	self._last_rot_t = t
	local camera_properties = self._camera_properties
	local new_head_pos = mvec2
	local new_head_rot = mrot2

	local parent_unit = self._parent_unit
	parent_unit:m_position(new_head_pos)
	mvec3_add(new_head_pos, self._head_stance.translation)

	local input = self._input
	input.look = axis
	input.look_multiplier = look_multiplier
	local stick_input_x, stick_input_y = self._look_function(axis, look_multiplier, dt, unscaled_axis)
	local look_polar_spin = camera_properties.spin - stick_input_x
	local look_polar_pitch = math_clamp(camera_properties.pitch + stick_input_y, -85, 85)
	local player_state = managers_player:current_state()

	local limits = self._limits
	if limits then
		if limits.spin then
			local d = (look_polar_spin - limits.spin.mid) / limits.spin.offset
			d = math_clamp(d, -1, 1)
			look_polar_spin = camera_properties.spin - math_lerp(stick_input_x, 0, math_abs(d))
		end

		if limits.pitch then
			local d = math_abs((look_polar_pitch - limits.pitch.mid) / limits.pitch.offset)
			d = math_clamp(d, -1, 1)
			look_polar_pitch = camera_properties.pitch + math_lerp(stick_input_y, 0, math_abs(d))
			look_polar_pitch = math_clamp(look_polar_pitch, -85, 85)
		end
	end

	if not limits or not limits.spin then
		look_polar_spin = look_polar_spin % 360
	end

	local look_polar = Polar(1, look_polar_pitch, look_polar_spin)
	local look_vec = look_polar:to_vector()
	local cam_offset_rot = mrot3
	mrot_lookat(cam_offset_rot, look_vec, math.UP)

	if self._animate_pitch == nil then
		mrot_set_zero(new_head_rot)
		mrot_mul(new_head_rot, self._head_stance.rotation)
		mrot_mul(new_head_rot, cam_offset_rot)
		camera_properties.pitch = look_polar_pitch
		camera_properties.spin = look_polar_spin
	end

	local parent_unit_camera = self.fs_parent_camera_ext
	local parent_unit_mov = self._parent_movement_ext
	local output_data = self._output_data
	output_data.position = new_head_pos

	if self._p_exit then
		self._p_exit = false
		output_data.rotation = parent_unit_mov.fall_rotation
		mrot_mul(output_data.rotation, parent_unit_camera:rotation())
		camera_properties.spin = output_data.rotation:y():to_polar().spin
	else
		output_data.rotation = new_head_rot --or output_data.rotation
	end

	local current_tilt = camera_properties.current_tilt
	local target_tilt = camera_properties.target_tilt
	if current_tilt ~= target_tilt then
		current_tilt = math.step(current_tilt, target_tilt, 150 * dt)
		camera_properties.current_tilt = current_tilt
	end

	if current_tilt ~= 0 then
		output_data.rotation = Rotation(output_data.rotation:yaw(), output_data.rotation:pitch(), output_data.rotation:roll() + current_tilt)
	end

	local new_shoulder_pos = mvec1
	local new_shoulder_rot = mrot1
	local bipod_rot = new_shoulder_rot
	local vel_overshot = self._vel_overshot
	local shoulder_stance = self._shoulder_stance

	if player_state == 'driving' then
		self:_set_camera_position_in_vehicle()
	elseif player_state == 'jerry1' or player_state == 'jerry2' then
		mrot_set_zero(cam_offset_rot)
		mrot_mul(cam_offset_rot, parent_unit_mov.fall_rotation)
		mrot_mul(cam_offset_rot, output_data.rotation)

		local shoulder_pos = mvec3
		local shoulder_rot = mrot4

		mrot_set_zero(shoulder_rot)
		mrot_mul(shoulder_rot, cam_offset_rot)
		mrot_mul(shoulder_rot, shoulder_stance.rotation)
		mrot_mul(shoulder_rot, vel_overshot.rotation)
		mvec3_set(shoulder_pos, shoulder_stance.translation)
		mvec3_add(shoulder_pos, vel_overshot.translation)
		mvec3_rot(shoulder_pos, cam_offset_rot)
		mvec3_add(shoulder_pos, parent_unit:position())
		self:set_position(shoulder_pos)
		self:set_rotation(shoulder_rot)
		parent_unit_camera:set_position(parent_unit:position())
		parent_unit_camera:set_rotation(cam_offset_rot)

	else
		mvec3_set(new_shoulder_pos, shoulder_stance.translation)
		mvec3_add(new_shoulder_pos, vel_overshot.translation)
		mvec3_rot(new_shoulder_pos, output_data.rotation)
		mvec3_add(new_shoulder_pos, new_head_pos)
		mrot_set_zero(new_shoulder_rot)
		mrot_mul(new_shoulder_rot, output_data.rotation)
		mrot_mul(new_shoulder_rot, shoulder_stance.rotation)
		mrot_mul(new_shoulder_rot, vel_overshot.rotation)

		self:set_position(new_shoulder_pos)
		self:set_rotation(new_shoulder_rot)
		parent_unit_camera:set_position(output_data.position)
		parent_unit_camera:set_rotation(output_data.rotation)
	end

	if not parent_unit_mov._current_state:in_steelsight() then
		if player_state == 'bipod' then
			self:set_position(PlayerBipod._shoulder_pos or new_shoulder_pos)
			self:set_rotation(bipod_rot)
			parent_unit_camera:set_position(PlayerBipod._camera_pos or output_data.position)
		else
			local equipped_weapon = self.fs_parent_inventory_ext:equipped_unit()
			local bipod_weapon_translation = Vector3()
			if equipped_weapon and equipped_weapon:base() then
				local weapon_tweak_data = equipped_weapon:base():weapon_tweak_data()
				if weapon_tweak_data and weapon_tweak_data.bipod_weapon_translation then
					bipod_weapon_translation = weapon_tweak_data.bipod_weapon_translation
				end
			end
			local bipod_pos = Vector3()
			mvec3_set(bipod_pos, bipod_weapon_translation)
			mvec3_rot(bipod_pos, output_data.rotation)
			mvec3_add(bipod_pos, new_head_pos)
			PlayerBipod:set_camera_positions(bipod_pos, output_data.position)
		end
	end
end
