-- highlight_changed.lua
-- Load it from main.lua with:
--     assert(SMODS.load_file('highlight_changed.lua'))()
-- Rename `MyMod` / `mymod_changed` to your own names if you like.

MyMod = MyMod or {}
MyMod.config = SMODS.current_mod.config or {}   -- comes from config.lua

local CHANGED_FLAG = 'mymod_changed'

-- ---------------------------------------------------------------
-- 1. Which cards count as "changed", and what category they're in
-- ---------------------------------------------------------------

-- Keys of anything you changed WITHOUT take_ownership (lovely patches, hooks...)
-- that should still shine, but don't need a Buffed/Nerfed/Reworked label.
MyMod.changed_keys = {
    
}

-- Which badge (if any) a given card gets. One key -> one category.
-- Anything listed here automatically shines too (see is_changed below),
-- so you don't need to also add it to changed_keys.
MyMod.change_type = {
    c_immolate = 'nerfed',
    c_wraith = 'buffed',
    c_ouija = 'reworked',
    c_sigil = 'buffed',
    c_hex = 'reworked',
    c_familiar = 'reworked',
    c_grim = 'reworked',
    c_incantation = 'reworked',
    c_black_hole = 'reworked',
    c_lovers = 'buffed',
    v_hone = 'reworked',
    v_glow_up = 'reworked',
    v_magic_trick = 'buffed',
    v_illusion = 'reworked',
    v_planet_merchant = 'reworked',
    v_planet_tycoon = 'reworked',

    j_greedy_joker = 'buffed',
    j_lusty_joker = 'buffed',
    j_wrathful_joker = 'buffed',
    j_gluttenous_joker = 'buffed',
    j_zany = 'buffed',
    j_mad = 'buffed',
    j_crazy = 'buffed',
    j_wily = 'buffed',
    j_clever = 'buffed',
    j_devious = 'buffed',
    j_four_fingers = 'buffed',
    j_shortcut = 'buffed',
    j_8_ball = 'buffed',
    j_runner = 'buffed',
    j_vampire = 'buffed',
    j_mail = 'nerfed',
    j_fortune_teller = 'buffed',
    j_order = 'buffed',
    j_vagabond = 'buffed',
    j_superposition = 'reworked',
    j_onyx_agate = 'reworked',
    j_marble = 'reworked',
    j_loyalty_card = 'reworked',
    j_hanging_chad = 'reworked',
    j_cloud_9 = 'buffed',
    j_erosion = 'reworked',
    j_throwback = 'reworked',
    j_glass = 'reworked',
    j_merry_andy = 'reworked',
    j_steel_joker = 'reworked',
    j_stone = 'reworked',
    j_flower_pot = 'reworked',
    j_satelite = 'reworked',
    j_shoot_the_moon = 'reworked',
    j_campfire = 'reworked',
    j_matador = 'reworked',
}

MyMod.BADGES = {
    buffed   = { label = 'Buffed',   colour = HEX('4caf50') }, -- green
    nerfed   = { label = 'Nerfed',   colour = HEX('9c27b0') }, -- purple
    reworked = { label = 'Reworked', colour = HEX('fdd835') }, -- yellow
}

function MyMod.is_changed(card)
    local center = card.config and card.config.center
    if not center then return false end
    return center[CHANGED_FLAG] == true
        or MyMod.changed_keys[center.key] == true
        or MyMod.change_type[center.key] ~= nil
end

-- Drop-in replacement for Class:take_ownership that also flags the object
-- for the shine, and optionally assigns it a badge category:
--     MyMod.take_ownership(SMODS.Joker, 'j_joker', { cost = 5 }, 'buffed')
function MyMod.take_ownership(class, key, changes, change_type, silent)
    changes[CHANGED_FLAG] = true
    if change_type then MyMod.change_type[key] = change_type end
    return class:take_ownership(key, changes, silent)
end

-- ---------------------------------------------------------------
-- 2. The shader (assets/shaders/polished.fs)
--    Shader key, file name and the `extern vec2` name in the .fs must all be identical.
-- ---------------------------------------------------------------
MyMod.shader = SMODS.Shader {
    key = 'polished',
    path = 'polished.fs',
}

-- ---------------------------------------------------------------
-- 3. Draw it on top of changed cards (no edition involved)
-- ---------------------------------------------------------------
SMODS.DrawStep {
    key = 'highlight_changed',
    -- Must run AFTER the step that draws the card's main sprite and BEFORE floating sprites.
    -- Check src/card_draw.lua in your Steamodded folder and adjust if the shine is missing.
    order = 44,
    conditions = { facing = 'front' },
    func = function(card, layer)
        if not MyMod.config.highlight_changed then return end
        if card.edition then return end          -- editions keep their own shader
        if card.debuff then return end           -- keep the debuff overlay readable
        if not MyMod.is_changed(card) then return end

        local center = card.config.center
        if not (center.discovered or card.bypass_discovery_center) then return end

        local sprite = card.children and card.children.center
        local key = MyMod.shader and MyMod.shader.key   -- final key, mod prefix included
        if not (sprite and key and G.SHADERS[key]) then return end

        sprite:draw_shader(key, nil, card.ARGS.send_to_shader or { 0, G.TIMERS.REAL })
    end,
}

-- ---------------------------------------------------------------
-- 4. Buffed / Nerfed / Reworked badges, shown next to Common / Tarot / etc.
--    Call MyMod.apply_changed_badges() ONCE, at the very end of main.lua,
--    after every take_ownership call and every card definition has run.
-- ---------------------------------------------------------------
function MyMod.apply_changed_badges()
    for key, center in pairs(G.P_CENTERS) do
        if MyMod.change_type[key] and not center._mymod_badge_hooked then
            local prev_set_badges = center.set_badges
            center.set_badges = function(self, card, badges)
                if prev_set_badges then prev_set_badges(self, card, badges) end
                if MyMod.config.highlight_changed then
                    local def = MyMod.BADGES[MyMod.change_type[key]]
                    if def then
                        badges[#badges + 1] = create_badge(def.label, def.colour, nil, 1)
                    end
                end
            end
            center._mymod_badge_hooked = true
        end
    end
end

-- ---------------------------------------------------------------
-- 5. Settings toggle
--    If you already have a config_tab, just add the create_toggle(...) node to it.
-- ---------------------------------------------------------------
SMODS.current_mod.config_tab = function()
    return {
        n = G.UIT.ROOT,
        config = { align = 'cm', padding = 0.1, colour = G.C.CLEAR },
        nodes = {
            create_toggle({
                label = 'Highlight changed cards',
                ref_table = MyMod.config,
                ref_value = 'highlight_changed',
            }),
        },
    }
end