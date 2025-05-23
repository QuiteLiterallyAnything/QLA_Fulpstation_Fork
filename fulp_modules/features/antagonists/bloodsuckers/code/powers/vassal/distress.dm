/datum/action/cooldown/bloodsucker/distress
	name = "Distress"
	desc = "Injure yourself to make a desperate call for help to your Master."
	button_icon_state = "power_distress"
	power_explanation = "Distress:\n\
		Use this Power from anywhere and your master Bloodsucker will instantly be alerted of your location."
	power_flags = NONE
	check_flags = NONE
	purchase_flags = NONE
	bloodcost = 10
	cooldown_time = 10 SECONDS
	should_level = FALSE

/datum/action/cooldown/bloodsucker/distress/ActivatePower(trigger_flags)
	. = ..()
	var/turf/open/floor/target_area = get_area(owner)
	var/datum/antagonist/vassal/vassaldatum = owner.mind.has_antag_datum(/datum/antagonist/vassal)

	owner.balloon_alert(owner, "you call out for your master!")
	to_chat(vassaldatum.master.owner, span_userdanger("[owner], your loyal vassal, is desperately calling for aid at [target_area]!"))

	var/mob/living/user = owner
	user.adjustBruteLoss(10)
