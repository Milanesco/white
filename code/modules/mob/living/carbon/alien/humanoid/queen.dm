/mob/living/carbon/alien/humanoid/royal
	//Common stuffs for Praetorian and Queen
	icon = 'icons/mob/alienqueen.dmi'
	status_flags = 0
	ventcrawler = VENTCRAWLER_NONE //pull over that ass too fat
	pixel_x = -16
	base_pixel_x = -16
	bubble_icon = "alienroyal"
	mob_size = MOB_SIZE_LARGE
	layer = LARGE_MOB_LAYER //above most mobs, but below speechbubbles
	plane = GAME_PLANE_UPPER_FOV_HIDDEN
	pressure_resistance = 200 //Because big, stompy xenos should not be blown around like paper.
	butcher_results = list(/obj/item/food/meat/slab/xeno = 20, /obj/item/stack/sheet/animalhide/xeno = 3)

	var/alt_inhands_file = 'icons/mob/alienqueen.dmi'

/mob/living/carbon/alien/humanoid/royal/on_lying_down(new_lying_angle)
	. = ..()
	plane = GAME_PLANE_FOV_HIDDEN //So it won't hide smaller mobs.

/mob/living/carbon/alien/humanoid/royal/on_standing_up(new_lying_angle)
	. = ..()
	plane = initial(plane)

/mob/living/carbon/alien/humanoid/royal/can_inject(mob/user, target_zone, injection_flags)
	return FALSE

/mob/living/carbon/alien/humanoid/royal/queen
	name = "alien queen"
	caste = "q"
	maxHealth = 400
	health = 400
	icon_state = "alienq"
	var/datum/action/small_sprite/smallsprite = new/datum/action/small_sprite/queen()

/mob/living/carbon/alien/humanoid/royal/queen/Initialize()
	//there should only be one queen
	for(var/mob/living/carbon/alien/humanoid/royal/queen/Q in GLOB.carbon_list)
		if(Q == src)
			continue
		if(Q.stat == DEAD)
			continue
		if(Q.client)
			name = "alien princess ([rand(1, 999)])"	//if this is too cutesy feel free to change it/remove it.
			break

	real_name = src.name

	AddSpell(new /obj/effect/proc_holder/spell/aoe_turf/repulse/xeno(src))
	AddAbility(new/obj/effect/proc_holder/alien/royal/queen/promote())
	smallsprite.Grant(src)

	priority_announce("На станции [station_name()] обнаружена королева ксеноморфов. Заблокируйте любой внешний доступ, включая воздуховоды и вентиляцию.", "Боевая Тревога", ANNOUNCER_ALIENS)

	return ..()

/mob/living/carbon/alien/humanoid/royal/queen/create_internal_organs()
	internal_organs += new /obj/item/organ/alien/plasmavessel/large/queen
	internal_organs += new /obj/item/organ/alien/resinspinner
	internal_organs += new /obj/item/organ/alien/acid
	internal_organs += new /obj/item/organ/alien/neurotoxin
	internal_organs += new /obj/item/organ/alien/eggsac
	..()

//Queen verbs
/obj/effect/proc_holder/alien/lay_egg
	name = "Lay Egg"
	desc = "Lay an egg to produce huggers to impregnate prey with."
	plasma_cost = 75
	check_turf = TRUE
	action_icon_state = "alien_egg"

/obj/effect/proc_holder/alien/lay_egg/fire(mob/living/carbon/user)
	if(!check_vent_block(user))
		return FALSE

	if(locate(/obj/structure/alien/egg) in get_turf(user))
		to_chat(user, span_alertalien("There's already an egg here."))
		return FALSE

	user.visible_message(span_alertalien("[user] lays an egg!"))
	new /obj/structure/alien/egg(user.loc)
	return TRUE

//Button to let queen choose her praetorian.
/obj/effect/proc_holder/alien/royal/queen/promote
	name = "Create Royal Parasite"
	desc = "Produce a royal parasite to grant one of your children the honor of being your Praetorian."
	plasma_cost = 500 //Plasma cost used on promotion, not spawning the parasite.

	action_icon_state = "alien_queen_promote"



/obj/effect/proc_holder/alien/royal/queen/promote/fire(mob/living/carbon/alien/user)
	var/obj/item/queenpromote/prom
	if(get_alien_type(/mob/living/carbon/alien/humanoid/royal/praetorian/))
		to_chat(user, span_noticealien("You already have a Praetorian!"))
		return
	else
		for(prom in user)
			to_chat(user, span_noticealien("You discard [prom]."))
			qdel(prom)
			return

		prom = new (user.loc)
		if(!user.put_in_active_hand(prom, 1))
			to_chat(user, span_warning("You must empty your hands before preparing the parasite."))
			return
		else //Just in case telling the player only once is not enough!
			to_chat(user, span_noticealien("Use the royal parasite on one of your children to promote her to Praetorian!"))
	return

/obj/item/queenpromote
	name = "\improper royal parasite"
	desc = "Inject this into one of your grown children to promote her to a Praetorian!"
	icon_state = "alien_medal"
	item_flags = ABSTRACT | DROPDEL
	icon = 'icons/mob/alien.dmi'

/obj/item/queenpromote/Initialize()
	. = ..()
	ADD_TRAIT(src, TRAIT_NODROP, ABSTRACT_ITEM_TRAIT)

/obj/item/queenpromote/attack(mob/living/M, mob/living/carbon/alien/humanoid/user)
	if(!isalienadult(M) || isalienroyal(M))
		to_chat(user, span_noticealien("You may only use this with your adult, non-royal children!"))
		return
	if(get_alien_type(/mob/living/carbon/alien/humanoid/royal/praetorian/))
		to_chat(user, span_noticealien("You already have a Praetorian!"))
		return

	var/mob/living/carbon/alien/humanoid/A = M
	if(A.stat == CONSCIOUS && A.mind && A.key)
		if(!user.usePlasma(500))
			to_chat(user, span_noticealien("You must have 500 plasma stored to use this!"))
			return

		to_chat(A, span_noticealien("The queen has granted you a promotion to Praetorian!"))
		user.visible_message(span_alertalien("[A] begins to expand, twist and contort!"))
		var/mob/living/carbon/alien/humanoid/royal/praetorian/new_prae = new (A.loc)
		A.mind.transfer_to(new_prae)
		qdel(A)
		qdel(src)
		return
	else
		to_chat(user, span_warning("This child must be alert and responsive to become a Praetorian!"))

/obj/item/queenpromote/attack_self(mob/user)
	to_chat(user, span_noticealien("You discard [src]."))
	qdel(src)
