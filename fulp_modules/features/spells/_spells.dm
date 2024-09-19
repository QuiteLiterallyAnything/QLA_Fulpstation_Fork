/datum/action/cooldown/spell/summon_dancefloor
	name = "Summon Dancefloor"
	desc = "When what a Devil really needs is funk."

	spell_requirements = NONE
	school = SCHOOL_EVOCATION
	cooldown_time = 20 SECONDS //20 seconds, so the effects can't be spammed
	invocation_type = INVOCATION_SHOUT
	invocation = "DR'P TH' B'T!!!"

	button_icon = 'icons/mob/actions/actions_minor_antag.dmi'
	button_icon_state = "funk"

	var/list/dancefloor_turfs
	var/list/dancefloor_turfs_types
	var/dancefloor_exists = FALSE

	var/datum/jukebox/effects_handler
	//List of brief song snippets that are later associated with visual effects on cast.
	//All effects and associated vars/procs copied over from dance machine code with minor adjustments.
	var/list/dancefloor_flare = list(
		'fulp_modules/sounds/effects/summon_dance_floor/title0_shortened.ogg',
		'fulp_modules/sounds/effects/summon_dance_floor/title2_shortened.ogg',
		'fulp_modules/sounds/effects/summon_dance_floor/title3_shortened.ogg',
	)
	/// Spotlight effects being played
	VAR_PRIVATE/list/obj/item/flashlight/spotlight/spotlights = list()
	/// Sparkle effects being played
	VAR_PRIVATE/list/obj/effect/overlay/sparkles/sparkles = list()

/datum/action/cooldown/spell/summon_dancefloor/cast(atom/target)
	. = ..()
	owner.emote("scream") //DISCO, HECK YEAH!!!
	var/list/funky_turfs = RANGE_TURFS(1, owner)
	for(var/turf/closed/solid in funky_turfs)
		to_chat(owner, span_warning("You're too close to a wall."))
		return

	if(dancefloor_exists)
		delete_dancefloor()

	LAZYINITLIST(dancefloor_turfs)
	LAZYINITLIST(dancefloor_turfs_types)

	dancefloor_exists = TRUE

	var/i = 1
	dancefloor_turfs.len = funky_turfs.len
	dancefloor_turfs_types.len = funky_turfs.len
	for(var/t in funky_turfs)
		var/turf/T = t
		dancefloor_turfs[i] = T
		dancefloor_turfs_types[i] = T.type
		T.ChangeTurf((i % 2 == 0) ? /turf/open/floor/light/colour_cycle/dancefloor_a : /turf/open/floor/light/colour_cycle/dancefloor_b, flags = CHANGETURF_INHERIT_AIR)
		i++

	var/desired_effect = pick(dancefloor_flare)
	playsound(get_turf(owner), desired_effect, 100, extrarange = 10, ignore_walls = TRUE)
	StartCooldown()
	switch(desired_effect)
		if('fulp_modules/sounds/effects/summon_dance_floor/title0_shortened.ogg')
			hierofunk()
		if('fulp_modules/sounds/effects/summon_dance_floor/title2_shortened.ogg')
			dance_setup()
			while(dancefloor_exists)
				rainbow_lights()
		if('fulp_modules/sounds/effects/summon_dance_floor/title3_shortened.ogg')
			lights_spin()

/datum/action/cooldown/spell/summon_dancefloor/proc/delete_dancefloor()
	dancefloor_exists = FALSE
	QDEL_LIST(spotlights)
	QDEL_LIST(sparkles)
	for(var/i in 1 to dancefloor_turfs.len)
		var/turf/T = dancefloor_turfs[i]
		T.ChangeTurf(dancefloor_turfs_types[i], flags = CHANGETURF_INHERIT_AIR)

//////////////////////////////////////////////////////////////////////////////////
// ALL CODE AFTER THIS POINT HAS BEEN COPIED/READAPTED FROM DANCE MACHINE CODE. //
//////////////////////////////////////////////////////////////////////////////////

/datum/action/cooldown/spell/summon_dancefloor/proc/hierofunk()
	var/turf/target_turf = get_turf(owner)
	for(var/i in 1 to 15)
		spawn_atom_to_turf(/obj/effect/temp_visual/hierophant/telegraph/edge, target_turf, 1, FALSE)
		sleep(0.75 SECONDS)

/datum/action/cooldown/spell/summon_dancefloor/proc/lights_spin()
	var/turf/target_turf = get_turf(owner)
	for(var/i in 1 to 25)
		var/obj/effect/overlay/sparkles/S = new /obj/effect/overlay/sparkles(target_turf)
		sparkles += S
		switch(i)
			if(1 to 8)
				S.orbit(target_turf, 30, TRUE, 60, 36, TRUE)
			if(9 to 15)
				S.orbit(target_turf, 62, TRUE, 60, 36, TRUE)
			if(16)
				S.orbit(target_turf, 62, TRUE, 60, 36, TRUE)
				playsound(target_turf, 'sound/magic/blind.ogg', 37, frequency = -1)
				for(var/mob/living/M in viewers(target_turf))
					M.emote("spin")
					M.emote("flip")
					M.emote("snap")
			if(17 to 24)
				S.orbit(target_turf, 95, TRUE, 60, 36, TRUE)
		sleep(0.7 SECONDS)

/datum/action/cooldown/spell/summon_dancefloor/proc/dance_setup()
	var/turf/cen = get_turf(owner)
	FOR_DVIEW(var/turf/t, 3, get_turf(owner),INVISIBILITY_LIGHTING)
		if(t.x == cen.x && t.y > cen.y)
			spotlights += new /obj/item/flashlight/spotlight(t, 1 + get_dist(owner, t), 30 - (get_dist(owner, t) * 8), COLOR_SOFT_RED)
			continue
		if(t.x == cen.x && t.y < cen.y)
			spotlights += new /obj/item/flashlight/spotlight(t, 1 + get_dist(owner, t), 30 - (get_dist(owner, t) * 8), LIGHT_COLOR_PURPLE)
			continue
		if(t.x > cen.x && t.y == cen.y)
			spotlights += new /obj/item/flashlight/spotlight(t, 1 + get_dist(owner, t), 30 - (get_dist(owner, t) * 8), LIGHT_COLOR_DIM_YELLOW)
			continue
		if(t.x < cen.x && t.y == cen.y)
			spotlights += new /obj/item/flashlight/spotlight(t, 1 + get_dist(owner, t), 30 - (get_dist(owner, t) * 8), LIGHT_COLOR_GREEN)
			continue
		if((t.x+1 == cen.x && t.y+1 == cen.y) || (t.x+2 == cen.x && t.y+2 == cen.y))
			spotlights += new /obj/item/flashlight/spotlight(t, 1.4 + get_dist(owner, t), 30 - (get_dist(owner, t) * 8), LIGHT_COLOR_ORANGE)
			continue
		if((t.x-1 == cen.x && t.y-1 == cen.y) || (t.x-2 == cen.x && t.y-2 == cen.y))
			spotlights += new /obj/item/flashlight/spotlight(t, 1.4 + get_dist(owner, t), 30 - (get_dist(owner, t) * 8), LIGHT_COLOR_CYAN)
			continue
		if((t.x-1 == cen.x && t.y+1 == cen.y) || (t.x-2 == cen.x && t.y+2 == cen.y))
			spotlights += new /obj/item/flashlight/spotlight(t, 1.4 + get_dist(owner, t), 30 - (get_dist(owner, t) * 8), LIGHT_COLOR_BLUEGREEN)
			continue
		if((t.x+1 == cen.x && t.y-1 == cen.y) || (t.x+2 == cen.x && t.y-2 == cen.y))
			spotlights += new /obj/item/flashlight/spotlight(t, 1.4 + get_dist(owner, t), 30 - (get_dist(owner, t) * 8), LIGHT_COLOR_BLUE)
			continue
		continue
	FOR_DVIEW_END

#define DISCO_INFENO_RANGE (rand(85, 115)*0.01)

/datum/action/cooldown/spell/summon_dancefloor/proc/rainbow_lights()
	for(var/g in spotlights)
		var/obj/item/flashlight/spotlight/glow = g
		if(QDELETED(glow))
			stack_trace("[glow?.gc_destroyed ? "Qdeleting glow" : "null entry"] found in [src].[gc_destroyed ? " Source qdeleting at the time." : ""]")
			return
		switch(glow.light_color)
			if(COLOR_SOFT_RED)
				if(glow.even_cycle)
					glow.set_light_on(FALSE)
					glow.set_light_color(LIGHT_COLOR_BLUE)
				else
					glow.set_light_range_power_color(glow.base_light_range * DISCO_INFENO_RANGE, glow.light_power * 1.48, LIGHT_COLOR_BLUE)
					glow.set_light_on(TRUE)
			if(LIGHT_COLOR_BLUE)
				if(glow.even_cycle)
					glow.set_light_range_power_color(glow.base_light_range * DISCO_INFENO_RANGE, glow.light_power * 2, LIGHT_COLOR_GREEN)
					glow.set_light_on(TRUE)
				else
					glow.set_light_on(FALSE)
					glow.set_light_color(LIGHT_COLOR_GREEN)
			if(LIGHT_COLOR_GREEN)
				if(glow.even_cycle)
					glow.set_light_on(FALSE)
					glow.set_light_color(LIGHT_COLOR_ORANGE)
				else
					glow.set_light_range_power_color(glow.base_light_range * DISCO_INFENO_RANGE, glow.light_power * 0.5, LIGHT_COLOR_ORANGE)
					glow.set_light_on(TRUE)
			if(LIGHT_COLOR_ORANGE)
				if(glow.even_cycle)
					glow.set_light_range_power_color(glow.base_light_range * DISCO_INFENO_RANGE, glow.light_power * 2.27, LIGHT_COLOR_PURPLE)
					glow.set_light_on(TRUE)
				else
					glow.set_light_on(FALSE)
					glow.set_light_color(LIGHT_COLOR_PURPLE)
			if(LIGHT_COLOR_PURPLE)
				if(glow.even_cycle)
					glow.set_light_on(FALSE)
					glow.set_light_color(LIGHT_COLOR_BLUEGREEN)
				else
					glow.set_light_range_power_color(glow.base_light_range * DISCO_INFENO_RANGE, glow.light_power * 0.44, LIGHT_COLOR_BLUEGREEN)
					glow.set_light_on(TRUE)
			if(LIGHT_COLOR_BLUEGREEN)
				if(glow.even_cycle)
					glow.set_light_range(glow.base_light_range * DISCO_INFENO_RANGE)
					glow.set_light_color(LIGHT_COLOR_DIM_YELLOW)
					glow.set_light_on(TRUE)
				else
					glow.set_light_on(FALSE)
					glow.set_light_color(LIGHT_COLOR_DIM_YELLOW)
			if(LIGHT_COLOR_DIM_YELLOW)
				if(glow.even_cycle)
					glow.set_light_on(FALSE)
					glow.set_light_color(LIGHT_COLOR_CYAN)
				else
					glow.set_light_range(glow.base_light_range * DISCO_INFENO_RANGE)
					glow.set_light_color(LIGHT_COLOR_CYAN)
					glow.set_light_on(TRUE)
			if(LIGHT_COLOR_CYAN)
				if(glow.even_cycle)
					glow.set_light_range_power_color(glow.base_light_range * DISCO_INFENO_RANGE, glow.light_power * 0.68, COLOR_SOFT_RED)
					glow.set_light_on(TRUE)
				else
					glow.set_light_on(FALSE)
					glow.set_light_color(COLOR_SOFT_RED)
				glow.even_cycle = !glow.even_cycle
	sleep(1 SECONDS)

#undef DISCO_INFENO_RANGE
