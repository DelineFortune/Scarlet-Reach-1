// ============================================================
//  DeLineFortune — Retaliation Mark (бафф-возвратка)
//  Эффект на владельце: входящий урон по нему снижается, а атакующий
//  получает отражение в 2× исходного урона. Работает через on_pre_damage().
// ============================================================

#define RETAL_MARK_FILTER "retaliation_mark_outline"

// ---------- HUD alert ----------
/atom/movable/screen/alert/status_effect/retaliation_mark
    name = "Retaliation"
    desc = "Incoming harm is tempered, and returned twofold."
    icon_state = "stressvg" // замени на свой при желании

// ---------- СТАТУС-ЭФФЕКТ ----------
/datum/status_effect/retaliation_mark
    id = "retaliation_mark"
    alert_type = /atom/movable/screen/alert/status_effect/retaliation_mark
    status_type = STATUS_EFFECT_REFRESH          // повторное наложение обновляет длительность
    duration = 0                                 // живое оставшееся время (ставим в on_apply)
    var/base_duration = 30 SECONDS               // базовая длительность

    // Параметры механики
    var/reduce_factor = 0.5                      // сколько ПО ПОЛУЧИТ владелец (0.5 = 50%)
    var/reflect_mult  = 2.0                      // во сколько раз вернуть атакующему (2.0 = 200%)
    var/_guard = FALSE                           // защита от рекурсии в on_pre_damage

/datum/status_effect/retaliation_mark/on_apply()
    . = ..()
    if(!.) return
    if(!duration) // первичное применение
        duration = base_duration
    if(!owner.get_filter(RETAL_MARK_FILTER))
        owner.add_filter(RETAL_MARK_FILTER, 2, list("type"="outline","color"="#ffb14d","alpha"=80,"size"=1))
    to_chat(owner, span_notice("A retaliatory ward settles over me."))
    playsound(owner, 'sound/magic/whiteflame.ogg', 55, FALSE)
    return TRUE

/datum/status_effect/retaliation_mark/refresh()
    // обновляем/продлеваем эффект до базовой длительности
    duration = max(duration, base_duration)
    return ..()

/datum/status_effect/retaliation_mark/on_remove()
    owner.remove_filter(RETAL_MARK_FILTER)
    playsound(owner, 'sound/items/firesnuff.ogg', 55, FALSE)
    return ..()

/// Центральный прок: модифицирует входящий урон и отражает его.
/// ДОЛЖЕН вызываться твоей damage-точкой до реального применения урона.
/// amount — входящий урон, damtype — тип урона, src_attacker — кто бил (может быть null).
/// Возвращает урон, который ПОЛУЧИТ ВЛАДЕЛЕЦ.
/datum/status_effect/retaliation_mark/proc/on_pre_damage(amount, damtype, atom/src_attacker)
    if(_guard || amount <= 0)
        return amount

    // уменьшаем урон владельцу
    var/to_owner = round(amount * reduce_factor)

    // отражаем на атакующего (только живым целям), с защитой от циклов
    if(ismob(src_attacker))
        var/mob/living/att = src_attacker
        if(att && !QDELETED(att) && att != owner && !att.reflect_bypass)
            _guard = TRUE
            var/reflect_amount = round(amount * reflect_mult)
            if(reflect_amount > 0)
                att.apply_reflected_damage(reflect_amount, damtype, owner)
                owner.visible_message(
                    span_warning("[owner] lashes back with retaliatory force!"),
                    span_warning("My ward retaliates!")
                )
            _guard = FALSE

    return to_owner


// ---------- НИЗКОУРОВНЕВЫЕ «СЫРЫЕ» ПРОКИ ДЛЯ ОТРАЖЕНИЯ ----------
// Эти проки нужны, чтобы отражённый урон не перехватывался эффектами ещё раз.

/mob/living
    /// bypass-флаг, чтобы отражённый урон не триггерил новые отражения/делители
    var/tmp/reflect_bypass = FALSE

/// Прямое нанесение отражённого урона по мобу без последующих отражений.
/mob/living/proc/apply_reflected_damage(amount, damtype, atom/source)
    reflect_bypass = TRUE
    switch(damtype)
        if(BRUTE) adjustBruteLoss(amount)
        if(BURN)  adjustFireLoss(amount)
        if(TOX)   adjustToxLoss(amount)
        if(OXY)   adjustOxyLoss(amount)
        else      apply_damage(amount, damtype)
    reflect_bypass = FALSE


// ---------- (ОПЦИОНАЛЬНО) ХЕЛПЕР, ЕСЛИ ХОЧЕШЬ ДЕРГАТЬ ИЗ ЦЕНТРАЛЬНОЙ ТОЧКИ ----------
// Если уже добавил вызов эффекта в своём damage proc — это можно не использовать.
/mob/living/proc/_retal_pre_damage(delta, damtype, atom/source)
    if(delta <= 0 || reflect_bypass)
        return delta
    var/datum/status_effect/retaliation_mark/R = has_status_effect(/datum/status_effect/retaliation_mark)
    if(R)
        delta = R.on_pre_damage(delta, damtype, source)
    return delta


// ---------- СПЕЛЛ (touch) ДЛЯ НАЛОЖЕНИЯ БАФФА ----------
/obj/effect/proc_holder/spell/targeted/touch/retaliation_mark
    name = "Retaliation"
    desc = "Bless a creature with a ward that halves incoming harm and returns it twofold to the attacker."
    school = "abjuration"
    clothes_req = FALSE
    chargedrain = 0
    chargetime = 10
    releasedrain = 6
    devotion_cost = 6
    associated_skill = /datum/skill/magic/holy
    hand_path = /obj/item/melee/touch_attack/retaliation_mark

/obj/item/melee/touch_attack/retaliation_mark
    name = "retaliatory touch"
    icon = 'icons/mob/roguehudgrabs.dmi'
    icon_state = "intouch"

/obj/item/melee/touch_attack/retaliation_mark/afterattack(atom/target, mob/living/carbon/human/user, proximity)
    if(!isliving(target))
        to_chat(user, span_warning("I must touch a living target."))
        return
    var/mob/living/L = target
    if(!L.Adjacent(user))
        to_chat(user, span_info("I must be next to [L]."))
        return

    var/datum/status_effect/retaliation_mark/M = L.has_status_effect(/datum/status_effect/retaliation_mark)
    if(M)
        // обновим длительность, если уже висит
        M.refresh()
    else
        M = L.apply_status_effect(/datum/status_effect/retaliation_mark)

    if(M)
        // при желании можно на лету подкрутить параметры:
        // M.reduce_factor = 0.5
        // M.reflect_mult  = 2.0
        // M.base_duration = 30 SECONDS
        user.visible_message(
            span_notice("[user] traces a burning sigil upon [L]."),
            span_notice("I bind [L] with a retaliatory ward.")
        )
        playsound(user, 'sound/magic/holycharging.ogg', 70, FALSE)
        user.devotion?.update_devotion(-5)
        qdel(src)
