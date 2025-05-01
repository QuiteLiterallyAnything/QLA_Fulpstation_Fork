
/datum/antagonist/traitor
	/// Whether to give secondary objectives to the traitor, which aren't necessary but can be completed for a progression and TC boost.
	var/give_secondary_objectives = TRUE

	/// Code that allows traitor to get a replacement uplink
	var/replacement_uplink_code = ""
	/// Radio frequency that traitor must speak on to get a replacement uplink
	var/replacement_uplink_frequency = ""

	ui_name = "FulpAntagInfoTraitor"

/datum/antagonist/traitor/on_gain()
	..()
	generate_replacement_codes()

	var/datum/component/uplink/uplink = owner.find_syndicate_uplink()
	if(uplink)
		if(give_secondary_objectives)
			uplink_handler.has_objectives = TRUE
			uplink_handler.generate_objectives()

	owner.teach_crafting_recipe(/datum/crafting_recipe/syndicate_uplink_beacon)

/datum/antagonist/traitor/on_removal()
	. = ..()
	if(!isnull(uplink_handler))
		uplink_handler.has_objectives = FALSE

	owner.forget_crafting_recipe(/datum/crafting_recipe/syndicate_uplink_beacon)

/datum/antagonist/traitor/proc/traitor_objective_to_html(datum/traitor_objective/to_display)
	var/string = "[to_display.name]"
	if(to_display.objective_state == OBJECTIVE_STATE_ACTIVE || to_display.objective_state == OBJECTIVE_STATE_INACTIVE)
		string += " <a href='byond://?src=[REF(owner)];edit_obj_tc=[REF(to_display)]'>[to_display.telecrystal_reward] TC</a>"
		string += " <a href='byond://?src=[REF(owner)];edit_obj_pr=[REF(to_display)]'>[to_display.progression_reward] PR</a>"
	else
		string += ", [to_display.telecrystal_reward] TC"
		string += ", [to_display.progression_reward] PR"
	if(to_display.objective_state == OBJECTIVE_STATE_ACTIVE && !istype(to_display, /datum/traitor_objective/ultimate))
		string += " <a href='byond://?src=[REF(owner)];fail_objective=[REF(to_display)]'>Fail this objective</a>"
		string += " <a href='byond://?src=[REF(owner)];succeed_objective=[REF(to_display)]'>Succeed this objective</a>"
	if(to_display.objective_state == OBJECTIVE_STATE_INACTIVE)
		string += " <a href='byond://?src=[REF(owner)];fail_objective=[REF(to_display)]'>Dispose of this objective</a>"

	if(to_display.skipped)
		string += " - <b>Skipped</b>"
	else if(to_display.objective_state == OBJECTIVE_STATE_FAILED)
		string += " - <b><font color='red'>Failed</font></b>"
	else if(to_display.objective_state == OBJECTIVE_STATE_INVALID)
		string += " - <b>Invalidated</b>"
	else if(to_display.objective_state == OBJECTIVE_STATE_COMPLETED)
		string += " - <b><font color='green'>Succeeded</font></b>"

	return string

/datum/antagonist/traitor/antag_panel_objectives()
	var/result = ..()
	if(!uplink_handler)
		return result
	result += "<i><b>Traitor specific objectives</b></i><br>"
	result += "<i><b>Concluded Objectives</b></i>:<br>"
	for(var/datum/traitor_objective/objective as anything in uplink_handler.completed_objectives)
		result += "[traitor_objective_to_html(objective)]<br>"
	if(!length(uplink_handler.completed_objectives))
		result += "EMPTY<br>"
	result += "<i><b>Ongoing Objectives</b></i>:<br>"
	for(var/datum/traitor_objective/objective as anything in uplink_handler.active_objectives)
		result += "[traitor_objective_to_html(objective)]<br>"
	if(!length(uplink_handler.active_objectives))
		result += "EMPTY<br>"
	result += "<i><b>Potential Objectives</b></i>:<br>"
	for(var/datum/traitor_objective/objective as anything in uplink_handler.potential_objectives)
		result += "[traitor_objective_to_html(objective)]<br>"
	if(!length(uplink_handler.potential_objectives))
		result += "EMPTY<br>"
	result += "<a href='byond://?src=[REF(owner)];common=give_objective'>Force add objective</a><br>"
	return result

/// proc that generates the traitors replacement uplink code and radio frequency
/datum/antagonist/traitor/proc/generate_replacement_codes()
	replacement_uplink_code = "[pick(GLOB.phonetic_alphabet)] [rand(10,99)]"
	replacement_uplink_frequency = sanitize_frequency(rand(MIN_UNUSED_FREQ, MAX_FREQ), free = FALSE, syndie = FALSE)

/datum/antagonist/traitor/ui_static_data(mob/user)
	var/datum/component/uplink/uplink = uplink_ref?.resolve()
	var/list/data = list()
	data["has_codewords"] = should_give_codewords
	if(should_give_codewords)
		data["phrases"] = jointext(GLOB.syndicate_code_phrase, ", ")
		data["responses"] = jointext(GLOB.syndicate_code_response, ", ")
	data["theme"] = traitor_flavor["ui_theme"]
	data["code"] = uplink?.unlock_code
	data["failsafe_code"] = uplink?.failsafe_code
	data["replacement_code"] = replacement_uplink_code
	data["replacement_frequency"] = format_frequency(replacement_uplink_frequency)
	data["intro"] = traitor_flavor["introduction"]
	data["allies"] = traitor_flavor["allies"]
	data["goal"] = traitor_flavor["goal"]
	data["has_uplink"] = uplink ? TRUE : FALSE
	data["given_uplink"] = give_uplink
	if(uplink)
		data["uplink_intro"] = traitor_flavor["uplink"]
		data["uplink_unlock_info"] = uplink.unlock_text
	data["objectives"] = get_objectives()
	return data

/datum/antagonist/traitor/roundend_report()
	var/list/result = list()
	var/traitor_won = TRUE
	result += printplayer(owner)
	var/used_telecrystals = 0
	var/uplink_owned = FALSE
	var/purchases = ""
	LAZYINITLIST(GLOB.uplink_purchase_logs_by_key)
	// Uplinks add an entry to uplink_purchase_logs_by_key on init.
	var/datum/uplink_purchase_log/purchase_log = GLOB.uplink_purchase_logs_by_key[owner.key]
	if(purchase_log)
		used_telecrystals = purchase_log.total_spent
		uplink_owned = TRUE
		purchases += purchase_log.generate_render(FALSE)
	var/objectives_text = ""
	if(objectives.len) //If the traitor had no objectives, don't need to process this.
		var/count = 1
		for(var/datum/objective/objective in objectives)
			if(!objective.check_completion())
				traitor_won = FALSE
			objectives_text += "<br><B>Objective #[count]</B>: [objective.explanation_text] [objective.get_roundend_success_suffix()]"
			count++
		if(uplink_handler.final_objective)
			objectives_text += "<br>[span_greentext("[traitor_won ? "Additionally" : "However"], the final objective \"[uplink_handler.final_objective]\" was completed!")]"
			traitor_won = TRUE

	result += "<br>[owner.name] <B>[traitor_flavor["roundend_report"]]</B>"

	if(uplink_owned)
		var/uplink_text = "(used [used_telecrystals] TC) [purchases]"
		if((used_telecrystals == 0) && traitor_won)
			var/static/icon/badass = icon('icons/ui/antags/badass.dmi', "badass")
			uplink_text += "<BIG>[icon2html(badass, world)]</BIG>"
		result += uplink_text
	result += objectives_text
	if(uplink_handler)
		if (uplink_handler.contractor_hub)
			result += contractor_round_end()
		result += "<br>The traitor had a total of [DISPLAY_PROGRESSION(uplink_handler.progression_points)] Reputation and [uplink_handler.telecrystals] Unused Telecrystals."
	var/special_role_text = LOWER_TEXT(name)
	if(traitor_won)
		result += span_greentext("The [special_role_text] was successful!")
	else
		result += span_redtext("The [special_role_text] has failed!")
		SEND_SOUND(owner.current, 'sound/ambience/misc/ambifailure.ogg')
	return result.Join("<br>")

/datum/antagonist/traitor/infiltrator
	// Used to denote traitors who have joined midround and therefore have no access to secondary objectives.
	// Progression elements are best left to the roundstart antagonists
	// There will still be a timelock on uplink items
	name = "\improper Infiltrator"
	give_secondary_objectives = FALSE
	uplink_flag_given = UPLINK_INFILTRATORS

/datum/antagonist/traitor/infiltrator/sleeper_agent
	name = "\improper Syndicate Sleeper Agent"

