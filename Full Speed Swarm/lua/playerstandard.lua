local key = ModPath .. '	' .. RequiredScript
if _G[key] then return else _G[key] = true end

local fs_original_playerstandard_update = PlayerStandard.update
function PlayerStandard:update(t, dt)
	fs_original_playerstandard_update(self, t, dt)

	if self._equipped_visibility_timer and t > self._equipped_visibility_timer and alive(self._equipped_unit) then
		self._equipped_visibility_timer = nil
	end
end

local fs_original_playerstandard__enter = PlayerStandard._enter
function PlayerStandard:_enter(...)
	if alive(self._equipped_unit) then
		self._equipped_unit:base():set_visibility_state(true)
	end

	return fs_original_playerstandard__enter(self, ...)
end

local fs_original_playerstandard_updattention = PlayerStandard._upd_attention
function PlayerStandard:_upd_attention()
	if self._seat and self._was_unarmed and managers.groupai:state():whisper_mode() then
		local preset = {
			'pl_mask_off_friend_combatant',
			'pl_mask_off_friend_non_combatant',
			'pl_mask_off_foe_combatant',
			'pl_mask_off_foe_non_combatant'
		}
		self._ext_movement:set_attention_settings(preset)
	else
		fs_original_playerstandard_updattention(self)
	end
end

local mvec3_dot = mvector3.dot
local mvec3_mul = mvector3.multiply
local mvec3_norm = mvector3.normalize
local mvec3_set = mvector3.set
local mvec3_set_z = mvector3.set_z
local mvec3_set_zero = mvector3.set_zero

local hold_to_run, hold_to_duck
local function _update_hold_to_run()
	hold_to_run = managers.user:get_setting('hold_to_run')
end
local function _update_hold_to_duck()
	hold_to_duck = managers.user:get_setting('hold_to_duck')
end

function PlayerStandard:_calculate_standard_variables() --t, dt)
	self._gnd_ray = nil
	self._gnd_ray_chk = nil
	self._unit:m_position(self._pos)
	self._rot = self._unit:rotation()
	self._cam_fwd = self._ext_camera:forward()

	mvec3_set(self._cam_fwd_flat, self._cam_fwd)
	mvec3_set_z(self._cam_fwd_flat, 0)
	mvec3_norm(self._cam_fwd_flat)

	local last_vel_xy = self._last_velocity_xy
	local sampled_vel_dir = self._unit:sampled_velocity()
	if not self._state_data.on_ladder then
		mvec3_set_z(sampled_vel_dir, 0)
	end
	local sampled_vel_len = mvec3_norm(sampled_vel_dir)
	if sampled_vel_len == 0 then
		mvec3_set_zero(self._last_velocity_xy)
	else
		local fwd_dot = mvec3_dot(sampled_vel_dir, last_vel_xy)
		mvec3_set(self._last_velocity_xy, sampled_vel_dir)
		mvec3_mul(self._last_velocity_xy, sampled_vel_len < fwd_dot and sampled_vel_len or math.max(0, fwd_dot))
	end

	self._setting_hold_to_run = hold_to_run
	self._setting_hold_to_duck = hold_to_duck
end

PlayerStandard.fs_update_crosshair_offset = PlayerStandard._update_crosshair_offset
PlayerStandard._update_crosshair_offset = function() end

local fs_original_playerstandard_startactionsteelsight = PlayerStandard._start_action_steelsight
function PlayerStandard:_start_action_steelsight(t)
	fs_original_playerstandard_startactionsteelsight(self, t)
	self:fs_update_crosshair_offset(t)
end

local fs_original_playerstandard_endactionsteelsight = PlayerStandard._end_action_steelsight
function PlayerStandard:_end_action_steelsight(t)
	fs_original_playerstandard_endactionsteelsight(self, t)
	self:fs_update_crosshair_offset(t)
end

DelayedCalls:Add('DelayedModFSS_playerstandardinit', 0, function()
	local fs_original_playerstandard_init = PlayerStandard.init
	function PlayerStandard:init(...)
		fs_original_playerstandard_init(self, ...)
		managers.user:add_setting_changed_callback('hold_to_run', _update_hold_to_run)
		_update_hold_to_run()
		managers.user:add_setting_changed_callback('hold_to_duck', _update_hold_to_duck)
		_update_hold_to_duck()

		local clbk_crosshair = function()
			if self._equipped_unit then
				self:fs_update_crosshair_offset(TimerManager:game():time())
			end
		end
		managers.user:add_setting_changed_callback('accessibility_dot', clbk_crosshair)
		managers.user:add_setting_changed_callback('accessibility_dot_size', clbk_crosshair)
		managers.user:add_setting_changed_callback('accessibility_dot_hide_ads', clbk_crosshair)
	end
end)

if not FullSpeedSwarm.settings.optimized_inputs or _G.IS_VR then
	return
end

DelayedCalls:Add('DelayedModFSS_playerstandardinit_input', 0, function()
	local fs_original_playerstandard_init = PlayerStandard.init
	function PlayerStandard:init(...)
		fs_original_playerstandard_init(self, ...)

		self.fs_wanted_pressed = {
			stats_screen = 'btn_stats_screen_press',
			duck = 'btn_duck_press',
			jump = 'btn_jump_press',
			primary_attack = 'btn_primary_attack_press',
			reload = 'btn_reload_press',
			secondary_attack = 'btn_steelsight_press',
			interact = 'btn_interact_press',
			run = 'btn_run_press',
			switch_weapon = 'btn_switch_weapon_press',
			use_item = 'btn_use_item_press',
			melee = 'btn_melee_press',
			weapon_gadget = 'btn_weapon_gadget_press',
			throw_grenade = 'btn_throw_grenade_press',
			weapon_firemode = 'btn_weapon_firemode_press',
			cash_inspect = 'btn_cash_inspect_press',
			deploy_bipod = 'btn_deploy_bipod',
			change_equipment = 'btn_change_equipment',
			interact_secondary = 'btn_interact_secondary_press',
			primary_choice1 = 'btn_primary_choice1',
			primary_choice2 = 'btn_primary_choice2',
		}
		self.fs_last_pressed_t = {}
		for _, v in pairs(self.fs_wanted_pressed) do
			self.fs_last_pressed_t[v] = -1000
		end

		self.fs_wanted_released = {
			stats_screen = 'btn_stats_screen_release',
			duck = 'btn_duck_release',
			primary_attack = 'btn_primary_attack_release',
			secondary_attack = 'btn_steelsight_release',
			interact = 'btn_interact_release',
			run = 'btn_run_release',
			use_item = 'btn_use_item_release',
			melee = 'btn_melee_release',
			throw_grenade = 'btn_projectile_release',
		}

		self.fs_wanted_downed = {
			primary_attack = 'btn_primary_attack_state',
			secondary_attack = 'btn_steelsight_state',
			run = 'btn_run_state',
			melee = 'btn_meleet_state',
			throw_grenade = 'btn_projectile_state',
		}
	end
end)

local fs_original_playerstandard_enter = PlayerStandard.enter
function PlayerStandard:enter(...)
	fs_original_playerstandard_enter(self, ...)
	self.fs_heavy_use = self._controller:fs_prepare_for_heavy_use()
	if self.fs_heavy_use > 0 then
		self._get_input = self.fs_get_input
	end
end

function PlayerStandard:fs_get_input(t, dt, paused)
	local state_data = self._state_data
	local controller = self._controller
	local controller_enabled = controller:enabled()
	local old_controller_enabled = state_data.controller_enabled
	if old_controller_enabled ~= controller_enabled then
		if old_controller_enabled then
			state_data.controller_enabled = controller_enabled
			return self:_create_on_controller_disabled_input()
		end
	elseif not old_controller_enabled then
		local input = {
			is_customized = true,
			btn_interact_release = managers.menu:get_controller():get_input_released('interact')
		}
		return input
	end
	state_data.controller_enabled = controller_enabled

	if paused then
		self._input_paused = true
		return {}
	end

	local pressed, downed, released = controller.fs_pressed, controller.fs_downed, controller.fs_released
	local pressed_nr = #pressed
	local released_nr = #released
	local downed_nr = #downed
	local has_pressed = pressed_nr > 0
	local has_released = released_nr > 0
	local has_downed = downed_nr > 0

	if not has_downed then
		self._input_paused = false
		if not has_pressed and not has_released then
			return {}
		end
	end

	local input = {
		data = { _unit = self._unit },
		any_input_pressed = has_pressed,
		any_input_released = has_released,
		any_input_downed = has_downed
	}

	if has_pressed then
		local wanted_pressed = self.fs_wanted_pressed
		for i = 1, pressed_nr do
			local btn = wanted_pressed[pressed[i]]
			if btn then
				input[btn] = true
				self.fs_last_pressed_t[btn] = t
			end
		end
		input.btn_projectile_press = input.btn_throw_grenade_press
		input.btn_primary_choice = input.btn_primary_choice1 and 1 or input.btn_primary_choice2 and 2 or nil
		if input.btn_stats_screen_press and self._unit:base():stats_screen_visible() then
			input.btn_stats_screen_press = false
		end
	end

	if has_downed then
		local wanted_downed = self.fs_wanted_downed
		for i = 1, downed_nr do
			local btn = wanted_downed[downed[i]]
			if btn then
				input[btn] = true
			end
		end
	end

	if has_released then
		local wanted_released = self.fs_wanted_released
		for i = 1, released_nr do
			local btn = wanted_released[released[i]]
			if btn then
				input[btn] = true
			end
		end
		if input.btn_stats_screen_release and not self._unit:base():stats_screen_visible() then
			input.btn_stats_screen_release = false
		end
	end

	local tupni = self._input
	if tupni then
		local current_state_name = self._ext_movement:current_state_name()
		for i = #tupni, 1, -1 do
			tupni[i]:update(t, dt, controller, input, current_state_name)
		end
	end

	return input
end

local fs_original_playerstandard_checkactionprimaryattack = PlayerStandard._check_action_primary_attack
function PlayerStandard:_check_action_primary_attack(t, input)
	if self._equipped_unit and not input.btn_primary_attack_press then
		if self.fs_last_pressed_t.btn_primary_attack_press > t - 0.2 then
			local wbase = self._equipped_unit:base()
			if not wbase._charging and wbase:fire_mode() == 'single' and not wbase:clip_empty() then
				input.btn_primary_attack_press = true
			end
		end
	end

	local result = fs_original_playerstandard_checkactionprimaryattack(self, t, input)

	if result then
		self.fs_last_pressed_t.btn_primary_attack_press = 0
	end

	return result
end
