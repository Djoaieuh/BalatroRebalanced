--#region Atlases

SMODS.Atlas{
    key = 'placeholders',
    path = 'placeholders.png',
    px = 71,
    py = 95
}


--#endregion

--#region JokerDisplay

--#endregion


--#region File Loading

print("MOD PATH: " .. tostring(SMODS.current_mod.path))
print("LOOKING IN: " .. tostring(SMODS.current_mod.path .. "src/jokers"))

local jokers_src = SMODS.NFS.getDirectoryItems(SMODS.current_mod.path .. "src/jokers")

print("FILES FOUND: " .. tostring(#jokers_src))

for _, file in ipairs(jokers_src) do
    assert(SMODS.load_file("src/jokers/" .. file))()
end

--#endregion

--#region Hand Levels

SMODS.PokerHand:take_ownership('High Card', { l_mult = 1, l_chips = 5 }, true)
SMODS.PokerHand:take_ownership('Pair', { l_mult = 1, l_chips = 10 }, true)
SMODS.PokerHand:take_ownership('Two Pair', { l_mult = 2, l_chips = 20 }, true)
SMODS.PokerHand:take_ownership('Three of a Kind', { l_mult = 2, l_chips = 30 }, true)
SMODS.PokerHand:take_ownership('Straight', { l_mult = 4, l_chips = 30 }, true)
SMODS.PokerHand:take_ownership('Flush', { l_mult = 2, l_chips = 20 }, true)
SMODS.PokerHand:take_ownership('Full House', { l_mult = 3, l_chips = 30 }, true)
SMODS.PokerHand:take_ownership('Four of a Kind', { l_mult = 4, l_chips = 40 }, true)
SMODS.PokerHand:take_ownership('Straight Flush', { l_mult = 8, l_chips = 80 }, true)
SMODS.PokerHand:take_ownership('Five of a Kind', { l_mult = 4, l_chips = 50 }, true)
SMODS.PokerHand:take_ownership('Flush House', { l_mult = 5, l_chips = 50 }, true)
SMODS.PokerHand:take_ownership('Flush Five', { l_mult = 4, l_chips = 60 }, true)

--#endregion

--#region Spectral Cards

SMODS.Consumable:take_ownership('immolate', {config = {remove_card = true, extra = {destroy = 4, dollars = 10}}}, true)

local WRAITH_MONEY = 10

SMODS.Consumable:take_ownership('wraith', {
    loc_txt = {
        name = 'Wraith',
        text = {
            'Creates a random',
            '{C:red}Rare{C:attention} Joker{},',
            'sets money to {C:money}$' .. WRAITH_MONEY,
        },
    },
    use = function(self, card, area, copier)
        G.E_MANAGER:add_event(Event({
            trigger = 'after',
            delay = 0.4,
            func = function()
                play_sound('timpani')
                SMODS.add_card({ set = 'Joker', rarity = 'Rare', key_append = 'wra' })
                card:juice_up(0.3, 0.5)
                if G.GAME.dollars ~= WRAITH_MONEY then
                    ease_dollars(WRAITH_MONEY - G.GAME.dollars, true)
                end
                return true
            end
        }))
        delay(0.6)
    end,
}, true)

SMODS.Consumable:take_ownership('ouija', {
    use = function(self, card, area, copier)
        G.E_MANAGER:add_event(Event({
            trigger = 'after',
            delay = 0.4,
            func = function()
                play_sound('tarot1')
                card:juice_up(0.3, 0.5)
                return true
            end
        }))
        for i = 1, #G.hand.cards do
            local percent = 1.15 - (i - 0.999) / (#G.hand.cards - 0.998) * 0.3
            G.E_MANAGER:add_event(Event({
                trigger = 'after',
                delay = 0.15,
                func = function()
                    G.hand.cards[i]:flip()
                    play_sound('card1', percent)
                    G.hand.cards[i]:juice_up(0.3, 0.3)
                    return true
                end
            }))
        end
        local _rank = pseudorandom_element(SMODS.Ranks, 'vremade_ouija')
        for i = 1, #G.hand.cards do
            G.E_MANAGER:add_event(Event({
                func = function()
                    local _card = G.hand.cards[i]
                    assert(SMODS.change_base(_card, nil, _rank.key))
                    return true
                end
            }))
        end

        -- debuff every card in hand until end of ante, instead of -1 hand size
        for i = 1, #G.hand.cards do
            local _card = G.hand.cards[i]
            _card.ability.ouija_debuff = true
            SMODS.calculate_context({ debuff_card = _card })
        end

        for i = 1, #G.hand.cards do
            local percent = 0.85 + (i - 0.999) / (#G.hand.cards - 0.998) * 0.3
            G.E_MANAGER:add_event(Event({
                trigger = 'after',
                delay = 0.15,
                func = function()
                    G.hand.cards[i]:flip()
                    play_sound('tarot2', percent, 0.6)
                    G.hand.cards[i]:juice_up(0.3, 0.3)
                    return true
                end
            }))
        end
        delay(0.5)
    end
}, true)

SMODS.current_mod.calculate = function(self, context)
    if context.debuff_card and context.debuff_card.ability.ouija_debuff then
        return { debuff = true }
    end

    if context.ante_change and context.ante_end then
        for _, playing_card in ipairs(G.playing_cards or {}) do
            if playing_card.ability.ouija_debuff then
                playing_card.ability.ouija_debuff = nil
                SMODS.calculate_context({ debuff_card = playing_card })
            end
        end
    end
end

SMODS.Consumable:take_ownership('sigil', {
    config = { max_highlighted = 1 },
    use = function(self, card, area, copier)
        G.E_MANAGER:add_event(Event({
            trigger = 'after',
            delay = 0.4,
            func = function()
                play_sound('tarot1')
                card:juice_up(0.3, 0.5)
                return true
            end
        }))
        for i = 1, #G.hand.cards do
            local percent = 1.15 - (i - 0.999) / (#G.hand.cards - 0.998) * 0.3
            G.E_MANAGER:add_event(Event({
                trigger = 'after',
                delay = 0.15,
                func = function()
                    G.hand.cards[i]:flip()
                    play_sound('card1', percent)
                    G.hand.cards[i]:juice_up(0.3, 0.3)
                    return true
                end
            }))
        end
        local _suit = G.hand.highlighted[1].base.suit
        for i = 1, #G.hand.cards do
            G.E_MANAGER:add_event(Event({
                func = function()
                    local _card = G.hand.cards[i]
                    assert(SMODS.change_base(_card, _suit))
                    return true
                end
            }))
        end
        for i = 1, #G.hand.cards do
            local percent = 0.85 + (i - 0.999) / (#G.hand.cards - 0.998) * 0.3
            G.E_MANAGER:add_event(Event({
                trigger = 'after',
                delay = 0.15,
                func = function()
                    G.hand.cards[i]:flip()
                    play_sound('tarot2', percent, 0.6)
                    G.hand.cards[i]:juice_up(0.3, 0.3)
                    return true
                end
            }))
        end
        delay(0.5)
    end,
    can_use = function(self, card)
        return G.hand and #G.hand.cards > 1 and #G.hand.highlighted == 1
    end
}, true)

SMODS.Consumable:take_ownership('hex', {
    use = function(self, card, area, copier)
        local editionless_jokers = SMODS.Edition:get_edition_cards(G.jokers, true)
        G.E_MANAGER:add_event(Event({
            trigger = 'after',
            delay = 0.4,
            func = function()
                local eligible_card = editionless_jokers[#editionless_jokers]
                eligible_card:set_edition("e_polychrome")
                eligible_card.ability.eternal = true

                card:juice_up(0.3, 0.5)
                return true
            end
        }))
    end,
    can_use = function(self, card)
        return next(SMODS.Edition:get_edition_cards(G.jokers, true))
    end
}, true)

-- Incantation
SMODS.Consumable:take_ownership('incantation', {
    pos = { x = 2, y = 4 },
    config = { max_highlighted = 1, extra = { destroy = 1 } },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.destroy } }
    end,
    can_use = function(self, card)
        return G.hand and #G.hand.highlighted == 1
    end,
    use = function(self, card, area, copier)
        local card_to_destroy = G.hand.highlighted[1]
        G.hand:unhighlight_all()

        -- find the destroyed card's position and its neighbours BEFORE it's removed
        local destroy_index = nil
        for i, c in ipairs(G.hand.cards) do
            if c == card_to_destroy then
                destroy_index = i
                break
            end
        end

        local neighbours = {}
        if destroy_index then
            if G.hand.cards[destroy_index - 1] then
                neighbours[#neighbours + 1] = G.hand.cards[destroy_index - 1]
            end
            if G.hand.cards[destroy_index + 1] then
                neighbours[#neighbours + 1] = G.hand.cards[destroy_index + 1]
            end
        end

        -- rank value table used for POSITION in the 2..14 wraparound cycle
        local RANK_VALUE = {
            ['2'] = 2, ['3'] = 3, ['4'] = 4, ['5'] = 5, ['6'] = 6, ['7'] = 7,
            ['8'] = 8, ['9'] = 9, ['T'] = 10, ['J'] = 11, ['Q'] = 12, ['K'] = 13, ['A'] = 14
        }
        local VALUE_RANK = {}
        for k, v in pairs(RANK_VALUE) do VALUE_RANK[v] = k end

        -- separate table for how much a DESTROYED card adds (Ace=1, face cards=10)
        local ADD_VALUE = {
            ['2'] = 2, ['3'] = 3, ['4'] = 4, ['5'] = 5, ['6'] = 6, ['7'] = 7,
            ['8'] = 8, ['9'] = 9, ['T'] = 10, ['J'] = 10, ['Q'] = 10, ['K'] = 10, ['A'] = 1
        }

        local destroy_rank_key = SMODS.Ranks[card_to_destroy.base.value].card_key
        local destroy_value = ADD_VALUE[destroy_rank_key]

        G.E_MANAGER:add_event(Event({
            trigger = 'after',
            delay = 0.4,
            func = function()
                play_sound('tarot1')
                card:juice_up(0.3, 0.5)
                return true
            end
        }))

        SMODS.destroy_cards(card_to_destroy)

        G.E_MANAGER:add_event(Event({
            trigger = 'after',
            delay = 0.7,
            func = function()
                for _, neighbour in ipairs(neighbours) do
                    local neighbour_rank_key = SMODS.Ranks[neighbour.base.value].card_key
                    local neighbour_value = RANK_VALUE[neighbour_rank_key]

                    -- wrap around like Strength: 2..14 range, loops past Ace back to 2
                    local offset = (neighbour_value - 2 + destroy_value) % 13
                    local new_value = offset + 2
                    local new_rank_key = VALUE_RANK[new_value]

                    local suit_letter = neighbour.base.suit:sub(1, 1)
                    local new_base = G.P_CARDS[suit_letter .. '_' .. new_rank_key]
                    if new_base then
                        neighbour:set_base(new_base)
                        neighbour:juice_up(0.3, 0.5)
                        play_sound('card1', 1.1)
                    end
                end
                return true
            end
        }))

        delay(0.3)
    end,
    draw = function(self, card, layer)
        -- This is for the Spectral shader. You don't need this with `set = "Spectral"`
        -- Also look into SMODS.DrawStep if you make multiple cards that need the same shader
        if (layer == 'card' or layer == 'both') and card.sprite_facing == 'front' then
            card.children.center:draw_shader('booster', nil, card.ARGS.send_to_shader)
        end
    end
}, true)

SMODS.Consumable:take_ownership('grim',{
    config = { extra = { tarots = 2 } },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.tarots } }
    end,
    use = function(self, card, area, copier)
        G.E_MANAGER:add_event(Event({
            trigger = 'after',
            delay = 0.4,
            func = function()
                play_sound('tarot1')
                card:juice_up(0.3, 0.5)

                local cen_pool = {}
                for _, enhancement_center in pairs(G.P_CENTER_POOLS["Enhanced"]) do
                    if enhancement_center.key ~= 'm_stone' and not enhancement_center.overrides_base_rank then
                        cen_pool[#cen_pool + 1] = enhancement_center.key
                    end
                end
                local enhancement = SMODS.poll_enhancement { guaranteed = true, options = cen_pool, key = "vremade_grim_card" }
                local new_card = SMODS.add_card {
                    set = "Base",
                    rank = 'Ace',
                    enhancement = enhancement,
                    area = G.hand,
                    key_append = "vremade_grim_card"
                }
                SMODS.calculate_context({ playing_card_added = true, cards = { new_card } })
                return true
            end
        }))

        for i = 1, card.ability.extra.tarots do
            G.E_MANAGER:add_event(Event({
                trigger = 'after',
                delay = 0.7 + (i * 0.15),
                func = function()
                    SMODS.add_card {
                        set = 'Tarot',
                        edition = 'e_negative',
                        area = G.consumeables,
                        key_append = 'vremade_grim_negative'
                    }
                    play_sound('generic1')
                    return true
                end
            }))
        end

        delay(0.3)
    end,
    can_use = function(self, card)
        return true
    end,
    draw = function(self, card, layer)
        if (layer == 'card' or layer == 'both') and card.sprite_facing == 'front' then
            card.children.center:draw_shader('booster', nil, card.ARGS.send_to_shader)
        end
    end
}, true)

-- Familiar
SMODS.Consumable:take_ownership('familiar', {
    config = { extra = { destroy = 2, cards = 3 } },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.destroy, card.ability.extra.cards } }
    end,
    use = function(self, card, area, copier)
        -- build a working copy of hand so we can pick distinct targets without repeats
        local remaining = {}
        for _, c in ipairs(G.hand.cards) do
            remaining[#remaining + 1] = c
        end

        -- pick N distinct random cards to destroy
        local cards_to_destroy = {}
        for i = 1, card.ability.extra.destroy do
            if #remaining == 0 then break end
            local pick = pseudorandom_element(remaining, pseudoseed('vremade_familiar_destroy_' .. i))
            cards_to_destroy[#cards_to_destroy + 1] = pick
            for j, c in ipairs(remaining) do
                if c == pick then
                    table.remove(remaining, j)
                    break
                end
            end
        end

        -- pick N distinct random cards (from what's left) to convert
        local cards_to_convert = {}
        for i = 1, card.ability.extra.cards do
            if #remaining == 0 then break end
            local pick = pseudorandom_element(remaining, pseudoseed('vremade_familiar_convert_' .. i))
            cards_to_convert[#cards_to_convert + 1] = pick
            for j, c in ipairs(remaining) do
                if c == pick then
                    table.remove(remaining, j)
                    break
                end
            end
        end

        G.E_MANAGER:add_event(Event({
            trigger = 'after',
            delay = 0.4,
            func = function()
                play_sound('tarot1')
                card:juice_up(0.3, 0.5)
                return true
            end
        }))

        if #cards_to_destroy > 0 then
            SMODS.destroy_cards(cards_to_destroy)
        end

        G.E_MANAGER:add_event(Event({
            trigger = 'after',
            delay = 0.7,
            func = function()
                for i, target in ipairs(cards_to_convert) do
                    -- pick a random face rank (J/Q/K)
                    local faces = {}
                    for _, rank_key in ipairs(SMODS.Rank.obj_buffer) do
                        local rank = SMODS.Ranks[rank_key]
                        if rank.face then table.insert(faces, rank) end
                    end
                    local new_rank_key = pseudorandom_element(faces, pseudoseed('vremade_familiar_rank')).card_key

                    -- keep the card's existing suit, only change rank
                    local suit_letter = target.base.suit:sub(1, 1)
                    local new_base = G.P_CARDS[suit_letter .. '_' .. new_rank_key]
                    if new_base then
                        target:set_base(new_base)
                    end

                    -- apply a random valid enhancement
                    local cen_pool = {}
                    for _, enhancement_center in pairs(G.P_CENTER_POOLS["Enhanced"]) do
                        if enhancement_center.key ~= 'm_stone' and not enhancement_center.overrides_base_rank then
                            cen_pool[#cen_pool + 1] = enhancement_center.key
                        end
                    end
                    local enhancement = SMODS.poll_enhancement { guaranteed = true, options = cen_pool, key = "vremade_familiar_enh" }
                    target:set_ability(G.P_CENTERS[enhancement])

                    -- 10% chance to add a random seal
                    if pseudorandom('vremade_familiar_seal_chance_' .. i) < 0.1 then
                        local seal_pool = {}
                        for _, seal_center in pairs(G.P_SEALS) do
                            seal_pool[#seal_pool + 1] = seal_center.key
                        end
                        local seal = pseudorandom_element(seal_pool, pseudoseed('vremade_familiar_seal_' .. i))
                        target:set_seal(seal, true)
                    end

                    -- 10% chance for an edition, weighted so Foil > Holo > Polychrome
                    if pseudorandom('vremade_familiar_edition_chance_' .. i) < 0.1 then
                        local edition_pool = {
                            { key = 'e_foil',       weight = 70 },
                            { key = 'e_holo',       weight = 25 },
                            { key = 'e_polychrome', weight = 5 },
                        }
                        local total_weight = 0
                        for _, e in ipairs(edition_pool) do total_weight = total_weight + e.weight end

                        local roll = pseudorandom('vremade_familiar_edition_pick_' .. i) * total_weight
                        local running = 0
                        local chosen_edition = edition_pool[1].key
                        for _, e in ipairs(edition_pool) do
                            running = running + e.weight
                            if roll <= running then
                                chosen_edition = e.key
                                break
                            end
                        end

                        target:set_edition(chosen_edition, true)
                    end

                    target:juice_up(0.3, 0.5)
                    play_sound('card1', 1.1)
                end
                return true
            end
        }))

        delay(0.3)
    end,
}, true)

local function csau_get_most_played_hand(exclude)
    exclude = exclude or {}
    local highest = -1
    local highest_pool = {}

    for k, hand in pairs(G.GAME.hands) do
        if hand.visible and hand.played and not exclude[k] and hand.played > highest then
            highest = hand.played
        end
    end
    for k, hand in pairs(G.GAME.hands) do
        if hand.visible and hand.played and not exclude[k] and hand.played == highest then
            table.insert(highest_pool, k)
        end
    end

    if #highest_pool == 0 then return nil end
    return pseudorandom_element(highest_pool, pseudoseed('black_hole_ban'))
end

SMODS.Consumable:take_ownership('c_black_hole', {
    loc_vars = function(self, info_queue, card)
    if card and card.area and card.area.config.collection then
        return { vars = { localize('k_csau_most_played') } }
    end

    local preview = nil
    if G.GAME and G.GAME.hands then
        preview = csau_get_most_played_hand(G.GAME.csau_black_hole_banned_hands or {})
    end
    return { vars = { preview and localize(preview, 'poker_hands') or localize('k_csau_none_left_ex') } }
end,

    use = function(self, card, area, copier)
        G.GAME.csau_black_hole_banned_hands = G.GAME.csau_black_hole_banned_hands or {}
        local banned_hand = csau_get_most_played_hand(G.GAME.csau_black_hole_banned_hands)

        G.E_MANAGER:add_event(Event({
            trigger = 'after',
            delay = 0.4,
            func = function()
                play_sound('tarot1')
                card:juice_up(0.3, 0.5)
                G.hand:change_size(1)
                return true
            end
        }))

        delay(0.2)

        if banned_hand then
            G.GAME.csau_black_hole_banned_hands[banned_hand] = true
            card_eval_status_text(card, 'extra', nil, nil, nil, {
                message = localize('k_csau_hand_banned_ex') .. localize(banned_hand, 'poker_hands'),
                colour = G.C.RED
            })
        else
            card_eval_status_text(card, 'extra', nil, nil, nil, {
                message = localize('k_csau_none_left_ex'),
                colour = G.C.RED
            })
        end

        delay(0.5)
    end
}, true)

-- Global, permanent debuff hook — applies on every blind (small/big/boss)
-- for the rest of the run, to every hand type in the banned table.
local csau_bh_triggered = false
local debuff_hand_ref = Blind.debuff_hand
function Blind:debuff_hand(cards, hand, handname, check)
    if G.GAME.csau_black_hole_banned_hands and G.GAME.csau_black_hole_banned_hands[handname] then
        csau_bh_triggered = true
        return true
    end
    csau_bh_triggered = false
    return debuff_hand_ref(self, cards, hand, handname, check)
end

local get_loc_debuff_textref = Blind.get_loc_debuff_text
function Blind:get_loc_debuff_text()
    if csau_bh_triggered then
        return "Not allowed [Black Hole]"
    end
    return get_loc_debuff_textref(self)
end

--#endregion

--#region Tarot Cards

SMODS.Consumable:take_ownership('lovers', {config = {mod_conv = 'm_wild', max_highlighted = 2}}, true)

--#endregion

--#region Joker Changes

SMODS.Joker:take_ownership('greedy_joker', {config = {extra = {s_mult = 4, suit = 'Diamonds'}}, }, true)
SMODS.Joker:take_ownership('lusty_joker', {config = {extra = {s_mult = 4, suit = 'Hearts'}}, }, true)
SMODS.Joker:take_ownership('wrathful_joker', {config = {extra = {s_mult = 4, suit = 'Spades'}}, }, true)
SMODS.Joker:take_ownership('gluttenous_joker', {config = {extra = {s_mult = 4, suit = 'Clubs'}}, }, true)

SMODS.Joker:take_ownership('zany', {config = {t_mult = 15, type = 'Three of a Kind'}, }, true)
SMODS.Joker:take_ownership('mad', {config = {t_mult = 12, type = 'Two Pair'}, }, true)
SMODS.Joker:take_ownership('crazy', {config = {t_mult = 20, type = 'Straight'}, }, true)
SMODS.Joker:take_ownership('wily', {config = {t_chips = 120, type = 'Three of a Kind'}, }, true)
SMODS.Joker:take_ownership('clever', {config = {t_chips = 100, type = 'Two Pair'}, }, true)
SMODS.Joker:take_ownership('devious', {config = {t_chips = 150, type = 'Straight'}, }, true)

SMODS.Joker:take_ownership('four_fingers', {rarity = 1, cost = 5}, true)

SMODS.Joker:take_ownership('shortcut', {rarity = 1, cost = 5}, true)

SMODS.Joker:take_ownership('8_ball', {config = {extra = 2, }}, true)

SMODS.Joker:take_ownership('runner', {config = {extra = {chips = 0, chip_mod = 20}}}, true)

SMODS.Joker:take_ownership('vampire', {config = {extra = 0.2, Xmult = 1}}, true)

SMODS.Joker:take_ownership('mail', {config = {extra = 4}}, true)

SMODS.Joker:take_ownership('fortune_teller', {config = {extra = 3}}, true)

SMODS.Joker:take_ownership('order', {config = {Xmult = 4, type = 'Straight'}, }, true)

SMODS.Joker:take_ownership('vagabond',{config = {extra = 6}} , true)

SMODS.Joker:take_ownership('superposition', {
    blueprint_compat = false,
    loc_txt = {
        name = 'Superposition',
        text = {
            'If played hand contains',
            'an {C:attention}Ace{} and a {C:attention}Straight{},',
            'add a {C:purple}Purple Seal{}',
            'to the {C:attention}Ace{}',
        },
    },
    loc_vars = function(self, info_queue, card)
        info_queue[#info_queue + 1] = G.P_SEALS['Purple']  -- shows the Purple Seal tooltip
        return {}
    end,
    calculate = function(self, card, context)
        if context.joker_main and next(context.poker_hands['Straight']) then
            local found_ace = false
            for _, scored_card in ipairs(context.scoring_hand) do
                if scored_card:get_id() == 14 then
                    found_ace = true
                    scored_card:set_seal('Purple', nil, true)
                end
            end
            if found_ace then
                return {
                    message = 'Purple Seal!',
                    colour = G.C.SECONDARY_SET.Tarot,
                }
            end
        end
    end,
}, true)

SMODS.Joker:take_ownership('onyx_agate',{
    key = "onyx_agate",
    name = 'onyxAgate',
    loc_txt = {
        name = 'Onyx Agate',
        text = {
            'Retrigger any {C:attention}played{} {C:blue}Clubs{}',
        },
    },
    cost = 6,
    config = { extra = {repetitions = 1 }},
    calculate = function(self, card, context)
        if context.repetition and context.cardarea == G.play and context.other_card:is_suit("Clubs") then
            return {
                repetitions = card.ability.extra.repetitions
            }
        end
    end,
},true)

SMODS.Joker:take_ownership('marble',{
    key = "marble",
    blueprint_compat = false,
    rarity = 2,
    cost = 6,
    override = true,
    pos = { x = 3, y = 2 },
    loc_vars = function(self, info_queue, card)
        info_queue[#info_queue + 1] = G.P_CENTERS.m_stone
    end,

    loc_txt = {
        name = 'Marble Joker',
        text = {
            'On the first {C:blue}hand{} of each',
            '{C:attention}round{} turn the 2 lowest {C:attention}ranked{}',
            'cards into {C:attention}Stone Cards{}'
        },
    },

    calculate = function(self, card, context)
    if context.before and context.full_hand  and G.GAME.current_round.hands_played == 0 then
        local hand = context.full_hand

        local sorted = {}
        for _, c in ipairs(hand) do
            table.insert(sorted, c)
        end

        table.sort(sorted, function(a, b)
            return a:get_id() < b:get_id()
        end)

        for i = 1, math.min(2, #sorted) do
            sorted[i]:set_ability(G.P_CENTERS.m_stone)
        end

        return {
            message = "Stone!"
        }
    end

    if context.setting_blind then

    end
end

} , true)

SMODS.Joker:take_ownership('j_loyalty_card', {
    config = {
        extra = {
            hands = 0,
            required = 6,
            every = 6,
            x_mult = 4,
            ready = false
        }
    },

    rarity = 1,
    cost = 4,

    loc_txt = {
    name = 'Loyalty Card',
    text = {
        'After {C:attention}#1#{} hands played,',
        'stores {X:mult,C:white}X#2#{} Mult',
        'When {C:attention}rightmost{}, cashes out',
        'and destroys itself',
        '{s:0.8,C:inactive}#3#'
        }
    },

    loc_vars = function(self, info_queue, card)
    local remaining = card.ability.extra.required - card.ability.extra.hands
    if remaining < 0 then remaining = 0 end

    local status_text
    if card.ability.extra.ready then
        status_text = '(Ready !)'
    else
        status_text = '(' .. remaining .. ' hands left!)'
    end

    return {
        vars = {
            card.ability.extra.required,
            card.ability.extra.x_mult,
            status_text
            }
        }
    end,

    calculate = function(self, card, context)

        -- Count hands played
        if context.after and not card.ability.extra.ready then
            card.ability.extra.hands = card.ability.extra.hands + 1

            if card.ability.extra.hands >= card.ability.extra.required then
                card.ability.extra.ready = true
                return {
                    message = 'Ready!',
                    colour = G.C.GREEN
                }
            else
                return {
                    message = card.ability.extra.hands .. '/' .. card.ability.extra.required,
                    colour = G.C.FILTER
                }
            end
        end

        -- Cash out if charged AND rightmost
        if context.joker_main
            and card.ability.extra.ready
            and card == G.jokers.cards[#G.jokers.cards] then

            return {
                x_mult = card.ability.extra.x_mult,
                message = 'Cashed Out!',
                colour = G.C.MULT,
                func = function()
                    G.E_MANAGER:add_event(Event({
                        trigger = 'after',
                        delay = 0.1,
                        func = function()
                            card:start_dissolve()
                            return true
                        end
                    }))
                end
            }
        end
    end
}, true)

SMODS.Joker:take_ownership('hanging_chad', {
    config = { extra = { repetitions = 1 } },

    calculate = function(self, card, context)
        if context.repetition and context.cardarea == G.play then
            local total_reps = 0

            if context.other_card == context.scoring_hand[1] then
                total_reps = total_reps + card.ability.extra.repetitions
            end

            if context.other_card == context.scoring_hand[#context.scoring_hand] then
                total_reps = total_reps + card.ability.extra.repetitions
            end

            if total_reps > 0 then
                return {
                    repetitions = total_reps
                }
            end
        end
    end,

}, true)

SMODS.Joker:take_ownership('cloud_9', {
    config = {
        extra = 1,
        count = 0
    },

    calculate = function(self, card, context)

        if context.individual
        and context.cardarea == G.play
        and context.other_card:get_id() == 9 then
            card.ability.count = card.ability.count + 1
        end

        if context.setting_blind then
            card.ability.count = 0
        end
    end,

    calc_dollar_bonus = function(self, card)
        local nine_tally = card.ability.count or 0

        for _, playing_card in ipairs(G.playing_cards) do
            if playing_card:get_id() == 9 then
                nine_tally = nine_tally + 1
            end
        end

        return nine_tally > 0 and card.ability.extra * nine_tally or nil
    end,

    loc_vars = function(self, info_queue, card)
        local nine_tally = card.ability.count or 0

        if G.playing_cards then
            for _, playing_card in ipairs(G.playing_cards) do
                if playing_card:get_id() == 9 then
                    nine_tally = nine_tally + 1
                end
            end
        end

        return {
            vars = {
                card.ability.extra,
                card.ability.extra * nine_tally
            }
        }
    end
}, true)

SMODS.Joker:take_ownership('erosion',{
    name = 'erosion',
    config = { extra = { Xmult_gain = 0.25, Xmult = 1 } },
    loc_vars = function(self, info_queue, card)
        info_queue[#info_queue + 1] = G.P_CENTERS.m_stone 
        return { vars = { card.ability.extra.Xmult_gain, card.ability.extra.Xmult } }
    end,
    calculate = function(self, card, context)
        if context.before and not context.blueprint then
            for _, scored_card in ipairs(context.scoring_hand) do
                if SMODS.has_enhancement(scored_card, 'm_stone') and not scored_card.debuff then
                scored_card.stone_eaten = true
                    SMODS.scale_card(card, {
                    ref_table = card.ability.extra,
                    ref_value = "Xmult",
                    scalar_value = "Xmult_gain",
                    message_key = 'a_xmult',
                    })
                    break 
                end
            end
        end

        
        if context.destroy_card and context.cardarea == G.play
            and context.destroy_card.stone_eaten and not context.blueprint then
            context.destroy_card.stone_eaten = nil
            return { remove = true }
        end

        if context.joker_main then
            return { xmult = card.ability.extra.Xmult }
        end
    end,
} , true)

SMODS.Joker:take_ownership('throwback',{
    blueprint_compat = false,
    name = 'throwback',
    config = { extra = { used = false, pending = false } },
    loc_vars = function(self, info_queue, card)
        return { vars = {
            card.ability.extra.used and localize('k_throwback_done') or localize('k_throwback_left')
        } }
    end,
    calculate = function(self, card, context)
        -- Arm: a pack was skipped and this round's use is still available
        if context.skipping_booster and not context.blueprint and not card.ability.extra.used then
            card.ability.extra.used = true
            card.ability.extra.pending = context.booster.key
        end

        -- Fire: the skipped pack has fully closed, so open the copy
        if context.ending_booster and not context.blueprint and card.ability.extra.pending then
            local key = card.ability.extra.pending
            card.ability.extra.pending = false

            local lock = card.ID
            G.CONTROLLER.locks[lock] = true -- stops the player clicking away mid-transition
            G.E_MANAGER:add_event(Event({
                trigger = 'after',
                delay = 0.4,
                func = function()
                    -- same way Charm Tag & co. open their packs (from VanillaRemade)
                    local booster = SMODS.create_card { key = key, area = G.play }
                    booster.T.x = G.play.T.x + G.play.T.w / 2 - G.CARD_W * 1.27 / 2
                    booster.T.y = G.play.T.y + G.play.T.h / 2 - G.CARD_H * 1.27 / 2
                    booster.T.w = G.CARD_W * 1.27
                    booster.T.h = G.CARD_H * 1.27
                    booster.cost = 0
                    booster.from_tag = true
                    G.FUNCS.use_card({ config = { ref_table = booster } })
                    booster:start_materialize()
                    G.CONTROLLER.locks[lock] = nil
                    return true
                end
            }))
            return {
                message = localize('k_again_ex'),
                colour = G.C.FILTER
            }
        end

        -- Reset for the next round
        if context.end_of_round and context.main_eval and not context.game_over
            and not context.blueprint and card.ability.extra.used then
            card.ability.extra.used = false
            return {
                message = localize('k_reset'),
                colour = G.C.GREEN
            }
        end
    end,
} , true)

SMODS.Joker:take_ownership('glass', {
    config = {
        no_glass_joker_effect = true
    },

    calculate = function(self, card, context)
        return nil
    end
}, true)

SMODS.Joker:take_ownership('merry_andy', {
    config = {
        extra = {
            d_size = 3,
            c_size = -1
        }
    },

    loc_vars = function(self, info_queue, card)
        return {
            vars = {
                card.ability.extra.d_size,
                card.ability.extra.c_size
            }
        }
    end,

    add_to_deck = function(self, card, from_debuff)
        G.GAME.round_resets.discards =
            G.GAME.round_resets.discards + card.ability.extra.d_size

        ease_discard(card.ability.extra.d_size)

        G.consumeables.config.card_limit =
            G.consumeables.config.card_limit + card.ability.extra.c_size
    end,

    remove_from_deck = function(self, card, from_debuff)
        G.GAME.round_resets.discards =
            G.GAME.round_resets.discards - card.ability.extra.d_size

        ease_discard(-card.ability.extra.d_size)

        G.consumeables.config.card_limit =
            G.consumeables.config.card_limit - card.ability.extra.c_size
    end
}, true)

SMODS.Joker:take_ownership('steel_joker', {
    name = 'steel_joker',
    config = {
        no_steel_joker_effect = true
    },

    calculate = function(self, card, context)
        return nil
    end
}, true)

SMODS.Joker:take_ownership('stone', {
    config = {
        extra = 25
    }
}, true)

assert(SMODS.load_file("src/jokers/flowerPot.lua"))()

SMODS.Joker:take_ownership('satellite', {
    config = {
        hand = nil
    },

    set_ability = function(self, card, initial, delay_sprites)
        local hands = {}

        for hand, data in pairs(G.GAME.hands) do
            if data.visible ~= false then
                hands[#hands + 1] = hand
            end
        end

        if #hands > 0 then
            card.ability.hand = pseudorandom_element(
                hands,
                pseudoseed('satellite')
            )
        end
    end,

    loc_vars = function(self, info_queue, card)
        return {
            vars = {
                card.ability.hand
                    and localize(card.ability.hand, 'poker_hands')
                    or "???"
            }
        }
    end,

    calc_dollar_bonus = function(self, card)
        if not card.ability.hand then
            return nil
        end

        local hand = G.GAME.hands[card.ability.hand]

        if hand and hand.level > 0 then
            return 2 * hand.level
        end

        return nil
    end,

    calculate = function(self, card, context)

        if context.after
            and context.scoring_name == card.ability.hand
        then
            local hands = {}

            for hand, data in pairs(G.GAME.hands) do
                if data.visible ~= false
                    and hand ~= card.ability.hand
                then
                    hands[#hands + 1] = hand
                end
            end

            if #hands > 0 then
                card.ability.hand = pseudorandom_element(
                    hands,
                    pseudoseed('satellite_change')
                )

                return {
                    message = localize('k_reset')
                }
            end
        end
    end
}, true)

SMODS.Joker:take_ownership('shoot_the_moon', {

    name = 'stm',

    calculate = function(self, card, context)

        -- Convert suits exactly once, when Play Hand is pressed.
        if context.press_play then
            -- Build the highlighted cards in left-to-right hand order,
            -- not selection-click order.
            local ordered_highlighted = {}
            for _, c in ipairs(G.hand.cards) do
                if c.highlighted then
                    ordered_highlighted[#ordered_highlighted + 1] = c
                end
            end

            if #ordered_highlighted > 0 then
                local first_card = ordered_highlighted[1]
                if first_card:get_id() == 12 then
                    local suit = first_card.base.suit
                    for i = 2, #ordered_highlighted do
                        if ordered_highlighted[i].base.suit ~= suit then
                            ordered_highlighted[i]:change_suit(suit)
                        end
                    end
                end
            end
        end

        -- Safety net: also confirm the Flush label using hand-position order.
        if context.evaluate_poker_hand
            and context.full_hand
            and #context.full_hand >= 5
        then
            local ordered = {}
            for _, c in ipairs(G.hand.cards) do
                if c.highlighted then
                    ordered[#ordered + 1] = c
                end
            end
            local first_card = ordered[1]
            if first_card and first_card:get_id() == 12 then
                return {
                    replace_scoring_name = "Flush"
                }
            end
        end

    end

}, true)

--#endregion

--#region Reroll Changes

local old_calculate_reroll_cost = calculate_reroll_cost

function calculate_reroll_cost(skip_increment)
    old_calculate_reroll_cost(skip_increment)

    if skip_increment then
        return
    end

    if G.GAME.current_round.free_rerolls > 0 then
        return
    end

    local extra_increase = 0

    if G.GAME.selected_back_key.key == 'b_black' then
        extra_increase = extra_increase + 1
    end

    if G.GAME.modifiers.extra_reroll_cost then
        extra_increase = extra_increase + 1
    end

    G.GAME.current_round.reroll_cost_increase =
        G.GAME.current_round.reroll_cost_increase + extra_increase

    G.GAME.current_round.reroll_cost =
        G.GAME.current_round.reroll_cost + extra_increase
end

--#endregion    

--#region Stakes

SMODS.Stake:take_ownership('blue', {
    modifiers = function()
        G.GAME.modifiers.extra_reroll_cost = true
    end,
}, true)

--#endregion

--#region Vouchers

SMODS.Voucher:take_ownership('hone', {
    redeem = function(self, card)
        G.GAME.common_mod = 0.45 / 0.70
        G.GAME.uncommon_mod = 0.50 / 0.25
        G.GAME.rare_mod = 0.05 / 0.05

        print("HONE:", G.GAME.common_mod, G.GAME.uncommon_mod, G.GAME.rare_mod)
    end
}, true)

SMODS.Voucher:take_ownership('glow_up', {
    redeem = function(self, card)
        G.GAME.common_mod = 0.40 / 0.70
        G.GAME.uncommon_mod = 0.50 / 0.25
        G.GAME.rare_mod = 0.10 / 0.05

        print("GLOW UP:", G.GAME.common_mod, G.GAME.uncommon_mod, G.GAME.rare_mod)
    end
}, true)

SMODS.Voucher:take_ownership('magic_trick', {
    calculate = function(self, card, context)
        -- Playing cards can appear in the shop as Enhanced cards
        if context.create_shop_card and (context.set == "Base"
                or context.set == "Enhanced") then -- we check for enhanced anyway so we don't overcorrect with other effects
            return {
                shop_create_flags = { set = "Playing Card", key_append = "balatroRebalanced_magic_trick_enhancement" }
            }
        end
        -- Shop playing cards have a chance to get an edition and/or a seal
        if context.modify_shop_card and
            (context.card.ability.set == 'Enhanced' or context.card.ability.set == 'Default') then -- is a playing card
            if pseudorandom('balatroRebalanced_magic_trick_edition_poll') > 0.8 then
                context.card:set_edition(SMODS.poll_edition { key = 'balatroRebalanced_magic_trick_edition', no_negative = true, guaranteed = true })
            end
            if pseudorandom('balatroRebalanced_magic_trick_seal_poll') > 0.6 then
                context.card:set_seal(SMODS.poll_seal { key = 'balatroRebalanced_magic_trick_seal', guaranteed = true })
            end
        end
    end,
}, true)

SMODS.Voucher:take_ownership('illusion', {

    name = 'illusion',

    config = {
        extra = {
            rerolls_needed = 5
        }
    },

    loc_vars = function(self, info_queue, card)
        return {
            vars = {
                5,
                G.GAME.illusion_rerolls or 0
            }
        }
    end,

    calculate = function(self, card, context)

        if context.reroll_shop and G.shop_booster then

            G.GAME.illusion_rerolls =
                (G.GAME.illusion_rerolls or 0) + 1

            if G.GAME.illusion_rerolls >= 5 then

                G.GAME.illusion_rerolls = 0

                if #G.shop_booster.cards < G.shop_booster.config.card_limit then
                    SMODS.add_booster_to_shop()

                    return {
                        message = localize('k_active_ex')
                    }
                end
            end
        end
    end,

}, true)

--#endregion

--#region Seals

local blue_seal_eor_ref = Card.get_end_of_round_effect
function Card:get_end_of_round_effect(context)
    local ret = blue_seal_eor_ref(self, context)

    if self.seal == 'Blue' and ret.effect then
        self.ability.blue_seal_planets_generated =
            (self.ability.blue_seal_planets_generated or 0) + 1

        if self.ability.blue_seal_planets_generated >= 3 then
            self:start_dissolve()
        end
    end

    return ret
end

G.P_SEALS.Blue.loc_vars = function(self, info_queue, card)
    local generated = (card and card.ability.blue_seal_planets_generated) or 0
    local left = 3 - generated
    if left < 0 then left = 0 end
    return { vars = { left } }
end

--#endregion

--#region Enhancements

SMODS.Enhancement:take_ownership('glass', {
    config = {
        Xmult = 2,
        extra = { odds = 4 }
    },
    shatters = true,

    loc_vars = function(self, info_queue, card)
        local xmult = card.ability.Xmult
        local odds = card.ability.extra.odds

        if G.jokers and next(SMODS.find_card('j_glass')) then
            xmult = 3
            odds = 2
        end

        local numerator, denominator =
            SMODS.get_probability_vars(card, 1, odds, 'vremade_glass')

        return {
            vars = {
                xmult,
                numerator,
                denominator
            }
        }
    end,

    calculate = function(self, card, context)
        if context.destroy_card
            and context.cardarea == G.play
            and context.destroy_card == card
        then
            local odds = card.ability.extra.odds

            if G.jokers and next(SMODS.find_card('j_glass')) then
                odds = 2
            end

            if SMODS.pseudorandom_probability(
                card,
                'vremade_glass',
                1,
                odds
            ) then
                card.glass_trigger = true
                return { remove = true }
            end
        end
    end
}, true)

--#endregion

--#region Decks

SMODS.Back:take_ownership('ghost',{
    config = { spectral_rate = 2, consumables = { 'c_ouija' } },
} , true)

--#endregion