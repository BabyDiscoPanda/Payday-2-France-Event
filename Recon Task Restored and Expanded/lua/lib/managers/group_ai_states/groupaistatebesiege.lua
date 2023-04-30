-- have to manually hook this one since we need to do stuff both before and after.
-- should be ok hopefully? hopefully won't break compatibility
local old_begin_assault = GroupAIStateBesiege._begin_assault_task
function GroupAIStateBesiege:_begin_assault_task(assault_areas)
    -- don't remove extra anticipation time if it's the first assault or skirmish (holdout)
    local extend_anticipation = self._task_data.assault.is_first or managers.skirmish:is_skirmish()
    

    old_begin_assault(self, assault_areas)

    if not self._task_data.assault.extra_time then
        self._task_data.assault.extra_time = 0
    end

    -- remove delay
    if (not extend_anticipation) and (not self._hunt_mode) and self._task_data.assault.is_hesitating then
        self._task_data.assault.is_hesitating = nil
        self._task_data.assault.phase_end_t = self._task_data.assault.phase_end_t - self:_get_difficulty_dependent_value(self._tweak_data.assault.hostage_hesitation_delay) + self._task_data.assault.extra_time
    end
end

Hooks:PostHook(GroupAIStateBesiege, "_end_regroup_task", "star_recon_end_regroup_task", function(self)
    -- extend break only if not skirmish
    local extend_break = not managers.skirmish:is_skirmish()
    local assault_task = self._task_data.assault
    self._task_data.recon.break_extended = nil

    -- if players have hostages then increase assault break
    if extend_break and self._hostage_headcount > 0 then
        assault_task.is_hesitating = true
        if assault_task.next_dispatch_t then
            -- we'll call out the extra assault delay once normal delay ends
            assault_task.voice_delay = assault_task.next_dispatch_t
        end
        local break_time = self:_get_difficulty_dependent_value(self._tweak_data.assault.delay) + self:_get_difficulty_dependent_value(self._tweak_data.assault.hostage_hesitation_delay)
        --if less than 60 we add extra 5 seconds per hostage, but max 60 (if a difficulty would allow it to exceed 60 by default then I do not want to change that).
        if break_time < 60 then
            break_time = break_time + 5 * (self._hostage_headcount - 1)
            if break_time > 60 then break_time = 60 end
        --if more than 60 already, clamp to 60 and add extra time to anticipation
        elseif break_time > 60 then
            assault_task.extra_time = break_time - 60
            break_time = 60
        end
        assault_task.next_dispatch_t = self._t + break_time
        self._task_data.recon.break_extended = true
	end
end)

--menu stuff
Hooks:PostHook(GroupAIStateBesiege, "init", "star_recon_ai_state_besiege_init", function(self, group_ai_state)
    local menu_exists = (StarReconMenu and StarReconMenu._data.assault_condition)
    -- These are for checking whether the appropriate functions should be called, to save on overhead if they aren't needed
    self._goin_valid =  menu_exists  and StarReconMenu._data.assault_condition > 1
    -- I could make settings changeable during a heist but that could damage performance if extra functions are being called so frequently, so I'd rather not
    -- Instead, we're setting it in stone at heist start.
    -- If enough people request it I might make it an option
    self._recon_assault_condition = StarReconMenu._data.assault_condition
end)

function GroupAIStateBesiege:is_recon_allowed() 
    if not self._recon_assault_condition then
        return false
    end

    local condition = self._recon_assault_condition
    
    if condition > 2 or (condition > 1 and self._hostage_headcount > 0) then
        return true
    end
    return false
end

--to do this with a hook it's potentially too performance-damaging so it's redefined
function GroupAIStateBesiege:_begin_new_tasks()
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

function GroupAIStateBesiege:_count_recon_force()
    local amount = 0

    for group_id, group in pairs(self._groups) do
        if group.objective.type == "recon_area" then
            amount = amount + (group.has_spawned and group.size or group.initial_size)
        end
    end

    return amount
end

--Have to redefine this one
function GroupAIStateBesiege:_upd_recon_tasks()
    local task_data = self._task_data.recon.tasks[1]

    self:_assign_enemy_groups_to_recon()

    local t = self._t

    if not task_data then
        --sometimes next dispatch is set to nil and then the tasks are cleared. unsure how but this should fix it
        if not self._task_data.recon.next_dispatch_t then
            self._task_data.recon.next_dispatch_t = t
        end
        return
    end

    local nr_wanted = 0
    local target_pos = task_data.target_area.pos

    if self._goin_valid and self._task_data.assault.active then
        -- removed assault groups retiring

        -- limit recon to both assault and recon spawn limits.
        local nr_wanted_recon = (math.ceil(self:_get_difficulty_dependent_value(self._tweak_data.recon.force)/2)) - self:_count_recon_force()
        local nr_wanted_assault = self._task_data.assault.force - self:_count_police_force("assault") - (self._task_data.assault.phase == "anticipation" and 5 or 0)
        nr_wanted = nr_wanted_assault < nr_wanted_recon and nr_wanted_assault or nr_wanted_recon
        if self._task_data.assault.phase == "fade" then
            nr_wanted = 0
        end
    else
        self:_assign_assault_groups_to_retire()
        nr_wanted = self:_get_difficulty_dependent_value(self._tweak_data.recon.force) - self:_count_police_force("recon")
    end 

    if nr_wanted <= 0 then
        return
    end

    local used_event, used_group = nil

    if task_data.use_spawn_event then
        task_data.use_spawn_event = false

        if self:_try_use_task_spawn_event(t, task_data.target_area, "recon") then
            used_event = true
        end
    end

    if not used_event then
        if next(self._spawning_groups) then
            --Nothing
        else
            local spawn_group, spawn_group_type = self:_find_spawn_group_near_area(task_data.target_area, self._tweak_data.recon.groups, nil, nil, callback(self, self, "_verify_anticipation_spawn_point"))

            if spawn_group then
                local grp_objective = {
                    attitude = "avoid",
                    scan = true,
                    stance = "hos",
                    type = "recon_area",
                    area = spawn_group.area,
                    target_area = task_data.target_area,
                    coarse_path = {
                        {
                            spawn_group.area.pos_nav_seg,
                            spawn_group.area.pos
                        }
                    }
                }

                self:_spawn_in_group(spawn_group, spawn_group_type, grp_objective)

                used_group = true
            end
        end
    end

    if used_event or used_group then
        table.remove(self._task_data.recon.tasks, 1)

        self._task_data.recon.next_dispatch_t = t + math.ceil(self:_get_difficulty_dependent_value(self._tweak_data.recon.interval)) + math.random() * self._tweak_data.recon.interval_variation
    end

    -- call out delay voiceline
    -- modified from _upd_assault_task
    local task_data = self._task_data.assault

    if task_data.is_hesitating and task_data.voice_delay and task_data.voice_delay < self._t then
        if self._hostage_headcount > 0 then
            local best_group = nil

            for _, group in pairs(self._groups) do
                --if possible we want retiring enemies to call for HRT but it's unlikely
                if not best_group or group.objective.type == "retire" then
                    best_group = group
                elseif best_group.objective.type ~= "recon_area" and group.objective.type ~= "retire" then
                    best_group = group
                end
            end

            if best_group and self:_voice_delay_assault(best_group) then
                task_data.is_hesitating = nil
            end
        else
            task_data.is_hesitating = nil
        end
    end
end

-- There's no reason for this to be setting the next dispatch, as upd_reenforce_tasks sets it already
Hooks:PostHook(GroupAIStateBesiege, "_begin_reenforce_task", "star_recon_begin_reenforce_task", function(self, reenforce_area)
    if self._reenforce_valid then
        self._task_data.reenforce.next_dispatch_t = self._t - 1 --Because in order for this to execute the value would have had to be at least this
    end
end)

--have to redo this to prevent stuck map spawns from blocking recon from spawning
function GroupAIStateBesiege:_set_recon_objective_to_group(group)
	local current_objective = group.objective
	local target_area = current_objective.target_area or current_objective.area

    --get tactics
    local group_leader_u_key, group_leader_u_data = self._determine_group_leader(group.units)
    local tactics_map = nil
    if group_leader_u_data and group_leader_u_data.tactics then
		tactics_map = {}

		for _, tactic_name in ipairs(group_leader_u_data.tactics) do
			tactics_map[tactic_name] = true
		end
    end

    local coward = tactics_map and tactics_map.ranged_fire
    local charge = tactics_map and tactics_map.charge

	if not target_area.loot and not target_area.hostages or not current_objective.moving_out and current_objective.moved_in and group.in_place_t and self._t - group.in_place_t > 15 then
		local recon_area = nil
		local to_search_areas = {
			current_objective.area
		}
		local found_areas = {
			[current_objective.area] = "init"
		}

        local backup_areas = {}
        local are_backups_safe = nil

		repeat
			local search_area = table.remove(to_search_areas, 1)

			if search_area.loot or search_area.hostages then
				local occupied = nil

				for test_group_id, test_group in pairs(self._groups) do
					if test_group ~= group and (test_group.objective.target_area == search_area or test_group.objective.area == search_area) then
						occupied = true

						break
					end
				end

				if not occupied and group.visited_areas and group.visited_areas[search_area] then
					occupied = true
				end

                local is_area_safe = not next(search_area.criminal.units)

				if occupied then
                    --if all areas are occupied we assign new tasks to those areas
                    if is_area_safe and not are_backups_safe then
                        backup_areas = {
                            search_area
                        }
                        are_backups_safe = true
                    else
                        table.insert(backup_areas, search_area)
                    end
                else

					if is_area_safe then
						recon_area = search_area

						break
					else
						recon_area = recon_area or search_area
					end
				end
			end

			if not next(search_area.criminal.units) then
				for other_area_id, other_area in pairs(search_area.neighbours) do
					if not found_areas[other_area] then
						table.insert(to_search_areas, other_area)

						found_areas[other_area] = search_area
					end
				end
			end
		until #to_search_areas == 0

        if not recon_area and #backup_areas > 0 then
            recon_area = backup_areas[math.random(#backup_areas)]
        end

        -- if valid action then reassign the recon to attack the player if they are at their objective
        if not recon_area and (self._task_data.recon.break_extended or self._recon_assault_condition == 4 or self._task_data.assault.is_first) and not current_objective.moving_out and current_objective.moved_in then
            local candidates = {}
            for area, _ in pairs(found_areas) do
                if next(area.criminal.units) then
                    table.insert(candidates, area)
                end
            end
            if #candidates > 0 then
                recon_area = candidates[math.random(#candidates)]
            end
        end

		if recon_area then
			local coarse_path = {
				{
					recon_area.pos_nav_seg,
					recon_area.pos
				}
			}
			local last_added_area = recon_area

			while found_areas[last_added_area] ~= "init" do
				last_added_area = found_areas[last_added_area]

				table.insert(coarse_path, 1, {
					last_added_area.pos_nav_seg,
					last_added_area.pos
				})
			end

			local grp_objective = {
				scan = true,
				pose = coward and "crouch" or "stand",
				type = "recon_area",
				stance = "hos",
				attitude = charge and "engage" or "avoid",
                interrupt_dis = coward and 800 or nil,
				area = current_objective.area,
				target_area = recon_area,
				coarse_path = coarse_path
			}

			self:_set_objective_to_enemy_group(group, grp_objective)

			current_objective = group.objective
        elseif current_objective and not current_objective.assigned_t or self._t > current_objective.assigned_t + 10 then
            --STUCK
            if (not current_objective.assigned_t) then
                current_objective.assigned_t = self._t
            else
                current_objective.type = "defend_area" --retires asap while not contributing to recon or assault force
                --log("RTRE: Unit stuck, retiring asap")
            end
		end
	end

	if current_objective.target_area then
		if current_objective.moving_out and not current_objective.moving_in and current_objective.coarse_path then
			local forwardmost_i_nav_point = self:_get_group_forwardmost_coarse_path_index(group)

			if forwardmost_i_nav_point and forwardmost_i_nav_point > 1 then
				for i = forwardmost_i_nav_point + 1, #current_objective.coarse_path do
                    --fixing bug where recon doesn't appropriately try to avoid player.
					local nav_point = current_objective.coarse_path[i]

					if not self:is_nav_seg_safe(nav_point[1]) then
						for _ = 0, #current_objective.coarse_path - i do
							table.remove(current_objective.coarse_path)
						end

						local grp_objective = {
							attitude = charge and "engage" or "avoid",
							scan = true,
							pose = coward and "crouch" or "stand",
							type = "recon_area",
							stance = "hos",
                            interrupt_dis = coward and 800 or nil,
							area = self:get_area_from_nav_seg_id(current_objective.coarse_path[#current_objective.coarse_path][1]),
							target_area = current_objective.target_area
						}

						self:_set_objective_to_enemy_group(group, grp_objective)

						return
					end
				end
			end
		end

        -- after spawning
		if not current_objective.moving_out and not current_objective.area.neighbours[current_objective.target_area.id] then
            -- check for alternate path if flanking and target area contains players.
            local alt_area = nil
            if tactics_map and tactics_map.flank and next(current_objective.target_area.criminal.units) then
                local alt_areas = {}
                for area_id, enter_from_area in pairs(current_objective.target_area.neighbours) do
                    local enter_from_here = true
                    --go around assault units if possible
                    local cop_units = enter_from_area.police.units
                    for u_key, u_data in pairs(cop_units) do
                        if u_data.group and u_data.group ~= group and u_data.group.objective.type == "assault_area" then
                            enter_from_here = false
                            break
                        end
                    end
                    if enter_from_here then
                        --check if other groups are attacking from that point. if so, we want to attack somewhere else
                        for group_id, group in pairs(self._groups) do
                            if group.objective and group.objective.target_area == current_objective.target_area and group.objective.coarse_path then
                                local other_path = group.objective.coarse_path
                                local attack_point = other_path[#other_path][1]
                                if attack_point == current_objective.target_area.pos_nav_seg and #other_path > 1 then
                                    attack_point = other_path[#other_path - 1][1]
                                end
                                if enter_from_area.pos_nav_seg == attack_point then
                                    enter_from_here = false
                                    break
                                end
                            end
                        end
                    end
                    if enter_from_here then
                        table.insert(alt_areas, enter_from_area)
                    end
                end
                if next(alt_areas) then
                    alt_area = alt_areas[math.random(#alt_areas)]
                end
            end
			local search_params = {
				id = "GroupAI_recon",
				from_seg = current_objective.area.pos_nav_seg,
				to_seg = alt_area and alt_area.pos_nav_seg or current_objective.target_area.pos_nav_seg,
				access_pos = self._get_group_acces_mask(group),
				verify_clbk = callback(self, self, "is_nav_seg_safe")
			}
			local coarse_path = managers.navigation:search_coarse(search_params)

			if coarse_path then
				self:_merge_coarse_path_by_area(coarse_path)
                if not alt_area then
				    table.remove(coarse_path)
                end

				local grp_objective = {
					scan = true,
					pose = coward and "crouch" or "stand",
					type = "recon_area",
					stance = "hos",
					attitude = charge and "engage" or "avoid",
                    interrupt_dis = coward and 800 or nil,
					area = self:get_area_from_nav_seg_id(coarse_path[#coarse_path][1]),
					target_area = current_objective.target_area,
					coarse_path = coarse_path
				}

				self:_set_objective_to_enemy_group(group, grp_objective)
			end
		end

		if not current_objective.moving_out and current_objective.area.neighbours[current_objective.target_area.id] then
            local area_hostile = next(current_objective.target_area.criminal.units)
			local grp_objective = {
				stance = area_hostile and "cbt" or "hos",
				scan = true,
				pose = charge and "stand" or "crouch",
				type = "recon_area",
				attitude = coward and "avoid" or "engage",
                interrupt_dis = coward and 800 or nil,
				area = current_objective.target_area
			}

			self:_set_objective_to_enemy_group(group, grp_objective)

			group.objective.moving_in = true
			group.objective.moved_in = true

			if area_hostile then
				self:_chk_group_use_smoke_grenade(group, {
					use_smoke = true,
					target_areas = {
						grp_objective.area
					}
				})
			end
		end
	end
end

Hooks:PostHook(GroupAIStateBesiege, "_assign_group_to_retire", "star_recon_retire_group", function(self, group)
    --Could not find flee point
    if group and group.objective and group.objective.type ~= "retire" then
        group.objective.type = "defend_area"
    end
end)

--fix retirement
function GroupAIStateBesiege:_assign_recon_groups_to_retire()
    --allow recon if valid
    if self._goin_valid and self:is_recon_allowed() then
        return
    end
	local function suitable_grp_func(group)
		if group.objective.type == "recon_area" then
			local grp_objective = {
				stance = "hos",
				attitude = "avoid",
				pose = "crouch",
				type = "assault_area",
				area = group.objective.area
			}

			self:_set_objective_to_enemy_group(group, grp_objective)
		end
	end

	self:_assign_groups_to_retire(self._tweak_data.assault.groups, suitable_grp_func, "assault_area")
end

function GroupAIStateBesiege:_assign_assault_groups_to_retire()
	local function suitable_grp_func(group)
		if group.objective.type == "assault_area" then
			local regroup_area = nil

			if next(group.objective.area.criminal.units) then
				for other_area_id, other_area in pairs(group.objective.area.neighbours) do
					if not next(other_area.criminal.units) then
						regroup_area = other_area

						break
					end
				end
			end

			regroup_area = regroup_area or group.objective.area
			local grp_objective = {
				stance = "hos",
				attitude = "avoid",
				pose = "crouch",
				type = "recon_area",
				area = regroup_area
			}

			self:_set_objective_to_enemy_group(group, grp_objective)
		end
	end

	self:_assign_groups_to_retire(self._tweak_data.recon.groups, suitable_grp_func, "recon_area")
end

function GroupAIStateBesiege:_assign_groups_to_retire(allowed_groups, suitable_grp_func, allowed_task)
	for group_id, group in pairs(self._groups) do
        if group.objective.type ~= "reenforce_area" and group.objective.type ~= "retire" and group.objective.type ~= allowed_task then 
            if not allowed_groups[group.type] then
                self:_assign_group_to_retire(group)
            elseif suitable_grp_func and allowed_groups[group.type] then
                suitable_grp_func(group)
            end
        end
	end
end