--#region Atlases

SMODS.Atlas{
    key = 'placeholders',
    path = 'placeholders.png',
    px = 71,
    py = 95
}

SMODS.Atlas{ key = 'flower_pot_spades',  path = 'Flower_Pot_Spades.png',  px = 71, py = 95 }
SMODS.Atlas{ key = 'flower_pot_clubs',   path = 'Flower_Pot_Clubs.png',   px = 71, py = 95 }
SMODS.Atlas{ key = 'flower_pot_hearts',  path = 'Flower_Pot_Hearts.png',  px = 71, py = 95 }
SMODS.Atlas{ key = 'flower_pot_diamond', path = 'Flower_Pot_Diamond.png', px = 71, py = 95 }


--#endregion

--#region JokerDisplay

if JokerDisplay then
    SMODS.load_file("joker_display_overrides.lua")()
end

--#endregion


--#region File Loading

local jokers_src = SMODS.NFS.getDirectoryItems(SMODS.current_mod.path .. "src/jokers")


for _, file in ipairs(jokers_src) do
    assert(SMODS.load_file("src/jokers/" .. file))()
end

assert(SMODS.load_file('highlight_changed.lua'))()

assert(SMODS.load_file("shop_skip.lua"))()
assert(SMODS.load_file("tarotTycoon.lua"))()
--#endregion

--#region Hand Levels

SMODS.PokerHand:take_ownership('High Card', { l_mult = 1, l_chips = 5 }, true)
SMODS.PokerHand:take_ownership('Pair', { l_mult = 1, l_chips = 10 }, true)
SMODS.PokerHand:take_ownership('Two Pair', { l_mult = 2, l_chips = 20 }, true)
SMODS.PokerHand:take_ownership('Three of a Kind', { l_mult = 2, l_chips = 30 }, true)
SMODS.PokerHand:take_ownership('Straight', { l_mult = 3, l_chips = 30 }, true)
SMODS.PokerHand:take_ownership('Flush', { l_mult = 2, l_chips = 20 }, true)
SMODS.PokerHand:take_ownership('Full House', { l_mult = 3, l_chips = 25 }, true)
SMODS.PokerHand:take_ownership('Four of a Kind', { l_mult = 4, l_chips = 30 }, true)
SMODS.PokerHand:take_ownership('Straight Flush', { l_mult = 5, l_chips = 50 }, true)
SMODS.PokerHand:take_ownership('Five of a Kind', { l_mult = 4, l_chips = 40 }, true)
SMODS.PokerHand:take_ownership('Flush House', { l_mult = 5, l_chips = 50 }, true)
SMODS.PokerHand:take_ownership('Flush Five', { l_mult = 3, l_chips = 50 }, true)

--#endregion

--#region Spectral Cards

SMODS.Consumable:take_ownership('immolate', {config = {remove_card = true, extra = {destroy = 4, dollars = 10}}}, true)

local WRAITH_MONEY = 5

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
                    G.GAME.reba_no_diamond_bonus = true   -- Wraith sets money to an exact amount
                    ease_dollars(WRAITH_MONEY - G.GAME.dollars, true)
                    G.GAME.reba_no_diamond_bonus = nil
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

    if context.remove_playing_cards then
        local broken = 0
        for _, c in ipairs(context.removed or {}) do
            if c.shattered then broken = broken + 1 end
        end
        if broken > 0 then G.GAME.reba_glass_broken = (G.GAME.reba_glass_broken or 0) + broken end
    end

    if context.starting_shop then
        G.GAME.planet_tycoon_active = true
        G.GAME.planet_tycoon_discount = 0
        calculate_reroll_cost(true)
    end

    if context.setting_blind then
        G.GAME.planet_tycoon_active = false
        G.GAME.planet_tycoon_discount = 0
    end

    -- JUGGLE TAG: lose 1 bonus hand size at the end of every round
    if context.end_of_round and context.main_eval and not context.game_over then
        if (G.GAME.juggle_bonus or 0) > 0 then
            G.hand:change_size(-1)
            G.GAME.juggle_bonus = G.GAME.juggle_bonus - 1
        end
    end

    -- UNCOMMON TAG: next Uncommon Joker you buy becomes Rental and is duplicated.
    -- If there is no room for the copy, nothing happens and the tag waits for the next Uncommon.
    if context.buying_card and not context.blueprint and context.card
        and context.card.ability and context.card.ability.set == 'Joker'
        and context.card.config and context.card.config.center
        and context.card.config.center.rarity == 2 then

        local tag_ref
        for _, t in ipairs(G.GAME.tags or {}) do
            if t.key == 'tag_uncommon' and not t.triggered then
                tag_ref = t
                break
            end
        end

        if tag_ref then
            local bought = context.card
            local frames = 0
            G.E_MANAGER:add_event(Event({
                trigger = 'immediate',
                blocking = false,
                blockable = false,
                func = function()
                    frames = frames + 1
                    if frames > 600 then return true end
                    if bought.area ~= G.jokers then return false end   -- purchase not finished yet
                    if tag_ref.triggered then return true end

                    -- need a free slot for the copy (a negative bought Joker already raised the limit)
                    if #G.jokers.cards >= G.jokers.config.card_limit then return true end

                    bought:set_rental(true)
                    local copy = copy_card(bought, nil, nil, nil, bought.edition and bought.edition.negative)
                    if copy.set_rental then copy:set_rental(true) end
                    copy:start_materialize()
                    copy:add_to_deck()
                    G.jokers:emplace(copy)

                    tag_ref:yep('+', G.C.GREEN, function() return true end)
                    tag_ref.triggered = true
                    return true
                end
            }))
        end
    end

    if context.debuff_card and context.debuff_card.ability.ouija_debuff then
        return { debuff = true }
    end

    if context.ante_change and context.ante_end then
        for _, playing_card in ipairs(G.playing_cards or {})do
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

                -- Eternal and Perishable can't coexist, so Hex swaps one for the other
                eligible_card.ability.eternal = false

                -- the sticker needs its countdown set up too, otherwise calculate_perishable
                -- compares nil at end of round and crashes
                if not eligible_card.ability.perishable then
                    eligible_card.ability.perishable = true
                    eligible_card.ability.perish_tally = G.GAME.perishable_rounds
                end

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
    config = { extra = { aces = 2, tarots = 1 } },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.aces, card.ability.extra.tarots } }
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

                local new_cards = {}
                for i = 1, card.ability.extra.aces do
                    -- each Ace rolls its own enhancement
                    local enhancement = SMODS.poll_enhancement { guaranteed = true, options = cen_pool, key = "vremade_grim_card" .. i }
                    new_cards[#new_cards + 1] = SMODS.add_card {
                        set = "Base",
                        rank = 'Ace',
                        enhancement = enhancement,
                        area = G.hand,
                        key_append = "vremade_grim_card" .. i
                    }
                end
                SMODS.calculate_context({ playing_card_added = true, cards = new_cards })
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
    config = { extra = { destroy = 2, cards = 2 } },
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
                G.hand:change_size(2)
                return true
            end
        }))

        delay(0.2)

        if banned_hand then
            G.GAME.csau_black_hole_banned_hands[banned_hand] = true
            card_eval_status_text(card, 'extra', nil, nil, nil, {
                message = "Banned: " .. localize(banned_hand, 'poker_hands'),
                colour = G.C.RED
        })
        else
        card_eval_status_text(card, 'extra', nil, nil, nil, {
            message = "None left!",
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

SMODS.Joker:take_ownership('8_ball', {config = {extra = 3, }}, true)

SMODS.Joker:take_ownership('runner', {config = {extra = {chips = 0, chip_mod = 20}}}, true)

SMODS.Joker:take_ownership('vampire', {config = {extra = 0.2, Xmult = 1}}, true)

SMODS.Joker:take_ownership('mail', {config = {extra = 4}}, true)

SMODS.Joker:take_ownership('flash', {config = {extra = 3, mult = 0}}, true)

-- FORTUNE TELLER: only counts Tarot cards used AFTER you got it.
-- On acquiring it, we store the run's current Tarot-usage total as a baseline,
-- and every calculation uses (current total - baseline).
local function fortune_tarots_since(card)
    local total = (G.GAME and G.GAME.consumeable_usage_total and G.GAME.consumeable_usage_total.tarot) or 0
    -- Fallback (collection / tooltip cards that never got add_to_deck): show 0
    local baseline = card.ability.extra.baseline or total
    return math.max(0, total - baseline)
end

SMODS.Joker:take_ownership('fortune_teller', {
    config = { extra = { mult = 2, baseline = nil } },

    add_to_deck = function(self, card, from_debuff)
        -- from_debuff = true just means it got un-debuffed, not freshly acquired
        if not from_debuff then
            card.ability.extra.baseline =
                (G.GAME.consumeable_usage_total and G.GAME.consumeable_usage_total.tarot) or 0
        end
    end,

    loc_vars = function(self, info_queue, card)
        return { vars = {
            card.ability.extra.mult,
            card.ability.extra.mult * fortune_tarots_since(card),
        } }
    end,

    calculate = function(self, card, context)
        if context.using_consumeable and not context.blueprint and context.consumeable.ability.set == "Tarot" then
            return {
                message = localize { type = 'variable', key = 'a_mult',
                    vars = { fortune_tarots_since(card) * card.ability.extra.mult } },
            }
        end
        if context.joker_main then
            return { mult = card.ability.extra.mult * fortune_tarots_since(card) }
        end
    end,
}, true)

SMODS.Joker:take_ownership('vagabond',{config = {extra = 6}} , true)

SMODS.Joker:take_ownership('card_sharp',{config = {extra = {Xmult = 2}}} , true)

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

SMODS.Joker:take_ownership('marble', {
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
        if context.before and context.full_hand and G.GAME.current_round.hands_played == 0 then
            -- Snapshot each card's base rank once. get_id() returns a random
            -- value for Stone Cards, which breaks table.sort's consistency
            -- requirement ("invalid order function for sorting").
            local entries = {}
            for i, c in ipairs(context.full_hand) do
                if not SMODS.has_enhancement(c, 'm_stone') then
                    entries[#entries + 1] = { card = c, rank = c.base.id, idx = i }
                end
            end

            if #entries == 0 then return end

            table.sort(entries, function(a, b)
                if a.rank ~= b.rank then return a.rank < b.rank end
                return a.idx < b.idx -- stable tie-break
            end)

            for i = 1, math.min(2, #entries) do
                entries[i].card:set_ability(G.P_CENTERS.m_stone)
            end

            return {
                message = "Stone!"
            }
        end
    end,
}, true)

SMODS.Joker:take_ownership('j_loyalty_card', {
    config = {
        extra = {
            hands = 0,
            required = 4,
            every = 4,
            x_mult = 4,
            ready = false
        }
    },
    eternal_compat = false,

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

                -- Same pattern as vanilla's own Loyalty Card: keep re-triggering
                -- the shake/wiggle for as long as `ready` stays true. Stops
                -- mattering once the card cashes out and dissolves below.
                local eval = function(c) return c.ability.extra.ready end
                juice_card_until(card, eval, true)

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
    blueprint_compat = false,
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

SMODS.Joker:take_ownership('erosion', {
    name = 'erosion',
    config = { extra = { Xmult_gain = 0.25, Xmult = 1 } },
    in_pool = function(self, args)
        if G.playing_cards then
            for _, playing_card in ipairs(G.playing_cards) do
                if SMODS.has_enhancement(playing_card, 'm_stone') then
                    return true
                end
            end
        end
        return false
    end,
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
}, true)

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

SMODS.Joker:take_ownership('merry_andy', {
    blueprint_compat = false,
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
    end,

    -- Unlock: skip 6 shops in a single run
    unlock_condition = { type = 'shop_skips', extra = 6 },
    check_for_unlock = function(self, args)
        return args.type == 'shop_skips' and (G.GAME.skips or 0) >= 6
    end,
}, true)

-- Wee Joker unlock: skip 9 shops in a single run
SMODS.Joker:take_ownership('wee', {
    unlock_condition = { type = 'shop_skips', extra = 9 },
    check_for_unlock = function(self, args)
        return args.type == 'shop_skips' and (G.GAME.skips or 0) >= 9
    end,
}, true)

SMODS.Joker:take_ownership('steel_joker', {
    blueprint_compat = false,
    name = 'steel_joker',
    config = {
        no_steel_joker_effect = true
    },

    calculate = function(self, card, context)
        return nil
    end
}, true)

SMODS.Joker:take_ownership('stone', {
    blueprint_compat = false,
    config = {
        extra = 25
    },

    calculate = function(self, card, context)
        return nil
    end
}, true)

local function satellite_most_played()
    if not (G and G.GAME and G.GAME.hands and G.handlist) then return nil end

    local best, best_played = nil, -1
    -- G.handlist runs best -> worst hand, and ">=" lets later entries win ties,
    -- so a fresh run (everything at 0 plays) defaults to High Card
    for _, name in ipairs(G.handlist) do
        local data = G.GAME.hands[name]
        if data and data.visible ~= false and data.played >= best_played then
            best, best_played = name, data.played
        end
    end
    return best
end

SMODS.Joker:take_ownership('satellite', {
    blueprint_compat = false,
    config = {
        extra = 2,   -- $ per hand level
        hand = nil
    },

    set_ability = function(self, card, initial, delay_sprites)
        card.ability.hand = satellite_most_played()
    end,

    loc_vars = function(self, info_queue, card)
        local display_hand = card.ability.hand or satellite_most_played()

        return {
            vars = {
                card.ability.extra,
                display_hand
                    and localize(display_hand, 'poker_hands')
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
            return card.ability.extra * hand.level
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

SMODS.Joker:take_ownership('shoot_the_moon', {blueprint_compat = false, rarity = 2, cost = 7}, true)

local old_evaluate_play = G.FUNCS.evaluate_play

G.FUNCS.evaluate_play = function(e)
    local shoot_the_moon = false

    if G.jokers and G.jokers.cards then
        for _, joker in ipairs(G.jokers.cards) do
            if joker.ability and joker.ability.name == 'Shoot the Moon' then
                shoot_the_moon = true
                break
            end
        end
    end

    if shoot_the_moon and G.play and G.play.cards and #G.play.cards > 0 then
        local queen = G.play.cards[1]

        if queen:get_id() == 12 then
            for i = 2, #G.play.cards do
                G.play.cards[i]:change_suit(queen.base.suit)
            end
        end
    end

    old_evaluate_play(e)
end

local function roll_campfire_target()
    -- Card sets Campfire can ask you to sell; values must match `card.ability.set`.
    -- Fully random: the same target can come up several times in a row.
    -- The list lives inside the function so it can never be nil or out of scope.
    return pseudorandom_element({ 'Joker', 'Tarot', 'Planet' }, pseudoseed('campfire_target'))
end

SMODS.Joker:take_ownership('campfire', {
    -- rarity, cost, pos, blueprint_compat, etc. stay as vanilla
    config = { extra = { xmult_gain = 0.25, xmult = 1 } },

    set_ability = function(self, card, initial, delay_sprites)
        -- Only roll if there is no target yet, so a reloaded/copied card keeps its target
        card.ability.extra.target = card.ability.extra.target or roll_campfire_target()
    end,

    loc_vars = function(self, info_queue, card)
        -- Fallback covers tooltip/stand-in cards that never went through set_ability
        local target = card.ability.extra.target or 'Joker'
        return {
            vars = {
                card.ability.extra.xmult_gain,
                card.ability.extra.xmult,
                localize('k_' .. string.lower(target)), -- "Joker" / "Tarot" / "Planet"
                colours = { G.C.SECONDARY_SET[target] },
            }
        }
    end,

    calculate = function(self, card, context)
        -- Ignore blueprint copies, and ignore Campfire being sold itself
        if context.selling_card and not context.blueprint and context.card ~= card then
            local extra = card.ability.extra

            if context.card.ability.set == extra.target then
                -- Correct sale: scale up, then pick a new target
                -- See note about SMODS Scaling Manipulation on the wiki
                extra.xmult = extra.xmult + extra.xmult_gain
                extra.target = roll_campfire_target()
                return {
                    message = localize('k_upgrade_ex')
                }
            elseif extra.xmult > 1 then
                -- Wrong sale: reset (target stays the same)
                extra.xmult = 1
                return {
                    message = localize('k_reset'),
                    colour = G.C.RED
                }
            end
        end

        if context.joker_main then
            return {
                xmult = card.ability.extra.xmult
            }
        end
    end,
}, true) -- silent: suppresses the take_ownership log message

SMODS.Joker:take_ownership('matador', {
    blueprint_compat = true,
    name = 'testmatador',
    -- rarity, cost, pos, blueprint_compat etc. stay as vanilla
    config = { extra = { hands = 3 } },

    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.hands } }
    end,

    calculate = function(self, card, context)
        -- context.blind is the blind prototype; only Boss Blinds (incl. Showdown) have `.boss`
        if context.setting_blind and context.blind.boss then
            G.E_MANAGER:add_event(Event({
                func = function()
                    -- Temporary: only affects the current blind, not round_resets.hands
                    ease_hands_played(card.ability.extra.hands)
                    SMODS.calculate_effect(
                        { message = localize { type = 'variable', key = 'a_hands', vars = { card.ability.extra.hands } } },
                        context.blueprint_card or card)
                    return true
                end
            }))
            return nil, true -- This is for Joker retrigger purposes
        end
    end,
}, true) 

-- BULL: +2 chips every time you earn money. Vanilla `extra` stays a number so vanilla code can't crash.
SMODS.Joker:take_ownership('bull', {
    config = { extra = 3, bull_chips = 0 },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra, card.ability.bull_chips or 0 } }
    end,
    calculate = function(self, card, context)
        if context.joker_main and (card.ability.bull_chips or 0) > 0 then
            return { chips = card.ability.bull_chips }
        end
    end,
}, true)

local ease_dollars_ref = ease_dollars
function ease_dollars(mod, instant)
    if mod and mod > 0 and G.jokers then
        for _, joker in ipairs(G.jokers.cards) do
            if joker.config.center.key == 'j_bull' then
                joker.ability.bull_chips = (joker.ability.bull_chips or 0) + joker.ability.extra
                card_eval_status_text(joker, 'extra', nil, nil, nil, {
                    message = localize{type = 'variable', key = 'a_chips', vars = {joker.ability.extra}},
                    colour = G.C.CHIPS,
                })
            end
        end
    end
    return ease_dollars_ref(mod, instant)
end

-- BOOTSTRAPS: vanilla `extra.dollars` / `extra.mult` kept (so vanilla code is safe); new state in separate fields
SMODS.Joker:take_ownership('bootstraps', {
    config = { extra = { dollars = 1, mult = 4 }, bs_mult = 0, bs_last = false },
    loc_vars = function(self, info_queue, card)
        return { vars = {
            card.ability.extra.mult,
            card.ability.bs_mult or 0,
            card.ability.bs_last or 0,
        } }
    end,
    calculate = function(self, card, context)
        if context.setting_blind and not context.blueprint then
            local now = G.GAME.dollars
            local last = card.ability.bs_last
            card.ability.bs_last = now   -- always the new target, even if lower

            if last then
                if now > last then
                    -- hit the target: grow
                    card.ability.bs_mult = (card.ability.bs_mult or 0) + card.ability.extra.mult
                    return {
                        message = localize{type = 'variable', key = 'a_mult', vars = {card.ability.extra.mult}},
                        colour = G.C.MULT,
                    }
                elseif (card.ability.bs_mult or 0) > 0 then
                    -- missed the target (equal or lower): reset
                    card.ability.bs_mult = 0
                    return {
                        message = localize('k_reset'),
                        colour = G.C.RED,
                    }
                end
            end
        end
        if context.joker_main and (card.ability.bs_mult or 0) > 0 then
            return { mult = card.ability.bs_mult }
        end
    end,
}, true)

-- HOLOGRAM: +X0.2 Mult per card added to the deck (instead of 0.25)
SMODS.Joker:take_ownership('hologram', {
    config = { extra = 0.2, Xmult = 1 },   -- config is replaced, not merged, so keep Xmult
}, true)

-- HIKER: +7 permanent chips per played card, and the chips are also scored immediately
-- (vanilla only upgrades the card, so the bonus did nothing until the next time it scored)
SMODS.Joker:take_ownership('hiker', {
    config = { extra = 7 },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra } }
    end,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play then
            local scored = context.other_card
            scored.ability.perma_bonus = (scored.ability.perma_bonus or 0) + card.ability.extra
            return {
                chips = card.ability.extra,   -- score it right now
                extra = { message = localize('k_upgrade_ex'), colour = G.C.CHIPS, message_card = scored },
            }
        end
    end,
}, true)

-- SPLASH: every played card scores; cards that wouldn't have scored naturally trigger an extra time
SMODS.Joker:take_ownership('splash', {
    blueprint_compat = false,

    calculate = function(self, card, context)
        if context.modify_scoring_hand then
            -- context.scoring_hand is the natural hand here, so a card missing
            -- from it only scores because of Splash. Set the flag on every call
            -- (true or false) so a stale flag from the hand preview can't stick.
            local natural = false
            for _, c in ipairs(context.scoring_hand) do
                if c == context.other_card then natural = true; break end
            end
            context.other_card.splash_extra = not natural
            return { add_to_hand = true }
        end

        if context.repetition and context.cardarea == G.play
            and context.other_card.splash_extra then
            return { repetitions = 1 }
        end

        if context.after and context.full_hand then
            for _, c in ipairs(context.full_hand) do
                c.splash_extra = nil
            end
        end
    end,
}, true)

-- GLASS JOKER: X0.75 Mult for every Glass Card broken this run, including before you got it
SMODS.Joker:take_ownership('glass', {
    config = { extra = 0.75, x_mult = 1 },
    loc_vars = function(self, info_queue, card)
        local broken = (G.GAME and G.GAME.reba_glass_broken) or 0
        return { vars = { card.ability.extra, 1 + card.ability.extra * broken } }
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            local x = 1 + card.ability.extra * ((G.GAME and G.GAME.reba_glass_broken) or 0)
            if x > 1 then return { xmult = x } end
        end
    end,
}, true)

--#endregion

--#region Reroll Changes

local old_calculate_reroll_cost = calculate_reroll_cost

function calculate_reroll_cost(skip_increment)
    -- a reroll that was paid for by the D6 Tag must not raise the price of later ones
    if G.GAME.reba_d6_used then
        G.GAME.reba_d6_used = nil
        skip_increment = true
    end

    -- D6 Tag rerolls are free (Chaos the Clown's free rerolls get used first)
    if (G.GAME.reba_d6_free or 0) > 0 and (G.GAME.current_round.free_rerolls or 0) <= 0 then
        G.GAME.current_round.reroll_cost = 0
        return
    end

    old_calculate_reroll_cost(skip_increment)

    -- Free rerolls already set the cost to 0, so no extra logic is needed
    if G.GAME.current_round.free_rerolls > 0 then
        return
    end

    if not skip_increment then
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

    if G.GAME.planet_tycoon_active then
        local discount = G.GAME.planet_tycoon_discount or 0

        if discount > 0 then
            discount = math.min(discount, G.GAME.current_round.reroll_cost)
            G.GAME.planet_tycoon_discount = discount

            G.GAME.current_round.reroll_cost = G.GAME.current_round.reroll_cost - discount
        end
    end
end

-- Spend one D6 free reroll whenever a reroll is made with one
local reroll_shop_ref = G.FUNCS.reroll_shop
G.FUNCS.reroll_shop = function(e)
    if (G.GAME.current_round.free_rerolls or 0) <= 0 and (G.GAME.reba_d6_free or 0) > 0 then
        G.GAME.reba_d6_free = G.GAME.reba_d6_free - 1
        G.GAME.reba_d6_used = true
    end
    return reroll_shop_ref(e)
end

-- Clears the shop rule when leaving the shop
local toggle_shop_ref = G.FUNCS.toggle_shop
G.FUNCS.toggle_shop = function(e)
    if G.GAME then
        G.GAME.shop_rules = nil
    end
    return toggle_shop_ref(e)
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

-- Base shop rarity weights: Common 0.70, Uncommon 0.25, Rare 0.05 (total 1.00).
-- Each *_mod below is (new weight) / (base weight), and the new weights always add up to 1.00.
-- Hone:    Uncommon x1.5 -> 0.375, Rare unchanged 0.05, Common takes the rest: 1 - 0.375 - 0.05 = 0.575
SMODS.Voucher:take_ownership('hone', {
    redeem = function(self, card)
        G.GAME.common_mod = 0.575 / 0.70
        G.GAME.uncommon_mod = 0.375 / 0.25   -- = 1.5
        G.GAME.rare_mod = 0.05 / 0.05

    end
}, true)

SMODS.Voucher:take_ownership('glow_up', {
    redeem = function(self, card)
        -- Glow Up (replaces Hone's values): Uncommon stays x1.5 -> 0.375, Rare x2 -> 0.10,
        -- Common takes the rest: 1 - 0.375 - 0.10 = 0.525
        G.GAME.common_mod = 0.525 / 0.70
        G.GAME.uncommon_mod = 0.375 / 0.25   -- = 1.5
        G.GAME.rare_mod = 0.10 / 0.05        -- = 2

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

-- Planet Merchant: buying a Planet card from the shop refills that one empty slot
SMODS.Voucher:take_ownership('planet_merchant', {
    calculate = function(self, card, context)
        if context.buying_card and context.card
            and context.card.ability.set == 'Planet'
            and G.shop_jokers
        then
            -- short delay so the bought card has left its slot
            G.E_MANAGER:add_event(Event({
                trigger = 'after',
                delay = 0.3,
                func = function()
                    -- add exactly one card, and only if there's actually room
                    if G.shop_jokers and G.shop_jokers.cards
                        and #G.shop_jokers.cards < G.shop_jokers.config.card_limit
                    then
                        G.shop_jokers:emplace(create_card_for_shop(G.shop_jokers))
                    end
                    return true
                end
            }))
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

--#region Decks

SMODS.Back:take_ownership('ghost',{
    config = { spectral_rate = 2, consumables = { 'c_hex' } },
} , true)

SMODS.Back:take_ownership ('black',{config = { hands = 0, joker_slot = 1 },} , true)

--#endregion

--#region Skip Tags
function create_UIBox_blind_tag(blind_choice, run_info)
    return nil
end

SMODS.Tag:take_ownership('boss', {
    in_pool = function(self, args)
        if G.GAME and G.GAME.tags then
            for _, t in ipairs(G.GAME.tags) do
                if t.key == 'tag_boss' then return false end
            end
        end
        return true
    end,
}, true)

--------------------------------------------------------------------------------
-- Shared helpers
--------------------------------------------------------------------------------

local EXTRA_JOKER_RARE_CHANCE = 0.2          -- Buffoon Tag extra joker: 80% Uncommon / 20% Rare
local STANDARD_SEALS = { 'Red', 'Blue', 'Gold', 'Purple' }

-- Kept so any other code calling apply_pack_upgrade() doesn't crash. No tag upgrades packs anymore.
PACK_UPGRADE_TAGS = {}

-- Recompute a pack's option count from its base value + bonuses. Idempotent.
local function refresh_pack_size(card)
    if not (card and card.ability and card.ability.set == 'Booster') then return end
    local center = card.config and card.config.center
    local base = center and center.config and center.config.extra
    if not base then return end

    local bonus = G.GAME and G.GAME.pack_upgrades and G.GAME.pack_upgrades[center.kind] or 0
    local extra_card = card.ability.extra_card and 1 or 0   -- Charm / Buffoon / Standard tag bonus card
    card.ability.extra = base + bonus + extra_card
end

function apply_pack_upgrade(tag_name)
    local def = PACK_UPGRADE_TAGS[tag_name]
    if not def then return end

    G.GAME.pack_upgrades = G.GAME.pack_upgrades or {}
    G.GAME.banned_keys = G.GAME.banned_keys or {}

    local count = (G.GAME.pack_upgrades[def.kind] or 0) + 1
    G.GAME.pack_upgrades[def.kind] = count

    if G.shop_booster and G.shop_booster.cards then
        for _, card in ipairs(G.shop_booster.cards) do
            refresh_pack_size(card)
        end
    end
end

-- Every new pack gets its size computed the moment it is created
local set_ability_ref = Card.set_ability
function Card:set_ability(center, initial, delay_sprites)
    set_ability_ref(self, center, initial, delay_sprites)
    refresh_pack_size(self)
end

-- When a tag-pack opens, wait for it to fill, then turn its LAST card into the announced bonus card.
--   extra_card = { kind = 'center', key = 'c_fool' / 'j_joker' }   -> card becomes that Tarot/Joker
--   extra_card = { kind = 'seal',   key = 'Red' }                  -> card gets that seal
-- Seal bonus card is applied at CREATION time of the pack's last card (synchronous, no timing issues).
-- The polling code below stays as a fallback / for Tarot + Joker bonus cards.
local pack_extra_state = nil
local pack_extra_create_ref = SMODS.create_card
function SMODS.create_card(t)
    local card = pack_extra_create_ref(t)
    local st = pack_extra_state
    if st and t and G.pack_cards and t.area == G.pack_cards then
        st.count = st.count + 1
        if st.count >= st.total then
            pack_extra_state = nil
            if st.spec.kind == 'seal' and card and card.set_seal then
                card:set_seal(st.spec.key, true)
                sendDebugMessage('[reba] bonus seal ' .. tostring(st.spec.key) .. ' applied at creation (card ' .. st.count .. '/' .. st.total .. ')')
            end
        end
    end
    return card
end

local open_ref = Card.open
function Card:open()
    refresh_pack_size(self)
    if self.ability and self.ability.extra_card then
        pack_extra_state = { spec = self.ability.extra_card, total = self.ability.extra, count = 0 }
    else
        pack_extra_state = nil
    end
    local ret = open_ref(self)

    local spec = self.ability and self.ability.extra_card
    if spec then
        local pack = self
        local frames = 0
        G.E_MANAGER:add_event(Event({
            trigger = 'immediate',
            blocking = false,
            blockable = false,
            func = function()
                frames = frames + 1
                if frames > 1200 then return true end  -- give up instead of polling forever
                if not (G.pack_cards and G.pack_cards.cards) then return false end
                if #G.pack_cards.cards < pack.ability.extra then return false end  -- pack not full yet

                local last = G.pack_cards.cards[#G.pack_cards.cards]
                last.reba_no_empower = true   -- the announced bonus card is never re-rolled by Tarot Tycoon

                if spec.kind == 'center' and G.P_CENTERS[spec.key] then
                    if REBA_TAROT_TYCOON and REBA_TAROT_TYCOON.is_empowered_key(spec.key) then
                        REBA_TAROT_TYCOON.become(last, spec.key)   -- Empowered card: plays the reveal
                    else
                        last:set_ability(G.P_CENTERS[spec.key], true)
                        last.config.center_key = spec.key          -- so it survives save/reload
                    end
                elseif spec.kind == 'seal' then
                    if last.seal ~= spec.key then last:set_seal(spec.key, true) end
                end
                sendDebugMessage('[reba] pack bonus (' .. tostring(spec.kind) .. ' ' .. tostring(spec.key) .. '): pack has ' .. #G.pack_cards.cards .. ' cards, last card seal = ' .. tostring(last.seal))
                last:juice_up(0.3, 0.5)
                return true
            end
        }))
    end

    return ret
end

-- Opens a free pack in the middle of the screen (the way Charm Tag & co. do).
-- `customize(booster)` lets each tag flag the pack before it opens.
local function open_tag_pack(tag, pack_key, colour, customize)
    local lock = tag.ID
    G.CONTROLLER.locks[lock] = true

    tag:yep('+', colour, function()
        local booster = SMODS.create_card { key = pack_key, area = G.play }
        booster.T.x = G.play.T.x + G.play.T.w / 2 - G.CARD_W * 1.27 / 2
        booster.T.y = G.play.T.y + G.play.T.h / 2 - G.CARD_H * 1.27 / 2
        booster.T.w = G.CARD_W * 1.27
        booster.T.h = G.CARD_H * 1.27
        booster.cost = 0
        booster.from_tag = true

        if customize then customize(booster) end
        refresh_pack_size(booster)

        G.FUNCS.use_card({ config = { ref_table = booster } })
        booster:start_materialize()
        G.CONTROLLER.locks[lock] = nil
        return true
    end)

    tag.triggered = true
    return true
end

-- Random Uncommon (80%) or Rare (20%) Joker key, from the real shop pool (respects owned jokers etc.)
local function roll_extra_joker(seed)
    local rare = pseudorandom(pseudoseed(seed .. '_rarity')) < EXTRA_JOKER_RARE_CHANCE
    -- legacy numeric rarity rolls: 0.9 -> Uncommon, 1 -> Rare
    local pool = get_current_pool('Joker', rare and 1 or 0.9, nil, seed)
    local valid = {}
    for _, key in ipairs(pool or {}) do
        if key ~= 'UNAVAILABLE' then valid[#valid + 1] = key end
    end
    if #valid == 0 then return 'j_joker' end
    return (pseudorandom_element(valid, pseudoseed(seed .. '_pick')))
end

--------------------------------------------------------------------------------
-- Rare Buffoon Pack: choose 1 of 3 Rare Jokers. Only obtainable from the Rare Tag.
--------------------------------------------------------------------------------

SMODS.Booster {
    key = 'buffoon_rare',
    kind = 'Buffoon',
    atlas = 'Booster',              -- vanilla pack atlas: reuse the normal Buffoon Pack art
    prefix_config = { atlas = false },  -- don't prefix 'Booster' to 'reba_Booster' (that atlas doesn't exist)
    no_collection = true,           -- hide from the Collection
    pos = { x = 0, y = 8 },
    config = { extra = 3, choose = 1 },
    cost = 6,
    weight = 0,                     -- never shows up naturally in the shop
    group_key = 'k_buffoon_pack',
    draw_hand = false,
    discovered = true,
    loc_txt = {
        name = 'Rare Buffoon Pack',
        text = {
            'Choose {C:attention}#1#{} of up to',
            '{C:attention}#2#{} {C:red}Rare{C:attention} Joker{} cards',
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { self.config.choose, self.config.extra } }
    end,
    create_card = function(self, card, i)
        return {
            set = 'Joker',
            area = G.pack_cards,
            rarity = 'Rare',
            skip_materialize = true,
            key_append = 'rare_buffoon',
        }
    end,
    ease_background_colour = function(self)
        ease_background_colour_blind(G.STATES.BUFFOON_PACK)
    end,
    particles = function(self) end,
}

local RARE_PACK_KEY = 'p_' .. SMODS.current_mod.prefix .. '_buffoon_rare'

--------------------------------------------------------------------------------
-- Charm Tag: free Mega Arcana Pack + ONE EXTRA pre-announced Tarot
--------------------------------------------------------------------------------

SMODS.Tag:take_ownership('tag_charm', {
    loc_vars = function(self, info_queue, tag)
        local key = tag and tag.ability and tag.ability.charm_card
        if key and G.P_CENTERS[key] then
            info_queue[#info_queue + 1] = G.P_CENTERS[key]
            return { vars = { localize { type = 'name_text', set = 'Tarot', key = key } } }
        end
        return { vars = { 'a random Tarot' } }
    end,
    apply = function(self, tag, context)
        if context.type ~= 'new_blind_choice' then return end
        return open_tag_pack(
            tag,
            'p_arcana_mega_' .. pseudorandom_element({ 1, 2 }, pseudoseed('charm_tag_pack')),
            G.C.PURPLE,
            function(booster)
                booster.ability.extra_card = { kind = 'center', key = tag.ability.charm_card or 'c_fool' }
            end
        )
    end,
}, true)

--------------------------------------------------------------------------------
-- Buffoon Tag: free Mega Buffoon Pack + ONE EXTRA pre-announced Uncommon/Rare Joker
--------------------------------------------------------------------------------

SMODS.Tag:take_ownership('tag_buffoon', {
    config = { type = 'new_blind_choice' },
    loc_txt = {
        name = 'Buffoon Tag',
        text = {
            'Get a free {C:attention}Mega Buffoon Pack{}',
            'with an extra {C:attention}#1#{}',
        },
    },
    loc_vars = function(self, info_queue, tag)
        local key = tag and tag.ability and tag.ability.buffoon_joker
        if key and G.P_CENTERS[key] then
            info_queue[#info_queue + 1] = G.P_CENTERS[key]
            return { vars = { localize { type = 'name_text', set = 'Joker', key = key } } }
        end
        return { vars = { 'Uncommon or Rare Joker' } }
    end,
    apply = function(self, tag, context)
        if context.type ~= 'new_blind_choice' then return end
        return open_tag_pack(tag, 'p_buffoon_mega_1', G.C.RED, function(booster)
            booster.ability.extra_card = { kind = 'center', key = tag.ability.buffoon_joker or 'j_joker' }
        end)
    end,
}, true)

--------------------------------------------------------------------------------
-- Standard Tag: free Mega Standard Pack + ONE EXTRA card with a pre-announced random Seal
--------------------------------------------------------------------------------

SMODS.Tag:take_ownership('tag_standard', {
    config = { type = 'new_blind_choice' },
    loc_txt = {
        name = 'Standard Tag',
        text = {
            'Get a free {C:attention}Mega Standard Pack{}',
            'with an extra card with a',
            '{C:attention}#1#{}',
        },
    },
    loc_vars = function(self, info_queue, tag)
        local seal = tag and tag.ability and tag.ability.standard_seal
        if seal and G.P_SEALS[seal] then
            info_queue[#info_queue + 1] = G.P_SEALS[seal]
            return { vars = { localize { type = 'name_text', set = 'Other', key = string.lower(seal) .. '_seal' } } }
        end
        return { vars = { 'random Seal' } }
    end,
    apply = function(self, tag, context)
        if context.type ~= 'new_blind_choice' then return end
        return open_tag_pack(
            tag,
            'p_standard_mega_' .. pseudorandom_element({ 1, 2 }, pseudoseed('standard_tag_pack')),
            G.C.BLUE,
            function(booster)
                booster.ability.extra_card = { kind = 'seal', key = tag.ability.standard_seal or 'Red' }
            end
        )
    end,
}, true)

--------------------------------------------------------------------------------
-- Rare Tag: free Rare Buffoon Pack (choose 1 of 3 Rare Jokers)
--------------------------------------------------------------------------------

SMODS.Tag:take_ownership('tag_rare', {
    config = { type = 'new_blind_choice' },
    loc_txt = {
        name = 'Rare Tag',
        text = {
            'Get a free',
            '{C:red}Rare Buffoon Pack{}',
        },
    },
    loc_vars = function(self, info_queue, tag)
        -- tooltip: "Choose 1 of up to 3 Rare Joker cards"
        if G.P_CENTERS[RARE_PACK_KEY] then
            info_queue[#info_queue + 1] = G.P_CENTERS[RARE_PACK_KEY]
        end
        return { vars = {} }
    end,
    apply = function(self, tag, context)
        if context.type ~= 'new_blind_choice' then return end
        return open_tag_pack(tag, RARE_PACK_KEY, G.C.RED)
    end,
}, true)

--------------------------------------------------------------------------------
-- Uncommon Tag: the next Uncommon Joker you buy becomes Rental and is duplicated.
-- The logic lives in SMODS.current_mod.calculate (context.buying_card), see calculate_additions.lua.
-- The tag only pops if there is room for the copy; otherwise it waits for the next Uncommon.
--------------------------------------------------------------------------------

SMODS.Tag:take_ownership('tag_uncommon', {
    config = { type = 'uncommon_buy' },   -- a context that never fires, so vanilla never consumes it
    apply = function(self, tag, context) end,
    loc_txt = {
        name = 'Uncommon Tag',
        text = {
            'Next {C:green}Uncommon Joker{} you buy',
            'becomes {C:attention}Rental{} and is {C:attention}duplicated{}',
            '{C:inactive}(Must have room){}',
        },
    },
    loc_vars = function(self, info_queue, tag)
        info_queue[#info_queue + 1] = { key = 'rental', set = 'Other', vars = { (G.GAME and G.GAME.rental_rate) or 3 } }
        return { vars = {} }
    end,
}, true)

--------------------------------------------------------------------------------
-- Meteor Tag: $1 per Planet card used this run
--------------------------------------------------------------------------------

local function planets_used()
    return (G.GAME and G.GAME.consumeable_usage_total and G.GAME.consumeable_usage_total.planet) or 0
end

SMODS.Tag:take_ownership('tag_meteor', {
    config = { type = 'immediate' },
    loc_txt = {
        name = 'Meteor Tag',
        text = {
            'Get {C:money}$1{} per {C:planet}Planet{} card',
            'used this run',
            '{C:inactive}(Currently {C:money}$#1#{C:inactive})',
        },
    },
    loc_vars = function(self, info_queue, tag)
        return { vars = { planets_used() } }
    end,
    apply = function(self, tag, context)
        if context.type ~= 'immediate' then return end

        local lock = tag.ID
        G.CONTROLLER.locks[lock] = true

        tag:yep('+', G.C.MONEY, function()
            local amount = planets_used()
            if amount > 0 then ease_dollars(amount, true) end
            G.CONTROLLER.locks[lock] = nil
            return true
        end)

        tag.triggered = true
        return true
    end,
}, true)

--------------------------------------------------------------------------------
-- Juggle Tag: +4 hand size, lose 1 bonus hand size at the end of each round.
-- The decay lives in SMODS.current_mod.calculate (see calculate_additions.lua).
-- Uses G.GAME.juggle_bonus instead of vanilla's temp_handsize (which resets after ONE round).
--------------------------------------------------------------------------------

SMODS.Tag:take_ownership('tag_juggle', {
    config = { type = 'round_start_bonus', h_size = 4 },
    loc_txt = {
        name = 'Juggle Tag',
        text = {
            '{C:attention}+4{} hand size. At the end',
            'of each round, lose {C:attention}1{}',
            'bonus hand size',
        },
    },
    apply = function(self, tag, context)
        if context.type ~= 'round_start_bonus' then return end
        tag:yep('+', G.C.BLUE, function() return true end)
        G.hand:change_size(4)
        G.GAME.juggle_bonus = (G.GAME.juggle_bonus or 0) + 4
        tag.triggered = true
        return true
    end,
}, true)

--------------------------------------------------------------------------------
-- Handy Tag: when you run out of hands WITHOUT beating the blind, gain +3 hands (once).
-- Hooks end_round, which runs when the game decides whether you won or lost.
--------------------------------------------------------------------------------

SMODS.Tag:take_ownership('tag_handy', {
    -- dollars_per_hand must stay: vanilla's tooltip code does arithmetic on it for 'Handy Tag'
    config = { type = 'handy_save', dollars_per_hand = 1 },     -- a context that never fires, handled by the end_round hook below
    apply = function(self, tag, context) end,
    loc_txt = {
        name = 'Handy Tag',
        text = {
            'When you run out of {C:blue}hands{}',
            'without beating the blind,',
            'gain {C:blue}+3{} hands',
        },
    },
}, true)

local end_round_ref = end_round
function end_round()
    if G.GAME and G.GAME.blind and G.GAME.chips < G.GAME.blind.chips
        and G.GAME.current_round.hands_left < 1 then
        for _, tag in ipairs(G.GAME.tags or {}) do
            if tag.key == 'tag_handy' and not tag.triggered then
                tag:yep('+', G.C.BLUE, function() return true end)
                tag.triggered = true
                ease_hands_played(3)
                -- go back to drawing a hand instead of ending the round
                G.STATE = G.STATES.DRAW_TO_HAND
                G.STATE_COMPLETE = false
                return
            end
        end
    end
    return end_round_ref()
end

--------------------------------------------------------------------------------
-- Unchanged tags
--------------------------------------------------------------------------------

local function pick_without_edition(cards, seed)
    local pool = {}
    for _, card in ipairs(cards or {}) do
        if not card.edition and not card.temp_edition then
            pool[#pool + 1] = card
        end
    end
    if #pool == 0 then return nil end
    return pseudorandom_element(pool, pseudoseed(seed))
end

local function make_edition_tag_apply(edition)
    return function(self, tag, context)
        if context.type ~= 'immediate' then return end

        local lock = tag.ID
        G.CONTROLLER.locks[lock] = true

        tag:yep('+', G.C.DARK_EDITION, function()
            local joker = G.jokers and pick_without_edition(G.jokers.cards, 'edition_tag_joker')
            local playing = pick_without_edition(G.playing_cards, 'edition_tag_deck')

            if joker then
                joker:set_edition({ [edition] = true }, true)
                joker:juice_up(0.3, 0.5)
            end
            if playing then
                playing:set_edition({ [edition] = true }, true)
            end

            G.CONTROLLER.locks[lock] = nil
            return true
        end)

        tag.triggered = true
        return true
    end
end

local function ante_in_range(min_ante, max_ante)
    return function(self, args)
        local ante = G.GAME and G.GAME.round_resets and G.GAME.round_resets.ante or 1
        if ante < min_ante then return false end
        if max_ante and ante > max_ante then return false end
        return true
    end
end

SMODS.Tag:take_ownership('tag_foil', {
    config = { type = 'immediate', edition = 'foil' },
    apply = make_edition_tag_apply('foil'),
    in_pool = ante_in_range(1, 2),
}, true)

SMODS.Tag:take_ownership('tag_holo', {
    config = { type = 'immediate', edition = 'holo' },
    apply = make_edition_tag_apply('holo'),
    in_pool = ante_in_range(3, 4),
}, true)

SMODS.Tag:take_ownership('tag_polychrome', {
    config = { type = 'immediate', edition = 'polychrome' },
    apply = make_edition_tag_apply('polychrome'),
    in_pool = ante_in_range(5, nil),
}, true)

-- Top-up Tag: 3 Common Jokers instead of 2
SMODS.Tag:take_ownership('tag_top_up', {
    config = { type = 'immediate', spawn_jokers = 3 },
}, true)

SMODS.Tag:take_ownership('tag_orbital', {}, true)
G.P_TAGS['tag_orbital'].config.levels = 5

local set_ability_tag_ref = Tag.set_ability
function Tag:set_ability()
    if self.name == 'Orbital Tag' and G.GAME and G.GAME.round_resets then
        local ante = G.GAME.round_resets.ante
        G.GAME.orbital_choices = G.GAME.orbital_choices or {}
        G.GAME.orbital_choices[ante] = G.GAME.orbital_choices[ante] or {}
    end

    set_ability_tag_ref(self)

    if self.name == 'Orbital Tag' and not self.ability.orbital_hand then
        local hands = {}
        for k, v in pairs(G.GAME.hands) do
            if v.visible then hands[#hands + 1] = k end
        end
        self.ability.orbital_hand = pseudorandom_element(hands, pseudoseed('orbital_fallback'))
    end

    -- Charm Tag: roll the extra Tarot up front so the tag can show it.
    -- Plain pool only; with Tarot Tycoon owned it may then be turned into its Empowered version.
    if self.name == 'Charm Tag' and not self.ability.charm_card then
        local pool = {}
        for _, center in ipairs(G.P_CENTER_POOLS.Tarot) do
            if not center.reba_empowered then
                pool[#pool + 1] = center.key
            end
        end
        self.ability.charm_card = pseudorandom_element(pool, pseudoseed('charm_tag_card'))
        if REBA_TAROT_TYCOON then
            self.ability.charm_card = REBA_TAROT_TYCOON.maybe_empower(self.ability.charm_card, 'charm_tag_empower')
        end
    end

    -- Buffoon Tag: roll the extra Uncommon/Rare Joker up front
    if self.name == 'Buffoon Tag' and not self.ability.buffoon_joker and G.GAME then
        self.ability.buffoon_joker = roll_extra_joker('buffoon_tag_joker')
    end

    -- Standard Tag: roll the extra card's Seal up front
    if self.name == 'Standard Tag' and not self.ability.standard_seal then
        self.ability.standard_seal = pseudorandom_element(STANDARD_SEALS, pseudoseed('standard_tag_seal'))
    end
end

-- Economy Tag: becomes a cash out tag (like Investment Tag). The row is added by the lovely patch.
SMODS.Tag:take_ownership('tag_economy', {
    config = { type = 'eval' },
}, true)

-- Called by the lovely patch for each Economy Tag during cash out
function economy_tag_trigger(tag, base)
    tag:yep('+', G.C.MONEY, function() return true end)
    tag.triggered = true
    return {
        dollars = base,
        condition = localize('ph_economy_match'),
        pos = tag.pos,
        tag = tag,
    }
end

SMODS.Tag:take_ownership('tag_ethereal', {
    loc_vars = function(self, info_queue, tag)
        info_queue[#info_queue + 1] = G.P_CENTERS.p_spectral_mega_1
        return { vars = {} }
    end,
}, true)

SMODS.Tag:take_ownership('tag_coupon', {
    apply = function(self, tag, context) end,
}, true)
G.P_TAGS['tag_coupon'].config.type = 'coupon_skip'  -- context that never fires

-- Garbage Tag: $2 per unused discard instead of $1
SMODS.Tag:take_ownership('tag_garbage', {
    loc_vars = function(self, info_queue, tag)
        local per = (tag and tag.config and tag.config.dollars_per_discard)
            or G.P_TAGS['tag_garbage'].config.dollars_per_discard
            or 2
        local unused = (G.GAME and G.GAME.unused_discards) or 0
        return { vars = { per, unused * per } }
    end,
}, true)
G.P_TAGS['tag_garbage'].config.dollars_per_discard = 2

SMODS.Tag:take_ownership('tag_skip', {
    config = { type = 'immediate', skip_bonus = 10 },
    loc_vars = function(self, info_queue, tag)
        local bonus = (tag and tag.config or self.config).skip_bonus
        local skips = (G.GAME and G.GAME.skips) or 0
        return { vars = { bonus, (skips + 1) * bonus } }
    end,
}, true)

--------------------------------------------------------------------------------
-- D6 Tag: your NEXT 3 rerolls cost $0. Stored in a run-wide counter, so tags stack
-- (Double Tag) and unused free rerolls carry over to later shops.
--------------------------------------------------------------------------------
SMODS.Tag:take_ownership('tag_d_six', {
    apply = function(self, tag, context)
        if context.type ~= 'shop_start' then return end
        tag:yep('+', G.C.GREEN, function()
            G.GAME.reba_d6_free = (G.GAME.reba_d6_free or 0) + 3
            calculate_reroll_cost(true)
            return true
        end)
        tag.triggered = true
        return true
    end,
}, true)

--#endregion

MyMod.apply_changed_badges() --Keep at the end