SMODS.Joker{
    key = "TestJoker2",
    atlas = "placeholders",
    pos = {
        x = 1,
        y = 0
    },

    config = {
        extra = {
            dollars = 1,
            reset = 1,
            scalar = 1
        }
    },
    rarity = 2,
    cost = 6,
    loc_vars = function (self, info_queue, card)
        return {
            vars = {
                card.ability.extra.dollars,
                card.ability.extra.scalar
            }
        }
        
    end,

    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play and context.other_card:is_suit('Clubs') then 

            SMODS.calculate_effect({dollars = card.ability.extra.dollars, context.other_card})

            SMODS.scale_card(card, {
                ref_table = card.ability.extra, 
                ref_value = 'dollars',
                scalar_value = 'scalar',
                message_colour = G.C.ATTENTION
            })
        end    

        if context.end_of_round and not context.blueprint and not context.repetition and not context.individual then
            card.ability.extra.dollars = card.ability.extra.reset
            return {
                message = localize('k_reset')
            }
        end
    end    
}