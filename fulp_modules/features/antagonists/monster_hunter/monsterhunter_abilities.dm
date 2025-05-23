/// Cooldown-bound action subtype for monster hunters.
/// Mainly just used for icons at the moment.
///
/// IMPORTANT: This subtype does not apply to ALL monster hunter abilities.
///            Those under the "spell" subtype have had their icon's adjusted manually.
/datum/action/cooldown/monster_hunter
	background_icon = 'fulp_modules/icons/antagonists/monster_hunter/actions_monster_hunter.dmi'
	background_icon_state = "background"

	overlay_icon = 'fulp_modules/icons/antagonists/monster_hunter/actions_monster_hunter.dmi'
	overlay_icon_state = "border"

/datum/action/cooldown/monster_hunter/paradox
	name = "Paradox Rabbit"
	desc = "The rabbit's movements will be translated onto you, ignoring any solid objects in your way."

	button_icon = 'fulp_modules/icons/antagonists/monster_hunter/rabbit.dmi'
	button_icon_state = "dead_rabbit_centered"

	overlay_icon_state = "diamonds"

	cooldown_time = 3 MINUTES
	///where we will be teleporting the rabbit too
	var/obj/effect/landmark/wonderchess_mark/chessmark
	///where the user will be while this whole ordeal is happening
	var/obj/effect/landmark/wonderland_mark/landmark
	///the rabbit in question if it exists
	var/mob/living/basic/rabbit/rabbit
	///where the user originally was
	var/turf/original_loc

/datum/action/cooldown/monster_hunter/paradox/New(Target)
	..()
	chessmark = GLOB.wonderland_marks["Wonderchess landmark"]
	landmark =  GLOB.wonderland_marks["Wonderland landmark"]



/datum/action/cooldown/monster_hunter/paradox/Activate()
	if(!is_station_level(owner.loc.z))
		to_chat(owner,span_warning("The pull of the ice moon isn't strong enough here.."))
		return
	StartCooldown(360 SECONDS, 360 SECONDS)
	if(!chessmark)
		return
	var/turf/theplace = get_turf(chessmark)
	var/turf/land_mark = get_turf(landmark)
	original_loc = get_turf(owner)
	var/mob/living/basic/rabbit/bunny = new(theplace)
	if(!bunny)
		return
	owner.forceMove(land_mark) ///the user remains safe in the wonderland
	var/mob/living/master = owner
	owner.mind.transfer_to(bunny)
	playsound(bunny, 'fulp_modules/features/antagonists/monster_hunter/sounds/paradoxskip.ogg',100)
	addtimer(CALLBACK(src,PROC_REF(return_to_station), master, bunny, theplace), 5 SECONDS)
	StartCooldown()

/datum/action/cooldown/monster_hunter/paradox/proc/return_to_station(mob/user, mob/bunny,turf/mark)
	var/new_x = bunny.x - mark.x
	var/new_y = bunny.y - mark.y
	var/turf/new_location = locate((original_loc.x + new_x) , (original_loc.y + new_y) , original_loc.z)
	user.forceMove(new_location)
	bunny.mind.transfer_to(user)
	playsound(user, 'fulp_modules/features/antagonists/monster_hunter/sounds/paradoxskip.ogg',100)
	rabbit = null
	original_loc = null
	qdel(bunny)


/datum/action/cooldown/monster_hunter/wonderland_drop
	name = "To Wonderland"
	button_icon = 'icons/turf/floors.dmi'
	button_icon_state = "junglegrass"
	cooldown_time = 5 MINUTES
	///where we will be teleporting the user too
	var/obj/effect/landmark/wonderland_mark/landmark
	///where the user originally was
	var/turf/original_loc

/datum/action/cooldown/monster_hunter/wonderland_drop/New(Target)
	..()
	landmark =  GLOB.wonderland_marks["Wonderland landmark"]



/datum/action/cooldown/monster_hunter/wonderland_drop/Activate()
	StartCooldown(360 SECONDS, 360 SECONDS)
	var/mob/living/sleeper = owner
	if(!landmark)
		return
	original_loc = get_turf(sleeper)
	var/turf/theplace = get_turf(landmark)
	sleeper.forceMove(theplace)
	sleeper.Sleeping(2 SECONDS)
	sleep(3 SECONDS)
	to_chat(sleeper, span_warning("You wake up in the Wonderland."))
	owner.playsound_local(sleeper, 'fulp_modules/features/antagonists/monster_hunter/sounds/wonderlandmusic.ogg',10)
	addtimer(CALLBACK(src, PROC_REF(return_to_station), sleeper), 1 MINUTES)
	StartCooldown()

/datum/action/cooldown/monster_hunter/wonderland_drop/proc/return_to_station(mob/living/sleeper)
	if(!original_loc)
		return
	sleeper.forceMove(original_loc)
	to_chat(sleeper, span_warning("You feel like you have woken up from a deep slumber, was it all a dream?"))
	original_loc = null

/datum/action/cooldown/spell/conjure_item/blood_silver
	name = "Create bloodsilver bullet"
	desc = "Withdraw your blood and mold it into a bloodsilver bullet"

	background_icon = 'fulp_modules/icons/antagonists/monster_hunter/actions_monster_hunter.dmi'
	background_icon_state = "background"

	button_icon = 'fulp_modules/icons/antagonists/monster_hunter/weapons.dmi'
	button_icon_state = "bloodsilver"

	overlay_icon = 'fulp_modules/icons/antagonists/monster_hunter/actions_monster_hunter.dmi'
	overlay_icon_state = "spades"


	cooldown_time = 2 MINUTES
	item_type = /obj/item/ammo_casing/silver
	spell_requirements = NONE
	delete_old = FALSE

/datum/action/cooldown/spell/blood_silver/conjure_item/cast(mob/living/carbon/cast_on)
	if(cast_on.blood_volume < BLOOD_VOLUME_NORMAL)
		to_chat(cast_on, span_warning ("Using this ability would put our health at risk!"))
		return
	. = ..()
	cast_on.blood_volume -= 20
