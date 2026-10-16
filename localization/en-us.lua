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

            j_merry_andy = {
                name = 'Merry Andy',
                text = {
                    "Gives {C:red}+#1# discard{}",
                    "and {C:attention}#2#{} Consumable slot"
                },
                unlock = {
                    "Skip {C:attention}6{} shops",
                    "in a single run",
                },
            },

            j_wee = {
                unlock = {
                    "Skip {C:attention}9{} shops",
                    "in a single run",
                },
            },

            j_steel_joker = {
                name = "Steel Joker",
                text = {
                    "Whenever you {C:red}discard{},",
                    "you will always draw at least",
                    "1 {C:attention}Steel Card{}",
                    "{C:inactive}(if any are left in the deck){}"
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
                    "Your {C:green}probability{} effects",
                    "trigger {C:attention}#1#{} extra times",
                },
            },

            j_flower_pot_clubs = {
                name = "Clubs Flower Pot",
                text = {
                    "After scoring {C:attention}#1#{} {C:clubs}Clubs{},",
                    "create a {C:spectral}Spectral{} card",
                    "{C:inactive}(Must have room) (#2#/#1#)",
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
                    "Every time you {C:money}earn money{},",
                    "gain {C:money}$#1#{} more",
                },
            },

            j_satellite = {
                name = "Satellite",
                text = {
                    "At end of round, gain {C:money}$#1#{}",
                    "for each {C:attention}#2#{} level you have",
                    "After you play a {C:attention}#2#{},",
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

            j_campfire = {
                name = "Campfire",
                text = {
                    "After you sell a {V:1}#3#{} gain",
                    "{X:mult,C:white}X#1#{} Mult and change target",
                    "Selling anything else",
                    "resets this Joker to {X:mult,C:white}X1{} Mult",
                    "{C:inactive}(Currently {X:mult,C:white}X#2#{C:inactive} Mult)",
                },
            },

            j_matador = {
                name = "Matador",
                text = {
                    "When {C:attention}Boss Blind{} is selected,",
                    "gain {C:blue}+#1#{} Hands",
                },
            },

            j_bull = {
                name = "Bull",
                text = {
                    "This Joker gains {C:chips}+#1#{} Chips every",
                    "time you {C:money}earn money{}",
                    "{C:inactive}(Currently {C:chips}+#2#{C:inactive} Chips)",
                },
            },
            j_bootstraps = {
                name = "Bootstraps",
                text = {
                    "When selecting a {C:attention}Blind{}, if you have",
                    "{C:money}more money{} than you did when selecting",
                    "the previous {C:attention}Blind{} {C:inactive}(${C:money}#3#{C:inactive})",
                    "gain {C:mult}+#1#{} Mult, otherwise reset to {C:mult}0{} Mult",
                    "{C:inactive}(Currently {C:mult}+#2#{C:inactive} Mult)",
                },
            },

            j_hologram = {
                name = "Hologram",
                text = {
                    "This Joker gains {X:mult,C:white}X#1#{} Mult",
                    "every time a {C:attention}playing card{}",
                    "is added to your deck",
                    "{C:inactive}(Currently {X:mult,C:white}X#2#{C:inactive} Mult)",
                },
            },

            j_hiker = {
                name = "Hiker",
                text = {
                    "Every played {C:attention}card{} permanently",
                    "gains {C:chips}+#1#{} Chips when scored,",
                    "and the bonus counts {C:attention}immediately{}",
                },
            },

            j_splash = {
                name = "Splash",
                text = {
                    "Every {C:attention}played card{} counts in scoring",
                    "Cards that wouldn't have scored in the",
                    "original hand trigger an {C:attention}extra{} time",
                },
            },

            j_fortune_teller = {
                name = "Fortune Teller",
                text = {
                    "After you use a {C:tarot}Tarot{} card,",
                    "gain {C:red}+#1#{} Mult",
                    "{C:inactive}(Currently {C:red}+#2#{C:inactive} Mult)",
                },
            },

            j_glass = {
                name = "Glass Joker",
                text = {
                    "{X:mult,C:white}X#1#{} Mult for every",
                    "{C:attention}Glass Card{} that was",
                    "destroyed this run",
                    "{C:inactive}(Currently {X:mult,C:white}X#2#{C:inactive} Mult)",
                },
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
        },

        Voucher = {
            v_hone = {
                name = 'Hone',
                text = {
                    '{C:green}Uncommon{} Jokers are',
                    '{C:attention}X1.5{} as likely to appear'
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
                    'Whenever you buy a {C:planet}Planet{} card,',
                    'automatically {C:attention}refill{} its {C:attention}Shop{} slot',
                }
            },

            v_planet_tycoon = {
                name = "Planet Tycoon",
                text = {
                    '{C:planet}Planet{} cards now upgrade',
                    'your {C:attention}poker hands{} by',
                    'an {C:attention}extra level{}'
                },
            },

            v_tarot_tycoon = {
                name = 'Tarot Tycoon',
                text = {
                    '{C:tarot}Tarot{} cards from the shop and',
                    '{C:attention}Arcana Packs{} have a chance',
                    'to be {C:purple}Empowered{}',
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
                    'make it {C:blue}Perishable{}.'
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
                    'Add 2 random {C:attention}Enhanced Aces{}',
                    'to your hand and create a random',
                    '{C:dark_edition}Negative{} {C:tarot}Tarot{} card'
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
                    "{C:attention}+2{} hand size",
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

        Tag = {
            tag_boss = {
                name = "Boss Tag",
                text = {
                    "Disables the next",
                    "{C:attention}Boss Blind{} when selected",
                },
            },

            tag_d_six = {
                name = "D6 Tag",
                text = {
                    "Your next {C:attention}3{} rerolls",
                    "cost {C:money}$0{}",
                },
            },
            tag_charm = {
                name = "Charm Tag",
                text = {
                    "Get a free {C:attention}Mega Arcana Pack{}",
                    "with an extra {C:tarot}#1# card{} inside",
                },
            },
            tag_meteor = {
                name = "Meteor Tag",
                text = {
                    "Get {C:money}$1{} per {C:planet}Planet{} card",
                    "used this run",
                    "{C:inactive}(Currently {C:money}$#1#{C:inactive})",
                },
            },
            tag_standard = {
                name = "Standard Tag",
                text = {
                    "Get a free {C:attention}Mega Standard Pack{}",
                    "with an extra card with a",
                    "{C:attention}#1#{}",
                },
            },
            tag_buffoon = {
                name = "Buffoon Tag",
                text = {
                    "Get a free {C:attention}Mega Buffoon Pack{}",
                    "with an extra {C:attention}#1#{}",
                },
            },

            tag_foil = {
                name = "Foil Tag",
                text = {
                    "A random {C:attention}Joker{} and a random",
                    "card in your deck become {C:dark_edition}Foil{}",
                },
            },
            tag_holo = {
                name = "Holographic Tag",
                text = {
                    "A random {C:attention}Joker{} and a random",
                    "card in your deck become {C:dark_edition}Holographic{}",
                },
            },
            tag_polychrome = {
                name = "Polychrome Tag",
                text = {
                    "A random {C:attention}Joker{} and a random",
                    "card in your deck become {C:dark_edition}Polychrome{}",
                },
            },

            tag_top_up = {
                name = "Top-up Tag",
                text = {
                    "Create up to {C:attention}3{} {C:blue}Common{} Jokers",
                    "{C:inactive}(Must have room){}",
                },
            },
            tag_orbital = {
                name = "Orbital Tag",
                text = {
                    "Upgrade {C:attention}#1#{} by",
                    "{C:attention}#2#{} levels",
                },
            },
            tag_economy = {
                name = "Economy Tag",
                text = {
                    "Doubles your next",
                    "{C:attention}cash out{}"
                },
            },

            tag_ethereal = {
                name = "Ethereal Tag",
                text = {
                    "Gives a free",
                    "{C:spectral}Mega Spectral Pack{}",
                },
            },

            tag_uncommon = {
                name = "Uncommon Tag",
                text = {
                    "Next {C:green}Uncommon Joker{} you buy",
                    "becomes {C:attention}Rental{} and is {C:attention}duplicated{}",
                    "{C:inactive}(Must have room){}",
                },
            },
            tag_rare = {
                name = "Rare Tag",
                text = {
                    "Get a free",
                    "{C:red}Rare Buffoon Pack{}",
                },
            },
            tag_coupon = {
                name = "Coupon Tag",
                text = {
                    "Next time you {C:attention}skip{}, get the reward",
                    "but proceed to the {C:attention}shop{} anyway",
                },
            },

            tag_garbage = {
                name = "Garbage Tag",
                text = {
                    "Gain {C:money}$#1#{} for each unused",
                    "{C:red}discard{} this run",
                    "{C:inactive}(Currently {C:money}$#2#{C:inactive})",
                },
            },
            
            tag_juggle = {
                name = "Juggle Tag",
                text = {
                    "{C:attention}+4{} hand size. At the end",
                    "of each round, lose {C:attention}1{}",
                    "bonus hand size",
                },
            },

            tag_handy = {
                name = "Handy Tag",
                text = {
                    "When you run out of {C:blue}hands{}",
                    "without beating the blind,",
                    "gain {C:blue}+3{} hands",
                },
            },

            tag_skip = {
                name = "Skip Tag",
                text = {
                    "Gives {C:money}$#1#{} for each",
                    "{C:attention}shop{} skipped this run",
                    "{C:inactive}(Currently {C:money}$#2#{C:inactive})",
                },
            },
        },

        Other = {
            p_reba_buffoon_rare = {
                name = "Rare Buffoon Pack",
                text = {
                    "Choose {C:attention}#1#{} of up to",
                    "{C:attention}#2#{} {C:red}Rare{C:attention} Joker{} cards",
                },
            },

            blue_seal = {
                name = 'Blue Seal',
                text = {
                    "Creates the {C:attention}Planet{} card",
                    "for the final {C:attention}poker hand{}",
                    "played, if held in hand.",
                    "{C:red}Destroys{} this card after",
                    "generating {C:attention}3{} Planet cards.",
                    "{C:inactive}(#1# left !)"
                }
            }
        },
    },

    misc = {
        dictionary = {
            k_throwback_left = "1 left!",
            k_throwback_done = "Done!",
            k_csau_most_played = "your most played hand",
            ph_economy_match = "Match your earnings",
        },
    },
}