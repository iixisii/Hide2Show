--[[
	⚪ Title: HIDE & SHOW
	⚪ Version: v4
	⚪ Date: 5.27.23
	⚪ Author: iixisii
	
	Description: [
		The script is designed to work with OBS (Open Broadcaster Software), which is commonly used for streaming and recording videos.
		The purpose of this script is to allow users to hide or show any source or object within OBS at any desired time.
		By using this script, you can easily control the visibility of different elements in your video streams or recordings.
		If you are interested in learning more about the script or obtaining it, you can visit the following link: https://obsproject.com/forum/resources/hide-show.1560/
	]
]]
obs = obslua
__settings__ = nil
prset_gnames_ls = {
	"action_setup_group",
	"conditional_setup_group"
}; prset_action_ls = {
	"<hide>", "<show>","<end>",
	"<blink>", "<reset>"
}; prset_flb_ls = {
	"<text>", "<play>", "<pause>",
	"<is hidden>","<is shown>","<ended>"
}; prset_source_ls = {
	"<all>", "<all_like>",
	"<rand>","<rand_like>",
}; action_list = {
	{name = "Hide & Show"; id = "hns"},
	{name = "Onshow (Event)"; id = "es"},
	{name = "Onhide (Event)"; id = "eh"},
	{name = "Onend (Event)"; id = 'ee'},
}; hns_list = {
	{ name = "Action (default)"; id = "hns"},
	{ name = "Conditional"; id = "cl"},
	{ name = "Operational"; id = "opl"}

}; hns_cond_list = {
	{ name = "<When>"; id = "cdwn"}, { name = "<If>"; id ="cdf"},
}; app_time_option = {
	{name = "Milliseconds"; id = "mis"},
	{name = "Seconds"; id = "sc"},
	{name = "Minutes"; id = "ms"},
	{name = "Hours"; id = "hr"}
}; hns_opera_list = {
	{name = "CLI (mode)"; id = "cm"},
	{name = "Delete (mode)"; id = "dm"}
}; LOG_LEVEL = {
	[1] = "DEBUG";[2] = "";
	[3] = "WARNING";[4] = "ERROR";
}; APP = {}
objp_config = nil; objp = nil;
objp_op = nil; objp_ops = nil; operaOp = nil
actionOp = nil; configureOp = nil;
operaScreenOp = nil
APP_SETTINGS_UPD_FNC = nil
APP_INTER_STATE = 0
APP_STREAMING_ACTIVE = false
APP_RECORDING_ACTIVE = false
APP_LOG_LVL = 2
APP_LOG_DB_LVL = 1
APP_LOG_WRN_LVL = 3
APP_LOG_ERR_LVL= 4
APP_LOG_NRM_LVL = 2
OPERATIONAL_INDEX = nil
OPERATIONAL_TYPE = nil
currSceneName = ""
APP_ACTIONS = {}
__GLOBAL_CLIENT_EVENT = nil

function script_properties()
	APP_INTER_STATE = APP_INTER_STATE + 1
	-- default settings;
	if __settings__ ~= nil then
		obs.obs_data_set_string(__settings__, "action_list", "<none>")
		obs.obs_data_set_string(__settings__, "source_list", "<none>")
	end
	
	objp = obs.obs_properties_create(); objp_config = 
	obs.obs_properties_create(); objp_op = 
	obs.obs_properties_create(); objp_ops = 
	obs.obs_properties_create(); actionOp = 
	obs.obs_properties_create(); configureOp = 
	obs.obs_properties_create(); operaOp = obs.obs_properties_create()
	-- [[ Welcome Box ]]
		--local top = obs.obs_properties_add_text(objp, "top", "", obs.OBS_TEXT_INFO)
		--obs.obs_property_set_description(top, welcomeIndex())
	-- [[ Error Label ]
		local action_setup_error_label = obs.obs_properties_add_text(objp, "action_setup_error_label","", obs.OBS_TEXT_INFO)
		obs.obs_property_text_set_info_type(action_setup_error_label, obs.OBS_TEXT_INFO_ERROR)
		obs.obs_property_set_visible(action_setup_error_label, false)
	-- [[ Source List ]]
		local obj_source_list = obs.obs_properties_add_list(objp, "source_list", "Source:", obs.OBS_COMBO_TYPE_LIST, obs.OBS_COMBO_FORMAT_STRING)
		obs.obs_property_set_modified_callback(obj_source_list, SourceListUpdate)
	-- [[ Input Text ]]
		local action_obj_text = obs.obs_properties_add_text(objp, "obj_setting_text","Enter text", obs.OBS_TEXT_DEFAULT)
		obs.obs_property_set_visible(action_obj_text, false)
		
	-- add all the sources
	TargetSourceListInit(objp)
	-- [[ Configure List ]]
		local obj_setting_list = obs.obs_properties_add_list(objp, "obj_setting_list", "Configure:", obs.OBS_COMBO_TYPE_LIST, obs.OBS_COMBO_FORMAT_STRING)
		obs.obs_property_set_visible(obj_config_g, true)
		obs.obs_property_set_description(obj_config_g, "Hide && Show (Setup)")
		-- Setup The Configure list;
		obs.obs_property_list_add_string(obj_setting_list, "Select to begin", "<none>");
		for _, iter in pairs(hns_list) do
			obs.obs_property_list_add_string(obj_setting_list, iter.name, iter.id)
		end
		obs.obs_property_set_modified_callback(obj_setting_list, SettingsList)
	-- [[ Action Group ]]
		action_setup_group = obs.obs_properties_add_group(objp, "action_setup_group","Action (Setup)", obs.OBS_GROUP_NORMAL, actionOp)
		-- Select target scene;
		local action_setup_scene_list = obs.obs_properties_add_list(actionOp, "action_setup_scene_list", "<b style = 'color:lime'>Scope</b>:", obs.OBS_COMBO_TYPE_LIST, obs.OBS_COMBO_FORMAT_STRING)
		obs.obs_property_list_add_string(action_setup_scene_list, "global (default)", "<none>")
		obs.obs_property_set_long_description(action_setup_scene_list, "What scene do you want to execute this instruction for (default is global; meaning every scene)")
		obs.obs_property_set_visible(action_setup_group, false)
	
	
	-- [[ Configure Group ]]
		config_cond_item = obs.obs_properties_add_group(objp, "conditional_setup_group","Conditional (Setup)", obs.OBS_GROUP_NORMAL, configureOp)
		-- Select target scene;
		local conditional_setup_scene_list = obs.obs_properties_add_list(configureOp, "conditional_setup_scene_list", "<b style = 'color:lime'>Scope</b>:", obs.OBS_COMBO_TYPE_LIST, obs.OBS_COMBO_FORMAT_STRING)
		obs.obs_property_list_add_string(conditional_setup_scene_list, "global (default)", "<none>")
		obs.obs_property_set_long_description(conditional_setup_scene_list, "What scene do you want to execute this instruction for (default is global; meaning every scene)")
		obs.obs_property_set_visible(config_cond_item, false)
	
	-- [[ Operational Group ]]
		local opera_group =	obs.obs_properties_add_group(objp, "opera_setup_group","Operational (Setup)", obs.OBS_GROUP_NORMAL, operaOp)
		local opera_setup_group_operation_label = obs.obs_properties_add_text(operaOp, "opera_setup_group_operation_label", "", obs.OBS_TEXT_INFO)
		local opera_list = obs.obs_properties_add_list(operaOp, "opera_setup_group_list", "Mode", obs.OBS_COMBO_TYPE_LIST, obs.OBS_COMBO_FORMAT_STRING)
		local opera_target_list = obs.obs_properties_add_list(operaOp, "opera_setup_group_target_list", "Filter (Optional)", obs.OBS_COMBO_TYPE_LIST, obs.OBS_COMBO_FORMAT_STRING)
		local opera_in_list = obs.obs_properties_add_list(operaOp, "opera_setup_group_operation_list", "Operations", obs.OBS_COMBO_TYPE_LIST, obs.OBS_COMBO_FORMAT_STRING)
		local opera_setup_group_cl = obs.obs_properties_add_text(operaOp, "opera_setup_group_cl", "", obs.OBS_TEXT_MULTILINE)
		local opera_setup_group_cl_btn = obs.obs_properties_add_button(operaOp, "opera_setup_group_cl_btn", "Execute", function(properties, prop)
			return COMMAND_PROMPT(properties, prop)
		end)
		-- Edit Button;
		--[[
			local opera_edit_btn = obs.obs_properties_add_button(operaOp, "opera_setup_group_edit_btn", "Edit 🖊", function(properties, prop)
				OPERATIONAL_TYPE = 2
				local operation = obs.obs_data_get_string(__settings__, "opera_setup_group_operation_list")
				local label = obs.obs_properties_get(properties, "opera_setup_group_operation_label")
				obs.obs_property_set_visible(label, false)
				if operation == nil or operation == "" or operation == "<none>" then
					obs.obs_property_set_visible(label, true)
					obs.obs_property_set_description(label, "<b style = 'color:red'>Warning: make sure operation is selected!</b>")
					return true
				end
				-- Edit
					local t = operation
					operation = splitBy(operation, "+")
					local scope = splitBy(operation[1],"|")[1]
					if operation then
						local fl = splitBy(operation[1],"|")
						local op = ""
						for i = 2, #fl do
							if op ~= "" then
								op =  op .. "|" .. fl[i]
							else
								op = fl[i]
							end
						end
						operation[1] = op
					end
					
					if(scope == "(global)") then 
						scope = "__HActionListS__"
					else
						scope = rplr_char(scope, "()", "")
					end
					local arrlist = obs.obs_data_get_array(__settings__,scope)
					if arrlist then
						local len = obs.obs_data_array_count(arrlist)
						local newArr = obs.obs_data_array_create()
						for i = 0, len - 1 do
							local pitem = obs.obs_data_array_item(arrlist, i)
							if pitem then
								local data = obs.obs_data_get_string(pitem, "key")
								if data == operation[1] then elseif #operation == 2 and operation[2] == data then else
									local newPitem = obs.obs_data_create()
									obs.obs_data_set_string(newPitem, "key", data)
									obs.obs_data_array_push_back(newArr, newPitem)
									obs.obs_data_release(newPitem)
								end
								obs.obs_data_release(pitem)
							end
						end
						obs.obs_property_set_visible(label, true)
						obs.obs_data_array_release(arrlist)
						obs.obs_data_set_array(__settings__, scope, newArr)
						obs.obs_data_array_release(newArr)
						
						OperationalInitEditor(properties, nil, __settings__); OperationalInitReset(properties)
						local op_list1 = splitBy(operation[1], "|")
						if op_list1[1] == "<act>" then
							obs.obs_data_set_string(__settings__, "obj_setting_list", "hns")
							obs.obs_data_set_string(__settings__, "source_list", op_list1[3])
							SettingsList(properties, nil, __settings__)
							ActionSetup(properties,nil, __settings__)
							if scope == "__HActionListS__" then
								obs.obs_data_set_string(__settings__, "action_setup_scene_list", "<gf>")
							elseif scope == currSceneName then
								obs.obs_data_set_string(__settings__, "action_setup_scene_list", "<default>")
							else
								obs.obs_data_set_string(__settings__, "action_setup_scene_list",scope)
							end
							
							-- setup hide;
							local time1 = time_splitter(op_list1[4])
							obs.obs_data_set_int(__settings__, "action_setup_group_hide_time", time1.value)
							obs.obs_data_set_string(__settings__, "action_setup_group_hide_time_option",time1.type)
							if time1.order == "%" then
								obs.obs_data_set_bool(__settings__, "action_setup_group_hide_time_rand", true)
							end
							local trepeat1 = op_list1[5]
							if trepeat1 and trepeat1 ~= "<inf>" then
								obs.obs_data_set_string(__settings__, "action_setup_group_repeat", "<cus>")
								trepeat1 = tonumber(rplr_char(trepeat1, "x"))
								obs.obs_data_set_int(__settings__, "action_setup_group_repeat_number", trepeat1)
								local action_setup_group_repeat_number = obs.obs_properties_get(properties, "action_setup_group_repeat_number")
								
								local treset1 = op_list1[6]
								if treset1 then
									treset1 = time_splitter(treset1)
									obs.obs_data_set_int(__settings__, "action_setup_group_repeat_time", treset1.value)
									if treset1.order == "%" then
										obs.obs_data_set_bool(__settings__, "action_setup_group_repeat_rand", true)
									end
									obs.obs_data_set_string(__settings__, "action_setup_group_repeat_option", treset1.type)
								end
								local action_setup_group_repeat_time = obs.obs_properties_get(properties, "action_setup_group_repeat_time")
								local action_setup_group_repeat_rand = obs.obs_properties_get(properties, "action_setup_group_repeat_rand")
								local action_setup_group_repeat_option = obs.obs_properties_get(properties, "action_setup_group_repeat_option")
								obs.obs_property_set_visible(action_setup_group_repeat_time, true)
								obs.obs_property_set_visible(action_setup_group_repeat_number, true)
								obs.obs_property_set_visible(action_setup_group_repeat_rand, true)
								obs.obs_property_set_visible(action_setup_group_repeat_option, true)
							end
							
							-- setup show;
							local op_list2 = splitBy(operation[2], "|")
							local time2 = time_splitter(op_list2[4])
							obs.obs_data_set_int(__settings__, "action_setup_group_show_time", time2.value)
							obs.obs_data_set_string(__settings__, "action_setup_group_show_time_option",time2.type)
							if time2.order == "%" then
								obs.obs_data_set_bool(__settings__, "action_setup_group_show_time_rand", true)
							end
							local trepeat2 = op_list2[5]
							if trepeat2 and trepeat2 ~= "<inf>" then
								obs.obs_data_set_string(__settings__, "action_setup_group_repeat", "<cus>")
								trepeat2 = tonumber(rplr_char(trepeat2, "x"))
								obs.obs_data_set_int(__settings__, "action_setup_group_repeat_number", trepeat2)
								local treset2 = op_list2[6]
								if treset2 then
									treset2 = time_splitter(treset2)
									obs.obs_data_set_int(__settings__, "action_setup_group_repeat_time", treset2.value)
									if treset2.order == "%" then
										obs.obs_data_set_bool(__settings__, "action_setup_group_repeat_rand", true)
									end
									obs.obs_data_set_string(__settings__, "action_setup_group_repeat_option", treset2.type)
								end
							end
							
						elseif op_list1[1] == "<cond>" then
							obs.obs_data_set_string(__settings__, "obj_setting_list", "cl")
							obs.obs_data_set_string(__settings__, "source_list", op_list1[5])
							SettingsList(properties, nil, __settings__)
							ConfigureSetup(properties,nil, __settings__)
							
							
							if scope == "__HActionListS__" then
								obs.obs_data_set_string(__settings__, "conditional_setup_scene_list", "<gf>")
							elseif scope == currSceneName then
								obs.obs_data_set_string(__settings__, "conditional_setup_scene_list", "<default>")
							else
								obs.obs_data_set_string(__settings__, "conditional_setup_scene_list",scope)
							end
							obs.obs_data_set_string(__settings__, "conditional_setup_group_statement_list", op_list1[2])
							ConditionalStatementInit(properties, nil, __settings__)
							
							obs.obs_data_set_string(__settings__, "conditional_setup_group_target_list", op_list1[3])
							obs.obs_data_set_string(__settings__, "conditional_setup_group_action_value", op_list1[#op_list1])
							obs.obs_data_set_string(__settings__, "conditional_setup_group_fall_list", op_list1[6])
							obs.obs_data_set_string(__settings__, "conditional_setup_group_action_list", op_list1[4])
							if op_list1[4] == "<text>" then
								local conditional_setup_group_action_value = obs.obs_properties_get(properties, "conditional_setup_group_action_value")
								obs.obs_property_set_visible(conditional_setup_group_action_value, true)
							end
						end
						
						
						init()
						InitScreen(properties, nil, __settings__)
						obs.obs_property_set_visible(label, false)
					end
					return true
			end)
		]]
		-- Delete Button
		local opera_delete_btn = obs.obs_properties_add_button(operaOp, "opera_setup_group_delete_btn", "Delete 🗑", function(properties, prop)
			OPERATIONAL_TYPE = 2
			local operation = obs.obs_data_get_string(__settings__, "opera_setup_group_operation_list")
			local label = obs.obs_properties_get(properties, "opera_setup_group_operation_label")
			obs.obs_property_set_visible(label, false)
			if operation == nil or operation == "<none>" then
				obs.obs_property_set_visible(label, true)
				obs.obs_property_set_description(label, [[
					<b style = 'color:red'>Warning: make sure operation is selected!</b>
				]]);
				return true
			end
			-- [[ Delete ]]
				local t = operation
				local scope = splitBy(operation,"|")[1]
				if operation then
					local fl = splitBy(operation,"|")
					local op = ""
					for i = 2, #fl do
						if op ~= "" then
							op =  op .. "|" .. fl[i]
						else
							op = fl[i]
						end
					end
					operation = op
				end
				
				if(scope == "(global)") then 
					scope = "__HActionListS__"
				else
					scope = rplr_char(scope, "()", "")
				end
				local arrlist = obs.obs_data_get_array(__settings__,scope)
				if arrlist then
					local len = obs.obs_data_array_count(arrlist)
					local newArr = obs.obs_data_array_create()
					for i = 0, len - 1 do
						local pitem = obs.obs_data_array_item(arrlist, i)
						if pitem then
							local data = obs.obs_data_get_string(pitem, "key")
							if data == operation then else
								local newPitem = obs.obs_data_create()
								obs.obs_data_set_string(newPitem, "key", data)
								obs.obs_data_array_push_back(newArr, newPitem)
								obs.obs_data_release(newPitem)
							end
							obs.obs_data_release(pitem)
						end
					end
					obs.obs_property_set_visible(label, true)
					obs.obs_data_array_release(arrlist)
					obs.obs_data_set_array(__settings__, scope, newArr)
					obs.obs_data_array_release(newArr)
					
					OperationalInitEditor(properties, nil, __settings__)
					init()
					obs.obs_property_set_description(label, [[
						<strong style = 'color:orange'>Operation successfully deleted!</strong>
					]]);
				end
				
			return true
		end)
		local opera_reset_btn = obs.obs_properties_add_button(operaOp, "opera_setup_group_reset_btn", "Refresh 🔄", APP_RESET)
		
		-- [[ Operational Callback]]
			obs.obs_property_set_modified_callback(opera_list, function(properties, property, settings_)
				if settings_ == nil then return false end
				local mode = obs.obs_data_get_string(settings_, "opera_setup_group_list")
				local targetList = obs.obs_properties_get(properties, "opera_setup_group_target_list")
				local ops_in = obs.obs_properties_get(properties, "opera_setup_group_operation_list")
				local delete = obs.obs_properties_get(properties, "opera_setup_group_delete_btn")
				local clBtn = obs.obs_properties_get(properties, "opera_setup_group_cl_btn")
				local cl = obs.obs_properties_get(properties, "opera_setup_group_cl")
				local label = obs.obs_properties_get(properties, "opera_setup_group_operation_label")
				obs.obs_property_set_visible(targetList, false)
				obs.obs_property_set_visible(label, false)
				obs.obs_property_set_visible(cl, false)
				obs.obs_property_set_visible(ops_in, false)
				obs.obs_property_set_visible(delete, false)
				obs.obs_property_set_visible(clBtn, false)
				obs.obs_property_set_description(label, "")
				OPERATIONAL_TYPE = nil
				if mode == nil or mode == "" then return true end
				if mode == "em" or mode == "dm" then
					obs.obs_property_list_clear(targetList)
					obs.obs_property_list_clear(ops_in)
					obs.obs_property_set_visible(targetList, true)
					obs.obs_property_set_visible(ops_in, true)
					obs.obs_property_list_add_string(targetList, "<Operate target>", "<none>");
					for _, sceneItemName in ipairs(get_all_current_sources_from_scene()) do
						obs.obs_property_list_add_string(targetList, sceneItemName, sceneItemName)
					end
					obs.obs_property_set_visible(operaScreen, true)
					
					-- [[ Operations ]]
						OperationalInitEditor(properties,nil,settings_)
						if mode == "em" then
							obs.obs_property_set_visible(edit, true)
						elseif mode == "dm" then
							obs.obs_property_set_visible(delete, true)
						end
					-----
				elseif mode == "cm" then
					obs.obs_property_set_visible(cl, true)
					obs.obs_property_set_visible(clBtn, true)
				end
				return true
			end)
			--
			obs.obs_property_set_modified_callback(opera_target_list, OperationalInitEditor)
		obs.obs_property_set_visible(opera_group, false)
		obs.obs_property_set_visible(opera_target_list, false)
		obs.obs_property_set_visible(opera_setup_group_cl, false)
		obs.obs_property_set_visible(opera_in_list, false)
		obs.obs_property_set_visible(opera_delete_btn, false)
		obs.obs_property_set_visible(opera_edit_btn, false)
		obs.obs_property_set_visible(opera_setup_group_cl_btn, false)
		obs.obs_property_set_visible(opera_setup_group_operation_label, false)
		
		obs.obs_property_list_add_string(opera_list, "<Operate mode>", "<none>");
		obs.obs_property_list_add_string(opera_target_list, "<Operate target>", "<none>");
		for _, it in ipairs(hns_opera_list) do
			obs.obs_property_list_add_string(opera_list, it.name, it.id);
		end
	-- [[ Display & Screen ]]
		local obj_op = obs.obs_properties_add_group(objp, "oper_op", "Display && Screen", obs.OBS_GROUP_NORMAL, objp_op)
		local display_screen_view_list = obs.obs_properties_add_list(objp_op, "display_screen_view_list", "View:", obs.OBS_COMBO_TYPE_LIST, obs.OBS_COMBO_FORMAT_STRING)
		local display_screen_filter_list = obs.obs_properties_add_list(objp_op, "display_screen_filter_list", "Filter:", obs.OBS_COMBO_TYPE_LIST, obs.OBS_COMBO_FORMAT_STRING)
		obs.obs_property_list_add_string(display_screen_filter_list, "None (default)", "<none>")
		obs.obs_property_list_add_string(display_screen_filter_list, "Conditional (only)", "<cnd>")
		obs.obs_property_list_add_string(display_screen_filter_list, "Actions (only)", "<act>")
		-- view change event;
		obs.obs_property_set_modified_callback(display_screen_view_list, function(properties, property, settings_)
			if settings_ == nil then return false end
			local m = obs.obs_data_get_string(settings_, "display_screen_view_list")
			if m == "" or m == nil then return false end
			local screen = obs.obs_properties_get(properties, "screen")
			obs.obs_data_set_string(settings_, "display_screen_filter_list", "<none>")
			obs.obs_property_set_description(screen, soure_list_view(properties))
			return true;
		end)
		-- filter change event;
		obs.obs_property_set_modified_callback(display_screen_filter_list, function(properties, property, settings_)
			if settings_ == nil then return false end
			local fv = obs.obs_data_get_string(settings_, "display_screen_filter_list")
			if fv == "" or fv == nil then
				return false
			end
			
			local screen = obs.obs_properties_get(properties, "screen")
			obs.obs_property_set_description(screen, soure_list_view(properties))
			return true
		end)
		obs.obs_property_list_add_string(display_screen_view_list, "<Display All>", "<all_af>")
		obs.obs_property_list_add_string(display_screen_view_list, "<Global>", "<gf>")
		local objp_screen = obs.obs_properties_add_text(objp_op, "screen",[[<b>loading...</b>]], obs.OBS_TEXT_INFO)
		-- Refresh {!}
		local obj_reset_btn = obs.obs_properties_add_button(objp_op, "reset_btn", "Refresh 🔄 ", APP_RESET)
		obs.obs_property_set_long_description(obj_reset_btn, [[
			Click this button to refresh the <i>display, settings, etc.</i>
			e.g <strong><i>(Whenever you switch to a different scene!)</i></b>
		]])
	-- [[ Scene collection ]]
		-- Runs only when APP_INTER_STATE >= 2
		--if APP_INTER_STATE >= 2 then
			InitScenesList(objp, nil, __settings__)
		--end
	--if APP_INTER_STATE >= 2 then 
		obs.obs_property_set_description(objp_screen, soure_list_view(objp))
	--end
	init()
	return objp
end

function script_defaults(settings_)
	-- [[ Repeat defaults ]]
		obs.obs_data_set_default_int(settings_, "action_setup_group_repeat_number", 1)
		obs.obs_data_set_default_int(settings_, "action_setup_group_repeat_time", 1);
		obs.obs_data_set_default_string(settings_, "action_setup_group_repeat_option", "<none>")
		obs.obs_data_set_default_string(settings_, "action_setup_group_repeat", "<inf>")
		
	-- [[ Hide defaults ]] 
		obs.obs_data_set_default_int(settings_, "action_setup_group_hide_time", 1)
		obs.obs_data_set_default_string(settings_, "action_setup_group_hide_time_option", "<none>")
		obs.obs_data_set_default_bool(settings_, "action_setup_group_hide_time_rand", false)
	
	-- [[ Show defaults ]]
		obs.obs_data_set_default_int(settings_, "action_setup_group_show_time", 1)
		obs.obs_data_set_default_string(settings_, "action_setup_group_show_time_option", "<none>")
		obs.obs_data_set_default_bool(settings_, "action_setup_group_show_time_rand", false)
	
end -- useless :) for now.

function script_description()
	return welcomeIndex()
end

function script_update(settings_)
	__settings__ = settings_
end
function script_load(settings_)
	
	__settings__ = settings_
	-- set default;
	obs.obs_data_set_bool(settings_, "MultiSync", false)
	obs.obs_data_set_int(settings_, "action_setup_duration_input1", 1)
	obs.obs_data_set_int(settings_, "action_setup_duration_input2", 1)
	obs.obs_data_set_string(settings_, "obj_setting_list", "<none>")
	obs.obs_data_set_string(settings_, "action_setup_duration_list", "<none>")
	obs.obs_data_set_int(settings_, "repeat_action_value1", -1)
	obs.obs_data_set_int(settings_, "repeat_action_value2", -1)
	obs.obs_data_set_string(settings_, "opera_setup_group_list", "<none>")
	obs.obs_data_set_string(settings_, "opera_setup_group_target_list", "<none>")
	obs.obs_data_set_string(settings_, "opera_setup_group_operation_list", "<none>")
	--
	local currSceneObj = obs.obs_frontend_get_current_scene()
	currSceneName = obs.obs_source_get_name(currSceneObj)
	obs.obs_source_release(currSceneObj)
	-- default global array storage
	local global_list_array = obs.obs_data_get_array(settings_, "__HActionListS__")
	if not global_list_array then
		local global_list_array = obs.obs_data_array_create();
		obs.obs_data_set_array(settings_, "__HActionListS__", global_list_array)
	end
	APP_STREAMING_ACTIVE = obs.obs_frontend_streaming_active(); APP_RECORDING_ACTIVE = obs.obs_frontend_recording_active()
	if global_list_array ~= nil then obs.obs_data_array_release(global_list_array) end
	-- callbacks;
	obs.obs_frontend_add_event_callback(onEvent)
end
function script_unload()

end
function welcomeIndex()
	return [[<center><h1 style = "color:#eee;padding:0;margin:0">HIDE & SHOW</h3><h5 style = 'color:#555'><i>V.4 - Made by iisxiao</i></h5></center>
		
		<center>
			<p>You can learn more about this script <a href = 'https://obsproject.com/forum/resources/hide-show.1560/'>here</a> or watch a tutorial <a href = 'https://youtu.be/kZeTWPo_ay0'>video</a></p>
		</center>
		<hr/>
	]]

end

function InitScenesList(properties, property, settings_)
	local action_setup_scene_list = obs.obs_properties_get(properties, "action_setup_scene_list")
	local conditional_setup_scene_list = obs.obs_properties_get(properties, "conditional_setup_scene_list")
	local display_screen_view_list = obs.obs_properties_get(properties, "display_screen_view_list")
	if action_setup_scene_list then	
		obs.obs_property_list_clear(action_setup_scene_list)
	end
	if conditional_setup_scene_list then	
		obs.obs_property_list_clear(conditional_setup_scene_list)
	end
	if display_screen_view_list then	
		obs.obs_property_list_clear(display_screen_view_list)
	end
	-- [[ View List ]]
		obs.obs_property_list_add_string(display_screen_view_list, "<Display All>", "<all_af>")
		obs.obs_property_list_add_string(display_screen_view_list, "<Global>", "<gf>")
	-- [[ Conditional List ]]
		obs.obs_property_list_add_string(conditional_setup_scene_list, "<Global>", "<none>")
	-- [[ Action List ]]
		obs.obs_property_list_add_string(action_setup_scene_list, "<Global>", "<none>")
		
	-- [[ Scene Collection ]]
		
		local scenes = obs.obs_frontend_get_scenes()
		-- get the current scene name;
		local f_obj = obs.obs_frontend_get_current_scene()
		local current_scene_name = obs.obs_source_get_name(f_obj)
		obs.obs_source_release(f_obj);
		if scenes ~= nil then
			for _, scene in ipairs(scenes) do
				local name = obs.obs_source_get_name(scene)
				local appn = name
				if current_scene_name == name then
					appn = name .. "| (Current Active)"
					name = "<default>"
				end
				obs.obs_property_list_add_string(action_setup_scene_list, appn, name)
				obs.obs_property_list_add_string(conditional_setup_scene_list, appn, name)
				
				obs.obs_property_list_add_string(display_screen_view_list, appn, name)
			end
			obs.source_list_release(scenes)
		end
	return true
end
-- table stuff
function GetTableLen(ta)
	local count = 0
	for _, iter in pairs(ta) do
		count = count + 1
	end
	return count;
end
function GetNameFromTableByIndex(ta, index)
	if GetTableLen(ta) > 0 then
		local start = 1
		for targetName, iter in pairs(ta) do
			if start == index then
				return targetName
			end
			start = start + 1
		end
	end
	return nil
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
APP     =   {
	ONSTREAM = 1; ONRECORD = 2; DEFAULT = {
		true, 0, false,-1
	}; NOT_DEFAULT = {
		1,2,-1
	}
}
-- Command Execution
function COMMAND_PROMPT(properties, property)
	local cmd_input_value = obs.obs_data_get_string(__settings__, "opera_setup_group_cl")
	
	local scene_name = currSceneName
	local warn_label = obs.obs_properties_get(properties, "opera_setup_group_operation_label")
	
	local APP_OBJECTS_NAMES = get_all_current_sources_from_scene()
	
	--[[
	if scene_name == nil or scene_name == "" then
		obs.obs_property_set_visible(warn_label, true)
		obs.obs_property_set_description(warn_label, "(Please select scene)")
		APP_LOG("make sure to select a scene before inserting anything", APP_LOG_WRN_LVL)
		return true;
	end
	]]
	local ainls = {} -- (APP_INFO) list
	local ap = nil; -- (APP_INFO)
	local error_list = {};
	if cmd_input_value == nil or strTrim(cmd_input_value) == "" then
		obs.obs_property_set_visible(warn_label, true)
		obs.obs_property_set_description(warn_label, "<b style = 'color:orange'>(Warning) You must input some text here :)</b>")
		return true;
	end
	
	obs.obs_property_set_visible(warn_label, false)
	local ValidateAction = function(cmd)
		if #cmd < 2 then
			obs.obs_property_set_visible(warn_label, true)
			obs.obs_property_set_description(warn_label, "<b style = 'color:red'>Invalid (action) 2 arguments expected; got 1</b>")
			return true;
		end
		local action_target = strTrim(cmd[2])
		if action_target == "" then
			obs.obs_property_set_visible(warn_label, true)
			obs.obs_property_set_description(warn_label, "<b style = 'color:red'>Invalid (action) 2 arguments expected; got 1</b>")
			return true;
		end
		if #cmd >= 3 then -- time
			local action_time = time_splitter(string.lower(strTrim(cmd[3])))
			if action_time == nil or action_time.value == nil or action_time.type == "" then
				obs.obs_property_set_visible(warn_label, true)
				obs.obs_property_set_description(warn_label, "<b style = 'color:red'>Invalid (action.Time) argument 3; time not valid</b>")
				return true
			end
		end
		-- check if the target exists;
		if not APP_ACTIONS:IsLikeAction(action_target) and string.lower(action_target) ~= "all" then
			-- check if (action_target) is index selection;
			if string.sub(action_target,1,1) == "#" then
				-- get the current index possible;
				local index_target = tonumber(rplr_char(strTrim(action_target), "#",""))
				if index_target and index_target > 0 and index_target <= #APP_OBJECTS_NAMES then
					if APP_OBJECTS_NAMES[index_target] then
						action_target = APP_OBJECTS_NAMES[index_target]
					else
						-- error;
						obs.obs_property_set_visible(warn_label, true)
						obs.obs_property_set_description(warn_label, "<b style='color:red'>Invalid (action.Target) argument 2; invalid selection</b>")
						APP_LOG("{" .. tostring(index_target) .. "} is not valid index selection; or is out-of-bound", APP_LOG_WRN_LVL)
						return true
					end
				else
					-- error;
					obs.obs_property_set_visible(warn_label, true)
					obs.obs_property_set_description(warn_label, "<b style = 'color:red'>Invalid (action.Target) argument 2; invalid selection</b>")
					APP_LOG("{" .. tostring(index_target) .. "} is not valid index selection; or is out-of-bound", APP_LOG_WRN_LVL)
					return true
				end
			end
			local __obj = __GET_SCENE_ITEM__(action_target)
			if __obj == nil then
				obs.obs_property_set_visible(warn_label, true)
				obs.obs_property_set_description(warn_label, "<b style = 'color:red'>Invalid (action.Target) argument 2; not found</b>")
				APP_LOG("{" .. tostring(action_target) .. "} is not found on the current scene!", APP_LOG_WRN_LVL)
				return true
			else
				__obj.release()
			end
		end
		-- check for repeative value;
		if #cmd >= 4 then
			local repeative_value = strTrim(cmd[4])
			if string.find(repeative_value,"x") == 1 then
				-- get the number;
				local rev = tonumber(rplr_char(repeative_value, "x",""))
				if rev == nil or rev <= 0 then
					obs.obs_property_set_visible(warn_label, true)
					obs.obs_property_set_description(warn_label, "<b style = 'color:red'>Invalid (action.repeat) argument 4</b>")
					APP_LOG("{" .. tostring(rplr_char(repeative_value, "x","")) .. "} is not valid number to repeat!; make sure you give it a number: example (1,2,3 etc.)", APP_LOG_WRN_LVL)
					
					return true;
				end
			elseif tonumber(repeative_value) == nil or tonumber(repeative_value) <= 0 then -- errro
				obs.obs_property_set_visible(warn_label, true)
				obs.obs_property_set_description(warn_label, "<b style = 'color:red'>Invalid (action.repeat) argument 4</b>")
				APP_LOG("{" .. tostring(repeative_value) .. "} is not valid number to repeat!; make sure you give it a number: example (1,2,3 etc.)", APP_LOG_WRN_LVL)
				return true
			end
		end
		
		-- reset time;
		if #cmd >= 5 then
			local reset = time_splitter(cmd[5]);
			if not rest.value or rest.value <= 0 then
				obs.obs_property_set_visible(warn_label, true)
				obs.obs_property_set_description(warn_label, "<b style = 'color:red'>Invalid (action.reset) argument 5</b>")
				APP_LOG("{reset} is not valid time!; example (1s, 5s, 10m, etc.)", APP_LOG_WRN_LVL)
				return true;
			end
			if rest.type ~= "ms" and rest.type ~= "sc" and rest.type ~= "mis" and rest.type == "hr" then
				obs.obs_property_set_visible(warn_label, true)
				obs.obs_property_set_description(warn_label, "<b style = 'color:red'>Invalid (action.reset) argument 5</b>")
				APP_LOG("{reset} is not valid time!; allowed time (ms => Minutes, sc => Seconds, mis => Milliseconds, hr => Hours)", APP_LOG_WRN_LVL)
				return true;
			end
		end
	end
	local ValidateCond = function(cmd)
		
		local sp = 0
		if string.sub(strTrim(cmd[1]), 1, 1) == "<" and string.sub(strTrim(cmd[1]),#strTrim(cmd[1]), #strTrim(cmd[1])) == ">" then -- Defined Scope;
			sp = 1
		end
		if #cmd < 5 + sp then
			obs.obs_property_set_visible(warn_label, true)
			obs.obs_property_set_description(warn_label, "<b style = 'color:red'>Invalid (Statement) " .. tostring(5 + sp) .. " arguments expected; got " .. tostring(#cmd) .. "</b>")
			return true
		end
		local cond = strTrim(string.lower(cmd[1 + sp]))
		local target1 = strTrim(cmd[2 + sp])
		local action1 = strTrim(string.lower(cmd[3 + sp]))
		local target2 = strTrim(cmd[4 + sp])
		local action2 = strTrim(string.lower(cmd[5 + sp]))
		if action1 == "text" then
			if #cmd >= 7 then
				action2 = strTrim(string.lower(cmd[6 + sp]))
				target2 = strTrim(cmd[5 + sp])
			else
				action2 = strTrim(string.lower(cmd[5 + sp]))
				target2 = strTrim(cmd[4 + sp])
			end
		end
		local stats = false;
		for _, it in ipairs(hns_cond_list) do
			if it and string.lower(rplr_char(strTrim(it.name), "<>","")) == cond then
				stats = true; cond = it.id  break;
			elseif it and string.lower(rplr_char(strTrim(it.id), "<>","")) == cond then
				cond = it.id; stats = true; break
			end
		end
		if not stats then
			obs.obs_property_set_visible(warn_label, true)
			obs.obs_property_set_description(warn_label, "<b style = 'color:red'>Invalid (Conditional.Command) is not supported</b>")
			return true
		end
		if target1 == "all" or APP_ACTIONS:IsLikeAction(target1) or target1 == "rand" then
			obs.obs_property_set_visible(warn_label, true)
			obs.obs_property_set_description(warn_label, "<b style = 'color:red'>Invalid (Conditional.First_Target) can't be that value</b>")
			return true
		end
		if action1 == "blink" then
			obs.obs_property_set_visible(warn_label, true)
			obs.obs_property_set_description(warn_label, "<b style = 'color:red'>Invalid (Conditional.Action) can't be (blink)</b>");
			return true
		end
		stats = false
		if cond == "cdf" then
			for _, a in ipairs(prset_flb_ls) do
				a = string.lower(strTrim(rplr_char(a, "<>","")))
				if a == action1 then
					stats = true;break
				end
			end
		elseif cond == "cdwn" then
			for _, a in ipairs(prset_action_ls) do
				a = string.lower(strTrim(rplr_char(a, "<>","")))
				if a == action1 then
					stats = true;break
				end
			end
		end
		if not stats then
			obs.obs_property_set_visible(warn_label, true)
			obs.obs_property_set_description(warn_label, "<b style = 'color:red'>Invalid (Conditional.Action) is not found (" .. tostring(action1) .. ")</b>");
			return true
		end
		stats = false
		if cond == "cdf" then
			for _, a in ipairs(prset_action_ls) do
				a = string.lower(strTrim(rplr_char(a, "<>","")))
				if a == action2 then
					stats = true;break
				end
			end
			if action2 == "reset" or action2 == "end" then
				stats = false
			end
		else
			for _, a in ipairs(prset_action_ls) do
				a = string.lower(strTrim(rplr_char(a, "<>","")))
				if a == action2 then
					stats = true;break
				end
			end
		end
		if not stats then
			obs.obs_property_set_visible(warn_label, true)
			obs.obs_property_set_description(warn_label, "<b style = 'color:red'>Invalid (Conditional.Action) is not found (" .. tostring(action2) .. ")</b>");
			return true
		end
	end
	local ValidInits = {}
	local initCmd = function(command_list,cmd_value, ty)
		if #command_list > 1 then
			local action_name = string.lower(strTrim(command_list[1]))
			-- Get Scope;
			local action_sct = currSceneName;
			local sp = 0
			if string.sub(strTrim(command_list[1]), 1, 1) == "<" and string.sub(strTrim(command_list[1]),#strTrim(command_list[1]), #strTrim(command_list[1])) == ">" then -- Defined Scope;
				sp = 1
				if strTrim(command_list[1]) == "<global>" then
					action_sct = "__HActionListS__" -- default scope;
				else
					action_sct = rplr_char(strTrim(command_list[1]), "<>","")
				end
				action_name = string.lower(strTrim(command_list[2]))
			end
			-- Create Scope;
			local act_sct_arr = obs.obs_data_get_array(__settings__, action_sct)
			if act_sct_arr == nil then
				act_sct_arr = obs.obs_data_array_create()
				obs.obs_data_set_array(__settings__, action_sct, act_sct_arr)
			end
			obs.obs_data_array_release(act_sct_arr)
			if action_name == "hide" or action_name == "show" then -- INSERT (ACTION)
				if ValidateAction(command_list) then
					return true;
				end
				local action_target = strTrim(command_list[2 + sp]);
				local action_time_value = "1sc"
				if #command_list >= 3 + sp then -- time
					local action_time = time_splitter(string.lower(strTrim(command_list[3 + sp])))
					if action_time ~= nil then
						action_time_value = action_time.order .. tostring(action_time.value) .. action_time.type
					end
				end
				-- check for repeative value;
				local repeative_value = "<inf>";
				if #command_list >= 4 + sp then
					repeative_value = strTrim(command_list[4 + sp])
					if string.find(repeative_value,"x") ~= 1 then
						repeative_value = "x" .. repeative_value
					end
					if repeative_value ~= "xinf" and repeative_value ~= "inf" and tonumber(repeative_value) ~= nil then
						-- check reset;
						local reset_value = ""
						if #command_list >= 5+sp then
							reset_value = "|" .. strTrim(command_list[5+sp])
						end
						repeative_value = repeative_value .. reset_value;
					end
				end
				-- check if the target exists;
				if not APP_ACTIONS:IsLikeAction(action_target) and string.lower(action_target) ~= "all" then
					-- check if (action_target) is index selection;
					if string.sub(action_target,1,1) == "#" then
						-- get the current index possible;
						local index_target = tonumber(rplr_char(strTrim(action_target), "#",""))
						if index_target and index_target > 0 and index_target <= #APP_OBJECTS_NAMES then
							if APP_OBJECTS_NAMES[index_target] then
								action_target = APP_OBJECTS_NAMES[index_target]
							end
						end
					end
				end
				--
				table.insert(ValidInits, function()
					local action = "<act>|" .. action_name .. "|" .. action_target .. "|" .. action_time_value .. "|" .. repeative_value
					if APP_ACTIONS:has(ty) and APP_ACTIONS:isOnFrontEnd(ty) then
						action = ty .. "{" .. action .. "}"
					end
					if not INSERT_INTO_OBS_ARRAY__(action_sct, action) then
						obs.obs_property_set_visible(warn_label, true)
						obs.obs_property_set_description(warn_label, "<b style = 'color:red'>Error: something went wrong</b>")
						APP_LOG("{Execute} Something awful happend! (to fix maybe restart the whole program)", APP_LOG_ERR_LVL)
						-- table.insert(error_list, "")
						return true
					end
					
				end)
			elseif action_name == "if" or action_name == "when" then
				if ValidateCond(command_list) then
					return true;
				end
				local cond = strTrim(string.lower(command_list[1 + sp]))
				local target1 = strTrim(command_list[2 + sp])
				local action1 = strTrim(string.lower(command_list[3 + sp]))
				local target2 = strTrim(command_list[4 + sp])
				local action2 = strTrim(string.lower(command_list[5 + sp]))
				local value = "";
				for _, it in ipairs(hns_cond_list) do
					if it and string.lower(rplr_char(strTrim(it.name), "<>","")) == cond then
						cond = it.id; break
					elseif it and string.lower(rplr_char(strTrim(it.id), "<>","")) == cond then
						cond = it.id; break
					end
				end
				if cond == "cdf" and action1 == "text" then
					if #command_list >= 6 then
						value = strTrim(command_list[4 + sp]) .. "|"
						target2 = strTrim(command_list[5 + sp])
						action2 = strTrim(string.lower(command_list[6 + sp]))
					else
						value = "|"
						target2 = strTrim(command_list[4 + sp])
						action2 = strTrim(string.lower(command_list[5 + sp]))
					end
				end
				table.insert(ValidInits, function()
					local action = "<cond>|" .. cond .. "|" .. target1 .. "|" .. action1 .. "|" .. value .. target2 .. "|" .. action2
					if APP_ACTIONS:has(ty) and APP_ACTIONS:isOnFrontEnd(ty) then
						action = ty .. "{" .. action .. "}"
					end
					if not INSERT_INTO_OBS_ARRAY__(action_sct, action) then
						obs.obs_property_set_visible(warn_label, true)
						obs.obs_property_set_description(warn_label, "<b style = 'color:red'>Error: something went wrong</b>")
						APP_LOG("{Execute} Something awful happend! (to fix maybe restart the whole program)", APP_LOG_ERR_LVL)
						-- table.insert(error_list, "")
						return true
					end
					
				end)
			else
				obs.obs_property_set_visible(warn_label, true)
				obs.obs_property_set_description(warn_label, "<b style = 'color:red'>Invalid command; first argument {" .. action_name .. "}</b>")
				return true
			end
		else -- error?
			obs.obs_property_set_visible(warn_label, true)
			obs.obs_property_set_description(warn_label, "<b style= 'color:red'>Invalid (command) is not supported!</b>")
			return true
		end
	end
	local cmd_list = cmd_txt_to_list(cmd_input_value)
	if cmd_list == true then
		obs.obs_property_set_visible(warn_label, true)
		obs.obs_property_set_description(warn_label, "<b style= 'color:red'>Invalid (onstream, onrecord)</b>")
		APP_LOG("something is not right with (onstream or onrecord) make sure you are not missing any closing bracket or opening bracket ({})", APP_LOG_ERR_LVL)
		return true;
	end
	local line = 1
	
	for _, cmd_value in ipairs(cmd_list) do
		-- read for (onstreaming, onrecording) command;
		if string.find(cmd_value, "onstream") == 1 or string.find(cmd_value, "onrecord") == 1 then
			local s = string.find(cmd_value, "{")
			local e = string.find(cmd_value, "}")
			if not s or not e then -- push error log;
				table.insert(error_list,"(onstream, onrecord) a closing bracket or opening bracket must be missing! on line > " .. line)
				break;
			end
			local k = strTrim(string.sub(cmd_value, 1, s-1))
			local new_cmd_list = cmd_txt_to_list(string.sub(cmd_value,s+1, e-1))
			-- make sure the code cmds are valid!;
			for _, cmd in ipairs(new_cmd_list) do
				local ls = splitBy(cmd, "|")
				if initCmd(ls, cmd, string.sub(cmd_value, 1, s-1)) then
					return true;
				else
					if k == "onstream" and not string.find(fixLog(ainls), tostring(APP.ONSTREAM)) then
						table.insert(ainls, APP.ONSTREAM)
					elseif k == "onrecord" and not string.find(fixLog(ainls), tostring(APP.ONRECORD)) then
						table.insert(ainls, APP.ONRECORD)
					end
				end
			end
		else
			-- read for (action) command
			local command_list = splitBy(cmd_value, "|")
			if initCmd(command_list, cmd_value, nil) then
				return true;
			else
				if not string.find(fixLog(ainls), "0") then
					table.insert(ainls, 0)
				end
			end
		end
		line = line + 1
	end
	if #error_list > 0 then -- error stop the execution;
		for _, er in ipairs(error_list) do
			APP_LOG(er, APP_LOG_WRN_LVL)
		end
		return true
	else -- execute cmds;
		for _, iter in ipairs(ValidInits) do
			iter()
		end
		ValidInits = {}
	end
	--[[Re-draw]]
	InitScreen(properties, nil, __settings__)

	-- call (update)
	init()
	
	return true
end
function IN_ARRAY(item, array)
	for i, v in ipairs(array) do
		if v == item then
			return true
		end
	end
	return false
end
function APP_RESET(properties, property)
	if __settings__ == nil then return false end
	-- Reset Data 
	obs.obs_data_set_string(__settings__, "display_screen_view_list", "<default>")
	obs.obs_data_set_string(__settings__, "conditional_setup_scene_list", "<default>")
	obs.obs_data_set_string(__settings__, "action_setup_scene_list", "<default>")
	obs.obs_data_set_string(__settings__, "opera_setup_group_list", "<none>")
	obs.obs_data_set_string(__settings__, "opera_setup_group_target_list", "<none>")
	
	-- [[ Operational ]]
		local opera_setup_group_target_list = obs.obs_properties_get(properties, "opera_setup_group_target_list")
		obs.obs_property_set_visible(opera_setup_group_target_list, false)
		OperationalInitReset(properties)
		
	-- Reset Scenes list;
	InitScenesList(properties, property, __settings__)
	
	-- Re-draw the screen
	local screen = obs.obs_properties_get(properties, "screen")
	obs.obs_property_set_description(screen, soure_list_view(properties))
	
	-- Reset/Cancel previous operation that were running!
	TargetSourceListInit(properties, nil, __settings__)
	return true
end
function OperationalInitEditor(properties, property, settings_)
	if settings_ == nil then return false end
	local filter = obs.obs_data_get_string(settings_, "opera_setup_group_target_list")
	local ops_in = obs.obs_properties_get(properties, "opera_setup_group_operation_list")
	obs.obs_property_list_clear(ops_in)
	obs.obs_property_list_add_string(ops_in, "<Select operation>", "<none>")
	local viewInvalid = 0
	local ops = { "__HActionListS__",currSceneName}
	-- iterate through all the names and put the data together;
	for _, tar in ipairs(ops) do
		if tar and tar ~= "" and tar ~= nil then
			local source_list = obs.obs_data_get_array(settings_, tar)
			if source_list == nil or obs.obs_data_array_count(source_list) <= 0 then
				viewInvalid = viewInvalid + 1
			else
				local len = obs.obs_data_array_count(source_list);
				-- show soure list;
				-- get all the sources in the array list; and display them to the screen;
				local scope = ""
				if tar == "__HActionListS__" then
					scope = "(global)"
				else
					scope = "(" .. tar .. ")"
				end
				local lastI = nil
				for i = 0, len - 1 do
					if lastI ~= i then
						local p_item = obs.obs_data_array_item(source_list,i)
						if p_item ~= nil then
							local value = obs.obs_data_get_string(p_item,"key")
							local IsOnStream = "";
							local IsOnRecord = "";
							local operiValue = value
							if string.find(string.lower(value), "onstream") == 1 then
								IsOnStream = "{on-stream}";
								value = string.sub(value, string.find(value, "{") + 1,string.find(value, "}") -1)
							elseif string.find(string.lower(value), "onrecord") == 1 then
								IsOnRecord = "{on-record}";
								value = string.sub(value, string.find(value, "{") + 1,string.find(value, "}") -1)
							end
							local p = splitBy(value, "|")
							if filter ~= "" and filter ~= "<none>" then
								if (p and p[1] == "<act>" and p[3] == filter) then
									local info = ""
									if p[1] == "<act>" then
										info = p[2] .. " " .. p[3] .. " every: " .. p[4]
										if p[5] and p[5] ~= "<inf>" then
											info = info .. " repeat: " .. p[5]
											if p[6] then
												info =info.. " reset after: " .. p[6]
											end
										end
									end
									obs.obs_property_list_add_string(ops_in, scope .. " -> " .. IsOnRecord .. IsOnStream .. " " .. info, scope .. "|" .. operiValue)
								elseif p and p[1] == "<cond>" and p[5] == filter then
									local info = ""
									if p[2] == "cdwn" then
										info = "(When) " .. p[3] .. " " .. p[4] .. " do: "  .. p[6] .. " for: " .. p[5]
									elseif p[2] == "cdf" then
										info = "(If) " .. p[3] .. " " .. p[4] .. " do: "  .. p[6] .. " for: " .. p[5]
									end
									obs.obs_property_list_add_string(ops_in, scope .. " -> " .. IsOnRecord .. IsOnStream .. " " .. info , scope .. "|" .. operiValue)
								end
							else
								local value2 = ""
								local info = ""
								if p[1] == "<cond>" then
									if p[2] == "cdwn" then
										info = "(When) " .. p[3] .. " " .. p[4] .. " do: "  .. p[6] .. " for: " .. p[5]
									elseif p[2] == "cdf" then
										info = "(If) " .. p[3] .. " " .. p[4] .. " do: "  .. p[6] .. " for: " .. p[5]
									end
								elseif p[1] == "<act>" then
									info = p[2] .. " " .. p[3] .. " every: " .. p[4]
									if p[5] and p[5] ~= "<inf>" then
										info = info .. " repeat: " .. p[5]
										if p[6] then
											info =info.. " reset after: " .. p[6]
										end
									end
								end
								obs.obs_property_list_add_string(ops_in, scope .. " -> " .. IsOnRecord .. IsOnStream .. " " .. info, scope .. "|" .. operiValue)
							end
							
							obs.obs_data_release(p_item)
						end
					end
				end
			end
			obs.obs_data_array_release(source_list)
		end
	end
	return true
end
function OperationalInitReset(properties)
	if __settings__ == nil then return false end
	-- [[ opera_setup_group_list ]]
		obs.obs_data_set_string(__settings__, "opera_setup_group_list", "<none>")
	-- [[ opera_setup_group_target_list ]]
	
		local opera_setup_group_target_list = obs.obs_properties_get(properties, "opera_setup_group_target_list")
		obs.obs_property_set_visible(opera_setup_group_target_list, false)
		obs.obs_data_set_string(__settings__, "opera_setup_group_target_list", "<none>")
		obs.obs_property_list_add_string(opera_setup_group_target_list, "<Operate target>", "<none>");
		for _, sceneItemName in ipairs(get_all_current_sources_from_scene()) do
			obs.obs_property_list_add_string(opera_setup_group_target_list, sceneItemName, sceneItemName)
		end
	-- [[ opera_setup_group_operation_list ]]
		local opera_setup_group_operation_list = obs.obs_properties_get(properties, "opera_setup_group_operation_list")
		obs.obs_property_set_visible(opera_setup_group_operation_list, false)
		obs.obs_data_set_string(__settings__, "opera_setup_group_operation_list", "<none>")
		
	-- [[ opera_setup_group_cl ]]
		local opera_setup_group_cl = obs.obs_properties_get(properties, "opera_setup_group_cl")
		obs.obs_property_set_visible(opera_setup_group_cl, false)
		obs.obs_data_set_string(__settings__, "opera_setup_group_cl", "")
	-- [[ opera_setup_group_cl_btn ]]
		local opera_setup_group_cl_btn = obs.obs_properties_get(properties, "opera_setup_group_cl_btn")
		obs.obs_property_set_visible(opera_setup_group_cl_btn, false)
	-- [[ opera_setup_group_delete_btn ]]
		local opera_setup_group_delete_btn = obs.obs_properties_get(properties, "opera_setup_group_delete_btn")
		obs.obs_property_set_visible(opera_setup_group_delete_btn, false)
	-- [[ opera_setup_group_operation_label ]]
		local opera_setup_group_operation_label = obs.obs_properties_get(properties, "opera_setup_group_operation_label")
		obs.obs_property_set_visible(opera_setup_group_operation_label, false)
		obs.obs_property_set_description(opera_setup_group_operation_label, "")
	return true
end
-- Compare values between two tables(arrays, pairs, etc)
function table.cmpv(t1, t2)
	local sts = false
	local c = 0
	local ks = {}
	for _, v in ipairs(t1) do
		c = c + 1
		if #t1 < #t2 or #t1 > #t2 then return false end
		local failed = true
		for k, j in ipairs(t2) do
			if not ks[k] then
				failed = true
				if type(v) == type(j) and type(v) == "table" then
					local m = table.cmpv(v, j)
					if m then
						failed = false; ks[k] = true
						break
					end
				elseif type(v) == type(j) and v == j then
					failed = false; ks[k] = true
					break
				end
			else
				failed = false
			end
		end
		if failed then return not failed end
	end
	if c <= 0 then -- using (pairs)
		local c1 = 0
		local c2 = 0
		for k2, v2 in pairs(t2) do
			c2 = c2 + 1
		end
		for k1, v1 in pairs(t1) do
			c1 = c1 + 1
			local failed = true
			for k2, v2 in pairs(t2) do
				if not ks[k2] then
					if type(v1) == type(v2) and type(v1) == "table" then
						local m = table.cmpv(v1, v2)
						if m then
							failed = false; ks[k2] = true
							break
						end
					elseif type(v1) == type(v2) and v1 == v2 then
						ks[k2] = true; failed = false
						break
					end
				end
			end
			if failed then return not failed end
		end
		if c1 < c2 or c1 > c2 then return false end
	end
	return true
end
function table.copy(t, dp)
	local t2 = {}
	local c = 0
	for k,v in pairs(t) do
		c = c + 1
		if dp and type(v) == "table" then t2[k] = table.copy(v,dp)
		else t2[k] = v end
	end
	if c <= 0 then -- ipairs;
		for _, v in ipairs(t) do
			if dp and type(v) == "table" then table.insert(t2, table.copy(v,dp))
			else table.insert(t2, v) end
		end
	end
	return t2
end
function table.search(iter, value, dp, gp)
	for i, v in pairs(iter) do
		if type(v) == type(value) and value == v then
			return true
		end
		if dp == true and type(v) == 'table' then
			if table.search(v, value, true) then
				if gp then return v; end
				return true
			end
		end
	end
	return false
end
-- Display Screen;
function soure_list_view(properties)
	local view_mode = obs.obs_data_get_string(__settings__, "display_screen_view_list")
	local view_filter = obs.obs_data_get_string(__settings__, "display_screen_filter_list")
	local view_from = {}
	if view_mode == "<gf>" then
		table.insert(view_from, "__HActionListS__")
	elseif view_mode == "<all_af>" then -- get all the scenes
		-- [[ Scene collection ]]
			local scenes = obs.obs_frontend_get_scenes()
			if scenes ~= nil then
				for _, scene in ipairs(scenes) do
					local name = obs.obs_source_get_name(scene)
					table.insert(view_from, name)
				end
				obs.source_list_release(scenes)
			end
			table.insert(view_from, "__HActionListS__")
	elseif view_mode == "<default>" then
		local ls = obs.obs_properties_get(properties, "display_screen_view_list")
		local lsc = obs.obs_property_list_item_count(ls)
		for i = 0, lsc - 1 do
			local str = obs.obs_property_list_item_string(ls, i)
			local name = obs.obs_property_list_item_name(ls, i)
			if str == view_mode then
				view_mode = ""
				local arc_ls = splitBy(name, "|")
				for i = 1, #arc_ls - 1 do
					view_mode = view_mode .. tostring(arc_ls[i])
				end
				break
			end
		end
		table.insert(view_from, view_mode)
	else
		table.insert(view_from, view_mode)
	end
	
	local view = ""; -- return back;
	local viewInvalid = 0
	local onStreamView = ""
	local onRecordView = ""
	-- iterate through all the names and put the data together;
	for _, tar in ipairs(view_from) do
	
		local source_list = obs.obs_data_get_array(__settings__, tar)
		if source_list == nil or obs.obs_data_array_count(source_list) <= 0 then
			viewInvalid = viewInvalid + 1
		else
			local len = obs.obs_data_array_count(source_list);
			-- show soure list;
			-- get all the sources in the array list; and display them to the screen;
			for i = 0, len - 1 do
				local p_item = obs.obs_data_array_item(source_list,i)
				if p_item ~= nil then
					local value = obs.obs_data_get_string(p_item,"key")
						
					if value ~= nil then
						local IsOnStream = false;
						local IsOnRecord = false;
						if string.find(string.lower(value), "onstream") == 1 then
							IsOnStream = true;
							value = string.sub(value, string.find(value, "{") + 1,string.find(value, "}") -1)
						elseif string.find(string.lower(value), "onrecord") == 1 then
							IsOnRecord = true;
							value = string.sub(value, string.find(value, "{") + 1,string.find(value, "}") -1)
						end
						local list = splitBy(value, "|")
						local place = ""
						if list and #list > 0 then
							local results = true
							if view_filter == "<cnd>" and not table.search(hns_cond_list, string.lower(strTrim(list[2])), true, false) then
								results = false
							elseif view_filter == "<act>" and table.search(hns_cond_list, string.lower(strTrim(list[2])), true, false) then
								results = false
							end
							
							if table.search(hns_cond_list, string.lower(strTrim(list[2])), true, false) and results then
								local condItem = table.search(hns_cond_list, string.lower(strTrim(list[2])), true, true)
								if strTrim(rplr_char(string.lower(condItem.name),"<>","")) == "if" then
									if list[3] == "<none>" then
										list[3] = ""
									end
									if string.lower(strTrim(rplr_char(list[4],"<>",""))) == "text" then
										list[4] = string.lower(strTrim(rplr_char(list[4],"<>",""))) .. " <i>=&gt;</i> "
										if #list == 6 then
											list[4] = list[4] .. "<i style = 'color:gray'>[Empty]</i>"
											local t = list[5]
											--list[5] = list[5]
											--list[4] = t
										else
											if list[5] and list[5] ~= "" then
												list[4] = list[4] .. tostring(list[5])
											else
												list[4] = list[4] .. "<i style = 'color:gray'>[Empty]</i>"
											end
											local t = list[6]
											list[6] = list[7]
											list[5] = t
										end
									else
										list[4] = strTrim(rplr_char(strTrim(list[4]),"<>",""))
									end
								else
									list[4] = strTrim(rplr_char(strTrim(list[4]),"<>",""))
								end
								
								place = "<div><b style = 'border-radius:5px;color:lightblue'><span style='color:rgb(0,160,255)'>|</span>" .. rplr_char(condItem.name,"<>","") .. "<span style = 'color:rgb(0,160,255)'>|</span></b>"
								place = place .. " <span style  = 'color:yellow'>" .. strTrim(rplr_char(strTrim(list[3]),"<>","")) .. "</span> <b style = 'color:pink'>(" ..list[4].. ")</b></div>"
								place = place .. "<div style = 'margin-left:40px'><span style = 'color:gray'>do:</span> " .. "<b style = 'color:red'>(" ..strTrim(rplr_char(strTrim(list[6]),"<>","")) .. ")</b></div>"
								place = place .. "<div style = 'margin-left:80px'><span style = 'color:gray'>for:</span> <span style = 'color:yellow'>" ..strTrim(rplr_char(strTrim(list[5]),"<>","")) .."</span></div>"
								
							elseif results and (view_filter == "<none>" or view_filter == "<act>") then -- others view;
								list[2] = string.lower(rplr_char(strTrim(list[2]), "()",""))
								if list[2] == "hide" or list[2] == "show" then
									if list[2] == "hide" then
										place = "<b style = 'color:red'>" .. list[2] .. "</b> "
									elseif list[2] == "show" then
										place = "<b style = 'color:green'>" .. list[2] .. "</b> "
									else
										place = "<b style = 'color:brown'>" .. list[2] .. "</b> "
									end
									local tm = time_splitter(string.lower(strTrim(list[4])))
									
									place = "<div>" .. place .. "<span style = 'color:yellow'>" .. rplr_char(rplr_char(list[3],"<","&lt;"), ">","&gt;") .. "</span></div> "
									place = place .. "<div style = 'margin-left:40px'>" .. "<span style = 'color:gray'>for every: </span><b>"
									place = place .. "<span style = 'color:lightblue'>" .. tostring(tm.value)
									if tm.order == "%" then
										place = place .. " random "
									end
									if tm.type == "mis" then
										place = place .. " milliseconds"
									elseif tm.type == "sc" then
										place = place .. " seconds"
									elseif tm.type == "ms" then
										place = place .. " minutes"
									elseif tm.type == "hr" then
										place = place .. " hours"
									end
									place = place .. "</span></b></div>"
									if string.lower(strTrim(list[5])) ~= "<inf>" then
										place = place .. "<div style = 'margin-left: 80px'><span style = 'color:gray'>Repeat for: </span><b style = 'color:green'>" .. rplr_char(string.lower(strTrim(list[5])), "x","") .. " </span> times</div>" 
										if list[6] ~= nil then
											place = place .. "<div style = 'margin-left: 40px'><span style = 'color:gray'>Reset after: </span><b style = 'color:orange'>"
											local ftm = time_splitter(string.lower(strTrim(list[6])))
											place = place .. tostring(ftm.value)
											if ftm.order == "%" then
												place = place .. " random "
											end
											if ftm.type == "mis" then
												place = place .. " milliseconds"
											elseif ftm.type == "sc" then
												place = place .. " seconds"
											elseif ftm.type == "ms" then
												place = place .. " minutes"
											elseif ftm.type == "hr" then
												place = place .. " hours"
											end
											place = place .. "</b></div>"
										end
									end	
								end
							end
						end
						if not IsOnStream and not IsOnRecord then 
							if place ~= "" then
								view = view .. "<div>" .. place .. "</div>"
							end
						else
							if IsOnStream then
								if place ~= "" then onStreamView = onStreamView .. "<div style = 'margin-left:40px'>" .. place .. "</div>" end
							elseif IsOnRecord then
								if place ~= "" then onRecordView = onRecordView .. "<div style = 'margin-left:40px'>" .. place .. "</div>" end
							end
						end
					end
				end
				obs.obs_data_release(p_item)
			end
		end
		obs.obs_data_array_release(source_list)
	end
	if onStreamView ~= "" then
		view = "<div><strong style = 'color:gold;padding:0px;'>ON-STREAM</strong> <i style = 'color:pink'>(Client Event)</i>  {" .. onStreamView .. "}</div>".. view
	end
	if onRecordView ~= "" then
		view = "<div><strong style = 'color:gold'>ON-RECORD</strong> <i style = 'color:pink'>(Client Event)</i>  {" .. onRecordView .. "}</div>".. view
	end
	if view == "" or view == nil then
		return [[<b style = 'color:yellow'>Nothing to show right now; try a different <i>filter</i>, or a different <i>view</i></b>]]
	end
	return view
end
function time_splitter(_time_value)
    local time_list = {type="s";value=1;order="";anim=""};
    if _time_value == nil then
		return time_list
    end
    local value1 = ""
    local value2 = "";
	local value3 = "";
	local get = nil;
    for x in string.gmatch(_time_value,".") do
		if get == "@" then
			value3 = value3 .. x;
		else
			if(tonumber(x) ~= nil) then
				value1 = value1 .. x
			elseif x == "%" then
				time_list.order = "%"
			elseif x == "@" and value3 == "" and value1 ~= "" and value2 ~= "" then -- get animation;
				get = "@";
			else
				value2 = value2 .. x;
			end
		end
    end
	value1 = value1:gsub("^%s*(.-)%s*$", "%1")
	value2 = string.lower(value2:gsub("^%s*(.-)%s*$", "%1"))
	value3 = value3:gsub("^%s*(.-)%s*$", "%1")
    value1 = tonumber(value1)
	time_list.value = value1
    time_list.type = value2;
	time_list.anim = value3
    return time_list
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
function fixLog(iter, ib,idn)
	local v = ""
	if type(iter) == "table" then
		for x, y in pairs(iter) do
			if type(x) == "string" then
				v = v .. tostring(x) .. ": " .. fixLog(y, ib,idn) .. " "
			elseif ib then
				v = v .. tostring(x) .. ": " .. fixLog(y,ib,idn) .. " "
			else
				v = v .. fixLog(y) .. " "
			end
		end
		return "{" .. v .. "}"
	elseif type(iter) == "function" then
		return "(function)";
	else
		return tostring(iter)
	end
end
-- returns an array that holds all the sources(items/objects) in the scene!
function get_all_current_sources_from_scene(ignoreSource)
	local source_name_list = nil
	-- Get the current scene
	local currentSource = obs.obs_frontend_get_current_scene()
	local currentScene = obs.obs_scene_from_source(currentSource)
	if currentScene ~= nil and currentSource ~= nil then
		-- Enumerate the items in the current scene
		local sceneItems = obs.obs_scene_enum_items(currentScene)
		if sceneItems ~= nil then
			source_name_list = {}
			for _, sceneItem in ipairs(sceneItems) do
				local source = obs.obs_sceneitem_get_source(sceneItem)
				if source ~= nil then
					
						
					local sourceName = obs.obs_source_get_name(source)
					if obs.obs_sceneitem_is_group(sceneItem) then
						local __ls = obs.obs_sceneitem_group_enum_items(sceneItem)
						if __ls ~= nil then
							-- iterate through all the items in the group;
							for _, it in ipairs(__ls) do
								local s = obs.obs_sceneitem_get_source(it)
								if s ~= nil then
									local sN = obs.obs_source_get_name(s)
									if not ignoreSource then
										table.insert(source_name_list, sN)
									elseif ignoreSource ~= sN then
										table.insert(source_name_list, sN)
									end
								end
							end
							obs.sceneitem_list_release(__ls)
						
						end
					end
					if not ignoreSource then
						table.insert(source_name_list, sourceName)
					elseif ignoreSource ~= sourceName then
						table.insert(source_name_list, sourceName)
					end
				end
			end
		end
		-- Release the scene items list
		obs.sceneitem_list_release(sceneItems)
	end
	-- Release the current scene source
	obs.obs_source_release(currentSource)
	return source_name_list
end
-- executes when (Source list) changes;
function SourceListUpdate(properties, property, settings_)
	if settings_ == nil then return false end
	local source_target = obs.obs_data_get_string(settings_, "source_list")
	local warn_label = obs.obs_properties_get(properties, "action_setup_error_label")
	local cond_list = obs.obs_properties_get(properties, "obj_setting_list")
	if source_target == nil or source_target == "" then return false; end
	SettingsList(properties, property, settings_)
	obs.obs_data_set_string(settings_, "obj_setting_text", "")
	local obj_setting_text = obs.obs_properties_get(properties, "obj_setting_text")
	obs.obs_property_set_visible(obj_setting_text, false)
	if source_target == "<none>" then -- hide everything else
		local setup_g = obs.obs_properties_get(properties, "obj_config_g")
		obs.obs_data_set_string(settings_, "obj_setting_list", "<none>")
		obs.obs_property_set_visible(setup_g, false)
		HIDE_ALL_PRSET_LS(properties, true); -- hide all prset;
		return true
	end
	if source_target == "<all_like>" or source_target == "<rand_like>" then
		obs.obs_property_set_visible(obj_setting_text, true)
	end
	--[[
	if source_target == "<rand>" or source_target == "<all>" or APP_ACTIONS:IsLikeAction(rplr_char(source_target, "<>")) then
		obs.obs_data_set_string(settings_, "obj_setting_list", "<none>")
		obs.obs_property_list_item_disable(cond_list,2, true)
		HIDE_ALL_PRSET_LS(properties, true)
	else
		obs.obs_property_list_item_disable(cond_list, 2, false)
	end
	]]
	-- [[ init updates (Conditional target list) ]]
		local cond_target_list = obs.obs_properties_get(properties, "conditional_setup_group_target_list")
		obs.obs_data_set_string(settings_,"conditional_setup_group_target_list", "<none>")
		local function init_cond_target_ls()
			obs.obs_property_list_clear(cond_target_list)
			obs.obs_property_list_add_string(cond_target_list, "Select<!>","<none>")
			if source_target == "<none>" then return nil; end
			-- preset source list;
			--[[
			for i, n in ipairs(prset_source_ls) do
				obs.obs_property_list_add_string(cond_target_list, n, n)
			end
			--]]
			local source_names = get_all_current_sources_from_scene()
			for i, v in ipairs(source_names) do
				obs.obs_property_list_add_string(cond_target_list, v,v)
			end
		end
		init_cond_target_ls()
	--
	
	
	
	return true
end
-- DISPLAYS ALL THE CURRENT SCENE SOURCES;
function TargetSourceListInit(properties, property, settings_)
	local source_list = obs.obs_properties_get(properties, "source_list")
	
	obs.obs_property_list_clear(source_list)
	obs.obs_property_list_add_string(source_list, "Select Target", "<none>")
	-- preset source list;
	for i, n in ipairs(prset_source_ls) do
		obs.obs_property_list_add_string(source_list, n, n)
	end
	local source_names = get_all_current_sources_from_scene()
	for i, name in ipairs(source_names) do
		-- Add the source name to the property list
		obs.obs_property_list_add_string(source_list, name, name)
	end
	
	return true
end
-- EXECUTES WHENEVER THE USER CHANGES THE SETTINGS;
local SettingsListPrev = false
function SettingsList(properties, property, settings_)
	if settings_ == nil then return false end
	local change =	obs.obs_data_get_string(settings_, "obj_setting_list")
	local warn_label = obs.obs_properties_get(properties, "action_setup_error_label")
	local opera = obs.obs_properties_get(properties, "opera_setup_group")
	local setup_g = obs.obs_properties_get(properties, "obj_config_g")
	local target_name = obs.obs_data_get_string(settings_, "source_list")
	local screen = obs.obs_properties_get(properties, "oper_op")
	obs.obs_property_set_visible(warn_label, false)
	obs.obs_property_set_visible(screen, true)
	obs.obs_property_set_visible(setup_g, true)
	obs.obs_property_set_visible(opera, false)
	InitScreen(properties, nil, settings_)
	if change == "opl" then -- operational display
		OperationalInitReset(properties)
		HIDE_ALL_PRSET_LS(properties, true); -- hide all prset;
		obs.obs_property_set_visible(opera, true)
		obs.obs_property_set_visible(screen, false)
		return true
	end
	if target_name == nil or target_name == "" or target_name == "<none>" then -- error (must select target name)
		if change ~= "<none>" and change ~= "" then 
			obs.obs_data_set_string(settings_, "obj_setting_list", "<none>")
			obs.obs_property_set_visible(warn_label, true)
			obs.obs_property_set_description(warn_label, [[(Invalid section) Must have source selected!]]);
		else
			obs.obs_property_set_visible(warn_label, false)
		end
		return true
	end
	
	-- set default;
	
	if change == nil or change == "" then return false; end
	
	if change == "hns" then -- Display Time Configure For (Hide N Show);
		SettingsListPrev = false
		return ActionSetup(properties, property, settings_)
	elseif change == "cl" then
		SettingsListPrev = false
		return ConfigureSetup(properties, property, settings_)
	else -- default select;
		HIDE_ALL_PRSET_LS(properties, true); -- hide all prset;
		return not SettingsListPrev
	end
end
function HIDE_ALL_PRSET_LS(properties, bool) -- hide/show all prset gs;
	if properties == nil then
		return false;
	end
	for _, propName in pairs(prset_gnames_ls) do -- hide all the groups currently visible;
		local prop = obs.obs_properties_get(properties, propName);
		if prop ~= nil then
			obs.obs_property_set_visible(prop, not bool)
		end
	end
	return true;
end
-- Redraws the screen;
function InitScreen(properties, property, settings_)
	local screen = obs.obs_properties_get(properties, "screen")
	if not screen then	return false end
	obs.obs_property_set_description(screen, soure_list_view(properties))
	return true
end
-- Executes the actions/events insert them into the program;
function ExecuteFunction(properties, property, settings_)
	
end
function cmd_txt_to_list(value) -- store all the commands one-by-one;
	local cmd_list = {}; 
	local cvalue = ""
	local x = 1
	while x <= #value do
		local char = string.sub(value, x, x)
		if char == ";" then -- move to the next cmd;
			if strTrim(cvalue) then
				cvalue = strTrim(cvalue)
				table.insert(cmd_list, #cmd_list + 1, cvalue)
			end
			cvalue = ""
		else
			cvalue = cvalue .. char
			if APP_ACTIONS:isOnFrontEnd(strTrim(cvalue)) then -- get the code block data;
				-- check for an opening curly bracket ({); and closing bracket(})
				local isValidOnFrontEndEvent = false;
				local brvalue = "";
				local _end = nil
				local i = x + 1;
				while (i <= #value) do
					local charI = string.sub(value, i, i);
					if isValidOnFrontEndEvent then -- get the closing bracket (})
						if charI == "}" then
							_end = i;
							isValidOnFrontEndEvent = true;break;
						else
							brvalue = brvalue .. charI;
						end
					else
						if charI == "{" then
							isValidOnFrontEndEvent = true;
						elseif strTrim(charI) ~= "" then -- error;
							isValidOnFrontEndEvent = false;break
						end
					end
					i = i + 1
				end
				if isValidOnFrontEndEvent == false or _end == nil then -- error;
					return true
				else -- push the (brvalue) into the list;
					cvalue = strTrim(cvalue); brvalue = strTrim(brvalue)
					table.insert(cmd_list, #cmd_list + 1, cvalue .. "{" .. brvalue .. "}");
					x = _end
					cvalue = ""
				end
			end
		end
		x = x + 1
	end
	cvalue = strTrim(cvalue)
	if cvalue ~= "" then
		table.insert(cmd_list, #cmd_list + 1, cvalue)
	end
	return cmd_list;
end
function ConditionalStatementInit(properties, property, settings_)
	if settings_ == nil then return false end
	local st = obs.obs_data_get_string(settings_, "conditional_setup_group_statement_list")
	-- reset options;
	local action_list = obs.obs_properties_get(properties, "conditional_setup_group_action_list")
	obs.obs_property_list_clear(action_list)
	obs.obs_property_list_add_string(action_list, "Select<!>","<none>")
	-- 
	local target_list = obs.obs_properties_get(properties, "conditional_setup_group_target_list")
	local fallback_list = obs.obs_properties_get(properties, "conditional_setup_group_fall_list")
	local enter_value = obs.obs_properties_get(properties, "conditional_setup_group_action_value")
	obs.obs_property_list_clear(fallback_list)
	obs.obs_property_list_add_string(fallback_list, "Select<!>","<none>")
	obs.obs_property_set_visible(enter_value, false)
	if st == "" or st == nil or st == "<none>" then
		return true
	end
	if st == "cdwn" then
		-- setup action list;
		obs.obs_property_set_visible(target_list, true)
		
		for _, n in ipairs(prset_action_ls) do
			if n ~= "<blink>" then
				obs.obs_property_list_add_string(action_list, n,n)
			end
			obs.obs_property_list_add_string(fallback_list, n,n)
		end
	elseif st == "cdf" then
		-- setup action list;
		for _, n in ipairs(prset_flb_ls) do
			obs.obs_property_list_add_string(action_list, n,n)
		end
		for _, n in ipairs(prset_action_ls) do
			if n ~= "<reset>" and n ~= "<end>" then
				obs.obs_property_list_add_string(fallback_list, n,n)
			end
		end
	end
	return true
end
-- SHOWS  THE Conditional setup;
function ConfigureSetup(properties, property, settings_)
	if settings_ == nil then return false end
	local cond_list = 
	obs.obs_properties_get(properties, "conditional_setup_group_statement_list"); local target_list = 
	obs.obs_properties_get(properties, "conditional_setup_group_target_list"); local action_list = 
	obs.obs_properties_get(properties, "conditional_setup_group_action_list"); local fallback_list = 
	obs.obs_properties_get(properties, "conditional_setup_group_fall_list")
	local source_target = obs.obs_data_get_string(settings_, "source_list")
	local config_cond_item = obs.obs_properties_get(properties, "conditional_setup_group")
	obs.obs_data_set_string(settings_, "conditional_setup_group_statement_list", "<none>")
	obs.obs_data_set_string(settings_, "conditional_setup_group_target_list", "<none>")
	obs.obs_data_set_string(settings_, "conditional_setup_group_action_list", "<none>")
	obs.obs_data_set_string(settings_, "conditional_setup_group_fall_list", "<none>")
	obs.obs_data_set_string(settings_,"conditional_setup_group_action_value","")
	HIDE_ALL_PRSET_LS(properties, true); -- hide all prset;
	local function init_target_ls()
		obs.obs_property_list_clear(target_list)
		obs.obs_property_list_add_string(target_list, "Select<!>","<none>")
		-- preset source list;
		--[[
		for i, n in ipairs(prset_source_ls) do
			obs.obs_property_list_add_string(target_list, n, n)
		end
		--]]
		local source_names = get_all_current_sources_from_scene()
		for i, v in ipairs(source_names) do
			obs.obs_property_list_add_string(target_list, v,v)
		end
	end
	if config_cond_item == nil then -- error;
		
		return true
	else -- show;
		obs.obs_property_set_visible(config_cond_item, true)
	end
	

	-- [[ statement ]]
		if not cond_list then -- create statement list
			cond_list = obs.obs_properties_add_list(configureOp, "conditional_setup_group_statement_list", "Statement(*)", obs.OBS_COMBO_TYPE_LIST, obs.OBS_COMBO_FORMAT_STRING)
			obs.obs_property_list_add_string(cond_list, "Select<!>","<none>")
			obs.obs_property_set_modified_callback(cond_list, ConditionalStatementInit)
			for _, opt in pairs(hns_cond_list) do
				if opt then
					obs.obs_property_list_add_string(cond_list, opt.name, opt.id)
				end
			end
		end
	-- [[ target ]]
		if not target_list then
			target_list = obs.obs_properties_add_list(configureOp, "conditional_setup_group_target_list", "Target(*)", obs.OBS_COMBO_TYPE_LIST, obs.OBS_COMBO_FORMAT_STRING)
		end
		init_target_ls()
	-- [[ action ]]
		if not action_list then
			action_list = obs.obs_properties_add_list(configureOp, "conditional_setup_group_action_list", "Action(*)", obs.OBS_COMBO_TYPE_LIST, obs.OBS_COMBO_FORMAT_STRING)
			obs.obs_property_list_add_string(action_list, "Select<!>","<none>")
			obs.obs_property_set_modified_callback(action_list, function(properties, property, settings_)
				if settings_ == nil then return false end
				local s = obs.obs_data_get_string(settings_, "conditional_setup_group_action_list")
				
				if s == "" or s == nil then return false end
				local enter_value = obs.obs_properties_get(properties, "conditional_setup_group_action_value")
				if s == "<text>" then
					obs.obs_property_set_visible(enter_value, true)
				else
					obs.obs_property_set_visible(enter_value, false)
				end
				return true
			end)
		end
	-- [[ value ]]
		local conditional_setup_group_action_value = obs.obs_properties_get(properties,"conditional_setup_group_action_value")
		if not conditional_setup_group_action_value then
			conditional_setup_group_action_value = obs.obs_properties_add_text(configureOp, "conditional_setup_group_action_value", "Enter Value", obs.OBS_TEXT_DEFAULT)
			obs.obs_property_set_long_description(conditional_setup_group_action_value, "Enter some value (optional)")
		end
		obs.obs_property_set_visible(conditional_setup_group_action_value, false)
	-- [[ fallback ]]
		if not fallback_list then
			fallback_list = obs.obs_properties_add_list(configureOp, "conditional_setup_group_fall_list", "Source fallback(*)", obs.OBS_COMBO_TYPE_LIST, obs.OBS_COMBO_FORMAT_STRING)
			obs.obs_property_list_add_string(fallback_list, "Select<!>","<none>")
		end
	-- [[ Error Label ]]
		local warn_label = obs.obs_properties_get(properties, "conditional_setup_group_error")
		if not warn_label then
			warn_label = obs.obs_properties_add_text(configureOp, "conditional_setup_group_error", "...", obs.OBS_TEXT_INFO)
			obs.obs_property_text_set_info_type(warn_label, obs.OBS_TEXT_INFO_ERROR)
			obs.obs_property_set_visible(warn_label, false)
		end
	-- [[ Execute Button ]]
		local execute_btn = obs.obs_properties_get(properties, "conditional_setup_group_execute_btn")
		if not execute_btn then
			obs.obs_properties_add_button(configureOp, "conditional_setup_group_execute_btn", "Execute", function(properties, property)
				local stm_v = obs.obs_data_get_string(settings_, "conditional_setup_group_statement_list")
				local stm_tar_v= obs.obs_data_get_string(settings_, "conditional_setup_group_target_list")
				local stm_act_v =  obs.obs_data_get_string(settings_, "conditional_setup_group_action_list")
				local stm_flb_v = obs.obs_data_get_string(settings_, "conditional_setup_group_fall_list")
				local stm_val = obs.obs_data_get_string(settings_, "conditional_setup_group_action_value")
				local source_target = obs.obs_data_get_string(settings_, "source_list")
				obs.obs_property_set_visible(warn_label, false)
				if (stm_v == "" or stm_v == "<none>" or stm_v == nil) or (stm_act_v == "" or stm_act_v  == "<none>" or stm_act_v == nil) or (stm_flb_v == "" or stm_flb_v == "<none>" or stm_flb_v == nil) then
					obs.obs_property_set_visible(warn_label, true)
					obs.obs_property_set_description(warn_label, "(Warning) select all the required options!")
					return true
				elseif stm_v == "cdwn" and (stm_tar_v == "" or stm_tar_v  == "<none>" or stm_tar_v == nil) then
					obs.obs_property_set_visible(warn_label, true)
					obs.obs_property_set_description(warn_label, "(Warning) select all the required options!")
					return true
				end
				if source_target == "<all_like>" or source_target == "<rand_like>" then
					local txt = obs.obs_data_get_string(settings_, "obj_setting_text")
					if txt == nil or strTrim(txt) == "" then -- Warning
						obs.obs_property_set_visible(warn_label,  true)
						obs.obs_property_set_description(warn_label, "(Warning) text/word is required for {all_like, rand_like}")
						return true
					end
					source_target = rplr_char(source_target, "<>") .. "_" .. txt
					obs.obs_property_set_visible(warn_label,  false)
				end
				local insert_scope = obs.obs_data_get_string(settings_, "conditional_setup_scene_list")
				-- Insert new action (statement);
				if insert_scope == "<none>" then
					insert_scope = "__HActionListS__" -- default global collection
				else -- create a new array collection;
					if insert_scope == "<default>" then -- get the actual name of the scene;
						local ls = obs.obs_properties_get(properties, "conditional_setup_scene_list")
						local lsc = obs.obs_property_list_item_count(ls)
						for i = 0, lsc - 1 do
							local str = obs.obs_property_list_item_string(ls, i)
							local name = obs.obs_property_list_item_name(ls, i)
							if str == insert_scope then
								insert_scope = ""
								local arc_ls = splitBy(name, "|")
								for i = 1, #arc_ls - 1 do
									insert_scope = insert_scope .. tostring(arc_ls[i])
								end
								break
							end
						end
					end
					local act_sct_arr = obs.obs_data_get_array(settings_, insert_scope)
					if act_sct_arr == nil then
						act_sct_arr = obs.obs_data_array_create()
						obs.obs_data_set_array(settings_, insert_scope, act_sct_arr)
					end
					obs.obs_data_array_release(act_sct_arr)
				end
				if stm_val ~= "" then
					stm_val =  stm_val .. "|"
				end
				local insert_stm = "<cond>|"..tostring(stm_v) .. "|" .. tostring(stm_tar_v) .. "|" .. tostring(stm_act_v) .. "|" .. tostring(stm_val) .. source_target .. "|" .. tostring(stm_flb_v)
				if INSERT_INTO_OBS_ARRAY__(insert_scope, insert_stm) then -- all good :)
					obs.obs_data_set_string(settings_, "conditional_setup_group_statement_list", "<none>")
					obs.obs_data_set_string(settings_, "conditional_setup_group_target_list", "<none>")
					obs.obs_data_set_string(settings_, "conditional_setup_group_action_list", "<none>")
					obs.obs_data_set_string(settings_, "conditional_setup_group_fall_list", "<none>")
					obs.obs_data_set_string(settings_,"conditional_setup_group_action_value","")
					obs.obs_property_set_visible(obs.obs_properties_get(properties,"conditional_setup_group_action_value"), false)
				else
					obs.obs_property_set_visible(warn_label, true)
					obs.obs_property_set_description(warn_label, "(Error) something bad happened! reload the script to fix")
				end
				
				InitScreen(properties, property, settings_)
				init()
				return true
			end)
		end
	return true
end

function ActionSetup(properties, property, settings_)
	if settings_ == nil then return false end
	local action_setup_group = obs.obs_properties_get(properties, "action_setup_group"); 
	HIDE_ALL_PRSET_LS(properties, true)
	if action_setup_group == nil then -- error ;
		return true;
	end
	obs.obs_property_set_visible(action_setup_group, true)
	
	-- [[ Hide Time ]]
		obs.obs_data_set_int(settings_, "action_setup_group_hide_time", 1)
		obs.obs_data_set_string(settings_, "action_setup_group_hide_time_option", "<none>")
		obs.obs_data_set_bool(settings_, "action_setup_group_hide_time_rand", false)
		local action_setup_group_hide_time = obs.obs_properties_get(properties, "action_setup_group_hide_time")
		if not action_setup_group_hide_time then -- create hide time option;
			action_setup_group_hide_time = obs.obs_properties_add_int(actionOp, "action_setup_group_hide_time", "Hide Time: ",1,10000000,1)
			-- time option;
			local action_setup_group_hide_time_option = obs.obs_properties_add_list(actionOp, "action_setup_group_hide_time_option", "",obs.OBS_COMBO_TYPE_LIST, obs.OBS_COMBO_FORMAT_STRING)
			obs.obs_property_list_add_string(action_setup_group_hide_time_option, "Duration<!>", "<none>")
			for _, tmt in ipairs(app_time_option) do
				obs.obs_property_list_add_string(action_setup_group_hide_time_option, tmt.name, tmt.id)
			end
			-- random option
			local action_setup_group_hide_time_rand = obs.obs_properties_add_bool(actionOp, "action_setup_group_hide_time_rand", "Randomize")
			
		end
	-- [[ Show Time ]]
		obs.obs_data_set_int(settings_, "action_setup_group_show_time", 1)
		obs.obs_data_set_string(settings_, "action_setup_group_show_time_option", "<none>")
		obs.obs_data_set_bool(settings_, "action_setup_group_show_time_rand", false)
		local action_setup_group_show_time = obs.obs_properties_get(properties, "action_setup_group_show_time")
		if not action_setup_group_show_time then -- create show time option;
			action_setup_group_show_time = obs.obs_properties_add_int(actionOp, "action_setup_group_show_time", "Show Time: ",1,10000000,1)
			-- time option;
			local action_setup_group_show_time_option = obs.obs_properties_add_list(actionOp, "action_setup_group_show_time_option", "",obs.OBS_COMBO_TYPE_LIST, obs.OBS_COMBO_FORMAT_STRING)
			obs.obs_property_list_add_string(action_setup_group_show_time_option, "Duration<!>", "<none>")
			for _, tmt in ipairs(app_time_option) do
				obs.obs_property_list_add_string(action_setup_group_show_time_option, tmt.name, tmt.id)
			end
			-- random option
			local action_setup_group_show_time_rand = obs.obs_properties_add_bool(actionOp, "action_setup_group_show_time_rand", "Randomize")
			
		end
	-- [[ Repeat Time ]]
		obs.obs_data_set_int(settings_, "action_setup_group_repeat_number", 1)
		obs.obs_data_set_int(settings_, "action_setup_group_repeat_time", -1);
		obs.obs_data_set_bool(settings_, "action_setup_group_repeat_rand", false)
		obs.obs_data_set_string(settings_, "action_setup_group_repeat_option", "<none>")
		obs.obs_data_set_string(settings_, "action_setup_group_repeat", "<inf>")
		local action_setup_group_repeat = obs.obs_properties_get(properties, "action_setup_group_repeat")
		if not action_setup_group_repeat then -- create repeat option;

			
			action_setup_group_repeat =	obs.obs_properties_add_list(actionOp, "action_setup_group_repeat", "Repeat Action:",obs.OBS_COMBO_TYPE_LIST, obs.OBS_COMBO_FORMAT_STRING)
			obs.obs_property_list_add_string(action_setup_group_repeat, "Infinite", "<inf>")
			obs.obs_property_list_add_string(action_setup_group_repeat, "Custom", "<cus>")
			
			-- Repeat number;
			local action_setup_group_repeat_number = obs.obs_properties_add_int(actionOp, "action_setup_group_repeat_number", "Number:",1,10000000,1)
			obs.obs_property_set_long_description(action_setup_group_repeat_number, "How many times do you want the action(hide/show) to execute for?")
			-- Repeat Reset time;
			local action_setup_group_repeat_time = obs.obs_properties_add_int(actionOp, "action_setup_group_repeat_time", "Reset After:",-1,10000000,1)
			obs.obs_property_set_long_description(action_setup_group_repeat_time, "How long do you want it to reset after it has reached the repetition limit?")
			local action_setup_group_repeat_rand = obs.obs_properties_add_bool(actionOp, "action_setup_group_repeat_rand", "Randomize")
			
			local action_setup_group_repeat_option = obs.obs_properties_add_list(actionOp, "action_setup_group_repeat_option", "",obs.OBS_COMBO_TYPE_LIST, obs.OBS_COMBO_FORMAT_STRING)
			obs.obs_property_list_add_string(action_setup_group_repeat_option, "Duration<!>", "<none>")
			for _, tmt in ipairs(app_time_option) do
				obs.obs_property_list_add_string(action_setup_group_repeat_option, tmt.name, tmt.id)
			end
			-- Repeat list modify!
			obs.obs_property_set_modified_callback(action_setup_group_repeat, function(properties, property, settings_)
				if settings_ == nil then return false end
				local rp = obs.obs_data_get_string(settings_, "action_setup_group_repeat")
				if rp == "<cus>" then
					obs.obs_property_set_visible(action_setup_group_repeat_number, true)
					obs.obs_property_set_visible(action_setup_group_repeat_time, true)
					obs.obs_property_set_visible(action_setup_group_repeat_option, true)
					obs.obs_property_set_visible(action_setup_group_repeat_rand, true)
				else
					-- reset;
					obs.obs_data_set_int(settings_, "action_setup_group_repeat_number", 1)
					obs.obs_data_set_int(settings_, "action_setup_group_repeat_time", -1);
					obs.obs_data_set_bool(settings_, "action_setup_group_repeat_rand", false)
					obs.obs_data_set_string(settings_, "action_setup_group_repeat_option", "<none>")
					obs.obs_property_set_visible(action_setup_group_repeat_number, false)
					obs.obs_property_set_visible(action_setup_group_repeat_time, false)
					obs.obs_property_set_visible(action_setup_group_repeat_option, false)
					obs.obs_property_set_visible(action_setup_group_repeat_rand, false)
				end
				return true
			end)
		
			obs.obs_property_set_visible(action_setup_group_repeat_number, false)
			obs.obs_property_set_visible(action_setup_group_repeat_time, false)
			obs.obs_property_set_visible(action_setup_group_repeat_option, false)
			obs.obs_property_set_visible(action_setup_group_repeat_rand, false)
		end
	-- [[ Action Error ]]
		local action_setup_error = obs.obs_properties_get(properties, "action_setup_error")
		if not action_setup_error then
			action_setup_error = obs.obs_properties_add_text(actionOp, "action_setup_error","", obs.OBS_TEXT_INFO)
			obs.obs_property_text_set_info_type(action_setup_error, obs.OBS_TEXT_INFO_ERROR)
		end
		obs.obs_property_set_visible(action_setup_error, false)
	-- [[ Execute ]]
		local action_setup_btn = obs.obs_properties_get(properties, "action_setup_btn")
		if not action_setup_btn then
			-- execute action;
			action_setup_btn = obs.obs_properties_add_button(actionOp, "action_setup_btn", "Execute", function(properties, property)
				local source_target = obs.obs_data_get_string(settings_, "source_list")
				if source_target == "<all_like>" or source_target == "<rand_like>" then
					local txt = obs.obs_data_get_string(settings_, "obj_setting_text")
					if txt == nil or strTrim(txt) == "" then -- Warning
						obs.obs_property_set_visible(action_setup_error,  true)
						obs.obs_property_set_description(action_setup_error, "(Warning) text/word is required for {all_like, rand_like}")
						return true
					end
					source_target = rplr_char(source_target, "<>") .. "_" .. txt
					obs.obs_property_set_visible(action_setup_error,  false)
				end
				local action_tmt_hide = obs.obs_data_get_int(settings_,"action_setup_group_hide_time")
				local action_tmt_show = obs.obs_data_get_int(settings_,"action_setup_group_show_time")
				local action_tmt_show_rand = obs.obs_data_get_bool(settings_, "action_setup_group_show_time_rand")
				local action_tmt_hide_rand = obs.obs_data_get_bool(settings_, "action_setup_group_hide_time_rand")
				local action_tmt_show_dur = obs.obs_data_get_string(settings_, "action_setup_group_show_time_option")
				local action_tmt_hide_dur = obs.obs_data_get_string(settings_, "action_setup_group_hide_time_option")
				local action_rp_val = obs.obs_data_get_int(settings_, "action_setup_group_repeat_number")
				local action_rp_tmt = obs.obs_data_get_int(settings_, "action_setup_group_repeat_time")
				local action_rp_rand = obs.obs_data_get_bool(settings_, "action_setup_group_repeat_rand")
				local action_rp_dur = obs.obs_data_get_string(settings_, "action_setup_group_repeat_option")
				local rp = obs.obs_data_get_string(settings_, "action_setup_group_repeat")
				local action_sct = obs.obs_data_get_string(settings_, "action_setup_scene_list")
				obs.obs_property_set_visible(action_setup_error,  false)
				-- hide time error;
				if action_tmt_hide == nil or action_tmt_hide <= 0 then
					obs.obs_property_set_visible(action_setup_error,  true)
					obs.obs_property_set_description(action_setup_error, "(Hide) time cannot be less than 1!")
					return true
				elseif action_tmt_hide_dur == nil or action_tmt_hide_dur == "" or action_tmt_hide_dur == "<none>" then
					obs.obs_property_set_visible(action_setup_error,  true)
					obs.obs_property_set_description(action_setup_error, "(Hide) time type is expected!")
					return true
				end
				-- show time error;
				if action_tmt_show == nil or action_tmt_show <= 0 then
					obs.obs_property_set_visible(action_setup_error,  true)
					obs.obs_property_set_description(action_setup_error, "(Show) time cannot be less than 1!")
					return true
				elseif action_tmt_show_dur == nil or action_tmt_show_dur == "" or action_tmt_show_dur == "<none>" then
					obs.obs_property_set_visible(action_setup_error,  true)
					obs.obs_property_set_description(action_setup_error, "(Show) time type is expected!")
					return true
				end
				
				-- repeat error
				if rp == "<cus>" then
					if action_rp_val <= 0 then
						obs.obs_property_set_visible(action_setup_error,  true)
						obs.obs_property_set_description(action_setup_error, "(Repeat) number cannot be less than 1")
						return true
					--[[elseif action_rp_tmt <= 0 then
						obs.obs_property_set_visible(action_setup_error,  true)
						obs.obs_property_set_description(action_setup_error, "(Reset after) time cannot be less than 1")
						return true
					elseif action_rp_dur == "<none>" then
						obs.obs_property_set_visible(action_setup_error,  true)
						obs.obs_property_set_description(action_setup_error, "(Reset after) time type is expected!")
						return true]]
					end
				end
				--
				if action_tmt_hide_rand == true then
					action_tmt_hide = "%" .. action_tmt_hide;
				end
				action_tmt_hide = tostring(action_tmt_hide) .. tostring(action_tmt_hide_dur)
				--
				if action_tmt_show_rand then
					action_tmt_show = "%" .. action_tmt_show
				end
				action_tmt_show = tostring(action_tmt_show) .. tostring(action_tmt_show_dur)
				--
				local rp_act = "<inf>";
				if rp == "<cus>" then
					
					rp_act = "x" .. tostring(action_rp_val)
					if action_rp_tmt > 0  then
						if action_rp_rand then
							action_rp_rand = "%"
						else
							action_rp_rand = ""
						end
						rp_act = rp_act .. "|" .. action_rp_rand .. tostring(action_rp_tmt) .. tostring(action_rp_dur)
					end
						
				end
				-- Insert new action (hide);
				if action_sct == "<none>" then
					action_sct = "__HActionListS__" -- default global collection
				else -- create a new array collection;
					if action_sct == "<default>" then -- get the actual name of the scene;
						local ls = obs.obs_properties_get(properties, "action_setup_scene_list")
						local lsc = obs.obs_property_list_item_count(ls)
						for i = 0, lsc - 1 do
							local str = obs.obs_property_list_item_string(ls, i)
							local name = obs.obs_property_list_item_name(ls, i)
							if str == action_sct then
								action_sct = ""
								local arc_ls = splitBy(name,"|")
								for i = 1, #arc_ls - 1 do
									action_sct = action_sct .. tostring(arc_ls[i])
								end
								break
							end
						end
					end
						
					local act_sct_arr = obs.obs_data_get_array(settings_, action_sct)
					if act_sct_arr == nil then
						act_sct_arr = obs.obs_data_array_create()
						obs.obs_data_set_array(settings_, action_sct, act_sct_arr)
					end
					obs.obs_data_array_release(act_sct_arr)
				end
				local insert_act = 0
				if INSERT_INTO_OBS_ARRAY__(action_sct,
				"<act>|(hide)|"..strTrim(source_target).."|".. action_tmt_hide .. "|" .. rp_act) then
					insert_act = insert_act + 1
				else -- error
					obs.obs_property_set_visible(action_setup_error,  true)
					obs.obs_property_set_description(action_setup_error, "(Execute) unable to execute action at this time; please try again!")
				end
				-- Insert new action (show);
				if INSERT_INTO_OBS_ARRAY__(action_sct,
				"<act>|(show)|"..strTrim(source_target).."|".. action_tmt_show .. "|" .. rp_act) then
					insert_act = insert_act + 1
				else -- error
					obs.obs_property_set_visible(action_setup_error,  true)
					obs.obs_property_set_description(action_setup_error, "(Execute) unable to execute action at this time; please try again!")
				end
				if insert_act >= 2 then
					obs.obs_data_set_int(settings_,"action_setup_group_hide_time", 1)
					obs.obs_data_set_int(settings_,"action_setup_group_show_time", 1)
					obs.obs_data_set_bool(settings_, "action_setup_group_show_time_rand", false)
					obs.obs_data_set_bool(settings_, "action_setup_group_hide_time_rand", false)
					obs.obs_data_set_string(settings_, "action_setup_group_show_time_option", "<none>")
					obs.obs_data_set_string(settings_, "action_setup_group_hide_time_option", "<none>")
					obs.obs_data_set_int(settings_, "action_setup_group_repeat_number", 1)
					obs.obs_data_set_int(settings_, "action_setup_group_repeat_time", 1)
					obs.obs_data_set_string(settings_, "action_setup_group_repeat_option", "<none>")
					obs.obs_data_set_string(settings_, "action_setup_group_repeat", "<none>")
				else -- error
				end
				InitScreen(properties, property, settings_)
				init()
				return true
			end)
		end
	return true
end
function strTrim(str)
	if not str then return "" end
	return str:gsub("^%s*(.-)%s*$", "%1");
end
function splitBy(string_value, op)
	if not string_value then return nil end
    local pipes = {}
    local whole = ""
    for char in string.gmatch(string_value,".") do
        if op == char then
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
__LIST_SCENE_ITEMS__ = {}

function __GroupList()
	-- Get the current scene
	local currentSource = obs.obs_frontend_get_current_scene()
	local currentScene = obs.obs_scene_from_source(currentSource)
	--
	local list;
	if currentScene ~= nil and currentSource ~= nil then
		-- Enumerate the items in the current scene
		local sceneItems = obs.obs_scene_enum_items(currentScene)
		if sceneItems ~= nil then
			list = {}
			for _, sceneItem in ipairs(sceneItems) do
				local source = obs.obs_sceneitem_get_source(sceneItem)
				if source ~= nil then
					local sourceName = obs.obs_source_get_name(source)
					if obs.obs_sceneitem_is_group(sceneItem) then
						table.insert(list, sourceName)
					end
					
				end
			end
			obs.sceneitem_list_release(sceneItems)
		end
	end
	obs.obs_source_release(currentSource)
	return list;
end
function __GET_SCENE_ITEM__(item_name)
    local sourceObject = obs.obs_get_source_by_name(item_name)
	local currentSource = obs.obs_frontend_get_current_scene()
	local currentScene = obs.obs_scene_from_source(currentSource)
    if currentScene ~= nil then
		local scene_item = obs.obs_scene_sceneitem_from_source(currentScene, sourceObject)
		-- check in groups if the current item doesn't exist;
		if not scene_item then
			for _, gN in ipairs(__GroupList()) do
				local groupSource =	obs.obs_get_source_by_name(gN)
				if groupSource then
					local groupItem = obs.obs_scene_sceneitem_from_source(currentScene, groupSource)
					obs.obs_source_release(groupSource)
					if groupItem then -- iterate through the items in the group and check for (item_name);
						local hasItem = false
						local __ls = obs.obs_sceneitem_group_enum_items(groupItem)
						if __ls ~= nil then
							for _, it in ipairs(__ls) do
								local s = obs.obs_sceneitem_get_source(it)
								if s ~= nil then
									local sN = obs.obs_source_get_name(s)
									if sN == item_name then
										obs.obs_sceneitem_addref(it)
										scene_item = it
										hasItem = true; break
									end
								end
							end
							obs.sceneitem_list_release(__ls)
						end
						obs.obs_sceneitem_release(groupItem)
						if hasItem then
							break
						end
					end
					
				end
			end
		end
		obs.obs_source_release(currentSource)
		obs.obs_source_release(sourceObject)
		local item_obj = {
			index = (#__LIST_SCENE_ITEMS__) + 1;
			item = scene_item
		}
		item_obj["release"] = function()
			
			if item_obj.item ~= nil then
				obs.obs_sceneitem_release(item_obj.item)
				item_obj.item = nil
				table.remove(__LIST_SCENE_ITEMS__, item_obj.index)
				return true
			end
			table.remove(__LIST_SCENE_ITEMS__, item_obj.index)
			return false
		end
		table.insert(__LIST_SCENE_ITEMS__, item_obj)
		return __LIST_SCENE_ITEMS__[#__LIST_SCENE_ITEMS__]
	end
	obs.obs_source_release(currentSource)
	obs.obs_source_release(sourceObject)
	return nil
end
function INSERT_INTO_OBS_ARRAY__(array_name, value)
	if array_name == nil or array_name == "" then
		return false
	end
	local __array_list = obs.obs_data_get_array(__settings__, array_name)
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


function setSourceVisible(source_name, enable)
	if source_name == nil or (not type(source_name) == "string") or source_name == ""  then
		return false
	end
	local __item = __GET_SCENE_ITEM__(source_name)
    if __item ~= nil then
		obs.obs_sceneitem_set_visible(__item.item, enable)
		__item.release()
	end
    return true
end

--- CALLBACKS

function onEvent(event)
	__GLOBAL_CLIENT_EVENT = event
	if event == obs.OBS_FRONTEND_EVENT_SCENE_CHANGED then -- scene changed!
		init()
	elseif event == obs.OBS_FRONTEND_EVENT_SCRIPTING_SHUTDOWN then -- backup cleaner sceneitems;
		obs.timer_remove(main)
		for _, item in ipairs(__LIST_SCENE_ITEMS__) do
			if item ~= nil and item.item ~= nil then
				obs.obs_sceneitem_release(item.item)
			end
		end
		__LIST_SCENE_ITEMS__ = {}
	elseif event == obs.OBS_FRONTEND_EVENT_STREAMING_STARTING then
		APP_LOG("Event {onstream} is now active!")
		APP_STREAMING_ACTIVE = true;
		init()
	elseif event == obs.OBS_FRONTEND_EVENT_RECORDING_STARTING then
		APP_LOG("Event {onrecord} is now active!")
		APP_RECORDING_ACTIVE = true;
		init()
	elseif event == obs.OBS_FRONTEND_EVENT_RECORDING_STOPPED then
		APP_RECORDING_ACTIVE = false;
		APP_LOG("Event {onrecord} is now disabled!")
		init()
	elseif event == obs.OBS_FRONTEND_EVENT_STREAMING_STOPPED then
		APP_STREAMING_ACTIVE = false;
		APP_LOG("Event {onstream} is now disabled!")
		init()
	end
end











INIT_MAIN = false
-- initialize the data;
init_list = {}
init_backup_list = {}
APP_STREAMING_ACTIVE = false
APP_RECORDING_ACTIVE = false

function init()
	if __GLOBAL_CLIENT_EVENT == obs.OBS_FRONTEND_EVENT_SCRIPTING_SHUTDOWN then
		if INIT_MAIN then
			obs.timer_remove(main)
		end
		return nil
	end
	-- clear
	if __settings__ == nil then -- some error handling ?
		return false
	end
	for _, iter in pairs(init_list) do -- set everything to default?
	
	end
	init_list = {
		Action = {}; Conion = {}
	}
	
	-- [[ Init operation ]]
		local __operations = obs.obs_data_array_create()
		
		local __global_operation = obs.obs_data_get_array(__settings__, "__HActionListS__")
		--
		local currSceneObj = obs.obs_frontend_get_current_scene()
		currSceneName = obs.obs_source_get_name(currSceneObj)
		local currScene = obs.obs_scene_from_source(currSceneObj)
		if currScene == nil then -- some error handling ?
			return false
		end
		obs.obs_source_release(currSceneObj)
		local __scene_operation = obs.obs_data_get_array(__settings__, currSceneName)
		-- put them together;
		if __scene_operation ~= nil then
			local length = obs.obs_data_array_count(__scene_operation)
			for i = 0, length - 1 do
				local __arrItem = obs.obs_data_array_item(__scene_operation, i)
				obs.obs_data_array_push_back(__operations, __arrItem)
				obs.obs_data_release(__arrItem)
			end
			obs.obs_data_array_release(__scene_operation)
		end
		--
		if __global_operation ~= nil then
			local length = obs.obs_data_array_count(__global_operation)
			for i = 0, length - 1 do
				local __arrItem = obs.obs_data_array_item(__global_operation, i)
				obs.obs_data_array_push_back(__operations, __arrItem)
				obs.obs_data_release(__arrItem)
			end
			obs.obs_data_array_release(__global_operation)
		end
		
			
		if __operations ~= nil then
			-- [[ Collect all the operations ]]
			local len = obs.obs_data_array_count(__operations)
			local Placement = 0
			local PlaceTable = {}
			for i = 0, len - 1 do
				local p_item = obs.obs_data_array_item(__operations,i)
				if p_item ~= nil then
					
					local value = obs.obs_data_get_string(p_item,"key")
					local list = nil
					if string.find(string.lower(value), "onrecord") == 1 and not APP_RECORDING_ACTIVE then -- NOT RECORDING
						value = ""
					elseif string.find(string.lower(value), "onrecord") == 1 and  APP_RECORDING_ACTIVE then
						value = string.sub(value, string.find(value, "{") + 1,string.find(value, "}") -1)
					end
					if string.find(string.lower(value), "onstream") == 1 and not APP_STREAMING_ACTIVE then -- NOT STREAMING
						value = ""
					elseif string.find(string.lower(value), "onstream") == 1 and APP_STREAMING_ACTIVE then
						value = string.sub(value, string.find(value, "{") + 1,string.find(value, "}") -1)
					end
					if value ~= "" and value ~= "" then
						list = splitBy(value, "|")
					end
					if list ~= nil and list[1] == "<act>" then
						Placement = Placement + 1
						local act_name = string.lower(strTrim(rplr_char(list[2],"()")))
						local act_target = rplr_char(strTrim(list[3]), "<>", "")
						local act_interval = time_splitter(list[4])
						local act_repeat = list[5]
						local act_reset = list[6]
						if act_interval.order == "%" and act_interval.value > 1 then
							act_interval.initalValue = math.random(1, act_interval.value)
						else
							act_interval.initalValue = act_interval.value
						end

						-- check to see if the target is hidden or shown by default;
						--
						local __sceneItem;
						if act_target ~= "all" and not APP_ACTIONS:IsLikeAction(act_target) and act_target ~= "rand" then
							__sceneItem = __GET_SCENE_ITEM__(act_target)
						end
						
						local ActT = {
							name = act_target; time = {
								init = act_interval.initalValue; max = act_interval.value; order = act_interval.order;
								type = act_interval.type; tick = os.clock() * 1000
							}
						}
						if act_repeat ~= nil and act_repeat ~= "" and act_repeat ~= "<none>" and act_repeat ~= "<inf>" then
							local rp = tonumber(rplr_char(act_repeat, "x"))
							local rs = nil
							if act_reset ~= "<none>" and act_reset ~= nil and act_reset ~= "" then
								rs = time_splitter(act_reset)
								rs["init"] = rs.value
							end
							ActT["repeat"] = {
								count = 0; max = rp; reset = rs
							}
						end
						if __sceneItem then
							if act_name == "show" then
								ActT.isShown = obs.obs_sceneitem_visible(__sceneItem.item)
							elseif act_name == "hide" then
								ActT.isHidden = not obs.obs_sceneitem_visible(__sceneItem.item)
							end
						else
							if act_name == "show" then
								ActT.isShown = true
							elseif act_name == "hide" then
								ActT.isHidden = false
							end
						end
						--
						if __sceneItem then __sceneItem.release() end
						PlaceTable[act_name] = ActT
						init_list["Action"][act_target] = {
							event =  nil; tick = 0
						}
						if Placement == 2 then
							table.insert(init_list["Action"], PlaceTable)
							PlaceTable = {}
							Placement = 0
						end
					elseif list ~= nil and list[1] == "<cond>" then
						local cdwn_name = string.lower(strTrim(list[2]))
						local cdwn_target = strTrim(list[3])
						local cdwn_act = strTrim(rplr_char(string.lower(list[4]), "<>()||"))
						local cdwn_main = strTrim(list[5])
						local cdwn_do = strTrim(rplr_char(string.lower(list[6]), "<>()||"))
						local cdwn_val = strTrim(list[7])
						
						if cdwn_name == "cdwn" then
							if init_list.Conion[cdwn_target] == nil then
								init_list.Conion[cdwn_target] = {}
							end
							if init_list.Conion[cdwn_target][cdwn_name] == nil then
								init_list.Conion[cdwn_target][cdwn_name] = {}
							end
							if init_list.Conion[cdwn_target][cdwn_name][cdwn_act] == nil then
								init_list.Conion[cdwn_target][cdwn_name][cdwn_act] = {}
							end
							local OpIndex = #init_list.Conion[cdwn_target][cdwn_name][cdwn_act] + 1
							if cdwn_do == "blink" then
								cdwn_do = function(n)
									if n == nil then
										n = cdwn_main
									end
									return Doblink(n, 100)
								end
							elseif cdwn_do == "hide" then
								cdwn_do = function(n)
									if n == nil then
										n = cdwn_main
									end
									return setSourceVisible(n, false)
								end
							elseif cdwn_do == "show" then
								cdwn_do = function(n)
									if n == nil then
										n = cdwn_main
									end
									return setSourceVisible(n, true)
								end
							elseif cdwn_do == "reset" then
								cdwn_do = function(n)
									if n == nil then
										n = cdwn_main
									end
									local xiter = nil
									for _, iter in ipairs(init_backup_list.Action) do
										if iter and iter.hide.name == n and iter.show and iter.show.name == n then
											xiter = table.copy(iter, true)
											for _, nextIter in ipairs(init_list.Action) do
												if nextIter and nextIter.hide and nextIter.hide.name and nextIter.hide.name == iter.hide.name then -- found the same object(Now init end)
													return false
												end
											end
											break
										end
									end
									if xiter ~= nil then
										table.insert(init_list.Action, xiter)
									end
								end
							elseif cdwn_do == "end" then
								cdwn_do = function(n)
									-- lookup for the operation to end;
									if n == nil then
										n = cdwn_main
									end
									for _, iter in ipairs(init_backup_list.Action) do
										if iter and iter.hide.name == n and iter.show and iter.show.name == n then
											-- initial an end from (init_list)
											for _, nextIter in ipairs(init_list.Action) do
												if nextIter and nextIter.hide and nextIter.hide.name and nextIter.hide.name == iter.hide.name then -- found the same object(Now init end)
													if nextIter.hide and nextIter.hide["repeat"] then
														nextIter.hide["repeat"]["count"] = nextIter.hide["repeat"]["max"]
													end
													if nextIter.show and nextIter.show["repeat"] then
														nextIter.show["repeat"]["count"] = nextIter.show["repeat"]["max"]
														nextIter.show["repeat"]["reset"] = nil
														if nextIter.hide and nextIter.hide["repeat"] then
															nextIter.hide["repeat"]["reset"] = nil
														end
													end
													break
												end
											end
										end
									end
								end
							else
								cdwn_do = function() return nil end
							end
							table.insert(init_list.Conion[cdwn_target][cdwn_name][cdwn_act], {
								["do"] = cdwn_do; ["for"] = cdwn_main
							})
						elseif cdwn_name == "cdf" then
							if cdwn_act == "text" then
								if #list == 6 then
									cdwn_val = ""
									cdwn_do = strTrim(rplr_char(string.lower(list[6]), "<>()||"))
									cdwn_main = strTrim(list[5])
								else
									cdwn_val = strTrim(list[5])
									cdwn_do = strTrim(rplr_char(string.lower(list[7]), "<>()||"))
									cdwn_main = strTrim(list[6])
								end
							end
							if not init_list.Conion["cdf"] then
								init_list.Conion["cdf"] = {}
							end
							if not init_list.Conion["cdf"][cdwn_act] then
								init_list.Conion["cdf"][cdwn_act] = {}
							end
							if cdwn_do == "blink" then
								cdwn_do = function(n)
									if n == nil then
										n = cdwn_main
									end
									return Doblink(n, 100)
								end
							elseif cdwn_do == "hide" then
								cdwn_do = function(n)
									if n == nil then
										n = cdwn_main
									end
									return setSourceVisible(n, false)
								end
							elseif cdwn_do == "show" then
								cdwn_do = function(n)
									if n == nil then
										n = cdwn_main
									end
									return setSourceVisible(n, true)
								end
							else
								cdwn_do = function() return nil end
							end
							table.insert(init_list.Conion["cdf"][cdwn_act], {
								target = cdwn_target; ["for"] = cdwn_main; val = cdwn_val;
								["do"] = cdwn_do
							});
						end
					end
					
				end
				obs.obs_data_release(p_item)
			end
			obs.obs_data_array_release(__operations)
		end	
		
	
	init_backup_list = {
		Action = table.copy(init_list.Action, true);
		Conion = table.copy(init_list.Conion, true)
	}
	-- Init main()
	if(INIT_MAIN) then
		obs.timer_remove(main)
	end
	obs.timer_add(main, 1) -- every one milliseconds calls (main);
	INIT_MAIN = true
end

-- makes a source item blink :)
local LastBlinks = {}
function Doblink(targetName, caller)
	if caller == nil or caller <= 0 then
		caller = 600
	end
	if LastBlinks[targetName] then return false end
	LastBlinks[targetName] = true
	local localTick = os.time() * 1000
	local sceneItem = __GET_SCENE_ITEM__(targetName)
	if not sceneItem then return false end
	local sceneItemVisible = obs.obs_sceneitem_visible(sceneItem.item)
	local function blink()
		if __GLOBAL_CLIENT_EVENT == obs.OBS_FRONTEND_EVENT_SCRIPTING_SHUTDOWN then
			sceneItem.release()
			obs.timer_remove(blink)
			return nil 
		end
		if (os.time() * 1000) - localTick >= caller then -- manage events/loops
			obs.obs_sceneitem_set_visible(sceneItem.item, sceneItemVisible)
			LastBlinks[targetName] = nil
			sceneItem.release()
			return obs.timer_remove(blink)
		end
		local localVisible = obs.obs_sceneitem_visible(sceneItem.item)
		obs.obs_sceneitem_set_visible(sceneItem.item, not localVisible)
	end
	
	obs.timer_add(blink, 100)
	return true
end

-- [[ APP FUNCTIONS ]]
	APP_ACTIONS = {
		{cmd = "hide";clientSide = false}, {cmd = "show"; clientSide = false},
		{cmd = "onhide";clientSide = false},{cmd = "onshow"; clientSide = false},
		{cmd = "onshowend";clientSide = false},{cmd = "onhideend";clientSide = false},
		{cmd = "onstream";clientSide = true},{cmd = "onrecord";clientSide = true},
		{cmd = "if"; clientSide = false}, {cmd = "when"; clientSide = false}
	}
	function APP_ACTIONS:has(_value)
		for _, iter in ipairs(APP_ACTIONS) do
			if(type(iter.cmd) == "string") and type(_value) == 'string' then
				if strTrim(string.lower(iter.cmd)) == strTrim(string.lower(_value)) then
					return true
				end
			end
		end
		return false
	end
	function APP_ACTIONS:isOnFrontEnd(_value)
		if not _value or not type(_value) == "string" then
			return false
		end
		_value = strTrim(_value)
		if(APP_ACTIONS:has(_value)) then
			-- search for on
			local x,y = string.find(_value, "on")
			if type(x) == "number" and x == 1 and type(y) == "number" and y > x then
				for _, iter in ipairs(APP_ACTIONS) do
					if iter.clientSide and iter.cmd == _value then
						return true;
					end
				end
			end
		end
		return false
	end
	function APP_ACTIONS:isOnAction(_value)
		if not _value or not type(_value) == "string" then
			return false
		end
		_value = strTrim(_value)
		if(APP_ACTIONS:has(_value)) then
			-- search for on
			local x,y = string.find(_value, "on")
			if(type(x) == "number" and x > 0 and type(y) == "number" and y > 0) then
				return true;
			end
		end
		return false
	end

	function APP_ACTIONS:CmdTar(c)
		if type(c) ~= "string" then
			return nil
		end
		local call_act = ""
		local getList = string.gmatch(c, "[^_]+");
		local cmd_list = {}
		for x in getList do
			table.insert(cmd_list,x)
		end
		-- look for word (like);
		if not (#cmd_list > 2) then
			return
		end
		local index;
		for i, v in ipairs(cmd_list) do
			if(v == "like") then
				index = i + 1;break
			end
			if call_act ~= "" and i < #cmd_list then
				call_act = call_act .. "_";
			end
			call_act = call_act .. v
		end
		if index == nil then
			return
		end
		return call_act;
	end
	function APP_ACTIONS:IsLikeAction(cmd) -- checks if (cmd) has a (all_like_*)
		if not cmd or not strTrim(cmd) then return false end
		local ls = splitBy(cmd, "_")
		if #ls > 1 and ls[2] == "like" then return true end
		--if(APP_ACTIONS:GetLikeAction(cmd) ~= nil) then return true end
		return false;
	end
	function APP_ACTIONS:GetLikeAction(cmd) -- return like (target)
		if type(cmd) ~= "string" then
			return nil
		end
		local getList = string.gmatch(cmd, "[^_]+");
		local cmd_list = {}
		for x in getList do
			table.insert(cmd_list,x)
		end
		-- look for word (like);
		if not (#cmd_list > 2) then
			return
		end
		local index;
		for i, v in ipairs(cmd_list) do
			if(v == "like") then
				index = i + 1;break
			end
		end
		if index == nil then
			return
		end
		local act = ""
		for i = index, #cmd_list do
			if act ~= "" then act = act .. "_" end
			act = act .. cmd_list[i];
		end
		return act;
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
-- [[ MAIN EXECUTATION FUNCTION ]]
local TimeStart = os.clock() * 1000
local TimeEnd = 0
function main()
	if __GLOBAL_CLIENT_EVENT == obs.OBS_FRONTEND_EVENT_SCRIPTING_SHUTDOWN then
		
		return obs.timer_remove(blink)
	end
	-- operation hide/Show
	for k, iter in ipairs(init_list.Action) do
		
		if iter.hide and not iter.hide.isHidden and iter.show and iter.show.isShown then -- preform hide
			local function initHide()
				if __GLOBAL_CLIENT_EVENT == obs.OBS_FRONTEND_EVENT_SCRIPTING_SHUTDOWN then
					return
				end
				iter.hide.time.tick = 0
				
				iter.show.time.tick = os.clock() * 1000
				TimeStart = os.clock() * 1000
				iter.hide.isHidden = true
				iter.show.isShown = false
				if iter.hide.time.order == "%" then -- re-assign (init) to random value;
					iter.hide.time.init = math.random(1, iter.hide.time.max)
				end
				
				-- [[ ALL OR ALL_LIKE OR RAND OR RAND_LIKE ]]
					if iter.hide.name == "all" or (APP_ACTIONS:IsLikeAction(iter.hide.name) and APP_ACTIONS:CmdTar(iter.hide.name) == "all") then -- {ALL, ALL_LIKE}
						if iter.hide.name == "all" then -- hide all source;
							for _, n in ipairs(get_all_current_sources_from_scene()) do
								setSourceVisible(n, false)
							end
						elseif APP_ACTIONS:IsLikeAction(iter.hide.name) then
							local tN = APP_ACTIONS:GetLikeAction(iter.hide.name);
							for _, n in ipairs(get_all_current_sources_from_scene()) do
								if APP_ACTIONS:LikeActionMatch(tN, n) then
									setSourceVisible(n, false)
								end
							end
						end
					elseif iter.hide.name == "rand" or (APP_ACTIONS:IsLikeAction(iter.hide.name) and APP_ACTIONS:CmdTar(iter.hide.name) == "rand") then -- {RAND, RAND_LIKE}
						if iter.hide.name == "rand" then
							local sources = get_all_current_sources_from_scene();
							if #sources > 0 then
								local rN = sources[math.random(1, #sources)]
								setSourceVisible(rN, false)
							end
						else -- Select a random target that matches (tN)
							local tN = APP_ACTIONS:GetLikeAction(iter.hide.name);
							local sum = 1
							local sources = get_all_current_sources_from_scene();
							if sum ~= nil and sum > 0 then
								local klist = {}
								if #sources > 0 then
									while true do
										if #klist >= #sources then break end
										local objectName = sources[math.random(1, #sources)];
										if APP_ACTIONS:LikeActionMatch(tN, objectName) then
											setSourceVisible(objectName, false)
											if sum <= 1 then  break; end
											sum = sum - 1;
										end
										
										if not IN_ARRAY(objectName, klist) then table.insert(klist, objectName) end
									end
								end
							end
						end
					else
						setSourceVisible(iter.hide.name, false)
					end
				local copyIter = table.copy(iter, true)
				if iter.hide["repeat"] then
					iter.hide["repeat"].count = iter.hide["repeat"].count + 1
					if iter.hide["repeat"].count >= iter.hide["repeat"].max then -- stop the hide from working;
						iter.hide["repeat"].count = 0
						
						if iter.hide["repeat"]["reset"] then -- reset
							
							local copyIterK = k
							local resetTick = os.time() * 1000
							if copyIter.hide["repeat"]["reset"]["order"] == "%" then
								copyIter.hide["repeat"]["reset"]["init"] = math.random(1, copyIter.hide["repeat"]["reset"].value)
							end
							
							local function resetTimer()
								local currTick = os.time() * 1000
								if copyIter.hide["repeat"]["reset"]["type"] == "mis" then
									if (currTick - resetTick) >= copyIter.hide["repeat"]["reset"]["init"] then
										table.insert(init_list.Action, copyIter)
										-- Check for events;
										if init_list.Conion[copyIter.hide.name] and init_list.Conion[copyIter.hide.name]["cdwn"] and init_list.Conion[copyIter.hide.name]["cdwn"]["reset"] then
											for _, event in ipairs(init_list.Conion[copyIter.hide.name]["cdwn"]["reset"]) do
												event["do"]()
											end
										end
										return obs.timer_remove(resetTimer)
									end
								elseif copyIter.hide["repeat"]["reset"]["type"] == "sc" then 
									if(currTick - resetTick) / 1000 >= copyIter.hide["repeat"]["reset"]["init"] then
										table.insert(init_list.Action, copyIter)
										if init_list.Conion[copyIter.hide.name] and init_list.Conion[copyIter.hide.name]["cdwn"] and init_list.Conion[copyIter.hide.name]["cdwn"]["reset"] then
											for _, event in ipairs(init_list.Conion[copyIter.hide.name]["cdwn"]["reset"]) do
												event["do"]()
											end
										end
										return obs.timer_remove(resetTimer)
									end
								elseif copyIter.hide["repeat"]["reset"]["type"] == "ms" then
									if(currTick - resetTick) / 60000 >= copyIter.hide["repeat"]["reset"]["init"] then
										table.insert(init_list.Action, copyIter)
										if init_list.Conion[copyIter.hide.name] and init_list.Conion[copyIter.hide.name]["cdwn"] and init_list.Conion[copyIter.hide.name]["cdwn"]["reset"] then
											for _, event in ipairs(init_list.Conion[copyIter.hide.name]["cdwn"]["reset"]) do
												event["do"]()
											end
										end
										return obs.timer_remove(resetTimer)
									end
								elseif copyIter.hide["repeat"]["reset"]["type"] == "hr" then
									if(currTick - resetTick) / 3.6000E+6 >= copyIter.hide["repeat"]["reset"]["init"] then
										table.insert(init_list.Action, copyIter)
										if init_list.Conion[copyIter.hide.name] and init_list.Conion[copyIter.hide.name]["cdwn"] and init_list.Conion[copyIter.hide.name]["cdwn"]["reset"] then
											for _, event in ipairs(init_list.Conion[copyIter.hide.name]["cdwn"]["reset"]) do
												event["do"]()
											end
										end
										return obs.timer_remove(resetTimer)
									end
								end
							end
							obs.timer_add(resetTimer, 1)
						else -- end (event)
							if init_list.Conion[copyIter.hide.name] and init_list.Conion[copyIter.hide.name]["cdwn"] and init_list.Conion[copyIter.hide.name]["cdwn"]["end"] then
								for _, event in ipairs(init_list.Conion[copyIter.hide.name]["cdwn"]["end"]) do
									event["do"]()
								end
							end
						end
						-- remove hide operation from list;
						table.remove(init_list.Action, k)
					end
				end
				-- Check for events;
				if init_list.Conion[copyIter.hide.name] and init_list.Conion[copyIter.hide.name]["cdwn"] and init_list.Conion[copyIter.hide.name]["cdwn"]["hide"] then
					for _, event in ipairs(init_list.Conion[copyIter.hide.name]["cdwn"]["hide"]) do
						event["do"]()
					end
				end
			end
			if iter.hide.time.type == "mis" then
				if ((os.clock() * 1000) - iter.hide.time.tick) >= iter.hide.time.init then -- hide the object;
					TimeEnd = os.clock() * 1000
					initHide()
				end
			elseif iter.hide.time.type == "sc" then -- calculate Seconds
				local total_seconds = ((os.clock() * 1000) - iter.hide.time.tick ) / 1000
				if total_seconds >= iter.hide.time.init then
					TimeEnd = os.clock() * 1000
					initHide()
				end
			elseif iter.hide.time.type == "ms" then -- Calculate Minutes
				local total_minutes = ((os.clock() * 1000) - iter.hide.time.tick ) / 60000
				if total_minutes >= iter.hide.time.init then
					initHide()
				end
			elseif iter.hide.time.type == "hr" then -- Calculate Hours
				local total_hours = ((os.clock() * 1000) - iter.hide.time.tick ) / 3.6000E+6
				if total_hours >= iter.hide.time.init then
					initHide()
				end
			end
		elseif iter.hide and iter.hide.isHidden and iter.show and not iter.show.isShown then -- (Show)
			local function initShow()
				if __GLOBAL_CLIENT_EVENT == obs.OBS_FRONTEND_EVENT_SCRIPTING_SHUTDOWN then
					return
				end
				iter.hide.time.tick = os.clock() * 1000
				iter.show.time.tick = 0
				iter.show.isShown = true
				iter.hide.isHidden = false
				if iter.show.time.order == "%" then -- re-assign (init) to random value;
					iter.show.time.init = math.random(1, iter.show.time.max)
				end
				-- [[ ALL OR ALL_LIKE OR RAND OR RAND_LIKE ]]
					if iter.show.name == "all" or (APP_ACTIONS:IsLikeAction(iter.show.name) and APP_ACTIONS:CmdTar(iter.show.name) == "all") then -- {ALL, ALL_LIKE}
						if iter.show.name == "all" then -- hide all source;
							for _, n in ipairs(get_all_current_sources_from_scene()) do
								setSourceVisible(n, true)
							end
						elseif APP_ACTIONS:IsLikeAction(iter.show.name) then
							local tN = APP_ACTIONS:GetLikeAction(iter.show.name);
							for _, n in ipairs(get_all_current_sources_from_scene()) do
								if APP_ACTIONS:LikeActionMatch(tN, n) then
									setSourceVisible(n, true)
								end
							end
						end
					elseif iter.show.name == "rand" or (APP_ACTIONS:IsLikeAction(iter.show.name) and APP_ACTIONS:CmdTar(iter.show.name) == "rand") then -- {RAND, RAND_LIKE}
						if iter.show.name == "rand" then
							local sources = get_all_current_sources_from_scene();
							if #sources > 0 then
								local rN = sources[math.random(1, #sources)]
								setSourceVisible(rN, true)
							end
						else -- Select a random target that matches (tN)
							local tN = APP_ACTIONS:GetLikeAction(iter.show.name);
							local sum = 1
							local sources = get_all_current_sources_from_scene();
							if sum ~= nil and sum > 0 then
								local klist = {}
								if #sources > 0 then
									while true do
										if #klist >= #sources then break end
										local objectName = sources[math.random(1, #sources)];
										if APP_ACTIONS:LikeActionMatch(tN, objectName) then
											setSourceVisible(objectName, true)
											if sum <= 1 then  break; end
											sum = sum - 1;
										end
										
										if not IN_ARRAY(objectName, klist) then table.insert(klist, objectName) end
									end
								end
							end
						end
					else
						setSourceVisible(iter.show.name, true)
					end
					
				local copyIter = table.copy(iter, true)
				if iter.show["repeat"] then
					iter.show["repeat"].count = iter.show["repeat"].count + 1
					if iter.show["repeat"].count >= iter.show["repeat"].max then -- stop the hide from working;
						iter.show["repeat"].count = 0
						
						if iter.show["repeat"]["reset"] then -- reset
							
							local copyIterK = k
							local resetTick = os.time() * 1000
							if copyIter.show["repeat"]["reset"]["order"] == "%" then
								copyIter.show["repeat"]["reset"]["init"] = math.random(1, copyIter.show["repeat"]["reset"].value)
							end
							local function resetTimer()
								local currTick = os.time() * 1000
								if copyIter.show["repeat"]["reset"]["type"] == "mis" then
									if (currTick - resetTick) >= copyIter.show["repeat"]["reset"]["init"] then
										table.insert(init_list.Action, copyIter)
										if init_list.Conion[copyIter.show.name] and init_list.Conion[copyIter.show.name]["cdwn"] and init_list.Conion[copyIter.show.name]["cdwn"]["reset"] then
											for _, event in ipairs(init_list.Conion[copyIter.show.name]["cdwn"]["reset"]) do
												event["do"]()
											end
										end
										return obs.timer_remove(resetTimer)
									end
								elseif copyIter.show["repeat"]["reset"]["type"] == "sc" then 
									if(currTick - resetTick) / 1000 >= copyIter.show["repeat"]["reset"]["init"] then
										table.insert(init_list.Action, copyIter)
										if init_list.Conion[copyIter.show.name] and init_list.Conion[copyIter.show.name]["cdwn"] and init_list.Conion[copyIter.show.name]["cdwn"]["reset"] then
											for _, event in ipairs(init_list.Conion[copyIter.show.name]["cdwn"]["reset"]) do
												event["do"]()
											end
										end
										return obs.timer_remove(resetTimer)
									end
								elseif copyIter.show["repeat"]["reset"]["type"] == "ms" then
									if(currTick - resetTick) / 60000 >= copyIter.show["repeat"]["reset"]["init"] then
										table.insert(init_list.Action, copyIter)
										if init_list.Conion[copyIter.show.name] and init_list.Conion[copyIter.show.name]["cdwn"] and init_list.Conion[copyIter.show.name]["cdwn"]["reset"] then
											for _, event in ipairs(init_list.Conion[copyIter.show.name]["cdwn"]["reset"]) do
												event["do"]()
											end
										end
										return obs.timer_remove(resetTimer)
									end
								elseif copyIter.show["repeat"]["reset"]["type"] == "hr" then
									if(currTick - resetTick) / 3.6000E+6 >= copyIter.show["repeat"]["reset"]["init"] then
										table.insert(init_list.Action, copyIter)
										if init_list.Conion[copyIter.show.name] and init_list.Conion[copyIter.show.name]["cdwn"] and init_list.Conion[copyIter.show.name]["cdwn"]["reset"] then
											for _, event in ipairs(init_list.Conion[copyIter.show.name]["cdwn"]["reset"]) do
												event["do"]()
											end
										end
										return obs.timer_remove(resetTimer)
									end
								end
							end
							obs.timer_add(resetTimer, 1)
						else -- end (event)
							if init_list.Conion[copyIter.show.name] and init_list.Conion[copyIter.show.name]["cdwn"] and init_list.Conion[copyIter.show.name]["cdwn"]["end"] then
								for _, event in ipairs(init_list.Conion[copyIter.show.name]["cdwn"]["end"]) do
									event["do"]()
								end
							end
						end
						table.remove(init_list.Action, k)
					end
				end
				-- Check for events;
				if init_list.Conion[copyIter.show.name] and init_list.Conion[copyIter.show.name]["cdwn"] and init_list.Conion[copyIter.show.name]["cdwn"]["show"] then
					for _, event in ipairs(init_list.Conion[copyIter.show.name]["cdwn"]["show"]) do
						event["do"]()
					end
				end
			end
			if iter.show.time.type == "mis" then
				if ((os.clock() * 1000) - iter.show.time.tick) >= iter.show.time.init then -- show the object;
					TimeEnd = os.clock() * 1000
					initShow()
				end
			elseif iter.show.time.type == "sc" then -- calculate Seconds
				local total_seconds = ((os.clock() * 1000) - iter.show.time.tick) / 1000
				if total_seconds >= iter.show.time.init then
					TimeEnd = os.clock() * 1000
					initShow()
				end
			elseif iter.show.time.type == "ms" then -- Calculate Minutes
				local total_minutes = ((os.clock() * 1000) - iter.show.time.tick) / 60000
				if total_minutes >= iter.show.time.init then
					initShow()
				end
			elseif iter.show.time.type == "hr" then -- Calculate Hours
				local total_hours = ((os.clock() * 1000) - iter.show.time.tick) / 3.6000E+6
				if total_hours >= iter.show.time.init then
					initShow()
				end
			end
			
		end
	end
	
	-- Statement check (If Statment)
	if init_list.Conion["cdf"] then
		for key, stm in pairs(init_list.Conion["cdf"]) do
			if key == "text" then -- Text change check;
				for _, iter in ipairs(stm) do
					local val = iter.val
					local target = iter.target;
					local effect = iter["for"]
					if target == "<none>" then
						target = effect
					end
					local function InitAction()
						-- [[ ALL OR ALL_LIKE OR RAND OR RAND_LIKE ]]
							if effect == "all" or (APP_ACTIONS:IsLikeAction(effect) and APP_ACTIONS:CmdTar(effect) == "all") then -- {ALL, ALL_LIKE}
								if effect== "all" then
									for _, n in ipairs(get_all_current_sources_from_scene()) do
										if n ~= target then 
											iter["do"](n)
										end
									end
								elseif APP_ACTIONS:IsLikeAction(effect) then
									local tN = APP_ACTIONS:GetLikeAction(effect);
									for _, n in ipairs(get_all_current_sources_from_scene()) do
										if APP_ACTIONS:LikeActionMatch(tN, n) then
											if n ~= target then iter["do"](n) end
										end
									end
								end
							elseif effect == "rand" or (APP_ACTIONS:IsLikeAction(effect) and APP_ACTIONS:CmdTar(effect) == "rand") then -- {RAND, RAND_LIKE}
								if effect == "rand" then
									local sources = get_all_current_sources_from_scene();
									if #sources > 0 then
										local rN = sources[math.random(1, #sources)]
										if rN ~= target then iter["do"](rN) end
									end
								else -- Select a random target that matches (tN)
									local tN = APP_ACTIONS:GetLikeAction(effect);
									local sum = 1
									local sources = get_all_current_sources_from_scene();
									if sum ~= nil and sum > 0 then
										local klist = {}
										if #sources > 0 then
											while true do
												if #klist >= #sources then break end
												local objectName = sources[math.random(1, #sources)];
												if APP_ACTIONS:LikeActionMatch(tN, objectName) and objectName ~= target then
													iter["do"](objectName)
													if sum <= 1 then  break; end
													sum = sum - 1;
												end
												
												if not IN_ARRAY(objectName, klist) then table.insert(klist, objectName) end
											end
										end
									end
								end
							else
								iter["do"]()
							end
					end
					if target ~= nil and effect ~= nil then
						local t = obs.obs_get_source_by_name(target)
						if t ~= nil then
							local s = obs.obs_source_get_settings(t)
							
							if s ~= nil then
								local currVal = obs.obs_data_get_string(s, "text")
								if currVal ~= nil then -- making user it is a text label?
									if (currVal == "" and (val == "" or val == nil)) or strTrim(currVal) == strTrim(val) then
										InitAction()
									end
								end
								obs.obs_data_release(s)
							end
						end
						obs.obs_source_release(t)
					end
				end
			elseif key == "play" or key == "pause" or key == "ended" then -- check if target is playing then
				for _, iter in ipairs(stm) do
					local target = iter.target
					local effect = iter["for"]
					if target == nil or target == "<none>" then
						target = effect
					end
					local function InitAction()
						-- [[ ALL OR ALL_LIKE OR RAND OR RAND_LIKE ]]
							if effect == "all" or (APP_ACTIONS:IsLikeAction(effect) and APP_ACTIONS:CmdTar(effect) == "all") then -- {ALL, ALL_LIKE}
								if effect== "all" then
									for _, n in ipairs(get_all_current_sources_from_scene()) do
										if n ~= target then 
											iter["do"](n)
										end
									end
								elseif APP_ACTIONS:IsLikeAction(effect) then
									local tN = APP_ACTIONS:GetLikeAction(effect);
									for _, n in ipairs(get_all_current_sources_from_scene()) do
										if APP_ACTIONS:LikeActionMatch(tN, n) then
											if n ~= target then iter["do"](n) end
										end
									end
								end
							elseif effect == "rand" or (APP_ACTIONS:IsLikeAction(effect) and APP_ACTIONS:CmdTar(effect) == "rand") then -- {RAND, RAND_LIKE}
								if effect == "rand" then
									local sources = get_all_current_sources_from_scene();
									if #sources > 0 then
										local rN = sources[math.random(1, #sources)]
										if target ~= rN then iter["do"](rN) end
									end
								else -- Select a random target that matches (tN)
									local tN = APP_ACTIONS:GetLikeAction(effect);
									local sum = 1
									local sources = get_all_current_sources_from_scene();
									if sum ~= nil and sum > 0 then
										local klist = {}
										if #sources > 0 then
											while true do
												if #klist >= #sources then break end
												local objectName = sources[math.random(1, #sources)];
												if APP_ACTIONS:LikeActionMatch(tN, objectName) and objectName ~= target then
													iter["do"](objectName)
													if sum <= 1 then  break; end
													sum = sum - 1;
												end
												
												if not IN_ARRAY(objectName, klist) then table.insert(klist, objectName) end
											end
										end
									end
								end
							else
								iter["do"]()
							end
					end
					local cmp = 1000000
					if key == "play" then
						cmp = obs.OBS_MEDIA_STATE_PLAYING 
					elseif key == "pause" then
						cmp = obs.OBS_MEDIA_STATE_PAUSED 
					elseif key == "ended" then
						cmp = obs.OBS_MEDIA_STATE_ENDED
					end
					if target ~= nil and effect ~= nil then
						local s = obs.obs_get_source_by_name(target)
						if s ~= nil and obs.obs_source_media_get_state(s) == cmp then
							InitAction()
						end
						obs.obs_source_release(s)
					end
				end
			elseif key == "is shown" or key == "is hidden" then
				for _, iter in ipairs(stm) do
					local target = iter.target
					local effect = rplr_char(strTrim(iter["for"]), "<>","")
					if target == nil or target == "<none>" then
						target = effect
					end
					local function InitAction()
						-- [[ ALL OR ALL_LIKE OR RAND OR RAND_LIKE ]]
							if effect == "all" or (APP_ACTIONS:IsLikeAction(effect) and APP_ACTIONS:CmdTar(effect) == "all") then -- {ALL, ALL_LIKE}
								if effect== "all" then
									for _, n in ipairs(get_all_current_sources_from_scene()) do
										if n ~= target then 
											iter["do"](n)
										end
									end
								elseif APP_ACTIONS:IsLikeAction(effect) then
									local tN = APP_ACTIONS:GetLikeAction(effect);
									for _, n in ipairs(get_all_current_sources_from_scene()) do
										if APP_ACTIONS:LikeActionMatch(tN, n) then
											if n ~= target then iter["do"](n) end
										end
									end
								end
							elseif effect == "rand" or (APP_ACTIONS:IsLikeAction(effect) and APP_ACTIONS:CmdTar(effect) == "rand") then -- {RAND, RAND_LIKE}
								if effect == "rand" then
									local sources = get_all_current_sources_from_scene();
									if #sources > 0 then
										local rN = sources[math.random(1, #sources)]
										if rN ~= target then iter["do"](rN) end
									end
								else -- Select a random target that matches (tN)
									local tN = APP_ACTIONS:GetLikeAction(effect);
									local sum = 1
									local sources = get_all_current_sources_from_scene();
									if sum ~= nil and sum > 0 then
										local klist = {}
										if #sources > 0 then
											while true do
												if #klist >= #sources then break end
												local objectName = sources[math.random(1, #sources)];
												if APP_ACTIONS:LikeActionMatch(tN, objectName) and objectName ~= target then
													iter["do"](objectName)
													if sum <= 1 then  break; end
													sum = sum - 1;
												end
												
												if not IN_ARRAY(objectName, klist) then table.insert(klist, objectName) end
											end
										end
									end
								end
							else
								iter["do"]()
							end
					end
					if target ~= nil and effect ~= nil then
						local t = __GET_SCENE_ITEM__(target)
						if t ~= nil then
						
							if obs.obs_sceneitem_visible(t.item) and key == "is shown" then
								InitAction()
							elseif not obs.obs_sceneitem_visible(t.item) and key == "is hidden" then
								InitAction()
							end
							t.release()
						end
						
					end
				end
			end
		end
	end
end
