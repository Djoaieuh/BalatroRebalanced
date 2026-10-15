-- shop_skip.lua
-- After every blind, shows a panel before the shop opens: "Proceed to Shop",
-- or "Skip Shop" to take a tag and go straight back to blind select.
-- With a Coupon Tag owned, skipping still gives the tag and opens the shop.

local PANEL_HEIGHT = 10
local PANEL_Y_OFFSET = 3  -- negative = up, positive = down
local PANEL_DELAY = 0.25  -- seconds between cash out and the panel appearing

-- disable vanilla blind skipping
G.FUNCS.skip_blind = function(e) end

-- The tag is rolled once per shop visit and stored in G.GAME so the
-- preview matches the reward and survives save/reload
local function roll_skip_tag_key()
  local key = get_next_tag_key('shopskip')
  for _ = 1, 10 do
    if key ~= 'tag_orbital' then break end -- Orbital needs per-blind setup
    key = get_next_tag_key('shopskip')
  end
  return key
end

-- The preview tag and the tag you actually receive are two separate Tag objects, and each rolls
-- its own bonus card on creation. Roll once per shop visit and share it between both.
local TAG_ROLL_FIELDS = {
  ['Charm Tag'] = 'charm_card',        -- extra Tarot
  ['Buffoon Tag'] = 'buffoon_joker',   -- extra Uncommon/Rare Joker
  ['Standard Tag'] = 'standard_seal',  -- extra card's Seal
}

local function sync_tag_roll(tag)
  local field = TAG_ROLL_FIELDS[tag.name]
  if not field then return end
  G.GAME.shop_skip_roll = G.GAME.shop_skip_roll or {}
  G.GAME.shop_skip_roll[field] = G.GAME.shop_skip_roll[field] or tag.ability[field]
  tag.ability[field] = G.GAME.shop_skip_roll[field]
end

function create_UIBox_shop_choice()
  local _tag = Tag(G.GAME.shop_skip_tag_key, nil, G.GAME.blind_on_deck)

  sync_tag_roll(_tag)

  local _tag_ui, _tag_sprite = _tag:generate_UI()
  _tag_sprite.states.collide.can = true -- lets hovering the tag show its tooltip

  -- no logo row if the atlas isn't found
  local sign_row = nil
  if G.ANIMATION_ATLAS and G.ANIMATION_ATLAS['shop_sign'] then
    local sign = AnimatedSprite(0, 0, 2.6, 1.3, G.ANIMATION_ATLAS['shop_sign'], {x = 0, y = 0})
    sign:define_draw_steps({
      {shader = 'dissolve', shadow_height = 0.05},
      {shader = 'dissolve'}
    })
    sign_row = {n = G.UIT.R, config = {align = "cm", minh = 1.5}, nodes = {
      {n = G.UIT.O, config = {object = sign}}
    }}
  end

  local extras = {n = G.UIT.R, config = {id = 'tag_container', ref_table = _tag, align = "cm"}, nodes = {
    {n = G.UIT.R, config = {align = 'tm', minh = 0.65}, nodes = {
      {n = G.UIT.T, config = {text = localize('k_or'), scale = 0.55, colour = G.C.WHITE, shadow = true}},
    }},
    {n = G.UIT.R, config = {id = 'tag_shop_choice', align = "cm", r = 0.1, padding = 0.1, minw = 1, can_collide = true, ref_table = _tag_sprite}, nodes = {
      {n = G.UIT.C, config = {id = 'tag_desc', align = "cm", minh = 1}, nodes = {
        _tag_ui
      }},
      {n = G.UIT.C, config = {align = "cm", colour = G.C.RED, minh = 0.6, minw = 2, maxw = 2, padding = 0.07, r = 0.1, shadow = true, hover = true, one_press = true, button = 'shop_choice_skip'}, nodes = {
        {n = G.UIT.T, config = {text = 'Skip Shop', scale = 0.4, colour = G.C.UI.TEXT_LIGHT, shadow = true}}
      }},
    }}
  }}

  return {n = G.UIT.ROOT, config = {align = "cm", colour = G.C.CLEAR}, nodes = {
    {n = G.UIT.R, config = {align = "tm", minh = PANEL_HEIGHT, r = 0.1, padding = 0.05, colour = mix_colours(G.C.BLACK, G.C.L_BLACK, 0.5), outline = 1.5, outline_colour = G.C.ORANGE}, nodes = {
      {n = G.UIT.R, config = {align = "cm", colour = mix_colours(G.C.BLACK, G.C.L_BLACK, 0.5), r = 0.1, outline = 1, outline_colour = G.C.L_BLACK}, nodes = {
        {n = G.UIT.R, config = {align = "cm", padding = 0.2}, nodes = {
          {n = G.UIT.R, config = {align = "cm", colour = G.C.ORANGE, minh = 0.6, minw = 2.9, padding = 0.07, r = 0.1, shadow = true, hover = true, one_press = true, button = 'shop_choice_enter'}, nodes = {
            {n = G.UIT.T, config = {text = 'Proceed to Shop', scale = 0.4, colour = G.C.UI.TEXT_LIGHT, shadow = true}}
          }},
        }},
        sign_row,
      }},
      {n = G.UIT.R, config = {id = 'blind_extras', align = "cm"}, nodes = {
        extras,
      }},
    }}
  }}
end

local function remove_choice_ui()
  if G.shop_choice then
    G.shop_choice:remove()
    G.shop_choice = nil
  end
end

local update_shop_ref = Game.update_shop
function Game:update_shop(dt)
  if not G.STATE_COMPLETE then
    -- G.load_shop_jokers is set when loading a save that was mid-shop;
    -- don't ask again in that case
    if not G.GAME.shop_choice_made and not G.load_shop_jokers then
      G.STATE_COMPLETE = true -- stops vanilla from building the shop

      -- A panel left over from a previous run (restarting or quitting to the menu
      -- while it was open) would still be referenced here and stop the new one
      -- from ever appearing. Nothing can legitimately own it at this point.
      if G.shop_choice then
        pcall(function() G.shop_choice:remove() end)
        G.shop_choice = nil
      end

      G.GAME.shop_skip_tag_key = G.GAME.shop_skip_tag_key or roll_skip_tag_key()

      -- delayed so a fast double-click on Cash Out can't hit "Proceed to Shop"
      -- before the panel is visible
      G.E_MANAGER:add_event(Event({
        trigger = 'after',
        delay = PANEL_DELAY,
        blocking = false,
        blockable = false,
        func = function()
          if G.STATE == G.STATES.SHOP and not G.shop_choice then
            G.shop_choice = UIBox{
              definition = create_UIBox_shop_choice(),
              config = {align = 'cm', offset = {x = 0, y = PANEL_Y_OFFSET}, major = G.ROOM_ATTACH, bond = 'Weak'}
            }
          end
          return true
        end
      }))
      return
    end
    G.GAME.shop_choice_made = nil -- consumed; next shop asks again
  end
  return update_shop_ref(self, dt)
end

G.FUNCS.shop_choice_enter = function(e)
  stop_use()
  remove_choice_ui()
  G.GAME.shop_skip_tag_key = nil -- unused; new roll next shop
  G.GAME.shop_skip_roll = nil -- unused; new roll next shop
  G.GAME.shop_choice_made = true
  G.STATE_COMPLETE = false -- next update_shop builds the shop as normal
end

G.FUNCS.shop_choice_skip = function(e)
  stop_use()
  remove_choice_ui()

  -- grab an owned Coupon Tag before adding the new tag so it can't consume itself
  local coupon
  for _, t in ipairs(G.GAME.tags) do
    if t.name == 'Coupon Tag' and not t.triggered then coupon = t; break end
  end

  -- count the skip first so Skip Tag includes this one
  G.GAME.skips = (G.GAME.skips or 0) + 1
  check_for_unlock({ type = 'shop_skips' })

  local key = G.GAME.shop_skip_tag_key or roll_skip_tag_key()
  G.GAME.shop_skip_tag_key = nil

  local new_tag = Tag(key, nil, G.GAME.blind_on_deck)
  sync_tag_roll(new_tag)  -- same bonus card / Joker / Seal the preview showed
  G.GAME.shop_skip_roll = nil
  add_tag(new_tag)

  -- fire immediate tags (Skip Tag, Top-up, Economy...) like vanilla skip_blind
  G.E_MANAGER:add_event(Event({
    trigger = 'immediate',
    func = function()
      delay(0.3)
      for i = 1, #G.GAME.tags do
        G.GAME.tags[i]:apply_to_run({type = 'immediate'})
      end
      return true
    end
  }))

  if coupon then
    coupon.triggered = true
    coupon:yep('+', G.C.GREEN, function() return true end)
    G.GAME.shop_choice_made = true
    G.STATE_COMPLETE = false
    return
  end

  G.STATE_COMPLETE = false
  G.STATE = G.STATES.BLIND_SELECT
end