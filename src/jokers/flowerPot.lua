-- flower_pot.lua
-- Load from your main mod file with:
--     assert(SMODS.load_file("flower_pot.lua"))()
--
-- Flower Pot rework:
--   * Vanilla Flower Pot counts consecutive same-suit cards (25 needed).
--   * When the streak is reached it transforms into that suit's hidden Flower Pot.
--   * The four suit pots never appear in shops/packs (in_pool = false).
--   * The suit pots are hidden from the Jokers collection until you obtain them.
--
--   Hearts   : your probability effects (Lucky Cards, Bloodstone, 8 Ball...) trigger 2 extra times
--   Clubs    : after scoring 10 Clubs, create a Spectral card
--   Spades   : +1 voucher in the shop each Ante (unchanged)
--   Diamonds : every time you earn money, gain $2 more

local SUITS = { 'Hearts', 'Diamonds', 'Spades', 'Clubs' }
local HIDE_UNTIL_DISCOVERED = true -- set to false while testing if you spawn cards from the collection
-- The suit pots are registered WITHOUT your mod prefix (see hidden_pot), so their
-- final keys are simply j_flower_pot_hearts / _diamonds / _spades / _clubs.
local POT_KEY = 'j_flower_pot_diamonds'

-- One atlas per suit pot. Files live in assets/1x and assets/2x with identical names:
--   Flower_Pot_Hearts.png, Flower_Pot_Diamond.png, Flower_Pot_Spades.png, Flower_Pot_Clubs.png
-- Each file is a single card (71x95 at 1x, 142x190 at 2x).
local POT_ATLAS = {}
for _, suit in ipairs(SUITS) do
    -- your Diamonds file is named "Diamond" (no s); the others match the suit name
    local file = (suit == 'Diamonds') and 'Flower_Pot_Diamond.png' or ('Flower_Pot_' .. suit .. '.png')
    POT_ATLAS[suit] = 'flower_pot_' .. suit:lower()
    SMODS.Atlas{ key = POT_ATLAS[suit], path = file, px = 71, py = 95 }
end

----------------------------------------------------------------------
-- 1) Shared setup for the four hidden suit pots
----------------------------------------------------------------------
local function hidden_pot(suit, def)
    def.key = "flower_pot_" .. suit:lower()
    def.prefix_config = { key = { mod = false } } -- key becomes j_flower_pot_<suit>, no mod prefix
    def.no_mod_badges = true -- hides the mod badge on the card, like take_ownership's silent flag
    -- no_collection is NOT set here: it is refreshed dynamically by the
    -- SMODS.collection_pool hook below, based on whether the pot is discovered.
    def.rarity = 3
    def.cost = 6
    def.atlas = POT_ATLAS[suit] -- each suit pot uses its own art
    def.pos = { x = 0, y = 0 }
    def.in_pool = function(self, args) return false end -- never appears in shop/packs
    SMODS.Joker(def)
end

----------------------------------------------------------------------
-- 2) HEARTS: your probability effects trigger 2 extra times.
--    * Jokers: when a Joker's chance-based effect SUCCEEDS while scoring (Bloodstone, 8 Ball,
--      Business Card, Reserved Parking...), its calculate is run again 2 more times and the
--      results are chained on, so each extra trigger rolls its own chance.
--    * Lucky Cards: same thing for the enhancement's scoring effect.
--    Only scoring-time contexts are repeated (never end-of-round destruction rolls like Gros Michel).
----------------------------------------------------------------------
local HEARTS_KEY = 'j_flower_pot_hearts'

hidden_pot('Hearts', {
    blueprint_compat = false,
    config = { extra = { repeats = 2 } },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.repeats } }
    end,
})

if SMODS.hearts_pot_hook_installed then
    sendWarnMessage("Hearts Flower Pot hook already installed - skipping duplicate.", "FlowerPot")
else
    SMODS.hearts_pot_hook_installed = true

    -- total extra triggers from all Hearts pots (each card counted once)
    local function hearts_extra_triggers()
        local seen, total = {}, 0
        for _, c in ipairs(SMODS.find_card(HEARTS_KEY)) do
            if not seen[c] then
                seen[c] = true
                total = total + ((c.ability.extra and c.ability.extra.repeats) or 0)
            end
        end
        return total
    end

    -- append `add` to the end of ret's extra-chain so it procs right after
    local function chain_effect(ret, add)
        if type(ret) ~= 'table' or type(add) ~= 'table' or not next(add) then return end
        local tail = ret
        while type(tail.extra) == 'table' do tail = tail.extra end
        if tail.extra == nil then tail.extra = add end
    end

    -- remember whether `trigger_obj` rolled (and won) a probability check during the current call
    local roll_log = nil
    local pseudorandom_probability_ref = SMODS.pseudorandom_probability
    function SMODS.pseudorandom_probability(trigger_obj, ...)
        local result = pseudorandom_probability_ref(trigger_obj, ...)
        if roll_log and trigger_obj == roll_log.obj and result then
            roll_log.success = true
        end
        return result
    end

    -- runs `fn()` once, and if a chance-based effect of `obj` succeeded, runs it `extra` more times
    local function with_extra_triggers(obj, extra, fn)
        local previous_log = roll_log
        local log = { obj = obj }
        roll_log = log
        local ret, post = fn()
        roll_log = previous_log

        if log.success and type(ret) == 'table' then
            SMODS.hearts_pot_running = true
            for _ = 1, extra do
                local again = fn()
                chain_effect(ret, again)
            end
            SMODS.hearts_pot_running = nil
        end
        return ret, post
    end

    -- Jokers
    local calculate_joker_ref = Card.calculate_joker
    function Card:calculate_joker(context)
        if SMODS.hearts_pot_running or not context
            or not (context.individual or context.joker_main or context.before) then
            return calculate_joker_ref(self, context)
        end
        local extra = hearts_extra_triggers()
        if extra == 0 then return calculate_joker_ref(self, context) end
        return with_extra_triggers(self, extra, function() return calculate_joker_ref(self, context) end)
    end

    -- Lucky Cards (and modded chance-based enhancements) while scoring
    local calculate_enhancement_ref = Card.calculate_enhancement
    function Card:calculate_enhancement(context)
        if SMODS.hearts_pot_running or not context or context.extra_enhancement
            or not (context.main_scoring and context.cardarea == G.play) then
            return calculate_enhancement_ref(self, context)
        end
        local extra = hearts_extra_triggers()
        if extra == 0 then return calculate_enhancement_ref(self, context) end
        return with_extra_triggers(self, extra, function() return calculate_enhancement_ref(self, context) end)
    end
end

----------------------------------------------------------------------
-- 3) CLUBS: after scoring 10 Clubs, create a Spectral card (needs room)
----------------------------------------------------------------------
hidden_pot('Clubs', {
    blueprint_compat = false,
    config = { extra = { needed = 10, count = 0 } },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.needed, card.ability.extra.count } }
    end,
    calculate = function(self, card, context)
        if context.blueprint then return end
        if context.individual and context.cardarea == G.play and context.other_card:is_suit('Clubs') then
            local extra = card.ability.extra
            extra.count = extra.count + 1

            if extra.count >= extra.needed
                and #G.consumeables.cards + G.GAME.consumeable_buffer < G.consumeables.config.card_limit then
                extra.count = extra.count - extra.needed
                G.GAME.consumeable_buffer = G.GAME.consumeable_buffer + 1
                G.E_MANAGER:add_event(Event({
                    trigger = 'before',
                    delay = 0.0,
                    func = function()
                        SMODS.add_card { set = 'Spectral', key_append = 'reba_clubs_pot' }
                        G.GAME.consumeable_buffer = 0
                        return true
                    end
                }))
                return { message = localize('k_plus_spectral'), colour = G.C.SECONDARY_SET.Spectral }
            end

            -- no room yet: the streak stays full and fires on the next Club once there is space
            return { message = extra.count .. '/' .. extra.needed, colour = G.C.SUITS.Clubs }
        end
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
-- 5) DIAMONDS: every time you earn money, gain $2 more.
--    Hooks ease_dollars: any positive money change gets +$2 per Diamonds pot added to it.
--    Set G.GAME.reba_no_diamond_bonus = true around an ease_dollars call to skip the bonus
--    (used by Wraith, which sets your money to an exact amount).
----------------------------------------------------------------------
hidden_pot('Diamonds', {
    blueprint_compat = false,
    config = { extra = { dollars = 2 } },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.dollars } }
    end,
})

if SMODS.diamond_pot_hook_installed then
    sendWarnMessage("Diamonds Flower Pot hook already installed - skipping duplicate. Look for a second copy of this code.", "FlowerPot")
else
    SMODS.diamond_pot_hook_installed = true

    local ease_dollars_ref = ease_dollars
    function ease_dollars(mod, instant)
        if mod and mod > 0 and G.jokers and not (G.GAME and G.GAME.reba_no_diamond_bonus) then
            local seen, bonus = {}, 0
            for _, c in ipairs(SMODS.find_card(POT_KEY)) do
                if not seen[c] then
                    seen[c] = true
                    bonus = bonus + ((c.ability.extra and c.ability.extra.dollars) or 0)
                end
            end
            mod = mod + bonus
        end
        return ease_dollars_ref(mod, instant)
    end
end

----------------------------------------------------------------------
-- 6) Collection visibility: suit pots stay hidden until discovered.
--    SMODS checks no_collection every time the collection is built, so we
--    refresh the flag each time the pool is requested. `discovered` is
--    saved in the profile by vanilla, so this persists between runs.
--    Guarded so the hook is only installed once.
----------------------------------------------------------------------
if not SMODS.flower_pot_collection_hook_installed then
    SMODS.flower_pot_collection_hook_installed = true

    local collection_pool_ref = SMODS.collection_pool
    function SMODS.collection_pool(base_pool)
        for _, suit in ipairs(SUITS) do
            local center = G.P_CENTERS['j_flower_pot_' .. suit:lower()]
            if center then
                center.no_collection = (HIDE_UNTIL_DISCOVERED and not center.discovered) or nil
            end
        end
        return collection_pool_ref(base_pool)
    end
end

----------------------------------------------------------------------
-- 7) The BASE Flower Pot (vanilla j_flower_pot, reworked)
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
    config = { extra = { suit = false, count = 0, needed = 20 } },
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
                        discover_card(G.P_CENTERS[key]) -- reveals it in the collection and saves to profile
                        return true
                    end
                }))
                return { message = localize('k_upgrade_ex'), colour = G.C.GREEN }
            end
        end
    end,
}, true)