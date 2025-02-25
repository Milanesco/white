/**
 * Lobstrosities, the poster boy of charging AI mobs. Drops crab meat and bones.
 * Outside of charging, it's intended behavior is that it is generally slow moving, but makes up for that with a knockdown attack to score additional hits.
 */
/mob/living/simple_animal/hostile/asteroid/lobstrosity
	name = "arctic lobstrosity"
	desc = "A marvel of evolution gone wrong, the frosty ice produces underground lakes where these ill tempered seafood gather. Beware its charge."
	icon = 'icons/mob/icemoon/icemoon_monsters.dmi'
	icon_state = "arctic_lobstrosity"
	icon_living = "arctic_lobstrosity"
	icon_dead = "arctic_lobstrosity_dead"
	mob_biotypes = MOB_ORGANIC|MOB_BEAST
	mouse_opacity = MOUSE_OPACITY_ICON
	friendly_verb_continuous = "chitters at"
	friendly_verb_simple = "chits at"
	speak_emote = list("трепещет")
	speed = 3
	move_to_delay = 20
	maxHealth = 150
	health = 150
	obj_damage = 15
	melee_damage_lower = 15
	melee_damage_upper = 19
	attack_verb_continuous = "snips"
	attack_verb_simple = "snip"
	attack_sound = 'sound/weapons/bite.ogg'
	attack_vis_effect = ATTACK_EFFECT_BITE //the closest we have to a crustacean pinching attack effect rn.
	weather_immunities = list(TRAIT_ASHSTORM_IMMUNE)
	vision_range = 5
	aggro_vision_range = 7
	charger = TRUE
	charge_distance = 4
	butcher_results = list(/obj/item/food/meat/crab = 2, /obj/item/stack/sheet/bone = 2)
	robust_searching = TRUE
	footstep_type = FOOTSTEP_MOB_CLAW
	crusher_loot = /obj/item/crusher_trophy/lobster_claw

/mob/living/simple_animal/hostile/asteroid/lobstrosity/lava
	name = "tropical lobstrosity"
	desc = "A marvel of evolution gone wrong, the sulfur lakes of lavaland have given them a vibrant, red hued shell. Beware its charge."
	icon_state = "lobstrosity"
	icon_living = "lobstrosity"
	icon_dead = "lobstrosity_dead"
	weather_immunities = list(TRAIT_LAVA_IMMUNE,TRAIT_ASHSTORM_IMMUNE)

/obj/item/crusher_trophy/lobster_claw
	name = "lobster claw"
	icon_state = "lobster_claw"
	desc = "A lobster claw."
	denied_type = /obj/item/crusher_trophy/lobster_claw
	bonus_value = 1

/obj/item/crusher_trophy/lobster_claw/effect_desc()
	return "mark detonation to briefly stagger the target for [bonus_value] seconds"

/obj/item/crusher_trophy/lobster_claw/on_mark_detonation(mob/living/target, mob/living/user)
	target.apply_status_effect(/datum/status_effect/stagger, bonus_value SECONDS)
