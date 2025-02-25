/obj/vehicle/sealed/mecha/combat/phazon
	desc = "Вершина научных исследований и гордость Нанотрейзен, он использует передовые технологии блюспейс и дорогие материалы."
	name = "Фазон"
	icon_state = "phazon"
	movedelay = 2
	dir_in = 2 //Facing South.
	step_energy_drain = 3
	max_integrity = 200
	deflect_chance = 30
	armor = list(MELEE = 30, BULLET = 30, LASER = 30, ENERGY = 30, BOMB = 30, BIO = 0, RAD = 50, FIRE = 100, ACID = 100)
	max_temperature = 25000
	wreckage = /obj/structure/mecha_wreckage/phazon
	internal_damage_threshold = 25
	force = 15
	max_equip = 3
	phase_state = "phazon-phase"

/obj/vehicle/sealed/mecha/combat/phazon/generate_actions()
	. = ..()
	initialize_passenger_action_type(/datum/action/vehicle/sealed/mecha/mech_toggle_phasing)
	initialize_passenger_action_type(/datum/action/vehicle/sealed/mecha/mech_switch_damtype)
