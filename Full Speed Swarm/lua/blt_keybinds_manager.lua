function BLTKeybind:_SetKey(idx, key)
	if not idx then
		return false
	end

	if key == '' then
		self._key.idstring = nil
		self._key.input = nil
	elseif string.find(key, 'mouse wheel ') == 1 then
		self._key.idstring = Idstring(key)
		self._key.input = Input:mouse()
	elseif string.find(key, 'mouse ') == 1 then
		self._key.idstring = Idstring(key:sub(7))
		self._key.input = Input:mouse()
	else
		self._key.idstring = Idstring(key)
		self._key.input = Input:keyboard()
	end

	log(string.format('[Keybind] Bound %s to %s', tostring(self:Id()), tostring(key)))
	self._key[idx] = key
end

function BLTKeybindsManager:update(t, dt, state)
	-- Don't run while chatting
	if self.fs_editing then
		return
	end

	-- Run keybinds
	for _, bind in ipairs(self.fs_filtered_keybinds) do
		local keys = bind._key
		local kids = keys.idstring
		if kids and keys.input:pressed(kids)then
			bind:Execute()
		end
	end
end

local state = Global.load_level and BLTKeybind.StateGame or BLTKeybind.StateMenu

local fs_original_bltkeybindsmanager_registerkeybind = BLTKeybindsManager.register_keybind
function BLTKeybindsManager:register_keybind(...)
	local bind = fs_original_bltkeybindsmanager_registerkeybind(self, ...)
	if bind:CanExecuteInState(state) and bind:ParentMod():IsEnabled() then
		table.insert(self.fs_filtered_keybinds, bind)
	end
	return bind
end


local BLT = BLT

local _state_menu = BLTKeybind.StateMenu
Hooks:Add('MenuUpdate', 'Base_Keybinds_MenuUpdate', function(t, dt)
	BLT.Keybinds:update(t, dt, _state_menu)
end)

local _state_game = BLTKeybind.StateGame
Hooks:Add('GameSetupUpdate', 'Base_Keybinds_GameStateUpdate', function(t, dt)
	BLT.Keybinds:update(t, dt, _state_game)
end)

local filtered_keybinds = {}
for _, bind in ipairs(BLT.Keybinds:keybinds()) do
	local keys = bind._key
	if keys.pc and keys.pc ~= '' then
		if bind:CanExecuteInState(state) and bind:ParentMod():IsEnabled() then
			bind:_SetKey('pc', keys.pc)
			table.insert(filtered_keybinds, bind)
		end
	end
end
BLT.Keybinds.fs_filtered_keybinds = filtered_keybinds


BLT.Keybinds.fs_editor = {}
function BLTKeybindsManager:enter_edit(source)
	self.fs_editor[source] = true
	self.fs_editing = true
end

function BLTKeybindsManager:exit_edit(source)
	self.fs_editor[source] = nil
	self.fs_editing = next(self.fs_editor) ~= nil
end

DelayedCalls:Add('DelayedModFSS_keyboard_typing_stuff', 0, function()
	if HUDManager then
		local fs_original_hudchat_onfocus = HUDChat._on_focus
		function HUDChat:_on_focus(...)
			if not self._focus then
				BLT.Keybinds:enter_edit('HUDChat' .. tostring(self))
			end
			return fs_original_hudchat_onfocus(self, ...)
		end
		local fs_original_hudchat_loosefocus = HUDChat._loose_focus
		function HUDChat:_loose_focus(...)
			BLT.Keybinds:exit_edit('HUDChat' .. tostring(self))
			return fs_original_hudchat_loosefocus(self, ...)
		end

		local fs_original_menumanager_openmenu = MenuManager.open_menu
		function MenuManager:open_menu(node_name, ...)
			if node_name == 'menu_pause' then
				BLT.Keybinds:enter_edit(node_name)
			end
			return fs_original_menumanager_openmenu(self, node_name, ...)
		end

		local fs_original_menumanager_closemenu = MenuManager.close_menu
		function MenuManager:close_menu(menu_name)
			if menu_name == 'menu_pause' then
				BLT.Keybinds:exit_edit(menu_name)
			end
			return fs_original_menumanager_closemenu(self, menu_name)
		end
	end

	local fs_original_menuiteminput_onfocus = MenuItemInput._on_focus
	function MenuItemInput:_on_focus(...)
		BLT.Keybinds:enter_edit('MenuItemInput' .. tostring(self))
		return fs_original_menuiteminput_onfocus(self, ...)
	end
	local fs_original_menuiteminput_loosefocus = MenuItemInput._loose_focus
	function MenuItemInput:_loose_focus(...)
		BLT.Keybinds:exit_edit('MenuItemInput' .. tostring(self))
		return fs_original_menuiteminput_loosefocus(self, ...)
	end

	local fs_original_menuitemtextbox_onfocus = MenuItemTextBox._on_focus
	function MenuItemTextBox:_on_focus(...)
		BLT.Keybinds:enter_edit('MenuItemTextBox' .. tostring(self))
		return fs_original_menuitemtextbox_onfocus(self, ...)
	end
	local fs_original_menuitemtextbox_loosefocus = MenuItemTextBox._loose_focus
	function MenuItemTextBox:_loose_focus(...)
		BLT.Keybinds:exit_edit('MenuItemTextBox' .. tostring(self))
		return fs_original_menuitemtextbox_loosefocus(self, ...)
	end

	local fs_original_chatgui_onfocus = ChatGui._on_focus
	function ChatGui:_on_focus(...)
		BLT.Keybinds:enter_edit('ChatGui' .. tostring(self))
		return fs_original_chatgui_onfocus(self, ...)
	end
	local fs_original_chatgui_loosefocus = ChatGui._loose_focus
	function ChatGui:_loose_focus(...)
		BLT.Keybinds:exit_edit('ChatGui' .. tostring(self))
		return fs_original_chatgui_loosefocus(self, ...)
	end

	local fs_original_menunodegui_activatecustomizecontroller = MenuNodeGui.activate_customize_controller
	function MenuNodeGui:activate_customize_controller(...)
		BLT.Keybinds:enter_edit('MenuItemCustomizeController' .. tostring(self))
		return fs_original_menunodegui_activatecustomizecontroller(self, ...)
	end
	local fs_original_menunodegui_endcustomizecontroller = MenuNodeGui._end_customize_controller
	function MenuNodeGui:_end_customize_controller(...)
		BLT.Keybinds:exit_edit('MenuItemCustomizeController' .. tostring(self))
		return fs_original_menunodegui_endcustomizecontroller(self, ...)
	end

	local fs_original_menunodegui_highlightrowitem = MenuNodeGui._highlight_row_item
	function MenuNodeGui:_highlight_row_item(row_item, ...)
		if row_item and row_item.type == 'chat' then
			BLT.Keybinds:enter_edit('MenuItemCustomizeController' .. tostring(self))
		end
		return fs_original_menunodegui_highlightrowitem(self, row_item, ...)
	end
	local fs_original_menunodegui_faderowitem = MenuNodeGui._fade_row_item
	function MenuNodeGui:_fade_row_item(row_item, ...)
		if row_item and row_item.type == 'chat' then
			BLT.Keybinds:exit_edit('MenuItemCustomizeController' .. tostring(self))
		end
		return fs_original_menunodegui_faderowitem(self, row_item, ...)
	end

	local fs_original_contractbrokergui_connectsearchinput = ContractBrokerGui.connect_search_input
	function ContractBrokerGui:connect_search_input()
		if not self._search_focus then
			BLT.Keybinds:enter_edit('ContractBrokerGui' .. tostring(self))
		end
		return fs_original_contractbrokergui_connectsearchinput(self)
	end
	local fs_original_contractbrokergui_disconnectsearchinput = ContractBrokerGui.disconnect_search_input
	function ContractBrokerGui:disconnect_search_input()
		if not self._search_focus then
			BLT.Keybinds:exit_edit('ContractBrokerGui' .. tostring(self))
		end
		return fs_original_contractbrokergui_disconnectsearchinput(self)
	end

	local fs_original_multiprofileitemgui_setediting = MultiProfileItemGui.set_editing
	function MultiProfileItemGui:set_editing(editing)
		if editing then
			BLT.Keybinds:enter_edit('MultiProfileItemGui' .. tostring(self))
		else
			BLT.Keybinds:exit_edit('MultiProfileItemGui' .. tostring(self))
		end
		return fs_original_multiprofileitemgui_setediting(self, editing)
	end
end)
