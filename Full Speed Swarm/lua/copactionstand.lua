local key = ModPath .. '	' .. RequiredScript
if _G[key] then return else _G[key] = true end

function CopActionStand:need_upd()
	return true
end

function CopActionStand:update(t)
	if self._ext_anim.base_need_upd then
		self._expired = true
	else
		self._ext_movement:upd_m_head_pos()
	end
end
