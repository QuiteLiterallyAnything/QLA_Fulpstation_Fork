/datum/dynamic_ruleset/latejoin/infiltrator
	antag_datum = /datum/antagonist/traitor/infiltrator

/datum/dynamic_ruleset/midround/from_living/autotraitor
	antag_datum = /datum/antagonist/traitor/infiltrator/sleeper_agent

/datum/dynamic_ruleset/midround/from_living/autotraitor/execute()
	var/mob/M = pick(candidates)
	assigned += M
	candidates -= M
	var/datum/antagonist/traitor/infiltrator/sleeper_agent/newTraitor = new
	M.mind.add_antag_datum(newTraitor)
	message_admins("[ADMIN_LOOKUPFLW(M)] was selected by the [name] ruleset and has been made into a midround traitor.")
	log_dynamic("[key_name(M)] was selected by the [name] ruleset and has been made into a midround traitor.")
	return TRUE

