dofile(ModPath .. "lua/DWPbase.lua")

Hooks:Add('LocalizationManagerPostInit', 'DWP_option_loc', function(loc)--maybe translations will be added in the future, but i doubt it
	DWP:Load()
	loc:load_localization_file(DWP._path .. 'menu/DWPmenu_en.txt', false)
end)

-- all the setting that can be changes in the mod's settings in game
Hooks:Add('MenuManagerInitialize', 'DWP_init', function(menu_manager)

	MenuCallbackHandler.DWPsave = function(this, item)
		DWP:Save()
	end

	MenuCallbackHandler.DWPcb_donothing = function(this, item)
		--nothingness
	end
	
	MenuCallbackHandler.DWPcb_arrestbeta = function(this, item)
		DWP.settings[item:name()] = item:value() == 'on'
		DWP:Save()
	end
	
	MenuCallbackHandler.DWPcb_hostagesbeta = function(this, item)
		DWP.settings[item:name()] = item:value() == 'on'
		DWP:Save()
	end
	
	MenuCallbackHandler.DWPcb_DSdozer = function(this, item)
		DWP.settings[item:name()] = item:value() == 'on'
		DWP:Save()
	end
	
	MenuCallbackHandler.DWPcb_bAmMarsh = function(this, item)
		DWP.settings[item:name()] = item:value() == 'on'
		DWP:Save()
	end
	
	MenuCallbackHandler.DWPcb_difficulty = function(this, item)
		DWP.settings.difficulty = tonumber(item:value())
		DWP:Save()
	end
	
	MenuCallbackHandler.DWPcb_assforce_pool = function(this, item)
		DWP.settings.assforce_pool = tonumber(item:value())
		DWP:Save()
	end
	
	MenuCallbackHandler.DWPcb_assduration = function(this, item)
		DWP.settings.assduration = tonumber(item:value())
		DWP:Save()
	end
	
	MenuCallbackHandler.DWPcb_gameplay_defaults = function(this, item)		
		DWP.menu_node._items_list[3].selected = 1
		DWP.settings.DSdozer = true
		
		DWP.menu_node._items_list[4].selected = 1
		DWP.settings.bAmMarsh = true
		
		DWP.menu_node._items_list[5].selected = 1
		DWP.settings.arrestbeta = true
		
		DWP.menu_node._items_list[6].selected = 2
		DWP.settings.hostagesbeta = false
		
		DWP.menu_node._items_list[7]._current_index = 1
		DWP.settings.difficulty = 1
		
		DWP.menu_node._items_list[8]._value = 400
		DWP.settings.assforce_pool = 400
		
		DWP.menu_node._items_list[9]._value = 350
		DWP.settings.assduration = 350
		managers.menu:active_menu().renderer:active_node_gui():refresh_gui(DWP.menu_node)
		DWP:Save()
	end
	
	MenuCallbackHandler.DWPcb_lobbyname = function(this, item)
		DWP.settings[item:name()] = item:value() == 'on'
		DWP:Save()
	end
	
	MenuCallbackHandler.DWPcb_endstattoggle = function(this, item)
		DWP.settings[item:name()] = item:value() == 'on'
		DWP:Save()
	end
	
	MenuCallbackHandler.DWPcb_endstatSPkills = function(this, item)
		DWP.settings[item:name()] = item:value() == 'on'
		DWP:Save()
	end
	
	MenuCallbackHandler.DWPcb_endstatheadshots = function(this, item)
		DWP.settings[item:name()] = item:value() == 'on'
		DWP:Save()
	end
	
	MenuCallbackHandler.DWPcb_endstataccuarcy = function(this, item)
		DWP.settings[item:name()] = item:value() == 'on'
		DWP:Save()
	end
	
	MenuCallbackHandler.DWPcb_skillinfo = function(this, item)
		DWP.settings[item:name()] = item:value() == 'on'
		DWP:Save()
	end
	
	MenuCallbackHandler.DWPcb_hourinfo = function(this, item)
		DWP.settings[item:name()] = item:value() == 'on'
		DWP:Save()
	end
	
	MenuCallbackHandler.DWPcb_infamy = function(this, item)
		DWP.settings[item:name()] = item:value() == 'on'
		DWP:Save()
	end
	
	MenuCallbackHandler.DWPcb_infomsgpublic = function(this, item)
		DWP.settings[item:name()] = item:value() == 'on'
		DWP:Save()
	end
	
	MenuCallbackHandler.DWPcb_statsmsgpublic = function(this, item)
		DWP.settings[item:name()] = item:value() == 'on'
		DWP:Save()
	end

	DWP:Load()

	MenuHelper:LoadFromJsonFile(DWP._path .. 'menu/DWPmenu.txt', DWP, DWP.settings)
end)