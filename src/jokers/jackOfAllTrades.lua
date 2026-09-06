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
    atlas = "placeholders",   -- reuse your existing test atlas; swap for real art later
    pos = { x = 1, y = 0 },   -- adjust to whichever slot is free in the atlas

    rarity = 2,               -- Uncommon
    cost = 5,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,

    calculate = function(self, card, context)
        -- context.individual + cardarea == G.play fires once per card in the played hand.
        -- 'card' here is the JOKER; context.other_card is the playing card currently scoring.
        if context.individual and context.cardarea == G.play then
            local jack = context.other_card

            if jack and jack.base and jack.base.value == "Jack" then
                local area = jack.area or G.play
                local idx = nil
                for i, c in ipairs(area.cards) do
                    if c == jack then
                        idx = i
                        break
                    end
                end

                local right_card = idx and area.cards[idx + 1]
                if right_card then
                    local copied_something = false

                    -- Copy Enhancement (e.g. Gold, Steel, Glass, etc.)
                    local enh_key = right_card.config.center and right_card.config.center.key
                    if enh_key and enh_key ~= "c_base" and enh_key ~= jack.config.center.key then
                        jack:set_ability(G.P_CENTERS[enh_key], nil, true)
                        copied_something = true
                    end

                    -- Copy Edition (Foil, Holo, Polychrome, Negative)
                    local right_edition = right_card.edition and right_card.edition.key
                    local jack_edition = jack.edition and jack.edition.key
                    if right_edition and right_edition ~= jack_edition then
                        jack:set_edition(right_edition, true)
                        copied_something = true
                    end

                    -- Copy Seal (Gold, Red, Blue, Purple)
                    if right_card.seal and right_card.seal ~= jack.seal then
                        jack:set_seal(right_card.seal, nil, true)
                        copied_something = true
                    end

                    if copied_something then
                        return {
                            message = "Copied!",
                            colour = G.C.SECONDARY_SET.Tarot
                        }
                    end
                end
            end
        end
    end
}