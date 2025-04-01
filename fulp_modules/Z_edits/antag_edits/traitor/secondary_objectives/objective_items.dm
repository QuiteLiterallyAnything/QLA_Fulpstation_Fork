GLOBAL_DATUM_INIT(steal_item_handler, /datum/objective_item_handler, new())

/// Holds references to information about all of the items you might need to steal for objectives
/datum/objective_item_handler
	var/list/list/objectives_by_path
	var/generated_items = FALSE

/datum/objective_item_handler/New()
	. = ..()
	objectives_by_path = list()
	for(var/datum/objective_item/item as anything in subtypesof(/datum/objective_item))
		objectives_by_path[initial(item.targetitem)] = list()
	RegisterSignal(SSatoms, COMSIG_SUBSYSTEM_POST_INITIALIZE, PROC_REF(save_items))
	RegisterSignal(SSdcs, COMSIG_GLOB_NEW_ITEM, PROC_REF(new_item_created))

/datum/objective_item_handler/proc/new_item_created(datum/source, obj/item/item)
	SIGNAL_HANDLER
	if(HAS_TRAIT(item, TRAIT_ITEM_OBJECTIVE_BLOCKED))
		return
	if(!generated_items)
		item.add_stealing_item_objective()
		return
	var/typepath = item.add_stealing_item_objective()
	if(typepath != null)
		register_item(item, typepath)

/// Registers all items that are potentially stealable and removes ones that aren't.
/// We still need to do things this way because on mapload, items may not be on the station until everything has finished loading.
/datum/objective_item_handler/proc/save_items()
	SIGNAL_HANDLER
	for(var/obj/item/typepath as anything in objectives_by_path)
		var/list/obj_by_path_cache = objectives_by_path[typepath].Copy()
		for(var/obj/item/object as anything in obj_by_path_cache)
			register_item(object, typepath)
	generated_items = TRUE

/datum/objective_item_handler/proc/register_item(atom/object, typepath)
	var/turf/place = get_turf(object)
	if(!place || !is_station_level(place.z))
		objectives_by_path[typepath] -= object
		return
	RegisterSignal(object, COMSIG_QDELETING, PROC_REF(remove_item))

/datum/objective_item_handler/proc/remove_item(atom/source)
	SIGNAL_HANDLER
	for(var/typepath in objectives_by_path)
		objectives_by_path[typepath] -= source
