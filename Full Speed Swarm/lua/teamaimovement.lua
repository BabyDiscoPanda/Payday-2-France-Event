local key = ModPath .. '	' .. RequiredScript
if _G[key] then return else _G[key] = true end

local fs_original_teamaimovement_setcarryingbag = TeamAIMovement.set_carrying_bag
function TeamAIMovement:set_carrying_bag(unit)
	fs_original_teamaimovement_setcarryingbag(self, unit)
	if unit and not unit:carry_data():can_explode() then
		unit:set_extension_update_enabled(Idstring('carry_data'), false)
	end
end

local fs_original_teamaimovement_predestroy = TeamAIMovement.pre_destroy
function TeamAIMovement:pre_destroy()
	TeamAIMovement.super.pre_destroy(self)
	fs_original_teamaimovement_predestroy(self)
end

function TeamAIMovement:throw_bag(target_unit, reason)
	if not self:carrying_bag() then
		return
	end

	local carry_unit = self._carry_unit
	self._was_carrying = {
		unit = carry_unit,
		reason = reason
	}

	carry_unit:carry_data():unlink()

	if Network:is_server() then
		-- self:sync_throw_bag(carry_unit, target_unit)
		-- managers.network:session():send_to_peers("sync_ai_throw_bag", self._unit, carry_unit, target_unit)
		-- ^^^ no, no, NO!

		local position, direction, force = carry_unit:position()

		if alive(target_unit) then
			direction = target_unit:position() - self._unit:position()
			mvector3.set_z(direction, math.abs(direction.x + direction.y) * 0.5)
			local throw_distance_multiplier = tweak_data.carry.types[tweak_data.carry[carry_unit:carry_data():carry_id()].type].throw_distance_multiplier
			force = tweak_data.ai_carry.throw_force * throw_distance_multiplier
		else
			direction = Vector3()
			force = 0
		end

		carry_unit:carry_data():set_position_and_throw(position, direction, force)
	end
end
