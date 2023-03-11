-- This script will let the user hide and show the source objects in OBS
hd_tm       = 0 -- (Hide Time)
sc_tm 		= 0 -- (Screen Time)
obs 		= obslua
sctm_to_sec 	= 0
hdtm_to_sec 	= 0
target_name 	= ""
_settings 	= nil
onhide_target_name 	= ""
onshow_target_name 	= ""
onhide_previous_state 	= nil
onshow_previous_state 	= nil
-- Properties; what the user will see;
function script_properties()
	props = obslua.obs_properties_create()
	obslua.obs_properties_add_int(props,"duration-one","Screen Time (Minutes)",1,100000,1)
	obslua.obs_properties_add_int(props,"duration-two","Hide Time (Minutes)",1,100000,1)
	obslua.obs_properties_add_button(props,"random","Randomize",randomize_time_callback)
	
	-- Selector{!}
	local target_selector = obs.obs_properties_add_list(props, "target-source-selector", "Source Target", obs.OBS_COMBO_TYPE_EDITABLE, obs.OBS_COMBO_FORMAT_STRING)
	local onhide_selector = obs.obs_properties_add_list(props, "onhide-source-selector", "On Hide Target (Will be shown)", obs.OBS_COMBO_TYPE_EDITABLE, obs.OBS_COMBO_FORMAT_STRING)
	-- remove/add for onhide;
	obs.obs_properties_add_button(props,"onhide-add","Add",add_to_onhide)
	obs.obs_properties_add_button(props,"onhide-remove","Remove",remove_to_onhide)
	local onshow_selector = obs.obs_properties_add_list(props, "onshow-source-selector", "On Show Target (Will be hidden)", obs.OBS_COMBO_TYPE_EDITABLE, obs.OBS_COMBO_FORMAT_STRING)
	-- remove/add for onshow;
	obs.obs_properties_add_button(props,"onshow-add","Add",add_to_onshow)
	obs.obs_properties_add_button(props,"onshow-remove","Remove",remove_to_onshow)
	-- populate the selectors;
	local sources = obs.obs_enum_sources()
	if sources ~= nil then
		for _, source in ipairs(sources) do
			local name = obs.obs_source_get_name(source)
			-- Target
			if name ~= onshow_target_name and name ~= onhide_target_name then
				obs.obs_property_list_add_string(target_selector, name, name)
			end
			if name ~= target_name then
				obs.obs_property_list_add_string(onhide_selector, name, name)
			end
			if name ~= target_name then
				obs.obs_property_list_add_string(onshow_selector, name, name)
			end
		end
	end
	obslua.obs_properties_add_button(props,"visible-btn","Show/All",show_all)
	obslua.obs_properties_add_button(props,"hide-btn","Hide/All",hide_all)
	obslua.obs_properties_add_button(props,"init","Enable / Disable",init)
	-- release & return
	obs.source_list_release(sources)
	return props; -- return the properties back, so the user can see it;
end
function hide_all()
	source_enable_by_name(target_name,false)
	-- hide all objects/source from (source_on_hide)
	for key, iter in pairs(source_on_hide) do
		source_enable_by_name(iter.target_name,false)
	end
	-- hide all objects/source from (source_on_show)
	for key, iter in pairs(source_on_show) do
		source_enable_by_name(iter.target_name,false)
	end
end
function show_all()
	source_enable_by_name(target_name,true)
	-- show all objects/source from (source_on_hide)
	for key, iter in pairs(source_on_hide) do
		source_enable_by_name(iter.target_name,true)
	end
	-- show all objects/source from (source_on_show)
	for key, iter in pairs(source_on_show) do
		source_enable_by_name(iter.target_name,true)
	end
end
function script_unload()
	show_all()
end
-- Main: this function is used to make an object(source) visible, and not visible
crr_sc_sec 	= 0
crr_hd_sec 	= 0
crr_ty 	= 1 -- (1) is shown (2) is hidden
function main()
	if not is_init then
		obs.timer_remove(main)
		return
	end
	-- Check if the current timer is same has the given timer;
	if crr_ty == 2 and crr_hd_sec >= hdtm_to_sec then -- showing timer;
		source_enable(true)
		crr_ty 	= 1 -- show object
		crr_hd_sec 	= 0;
		gene_randomize()
		-- setup {OnHide} {OnShow} -> Hide onshow_target;
		HideAllOnShow()
		return
	elseif crr_ty == 1 and crr_sc_sec >= sctm_to_sec then -- hidding timer;
		source_enable(false)
		crr_ty 	= 2 -- hide object
		crr_sc_sec 	= 0;
		gene_randomize()
		-- setup {OnHide} {OnShow} -> Show onhide_target;
		ShowAllOnHide()
		return
	elseif crr_ty == 2 then -- increment crr_hd_sec by 1
		crr_hd_sec 	= crr_hd_sec + 1
		return
	elseif crr_ty == 1 then -- increment crr_sc_sec by 1
		crr_sc_sec 	= crr_sc_sec + 1
		return
	else -- crr_ty is not (1 || 2)
		obs.timer_remove(main)
		print("(HIDE & SHOW ERROR) -> with (crr_ty); please set it to (1) or (2) to make it work!")
		return
	end
	-- debug (ONLY!)
	--[[
	local target_source = obs.obs_get_source_by_name(target_name)
	if target_source then
		print("HAS_TARGET! > " ..crr_ty)
		if crr_ty == 1 then
			obs.obs_source_set_enabled(target_source,false)
			crr_ty = 2
		elseif crr_ty == 2 then
			obs.obs_source_set_enabled(target_source,true)
			crr_ty = 1
		end
		-- MAIN SETTINGS
		obs.obs_source_release(target_source)
	end
	--]]
end
-- This function will show/hide the source object & release it when it is done with it;
function source_enable_by_name(name,bool)
	if name == "" then
		return
	end
	local target_source = obs.obs_get_source_by_name(name)
	if target_source then
		obs.obs_source_set_enabled(target_source,bool)
		obs.obs_source_release(target_source)
	else
		print("(HIDE & SHOW ERROR) -> could not find source object; please try a different source object!")
	end
end
function source_enable(bool)
	if target_name == "" then
		return
	end
	local target_source = obs.obs_get_source_by_name(target_name)
	if target_source then
		obs.obs_source_set_enabled(target_source,bool)
		obs.obs_source_release(target_source)
	else
		print("(HIDE & SHOW ERROR) ->  could not find source object; please try a different source object!")
	end
end

-- sets defaults to the object/source
function set_all_defaults()
	source_enable(previous_source_enabled)
	-- defaults for Onhide
	for _, iter in ipairs(source_on_hide) do
		source_enable_by_name(iter.target_name,iter.state)
	end
	--defaults for (Onshow)
	for _, iter in ipairs(source_on_show) do
		source_enable_by_name(iter.target_name,iter.state)
	end
end
function script_load(settings)
	if _settings ~= nil then
		obs.obs_data_release(_settings)
		_settings = nil
	end
	_settings = settings
end
-- settings defaults data
function script_defaults(settings)
	-- defaults;
	target_name = obs.obs_data_get_string(settings,"target-source-selector")
	onhide_target_name = obs.obs_data_get_string(settings,"onhide-source-selector")
	onshow_target_name 	= obs.obs_data_get_string(settings,"onshow-source-selector")
	sc_tm 	= obs.obs_data_get_int(settings,"duration-one")
	hd_tm 	= obs.obs_data_get_int(settings,"duration-two")
	sctm_to_sec 	= math.floor(sc_tm * 60) --ctm_to_sec 	= math.floor(sctm_to_sec % 60)
	hdtm_to_sec 	= math.floor(hd_tm * 60) --hdtm_to_sec	= math.floor(hdtm_to_sec % 60)
	if onhide_target_name ~= "" then
		local target_source = obs.obs_get_source_by_name(onhide_target_name)
		if target_source then
			onhide_previous_state = obs.obs_source_enabled(target_source)
			obs.obs_source_release(target_source)
		end
	end
	if onshow_target_name ~= "" then
		local target_source = obs.obs_get_source_by_name(onshow_target_name)
		if target_source then
			onshow_previous_state = obs.obs_source_enabled(target_source)
			obs.obs_source_release(target_source)
		end
	end
end
previous_source_enabled 	= true
-- updates data, whenever the user interacts with the interface;
function script_update(settings)
	sc_tm 	= obslua.obs_data_get_int(settings,"duration-one")
	hd_tm 	= obslua.obs_data_get_int(settings,"duration-two")
	target_name 	= obs.obs_data_get_string(settings, "target-source-selector")
	onhide_target_name 	= obs.obs_data_get_string(settings,"onhide-source-selector")
	onshow_target_name 	= obs.obs_data_get_string(settings,"onshow-source-selector")
	sctm_to_sec 	= math.floor(sc_tm * 60) --ctm_to_sec 	= math.floor(sctm_to_sec % 60)
	hdtm_to_sec 	= math.floor(hd_tm * 60) --hdtm_to_sec	= math.floor(hdtm_to_sec % 60)
	-- disable timer;
	-- show restart the timer; if is enabled!
	source_enable(previous_source_enabled)
	
	if is_init then
		init(); -- stop
		init(); -- start;
	end
	-- set-defaults;
	local target_source = obs.obs_get_source_by_name(target_name)
	if target_source then
		previous_source_enabled = obs.obs_source_enabled(target_source)
		obs.obs_source_release(target_source)
	end
end
-- Hides all (OnShow) Objects/Sources;
function HideAllOnShow()
	for key, target in pairs(source_on_show) do
		local source_target = obs.obs_get_source_by_name(target["target_name"])
		if source_target then
			if target.state == nil then
				source_on_show[key]["state"] = obs.obs_source_enabled(source_target)
			end
			obs.obs_source_set_enabled(source_target,false)
			obs.obs_source_release(source_target)
		end
	end
end
-- Shows all (OnHide)
function ShowAllOnHide()
	for key, target in pairs(source_on_hide) do
		local source_target = obs.obs_get_source_by_name(target["target_name"])
		if source_target then
			if target.state == nil then
				source_on_hide[key]["state"] = obs.obs_source_enabled(source_target)
			end
			obs.obs_source_set_enabled(source_target,true)
			obs.obs_source_release(source_target)
		end
	end
end
-- Start function; this will start the program/disable it;
is_init 	= false;
function init()
	if is_init then -- stops the program;
		is_init = false
		obslua.timer_remove(main)
		set_all_defaults()
		print ("HIDE & SHOW - deactivated!")
	else -- starts the program;
		obslua.timer_remove(main)
		obslua.timer_add(main,1000)
		is_init = true
		-- set-defaults;
		if crr_ty == 1 then -- show the object;
			source_enable(true)
			-- setup {OnHide} {OnShow} -> Hide onshow_target;
			HideAllOnShow()
		else
			source_enable(false)
			-- setup {OnHide} {OnShow} -> Show onhide_target;
			ShowAllOnHide()
		end
		print ("HIDE & SHOW - activated!")
	end
end
-- randomizes the time of (Screen Time) and (Hide Time)
local index 	= 1
is_randomzied 	= false
function gene_randomize()
	if is_randomzied then
		sc_tm 	= math.random(1,obs.obs_data_get_int(_settings,"duration-one")) -- getting previous data and randomizes the results
		hd_tm	= math.random(1,obs.obs_data_get_int(_settings,"duration-two")) -- getting previous data and randomizes the results
		sctm_to_sec 	= math.floor(sc_tm * 60) -- converts the minutes to seconds
		hdtm_to_sec 	= math.floor(hd_tm * 60) -- converts the minutes to seconds
	end
end
function randomize_time_callback(ps,it)
	if not is_randomzied then
		print("(HIDE & SHOW): Randomize activated!\n\t-> Will use (Screen Time) & (Hide Time) to choose the randomness.");
		is_randomzied = true
		gene_randomize()
	else
		print("(HIDE & SHOW): Randomize deactivated!");
		is_randomzied 	= false
		sc_tm 	= obs.obs_data_get_int(_settings,"duration-one")
		hd_tm	= obs.obs_data_get_int(_settings,"duration-two")
		sctm_to_sec 	= math.floor(sc_tm * 60) --ctm_to_sec 	= math.floor(sctm_to_sec % 60)
		hdtm_to_sec 	= math.floor(hd_tm * 60) --hdtm_to_sec	= math.floor(hdtm_to_sec % 60)
		if is_init then
			init(); -- stop;
			init(); -- start;
		end
	end
end


-- returns the state of the object/source;
function get_state(name)
	local target_state = nil
	local target_source = obs.obs_get_source_by_name(name)
	if target_source then
		target_state = obs.obs_source_enabled(target_source)
		obs.obs_source_release(target_source)
	end
	return target_state;
end





-- adds a new object/source for (OnHide)
source_on_hide = {}
function add_to_onhide()
	local target_name 	= obs.obs_data_get_string(_settings,"onhide-source-selector")
	local target_name_exists = false;
	for key, target in pairs(source_on_hide) do
		if target.target_name == target_name then
			target_name_exists = true;
			break
		end
	end
	if not target_name_exists then
		local target_state = get_state(target_name)
		--print("State-Hide: " .. target_state)
		source_on_hide[target_name] = {
			target_name = target_name;state = target_state
		};
	end
	print("OnHide - Source List:")
	for key, _name in pairs(source_on_hide) do
		print("=> ".._name.target_name)
	end
end
-- removes an object/source for (OnHide)
function remove_to_onhide()
	local target_name 	= obs.obs_data_get_string(_settings,"onhide-source-selector")
	local target_name_exists = false;
	for key, _name in pairs(source_on_hide) do
		if key == target_name then
			target_name_exists = true;
			break
		end
	end
	if target_name_exists then
		source_on_hide[target_name] = nil
	end
	print("OnHide - Source List:")
	for key, _name in pairs(source_on_hide) do
		print("=> ".._name.target_name)
	end
end


-- adds a new object/source for (OnSHow)
source_on_show = {}
function add_to_onshow()
	local target_name 	= obs.obs_data_get_string(_settings,"onshow-source-selector")
	local target_name_exists = false;
	for key, target in pairs(source_on_show) do
		if target.target_name == target_name then
			target_name_exists = true;
			break
		end
	end
	if not target_name_exists then
		local target_state = get_state(target_name)
		--print("State-Show: " .. +)
		source_on_show[target_name] = {
			target_name = target_name;state = target_state
		};
	end
	print("OnShow - Source List:")
	for key, _name in pairs(source_on_show) do
		print("=> ".._name.target_name)
	end
end
-- removes an object/source for (OnSHow)
function remove_to_onshow()
	local target_name 	= obs.obs_data_get_string(_settings,"onshow-source-selector")
	local target_name_exists = false;
	for key, _name in pairs(source_on_show) do
		if _name == target_name then
			target_name_exists = true;
			break
		end
	end
	if not target_name_exists then
		source_on_show[target_name] = nil
	end
	print("OnShow - Source List:")
	for key, _name in pairs(source_on_show) do
		print("=> ".._name.target_name)
	end
end







-- The description that, the user will see
function script_description()
	return string.format([[	 (( HIDE & SHOW )) ]])
end


