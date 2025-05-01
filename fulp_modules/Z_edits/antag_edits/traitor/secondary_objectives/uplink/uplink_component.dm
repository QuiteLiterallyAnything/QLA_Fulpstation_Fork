/datum/component/uplink/Initialize(
	owner,
	lockable = TRUE,
	enabled = FALSE,
	uplink_flag = UPLINK_TRAITORS,
	starting_tc = TELECRYSTALS_DEFAULT,
	has_progression = FALSE,
	datum/uplink_handler/uplink_handler_override,
)
	if(!isitem(parent))
		return COMPONENT_INCOMPATIBLE
	RegisterSignal(parent, COMSIG_ATOM_ATTACKBY, PROC_REF(OnAttackBy))
	RegisterSignal(parent, COMSIG_ITEM_ATTACK_SELF, PROC_REF(interact))
	if(istype(parent, /obj/item/implant))
		RegisterSignal(parent, COMSIG_IMPLANT_ACTIVATED, PROC_REF(implant_activation))
		RegisterSignal(parent, COMSIG_IMPLANT_IMPLANTING, PROC_REF(implanting))
		RegisterSignal(parent, COMSIG_IMPLANT_OTHER, PROC_REF(old_implant))
		RegisterSignal(parent, COMSIG_IMPLANT_EXISTING_UPLINK, PROC_REF(new_implant))
	else if(istype(parent, /obj/item/modular_computer))
		RegisterSignal(parent, COMSIG_TABLET_CHANGE_ID, PROC_REF(new_ringtone))
		RegisterSignal(parent, COMSIG_TABLET_CHECK_DETONATE, PROC_REF(check_detonate))
	else if(istype(parent, /obj/item/radio))
		RegisterSignal(parent, COMSIG_RADIO_NEW_MESSAGE, PROC_REF(new_message))
	else if(istype(parent, /obj/item/pen))
		RegisterSignal(parent, COMSIG_PEN_ROTATED, PROC_REF(pen_rotation))
	else if(istype(parent, /obj/item/uplink/replacement))
		RegisterSignal(parent, COMSIG_MOVABLE_HEAR, PROC_REF(on_heard))

	if(owner)
		src.owner = owner
		LAZYINITLIST(GLOB.uplink_purchase_logs_by_key)
		if(GLOB.uplink_purchase_logs_by_key[owner])
			purchase_log = GLOB.uplink_purchase_logs_by_key[owner]
		else
			purchase_log = new(owner, src)
		RegisterSignal(parent, COMSIG_ATOM_EXAMINE, PROC_REF(on_examine))
	src.lockable = lockable
	src.active = enabled
	if(!uplink_handler_override)
		uplink_handler = new()
		uplink_handler.has_objectives = FALSE
		uplink_handler.uplink_flag = uplink_flag
		uplink_handler.telecrystals = starting_tc
		uplink_handler.has_progression = has_progression
		uplink_handler.purchase_log = purchase_log
	else
		uplink_handler = uplink_handler_override
	RegisterSignal(uplink_handler, COMSIG_UPLINK_HANDLER_ON_UPDATE, PROC_REF(handle_uplink_handler_update))
	RegisterSignal(uplink_handler, COMSIG_UPLINK_HANDLER_REPLACEMENT_ORDERED, PROC_REF(handle_uplink_replaced))
	if(!lockable)
		active = TRUE
		locked = FALSE
	previous_attempts = list()


/// When a new uplink is made via the syndicate beacon it locks all lockable uplinks and destroys replacement uplinks
/datum/component/uplink/proc/handle_uplink_replaced()
	SIGNAL_HANDLER
	if(lockable)
		lock_uplink()
	if(!istype(parent, /obj/item/uplink/replacement))
		return
	var/obj/item/uplink_item = parent
	do_sparks(number = 3, cardinal_only = FALSE, source = uplink_item)
	uplink_item.visible_message(span_warning("The [uplink_item] suddenly combusts!"), vision_distance = COMBAT_MESSAGE_RANGE)
	new /obj/effect/decal/cleanable/ash(get_turf(uplink_item))
	qdel(uplink_item)

/// Proc that unlocks a locked replacement uplink when it hears the unlock code from their datum
/datum/component/uplink/proc/on_heard(datum/source, list/hearing_args)
	SIGNAL_HANDLER
	if(!locked)
		return
	if(!findtext(hearing_args[HEARING_RAW_MESSAGE], unlock_code))
		return
	var/atom/replacement_uplink = parent
	locked = FALSE
	replacement_uplink.balloon_alert_to_viewers("beep", vision_distance = COMBAT_MESSAGE_RANGE)

/datum/component/uplink/ui_interact(mob/user, datum/tgui/ui)
	active = TRUE
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "FulpUplink", name)
		// This UI is only ever opened by one person,
		// and never is updated outside of user input.
		ui.set_autoupdate(FALSE)
		ui.open()

/datum/component/uplink/ui_data(mob/user)
	if(!user.mind)
		return
	var/list/data = list()
	data["telecrystals"] = uplink_handler.telecrystals
	data["progression_points"] = uplink_handler.progression_points
	data["current_expected_progression"] = SStraitor.current_global_progression
	data["maximum_active_objectives"] = uplink_handler.maximum_active_objectives
	data["progression_scaling_deviance"] = SStraitor.progression_scaling_deviance
	data["current_progression_scaling"] = SStraitor.current_progression_scaling

	data["maximum_potential_objectives"] = uplink_handler.maximum_potential_objectives

	if(uplink_handler.primary_objectives)
		var/list/primary_objectives = list()
		for(var/datum/objective/task as anything in uplink_handler.primary_objectives)
			var/list/task_data = list()
			if(length(primary_objectives) > length(GLOB.phonetic_alphabet))
				task_data["task_name"] = "DIRECTIVE [length(primary_objectives) + 1]" //The english alphabet is WEAK
			else
				task_data["task_name"] = "DIRECTIVE [uppertext(GLOB.phonetic_alphabet[length(primary_objectives) + 1])]"
			task_data["task_text"] = task.explanation_text
			primary_objectives += list(task_data)
		data["primary_objectives"] = primary_objectives

	if(uplink_handler.has_objectives)
		var/list/potential_objectives = list()
		for(var/index in 1 to uplink_handler.potential_objectives.len)
			var/datum/traitor_objective/objective = uplink_handler.potential_objectives[index]
			var/list/objective_data = objective.uplink_ui_data(user)
			objective_data["id"] = index
			potential_objectives += list(objective_data)

		var/list/active_objectives = list()
		for(var/index in 1 to uplink_handler.active_objectives.len)
			var/datum/traitor_objective/objective = uplink_handler.active_objectives[index]
			var/list/objective_data = objective.uplink_ui_data(user)
			objective_data["id"] = index
			active_objectives += list(objective_data)


		data["potential_objectives"] = potential_objectives
		data["active_objectives"] = active_objectives
		data["completed_final_objective"] = uplink_handler.final_objective

	var/list/stock_list = uplink_handler.item_stock.Copy()
	var/list/extra_purchasable_stock = list()
	var/list/extra_purchasable = list()
	for(var/datum/uplink_item/item as anything in uplink_handler.extra_purchasable)
		if(item.stock_key in stock_list)
			extra_purchasable_stock[REF(item)] = stock_list[item.stock_key]
		var/atom/actual_item = item.item
		extra_purchasable += list(list(
			"id" = item.type,
			"name" = item.name,
			"icon" = actual_item.icon,
			"icon_state" = actual_item.icon_state,
			"cost" = item.cost,
			"desc" = item.desc,
			"category" = item.category ? initial(item.category.name) : null,
			"purchasable_from" = item.purchasable_from,
			"restricted" = item.restricted,
			"limited_stock" = item.limited_stock,
			"restricted_roles" = item.restricted_roles,
			"restricted_species" = item.restricted_species,
			"progression_minimum" = item.progression_minimum,
			"ref" = REF(item),
		))
	var/list/remaining_stock = list()
	for(var/item as anything in stock_list)
		remaining_stock[item] = stock_list[item]
	data["extra_purchasable"] = extra_purchasable
	data["extra_purchasable_stock"] = extra_purchasable_stock
	data["current_stock"] = remaining_stock
	data["shop_locked"] = uplink_handler.shop_locked
	data["purchased_items"] = length(uplink_handler.purchase_log?.purchase_log)
	data["can_renegotiate"] = user.mind == uplink_handler.owner && uplink_handler.can_replace_objectives?.Invoke() == TRUE
	return data

/datum/component/uplink/ui_static_data(mob/user)
	var/list/data = list()
	data["uplink_flag"] = uplink_handler.uplink_flag
	data["has_progression"] = uplink_handler.has_progression
	data["has_objectives"] = uplink_handler.has_objectives
	data["lockable"] = lockable
	data["assigned_role"] = uplink_handler.assigned_role
	data["assigned_species"] = uplink_handler.assigned_species
	data["debug"] = uplink_handler.debug_mode
	return data

/datum/component/uplink/ui_act(action, params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	if(!active)
		return
	switch(action)
		if("buy")
			var/datum/uplink_item/item
			if(params["ref"])
				item = locate(params["ref"]) in uplink_handler.extra_purchasable
				if(!item)
					return
			else
				var/datum/uplink_item/item_path = text2path(params["path"])
				if(!ispath(item_path, /datum/uplink_item))
					return
				item = SStraitor.uplink_items_by_type[item_path]
			uplink_handler.purchase_item(ui.user, item, parent)
		if("buy_raw_tc")
			if (uplink_handler.telecrystals <= 0)
				return
			var/desired_amount = tgui_input_number(ui.user, "How many raw telecrystals to buy?", "Buy Raw TC", default = uplink_handler.telecrystals, max_value = uplink_handler.telecrystals)
			if(!desired_amount || desired_amount < 1)
				return
			uplink_handler.purchase_raw_tc(ui.user, desired_amount, parent)
		if("lock")
			if(!lockable)
				return TRUE
			lock_uplink()
		if("renegotiate_objectives")
			uplink_handler.replace_objectives?.Invoke()
			SStgui.update_uis(src)

	if(!uplink_handler.has_objectives)
		return TRUE

	if(uplink_handler.owner?.current != ui.user || !uplink_handler.can_take_objectives)
		return TRUE

	switch(action)
		if("regenerate_objectives")
			uplink_handler.generate_objectives()
			return TRUE

	var/list/objectives
	switch(action)
		if("start_objective")
			objectives = uplink_handler.potential_objectives
		if("objective_act", "finish_objective", "objective_abort")
			objectives = uplink_handler.active_objectives

	if(!objectives)
		return

	var/objective_index = round(text2num(params["index"]))
	if(objective_index < 1 || objective_index > length(objectives))
		return TRUE
	var/datum/traitor_objective/objective = objectives[objective_index]

	// Objective actions
	switch(action)
		if("start_objective")
			uplink_handler.take_objective(ui.user, objective)
		if("objective_act")
			uplink_handler.ui_objective_act(ui.user, objective, params["objective_action"])
		if("finish_objective")
			if(!objective.finish_objective(ui.user))
				return
			uplink_handler.complete_objective(objective)
		if("objective_abort")
			uplink_handler.abort_objective(objective)
	return TRUE
