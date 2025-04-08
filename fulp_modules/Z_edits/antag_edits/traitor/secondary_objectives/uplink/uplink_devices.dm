// Uplink subtype used as replacement uplink
/obj/item/uplink/replacement
	lockable_uplink = TRUE

/obj/item/uplink/replacement/Initialize(mapload, owner, tc_amount = 10, datum/uplink_handler/uplink_handler_override = null)
	. = ..()
	var/datum/component/uplink/hidden_uplink = GetComponent(/datum/component/uplink)
	var/mob/living/replacement_needer = owner
	if(!istype(replacement_needer))
		return
	var/datum/antagonist/traitor/traitor_datum = replacement_needer?.mind.has_antag_datum(/datum/antagonist/traitor)
	hidden_uplink.unlock_code = traitor_datum?.replacement_uplink_code
	become_hearing_sensitive()

/obj/item/uplink/replacement/screwdriver_act_secondary(mob/living/user, obj/item/tool)
	tool.play_tool_sound(src)
	balloon_alert(user, "deconstructing...")
	if (!do_after(user, 3 SECONDS, target = src))
		return FALSE
	qdel(src)
	return TRUE

/obj/item/uplink/replacement/examine(mob/user)
	. = ..()
	if(!IS_TRAITOR(user))
		return
	. += span_notice("You can destroy this device with a screwdriver.")
