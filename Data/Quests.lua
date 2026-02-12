---------------------------------------------------
-- Housing Completed - Quests.lua
-- Quest reward housing decor
---------------------------------------------------
local addonName, HC = ...

-- Quest reward decor items: { name, questName, vendor, vendorZone, cost, expansion }
HC.QuestItems = {
    -- Classic Quests
    { name = "Hooded Iron Lantern", quest = "Kobold Candles", vendor = "Captain Lancy Revshon", zone = "Stormwind", cost = "120 gold", expansion = "classic" },
    { name = "Northshire Barrel", quest = "Report to Goldshire", vendor = "Captain Lancy Revshon", zone = "Stormwind", cost = "160 gold", expansion = "classic" },
    { name = "Stormwind Arched Trellis", quest = "Ending the Invasion!", vendor = "Captain Lancy Revshon", zone = "Stormwind", cost = "240 gold", expansion = "classic" },
    { name = "Stormwind Wooden Table", quest = "Welcome to Stormwind", vendor = "Captain Lancy Revshon", zone = "Stormwind", cost = "240 gold", expansion = "classic" },
    { name = "City Wanderer's Candleholder", quest = "\"I TAKE Candle!\"", vendor = "Captain Lancy Revshon", zone = "Stormwind", cost = "40 gold", expansion = "classic" },
    { name = "Stormwind Weapon Rack", quest = "The Dawning of a New Day", vendor = "Captain Lancy Revshon", zone = "Stormwind", cost = "80 gold", expansion = "classic" },
    { name = "Westfall Woven Basket", quest = "You Have Our Thanks", vendor = "Captain Lancy Revshon", zone = "Stormwind", cost = "160 gold", expansion = "classic" },
    { name = "Jewelcrafter's Tent", quest = "The Perenolde Tiara", vendor = "Captain Lancy Revshon", zone = "Stormwind", cost = "400 gold", expansion = "classic" },
    { name = "Stormwind Forge", quest = "A Binding Contract", vendor = "Captain Lancy Revshon", zone = "Stormwind", cost = "800 gold", expansion = "classic" },
    
    -- Duskwood Quests
    { name = "Small Gilnean Table", quest = "Morbent's Bane", vendor = "Wilkinson", zone = "Duskwood", cost = "157g 50s", expansion = "classic" },
    { name = "Waning Wood Fence", quest = "Cry For The Moon", vendor = "Wilkinson", zone = "Duskwood", cost = "135 gold", expansion = "classic" },
    
    -- Burning Steppes Quest
    { name = "Shadowforge Lamppost", quest = "Return to Keeshan/Ariok", vendor = "Hoddruc Bladebender", zone = "Burning Steppes", cost = "450 gold", expansion = "classic" },
    
    -- Blasted Lands Quest
    { name = "Surwich Peddler's Wagon", quest = "The Downfall of Marl Wormthorn", vendor = "Maurice Essman", zone = "Blasted Lands", cost = "990 gold", expansion = "classic" },
    
    -- Searing Gorge Quests
    { name = "Shadowforge Grinding Wheel", quest = "Welcome to the Brotherhood", vendor = "Master Smith Burninate", zone = "Searing Gorge", cost = "560 gold", expansion = "classic" },
    { name = "Shadowforge Wooden Box", quest = "The Mountain-Lord's Support", vendor = "Master Smith Burninate", zone = "Searing Gorge", cost = "120 gold", expansion = "classic" },
    
    -- Loch Modan Quest
    { name = "Thelsamar Hanging Lantern", quest = "Axis of Awful", vendor = "Drac Roughcut", zone = "Loch Modan", cost = "240 gold", expansion = "classic" },
    
    -- Tauren Quest
    { name = "Tauren Bluff Rug", quest = "Walk With The Earth Mother", vendor = "Brave Tuho", zone = "Thunder Bluff", cost = "170 gold", expansion = "classic" },
    
    -- Silverpine Quests
    { name = "Lordaeron Fence", quest = "Lordaeron", vendor = "Captain Donald Adams", zone = "Undercity", cost = "142g 50s", expansion = "classic" },
    { name = "Lordaeron Fencepost", quest = "Lordaeron", vendor = "Captain Donald Adams", zone = "Undercity", cost = "95 gold", expansion = "classic" },
    { name = "Stoppered Gilnean Barrel", quest = "Pyrewood's Fall", vendor = "Edwin Harly", zone = "Silverpine Forest", cost = "135 gold", expansion = "classic" },
    
    -- Grizzly Hills Quest
    { name = "Wooden Outhouse", quest = "Doing Your Duty", vendor = "Woodsman Drake", zone = "Grizzly Hills", cost = "425 gold", expansion = "wotlk" },
    
    -- Gilneas Quests
    { name = "Worgen's Chicken Coop", quest = "Last Meal", vendor = "Lord Candren", zone = "Darnassus", cost = "135 gold", expansion = "cata" },
    { name = "Little Wolf's Loo", quest = "Ready to Go", vendor = "Lord Candren", zone = "Darnassus", cost = "405 gold", expansion = "cata" },
    
    -- Twilight Highlands Quests
    { name = "Dilapidated Wildhammer Well", quest = "Eye Spy", vendor = "Breana Bitterbrand", zone = "Twilight Highlands", cost = "1,000 gold", expansion = "cata" },
    { name = "Overgrown Wildhammer Fountain", quest = "Wild, Wild, Wildhammer Wedding", vendor = "Breana Bitterbrand", zone = "Twilight Highlands", cost = "1,500 gold", expansion = "cata" },
    
    -- MoP Quests
    { name = "Kun-Lai Lacquered Rickshaw", quest = "The Leader Hozen", vendor = "Brother Furtrim", zone = "Kun-Lai Summit", cost = "1,000 gold", expansion = "mop" },
    { name = "Shaohao Ceremonial Bell", quest = "Path of the Last Emperor", vendor = "Tan Shin Tiao", zone = "Vale of Eternal Blossoms", cost = "2,000 gold", expansion = "mop" },
    { name = "Golden Pandaren Privacy Screen", quest = "The Jade Serpent", vendor = "Sage Whiteheart/Lotusbloom", zone = "Vale of Eternal Blossoms", cost = "500 gold", expansion = "mop" },
    { name = "Pandaren Stone Lamppost", quest = "Welcome to Dawn's Blossom", vendor = "Sage Whiteheart/Lotusbloom", zone = "Vale of Eternal Blossoms", cost = "300 gold", expansion = "mop" },
    { name = "Wooden Doghouse", quest = "Lost and Lonely", vendor = "Gina Mudclaw", zone = "Valley of the Four Winds", cost = "270 gold", expansion = "mop", notes = "Requires 12,600 Revered with The Tillers" },
    
    -- WoD Quests
    { name = "Frostwolf Bookcase", quest = "Last Steps", vendor = "Sergeant Grimjaw", zone = "Frostwall", cost = "255g + 500 GR", expansion = "wod", faction = "horde" },
    { name = "Frostwolf Round Table", quest = "Establish Your Garrison", vendor = "Sergeant Grimjaw", zone = "Frostwall", cost = "170g + 300 GR", expansion = "wod", faction = "horde" },
    { name = "Architect's Drafting Table", quest = "My Very Own Castle", vendor = "Sergeant Crowler", zone = "Lunarfall", cost = "1,500 GR", expansion = "wod", faction = "alliance" },
    { name = "Emblem of the Naaru's Blessing", quest = "The Prophet's Final Message", vendor = "Trader Caerel", zone = "Stormshield", cost = "2,000 GR", expansion = "wod" },
    { name = "Large Karabor Fountain", quest = "The Defense of Karabor", vendor = "Trader Caerel", zone = "Stormshield", cost = "800g + 2,000 Apexis", expansion = "wod" },
    
    -- Legion Quests
    { name = "Tome of the Lost Dragon", quest = "The Head of the Snake", vendor = "Berazus", zone = "Azsuna", cost = "1,000 OR", expansion = "legion" },
    { name = "Draenic Bookcase", quest = "A Non-Prophet Organization", vendor = "Toraan the Revered", zone = "Argus", cost = "720 gold", expansion = "legion" },
    { name = "Draenic Wooden Wall Shelf", quest = "Bringer of the Light", vendor = "Toraan the Revered", zone = "Argus", cost = "270 gold", expansion = "legion" },
    
    -- Highmountain Quests
    { name = "Dried Whitewash Corn", quest = "The Flow of the River", vendor = "Torv Dubstomp", zone = "Thunder Totem", cost = "270g + 500 OR", expansion = "legion" },
    { name = "Hanging Arrow Kite", quest = "Blood Debt", vendor = "Torv Dubstomp", zone = "Thunder Totem", cost = "270g + 500 OR", expansion = "legion" },
    { name = "Kobold Treasure Pile", quest = "Can't Hold a Candle To You", vendor = "Torv Dubstomp", zone = "Thunder Totem", cost = "90g + 200 OR", expansion = "legion" },
    { name = "Large Highmountain Drum", quest = "Ceremonial Drums", vendor = "Torv Dubstomp", zone = "Thunder Totem", cost = "270g + 500 OR", expansion = "legion" },
    { name = "Skyhorn Banner", quest = "The Skies of Highmountain", vendor = "Torv Dubstomp", zone = "Thunder Totem", cost = "630g + 1,000 OR", expansion = "legion" },
    { name = "Tauren Vertical Windmill", quest = "The Underking", vendor = "Torv Dubstomp", zone = "Thunder Totem", cost = "630g + 1,000 OR", expansion = "legion" },
    
    -- Suramar Quests
    { name = "Covered Ornate Suramar Table", quest = "And They Will Tremble", vendor = "Jocenna", zone = "Suramar", cost = "400 OR", expansion = "legion" },
    { name = "Elaborate Suramar Window", quest = "Visitor in Shal'Aran", vendor = "Jocenna", zone = "Suramar", cost = "225 OR", expansion = "legion" },
    { name = "Nightborne Merchant's Stall", quest = "Sign of the Dusk Lily", vendor = "Jocenna", zone = "Suramar", cost = "600 OR", expansion = "legion" },
    
    -- Val'sharah Quests
    { name = "Bradensbrook Smoke Lantern", quest = "Shriek No More", vendor = "Corbin Branbell", zone = "Val'sharah", cost = "350 OR", expansion = "legion" },
    { name = "Bradensbrook Thorned Well", quest = "Source of the Corruption", vendor = "Corbin Branbell", zone = "Val'sharah", cost = "1,000 OR", expansion = "legion" },
    { name = "Crescent Moon Lamppost", quest = "The Tears of Elune", vendor = "Selfira Ambergrove", zone = "Val'sharah", cost = "600 OR", expansion = "legion" },
    
    -- BfA Quests
    { name = "Admiral's Bed", quest = "Allegiance of Kul Tiras", vendor = "Pearl Barlow", zone = "Boralus", cost = "550 War Resources", expansion = "bfa" },
    { name = "Seaworthy Boralus Bell", quest = "My Brother's Keeper", vendor = "Pearl Barlow", zone = "Boralus", cost = "800 War Resources", expansion = "bfa" },
    { name = "Tiragarde Emblem", quest = "War Marches On", vendor = "Pearl Barlow", zone = "Boralus", cost = "500 War Resources", expansion = "bfa" },
    { name = "Golden Zandalari Bed", quest = "Of Dark Deeds and Dark Days", vendor = "T'lama", zone = "Dazar'alor", cost = "1,000 War Resources", expansion = "bfa", faction = "horde" },
    { name = "Idol of Rezan", quest = "To Sacrifice a Loa", vendor = "T'lama", zone = "Dazar'alor", cost = "200 War Resources", expansion = "bfa", faction = "horde" },
    
    -- Dragonflight Quests
    { name = "Open Tome of the Dragon's Dedication", quest = "A Last Hope", vendor = "Lifecaller Tzadrak", zone = "The Waking Shores", cost = "500 Dragon Isles Supplies", expansion = "df" },
    { name = "Draconic Memorial Stone", quest = "Archives Return", vendor = "Silvrath", zone = "Valdrakken", cost = "600 Dragon Isles Supplies", expansion = "df" },
    { name = "Valdrakken Lamppost", quest = "Enforced Relaxation", vendor = "Silvrath", zone = "Valdrakken", cost = "200 Dragon Isles Supplies", expansion = "df" },
    { name = "Bel'ameth Traveler's Pack", quest = "The Returning", vendor = "Ellandrieth", zone = "Amirdrassil", cost = "300 Dragon Isles Supplies", expansion = "df" },
    
    -- TWW Quests
    { name = "Fallside Lantern", quest = "The Weight of Duty", vendor = "Garnett", zone = "Dornogal", cost = "450 Resonance Crystals", expansion = "tww" },
    { name = "Stonelight Countertop", quest = "Bad Business", vendor = "Garnett", zone = "Dornogal", cost = "800 Resonance Crystals", expansion = "tww" },
    { name = "Freywold Bench", quest = "Heart of a Hero", vendor = "Cinnabar", zone = "Isle of Dorn", cost = "400 Resonance Crystals", expansion = "tww" },
    { name = "Freywold Fountain", quest = "To Wake a Giant", vendor = "Cinnabar", zone = "Isle of Dorn", cost = "1,100 Resonance Crystals", expansion = "tww" },
    { name = "Coreway Sentinel Lamppost", quest = "On the Road", vendor = "Chert", zone = "The Ringing Deeps", cost = "650 Resonance Crystals", expansion = "tww" },
    { name = "Earthen Etched Throne", quest = "Into the Machine", vendor = "Chert", zone = "The Ringing Deeps", cost = "500 Resonance Crystals", expansion = "tww" },
    { name = "Arathi Bartender's Shelves", quest = "To Kill a Queen", vendor = "Nalina Ironsong", zone = "Hallowfall", cost = "500 Resonance Crystals", expansion = "tww" },
    
    -- Undermine Quests
    { name = "\"Elegant\" Lawn Flamingo", quest = "Ad-Hoc Wedding Planner", vendor = "Stacks Topskimmer", zone = "Undermine", cost = "750 Resonance Crystals", expansion = "tww" },
    { name = "Cartel Head's Schmancy Desk", quest = "Cashing the Check", vendor = "Stacks Topskimmer", zone = "Undermine", cost = "800 Resonance Crystals", expansion = "tww" },
    { name = "Cozy Four-Pipe Bed", quest = "My Hole in the Wall", vendor = "Stacks Topskimmer", zone = "Undermine", cost = "900 Resonance Crystals", expansion = "tww" },
    { name = "Undermine Market Stall", quest = "Unsolicited Feedback", vendor = "Stacks Topskimmer", zone = "Undermine", cost = "1,000 Resonance Crystals", expansion = "tww" },
}
