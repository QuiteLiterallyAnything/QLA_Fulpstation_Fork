/////////////////////////////////////
///        PUMPKIN METEORS        ///
/////////////////////////////////////

// Made using a lot of recycled code from 'cateor.dm'
/obj/effect/meteor/pumpkin
	name = "spooky gourd energy"
	desc = "It has an aura of mischief to it..."
	icon = 'fulp_modules/features/halloween/2025/pumpkin_meteors/pumpkinteor.dmi'
	icon_state = "pumpkinteor"
	pass_flags = PASSGLASS | PASSGRILLE | PASSBLOB | PASSCLOSEDTURF | PASSTABLE | PASSMACHINE | PASSSTRUCTURE | PASSDOORS | PASSVEHICLE | PASSFLAPS
	hits = 1
	meteorsound = null
	hitpwr = NONE
	light_system = OVERLAY_LIGHT
	light_color = "#FB8237"
	light_range = 2.5
	light_power = 0.625

	/// Used for adjusting pumpkinteor size
	var/matrix/size = matrix()
	///Used in one instance of size adjustment— not really that important.
	var/resize_count = 1.5

/obj/effect/meteor/pumpkin/Initialize(mapload, turf/target)
	. = ..()
	size.Scale(1.5,1.5)
	src.transform = size

/obj/effect/meteor/pumpkin/get_hit()
	return

/obj/effect/meteor/pumpkin/attack_hand(mob/living/thing_that_touched_the_cateor, list/modifiers)
	to_chat(thing_that_touched_the_cateor, span_large(span_hypnophrase("BOO!")))
	Bump(thing_that_touched_the_cateor)

/obj/effect/meteor/cateor/Bump(mob/living/M)
	return
