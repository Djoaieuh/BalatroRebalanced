return {
    descriptions = {
        Joker = {
            j_hanging_chad = {
                name = 'Hanging Chad',
                text = {
                    'Retrigger the {C:attention}first{} and',
                    '{C:attention}last{} played card in scoring'
                }
            },

            j_cloud_9 = {
                name = 'Cloud 9',
                text = {
                    'Earn {C:money}$1{} for each',
                    '{C:attention}9{} you played this round',
                    'and each {C:attention}9{} in your',
                    '{C:attention}full deck{} at end of round',
                    '{C:inactive}(Currently: {C:money}$#2#{}{C:inactive}){}'
                }
            },

            j_erosion = {
                name = "Erosion",
                text = {
                    "Destroys {C:attention}1{} scored {C:attention}Stone Card{}",
                    "per hand to gain {X:mult,C:white}X#1#{} Mult",
                    "{C:inactive}(Currently {X:mult,C:white}X#2#{C:inactive} Mult)",
                },
            },

            j_throwback = {
                name = "Throwback",
                text = {
                    "Once per round, after you",
                    "{C:attention}skip{} a {C:attention}Booster Pack{},",
                    "open another of the {C:attention}same type{}",
                    "{C:inactive}(#1#){}",
                },
            },

            j_glass = {
                name = "Glass Joker",
                text = {
                    "Glass cards now have a",
                    "{C:green}1 in 2{} chance to break",
                    "but give {X:mult,C:white}X3{} Mult"
                }
            },

            j_merry_andy = {
                name = 'Merry Andy',
                text = {
                    "Gives {C:red}+#1# discard{}",
                    "and {C:attention}#2#{} Consumable slot"
                }
            },

            j_steel_joker = {
                name = "Steel Joker",
                text = {
                    "Whenever you {C:red}discard{},",
                    "you will always draw at least",
                    "1 {C:attention}Steel Card{}"
                }
            },

            j_stone = {
                name = "Stone Joker",
                text = {
                    "{C:attention}Stone Cards{} can form",
                    "{C:attention}Poker Hands{}"
                }
            },

            j_flower_pot = {
                name = "Flower Pot",
                text = {
                    "After playing {C:attention}#1#{} cards of the",
                    "same {C:attention}suit{} in a row, transforms",
                    "into that suit's {C:attention}Flower Pot{}",
                    "{C:inactive}(Streak: {V:1}#2#{C:inactive}, #3#/#1#)",
                },
            },

            j_flower_pot_hearts = {
                name = "Hearts Flower Pot",
                text = {
                    "{C:attention}+#1#{} hand size",
                },
            },

            j_flower_pot_clubs = {
                name = "Clubs Flower Pot",
                text = {
                    "Copies ability of",
                    "{C:attention}Joker{} to the right",
                },
            },

            j_flower_pot_spades = {
                name = "Spades Flower Pot",
                text = {
                    "{C:attention}+#1#{} Voucher available in",
                    "the shop each {C:attention}Ante{}",
                },
            },

            j_flower_pot_diamonds = {
                name = "Diamonds Flower Pot",
                text = {
                    "Playing card {C:attention}Enhancements{},",
                    "{C:attention}Seals{} and {C:attention}Editions{}",
                    "trigger an {C:attention}extra{} time",
                },
            },

            j_satellite = {
                name = "Satellite",
                text = {
                    "At end of round, gain {C:money}$2{}",
                    "for each {C:attention}#1#{} level you have",
                    "After you play a {C:attention}#1#{},",
                    "this changes hand"
                }
            },

            j_shoot_the_moon = {
                name = "Shoot the Moon",
                text = {
                    "If the first card in your {C:attention}played hand{}",
                    "is a {C:attention}Queen{}, convert all other",
                    "cards to the {C:attention}Queen's suit{}"
                }
            },
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
            },

            b_ghost = {
                name = 'Ghost Deck',
                text = {
                    '{C:blue}Spectral{} cards may',
                    'appear in the shop,',
                    'start with a {C:blue}Ouija{} card'
                }
            }
        },

        Voucher = {
            v_hone = {
                name = 'Hone',
                text = {
                    '{C:green}Uncommon{} Jokers are',
                    '{C:attention}X2{} as likely to appear'
                }
            },

            v_glow_up = {
                name = 'Glow Up',
                text = {
                    '{C:red}Rare{} Jokers are',
                    '{C:attention}X2{} as likely to appear'
                }
            },

            v_magic_trick = {
                name = "Magic Trick",
                text = {
                    "Playing cards can be",
                    "purchased from the shop",
                    "and may have an {C:attention}Enhancement{},",
                    "{C:dark_edition}Edition{}, and/or {C:attention}Seal{}",
                },
            },
            v_illusion = {
                name = "Illusion",
                text = {
                    "Every {C:attention}#1#{} rerolls, spawn",
                    "a {C:attention}Booster Pack{} in the shop",
                    "{C:inactive}(Currently {C:attention}#2#{C:inactive}/#1#)",
                },
            },

            v_planet_merchant = {
                name = 'Planet Merchant',
                text = {
                    '{C:planet}Planet{} cards now upgrade',
                    'your {C:attention}poker hands{} by',
                    'an {C:attention}extra level{}'
                }
            },

            v_planet_tycoon = {
                name = "Planet Tycoon",
                text = {
                    "Whenever you use a {C:planet}Planet{} card",
                    "in the {C:attention}Shop{},",
                    "reduce the reroll cost by {C:money}$2{}"
                },
            },

        },

        Spectral = {
            c_ouija = {
                name = 'Ouija',
                text = {
                    "Converts all cards in hand",
                    "to a single {C:attention}random rank{}",
                    "They are {C:red}debuffed{} until",
                    "the {C:attention}next Ante{}"
                }
            },

            c_sigil = {
                name = 'Sigil',
                text = {
                    'Converts all cards in hand',
                    'to the {C:attention}suit{} of the {C:attention}selected card{}'
                }
            },

            c_hex = {
                name = 'Hex',
                text = {
                    'Add {C:edition}Polychrome{} to',
                    'your {C:attention}right-most{} Joker and',
                    'make it {C:dark_edition}Eternal{}.'
                }
            },

            c_incantation = {
                name = 'Incantation',
                text = {
                    '{C:red}Destroy{} a card and',
                    "add it's {C:attention}rank{}",
                    "to it's neighbours"
                }
            },

            c_grim = {
                name = 'Grim',
                text = {
                    'Add a random {C:attention}Enhanced Ace{}',
                    'to your hand and create {C:attention}2{} random',
                    '{C:dark_edition}Negative{} {C:tarot{} cards'
                }
            },

            c_familiar = {
                name = 'Familiar',
                text = {
                    '{C:red}Destroy{} {C:attention}#1#{} random cards',
                    'and convert {C:attention}#2#{} cards into',
                    'random {C:attention}Enhanced{} face cards'
                }
            },

            c_black_hole = {
                name = "Black Hole",
                text = {
                    "{C:attention}+1{} hand size",
                    "you can no longer play",
                    "{C:attention}#1#{}"
                }
            },
        },

        Enhanced = {
            m_glass = {
                name = "Glass Card",
                text = {
                    "{X:mult,C:white}X#1#{} Mult",
                    "{C:green}#2# in #3#{} chance to break"
                }
            }
        },

        Other = {
            blue_seal = {
                name = 'Blue Seal',
                text = {
                    "Creates the {C:attention}Planet{} card",
                    "for the final {C:attention}poker hand{}",
                    "played, if held in hand.",
                    "{C:red}Destroys{} this card after",
                    "generating {C:attention}3{} Planet cards.",
                    "{C:inactive}(#1# left !)#"
                }
            }
        },
    },

    misc = {
        dictionary = {
            k_throwback_left = "1 left!",
            k_throwback_done = "Done!",
            k_csau_most_played = "your most played hand",
        },
    },
}