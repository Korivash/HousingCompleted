---------------------------------------------------
-- Housing Completed - Sources.lua
-- Master decor item database
---------------------------------------------------
local addonName, HC = ...

-- All housing decor items with sources
-- Format: { name, sourceType, source, cost, zone, coords, mapID, faction, expansion, notes }
HC.DecorItems = {
    -- =====================================================
    -- ACHIEVEMENTS
    -- =====================================================
    -- Dornogal Achievement Items
    { name = "Boulder Springs Recliner", sourceType = "achievement", source = "Sojourner of Isle of Dorn", vendor = "Garnett", cost = "900 Resonance Crystals", zone = "Dornogal", coords = {54.6, 57.2}, mapID = 2339, expansion = "tww" },
    { name = "Dornogal Brazier", sourceType = "achievement", source = "We're Here All Night", vendor = "Garnett", cost = "600 Resonance Crystals", zone = "Dornogal", coords = {54.6, 57.2}, mapID = 2339, expansion = "tww" },
    { name = "Fallside Storage Tent", sourceType = "achievement", source = "Professional Algari Master", vendor = "Garnett", cost = "900 Resonance Crystals", zone = "Dornogal", coords = {54.6, 57.2}, mapID = 2339, expansion = "tww" },
    { name = "Rambleshire Resting Platform", sourceType = "achievement", source = "Rocked to Sleep", vendor = "Garnett", cost = "800 Resonance Crystals", zone = "Dornogal", coords = {54.6, 57.2}, mapID = 2339, expansion = "tww" },
    { name = "Tome of Earthen Directives", sourceType = "achievement", source = "State of the Union", vendor = "Jorid", cost = "750 Resonance Crystals", zone = "Dornogal", coords = {57, 60.6}, mapID = 2339, expansion = "tww" },
    
    -- Ironforge Achievement Items
    { name = "Dark Iron Brazier", sourceType = "achievement", source = "Kings Under the Mountain", vendor = "Dedric Sleetshaper", cost = "700 gold", zone = "Ironforge", coords = {25, 42}, mapID = 87, expansion = "classic" },
    { name = "Shadowforge Stone Chair", sourceType = "achievement", source = "Blood in the Snow", vendor = "Dedric Sleetshaper", cost = "350 gold", zone = "Ironforge", coords = {25, 42}, mapID = 87, expansion = "classic" },
    
    -- Gilneas Achievement Items
    { name = "Arched Rose Trellis", sourceType = "achievement", source = "Reclamation of Gilneas", vendor = "Samantha Buckley", cost = "100 gold", zone = "Gilneas City", coords = {65.2, 47.2}, mapID = 217, expansion = "cata" },
    { name = "Gilnean Bench", sourceType = "achievement", source = "Reclamation of Gilneas", vendor = "Samantha Buckley", cost = "75 gold", zone = "Gilneas City", coords = {65.2, 47.2}, mapID = 217, expansion = "cata" },
    { name = "Gilnean Celebration Keg", sourceType = "achievement", source = "Reclamation of Gilneas", vendor = "Samantha Buckley", cost = "150 gold", zone = "Gilneas City", coords = {65.2, 47.2}, mapID = 217, expansion = "cata", notes = "Worgen only" },
    { name = "Gilnean Stocks", sourceType = "achievement", source = "Reclamation of Gilneas", vendor = "Samantha Buckley", cost = "100 gold", zone = "Gilneas City", coords = {65.2, 47.2}, mapID = 217, expansion = "cata" },
    { name = "Gilnean Washing Line", sourceType = "achievement", source = "Reclamation of Gilneas", vendor = "Samantha Buckley", cost = "125 gold", zone = "Gilneas City", coords = {65.2, 47.2}, mapID = 217, expansion = "cata" },
    { name = "Gilnean Wooden Bed", sourceType = "achievement", source = "Reclamation of Gilneas", vendor = "Samantha Buckley", cost = "75 gold", zone = "Gilneas City", coords = {65.2, 47.2}, mapID = 217, expansion = "cata" },
    
    -- PvP Achievement Items - Alliance
    { name = "Alliance Battlefield Banner", sourceType = "achievement", source = "Me and the Cappin' Makin' It Happen", vendor = "Riica", cost = "600 Honor", zone = "Stormwind", coords = {77.8, 66}, mapID = 84, faction = "alliance", expansion = "classic" },
    { name = "Alliance Dueling Flag", sourceType = "achievement", source = "Wrecking Ball", vendor = "Riica", cost = "1,000 Honor", zone = "Stormwind", coords = {77.8, 66}, mapID = 84, faction = "alliance", expansion = "classic" },
    { name = "Fortified Alliance Banner", sourceType = "achievement", source = "Alterac Grave Robber", vendor = "Riica", cost = "1,200 Honor", zone = "Stormwind", coords = {77.8, 66}, mapID = 84, faction = "alliance", expansion = "classic" },
    { name = "Silverwing Sentinel's Flag", sourceType = "achievement", source = "Persistent Defender", vendor = "Riica", cost = "800 Honor", zone = "Stormwind", coords = {77.8, 66}, mapID = 84, faction = "alliance", expansion = "classic" },
    
    -- PvP Achievement Items - Horde
    { name = "Fortified Horde Banner", sourceType = "achievement", source = "Tower Defense", vendor = "Joruh", cost = "1,200 Honor", zone = "Orgrimmar", coords = {38.8, 72}, mapID = 85, faction = "horde", expansion = "classic" },
    { name = "Horde Battlefield Banner", sourceType = "achievement", source = "Overly Defensive", vendor = "Joruh", cost = "600 Honor", zone = "Orgrimmar", coords = {38.8, 72}, mapID = 85, faction = "horde", expansion = "classic" },
    { name = "Horde Dueling Flag", sourceType = "achievement", source = "The Grim Reaper", vendor = "Joruh", cost = "1,000 Honor", zone = "Orgrimmar", coords = {38.8, 72}, mapID = 85, faction = "horde", expansion = "classic" },
    { name = "Iron Dragonmaw Gate", sourceType = "achievement", source = "Master of Twin Peaks", vendor = "Joruh", cost = "5,000 Honor", zone = "Orgrimmar", coords = {38.8, 72}, mapID = 85, faction = "horde", expansion = "classic" },
    { name = "Warsong Outriders Flag", sourceType = "achievement", source = "Warsong Gulch Veteran", vendor = "Joruh", cost = "800 Honor", zone = "Orgrimmar", coords = {38.8, 72}, mapID = 85, faction = "horde", expansion = "classic" },
    
    -- Order Hall Achievement Items
    { name = "Ebon Blade Planning Map", sourceType = "achievement", source = "Raise an Army for Acherus", vendor = "Quartermaster Ozorg", cost = "1,500 Order Resources", zone = "Acherus", expansion = "legion", notes = "Death Knight only" },
    { name = "Ebon Blade Weapon Rack", sourceType = "achievement", source = "The Deathlord's Campaign", vendor = "Quartermaster Ozorg", cost = "1,200 Order Resources", zone = "Acherus", expansion = "legion", notes = "Death Knight only" },
    { name = "Replica Acherus Soul Forge", sourceType = "achievement", source = "Hidden Potential of the Deathlord", vendor = "Quartermaster Ozorg", cost = "2,500 Order Resources", zone = "Acherus", expansion = "legion", notes = "Death Knight only" },
    
    -- Mechagon Achievement Items
    { name = "Gnomish Cog Stack", sourceType = "achievement", source = "Junkyard Scavenger", vendor = "Stolen Royal Vendorbot", cost = "50 Spare Parts", zone = "Mechagon", coords = {73.6, 36.6}, mapID = 1462, expansion = "bfa" },
    { name = "Gnomish T.O.O.L.B.O.X.", sourceType = "achievement", source = "M.C. Hammered", vendor = "Stolen Royal Vendorbot", cost = "100 Spare Parts", zone = "Mechagon", coords = {73.6, 36.6}, mapID = 1462, expansion = "bfa" },
    { name = "Redundant Reclamation Rig", sourceType = "achievement", source = "Diversified Investments", vendor = "Stolen Royal Vendorbot", cost = "500 gold + materials", zone = "Mechagon", coords = {73.6, 36.6}, mapID = 1462, expansion = "bfa" },
    
    -- Undermine Achievement Items
    { name = "Rocket-Powered Fountain", sourceType = "achievement", source = "Sojourner of Undermine", vendor = "Stacks Topskimmer", cost = "1,500 Resonance Crystals", zone = "Undermine", coords = {43.2, 50.6}, mapID = 2346, expansion = "tww" },
    
    -- =====================================================
    -- DROPS
    -- =====================================================
    { name = "Ancient Elven Highback Chair", sourceType = "drop", source = "Glimmering Treasure Chest", expansion = "legion" },
    { name = "Argussian Crate", sourceType = "drop", source = "L'ura - The Seat of the Triumvirate", expansion = "legion" },
    { name = "Banshee Queen's Banner", sourceType = "drop", source = "Darkshore rares", expansion = "bfa" },
    { name = "Echo of Doragosa", sourceType = "drop", source = "Algeth'ar Academy", expansion = "df" },
    { name = "Gilnean Circular Rug", sourceType = "drop", source = "Lord Godfrey - Shadowfang Keep", expansion = "cata" },
    { name = "Gnomish Tesla Tower", sourceType = "drop", source = "King Mechagon - Operation: Mechagon", expansion = "bfa" },
    { name = "Horde Battle Emblem", sourceType = "drop", source = "Warlord Zaela - Upper Blackrock Spire", expansion = "wod" },
    { name = "Horde Warlord's Throne", sourceType = "drop", source = "Garrosh Hellscream - Siege of Orgrimmar", expansion = "mop" },
    { name = "Magistrix's Garden Fountain", sourceType = "drop", source = "Spellblade Aluriel - The Nighthold", expansion = "legion" },
    { name = "Meadery Ochre Window", sourceType = "drop", source = "Goldie Baronbottom - Cinderbrew Meadery", expansion = "tww" },
    { name = "Moon-Blessed Storage Crate", sourceType = "drop", source = "Shade of Xavius - Darkheart Thicket", expansion = "legion" },
    { name = "Ornate Suramar Table", sourceType = "drop", source = "Advisor Melandrus - Court of Stars", expansion = "legion" },
    { name = "Overgrown Arathi Trellis", sourceType = "drop", source = "Prioress Murrpray - Priory of the Sacred Flame", expansion = "tww" },
    { name = "Qalashi Goulash", sourceType = "drop", source = "Warlord Sargha - Neltharus", expansion = "df" },
    { name = "Stolen Ironforge Seat", sourceType = "drop", source = "Harlan Sweete - Freehold", expansion = "bfa" },
    { name = "Stormwind Footlocker", sourceType = "drop", source = "Deadmines", expansion = "classic" },
    { name = "Thunder Totem Brazier", sourceType = "drop", source = "Dargul - Neltharion's Lair", expansion = "legion" },
    { name = "Tome of Pandaren Wisdom", sourceType = "drop", source = "Sha of Doubt - Temple of the Jade Serpent", expansion = "mop" },
    { name = "Tome of Reliquary Insights", sourceType = "drop", source = "Viz'aduum the Watcher - Karazhan", expansion = "legion" },
    { name = "Trashfire Barrel", sourceType = "drop", source = "Treasure - Undermine", expansion = "tww" },
    { name = "Valdrakken Hanging Lamp", sourceType = "drop", source = "Ruby Life Pools", expansion = "df" },
    
    -- =====================================================
    -- PROMOTIONS
    -- =====================================================
    { name = "\"The Harbinger\" Painting", sourceType = "promo", source = "Midnight Epic Edition", expansion = "midnight" },
    { name = "\"The High Exarch\" Painting", sourceType = "promo", source = "Midnight Epic Edition", expansion = "midnight" },
    { name = "\"The Ranger of the Void\" Painting", sourceType = "promo", source = "Midnight Epic Edition", expansion = "midnight" },
    { name = "\"The Redeemer\" Painting", sourceType = "promo", source = "Midnight Epic Edition", expansion = "midnight" },
    { name = "Light-Infused Fountain", sourceType = "promo", source = "Midnight Epic Edition", expansion = "midnight" },
    { name = "Light-Infused Rotunda", sourceType = "promo", source = "Midnight Epic Edition", expansion = "midnight" },
    { name = "Void-Corrupted Fountain", sourceType = "promo", source = "Midnight Epic Edition", expansion = "midnight" },
    { name = "Void-Corrupted Rotunda", sourceType = "promo", source = "Midnight Epic Edition", expansion = "midnight" },
    { name = "Hatred's Wolfpelt Rug", sourceType = "promo", source = "Diablo IV: Lord of Hatred pre-purchase", expansion = "tww" },
    { name = "Prime Evil's Chest", sourceType = "promo", source = "Diablo IV: Lord of Hatred pre-purchase", expansion = "tww" },
    { name = "Sanctuary Chess Board", sourceType = "promo", source = "Diablo IV: Lord of Hatred pre-purchase", expansion = "tww" },
}
