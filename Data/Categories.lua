---------------------------------------------------
-- Housing Completed - Categories.lua
-- Decor source categories and filters
---------------------------------------------------
local addonName, HC = ...

HC.SourceTypes = {
    { id = "achievement", name = "Achievement", icon = "Interface\\Icons\\Achievement_General_100kQuests", color = {1, 0.8, 0.2} },
    { id = "vendor", name = "Vendor", icon = "Interface\\Icons\\INV_Misc_Coin_01", color = {0.3, 0.9, 0.3} },
    { id = "quest", name = "Quest", icon = "Interface\\Icons\\INV_Misc_Book_07", color = {1, 1, 0.4} },
    { id = "reputation", name = "Reputation", icon = "Interface\\Icons\\Achievement_Reputation_08", color = {0.6, 0.4, 1} },
    { id = "profession", name = "Profession", icon = "Interface\\Icons\\INV_Misc_Note_01", color = {1, 0.5, 0.2} },
    { id = "drop", name = "Drop", icon = "Interface\\Icons\\INV_Misc_Bag_10_Blue", color = {0.4, 0.7, 1} },
    { id = "auction", name = "Auction House", icon = "Interface\\Icons\\INV_Misc_Coin_02", color = {1, 0.82, 0} },
    { id = "promo", name = "Promotion", icon = "Interface\\Icons\\INV_Misc_Gift_05", color = {1, 0.4, 0.8} },
    { id = "unknown", name = "Unknown", icon = "Interface\\Icons\\INV_Misc_QuestionMark", color = {0.5, 0.5, 0.5} },
}

HC.Expansions = {
    { id = "classic", name = "Classic", color = {1, 0.82, 0} },
    { id = "tbc", name = "The Burning Crusade", color = {0.6, 1, 0} },
    { id = "wotlk", name = "Wrath of the Lich King", color = {0.4, 0.6, 1} },
    { id = "cata", name = "Cataclysm", color = {1, 0.4, 0} },
    { id = "mop", name = "Mists of Pandaria", color = {0.2, 0.8, 0.4} },
    { id = "wod", name = "Warlords of Draenor", color = {0.6, 0.3, 0.1} },
    { id = "legion", name = "Legion", color = {0.1, 0.8, 0.1} },
    { id = "bfa", name = "Battle for Azeroth", color = {0.8, 0.6, 0.2} },
    { id = "sl", name = "Shadowlands", color = {0.4, 0.5, 0.8} },
    { id = "df", name = "Dragonflight", color = {0.2, 0.6, 0.8} },
    { id = "tww", name = "The War Within", color = {0.5, 0.3, 0.7} },
    { id = "midnight", name = "Midnight", color = {0.8, 0.2, 0.4} },
}

-- Correct profession icons
HC.Professions = {
    { id = "alchemy", name = "Alchemy", icon = "Interface\\Icons\\Trade_Alchemy" },
    { id = "blacksmithing", name = "Blacksmithing", icon = "Interface\\Icons\\Trade_BlackSmithing" },
    { id = "cooking", name = "Cooking", icon = "Interface\\Icons\\INV_Misc_Food_15" },
    { id = "enchanting", name = "Enchanting", icon = "Interface\\Icons\\Trade_Engraving" },
    { id = "engineering", name = "Engineering", icon = "Interface\\Icons\\Trade_Engineering" },
    { id = "herbalism", name = "Herbalism", icon = "Interface\\Icons\\Trade_Herbalism" },
    { id = "inscription", name = "Inscription", icon = "Interface\\Icons\\INV_Inscription_Tradeskill01" },
    { id = "jewelcrafting", name = "Jewelcrafting", icon = "Interface\\Icons\\INV_Misc_Gem_02" },
    { id = "leatherworking", name = "Leatherworking", icon = "Interface\\Icons\\Trade_LeatherWorking" },
    { id = "mining", name = "Mining", icon = "Interface\\Icons\\Trade_Mining" },
    { id = "skinning", name = "Skinning", icon = "Interface\\Icons\\INV_Misc_Pelt_Wolf_01" },
    { id = "tailoring", name = "Tailoring", icon = "Interface\\Icons\\Trade_Tailoring" },
    { id = "fishing", name = "Fishing", icon = "Interface\\Icons\\Trade_Fishing" },
    { id = "archaeology", name = "Archaeology", icon = "Interface\\Icons\\Trade_Archaeology" },
}

-- Lookup table for quick access
HC.ProfessionIcons = {}
for _, prof in ipairs(HC.Professions) do
    HC.ProfessionIcons[prof.id] = prof.icon
    HC.ProfessionIcons[prof.name:lower()] = prof.icon
end

HC.DecorCategories = {
    { id = "furnishings", name = "Furnishings", icon = "Interface\\Icons\\INV_Misc_Basket_01" },
    { id = "lighting", name = "Lighting", icon = "Interface\\Icons\\INV_Misc_Lantern_01" },
    { id = "decorative", name = "Decorative", icon = "Interface\\Icons\\INV_Misc_Flower_01" },
    { id = "storage", name = "Storage", icon = "Interface\\Icons\\INV_Crate_01" },
    { id = "structures", name = "Structures", icon = "Interface\\Icons\\Achievement_GuildPerk_MassResurrection" },
    { id = "outdoor", name = "Outdoor", icon = "Interface\\Icons\\INV_Misc_Herb_01" },
    { id = "trophies", name = "Trophies", icon = "Interface\\Icons\\INV_Misc_Head_Dragon_01" },
    { id = "misc", name = "Miscellaneous", icon = "Interface\\Icons\\INV_Misc_QuestionMark" },
}
