--[[
    JokerDisplay overrides for BalatroRebalanced

    Add this near your other file-loading code in main.lua:

        if JokerDisplay then
            SMODS.load_file("joker_display_overrides.lua")()
        end

    Key naming: confirmed — every key below is just "j_" + whatever string
    you passed to take_ownership (e.g. take_ownership('marble', ...) is
    j_marble, NOT j_marble_joker). Fixed a couple I had wrong last round
    (marble, glass, stone).
]]

local jd_def = JokerDisplay.Definitions

--#region Vampire (j_vampire)
-- Correction from last round: this is fine. Vanilla's own definition is
-- `config = { extra = 0.1, Xmult = 1 }` — extra as a bare number and
-- Xmult at the top level is exactly how the base game stores it, not a
-- structural mistake on your end. Your change (0.1 -> 0.2) is a pure
-- numeric tweak with no shape change, so no override needed here.
--#endregion

--#region Cloud 9 (j_cloud_9)
jd_def["j_cloud_9"] = {
    text = {
        { text = "$", colour = G.C.MONEY },
        { ref_table = "card.joker_display_values", ref_value = "amount", colour = G.C.MONEY }
    },
    calc_function = function(card)
        local nine_tally = card.ability.count or 0
        if G.playing_cards then
            for _, playing_card in ipairs(G.playing_cards) do
                if playing_card:get_id() == 9 then
                    nine_tally = nine_tally + 1
                end
            end
        end
        card.joker_display_values.amount = card.ability.extra * nine_tally
    end
}
--#endregion

--#region Erosion (j_erosion)
-- Using the standard Xmult badge template (border_nodes) instead of plain
-- text — this is what gives the white-on-red bordered look, and defaults
-- to G.C.XMULT for the border colour automatically.
jd_def["j_erosion"] = {
    text = {
        {
            border_nodes = {
                { text = "X" },
                { ref_table = "card.ability.extra", ref_value = "Xmult" }
            }
        }
    }
}
--#endregion

--#region Campfire (j_campfire)
jd_def["j_campfire"] = {
    text = {
        {
            border_nodes = {
                { text = "X" },
                { ref_table = "card.ability.extra", ref_value = "xmult" }
            }
        }
    },
    reminder_text = {
        { ref_table = "card.joker_display_values", ref_value = "target" }
    },
    calc_function = function(card)
        card.joker_display_values.target = card.ability.extra.target or "Joker"
    end,
    style_function = function(card, text, reminder_text, extra)
        if reminder_text and reminder_text.children[1] then
            local target = card.ability.extra.target or "Joker"
            local colour = G.C.RED
            if target == "Planet" then
                colour = G.C.SECONDARY_SET.Planet
            elseif target == "Tarot" then
                colour = G.C.SECONDARY_SET.Tarot
            end
            reminder_text.children[1].config.colour = colour
        end
        return false
    end
}
--#endregion

--#region Satellite (j_satellite)
jd_def["j_satellite"] = {
    text = {
        { text = "$", colour = G.C.MONEY },
        { ref_table = "card.joker_display_values", ref_value = "amount", colour = G.C.MONEY }
    },
    reminder_text = {
        { ref_table = "card.joker_display_values", ref_value = "hand_name", colour = G.C.ORANGE }
    },
    calc_function = function(card)
        local display_hand = card.ability.hand
        if not display_hand and G.GAME and G.GAME.hands then
            local hands = {}
            for hand, data in pairs(G.GAME.hands) do
                if data.visible ~= false then hands[#hands + 1] = hand end
            end
            if #hands > 0 then
                display_hand = pseudorandom_element(hands, pseudoseed('satellite_display'))
            end
        end
        if display_hand then
            local hand = G.GAME.hands[display_hand]
            card.joker_display_values.amount = (hand and hand.level > 0) and hand.level or 0
            card.joker_display_values.hand_name = localize(display_hand, 'poker_hands')
        end
    end
}
--#endregion

--#region Vagabond (j_vagabond)
-- Built-in display was giving a wrong result at your new threshold (extra
-- = 6, up from vanilla's 4) — showing +0 at $5, when it should only be +0
-- once you're above $6. Reading straight from card.ability.extra instead
-- of whatever hardcoded/mismatched comparison the built-in def was using.
jd_def["j_vagabond"] = {
    text = {
        { text = "+", colour = G.C.PURPLE },
        { ref_table = "card.joker_display_values", ref_value = "bonus", colour = G.C.PURPLE }
    },
    calc_function = function(card)
        card.joker_display_values.bonus = (G.GAME.dollars <= card.ability.extra) and 1 or 0
    end
}
--#endregion

--#region Matador (j_matador)
jd_def["j_matador"] = { text = {}, reminder_text = {} }
--#endregion

--#region Fortune Teller (j_fortune_teller)
-- Built-in display was stuck on vanilla's +1 Mult per Tarot used, not
-- reading your extra.mult = 2 change. Reading it directly instead.
jd_def["j_fortune_teller"] = {
    text = {
        { text = "+", colour = G.C.MULT },
        { ref_table = "card.joker_display_values", ref_value = "mult", colour = G.C.MULT }
    },
    calc_function = function(card)
        card.joker_display_values.mult = card.ability.extra.mult *
            (G.GAME.consumeable_usage_total and G.GAME.consumeable_usage_total.tarot or 0)
    end
}
--#endregion

--#region Superposition (j_superposition)
-- Live preview: +1 if the current hand contains an Ace AND qualifies as
-- a Straight, +0 otherwise. Guards against poker_hands['Straight'] being
-- nil (crashed 'next' when nothing scores as a Straight yet).
jd_def["j_superposition"] = {
    text = {
        { text = "+", colour = G.C.PURPLE },
        { ref_table = "card.joker_display_values", ref_value = "bonus", colour = G.C.PURPLE }
    },
    calc_function = function(card)
        local text, poker_hands, scoring_hand = JokerDisplay.evaluate_hand()
        local is_straight = poker_hands and poker_hands['Straight'] and next(poker_hands['Straight'])
        local found_ace = false
        if scoring_hand then
            for _, c in pairs(scoring_hand) do
                if c:get_id() == 14 then
                    found_ace = true
                    break
                end
            end
        end
        card.joker_display_values.bonus = (is_straight and found_ace) and 1 or 0
    end
}
--#endregion

--#region Glass Joker (j_glass)
-- Your patch makes the vanilla scoring check unconditionally skip
-- ("if false then"). Wait — that patch is actually on Stone Joker, see
-- below. Glass Joker itself: calculate just returns nil in main.lua, no
-- corresponding lovely patch was shown, so it's unclear if the deck-wide
-- Xmult tracking still runs elsewhere or is fully dead. Blanking for now;
-- tell me if Glass Joker's effect moved somewhere and I'll point this at
-- the real source instead.
jd_def["j_glass"] = { text = {}, reminder_text = {} }
--#endregion

--#region Steel Joker (j_steel_joker)
-- No display — passive Xmult scaling is fully disabled (no_steel_joker_effect),
-- replaced by the guaranteed-draw mechanic, and that's not something
-- worth representing as a number on the card.
jd_def["j_steel_joker"] = { text = {}, reminder_text = {} }
--#endregion

--#region Stone Joker (j_stone)
-- Confirmed: this is now a static effect ("Stone Cards now count towards
-- poker hands"), not a scaling number — matches the card.lua patch that
-- unconditionally disables the old passive Chips scoring. No display
-- entry needed. This line just overwrites JokerDisplay's built-in j_stone
-- definition (which still expects the old stone_tally-based Chips value)
-- with an empty one, so it stops trying to read a value that no longer
-- means anything and can't crash.
jd_def["j_stone"] = { text = {}, reminder_text = {} }
--#endregion

--#region Shoot the Moon (j_shoot_the_moon)
-- Active state: previews whether the current highlighted hand would
-- trigger the suit-conversion (first card in the played hand is a Queen).
-- Styling matches DNA's Active/Inactive format (bracketed, green vs.
-- G.C.UI.TEXT_INACTIVE), scale brought down to match DNA's size.
jd_def["j_shoot_the_moon"] = {
    text = {
        { ref_table = "card.joker_display_values", ref_value = "status", scale = 0.35 }
    },
    calc_function = function(card)
        local text, poker_hands, scoring_hand = JokerDisplay.evaluate_hand()
        local first_card = scoring_hand and scoring_hand[1]
        card.joker_display_values.status = (first_card and first_card:get_id() == 12) and "[Active!]" or "[Inactive]"
    end,
    style_function = function(card, text, reminder_text, extra)
        if text and text.children[1] then
            text.children[1].config.colour = (card.joker_display_values.status == "[Active!]") and G.C.GREEN or
                G.C.UI.TEXT_INACTIVE
        end
        return false
    end
}
--#endregion

--#region Marble Joker (j_marble)
-- Active! on the first hand of the round (when the transform can trigger),
-- [Inactive] otherwise. Styling matches DNA's format, scale brought down
-- to match DNA's size.
jd_def["j_marble"] = {
    text = {
        { ref_table = "card.joker_display_values", ref_value = "status", scale = 0.35 }
    },
    calc_function = function(card)
        card.joker_display_values.status = (G.GAME.current_round.hands_played == 0) and "[Active!]" or "[Inactive]"
    end,
    style_function = function(card, text, reminder_text, extra)
        if text and text.children[1] then
            text.children[1].config.colour = (G.GAME.current_round.hands_played == 0) and G.C.GREEN or
                G.C.UI.TEXT_INACTIVE
        end
        return false
    end
}
--#endregion

--#region Onyx Agate (j_onyx_agate)
jd_def["j_onyx_agate"] = { text = {}, reminder_text = {} }
--#endregion

--#region Loyalty Card (j_loyalty_card)
-- Same Active/Inactive pattern as Marble Joker/DNA, plus the hands-left
-- countdown while it's charging up. Scale brought down to match DNA's size.
jd_def["j_loyalty_card"] = {
    text = {
        { ref_table = "card.joker_display_values", ref_value = "status", scale = 0.35 }
    },
    reminder_text = {
        { ref_table = "card.joker_display_values", ref_value = "hands_left" }
    },
    calc_function = function(card)
        local extra = card.ability.extra
        card.joker_display_values.status = extra.ready and "[Active!]" or "[Inactive]"
        local remaining = math.max(0, extra.required - extra.hands)
        card.joker_display_values.hands_left = remaining .. " hands left"
    end,
    style_function = function(card, text, reminder_text, extra)
        if text and text.children[1] then
            text.children[1].config.colour = card.ability.extra.ready and G.C.GREEN or G.C.UI.TEXT_INACTIVE
        end
        return false
    end
}
--#endregion

--#region Throwback (j_throwback)
-- Note: card.ability.extra.used means "already triggered this round," so
-- Active (green) is when it's NOT used yet (still able to trigger),
-- Inactive (grey) is once it's been spent for the round. Styling matches
-- DNA's format, scale brought down to match DNA's size.
jd_def["j_throwback"] = {
    text = {
        { ref_table = "card.joker_display_values", ref_value = "status", scale = 0.35 }
    },
    calc_function = function(card)
        card.joker_display_values.status = card.ability.extra.used and "[Inactive]" or "[Active!]"
    end,
    style_function = function(card, text, reminder_text, extra)
        if text and text.children[1] then
            text.children[1].config.colour = card.ability.extra.used and G.C.UI.TEXT_INACTIVE or G.C.GREEN
        end
        return false
    end
}
--#endregion

--#region Flower Pot (j_flower_pot) — base/streak stage only
-- The four hidden evolved pots (j_flower_pot_hearts/diamonds/spades/clubs)
-- are all static flat-bonus jokers (no per-turn changing number), so their
-- vanilla loc_vars text is enough — no JokerDisplay override needed there,
-- and since they're brand-new custom keys there's no stale built-in
-- definition to conflict with anyway.
-- The BASE pot (before it evolves) tracks a same-suit streak though, and
-- vanilla's own Flower Pot display definition (if it has one) won't know
-- about your `suit`/`count`/`needed` fields, so this one does need an
-- override.
jd_def["j_flower_pot"] = {
    text = {
        { ref_table = "card.joker_display_values", ref_value = "count" },
        { text = "/" },
        { ref_table = "card.ability.extra", ref_value = "needed" }
    },
    reminder_text = {
        { ref_table = "card.joker_display_values", ref_value = "suit_text" }
    },
    calc_function = function(card)
        local extra = card.ability.extra
        card.joker_display_values.count = extra.count
        card.joker_display_values.suit_text = extra.suit and localize(extra.suit, 'suits_singular') or "No streak yet"
    end
}
--#endregion

--[[
    Confirmed keys, no override written (need more info to do these safely
    or correctly):

    j_order (The Order — X3 -> X4 Mult on Straight), j_zany / j_mad /
    j_crazy / j_wily / j_clever / j_devious (the type-mult/chip family),
    Vampire, Hanging Chad, and the plain stat-tweak jokers
    (greedy/lusty/wrathful/gluttenous, four_fingers, shortcut, 8_ball,
    runner, mail, card_sharp) — all confirmed safe. Vanilla itself stores their config exactly the way you have it
    (top-level t_mult/type/Xmult, extra sometimes a bare number), so these
    are pure numeric rebalances with no structural change. No overrides
    needed for any of them.
]]