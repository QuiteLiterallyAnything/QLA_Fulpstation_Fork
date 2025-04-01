///////////////////////////////////////////////////////////////////////
///  This incredibly long proc contains a bit of logic that allows  ///
///  admins to override traitor secondnary objectives...            ///
///////////////////////////////////////////////////////////////////////

/datum/mind/Topic(href, href_list)
	if(!check_rights(R_ADMIN))
		return
	var/self_antagging = usr == current
	if(href_list["add_antag"])
		add_antag_wrapper(text2path(href_list["add_antag"]),usr)
	if(href_list["remove_antag"])
		var/datum/antagonist/A = locate(href_list["remove_antag"]) in antag_datums
		if(!istype(A))
			to_chat(usr,span_warning("Invalid antagonist ref to be removed."))
			return
		A.admin_remove(usr)
	if(href_list["open_antag_vv"])
		var/datum/antagonist/to_vv = locate(href_list["open_antag_vv"]) in antag_datums
		if(!istype(to_vv))
			to_chat(usr, span_warning("Invalid antagonist ref to be vv'd."))
			return
		usr.client?.debug_variables(to_vv)
	if (href_list["role_edit"])
		var/new_role = input("Select new role", "Assigned role", assigned_role.title) as null|anything in sort_list(SSjob.name_occupations)
		if(isnull(new_role))
			return
		var/datum/job/new_job = SSjob.get_job(new_role)
		if (!new_job)
			to_chat(usr, span_warning("Job not found."))
			return
		set_assigned_role(new_job)
	else if (href_list["obj_edit"] || href_list["obj_add"])
		var/objective_pos //Edited objectives need to keep same order in antag objective list
		var/def_value
		var/datum/antagonist/target_antag
		var/datum/objective/old_objective //The old objective we're replacing/editing
		var/datum/objective/new_objective //New objective we're be adding
		if(href_list["obj_edit"])
			for(var/datum/antagonist/A in antag_datums)
				old_objective = locate(href_list["obj_edit"]) in A.objectives
				if(old_objective)
					target_antag = A
					objective_pos = A.objectives.Find(old_objective)
					break
			if(!old_objective)
				to_chat(usr,"Invalid objective.")
				return
		else
			if(href_list["target_antag"])
				var/datum/antagonist/X = locate(href_list["target_antag"]) in antag_datums
				if(X)
					target_antag = X
			if(!target_antag)
				switch(antag_datums.len)
					if(0)
						target_antag = add_antag_datum(/datum/antagonist/custom)
					if(1)
						target_antag = antag_datums[1]
					else
						var/datum/antagonist/target = input("Which antagonist gets the objective:", "Antagonist", "(new custom antag)") as null|anything in sort_list(antag_datums) + "(new custom antag)"
						if (QDELETED(target))
							return
						else if(target == "(new custom antag)")
							target_antag = add_antag_datum(/datum/antagonist/custom)
						else
							target_antag = target
		if(!GLOB.admin_objective_list)
			generate_admin_objective_list()
		if(old_objective)
			if(old_objective.name in GLOB.admin_objective_list)
				def_value = old_objective.name
		var/selected_type = input("Select objective type:", "Objective type", def_value) as null|anything in GLOB.admin_objective_list
		selected_type = GLOB.admin_objective_list[selected_type]
		if (!selected_type)
			return
		if(!old_objective)
			//Add new one
			new_objective = new selected_type
			new_objective.owner = src
			new_objective.admin_edit(usr)
			target_antag.objectives += new_objective
			message_admins("[key_name_admin(usr)] added a new objective for [current]: [new_objective.explanation_text]")
			log_admin("[key_name(usr)] added a new objective for [current]: [new_objective.explanation_text]")
		else
			if(old_objective.type == selected_type)
				//Edit the old
				old_objective.admin_edit(usr)
				new_objective = old_objective
			else
				//Replace the old
				new_objective = new selected_type
				new_objective.owner = src
				new_objective.admin_edit(usr)
				target_antag.objectives -= old_objective
				target_antag.objectives.Insert(objective_pos, new_objective)
			message_admins("[key_name_admin(usr)] edited [current]'s objective to [new_objective.explanation_text]")
			log_admin("[key_name(usr)] edited [current]'s objective to [new_objective.explanation_text]")
	else if (href_list["obj_delete"])
		var/datum/objective/objective
		for(var/datum/antagonist/A in antag_datums)
			objective = locate(href_list["obj_delete"]) in A.objectives
			if(istype(objective))
				A.objectives -= objective
				break
		if(!objective)
			to_chat(usr,"Invalid objective.")
			return
		//qdel(objective) Needs cleaning objective destroys
		message_admins("[key_name_admin(usr)] removed an objective for [current]: [objective.explanation_text]")
		log_admin("[key_name(usr)] removed an objective for [current]: [objective.explanation_text]")
	else if(href_list["obj_completed"])
		var/datum/objective/objective
		for(var/datum/antagonist/A in antag_datums)
			objective = locate(href_list["obj_completed"]) in A.objectives
			if(istype(objective))
				objective = objective
				break
		if(!objective)
			to_chat(usr,"Invalid objective.")
			return
		objective.completed = !objective.completed
		log_admin("[key_name(usr)] toggled the win state for [current]'s objective: [objective.explanation_text]")
	else if(href_list["obj_prompt_custom"])
		var/datum/antagonist/target_antag
		if(href_list["target_antag"])
			var/datum/antagonist/found_datum = locate(href_list["target_antag"]) in antag_datums
			if(found_datum)
				target_antag = found_datum
		if(isnull(target_antag))
			switch(length(antag_datums))
				if(0)
					target_antag = add_antag_datum(/datum/antagonist/custom)
				if(1)
					target_antag = antag_datums[1]
				else
					var/datum/antagonist/target = input("Which antagonist gets the objective:", "Antagonist", "(new custom antag)") as null|anything in sort_list(antag_datums) + "(new custom antag)"
					if (QDELETED(target))
						return
					else if(target == "(new custom antag)")
						target_antag = add_antag_datum(/datum/antagonist/custom)
					else
						target_antag = target
		var/replace_existing = input("Replace existing objectives?","Replace objectives?") in list("Yes", "No")
		if (isnull(replace_existing))
			return
		replace_existing = replace_existing == "Yes"
		var/replace_escape
		if (!replace_existing)
			replace_escape = FALSE
		else
			replace_escape = input("Replace survive/escape/martyr objectives?","Replace objectives?") in list("Yes", "No")
			if (isnull(replace_escape))
				return
			replace_escape = replace_escape == "Yes"
		target_antag.submit_player_objective(retain_existing = !replace_existing, retain_escape = !replace_escape, force = TRUE)
		log_admin("[key_name(usr)] prompted [current] to enter their own objectives for [target_antag].")
	else if (href_list["silicon"])
		switch(href_list["silicon"])
			if("unemag")
				var/mob/living/silicon/robot/R = current
				if (istype(R))
					R.SetEmagged(0)
					message_admins("[key_name_admin(usr)] has unemag'ed [R].")
					log_admin("[key_name(usr)] has unemag'ed [R].")
			if("unemagcyborgs")
				if(isAI(current))
					var/mob/living/silicon/ai/ai = current
					for (var/mob/living/silicon/robot/R in ai.connected_robots)
						R.SetEmagged(0)
					message_admins("[key_name_admin(usr)] has unemag'ed [ai]'s Cyborgs.")
					log_admin("[key_name(usr)] has unemag'ed [ai]'s Cyborgs.")

	else if(href_list["edit_obj_tc"])
		var/datum/traitor_objective/objective = locate(href_list["edit_obj_tc"])
		if(!istype(objective))
			return
		var/telecrystal = input("Set new telecrystal reward for [objective.name]","Syndicate uplink", objective.telecrystal_reward) as null | num
		if(isnull(telecrystal))
			return
		objective.telecrystal_reward = telecrystal
		message_admins("[key_name_admin(usr)] changed [objective]'s telecrystal reward count to [telecrystal].")
		log_admin("[key_name(usr)] changed [objective]'s telecrystal reward count to [telecrystal].")
	else if(href_list["edit_obj_pr"])
		var/datum/traitor_objective/objective = locate(href_list["edit_obj_pr"])
		if(!istype(objective))
			return
		var/progression = input("Set new progression reward for [objective.name]","Syndicate uplink", objective.progression_reward) as null | num
		if(isnull(progression))
			return
		objective.progression_reward = progression
		message_admins("[key_name_admin(usr)] changed [objective]'s progression reward count to [progression].")
		log_admin("[key_name(usr)] changed [objective]'s progression reward count to [progression].")
	else if(href_list["fail_objective"])
		var/datum/traitor_objective/objective = locate(href_list["fail_objective"])
		if(!istype(objective))
			return
		var/performed = objective.objective_state == OBJECTIVE_STATE_INACTIVE? "skipped" : "failed"
		message_admins("[key_name_admin(usr)] forcefully [performed] [objective].")
		log_admin("[key_name(usr)] forcefully [performed] [objective].")
		objective.fail_objective()
	else if(href_list["succeed_objective"])
		var/datum/traitor_objective/objective = locate(href_list["succeed_objective"])
		if(!istype(objective))
			return
		message_admins("[key_name_admin(usr)] forcefully succeeded [objective].")
		log_admin("[key_name(usr)] forcefully succeeded [objective].")
		objective.succeed_objective()
	else if (href_list["common"])
		switch(href_list["common"])
			if("undress")
				for(var/obj/item/W in current)
					current.dropItemToGround(W, TRUE) //The TRUE forces all items to drop, since this is an admin undress.
			if("takeuplink")
				take_uplink()
				wipe_memory_type(/datum/memory/key/traitor_uplink/implant)
				log_admin("[key_name(usr)] removed [current]'s uplink.")
			if("crystals")
				if(check_rights(R_FUN))
					var/datum/component/uplink/U = find_syndicate_uplink()
					if(U)
						var/crystals = tgui_input_number(
							user = usr,
							message = "Amount of telecrystals for [key]",
							title = "Syndicate uplink",
							default = U.uplink_handler.telecrystals,
						)
						if(isnum(crystals))
							U.uplink_handler.set_telecrystals(crystals)
							message_admins("[key_name_admin(usr)] changed [current]'s telecrystal count to [crystals].")
							log_admin("[key_name(usr)] changed [current]'s telecrystal count to [crystals].")
			if("progression")
				if(!check_rights(R_FUN))
					return
				var/datum/component/uplink/uplink = find_syndicate_uplink()
				if(!uplink)
					return
				var/progression = input("Set new progression points for [key]","Syndicate uplink", uplink.uplink_handler.progression_points) as null | num
				if(isnull(progression))
					return
				uplink.uplink_handler.progression_points = progression
				message_admins("[key_name_admin(usr)] changed [current]'s progression point count to [progression].")
				log_admin("[key_name(usr)] changed [current]'s progression point count to [progression].")
				uplink.uplink_handler.update_objectives()
				uplink.uplink_handler.generate_objectives()
			if("give_objective")
				if(!check_rights(R_FUN))
					return
				var/datum/component/uplink/uplink = find_syndicate_uplink()
				if(!uplink || !uplink.uplink_handler)
					return
				var/list/all_objectives = subtypesof(/datum/traitor_objective)
				var/objective_typepath = tgui_input_list(usr, "Select objective", "Select objective", all_objectives)
				if(!objective_typepath)
					return
				var/datum/traitor_objective/objective = uplink.uplink_handler.try_add_objective(objective_typepath, force = TRUE)
				if(objective)
					message_admins("[key_name_admin(usr)] gave [current] a traitor objective ([objective_typepath]).")
					log_admin("[key_name(usr)] gave [current] a traitor objective ([objective_typepath]).")
				else
					to_chat(usr, span_warning("Failed to generate the objective!"))
					message_admins("[key_name_admin(usr)] failed to give [current] a traitor objective ([objective_typepath]).")
					log_admin("[key_name(usr)] failed to give [current] a traitor objective ([objective_typepath]).")
			if("uplink")
				var/datum/antagonist/traitor/traitor_datum = has_antag_datum(/datum/antagonist/traitor)
				if(!give_uplink(antag_datum = traitor_datum || null))
					to_chat(usr, span_danger("Equipping a syndicate failed!"))
					log_admin("[key_name(usr)] tried and failed to give [current] an uplink.")
				else
					log_admin("[key_name(usr)] gave [current] an uplink.")
	else if (href_list["obj_announce"])
		announce_objectives()
	//Something in here might have changed your mob
	if(self_antagging && (!usr || !usr.client) && current.client)
		usr = current
	traitor_panel()
