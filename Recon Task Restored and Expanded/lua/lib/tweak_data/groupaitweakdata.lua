local tweak_data_ref = nil
local data_path = ModPath .. "menu/settings.json"

function GroupAITweakData:getHeistType()
    local level_id = Global.level_data and Global.level_data.level_id -- referenced from Assault Tweaks Standalone

    if not level_id then
        return nil
    elseif level_id == "firestarter_2" or level_id == "hox_2" or level_id == "hox_3" then
        return "fbi"
    elseif level_id == "welcome_to_the_jungle_2" or level_id == "chew" or level_id == "chca" or level_id == "trai" or (self.rtre_menu_data and self.rtre_menu_data.enemy_set == 2) then
        return "remote"
    elseif level_id == "rvd1" or level_id == "rvd2" then
        return "la"
    elseif level_id == "chas" or level_id == "sand" or level_id == "pent" then
        return "sanfran"
    elseif level_id == "ranc" then
        return "texas"
    else
        return "normal"
    end
end

Hooks:PreHook(GroupAITweakData, "init", "star_recon_init_groupaitweakdata", function(self, tweak_data)
    tweak_data_ref = tweak_data
    self.rtre_menu_data = {}
    -- get menu data
    local file = io.open( data_path, "r" )
    if file then
        self.rtre_menu_data = json.decode( file:read("*all") )
        file:close()
    end
    if not self.rtre_menu_data.enemy_set then self.rtre_menu_data.enemy_set = 1 end
    if not self.rtre_menu_data.murky_set then self.rtre_menu_data.murky_set = 1 end
    if not self.rtre_menu_data.bronco_guy then self.rtre_menu_data.bronco_guy = false end
    if not self.rtre_menu_data.assault_condition then self.rtre_menu_data.assault_condition = 1 end
    if not self.rtre_menu_data.reinforce_allowed then self.rtre_menu_data.reinforce_allowed = false end
end)

--Define recon units and add to original
Hooks:PostHook(GroupAITweakData, "_init_unit_categories", "star_recon_init_unit_categories", function(self, difficulty_index)
    local access_type_walk_only = {
		walk = true
	}
    local access_type_all = {
		acrobatic = true,
		walk = true
	}

    --check for whether required packages are loaded for murky units. if not, swap out
    --if we don't then host will crash. if we force load packages, clients without mod will not see enemies
    --I don't know the memory cost of checking this unfortunately
    local murky_scar = nil
    local murky_ump = nil
    local murky_c45 = nil
    local murky_mp5 = nil

    --from gamesetup.lua
    local lvl_tweak_data = tweak_data_ref and Global.level_data and Global.level_data.level_id and tweak_data_ref.levels[Global.level_data.level_id]
    local level_package = lvl_tweak_data and lvl_tweak_data.package

    if type(level_package) == "table" then
        for _, package in ipairs(level_package) do
            -- i don't feel like making a table so this bad if statement will have to do
            -- i can't just say if not job_bph because custom packages from custom heists would crash
            if not murky_scar and (package == "packages/job_mex" or package == "packages/job_mex2" or package == "packages/job_des") then
                murky_scar = Idstring("units/pd2_dlc_des/characters/ene_murkywater_not_security_2/ene_murkywater_not_security_2")
            end

            if not murky_c45 and (murky_scar or package == "packages/narr_jerry1" or package == "packages/dlcs/vit/job_vit") then
                murky_c45 = Idstring("units/pd2_dlc_vit/characters/ene_murkywater_secret_service/ene_murkywater_secret_service")
            end
    
            if not murky_ump and (murky_c45 or package == "packages/dlcs/bph/job_bph") then
                murky_ump = Idstring("units/pd2_dlc_des/characters/ene_murkywater_no_light_not_security/ene_murkywater_no_light_not_security")
            end
        end
    else
        if level_package and (level_package == "packages/job_mex" or level_package == "packages/job_mex2" or level_package == "packages/job_des") then
            murky_scar = Idstring("units/pd2_dlc_des/characters/ene_murkywater_not_security_2/ene_murkywater_not_security_2")
        end

        if murky_scar or (level_package and (level_package == "packages/narr_jerry1" or level_package == "packages/dlcs/vit/job_vit")) then
            murky_c45 = Idstring("units/pd2_dlc_vit/characters/ene_murkywater_secret_service/ene_murkywater_secret_service")
        end

        if murky_c45 or (level_package and level_package == "packages/dlcs/bph/job_bph") then
            murky_ump = Idstring("units/pd2_dlc_des/characters/ene_murkywater_no_light_not_security/ene_murkywater_no_light_not_security")
        end
    end

    murky_mp5 = Idstring("units/pd2_dlc_bph/characters/ene_murkywater_light/ene_murkywater_light")
    
    if not murky_ump then
        murky_ump = murky_mp5
    end
    if not murky_c45 then
        murky_c45 = murky_mp5
    end

    -- old murky set
    if self.rtre_menu_data and self.rtre_menu_data.murky_set == 3 then
        murky_mp5 = murky_ump
        if murky_scar then 
            murky_ump = murky_scar
        end
    end

    local is_classic = self.rtre_menu_data and self.rtre_menu_data.enemy_set == 3

    --Normal
    if difficulty_index <= 2 then
        self.unit_categories.RECON_light = {
            unit_types = {
                america = {
                    Idstring("units/payday2/characters/ene_cop_1/ene_cop_1"),
                    Idstring("units/payday2/characters/ene_cop_2/ene_cop_2")
                },
                russia = {
                    Idstring("units/pd2_dlc_mad/characters/ene_akan_cs_cop_akmsu_smg/ene_akan_cs_cop_akmsu_smg"),
                    Idstring("units/pd2_dlc_mad/characters/ene_akan_cs_cop_asval_smg/ene_akan_cs_cop_asval_smg")
                },
                zombie = {
                    Idstring("units/pd2_dlc_hvh/characters/ene_cop_hvh_1/ene_cop_hvh_1"),
                    Idstring("units/pd2_dlc_hvh/characters/ene_cop_hvh_2/ene_cop_hvh_2")
                },
                murkywater = {
                    murky_c45
                },
                federales = {
                    Idstring("units/pd2_dlc_bex/characters/ene_policia_01/ene_policia_01"),
                    Idstring("units/pd2_dlc_bex/characters/ene_policia_02/ene_policia_02")
                }
            },
            access = access_type_walk_only
        }

        self.unit_categories.RECON_heavy = {
            unit_types = {
                america = {
                    Idstring("units/payday2/characters/ene_cop_3/ene_cop_3"),
                    Idstring("units/payday2/characters/ene_cop_4/ene_cop_4")
                },
                russia = {
                    Idstring("units/pd2_dlc_mad/characters/ene_akan_cs_cop_ak47_ass/ene_akan_cs_cop_ak47_ass"),
                    Idstring("units/pd2_dlc_mad/characters/ene_akan_cs_cop_r870/ene_akan_cs_cop_r870")
                },
                zombie = {
                    Idstring("units/pd2_dlc_hvh/characters/ene_cop_hvh_3/ene_cop_hvh_3"),
                    Idstring("units/pd2_dlc_hvh/characters/ene_cop_hvh_4/ene_cop_hvh_4")
                },
                murkywater = {
                    murky_c45
                },
                federales = {
                    Idstring("units/pd2_dlc_bex/characters/ene_policia_01/ene_policia_01"),
                    Idstring("units/pd2_dlc_bex/characters/ene_policia_02/ene_policia_02")
                }
            },
            access = access_type_walk_only
        }

    --Hard/Very Hard
    elseif difficulty_index <= 4 and not is_classic then
        self.unit_categories.RECON_light = {
            unit_types = {
                america = {
                    Idstring("units/payday2/characters/ene_cop_2/ene_cop_2"),
                    Idstring("units/payday2/characters/ene_cop_3/ene_cop_3"),
                    Idstring("units/payday2/characters/ene_cop_4/ene_cop_4")
                },
                russia = {
                    Idstring("units/pd2_dlc_mad/characters/ene_akan_cs_cop_akmsu_smg/ene_akan_cs_cop_akmsu_smg"),
                    Idstring("units/pd2_dlc_mad/characters/ene_akan_cs_cop_asval_smg/ene_akan_cs_cop_asval_smg")
                },
                zombie = {
                    Idstring("units/pd2_dlc_hvh/characters/ene_cop_hvh_2/ene_cop_hvh_2"),
                    Idstring("units/pd2_dlc_hvh/characters/ene_cop_hvh_3/ene_cop_hvh_3"),
                    Idstring("units/pd2_dlc_hvh/characters/ene_cop_hvh_4/ene_cop_hvh_4")
                },
                murkywater = {
                    murky_c45
                },
                federales = {
                    Idstring("units/pd2_dlc_bex/characters/ene_policia_01/ene_policia_01"),
                    Idstring("units/pd2_dlc_bex/characters/ene_policia_02/ene_policia_02")
                }
            },
            access = access_type_walk_only
        }

        self.unit_categories.RECON_heavy = {
            unit_types = {
                america = {
                    Idstring("units/payday2/characters/ene_cop_3/ene_cop_3"),
                    Idstring("units/payday2/characters/ene_cop_4/ene_cop_4"),
                    Idstring("units/payday2/characters/ene_fbi_3/ene_fbi_3")
                },
                russia = {
                    Idstring("units/pd2_dlc_mad/characters/ene_akan_cs_cop_ak47_ass/ene_akan_cs_cop_ak47_ass"),
                    Idstring("units/pd2_dlc_mad/characters/ene_akan_cs_cop_r870/ene_akan_cs_cop_r870")
                },
                zombie = {
                    Idstring("units/pd2_dlc_hvh/characters/ene_cop_hvh_3/ene_cop_hvh_3"),
                    Idstring("units/pd2_dlc_hvh/characters/ene_cop_hvh_4/ene_cop_hvh_4"),
                    Idstring("units/pd2_dlc_hvh/characters/ene_fbi_hvh_3/ene_fbi_hvh_3")

                },
                murkywater = {
                    murky_mp5

                },
                federales = {
                    Idstring("units/payday2/characters/ene_fbi_1/ene_fbi_1"),
                    Idstring("units/payday2/characters/ene_fbi_2/ene_fbi_2"),
                    Idstring("units/payday2/characters/ene_fbi_3/ene_fbi_3")

                }
            },
            access = access_type_walk_only
        }

    --Overkill/Mayhem
    elseif difficulty_index <= 6 then
        self.unit_categories.RECON_light = {
            unit_types = {
                america = {
                    Idstring("units/payday2/characters/ene_fbi_1/ene_fbi_1"),
                    Idstring("units/payday2/characters/ene_fbi_3/ene_fbi_3")
                },
                russia = {
                    Idstring("units/pd2_dlc_mad/characters/ene_akan_cs_cop_akmsu_smg/ene_akan_cs_cop_akmsu_smg"),
                    Idstring("units/pd2_dlc_mad/characters/ene_akan_cs_cop_asval_smg/ene_akan_cs_cop_asval_smg")
                },
                zombie = {
                    Idstring("units/pd2_dlc_hvh/characters/ene_fbi_hvh_1/ene_fbi_hvh_1"),
                    Idstring("units/pd2_dlc_hvh/characters/ene_fbi_hvh_3/ene_fbi_hvh_3")
                },
                murkywater = {
                    murky_c45,
                    murky_mp5
                },
                federales = {
                    Idstring("units/payday2/characters/ene_fbi_1/ene_fbi_1"),
                    Idstring("units/payday2/characters/ene_fbi_3/ene_fbi_3")
                }
            },
            access = access_type_all
        }

        self.unit_categories.RECON_heavy = {
            unit_types = {
                america = {
                    Idstring("units/payday2/characters/ene_fbi_3/ene_fbi_3"),
                    Idstring("units/payday2/characters/ene_fbi_2/ene_fbi_2")
                },
                russia = {
                    Idstring("units/pd2_dlc_mad/characters/ene_akan_cs_cop_ak47_ass/ene_akan_cs_cop_ak47_ass"),
                    Idstring("units/pd2_dlc_mad/characters/ene_akan_cs_cop_r870/ene_akan_cs_cop_r870")
                },
                zombie = {
                    Idstring("units/pd2_dlc_hvh/characters/ene_fbi_hvh_3/ene_fbi_hvh_3"),
                    Idstring("units/pd2_dlc_hvh/characters/ene_fbi_hvh_2/ene_fbi_hvh_2")
                },
                murkywater = {
                    murky_mp5,
                    murky_ump
                },
                federales = {
                    Idstring("units/payday2/characters/ene_fbi_3/ene_fbi_3"),
                    Idstring("units/payday2/characters/ene_fbi_2/ene_fbi_2")

                }
            },
            access = access_type_all
        }

    --Death Wish/Death Sentence
    else
        self.unit_categories.RECON_light = {
            unit_types = {
                america = {
                    Idstring("units/payday2/characters/ene_fbi_3/ene_fbi_3")
                },
                russia = {
                    Idstring("units/pd2_dlc_mad/characters/ene_akan_cs_cop_akmsu_smg/ene_akan_cs_cop_akmsu_smg"),
                    Idstring("units/pd2_dlc_mad/characters/ene_akan_cs_cop_asval_smg/ene_akan_cs_cop_asval_smg")
                },
                zombie = {
                    Idstring("units/pd2_dlc_hvh/characters/ene_fbi_hvh_3/ene_fbi_hvh_3")
                },
                murkywater = {
                    murky_mp5
                },
                federales = {
                    Idstring("units/payday2/characters/ene_fbi_3/ene_fbi_3")
                }
            },
            access = access_type_all
        }

        self.unit_categories.RECON_heavy = {
            unit_types = {
                america = {
                    Idstring("units/payday2/characters/ene_fbi_2/ene_fbi_2")
                },
                russia = {
                    Idstring("units/pd2_dlc_mad/characters/ene_akan_cs_cop_ak47_ass/ene_akan_cs_cop_ak47_ass"),
                    Idstring("units/pd2_dlc_mad/characters/ene_akan_cs_cop_r870/ene_akan_cs_cop_r870")
                },
                zombie = {
                    Idstring("units/pd2_dlc_hvh/characters/ene_fbi_hvh_2/ene_fbi_hvh_2")
                },
                murkywater = {
                    murky_ump
                },
                federales = {
                    Idstring("units/payday2/characters/ene_fbi_2/ene_fbi_2")
                }
            },
            access = access_type_all
        }
    end

    --for Classic style; police are mostly the same as normal difficulty except for russia faction and access type
    self.unit_categories.RECON_police_light = {
        unit_types = {
            america = {
                Idstring("units/payday2/characters/ene_cop_1/ene_cop_1"),
                Idstring("units/payday2/characters/ene_cop_2/ene_cop_2")
            },
            russia = {
                Idstring("units/pd2_dlc_mad/characters/ene_akan_cs_cop_ak47_ass/ene_akan_cs_cop_ak47_ass"),
                Idstring("units/pd2_dlc_mad/characters/ene_akan_cs_cop_r870/ene_akan_cs_cop_r870")
            },
            zombie = {
                Idstring("units/pd2_dlc_hvh/characters/ene_cop_hvh_1/ene_cop_hvh_1"),
                Idstring("units/pd2_dlc_hvh/characters/ene_cop_hvh_2/ene_cop_hvh_2")
            },
            murkywater = {
                murky_c45
            },
            federales = {
                Idstring("units/pd2_dlc_bex/characters/ene_policia_01/ene_policia_01"),
                Idstring("units/pd2_dlc_bex/characters/ene_policia_02/ene_policia_02")
            }
        },
        access = access_type_walk_only
    }

    self.unit_categories.RECON_police_heavy = {
        unit_types = {
            america = {
                Idstring("units/payday2/characters/ene_cop_3/ene_cop_3"),
                Idstring("units/payday2/characters/ene_cop_4/ene_cop_4")
            },
            russia = {
                Idstring("units/pd2_dlc_mad/characters/ene_akan_cs_cop_akmsu_smg/ene_akan_cs_cop_akmsu_smg"),
                Idstring("units/pd2_dlc_mad/characters/ene_akan_cs_cop_asval_smg/ene_akan_cs_cop_asval_smg")
            },
            zombie = {
                Idstring("units/pd2_dlc_hvh/characters/ene_cop_hvh_3/ene_cop_hvh_3"),
                Idstring("units/pd2_dlc_hvh/characters/ene_cop_hvh_4/ene_cop_hvh_4")
            },
            murkywater = {
                murky_c45
            },
            federales = {
                Idstring("units/pd2_dlc_bex/characters/ene_policia_01/ene_policia_01"),
                Idstring("units/pd2_dlc_bex/characters/ene_policia_02/ene_policia_02")
            }
        },
        access = access_type_walk_only
    }

    -- similar to CS_swat but different for mayhem/death wish. also different on DS because the russia blue swat equivalents would be overpowered compared to the rest of the russia units
    if difficulty_index == 6 or difficulty_index == 7 then
        self.unit_categories.RECON_swat_smg = {
            unit_types = {
                america = {
                    Idstring("units/payday2/characters/ene_city_swat_3/ene_city_swat_3")
                },
                russia = {
                    Idstring("units/pd2_dlc_mad/characters/ene_akan_fbi_swat_dw_ak47_ass/ene_akan_fbi_swat_dw_ak47_ass")
                },
                zombie = {
                    Idstring("units/pd2_dlc_hvh/characters/ene_swat_hvh_1/ene_swat_hvh_1")
                },
                murkywater = {
                    Idstring("units/pd2_dlc_bph/characters/ene_murkywater_light/ene_murkywater_light")
                },
                federales = {
                    Idstring("units/pd2_dlc_bex/characters/ene_swat_policia_federale/ene_swat_policia_federale")
                }
            },
            access = access_type_all
        }

        self.unit_categories.RECON_swat_shotty = {
            unit_types = {
                america = {
                    Idstring("units/payday2/characters/ene_city_swat_2/ene_city_swat_2")
                },
                russia = {
                    Idstring("units/pd2_dlc_mad/characters/ene_akan_fbi_swat_dw_r870/ene_akan_fbi_swat_dw_r870")
                },
                zombie = {
                    Idstring("units/pd2_dlc_hvh/characters/ene_swat_hvh_2/ene_swat_hvh_2")
                },
                murkywater = {
                    Idstring("units/pd2_dlc_bph/characters/ene_murkywater_light_r870/ene_murkywater_light_r870")
                },
                federales = {
                    Idstring("units/pd2_dlc_bex/characters/ene_swat_policia_federale_r870/ene_swat_policia_federale_r870")
                }
            },
            access = access_type_all
        }
    elseif difficulty_index == 8 then
        self.unit_categories.RECON_swat_smg = {
            unit_types = {
                america = {
                    Idstring("units/pd2_dlc_gitgud/characters/ene_zeal_swat/ene_zeal_swat")
                },
                russia = {
                    Idstring("units/pd2_dlc_mad/characters/ene_akan_fbi_swat_dw_ak47_ass/ene_akan_fbi_swat_dw_ak47_ass")
                },
                zombie = {
                    Idstring("units/pd2_dlc_hvh/characters/ene_swat_hvh_1/ene_swat_hvh_1")
                },
                murkywater = {
                    Idstring("units/pd2_dlc_bph/characters/ene_murkywater_light/ene_murkywater_light")
                },
                federales = {
                    Idstring("units/pd2_dlc_bex/characters/ene_swat_policia_federale/ene_swat_policia_federale")
                }
            },
            access = access_type_all
        }

        self.unit_categories.RECON_swat_shotty = {
            unit_types = {
                america = {
                    Idstring("units/pd2_dlc_gitgud/characters/ene_zeal_swat/ene_zeal_swat")
                },
                russia = {
                    Idstring("units/pd2_dlc_mad/characters/ene_akan_fbi_swat_dw_r870/ene_akan_fbi_swat_dw_r870")
                },
                zombie = {
                    Idstring("units/pd2_dlc_hvh/characters/ene_swat_hvh_2/ene_swat_hvh_2")
                },
                murkywater = {
                    Idstring("units/pd2_dlc_bph/characters/ene_murkywater_light/ene_murkywater_light")
                },
                federales = {
                    Idstring("units/pd2_dlc_bex/characters/ene_swat_policia_federale/ene_swat_policia_federale")
                }
            },
            access = access_type_all
        }
    else
        self.unit_categories.RECON_swat_smg = self.unit_categories.CS_swat_MP5
        self.unit_categories.RECON_swat_shotty = self.unit_categories.CS_swat_R870
        
    end

    self.unit_categories.RECON_bronco_guy = {
        unit_types = {
            america = {
                Idstring("units/payday2/characters/ene_cop_2/ene_cop_2")
            },
            russia = {
                Idstring("units/pd2_dlc_mad/characters/ene_akan_cs_cop_akmsu_smg/ene_akan_cs_cop_akmsu_smg"),
                Idstring("units/pd2_dlc_mad/characters/ene_akan_cs_cop_asval_smg/ene_akan_cs_cop_asval_smg")
            },
            zombie = {
                Idstring("units/pd2_dlc_hvh/characters/ene_cop_hvh_2/ene_cop_hvh_2")
            },
            murkywater = {
                murky_c45
            },
            federales = {
                Idstring("units/pd2_dlc_bex/characters/ene_policia_01/ene_policia_01"),
                Idstring("units/pd2_dlc_bex/characters/ene_policia_02/ene_policia_02")
            }
        },
        access = access_type_walk_only
    }

    -- per level modifications
    local heist_type = self:getHeistType()
    if heist_type and heist_type == "fbi" then
        self.unit_categories.RECON_light.access = access_type_all
        self.unit_categories.RECON_heavy.access = access_type_all
        --stronger fbi units
        if difficulty_index <= 2 then
            self.unit_categories.RECON_light.unit_types.america = {
                Idstring("units/payday2/characters/ene_fbi_1/ene_fbi_1"),
                Idstring("units/payday2/characters/ene_fbi_2/ene_fbi_2")
            }

            self.unit_categories.RECON_heavy.unit_types.america = {
                Idstring("units/payday2/characters/ene_fbi_2/ene_fbi_2"),
                Idstring("units/payday2/characters/ene_fbi_3/ene_fbi_3")
            }
            
        elseif difficulty_index <= 4 then
            self.unit_categories.RECON_light.unit_types.america = {
                Idstring("units/payday2/characters/ene_fbi_1/ene_fbi_1"),
                Idstring("units/payday2/characters/ene_fbi_3/ene_fbi_3")
            }

            self.unit_categories.RECON_heavy.unit_types.america = {
                Idstring("units/payday2/characters/ene_fbi_2/ene_fbi_2"),
                Idstring("units/payday2/characters/ene_fbi_3/ene_fbi_3")
            }

        elseif difficulty_index <= 6 then
            self.unit_categories.RECON_light.unit_types.america = {
                Idstring("units/payday2/characters/ene_fbi_2/ene_fbi_2"),
                Idstring("units/payday2/characters/ene_fbi_3/ene_fbi_3")
            }

            self.unit_categories.RECON_heavy.unit_types.america = {
                Idstring("units/payday2/characters/ene_fbi_3/ene_fbi_3")
            }

        else
            self.unit_categories.RECON_light.unit_types.america = {
                Idstring("units/payday2/characters/ene_fbi_2/ene_fbi_2"),
                Idstring("units/payday2/characters/ene_fbi_3/ene_fbi_3")
            }

            self.unit_categories.RECON_heavy.unit_types.america = {
                Idstring("units/payday2/characters/ene_fbi_2/ene_fbi_2")
            }
        end

        self.unit_categories.RECON_bronco_guy.unit_types.america = {
            Idstring("units/payday2/characters/ene_fbi_1/ene_fbi_1")
        }

    elseif heist_type and heist_type == "remote" then
        --replace cops with fbi units in remote heists. doesn't affect overkill+
        self.unit_categories.RECON_light.access = access_type_all
        self.unit_categories.RECON_heavy.access = access_type_all
        if difficulty_index <= 2 then
            self.unit_categories.RECON_light.unit_types.america = {
                Idstring("units/payday2/characters/ene_fbi_1/ene_fbi_1")
            }
            self.unit_categories.RECON_light.unit_types.zombie = {
                Idstring("units/pd2_dlc_hvh/characters/ene_fbi_hvh_1/ene_fbi_hvh_1")
            }
            self.unit_categories.RECON_light.unit_types.federales = {
                Idstring("units/payday2/characters/ene_fbi_1/ene_fbi_1")
            }

            self.unit_categories.RECON_heavy.unit_types.america = {
                Idstring("units/payday2/characters/ene_fbi_2/ene_fbi_2")
            }
            self.unit_categories.RECON_heavy.unit_types.zombie = {
                Idstring("units/pd2_dlc_hvh/characters/ene_fbi_hvh_2/ene_fbi_hvh_2")
            }
            self.unit_categories.RECON_heavy.unit_types.federales = {
                Idstring("units/payday2/characters/ene_fbi_2/ene_fbi_2")
            }
            
        elseif difficulty_index <= 4 and not is_classic then
            self.unit_categories.RECON_light.unit_types.america = {
                Idstring("units/payday2/characters/ene_fbi_1/ene_fbi_1"),
                Idstring("units/payday2/characters/ene_fbi_2/ene_fbi_2")
            }
            self.unit_categories.RECON_light.unit_types.zombie = {
                Idstring("units/pd2_dlc_hvh/characters/ene_fbi_hvh_1/ene_fbi_hvh_1"),
                Idstring("units/pd2_dlc_hvh/characters/ene_fbi_hvh_2/ene_fbi_hvh_2")
            }
            self.unit_categories.RECON_light.unit_types.federales = {
                Idstring("units/payday2/characters/ene_fbi_1/ene_fbi_1"),
                Idstring("units/payday2/characters/ene_fbi_2/ene_fbi_2")
            }

            self.unit_categories.RECON_heavy.unit_types.america = {
                Idstring("units/payday2/characters/ene_fbi_2/ene_fbi_2"),
                Idstring("units/payday2/characters/ene_fbi_3/ene_fbi_3")
            }
            self.unit_categories.RECON_heavy.unit_types.zombie = {
                Idstring("units/pd2_dlc_hvh/characters/ene_fbi_hvh_2/ene_fbi_hvh_2"),
                Idstring("units/pd2_dlc_hvh/characters/ene_fbi_hvh_3/ene_fbi_hvh_3")
            }
            self.unit_categories.RECON_heavy.unit_types.federales = {
                Idstring("units/payday2/characters/ene_fbi_2/ene_fbi_2"),
                Idstring("units/payday2/characters/ene_fbi_3/ene_fbi_3")
            }
        end
        
        self.unit_categories.RECON_bronco_guy.unit_types.america = {
            Idstring("units/payday2/characters/ene_fbi_1/ene_fbi_1")
        }

        self.unit_categories.RECON_bronco_guy.unit_types.zombie = self.unit_categories.RECON_bronco_guy.unit_types.america
        self.unit_categories.RECON_bronco_guy.unit_types.federales = self.unit_categories.RECON_bronco_guy.unit_types.america

    elseif heist_type and heist_type == "la" then
        --la cops for reservoir dogs, like the scripted spawn
        if difficulty_index <= 2 or (difficulty_index == 3 and is_classic) then
            self.unit_categories.RECON_light.unit_types.america = {
                Idstring("units/pd2_dlc_rvd/characters/ene_la_cop_1/ene_la_cop_1"),
                Idstring("units/pd2_dlc_rvd/characters/ene_la_cop_2/ene_la_cop_2")
            }

            self.unit_categories.RECON_heavy.unit_types.america = {
                Idstring("units/pd2_dlc_rvd/characters/ene_la_cop_3/ene_la_cop_3"),
                Idstring("units/pd2_dlc_rvd/characters/ene_la_cop_4/ene_la_cop_4")
            }

        elseif difficulty_index <= 4 and not is_classic then
            self.unit_categories.RECON_light.unit_types.america = {
                Idstring("units/pd2_dlc_rvd/characters/ene_la_cop_2/ene_la_cop_2"),
                Idstring("units/pd2_dlc_rvd/characters/ene_la_cop_3/ene_la_cop_3"),
                Idstring("units/pd2_dlc_rvd/characters/ene_la_cop_4/ene_la_cop_4")
            }

            self.unit_categories.RECON_heavy.unit_types.america = {
                Idstring("units/pd2_dlc_rvd/characters/ene_la_cop_3/ene_la_cop_3"),
                Idstring("units/pd2_dlc_rvd/characters/ene_la_cop_4/ene_la_cop_4"),
                Idstring("units/payday2/characters/ene_fbi_3/ene_fbi_3")
            }
        end

        self.unit_categories.RECON_police_light.unit_types.america = {
            Idstring("units/pd2_dlc_rvd/characters/ene_la_cop_1/ene_la_cop_1"),
            Idstring("units/pd2_dlc_rvd/characters/ene_la_cop_2/ene_la_cop_2")
        }

        self.unit_categories.RECON_police_heavy.unit_types.america = {
            Idstring("units/pd2_dlc_rvd/characters/ene_la_cop_3/ene_la_cop_3"),
            Idstring("units/pd2_dlc_rvd/characters/ene_la_cop_4/ene_la_cop_4")
        }

        self.unit_categories.RECON_bronco_guy.unit_types.america = {
            Idstring("units/pd2_dlc_rvd/characters/ene_la_cop_2/ene_la_cop_2")
        }

    elseif heist_type and heist_type == "sanfran" then
        --san francisco cops for the city of light heists
        if difficulty_index <= 2 or (difficulty_index == 3 and is_classic) then
            self.unit_categories.RECON_light.unit_types.america = {
                Idstring("units/pd2_dlc_chas/characters/ene_male_chas_police_01/ene_male_chas_police_01"),
                Idstring("units/pd2_dlc_chas/characters/ene_male_chas_police_02/ene_male_chas_police_02")
            }

            self.unit_categories.RECON_heavy.unit_types.america = {
                Idstring("units/pd2_dlc_chas/characters/ene_male_chas_police_01/ene_male_chas_police_01"),
                Idstring("units/pd2_dlc_chas/characters/ene_male_chas_police_02/ene_male_chas_police_02")
            }

        elseif difficulty_index <= 4 and not is_classic then
            self.unit_categories.RECON_light.unit_types.america = {
                Idstring("units/pd2_dlc_chas/characters/ene_male_chas_police_01/ene_male_chas_police_01"),
                Idstring("units/pd2_dlc_chas/characters/ene_male_chas_police_02/ene_male_chas_police_02")
            }

            self.unit_categories.RECON_heavy.unit_types.america = {
                Idstring("units/payday2/characters/ene_fbi_1/ene_fbi_1"),
                Idstring("units/payday2/characters/ene_fbi_2/ene_fbi_2"),
                Idstring("units/payday2/characters/ene_fbi_3/ene_fbi_3")
            }
        end
        self.unit_categories.RECON_police_light.unit_types.america = {
            Idstring("units/pd2_dlc_chas/characters/ene_male_chas_police_01/ene_male_chas_police_01"),
            Idstring("units/pd2_dlc_chas/characters/ene_male_chas_police_02/ene_male_chas_police_02")
        }

        self.unit_categories.RECON_police_heavy.unit_types.america = {
            Idstring("units/pd2_dlc_chas/characters/ene_male_chas_police_01/ene_male_chas_police_01"),
            Idstring("units/pd2_dlc_chas/characters/ene_male_chas_police_02/ene_male_chas_police_02")
        }

        self.unit_categories.RECON_bronco_guy.unit_types.america = {
            Idstring("units/pd2_dlc_chas/characters/ene_male_chas_police_01/ene_male_chas_police_01"),
            Idstring("units/pd2_dlc_chas/characters/ene_male_chas_police_02/ene_male_chas_police_02")
        }
    elseif heist_type and heist_type == "texas" then
        --texas rangers for the texas heists
        if difficulty_index <= 2 or (difficulty_index == 3 and is_classic) then
            self.unit_categories.RECON_light.unit_types.america = {
                Idstring("units/pd2_dlc_ranc/characters/ene_male_ranc_ranger_01/ene_male_ranc_ranger_01"),
                Idstring("units/pd2_dlc_ranc/characters/ene_male_ranc_ranger_02/ene_male_ranc_ranger_02")
            }

            self.unit_categories.RECON_heavy.unit_types.america = {
                Idstring("units/pd2_dlc_ranc/characters/ene_male_ranc_ranger_01/ene_male_ranc_ranger_01"),
                Idstring("units/pd2_dlc_ranc/characters/ene_male_ranc_ranger_02/ene_male_ranc_ranger_02")
            }

        elseif difficulty_index <= 4 and not is_classic then
            self.unit_categories.RECON_light.unit_types.america = {
                Idstring("units/pd2_dlc_ranc/characters/ene_male_ranc_ranger_01/ene_male_ranc_ranger_01"),
                Idstring("units/pd2_dlc_ranc/characters/ene_male_ranc_ranger_02/ene_male_ranc_ranger_02")
            }

            self.unit_categories.RECON_heavy.unit_types.america = {
                Idstring("units/payday2/characters/ene_fbi_1/ene_fbi_1"),
                Idstring("units/payday2/characters/ene_fbi_2/ene_fbi_2"),
                Idstring("units/payday2/characters/ene_fbi_3/ene_fbi_3")
            }
        end
        self.unit_categories.RECON_police_light.unit_types.america = {
            Idstring("units/pd2_dlc_ranc/characters/ene_male_ranc_ranger_01/ene_male_ranc_ranger_01"),
            Idstring("units/pd2_dlc_ranc/characters/ene_male_ranc_ranger_02/ene_male_ranc_ranger_02")
        }

        self.unit_categories.RECON_police_heavy.unit_types.america = {
            Idstring("units/pd2_dlc_ranc/characters/ene_male_ranc_ranger_01/ene_male_ranc_ranger_01"),
            Idstring("units/pd2_dlc_ranc/characters/ene_male_ranc_ranger_02/ene_male_ranc_ranger_02")
        }

        self.unit_categories.RECON_bronco_guy.unit_types.america = {
            Idstring("units/pd2_dlc_ranc/characters/ene_male_ranc_ranger_01/ene_male_ranc_ranger_01"),
            Idstring("units/pd2_dlc_ranc/characters/ene_male_ranc_ranger_02/ene_male_ranc_ranger_02")
        }
    end

    --murky set flashlights
    if murky_scar and self.rtre_menu_data and self.rtre_menu_data.murky_set == 2 then
        local categories_to_check = {
            "RECON_light",
            "RECON_heavy"
        }
        local heavy = Idstring("units/pd2_dlc_des/characters/ene_murkywater_no_light_not_security/ene_murkywater_no_light_not_security")
        local ump = Idstring("units/pd2_dlc_des/characters/ene_murkywater_not_security_1/ene_murkywater_not_security_1")

        for _, cat in pairs(categories_to_check) do
            local units = self.unit_categories[cat].unit_types.murkywater
            local heavies = 0
            local others = {}
            for k, unit in pairs(units) do
                if unit == heavy then
                    heavies = heavies + 1
                    units[k] = ump
                else
                    table.insert(others, unit)
                end
            end
            --double original units to maintain roughly the same presence compared to heavies
            for _, unit in pairs(others) do
                table.insert(units, unit)
            end
            while heavies > 0 do
                table.insert(units, murky_scar)
                heavies = heavies - 1
            end
        end
    end
end)

Hooks:PostHook(GroupAITweakData, "_init_enemy_spawn_groups", "star_recon_init_enemy_spawn_groups", function(self, difficulty_index)
    self._tactics.recon_case = {
        "ranged_fire",
        "provide_coverfire",
        "provide_support",
        "flank"
    }
    self._tactics.recon_rescue = {
        "provide_coverfire",
        "provide_support",
        "flank"
    }
    self._tactics.recon_rescue_leader = {
        "charge",
        "provide_coverfire",
        "provide_support",
        "flank"
    }
    self._tactics.recon_rush = {
        "charge",
        "provide_coverfire",
        "provide_support",
        "deathguard",
        "murder"
    }

    self.enemy_spawn_groups.tac_recon_case = {
        amount = {
            3,
            5
        },
        spawn = {
            {
                amount_min = 2,
                freq = 2,
                amount_max = 4,
                rank = 2,
                unit = "RECON_light",
                tactics = self._tactics.recon_case
            },
            {
                amount_min = 1,
                freq = 1.25,
                amount_max = 2,
                rank = 3,
                unit = "RECON_heavy",
                tactics = self._tactics.recon_case
            }
        }
    }
    self.enemy_spawn_groups.tac_recon_rescue = {
        amount = {
            4,
            4
        },
        spawn = {
            {
                amount_min = 1,
                freq = 1,
                amount_max = 1,
                rank = 3,
                unit = "RECON_heavy",
                tactics = self._tactics.recon_rescue_leader
            },
            {
                amount_min = 3,
                freq = 1,
                amount_max = 3,
                rank = 1,
                unit = "RECON_light",
                tactics = self._tactics.recon_rescue
            }
        }
    }

    self.enemy_spawn_groups.tac_recon_rush = {
        amount = {
            2,
            3
        },
        spawn = {
            {
                amount_min = 1,
                freq = 1.5,
                amount_max = 2,
                rank = 2,
                unit = "RECON_light",
                tactics = self._tactics.recon_rush
            },
            {
                amount_min = 1,
                freq = 2,
                amount_max = 2,
                rank = 3,
                unit = "RECON_heavy",
                tactics = self._tactics.recon_rush
            }
        }
    }

    self.enemy_spawn_groups.tac_recon_police = {
        amount = {
            3,
            4
        },
        spawn = {
            {
                amount_min = 2,
                freq = 2,
                amount_max = 3,
                rank = 2,
                unit = "RECON_police_light",
                tactics = self._tactics.recon_case
            },
            {
                amount_min = 1,
                freq = 1.25,
                amount_max = 1,
                rank = 3,
                unit = "RECON_police_heavy",
                tactics = self._tactics.recon_case
            }
        }
    }

    self.enemy_spawn_groups.tac_recon_swats = {
        amount = {
            3,
            3
        },
        spawn = {
            {
                amount_min = 2,
                freq = 1,
                amount_max = 3,
                rank = 1,
                unit = "RECON_swat_smg",
                tactics = self._tactics.recon_rescue
            },
            {
                amount_min = 0,
                freq = 1,
                amount_max = 1,
                rank = 2,
                unit = "RECON_swat_smg",
                tactics = self._tactics.recon_rescue_leader
            },
            {
                amount_min = 0,
                freq = 0.5,
                amount_max = 1,
                rank = 2,
                unit = "RECON_swat_smg",
                tactics = self._tactics.recon_rush
            },
            {
                amount_min = 0,
                freq = 0.5,
                amount_max = 1,
                rank = 2,
                unit = "RECON_swat_shotty",
                tactics = self._tactics.recon_rush
            }
        }
    }
    self.enemy_spawn_groups.tac_reenforce_2lights = {
        amount = {
            2,
            2
        },
        spawn = {
            {
                amount_min = 2,
                freq = 1,
                amount_max = 2,
                rank = 1,
                unit = "RECON_light",
                tactics = self._tactics.recon_case
            }
        }
    }
    self.enemy_spawn_groups.tac_reenforce_1heavy = {
        amount = {
            1,
            1
        },
        spawn = {
            {
                amount_min = 1,
                freq = 1,
                amount_max = 1,
                rank = 2,
                unit = "RECON_heavy",
                tactics = self._tactics.recon_case
            }
        }
    }
    self.enemy_spawn_groups.tac_reenforce_2heavies = {
        amount = {
            2,
            2
        },
        spawn = {
            {
                amount_min = 2,
                freq = 1,
                amount_max = 2,
                rank = 2,
                unit = "RECON_heavy",
                tactics = self._tactics.recon_rescue
            }
        }
    }
    self.enemy_spawn_groups.tac_reenforce_team = {
        amount = {
            3,
            3
        },
        spawn = {
            {
                amount_min = 2,
                freq = 1,
                amount_max = 2,
                rank = 1,
                unit = "RECON_light",
                tactics = self._tactics.recon_rescue
            },
            {
                amount_min = 1,
                freq = 1,
                amount_max = 1,
                rank = 2,
                unit = "RECON_heavy",
                tactics = self._tactics.recon_rescue
            }
        }
    }
    self.enemy_spawn_groups.tac_reenforce_police = {
        amount = {
            2,
            2
        },
        spawn = {
            {
                amount_min = 1,
                freq = 1.5,
                amount_max = 2,
                rank = 1,
                unit = "RECON_police_light",
                tactics = self._tactics.recon_case
            },
            {
                amount_min = 1,
                freq = 1,
                amount_max = 2,
                rank = 1,
                unit = "RECON_police_heavy",
                tactics = self._tactics.recon_case
            }
        }
    }
    self.enemy_spawn_groups.tac_reenforce_swats = {
        amount = {
            2,
            3
        },
        spawn = {
            {
                amount_min = 1,
                freq = 1.5,
                amount_max = 3,
                rank = 1,
                unit = "RECON_swat_smg",
                tactics = self._tactics.recon_rescue
            },
            {
                amount_min = 0,
                freq = 0.5,
                amount_max = 1,
                rank = 1,
                unit = "RECON_swat_shotty",
                tactics = self._tactics.recon_rescue
            }
        }
    }
    self.enemy_spawn_groups.tac_bronco_guy = {
        amount = {
            1,
            1
        },
        spawn = {
            {
                amount_min = 1,
                freq = 1,
                amount_max = 1,
                rank = 1,
                unit = "RECON_bronco_guy",
                tactics = self._tactics.recon_case
            }
        }
    }

    -- for shotgunner group
    local replacements = {
        ["CS_swat_MP5"] = "CS_swat_R870",
        ["CS_heavy_M4"] = "CS_heavy_R870",
        ["FBI_swat_M4"] = "FBI_swat_R870",
        ["FBI_heavy_G36"] = "FBI_heavy_R870"
    }

    local heavies = {
        "CS_heavy_M4",
        "CS_heavy_R870",
        "CS_heavy_M4_w",
        "FBI_heavy_G36",
        "FBI_heavy_R870",
        "FBI_heavy_G36_w"
    }

    -- assault groups, don't want to include medics in reenforce, otherwise deep copy.
    if self.enemy_spawn_groups.tac_swat_rifle_flank then
        local ref = self.enemy_spawn_groups.tac_swat_rifle_flank
        self.enemy_spawn_groups.tac_reenforce_swat_rifle = {amount = {}, spawn = {}}
        local rifle = self.enemy_spawn_groups.tac_reenforce_swat_rifle
        self.enemy_spawn_groups.tac_reenforce_swat_shotgun = {amount = {}, spawn = {}}
        local shotgun = self.enemy_spawn_groups.tac_reenforce_swat_shotgun
        local amount = {}
        for k, data in pairs(ref.amount) do
            amount[k] = data
            amount[k] = data
        end
        --units
        local heavy_min_reduced = false
        local heavy_max_reduced = false
        for _, u_data in pairs(ref.spawn) do
            if u_data.unit == "medic_M4" or u_data.unit == "medic_R870" then
                -- remove medic
                if u_data.amount_min and amount[1] then amount[1] = amount[1] - u_data.amount_min end
                if u_data.amount_max and amount[2] then amount[2] = amount[2] - u_data.amount_max end
            else
                local r_tab = {}
                local sh_tab = {}
                -- copy data
                for k, v in pairs(u_data) do
                    -- reduce heavy count by 1.
                    if k == "amount_min" and not heavy_min_reduced and v > 0 and u_data.unit and table.contains(heavies, u_data.unit) then
                        heavy_min_reduced = true
                        r_tab[k] = v - 1
                        sh_tab[k] = v - 1
                        amount[1] = amount[1] - 1
                    elseif k == "amount_max" and not heavy_max_reduced and v > 0 and u_data.unit and table.contains(heavies, u_data.unit) then
                        heavy_max_reduced = true
                        r_tab[k] = v - 1
                        sh_tab[k] = v - 1
                        amount[2] = amount[2] - 1
                    else
                        r_tab[k] = v
                        if k == "unit" and replacements[v] then
                            sh_tab[k] = replacements[v]
                        elseif k == "tactics" then
                            sh_tab[k] = self._tactics.recon_rescue
                        else
                            sh_tab[k] = v
                        end
                    end
                end
                if r_tab.amount_max > 0 then
                    table.insert(rifle.spawn, r_tab)
                    table.insert(shotgun.spawn, sh_tab)
                end
            end
        end
        -- if heavies not reduced at least reduce entire thing by one
        if not heavy_min_reduced then
            amount[1] = amount[1] - 1
        end
        if not heavy_max_reduced then
            amount[2] = amount[2] - 1
        end
        rifle.amount = amount
        shotgun.amount = amount
    end
end)

Hooks:PostHook(GroupAITweakData, "_init_task_data", "star_recon_init_task_data", function(self, difficulty_index, difficulty)
    -- let them respawn faster so maybe you'll actually get to engage them
    self.besiege.recon.interval = {
        5,
        3,
        1
    }
    self.besiege.recon.interval_variation = 0

    self.besiege.recon.force = {
        3,
        6,
        10
    }

    local heist_type = self:getHeistType()
    if heist_type == "fbi" then
        -- more units if attacking fbi building
        self.besiege.recon.force = {
            4,
            8,
            12
        }
    end

    self.besiege.recon.groups = {
        tac_recon_case = {
            1,
            0.6,
            0.3
        },
        tac_recon_rescue = {
            0,
            0.3,
            0.4
        },
        tac_recon_rush = {
            0,
            0.1,
            0.3
        },
        single_spooc = {
            0,
            0,
            0
        },
        Phalanx = {
            0,
            0,
            0
        }
    }
    
    self.star_recon_groups_to_inject = {
        "tac_recon_case",
        "tac_recon_rescue",
        "tac_recon_rush"
    }
    
    if self.rtre_menu_data then
        local reenforce_valid = (self.rtre_menu_data.reinforce_allowed)
        --reenforce
        if reenforce_valid then
            self.besiege.reenforce.groups = {
                tac_reenforce_2lights = {
                    0.6,
                    0.3,
                    0
                },
                tac_reenforce_1heavy = {
                    0.4,
                    0.2,
                    0
                },
                tac_reenforce_2heavies = {
                    0,
                    0.2,
                    0.4
                },
                tac_reenforce_team = {
                    0,
                    0.3,
                    0.6
                }
            }

            table.insert(self.star_recon_groups_to_inject, "tac_reenforce_2lights")
            table.insert(self.star_recon_groups_to_inject, "tac_reenforce_1heavy")
            table.insert(self.star_recon_groups_to_inject, "tac_reenforce_2heavies")
            table.insert(self.star_recon_groups_to_inject, "tac_reenforce_team")
        end
        --classic enemy set
        if self.rtre_menu_data.enemy_set == 3 then
            if difficulty_index <= 3 and heist_type ~= "fbi" then
                --reset groups
                self.besiege.recon.groups = {
                    single_spooc = {
                        0,
                        0,
                        0
                    },
                    Phalanx = {
                        0,
                        0,
                        0
                    }
                }
                if reenforce_valid then 
                    self.besiege.reenforce.groups = {}
                end
                -- remote heists below VH have just swat
                if heist_type == "remote" then
                    self.besiege.recon.groups.tac_recon_swats = {
                        1,
                        1,
                        1
                    }

                    self.star_recon_groups_to_inject = {
                        "tac_recon_swats"
                    }
                    
                    if reenforce_valid then
                        self.besiege.reenforce.groups.tac_reenforce_swats = {
                            1,
                            1,
                            1
                        }

                        table.insert(self.star_recon_groups_to_inject, "tac_reenforce_swats")
                    end
                --normal diff
                elseif difficulty_index <= 2 then
                    self.besiege.recon.groups.tac_recon_police = {
                        1,
                        1,
                        0
                    }
                    self.besiege.recon.groups.tac_recon_swats = {
                        0,
                        0,
                        1
                    }

                    self.star_recon_groups_to_inject = {
                        "tac_recon_police",
                        "tac_recon_swats"
                    }

                    if reenforce_valid then
                        self.besiege.reenforce.groups.tac_reenforce_police = {
                            1,
                            1,
                            0
                        }
                        self.besiege.reenforce.groups.tac_reenforce_swats = {
                            0,
                            0,
                            1
                        }

                        table.insert(self.star_recon_groups_to_inject, "tac_reenforce_police")
                        table.insert(self.star_recon_groups_to_inject, "tac_reenforce_swats")
                    end
                -- hard diff
                else 
                    self.besiege.recon.groups.tac_recon_police = {
                        1,
                        0.5,
                        0
                    }
                    self.besiege.recon.groups.tac_recon_swats = {
                        0,
                        0.5,
                        1
                    }

                    self.star_recon_groups_to_inject = {
                        "tac_recon_police",
                        "tac_recon_swats"
                    }

                    if reenforce_valid then
                        self.besiege.reenforce.groups.tac_reenforce_police = {
                            1,
                            0.5,
                            0
                        }
                        self.besiege.reenforce.groups.tac_reenforce_swats = {
                            0,
                            0.5,
                            1
                        }

                        table.insert(self.star_recon_groups_to_inject, "tac_reenforce_police")
                        table.insert(self.star_recon_groups_to_inject, "tac_reenforce_swats")
                    end
                end
            -- vh diff
            elseif difficulty_index <= 4 then
                -- final groups
                self.besiege.recon.groups = {
                    tac_recon_case = {
                        0,
                        0,
                        0.6
                    },
                    tac_recon_rescue = {
                        0,
                        0,
                        0.3
                    },
                    tac_recon_rush = {
                        0,
                        0,
                        0.1
                    },
                    single_spooc = {
                        0,
                        0,
                        0
                    },
                    Phalanx = {
                        0,
                        0,
                        0
                    }
                }

                if reenforce_valid then
                    self.besiege.reenforce.groups = {
                        tac_reenforce_2lights = {
                            0,
                            0,
                            0.3
                        },
                        tac_reenforce_1heavy = {
                            0,
                            0,
                            0.2
                        },
                        tac_reenforce_2heavies = {
                            0,
                            0,
                            0.2
                        },
                        tac_reenforce_team = {
                            0,
                            0,
                            0.3
                        }
                    }
                end
                -- remote heists will not have any cops below 0.5 diff. other heists will
                if heist_type == "remote" then
                    self.besiege.recon.groups.tac_recon_swats = {
                        1,
                        1,
                        0
                    }

                    table.insert(self.star_recon_groups_to_inject, "tac_recon_swats")
                    
                    if reenforce_valid then
                        self.besiege.reenforce.groups.tac_reenforce_swats = {
                            1,
                            1,
                            0
                        }

                        table.insert(self.star_recon_groups_to_inject, "tac_reenforce_swats")
                    end
                else
                    self.besiege.recon.groups.tac_recon_police = {
                        0.5,
                        0,
                        0
                    }
                    self.besiege.recon.groups.tac_recon_swats = {
                        0.5,
                        1,
                        0
                    }

                    table.insert(self.star_recon_groups_to_inject, "tac_recon_police")
                    table.insert(self.star_recon_groups_to_inject, "tac_recon_swats")
                    if reenforce_valid then
                        self.besiege.reenforce.groups.tac_reenforce_police = {
                            0.5,
                            0,
                            0
                        }
                        self.besiege.reenforce.groups.tac_reenforce_swats = {
                            0.5,
                            1,
                            0
                        }

                        table.insert(self.star_recon_groups_to_inject, "tac_reenforce_police")
                        table.insert(self.star_recon_groups_to_inject, "tac_reenforce_swats")
                    end
                end
            -- Overkill+
            else
                -- add cops and swats to difficulties overkill and above. no cops on remote heists
                if heist_type == "remote" or heist_type == "fbi" then
                    self.besiege.recon.groups.tac_recon_swats = {
                        1,
                        0,
                        0
                    }

                    table.insert(self.star_recon_groups_to_inject, "tac_recon_swats")
                    
                    if reenforce_valid then
                        self.besiege.reenforce.groups.tac_reenforce_swats = {
                            1,
                            0,
                            0
                        }

                        table.insert(self.star_recon_groups_to_inject, "tac_reenforce_swats")
                    end
                else
                    self.besiege.recon.groups.tac_recon_police = {
                        0.30,
                        0,
                        0
                    }
                    self.besiege.recon.groups.tac_recon_swats = {
                        0.70,
                        0,
                        0
                    }

                    table.insert(self.star_recon_groups_to_inject, "tac_recon_police")
                    table.insert(self.star_recon_groups_to_inject, "tac_recon_swats")

                    if reenforce_valid then
                        self.besiege.reenforce.groups.tac_reenforce_police = {
                            0.30,
                            0,
                            0
                        }
                        self.besiege.reenforce.groups.tac_reenforce_swats = {
                            0.70,
                            0,
                            0
                        }
                        table.insert(self.star_recon_groups_to_inject, "tac_reenforce_police")
                        table.insert(self.star_recon_groups_to_inject, "tac_reenforce_swats")
                    end
                end
                -- add assault groups on overkill+ for classic enemy set reenforce
                if reenforce_valid then
                    self.besiege.reenforce.groups.tac_reenforce_swat_rifle = {
                        0,
                        0,
                        0.5
                    }
                    self.besiege.reenforce.groups.tac_reenforce_swat_shotgun = {
                        0,
                        0,
                        0.5
                    }

                    table.insert(self.star_recon_groups_to_inject, "tac_reenforce_swat_rifle")
                    table.insert(self.star_recon_groups_to_inject, "tac_reenforce_swat_shotgun")
                end
            end
        -- smg swats
        elseif self.rtre_menu_data.enemy_set == 4 then
            self.besiege.recon.groups = {
                tac_recon_swats = {
                    1,
                    1,
                    1
                },
                single_spooc = {
                    0,
                    0,
                    0
                },
                Phalanx = {
                    0,
                    0,
                    0
                }
            }
            
            self.star_recon_groups_to_inject = {
                "tac_recon_swats"
            }

            if reenforce_valid then
                self.besiege.reenforce.groups = {
                    tac_reenforce_swats = {
                        1,
                        1,
                        1
                    }
                }

                table.insert(self.star_recon_groups_to_inject, "tac_reenforce_swats")
            end
        -- assault groups
        elseif self.rtre_menu_data.enemy_set == 5 then
            self.besiege.recon.groups = {
                tac_swat_rifle_flank = {
                    0.7,
                    0.6,
                    0.5
                },
                tac_swat_shotgun_flank = {
                    0.3,
                    0.3,
                    0.3
                },
                tac_swat_shotgun_rush = {
                    0,
                    0.1,
                    0.2
                },
                single_spooc = {
                    0,
                    0,
                    0
                },
                Phalanx = {
                    0,
                    0,
                    0
                }
            }

            local function is_present(table)
                if not table then
                    return false
                end
                for _, v in pairs(table) do
                    if type(v) == "number" and v > 0 then
                        return true
                    end
                end
                return false
            end

            --add some rare specials
            if self.besiege.assault.groups and is_present(self.besiege.assault.groups.tac_tazer_flanking) then
                self.besiege.recon.groups.tac_tazer_flanking = {
                    0,
                    0.03,
                    0.07
                }
            end
            if self.besiege.assault.groups and is_present(self.besiege.assault.groups.FBI_spoocs) then
                self.besiege.recon.groups.FBI_spoocs = {
                    0,
                    0.02,
                    0.03
                }
            end

            self.star_recon_groups_to_inject = {}

            if reenforce_valid then
                self.besiege.reenforce.groups = {
                    tac_reenforce_swat_rifle = {
                        0.5,
                        0.5,
                        0.5
                    },
                    tac_reenforce_swat_shotgun = {
                        0.5,
                        0.5,
                        0.5
                    }
                }

                table.insert(self.star_recon_groups_to_inject, "tac_reenforce_swat_rifle")
                table.insert(self.star_recon_groups_to_inject, "tac_reenforce_swat_shotgun")
            end
        end
        --bronco guy
        local faction = Global.level_data and Global.level_data.level_id and tweak_data_ref.levels[Global.level_data.level_id].ai_group_type
        if self.rtre_menu_data.bronco_guy then
            self.besiege.recon.groups.tac_bronco_guy = {
                0.01,
                0.01,
                0.01
            }
            
            if reenforce_valid then
                self.besiege.reenforce.groups.tac_bronco_guy = {
                    0.01,
                    0.01,
                    0.01
                }
            end

            table.insert(self.star_recon_groups_to_inject, "tac_bronco_guy")
        end
    end
    
    -- reclone
    self.street = deep_clone(self.besiege)
    self.safehouse = deep_clone(self.besiege)
end)