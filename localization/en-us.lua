return {
    descriptions = {
        Joker = {
            j_balatroRebalanced_TestJoker = {
                name = 'Test Joker',
                text = {
                    '{C:chips}+#1#{} chips'
                }
            },

            j_balatroRebalanced_TestJoker2 = {
                name = 'Test Joker 2',
                text = {
                    {
                        'Gives {C:money}$#1#{} for each',
                        'scoring {C:clubs}Clubs{} card'
                    },{
                        'Money scales by {C:attention}#2#{}',
                        'every trigger',
                        '{C:inactive}(Resets at end of round){}'
                    }
                }
            },

            j_balatroRebalanced_TestJoker3 = {
                name = 'Test Joker 3',
                text = {
                    '{C:red}+#1# discards{}',
                    'Gives {C:money}1${} for each unused {C:red}discard{}'
                }
            }
        },
        Stake = {
            stake_blue = {
                name = 'Blue Stake',
                text = {
                    'Shop rerolls increment by {C:money}$1{} extra',
                    '{s:0.8}Applies all previous Stakes{}'
                }
            }
        },
        Back = {
            b_black = {
                name = 'Black Deck',
                text = {
                    '{C:attention}+1{} Joker slot',
                    'Shop only offers 1 {C:attention}Booster Pack',
                    'and rerolls increment by {C:money}$1{} extra',
                }
            }
        }
    }
}