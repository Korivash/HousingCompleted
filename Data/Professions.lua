---------------------------------------------------
-- Housing Completed - Professions.lua
-- Profession-crafted housing decor
---------------------------------------------------
local addonName, HC = ...

-- Profession crafted items: { name, profession, expansion, skillLevel }
HC.ProfessionItems = {
    -- ALCHEMY
    { name = "Apothecary's Worktable", profession = "Alchemy", expansion = "classic", skill = 240 },
    { name = "Boulder Springs Hot Tub", profession = "Alchemy", expansion = "tww", skill = 75 },
    { name = "Dragon's Elixir Bottle", profession = "Alchemy", expansion = "df", skill = 80 },
    { name = "Verdant Valdrakken Vase", profession = "Alchemy", expansion = "df", skill = 80 },
    
    -- BLACKSMITHING
    { name = "Shadowforge Sconce", profession = "Blacksmithing", expansion = "classic", skill = 240 },
    { name = "Rusting Bolted Bench", profession = "Blacksmithing", expansion = "tww", skill = 75 },
    { name = "Valdrakken Hanging Cauldron", profession = "Blacksmithing", expansion = "df", skill = 80 },
    
    -- COOKING
    { name = "Dornic Mine and Cheese Platter", profession = "Cooking", expansion = "tww", skill = 80 },
    { name = "Bruffalon Rib Platter", profession = "Cooking", expansion = "df", skill = 80 },
    
    -- ENCHANTING
    { name = "Dornogal Hanging Sconce", profession = "Enchanting", expansion = "tww", skill = 80 },
    { name = "Five Flights' Grimoire", profession = "Enchanting", expansion = "df", skill = 80 },
    
    -- ENGINEERING
    { name = "Schmancy Goblin String Lights", profession = "Engineering", expansion = "tww", skill = 80 },
    { name = "Titanic Tyrhold Fountain", profession = "Engineering", expansion = "df", skill = 80 },
    
    -- INSCRIPTION
    { name = "Dornogal Bookcase", profession = "Inscription", expansion = "tww", skill = 80 },
    { name = "Valdrakken Storage Crate", profession = "Inscription", expansion = "df", skill = 80 },
    
    -- JEWELCRAFTING
    { name = "Gundargaz Candelabra", profession = "Jewelcrafting", expansion = "tww", skill = 80 },
    { name = "Valdrakken Gilded Throne", profession = "Jewelcrafting", expansion = "df", skill = 80 },
    
    -- LEATHERWORKING
    { name = "Zhevra-Stripe Rug", profession = "Leatherworking", expansion = "tww", skill = 80 },
    { name = "Valdrakken Market Tent", profession = "Leatherworking", expansion = "df", skill = 80 },
    
    -- TAILORING
    { name = "Undermine Bean Bag Chair", profession = "Tailoring", expansion = "tww", skill = 75 },
    { name = "Tapestry of the Five Flights", profession = "Tailoring", expansion = "df", skill = 80 },
    
    -- TINKERING (Mechagon)
    { name = "Gnomish Fence", profession = "Tinkering", expansion = "bfa", notes = "Junkyard Tinkering" },
    { name = "Mechagon Armory Rack", profession = "Tinkering", expansion = "bfa", notes = "Junkyard Tinkering" },
}
