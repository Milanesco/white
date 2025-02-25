// Banana
/obj/item/seeds/banana
	name = "пачка семян банана"
	desc = "Семена, из которых вырастают банановые деревья. Когда вырастут, держите плоды подальше от клоунов."
	icon_state = "seed-banana"
	species = "banana"
	plantname = "Banana Tree"
	product = /obj/item/food/grown/banana
	lifespan = 50
	endurance = 30
	instability = 10
	growing_icon = 'icons/obj/hydroponics/growing_fruits.dmi'
	icon_dead = "banana-dead"
	genes = list(/datum/plant_gene/trait/slip, /datum/plant_gene/trait/repeated_harvest)
	mutatelist = list(/obj/item/seeds/banana/mime, /obj/item/seeds/banana/bluespace)
	reagents_add = list(/datum/reagent/consumable/banana = 0.1, /datum/reagent/potassium = 0.1, /datum/reagent/consumable/nutriment/vitamin = 0.04, /datum/reagent/consumable/nutriment = 0.02)
	graft_gene = /datum/plant_gene/trait/slip

/obj/item/food/grown/banana
	seed = /obj/item/seeds/banana
	name = "банан"
	desc = "Отличный реквизит для клоуна."
	icon_state = "banana"
	inhand_icon_state = "banana"
	trash_type = /obj/item/grown/bananapeel
	bite_consumption_mod = 3
	foodtypes = FRUIT
	juice_results = list(/datum/reagent/consumable/banana = 0)
	distill_reagent = /datum/reagent/consumable/ethanol/bananahonk

/obj/item/food/grown/banana/generate_trash(atom/location)
	. = ..()
	var/obj/item/grown/bananapeel/peel = .
	if(istype(peel))
		peel.grind_results = list(/datum/reagent/medicine/coagulant/banana_peel = peel.seed.potency * 0.2)
		peel.juice_results = list(/datum/reagent/medicine/coagulant/banana_peel = peel.seed.potency * 0.2)

/obj/item/food/grown/banana/suicide_act(mob/user)
	user.visible_message(span_suicide("[user] is aiming [src] at [user.ru_na()]self! It looks like [user.p_theyre()] trying to commit suicide!"))
	playsound(loc, 'sound/items/bikehorn.ogg', 50, TRUE, -1)
	sleep(25)
	if(!user)
		return (OXYLOSS)
	user.say("BANG!", forced = /datum/reagent/consumable/banana)
	sleep(25)
	if(!user)
		return (OXYLOSS)
	user.visible_message("<B>[user]</B> ржёт так сильно, что начинает задыхаться!")
	return (OXYLOSS)

//Banana Peel
/obj/item/grown/bananapeel
	seed = /obj/item/seeds/banana
	name = "банановая кожура"
	desc = "Кожура от банана."
	lefthand_file = 'icons/mob/inhands/misc/food_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/misc/food_righthand.dmi'
	icon_state = "banana_peel"
	inhand_icon_state = "banana_peel"
	w_class = WEIGHT_CLASS_TINY
	throwforce = 0
	throw_speed = 3
	throw_range = 7

/obj/item/grown/bananapeel/Initialize(mapload)
	. = ..()
	if(prob(40))
		if(prob(60))
			icon_state = "[icon_state]_2"
		else
			icon_state = "[icon_state]_3"

/obj/item/grown/bananapeel/suicide_act(mob/user)
	user.visible_message(span_suicide("[user] is deliberately slipping on [src]! It looks like [user.p_theyre()] trying to commit suicide!"))
	playsound(loc, 'sound/misc/slip.ogg', 50, TRUE, -1)
	return (BRUTELOSS)


// Mimana - invisible sprites are totally a feature!
/obj/item/seeds/banana/mime
	name = "пачка семян мимана"
	desc = "Семена, из которых вырастают мимановые деревья. Когда вырастут, держите плоды подальше от мимов."
	icon_state = "seed-mimana"
	species = "mimana"
	plantname = "Mimana Tree"
	product = /obj/item/food/grown/banana/mime
	growthstages = 4
	mutatelist = list()
	reagents_add = list(/datum/reagent/consumable/nothing = 0.1, /datum/reagent/toxin/mutetoxin = 0.1, /datum/reagent/consumable/nutriment = 0.02)
	rarity = 15

/obj/item/food/grown/banana/mime
	seed = /obj/item/seeds/banana/mime
	name = "миман"
	desc = "Отличный реквизит для мима."
	icon_state = "mimana"
	trash_type = /obj/item/grown/bananapeel/mimanapeel
	distill_reagent = /datum/reagent/consumable/ethanol/silencer

/obj/item/grown/bananapeel/mimanapeel
	seed = /obj/item/seeds/banana/mime
	name = "мимановая кожура"
	desc = "Кожура от мимана."
	icon_state = "mimana_peel"
	inhand_icon_state = "mimana_peel"

// Bluespace Banana
/obj/item/seeds/banana/bluespace
	name = "пачка семян блюспейс-банана"
	desc = "Семена, из которых вырастают блюспейс-банановые деревья. Когда вырастут, держите плоды подальше от блюспейс-клоунов."
	icon_state = "seed-banana-blue"
	species = "bluespacebanana"
	icon_grow = "banana-grow"
	plantname = "Bluespace Banana Tree"
	instability = 40
	product = /obj/item/food/grown/banana/bluespace
	mutatelist = list()
	genes = list(/datum/plant_gene/trait/slip, /datum/plant_gene/trait/teleport, /datum/plant_gene/trait/repeated_harvest)
	reagents_add = list(/datum/reagent/bluespace = 0.2, /datum/reagent/consumable/banana = 0.1, /datum/reagent/consumable/nutriment/vitamin = 0.04, /datum/reagent/consumable/nutriment = 0.02)
	rarity = 30
	graft_gene = /datum/plant_gene/trait/teleport

/obj/item/food/grown/banana/bluespace
	seed = /obj/item/seeds/banana/bluespace
	name = "блюспейс банан"
	icon_state = "bluenana"
	inhand_icon_state = "bluespace_peel"
	trash_type = /obj/item/grown/bananapeel/bluespace
	tastes = list("банан" = 1)
	wine_power = 60
	wine_flavor = "slippery hypercubes"

/obj/item/grown/bananapeel/bluespace
	seed = /obj/item/seeds/banana/bluespace
	name = "блюспейс банановая кожура"
	desc = "Кожура от блюспейс банана."
	icon_state = "bluenana_peel"

// Other
/obj/item/grown/bananapeel/specialpeel     //used by /obj/item/clothing/shoes/clown_shoes/banana_shoes
	name = "синтетическая банановая кожура"
	desc = "Обычная, искусственая банановая кожурка."

/obj/item/grown/bananapeel/specialpeel/ComponentInitialize()
	. = ..()
	AddComponent(/datum/component/slippery, 40)
