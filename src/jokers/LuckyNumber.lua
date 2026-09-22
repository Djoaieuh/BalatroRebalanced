-- ============================================================
-- Lucky Number (placeholder name -- swap loc_txt.name for your real one)
--
-- Each hand, a random target number is picked. If the sum of the scored
-- cards' rank values (2-10 numeric, 10 for face cards, 11 for Ace -- the
-- same "blackjack style" values Balatro itself uses for base chips)
-- exactly matches the target, you gain +1 hand for the rest of the round.
-- The target re-rolls every hand.
-- ============================================================

SMODS.Joker {
    key = "lucky_number",
    loc_txt = {
        name = "Lucky Number",
        text = {
            "If scored cards' ranks add up",
            "to {C:attention}#1#{} this hand, gain",
            "{C:attention}+1{} hand this round",
            "{s:0.8,C:inactive}(target changes each hand)"
        }
    },
    atlas = "placeholders",
    pos = { x = 2, y = 0 },   -- adjust to a free atlas slot

    config = {
        extra = {
            target = 21,          -- current hand's target, re-rolled each hand
            current_sum = 0,       -- running total for THIS hand
            min_target = 15,
            max_target = 25
        }
    },
    rarity = 2,
    cost = 5,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,

    loc_vars = function(self, info_queue, card)
        return {
            vars = { card.ability.extra.target }
        }
    end,

    calculate = function(self, card, context)
        -- Reset the running sum at the start of each hand's accumulation.
        -- (Target is NOT rerolled here -- see joker_main below for why.)
        if context.individual and context.cardarea == G.play then
            local c = context.other_card

            if context.full_hand and c == context.full_hand[1] then
                card.ability.extra.current_sum = 0
            end

            if c and c.base then
                local rank_value = c.base.nominal or 0
                card.ability.extra.current_sum = card.ability.extra.current_sum + rank_value
                print("LUCKY NUMBER: added " .. tostring(rank_value) .. ", running sum = " .. tostring(card.ability.extra.current_sum))
            end
        end

        -- Check the total against the target that was DISPLAYED while this hand
        -- was being played, THEN roll the next target for the upcoming hand.
        -- Rolling here (after the check, not before) ensures the number shown
        -- on the card before you play always matches what gets checked.
        if context.joker_main then
            print("LUCKY NUMBER: joker_main check -- sum=" .. tostring(card.ability.extra.current_sum) .. " target=" .. tostring(card.ability.extra.target))
            local hit = card.ability.extra.current_sum == card.ability.extra.target

            card.ability.extra.target = pseudorandom(
                "lucky_number_target",
                card.ability.extra.min_target,
                card.ability.extra.max_target
            )
            print("LUCKY NUMBER: rolled next target = " .. tostring(card.ability.extra.target))

            if hit then
                print("LUCKY NUMBER: MATCH! Granting +1 hand")
                ease_hands_played(1)

                return {
                    message = "+1 Hand!",
                    colour = G.C.SECONDARY_SET.Spectral
                }
            end
        end
    end
}