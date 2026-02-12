---------------------------------------------------
-- Housing Completed - Reputation.lua
-- Reputation-based housing decor
---------------------------------------------------
local addonName, HC = ...

-- Reputation items: { name, faction, standing, vendor, zone, cost, expansion }
HC.ReputationItems = {
    -- Stormwind
    { name = "Elwynn Fence", faction = "Stormwind", standing = "Friendly", vendor = "Captain Lancy Revshon", zone = "Stormwind", cost = "40 gold" },
    { name = "Elwynn Fencepost", faction = "Stormwind", standing = "Friendly", vendor = "Captain Lancy Revshon", zone = "Stormwind", cost = "60 gold" },
    { name = "Stormwind Gazebo", faction = "Stormwind", standing = "Exalted", vendor = "Captain Lancy Revshon", zone = "Stormwind", cost = "200 gold" },
    { name = "Stormwind Lamppost", faction = "Stormwind", standing = "Honored", vendor = "Captain Lancy Revshon", zone = "Stormwind", cost = "80 gold" },
    { name = "Stormwind Peddler's Cart", faction = "Stormwind", standing = "Exalted", vendor = "Captain Lancy Revshon", zone = "Stormwind", cost = "200 gold" },
    
    -- Ironforge
    { name = "Ironforge Fence", faction = "Ironforge", standing = "Friendly", vendor = "Captain Stonehelm", zone = "Ironforge", cost = "120 gold" },
    { name = "Ironforge Fencepost", faction = "Ironforge", standing = "Friendly", vendor = "Captain Stonehelm", zone = "Ironforge", cost = "200 gold" },
    { name = "Ornate Dwarven Wardrobe", faction = "Ironforge", standing = "Revered", vendor = "Captain Stonehelm", zone = "Ironforge", cost = "800 gold" },
    { name = "Ornate Ironforge Bench", faction = "Ironforge", standing = "Honored", vendor = "Captain Stonehelm", zone = "Ironforge", cost = "360 gold" },
    
    -- Gilneas
    { name = "Gilnean Noble's Trellis", faction = "Gilneas", standing = "Revered", vendor = "Lord Candren", zone = "Darnassus", cost = "315 gold" },
    { name = "Gilnean Stone Wall", faction = "Gilneas", standing = "Honored", vendor = "Lord Candren", zone = "Darnassus", cost = "270 gold" },
    
    -- Tranquillien (Blood Elves)
    { name = "Sin'dorei Crafter's Forge", faction = "Tranquillien", standing = "Exalted", vendor = "Provisioner Vredigar", zone = "Ghostlands", cost = "4,750 gold" },
    { name = "Sin'dorei Sleeper", faction = "Tranquillien", standing = "Exalted", vendor = "Provisioner Vredigar", zone = "Ghostlands", cost = "4,750 gold" },
    
    -- Wildhammer Clan
    { name = "Embellished Dwarven Tome", faction = "Wildhammer Clan", standing = "Honored", vendor = "Breana Bitterbrand", zone = "Twilight Highlands", cost = "2,000 gold" },
    { name = "Round Dwarven Table", faction = "Wildhammer Clan", standing = "Friendly", vendor = "Breana Bitterbrand", zone = "Twilight Highlands", cost = "400 gold" },
    
    -- Order of the Cloud Serpent
    { name = "Lucky Hanging Lantern", faction = "Order of the Cloud Serpent", standing = "Honored", vendor = "San Redscale", zone = "The Jade Forest", cost = "475 gold" },
    { name = "Red Crane Kite", faction = "Order of the Cloud Serpent", standing = "Revered", vendor = "San Redscale", zone = "The Jade Forest", cost = "950 gold" },
    
    -- The Lorewalkers
    { name = "Empty Lorewalker's Bookcase", faction = "The Lorewalkers", standing = "Revered", vendor = "Tan Shin Tiao", zone = "Vale of Eternal Blossoms", cost = "1,000 gold" },
    { name = "Pandaren Cradle Stool", faction = "The Lorewalkers", standing = "Friendly", vendor = "Tan Shin Tiao", zone = "Vale of Eternal Blossoms", cost = "300 gold" },
    { name = "Pandaren Scholar's Bookcase", faction = "The Lorewalkers", standing = "Revered", vendor = "Tan Shin Tiao", zone = "Vale of Eternal Blossoms", cost = "2,000 gold" },
    
    -- Council of Exarchs
    { name = "\"Dawning Hope\" Mosaic", faction = "Council of Exarchs", standing = "Revered", vendor = "Vindicator Nuurem", zone = "Stormshield", cost = "1,000 GR" },
    { name = "Draenethyst Lantern", faction = "Council of Exarchs", standing = "Friendly", vendor = "Vindicator Nuurem", zone = "Stormshield", cost = "250 GR" },
    { name = "Grand Draenethyst Lamp", faction = "Council of Exarchs", standing = "Exalted", vendor = "Vindicator Nuurem", zone = "Stormshield", cost = "1,500 GR" },
    
    -- Highmountain Tribe
    { name = "Highmountain Totem", faction = "Highmountain Tribe", standing = "Exalted", vendor = "Ransa Greyfeather", zone = "Thunder Totem", cost = "900g + 2,000 OR" },
    { name = "Riverbend Jar", faction = "Highmountain Tribe", standing = "Friendly", vendor = "Ransa Greyfeather", zone = "Thunder Totem", cost = "270g + 500 OR" },
    { name = "Tauren Waterwheel", faction = "Highmountain Tribe", standing = "Exalted", vendor = "Ransa Greyfeather", zone = "Thunder Totem", cost = "900g + 2,000 OR" },
    
    -- The Nightfallen
    { name = "\"Fruit of the Arcan'dor\" Painting", faction = "The Nightfallen", standing = "Exalted", vendor = "First Arcanist Thalyssra", zone = "Suramar", cost = "800g + 2,000 OR" },
    { name = "Arcwine Counter", faction = "The Nightfallen", standing = "Revered", vendor = "First Arcanist Thalyssra", zone = "Suramar", cost = "560g + 1,000 OR" },
    { name = "Nightborne Fireplace", faction = "The Nightfallen", standing = "Exalted", vendor = "First Arcanist Thalyssra", zone = "Suramar", cost = "560g + 1,000 OR" },
    { name = "Suramar Library", faction = "The Nightfallen", standing = "Honored", vendor = "First Arcanist Thalyssra", zone = "Suramar", cost = "400g + 750 OR" },
    { name = "Suramar Street Light", faction = "The Nightfallen", standing = "Revered", vendor = "First Arcanist Thalyssra", zone = "Suramar", cost = "560g + 1,000 OR" },
    
    -- Dreamweavers
    { name = "Cenarion Privacy Screen", faction = "Dreamweavers", standing = "Exalted", vendor = "Selfira Ambergrove", zone = "Val'sharah", cost = "1,000g + 2,000 OR" },
    { name = "Cenarion Rectangular Rug", faction = "Dreamweavers", standing = "Honored", vendor = "Selfira Ambergrove", zone = "Val'sharah", cost = "500g + 750 OR" },
    { name = "Kaldorei Washbasin", faction = "Dreamweavers", standing = "Revered", vendor = "Selfira Ambergrove", zone = "Val'sharah", cost = "700g + 1,000 OR" },
    
    -- Proudmoore Admiralty
    { name = "Boralus Fence", faction = "Proudmoore Admiralty", standing = "Friendly", vendor = "Provisioner Fray", zone = "Tiragarde Sound", cost = "100 WR" },
    { name = "Boralus Fencepost", faction = "Proudmoore Admiralty", standing = "Friendly", vendor = "Provisioner Fray", zone = "Tiragarde Sound", cost = "50 WR" },
    { name = "Boralus String Lights", faction = "Proudmoore Admiralty", standing = "Honored", vendor = "Provisioner Fray", zone = "Tiragarde Sound", cost = "75 WR" },
    { name = "Tidesage's Bookcase", faction = "Proudmoore Admiralty", standing = "Revered", vendor = "Provisioner Fray", zone = "Tiragarde Sound", cost = "500 WR" },
    
    -- Storm's Wake
    { name = "Admirality's Copper Lantern", faction = "Storm's Wake", standing = "Friendly", vendor = "Caspian", zone = "Stormsong Valley", cost = "125 WR" },
    { name = "Bowhull Bookcase", faction = "Storm's Wake", standing = "Revered", vendor = "Caspian", zone = "Stormsong Valley", cost = "550 WR" },
    { name = "Copper Stormsong Well", faction = "Storm's Wake", standing = "Revered", vendor = "Caspian", zone = "Stormsong Valley", cost = "800 WR" },
    
    -- Zandalari Empire
    { name = "Blue Dazar'alor Rug", faction = "Zandalari Empire", standing = "Honored", vendor = "T'lama", zone = "Dazar'alor", cost = "150 WR" },
    { name = "Stone Zandalari Lamp", faction = "Zandalari Empire", standing = "Friendly", vendor = "T'lama", zone = "Dazar'alor", cost = "100 WR" },
    { name = "Zandalari War Brazier", faction = "Zandalari Empire", standing = "Revered", vendor = "T'lama", zone = "Dazar'alor", cost = "300 WR" },
    { name = "Zandalari Weapon Rack", faction = "Zandalari Empire", standing = "Honored", vendor = "T'lama", zone = "Dazar'alor", cost = "300 WR" },
    
    -- Talanji's Expedition
    { name = "Dazar'alor Market Tent", faction = "Talanji's Expedition", standing = "Revered", vendor = "Provisioner Lija", zone = "Nazmir", cost = "400 WR" },
    { name = "Zandalari Sconce", faction = "Talanji's Expedition", standing = "Honored", vendor = "Provisioner Lija", zone = "Nazmir", cost = "150 WR" },
    { name = "Zandalari War Torch", faction = "Talanji's Expedition", standing = "Honored", vendor = "Provisioner Lija", zone = "Nazmir", cost = "150 WR" },
    
    -- Rustbolt Resistance
    { name = "Automated Gnomeregan Guardian", faction = "Rustbolt Resistance", standing = "Exalted", vendor = "Stolen Royal Vendorbot", zone = "Mechagon", cost = "1,000g + materials" },
    { name = "Emergency Warning Lamp", faction = "Rustbolt Resistance", standing = "Honored", vendor = "Stolen Royal Vendorbot", zone = "Mechagon", cost = "100g + 1 Energy Cell" },
    { name = "Gnomish Safety Flamethrower", faction = "Rustbolt Resistance", standing = "Exalted", vendor = "Stolen Royal Vendorbot", zone = "Mechagon", cost = "200g + materials" },
    
    -- Dragonscale Expedition
    { name = "Blood Elven Candelabra", faction = "Dragonscale Expedition", standing = "Renown 16", vendor = "Rae'ana", zone = "The Waking Shores", cost = "400 DIS" },
    { name = "Circular Sin'dorei Rug", faction = "Dragonscale Expedition", standing = "Renown 10", vendor = "Rae'ana", zone = "The Waking Shores", cost = "250 DIS" },
    { name = "Reliquary Telescope", faction = "Dragonscale Expedition", standing = "Renown 24", vendor = "Rae'ana", zone = "The Waking Shores", cost = "750 DIS" },
    
    -- Valdrakken Accord
    { name = "Draconic Stone Table", faction = "Valdrakken Accord", standing = "Renown 14", vendor = "Unatos", zone = "Valdrakken", cost = "300 DIS" },
    { name = "Dragon's Grand Mirror", faction = "Valdrakken Accord", standing = "Renown 20", vendor = "Unatos", zone = "Valdrakken", cost = "250 DIS" },
    { name = "Valdrakken Garden Fountain", faction = "Valdrakken Accord", standing = "Renown 6", vendor = "Unatos", zone = "Valdrakken", cost = "400 DIS" },
    { name = "Valdrakken Oven", faction = "Valdrakken Accord", standing = "Renown 3", vendor = "Unatos", zone = "Valdrakken", cost = "500 DIS" },
    
    -- Flame's Radiance
    { name = "Collection of Arathi Scripture", faction = "Flame's Radiance", standing = "Renown 8", vendor = "Lars Bronsmaelt", zone = "Hallowfall", cost = "1,200 Resonance Crystals" },
    
    -- Undermine Cartels
    { name = "Incontinental Table Lamp", faction = "Bilgewater Cartel", standing = "Honored", vendor = "Rocco Razzboom", zone = "Undermine", cost = "450 Resonance Crystals" },
    { name = "Spring-Powered Undermine Chair", faction = "Bilgewater Cartel", standing = "Honored", vendor = "Rocco Razzboom", zone = "Undermine", cost = "450 Resonance Crystals" },
    { name = "Relaxing Goblin Beach Chair", faction = "Blackwater Cartel", standing = "Revered", vendor = "Boatswain Hardee", zone = "Undermine", cost = "900 Resonance Crystals" },
    { name = "Undermine Alleyway Sconce", faction = "Blackwater Cartel", standing = "Honored", vendor = "Boatswain Hardee", zone = "Undermine", cost = "475 Resonance Crystals" },
    { name = "Undermine Bookcase", faction = "Darkfuse Solutions", standing = "Honored", vendor = "Sitch Lowdown", zone = "Undermine", cost = "800 Resonance Crystals" },
    { name = "Undermine Mechanic's Hanging Lamp", faction = "Steamwheedle Cartel", standing = "Honored", vendor = "Lab Assistant Laszly", zone = "Undermine", cost = "500 Resonance Crystals" },
    { name = "Spring-Powered Pointer", faction = "Venture Company", standing = "Revered", vendor = "Shredz the Scrapper", zone = "Undermine", cost = "650 Resonance Crystals" },
    
    -- K'aresh Trust
    { name = "Deactivated K'areshi Warp Cannon", faction = "K'aresh Trust", standing = "Renown 19", vendor = "Om'sirik", zone = "Tazavesh", cost = "2,000 Resonance Crystals" },
    { name = "K'areshi Protectorate Portal", faction = "K'aresh Trust", standing = "Renown 19", vendor = "Om'sirik", zone = "Tazavesh", cost = "1,000 Resonance Crystals" },
    { name = "Ethereal Pipe Segment", faction = "K'aresh Trust", standing = "Renown 15", vendor = "Om'sirik", zone = "Tazavesh", cost = "800 Resonance Crystals" },
    
    -- Brawler's Guild
    { name = "Brawler's Barricade", faction = "Brawler's Guild", standing = "Rank 2", vendor = "Quackenbush/Paul North", zone = "Brawl'gar/Brawlpub", cost = "500 gold" },
    { name = "Brawler's Guild Punching Bag", faction = "Brawler's Guild", standing = "Rank 5", vendor = "Quackenbush/Paul North", zone = "Brawl'gar/Brawlpub", cost = "8,000 gold" },
    { name = "Champion Brawler's Gloves", faction = "Brawler's Guild", standing = "Rank 7", vendor = "Quackenbush/Paul North", zone = "Brawl'gar/Brawlpub", cost = "500 gold" },
}
