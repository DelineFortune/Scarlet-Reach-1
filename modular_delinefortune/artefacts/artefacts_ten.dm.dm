#define MALUM_ALLOWED_INGOTS list( \
    /obj/item/ingot/steel, \
    /obj/item/ingot/iron, \
    /obj/item/ingot/aalloy, \
    /obj/item/ingot/purifiedaalloy \
)

/*============
Malum's tool
============*/
/*
- A universal hammer-tool that can do everything. Blacksmiths will kill you for this.
*/

/obj/item/rogueweapon/hammer/artefact/malum
	force = 21
	possible_item_intents = list(/datum/intent/mace/strike, /datum/intent/mace/smash, /datum/intent/forge,  /datum/intent/smelt)
	name = "Malum's tool"
	desc = "A blessed hammer that forges fate as it pleases."
	icon_state = "hammer"
	icon = 'icons/roguetown/weapons/tools.dmi'
	sharpness = IS_BLUNT
	//dropshrink = 0.8
	wlength = 10
	slot_flags = ITEM_SLOT_HIP
	w_class = WEIGHT_CLASS_NORMAL
	associated_skill = /datum/skill/combat/maces
	smeltresult = /obj/item/ash
	grid_width = 32
	grid_height = 64


/datum/intent/forge //FUCK AUTISTIC ANVIL SMASH allows you to create 1 bar items on the spot
    name = "forge"
    icon_state = "inforge"
    chargetime = 0
    noaa = TRUE
    candodge = FALSE
    canparry = FALSE
    misscost = 0
    no_attack = TRUE
    releasedrain = 0
    blade_class = BCLASS_PUNCH


/datum/intent/smelt // Malum's tool intent ok allows you to smelt items on the spot if they made of IRON STEEL and that shitty metal from skeletons
	name = "smelt"
	icon_state = "insmelt"
	chargetime = 0
	noaa = TRUE
	candodge = FALSE
	canparry = FALSE
	misscost = 0
	no_attack = TRUE
	releasedrain = 0
	blade_class = BCLASS_PUNCH


//shit made helper

proc/_malum_recipe_requires_extras(datum/anvil_recipe/R)
	if(!R) return FALSE
	if(ispath(R:needed_item)) return TRUE
	var/ai = R:additional_items
	if(ispath(ai)) return TRUE
	if(islist(ai) && length(ai) > 0) return TRUE
	return FALSE

/obj/item/rogueweapon/hammer/artefact/malum/afterattack(atom/target, mob/user, proximity_flag, click_parameters)
	. = ..()
	if(!proximity_flag || !user || !user.used_intent)
		return

	// ===== FORGE===== //only one bar items you retard
	if(istype(user.used_intent, /datum/intent/forge))
		if(istype(target, /obj/machinery/anvil))
			var/obj/machinery/anvil/A = target
			if(A.hingot && istype(A.hingot, /obj/item/ingot))
				var/obj/item/ingot/ing_on_anvil = A.hingot
				A.hingot = null
				A.update_icon()
				ing_on_anvil.forceMove(src)
				forge_open_category_menu(user, ing_on_anvil)
				return
			to_chat(user, span_warning("Place an ingot on the anvil or click an ingot directly."))
			return

		if(!isitem(target))
			to_chat(user, span_warning("I need to click an ingot to forge."))
			return
		var/obj/item/ingot/ing = target
		if(!istype(ing, /obj/item/ingot))
			to_chat(user, span_warning("[target] is not an ingot."))
			return

		ing.forceMove(src)
		forge_open_category_menu(user, ing)
		return

	// ===== SMELT =====
	if(istype(user.used_intent, /datum/intent/smelt))
		if(!isitem(target))
			to_chat(user, span_warning("I need an item to smelt down."))
			return

		var/obj/item/I2 = target
		var/ok_surface = isturf(I2.loc) || istype(I2.loc, /obj/machinery/anvil)
		if(!ok_surface)
			to_chat(user, span_warning("Place [I2] down on the ground or an anvil first."))
			return

		var/smeltpath = I2.smeltresult
		if(!ispath(smeltpath))
			to_chat(user, span_warning("[I2] cannot be smelted."))
			return

		var/list/allowed = list(
			/obj/item/ingot/steel,
			/obj/item/ingot/iron,
			/obj/item/ingot/aalloy,
			/obj/item/ingot/purifiedaalloy
		)
		if(!(smeltpath in allowed))
			to_chat(user, span_warning("[I2] is not suitable for this hammer's smelting."))
			return

		var/yield = 1

		user.visible_message(
			span_info("[user] begins smelting down \the [I2] with [src]."),
			span_info("I start smelting \the [I2]...")
		)
		playsound(get_turf(I2), 'sound/items/bsmith3.ogg', 70, FALSE)

		if(!do_after(user, 10 SECONDS, target = I2))
			to_chat(user, span_warning("The smelting is interrupted!"))
			return
		if(QDELETED(I2) || (!isturf(I2.loc) && !istype(I2.loc, /obj/machinery/anvil)))
			to_chat(user, span_warning("The smelting cannot be completed."))
			return

		var/turf/T = get_turf(I2)
		qdel(I2)

		var/obj/item/last_ingot = null
		for(var/i = 1, i <= yield, i++)
			last_ingot = new smeltpath(T)

		user.visible_message(
			span_notice("[user] completes the smelting, revealing [yield] [last_ingot ? last_ingot.name : "ingot"](s)."),
			span_notice("The smelting is done.")
		)
		playsound(T, 'sound/items/bsmith4.ogg', 70, FALSE)
		user.changeNext_move(CLICK_CD_INTENTCAP)
		return

// CRAFT STARTTS HERE //

/obj/item/rogueweapon/hammer/artefact/malum/proc/forge_open_category_menu(mob/user, obj/item/ingot/ing)
	var/list/by_cat = list(
		"Armor"     = list(),
		"Weapons"   = list(),
		"Tools"     = list(),
		"Valuables" = list()
	)

	for(var/datum/anvil_recipe/R in GLOB.anvil_recipes)
		if(!ispath(R.req_bar) || !istype(ing, R.req_bar))
			continue

		if(_malum_recipe_requires_extras(R))
			continue

		if(!ispath(R.created_item))
			continue

		var/name = R.name ? R.name : "[R.created_item]"
		if(istype(R, /datum/anvil_recipe/armor))
			by_cat["Armor"][name] = R.type
		else if(istype(R, /datum/anvil_recipe/weapons))
			by_cat["Weapons"][name] = R.type
		else if(istype(R, /datum/anvil_recipe/tools))
			by_cat["Tools"][name] = R.type
		else if(istype(R, /datum/anvil_recipe/valuables))
			by_cat["Valuables"][name] = R.type

	var/total = 0
	for(var/k in by_cat)
		total += length(by_cat[k])

	if(total <= 0)
		ing.forceMove(get_turf(src))
		to_chat(user, span_warning("No single-bar recipes for [ing.name]."))
		return

	var/contents = "<center><b>Malum's Tool — Instant Forge</b><br>Consumed: [ing.name]</center><hr>"

	for(var/section in list("Armor","Weapons","Tools","Valuables"))
		var/list/map = by_cat[section]
		if(!length(map))
			continue

		contents += "<b>[section]</b><br>"

		var/list/names = list()
		for(var/n in map)
			names += n
		names = sortList(names)

		for(var/n in names)
			var/rec_type = map[n]
			var/href_make = "?src=[REF(src)];forgemake=[rec_type];ing=[REF(ing)]"
			contents += "<a href='[href_make]'>[n]</a><br>"

		contents += "<br>"

	var/datum/browser/popup = new(user, "MALUMFORGE", "", 460, 560)
	popup.set_content(contents)
	popup.open()

/obj/item/rogueweapon/hammer/artefact/malum/proc/forge_do_craft(mob/user, obj/item/ingot/ing, rec_type)
	if(!istype(ing) || QDELETED(ing))
		to_chat(user, span_warning("Where did the ingot go?"))
		return
	if(!ispath(rec_type, /datum/anvil_recipe))
		to_chat(user, span_warning("That recipe is broken."))
		return

	var/datum/anvil_recipe/R = new rec_type

	if(!ispath(R.req_bar) || !istype(ing, R.req_bar) || _malum_recipe_requires_extras(R) || !ispath(R.created_item))
		qdel(R)
		to_chat(user, span_warning("This recipe cannot be made from [ing]."))
		return

	user.visible_message(
		span_info("[user] starts shaping \the [ing] with [src]."),
		span_info("I begin crafting with [ing]...")
	)
	playsound(get_turf(ing), 'sound/items/bsmith3.ogg', 70, FALSE)

	if(!do_after(user, 10 SECONDS, target = ing))
		to_chat(user, span_warning("The crafting is interrupted!"))
		qdel(R)
		return
	if(QDELETED(ing) || !ing.loc)
		to_chat(user, span_warning("The ingot is no longer suitable."))
		qdel(R)
		return

	var/turf/T = get_turf(ing)
	qdel(ing)
	var/obj/item/product = new R.created_item(T)

	user.visible_message(
		span_notice("[user] completes the craft, producing \the [product]."),
		span_notice("I finish crafting.")
	)
	playsound(T, 'sound/items/bsmith4.ogg', 70, FALSE)
	user.changeNext_move(CLICK_CD_INTENTCAP)
	qdel(R)

/obj/item/rogueweapon/hammer/artefact/malum/Topic(href, href_list)
	. = ..()
	if(!usr || !usr.canUseTopic(src, BE_CLOSE))
		return


	if(href_list["forgemake"])
		var/obj/item/ingot/ing = locate(href_list["ing"])
		var/rec_type = text2path(href_list["forgemake"])
		if(ing && ispath(rec_type, /datum/anvil_recipe))
			forge_do_craft(usr, ing, rec_type)
		return

/*============
Necra's Censer (by ARefrigerator)
============*/
/*
- Cleans in an area around the person after
  a do_after call, infinite uses. Should aid
  the morticians with cleaning the town.
*/

obj/item/artefact/necra_censer
	name = "Necra's censer"
	desc = "A small bronze censer that expels an otherworldly mist."
	icon = 'icons/roguetown/items/misc.dmi'
	icon_state ="necra_censer"
	lefthand_file = 'icons/mob/inhands/items_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/items_righthand.dmi'
	item_state = "necra_censer"
	throw_speed = 3
	throw_range = 7
	throwforce = 4
	//hitsound = 'sound/blank.ogg'
	sellprice = 10 // Shouldn't be worth a lot in world
	dropshrink = 0.6
	grid_width = 32
	grid_height = 64

obj/item/artefact/necra_censer/attack_self(mob/user)
	if(do_after(user, 3 SECONDS))
		playsound(user.loc,  'sound/items/censer_use.ogg', 100)
		user.visible_message(span_info("[user.name] lifts up their arm and swings the chain on \the [name] around lightly."))
		var/datum/effect_system/smoke_spread/smoke/necra_censer/S = new
		S.set_up(3, user.loc)
		S.start()


/*=========================================
  Dendor’s Endless Hose — additive mode
  Click soil to add ±100 water/nutrition,
  optional bless, and growth modes incl. KILL
=========================================*/

/obj/item/artefact/dendor_hose //bless your tree with its piss
	name = "Dendor's Endless Hose"
	desc = "A living crook of wood that bends soil to the Treefather’s will. Click soil to add ±100 water/nutriment, bless, or affect growth." //Dendor's piss
	icon = 'icons/roguetown/items/misc.dmi'
	icon_state = "necra_censer"
	lefthand_file = 'icons/mob/inhands/items_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/items_righthand.dmi'
	item_state = "staff"
	w_class = WEIGHT_CLASS_NORMAL
	slot_flags = ITEM_SLOT_BACK|ITEM_SLOT_HIP
	grid_width = 32
	grid_height = 64

	//  -1 = -100, 0 = off, 1 = +100
	var/water_step_state = 1
	var/nutri_step_state = 1

	var/auto_bless = TRUE

	// its "none" | "mature" | "produce" | "kill", retard
	var/growth_mode = "none"

	// helper text
/obj/item/artefact/dendor_hose/examine(mob/user)
	. = ..()
	. += "<hr><span class='notice'><b>Additive settings</b></span><br>"
	. += "Water: <b>[hose_state_text(water_step_state)]</b> per click<br>"
	. += "Nutrition: <b>[hose_state_text(nutri_step_state)]</b> per click<br>"
	. += "Bless: <b>[auto_bless ? "ON" : "OFF"]</b><br>"
	. += "Growth: <b>[uppertext(growth_mode)]</b><br>"
	. += "<span class='info'>Use in hand to configure.</span>"

/obj/item/artefact/dendor_hose/proc/hose_state_text(state)
	if(state == 1)  return "+100"
	if(state == -1) return "-100"
	return "OFF"

/obj/item/artefact/dendor_hose/attack_self(mob/user)
	open_config_ui(user)

/obj/item/artefact/dendor_hose/proc/open_config_ui(mob/user)
	var/contents = "<center><b>Dendor’s Endless Hose — Settings</b></center><hr>"

	contents += "<b>Water delta per click</b><br>"
	contents += "<a href='?src=[REF(src)];cyclestep=water'>[hose_state_text(water_step_state)]</a><br><br>"

	contents += "<b>Nutrition delta per click</b><br>"
	contents += "<a href='?src=[REF(src)];cyclestep=nutri'>[hose_state_text(nutri_step_state)]</a><br><br>"

	contents += "<b>Bless</b>: <a href='?src=[REF(src)];toggle=bless'>[auto_bless ? "ON" : "OFF"]</a><br><br>"

	contents += "<b>Growth</b><br>"
	contents += "Mode: "
	var/list/modes = list("none","mature","produce","kill")
	for(var/m in modes)
		if(m == growth_mode)
			contents += " <b>[uppertext(m)]</b> "
		else
			contents += " <a href='?src=[REF(src)];mode=[m]'>[uppertext(m)]</a> "
	contents += "<hr><center><i>Click soil to apply.</i></center>"

	var/datum/browser/popup = new(user, "DENDOR_HOSE", "", 420, 340)
	popup.set_content(contents)
	popup.open()

/obj/item/artefact/dendor_hose/Topic(href, href_list)
	. = ..()
	if(!usr || !usr.canUseTopic(src, BE_CLOSE))
		return

	// im going to keep a comment here because i know some of you stupid retards that going to numberfuck everything +1 -> 0 -> -1 -> +1
	if(href_list["cyclestep"])
		var/what = href_list["cyclestep"]
		if(what == "water")
			if(water_step_state == 1) water_step_state = 0
			else if(water_step_state == 0) water_step_state = -1
			else water_step_state = 1
		else if(what == "nutri")
			if(nutri_step_state == 1) nutri_step_state = 0
			else if(nutri_step_state == 0) nutri_step_state = -1
			else nutri_step_state = 1
		open_config_ui(usr)
		return

	if(href_list["toggle"] == "bless")
		auto_bless = !auto_bless
		open_config_ui(usr)
		return

	if(href_list["mode"])
		var/m = lowertext(href_list["mode"])
		if(m in list("none","mature","produce","kill"))
			growth_mode = m
		open_config_ui(usr)
		return

/obj/item/artefact/dendor_hose/afterattack(atom/target, mob/user, proximity_flag, click_parameters)
	. = ..()
	if(!proximity_flag || !istype(target, /obj/structure/soil))
		return
	var/obj/structure/soil/S = target
	apply_additives_to_soil(S, user)

/obj/item/artefact/dendor_hose/proc/apply_additives_to_soil(obj/structure/soil/S, mob/user)
	var/w_delta = water_step_state * 100
	if(w_delta)
		S.adjust_water(w_delta)

	var/n_delta = nutri_step_state * 100
	if(n_delta)
		S.adjust_nutrition(n_delta)

	if(auto_bless)
		S.bless_soil()

	if(S.plant)
		switch(growth_mode)
			if("mature")
				if(!S.plant_dead && !S.matured)
					var/miss = max(S.plant.maturation_time - S.growth_time, 0)
					if(miss > 0)
						S.add_growth(miss)
			if("produce")
				if(!S.plant_dead)
					if(!S.matured)
						var/miss2 = max(S.plant.maturation_time - S.growth_time, 0)
						if(miss2 > 0)
							S.add_growth(miss2)
					if(!S.produce_ready)
						var/miss_prod = max(S.plant.produce_time - S.produce_time, 0)
						if(miss_prod > 0)
							S.add_growth(miss_prod)
			if("kill")
				S.plant_dead = TRUE
				S.plant_health = 0
				S.produce_ready = FALSE
				S.update_icon()
				user.visible_message(
					span_warning("[user] withers the crop with a grim decree."),
					span_warning("The life is snuffed out.")
				)

	if(growth_mode != "kill")
		user.visible_message(
			span_green("[user] tends the soil with the Endless Hose."),
			span_good("The soil yields to my will.")
		)
	playsound(S, 'sound/foley/waterwash (1).ogg', 80, FALSE)

/*==============================
  Noc's Phylactery 
  - Binds to a target by sampling blood (30s) but honestly its just scan_process
  - Use in hand: shows target & your XYZ + distance
==============================*/

/obj/item/artefact/noc_phylactery
	name = "Noc's Phylactery"
	desc = "A lunar phylactery of Noc: a crystal vessel that binds a drop of blood to a path under the moon's gaze. In elder nights, mages used such vessels to hunt apostates who abused or stole arcane knowledge."
	icon = 'icons/roguetown/items/misc.dmi'
	icon_state = "phylactery"
	item_state = "phylactery"
	w_class = WEIGHT_CLASS_TINY
	var/bound = FALSE
	var/target_ref = null
	var/target_name = null
	var/bound_time = 0
	var/binding = FALSE
	var/pending_target_name = null

/obj/item/artefact/noc_phylactery/examine(mob/user)
	. = ..()
	if(bound)
		. += "<hr><span class='notice'>It hums softly — someone's blood is bound within.</span><br>"
		. += "Bound to: <b>[target_name ? target_name : "unknown"]</b><br>"
	else if(binding)
		. += "<hr><span class='warning'>The glass warms in your hand — attunement in progress...</span><br>"
	else
		. += "<hr><span class='info'>Use on a living being to attune by blood (30 seconds).</span><br>"


/obj/item/artefact/noc_phylactery/attack_self(mob/user)
	if(!bound)
		to_chat(user, span_info("The phylactery is inert. Bind it to someone first."))
		return

	var/mob/living/T = get_target_mob()
	var/turf/ut = get_turf(user)
	if(!ut)
		to_chat(user, span_warning("I cannot sense my own footing."))
		return

	var/tx = "?"
	var/ty = "?"
	var/tz = "?"
	var/distance_tiles = -1

	if(T && !QDELETED(T))
		var/turf/tt = get_turf(T)
		if(tt)
			tx = "[tt.x]"
			ty = "[tt.y]"
			tz = "[tt.z]"
			distance_tiles = get_dist(ut, tt)
		else
			to_chat(user, span_warning("The phylactery finds the blood, but not the ground beneath them..."))
	else
		to_chat(user, span_warning("The blood-sample feels dull — perhaps the vessel is gone."))

	to_chat(user, span_notice("-- Noc's Phylactery --"))
	to_chat(user, span_info("Target [target_name ? target_name : "unknown"]: X=[tx], Y=[ty], Z=[tz]"))
	to_chat(user, span_info("You: X=[ut.x], Y=[ut.y], Z=[ut.z]"))
	if(distance_tiles >= 0)
		to_chat(user, span_info("Approx. distance: [distance_tiles] tiles"))
	playsound(user, 'sound/magic/churn.ogg', 50, FALSE)

/obj/item/artefact/noc_phylactery/afterattack(atom/target, mob/user, proximity_flag, click_parameters)
	. = ..()
	if(!proximity_flag)
		return
	if(binding)
		to_chat(user, span_warning("It is already drawing a sample..."))
		return
	if(!isliving(target))
		to_chat(user, span_warning("It needs living blood to bind."))
		return

	var/mob/living/L = target
	start_binding(L, user)

/obj/item/artefact/noc_phylactery/proc/start_binding(mob/living/L, mob/user)
	if(binding)
		return
	binding = TRUE

	pending_target_name = get_true_name(L) //John Unknown Unknown

	user.visible_message(
		span_info("[user] presses the phylactery to [pending_target_name]; dim runes kindle along the filigree."),
		span_notice("I begin the attunement, drawing a blood sample from [pending_target_name]...")
	)
	playsound(get_turf(user), 'sound/magic/churn.ogg', 60, FALSE)

	if(!do_after(user, 30 SECONDS, target = L))
		to_chat(user, span_warning("The attunement is interrupted. The glass cools down."))
		binding = FALSE
		pending_target_name = null
		return

	if(QDELETED(src) || QDELETED(L) || QDELETED(user))
		binding = FALSE
		pending_target_name = null
		return
	if(get_dist(user, L) > 1) // yes im aware but no Adjacent()
		to_chat(user, span_warning("The subject slipped away at the final step."))
		binding = FALSE
		pending_target_name = null
		return

	var/success = bind_to_target(L, pending_target_name)
	if(success)
		user.visible_message(
			span_notice("A crimson thread curls into the crystal; the phylactery thrums softly."),
			span_good("It is done. The blood remembers.")
		)
		playsound(get_turf(user), 'sound/magic/whiteflame.ogg', 60, FALSE)
	else
		to_chat(user, span_warning("The charm fizzles and fails to hold."))
	binding = FALSE
	pending_target_name = null

/obj/item/artefact/noc_phylactery/proc/bind_to_target(mob/living/L, cached_name = null)
	target_ref = REF(L)
	target_name = cached_name ? cached_name : get_true_name(L)
	bound_time = world.time
	bound = TRUE
	return TRUE

/obj/item/artefact/noc_phylactery/proc/get_target_mob()
	if(!target_ref)
		return null
	var/mob/living/L = locate(target_ref)
	return L

/obj/item/artefact/noc_phylactery/proc/get_true_name(mob/living/L)
	if(ishuman(L))
		var/mob/living/carbon/human/H = L
		return H.real_name ? H.real_name : (H.name ? H.name : "someone")
	return L.name ? L.name : "someone"

/obj/item/artefact/noc_phylactery/attack(mob/living/M, mob/user)
	if(isliving(M))
		start_binding(M, user)
	return


// --------------------------
// Artefact: Eora's Heart
// --------------------------

/*========================================
  Eora's Heart — partner viewer
  -----------------------------------------
  • Use on self: shows your unique partners (names) this round
  • Use on target: shows their unique partners (names) this round
========================================*/

/obj/item/artefact/eora_heart
	name = "Eora's Heart"
	desc = "A velvet heart dedicated to Eora. It remembers the names of bonds formed this round."
	icon = 'icons/roguetown/items/misc.dmi'
	icon_state = "eora_heart"
	item_state = "eora_heart"
	w_class = WEIGHT_CLASS_TINY
	var/last_used = 0

/obj/item/artefact/eora_heart/examine(mob/user)
	. = ..()
	. += "<hr><span class='info'>Use in hand: show your unique partners (names) this round.</span><br>"
	. += "<span class='info'>Use on a player: show their unique partners (names) this round.</span><br>"

/obj/item/artefact/eora_heart/attack_self(mob/user)
	if(world.time < last_used + 300)
		to_chat(user, span_warning("The heart is quiet. Give it a moment."))
		return
	last_used = world.time

	if(!ishuman(user) || !user.client)
		to_chat(user, span_warning("The heart needs a living player to answer."))
		return

	var/mob/living/carbon/human/H = user
	var/cnt = eora_get_partner_count(H)
	var/list/names = eora_get_partner_names(H)

	to_chat(user, span_notice("Eora's Whisper: You have <b>[cnt]</b> unique partner[cnt==1 ? "" : "s"] this round."))
	if(names && names.len)
		to_chat(user, "<span class='info'>Names:</span>")
		for(var/N in names)
			to_chat(user, " • [html_encode(N)]")
	else
		to_chat(user, "<span class='info'>No names to show.</span>")

	playsound(user, 'sound/magic/whiteflame.ogg', 50, FALSE)

/obj/item/artefact/eora_heart/afterattack(atom/target, mob/user, proximity_flag, click_parameters)
	. = ..()
	if(!proximity_flag) return

	if(world.time < last_used + 300)
		to_chat(user, span_warning("The heart is quiet. Give it a moment."))
		return
	last_used = world.time

	if(!isliving(target))
		to_chat(user, span_warning("The heart only answers for living beings."))
		return
	if(!ishuman(target) || !target:client)
		to_chat(user, span_warning("The heart only tallies players."))
		return

	var/mob/living/carbon/human/H = target
	var/cnt = eora_get_partner_count(H)
	var/list/names = eora_get_partner_names(H)

	to_chat(user, span_notice("Eora's Whisper: [html_encode(H.name)] has <b>[cnt]</b> unique partner[cnt==1 ? "" : "s"] this round."))
	if(names && names.len)
		to_chat(user, "<span class='info'>Names:</span>")
		for(var/N in names)
			to_chat(user, " • [html_encode(N)]")
	else
		to_chat(user, "<span class='info'>No names to show.</span>")

	playsound(user, 'sound/magic/whiteflame.ogg', 50, FALSE)


// --------------------------
// Round-local registries
// --------------------------

var/global/list/EORA_PARTNERS_BY_ID = list()
var/global/list/EORA_ID_NAME = list()


// --------------------------
// Helper procs (registries)
// --------------------------

/proc/eora_get_round_id(mob/living/carbon/human/H)
	if(!H) return null
	if(H.mind) return REF(H.mind)
	return REF(H)

/proc/eora_update_name(mob/living/carbon/human/H)
	if(!H) return
	var/id = eora_get_round_id(H)
	if(!id) return
	var/display = H.real_name ? H.real_name : H.name
	if(display && length(display))
		EORA_ID_NAME[id] = "[display]"

/proc/eora_lookup_name_by_id(id)
	if(!id) return "Unknown"

	if(islist(GLOB?.human_list))
		for(var/mob/living/carbon/human/H in GLOB.human_list)
			if(eora_get_round_id(H) == id)
				return H.real_name ? H.real_name : H.name
	else
		for(var/mob/living/carbon/human/H in world)
			if(eora_get_round_id(H) == id)
				return H.real_name ? H.real_name : H.name

	if(EORA_ID_NAME[id])
		return "[EORA_ID_NAME[id]]"

	return "Unknown"

/proc/eora_register_consensual_pair(mob/living/carbon/human/A, mob/living/carbon/human/B)
	if(!A || !B) return
	if(!A.client || !B.client) return
	if(A == B) return

	var/idA = eora_get_round_id(A)
	var/idB = eora_get_round_id(B)
	if(!idA || !idB) return

	if(!EORA_PARTNERS_BY_ID[idA]) EORA_PARTNERS_BY_ID[idA] = list()
	if(!EORA_PARTNERS_BY_ID[idB]) EORA_PARTNERS_BY_ID[idB] = list()

	var/list/LA = EORA_PARTNERS_BY_ID[idA]
	var/list/LB = EORA_PARTNERS_BY_ID[idB]

	LA[idB] = TRUE
	LB[idA] = TRUE

	eora_update_name(A)
	eora_update_name(B)

/proc/eora_get_partner_count(mob/living/carbon/human/H)
	if(!H || !H.client) return 0
	var/id = eora_get_round_id(H)
	if(!id) return 0
	var/list/L = EORA_PARTNERS_BY_ID[id]
	if(!islist(L)) return 0
	var/c = 0
	for(var/_ in L) c++
	return c

/proc/eora_get_partner_names(mob/living/carbon/human/H)
	var/list/names = list()
	if(!H || !H.client) return names
	var/id = eora_get_round_id(H)
	if(!id) return names

	var/list/L = EORA_PARTNERS_BY_ID[id]
	if(!islist(L)) return names

	for(var/pid in L)
		var/n = eora_lookup_name_by_id(pid)
		if(n && !names.Find(n))
			names += n

	return sortList(names)
