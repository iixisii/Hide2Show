--[[
    3.5.23 (hide & show) version 3
    (commands) => action | target | time.optional (default) => 1s
    (commands) on.action | target | target_event_name | action.optional
	(targetPlacement) all
	(targetPlacement) all_like_*
    (possible commands) =>
    [
        (hide) -- will hide the target
        (show) -- will show the target
        (onhide) -- will show or hide the target when (hide) is executed .default => show
        (onshow) -- will hide or show the target when (show) is executed .default => hide
		(default) -- use this command if you want (hide) or (show) objects by default.
		
	]
    (possible implements) => [
        1. hide | example_target_source_name
        2. show | example_target_source_name
        3. onhide | example_target_source_name
        4. onshow | example_target_source_name
        5. hide | example_target_source_name | 10s -- hides the target in (10 seconds) use (m) for (minutes)
        6. show | example_target_source_name | 5s  -- hides the target in (5 seconds) use (m) for (minutes)
		7. hide | all -- will hide everything every 1s
		8. show | all_like_icon -- will show everything that starts with (icon) every 1s
		9. onshow | target | all | hide;
		0. onhide | target | all_like_icon | show
	]
    we can be friends twitter(iis_xiao) or instagram(xiao_sings) <3
]]
obs     =   obslua
APP     =   {}
APP_EVENT
        =   {}
__SETTINGS__ = {
	SCENE = ""
}
APP_CALLBACKS = {}
APP_ON_EVENT = {
    onhide = {};
    onshow = {};
};
APP_OBJECTS = {};
APP_ACTIONS = {"hide","show","onhide","onshow","(onshow)","(hide)","(show)","(onhide)"}
APP_IS_ENABLE = false
APP_TRANSITIONS = {
	"Fade", "Cut", "None"
}
LOG_LEVEL = {
	[1] = "DEBUG";[2] = "";
	[3] = "WARNING";[4] = "ERROR";
}
APP_LOG_LVL = 2
APP_LOG_DB_LVL = 1
APP_LOG_WRN_LVL = 3
APP_LOG_ERR_LVL= 4
APP_LOG_NRM_LVL = 2
APP_ACTION_PROP = nil
APP_SETTINGS = nil
--[[ OBS RELATED OPERATIONS ]]



function script_properties()
	-- Properties;
    local props = obs.obs_properties_create()
	local gprops = obs.obs_properties_create()
	local aprops = obs.obs_properties_create()
	local sprops = obs.obs_properties_create()
	local eprops = obs.obs_properties_create()
	local rmprops = obs.obs_properties_create()
	local mlprops = obs.obs_properties_create()
	
	--
	local scene_name = ""
	if APP_SETTINGS ~= nil then
		scene_name = obs.obs_data_get_string(APP_SETTINGS, "scene_name")
		__SETTINGS__.SCENE = scene_name
	end
	--[[Status Group]]
	obs.obs_properties_add_group(props, "status_group", "Status", obs.OBS_GROUP_NORMAL,sprops)
	local ui = obs.obs_properties_add_bool(sprops, "ui","UI")
	local linear = obs.obs_properties_add_bool(sprops,"linear","Linear Behavior");
	local autoSwitch = obs.obs_properties_add_bool(sprops,"auto_switch_scene","Switch Scene");
	obs.obs_property_set_long_description(autoSwitch, "Check the box to switch scene whenever you select a different scene")
	--[[Configuration Group]]
    local config = obs.obs_properties_add_group(props, "config_group", "Configuration", obs.OBS_GROUP_NORMAL,gprops)
    local scene_list = obs.obs_properties_add_list(gprops, "scene_name", "Scene(*)", obs.OBS_COMBO_TYPE_LIST, obs.OBS_COMBO_FORMAT_STRING)
    local manual = obs.obs_properties_add_bool(gprops, "interface_manual", "Manual interface")
	--[[Populate Scenes]]
	-- Collect all the scenes
	
	
	local scenes = obs.obs_frontend_get_scenes()
	if scenes ~= nil then
        obs.obs_property_list_add_string(scene_list, "<Select>", nil)
		for _, scene in ipairs(scenes) do
			local name = obs.obs_source_get_name(scene)
			obs.obs_property_list_add_string(scene_list, name, name)
		end
        obs.source_list_release(scenes)
	end
	obs.obs_property_set_modified_callback(scene_list,function(properties, property, settings)
		scene_modified(properties, property, settings)
		
		if obs.obs_data_get_bool(APP_SETTINGS, "auto_switch_scene") then
			local scene_name = obs.obs_data_get_string(APP_SETTINGS, "scene_name")
			local scene = obs.obs_get_source_by_name(scene_name)
			if scene ~= nil then
				obs.obs_frontend_set_current_scene(scene)
			end
			obs.obs_source_release(scene)
		end
		return true
	end)
	--[[Action Group]]
	local action = obs.obs_properties_add_group(props, "action_group", "Action Setup", obs.OBS_GROUP_NORMAL,aprops)
	--local waring_action = obs.obs_properties_add_text(aprops, "action_warning","Action warning label!", obs.OBS_TEXT_INFO )
	--obs.obs_property_text_set_info_type(waring_action, obs.OBS_TEXT_INFO_ERROR)
	-- Action list
	local action_list = obs.obs_properties_add_list(aprops, "action_name", "Action(*)",obs.OBS_COMBO_TYPE_LIST, obs.OBS_COMBO_FORMAT_STRING)
	obs.obs_property_list_add_string(action_list, "<Select>", nil)
	obs.obs_property_list_add_string(action_list, "Hide", "hide")
	obs.obs_property_list_add_string(action_list, "Show", "show")
	
	-- Target list
	local target_list = obs.obs_properties_add_list(aprops, "action_target", "Target(*)",obs.OBS_COMBO_TYPE_LIST, obs.OBS_COMBO_FORMAT_STRING)
	
	local target_list_all_like_input = obs.obs_properties_add_text(aprops, "action_target_list_all_like_input","Enter (all_like_*) value(*)", obs.OBS_TEXT_DEFAULT)
	obs.obs_property_set_visible(target_list_all_like_input, false)
	-- Time
	local time_p = obs.obs_properties_add_int(aprops, "action_time", "Time (Seconds):",1,1000000,1)
	-- Randomness
	local rand_p = obs.obs_properties_add_bool(aprops, "action_rand", "Random");
	-- add action
	local action_warn_label = obs.obs_properties_add_text(aprops, "action_warn_label","Warning !", obs.OBS_TEXT_INFO)
	local add_action_p = obs.obs_properties_add_button(aprops,"action_add", "Add Action", add_action)
	obs.obs_property_text_set_info_type(action_warn_label, obs.OBS_TEXT_INFO_WARNING)
	obs.obs_property_set_visible(action_warn_label, false)
	--[[Event Group]]
	local events = obs.obs_properties_add_group(props, "event_group", "Event Setup", obs.OBS_GROUP_NORMAL,eprops)
	-- event list
	local action_list = obs.obs_properties_add_list(eprops, "event_name", "Event(*)",obs.OBS_COMBO_TYPE_LIST, obs.OBS_COMBO_FORMAT_STRING)
	obs.obs_property_list_add_string(action_list, "<Select>", "")
	obs.obs_property_list_add_string(action_list, "Onhide", "onhide")
	obs.obs_property_list_add_string(action_list, "Onshow", "onshow")
	-- Target list
	local event_target_list = obs.obs_properties_add_list(eprops, "event_target", "Handle(*)",obs.OBS_COMBO_TYPE_LIST, obs.OBS_COMBO_FORMAT_STRING)
	-- Effect list
	local effect_target_list = obs.obs_properties_add_list(eprops, "effect_target", "Target(*)",obs.OBS_COMBO_TYPE_LIST, obs.OBS_COMBO_FORMAT_STRING)
	local effect_list_all_like_input = obs.obs_properties_add_text(eprops, "effect_target_list_all_like_input","Enter (all_like_*) value(*)", obs.OBS_TEXT_DEFAULT)
	obs.obs_property_set_visible(effect_list_all_like_input, false)
	-- Action list
	local action_list = obs.obs_properties_add_list(eprops, "event_action_name", "Action",obs.OBS_COMBO_TYPE_LIST, obs.OBS_COMBO_FORMAT_STRING)
	obs.obs_property_list_add_string(action_list, "<Select>", "")
	obs.obs_property_list_add_string(action_list, "Hide", "hide")
	obs.obs_property_list_add_string(action_list, "Show", "show")
	
	-- add event
	local event_warn_label = obs.obs_properties_add_text(eprops, "event_warn_label","Warning !", obs.OBS_TEXT_INFO)
	local add_event_p = obs.obs_properties_add_button(eprops,"event_add", "Add Event", add_event)
	obs.obs_property_text_set_info_type(event_warn_label, obs.OBS_TEXT_INFO_WARNING)
	obs.obs_property_set_visible(event_warn_label, false)
	--[[Manual Group]]
	local manual_group = obs.obs_properties_add_group(props, "manual_group", "Command Prompt", obs.OBS_GROUP_NORMAL,mlprops)
	local manual_input = obs.obs_properties_add_text(mlprops, "terminal_cmd", "", obs.OBS_TEXT_DEFAULT)
	local manual_label = obs.obs_properties_add_text(mlprops, "terminal_label","", obs.OBS_TEXT_INFO)
	local manual_btn = obs.obs_properties_add_button(mlprops, "terminal_btn", "Execute", COMMAND_PROMPT)
	obs.obs_property_text_set_info_type(manual_label, obs.OBS_TEXT_INFO_ERROR)
	obs.obs_property_set_visible(manual_label, false)
	obs.obs_property_set_visible(manual_group, false)
	-- Populate the targets
	--if __SETTINGS__.SCENE == nil or __SETTINGS__.SCENE == "" then
		obs.obs_property_list_add_string(target_list, "<SCENE NOT SELECTED>", "")
		obs.obs_property_list_add_string(event_target_list, "<SCENE NOT SELECTED>", "")
		obs.obs_property_list_add_string(effect_target_list, "<SCENE NOT SELECTED>", "")
	--else
		--
	--end
	--[[Source List]]
    local pl = obs.obs_properties_add_text(props, "hide_n_show_sources_label","", obs.OBS_TEXT_INFO)
    --[[Rm List source group]]
    local rm_ls_gp=  obs.obs_properties_add_group(props, "rm_ls_gp", "Operation", obs.OBS_GROUP_NORMAL,rmprops)
    local rm_source_list = obs.obs_properties_add_list(rmprops, "rm_ls_list", "Select:",obs.OBS_COMBO_TYPE_LIST, obs.OBS_COMBO_FORMAT_STRING)
    local rm_source_btn = obs.obs_properties_add_button(rmprops,"rm_ls_btn", "Delete", remove_source_from_list)
    local source_list = obs.obs_data_get_array(APP_SETTINGS,scene_name)
    if source_list == nil or obs.obs_data_array_count(source_list) <= 0 then
		 obs.obs_property_set_visible(rm_ls_gp, false)
		 
    end
    obs.obs_data_array_release(source_list)
    -- descriptions
    obs.obs_property_set_long_description(time_p, "example: 120 seconds would be 2 minutes")
    obs.obs_property_set_long_description(rand_p, "check to make (Time) random")
    obs.obs_property_set_long_description(ui, "lets the user to user (Interface) buttons, and stuff.")
    obs.obs_property_set_long_description(linear, "When this box is checked, it will make it so that hide/show\n\rexecutes only if it reaches its specificed (min/sec) example => {hide} cannot \n\rexecute if {show} was not executed or if it hasn't reached the specific (min/secs); same applies to (show)")
    obs.obs_property_set_long_description(target_list_all_like_input, [[Enter a word/name of something that you want to use as <b>all_like_*</b> example: <b>my_label</b> becomes => all_like_my_label]])
    obs.obs_property_set_long_description(effect_list_all_like_input, [[Enter a word/name of something that you want to use as <b>all_like_*</b> example: <b>my_label</b> becomes => all_like_my_label]])
     obs.obs_property_set_long_description(manual_input,
		[[<table><b>Example(1):</b> <span style = 'color:gray'> action | target | time.optional</span>]]
		..
		[[<br/><b>Example(2):</b> <span style = 'color:gray'> on.event | trigger_target | target | action.optional </span>]]
		..
		[[<br/><b>Example(3):</b> <span style = 'color:gray'> hide | target | action</span>]]
		..
		[[<br/><b>Example(4):</b> <span style = 'color:gray'> default | action</span>]]
		..
		[[</table>]]
     )
    --
    interface_modified(props, nil, nil)
    scene_modified(props, nil,nil);
    -- event for (lists)
    obs.obs_property_set_modified_callback(effect_target_list,list_event_change)
    obs.obs_property_set_modified_callback(target_list,list_event_change)
    obs.obs_property_set_modified_callback(ui,interface_modified)
    obs.obs_property_set_modified_callback(manual,interface_modified)
    obs.obs_property_set_description(pl, soure_list_view())
    return props
end

function script_unload()
    for name, iter in pairs(APP_OBJECTS) do -- set defaults
        APP:show(name);
    end
end
local LinearBehavior = false;
function script_load(_settings)
	if APP_SETTINGS ~= nil then
		obs.obs_data_release(APP_SETTINGS);
	end
	
	APP_SETTINGS = _settings
	if obs.obs_data_get_bool(_settings,"linear") == true then
		LinearBehavior = true;
	else
		LinearBehavior = false;
	end
	-- (source_list) setup
	local source_list = obs.obs_data_get_array(APP_SETTINGS,"source_list")
	if source_list == nil then
		local new_list = obs.obs_data_array_create()
		obs.obs_data_set_array(APP_SETTINGS, "source_list", new_list)
		obs.obs_save_sources()
		obs.obs_data_array_release(new_list)
	else
		obs.obs_data_array_release(source_list)
	end
	--append_interface(APPS_PROPS, obs.obs_data_get_bool(_settings, "interface"))
	
    --[[local action_title = obs.obs_data_get_string(_settings, "actionTitle")
    if action_title == "Disable" then
        APP_IS_ENABLE = true
    end]]
    --if APP_IS_ENABLE then
        --APP:Enable()
    --[[else
        APP:Disable()
    end]]
end
function script_update(_settings)
    -- update (APP_EVENT)
	if obs.obs_data_get_bool(_settings,"linear") == true then
		LinearBehavior = true;
	else
		LinearBehavior = false;
	end
    APP:initUpdate(_settings)
end
function script_default(_settings)
	if obs.obs_data_get_bool(_settings,"linear") == true then
		LinearBehavior = true;
	else
		LinearBehavior = false;
	end
end
function script_save(_settings) end
-- END OF OBS RELATED OPERATIONS





-- [[ USER DEFINED OPERATIONS ]]

function INSERT_INTO_OBS_ARRAY__(array_name, value)
	if array_name == nil or array_name == "" then
		return false
	end
	local __array_list = obs.obs_data_get_array(APP_SETTINGS, array_name)
	if __array_list ~= nil then
		local newAction = obs.obs_data_create();
		obs.obs_data_set_string(newAction, "key", value);
		obs.obs_data_array_push_back(__array_list, newAction)
		obs.obs_data_release(newAction)
		obs.obs_data_array_release(__array_list)
		return true;
	end
	return false
end



function COMMAND_PROMPT(properties, property)
	local command_list = obs.obs_data_get_string(APP_SETTINGS, "terminal_cmd")
	obs.obs_data_set_string(APP_SETTINGS, "terminal_cmd", "")
	local scene_name = obs.obs_data_get_string(APP_SETTINGS, "scene_name")
	local warn_label = obs.obs_properties_get(properties, "terminal_label")
	if scene_name == nil or scene_name == "" then
		obs.obs_property_set_visible(warn_label, true)
		obs.obs_property_set_description(warn_label, "(Please select scene)")
		APP_LOG("make sure to select a scene before inserting anything", APP_LOG_WRN_LVL)
		return true;
	end
	if command_list == nil or command_list == "" then
		obs.obs_property_set_visible(warn_label, true)
		obs.obs_property_set_description(warn_label, "Invalid command!")
		return true;
	end
	local cmd_value = command_list
	command_list = string_pipes(command_list)
	obs.obs_property_set_visible(warn_label, false)
	if command_list and #command_list > 1 then
		local action_name = string.lower(command_list[1]:gsub("^%s*(.-)%s*$", "%1"))
		if APP_ACTIONS:isOnAction(action_name) then -- INSERT (EVENT)
			if #command_list < 3 then
				obs.obs_property_set_visible(warn_label, true)
				obs.obs_property_set_description(warn_label, "Invalid (On.event) 3 arguments expected; got 2")
				return true;
			end
			local action_value = ""
			if action_name == "onhide" then
				action_value = "show"
			else
				action_value = "hide"
			end
			local listen_target = command_list[2]:gsub("^%s*(.-)%s*$", "%1")
			local effect_target = command_list[3]:gsub("^%s*(.-)%s*$", "%1")
			if #command_list >= 4 then
				local v = string.lower(command_list[4]:gsub("^%s*(.-)%s*$", "%1"))
				if not APP_ACTIONS:has(v) then
					obs.obs_property_set_visible(warn_label, true)
					obs.obs_property_set_description(warn_label, "Invalid (On.event.action) argument 4")
					APP_LOG("{" .. tostring(v) .. "} (On.event.action) is not an action!", APP_LOG_WRN_LVL)
					return true
				else
					action_value = v
				end
			end
			-- make sure (listen_target) exists
			local __obj1 = __GET_SCENE_ITEM__(listen_target)
			if __obj1 == nil then
				obs.obs_property_set_visible(warn_label, true)
				obs.obs_property_set_description(warn_label, "Invalid (On.event.target) argument 2; not found")
				APP_LOG("{" .. tostring(listen_target) .. "} (On.event.target) is not found on the current scene!", APP_LOG_WRN_LVL)
				return true
			else
				obs.obs_sceneitem_release(__obj1)
			end
			if not APP_ACTIONS:IsLikeAction(effect_target) and string.lower(effect_target) ~= "all" then
				local __obj2 = __GET_SCENE_ITEM__(effect_target)
				if __obj2 == nil then
					obs.obs_property_set_visible(warn_label, true)
					obs.obs_property_set_description(warn_label, "Invalid (On.event.target) argument 3; not found")
					APP_LOG("{" .. tostring(effect_target) .. "} (On.event.target) is not found on the current scene!", APP_LOG_WRN_LVL)
					return true
				else
					obs.obs_sceneitem_release(__obj2)
				end
			end
			local action = "[" .. scene_name .. "]|" .. action_name .. "|" .. listen_target .. "|" .. effect_target .. "|" .. action_value
			if not INSERT_INTO_OBS_ARRAY__(scene_name, action) then
				obs.obs_property_set_visible(warn_label, true)
				obs.obs_property_set_description(warn_label, "Error: something went wrong")
				APP_LOG("{Execute} Something awful happend! (to fix maybe restart the whole program)", APP_LOG_ERR_LVL)
			else
				local op = obs.obs_properties_get(properties, "rm_ls_gp");
				obs.obs_property_set_visible(op, true)
			end
		elseif action_name == "hide" or action_name == "show" then -- INSERT (ACTION)
			if #command_list < 2 then
				obs.obs_property_set_visible(warn_label, true)
				obs.obs_property_set_description(warn_label, "Invalid (action) 2 arguments expected; got 1")
				return true;
			end
			local action_target = command_list[2]:gsub("^%s*(.-)%s*$", "%1")
			if action_target == "" then
				obs.obs_property_set_visible(warn_label, true)
				obs.obs_property_set_description(warn_label, "Invalid (action) 2 arguments expected; got 1")
				return true;
			end
			local action_time_value = "1s"
			if #command_list >= 3 then -- time
				local action_time = time_splitter(string.lower(command_list[3]:gsub("^%s*(.-)%s*$", "%1")))
				if action_time == nil or action_time.value == nil or action_time.type == "" then
					obs.obs_property_set_visible(warn_label, true)
					obs.obs_property_set_description(warn_label, "Invalid (action.Time) argument 3; time not valid")
					return true
				else
					action_time_value = action_time.order .. tostring(action_time.value) .. action_time.type
				end
			end
			-- check if the target exists;
			if not APP_ACTIONS:IsLikeAction(action_target) and string.lower(action_target) ~= "all" then
				local __obj = __GET_SCENE_ITEM__(action_target)
				if __obj == nil then
					obs.obs_property_set_visible(warn_label, true)
					obs.obs_property_set_description(warn_label, "Invalid (action.Target) argument 2; not found")
					APP_LOG("{" .. tostring(action_target) .. "} is not found on the current scene!", APP_LOG_WRN_LVL)
					return true
				else
					obs.obs_sceneitem_release(__obj)
				end
			end
			local action = "[" .. scene_name .. "]|" .. action_name .. "|" .. action_target .. "|" .. action_time_value
			if not INSERT_INTO_OBS_ARRAY__(scene_name, action) then 
				obs.obs_property_set_visible(warn_label, true)
				obs.obs_property_set_description(warn_label, "Error: something went wrong")
				APP_LOG("{Execute} Something awful happend! (to fix maybe restart the whole program)", APP_LOG_ERR_LVL)
			else
				local op = obs.obs_properties_get(properties, "rm_ls_gp");
				obs.obs_property_set_visible(op, true)
			end
		elseif action_name == "default" then
			if #command_list <= 1 then
				obs.obs_property_set_visible(warn_label, true)
				obs.obs_property_set_description(warn_label, "Invalid (default); missing second argument")
				return true
			end
			local act = string.lower(command_list[2]:gsub("^%s*(.-)%s*$", "%1"))
			if act ~= "hide" and act ~= "show" then
				obs.obs_property_set_visible(warn_label, true)
				obs.obs_property_set_description(warn_label, "Invalid (default.action); must an action")
				return true
			end
			local action = "[" .. scene_name .. "]" .. "|default|" .. act
			if not INSERT_INTO_OBS_ARRAY__(scene_name, action) then
				obs.obs_property_set_visible(warn_label, true)
				obs.obs_property_set_description(warn_label, "Error: something went wrong")
				APP_LOG("{Execute} Something awful happend! (to fix maybe restart the whole program)", APP_LOG_ERR_LVL)
			else
				local op = obs.obs_properties_get(properties, "rm_ls_gp");
				obs.obs_property_set_visible(op, true)
			end
		else -- INSERT (OTHERS)
			obs.obs_property_set_visible(warn_label, true)
			obs.obs_property_set_description(warn_label, "Invalid command; first argument {" .. action_name .. "}")
		end
	else -- object source;
		local objectName = "";
		local object_list = ""
		for i = 1,#cmd_value do
			local charx = string.sub(cmd_value, i, i);
			if charx == "," then
				-- store the current object it found;
				if APP:HasObject(objectName)  then
					if object_list ~= "" then
						object_list = object_list .. "," .. objectName
					else
						object_list = objectName
					end
				else
					APP_LOG("Failed to insert source {" .. objectName .. "} does not exist!", APP_LOG_WRN_LVL)
				end
				objectName = "";
			else
				objectName = objectName .. charx;
			end
			objectName = objectName:gsub("^%s*(.-)%s*$", "%1");
		end
		if APP:HasObject(objectName)  then
			if object_list ~= "" then
				object_list = object_list .. "," .. objectName
			else
				object_list = objectName
			end
		else
			APP_LOG("Failed to insert source {" .. objectName .. "} does not exist!", APP_LOG_WRN_LVL)
		end
		if object_list ~= "" then
			if not INSERT_INTO_OBS_ARRAY__(scene_name, object_list) then 
				APP_LOG("{Execute} Something awful happend! (to fix maybe restart the whole program)", APP_LOG_ERR_LVL)
			else
				local op = obs.obs_properties_get(properties, "rm_ls_gp");
				obs.obs_property_set_visible(op, true)
			end
		end
	end
	--[[Re-draw]]
	local p_list = obs.obs_properties_get(properties, "hide_n_show_sources_label")
	obs.obs_property_set_description(p_list,soure_list_view())
	scene_modified(properties, property, nil)
	APP:initUpdate()
	return true
end
function __GET_SCENE_ITEM__(item_name)
	local sceneName = obs.obs_data_get_string(APP_SETTINGS, "scene_name")
	local sceneObject = obs.obs_get_source_by_name(sceneName)
    local sourceObject = obs.obs_get_source_by_name(item_name)
    if sceneObject ~= nil then
		local scene = obs.obs_scene_from_source(sceneObject)
		local scene_item = obs.obs_scene_sceneitem_from_source(scene, sourceObject)
		obs.obs_source_release(sceneObject)
		obs.obs_source_release(sourceObject)
		return scene_item
	end
	obs.obs_source_release(sourceObject)
end
function toggle_prop_by_name(ps1, name, t)
	if ps1 == nil or name == nil or (t ~= false and t ~= true) then
		return false
	end
	local p_obj = obs.obs_properties_get(ps1, name);
	if p_obj ~= nil then
		obs.obs_property_set_visible(p_obj,t)
		return true
	else
	end
	return false
end
function interface_modified(properties,property, s)
	local show_ui = false
	local interface_manual = false
	if APP_SETTINGS ~= nil then
		show_ui = obs.obs_data_get_bool(APP_SETTINGS, "ui")
		interface_manual = obs.obs_data_get_bool(APP_SETTINGS, "interface_manual")
	end
	local p_action = obs.obs_properties_get(properties, "action_group")
	local p_config = obs.obs_properties_get(properties, "config_group")
	local p_events = obs.obs_properties_get(properties, "event_group")
	--local p_list_label = obs.obs_properties_get(ps1, "hide_n_show_sources_label")
	obs.obs_property_set_visible(p_action, show_ui)
	obs.obs_property_set_visible(p_config, show_ui)
	obs.obs_property_set_visible(p_events, show_ui)
	
	local p_manual = obs.obs_properties_get(properties, "manual_group")
	if show_ui and interface_manual then
		obs.obs_property_set_visible(p_action, false)
		obs.obs_property_set_visible(p_events, false)
		--
		obs.obs_property_set_visible(p_manual, true)
	elseif show_ui and not interface_manual then
		obs.obs_property_set_visible(p_manual, false)
	end
	return true
end
function scene_modified(properties, property, s)
	local scene_name = obs.obs_data_get_string(APP_SETTINGS, "scene_name");
	local p_action_list = obs.obs_properties_get(properties, "action_target");
	local p_event_list = obs.obs_properties_get(properties,"event_target");
	local p_effect_list = obs.obs_properties_get(properties,"effect_target");
	 local p_source_list = obs.obs_properties_get(properties, "rm_ls_list")
	if scene_name == "" or scene_name == nil then
		return false;
	end
	-- make sure (scene_name) is stored on the settings
	local __scene_list = obs.obs_data_get_array(APP_SETTINGS, scene_name)
	if __scene_list == nil then
		__scene_list = obs.obs_data_array_create()
		obs.obs_data_set_array(APP_SETTINGS, scene_name, __scene_list)
		obs.obs_save_sources()
	end
	local function search_and_label_remove(p)
		if obs.obs_property_list_item_count(p) > 0 then
			local first_item = obs.obs_property_list_item_name(p,0);
			if first_item == "<SCENE NOT SELECTED>" then
				obs.obs_property_list_item_remove(p, 0)
			end
		end
	end
	search_and_label_remove(p_action_list);
	search_and_label_remove(p_event_list);
	search_and_label_remove(p_effect_list);
	-- clear all the previous items;
	local function clear_all(p, cp)
		for i = 0,obs.obs_property_list_item_count(p) do
			obs.obs_property_list_item_remove(p, i);
		end
		if(obs.obs_property_list_item_count(p) > 0) then
			if cp == nil then
				cp = obs.obs_property_list_item_count(p)
			end
			if cp > 0 then
				return clear_all(p, cp - 1)
			end
		end
	end
	clear_all(p_action_list, nil)
	clear_all(p_event_list, nil)
	clear_all(p_effect_list, nil)
	clear_all(p_source_list, nil)
	-- show all the items of the current scene;
    local _scene_obj = obs.obs_get_source_by_name(scene_name)
    local current_scene = obs.obs_scene_from_source(_scene_obj)
    local all_items = obs.obs_scene_enum_items(current_scene);
    if all_items ~= nil then
		obs.obs_property_list_add_string(p_action_list, "<Select>","<nil>");
		obs.obs_property_list_add_string(p_event_list, "<Select>", "<nil>");
		obs.obs_property_list_add_string(p_effect_list, "<Select>", "<nil>");
		obs.obs_property_list_add_string(p_effect_list, "<All>", "all");
		obs.obs_property_list_add_string(p_action_list,"<All>", "all");
		--
		obs.obs_property_list_add_string(p_effect_list, "<All_lik_*>", "all_like_*");
		obs.obs_property_list_add_string(p_action_list,"<All_lik_*>", "all_like_*");
		for _, item in ipairs(all_items) do
			local s = obs.obs_sceneitem_get_source(item);
			local name = obs.obs_source_get_name(s);
			obs.obs_property_list_add_string(p_action_list, name, name);
			obs.obs_property_list_add_string(p_event_list, name, name);
			obs.obs_property_list_add_string(p_effect_list, name, name);
		end
		--obs.obs_property_set_int()
	end
    obs.sceneitem_list_release(all_items)
    obs.obs_source_release(_scene_obj)
    -- delete (operation)
   
	
	if __scene_list ~= nil and obs.obs_data_array_count(__scene_list) > 0 then
		obs.obs_property_list_add_string(p_source_list, "", "")
		local len = obs.obs_data_array_count(__scene_list);
		-- show soure list;
		-- get all the sources in the array list; and display them to the label;
		for i = 0, len - 1 do
			local p_item = obs.obs_data_array_item(__scene_list,i)
			if p_item ~= nil then 
				local value = obs.obs_data_get_string(p_item,"key")
				local value_list = string_pipes(value)
				if #value_list >= 2 then --- (ACTION) command
					local scene_name = value_list[1]:gsub("^%s*(.-)%s*$", "%1")
					local action_name = string.lower(value_list[2]:gsub("^%s*(.-)%s*$", "%1"))
					if APP_ACTIONS:isOnAction(action_name) then
						local event = value_list[3]:gsub("^%s*(.-)%s*$", "%1");
						local target = value_list[4]:gsub("^%s*(.-)%s*$", "%1");
						local action_value = value_list[5]
						local action = scene_name .. " | " .. action_name .. " | " .. event .. " | " ..  target ..  " | " .. action_value
						obs.obs_property_list_add_string(p_source_list, action, action)
					elseif action_name == "hide" or action_name == "show" then
						local target = value_list[3];
						local timer = time_splitter(value_list[4])
						local action = scene_name .. " | " .. action_name .. " | " .. target .. " | " .. timer.order .. tostring(timer.value) .. tostring(timer.type)
						obs.obs_property_list_add_string(p_source_list, action, action)
					else -- default
						local action = scene_name .. " | " .. value_list[2] .. " | " .. value_list[3]
						obs.obs_property_list_add_string(p_source_list, action, action)
					end
				else -- program sources;
					local action = "(Program sources) " .. value
					obs.obs_property_list_add_string(p_source_list, action, value)
				end
			end
		end
		
	end
	if __scene_list ~= nil then
		obs.obs_data_array_release(__scene_list)
	end
	local p_list = obs.obs_properties_get(properties, "hide_n_show_sources_label")
	obs.obs_property_set_description(p_list,soure_list_view())
	return true
end
function list_event_change(properties, property)
	local property_name = obs.obs_property_name(property)
	
	if property_name == "action_target" or property_name == "effect_target" then
		local property_value1 = obs.obs_data_get_string(APP_SETTINGS, "action_target")
		local property_value2 = obs.obs_data_get_string(APP_SETTINGS, "effect_target")
		local all_like_input1 = obs.obs_properties_get(properties, "action_target_list_all_like_input")
		local all_like_input2 = obs.obs_properties_get(properties, "effect_target_list_all_like_input")
		if property_value1 == "all_like_*" then
			obs.obs_property_set_visible(all_like_input1, true)
		else
			obs.obs_property_set_visible(all_like_input1, false)
		end
		if property_value2 == "all_like_*" then
			obs.obs_property_set_visible(all_like_input2, true)
		else
			obs.obs_property_set_visible(all_like_input2, false)
		end
	end
	return true
end
function soure_list_view()
	local scene_name = obs.obs_data_get_string(APP_SETTINGS, "scene_name")
	local source_list = obs.obs_data_get_array(APP_SETTINGS, scene_name)
	if source_list == nil or obs.obs_data_array_count(source_list) <= 0 or scene_name == nil or scene_name == ""  then
		-- no source list
		return [[<h1>(SOURCE LIST)</h1>]] .. [[<strong style = 'color:#555'>The list is empty, right now.</strong>]]
	end
	
	local view = [[<h1>(SOURCE LIST)</h1>]];
	local len = obs.obs_data_array_count(source_list);
    -- show soure list;
	-- get all the sources in the array list; and display them to the label;
	local viewObject = ""
	local viewCount = 0
	for i = 0, len - 1 do
		local p_item = obs.obs_data_array_item(source_list,i)
		if p_item ~= nil then 
			local value = obs.obs_data_get_string(p_item,"key")
			local value_list = string_pipes(value)
			if #value_list >= 2 then --- (ACTION) command
				local scene_name = value_list[1];
				local action_name = value_list[2];
				if APP_ACTIONS:isOnAction(action_name) then
					local action_event = value_list[3]
					local action_target = value_list[4]
					local action_value = value_list[5]
					view = view .. [[<b style = 'color:#eee'>]] .. scene_name .. 
					[[</b> <span style = 'color:gray'>|</span> <span style = 'color:orange'>]] .. 
					action_name .. [[</span> <span style = 'color:gray'>|</span> <span style = 'color:yellow'>]] .. 
					action_event .. [[</span> <span style = 'color:gray'>|</span> <span style = 'color:green'>]] ..
					action_target .. [[</span> <span style = 'color:gray'>|</span> <span style = 'color:rgb(0,160,255)'>]] ..
					action_value .. [[</span><br/>]]
				elseif #value_list >= 4 then
					local action_target = value_list[3];
					local action_time = time_splitter(value_list[4]);
					local action_time_type = action_time.type;
					local action_random = action_time.order;
					action_time = action_time.value

					view = view .. [[<b style = 'color:#eee'>]] .. scene_name .. 
					[[</b> <span style = 'color:gray'>|</span> <span style = 'color:rgb(0,160,255)'>]] .. 
					action_name .. [[</span> <span style = 'color:gray'>|</span> <span style = 'color:yellow'>]] .. 
					action_target .. [[</span> <span style = 'color:gray'>|</span> <span style = 'color:pink'>]] .. 
					action_random .. [[</span> <span style = 'color:green'>]] .. tostring(action_time) .. action_time_type ..
					[[</span>]] .. [[<br/>]]
				else -- default
					view = view .. [[<b style = 'color:#eee'>]] .. scene_name .. 
					[[</b> <span style = 'color:gray'>|</span> <span style = 'color:orange'>]] .. 
					value_list[2] .. [[</span> <span style = 'color:gray'>|</span> <span style = 'color:rgb(0,160,255)'>]] ..
					value_list[3] .. [[</span><br/>]]
				end
			else -- object list
				-- check if the current data is above (defaults)
				local isDefault = false
				local def = ""
				for x = i + 1, len -1 do
					local p_item = obs.obs_data_array_item(source_list,x)
					if p_item ~= nil then 
						local value = obs.obs_data_get_string(p_item,"key")
						local value_list = string_pipes(value)
						if value_list and #value_list >= 3 then
							if value_list[2] == "default" then
								isDefault = true;def = value_list[3];break
							end
						end
					end
				end
				
				local objectName = ""
				for i = 1, #value do
					local char = string.sub(value, i, i)
					if char == "," then
						if objectName ~= "" and APP:HasObject(objectName) then
							if viewCount >= 4 then
								viewCount = 0
								viewObject = viewObject .. [[<br/>]]
							elseif viewCount > 0 then
								viewObject = viewObject .. [[<span style = 'color:#555'>,</span>]]
							end
							viewObject = viewObject .. [[<span><i><b style = 'color:darkgray'>]] .. objectName .. [[</b></i></span>]]
							if  isDefault then
								viewObject = viewObject .. [[<span style = 'color:pink'> (default:]] .. def .. [[) </span>]]
							end
							viewCount = viewCount + 1
						end
						objectName = ""
					else
						objectName = objectName .. char
					end
				end
				if objectName ~= "" and APP:HasObject(objectName) then
					if viewCount >= 4 then
						viewCount = 0
						viewObject = viewObject .. [[<br/>]]
					elseif viewCount > 0 then
						viewObject = viewObject .. [[<span style = 'color:#555'>,</span>]]
					end
					viewObject = viewObject .. [[<i><b style = 'color:darkgray'>]] .. objectName .. [[</b></i>]]
					if  isDefault then
						viewObject = viewObject .. [[<span style = 'color:pink'> (default:]] .. def .. [[) </span>]]
					end
					viewCount = viewCount + 1
				end
			end
		end
	end
	if viewObject ~= nil and viewObject ~= "" then
		viewObject = [[<strong style = 'color:#555'>(Program sources)</strong> {<div style = 'margin-left:40px'>]] .. viewObject ..
		[[</div>}]]
	end
	obs.obs_data_array_release(source_list)
	return view .. viewObject
end
function add_action(properties, property)
	APP_LOG("{Add Action}",APP_LOG_LVL)
	local scene_name = obs.obs_data_get_string(APP_SETTINGS, "scene_name")
	local action_name = obs.obs_data_get_string(APP_SETTINGS, "action_name")
	local action_target = obs.obs_data_get_string(APP_SETTINGS, "action_target")
	local action_time = obs.obs_data_get_int(APP_SETTINGS, "action_time")
	local action_random = obs.obs_data_get_bool(APP_SETTINGS, "action_rand")
	local action_time_type = "s";
	if action_time == "" or action_time == nil or action_time <= 0 then
		action_time = 1 -- default time (seconds)
	end
	if action_target == "all_like_*"  then
		action_target = obs.obs_data_get_string(APP_SETTINGS, "action_target_list_all_like_input")
		if action_target ~= nil and action_target ~= "" then
			action_target = "all_like_" .. action_target
		end
	end
	local warn_label = obs.obs_properties_get(properties, "action_warn_label")
	if action_name == "" or action_name == '<nil>' or action_name == nil or action_target == "<nil>" or action_name == '' or action_target == nil then
		obs.obs_property_set_visible(warn_label, true)
		obs.obs_property_set_description(warn_label,"Invalid selection")
		APP_LOG("{Add Action} some selection are require(*)", APP_LOG_WRN_LVL)
		return true
	end
	obs.obs_property_set_visible(warn_label, false)
	if action_random then
		action_random = "%"
	else
		action_random = ""
	end
	if action_time >= 60 then
		action_time_type = "m"
		action_time = math.floor(action_time / 60)
	end
	local action =  "[" .. scene_name .. "]|" .. action_name .. "|" .. action_target ..  "|" .. action_random .. tostring(action_time) .. action_time_type
	if not INSERT_INTO_OBS_ARRAY__(scene_name, action) then 
		APP_LOG("{Add Acton} Something awful happend! (to fix maybe restart the whole program)", APP_LOG_ERR_LVL)
		obs.obs_property_set_visible(warn_label, true)
		obs.obs_property_set_description(warn_label,"Unknown error!")
	else
		local op = obs.obs_properties_get(properties, "rm_ls_gp");
		obs.obs_property_set_visible(op, true)
	end
	local p_list = obs.obs_properties_get(properties, "hide_n_show_sources_label")
	obs.obs_property_set_description(p_list,soure_list_view())
	scene_modified(properties, property, nil)
	APP:initUpdate()
	return true
end
function add_event(properties, property) --- Adds on event action
	APP_LOG("{Add Event}",APP_LOG_LVL)
	local scene_name = obs.obs_data_get_string(APP_SETTINGS, "scene_name")
	local action_event = obs.obs_data_get_string(APP_SETTINGS, "event_name")
	local action_listen_target = obs.obs_data_get_string(APP_SETTINGS, "event_target")
	local action_name = obs.obs_data_get_string(APP_SETTINGS, "event_action_name")
	local action_target = obs.obs_data_get_string(APP_SETTINGS, "effect_target")
	
	if action_name == nil or action_name == "" then
		if action_event == "onshow" then
			action_name = "hide"
		else
			action_name = "show"
		end
	end
	if action_target == "all_like_*"  then
		action_target = obs.obs_data_get_string(APP_SETTINGS, "effect_target_list_all_like_input")
		if action_target ~= nil and action_target ~= "" then
			action_target = "all_like_" .. action_target
		end
	end
	local warn_label = obs.obs_properties_get(properties, "event_warn_label")
	
	if action_event == "<nil>" or action_event == '' or action_event == nil or action_listen_target == "<nil>" or action_listen_target == nil or action_listen_target == '' then
		obs.obs_property_set_visible(warn_label, true)
		obs.obs_property_set_description(warn_label,"Invalid selection")
		APP_LOG("{Add Event} some selection are require(*)", APP_LOG_WRN_LVL)
		
		return true;
	end
	obs.obs_property_set_visible(warn_label, false)
	local action =  "[" .. scene_name .. "]|" .. action_event .. "|" .. action_listen_target ..  "|" .. action_target .. "|" .. action_name
	if not INSERT_INTO_OBS_ARRAY__(scene_name, action) then 
		obs.obs_property_set_visible(warn_label, true)
		obs.obs_property_set_description(warn_label,"Unknown error!")
		APP_LOG("{Add Event} Something awful happend! (to fix maybe restart the whole program)", APP_LOG_ERR_LVL)
	else
		local op = obs.obs_properties_get(properties, "rm_ls_gp");
		obs.obs_property_set_visible(op, true)
	end
	local p_list = obs.obs_properties_get(properties, "hide_n_show_sources_label")
	obs.obs_property_set_description(p_list,soure_list_view(properties,property ))
	scene_modified(properties,property,nil)
	APP:initUpdate()
	return true
end


function remove_source_from_list(properties, property)
	local remove_target = obs.obs_data_get_string(APP_SETTINGS, "rm_ls_list")
	local scene_name = obs.obs_data_get_string(APP_SETTINGS, "scene_name")
	
	local source_list = obs.obs_data_get_array(APP_SETTINGS, scene_name)
	if source_list ~= nil then
		local c = obs.obs_data_array_count(source_list)
		local indexSource;
		for i = 0, c - 1 do
			local p_item = obs.obs_data_array_item(source_list,i)
			if p_item ~= nil then 
				local value = obs.obs_data_get_string(p_item,"key")
				if rplr_char(value,"|"," | ") == remove_target then
					indexSource = i;
					break
				end
			end
		end
		if indexSource ~= nil then
			APP_LOG("remove {" .. remove_target .. "} from source list", APP_LOG_LVL)
			obs.obs_data_array_erase(source_list, indexSource)
		else
			APP_LOG("unable to remove {" .. remove_target .. "} from source list", APP_LOG_ERR_LVL)
		end
		if obs.obs_data_array_count(source_list) <= 0 then
			local op = obs.obs_properties_get(properties, "rm_ls_gp");
			obs.obs_property_set_visible(op, false)
		end
		obs.obs_data_array_release(source_list)
	else
		APP_LOG("unable to remove {" .. remove_target .. "} from source list", APP_LOG_ERR_LVL)
	end
	scene_modified(properties, property)
	local p_list = obs.obs_properties_get(properties, "hide_n_show_sources_label")
	obs.obs_property_set_description(p_list,soure_list_view())
	APP:initUpdate()
	return true
end
function APP_LOG(message, mode)
	if LOG_LEVEL[mode] == nil then
		mode = LOG_LEVEL[2]
	else
		mode = LOG_LEVEL[mode]
	end
	if mode ~= "" then
		mode = " " .. mode
	end
	local prepend_header = "(Hide2Show" .. tostring(mode) .. ")"
	print(prepend_header .. " " .. message)
	return true
end
function APP_ACTIONS:has(_value)
    local status = false
    for _, iter_value in pairs(APP_ACTIONS) do
        if(type(iter_value) == "string") then
            if iter_value == _value then
                status = true
                break
            end
        end
    end
    return status
end
function APP_ACTIONS:isOnAction(_value)
    if(APP_ACTIONS:has(_value)) then
        -- search for on
        local x,y = string.find(_value, "on")
        if(type(x) == "number" and x > 0 and type(y) == "number" and y > 0) then
            return true;
        end
    end
    return false
end
function APP_ACTIONS:IsLikeAction(cmd) -- checks if (cmd) has a (all_like_*)
	if type(cmd) ~= "string" then
		return false
	end
	cmd = string.lower(cmd)
	local getList = string.gmatch(cmd, "[^_]+");
	local cmd_list = {}
	for x in getList do
		table.insert(cmd_list,x)
	end
	if #cmd_list >= 3 and cmd_list[1] == "all" and cmd_list[2] == "like" then
		return true;
	end
	return false;
end
function APP_ACTIONS:GetLikeAction(cmd) -- return like (target)
	if type(cmd) ~= "string" then
		return nil
	end
	cmd = string.lower(cmd)
	local getList = string.gmatch(cmd, "[^_]+");
	local cmd_list = {}
	for x in getList do
		table.insert(cmd_list,x)
	end
	if #cmd_list >= 3 and cmd_list[1] == "all" and cmd_list[2] == "like" then
		local act = ""
		for i = 3, #cmd_list do
			act = act .. cmd_list[i];
		end
		return act;
	end
	return nil;
end
function APP_ACTIONS:LikeActionMatch(act1, act2) -- checks if (act1) is include of (act2)
	if not (type(act1) == type(act2) and type(act1) == "string") then
		return false;
	end
	local param = "";
	for i = 1, #act2 do
		if #param == #act1 and param == act1 then
			return true;
		end
		param = param .. string.sub(act2,i,i);
		-- make sure each character matches (act1)
		if #param > #act1 then
			param = "";
		else
			for x = 1, #param do
				if string.sub(param, x, x) ~= string.sub(act1, x, x) then
					param = "";break;
				end
			end
		end
	end
	if #param == #act1 and param == act1 then
		return true;
	end
	return false;
end
function APP:HasObject(object_name)
	local __item = __GET_SCENE_ITEM__(object_name)
	if __item == nil then
		return false
	end
	obs.obs_sceneitem_release(__item)
	return true
end
APP.source = function(_source_name) -- returns a source(make sure to release!) if name given/and exists.
    return obs.obs_get_source_by_name(_source_name)
end
function rplr_char(str, char, rpr)
	if rpr == nil then
		rpr = ""
	end
	local newStr = ""
	for val in string.gmatch(str,".") do
		local charExist = false
		for valY in string.gmatch(char, ".") do
			if valY == val then
				charExist = true;break
			end
		end
		if not charExist then
			newStr = newStr .. val
		else 
			newStr = newStr .. rpr
		end
	end
	return newStr
end
function APP:initUpdate(_settings) -- executes every time the user interacts with (interface)
	for _, iter in ipairs(APP_CALLBACKS) do
        if type(iter) == "function" then
            obs.timer_remove(iter)
        end
    end
    for objectName, iter in pairs(APP_OBJECTS) do -- set defaults
        APP:show(objectName);
    end
    APP_CALLBACKS = {}
    APP_EVENT = {}
	APP_OBJECTS = {}
	APP_ON_EVENT = {
		onhide = {};
		onshow = {};
	};
	local scene_name = obs.obs_data_get_string(APP_SETTINGS, "scene_name")
	local __source_list_items__ = obs.obs_data_get_array(APP_SETTINGS, scene_name)
	if __source_list_items__ == nil then
		-- no source list
		return false
	end
	local source_list_count = obs.obs_data_array_count(__source_list_items__)
	-- get all the sources in the array list; and display them to the label;
    -- get the list and save them in (APP_EVENT) for later use.
    for iter_count = 0, source_list_count - 1 do
        local __iter__      = obs.obs_data_array_item(__source_list_items__, iter_count)
        local target_value   = obs.obs_data_get_string(__iter__, "key")
        if(target_value and target_value ~= "") then
            local commands = string_pipes(target_value)
            if commands and type(commands) == "table" and #commands > 1 then
				local scene_name = rplr_char(commands[1]:gsub("^%s*(.-)%s*$", "%1"), "[]")
                local action_name = string.lower(commands[2]:gsub("^%s*(.-)%s*$", "%1"))
                if APP_ACTIONS:has(action_name) then
                    local action_target = commands[3]:gsub("^%s*(.-)%s*$", "%1")
					if APP:HasObject(action_target) and APP_OBJECTS[action_target] == nil then
						APP_OBJECTS[action_target] = {
							isHidden = false;SKIP=false
						};
					end
                    --APP:show(action_target);
                    local action_timer = "1s"
                    local action_event_target = ""
                    local action_value = "";
                    if APP_ACTIONS:isOnAction(action_name) then
                        if #commands >= 4 then
                            action_event_target = commands[4]:gsub("^%s*(.-)%s*$", "%1")
							if APP:HasObject(action_event_target) and not APP_OBJECTS[action_event_target] then
								APP_OBJECTS[action_event_target] = {
									isHidden = false
								};
							end
							if #commands >= 5 then
                                action_value = string.lower(commands[5]:gsub("^%s*(.-)%s*$", "%1"))
                                if APP_ACTIONS:has(action_value) == false or APP_ACTIONS:isOnAction(action_value) then
                                    action_value = ""
                                end
                            end
                            if action_value == "" then
                                if action_name == "onhide" then
                                    action_value = "show"
                                else
                                    action_value = "hide"
                                end
                            end
                            table.insert(APP_EVENT, {
								actionScene = scene_name;
                                actionName = action_name;
                                actionTarget = action_target;
                                actionEvent = action_event_target;
                                actionValue = action_value;
                            })
                        end
                    else
                        if #commands >= 4 then
                            action_timer = commands[4]:gsub("^%s*(.-)%s*$", "%1")
                        end
                        table.insert(APP_EVENT,#APP_EVENT + 1, {
							actionScene = scene_name;
                            actionName = action_name;
                            actionTarget = action_target;
                            actionTimer = time_splitter(action_timer);
                        });
                    end
                else -- read defaults;
                    if action_name == "default" and iter_count > 0 and #commands > 1 then
                        local action_value = commands[3]:gsub("^%s*(.-)%s*$", "%1");
                        local temp_count = iter_count - 1;
                        while (temp_count >=0) do
                            local __prev_iter      = obs.obs_data_array_item(__source_list_items__,temp_count)
                            local cmd_value   = obs.obs_data_get_string(__prev_iter, "key")
                            local cmd_list = string_pipes(cmd_value)
                            local scene_name = ""
                            local a_n = ""  
                            if cmd_list and #cmd_list >= 2 then
								scene_name = rplr_char(cmd_list[1]:gsub("^%s*(.-)%s*$", "%1"), "[]")
								a_n = string.lower(cmd_list[2]:gsub("^%s*(.-)%s*$", "%1"));
							end
                            -- check action types; apply the defaults to the target;
                            if APP_ACTIONS:has(a_n) then
                                local a_t = "";
                                if APP_ACTIONS:isOnAction(a_n) and #cmd_list >= 4 then
                                    a_t = cmd_list[4]:gsub("^%s*(.-)%s*$", "%1");
                                elseif not APP_ACTIONS:isOnAction(a_n) and #cmd_list >= 3 then
                                    a_t = cmd_list[3]:gsub("^%s*(.-)%s*$", "%1"); 
                                end

                                if action_value == "hide" then
                                    APP:hide(a_t);
									if APP_OBJECTS[a_t] ~= nil then
										APP_OBJECTS[a_t]["isHidden"] = true;
									end
                                elseif action_value == "show" then
                                    APP:show(a_t);
									if APP_OBJECTS[a_t] ~= nil then
										APP_OBJECTS[a_t]["isHidden"] = false;
									end
                                end
							else -- set defaults to object list
								local objectName = "";
								for x = 1,#cmd_value do
									local charx = string.sub(cmd_value, x, x);
									
									if charx == "," then
										-- store the current object it found;
										if action_value == "hide" then
											APP:hide(objectName);
											if APP_OBJECTS[objectName] ~= nil then
												APP_OBJECTS[objectName]["isHidden"] = true;
											end
										elseif action_value == "show" then
											APP:show(objectName);
											if APP_OBJECTS[objectName] ~= nil then
												APP_OBJECTS[objectName]["isHidden"] = false;
											end
										end
										objectName = "";
									else
										objectName = objectName .. charx;
									end
									objectName = objectName:gsub("^%s*(.-)%s*$", "%1");
								end
								if objectName ~= "" then
									-- store the current object it found;
									if action_value == "hide" then
										APP:hide(objectName);
										if APP_OBJECTS[objectName] ~= nil then
											APP_OBJECTS[objectName]["isHidden"] = true;
										end
									elseif action_value == "show" then
										APP:show(objectName);
										if APP_OBJECTS[objectName] ~= nil then
											APP_OBJECTS[objectName]["isHidden"] = false;
										end
									end
								end
                            end
                            obs.obs_data_release(__prev_iter);
                            if temp_count <= 0 or a_n == "default" then
                                break;
                            end
                            temp_count = temp_count - 1;
                        end
                    end
                end
			else
				-- store Objects;
				local objectName = "";
				for i = 1,#target_value do
					local charx = string.sub(target_value, i, i);
					
					if charx == "," then
						-- store the current object it found;
						if not APP_OBJECTS[objectName] then
							APP_OBJECTS[objectName] = {
								isHidden = false;SKIP=false
							};
						end
						objectName = "";
					else
						objectName = objectName .. charx;
					end
					objectName = objectName:gsub("^%s*(.-)%s*$", "%1");
				end
				if objectName ~= "" then
					-- store the current object it found;
					if not APP_OBJECTS[objectName] then
						APP_OBJECTS[objectName] = {
							isHidden = false;SKIP=false
						};
					end
				end
				
            end
        end
        obs.obs_data_release(__iter__)
    end
    obs.obs_data_array_release(__source_list_items__)
    -- [DEBUG LOG]
	--[[
    -- OUTPUT => (APP_OBJECTS)
    for key,  iter in pairs(APP_OBJECTS) do
		print("(APP_OBJECTS) item: " .. tostring(key) .. " count: " .. tostring(#key));
		for x, y in pairs(iter) do
			print("(APP_OBJECTS item) " .. tostring(x) .. " => " .. fixLog(y))
		end
	end
	-- OUTPUT => (APP_EVENT)
	for _, iter in ipairs(APP_EVENT) do
		for key, val in pairs(iter) do
			print("(APP_EVENT) " .. tostring(key) .. " => " .. fixLog(val));
		end
	end]]
    APP:Enable()
end
function fixLog(iter)
	local v = ""
	if type(iter) == "table" then
		for x, y in pairs(iter) do
			if type(x) == "string" then
				v = v .. tostring(x) .. ": " .. fixLog(y) .. " "
			else
				v = v .. fixLog(y) .. " "
			end
		end
		return v
	elseif type(iter) == "function" then
		return "(function)";
	else
		return tostring(iter)
	end
end
function time_splitter(_time_value)
    local time_list = {type="s";value=1;order=""};
    if _time_value == nil then
		return time_list
    end
    local value1 = ""
    local value2 = "";
    for x in string.gmatch(_time_value,".") do
        if(tonumber(x) ~= nil) then
            value1 = value1 .. x
        elseif x == "%" then
            time_list.order = "%"
        else
            value2 = value2 .. x;
        end
    end
	value2 = string.lower(value2)
	if value2 ~= "m" and value2 ~= "s" then
		value2 = ""
	end
    value1 = tonumber(value1)
    time_list.type = value2;
    time_list.value = value1;
	
    return time_list
end

function APP:setEnable(source_name, enable)
	if source_name == nil or (not type(source_name) == "string") or source_name == ""  then
		return false
	end
	local __item = __GET_SCENE_ITEM__(source_name)
    if __item ~= nil then
		obs.obs_sceneitem_set_visible(__item, enable)
		obs.obs_sceneitem_release(__item)
	end
    return true
end
function APP:hide(sourceName)
	if APP_OBJECTS[sourceName] ~= nil then
		APP_OBJECTS[sourceName]["isHidden"] = true;
	end
    return APP:setEnable(sourceName, false)
end
function APP:show(sourceName)
	if APP_OBJECTS[sourceName] ~= nil then
		APP_OBJECTS[sourceName]["isHidden"] = false;
	end
    return APP:setEnable(sourceName, true)
end
-- Enables the program
function APP:Enable()
    -- add new callbacks
    for _, iter in ipairs(APP_EVENT) do
        --spawn(function()
            local action_name = iter.actionName
            if APP_ACTIONS:has(action_name) then
                local action_target = iter.actionTarget:gsub("^%s*(.-)%s*$", "%1")
                --APP:show(action_target);
                local action_event_target;
                local action_timer;
                local action_value;
                if APP_ACTIONS:isOnAction(action_name) then
                    --APP:hide(iter.actionEvent)
                    action_value = iter.actionValue
                    action_event_target = iter.actionEvent:gsub("^%s*(.-)%s*$", "%1")
                    if APP_ON_EVENT[action_name] ~= nil then
                        if APP_ON_EVENT[action_name][action_target] == nil then
                            APP_ON_EVENT[action_name][action_target] = {}
                        end
                        table.insert(APP_ON_EVENT[action_name][action_target], #APP_ON_EVENT[action_name][action_target] + 1, function()
							
							if action_value == "hide" then
								-- hide the target
								if action_event_target == "all" then
									-- hide all objects;
									for objectName, iter in pairs(APP_OBJECTS) do
										if objectName ~= action_target then	
											APP:hide(objectName);
										end
									end
								elseif APP_ACTIONS:IsLikeAction(action_event_target) then
									-- hide all objects that matches a like option;
									local likeAct = APP_ACTIONS:GetLikeAction(action_event_target);
									for objectName, iter in pairs(APP_OBJECTS) do
										if APP_ACTIONS:LikeActionMatch(likeAct, objectName) and objectName ~= action_target then
											APP:hide(objectName);
										end
									end
								else
									APP:hide(action_event_target)
								end
                            elseif action_value == "show" then
                                -- show the target
								if action_event_target == "all" then
									-- show all objects;
									for objectName, iter in pairs(APP_OBJECTS) do
										if objectName ~= action_target then 
											APP:show(objectName);
										end
									end
								elseif APP_ACTIONS:IsLikeAction(action_event_target) then
									-- show all objects that matches a like option;
									local likeAct = APP_ACTIONS:GetLikeAction(action_event_target);
									for objectName, iter in pairs(APP_OBJECTS) do
										if APP_ACTIONS:LikeActionMatch(likeAct, objectName) and objectName ~= action_target then
											APP:show(objectName);
										end
									end
								else
									APP:show(action_event_target)
								end
                            end
                        end)
                    end
                else
                    action_timer = iter.actionTimer
                    local action_timer_type = action_timer.type
                    local action_timer_order = action_timer.order
                    local action_timer_value = action_timer.value
                    local min = 1
                    local max = nil
                    local function init_timer()
                        if action_timer_order == "%" and action_timer_value > 1 then
                            max = math.random(1, action_timer_value)
                        else
                            max = action_timer_value
                            
                        end
                        if action_timer_type == "m" then
							max = max * 60
						end
                        min = 1;
                    end
                    init_timer()
                    table.insert(APP_CALLBACKS, #APP_CALLBACKS + 1, function()
						if LinearBehavior then
							if action_name == "hide" then
								if action_target == "all" or APP_ACTIONS:IsLikeAction(action_target) then
									local SkipExe = false
									if APP_ACTIONS:IsLikeAction(action_target) then
										local likeAct = APP_ACTIONS:GetLikeAction(action_target)
										for objectName,iter in pairs(APP_OBJECTS) do
											if APP_ACTIONS:LikeActionMatch(likeAct,objectName) and APP_OBJECTS[objectName].isHidden then
												SkipExe = true;break
											elseif APP_ACTIONS:LikeActionMatch(likeAct, objectName) and APP_OBJECTS[objectName] and APP_OBJECTS[objectName].SKIP then
												APP_OBJECTS[objectName].SKIP = false
												SkipExe = true;
											end
										end
									else
										for objectName,iter in pairs(APP_OBJECTS) do
											if APP_OBJECTS[objectName].isHidden then
												APP_OBJECTS[objectName].SKIP=false
												SkipExe = true;break
											elseif APP_OBJECTS[objectName] and APP_OBJECTS[objectName].SKIP then
												APP_OBJECTS[objectName].SKIP = false
												SkipExe = true;
											end
										end
									end
									if SkipExe then
										min = 1
										return
									end
								elseif APP_OBJECTS[action_target] and APP_OBJECTS[action_target].isHidden then
									min = 1
									return
								elseif APP_OBJECTS[action_target] and APP_OBJECTS[action_target].SKIP then
									APP_OBJECTS[action_target].SKIP = false;
									min = 1
									return
								end
							elseif action_name == "show" then
								if action_target == "all" or APP_ACTIONS:IsLikeAction(action_target) then
									local SkipExe = false
									if APP_ACTIONS:IsLikeAction(action_target) then
										local likeAct = APP_ACTIONS:GetLikeAction(action_target)
										for objectName,iter in pairs(APP_OBJECTS) do
											if APP_ACTIONS:LikeActionMatch(likeAct,objectName) and APP_OBJECTS[objectName] and not APP_OBJECTS[objectName].isHidden then
												SkipExe = true;break
											elseif APP_ACTIONS:LikeActionMatch(likeAct,objectName) and APP_OBJECTS[objectName] and APP_OBJECTS[objectName].SKIP then
												APP_OBJECTS[objectName].SKIP = false
												SkipExe = true;
											end
										end
									else
										for objectName,iter in pairs(APP_OBJECTS) do
											if APP_OBJECTS[objectName] and not APP_OBJECTS[objectName].isHidden then
												SkipExe = true;break
											elseif APP_OBJECTS[objectName] and APP_OBJECTS[objectName].SKIP then
												APP_OBJECTS[objectName].SKIP = false
												SkipExe = true
											end
										end
									end
									if SkipExe then
										min = 1
										return
									end
								elseif APP_OBJECTS[action_target] and not APP_OBJECTS[action_target].isHidden then
									min = 1
									return
								elseif APP_OBJECTS[action_target] and APP_OBJECTS[action_target].SKIP then
									APP_OBJECTS[action_target].SKIP = false;
									min = 1
									return
								end
							end
						end
                    	if min >= max then
							if LinearBehavior and action_target ~= "all" and not APP_ACTIONS:IsLikeAction(action_target) and APP_OBJECTS[action_target] then
								APP_OBJECTS[action_target].SKIP = true
							end
							if action_name == "hide" then -- (HIDE) object
								if action_target == "all" then -- hide all objects;
									for objectName, v in pairs(APP_OBJECTS) do
										APP:hide(objectName)
										if LinearBehavior and APP_OBJECTS[objectName] then
											APP_OBJECTS[objectName].SKIP = true
										end
										
									end
								elseif APP_ACTIONS:IsLikeAction(action_target) then
									local likeAct = APP_ACTIONS:GetLikeAction(action_target);
									for objectName in pairs(APP_OBJECTS) do
										if APP_ACTIONS:LikeActionMatch(likeAct, objectName) then
											APP:hide(objectName)
											if LinearBehavior and APP_OBJECTS[objectName] then
												APP_OBJECTS[objectName].SKIP = true
											end
										end
									end
								else -- default
									APP:hide(action_target)
									-- handle event calls
									if APP_ON_EVENT["onhide"][action_target] ~= nil then
										for _, iter_fnc in ipairs(APP_ON_EVENT["onhide"][action_target]) do
											iter_fnc();
										end
									end
								end
							elseif action_name == "show" then -- (SHOW) object
								if action_target == "all" then
									for objectName in pairs(APP_OBJECTS) do
										APP:show(objectName)
										if LinearBehavior and APP_OBJECTS[objectName] then
											APP_OBJECTS[objectName].SKIP = true
										end
									end
								elseif APP_ACTIONS:IsLikeAction(action_target) then
									local likeAct = APP_ACTIONS:GetLikeAction(action_target);
									for objectName in pairs(APP_OBJECTS) do
										if APP_ACTIONS:LikeActionMatch(likeAct, objectName) then
											APP:show(objectName)
											if LinearBehavior and APP_OBJECTS[objectName] then
												APP_OBJECTS[objectName].SKIP = true
											end
										end
									end
								else -- default
									APP:show(action_target)
									-- handle event calls
									if APP_ON_EVENT["onshow"][action_target] ~= nil then
										for _, iter_fnc in ipairs(APP_ON_EVENT["onshow"][action_target]) do
											iter_fnc();
										end
									end
								end
							end
							init_timer()
							
							return
						end
						min = min + 1
                    end)
                    obs.timer_add(APP_CALLBACKS[#APP_CALLBACKS],1000)
                end
            end
        --end)
    end
end
-- Disables the progam
function APP:Disable()
    for _, iter in ipairs(APP_CALLBACKS) do
        if type(iter) == "function" then
            obs.timer_remove(iter)
        end
    end
    for _, iter in ipairs(APP_EVENT) do -- set defaults
        APP:show(iter);
    end
    APP_CALLBACKS = {}
end
function string_pipes(string_value)
    local pipes = {}
    local whole = ""
    for char in string.gmatch(string_value,".") do
        if char == "|" then
            if whole ~= "" then
                table.insert(pipes, whole)
            end
            whole = ""
        else
            whole = whole ..  char
        end
    end
    if whole ~= "" then
        table.insert(pipes, whole)
    end
    return pipes;
end

-- END OF USER DEFINED OPERATIONS

