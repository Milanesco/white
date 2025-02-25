/datum/species/abductor
	name = "похититель"
	id = "abductor"
	say_mod = "тараторит"
	sexes = FALSE
	species_traits = list(NOBLOOD,NOEYESPRITES)
	inherent_traits = list(TRAIT_ADVANCEDTOOLUSER,TRAIT_VIRUSIMMUNE,TRAIT_CHUNKYFINGERS,TRAIT_NOHUNGER,TRAIT_NOBREATH,TRAIT_CAN_STRIP,TRAIT_NOHYDRATION)
	mutanttongue = /obj/item/organ/tongue/abductor
	changesource_flags = MIRROR_BADMIN | WABBAJACK | MIRROR_PRIDE | MIRROR_MAGIC | RACE_SWAP | ERT_SPAWN | SLIME_EXTRACT
	ass_image = 'icons/ass/assgrey.png'

/datum/species/abductor/on_species_gain(mob/living/carbon/C, datum/species/old_species)
	. = ..()
	var/datum/atom_hud/abductor_hud = GLOB.huds[DATA_HUD_ABDUCTOR]
	abductor_hud.add_hud_to(C)

	C.set_safe_hunger_level()

/datum/species/abductor/on_species_loss(mob/living/carbon/C)
	. = ..()
	var/datum/atom_hud/abductor_hud = GLOB.huds[DATA_HUD_ABDUCTOR]
	abductor_hud.remove_hud_from(C)
