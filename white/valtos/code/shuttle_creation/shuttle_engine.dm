//-----------------------------------------------
//-------------Engine Thrusters------------------
//-----------------------------------------------

/obj/machinery/shuttle/engine
	name = "двигатель шаттла"
	desc = "Двигатель для шаттлов."
	density = TRUE
	obj_integrity = 250
	max_integrity = 250
	icon = 'icons/turf/shuttle.dmi'
	icon_state = "burst_plasma"
	idle_power_usage = 150
	circuit = /obj/item/circuitboard/machine/shuttle/engine
	var/thrust = 0
	var/fuel_use = 0
	var/bluespace_capable = TRUE
	var/cooldown = 0
	var/thruster_active = FALSE
	var/needs_heater = TRUE
	var/datum/weakref/attached_heater

/obj/machinery/shuttle/engine/plasma
	name = "плазменный двигатель"
	desc = "Двигатель, который сжигает плазму, хранящуюся в располагающемся рядом предзажигателе плазменного двигателя."
	icon_state = "burst_plasma"
	icon_state_off = "burst_plasma_off"

	idle_power_usage = 0
	circuit = /obj/item/circuitboard/machine/shuttle/engine/plasma
	thrust = 25
	fuel_use = 0.24
	bluespace_capable = FALSE
	cooldown = 45

/obj/machinery/shuttle/engine/void
	name = "пустотный двигатель"
	desc = "Двигатель, использующий технологию для пространственного прорыва для движения."
	icon_state = "burst_void"
	icon_state_off = "burst_void"
	icon_state_closed = "burst_void"
	icon_state_open = "burst_void_open"
	idle_power_usage = 0
	circuit = /obj/item/circuitboard/machine/shuttle/engine/void
	thrust = 400
	fuel_use = 0
	bluespace_capable = TRUE
	needs_heater = FALSE
	cooldown = 90

/obj/machinery/shuttle/engine/Initialize()
	. = ..()
	check_setup()

/obj/machinery/shuttle/engine/on_construction()
	. = ..()
	check_setup()

/obj/machinery/shuttle/engine/proc/check_setup()
	var/heater_turf
	switch(dir)
		if(NORTH)
			heater_turf = get_offset_target_turf(src, 0, 1)
		if(SOUTH)
			heater_turf = get_offset_target_turf(src, 0, -1)
		if(EAST)
			heater_turf = get_offset_target_turf(src, 1, 0)
		if(WEST)
			heater_turf = get_offset_target_turf(src, -1, 0)
	if(!heater_turf)
		attached_heater = null
		update_engine()
		return
	attached_heater = null
	var/obj/machinery/atmospherics/components/unary/shuttle/heater/as_heater = locate() in heater_turf
	if(!as_heater)
		return
	if(as_heater.dir != dir)
		return
	if(as_heater.panel_open)
		return
	if(!as_heater.anchored)
		return
	attached_heater = WEAKREF(as_heater)
	update_engine()
	return

/obj/machinery/shuttle/engine/proc/update_engine()
	if(!needs_heater)
		icon_state = icon_state_closed
		thruster_active = TRUE
		return
	if(!attached_heater)
		icon_state = icon_state_off
		thruster_active = FALSE
		return
	var/obj/machinery/atmospherics/components/unary/shuttle/heater/resolved_heater = attached_heater.resolve()
	if(panel_open)
		thruster_active = FALSE
	else if(resolved_heater?.hasFuel(1))
		icon_state = icon_state_closed
		thruster_active = TRUE
	else
		thruster_active = FALSE
		icon_state = icon_state_off
	return

/obj/machinery/shuttle/engine/void/update_engine()
	if(panel_open)
		thruster_active = FALSE
		return
	thruster_active = TRUE
	icon_state = icon_state_closed
	return

//Thanks to spaceheater.dm for inspiration :)
/obj/machinery/shuttle/engine/proc/fireEngine()
	var/turf/heatTurf = loc
	if(!heatTurf)
		return
	var/datum/gas_mixture/env = heatTurf.return_air()
	var/heat_cap = env.heat_capacity()
	var/req_power = abs(env.return_temperature() - ENGINE_HEAT_TARGET) * heat_cap
	req_power = min(req_power, ENGINE_HEATING_POWER)
	var/deltaTemperature = req_power / heat_cap
	if(deltaTemperature < 0)
		return
	env.set_temperature(env.return_temperature() + deltaTemperature)
	air_update_turf()

/obj/machinery/shuttle/engine/attackby(obj/item/I, mob/living/user, params)
	check_setup()
	if(default_deconstruction_screwdriver(user, icon_state_open, icon_state_closed, I))
		return
	if(default_pry_open(I))
		return
	if(panel_open)
		if(default_change_direction_wrench(user, I))
			return
	if(default_deconstruction_crowbar(I))
		return
	return ..()
