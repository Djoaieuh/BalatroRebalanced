--------------------------------------------------------------------------------
-- TAROT TYCOON
-- Every vanilla Tarot has an "Empowered" twin: a separate consumable with the
-- same art, its own text and its own effect.
--   * Tarots in the shop / Arcana Packs roll EMPOWER_CHANCE to turn into their
--     twin a moment after appearing (normal card first, then the reveal).
--   * Emperor and The Fool (Empowered) create Empowered cards directly.
--   * The twins never appear in normal pools (in_pool = false).
-- NOT FULLY TESTED IN-GAME. Spots most likely to need tweaks are marked "CHECK".
--------------------------------------------------------------------------------

local EMPOWER_CHANCE = 0.25
local VOUCHER_KEY    = 'v_tarot_tycoon'

local PREFIX     = SMODS.current_mod.prefix
local SHADER_KEY = PREFIX .. '_empowered'   -- name used for G.SHADERS / draw_shader (the .fs extern is plain "empowered")
local PURPLE     = HEX('9b30ff')

local EMPOWERED_OF = {}   -- 'c_chariot' -> 'c_<prefix>_empowered_chariot'
local BASE_OF      = {}   -- the reverse
local POOL         = {}   -- every empowered key (Emperor picks from this)

--#region Voucher

-- Tarot Tycoon no longer boosts Tarot frequency (same idea as Planet Tycoon).
SMODS.Voucher:take_ownership('tarot_tycoon', {
    loc_txt = {
        name = 'Tarot Tycoon',
        text = {
            '{C:tarot}Tarot{} cards in the shop and',
            '{C:attention}Arcana Packs{} have a {C:green}' .. math.floor(EMPOWER_CHANCE * 100) .. '%{} chance',
            'to be {C:purple}Empowered{}',
        },
    },
    redeem = function(self, card) end,
}, true)

local function tycoon_active()
    return G.GAME and G.GAME.used_vouchers and G.GAME.used_vouchers[VOUCHER_KEY]
end

--#endregion

--#region Shader + visuals

SMODS.Shader({ key = 'empowered', path = 'empowered.fs' })

local function send_progress(card)
    local sh = G.SHADERS and G.SHADERS[SHADER_KEY]
    if sh then pcall(function() sh:send('empower_prog', card.reba_prog or 1) end) end
end

-- idle bob: faint oversized ghost floating behind the card (like The Soul)
SMODS.DrawStep({
    key = 'empowered_aura',
    order = 9, -- CHECK: must draw before the center sprite
    func = function(self, layer)
        if self.config.center.reba_empowered then
            send_progress(self)
            local bob = 0.08 + 0.04 * math.sin(1.8 * G.TIMERS.REAL)
            self.children.center:draw_shader(SHADER_KEY, 0, self.ARGS.send_to_shader,
                nil, self.children.center, 0.05, 0, 0, bob, nil, 0.6)
        end
    end,
    conditions = { vortex = false, facing = 'front' },
})

-- the shader on the card itself
SMODS.DrawStep({
    key = 'empowered',
    order = 25, -- after the edition shader
    func = function(self, layer)
        if self.config.center.reba_empowered then
            send_progress(self)
            self.children.center:draw_shader(SHADER_KEY, nil, self.ARGS.send_to_shader)
        end
    end,
    conditions = { vortex = false, facing = 'front' },
})

local function after(delay, fn)
    G.E_MANAGER:add_event(Event({
        trigger = 'after', delay = delay, blockable = false,
        func = function() fn(); return true end,
    }))
end

local function empower_fx(card)
    card.reba_prog = 0
    card:juice_up(0.6, 0.4)
    play_sound('holo1', 0.55, 0.9)
    play_sound('gold_seal', 0.7, 0.5)

    -- smaller, fewer, slower
    Particles(card.T.x + card.T.w / 2, card.T.y + card.T.h / 2, 0, 0, {
    timer_type = 'TOTAL', timer = 0.05, pulse_max = 8,
    scale = 0.22, speed = 1.5, lifespan = 1.1,
    attach = card,
    colours = { HEX('d94dff'), HEX('7a1fd1'), HEX('fff0ff') },
    fill = true,
    })

    -- surging shake while the flames sweep up, fading out as it completes
    for i = 1, 4 do
        after(0.2 * i, function()
            if not card.removed then card:juice_up(0.35 - 0.07 * i, 0.25 - 0.05 * i) end
        end)
    end

    G.E_MANAGER:add_event(Event({
        trigger = 'ease', blockable = false,
        ref_table = card, ref_value = 'reba_prog',
        ease_to = 1, delay = 0.9,
        func = function(t) return t end,
    }))
end

local function badge(self, card, badges)
    badges[#badges + 1] = create_badge('Empowered', PURPLE, G.C.WHITE, 1.2)
end

--#endregion

--#region Registering the Empowered consumables

local function register(name, vanilla_key, def)
    local vc = G.P_CENTERS[vanilla_key]
    -- build the full key BEFORE SMODS.Consumable rewrites def.key with the prefix
    local full = 'c_' .. PREFIX .. '_empowered_' .. name

    def.key = 'empowered_' .. name
    def.set = 'Tarot'
    def.atlas = vc.atlas or 'Tarot'
    def.prefix_config = { atlas = false }   -- keep vanilla's 'Tarot' atlas name
    def.pos = vc.pos
    def.cost = vc.cost or 3
    def.discovered = true
    def.no_mod_badges = true                -- hides the "Balatro Rebalanced" mod badge
    def.reba_empowered = true               -- read by the draw steps
    def.in_pool = function() return false end
    def.set_badges = badge
    SMODS.Consumable(def)

    EMPOWERED_OF[vanilla_key] = full
    BASE_OF[full] = vanilla_key
    POOL[#POOL + 1] = full
end

local function room_for_consumable(card)
    return #G.consumeables.cards < G.consumeables.config.card_limit or card.area == G.consumeables
end

local function can_target(self, card)
    if not G.hand then return false end
    local n = #G.hand.highlighted
    return n >= (card.ability.min_highlighted or 1) and n <= card.ability.max_highlighted
end

-- flip the targets, apply fn to each, flip back, then run after_fn
local function flip_apply(card, targets, fn, after_fn)
    G.E_MANAGER:add_event(Event({
        trigger = 'after', delay = 0.4,
        func = function() play_sound('tarot1'); card:juice_up(0.3, 0.5); return true end,
    }))
    for i, c in ipairs(targets) do
        local percent = 1.15 - (i - 0.999) / (#targets - 0.998) * 0.3
        G.E_MANAGER:add_event(Event({
            trigger = 'after', delay = 0.15,
            func = function() c:flip(); play_sound('card1', percent); c:juice_up(0.3, 0.3); return true end,
        }))
    end
    delay(0.2)
    for i, c in ipairs(targets) do
        G.E_MANAGER:add_event(Event({
            trigger = 'after', delay = 0.1,
            func = function() fn(c, i); return true end,
        }))
    end
    for i, c in ipairs(targets) do
        local percent = 0.85 + (i - 0.999) / (#targets - 0.998) * 0.3
        G.E_MANAGER:add_event(Event({
            trigger = 'after', delay = 0.15,
            func = function() c:flip(); play_sound('tarot2', percent, 0.6); c:juice_up(0.3, 0.3); return true end,
        }))
    end
    if after_fn then after_fn() end
    G.E_MANAGER:add_event(Event({
        trigger = 'after', delay = 0.2,
        func = function() G.hand:unhighlight_all(); return true end,
    }))
    delay(0.5)
end

local function highlighted_copy()
    local t = {}
    for i, c in ipairs(G.hand.highlighted) do t[i] = c end
    return t
end

-- Creates an Empowered card in the consumable slots and plays the reveal on it
local function spawn_empowered(ekey, key_append)
    local c = SMODS.add_card({ key = ekey, area = G.consumeables, key_append = key_append or 'reba_empowered' })
    c.reba_prog = 0
    after(0.35, function() if not c.removed then empower_fx(c) end end)
    return c
end

------------------------------ enhancement tarots ------------------------------
for _, e in ipairs({
    -- name,        vanilla key,    enhancement, targets, title
    { 'magician',   'c_magician',   'm_lucky',   3, 'Magician'   },
    { 'empress',    'c_empress',    'm_mult',    3, 'Empress'    },
    { 'hierophant', 'c_heirophant', 'm_bonus',   3, 'Hierophant' },
    { 'lovers',     'c_lovers',     'm_wild',    3, 'Lovers'     },
    { 'chariot',    'c_chariot',    'm_steel',   2, 'Chariot'    },
    { 'justice',    'c_justice',    'm_glass',   2, 'Justice'    },
    { 'devil',      'c_devil',      'm_gold',    2, 'Devil'      },
    { 'tower',      'c_tower',      'm_stone',   2, 'Tower'      },
}) do
    register(e[1], e[2], {
        config = { max_highlighted = e[4], mod_conv = e[3] },
        loc_txt = {
            name = 'Empowered ' .. e[5],
            text = { 'Enhances {C:attention}#1#{} selected', 'cards to {C:attention}#2#s{}' },
        },
        loc_vars = function(self, info_queue, card)
            info_queue[#info_queue + 1] = G.P_CENTERS[card.ability.mod_conv]
            return { vars = {
                card.ability.max_highlighted,
                localize { type = 'name_text', set = 'Enhanced', key = card.ability.mod_conv },
            } }
        end,
        can_use = can_target,
        use = function(self, card, area, copier)
            local conv = card.ability.mod_conv
            flip_apply(card, highlighted_copy(), function(c) c:set_ability(G.P_CENTERS[conv]) end)
        end,
    })
end

--------------------------------- suit tarots ----------------------------------
for _, e in ipairs({
    { 'star',  'c_star',  'Diamonds', 'Star'  },
    { 'moon',  'c_moon',  'Clubs',    'Moon'  },
    { 'sun',   'c_sun',   'Hearts',   'Sun'   },
    { 'world', 'c_world', 'Spades',   'World' },
}) do
    register(e[1], e[2], {
        config = { max_highlighted = 4, suit_conv = e[3] },
        loc_txt = {
            name = 'Empowered ' .. e[4],
            text = { 'Converts {C:attention}#1#{} selected', 'cards to {V:1}#2#{}' },
        },
        loc_vars = function(self, info_queue, card)
            return { vars = {
                card.ability.max_highlighted,
                localize(card.ability.suit_conv, 'suits_plural'),
                colours = { G.C.SUITS[card.ability.suit_conv] },
            } }
        end,
        can_use = can_target,
        use = function(self, card, area, copier)
            local suit = card.ability.suit_conv
            flip_apply(card, highlighted_copy(), function(c) assert(SMODS.change_base(c, suit)) end)
        end,
    })
end

-------------------------------------- others ---------------------------------
register('strength', 'c_strength', {
    config = { max_highlighted = 3 },
    loc_txt = { name = 'Empowered Strength', text = { 'Increases rank of up to', '{C:attention}#1#{} selected cards by {C:attention}1{}' } },
    loc_vars = function(self, info_queue, card) return { vars = { card.ability.max_highlighted } } end,
    can_use = can_target,
    use = function(self, card, area, copier)
        flip_apply(card, highlighted_copy(), function(c) assert(SMODS.modify_rank(c, 1)) end) -- CHECK: needs a recent SMODS
    end,
})

register('hanged_man', 'c_hanged_man', {
    config = { max_highlighted = 3 },
    loc_txt = { name = 'Empowered Hanged Man', text = { 'Destroys up to', '{C:attention}#1#{} selected cards' } },
    loc_vars = function(self, info_queue, card) return { vars = { card.ability.max_highlighted } } end,
    can_use = can_target,
    use = function(self, card, area, copier)
        local targets = highlighted_copy()
        G.E_MANAGER:add_event(Event({
            trigger = 'after', delay = 0.4,
            func = function() play_sound('tarot1'); card:juice_up(0.3, 0.5); return true end,
        }))
        SMODS.destroy_cards(targets)
        delay(0.3)
    end,
})

register('death', 'c_death', {
    config = { max_highlighted = 2, min_highlighted = 2 },
    loc_txt = {
        name = 'Empowered Death',
        text = {
            'Select {C:attention}2{} cards, the {C:attention}left{} card',
            'becomes a copy of the {C:attention}right{} card',
            'and a {C:attention}new copy{} of it is added',
            'to your hand',
        },
    },
    can_use = function(self, card) return G.hand and #G.hand.highlighted == 2 end,
    use = function(self, card, area, copier)
        local targets = highlighted_copy()
        local right = targets[1]
        for _, c in ipairs(targets) do if c.T.x > right.T.x then right = c end end
        flip_apply(card, targets,
            function(c) if c ~= right then copy_card(right, c) end end,
            function()
                G.E_MANAGER:add_event(Event({
                    trigger = 'after', delay = 0.6,
                    func = function()
                        G.playing_card = (G.playing_card and G.playing_card + 1) or 1
                        local copy = copy_card(right, nil, nil, G.playing_card)
                        copy:add_to_deck()
                        G.deck.config.card_limit = G.deck.config.card_limit + 1
                        table.insert(G.playing_cards, copy)
                        G.hand:emplace(copy)
                        copy.states.visible = nil
                        G.E_MANAGER:add_event(Event({ func = function() copy:start_materialize(); return true end }))
                        SMODS.calculate_context({ playing_card_added = true, cards = { copy } })
                        return true
                    end,
                }))
            end)
    end,
})

register('high_priestess', 'c_high_priestess', {
    config = { extra = { planets = 3 } },
    loc_txt = { name = 'Empowered High Priestess', text = { 'Creates up to {C:attention}#1#{} random', '{C:planet}Planet{} cards', '{C:inactive}(Must have room){}' } },
    loc_vars = function(self, info_queue, card) return { vars = { card.ability.extra.planets } } end,
    can_use = function(self, card) return room_for_consumable(card) end,
    use = function(self, card, area, copier)
        for i = 1, card.ability.extra.planets do
            G.E_MANAGER:add_event(Event({
                trigger = 'before', delay = 0.0,
                func = function()
                    if #G.consumeables.cards < G.consumeables.config.card_limit then
                        play_sound('timpani')
                        SMODS.add_card({ set = 'Planet', area = G.consumeables, key_append = 'reba_empowered_priestess' })
                        card:juice_up(0.3, 0.5)
                    end
                    return true
                end,
            }))
        end
        delay(0.6)
    end,
})

register('emperor', 'c_emperor', {
    config = { extra = { count = 2 } },
    loc_txt = { name = 'Empowered Emperor', text = { 'Creates up to {C:attention}#1#{} random', '{C:purple}Empowered{} {C:tarot}Tarot{} cards', '{C:inactive}(Must have room){}' } },
    loc_vars = function(self, info_queue, card) return { vars = { card.ability.extra.count } } end,
    can_use = function(self, card) return room_for_consumable(card) end,
    use = function(self, card, area, copier)
        for i = 1, card.ability.extra.count do
            G.E_MANAGER:add_event(Event({
                trigger = 'before', delay = 0.0,
                func = function()
                    if #G.consumeables.cards < G.consumeables.config.card_limit then
                        play_sound('timpani')
                        local ekey = (pseudorandom_element(POOL, pseudoseed('reba_empowered_emperor')))
                        spawn_empowered(ekey, 'reba_empowered_emperor')
                        card:juice_up(0.3, 0.5)
                    end
                    return true
                end,
            }))
        end
        delay(0.6)
    end,
})

register('hermit', 'c_hermit', {
    config = { extra = 40 },
    loc_txt = { name = 'Empowered Hermit', text = { 'Doubles your money', '{C:inactive}(Max of {C:money}$#1#{C:inactive}){}' } },
    loc_vars = function(self, info_queue, card) return { vars = { card.ability.extra } } end,
    can_use = function(self, card) return true end,
    use = function(self, card, area, copier)
        G.E_MANAGER:add_event(Event({
            trigger = 'after', delay = 0.4,
            func = function()
                ease_dollars(math.max(0, math.min(G.GAME.dollars, card.ability.extra)), true)
                return true
            end,
        }))
        delay(0.6)
    end,
})

-- Temperance: sell value of Jokers AND consumables (the card itself is not counted)
local function sell_total(except)
    local total = 0
    for _, j in ipairs(G.jokers and G.jokers.cards or {}) do total = total + (j.sell_cost or 0) end
    for _, c in ipairs(G.consumeables and G.consumeables.cards or {}) do
        if c ~= except then total = total + (c.sell_cost or 0) end
    end
    return total
end

register('temperance', 'c_temperance', {
    config = { extra = 75 },
    loc_txt = {
        name = 'Empowered Temperance',
        text = {
            'Gives the total {C:attention}sell value{} of all',
            'owned {C:attention}Jokers{} and {C:attention}consumables{}',
            '{C:inactive}(Max of {C:money}$#1#{C:inactive}, currently {C:money}$#2#{C:inactive}){}',
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra, math.min(sell_total(card), card.ability.extra) } }
    end,
    can_use = function(self, card) return true end,
    use = function(self, card, area, copier)
        local amount = math.min(sell_total(card), card.ability.extra)
        G.E_MANAGER:add_event(Event({
            trigger = 'after', delay = 0.4,
            func = function()
                if amount > 0 then ease_dollars(amount, true) end
                card:juice_up(0.3, 0.5)
                return true
            end,
        }))
        delay(0.6)
    end,
})

register('wheel_of_fortune', 'c_wheel_of_fortune', {
    config = { extra = { odds = 2 } },
    loc_txt = {
        name = 'Empowered Wheel of Fortune',
        text = {
            '{C:green}#1# in #2#{} chance to add {C:dark_edition}Foil{},',
            '{C:dark_edition}Holographic{}, or {C:dark_edition}Polychrome{}',
            'edition to a random {C:attention}Joker{}',
        },
    },
    loc_vars = function(self, info_queue, card)
        local n, d = SMODS.get_probability_vars(card, 1, card.ability.extra.odds, 'reba_empowered_wheel')
        return { vars = { n, d } }
    end,
    can_use = function(self, card) return next(SMODS.Edition:get_edition_cards(G.jokers, true)) end,
    use = function(self, card, area, copier)
        local hit = SMODS.pseudorandom_probability(card, 'reba_empowered_wheel', 1, card.ability.extra.odds, 'reba_empowered_wheel')
        G.E_MANAGER:add_event(Event({
            trigger = 'after', delay = 0.4,
            func = function()
                if hit then
                    local eligible = SMODS.Edition:get_edition_cards(G.jokers, true)
                    local target = (pseudorandom_element(eligible, pseudoseed('reba_empowered_wheel_target')))
                    local edition = SMODS.poll_edition { key = 'reba_empowered_wheel_ed', guaranteed = true, no_negative = true }
                    if target and edition then
                        target:set_edition(edition, true)
                        check_for_unlock({ type = 'have_edition' })
                    end
                else
                    card_eval_status_text(card, 'extra', nil, nil, nil, {
                        message = localize('k_nope_ex'), colour = G.C.SECONDARY_SET.Tarot,
                    })
                    play_sound('tarot2', 0.76, 0.4)
                end
                card:juice_up(0.3, 0.5)
                return true
            end,
        }))
        delay(0.6)
    end,
})

register('fool', 'c_fool', {
    loc_txt = {
        name = 'Empowered Fool',
        text = {
            'Creates an {C:purple}Empowered{} copy of the',
            'last {C:tarot}Tarot{} or {C:planet}Planet{} card used',
            '{C:inactive}(Planets are copied as normal)',
            '{s:0.8,C:inactive}(Currently #1#)',
        },
    },
    loc_vars = function(self, info_queue, card)
        local last = G.GAME and G.GAME.last_tarot_planet
        local c = last and G.P_CENTERS[last]
        return { vars = { c and localize { type = 'name_text', key = c.key, set = c.set } or localize('k_none') } }
    end,
    can_use = function(self, card)
        local last = G.GAME.last_tarot_planet
        return room_for_consumable(card) and last and last ~= 'c_fool' and G.P_CENTERS[last] ~= nil
    end,
    use = function(self, card, area, copier)
        local last = G.GAME.last_tarot_planet
        G.E_MANAGER:add_event(Event({
            trigger = 'after', delay = 0.4,
            func = function()
                if G.consumeables.config.card_limit > #G.consumeables.cards then
                    play_sound('timpani')
                    local ekey = EMPOWERED_OF[last]
                    if ekey then
                        spawn_empowered(ekey, 'reba_empowered_fool')
                    else
                        SMODS.add_card({ key = last, area = G.consumeables, key_append = 'reba_empowered_fool' })
                    end
                    card:juice_up(0.3, 0.5)
                end
                return true
            end,
        }))
        delay(0.6)
    end,
})

register('judgement', 'c_judgement', {
    config = { extra = { count = 2 } },
    loc_txt = {
        name = 'Empowered Judgement',
        text = {
            'Creates {C:attention}#1#{} random {C:attention}Jokers{}',
            'Jokers without room are',
            '{C:attention}sold{} for their full price',
        },
    },
    loc_vars = function(self, info_queue, card) return { vars = { card.ability.extra.count } } end,
    can_use = function(self, card) return true end,
    use = function(self, card, area, copier)
        for i = 1, card.ability.extra.count do
            G.E_MANAGER:add_event(Event({
                trigger = 'after', delay = (i == 1) and 0.4 or 0.6,
                func = function()
                    play_sound('timpani')
                    local j = SMODS.create_card { set = 'Joker', area = G.jokers, key_append = 'reba_empowered_judgement' }
                    local fits = (j.edition and j.edition.negative) or #G.jokers.cards < G.jokers.config.card_limit
                    if fits then
                        j:add_to_deck()
                        G.jokers:emplace(j)
                        j:start_materialize()
                    else
                        local value = j.cost or 0 -- CHECK: "full value" = shop price. Use j.sell_cost for sell value
                        j:remove()
                        ease_dollars(value, true)
                        card_eval_status_text(card, 'extra', nil, nil, nil, {
                            message = localize('$') .. value, colour = G.C.MONEY,
                        })
                    end
                    card:juice_up(0.3, 0.5)
                    return true
                end,
            }))
        end
        delay(0.6)
    end,
})

--#endregion

--#region Last-used bookkeeping (for The Fool)

-- Vanilla stores the used card's key in G.GAME.last_tarot_planet BEFORE its effect runs.
--  * Empowered cards are stored as their vanilla base key, so the normal Fool
--    always makes a NON-empowered copy and the Empowered Fool re-empowers it.
--  * Empowered Fool never overwrites it (just like vanilla Fool).
if set_consumeable_usage then
    local usage_ref = set_consumeable_usage
    function set_consumeable_usage(card)
        local prev = G.GAME.last_tarot_planet
        usage_ref(card)
        local key = card and card.config and card.config.center_key
        if key and BASE_OF[key] then
            if key == EMPOWERED_OF['c_fool'] then
                G.GAME.last_tarot_planet = prev
            else
                G.GAME.last_tarot_planet = BASE_OF[key]
            end
        end
    end
end

--#endregion

--#region Rolling: shop and Arcana Packs

local function try_empower(card, seed)
    if not tycoon_active() then return end
    if not (card and card.ability and card.ability.set == 'Tarot') then return end
    if not EMPOWERED_OF[card.config.center.key] then return end
    if pseudorandom(seed) >= EMPOWER_CHANCE then return end

    -- the plain Tarot appears first; a moment later it turns into its Empowered twin
    after(0.8 + math.random() * 0.5, function()
        if card.removed then return end
        local ekey = EMPOWERED_OF[card.config.center.key]   -- re-read: another effect may have changed the card
        if not ekey or not G.P_CENTERS[ekey] then return end
        card.reba_prog = 0
        card:set_ability(G.P_CENTERS[ekey], true)
        card:set_cost()
        empower_fx(card)
    end)
end

local shop_ref = create_card_for_shop
function create_card_for_shop(area)
    local card = shop_ref(area)
    try_empower(card, 'reba_empower_shop')
    return card
end

local smods_create_ref = SMODS.create_card
function SMODS.create_card(t)
    local card = smods_create_ref(t)
    if t and G.pack_cards and t.area == G.pack_cards then
        try_empower(card, 'reba_empower_pack')
    end
    return card
end

local card_update_ref = Card.update
function Card:update(dt)
    card_update_ref(self, dt)
    if self.config and self.config.center and self.config.center.reba_empowered
        and self.states and self.states.visible then
        self.reba_pulse = (self.reba_pulse or (2 + math.random() * 3)) - dt
        if self.reba_pulse <= 0 then
            self.reba_pulse = 3 + math.random() * 3
            self:juice_up(0.06, 0.04)
        end
    end
end

--#endregion