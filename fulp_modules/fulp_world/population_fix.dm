
/// Adapted from the admin verb "spawn_debug_full_crew" in 'code\modules\admin\admin_verbs.dm'
/proc/populate_station()
	// A list of jobs that we exclude during the spawning loop.
	var/list/jobs_to_exclude = list(
		JOB_CAPTAIN,
		JOB_HEAD_OF_PERSONNEL,
		JOB_HEAD_OF_SECURITY,
		JOB_RESEARCH_DIRECTOR,
		JOB_CHIEF_ENGINEER,
		JOB_CHIEF_MEDICAL_OFFICER,
		JOB_BRIDGE_ASSISTANT,
		JOB_VETERAN_ADVISOR,
		JOB_AI,
		JOB_CORONER,
		JOB_CARGO_GORILLA,
		JOB_PUN_PUN,
		JOB_PERSONAL_AI,
		JOB_HUMAN_AI,
	)

	// Okay, now go through all nameable occupations.
	// Pick out all jobs that have JOB_CREW_MEMBER set.
	// Then, spawn a human and slap a person into it.
	for(var/rank in SSjob.name_occupations)
		if(rank in jobs_to_exclude)
			continue

		var/datum/job/job = SSjob.get_job(rank)

		// JOB_CREW_MEMBER is all jobs that pretty much aren't silicon
		if(!(job.job_flags & JOB_CREW_MEMBER))
			continue

		// Create our new_player for this job and set up its mind.
		var/mob/dead/new_player/new_guy = new()
		new_guy.mind_initialize()
		new_guy.mind.name = "[rank] Dummy"


		// Assign the rank to the new player dummy.
		if(!SSjob.assign_role(new_guy, job, do_eligibility_checks = FALSE))
			qdel(new_guy)
			continue

		// It's got a job, spawn in a human and shove it in the human.
		var/atom/destination = new_guy.mind.assigned_role.get_roundstart_spawn_point()
		var/mob/living/carbon/human/character = new(destination)
		character.name = new_guy.mind.name
		new_guy.mind.transfer_to(character)
		qdel(new_guy)

		// Then equip up the human with job gear.
		SSjob.equip_rank(character, job)
		job.after_latejoin_spawn(character)

		// Finally, ensure the minds are tracked and in the manifest.
		SSticker.minds += character.mind
		if(ishuman(character))
			GLOB.manifest.inject(character)

		CHECK_TICK
