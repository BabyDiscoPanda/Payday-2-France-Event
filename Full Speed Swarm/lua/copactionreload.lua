local key = ModPath .. '	' .. RequiredScript
if _G[key] then return else _G[key] = true end

local fs_original_copactionreload_update = CopActionReload.update
function CopActionReload:update(t)
	if t > self._reload_t then
		if not alive(self._weapon_unit) then
			self._expired = true
			return
		end
	end

	fs_original_copactionreload_update(self, t)
end
