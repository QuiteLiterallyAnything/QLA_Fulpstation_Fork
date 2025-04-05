/// Helper component that registers signals on an object
/// This is not necessary to use and gives little control over the conditions
/datum/component/traitor_objective_register
	dupe_mode = COMPONENT_DUPE_ALLOWED

	/// The target to apply the succeed/fail signals onto
	var/datum/target
	/// Signals to listen out for to automatically succeed the objective
	var/succeed_signals
	/// Signals to listen out for to automatically fail the objective.
	var/fail_signals
	/// Whether failing has a penalty
	var/penalty = 0

/datum/component/traitor_objective_register/Initialize(datum/target, succeed_signals, fail_signals, penalty)
	. = ..()
	if(!istype(parent, /datum/traitor_objective))
		return COMPONENT_INCOMPATIBLE
	src.target = target
	src.succeed_signals = succeed_signals
	src.fail_signals = fail_signals
	src.penalty = penalty

/datum/component/traitor_objective_register/RegisterWithParent()
	if(succeed_signals)
		RegisterSignals(target, succeed_signals, PROC_REF(on_success))
	if(fail_signals)
		RegisterSignals(target, fail_signals, PROC_REF(on_fail))
	RegisterSignals(parent, list(COMSIG_TRAITOR_OBJECTIVE_COMPLETED, COMSIG_TRAITOR_OBJECTIVE_FAILED), PROC_REF(delete_self))

/datum/component/traitor_objective_register/UnregisterFromParent()
	if(target)
		if(succeed_signals)
			UnregisterSignal(target, succeed_signals)
		if(fail_signals)
			UnregisterSignal(target, fail_signals)
	UnregisterSignal(parent, list(
		COMSIG_TRAITOR_OBJECTIVE_COMPLETED,
		COMSIG_TRAITOR_OBJECTIVE_FAILED
	))

/datum/component/traitor_objective_register/proc/on_fail(datum/traitor_objective/source)
	SIGNAL_HANDLER
	var/datum/traitor_objective/objective = parent
	objective.fail_objective(penalty)

/datum/component/traitor_objective_register/proc/on_success()
	SIGNAL_HANDLER
	var/datum/traitor_objective/objective = parent
	objective.succeed_objective()

/datum/component/traitor_objective_register/proc/delete_self()
	SIGNAL_HANDLER
	qdel(src)


/////////////////////////////////////////////////////////////////////////
//                traitor_objective_limit_per_time.dm                  //
/////////////////////////////////////////////////////////////////////////


/// Helper component to track events on
/datum/component/traitor_objective_limit_per_time
	dupe_mode = COMPONENT_DUPE_HIGHLANDER

	/// The maximum time that an objective will be considered for. Set to -1 to accept any time.
	var/time_period = 0
	/// The maximum amount of objectives that can be active or recently active at one time
	var/maximum_objectives = 0
	/// The typepath which we check for
	var/typepath

/datum/component/traitor_objective_limit_per_time/Initialize(typepath, time_period, maximum_objectives)
	. = ..()
	if(!istype(parent, /datum/traitor_objective))
		return COMPONENT_INCOMPATIBLE
	src.time_period = time_period
	src.maximum_objectives = maximum_objectives
	src.typepath = typepath
	if(!typepath)
		src.typepath = parent.type

/datum/component/traitor_objective_limit_per_time/RegisterWithParent()
	RegisterSignal(parent, COMSIG_TRAITOR_OBJECTIVE_PRE_GENERATE, PROC_REF(handle_generate))

/datum/component/traitor_objective_limit_per_time/UnregisterFromParent()
	UnregisterSignal(parent, COMSIG_TRAITOR_OBJECTIVE_PRE_GENERATE)


/datum/component/traitor_objective_limit_per_time/proc/handle_generate(datum/traitor_objective/source, datum/mind/owner, list/potential_duplicates)
	SIGNAL_HANDLER
	var/datum/uplink_handler/handler = source.handler
	if(!handler)
		return
	var/count = 0
	for(var/datum/traitor_objective/objective as anything in handler.potential_duplicate_objectives[typepath])
		if(time_period != -1 && objective.objective_state != OBJECTIVE_STATE_INACTIVE && (world.time - objective.time_of_completion) > time_period)
			continue
		count++

	if(count >= maximum_objectives)
		return COMPONENT_TRAITOR_OBJECTIVE_ABORT_GENERATION


/////////////////////////////////////////////////////////////////////////
//                 traitor_objective_mind_tracker.dm                   //
/////////////////////////////////////////////////////////////////////////


/// Helper component to track events on
/datum/component/traitor_objective_mind_tracker
	dupe_mode = COMPONENT_DUPE_ALLOWED

	/// The target to track
	var/datum/mind/target
	/// Signals to listen out for mapped to procs to call
	var/list/signals
	/// Current registered target
	var/mob/current_registered_target

/datum/component/traitor_objective_mind_tracker/Initialize(datum/target, signals)
	. = ..()
	if(!istype(parent, /datum/traitor_objective))
		return COMPONENT_INCOMPATIBLE
	src.target = target
	src.signals = signals

/datum/component/traitor_objective_mind_tracker/RegisterWithParent()
	RegisterSignal(target, COMSIG_MIND_TRANSFERRED, PROC_REF(handle_mind_transferred))
	RegisterSignal(target, COMSIG_QDELETING, PROC_REF(delete_self))
	RegisterSignals(parent, list(COMSIG_TRAITOR_OBJECTIVE_COMPLETED, COMSIG_TRAITOR_OBJECTIVE_FAILED), PROC_REF(delete_self))
	handle_mind_transferred(target)

/datum/component/traitor_objective_mind_tracker/UnregisterFromParent()
	UnregisterSignal(target, COMSIG_MIND_TRANSFERRED)
	if(target.current)
		parent.UnregisterSignal(target.current, signals)

/datum/component/traitor_objective_mind_tracker/proc/handle_mind_transferred(datum/source, mob/previous_body)
	SIGNAL_HANDLER
	if(current_registered_target)
		parent.UnregisterSignal(current_registered_target, signals)

	for(var/signal in signals)
		parent.RegisterSignal(target.current, signal, signals[signal])

/datum/component/traitor_objective_mind_tracker/proc/delete_self()
	SIGNAL_HANDLER
	qdel(src)
