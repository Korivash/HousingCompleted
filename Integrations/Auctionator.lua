---------------------------------------------------
-- Housing Completed - Integrations/Auctionator.lua
-- Optional Auctionator pricing provider
---------------------------------------------------
local addonName, HC = ...

local CALLER_ID = "HousingCompleted"

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
        dbCallbackRegistered = false,
        generation = 0,
        cacheByItemLink = {},
        cacheByItemID = {},
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
        self.generation = (self.generation or 0) + 1
    end

    function provider:TryEnable()
        self.api = GetAuctionatorAPI()
        self.enabled = self.api ~= nil
        if not self.enabled then
            return false
        end

        if (not self.dbCallbackRegistered) and type(self.api.RegisterForDBUpdate) == "function" then
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

    function provider:GetAuctionPrice(itemLink, itemID)
        if not self:IsEnabled() then
            return nil
        end

        local api = self.api
        if not api then
            return nil
        end

        if type(itemLink) == "string" and itemLink ~= "" then
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

        if type(itemID) == "number" then
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

        return nil
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

    function provider:SendMissingMaterialsToShoppingList(materials, shoppingListName, triggerSearch)
        if not self:IsEnabled() then
            return false, 0, "Auctionator is not available."
        end

        local api = self.api
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
