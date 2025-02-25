GLOBAL_LIST_INIT(hardcoded_gases, list(/datum/gas/oxygen, /datum/gas/nitrogen, /datum/gas/carbon_dioxide, /datum/gas/plasma)) //the main four gases, which were at one time hardcoded
//Now this is what I call history
GLOBAL_LIST_INIT(nonreactive_gases, typecacheof(list(/datum/gas/oxygen, /datum/gas/nitrogen, /datum/gas/carbon_dioxide, /datum/gas/pluoxium, /datum/gas/stimulum, /datum/gas/nitryl))) //unable to react amongst themselves

/proc/meta_gas_list()
	. = subtypesof(/datum/gas)
	for(var/gas_path in .)
		var/list/gas_info = new(7)
		var/datum/gas/gas = gas_path

		gas_info[META_GAS_SPECIFIC_HEAT] = initial(gas.specific_heat)
		gas_info[META_GAS_NAME] = initial(gas.name)

		gas_info[META_GAS_MOLES_VISIBLE] = initial(gas.moles_visible)
		if(initial(gas.moles_visible) != null)
			gas_info[META_GAS_OVERLAY] = new /list(TOTAL_VISIBLE_STATES)
			for(var/i in 1 to TOTAL_VISIBLE_STATES)
				gas_info[META_GAS_OVERLAY][i] = new /obj/effect/overlay/gas(initial(gas.gas_overlay), log(4, (i+0.4*TOTAL_VISIBLE_STATES) / (0.35*TOTAL_VISIBLE_STATES)) * 255)

		gas_info[META_GAS_FUSION_POWER] = initial(gas.fusion_power)
		gas_info[META_GAS_DANGER] = initial(gas.dangerous)
		gas_info[META_GAS_ID] = initial(gas.id)
		.[gas_path] = gas_info

/proc/gas_id2path(id)
	var/list/meta_gas = GLOB.meta_gas_info
	if(id in meta_gas)
		return id
	for(var/path in meta_gas)
		if(meta_gas[path][META_GAS_ID] == id)
			return path
	return ""

/*||||||||||||||/----------\||||||||||||||*\
||||||||||||||||[GAS DATUMS]||||||||||||||||
||||||||||||||||\__________/||||||||||||||||
||||These should never be instantiated. ||||
||||They exist only to make it easier   ||||
||||to add a new gas. They are accessed ||||
||||only by meta_gas_list().            ||||
\*||||||||||||||||||||||||||||||||||||||||*/

/datum/gas
	var/id = ""
	var/specific_heat = 0
	var/name = ""
	var/gas_overlay = "" //icon_state in icons/effects/atmospherics.dmi
	var/moles_visible = null
	var/dangerous = FALSE //currently used by canisters
	var/fusion_power = 0 //How much the gas accelerates a fusion reaction
	var/rarity = 0 // relative rarity compared to other gases, used when setting up the reactions list.

// If you add or remove gases, update TOTAL_NUM_GASES in the extools code to match! Extools currently expects 21 gas types to exist.

/datum/gas/oxygen
	id = "o2"
	specific_heat = 20
	name = "Кислород"
	rarity = 900

/datum/gas/nitrogen
	id = "n2"
	specific_heat = 20
	name = "Азот"
	rarity = 1000

/datum/gas/carbon_dioxide //what the fuck is this?
	id = "co2"
	specific_heat = 30
	name = "Углекислый газ"
	rarity = 700

/datum/gas/plasma
	id = "plasma"
	specific_heat = 200
	name = "Плазма"
	gas_overlay = "plasma"
	moles_visible = MOLES_GAS_VISIBLE
	dangerous = TRUE
	rarity = 800

/datum/gas/water_vapor
	id = "water_vapor"
	specific_heat = 40
	name = "Пар"
	gas_overlay = "water_vapor"
	moles_visible = MOLES_GAS_VISIBLE
	fusion_power = 8
	rarity = 500

/datum/gas/hypernoblium
	id = "nob"
	specific_heat = 2000
	name = "Гипер-ноблий"
	gas_overlay = "freon"
	moles_visible = MOLES_GAS_VISIBLE
	dangerous = TRUE
	fusion_power = 10
	rarity = 50

/datum/gas/nitrous_oxide
	id = "n2o"
	specific_heat = 40
	name = "Закись азота"
	gas_overlay = "nitrous_oxide"
	moles_visible = MOLES_GAS_VISIBLE * 2
	fusion_power = 10
	dangerous = TRUE
	rarity = 600

/datum/gas/nitryl
	id = "no2"
	specific_heat = 20
	name = "Нитрил"
	gas_overlay = "nitryl"
	moles_visible = MOLES_GAS_VISIBLE
	dangerous = TRUE
	rarity = 100

/datum/gas/tritium
	id = "tritium"
	specific_heat = 10
	name = "Тритий"
	gas_overlay = "tritium"
	moles_visible = MOLES_GAS_VISIBLE
	dangerous = TRUE
	fusion_power = 5
	rarity = 300

/datum/gas/bz
	id = "bz"
	specific_heat = 20
	name = "БЗ"
	dangerous = TRUE
	fusion_power = 8
	rarity = 400

/datum/gas/stimulum
	id = "stim"
	specific_heat = 5
	name = "Стимулум"
	fusion_power = 7
	rarity = 1

/datum/gas/pluoxium
	id = "pluox"
	specific_heat = 80
	name = "Плюоксиум"
	fusion_power = -10
	rarity = 200

/datum/gas/miasma
	id = "miasma"
	specific_heat = 20
	name = "Миазма"
	gas_overlay = "miasma"
	moles_visible = MOLES_GAS_VISIBLE * 60
	rarity = 250

/datum/gas/freon
	id = "freon"
	specific_heat = 600
	name = "Фреон"
	gas_overlay = "freon"
	moles_visible = MOLES_GAS_VISIBLE *30
	fusion_power = -5
	rarity = 10

/datum/gas/hydrogen
	id = "hydrogen"
	specific_heat = 15
	name = "Водород"
	dangerous = TRUE
	fusion_power = 2
	rarity = 600

/datum/gas/healium
	id = "healium"
	specific_heat = 10
	name = "Хилиум"
	dangerous = TRUE
	gas_overlay = "healium"
	moles_visible = MOLES_GAS_VISIBLE
	rarity = 300

/datum/gas/proto_nitrate
	id = "proto_nitrate"
	specific_heat = 30
	name = "Протонитрат"
	dangerous = TRUE
	gas_overlay = "proto_nitrate"
	moles_visible = MOLES_GAS_VISIBLE
	rarity = 200

/datum/gas/zauker
	id = "zauker"
	specific_heat = 350
	name = "Циклон Б"
	dangerous = TRUE
	gas_overlay = "zauker"
	moles_visible = MOLES_GAS_VISIBLE
	rarity = 1

/datum/gas/halon
	id = "halon"
	specific_heat = 175
	name = "Галон"
	dangerous = TRUE
	gas_overlay = "halon"
	moles_visible = MOLES_GAS_VISIBLE
	rarity = 300

/datum/gas/helium
	id = "helium"
	specific_heat = 15
	name = "Гелий"
	fusion_power = 7
	rarity = 50

/datum/gas/antinoblium
	id = "antinoblium"
	specific_heat = 1
	name = "Антиноблий"
	dangerous = TRUE
	gas_overlay = "antinoblium"
	moles_visible = MOLES_GAS_VISIBLE
	fusion_power = 20
	rarity = 1

/obj/effect/overlay/gas
	icon = 'icons/effects/atmospherics.dmi'
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	anchored = TRUE  // should only appear in vis_contents, but to be safe
	layer = FLY_LAYER
	plane = ABOVE_GAME_PLANE
	appearance_flags = TILE_BOUND
	vis_flags = NONE

/obj/effect/overlay/gas/New(state, alph)
	. = ..()
	icon_state = state
	alpha = alph
