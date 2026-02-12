---------------------------------------------------
-- Housing Completed - Vendors.lua
-- All housing decor vendors with locations
---------------------------------------------------
local addonName, HC = ...

-- Vendor database: { id, name, zone, subzone, x, y, mapID, faction, expansion, items = {} }
HC.Vendors = {
    -- =====================================================
    -- CLASSIC
    -- =====================================================
    { id = 68364, name = "Paul North", zone = "Brawl'gar Arena", x = 52.0, y = 27.8, mapID = 503, faction = "horde", expansion = "classic", notes = "Brawler's Guild" },
    { id = 68363, name = "Quackenbush", zone = "Bizmo's Brawlpub", x = 51.0, y = 30.0, mapID = 499, faction = "alliance", expansion = "classic", notes = "Brawler's Guild" },
    { id = 13217, name = "Thanthaldis Snowgleam", zone = "Hillsbrad Foothills", subzone = "The Headland", x = 44.6, y = 46.6, mapID = 25, faction = "neutral", expansion = "classic" },
    { id = 44337, name = "Maurice Essman", zone = "Blasted Lands", subzone = "Surwich", x = 45.8, y = 88.6, mapID = 17, faction = "alliance", expansion = "classic" },
    { id = 115805, name = "Hoddruc Bladebender", zone = "Burning Steppes", subzone = "Chiselgrip", x = 46.8, y = 44.6, mapID = 36, faction = "neutral", expansion = "classic" },
    { id = 1247, name = "Innkeeper Belm", zone = "Dun Morogh", subzone = "Kharanos", x = 54.4, y = 50.8, mapID = 27, faction = "alliance", expansion = "classic", notes = "Gnome/Dwarf only" },
    { id = 44114, name = "Wilkinson", zone = "Duskwood", subzone = "Raven Hill", x = 20.2, y = 58.2, mapID = 47, faction = "alliance", expansion = "classic" },
    { id = 23995, name = "Axle", zone = "Dustwallow Marsh", subzone = "Mudsprocket", x = 41.8, y = 74.0, mapID = 70, faction = "neutral", expansion = "classic" },
    { id = 45417, name = "Fiona", zone = "Eastern Plaguelands", subzone = "Light's Hope Chapel", x = 73.8, y = 52.2, mapID = 23, faction = "neutral", expansion = "classic" },
    { id = 253235, name = "Dedric Sleetshaper", zone = "Ironforge", subzone = "The Commons", x = 24.72, y = 43.93, mapID = 87, faction = "alliance", expansion = "classic" },
    { id = 50309, name = "Captain Stonehelm", zone = "Ironforge", subzone = "The Great Forge", x = 55.8, y = 47.8, mapID = 87, faction = "alliance", expansion = "classic" },
    { id = 253232, name = "Inge Brightview", zone = "Ironforge", subzone = "Hall of Explorers", x = 76, y = 8.6, mapID = 87, faction = "alliance", expansion = "classic" },
    { id = 1465, name = "Drac Roughcut", zone = "Loch Modan", subzone = "Thelsamar", x = 35.6, y = 49.0, mapID = 48, faction = "alliance", expansion = "classic" },
    { id = 254606, name = "Joruh", zone = "Orgrimmar", subzone = "Hall of Legends", x = 38.8, y = 71.93, mapID = 85, faction = "horde", expansion = "classic" },
    { id = 50488, name = "Stone Guard Nargol", zone = "Orgrimmar", x = 50.2, y = 58.4, mapID = 85, faction = "horde", expansion = "classic" },
    { id = 256119, name = "Lonalo", zone = "Orgrimmar", subzone = "The Drag", x = 58.4, y = 50.6, mapID = 85, faction = "horde", expansion = "classic" },
    { id = 261262, name = "Gabbi", zone = "Orgrimmar", subzone = "Near Trading Post", x = 48.4, y = 81.0, mapID = 85, faction = "horde", expansion = "classic" },
    { id = 14624, name = "Master Smith Burninate", zone = "Searing Gorge", subzone = "Thorium Point", x = 38.6, y = 28.7, mapID = 32, faction = "neutral", expansion = "classic" },
    { id = 2140, name = "Edwin Harly", zone = "Silverpine Forest", subzone = "The Sepulcher", x = 44.06, y = 39.68, mapID = 21, faction = "horde", expansion = "classic" },
    { id = 49877, name = "Captain Lancy Revshon", zone = "Stormwind City", subzone = "Trade District", x = 67.79, y = 73.05, mapID = 84, faction = "alliance", expansion = "classic" },
    { id = 256071, name = "Solelo", zone = "Stormwind City", subzone = "Mage Quarter", x = 49.0, y = 80.0, mapID = 84, faction = "alliance", expansion = "classic" },
    { id = 254603, name = "Riica", zone = "Stormwind City", subzone = "Old Town", x = 77.8, y = 65.8, mapID = 84, faction = "alliance", expansion = "classic" },
    { id = 261231, name = "Tuuran", zone = "Stormwind City", subzone = "Near Trading Post", x = 48.6, y = 68.8, mapID = 84, faction = "alliance", expansion = "classic" },
    { id = 2483, name = "Jacquilina Dramet", zone = "Northern Stranglethorn", subzone = "Nesingwary's Expedition", x = 43.6, y = 23, mapID = 50, faction = "neutral", expansion = "classic" },
    { id = 50483, name = "Brave Tuho", zone = "Thunder Bluff", x = 46.6, y = 50.6, mapID = 88, faction = "horde", expansion = "classic" },
    { id = 3178, name = "Stuart Fleming", zone = "Wetlands", subzone = "Menethil Harbor", x = 6.27, y = 57.45, mapID = 56, faction = "alliance", expansion = "classic" },
    
    -- =====================================================
    -- THE BURNING CRUSADE
    -- =====================================================
    { id = 16528, name = "Provisioner Vredigar", zone = "Ghostlands", subzone = "Tranquillien", x = 47.6, y = 32.4, mapID = 95, faction = "horde", expansion = "tbc" },
    
    -- =====================================================
    -- WRATH OF THE LICH KING
    -- =====================================================
    { id = 28038, name = "Purser Boulian", zone = "Sholazar Basin", subzone = "Nesingwary Base Camp", x = 26.8, y = 59.2, mapID = 119, faction = "neutral", expansion = "wotlk" },
    { id = 27391, name = "Woodsman Drake", zone = "Grizzly Hills", subzone = "Amberpine Lodge", x = 32.4, y = 60, mapID = 116, faction = "alliance", expansion = "wotlk" },
    { id = 25206, name = "Ahlurglgr", zone = "Borean Tundra", subzone = "Winterfin Retreat", x = 43.03, y = 13.78, mapID = 114, faction = "neutral", expansion = "wotlk" },
    
    -- =====================================================
    -- CATACLYSM
    -- =====================================================
    { id = 211065, name = "Marie Allen", zone = "Gilneas", subzone = "Stormglen Village", x = 60.4, y = 92.4, mapID = 217, faction = "alliance", expansion = "cata" },
    { id = 50307, name = "Lord Candren", zone = "Gilneas City", x = 56.94, y = 55.91, mapID = 217, faction = "alliance", expansion = "cata" },
    { id = 216888, name = "Samantha Buckley", zone = "Gilneas City", x = 65.2, y = 47.2, mapID = 217, faction = "alliance", expansion = "cata" },
    { id = 253227, name = "Breana Bitterbrand", zone = "Twilight Highlands", subzone = "Thundermar", x = 49.6, y = 29.6, mapID = 241, faction = "alliance", expansion = "cata" },
    
    -- =====================================================
    -- MISTS OF PANDARIA
    -- =====================================================
    { id = 58414, name = "San Redscale", zone = "The Jade Forest", subzone = "Arboretum", x = 56.6, y = 44.4, mapID = 371, faction = "neutral", expansion = "mop" },
    { id = 59698, name = "Brother Furtrim", zone = "Kun-Lai Summit", subzone = "One Keg", x = 57.2, y = 61, mapID = 379, faction = "neutral", expansion = "mop" },
    { id = 58706, name = "Gina Mudclaw", zone = "Valley of the Four Winds", subzone = "Halfhill", x = 53.2, y = 51.6, mapID = 376, faction = "neutral", expansion = "mop" },
    { id = 64001, name = "Sage Lotusbloom", zone = "Vale of Eternal Blossoms", subzone = "Shrine of Two Moons", x = 62.8, y = 23.2, mapID = 390, faction = "horde", expansion = "mop" },
    { id = 64032, name = "Sage Whiteheart", zone = "Vale of Eternal Blossoms", subzone = "Shrine of Seven Stars", x = 85.2, y = 61.6, mapID = 1530, faction = "alliance", expansion = "mop" },
    { id = 64605, name = "Tan Shin Tiao", zone = "Vale of Eternal Blossoms", subzone = "Mogu'shan Palace", x = 82.23, y = 29.33, mapID = 390, faction = "neutral", expansion = "mop" },
    { id = 62088, name = "Lali the Assistant", zone = "Vale of Eternal Blossoms", subzone = "Mogu'shan Palace", x = 82.8, y = 30.8, mapID = 390, faction = "neutral", expansion = "mop" },
    
    -- =====================================================
    -- WARLORDS OF DRAENOR
    -- =====================================================
    { id = 79812, name = "Moz'def", zone = "Frostwall", x = 48.0, y = 66.0, mapID = 525, faction = "horde", expansion = "wod", notes = "Requires Level 1 Barracks" },
    { id = 76872, name = "Supplymaster Eri", zone = "Frostwall", x = 48.0, y = 66.0, mapID = 525, faction = "horde", expansion = "wod" },
    { id = 79774, name = "Sergeant Grimjaw", zone = "Frostwall", x = 43.8, y = 47.4, mapID = 590, faction = "horde", expansion = "wod" },
    { id = 87015, name = "Kil'rip", zone = "Frostwall", x = 48.0, y = 66.0, mapID = 525, faction = "horde", expansion = "wod", notes = "Requires Level 2 Trading Post" },
    { id = 78564, name = "Sergeant Crowler", zone = "Lunarfall", x = 38.5, y = 31.4, mapID = 582, faction = "alliance", expansion = "wod" },
    { id = 85427, name = "Maaria", zone = "Stormshield", x = 31.0, y = 15.0, mapID = 622, faction = "alliance", expansion = "wod", notes = "Requires Level 2 Trading Post" },
    { id = 85950, name = "Trader Caerel", zone = "Stormshield", x = 41.4, y = 59.8, mapID = 622, faction = "alliance", expansion = "wod" },
    { id = 85932, name = "Vindicator Nuurem", zone = "Stormshield", subzone = "The Town Hall", x = 46.4, y = 74.6, mapID = 622, faction = "alliance", expansion = "wod" },
    { id = 81133, name = "Artificer Kallaes", zone = "Shadowmoon Valley", subzone = "Embaari Village", x = 46.2, y = 39.3, mapID = 539, faction = "alliance", expansion = "wod" },
    { id = 87775, name = "Ruuan the Seer", zone = "Spires of Arak", subzone = "Veil Terokk", x = 46.6, y = 45.0, mapID = 542, faction = "neutral", expansion = "wod" },
    
    -- =====================================================
    -- LEGION
    -- =====================================================
    { id = 127151, name = "Toraan the Revered", zone = "Argus", subzone = "The Vindicaar", x = 68.22, y = 56.91, mapID = 940, faction = "neutral", expansion = "legion" },
    { id = 89939, name = "Berazus", zone = "Azsuna", subzone = "Leyhollow Cave", x = 47.8, y = 23.6, mapID = 630, faction = "neutral", expansion = "legion" },
    { id = 112716, name = "Rasil Fireborne", zone = "Dalaran", subzone = "Photonic Playground", x = 43.4, y = 49.4, mapID = 627, faction = "neutral", expansion = "legion" },
    { id = 252043, name = "Halenthos Brightstride", zone = "Dalaran", subzone = "Sunreaver Sanctuary", x = 67.46, y = 33.89, mapID = 627, faction = "horde", expansion = "legion" },
    { id = 105333, name = "Val'zuun", zone = "Dalaran", subzone = "The Underbelly", x = 67.36, y = 63.22, mapID = 628, faction = "neutral", expansion = "legion" },
    { id = 106902, name = "Ransa Greyfeather", zone = "Highmountain", subzone = "Thunder Totem", x = 38.06, y = 46.05, mapID = 750, faction = "neutral", expansion = "legion" },
    { id = 108017, name = "Torv Dubstomp", zone = "Highmountain", subzone = "Thunder Totem Lower", x = 54.80, y = 78.08, mapID = 652, faction = "neutral", expansion = "legion" },
    { id = 108537, name = "Crafty Palu", zone = "Highmountain", subzone = "Shipwreck Cove", x = 41.62, y = 10.44, mapID = 650, faction = "neutral", expansion = "legion" },
    { id = 115736, name = "First Arcanist Thalyssra", zone = "Suramar", subzone = "Shal'Aran", x = 36.49, y = 45.83, mapID = 680, faction = "neutral", expansion = "legion" },
    { id = 93971, name = "Leyweaver Inondra", zone = "Suramar", subzone = "The Grand Promenade", x = 40.32, y = 69.73, mapID = 680, faction = "neutral", expansion = "legion" },
    { id = 252969, name = "Jocenna", zone = "Suramar", subzone = "Concourse of Destiny", x = 49.63, y = 62.83, mapID = 680, faction = "neutral", expansion = "legion" },
    { id = 253387, name = "Selfira Ambergrove", zone = "Val'sharah", subzone = "Lorlathil", x = 54.26, y = 72.36, mapID = 641, faction = "neutral", expansion = "legion" },
    { id = 106901, name = "Sylvia Hartshorn", zone = "Val'sharah", subzone = "Lorlathil", x = 54.7, y = 73.25, mapID = 641, faction = "neutral", expansion = "legion" },
    { id = 252498, name = "Corbin Branbell", zone = "Val'sharah", subzone = "Bradensbrook", x = 42.09, y = 59.38, mapID = 641, faction = "neutral", expansion = "legion" },
    { id = 109306, name = "Myria Glenbrook", zone = "Val'sharah", subzone = "Lightsong", x = 60.2, y = 84.86, mapID = 641, faction = "neutral", expansion = "legion" },
    
    -- Order Halls
    { id = 93550, name = "Quartermaster Ozorg", zone = "Acherus", notes = "Death Knight Order Hall", expansion = "legion" },
    { id = 112407, name = "Falara Nightsong", zone = "Fel Hammer", notes = "Demon Hunter Order Hall", expansion = "legion" },
    { id = 100196, name = "Eadric the Pure", zone = "Sanctum of Light", notes = "Paladin Order Hall", expansion = "legion" },
    { id = 103693, name = "Outfitter Reynolds", zone = "Trueshot Lodge", notes = "Hunter Order Hall", expansion = "legion" },
    { id = 112323, name = "Amurra Thistledew", zone = "The Dreamgrove", notes = "Druid Order Hall", expansion = "legion" },
    { id = 105986, name = "Kelsey Steelspark", zone = "Hall of Shadows", notes = "Rogue Order Hall", expansion = "legion" },
    { id = 112338, name = "Caydori Brightstar", zone = "Temple of the Five Dawns", notes = "Monk Order Hall", expansion = "legion" },
    { id = 112434, name = "Gigi Gigavoid", zone = "Dreadscar Rift", notes = "Warlock Order Hall", expansion = "legion" },
    { id = 112440, name = "Jackson Watkins", zone = "Hall of the Guardian", notes = "Mage Order Hall", expansion = "legion" },
    { id = 112318, name = "Flamesmith Lanying", zone = "The Maelstrom", notes = "Shaman Order Hall", expansion = "legion" },
    { id = 112392, name = "Quartermaster Durnolf", zone = "Skyhold", notes = "Warrior Order Hall", expansion = "legion" },
    { id = 112401, name = "Meridelle Lightspark", zone = "Netherlight Temple", notes = "Priest Order Hall", expansion = "legion" },
    
    -- =====================================================
    -- BATTLE FOR AZEROTH
    -- =====================================================
    { id = 152194, name = "MOTHER", zone = "Silithus", subzone = "Chamber of Heart", x = 48.3, y = 72.1, mapID = 1473, faction = "neutral", expansion = "bfa" },
    { id = 252313, name = "Caspian", zone = "Stormsong Valley", subzone = "Brennadom", x = 59.6, y = 69.6, mapID = 942, faction = "alliance", expansion = "bfa" },
    { id = 150716, name = "Stolen Royal Vendorbot", zone = "Mechagon", subzone = "Rustbolt", x = 73.7, y = 36.91, mapID = 1462, faction = "neutral", expansion = "bfa" },
    { id = 135808, name = "Provisioner Fray", zone = "Tiragarde Sound", subzone = "Harbormaster's Office", x = 67.6, y = 21.8, mapID = 1161, faction = "alliance", expansion = "bfa" },
    { id = 252345, name = "Pearl Barlow", zone = "Tiragarde Sound", subzone = "Boralus Harbor", x = 70.74, y = 15.66, mapID = 1161, faction = "alliance", expansion = "bfa" },
    { id = 246721, name = "Janey Forrest", zone = "Tiragarde Sound", subzone = "Hook Point", x = 56.29, y = 45.82, mapID = 1161, faction = "alliance", expansion = "bfa" },
    { id = 135459, name = "Provisioner Lija", zone = "Nazmir", subzone = "Zul'jan Ruins", x = 39.11, y = 79.47, mapID = 863, faction = "horde", expansion = "bfa" },
    { id = 148924, name = "Provisioner Mukra", zone = "Zuldazar", subzone = "Port of Zandalar", x = 51.22, y = 95.08, mapID = 1165, faction = "horde", expansion = "bfa" },
    { id = 251921, name = "Arcanist Peroleth", zone = "Zuldazar", subzone = "Port of Zandalar", x = 58.0, y = 62.6, mapID = 862, faction = "horde", expansion = "bfa" },
    { id = 252326, name = "T'lama", zone = "Dazar'alor", subzone = "The Great Seal", x = 36.94, y = 59.17, mapID = 1164, faction = "horde", expansion = "bfa" },
    
    -- =====================================================
    -- SHADOWLANDS
    -- =====================================================
    { id = 174710, name = "Chachi the Artiste", zone = "Revendreth", subzone = "Sinfall", x = 54.0, y = 24.8, mapID = 1699, faction = "neutral", expansion = "sl", notes = "Venthyr covenant only" },
    { id = 162804, name = "Ve'nari", zone = "The Maw", subzone = "Ve'nari's Refuge", x = 46.8, y = 41.6, mapID = 1543, faction = "neutral", expansion = "sl" },
    
    -- =====================================================
    -- DRAGONFLIGHT
    -- =====================================================
    { id = 253086, name = "Jolinth", zone = "The Forbidden Reach", subzone = "Morqut Village", x = 35.2, y = 57.0, mapID = 2151, faction = "neutral", expansion = "df" },
    { id = 193015, name = "Unatos", zone = "Valdrakken", subzone = "The Seat of Aspects", x = 58.2, y = 35.6, mapID = 2112, faction = "neutral", expansion = "df" },
    { id = 253067, name = "Silvrath", zone = "Valdrakken", subzone = "The Parting Glass", x = 71.53, y = 49.62, mapID = 2112, faction = "neutral", expansion = "df" },
    { id = 199605, name = "Evantkis", zone = "Valdrakken", subzone = "Treasury", x = 58.4, y = 57.4, mapID = 2112, faction = "neutral", expansion = "df" },
    { id = 193659, name = "Provisioner Thom", zone = "Valdrakken", subzone = "The Obsidian Enclave", x = 36.8, y = 50.6, mapID = 2112, faction = "neutral", expansion = "df" },
    { id = 196637, name = "Tethalash", zone = "Valdrakken", x = 25.52, y = 33.65, mapID = 2112, faction = "neutral", expansion = "df", notes = "Evoker only" },
    { id = 209192, name = "Provisioner Aristta", zone = "Thaldraszus", subzone = "Azerothian Archives", x = 61.4, y = 31.4, mapID = 2025, faction = "neutral", expansion = "df" },
    { id = 209220, name = "Ironus Coldsteel", zone = "Thaldraszus", subzone = "Eon's Fringe", x = 52.2, y = 80.8, mapID = 2025, faction = "neutral", expansion = "df" },
    { id = 189226, name = "Cataloger Jakes", zone = "The Waking Shores", subzone = "Dragonscale Basecamp", x = 47.0, y = 82.6, mapID = 2022, faction = "neutral", expansion = "df" },
    { id = 188265, name = "Rae'ana", zone = "The Waking Shores", subzone = "Dragonscale Basecamp", x = 47.8, y = 82.2, mapID = 2022, faction = "neutral", expansion = "df" },
    { id = 191025, name = "Lifecaller Tzadrak", zone = "The Waking Shores", subzone = "Ruby Lifeshrine", x = 62.0, y = 73.8, mapID = 2022, faction = "neutral", expansion = "df" },
    { id = 216286, name = "Moon Priestess Lasara", zone = "Amirdrassil", subzone = "Bel'ameth", x = 46.6, y = 70.6, mapID = 2239, faction = "alliance", expansion = "df" },
    { id = 216284, name = "Mythrin'dir", zone = "Amirdrassil", subzone = "Bel'ameth", x = 54.0, y = 60.8, mapID = 2239, faction = "alliance", expansion = "df" },
    { id = 216285, name = "Ellandrieth", zone = "Amirdrassil", subzone = "Bel'ameth", x = 48.4, y = 53.6, mapID = 2239, faction = "neutral", expansion = "df" },
    
    -- =====================================================
    -- THE WAR WITHIN
    -- =====================================================
    { id = 223728, name = "Auditor Balwurz", zone = "Dornogal", subzone = "Foundation Hall", x = 39.2, y = 24.4, mapID = 2339, faction = "neutral", expansion = "tww" },
    { id = 219318, name = "Jorid", zone = "Dornogal", subzone = "The Forgegrounds", x = 57.0, y = 60.6, mapID = 2339, faction = "neutral", expansion = "tww" },
    { id = 252910, name = "Garnett", zone = "Dornogal", subzone = "The Forgegrounds", x = 54.68, y = 57.24, mapID = 2339, faction = "neutral", expansion = "tww" },
    { id = 252312, name = "Second Chair Pawdo", zone = "Dornogal", x = 52.84, y = 68.0, mapID = 2339, faction = "neutral", expansion = "tww" },
    { id = 219217, name = "Velerd", zone = "Dornogal", x = 55.2, y = 76.4, mapID = 2339, faction = "neutral", expansion = "tww" },
    { id = 252901, name = "Cinnabar", zone = "Isle of Dorn", subzone = "Freywold Village", x = 42.0, y = 73.0, mapID = 2248, faction = "neutral", expansion = "tww" },
    { id = 226205, name = "Cendvin", zone = "Isle of Dorn", subzone = "Cinderbrew Meadery", x = 74.4, y = 45.2, mapID = 2248, faction = "neutral", expansion = "tww" },
    { id = 221390, name = "Waxmonger Squick", zone = "The Ringing Deeps", subzone = "Gundargaz", x = 43.2, y = 32.8, mapID = 2214, faction = "neutral", expansion = "tww" },
    { id = 252887, name = "Chert", zone = "The Ringing Deeps", subzone = "Gundargaz", x = 43.4, y = 33.0, mapID = 2214, faction = "neutral", expansion = "tww" },
    { id = 217642, name = "Nalina Ironsong", zone = "Hallowfall", subzone = "Mereldar", x = 42.8, y = 55.83, mapID = 2215, faction = "neutral", expansion = "tww" },
    { id = 240852, name = "Lars Bronsmaelt", zone = "Hallowfall", subzone = "Morgaen's Tears", x = 28.28, y = 56.18, mapID = 2215, faction = "neutral", expansion = "tww" },
    { id = 218202, name = "Thripps", zone = "Azj-Kahet", subzone = "City of Threads", x = 50.0, y = 31.6, mapID = 2213, faction = "neutral", expansion = "tww" },
    { id = 251911, name = "Stacks Topskimmer", zone = "Undermine", subzone = "The Incontinental Hotel", x = 43.19, y = 50.47, mapID = 2346, faction = "neutral", expansion = "tww" },
    { id = 231409, name = "Smaks Topskimmer", zone = "Undermine", subzone = "The Incontinental Hotel", x = 43.8, y = 50.8, mapID = 2346, faction = "neutral", expansion = "tww" },
    { id = 231406, name = "Rocco Razzboom", zone = "Undermine", subzone = "The Scrapshop", x = 39.16, y = 22.2, mapID = 2346, faction = "neutral", expansion = "tww" },
    { id = 231405, name = "Boatswain Hardee", zone = "Undermine", subzone = "Port Authority", x = 63.43, y = 16.8, mapID = 2346, faction = "neutral", expansion = "tww" },
    { id = 231408, name = "Lab Assistant Laszly", zone = "Undermine", subzone = "The Vatworks", x = 27.18, y = 72.54, mapID = 2346, faction = "neutral", expansion = "tww" },
    { id = 231407, name = "Shredz the Scrapper", zone = "Undermine", subzone = "Venture Plaza", x = 53.34, y = 72.69, mapID = 2346, faction = "neutral", expansion = "tww" },
    { id = 231396, name = "Sitch Lowdown", zone = "Undermine", subzone = "Hovel Hill", x = 30.78, y = 38.93, mapID = 2346, faction = "neutral", expansion = "tww" },
    { id = 235621, name = "Ando the Gat", zone = "Liberation of Undermine", x = 43.29, y = 51.89, mapID = 2406, faction = "neutral", expansion = "tww" },
    { id = 235314, name = "Ta'sam", zone = "Tazavesh", x = 43.2, y = 34.8, mapID = 2472, faction = "neutral", expansion = "tww" },
    { id = 235252, name = "Om'sirik", zone = "Tazavesh", subzone = "Tazarest", x = 40.33, y = 29.36, mapID = 2472, faction = "neutral", expansion = "tww" },
    
    -- =====================================================
    -- MIDNIGHT
    -- =====================================================
    { id = 252915, name = "Corlen Hordralin", zone = "Silvermoon City", subzone = "The Bazaar", x = 44.16, y = 62.72, mapID = 2393, faction = "neutral", expansion = "midnight" },
    { id = 256828, name = "Dennia Silvertongue", zone = "Silvermoon City", subzone = "Murder Row", x = 51.16, y = 56.47, mapID = 2393, faction = "neutral", expansion = "midnight" },
    { id = 249196, name = "Materialist Ophinell", zone = "Twilight Highlands", x = 49.6, y = 81.2, mapID = 241, faction = "neutral", expansion = "midnight" },

    -- =====================================================
    -- DECORVENDOR MERGED (ADDITIONAL VENDORS)
    -- =====================================================
    { id = 142115, name = "Fiona", zone = "Boralus Harbor", x = 67.6, y = 40.8, mapID = 1161, faction = "alliance", expansion = "bfa", model3D = 34450, notes = "DecorVendor: Boralus Harbor" },
    { id = 252316, name = "Delphine", zone = "Norwington Estate", x = 53.4, y = 31.2, mapID = 895, faction = "neutral", expansion = "bfa", model3D = 137394, notes = "DecorVendor: Norwington Estate" },
    { id = 148923, name = "Captain Zen'taga", zone = "Port of Zandalar", x = 44.6, y = 94.4, mapID = 1165, faction = "horde", expansion = "bfa", model3D = 90162, notes = "DecorVendor: Port of Zandalar" },
    { id = 49386, name = "Craw MacGraw", zone = "Thundermar", x = 48.6, y = 30.6, mapID = 241, faction = "alliance", expansion = "cata", model3D = 36453, notes = "DecorVendor: Thundermar" },
    { id = 144129, name = "Plugger Spazzring", zone = "Dark Iron Dwarf Only", x = 49.77, y = 32.22, mapID = 1186, faction = "neutral", expansion = "classic", model3D = 8652, notes = "Race Locked - Dark Iron Dwarf Only" },
    { id = 50304, name = "Captain Donald Adams", zone = "PRE-DESTRUCTION", x = 63.2, y = 49.0, mapID = 90, faction = "horde", expansion = "classic", model3D = 37023, notes = "DecorVendor: PRE-DESTRUCTION" },
    { id = 112634, name = "Hilseth Travelstride", zone = "Field of Dreamers (patrols)", x = 57.14, y = 71.91, mapID = 641, faction = "neutral", expansion = "legion", model3D = 72149, notes = "DecorVendor: Field of Dreamers (patrols)" },
    { id = 253434, name = "Sileas Duskvine", zone = "Irongrove Retreat", x = 79.92, y = 73.89, mapID = 641, faction = "neutral", expansion = "legion", model3D = 137851, notes = "DecorVendor: Irongrove Retreat" },
    { id = 255101, name = "Mynde", zone = "Shimmershade Garden", x = 45.58, y = 69.15, mapID = 680, faction = "neutral", expansion = "legion", model3D = 138645, notes = "DecorVendor: Shimmershade Garden" },
    { id = 256826, name = "Mrgrgrl", zone = "Val'sharah", x = 68.72, y = 95.1, mapID = 641, faction = "neutral", expansion = "legion", model3D = 139842, notes = "DecorVendor: Val'sharah" },
    { id = 248594, name = "Sundries Merchant", zone = "suramar", x = 50.9, y = 77.78, mapID = 680, faction = "neutral", expansion = "legion", model3D = 73413, notes = "DecorVendor: suramar" },
    { id = 255218, name = "Argan Hammerfist", zone = "Founders Point", x = 52.2, y = 37.8, mapID = 2352, faction = "alliance", expansion = "the neighborhoods", model3D = 138689, notes = "DecorVendor: Founders Point" },
    { id = 255216, name = "Balen Starfinder", zone = "Founders Point", x = 52.2, y = 38.0, mapID = 2352, faction = "alliance", expansion = "the neighborhoods", model3D = 138688, notes = "DecorVendor: Founders Point" },
    { id = 255213, name = "Faarden the Builder", zone = "Founders Point", x = 52.0, y = 38.4, mapID = 2352, faction = "alliance", expansion = "the neighborhoods", model3D = 138687, notes = "DecorVendor: Founders Point" },
    { id = 256750, name = "Klasa", zone = "Founders Point", x = 58.3, y = 61.68, mapID = 2352, faction = "alliance", expansion = "the neighborhoods", model3D = 139782, notes = "DecorVendor: Founders Point" },
    { id = 255221, name = "Trevor Grenner", zone = "Founders Point", x = 53.47, y = 40.93, mapID = 2352, faction = "alliance", expansion = "the neighborhoods", model3D = 138690, notes = "DecorVendor: Founders Point" },
    { id = 255203, name = "Xiao Dan", zone = "Founders Point", x = 51.95, y = 38.31, mapID = 2352, faction = "alliance", expansion = "the neighborhoods", model3D = 138684, notes = "DecorVendor: Founders Point" },
    { id = 255278, name = "Gronthul", zone = "Razorwind Shores", x = 54.12, y = 59.11, mapID = 2351, faction = "horde", expansion = "the neighborhoods", model3D = 138741, notes = "DecorVendor: Razorwind Shores" },
    { id = 255298, name = "Jehzar Starfall", zone = "Razorwind Shores", x = 53.56, y = 58.49, mapID = 2351, faction = "horde", expansion = "the neighborhoods", model3D = 138752, notes = "DecorVendor: Razorwind Shores" },
    { id = 255299, name = "Lefton Farrer", zone = "Razorwind Shores", x = 53.48, y = 58.53, mapID = 2351, faction = "horde", expansion = "the neighborhoods", model3D = 138753, notes = "DecorVendor: Razorwind Shores" },
    { id = 240465, name = "Lonomia", zone = "Razorwind Shores", x = 68.29, y = 75.5, mapID = 2351, faction = "horde", expansion = "the neighborhoods", model3D = 127583, notes = "DecorVendor: Razorwind Shores" },
    { id = 255297, name = "Shon'ja", zone = "Razorwind Shores", x = 54.13, y = 59.05, mapID = 2351, faction = "horde", expansion = "the neighborhoods", model3D = 138751, notes = "DecorVendor: Razorwind Shores" },
    { id = 226994, name = "Blair Bass", zone = "Undermine", x = 34.0, y = 70.8, mapID = 2346, faction = "neutral", expansion = "tww", model3D = 127681, notes = "DecorVendor: Undermine" },
    { id = 239333, name = "Street Food Vendor", zone = "Undermine", x = 26.2, y = 42.8, mapID = 2346, faction = "neutral", expansion = "tww", model3D = 127373, notes = "DecorVendor: Undermine" },
    { id = 86779, name = "Krixel Pinchwhistle", zone = "Alliance Garrison", x = 31.0, y = 15.0, mapID = 539, faction = "alliance", expansion = "wod", model3D = 56410, notes = "DecorVendor: Alliance Garrison" },
    { id = 88220, name = "Peter", zone = "Alliance Garrison", x = 31.0, y = 15.0, mapID = 539, faction = "alliance", expansion = "wod", model3D = 60816, notes = "DecorVendor: Alliance Garrison" },
    { id = 87312, name = "Vora Strongarm", zone = "Horde Garrison", x = 48.0, y = 66.0, mapID = 525, faction = "horde", expansion = "wod", model3D = 27957, notes = "DecorVendor: Horde Garrison" },
    { id = 256946, name = "Duskcaller Erthix", zone = "Terokkar Refuge", x = 70.4, y = 57.6, mapID = 535, faction = "neutral", expansion = "wod", model3D = 139888, notes = "DecorVendor: Terokkar Refuge" },
    { id = 86779, name = "Krixel Pinchwhistle", zone = "Trading Post Level 2", x = 31.0, y = 15.0, mapID = 525, faction = "horde", expansion = "wod", model3D = 56410, notes = "DecorVendor: Trading Post Level 2" },

}
