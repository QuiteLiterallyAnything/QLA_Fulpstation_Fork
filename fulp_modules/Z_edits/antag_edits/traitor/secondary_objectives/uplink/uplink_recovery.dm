/datum/crafting_recipe/syndicate_uplink_beacon
	name = "Syndicate Uplink Beacon"
	result = /obj/structure/syndicate_uplink_beacon
	tool_behaviors = list(TOOL_SCREWDRIVER)
	time = 6 SECONDS
	reqs = list(
		/obj/item/stack/sheet/iron = 5,
		/obj/item/stack/cable_coil = 5,
		/obj/item/beacon = 1,
		/obj/item/stack/ore/bluespace_crystal = 1,
	)
	category = CAT_STRUCTURE
	crafting_flags = CRAFT_CHECK_DENSITY | CRAFT_MUST_BE_LEARNED
