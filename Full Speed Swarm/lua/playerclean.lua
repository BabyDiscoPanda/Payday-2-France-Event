local key = ModPath .. '	' .. RequiredScript
if _G[key] then return else _G[key] = true end

function PlayerClean:_upd_attention()
	self._ext_movement:set_attention_settings({
		'pl_mask_off_friend_combatant',
		'pl_mask_off_friend_non_combatant',
		'pl_mask_off_foe_combatant',
		'pl_mask_off_foe_non_combatant'
	})
end
