-- flower_pot.lua
-- Load from your main mod file with:
--     assert(SMODS.load_file("flower_pot.lua"))()
--
-- Flower Pot rework:
--   * Vanilla Flower Pot counts consecutive same-suit cards (25 needed).
--   * When the streak is reached it transforms into that suit's hidden Flower Pot.
--   * The four suit pots never appear in shops/packs (in_pool = false).
--
--   Hearts   : +3 hand size
--   Clubs    : Blueprint effect
--   Spades   : +1 voucher in the shop each Ante
--   Diamonds : enhancements, seals and editions on playing cards trigger an extra time

local SUITS = { 'Hearts', 'Diamonds', 'Spades', 'Clubs' }
local HIDE_POTS_FROM_COLLECTION = true -- set to false while testing if you spawn cards from the collection
-- The suit pots are registered WITHOUT your mod prefix (see hidden_pot), so their
-- final keys are simply j_flower_pot_hearts / _diamonds / _spades / _clubs.
local POT_KEY = 'j_flower_pot_diamonds'

----------------------------------------------------------------------
-- 1) Shared setup for the four hidden suit pots
----------------------------------------------------------------------
local function hidden_pot(suit, def)
    def.key = "flower_pot_" .. suit:lower()
    def.prefix_config = { key = { mod = false } } -- key becomes j_flower_pot_<suit>, no mod prefix
    def.no_mod_badges = true -- hides the mod badge on the card, like take_ownership's silent flag
    def.no_collection = HIDE_POTS_FROM_COLLECTION -- true = not listed in the Jokers collection
    def.rarity = 2
    def.cost = 6
    def.pos = def.pos or { x = 0, y = 6 } -- placeholder sprite, swap for your own atlas
    def.in_pool = function(self, args) return false end -- never appears in shop/packs
    SMODS.Joker(def)
end

----------------------------------------------------------------------
-- 2) HEARTS: +3 hand size (same approach as Juggler)
----------------------------------------------------------------------
hidden_pot('Hearts', {
    blueprint_compat = false,
    config = { extra = { h_size = 3 } },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.h_size } }
    end,
    add_to_deck = function(self, card, from_debuff)
        G.hand:change_size(card.ability.extra.h_size)
    end,
    remove_from_deck = function(self, card, from_debuff)
        G.hand:change_size(-card.ability.extra.h_size)
    end,
})

----------------------------------------------------------------------
-- 3) CLUBS: Blueprint effect (copied from vanilla Blueprint)
----------------------------------------------------------------------
hidden_pot('Clubs', {
    blueprint_compat = true,
    loc_vars = function(self, info_queue, card)
        -- green "Compatible" / red "Incompatible" badge under the description
        if card.area and card.area == G.jokers then
            local other_joker
            for i = 1, #G.jokers.cards do
                if G.jokers.cards[i] == card then other_joker = G.jokers.cards[i + 1] end
            end
            local compatible = other_joker and other_joker ~= card and other_joker.config.center.blueprint_compat
            local main_end = {
                {
                    n = G.UIT.C,
                    config = { align = "bm", minh = 0.4 },
                    nodes = {
                        {
                            n = G.UIT.C,
                            config = { ref_table = card, align = "m", colour = compatible and mix_colours(G.C.GREEN, G.C.JOKER_GREY, 0.8) or mix_colours(G.C.RED, G.C.JOKER_GREY, 0.8), r = 0.05, padding = 0.06 },
                            nodes = {
                                { n = G.UIT.T, config = { text = ' ' .. localize('k_' .. (compatible and 'compatible' or 'incompatible')) .. ' ', colour = G.C.UI.TEXT_LIGHT, scale = 0.32 * 0.8 } },
                            }
                        }
                    }
                }
            }
            return { main_end = main_end }
        end
    end,
    calculate = function(self, card, context)
        local other_joker = nil
        for i = 1, #G.jokers.cards do
            if G.jokers.cards[i] == card then other_joker = G.jokers.cards[i + 1] end
        end
        local ret = SMODS.blueprint_effect(card, other_joker, context)
        if ret then
            ret.colour = G.C.BLUE
        end
        return ret
    end,
})

----------------------------------------------------------------------
-- 4) SPADES: +1 voucher in the shop each Ante
--    SMODS.change_voucher_limit bumps G.GAME.modifiers.extra_vouchers;
--    the shop tops up this Ante's vouchers the next time it opens.
----------------------------------------------------------------------
hidden_pot('Spades', {
    blueprint_compat = false,
    config = { extra = { vouchers = 1 } },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.vouchers } }
    end,
    add_to_deck = function(self, card, from_debuff)
        SMODS.change_voucher_limit(card.ability.extra.vouchers)
    end,
    remove_from_deck = function(self, card, from_debuff)
        SMODS.change_voucher_limit(-card.ability.extra.vouchers)
    end,
})

----------------------------------------------------------------------
-- 5) DIAMONDS: the joker itself is just a marker. The effect is the
--    eval_card hook below, which appends extra procs of the card's own
--    enhancement / seal / edition effects (NOT a retrigger, so jokers
--    don't fire again).
----------------------------------------------------------------------
hidden_pot('Diamonds', {
    blueprint_compat = false,
})

local GOLD_SEAL_DOLLARS = 3 -- vanilla Gold Seal payout (hardcoded in vanilla, so mirrored here)

-- The hook must be installed exactly ONCE. A second copy (e.g. this file loaded twice, or an
-- older paste of this code somewhere else in your mod) makes every proc happen one time too many.
if SMODS.diamond_pot_hook_installed then
    sendWarnMessage("Diamonds Flower Pot hook already installed - skipping duplicate. Look for a second copy of this code.", "FlowerPot")
else
    SMODS.diamond_pot_hook_installed = true
    sendInfoMessage("Diamonds Flower Pot hook installed", "FlowerPot")

    -- keeps the edition popup/sound on the chained edition proc
    local calculate_effect_ref = SMODS.calculate_effect
    function SMODS.calculate_effect(effect, scored_card, from_edition, pre_jokers)
        if type(effect) == 'table' and effect.diamond_pot_edition then from_edition = true end
        return calculate_effect_ref(effect, scored_card, from_edition, pre_jokers)
    end

    -- append `add` to the end of ret[key]'s extra-chain so it procs right after
    local function chain(ret, key, add)
        if type(add) ~= 'table' or not next(add) then return end
        if type(ret[key]) ~= 'table' then ret[key] = add; return end
        local tail = ret[key]
        while tail.extra do tail = tail.extra end
        tail.extra = add
    end

    -- which evaluations count as "the card triggering"
    local function classify(card, context)
        if context.extra_enhancement or SMODS.diamond_pot_running then return end
        if context.main_scoring or context.playing_card_end_of_round then return 'scoring' end
        if context.repetition_only or (context.discard and context.other_card == card) then return 'calc' end
    end

    -- number of active Diamonds pots (each card counted once)
    local function count_pots()
        local seen, n = {}, 0
        for _, c in ipairs(SMODS.find_card(POT_KEY)) do
            if not seen[c] then seen[c] = true; n = n + 1 end
        end
        return n
    end

    local eval_card_ref = eval_card
    function eval_card(card, context)
        local ret, post = eval_card_ref(card, context)
        if not (card and card.playing_card and context) then return ret, post end

        local kind = classify(card, context)
        if not kind or not card:can_calculate(context.ignore_debuff) then return ret, post end

        local pots = count_pots() -- each Diamonds pot = one extra proc
        if pots == 0 then return ret, post end

        SMODS.diamond_pot_running = true
        for _ = 1, pots do
            if kind == 'scoring' then
                -- second pass that returns ONLY the enhancement part
                -- (no base rank chips, no permanent bonuses, and no hardcoded seals)
                local old = card.ability.extra_enhancement
                card.ability.extra_enhancement = card.config.center.key
                context.extra_enhancement = true
                local extra = eval_card_ref(card, context)
                context.extra_enhancement = nil
                card.ability.extra_enhancement = old
                chain(ret, 'playing_card', extra.playing_card) -- Bonus/Mult/Glass X2/Stone/Steel
                chain(ret, 'enhancement', extra.enhancement)   -- Lucky and modded enhancements

                -- Gold Seal money is hardcoded in vanilla and skipped by the pass above
                if context.main_scoring and context.cardarea == G.play and card.seal == 'Gold' then
                    local seal_obj = G.P_SEALS.Gold
                    if not (seal_obj and type(seal_obj.get_p_dollars) == 'function') then
                        chain(ret, 'playing_card', { p_dollars = GOLD_SEAL_DOLLARS })
                    end
                end

                -- End of round: Gold Card $ and the Blue Seal planet both live in
                -- get_end_of_round_effect (Blue Seal is hardcoded and skipped by the flagged pass)
                if context.end_of_round and context.cardarea == G.hand and context.playing_card_end_of_round then
                    chain(ret, 'end_of_round', card:get_end_of_round_effect(context))
                end
            else
                -- discard / Red Seal retrigger checks: just calculate again
                chain(ret, 'enhancement', card:calculate_enhancement(context))
            end
            if card.edition then
                local ed = card:calculate_edition(context)
                if type(ed) == 'table' then ed.diamond_pot_edition = true end
                chain(ret, 'edition', ed)
            end
            if card.seal then chain(ret, 'seals', card:calculate_seal(context)) end -- Red, Purple
        end
        SMODS.diamond_pot_running = nil

        return ret, post
    end
end

----------------------------------------------------------------------
-- 6) The BASE Flower Pot (vanilla j_flower_pot, reworked)
--    Counts consecutive same-suit scoring cards and transforms into
--    that suit's pot. Defined last because it references the keys above.
----------------------------------------------------------------------
SMODS.Joker:take_ownership('flower_pot', {
    name = "Flower Pot Sprout", -- internal only; stops vanilla's name-based Flower Pot code from running
    unlocked = true,
    blueprint_compat = false,
    rarity = 3,
    -- While you own ANY suited Flower Pot, the base Flower Pot can't spawn again
    -- (SMODS drops it from used_jokers when it transforms, so we block it ourselves).
    -- Showman-style effects lift the block, exactly like they do for normal duplicates.
    in_pool = function(self, args)
        if SMODS.showman(self.key) then return true end
        for _, suit in ipairs(SUITS) do
            if next(SMODS.find_card('j_flower_pot_' .. suit:lower(), true)) then
                return false
            end
        end
        return true
    end,
    config = { extra = { suit = false, count = 0, needed = 25 } },
    loc_vars = function(self, info_queue, card)
        local extra = card.ability.extra
        return { vars = {
            extra.needed,
            extra.suit and localize(extra.suit, 'suits_singular') or localize('k_none'),
            extra.count,
            colours = { extra.suit and G.C.SUITS[extra.suit] or G.C.UI.TEXT_INACTIVE },
        } }
    end,
    calculate = function(self, card, context)
        if context.after and not context.blueprint then
            local extra = card.ability.extra
            local hand = context.scoring_hand

            -- every suit that ALL scoring cards satisfy (Wild cards / Smeared can satisfy several)
            local shared = {}
            for _, suit in ipairs(SUITS) do
                local all = true
                for _, c in ipairs(hand) do
                    if not c:is_suit(suit, true) then all = false; break end
                end
                if all then shared[#shared + 1] = suit end
            end

            local continues = false
            for _, suit in ipairs(shared) do
                if suit == extra.suit then continues = true end
            end

            if continues then
                extra.count = extra.count + #hand              -- streak continues
            elseif #shared > 0 then
                extra.suit, extra.count = shared[1], #hand     -- new streak
            else
                extra.suit, extra.count = false, 0             -- mixed suits: streak broken
            end

            if extra.count >= extra.needed then
                local key = 'j_flower_pot_' .. extra.suit:lower()
                G.E_MANAGER:add_event(Event({
                    trigger = 'after',
                    delay = 0.3,
                    func = function()
                        play_sound('tarot1')
                        card:juice_up(0.8, 0.8)
                        card:set_ability(key) -- SMODS handles add/remove_from_deck and keeps stickers
                        return true
                    end
                }))
                return { message = localize('k_upgrade_ex'), colour = G.C.GREEN }
            end
        end
    end,
}, true)