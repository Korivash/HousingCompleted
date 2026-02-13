---------------------------------------------------
-- Housing Completed - Integrations/Auctionator.lua
-- Optional Auctionator pricing provider
---------------------------------------------------
local addonName, HC = ...

local CALLER_ID = "HousingCompleted"
local TSM_CUSTOM_PRICE_AH = "first(dbminbuyout, dbmarket, dbregionmarketavg)"
local TSM_CUSTOM_PRICE_CRAFT = "crafting"

local function WipeTable(t)
    if type(t) == "table" then
        wipe(t)
    end
end

local function GetAuctionatorAPI()
    if not (C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded("Auctionator")) then
        return nil
    end

    local api = Auctionator and Auctionator.API and Auctionator.API.v1
    if type(api) ~= "table" then
        return nil
    end

    if type(api.GetAuctionPriceByItemLink) ~= "function" then
        return nil
    end
    if type(api.GetAuctionPriceByItemID) ~= "function" then
        return nil
    end

    return api
end

local function GetTradeSkillMasterAPI()
    if not (C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded("TradeSkillMaster")) then
        return nil
    end
    local api = _G.TSM_API
    if type(api) ~= "table" then
        return nil
    end
    if type(api.GetCustomPriceValue) ~= "function" then
        return nil
    end
    return api
end

function HC:InitializeAuctionatorPricingProvider()
    if self.PricingProvider and self.PricingProvider._initialized then
        return self.PricingProvider
    end

    local provider = {
        _initialized = true,
        name = "Auctionator",
        callerID = CALLER_ID,
        enabled = false,
        api = nil,
        tsmAPI = nil,
        dbCallbackRegistered = false,
        generation = 0,
        cacheByItemLink = {},
        cacheByItemID = {},
        tsmAuctionCacheByItemString = {},
        tsmCraftCacheByItemString = {},
    }

    function provider:GetGeneration()
        return self.generation or 0
    end

    function provider:IsEnabled()
        return self.enabled and true or false
    end

    function provider:InvalidateCache()
        WipeTable(self.cacheByItemLink)
        WipeTable(self.cacheByItemID)
        WipeTable(self.tsmAuctionCacheByItemString)
        WipeTable(self.tsmCraftCacheByItemString)
        self.generation = (self.generation or 0) + 1
    end

    function provider:TryEnable()
        self.api = GetAuctionatorAPI()
        self.tsmAPI = GetTradeSkillMasterAPI()
        self.enabled = (self.api ~= nil) or (self.tsmAPI ~= nil)
        if not self.enabled then
            return false
        end

        if self.api and (not self.dbCallbackRegistered) and type(self.api.RegisterForDBUpdate) == "function" then
            local ok = pcall(self.api.RegisterForDBUpdate, self.callerID, function()
                self:InvalidateCache()
                if HC and HC.OnPricingDataUpdated then
                    HC:OnPricingDataUpdated("auctionator_db_update")
                end
            end)
            if ok then
                self.dbCallbackRegistered = true
            end
        end

        return true
    end

    function provider:GetTSMItemString(itemLink, itemID)
        local tsm = self.tsmAPI
        if not tsm then
            return nil
        end
        if type(itemID) == "number" then
            return "i:" .. tostring(itemID)
        end
        if type(itemLink) == "string" and itemLink ~= "" and type(tsm.ToItemString) == "function" then
            local ok, itemString = pcall(tsm.ToItemString, itemLink)
            if ok and type(itemString) == "string" and itemString ~= "" then
                return itemString
            end
        end
        return nil
    end

    function provider:GetAuctionPrice(itemLink, itemID)
        if not self:IsEnabled() then
            return nil
        end

        local api = self.api

        if api and type(itemLink) == "string" and itemLink ~= "" then
            local cached = self.cacheByItemLink[itemLink]
            if cached ~= nil then
                return cached or nil
            end

            local ok, price = pcall(api.GetAuctionPriceByItemLink, self.callerID, itemLink)
            if ok and type(price) == "number" and price > 0 then
                self.cacheByItemLink[itemLink] = price
                if type(itemID) == "number" then
                    self.cacheByItemID[itemID] = price
                end
                return price
            end

            self.cacheByItemLink[itemLink] = false
        end

        if api and type(itemID) == "number" then
            local cached = self.cacheByItemID[itemID]
            if cached ~= nil then
                return cached or nil
            end

            local ok, price = pcall(api.GetAuctionPriceByItemID, self.callerID, itemID)
            if ok and type(price) == "number" and price > 0 then
                self.cacheByItemID[itemID] = price
                return price
            end

            self.cacheByItemID[itemID] = false
        end

        local tsm = self.tsmAPI
        if tsm then
            local itemString = self:GetTSMItemString(itemLink, itemID)
            if itemString then
                local cached = self.tsmAuctionCacheByItemString[itemString]
                if cached ~= nil then
                    return cached or nil
                end

                local ok, price = pcall(tsm.GetCustomPriceValue, TSM_CUSTOM_PRICE_AH, itemString)
                if ok and type(price) == "number" and price > 0 then
                    local rounded = math.floor(price + 0.5)
                    self.tsmAuctionCacheByItemString[itemString] = rounded
                    return rounded
                end

                self.tsmAuctionCacheByItemString[itemString] = false
            end
        end

        return nil
    end

    function provider:GetAuctionAge(itemLink, itemID)
        if not self:IsEnabled() then return nil end
        local api = self.api
        if not api then return nil end

        if type(itemLink) == "string" and itemLink ~= "" and type(api.GetAuctionAgeByItemLink) == "function" then
            local ok, age = pcall(api.GetAuctionAgeByItemLink, self.callerID, itemLink)
            if ok and type(age) == "number" and age >= 0 then
                return age
            end
        end
        if type(itemID) == "number" and type(api.GetAuctionAgeByItemID) == "function" then
            local ok, age = pcall(api.GetAuctionAgeByItemID, self.callerID, itemID)
            if ok and type(age) == "number" and age >= 0 then
                return age
            end
        end
        return nil
    end

    function provider:GetAuctionInfo(itemLink, itemID)
        local price = self:GetAuctionPrice(itemLink, itemID)
        if not price then
            return nil
        end
        local age = self:GetAuctionAge(itemLink, itemID)
        return {
            price = price,
            age = age,
        }
    end

    function provider:GetVendorPrice(itemLink, itemID)
        if not self:IsEnabled() then
            return nil
        end

        local api = self.api
        if not api then
            return nil
        end

        if type(itemID) == "number" and type(api.GetVendorPriceByItemID) == "function" then
            local ok, price = pcall(api.GetVendorPriceByItemID, self.callerID, itemID)
            if ok and type(price) == "number" and price > 0 then
                return price
            end
        end

        if type(itemLink) == "string" and itemLink ~= "" and type(api.GetVendorPriceByItemLink) == "function" then
            local ok, price = pcall(api.GetVendorPriceByItemLink, self.callerID, itemLink)
            if ok and type(price) == "number" and price > 0 then
                return price
            end
        end

        return nil
    end

    function provider:GetCraftPrice(itemLink, itemID)
        if not self:IsEnabled() then
            return nil
        end
        local tsm = self.tsmAPI
        if not tsm then
            return nil
        end

        local itemString = self:GetTSMItemString(itemLink, itemID)
        if not itemString then
            return nil
        end

        local cached = self.tsmCraftCacheByItemString[itemString]
        if cached ~= nil then
            return cached or nil
        end

        local ok, value = pcall(tsm.GetCustomPriceValue, TSM_CUSTOM_PRICE_CRAFT, itemString)
        if ok and type(value) == "number" and value > 0 then
            local rounded = math.floor(value + 0.5)
            self.tsmCraftCacheByItemString[itemString] = rounded
            return rounded
        end

        self.tsmCraftCacheByItemString[itemString] = false
        return nil
    end

    function provider:SendMissingMaterialsToShoppingList(materials, shoppingListName, triggerSearch)
        if not self:IsEnabled() then
            return false, 0, "Auctionator is not available."
        end

        local api = self.api
        if type(api) ~= "table" then
            return false, 0, "Auctionator shopping list API not available."
        end
        if type(api.ConvertToSearchString) ~= "function" or type(api.CreateShoppingList) ~= "function" then
            return false, 0, "Auctionator shopping list API not available."
        end

        if type(materials) ~= "table" or #materials == 0 then
            return false, 0, "No missing materials to export."
        end

        local terms = {}
        local names = {}
        for _, mat in ipairs(materials) do
            local itemName = mat.name
            if (not itemName or itemName == "") and type(mat.itemID) == "number" and C_Item and C_Item.GetItemNameByID then
                itemName = C_Item.GetItemNameByID(mat.itemID)
            end
            if itemName and itemName ~= "" then
                local qty = tonumber(mat.quantity) or 1
                table.insert(terms, {
                    searchString = itemName,
                    isExact = true,
                    quantity = math.max(1, math.floor(qty + 0.5)),
                })
                table.insert(names, itemName)
            end
        end

        if #terms == 0 then
            return false, 0, "No named materials could be exported."
        end

        local listName = (type(shoppingListName) == "string" and shoppingListName ~= "") and shoppingListName or "HousingCompleted Missing Mats"
        local existing = {}
        if type(api.GetShoppingListItems) == "function" then
            local okExisting, items = pcall(api.GetShoppingListItems, self.callerID, listName)
            if okExisting and type(items) == "table" then
                for _, s in ipairs(items) do
                    if type(s) == "string" and s ~= "" then
                        existing[s] = true
                    end
                end
            end
        end

        local searchStrings = {}
        for existingSearchString in pairs(existing) do
            table.insert(searchStrings, existingSearchString)
        end
        for _, term in ipairs(terms) do
            local okConvert, searchString = pcall(api.ConvertToSearchString, self.callerID, term)
            if okConvert and type(searchString) == "string" and searchString ~= "" and not existing[searchString] then
                existing[searchString] = true
                table.insert(searchStrings, searchString)
            end
        end

        local okCreate = pcall(api.CreateShoppingList, self.callerID, listName, searchStrings)
        if not okCreate then
            return false, 0, "Failed creating Auctionator shopping list."
        end

        if triggerSearch and type(api.MultiSearchExact) == "function" and AuctionHouseFrame and AuctionHouseFrame:IsShown() then
            pcall(api.MultiSearchExact, self.callerID, names)
        end

        return true, #terms, "Exported missing materials to Auctionator list: " .. listName
    end

    self.PricingProvider = provider
    provider:TryEnable()
    return provider
end

function HC:TryEnableAuctionatorIntegration()
    local provider = self:InitializeAuctionatorPricingProvider()
    local wasEnabled = provider:IsEnabled()
    local isEnabled = provider:TryEnable()
    if isEnabled and not wasEnabled and self.OnPricingDataUpdated then
        self:OnPricingDataUpdated("auctionator_loaded")
    end
    return isEnabled
end

function HC:TryEnableTradeSkillMasterIntegration()
    local provider = self:InitializeAuctionatorPricingProvider()
    local wasEnabled = provider:IsEnabled()
    local isEnabled = provider:TryEnable()
    if isEnabled and not wasEnabled and self.OnPricingDataUpdated then
        self:OnPricingDataUpdated("tsm_loaded")
    end
    return isEnabled
end
