#define REMOTE_MODE_OFF "Off"
#define REMOTE_MODE_SELF "Local"
#define REMOTE_MODE_TARGET "Targeted"
#define REMOTE_MODE_AOE "Area"
#define REMOTE_MODE_RELAY "Relay"

/obj/item/nanite_remote
	name = "nanite remote control"
	desc = "A device that can remotely control active nanites through wireless signals."
	w_class = WEIGHT_CLASS_SMALL
	req_access = list(ACCESS_RESEARCH)
	icon = 'fulp_modules/icons/nanites/nanite_device.dmi'
	icon_state = "nanite_remote"
	base_icon_state = "nanite_remote"
	item_flags = NOBLUDGEON

	///Boolean on whether the nanite remote has been locked, preventing changing of any setting.
	var/locked = FALSE
	var/mode = REMOTE_MODE_OFF
	var/list/saved_settings = list()
	var/last_id = 0
	var/code = 0
	var/relay_code = 0
	var/current_program_name = "Program"

/obj/item/nanite_remote/examine(mob/user)
	. = ..()
	if(locked)
		. += span_notice("Alt-click to unlock.")

/obj/item/nanite_remote/click_alt(mob/user)
	if(!user.can_perform_action(src))
		return
	if(allowed(user))
		locked = !locked
		user.balloon_alert(user, (locked ? "locked" : "unlocked"))
		update_appearance(UPDATE_ICON)
	else
		user.balloon_alert(user, "access denied!")

/obj/item/nanite_remote/emag_act(mob/user)
	if(obj_flags & EMAGGED)
		return
	to_chat(user, span_warning("You override [src]'s ID lock."))
	obj_flags |= EMAGGED
	if(locked)
		locked = FALSE
		update_appearance(UPDATE_ICON)

/obj/item/nanite_remote/update_overlays()
	. = ..()
	if(obj_flags & EMAGGED)
		. += "[base_icon_state]_emagged"
	if(locked)
		. += "[base_icon_state]_locked"

/obj/item/nanite_remote/interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	switch(mode)
		if(REMOTE_MODE_SELF)
			to_chat(user, span_notice("You activate [src], signaling the nanites in your bloodstream."))
			signal_mob(user, code, key_name(user))
			return ITEM_INTERACT_SUCCESS
		if(REMOTE_MODE_TARGET)
			if(isliving(interacting_with) && (get_dist(interacting_with, get_turf(src)) <= 7))
				to_chat(user, span_notice("You activate [src], signaling the nanites inside [interacting_with]."))
				signal_mob(interacting_with, code, key_name(user))
				return ITEM_INTERACT_SUCCESS
		if(REMOTE_MODE_AOE)
			to_chat(user, span_notice("You activate [src], signaling the nanites inside every host around you."))
			for(var/mob/living/L in view(user, 7))
				signal_mob(L, code, key_name(user))
			return ITEM_INTERACT_SUCCESS
		if(REMOTE_MODE_RELAY)
			to_chat(user, span_notice("You activate [src], signaling all connected relay nanites."))
			signal_relay(code, relay_code, key_name(user))
			return ITEM_INTERACT_SUCCESS
	return ITEM_INTERACT_FAILURE

/obj/item/nanite_remote/proc/signal_mob(mob/living/M, code, source)
	SEND_SIGNAL(M, COMSIG_NANITE_SIGNAL, code, source)

/obj/item/nanite_remote/proc/signal_relay(code, relay_code, source)
	for(var/datum/nanite_program/relay/relays as anything in SSnanites.nanite_relays)
		relays.relay_signal(code, relay_code, source)

/obj/item/nanite_remote/ui_state(mob/user)
	return GLOB.hands_state

/obj/item/nanite_remote/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "NaniteRemote", name)
		ui.open()

/obj/item/nanite_remote/ui_data()
	var/list/data = list()
	data["code"] = code
	data["relay_code"] = relay_code
	data["mode"] = mode
	data["locked"] = locked
	data["saved_settings"] = saved_settings
	data["program_name"] = current_program_name
	return data

/obj/item/nanite_remote/ui_act(action, params)
	. = ..()
	if(.)
		return
	switch(action)
		if("set_code")
			if(locked)
				return
			var/new_code = text2num(params["code"])
			if(!isnull(new_code))
				new_code = clamp(round(new_code, 1),0,9999)
				code = new_code
			return TRUE
		if("set_relay_code")
			if(locked)
				return
			var/new_code = text2num(params["code"])
			if(!isnull(new_code))
				new_code = clamp(round(new_code, 1),0,9999)
				relay_code = new_code
			return TRUE
		if("update_name")
			current_program_name = params["name"]
			return TRUE
		if("save")
			if(locked)
				return
			var/new_save = list()
			new_save["id"] = last_id + 1
			last_id++
			new_save["name"] = current_program_name
			new_save["code"] = code
			new_save["mode"] = mode
			new_save["relay_code"] = relay_code
			saved_settings += list(new_save)
			return TRUE
		if("load")
			var/code_id = params["save_id"]
			var/list/setting
			for(var/list/X in saved_settings)
				if(X["id"] == text2num(code_id))
					setting = X
					break
			if(setting)
				code = setting["code"]
				mode = setting["mode"]
				relay_code = setting["relay_code"]
			return TRUE
		if("remove_save")
			if(locked)
				return
			var/code_id = params["save_id"]
			for(var/list/setting in saved_settings)
				if(setting["id"] == text2num(code_id))
					saved_settings -= list(setting)
					break
			return TRUE
		if("select_mode")
			if(locked)
				return
			mode = params["mode"]
			return TRUE
		if("lock")
			if(!(obj_flags & EMAGGED))
				locked = TRUE
				update_appearance()
			return TRUE


/obj/item/nanite_remote/comm
	name = "nanite communication remote"
	desc = "A device that can send text messages to specific programs."
	icon_state = "nanite_comm_remote"
	var/comm_message = ""

/obj/item/nanite_remote/comm/afterattack(atom/target, mob/user, proximity_flag, click_parameters)
	switch(mode)
		if(REMOTE_MODE_OFF)
			return
		if(REMOTE_MODE_SELF)
			to_chat(user, span_notice("You activate [src], signaling the nanites in your bloodstream."))
			signal_mob(user, code, comm_message)
		if(REMOTE_MODE_TARGET)
			if(isliving(target) && (get_dist(target, get_turf(src)) <= 7))
				to_chat(user, span_notice("You activate [src], signaling the nanites inside [target]."))
				signal_mob(target, code, comm_message, key_name(user))
		if(REMOTE_MODE_AOE)
			to_chat(user, span_notice("You activate [src], signaling the nanites inside every host around you."))
			for(var/mob/living/L in view(user, 7))
				signal_mob(L, code, comm_message, key_name(user))
		if(REMOTE_MODE_RELAY)
			to_chat(user, span_notice("You activate [src], signaling all connected relay nanites."))
			signal_relay(code, relay_code, comm_message, key_name(user))

/obj/item/nanite_remote/comm/signal_mob(mob/living/M, code, source)
	SEND_SIGNAL(M, COMSIG_NANITE_COMM_SIGNAL, code, comm_message)

/obj/item/nanite_remote/comm/signal_relay(code, relay_code, source)
	for(var/datum/nanite_program/relay/relays as anything in SSnanites.nanite_relays)
		relays.relay_comm_signal(code, relay_code, comm_message)

/obj/item/nanite_remote/comm/ui_data()
	var/list/data = list()
	data["comms"] = TRUE
	data["code"] = code
	data["relay_code"] = relay_code
	data["message"] = comm_message
	data["mode"] = mode
	data["locked"] = locked
	data["saved_settings"] = saved_settings
	data["program_name"] = current_program_name
	return data

/obj/item/nanite_remote/comm/ui_act(action, params)
	. = ..()
	if(.)
		return
	switch(action)
		if("set_message")
			if(locked)
				return
			var/new_message = html_encode(params["value"])
			if(!new_message)
				return
			comm_message = new_message
			return TRUE

#undef REMOTE_MODE_OFF
#undef REMOTE_MODE_SELF
#undef REMOTE_MODE_TARGET
#undef REMOTE_MODE_AOE
#undef REMOTE_MODE_RELAY
