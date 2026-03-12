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

local function GetEconomyDB()
    HousingCompletedDB = HousingCompletedDB or {}
    HousingCompletedDB.economy = HousingCompletedDB.economy or {}
    HousingCompletedDB.economy.directPriceCache = HousingCompletedDB.economy.directPriceCache or {}
    HousingCompletedDB.economy.ownedAuctions = HousingCompletedDB.economy.ownedAuctions or {}
    if type(HousingCompletedDB.economy.preferredPriceSource) ~= "string" or HousingCompletedDB.economy.preferredPriceSource == "" then
        HousingCompletedDB.economy.preferredPriceSource = "auto"
    end
    return HousingCompletedDB.economy
end

function HC:InitializeAuctionatorPricingProvider()
    if self.PricingProvider and self.PricingProvider._initialized then
        return self.PricingProvider
    end

    local provider = {
        _initialized = true,
        callerID = CALLER_ID,
        api = nil,
        tsmAPI = nil,
        dbCallbackRegistered = false,
        generation = 0,
        cacheByItemLink = {},
        cacheByItemID = {},
        tsmAuctionCacheByItemString = {},
        tsmCraftCacheByItemString = {},
        directPriceCache = {},
        directPriceCacheTime = nil,
        ownedAuctions = {},
        activeDirectScan = false,
        directNeededItems = {},
        directFound = 0,
        directTotal = 0,
        directProgressCb = nil,
        directDoneCb = nil,
        directTimeout = nil,
        ahEventFrame = nil,
    }

    function provider:GetGeneration()
        return self.generation or 0
    end

    function provider:InvalidateCache()
        WipeTable(self.cacheByItemLink)
        WipeTable(self.cacheByItemID)
        WipeTable(self.tsmAuctionCacheByItemString)
        WipeTable(self.tsmCraftCacheByItemString)
        self.generation = (self.generation or 0) + 1
    end

    function provider:LoadSavedState()
        local economy = GetEconomyDB()
        self.directPriceCache = economy.directPriceCache or {}
        self.directPriceCacheTime = economy.directPriceCacheTime
        self.ownedAuctions = economy.ownedAuctions or {}
    end

    function provider:SaveDirectCache()
        local economy = GetEconomyDB()
        economy.directPriceCache = self.directPriceCache
        economy.directPriceCacheTime = self.directPriceCacheTime
    end

    function provider:SaveOwnedAuctions()
        local economy = GetEconomyDB()
        economy.ownedAuctions = self.ownedAuctions
    end

    function provider:GetPreferredPriceSource()
        local economy = GetEconomyDB()
        local source = type(economy.preferredPriceSource) == "string" and economy.preferredPriceSource:lower() or "auto"
        if source ~= "auto" and source ~= "direct" and source ~= "auctionator" and source ~= "tsm" then
            source = "auto"
        end
        return source
    end

    function provider:SetPreferredPriceSource(source)
        local normalized = type(source) == "string" and source:lower() or "auto"
        if normalized ~= "auto" and normalized ~= "direct" and normalized ~= "auctionator" and normalized ~= "tsm" then
            normalized = "auto"
        end
        local economy = GetEconomyDB()
        economy.preferredPriceSource = normalized
        self:InvalidateCache()
        if HC and HC.OnPricingDataUpdated then
            HC:OnPricingDataUpdated("price_source_changed")
        end
    end

    function provider:GetAvailableSources()
        local out = {
            { id = "auto", label = "Auto", available = true },
            { id = "direct", label = "Direct AH", available = true },
            { id = "auctionator", label = "Auctionator", available = self.api ~= nil },
            { id = "tsm", label = "TSM", available = self.tsmAPI ~= nil },
        }
        return out
    end

    function provider:GetActiveSourceName()
        local preferred = self:GetPreferredPriceSource()
        if preferred == "auto" then
            if self.tsmAPI then
                return "TSM"
            end
            if self.api then
                return "Auctionator"
            end
            return "Direct AH"
        end
        if preferred == "direct" then
            return "Direct AH"
        end
        if preferred == "auctionator" then
            return "Auctionator"
        end
        if preferred == "tsm" then
            return "TSM"
        end
        return "Auto"
    end

    function provider:IsEnabled()
        return true
    end

    function provider:IsAuctionHouseOpen()
        return AuctionHouseFrame and AuctionHouseFrame:IsShown()
    end

    function provider:IsDirectScanInProgress()
        return self.activeDirectScan and true or false
    end

    function provider:GetDirectCacheInfo()
        local count = 0
        for _ in pairs(self.directPriceCache or {}) do
            count = count + 1
        end
        return count, self.directPriceCacheTime
    end

    function provider:GetDirectScanProgress()
        if not self.activeDirectScan then
            return nil, nil
        end
        return self.directFound, self.directTotal
    end

    function provider:ClearDirectCache()
        WipeTable(self.directPriceCache)
        self.directPriceCacheTime = nil
        self:SaveDirectCache()
        self:InvalidateCache()
        if HC and HC.OnPricingDataUpdated then
            HC:OnPricingDataUpdated("direct_cache_cleared")
        end
    end

    function provider:GetOwnedAuctionInfo(itemID)
        if not itemID then
            return nil
        end
        return self.ownedAuctions and self.ownedAuctions[itemID] or nil
    end

    function provider:ProcessOwnedAuctions()
        if not (C_AuctionHouse and C_AuctionHouse.GetOwnedAuctions) then
            return
        end
        local auctions = C_AuctionHouse.GetOwnedAuctions()
        if type(auctions) ~= "table" then
            return
        end

        local nextOwned = {}
        for _, info in ipairs(auctions) do
            local itemID = info and info.itemKey and info.itemKey.itemID
            if itemID then
                local status = info.status
                local isActive = status == 0 or (Enum and Enum.AuctionStatus and status == Enum.AuctionStatus.Active)
                local isSold = status == 1 or (Enum and Enum.AuctionStatus and status == Enum.AuctionStatus.Sold)
                if isActive or isSold then
                    local existing = nextOwned[itemID]
                    if not existing then
                        existing = { qty = 0, buyout = nil, sold = 0 }
                        nextOwned[itemID] = existing
                    end
                    if isActive then
                        existing.qty = existing.qty + (tonumber(info.quantity) or 1)
                        local buyout = tonumber(info.buyoutAmount)
                        if buyout and buyout > 0 and ((not existing.buyout) or buyout < existing.buyout) then
                            existing.buyout = buyout
                        end
                    end
                    if isSold then
                        existing.sold = existing.sold + (tonumber(info.quantity) or 1)
                    end
                end
            end
        end

        self.ownedAuctions = nextOwned
        self:SaveOwnedAuctions()
        self:InvalidateCache()
        if HC and HC.OnPricingDataUpdated then
            HC:OnPricingDataUpdated("owned_auctions_updated")
        end
    end

    function provider:QueryOwnedAuctions()
        if C_AuctionHouse and C_AuctionHouse.QueryOwnedAuctions and self:IsAuctionHouseOpen() then
            pcall(C_AuctionHouse.QueryOwnedAuctions, {})
            return true
        end
        return false
    end

    function provider:ProcessDirectBrowseResults(results)
        if not self.activeDirectScan or type(results) ~= "table" then
            return
        end

        for _, resultInfo in ipairs(results) do
            local itemID = resultInfo and resultInfo.itemKey and resultInfo.itemKey.itemID
            if itemID and self.directNeededItems[itemID] and resultInfo.totalQuantity and resultInfo.totalQuantity > 0 then
                if self.directPriceCache[itemID] == nil then
                    self.directFound = self.directFound + 1
                end
                self.directPriceCache[itemID] = tonumber(resultInfo.minPrice) or 0
            end
        end

        if self.directProgressCb then
            self.directProgressCb(self.directFound, self.directTotal)
        end
    end

    function provider:FinalizeDirectScan(reason)
        if not self.activeDirectScan then
            return
        end

        self.activeDirectScan = false
        if self.directTimeout then
            self.directTimeout:Cancel()
            self.directTimeout = nil
        end

        for itemID in pairs(self.directNeededItems or {}) do
            if self.directPriceCache[itemID] == nil then
                self.directPriceCache[itemID] = 0
            end
        end

        self.directPriceCacheTime = time()
        self:SaveDirectCache()
        self:InvalidateCache()

        local doneCb = self.directDoneCb
        self.directNeededItems = {}
        self.directFound = 0
        self.directTotal = 0
        self.directProgressCb = nil
        self.directDoneCb = nil

        if HC and HC.OnPricingDataUpdated then
            HC:OnPricingDataUpdated(reason or "direct_scan_complete")
        end

        if doneCb then
            doneCb()
        end
    end

    function provider:EnsureAHEventFrame()
        if self.ahEventFrame then
            return
        end

        local frame = CreateFrame("Frame")
        frame:RegisterEvent("AUCTION_HOUSE_SHOW")
        frame:RegisterEvent("AUCTION_HOUSE_BROWSE_RESULTS_UPDATED")
        frame:RegisterEvent("AUCTION_HOUSE_BROWSE_RESULTS_ADDED")
        frame:RegisterEvent("AUCTION_HOUSE_CLOSED")
        frame:RegisterEvent("OWNED_AUCTIONS_UPDATED")
        frame:SetScript("OnEvent", function(_, event, ...)
            if event == "AUCTION_HOUSE_SHOW" then
                self:QueryOwnedAuctions()
                return
            end
            if event == "OWNED_AUCTIONS_UPDATED" then
                self:ProcessOwnedAuctions()
                return
            end
            if event == "AUCTION_HOUSE_CLOSED" then
                self:FinalizeDirectScan("auction_house_closed")
                return
            end
            if not self.activeDirectScan then
                return
            end
            if event == "AUCTION_HOUSE_BROWSE_RESULTS_UPDATED" then
                if C_AuctionHouse and C_AuctionHouse.GetBrowseResults then
                    self:ProcessDirectBrowseResults(C_AuctionHouse.GetBrowseResults())
                end
                if C_AuctionHouse and C_AuctionHouse.HasFullBrowseResults and C_AuctionHouse.HasFullBrowseResults() then
                    self:FinalizeDirectScan("direct_scan_complete")
                elseif C_AuctionHouse and C_AuctionHouse.RequestMoreBrowseResults then
                    C_AuctionHouse.RequestMoreBrowseResults()
                end
                return
            end
            if event == "AUCTION_HOUSE_BROWSE_RESULTS_ADDED" then
                local added = ...
                self:ProcessDirectBrowseResults(added)
                if C_AuctionHouse and C_AuctionHouse.HasFullBrowseResults and C_AuctionHouse.HasFullBrowseResults() then
                    self:FinalizeDirectScan("direct_scan_complete")
                elseif C_AuctionHouse and C_AuctionHouse.RequestMoreBrowseResults then
                    C_AuctionHouse.RequestMoreBrowseResults()
                end
            end
        end)
        self.ahEventFrame = frame
    end

    function provider:StartDirectScan(itemIDs, progressCb, doneCb)
        if type(itemIDs) ~= "table" then
            if doneCb then
                doneCb()
            end
            return false
        end
        if not self:IsAuctionHouseOpen() then
            if doneCb then
                doneCb()
            end
            return false
        end

        self:EnsureAHEventFrame()

        local needed = {}
        local total = 0
        for _, itemID in ipairs(itemIDs) do
            local id = tonumber(itemID)
            if id and self.directPriceCache[id] == nil then
                needed[id] = true
                total = total + 1
            end
        end

        if total == 0 then
            if doneCb then
                doneCb()
            end
            return true
        end

        if self.activeDirectScan then
            self:FinalizeDirectScan("direct_scan_replaced")
        end

        self.activeDirectScan = true
        self.directNeededItems = needed
        self.directFound = 0
        self.directTotal = total
        self.directProgressCb = progressCb
        self.directDoneCb = doneCb
        self.directTimeout = C_Timer.NewTimer(60, function()
            self:FinalizeDirectScan("direct_scan_timeout")
        end)

        if C_AuctionHouse and C_AuctionHouse.SendBrowseQuery then
            C_AuctionHouse.SendBrowseQuery({
                searchString = "",
                sorts = {},
                filters = {},
                itemClassFilters = {},
            })
            return true
        end

        self:FinalizeDirectScan("direct_scan_unavailable")
        return false
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

    function provider:GetAuctionatorPrice(itemLink, itemID)
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

    function provider:GetTSMPrice(itemLink, itemID)
        local tsm = self.tsmAPI
        if not tsm then
            return nil
        end
        local itemString = self:GetTSMItemString(itemLink, itemID)
        if not itemString then
            return nil
        end

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
        return nil
    end

    function provider:GetDirectPrice(itemID)
        local price = type(itemID) == "number" and self.directPriceCache[itemID] or nil
        if type(price) == "number" and price > 0 then
            return price
        end
        return nil
    end

    function provider:GetAuctionPrice(itemLink, itemID)
        local preferred = self:GetPreferredPriceSource()

        if preferred == "direct" then
            return self:GetDirectPrice(itemID)
        end
        if preferred == "auctionator" then
            return self:GetAuctionatorPrice(itemLink, itemID)
        end
        if preferred == "tsm" then
            return self:GetTSMPrice(itemLink, itemID)
        end

        local tsmPrice = self:GetTSMPrice(itemLink, itemID)
        if tsmPrice then
            return tsmPrice
        end

        local auctionatorPrice = self:GetAuctionatorPrice(itemLink, itemID)
        if auctionatorPrice then
            return auctionatorPrice
        end

        return self:GetDirectPrice(itemID)
    end

    function provider:GetAuctionAge(itemLink, itemID)
        local preferred = self:GetPreferredPriceSource()

        if preferred == "direct" or (preferred == "auto" and not self.tsmAPI and not self.api) then
            if self.directPriceCacheTime then
                return math.max(0, time() - self.directPriceCacheTime)
            end
            return nil
        end

        local api = self.api
        if not api then
            return nil
        end

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
        return {
            price = price,
            age = self:GetAuctionAge(itemLink, itemID),
            source = self:GetActiveSourceName(),
        }
    end

    function provider:GetVendorPrice(itemLink, itemID)
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

    function provider:TryEnable()
        self.api = GetAuctionatorAPI()
        self.tsmAPI = GetTradeSkillMasterAPI()
        self:LoadSavedState()
        self:EnsureAHEventFrame()

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

    self.PricingProvider = provider
    provider:TryEnable()
    return provider
end

function HC:TryEnableAuctionatorIntegration()
    local provider = self:InitializeAuctionatorPricingProvider()
    local wasAvailable = provider.api ~= nil
    provider:TryEnable()
    if (provider.api ~= nil) and not wasAvailable and self.OnPricingDataUpdated then
        self:OnPricingDataUpdated("auctionator_loaded")
    end
    return provider.api ~= nil
end

function HC:TryEnableTradeSkillMasterIntegration()
    local provider = self:InitializeAuctionatorPricingProvider()
    local wasAvailable = provider.tsmAPI ~= nil
    provider:TryEnable()
    if (provider.tsmAPI ~= nil) and not wasAvailable and self.OnPricingDataUpdated then
        self:OnPricingDataUpdated("tsm_loaded")
    end
    return provider.tsmAPI ~= nil
end
