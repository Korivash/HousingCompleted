---------------------------------------------------
-- Housing Completed - AuctionItems.lua
-- Items that can be purchased on the Auction House
-- These are typically crafted by professions and tradeable
---------------------------------------------------
local addonName, HC = ...

-- Auction House items: { name, profession, notes }
-- These are items crafted by professions that can be sold/bought on AH
HC.AuctionItems = {
    -- Tailoring
    { name = "Silken Curtains", profession = "Tailoring", notes = "Crafted" },
    { name = "Elegant Cloth Drapes", profession = "Tailoring", notes = "Crafted" },
    { name = "Embroidered Cushion", profession = "Tailoring", notes = "Crafted" },
    { name = "Linen Tablecloth", profession = "Tailoring", notes = "Crafted" },
    { name = "Silk Canopy", profession = "Tailoring", notes = "Crafted" },
    { name = "Woven Tapestry", profession = "Tailoring", notes = "Crafted" },
    { name = "Decorative Pillow Set", profession = "Tailoring", notes = "Crafted" },
    
    -- Blacksmithing
    { name = "Iron Chandelier", profession = "Blacksmithing", notes = "Crafted" },
    { name = "Ornate Candelabra", profession = "Blacksmithing", notes = "Crafted" },
    { name = "Metal Wall Sconce", profession = "Blacksmithing", notes = "Crafted" },
    { name = "Decorative Iron Gate", profession = "Blacksmithing", notes = "Crafted" },
    { name = "Forge-Crafted Brazier", profession = "Blacksmithing", notes = "Crafted" },
    { name = "Steel Display Rack", profession = "Blacksmithing", notes = "Crafted" },
    
    -- Engineering
    { name = "Mechanical Squirrel Display", profession = "Engineering", notes = "Crafted" },
    { name = "Clockwork Lamp", profession = "Engineering", notes = "Crafted" },
    { name = "Steam-Powered Fan", profession = "Engineering", notes = "Crafted" },
    { name = "Gnomish Weather Machine", profession = "Engineering", notes = "Crafted" },
    { name = "Automated Mail Sorter", profession = "Engineering", notes = "Crafted" },
    
    -- Jewelcrafting
    { name = "Jeweled Music Box", profession = "Jewelcrafting", notes = "Crafted" },
    { name = "Crystal Vase", profession = "Jewelcrafting", notes = "Crafted" },
    { name = "Gemstone Display", profession = "Jewelcrafting", notes = "Crafted" },
    { name = "Ornate Jewelry Box", profession = "Jewelcrafting", notes = "Crafted" },
    
    -- Leatherworking
    { name = "Leather Armchair", profession = "Leatherworking", notes = "Crafted" },
    { name = "Hide Rug", profession = "Leatherworking", notes = "Crafted" },
    { name = "Leather Ottoman", profession = "Leatherworking", notes = "Crafted" },
    { name = "Mounted Trophy Frame", profession = "Leatherworking", notes = "Crafted" },
    
    -- Inscription
    { name = "Illuminated Manuscript", profession = "Inscription", notes = "Crafted" },
    { name = "Calligraphy Scroll", profession = "Inscription", notes = "Crafted" },
    { name = "Book Display Stand", profession = "Inscription", notes = "Crafted" },
    { name = "Painted Banner", profession = "Inscription", notes = "Crafted" },
    
    -- Enchanting
    { name = "Enchanted Lantern", profession = "Enchanting", notes = "Crafted" },
    { name = "Glowing Crystal Ball", profession = "Enchanting", notes = "Crafted" },
    { name = "Mystic Orb", profession = "Enchanting", notes = "Crafted" },
    
    -- Alchemy
    { name = "Bubbling Cauldron", profession = "Alchemy", notes = "Crafted" },
    { name = "Potion Display Rack", profession = "Alchemy", notes = "Crafted" },
    { name = "Alchemist's Workbench", profession = "Alchemy", notes = "Crafted" },
    
    -- Cooking
    { name = "Feast Table", profession = "Cooking", notes = "Crafted" },
    { name = "Spice Rack", profession = "Cooking", notes = "Crafted" },
    { name = "Cooking Pot Display", profession = "Cooking", notes = "Crafted" },
    
    -- World Drops / BoE Items
    { name = "Mysterious Crate", profession = nil, notes = "World Drop" },
    { name = "Ancient Artifact", profession = nil, notes = "World Drop" },
    { name = "Dusty Painting", profession = nil, notes = "World Drop" },
}
