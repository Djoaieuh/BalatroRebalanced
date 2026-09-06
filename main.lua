--#region Atlases

SMODS.Atlas{
    key = 'placeholders',
    path = 'placeholders.png',
    px = 71,
    py = 95
}


--#endregion


--#region File Loading

print("MOD PATH: " .. tostring(SMODS.current_mod.path))
print("LOOKING IN: " .. tostring(SMODS.current_mod.path .. "src/jokers"))

local jokers_src = SMODS.NFS.getDirectoryItems(SMODS.current_mod.path .. "src/jokers")

print("FILES FOUND: " .. tostring(#jokers_src))

for _, file in ipairs(jokers_src) do
    assert(SMODS.load_file("src/jokers/" .. file))()
end

--#endregion