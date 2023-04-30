local key = ModPath .. '	' .. RequiredScript
if _G[key] then return else _G[key] = true end

if not FullSpeedSwarm.settings.optimized_inputs then
	return
end

core:module('CoreControllerWrapper')

local mvec3_copy = mvector3.copy

local fs_original_controllerwrapper_init = ControllerWrapper.init
function ControllerWrapper:init(...)
	self.fs_timer_wall_running = TimerManager:wall_running()
	fs_original_controllerwrapper_init(self, ...)
end

function ControllerWrapper:fs_reset()
	self.fs_delay_trigger_queue = not not next(self._delay_trigger_queue)
	self.fs_has_delay_map = not not next(self._delay_map)
	self.fs_has_multi_input_map = not not next(self._multi_input_map)
	self.fs_id2coname = self._setup:fs_get_ref_engine_ids()
end

for _, fname in ipairs({
	'init',
	'rebind_connections',
	'queue_delay_trigger',
	'remove_trigger',
	'_really_activate',
	'_really_deactivate',
}) do
	local fs_original_controllerwrapper_func = ControllerWrapper[fname]
	ControllerWrapper[fname] = function(self, ...)
		fs_original_controllerwrapper_func(self, ...)
		self:fs_reset()
	end
end

function ControllerWrapper:update(t, dt)
	self:reset_cache(true)
	if self.fs_has_delay_trigger_queue then
		self:update_delay_trigger_queue()
	end
	self:check_connect_changed_status()

	if alive(self._virtual_controller) then
		self._virtual_controller:clear_axis_triggers()
	end
end

function ControllerWrapper:reset_cache(check_time)
	local reset_cache_time = self.fs_timer_wall_running:time()

	if not check_time or self._reset_cache_time < reset_cache_time then
		self._input_any_cache = nil
		self._input_any_pressed_cache = nil
		self._input_any_released_cache = nil

		if next(self._input_pressed_cache) then
			self._input_pressed_cache = {}
		end

		if next(self._input_bool_cache) then
			self._input_bool_cache = {}
		end

		if next(self._input_float_cache) then
			self._input_float_cache = {}
		end

		if next(self._input_axis_cache) then
			self._input_axis_cache = {}
		end

		if _G.IS_VR then
			if next(self._input_touch_bool_cache) then
				self._input_touch_bool_cache = {}
			end

			if next(self._input_touch_pressed_cache) then
				self._input_touch_pressed_cache = {}
			end

			if next(self._input_touch_released_cache) then
				self._input_touch_released_cache = {}
			end
		end

		if self.fs_has_multi_input_map then
			self:update_multi_input()
		end
		if self.fs_has_delay_map then
			self:update_delay_input()
		end

		self._reset_cache_time = reset_cache_time
	end
end

local empty_dummy = {}

function ControllerWrapper:fs_get_all_input_pdr()
	if self._enabled then
		local vc = self._virtual_controller
		if vc then
			return vc:pressed_list(), vc:down_list(), vc:released_list()
		end
	end

	return empty_dummy, empty_dummy, empty_dummy
end

local mvec3_x = mvector3.x
local mvec3_y = mvector3.y
local mvec3_z = mvector3.z
local mvec3_set_static = mvector3.set_static
function ControllerWrapper:get_modified_axis(connection_name, connection, axis)
	local mul_x, mul_y, mul_z = connection:fs_get_multiplier()
	if mul_x then
		mvec3_set_static(axis, mvec3_x(axis) * mul_x, mvec3_y(axis) * mul_y, mvec3_z(axis) * mul_z)
	end

	local inv_x, inv_y, inv_z = connection:fs_get_inversion()
	if inv_x then
		mvec3_set_static(axis, mvec3_x(axis) * inv_x, mvec3_y(axis) * inv_y, mvec3_z(axis) * inv_z)
	end

	return self:lerp_axis(connection_name, connection, axis)
end

local id_strings = {}
local clbks = {}
function ControllerWrapper:get_input_axis_clbk(connection_name, func)
	if not self:enabled() then
		return
	end

	local id = id_strings[connection_name]
	if not id then
		id = Idstring(connection_name)
		id_strings[connection_name] = id
	end

	local clbkey = connection_name .. tostring(func) -- assume no callbacks spam
	local f = clbks[clbkey]
	if not f then
		local connection = self._setup:get_connection(connection_name)
		f = function(axis_id, controller_name, axis)
			local unscaled_axis = mvec3_copy(axis)
			func(
				self:get_modified_axis(connection_name, connection, axis),
				self:get_unscaled_axis(connection_name, connection, unscaled_axis),
				connection:get_multiplier()
			)
		end
		clbks[clbkey] = f
	end

	self._virtual_controller:add_axis_trigger(id, f)
end

function ControllerWrapper:fs_update(t, dt)
	if self.fs_has_delay_trigger_queue then
		self:update_delay_trigger_queue()
	end
	self:check_connect_changed_status()

	self:fs_process_all_pdr()
	self._input_axis_cache.move = nil
	self._input_axis_cache.drive = nil

	if alive(self._virtual_controller) then
		self._virtual_controller:clear_axis_triggers()
	end
end

function ControllerWrapper:fs_reset_cache(check_time)
	-- qued
end

function ControllerWrapper:fs_process_all_pdr()
	local pressed, downed, released = self:fs_get_all_input_pdr()

	local pressed_nr = #pressed
	local downed_nr = #downed
	local released_nr = #released

	local has_pressed = pressed_nr > 0
	local has_downed = downed_nr > 0
	local has_released = released_nr > 0

	self._input_any_cache = has_downed
	self._input_any_pressed_cache = has_pressed
	self._input_any_released_cache = has_released

	local id2coname = self.fs_id2coname
	for i = 1, pressed_nr do
		local name = id2coname[pressed[i]]
		pressed[i] = name
		pressed[name] = true
	end
	for i = 1, downed_nr do
		local name = id2coname[downed[i]]
		downed[i] = name
		downed[name] = true
	end
	for i = 1, released_nr do
		local name = id2coname[released[i]]
		released[i] = name
		released[name] = true
	end

	self.fs_pressed = pressed
	self.fs_downed = downed
	self.fs_released = released
end

function ControllerWrapper:fs_get_input_pressed(connection_name)
	return self.fs_pressed[connection_name]
end

function ControllerWrapper:fs_get_input_bool(connection_name)
	return self.fs_downed[connection_name]
end

function ControllerWrapper:fs_prepare_for_heavy_use()
	if self.fs_prepared_for_heavy_use then
		return 1
	end
	self.fs_prepared_for_heavy_use = true

	if _G.IS_VR or self.fs_has_multi_input_map or self.fs_has_delay_map then
		return 0
	end

	self.update = self.fs_update
	self.reset_cache = self.fs_reset_cache
	self.get_input_pressed = self.fs_get_input_pressed
	self.get_input_bool = self.fs_get_input_bool
	self:fs_process_all_pdr()

	return 2
end
