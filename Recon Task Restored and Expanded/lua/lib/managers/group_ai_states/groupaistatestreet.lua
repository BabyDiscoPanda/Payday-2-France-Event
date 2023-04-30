-- like for besiege we need to manually hook.
local old_begin_assault = GroupAIStateStreet._begin_assault
function GroupAIStateStreet:_begin_assault()
    -- don't remove extra anticipation time if it's the first assault or skirmish (holdout)
    local extend_anticipation = self._task_data.assault.is_first or managers.skirmish:is_skirmish()

    old_begin_assault(self)

    if not self._task_data.assault.extra_time then
        self._task_data.assault.extra_time = 0
    end

    -- remove delay
    if (not extend_anticipation) and (not self._hunt_mode) and self._task_data.assault.is_hesitating then
        self._task_data.assault.is_hesitating = nil
        self._task_data.assault.phase_end_t = self._task_data.assault.phase_end_t - self:_get_difficulty_dependent_value(self._tweak_data.assault.hostage_hesitation_delay) + self._task_data.assault.extra_time
    end
end

--I don't even think this state is used in this game but whatever lol
--to do this with a hook it's potentially too performance-damaging so it's redefined
function GroupAIStateStreet:_begin_new_tasks()
    local all_areas = self._area_data
    local nav_manager = managers.navigation
    local all_nav_segs = nav_manager._nav_segments
    local task_data = self._task_data
    local t = self._t
    local reenforce_candidates = nil
    local reenforce_data = task_data.reenforce

    if reenforce_data.next_dispatch_t and reenforce_data.next_dispatch_t < t then
        reenforce_candidates = {}
    end

    local recon_candidates, are_recon_candidates_safe = nil
    local recon_data = task_data.recon

    -- new recon condition
    if recon_data.next_dispatch_t and recon_data.next_dispatch_t < t and not task_data.regroup.active and (not task_data.assault.active or (self._goin_valid and self:is_recon_allowed())) then
        recon_candidates = {}
    elseif self._task_data.assault.active and self._task_data.recon.tasks[1] and recon_data.next_dispatch_t and recon_data.next_dispatch_t < t and (not self._goin_valid or not self:is_recon_allowed()) then
        self._task_data.recon.tasks = {}
    end

    local assault_candidates = nil
    local assault_data = task_data.assault

    if self._difficulty_value > 0 and assault_data.next_dispatch_t and assault_data.next_dispatch_t < t and not task_data.regroup.active then
        assault_candidates = {}
    end

    if not reenforce_candidates and not recon_candidates and not assault_candidates then
        return
    end

    local found_areas = {}
    local to_search_areas = {}

    for area_id, area in pairs(all_areas) do
        if area.spawn_points then
            for _, sp_data in pairs(area.spawn_points) do
                if sp_data.delay_t <= t and not all_nav_segs[sp_data.nav_seg].disabled then
                    table.insert(to_search_areas, area)

                    found_areas[area_id] = true

                    break
                end
            end
        end

        if not found_areas[area_id] and area.spawn_groups then
            for _, sp_data in pairs(area.spawn_groups) do
                if sp_data.delay_t <= t and not all_nav_segs[sp_data.nav_seg].disabled then
                    table.insert(to_search_areas, area)

                    found_areas[area_id] = true

                    break
                end
            end
        end
    end

    if #to_search_areas == 0 then
        return
    end

    if assault_candidates and self._hunt_mode then
        for criminal_key, criminal_data in pairs(self._char_criminals) do
            if not criminal_data.status then
                local nav_seg = criminal_data.tracker:nav_segment()
                local area = self:get_area_from_nav_seg_id(nav_seg)
                found_areas[area] = true

                table.insert(assault_candidates, area)
            end
        end
    end

    local i = 1

    repeat
        local area = to_search_areas[i]
        local force_factor = area.factors.force
        local demand = force_factor and force_factor.force
        local nr_police = table.size(area.police.units)
        local nr_criminals = table.size(area.criminal.units)
        local criminal_character_in_area = false

        for criminal_key, _ in pairs(area.criminal.units) do
            if not self._criminals[criminal_key].status and not self._criminals[criminal_key].is_deployable then
                criminal_character_in_area = true

                break
            end
        end

        if reenforce_candidates and demand and demand > 0 and nr_criminals == 0 then
            local area_free = true

            for i_task, reenforce_task_data in ipairs(reenforce_data.tasks) do
                if reenforce_task_data.target_area == area then
                    area_free = false

                    break
                end
            end

            if area_free then
                table.insert(reenforce_candidates, area)
            end
        end

        if recon_candidates and (area.loot or area.hostages) then
            local occupied = nil

            -- check if there is already a queued task for this area
            for task_id, task in pairs(self._task_data.recon.tasks) do
                if task.target_area == area then
                    occupied = true

                    break
                end
            end

            if not occupied then
                local is_area_safe = nr_criminals == 0

                if is_area_safe then
                    if are_recon_candidates_safe then
                        table.insert(recon_candidates, area)
                    else
                        are_recon_candidates_safe = true
                        recon_candidates = {
                            area
                        }
                    end
                elseif not are_recon_candidates_safe then
                    table.insert(recon_candidates, area)
                end
            end
        end

        if assault_candidates and criminal_character_in_area then
            table.insert(assault_candidates, area)
        end

        if not criminal_character_in_area then
            for neighbour_area_id, neighbour_area in pairs(area.neighbours) do
                if not found_areas[neighbour_area_id] then
                    table.insert(to_search_areas, neighbour_area)

                    found_areas[neighbour_area_id] = true
                end
            end
        end

        i = i + 1
    until i > #to_search_areas

    if recon_data.break_extended and assault_data.active then
        recon_data.break_extended = nil
    end

    --prevent cheese tactic, if no recon objectives or tasks and assault break is extended, or recon is set to appear always, then set task on the player
    if recon_candidates and not recon_candidates[1] and not recon_data.tasks[1] and (recon_data.break_extended or self._recon_assault_condition == 4) then
        for criminal_key, criminal_data in pairs(self._char_criminals) do
            if not criminal_data.status then
                local nav_seg = criminal_data.tracker:nav_segment()
                local area = self:get_area_from_nav_seg_id(nav_seg)


                table.insert(recon_candidates, area)
            end
        end
    end


    if assault_candidates and #assault_candidates > 0 then
        self:_begin_assault_task(assault_candidates)
        
        recon_candidates = nil
    end

    if recon_candidates and #recon_candidates > 0 then
        local recon_area = recon_candidates[math.random(#recon_candidates)]

        self:_begin_recon_task(recon_area)
    end

    if reenforce_candidates and #reenforce_candidates > 0 then
        local lucky_i_candidate = math.random(#reenforce_candidates)
        local reenforce_area = reenforce_candidates[lucky_i_candidate]

        self:_begin_reenforce_task(reenforce_area)

        recon_candidates = nil
    end
end