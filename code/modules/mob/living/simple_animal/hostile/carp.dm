#define REGENERATION_DELAY 60  // After taking damage, how long it takes for automatic regeneration to begin for megacarps (ty robustin!)

/mob/living/simple_animal/hostile/carp
	name = "космокарп"
	desc = "Милашка - подумаешь ты перед первым в своей жизни укусом карпа."
	icon = 'icons/mob/carp.dmi'
	icon_state = "base"
	icon_living = "base"
	icon_dead = "base_dead"
	icon_gib = "carp_gib"
	mob_biotypes = MOB_ORGANIC|MOB_BEAST
	movement_type = FLOATING
	speak_chance = 0
	turns_per_move = 5
	butcher_results = list(/obj/item/food/fishmeat/carp = 2)
	response_help_continuous = "гладит"
	response_help_simple = "гладит"
	response_disarm_continuous = "аккуратно отталкивает"
	response_disarm_simple = "аккуратно отталкивает"
	emote_taunt = list("скрежетает зубками")
	taunt_chance = 30
	speed = 0
	maxHealth = 25
	health = 25
	food_type = list(/obj/item/food/meat)
	tame_chance = 10
	bonus_tame_chance = 5
	search_objects = 1
	wanted_objects = list(/obj/item/storage/cans)
	harm_intent_damage = 8
	obj_damage = 100
	melee_damage_lower = 15
	melee_damage_upper = 15
	attack_verb_continuous = "кусает"
	attack_verb_simple = "кусает"
	attack_sound = 'sound/weapons/bite.ogg'
	attack_vis_effect = ATTACK_EFFECT_BITE
	speak_emote = list("скрежещет")
	//Space carp aren't affected by cold.
	atmos_requirements = list("min_oxy" = 0, "max_oxy" = 0, "min_tox" = 0, "max_tox" = 0, "min_co2" = 0, "max_co2" = 0, "min_n2" = 0, "max_n2" = 0)
	minbodytemp = 0
	maxbodytemp = 1500
	faction = list("carp")
	pressure_resistance = 200
	gold_core_spawnable = HOSTILE_SPAWN
	/// If the carp uses random coloring
	var/random_color = TRUE
	/// The chance for a rare color variant
	var/rarechance = 1
	/// List of usual carp colors
	var/static/list/carp_colors = list(
		"lightpurple" = "#aba2ff",
		"lightpink" = "#da77a8",
		"green" = "#70ff25",
		"grape" = "#df0afb",
		"swamp" = "#e5e75a",
		"turquoise" = "#04e1ed",
		"brown" = "#ca805a",
		"teal" = "#20e28e",
		"lightblue" = "#4d88cc",
		"rusty" = "#dd5f34",
		"lightred" = "#fd6767",
		"yellow" = "#f3ca4a",
		"blue" = "#09bae1",
		"palegreen" = "#7ef099"
	)
	/// List of rare carp colors
	var/static/list/carp_colors_rare = list(
		"silver" = "#fdfbf3"
	)

/mob/living/simple_animal/hostile/carp/Initialize(mapload)
	AddElement(/datum/element/simple_flying)
	if(random_color)
		set_greyscale(new_config=/datum/greyscale_config/carp)
		carp_randomify(rarechance)
	. = ..()
	ADD_TRAIT(src, TRAIT_SPACEWALK, INNATE_TRAIT)
	add_cell_sample()
	var/datum/action/small_sprite/action = new
	action.Grant(src)

/mob/living/simple_animal/hostile/carp/add_cell_sample()
	AddElement(/datum/element/swabable, CELL_LINE_TABLE_CARP, CELL_VIRUS_TABLE_GENERIC_MOB, 1, 5)

/**
 * Randomly assigns a color to a carp from either a common or rare color variant lists
 *
 * Arguments:
 * * rare The chance of the carp receiving color from the rare color variant list
 */
/mob/living/simple_animal/hostile/carp/proc/carp_randomify(rarechance)
	var/our_color
	if(prob(rarechance))
		our_color = pick(carp_colors_rare)
		set_greyscale(colors=list(carp_colors_rare[our_color]))
	else
		our_color = pick(carp_colors)
		set_greyscale(colors=list(carp_colors[our_color]))

/mob/living/simple_animal/hostile/carp/revive(full_heal = FALSE, admin_revive = FALSE)
	. = ..()
	if(.)
		update_icon()

/mob/living/simple_animal/hostile/carp/proc/chomp_plastic()
	var/obj/item/storage/cans/tasty_plastic = locate(/obj/item/storage/cans) in view(1, src)
	if(tasty_plastic && Adjacent(tasty_plastic))
		visible_message(span_notice("[capitalize(src.name)] gets its head stuck in [tasty_plastic], and gets cut breaking free from it!") , span_notice("Пытаюсь avoid [tasty_plastic], but it looks so... delicious... Ow! It cuts the inside of your mouth!"))

		new /obj/effect/decal/cleanable/plastic(loc)

		adjustBruteLoss(5)
		qdel(tasty_plastic)

/mob/living/simple_animal/hostile/carp/Life(delta_time = SSMOBS_DT, times_fired)
	. = ..()
	if(stat == CONSCIOUS)
		chomp_plastic()

/mob/living/simple_animal/hostile/carp/tamed()
	. = ..()
	can_buckle = TRUE
	buckle_lying = 0
	AddElement(/datum/element/ridable, /datum/component/riding/creature/carp)

/mob/living/simple_animal/hostile/carp/holocarp
	icon_state = "holocarp"
	icon_living = "holocarp"
	maxbodytemp = INFINITY
	gold_core_spawnable = NO_SPAWN
	del_on_death = 1
	random_color = FALSE
	food_type = list()
	tame_chance = 0
	bonus_tame_chance = 0

/mob/living/simple_animal/hostile/carp/holocarp/add_cell_sample()
	return

/mob/living/simple_animal/hostile/carp/megacarp
	icon = 'icons/mob/broadMobs.dmi'
	name = "мега-космокарп"
	desc = "Милашка - подумаешь ты перед первым в своей жизни укусом карпа. Этот выглядит здоровее обычного."
	icon_state = "megacarp"
	icon_living = "megacarp"
	icon_dead = "megacarp_dead"
	icon_gib = "megacarp_gib"
	health_doll_icon = "megacarp"
	maxHealth = 100
	health = 100
	pixel_x = -16
	base_pixel_x = -16
	mob_size = MOB_SIZE_LARGE
	random_color = FALSE
	food_type = list()
	tame_chance = 0
	bonus_tame_chance = 0

	obj_damage = 120
	melee_damage_lower = 30
	melee_damage_upper = 30

	var/regen_cooldown = 0

/mob/living/simple_animal/hostile/carp/megacarp/Initialize()
	. = ..()
	name = "[pick(GLOB.megacarp_first_names)] [pick(GLOB.megacarp_last_names)]"
	melee_damage_lower += rand(2, 10)
	melee_damage_upper += rand(10,20)
	maxHealth += rand(30,60)
	move_to_delay = rand(3,7)
	AddElement(/datum/element/swabable, CELL_LINE_TABLE_MEGACARP, CELL_VIRUS_TABLE_GENERIC_MOB)

/mob/living/simple_animal/hostile/carp/megacarp/add_cell_sample()
	AddElement(/datum/element/swabable, CELL_LINE_TABLE_MEGACARP, CELL_VIRUS_TABLE_GENERIC_MOB, 1, 5)

/mob/living/simple_animal/hostile/carp/megacarp/adjustHealth(amount, updating_health = TRUE, forced = FALSE)
	. = ..()
	if(.)
		regen_cooldown = world.time + REGENERATION_DELAY

/mob/living/simple_animal/hostile/carp/megacarp/Login()
	. = ..()
	if(!. || !client)
		return FALSE

	AddElement(/datum/element/ridable, /datum/component/riding/creature/megacarp)
	can_buckle = TRUE
	buckle_lying = 0

/mob/living/simple_animal/hostile/carp/megacarp/Life(delta_time = SSMOBS_DT, times_fired)
	. = ..()
	if(regen_cooldown < world.time)
		heal_overall_damage(2 * delta_time)

/mob/living/simple_animal/hostile/carp/lia
	name = "Lia"
	real_name = "Lia"
	desc = "A failed experiment of Nanotrasen to create weaponised carp technology. This less than intimidating carp now serves as the Head of Security's pet."
	gender = FEMALE
	speak_emote = list("пищит")
	gold_core_spawnable = NO_SPAWN
	faction = list("neutral")
	health = 200
	icon_dead = "magicarp_dead"
	icon_gib = "magicarp_gib"
	icon_living = "magicarp"
	icon_state = "magicarp"
	maxHealth = 200
	random_color = FALSE
	food_type = list()
	tame_chance = 0
	bonus_tame_chance = 0
	pet_bonus = TRUE
	pet_bonus_emote = "bloops happily!"

/mob/living/simple_animal/hostile/carp/cayenne
	name = "Cayenne"
	real_name = "Cayenne"
	desc = "A failed Syndicate experiment in weaponized space carp technology, it now serves as a lovable mascot."
	gender = FEMALE
	speak_emote = list("пищит")
	gold_core_spawnable = NO_SPAWN
	faction = list(ROLE_SYNDICATE)
	rarechance = 10
	food_type = list()
	tame_chance = 0
	bonus_tame_chance = 0
	pet_bonus = TRUE
	pet_bonus_emote = "bloops happily!"
	/// Keeping track of the nuke disk for the functionality of storing it.
	var/obj/item/disk/nuclear/disky
	/// Location of the file storing disk overlays
	var/icon/disk_overlay_file = 'icons/mob/carp.dmi'
	/// Colored disk mouth appearance for adding it as a mouth overlay
	var/mutable_appearance/colored_disk_mouth

/mob/living/simple_animal/hostile/carp/cayenne/Initialize()
	. = ..()
	colored_disk_mouth = mutable_appearance(SSgreyscale.GetColoredIconByType(/datum/greyscale_config/carp/disk_mouth, greyscale_colors))
	ADD_TRAIT(src, TRAIT_DISK_VERIFIER, INNATE_TRAIT) //carp can verify disky
	ADD_TRAIT(src, TRAIT_ADVANCEDTOOLUSER, INNATE_TRAIT) //carp SMART

/mob/living/simple_animal/hostile/carp/cayenne/death(gibbed)
	if(disky)
		disky.forceMove(drop_location())
		disky = null
	return ..()

/mob/living/simple_animal/hostile/carp/cayenne/Destroy(force)
	QDEL_NULL(disky)
	return ..()

/mob/living/simple_animal/hostile/carp/cayenne/examine(mob/user)
	. = ..()
	if(disky)
		. += span_notice("Wait... is that [disky] in [p_their()] mouth?")

/mob/living/simple_animal/hostile/carp/cayenne/AttackingTarget(atom/attacked_target)
	if(istype(attacked_target, /obj/item/disk/nuclear))
		var/obj/item/disk/nuclear/potential_disky = attacked_target
		if(potential_disky.anchored)
			return
		potential_disky.forceMove(src)
		disky = potential_disky
		to_chat(src, span_nicegreen("YES!! You manage to pick up [disky]. (Click anywhere to place it back down.)"))
		update_icon()
		if(!disky.fake)
			client.give_award(/datum/award/achievement/misc/cayenne_disk, src)
		return
	if(disky)
		if(isopenturf(attacked_target))
			to_chat(src, span_notice("You place [disky] on [attacked_target]"))
			disky.forceMove(attacked_target.drop_location())
			disky = null
			update_icon()
		else
			disky.melee_attack_chain(src, attacked_target)
		return
	return ..()

/mob/living/simple_animal/hostile/carp/cayenne/Exited(atom/movable/AM, atom/newLoc)
	. = ..()
	if(AM == disky)
		disky = null
		update_icon()

/mob/living/simple_animal/hostile/carp/cayenne/update_overlays()
	. = ..()
	if(!disky || stat == DEAD)
		return
	. += colored_disk_mouth
	. += mutable_appearance(disk_overlay_file, "disk_overlay")

/mob/living/simple_animal/hostile/carp/bluespacecarp
	name = "Блюспэйскарп"
	desc = "Интересная зверушка, постоянно мерцает. Интересно, на какой частоте?"
	maxHealth = 90
	health = 90
	harm_intent_damage = 5
	attack_verb_continuous = "прожигает"
	attack_verb_simple = "прожигает"
	attack_sound = 'sound/weapons/blaster.ogg'
	rarechance = 10
	melee_damage_type = BURN
	butcher_results = list(/obj/item/food/fishmeat/carp = 2, /obj/item/stack/telecrystal = 2)
	var/safe_cooldown = 20
	var/safe

/mob/living/simple_animal/hostile/carp/bluespacecarp/Initialize()
	safe = world.time
	. = ..()

/mob/living/simple_animal/hostile/carp/bluespacecarp/attackby(obj/item/W, mob/user, params)
	if(safe+safe_cooldown <= world.time && stat != DEAD)
		do_sparks(1, FALSE, src)
		to_chat(user,("[src.name] дематериализуется и удар пролетает насквозь!"))
		safe = world.time
		if(prob(20))
			empulse(src, 2, 5)
		return
	else
		return ..()
