# Changelog

## [0.2.2]

### Changed

- Fortune Teller now only counts Tarot cards used after you obtained it
- Flower Pot now needs 20 cards of the same suit in a row instead of 25
- Hearts Flower Pot now makes your probability effects (Lucky Cards, Bloodstone, 8 Ball, etc.) trigger 2 extra times instead of giving +4 hand size
- Clubs Flower Pot now creates a Spectral card after scoring 10 Clubs instead of copying the Joker to its right
- Diamonds Flower Pot now gives $2 more every time you earn money instead of retriggering Enhancements, Seals and Editions
- Hiker now gives +7 Chips instead of +5, and the bonus also scores immediately
- Hologram now gains X0.2 Mult per card added instead of X0.25
- Juggle Tag now gives +4 hand size, then you lose 1 bonus hand size at the end of each round
- Uncommon Tag now adds a Rental sticker to the next Uncommon Joker you buy and duplicates it
- Rare Tag now gives a free Rare Buffoon Pack which contains 3 Rare Jokers
- Meteor Tag now gives $1 per Planet card used this run 
- Charm Tag now gives a Mega Arcana Pack with an extra pre-announced Tarot card
- Buffoon Tag now gives a Mega Buffoon Pack with an extra pre-announced Uncommon or Rare Joker
- Standard Tag now gives a Mega Standard Pack with an extra card with a pre-announced random Seal
- Handy Tag now gives +3 hands when you run out of hands without beating the blind
- Hone now makes Uncommon Jokers X1.5 as likely to appear instead of X2
- Adjusted several poker hand level-up values:
  - Full House: +3 Mult / +25 Chips per level 
  - Four of a Kind: +4 Mult / +30 Chips per level
  - Straight Flush: +5 Mult / +50 Chips per level 
  - Five of a Kind: +4 Mult / +40 Chips per level 
  - Straight and Flush Five are back to their vanilla level-up values
- Shoot the Moon is now an Uncommon Joker
- Glass Joker now gains 0.75X mult per Glass card you've destroyed this run
- D6 Tag now makes your next 3 rerolls cost $0
- Tarot Tycoon now gives a chance for your Tarots cards to be empowered (Empowered Tarots cards are more powerful versions of the original)
- The Order was reverted to X3 mult

## [0.2.1]

### Changed

- Erosion now only appears when you have at least one Stone Card in the deck
- Shortcut is now an Uncommon Joker again
- Neptune now gives +5 Mult / +60 Chips instead of +8 Mult / +80 Chips
- Bull now gains +3 Chips every time you earn money instead of +2
- Loyalty card can no longer spawn with an Eternal Sticker
- Familiar now only converts 2 cards to face cards down from 3
- Bootstraps now resets if you don't have more money than when selecting the previous blind
- Satelite now gives 2$ per hand level, and always starts on your most played hand
- Skip Tag now displays how much money it's going to give
- Flash Card now gains +3 Mult instead of +2
- Planet Merchant and Planet Tycoon's effects were swapped
- Planet Merchant now refills a shop slot whenever you buy a Planet card
- Splash now retriggers cards that wouldn't have scored in the original hand
- Hex now makes your right-most Joker Perishable instead of Eternal
- Steel Joker description now clarifies you need to have a Steel card in deck to draw one
- Changed Merry Andy and Wee Joker unlock conditions to require skipping the shop instead
- Grim now adds 2 Aces and creates 1 random Negative Tarot card
- Wraith now sets your money to 5 instead of 10
- 8 Ball now has a 1 in 3 chance instead of 1 in 2 

### Fixed

- Fixed a bug where resuming the game on the skip selection screen would cause a softlock
- Fixed a bug where opening a Booster Pack with an active Booster Pack tag would crash the game

## [0.2.0]

### Changed

- Reworked skipping mechanic entirely
- Reworked several skip tags. Check the [patch notes](https://github.com/Djoaieuh/BalatroRebalanced/blob/main/PATCHNOTES.md) to see changes
- Bull and Bootstraps effect has been reworked. Check the [patch notes](https://github.com/Djoaieuh/BalatroRebalanced/blob/main/PATCHNOTES.md) to see changes

### Fixed

- Marble Joker crashing the game when played with Stone Cards

## [0.1.1]

### Added 
- Support for JokerDisplay mod 
- Highlighted shader now has sparkles 
- Custom Sprite for each Flower Pot variant

### Fixed
- Satelite not having the "Reworked" tag and not being correctly highlighted
- Fortune Teller still giving 1 mult per Tarot card used
- Removed Hone and Glow Up debug message
- Fixed ERROR in black hole message

### Changed
- Card Sharp nerfed from X3 Mult to X2 Mult
- Fortune Teller nerfed from giving +3 mult for each Tarot card used to +2 mult
- Ghost Deck starts with a Hex card again instead of a Ouija card
- Loyalty card now activates after 4 hands instead of 6
- Loyalty card now has a shaking animation when ready 
- Flower Pot variants now appear in the collection after obtaining them in a run

## [0.1.0] 
### Added
- Initial release