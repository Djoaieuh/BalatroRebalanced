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

--#region Changes 

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

SMODS.Joker:take_ownership('8_ball', {config = {extra = 2, }}, true)

SMODS.Joker:take_ownership('runner', {config = {extra = {chips = 0, chip_mod = 20}}}, true)

SMODS.Joker:take_ownership('vampire', {config = {extra = 0.2, Xmult = 1}}, true)

SMODS.Joker:take_ownership('mail', {config = {extra = 4}}, true)

SMODS.Joker:take_ownership('fortune_teller', {config = {extra = 3}}, true)

SMODS.Joker:take_ownership('order', {config = {Xmult = 4, type = 'Straight'}, }, true)

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

SMODS.Consumable:take_ownership('lovers', {config = {mod_conv = 'm_wild', max_highlighted = 2}}, true)

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
    unlocked = false,
    blueprint_compat = true,
    loc_txt = {
        name = 'Onyx Agate',
        text = {
            'Retrigger any {C:attention}played{} {C:blue}Clubs{}',
        },
    },
    rarity = 2,
    cost = 6,
    pos = { x = 2, y = 8 },
    config = { extra = 1 },
    calculate = function(self, card, context)
        if context.repetition and context.cardarea == G.play and context.other_card:is_suit("Clubs") then
            return {
                repetitions = card.ability.extra
            }
        end
    end,
    locked_loc_vars = function(self, info_queue, card)
        return { vars = { 30, localize('Clubs', 'suits_singular') } }
    end,
    check_for_unlock = function(self, args) -- equivalent to `unlock_condition = { type = 'modify_deck', extra = { count = 30, suit = 'Clubs' } }`
        if args.type == 'modify_deck' then
            local count = 0
            for _, playing_card in ipairs(G.playing_cards or {}) do
                if playing_card.base.suit == "Clubs" then count = count + 1 end
                if count >= 30 then
                    return true
                end
            end
        end
        return false
    end, 
},true)

--#endregion