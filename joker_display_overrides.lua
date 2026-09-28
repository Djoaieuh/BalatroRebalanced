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

    Styling convention (confirmed against JokerDisplay's own source):
    - Use text_config = { colour = X } to colour a whole `text` array
      uniformly (e.g. the "+" and the number share one colour). Only set
      colour per-node when nodes genuinely differ, like Scholar's
      chips/mult split.
    - Active/Inactive indicators go in reminder_text, wrapped in literal
      "(" / ")" nodes — exactly like the real j_dna entry. This is what
      makes status text render at DNA's size automatically; putting it
      in `text` (like an earlier version did) is why it was oversized.
    - Where a joker has its OWN localization keys or literal status
      strings (Loyalty Card, Throwback), those are used instead of the
      generic jdis_active/jdis_inactive pair, since those keys don't
      apply to them.
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
        { text = "$" },
        { ref_table = "card.joker_display_values", ref_value = "amount" }
    },
    text_config = { colour = G.C.MONEY },
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
-- border_nodes handles its own colour (defaults to G.C.XMULT), no
-- text_config needed.
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
        { text = "$" },
        { ref_table = "card.joker_display_values", ref_value = "amount" }
    },
    text_config = { colour = G.C.MONEY },
    reminder_text = {
        { ref_table = "card.joker_display_values", ref_value = "hand_name" }
    },
    reminder_text_config = { colour = G.C.ORANGE },
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
        { text = "+" },
        { ref_table = "card.joker_display_values", ref_value = "bonus" }
    },
    text_config = { colour = G.C.PURPLE },
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
        { text = "+" },
        { ref_table = "card.joker_display_values", ref_value = "mult" }
    },
    text_config = { colour = G.C.MULT },
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
-- Colour corrected to G.C.SECONDARY_SET.Tarot — that's what the real
-- vanilla j_superposition entry uses (Tarot-themed effect), not purple.
jd_def["j_superposition"] = {
    text = {
        { text = "+" },
        { ref_table = "card.joker_display_values", ref_value = "bonus" }
    },
    text_config = { colour = G.C.SECONDARY_SET.Tarot },
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
jd_def["j_glass"] = { text = {}, reminder_text = {} }
--#endregion

--#region Steel Joker (j_steel_joker)
jd_def["j_steel_joker"] = { text = {}, reminder_text = {} }
--#endregion

--#region Stone Joker (j_stone)
jd_def["j_stone"] = { text = {}, reminder_text = {} }
--#endregion

--#region Shoot the Moon (j_shoot_the_moon)
-- UNVERIFIED. take_ownership('shoot_the_moon', {blueprint_compat = false})
-- shows no config, no calculate function, no ability.extra — the lovely
-- patch only deletes the vanilla bonus. The "convert suits to match a
-- leading Queen" mechanic has not been confirmed anywhere in the source
-- shown to me; it may live in a main.lua evaluate_play hook, or may not
-- currently exist at all. This preview logic is a guess at what such a
-- hook would check, not a confirmed read of an actual mechanic. Paste
-- the evaluate_play hook (or confirm there isn't one) before trusting
-- this in-game.
jd_def["j_shoot_the_moon"] = {
    reminder_text = {
        { text = "(" },
        { ref_table = "card.joker_display_values", ref_value = "active_text" },
        { text = ")" },
    },
    calc_function = function(card)
        local text, poker_hands, scoring_hand = JokerDisplay.evaluate_hand()
        local first_card = scoring_hand and scoring_hand[1]
        card.joker_display_values.is_active = first_card and first_card:get_id() == 12
        card.joker_display_values.active_text = localize("jdis_" ..
            (card.joker_display_values.is_active and "active" or "inactive"))
    end,
    style_function = function(card, text, reminder_text, extra)
        if reminder_text and reminder_text.children[2] then
            reminder_text.children[2].config.colour = card.joker_display_values.is_active and G.C.GREEN or
                G.C.UI.TEXT_INACTIVE
        end
        return false
    end
}
--#endregion

--#region Marble Joker (j_marble)
-- Active on the first hand of the round (when the transform can trigger),
-- Inactive otherwise. Uses DNA's real reminder_text pattern with the
-- generic jdis_active/jdis_inactive keys, which is correct here since
-- Marble Joker doesn't define its own status strings.
jd_def["j_marble"] = {
    reminder_text = {
        { text = "(" },
        { ref_table = "card.joker_display_values", ref_value = "active_text" },
        { text = ")" },
    },
    calc_function = function(card)
        card.joker_display_values.is_active = G.GAME.current_round.hands_played == 0
        card.joker_display_values.active_text = localize("jdis_" ..
            (card.joker_display_values.is_active and "active" or "inactive"))
    end,
    style_function = function(card, text, reminder_text, extra)
        if reminder_text and reminder_text.children[2] then
            reminder_text.children[2].config.colour = card.joker_display_values.is_active and G.C.GREEN or
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
-- Real fields (confirmed from take_ownership source): extra.hands,
-- extra.required, extra.every, extra.x_mult, extra.ready. Status text
-- matches the mod's own loc_vars exactly: "(Ready !)" when ready,
-- "(N hands left!)" while counting up — not the generic Active/Inactive
-- pair, since this joker writes its own status string.
-- NOTE: your take_ownership call for this one is 'j_loyalty_card' (with
-- the j_ prefix already included), unlike shoot_the_moon/throwback below
-- which pass the bare name. If SMODS always prepends j_, this joker's
-- real key may end up as j_j_loyalty_card — worth checking the actual
-- registered key in-game. This override targets j_loyalty_card, matching
-- what worked earlier in this conversation.
jd_def["j_loyalty_card"] = {
    reminder_text = {
        { ref_table = "card.joker_display_values", ref_value = "status_text" }
    },
    calc_function = function(card)
        local extra = card.ability.extra
        local remaining = math.max(0, extra.required - extra.hands)
        card.joker_display_values.is_active = extra.ready
        card.joker_display_values.status_text = extra.ready and "(Ready !)" or ("(" .. remaining .. " hands left!)")
    end,
    style_function = function(card, text, reminder_text, extra)
        if reminder_text and reminder_text.children[1] then
            reminder_text.children[1].config.colour = card.joker_display_values.is_active and G.C.GREEN or
                G.C.UI.TEXT_INACTIVE
        end
        return false
    end
}
--#endregion

--#region Throwback (j_throwback)
-- Real field (confirmed): extra.used. Not used = still armable this
-- round (Active), used = already committed, waiting on the pack/reset
-- (Inactive). Uses the mod's real localization keys, k_throwback_left /
-- k_throwback_done, instead of the generic jdis_ pair, since Throwback
-- defines its own. Wrapped in parens to match DNA's visual convention —
-- unconfirmed whether the mod's own loc_txt already includes parens
-- around #1#; check in-game for doubled parens.
jd_def["j_throwback"] = {
    reminder_text = {
        { text = "(" },
        { ref_table = "card.joker_display_values", ref_value = "status_text" },
        { text = ")" },
    },
    calc_function = function(card)
        card.joker_display_values.is_active = not card.ability.extra.used
        card.joker_display_values.status_text = card.ability.extra.used and localize('k_throwback_done') or
            localize('k_throwback_left')
    end,
    style_function = function(card, text, reminder_text, extra)
        if reminder_text and reminder_text.children[2] then
            reminder_text.children[2].config.colour = card.joker_display_values.is_active and G.C.GREEN or
                G.C.UI.TEXT_INACTIVE
        end
        return false
    end
}
--#endregion

--#region Flower Pot (j_flower_pot) — base/streak stage only
-- Text colour now tracks the current streak suit (lightened, same as
-- Ancient/Castle/Idol elsewhere in this mod — raw G.C.SUITS.Clubs and
-- .Spades are near-black and unreadable as plain text, hence lighten()).
-- Falls back to the inactive grey when there's no streak yet.
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
    end,
    style_function = function(card, text, reminder_text, extra)
        local suit = card.ability.extra.suit
        local colour = suit and lighten(G.C.SUITS[suit], 0.35) or G.C.UI.TEXT_INACTIVE
        if text and text.children then
            for _, child in ipairs(text.children) do
                if child.config then child.config.colour = colour end
            end
        end
        if reminder_text and reminder_text.children[1] then
            reminder_text.children[1].config.colour = colour
        end
        return false
    end
}
--#endregion

--#region Flower Pot — Clubs (j_flower_pot_clubs)
-- Copied directly from the real j_blueprint entry — your Clubs pot's
-- calculate() calls SMODS.blueprint_effect the same way vanilla
-- Blueprint does, copying whatever joker sits to its right, so its
-- display should behave identically: green/red compatibility badge plus
-- JokerDisplay.copy_display mirroring the copied joker's own display.
jd_def["j_flower_pot_clubs"] = {
    reminder_text = {
        { text = "(" },
        { ref_table = "card.joker_display_values", ref_value = "blueprint_compat", colour = G.C.RED },
        { text = ")" }
    },
    calc_function = function(card)
        local copied_joker, copied_debuff = JokerDisplay.calculate_blueprint_copy(card)
        card.joker_display_values.blueprint_compat = localize('k_incompatible')
        JokerDisplay.copy_display(card, copied_joker, copied_debuff)
    end,
    get_blueprint_joker = function(card)
        for i = 1, #G.jokers.cards do
            if G.jokers.cards[i] == card then
                return G.jokers.cards[i + 1]
            end
        end
        return nil
    end
}
--#endregion

--#region Flower Pot — Spades (j_flower_pot_spades)
-- Nothing to display, per your call. Explicit blank, same convention as
-- Matador/Onyx Agate above.
jd_def["j_flower_pot_spades"] = { text = {}, reminder_text = {} }
--#endregion

--#region Flower Pot — Diamonds (j_flower_pot_diamonds)
-- Nothing to display, per your call.
jd_def["j_flower_pot_diamonds"] = { text = {}, reminder_text = {} }
--#endregion

--[[
    Flower Pot — Hearts (j_flower_pot_hearts): deliberately no entry here.
    "Same as Juggler" — Juggler's real vanilla entry is `j_juggler = {}`,
    an empty table, meaning JokerDisplay applies NO custom display to it
    at all (falls back to whatever the base game shows by default). So
    matching Juggler means not overriding this key, not overriding it
    with an empty one — those aren't quite the same thing, and the
    correct match for "nothing, like Juggler" is simply not touching it.
]]

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