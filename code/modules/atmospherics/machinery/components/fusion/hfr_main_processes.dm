/**
 * Main Fusion processes
 * process() Organizes all other calls, and is the best starting point for top-level logic.
 * fusion_process() handles all the main fusion reaction logic and consequences (lightning, radiation, particles) from an active fusion reaction.
 */

/obj/machinery/atmospherics/components/unary/hypertorus/core/process(delta_time)
	/*
	 *Pre-checks
	 */
	//first check if the machine is active
	if(!active)
		return

	//then check if the other machines are still there
	if(!check_part_connectivity())
		deactivate()
		return

	// Run the reaction if it is either live or being started
	if (start_power || power_level)
		play_ambience()
		fusion_process(delta_time)
		// Note that we process damage/healing even if the fusion process aborts.
		// Running out of fuel won't save you if your moderator and coolant are exploding on their own.
		check_spill()
		process_damageheal(delta_time)
		check_alert()
	if (start_power)
		remove_waste(delta_time)
	update_pipenets()

	check_deconstructable()

/**
 * Called by process()
 * Contains the main fusion calculations and checks, for more informations check the comments along the code.
 */
/obj/machinery/atmospherics/components/unary/hypertorus/core/proc/fusion_process(delta_time)
//fusion: a terrible idea that was fun but broken. Now reworked to be less broken and more interesting. Again (and again, and again). Again! Again but with machine!
//Fusion Rework Counter: Please increment this if you make a major overhaul to this system again.
//7 reworks

	if (check_power_use())
		if (start_cooling)
			inject_from_side_components(delta_time)
			process_internal_cooling(delta_time)
	else
		// No power forces bad settings
		magnetic_constrictor = 100
		heating_conductor = 500
		current_damper = 0
		fuel_injection_rate = 20
		moderator_injection_rate = 50
		waste_remove = FALSE
		iron_content += 0.02 * power_level * delta_time

	update_temperature_status(delta_time)

	//Store the temperature of the gases after one cicle of the fusion reaction
	var/archived_heat = internal_fusion.return_temperature()
	//Store the volume of the fusion reaction multiplied by the force of the magnets that controls how big it will be
	var/volume = internal_fusion.return_volume() * (magnetic_constrictor * 0.01)

	var/energy_concentration_multiplier = 1
	var/positive_temperature_multiplier = 1
	var/negative_temperature_multiplier = 1

	//We scale it down by volume/2 because for fusion conditions, moles roughly = 2*volume, but we want it to be based off something constant between reactions.
	var/scale_factor = volume * 0.5

	/// Store the fuel gases and the byproduct gas quantities
	var/list/fuel_list = list()
	/// Scaled down moles of gases, no less than 0
	var/list/scaled_fuel_list = list()

	if (selected_fuel)
		energy_concentration_multiplier = selected_fuel.energy_concentration_multiplier
		positive_temperature_multiplier = selected_fuel.positive_temperature_multiplier
		negative_temperature_multiplier = selected_fuel.negative_temperature_multiplier

		for(var/gas_id in selected_fuel.requirements | selected_fuel.primary_products)
			var/amount = internal_fusion.get_moles(gas_id)
			fuel_list[gas_id] = amount
			scaled_fuel_list[gas_id] = max((amount - FUSION_MOLE_THRESHOLD) / scale_factor, 0)

	/// Store the moderators gases quantities
	var/list/moderator_list = list()
	/// Scaled down moles of gases, no less than 0
	var/list/scaled_moderator_list = list()
	for(var/gas_id in moderator_internal.get_gases())
		var/amount = moderator_internal.get_moles(gas_id)
		moderator_list[gas_id] = amount
		scaled_moderator_list[gas_id] = max((amount - FUSION_MOLE_THRESHOLD) / scale_factor, 0)

	/*
	 *FUSION MAIN PROCESS
	 */
	//This section is used for the instability calculation for the fusion reaction
	//The size of the phase space hypertorus
	var/toroidal_size = (2 * PI) + TORADIANS(arctan((volume - TOROID_VOLUME_BREAKEVEN) / TOROID_VOLUME_BREAKEVEN))
	//Calculation of the gas power, only for theoretical instability calculations
	var/gas_power = 0
	for (var/gas_id in internal_fusion.get_gases())
		gas_power += (GLOB.meta_gas_info[gas_id][META_GAS_FUSION_POWER] * internal_fusion.get_moles(gas_id))
	for (var/gas_id in moderator_internal.get_gases())
		gas_power += (GLOB.meta_gas_info[gas_id][META_GAS_FUSION_POWER] * moderator_internal.get_moles(gas_id) * 0.75)

	instability = MODULUS((gas_power * INSTABILITY_GAS_POWER_FACTOR)**2, toroidal_size) + (current_damper * 0.01) - iron_content * 0.05
	//Effective reaction instability (determines if the energy is used/released)
	var/internal_instability = 0
	if(instability * 0.5 < FUSION_INSTABILITY_ENDOTHERMALITY)
		internal_instability = 1
	else
		internal_instability = -1

	/*
	 *Modifiers
	 */
	///Those are the scaled gases that gets consumed and adjust energy
	// Gases that increase the amount of energy
	var/energy_modifiers = scaled_moderator_list[/datum/gas/nitrogen] * 0.35 + \
								scaled_moderator_list[/datum/gas/carbon_dioxide] * 0.55 + \
								scaled_moderator_list[/datum/gas/nitrous_oxide] * 0.95 + \
								scaled_moderator_list[/datum/gas/zauker] * 1.55 + \
								scaled_moderator_list[/datum/gas/antinoblium] * 20
	// Gases that decrease the amount of energy
	energy_modifiers -= scaled_moderator_list[/datum/gas/hypernoblium] * 10 + \
								scaled_moderator_list[/datum/gas/water_vapor] * 0.75 + \
								scaled_moderator_list[/datum/gas/nitryl] * 0.15 + \
								scaled_moderator_list[/datum/gas/healium] * 0.45 + \
								scaled_moderator_list[/datum/gas/freon] * 1.15
	///Between 0.25 and 100, this value is used to modify the behaviour of the internal energy and the core temperature based on the gases present in the mix
	var/power_modifier = scaled_moderator_list[/datum/gas/oxygen] * 0.55 + \
								scaled_moderator_list[/datum/gas/carbon_dioxide] * 0.95 + \
								scaled_moderator_list[/datum/gas/nitryl] * 1.45 + \
								scaled_moderator_list[/datum/gas/zauker] * 5.55 + \
								scaled_moderator_list[/datum/gas/plasma] * 0.05 - \
								scaled_moderator_list[/datum/gas/nitrous_oxide] * 0.05 - \
								scaled_moderator_list[/datum/gas/freon] * 0.75
	///Minimum 0.25, this value is used to modify the behaviour of the energy emission based on the gases present in the mix
	var/heat_modifier = scaled_moderator_list[/datum/gas/plasma] * 1.25 - \
								scaled_moderator_list[/datum/gas/nitrogen] * 0.75 - \
								scaled_moderator_list[/datum/gas/nitrous_oxide] * 1.45 - \
								scaled_moderator_list[/datum/gas/freon] * 0.95
	///Between 0.005 and 1000, this value modify the radiation emission of the reaction, higher values increase the emission
	var/radiation_modifier = scaled_moderator_list[/datum/gas/freon] * 1.15 - \
									scaled_moderator_list[/datum/gas/nitrogen] * 0.45 - \
									scaled_moderator_list[/datum/gas/plasma] * 0.95 + \
									scaled_moderator_list[/datum/gas/bz] * 1.9 + \
									scaled_moderator_list[/datum/gas/proto_nitrate] * 0.1 + \
									scaled_moderator_list[/datum/gas/antinoblium] * 10

	if (selected_fuel)
		// These should probably be static coefficients read from a table rather than things that depend on the current recipe
		// the same is true for the effects above
		energy_modifiers += scaled_fuel_list[selected_fuel.requirements[1]] + \
									scaled_fuel_list[selected_fuel.requirements[2]]
		energy_modifiers -= scaled_fuel_list[selected_fuel.primary_products[1]]

		power_modifier += scaled_fuel_list[selected_fuel.requirements[2]] * 1.05 - \
									scaled_fuel_list[selected_fuel.primary_products[1]] * 0.55

		heat_modifier += scaled_fuel_list[selected_fuel.requirements[1]] * 1.15 + \
									scaled_fuel_list[selected_fuel.primary_products[1]] * 1.05

		radiation_modifier += scaled_fuel_list[selected_fuel.primary_products[1]]

	power_modifier = clamp(power_modifier, 0.25, 100)
	heat_modifier = clamp(heat_modifier, 0.25, 100)
	radiation_modifier = clamp(radiation_modifier, 0.005, 1000)

	/*
	 *Main calculations (energy, internal power, core temperature, delta temperature,
	 *conduction, radiation, efficiency, power output, heat limiter modifier and heat output)
	 */
	internal_power = 0
	efficiency = VOID_CONDUCTION * 1

	if (selected_fuel)
		// Power of the gas mixture
		internal_power = (scaled_fuel_list[selected_fuel.requirements[1]] * power_modifier / 100) * (scaled_fuel_list[selected_fuel.requirements[2]] * power_modifier / 100) * (PI * (2 * (scaled_fuel_list[selected_fuel.requirements[1]] * CALCULATED_H2RADIUS) * (scaled_fuel_list[selected_fuel.requirements[2]] * CALCULATED_TRITRADIUS))**2) * energy

		// Efficiency of the reaction, it increases with the amount of byproduct
		efficiency = VOID_CONDUCTION * clamp(scaled_fuel_list[selected_fuel.primary_products[1]], 1, 100)

	//Can go either positive or negative depending on the instability and the negative energy modifiers
	//E=mc^2 with some changes for gameplay purposes
	energy = (energy_modifiers * LIGHT_SPEED ** 2) * max(internal_fusion.return_temperature() * heat_modifier / 100, 1)
	energy = energy / energy_concentration_multiplier
	energy = clamp(energy, 0, 1e35) //ugly way to prevent NaN error
	//Temperature inside the center of the gas mixture
	core_temperature = internal_power * power_modifier / 1000
	core_temperature = max(TCMB, core_temperature)
	//Difference between the gases temperature and the internal temperature of the reaction
	delta_temperature = archived_heat - core_temperature
	//Energy from the reaction lost from the molecule colliding between themselves.
	conduction = - delta_temperature * (magnetic_constrictor * 0.001)
	//The remaining wavelength that actually can do damage to mobs.
	radiation = max(-(PLANCK_LIGHT_CONSTANT / 5e-18) * radiation_modifier * delta_temperature, 0)
	power_output = efficiency * (internal_power - conduction - radiation)
	//Hotter air is easier to heat up and cool down
	heat_limiter_modifier = 10 * (10 ** power_level) * (heating_conductor / 100)
	//The amount of heat that is finally emitted, based on the power output. Min and max are variables that depends of the modifier
	heat_output_min = - heat_limiter_modifier * 0.01 * negative_temperature_multiplier
	heat_output_max = heat_limiter_modifier * positive_temperature_multiplier
	heat_output = clamp(internal_instability * power_output * heat_modifier / 100, heat_output_min, heat_output_max)

	// Is the fusion process actually going to run?
	// Note we have to always perform the above calculations to keep the UI updated, so we can't use this to early return.
	if (!check_fuel())
		return

	// Phew. Lets calculate what this means in practice.
	var/fuel_consumption_rate = clamp(fuel_injection_rate * 0.01 * 5 * power_level, 0.05, 30)
	var/consumption_amount = fuel_consumption_rate * delta_time
	var/production_amount
	switch(power_level)
		if(3,4)
			production_amount = clamp(heat_output * 5e-4, 0, fuel_consumption_rate) * delta_time
		else
			production_amount = clamp(heat_output / 10 ** (power_level+1), 0, fuel_consumption_rate) * delta_time

	// antinob production is special, and uses its own calculations from how stale the fusion mix is (via byproduct ratio and fresh fuel rate)
	var/dirty_production_rate = scaled_fuel_list[scaled_fuel_list[3]] / fuel_injection_rate

	// Run the effects of our selected fuel recipe

	var/datum/gas_mixture/internal_output = new
	moderator_fuel_process(delta_time, production_amount, consumption_amount, internal_output, moderator_list, selected_fuel, fuel_list)

	// Run the common effects, committing changes where applicable

	// This is repetition, but is here as a placeholder for what will need to be done to allow concurrently running multiple recipes
	var/common_production_amount = production_amount * selected_fuel.gas_production_multiplier
	moderator_common_process(delta_time, common_production_amount, internal_output, moderator_list, dirty_production_rate, heat_output, radiation_modifier)

/**
 * Perform recipe specific actions. Fuel consumption and recipe based gas production happens here.
 */
/obj/machinery/atmospherics/components/unary/hypertorus/core/proc/moderator_fuel_process(delta_time, production_amount, consumption_amount, datum/gas_mixture/internal_output, moderator_list, datum/hfr_fuel/fuel, fuel_list)
	// Adjust fusion consumption/production based on this recipe's characteristics
	var/fuel_consumption = consumption_amount * 0.85 * selected_fuel.fuel_consumption_multiplier
	var/scaled_production = production_amount * selected_fuel.gas_production_multiplier

	for(var/gas_id in fuel.requirements)
		internal_fusion.adjust_moles(gas_id, -min(fuel_list[gas_id], fuel_consumption))
	for(var/gas_id in fuel.primary_products)
		internal_fusion.adjust_moles(gas_id, fuel_consumption * 0.5)

	// Each recipe provides a tier list of six output gases.
	// Which gases are produced depend on what the fusion level is.
	var/list/tier = fuel.secondary_products
	switch(power_level)
		if(1)
			moderator_internal.adjust_moles(tier[1], scaled_production * 0.95)
			moderator_internal.adjust_moles(tier[2], scaled_production * 0.75)
		if(2)
			moderator_internal.adjust_moles(tier[1], scaled_production * 1.65)
			moderator_internal.adjust_moles(tier[2], scaled_production)
			if(moderator_list[/datum/gas/plasma] > 50)
				moderator_internal.adjust_moles(tier[3], scaled_production * 1.15)
		if(3)
			moderator_internal.adjust_moles(tier[2], scaled_production * 0.5)
			moderator_internal.adjust_moles(tier[3], scaled_production * 0.45)
		if(4)
			moderator_internal.adjust_moles(tier[3], scaled_production * 1.65)
			moderator_internal.adjust_moles(tier[4], scaled_production * 1.25)
		if(5)
			moderator_internal.adjust_moles(tier[4], scaled_production * 0.65)
			moderator_internal.adjust_moles(tier[5], scaled_production)
			moderator_internal.adjust_moles(tier[6], scaled_production * 0.75)
		if(6)
			moderator_internal.adjust_moles(tier[5], scaled_production * 0.35)
			moderator_internal.adjust_moles(tier[6], scaled_production)

/**
 * Perform common fusion actions:
 *
 * - Gases that get produced irrespective of recipe
 * - Temperature modifiers, radiation modifiers, and the application of each
 * - Committing staged output, performing filtering, and making !FUN! emissions
 */
/obj/machinery/atmospherics/components/unary/hypertorus/core/proc/moderator_common_process(delta_time, scaled_production, datum/gas_mixture/internal_output, moderator_list, dirty_production_rate, heat_output, radiation_modifier)
	switch(power_level)
		if(1)
			if(moderator_list[/datum/gas/plasma] > 100)
				moderator_internal.adjust_moles(/datum/gas/nitrous_oxide, scaled_production * 0.5)
				moderator_internal.adjust_moles(/datum/gas/plasma, -min(moderator_internal.get_moles(/datum/gas/plasma), scaled_production * 0.85))
			if(moderator_list[/datum/gas/bz] > 150)
				internal_output.adjust_moles(/datum/gas/halon, scaled_production * 0.55)
				moderator_internal.adjust_moles(/datum/gas/bz, -min(moderator_internal.get_moles(/datum/gas/bz), scaled_production * 0.95))
		if(2)
			if(moderator_list[/datum/gas/plasma] > 50)
				internal_output.adjust_moles(/datum/gas/bz, scaled_production * 1.8)
				moderator_internal.adjust_moles(/datum/gas/plasma, -min(moderator_internal.get_moles(/datum/gas/plasma), scaled_production * 1.75))
			if(moderator_list[/datum/gas/proto_nitrate] > 20)
				radiation *= 1.55
				heat_output *= 1.025
				internal_output.adjust_moles(/datum/gas/nitryl, scaled_production * 1.05)
				moderator_internal.adjust_moles(/datum/gas/proto_nitrate, -min(moderator_internal.get_moles(/datum/gas/proto_nitrate), scaled_production * 1.35))
		if(3, 4)
			if(moderator_list[/datum/gas/plasma] > 10)
				internal_output.adjust_moles(/datum/gas/freon, scaled_production * 0.15)
				internal_output.adjust_moles(/datum/gas/nitryl, scaled_production * 1.05)
				moderator_internal.adjust_moles(/datum/gas/plasma, -min(moderator_internal.get_moles(/datum/gas/plasma), scaled_production * 0.45))
			if(moderator_list[/datum/gas/freon] > 50)
				heat_output *= 0.9
				radiation *= 0.8
			if(moderator_list[/datum/gas/proto_nitrate]> 15)
				internal_output.adjust_moles(/datum/gas/nitryl, scaled_production * 1.25)
				internal_output.adjust_moles(/datum/gas/halon, scaled_production * 1.15)
				moderator_internal.adjust_moles(/datum/gas/proto_nitrate, -min(moderator_internal.get_moles(/datum/gas/proto_nitrate), scaled_production * 1.55))
				radiation *= 1.95
				heat_output *= 1.25
			if(moderator_list[/datum/gas/bz] > 100)
				internal_output.adjust_moles(/datum/gas/proto_nitrate, scaled_production * 1.5)
				internal_output.adjust_moles(/datum/gas/healium, scaled_production * 1.5)
				induce_hallucination(50 * power_level, delta_time)
		if(5)
			if(moderator_list[/datum/gas/plasma] > 15)
				internal_output.adjust_moles(/datum/gas/freon, scaled_production *0.25)
				moderator_internal.adjust_moles(/datum/gas/plasma, -min(moderator_internal.get_moles(/datum/gas/plasma), scaled_production * 1.45))
			if(moderator_list[/datum/gas/freon] > 500)
				heat_output *= 0.5
				radiation *= 0.2
			if(moderator_list[/datum/gas/proto_nitrate] > 50)
				internal_output.adjust_moles(/datum/gas/nitryl, scaled_production * 1.95)
				internal_output.adjust_moles(/datum/gas/pluoxium, scaled_production)
				moderator_internal.adjust_moles(/datum/gas/proto_nitrate, -min(moderator_internal.get_moles(/datum/gas/proto_nitrate), scaled_production * 1.35))
				radiation *= 1.95
				heat_output *= 1.25
			if(moderator_list[/datum/gas/bz] > 100)
				internal_output.adjust_moles(/datum/gas/healium, scaled_production)
				induce_hallucination(500, delta_time)
				moderator_internal.adjust_moles(/datum/gas/freon, scaled_production * 1.15)
			if(moderator_list[/datum/gas/healium] > 100)
				if(critical_threshold_proximity > 400)
					critical_threshold_proximity = max(critical_threshold_proximity - (moderator_list[/datum/gas/healium] / 100 * delta_time ), 0)
					moderator_internal.adjust_moles(/datum/gas/healium, -min(moderator_internal.get_moles(/datum/gas/healium), scaled_production * 20))
			if(moderator_internal.return_temperature() < 1e7 || (moderator_list[/datum/gas/plasma] > 100 && moderator_list[/datum/gas/bz] > 50))
				internal_output.adjust_moles(/datum/gas/antinoblium, dirty_production_rate * 0.9 / 0.065 * delta_time)
		if(6)
			if(moderator_list[/datum/gas/plasma] > 30)
				moderator_internal.adjust_moles(/datum/gas/bz, scaled_production * 1.15)
				moderator_internal.adjust_moles(/datum/gas/plasma, -min(moderator_internal.get_moles(/datum/gas/plasma), scaled_production * 1.45))
			if(moderator_list[/datum/gas/proto_nitrate])
				internal_output.adjust_moles(/datum/gas/zauker, scaled_production * 5.35)
				internal_output.adjust_moles(/datum/gas/nitryl, scaled_production * 2.15)
				moderator_internal.adjust_moles(/datum/gas/proto_nitrate, -min(moderator_internal.get_moles(/datum/gas/proto_nitrate), scaled_production * 3.35))
				radiation *= 2
				heat_output *= 2.25
			if(moderator_list[/datum/gas/bz])
				induce_hallucination(900, delta_time, force=TRUE)
				moderator_internal.adjust_moles(/datum/gas/antinoblium, clamp(dirty_production_rate / 0.045, 0, 10) * delta_time)
			if(moderator_list[/datum/gas/healium] > 100)
				if(critical_threshold_proximity > 400)
					critical_threshold_proximity = max(critical_threshold_proximity - (moderator_list[/datum/gas/healium] / 100 * delta_time ), 0)
					moderator_internal.adjust_moles(/datum/gas/healium, -min(moderator_internal.get_moles(/datum/gas/healium), scaled_production * 20))
			internal_fusion.adjust_moles(/datum/gas/antinoblium, dirty_production_rate * 0.01 / 0.095 * delta_time)

	//Modifies the internal_fusion temperature with the amount of heat output
	var/temperature_modifier = selected_fuel.temperature_change_multiplier
	if(internal_fusion.return_temperature() <= FUSION_MAXIMUM_TEMPERATURE * temperature_modifier)
		internal_fusion.set_temperature(clamp(internal_fusion.return_temperature() + heat_output,TCMB,FUSION_MAXIMUM_TEMPERATURE * temperature_modifier))
	else
		internal_fusion.set_temperature(internal_fusion.return_temperature() - (heat_limiter_modifier * 0.01 * delta_time))

	//heat up and output what's in the internal_output into the linked_output port
	if(internal_output.total_moles() > 0)
		if(moderator_internal.total_moles() > 0)
			internal_output.set_temperature(moderator_internal.return_temperature() * HIGH_EFFICIENCY_CONDUCTIVITY)
		else
			internal_output.set_temperature(internal_fusion.return_temperature() * METALLIC_VOID_CONDUCTIVITY)
		linked_output.airs[1].merge(internal_output)

	evaporate_moderator(delta_time)

	check_nuclear_particles(moderator_list)

	check_lightning_arcs(moderator_list)

	// Oxygen burns away iron content rapidly
	if(moderator_list[/datum/gas/oxygen] > 150)
		if(iron_content > 0)
			var/max_iron_removable = IRON_OXYGEN_HEAL_PER_SECOND
			var/iron_removed = min(max_iron_removable * delta_time, iron_content)
			iron_content -= iron_removed
			moderator_internal.adjust_moles(/datum/gas/oxygen, -iron_removed * OXYGEN_MOLES_CONSUMED_PER_IRON_HEAL)

	check_gravity_pulse(delta_time)

	emit_rads()

/obj/machinery/atmospherics/components/unary/hypertorus/core/proc/evaporate_moderator(delta_time)
	// Don't evaporate if the reaction is dead
	if (!power_level)
		return
	// All gases in the moderator slowly burn away over time, whether used for production or not
	if(moderator_internal.total_moles() > 0)
		moderator_internal.remove(moderator_internal.total_moles() * (1 - (1 - 0.0005 * power_level) ** delta_time))

/obj/machinery/atmospherics/components/unary/hypertorus/core/proc/process_damageheal(delta_time)
	// Archive current health for damage cap purposes
	critical_threshold_proximity_archived = critical_threshold_proximity

	// If we're operating at an extreme power level, take increasing damage for the amount of fusion mass over a low threshold
	if(power_level >= HYPERTORUS_OVERFULL_MIN_POWER_LEVEL)
		var/overfull_damage_taken = HYPERTORUS_OVERFULL_MOLAR_SLOPE * internal_fusion.total_moles() + HYPERTORUS_OVERFULL_TEMPERATURE_SLOPE * coolant_temperature + HYPERTORUS_OVERFULL_CONSTANT
		critical_threshold_proximity = max(critical_threshold_proximity + max(overfull_damage_taken * delta_time, 0), 0)

	// If we're running on a thin fusion mix, heal up
	if(internal_fusion.total_moles() < HYPERTORUS_SUBCRITICAL_MOLES && power_level <= 5)
		var/subcritical_heal_restore = (internal_fusion.total_moles() - HYPERTORUS_SUBCRITICAL_MOLES) / HYPERTORUS_SUBCRITICAL_SCALE
		critical_threshold_proximity = max(critical_threshold_proximity + min(subcritical_heal_restore * delta_time, 0), 0)

	// If coolant is sufficiently cold, heal up
	if(internal_fusion.total_moles() > 0 && (airs[1].total_moles() && coolant_temperature < HYPERTORUS_COLD_COOLANT_THRESHOLD) && power_level <= 4)
		var/cold_coolant_heal_restore = log(10, max(coolant_temperature, 1) * HYPERTORUS_COLD_COOLANT_SCALE) - (HYPERTORUS_COLD_COOLANT_MAX_RESTORE * 2)
		critical_threshold_proximity = max(critical_threshold_proximity + min(cold_coolant_heal_restore * delta_time, 0), 0)

	critical_threshold_proximity += max(iron_content - HYPERTORUS_MAX_SAFE_IRON, 0) * delta_time

	// Apply damage cap
	critical_threshold_proximity = min(critical_threshold_proximity_archived + (delta_time * DAMAGE_CAP_MULTIPLIER * melting_point), critical_threshold_proximity)

	// If we have a preposterous amount of mass in the fusion mix, things get bad extremely fast
	if(internal_fusion.total_moles() >= HYPERTORUS_HYPERCRITICAL_MOLES)
		var/hypercritical_damage_taken = max((internal_fusion.total_moles() - HYPERTORUS_HYPERCRITICAL_MOLES) * HYPERTORUS_HYPERCRITICAL_SCALE, 0)
		critical_threshold_proximity = max(critical_threshold_proximity + min(hypercritical_damage_taken, HYPERTORUS_HYPERCRITICAL_MAX_DAMAGE), 0) * delta_time

	// High power fusion might create other matter other than helium, iron is dangerous inside the machine, damage can be seen
	if(power_level > 4 && prob(IRON_CHANCE_PER_FUSION_LEVEL * power_level))//at power level 6 is 100%
		iron_content += IRON_ACCUMULATED_PER_SECOND * delta_time
	if(iron_content > 0 && power_level <= 4 && prob(25 / (power_level + 1)))
		iron_content = max(iron_content - 0.01 * delta_time, 0)
	iron_content = clamp(iron_content, 0, 1)

/obj/machinery/atmospherics/components/unary/hypertorus/core/proc/check_nuclear_particles(moderator_list)
	// New nuclear particle emission sytem.
	if(power_level < 4)
		return
	if(moderator_list[/datum/gas/bz] < (150 / power_level))
		return
	var/obj/machinery/hypertorus/corner/picked_corner = pick(corners)
	picked_corner.loc.fire_nuclear_particle(turn(picked_corner.dir, 180))

/obj/machinery/atmospherics/components/unary/hypertorus/core/proc/check_lightning_arcs(moderator_list)
	if(power_level < 4)
		return
	if(moderator_list[/datum/gas/antinoblium] <= 50 && critical_threshold_proximity <= 500)
		return
	var/zap_number = power_level - 2

	if(critical_threshold_proximity > 650 && prob(20))
		zap_number += 1

	var/cutoff = 1500
	cutoff = clamp(3000 - (power_level * (internal_fusion.total_moles() * 0.45)), 450, 3000)

	var/zaps_aspect = "sm_arc"
	var/flags = ZAP_SUPERMATTER_FLAGS
	switch(power_level)
		if(5)
			zaps_aspect = "sm_arc_supercharged"
			flags |= (ZAP_MOB_DAMAGE)
		if(6)
			zaps_aspect = "sm_arc_dbz_referance"
			flags |= (ZAP_MOB_DAMAGE | ZAP_OBJ_DAMAGE)

	playsound(loc, 'sound/weapons/emitter2.ogg', 100, TRUE, extrarange = 10)
	for(var/i in 1 to zap_number)
		supermatter_zap(src, 5, power_level * 300, flags, zap_cutoff = cutoff, power_level = src.power_level * 1000, zap_icon = zaps_aspect)

/obj/machinery/atmospherics/components/unary/hypertorus/core/proc/check_gravity_pulse(delta_time)
	if(DT_PROB(100 - critical_threshold_proximity / 15, delta_time))
		return
	var/grav_range = round(log(2.5, critical_threshold_proximity))
	for(var/mob/alive_mob in GLOB.alive_mob_list)
		if(alive_mob.z != z || get_dist(alive_mob, src) > grav_range || alive_mob.mob_negates_gravity())
			continue
		step_towards(alive_mob, loc)

/obj/machinery/atmospherics/components/unary/hypertorus/core/proc/remove_waste(delta_time)
	//Gases can be removed from the moderator internal by using the interface.
	if(!waste_remove)
		return
	var/filtering_amount = moderator_scrubbing.len
	for(var/gas in moderator_internal.get_gases() & moderator_scrubbing)
		var/datum/gas_mixture/removed = moderator_internal.remove_specific(gas, (moderator_filtering_rate / filtering_amount) * delta_time)
		if(removed)
			linked_output.airs[1].merge(removed)

	if (selected_fuel)
		var/datum/gas_mixture/internal_remove
		for(var/gas_id in selected_fuel.primary_products)
			if(internal_fusion.get_moles(gas_id) > 0)
				internal_remove = internal_fusion.remove_specific(gas_id, internal_fusion.get_moles(gas_id) * (1 - (1 - 0.25) ** delta_time))
				linked_output.airs[1].merge(internal_remove)

/obj/machinery/atmospherics/components/unary/hypertorus/core/proc/process_internal_cooling(delta_time)
	if(moderator_internal.total_moles() > 0 && internal_fusion.total_moles() > 0)
		//Modifies the moderator_internal temperature based on energy conduction and also the fusion by the same amount
		var/fusion_temperature_delta = internal_fusion.return_temperature() - moderator_internal.return_temperature()
		var/fusion_heat_amount = (1 - (1 - METALLIC_VOID_CONDUCTIVITY) ** delta_time) * fusion_temperature_delta * (internal_fusion.heat_capacity() * moderator_internal.heat_capacity() / (internal_fusion.heat_capacity() + moderator_internal.heat_capacity()))
		internal_fusion.set_temperature(max(internal_fusion.return_temperature() - fusion_heat_amount / internal_fusion.heat_capacity(), TCMB))
		moderator_internal.set_temperature(max(moderator_internal.return_temperature() + fusion_heat_amount / moderator_internal.heat_capacity(), TCMB))

	if(airs[1].total_moles() * 0.05 <= MINIMUM_MOLE_COUNT)
		return
	var/datum/gas_mixture/cooling_port = airs[1]
	var/datum/gas_mixture/cooling_remove = cooling_port.remove(0.05 * cooling_port.total_moles())
	//Cooling of the moderator gases with the cooling loop in and out the core
	if(moderator_internal.total_moles() > 0)
		var/coolant_temperature_delta = cooling_remove.return_temperature() - moderator_internal.return_temperature()
		var/cooling_heat_amount = (1 - (1 - HIGH_EFFICIENCY_CONDUCTIVITY) ** delta_time) * coolant_temperature_delta * (cooling_remove.heat_capacity() * moderator_internal.heat_capacity() / (cooling_remove.heat_capacity() + moderator_internal.heat_capacity()))
		cooling_remove.set_temperature(max(cooling_remove.return_temperature() - cooling_heat_amount / cooling_remove.heat_capacity(), TCMB))
		moderator_internal.set_temperature(max(moderator_internal.return_temperature() + cooling_heat_amount / moderator_internal.heat_capacity(), TCMB))

	else if(internal_fusion.total_moles() > 0)
		var/coolant_temperature_delta = cooling_remove.return_temperature() - internal_fusion.return_temperature()
		var/cooling_heat_amount = (1 - (1 - METALLIC_VOID_CONDUCTIVITY) ** delta_time) * coolant_temperature_delta * (cooling_remove.heat_capacity() * internal_fusion.heat_capacity() / (cooling_remove.heat_capacity() + internal_fusion.heat_capacity()))
		cooling_remove.set_temperature(max(cooling_remove.return_temperature() - cooling_heat_amount / cooling_remove.heat_capacity(), TCMB))
		internal_fusion.set_temperature(max(internal_fusion.return_temperature() + cooling_heat_amount / internal_fusion.heat_capacity(), TCMB))
	cooling_port.merge(cooling_remove)

/obj/machinery/atmospherics/components/unary/hypertorus/core/proc/inject_from_side_components(delta_time)
	update_pipenets()

	//Check and stores the gases from the moderator input in the moderator internal gasmix
	var/datum/gas_mixture/moderator_port = linked_moderator.airs[1]
	if(start_moderator && moderator_port.total_moles())
		moderator_internal.merge(moderator_port.remove(moderator_injection_rate * delta_time))
		linked_moderator.update_parents()

	//Check if the fuels are present and move them inside the fuel internal gasmix
	if(!start_fuel || !selected_fuel || !check_gas_requirements())
		return

	var/datum/gas_mixture/fuel_port = linked_input.airs[1]
	for(var/gas_type in selected_fuel.requirements)
		internal_fusion.merge(fuel_port.remove_specific(gas_type, fuel_injection_rate * delta_time / length(selected_fuel.requirements)))
		linked_input.update_parents()

/obj/machinery/atmospherics/components/unary/hypertorus/core/proc/check_deconstructable()
	if(!active)
		return
	if(power_level > 0)
		fusion_started = TRUE
		linked_input.fusion_started = TRUE
		linked_output.fusion_started = TRUE
		linked_moderator.fusion_started = TRUE
		linked_interface.fusion_started = TRUE
		for(var/obj/machinery/hypertorus/corner/corner in corners)
			corner.fusion_started = TRUE
	else
		fusion_started = FALSE
		linked_input.fusion_started = FALSE
		linked_output.fusion_started = FALSE
		linked_moderator.fusion_started = FALSE
		linked_interface.fusion_started = FALSE
		for(var/obj/machinery/hypertorus/corner/corner in corners)
			corner.fusion_started = FALSE
