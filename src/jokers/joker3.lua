SMODS.Joker{
    key = "TestJoker3",
    atlas = "placeholders",
    pos = {
        x = 2,
        y = 0
    },

    config = {
        extra = {
            discards = 2,
        }
    },
    rarity = 3,
    cost = 7,
    loc_vars = function (self, info_queue, card)
        return {
            vars = {
                card.ability.extra.discards,
            }
        }
        
    end,

    add_to_deck = function(self, card, from_debuff)
        G.GAME.round_resets.discards = G.GAME.round_resets.discards + card.ability.extra.discards
        ease_discard(card.ability.extra.discards)
    end;

    remove_from_deck = function(self, card, from_debuff)
        G.GAME.round_resets.discards = G.GAME.round_resets.discards - card.ability.extra.discards
        ease_discard(-card.ability.extra.discards)
    end,

    calc_dollar_bonus = function(seld, card)
        return G.GAME.current_round.discards_left
    end
    
}