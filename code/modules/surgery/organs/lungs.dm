/obj/item/organ/lungs
	var/failed = FALSE
	var/operated = FALSE	//whether we can still have our damages fixed through surgery
	name = "lungs"
	icon_state = "lungs"
	zone = BODY_ZONE_CHEST
	slot = ORGAN_SLOT_LUNGS
	gender = PLURAL
	w_class = WEIGHT_CLASS_SMALL

	healing_factor = STANDARD_ORGAN_HEALING
	decay_factor = STANDARD_ORGAN_DECAY

	high_threshold_passed = "<span class='warning'>I feel some sort of constriction around my chest as my breathing becomes shallow and rapid.</span>"
	now_fixed = "<span class='warning'>My lungs seem to once again be able to hold air.</span>"
	high_threshold_cleared = "<span class='info'>The constriction around my chest loosens as my breathing calms down.</span>"

	sellprice = 20

/obj/item/organ/lungs/on_life()
	..()
	if((!failed) && ((organ_flags & ORGAN_FAILING)))
		if(owner.stat == CONSCIOUS)
			owner.visible_message("<span class='danger'>[owner] grabs [owner.p_their()] throat, struggling for breath!</span>", \
								"<span class='danger'>I suddenly feel like you can't breathe!</span>")
		failed = TRUE
	else if(!(organ_flags & ORGAN_FAILING))
		failed = FALSE
	return

/obj/item/organ/lungs/prepare_eat()
	var/obj/S = ..()
	return S

/obj/item/organ/lungs/plasmaman
	name = "plasma filter"
	desc = ""
	icon_state = "lungs-plasma"


/obj/item/organ/lungs/slime
	name = "vacuole"
	desc = ""

/obj/item/organ/lungs/golem
	name = "golem aersource"
	desc = "A complex hollow crystal, which courses with air through unknowable means. Steam wisps around it in a vortex."
	icon_state = "lungs-con"
	
/obj/item/organ/lungs/t1
	name = "completed lungs"
	icon_state = "lungs"
	desc = "Immaculate vessels of breath, crafted with precision beyond mortal means. Each inhale feels endless, as if the very sky itself had been pressed into flesh."
	sellprice = 100

/obj/item/organ/lungs/t2
	name = "blessed lungs"
	icon_state = "lungs"
	desc = "Bestowed upon those who swore to inhale even the poisoned winds in Her name. Their breath flows with unnatural vigor, though each exhale whispers of debt unpaid."
	sellprice = 200

/obj/item/organ/lungs/t3
	name = "corrupted lungs"
	icon_state = "lungs"
	desc = "Rotten bellows that drink deep of miasma and ash. They grant breath where none should be drawn, but every gasp binds the bearer tighter to decay. Too potent for mortal frame, they are a heresy, breathing with a forbidden spark of divinity."
	maxHealth = 2 * STANDARD_ORGAN_THRESHOLD
	sellprice = 300

/datum/status_effect/buff/t1lungs
	id = "t1lungs"
	alert_type = /atom/movable/screen/alert/status_effect/buff/t1lungs

/atom/movable/screen/alert/status_effect/buff/t1lungs
	name = "Completed lungs"
	desc = "I have better version of lungs now "

/obj/item/organ/lungs/t1/Insert(mob/living/carbon/M)
	..()
	if(M)
		M.apply_status_effect(/datum/status_effect/buff/t1lungs)
		ADD_TRAIT(M, TRAIT_T1_LUNGS, TRAIT_GENERIC)

/obj/item/organ/lungs/t1/Remove(mob/living/carbon/M, special = 0)
	..()
	if(M.has_status_effect(/datum/status_effect/buff/t1lungs))
		M.remove_status_effect(/datum/status_effect/buff/t1lungs)
		REMOVE_TRAIT(M, TRAIT_T1_LUNGS, TRAIT_GENERIC) //waterbreath, +10% stamina regen, regen delay −2 ticks, sprint drain −1.6 .

/datum/status_effect/buff/t2lungs
	id = "t2lungs"
	alert_type = /atom/movable/screen/alert/status_effect/buff/t2lungs

/atom/movable/screen/alert/status_effect/buff/t2lungs 
	name = "Blessed lungs"
	desc = "A blessed lungs... Maybe"

/obj/item/organ/lungs/t2/Insert(mob/living/carbon/M)
	..()
	if(M)
		M.apply_status_effect(/datum/status_effect/buff/t2lungs)
		ADD_TRAIT(M, TRAIT_T2_LUNGS, TRAIT_GENERIC)


/obj/item/organ/lungs/t2/Remove(mob/living/carbon/M, special = 0)
	..()
	if(M.has_status_effect(/datum/status_effect/buff/t2lungs))
		M.remove_status_effect(/datum/status_effect/buff/t2lungs)
		REMOVE_TRAIT(M, TRAIT_T2_LUNGS , TRAIT_GENERIC) //waterbreath, +20% stamina regen, regen delay −4 ticks, sprint drain −1.2.


/atom/movable/screen/alert/status_effect/buff/t3lungs
	name = "Corrupted lungs"
	desc = "The cursed thing is inside me now."

/datum/status_effect/buff/t3lungs/tick()
    owner.adjustOxyLoss(-5)

/obj/item/organ/lungs/t3/Insert(mob/living/carbon/M)
	..()
	if(M)
		M.apply_status_effect(/datum/status_effect/buff/t3lungs)
		ADD_TRAIT(M, TRAIT_T3_LUNGS, TRAIT_GENERIC)


/obj/item/organ/lungs/t3/Remove(mob/living/carbon/M, special = 0)
	..()
	if(M.has_status_effect(/datum/status_effect/buff/t3lungs))
		M.remove_status_effect(/datum/status_effect/buff/t3lungs)
		REMOVE_TRAIT(M, TRAIT_T3_LUNGS , TRAIT_GENERIC)	//no breath, +30% stamina regen, regen delay −6 ticks, sprint drain −0.8.
