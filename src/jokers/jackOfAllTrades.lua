-- ============================================================
-- Jack of All Trades (v3 - corrected against real Balatro source)
--
-- v2 tried to hook Card:calculate_card, which does NOT exist in the actual
-- game -- confirmed by inspecting the real card.lua. That's why it silently
-- did nothing: we were defining a dead function nobody calls.
--
-- The real per-card scoring math is read through these EXISTING getter
-- methods (confirmed present in card.lua):
--   Card:get_chip_bonus()   -- chips from Enhancement
--   Card:get_chip_mult()    -- flat mult from Enhancement
--   Card:get_chip_x_mult()  -- x_mult from Enhancement
--   Card:get_edition()      -- chip/mult/x_mult from Edition
--
-- By hooking all four to run our copy logic first, the copy is guaranteed
-- to have happened before ANY of the Jack's own scoring numbers are read,
-- regardless of which getter the engine calls first.
-- ============================================================

local JACK_KEY = "j_" .. SMODS.current_mod.prefix .. "_jack_of_all_trades"

local function exj_player_has_jack_of_all_trades()
    if not (G.jokers and G.jokers.cards) then return false end
    for _, j in ipairs(G.jokers.cards) do
        if j.config.center.key == JACK_KEY then
            return true
        end
    end
    return false
end

local function exj_copy_from_right_neighbor(self)
    if not (self.playing_card and self.area == G.play and self.base and self.base.value == "Jack") then
        return
    end
    if not exj_player_has_jack_of_all_trades() then return end

    local area = self.area
    local idx = nil
    for i, c in ipairs(area.cards) do
        if c == self then
            idx = i
            break
        end
    end
    local right_card = idx and area.cards[idx + 1]
    if not right_card then return end

    -- Enhancement
    local enh_key = right_card.config.center and right_card.config.center.key
    if enh_key and enh_key ~= "c_base" and enh_key ~= self.config.center.key then
        self:set_ability(G.P_CENTERS[enh_key], nil, true)
    end

    -- Edition
    local right_edition = right_card.edition and right_card.edition.key
    local self_edition = self.edition and self.edition.key
    if right_edition and right_edition ~= self_edition then
        self:set_edition(right_edition, true)
    end

    -- Seal
    if right_card.seal and right_card.seal ~= self.seal then
        self:set_seal(right_card.seal, nil, true)
    end
end

local exj_ref_get_chip_bonus = Card.get_chip_bonus
function Card:get_chip_bonus()
    exj_copy_from_right_neighbor(self)
    return exj_ref_get_chip_bonus(self)
end

local exj_ref_get_chip_mult = Card.get_chip_mult
function Card:get_chip_mult()
    exj_copy_from_right_neighbor(self)
    return exj_ref_get_chip_mult(self)
end

local exj_ref_get_chip_x_mult = Card.get_chip_x_mult
function Card:get_chip_x_mult(context)
    exj_copy_from_right_neighbor(self)
    return exj_ref_get_chip_x_mult(self, context)
end

local exj_ref_get_edition = Card.get_edition
function Card:get_edition()
    exj_copy_from_right_neighbor(self)
    return exj_ref_get_edition(self)
end

SMODS.Joker {
    key = "jack_of_all_trades",
    loc_txt = {
        name = "Jack of All Trades",
        text = {
            "Whenever a {C:attention}Jack{} scores,",
            "it copies the {C:attention}Enhancement{},",
            "{C:attention}Edition{} and {C:attention}Seal{}",
            "of the card to its right"
        }
    },
    atlas = "placeholders",
    pos = { x = 1, y = 0 },

    rarity = 2,
    cost = 5,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true

    -- No `calculate` needed -- the effect lives entirely in the getter
    -- overrides above. This Joker's only job is to exist in G.jokers.cards
    -- so exj_player_has_jack_of_all_trades() can detect it.
}