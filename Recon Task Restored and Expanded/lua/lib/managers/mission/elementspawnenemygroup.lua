Hooks:PostHook(ElementSpawnEnemyGroup, "init", "star_recon_init_spawn_group_element", function(self, ...)
    local groups = self._values.preferred_spawn_groups

    if groups ~= nil then
        for k, v in pairs(groups) do
            if v == "tac_swat_rifle_flank" then
                if tweak_data and tweak_data.group_ai and tweak_data.group_ai.star_recon_groups_to_inject then
                    for _, group in pairs(tweak_data.group_ai.star_recon_groups_to_inject) do
                        table.insert(groups, group)
                    end
                else
                    table.insert(groups, "tac_recon_case")
                    table.insert(groups, "tac_recon_rescue")
                    table.insert(groups, "tac_recon_rush")
                    table.insert(groups, "tac_recon_police")
                    table.insert(groups, "tac_recon_swats")
                    table.insert(groups, "tac_reenforce_2lights")
                    table.insert(groups, "tac_reenforce_1heavy")
                    table.insert(groups, "tac_reenforce_2heavies")
                    table.insert(groups, "tac_reenforce_team")
                    table.insert(groups, "tac_reenforce_police")
                    table.insert(groups, "tac_reenforce_swats")
                    table.insert(groups, "tac_bronco_guy")
                    table.insert(groups, "tac_reenforce_swat_rifle")
                    table.insert(groups, "tac_reenforce_swat_shotgun")
                    log("Recon Task Restored and Expanded: could not find groups to inject, inserting all")
                end
                break
            end
        end
    end
    --testing
    --for k, v in pairs(groups) do
        --log("Key: " .. k .. " Data: " .. v)
    --end
end)