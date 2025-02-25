//Penguins

/mob/living/simple_animal/pet/penguin
	response_help_continuous = "гладит"
	response_help_simple = "гладит"
	response_disarm_continuous = "bops"
	response_disarm_simple = "bop"
	response_harm_continuous = "пинает"
	response_harm_simple = "пинает"
	speak = list("Га Га!", "НУТ НУТ!", "НУТ!", "Нут", "нут", "Пра!", "Гра!")
	speak_emote = list("кричит", "гогочет")
	emote_hear = list("каааакает!", "гаааакает!", "ерундит.","ЕРУНДИТ!")
	emote_see = list("трясет клювом.", "хлопает крыльями.","чистит себя.")
	faction = list("penguin")
	minbodytemp = 0
	see_in_dark = 5
	speak_chance = 1
	turns_per_move = 10
	icon = 'icons/mob/penguins.dmi'
	butcher_results = list(/obj/item/organ/ears/penguin = 1, /obj/item/food/meat/slab/penguin = 3)
	pet_bonus = TRUE
	pet_bonus_emote = "honks happily!"

	footstep_type = FOOTSTEP_MOB_BAREFOOT

/mob/living/simple_animal/pet/penguin/Initialize()
	. = ..()
	AddElement(/datum/element/waddling)

/mob/living/simple_animal/pet/penguin/emperor
	name = "Emperor penguin"
	real_name = "penguin"
	desc = "Emperor of all they survey."
	icon_state = "penguin"
	icon_living = "penguin"
	icon_dead = "penguin_dead"
	gold_core_spawnable = FRIENDLY_SPAWN
	butcher_results = list(/obj/item/organ/ears/penguin = 1, /obj/item/food/meat/slab/penguin = 3)

/mob/living/simple_animal/pet/penguin/emperor/shamebrero
	name = "Shamebrero penguin"
	desc = "Shameful of all he surveys."
	icon_state = "penguin_shamebrero"
	icon_living = "penguin_shamebrero"
	gold_core_spawnable = NO_SPAWN
	unique_pet = TRUE

/mob/living/simple_animal/pet/penguin/baby
	speak = list("gah", "noot noot", "noot!", "noot", "squeee!", "noo!")
	name = "Penguin chick"
	real_name = "penguin"
	desc = "Can't fly and barely waddles, yet the prince of all chicks."
	icon_state = "penguin_baby"
	icon_living = "penguin_baby"
	icon_dead = "penguin_baby_dead"
	density = FALSE
	pass_flags = PASSMOB
	mob_size = MOB_SIZE_SMALL
	butcher_results = list(/obj/item/organ/ears/penguin = 1, /obj/item/food/meat/slab/penguin = 1)

