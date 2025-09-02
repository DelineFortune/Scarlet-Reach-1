/datum/advclass/pioneer //minecraft griefer class that tnts your house dog and ass
	name = "Pioneer"
	tutorial = "Pioneers redraw the battlefield. They cut roads through obstacles, unhinge gates, and lace the ground with clever devices-making allies swift and enemies slow."
	allowed_sexes = list(MALE, FEMALE)
	allowed_races = RACES_ALL_KINDS
	outfit = /datum/outfit/job/roguetown/bandit/pioneer
	category_tags = list(CTAG_BANDIT)
	cmode_music = 'sound/music/combat_bandit2.ogg'

/datum/outfit/job/roguetown/bandit/pioneer/pre_equip(mob/living/carbon/human/H)
	..()
	if (!(istype(H.patron, /datum/patron/inhumen/zizo) || istype(H.patron, /datum/patron/inhumen/matthios) || istype(H.patron, /datum/patron/inhumen/graggar) || istype(H.patron, /datum/patron/inhumen/baotha)))
		to_chat(H, span_warning("My former deity has abandoned me.. Matthios is my new master."))
		H.set_patron(/datum/patron/inhumen/matthios)
	H.adjust_skillrank(/datum/skill/combat/polearms, 3, TRUE)
	H.adjust_skillrank(/datum/skill/combat/axes, 3, TRUE)
	H.adjust_skillrank(/datum/skill/combat/wrestling, 3, TRUE)
	H.adjust_skillrank(/datum/skill/combat/unarmed, 3, TRUE)
	H.adjust_skillrank(/datum/skill/combat/bows, 5, TRUE)
	H.adjust_skillrank(/datum/skill/combat/crossbows, 5, TRUE)
	H.adjust_skillrank(/datum/skill/craft/crafting, 2, TRUE)
	H.adjust_skillrank(/datum/skill/craft/carpentry, 2, TRUE)
	H.adjust_skillrank(/datum/skill/misc/reading, 3, TRUE)
	H.adjust_skillrank(/datum/skill/misc/athletics, 3, TRUE)
	H.adjust_skillrank(/datum/skill/misc/climbing, 2, TRUE)
	H.adjust_skillrank(/datum/skill/misc/lockpicking, 4, TRUE)
	H.adjust_skillrank(/datum/skill/craft/traps, 3, TRUE)
	H.adjust_skillrank(/datum/skill/misc/tracking, 3, TRUE)
	H.adjust_skillrank(/datum/skill/craft/engineering, 2, TRUE)
	H.adjust_skillrank(/datum/skill/craft/blacksmithing, 2, TRUE)
	H.adjust_skillrank(/datum/skill/craft/armorsmithing, 2, TRUE)
	H.adjust_skillrank(/datum/skill/craft/weaponsmithing, 2, TRUE)
	H.adjust_skillrank(/datum/skill/craft/smelting, 2, TRUE)
	H.adjust_skillrank(/datum/skill/labor/lumberjacking, 4, TRUE)
	H.adjust_skillrank(/datum/skill/labor/mining, 4, TRUE) //to dig everywhere
	belt =	/obj/item/storage/belt/rogue/leather
	head = /obj/item/clothing/head/roguetown/helmet/kettle
	pants = /obj/item/clothing/under/roguetown/trou/leather
	shirt = /obj/item/clothing/suit/roguetown/shirt/shortshirt/random
	shoes = /obj/item/clothing/shoes/roguetown/boots/armor //toe safety first
	mask = /obj/item/clothing/mask/rogue/facemask/steel
	neck = /obj/item/clothing/neck/roguetown/coif
	gloves = /obj/item/clothing/gloves/roguetown/angle/grenzelgloves/blacksmith
	armor = /obj/item/clothing/suit/roguetown/armor/islandworkingarmor
	backr = /obj/item/storage/backpack/rogue/backpack/bagpack
	backl = /obj/item/rogueweapon/pick/steel
	beltr = /obj/item/rogueweapon/stoneaxe/pioneer //its an axe yes
	beltl = /obj/item/flashlight/flare/torch/lantern
	backpack_contents = list(
		/obj/item/lockpickring/mundane = 1,
		/obj/item/flashlight/flare/torch = 1,
		/obj/item/restraints/legcuffs/beartrap = 2,
		/obj/item/flint = 1,
		/obj/item/rogueore/coal=1,
		/obj/item/rogueore/iron=1,
		/obj/item/rogueweapon/hammer/iron = 1,
		/obj/item/rogueweapon/tongs = 1
	)
	id = /obj/item/scomstone/mattcoin
	H.change_stat("strength", 2) // to be sure they can mine/smith without problems
	H.change_stat("constitution", 1) // use armor get peel-ed idiot
	H.change_stat("endurance", 2) // no speed get peel-ed, idiot
	H.change_stat("perception", 2)
	H.change_stat("intelligence", 4)
	H.change_stat("fortune", 2)
	ADD_TRAIT(H, TRAIT_MEDIUMARMOR, TRAIT_GENERIC)

