--[[
    10.25.2022 (hide & show) version 2
    (commands) => action | target | time.optional (default) => 1s
    (commands) on.action | target | target_event_name | action.optional
    (possible commands) =>

    [
        (hide) -- will hide the target
        (show) -- will show the target
        (onhide) -- will show or hide the target when (hide) is executed .default => show
        (onshow) -- will hide or show the target when (show) is executed .default => hide
    ]
    (possible implements) => [
        1. hide | example_target_source_name
        2. show | example_target_source_name
        3. onhide | example_target_source_name
        4. onshow | example_target_source_name
        5. hide | example_target_source_name | 10s -- hides the target in (10 seconds) use (m) for (minutes)
        6. show | example_target_source_name | 5s  -- hides the target in (5 seconds) use (m) for (minutes)
    ]
    we can be friends @xiao_sings twitter or instagram <3
]]

obs     =   obslua
APP     =   {}
APP_EVENT
        =   {}
__SETTINGS__ = nil
APP_CALLBACKS = {}
APP_ON_EVENT = {
    onhide = {};
    onshow = {};
};
APP_ACTIONS = {"hide","show","onhide","onshow","(onshow)","(hide)","(show)","(onhide)"}
APP_IS_ENABLE = false
APP_AUTO_ENABLE = false
--[[ OBS RELATED OPERATIONS ]]
function script_properties()
    local props = obs.obs_properties_create()
    obs.obs_properties_add_editable_list(props, "hide_n_show_sources", "(Hide & Show Source List)",obs.OBS_EDITABLE_LIST_TYPE_STRINGS,nil,nil)
    --obs.obs_properties_add_button(props, "power-btn","Enable", PowerAction)
    --[[obs.obs_properties_add_button(props, "reset-btn","Reset", function()
        APP:Disable();
        local __source_list_items__ = obs.obs_data_get_array(_settings, "hide_n_show_sources")
        local group_list = obs.obs_properties_get(props, "hide_n_show_sources")
        obs.obs_property_list_clear(__source_list_items__);

        obs.obs_data_array_release(__source_list_items__);
        for _, iter in ipairs(APP_EVENT) do -- set defaults
            local action_target = iter.actionTarget;
            APP:show(action_target);
            if APP_ACTIONS:isOnAction(iter.actionName) then
                APP:show(iter.actionEvent)
            end
        end
        APP_EVENT = {};
        APP_CALLBACKS = {};
        APP_ON_EVENT = {onhide = {};onshow= {}}
    end)--]]
    return props
end

function script_unload()
    for _, iter in ipairs(APP_EVENT) do -- set defaults
        local action_target = iter.actionTarget;
        APP:show(action_target);
        if APP_ACTIONS:isOnAction(iter.actionName) then
            APP:show(iter.actionEvent)
        end
    end
end
function script_load(_settings)
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

    APP:initUpdate(_settings)
    --[[
    if __SETTINGS__ ~= nil then
        obs.obs_data_release(__SETTINGS__)
    end
    __SETTINGS__ = _settings
    ]]
end
function script_default(_settings)
    --[[if APP_IS_ENABLE then
        obs.obs_data_set_string(_settings,"actionTitle","Disable")
    else
        obs.obs_data_set_string(_settings,"actionTitle","Enable")
    end]]
    if __SETTINGS__ ~= nil then
        obs.obs_data_release(__SETTINGS__)
    end
    __SETTINGS__ = _settings
end
function script_save(_settings) end
-- END OF OBS RELATED OPERATIONS





-- [[ USER DEFINED OPERATIONS ]]
function APP_ACTIONS:has (_value)
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
APP.isEnable = function(_source_name) -- true or false if is enable(true) or not (false)
    local __target__ = APP.source(_source_name)
    if __target__ then
        local isEnable = obs.obs_source_enabled(__target__)
        obs.obs_source_release(__target__)
        return isEnable
    end
    return nil
end
APP.source = function(_source_name) -- returns a source(make sure to release!) if name given/and exists.
    return obs.obs_get_source_by_name(_source_name)
end
function APP:initUpdate(_settings) -- executes every time the user interacts with (interface)
    for _, iter in ipairs(APP_CALLBACKS) do
        if type(iter) == "function" then
            obs.timer_remove(iter)
        end
    end
    for _, iter in ipairs(APP_EVENT) do -- set defaults
        local action_target = iter.actionTarget;
        APP:show(action_target);
        if APP_ACTIONS:isOnAction(iter.actionName) then
            APP:show(iter.actionEvent)
        end
    end
    APP_CALLBACKS = {}
    APP_EVENT = {}
    local __source_list_items__ = obs.obs_data_get_array(_settings, "hide_n_show_sources")
    local source_list_count = obs.obs_data_array_count(__source_list_items__)
    -- get the list and save them in (APP_EVENT) for later use.
    for iter_count = 0, source_list_count do
        local __iter__      = obs.obs_data_array_item(__source_list_items__, iter_count)
        local target_value   = obs.obs_data_get_string(__iter__, "value")
        if(target_value and target_value ~= "") then
            local commands = string_pipes(target_value)
            if commands and type(commands) == "table" and #commands > 1 then
                local action_name = string.lower(commands[1]:gsub("^%s*(.-)%s*$", "%1"))
                if APP_ACTIONS:has(action_name) then
                    local action_target = commands[2]:gsub("^%s*(.-)%s*$", "%1")
                    --APP:show(action_target);
                    local action_timer = "1s"
                    local action_event_target = ""
                    local action_value = "";
                    if APP_ACTIONS:isOnAction(action_name) then
                        if #commands >= 3 then
                            action_event_target = commands[3]:gsub("^%s*(.-)%s*$", "%1")
                            if #commands >= 4 then
                                action_value = string.lower(commands[4]:gsub("^%s*(.-)%s*$", "%1"))
                                if APP_ACTIONS:has(action_value) == false or APP_ACTIONS:isOnAction(action_value) then
                                    action_value = ""
                                end
                            end
                            if(action_value == "hide") then
                                APP:show(action_event_target)
                            elseif action_value == "show" then
                                APP:hide(action_event_target);
                            end
                            if action_value == "" then
                                if action_name == "onhide" then
                                    action_value = "show"
                                else
                                    action_value = "hide"
                                end
                            end
                            table.insert(APP_EVENT, {
                                actionName = action_name;
                                actionTarget = action_target;
                                actionEvent = action_event_target;
                                actionValue = action_value;
                            })
                        end
                    else
                        if #commands >= 3 then
                            action_timer = commands[3]:gsub("^%s*(.-)%s*$", "%1")
                        end
                        if action_name == "hide" then
                            APP:show(action_target);
                        elseif action_name == "show" then
                            APP:hide(action_target);
                        end
                        --@log print("ActionEvet: " .. action_name .. " || " .. action_target .. " || " ..  action_timer)
                        table.insert(APP_EVENT,#APP_EVENT + 1, {
                            actionName = action_name;
                            actionTarget = action_target;
                            actionTimer = time_splitter(action_timer);
                        });
                    end
                else -- read defaults;
                    if action_name == "default" and iter_count > 0 and #commands > 1 then
                        local action_value = commands[2]:gsub("^%s*(.-)%s*$", "%1");
                        local temp_count = iter_count - 1;
                        while (temp_count >=0) do
                            local __prev_iter      = obs.obs_data_array_item(__source_list_items__,temp_count)
                            local cmd_value   = obs.obs_data_get_string(__prev_iter, "value")
                            local cmd_list = string_pipes(cmd_value)
                            local a_n = string.lower(cmd_list[1]:gsub("^%s*(.-)%s*$", "%1"));                            
                            -- check action types; apply the defaults to the target;
                            if APP_ACTIONS:has(a_n) then
                                local a_t = "";
                                if APP_ACTIONS:isOnAction(a_n) and #cmd_list >= 3 then
                                    a_t = cmd_list[3]:gsub("^%s*(.-)%s*$", "%1");
                                elseif not APP_ACTIONS:isOnAction(a_n) and #cmd_list >= 2 then
                                    a_t = cmd_list[2]:gsub("^%s*(.-)%s*$", "%1"); 
                                end

                                if action_value == "hide" then
                                    APP:hide(a_t);
                                elseif action_value == "show" then
                                    APP:show(a_t);
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
            end
        end
        obs.obs_data_release(__iter__)
    end
    obs.obs_data_array_release(__source_list_items__)
    --if APP_IS_ENABLE then
        APP:Enable()
   --end
end
function time_splitter(_time_value)
    local time_list = {type="s";value=1;order="."};
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
    value1 = tonumber(value1)
    time_list.type = value2;
    time_list.value = value1;

    return time_list
end
function APP:setEnable(_source_name, _enable)
    local __target__ = APP.source(_source_name)
    if __target__ then
        obs.obs_source_set_enabled(__target__, _enable)
        obs.obs_source_release(__target__)
    end
end
function APP:hide(_source_name)
    return APP:setEnable(_source_name, false)
end
function APP:show(_source_name)
    return APP:setEnable(_source_name, true)
end
-- Enables the program
function APP:Enable()
    print("Enable{!}");
    -- remove previous callbacks
    for _, iter in ipairs(APP_CALLBACKS) do
        if type(iter) == "function" then
            obs.timer_remove(iter)
        end
    end
    APP_CALLBACKS = {}
    -- add new callbacks
    for _, iter in ipairs(APP_EVENT) do
        --spawn(function()
            local action_name = iter.actionName
            if APP_ACTIONS:has(action_name) then
                local action_target = iter.actionTarget
                --APP:show(action_target);
                local action_event_target;
                local action_timer;
                local action_value;
                if APP_ACTIONS:isOnAction(action_name) then

                    --@log print("OnEvent{!}");
                    --APP:hide(iter.actionEvent)
                    action_value = iter.actionValue
                    action_event_target = iter.actionEvent
                    if APP_ON_EVENT[action_name] ~= nil then
                        if APP_ON_EVENT[action_name][action_target] == nil then
                            APP_ON_EVENT[action_name][action_target] = {}
                        end
                        table.insert(APP_ON_EVENT[action_name][action_target], #APP_ON_EVENT[action_name][action_target] + 1, function()
                            --@log print("OnEventExE{!} |" .. action_name .. " || " .. action_target .. " || " .. action_event_target .. " || " .. action_value);
                            if action_value == "hide" then
                                -- hide the target
                                APP:hide(action_event_target)
                                --@log print("NOW HIDING{!}")
                            elseif action_value == "show" then
                                --@log print("NOW SHOWING{!}");
                                -- show the target
                                APP:show(action_event_target)
                            end
                        end)
                    end
                else
                    --@log print("ActionEvet{!}")
                    action_timer = iter.actionTimer
                    local action_timer_type = action_timer.type
                    local action_timer_order = action_timer.order
                    local action_timer_value = action_timer.value
                    local min = 1
                    local max = nil
                    local function init_timer()
                        --@log print("Init-Timer{!} > " .. tostring(action_timer_value))
                        if action_timer_order == "%" then
                            max = math.random(1, action_timer_value)
                        else
                            max = action_timer_value
                        end
                        min = 1;
                    end
                    table.insert(APP_CALLBACKS, #APP_CALLBACKS + 1, function()
                        if max == nil then
                            init_timer()
                        end
                        local has_reached_end = false
                        if action_timer_type == "m" then -- minutes conversion
                            --@log print(action_name.. " >" .. action_target .. "< " .. " || " .. "Current: " .. tostring(min) .. " Max: " .. tostring(max) .. " |MINUTES|")
                            if min >= (max * 60) then
                                has_reached_end = true
                            end
                        elseif min >= max then
                            has_reached_end = true;
                        else
                            --@log print(action_name.. " >" .. action_target .. "< " .. " || " .. "Current: " .. tostring(min) .. " Max: " .. tostring(max) .. " |SECONDS|")
                        end
                        if has_reached_end then
                            --@log print(action_name .. " >" .. action_target .. "< reached[!]")
                            init_timer()
                            if action_name == "hide" then
                                -- hide the target
                                APP:hide(action_target)
                                --@logprint("NOW HIDING{!}")
                                -- handle event calls
                                if APP_ON_EVENT["onhide"][action_target] ~= nil then
                                    for _, iter_fnc in ipairs(APP_ON_EVENT["onhide"][action_target]) do
                                        iter_fnc();
                                    end
                                end
                            elseif action_name == "show" then
                                --@logprint("NOW SHOWING{!}");
                                -- show the target
                                APP:show(action_target)
                                -- handle event calls
                                if APP_ON_EVENT["onshow"][action_target] ~= nil then
                                    for _, iter_fnc in ipairs(APP_ON_EVENT["onshow"][action_target]) do
                                        iter_fnc();
                                    end
                                end
                            end
                            return
                        end
                        min = min + 1
                    end)
                    obs.timer_add(APP_CALLBACKS[#APP_CALLBACKS],1000)
                end
                --@log print("Action-Name: " .. iter.actionName .. " || Action-Target: " .. iter.actionTarget)
            end
        --end)
    end
    --[[ Debug Information 
    print("APPS: " .. #APP_CALLBACKS)
    for key, _ in pairs(APP_ON_EVENT) do
        for vkey, ls in pairs(APP_ON_EVENT[key]) do
            print(key .. " => " .. vkey .. " counts: " .. #ls);
        end
    end
    --]]
end
-- Disables the progam
function APP:Disable()
    print("Disable{!}");
    for _, iter in ipairs(APP_CALLBACKS) do
        if type(iter) == "function" then
            obs.timer_remove(iter)
        end
    end
    for _, iter in ipairs(APP_EVENT) do -- set defaults
        local action_target = iter.actionTarget;
        APP:show(action_target);
        if APP_ACTIONS:isOnAction(iter.actionName) then
            APP:hide(iter.actionEvent)
        end
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
function PowerAction(_props, _btn, _settings)
    if(APP_IS_ENABLE) then
        obs.obs_data_set_string(__SETTINGS__, "actionTitle","Enable")
        APP:Disable()
        APP_IS_ENABLE = false
    else
        APP_IS_ENABLE = true
        obs.obs_data_set_string(__SETTINGS__,"actionTitle", "Disable")
        APP:Enable()
    end
end

-- END OF USER DEFINED OPERATIONS

