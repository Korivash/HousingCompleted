---------------------------------------------------
-- Housing Completed - Achievements.lua
-- Achievement-based housing decor
---------------------------------------------------
local addonName, HC = ...

-- Achievement decor items: { name, achievementName, vendor, vendorZone, cost }
HC.AchievementItems = {
    -- PvP Achievements
    { name = "Alliance Battlefield Banner", achievement = "Me and the Cappin' Makin' It Happen", vendor = "Riica", zone = "Stormwind", cost = "600 Honor", faction = "alliance" },
    { name = "Alliance Dueling Flag", achievement = "Wrecking Ball", vendor = "Riica", zone = "Stormwind", cost = "1,000 Honor", faction = "alliance" },
    { name = "Horde Battlefield Banner", achievement = "Overly Defensive", vendor = "Joruh", zone = "Orgrimmar", cost = "600 Honor", faction = "horde" },
    { name = "Horde Dueling Flag", achievement = "The Grim Reaper", vendor = "Joruh", zone = "Orgrimmar", cost = "1,000 Honor", faction = "horde" },
    { name = "Berserker's Empowerment", achievement = "Entering Battle", vendor = "Riica/Joruh", cost = "5 Honor" },
    { name = "Challenger's Dueling Flag", achievement = "Duel-icious", vendor = "Riica/Joruh", cost = "1,000 Honor" },
    { name = "Deephaul Crystal", achievement = "Sprinting in the Ravine", vendor = "Riica/Joruh", cost = "2,500 Honor" },
    { name = "Kotmogu Orb of Power", achievement = "Master of Temple of Kotmogu", vendor = "Riica/Joruh", cost = "1,000 Honor" },
    { name = "Kotmogu Pedestal", achievement = "Master of Temple of Kotmogu", vendor = "Riica/Joruh", cost = "2,000 Honor" },
    
    -- Dungeon/Raid Achievements
    { name = "Head of the Broodmother", achievement = "More Dots! (25 player)", vendor = "Axle", zone = "Dustwallow Marsh", cost = "250 gold" },
    
    -- Order Hall Achievements - Death Knight
    { name = "Ebon Blade Planning Map", achievement = "Raise an Army for Acherus", vendor = "Quartermaster Ozorg", zone = "Acherus", cost = "1,500 Order Resources", class = "DEATHKNIGHT" },
    { name = "Ebon Blade Weapon Rack", achievement = "The Deathlord's Campaign", vendor = "Quartermaster Ozorg", zone = "Acherus", cost = "1,200 Order Resources", class = "DEATHKNIGHT" },
    { name = "Replica Acherus Soul Forge", achievement = "Hidden Potential of the Deathlord", vendor = "Quartermaster Ozorg", zone = "Acherus", cost = "2,500 Order Resources", class = "DEATHKNIGHT" },
    { name = "Replica Libram of the Dead", achievement = "Legendary Research of the Ebon Blade", vendor = "Quartermaster Ozorg", zone = "Acherus", cost = "2,000 Order Resources", class = "DEATHKNIGHT" },
    
    -- Order Hall Achievements - Demon Hunter
    { name = "Fel Hammer Scouting Map", achievement = "Raise an Army for the Fel Hammer", vendor = "Falara Nightsong", zone = "Fel Hammer", cost = "1,500 Order Resources", class = "DEMONHUNTER" },
    { name = "Illidari Glaiverest", achievement = "The Slayer's Campaign", vendor = "Falara Nightsong", zone = "Fel Hammer", cost = "1,200 Order Resources", class = "DEMONHUNTER" },
    { name = "Replica Cursed Forge of the Nathrezim", achievement = "Hidden Potential of the Slayer", vendor = "Falara Nightsong", zone = "Fel Hammer", cost = "2,500 Order Resources", class = "DEMONHUNTER" },
    
    -- Order Hall Achievements - Druid
    { name = "Brazier of Elune", achievement = "The Archdruid's Campaign", vendor = "Amurra Thistledew", zone = "The Dreamgrove", cost = "1,200 Order Resources", class = "DRUID" },
    { name = "Cenarion Arch", achievement = "Raise an Army for the Dreamgrove", vendor = "Amurra Thistledew", zone = "The Dreamgrove", cost = "1,500 Order Resources", class = "DRUID" },
    { name = "Seed of Ages Cutting", achievement = "Hidden Potential of the Archdruid", vendor = "Amurra Thistledew", zone = "The Dreamgrove", cost = "2,500 Order Resources", class = "DRUID" },
    
    -- Mechagon Achievements
    { name = "Gnomish Cog Stack", achievement = "Junkyard Scavenger", vendor = "Stolen Royal Vendorbot", zone = "Mechagon", cost = "50 Spare Parts" },
    { name = "Gnomish T.O.O.L.B.O.X.", achievement = "M.C. Hammered", vendor = "Stolen Royal Vendorbot", zone = "Mechagon", cost = "100 Spare Parts" },
    { name = "Redundant Reclamation Rig", achievement = "Diversified Investments", vendor = "Stolen Royal Vendorbot", zone = "Mechagon", cost = "500 gold + materials" },
    { name = "Screw-Sealed Stembarrel", achievement = "Junkyard Apprentice", vendor = "Stolen Royal Vendorbot", zone = "Mechagon", cost = "1 S.P.A.R.E. Crate" },
    
    -- Gilneas Achievements
    { name = "Arched Rose Trellis", achievement = "Reclamation of Gilneas", vendor = "Samantha Buckley", zone = "Gilneas City", cost = "100 gold" },
    { name = "Gilnean Bench", achievement = "Reclamation of Gilneas", vendor = "Samantha Buckley", zone = "Gilneas City", cost = "75 gold" },
    { name = "Gilnean Celebration Keg", achievement = "Reclamation of Gilneas", vendor = "Samantha Buckley", zone = "Gilneas City", cost = "150 gold", notes = "Worgen only" },
    { name = "Gilnean Stocks", achievement = "Reclamation of Gilneas", vendor = "Samantha Buckley", zone = "Gilneas City", cost = "100 gold" },
    { name = "Gilnean Washing Line", achievement = "Reclamation of Gilneas", vendor = "Samantha Buckley", zone = "Gilneas City", cost = "125 gold" },
    { name = "Gilnean Wooden Bed", achievement = "Reclamation of Gilneas", vendor = "Samantha Buckley", zone = "Gilneas City", cost = "75 gold" },
    
    -- Current Content Achievements
    { name = "Boulder Springs Recliner", achievement = "Sojourner of Isle of Dorn", vendor = "Garnett", zone = "Dornogal", cost = "900 Resonance Crystals" },
    { name = "Dornogal Brazier", achievement = "We're Here All Night", vendor = "Garnett", zone = "Dornogal", cost = "600 Resonance Crystals" },
    { name = "Rocket-Powered Fountain", achievement = "Sojourner of Undermine", vendor = "Stacks Topskimmer", zone = "Undermine", cost = "1,500 Resonance Crystals" },
    
    -- Exploration Achievements
    { name = "Goldshire Food Cart", achievement = "Full Caravan", vendor = "Fiona", zone = "Various", cost = "3,000 gold" },
    { name = "Nesingwary Elk Trophy", achievement = "The Green Hills of Stranglethorn", vendor = "Jaquilina Dramet", zone = "Northern Stranglethorn", cost = "450 gold" },
    { name = "Nesingwary Shoveltusk Trophy", achievement = "The Snows of Northrend", vendor = "Purser Boulian", zone = "Sholazar Basin", cost = "500 gold" },
    
    -- Suramar Achievements
    { name = "\"Night on the Jeweled Estate\" Painting", achievement = "Good Suramaritan", vendor = "Jocenna", zone = "Suramar", cost = "1,000 gold + 2,000 OR", notes = "Also requires Exalted with The Nightfallen" },
    { name = "Deluxe Suramar Sleeper", achievement = "Insurrection", vendor = "Jocenna", zone = "Suramar", cost = "1,200 Order Resources" },
    
    -- Val'sharah Achievements
    { name = "Kaldorei Treasure Trove", achievement = "Treasures of Val'sharah", vendor = "Selfira Ambergrove", zone = "Val'sharah", cost = "750 Order Resources" },
    { name = "Shala'nir Feather Bed", achievement = "That's Val'sharah Folks!", vendor = "Selfira Ambergrove", zone = "Val'sharah", cost = "950 Order Resources" },
}
