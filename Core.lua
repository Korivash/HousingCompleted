---------------------------------------------------
-- Housing Completed - Core.lua
-- Main addon logic and initialization
-- Author: Korivash
---------------------------------------------------
local addonName, HC = ...
_G["HousingCompleted"] = HC

HC.version = "1.4.0"
HC.searchResults = {}
HC.collectionCache = {}

-- Default saved variables
local defaults = {
    minimap = { hide = false },
    showMinimapButton = true,
scale = 1.0,
    windowPos = nil,
    navigation = {
        forceTomTom = true,
    },
    filters = {
        showCollected = true,
        showUncollected = true,
        showUnknownOnly = false,
        sourceTypes = {},
        expansions = {},
        minProfit = 0,
        minMargin = 0,
        craftableOnly = false,
        lowRiskOnly = false,
    },
    lastTab = "acquire",
    shoppingList = {},
    mode = "hybrid",
    economy = {
        priceHistory = {},
        maxHistory = 8,
    },
}

---------------------------------------------------
-- SavedVariables item cache (names/icons)
---------------------------------------------------
HC.cacheVersion = 1
HC.pendingItemLoads = HC.pendingItemLoads or {}
HC._uiRefreshQueued = false
HC._pricingRefreshQueued = false

function HC:InitSavedVars()
    -- Root table
    if type(HousingCompletedDB) ~= "table" then
        HousingCompletedDB = {}
    end

    -- Safe copy: CopyTable only works on tables; primitives should pass through
    local function SafeCopy(val)
        if type(val) == "table" then
            return CopyTable(val)
        end
        return val
    end

    -- Merge defaults + repair type-mismatches (e.g. legacy booleans)
    if not HousingCompletedDB._initedDefaults then
        for k, v in pairs(defaults) do
            if HousingCompletedDB[k] == nil then
                HousingCompletedDB[k] = SafeCopy(v)
            elseif type(v) == "table" then
                if type(HousingCompletedDB[k]) ~= "table" then
                    -- Repair bad legacy type (e.g. settings=false)
                    HousingCompletedDB[k] = SafeCopy(v)
                else
                    for kk, vv in pairs(v) do
                        if HousingCompletedDB[k][kk] == nil then
                            HousingCompletedDB[k][kk] = SafeCopy(vv)
                        elseif type(vv) == "table" and type(HousingCompletedDB[k][kk]) ~= "table" then
                            -- Repair nested type mismatch
                            HousingCompletedDB[k][kk] = SafeCopy(vv)
                        end
                    end
                end
            end
        end
        HousingCompletedDB._initedDefaults = true
    end


    -- Navigation settings (repair for existing DBs)
    if type(HousingCompletedDB.navigation) ~= "table" then
        HousingCompletedDB.navigation = { forceTomTom = true }
    end
    if HousingCompletedDB.navigation.forceTomTom == nil then
        HousingCompletedDB.navigation.forceTomTom = true
    end

    if type(HousingCompletedDB.shoppingList) ~= "table" then
        HousingCompletedDB.shoppingList = {}
    end

    if type(HousingCompletedDB.economy) ~= "table" then
        HousingCompletedDB.economy = { priceHistory = {}, maxHistory = 8 }
    end
    if type(HousingCompletedDB.economy.priceHistory) ~= "table" then
        HousingCompletedDB.economy.priceHistory = {}
    end
    HousingCompletedDB.economy.maxHistory = tonumber(HousingCompletedDB.economy.maxHistory) or 8
    if HousingCompletedDB.mode ~= "collector" and HousingCompletedDB.mode ~= "hybrid" and HousingCompletedDB.mode ~= "goblin" then
        HousingCompletedDB.mode = "hybrid"
    end

    -- Item cache (flat at root for fast access)
    if type(HousingCompletedDB.itemCache) ~= "table" then
        HousingCompletedDB.itemCache = {}
    end

    HousingCompletedDB.cacheVersion = tonumber(HousingCompletedDB.cacheVersion) or HC.cacheVersion
    if HousingCompletedDB.cacheVersion ~= HC.cacheVersion then
        -- Future-proof: wipe cache on schema change
        HousingCompletedDB.itemCache = {}
        HousingCompletedDB.cacheVersion = HC.cacheVersion
    end
end

function HC:GetShoppingList()
    if not HousingCompletedDB then return {} end
    HousingCompletedDB.shoppingList = HousingCompletedDB.shoppingList or {}
    return HousingCompletedDB.shoppingList
end

function HC:BuildShoppingListEntry(resultData)
    if not resultData then return nil end

    local mapID, x, y, title = self:GetResultWaypoint(resultData)
    local itemID = (resultData.data and resultData.data.itemID) or resultData.itemID
    local name = resultData.name or (resultData.data and resultData.data.name) or title
    local vendor = resultData.vendor or (resultData.data and resultData.data.name)
    local zone = resultData.zone or (resultData.data and resultData.data.zone) or ""
    local sourceType = self:NormalizeSourceType(resultData.type or "unknown")
    local source = resultData.source or ""

    if not name or name == "" then return nil end

    local key = string.format(
        "%s|%s|%s|%s",
        tostring(itemID or ""),
        tostring(name or ""):lower(),
        tostring(vendor or ""):lower(),
        tostring(zone or ""):lower()
    )

    return {
        key = key,
        itemID = itemID,
        name = name,
        sourceType = sourceType,
        source = source,
        vendor = vendor,
        zone = zone,
        mapID = mapID,
        x = x,
        y = y,
        title = title or name,
        addedAt = time(),
    }
end

function HC:AddResultToShoppingList(resultData)
    local entry = self:BuildShoppingListEntry(resultData)
    if not entry then
        return false, "No item selected."
    end

    local list = self:GetShoppingList()
    for _, existing in ipairs(list) do
        if existing.key == entry.key then
            return false, "Item is already in shopping list."
        end
    end

    table.insert(list, entry)
    return true, "Added to shopping list."
end

function HC:RemoveShoppingListEntry(index)
    local list = self:GetShoppingList()
    if type(index) ~= "number" or index < 1 or index > #list then
        return false
    end
    table.remove(list, index)
    return true
end

function HC:ClearShoppingList()
    local list = self:GetShoppingList()
    wipe(list)
end

function HC:MapWaypointsForShoppingList()
    local list = self:GetShoppingList()
    if #list == 0 then
        print("|cff00ff99Housing Completed|r: Shopping list is empty.")
        return false
    end

    local tt = _G.TomTom
    local hasTomTom = tt and type(tt.AddWaypoint) == "function"
    local mapped = 0
    local seen = {}
    local first = nil

    for _, entry in ipairs(list) do
        local mapID, x, y = entry.mapID, entry.x, entry.y
        if mapID and x and y then
            local nx, ny = x, y
            if nx > 1 or ny > 1 then
                nx, ny = x / 100, y / 100
            end
            if nx > 0 and ny > 0 and nx <= 1 and ny <= 1 then
                local key = string.format("%d:%.4f:%.4f", mapID, nx, ny)
                if not seen[key] then
                    seen[key] = true
                    if not first then
                        first = entry
                    end
                    if hasTomTom then
                        tt:AddWaypoint(mapID, nx, ny, {
                            title = entry.title or entry.name or "Shopping Target",
                            persistent = false,
                            minimap = true,
                            world = true,
                        })
                    end
                    mapped = mapped + 1
                end
            end
        end
    end

    if mapped == 0 then
        print("|cff00ff99Housing Completed|r: Shopping list has no mappable entries.")
        return false
    end

    if hasTomTom then
        print("|cff00ff99Housing Completed|r: Added " .. mapped .. " shopping waypoint" .. (mapped == 1 and "." or "s."))
        return true
    end

    if first then
        self:SetSmartWaypoint(first.x, first.y, first.mapID, first.title or first.name)
        print("|cff00ff99Housing Completed|r: TomTom not detected, set first shopping waypoint only.")
        return true
    end

    return false
end

function HC:GetCachedItemInfo(itemID)
    if not HousingCompletedDB or not HousingCompletedDB.itemCache then return nil, nil end
    local c = HousingCompletedDB.itemCache[itemID]
    if c then
        return c.name, c.icon
    end
    return nil, nil
end

function HC:UpdateItemCache(itemID, name, icon)
    if not itemID or not HousingCompletedDB or not HousingCompletedDB.itemCache then return end
    if not name and not icon then return end

    local c = HousingCompletedDB.itemCache[itemID] or {}
    if name and name ~= "" then c.name = name end
    if icon then c.icon = icon end
    HousingCompletedDB.itemCache[itemID] = c
end

function HC:EnsureItemCached(itemID)
    if not itemID then return end
    if self.pendingItemLoads[itemID] then return end

    local name, icon = self:GetCachedItemInfo(itemID)
    if name and icon then return end

    if C_Item and C_Item.RequestLoadItemDataByID then
        self.pendingItemLoads[itemID] = true
        C_Item.RequestLoadItemDataByID(itemID)
    end
end

function HC:OnItemDataLoadResult(itemID, success)
    self.pendingItemLoads[itemID] = nil
    if not success then return end

    local name = C_Item and C_Item.GetItemNameByID and C_Item.GetItemNameByID(itemID) or nil
    local icon = C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(itemID) or nil

    if name or icon then
        self:UpdateItemCache(itemID, name, icon)
        -- keep runtime cache in sync
        if self.allItemCache and self.allItemCache[itemID] then
            if name then self.allItemCache[itemID].name = name end
            if icon then self.allItemCache[itemID].icon = icon end
        end
        if name then
            self.itemNameToID = self.itemNameToID or {}
            local key = self:NormalizeItemName(name)
            if key then
                self.itemNameToID[key] = itemID
            end
        end
        self:ScheduleUIRefresh()
    end
end

function HC:ScheduleUIRefresh()
    if self._uiRefreshQueued then return end
    self._uiRefreshQueued = true
    C_Timer.After(0.2, function()
        self._uiRefreshQueued = false
        if self.mainFrame and self.mainFrame:IsShown() and self.DoSearch then
            self:DoSearch()
        end
    end)
end

function HC:SchedulePricingRefresh()
    if self._pricingRefreshQueued then return end
    self._pricingRefreshQueued = true
    C_Timer.After(0.15, function()
        self._pricingRefreshQueued = false
        if not (self.mainFrame and self.mainFrame:IsShown()) then
            return
        end
        if self.RefreshVisiblePricingData then
            self:RefreshVisiblePricingData()
        elseif self.DoSearch then
            self:DoSearch()
        end
    end)
end

function HC:OnPricingDataUpdated(reason)
    self:SchedulePricingRefresh()
    if self.shoppingListPanel and self.shoppingListPanel:IsShown() and self.RefreshShoppingListPanel then
        self:RefreshShoppingListPanel()
    end
end

function HC:NormalizeItemName(name)
    if type(name) ~= "string" then return nil end
    local normalized = name
    normalized = normalized:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    normalized = normalized:gsub("%s+", " ")
    normalized = normalized:gsub("^%s+", ""):gsub("%s+$", "")
    normalized = normalized:lower()
    if normalized == "" then return nil end
    return normalized
end

function HC:NormalizeSourceType(sourceType)
    local t = type(sourceType) == "string" and sourceType:lower() or "unknown"
    t = t:gsub("[%s%-]+", "_")

    if t == "promotion" then return "promo" end
    if t == "world_quest" or t == "worldquest" then return "quest" end
    if t == "crafted" or t == "craft" or t == "learned" then return "profession" end
    if t == "treasure" or t == "gathering" or t == "in_game" then return "drop" end

    if t == "achievement" or t == "vendor" or t == "quest" or t == "reputation"
        or t == "profession" or t == "drop" or t == "auction" or t == "promo" or t == "unknown" then
        return t
    end

    return "unknown"
end

function HC:BuildItemNameLookup()
    self.itemNameToID = {}
    for itemID, itemData in pairs(self.allItemCache or {}) do
        if itemData and itemData.name then
            local key = self:NormalizeItemName(itemData.name)
            if key then
                self.itemNameToID[key] = itemID
            end
        end
    end
end

function HC:ResolveItemIDByName(itemName)
    local key = self:NormalizeItemName(itemName)
    if not key then return nil end
    if not self.itemNameToID then
        self:BuildItemNameLookup()
    end
    return self.itemNameToID[key]
end


---------------------------------------------------
-- Initialization
---------------------------------------------------
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("ITEM_DATA_LOAD_RESULT")

frame:SetScript("OnEvent", function(self, event, ...)
    local arg1, arg2 = ...
    if event == "ADDON_LOADED" and arg1 == addonName then
        HC:Initialize()
    elseif event == "ADDON_LOADED" and arg1 == "Auctionator" then
        if HC.TryEnableAuctionatorIntegration then
            HC:TryEnableAuctionatorIntegration()
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        C_Timer.After(2, function()
            HC:CacheCollection()
        end)
    elseif event == "ITEM_DATA_LOAD_RESULT" then
        -- arg1=itemID, arg2=success
        HC:OnItemDataLoadResult(arg1, arg2)
    end
end)

function HC:Initialize()
    -- Initialize saved variables
    self:InitSavedVars()
    
    -- Setup minimap button
    self:SetupMinimapButton()

    -- Build item-first index (items -> sources)
    self:BuildItemIndex()

    -- Prime master item list (names/icons load over time via client cache)
    self:ResolveAllItems()

    if self.InitializeAuctionatorPricingProvider then
        self:InitializeAuctionatorPricingProvider()
        self:TryEnableAuctionatorIntegration()
    end
    
    -- Register slash commands
    SLASH_HOUSINGCOMPLETED1 = "/hc"
    SLASH_HOUSINGCOMPLETED2 = "/housing"
    SLASH_HOUSINGCOMPLETED3 = "/housingcompleted"
    SlashCmdList["HOUSINGCOMPLETED"] = function(msg)
        local cmd = msg:lower():trim()
        if cmd == "config" or cmd == "settings" then
            HC:OpenSettings()
        elseif cmd == "minimap" then
            HousingCompletedDB.showMinimapButton = not HousingCompletedDB.showMinimapButton
            local LibDBIcon = LibStub("LibDBIcon-1.0", true)
            if LibDBIcon then
                if HousingCompletedDB.showMinimapButton then
                    LibDBIcon:Show("HousingCompleted")
                else
                    LibDBIcon:Hide("HousingCompleted")
                end
                HousingCompletedDB.minimap.hide = not HousingCompletedDB.showMinimapButton
            end
            print("|cff00ff99Housing|r |cffffffffCompleted|r: Minimap button " .. (HousingCompletedDB.showMinimapButton and "shown" or "hidden"))
        else
            HC:ToggleUI()
        end
    end
    
    print("|cff00ff99Housing|r |cffffffffCompleted|r v" .. self.version .. " loaded. Type |cff00ffff/hc|r to open.")
end

function HC:SetupMinimapButton()
    local LDB = LibStub("LibDataBroker-1.1", true)
    local LibDBIcon = LibStub("LibDBIcon-1.0", true)
    
    if not LDB or not LibDBIcon then 
        print("|cff00ff99Housing Completed|r: LibDataBroker or LibDBIcon not found")
        return 
    end
    
    -- Create the LDB object FIRST
    local dataObj = LDB:NewDataObject("HousingCompleted", {
        type = "launcher",
        text = "Housing Completed",
        icon = "Interface\\Icons\\INV_Misc_Key_14",
        OnClick = function(_, button)
            if button == "LeftButton" then
                HC:ToggleUI()
            elseif button == "RightButton" then
                HC:OpenSettings()
            end
        end,
        OnTooltipShow = function(tooltip)
            tooltip:AddLine("|cff00ff99Housing|r |cffffffffCompleted|r")
            tooltip:AddLine(" ")
            tooltip:AddLine("|cffffffffLeft-click|r to open tracker")
            tooltip:AddLine("|cffffffffRight-click|r for settings")
        end,
    })
    
    -- Ensure we have a valid object before registering
    if not dataObj then
        print("|cff00ff99Housing Completed|r: Failed to create data broker object")
        return
    end
    
    -- Now register with LibDBIcon
    LibDBIcon:Register("HousingCompleted", dataObj, HousingCompletedDB.minimap)
    
    if HousingCompletedDB.showMinimapButton == false then
        LibDBIcon:Hide("HousingCompleted")
    end
end

---------------------------------------------------
-- Collection Tracking
---------------------------------------------------
function HC:CacheCollection()
    -- Cache the player's housing collection
    self.collectionCache = {}
    self.collectionNameCache = {}
    self.collectionItemIDCache = {}
    self.catalogReady = false

    local function mergeCollectionEntry(info)
        if not info then return end

        local entry = {
            collected = info.isCollected and true or false,
            count = tonumber(info.count) or 0,
            name = info.name,
            itemID = info.itemID,
            decorID = info.decorID,
        }

        if entry.decorID then
            local existingDecor = self.collectionCache[entry.decorID]
            if existingDecor then
                existingDecor.collected = existingDecor.collected or entry.collected
                if entry.count > (existingDecor.count or 0) then
                    existingDecor.count = entry.count
                end
                if (not existingDecor.name or existingDecor.name == "") and entry.name and entry.name ~= "" then
                    existingDecor.name = entry.name
                end
                if (not existingDecor.itemID) and entry.itemID then
                    existingDecor.itemID = entry.itemID
                end
            else
                self.collectionCache[entry.decorID] = entry
            end
        end

        if entry.name and entry.name ~= "" then
            local key = self:NormalizeItemName(entry.name)
            if key then
                local existingName = self.collectionNameCache[key]
                if existingName then
                    existingName.collected = existingName.collected or entry.collected
                    if entry.count > (existingName.count or 0) then
                        existingName.count = entry.count
                    end
                    if (not existingName.itemID) and entry.itemID then
                        existingName.itemID = entry.itemID
                    end
                else
                    self.collectionNameCache[key] = {
                        collected = entry.collected,
                        count = entry.count,
                        name = entry.name,
                        itemID = entry.itemID,
                    }
                end
            end
        end

        if entry.itemID then
            local existingItem = self.collectionItemIDCache[entry.itemID]
            if existingItem then
                existingItem.collected = existingItem.collected or entry.collected
                if entry.count > (existingItem.count or 0) then
                    existingItem.count = entry.count
                end
                if (not existingItem.name or existingItem.name == "") and entry.name and entry.name ~= "" then
                    existingItem.name = entry.name
                end
            else
                self.collectionItemIDCache[entry.itemID] = {
                    collected = entry.collected,
                    count = entry.count,
                    name = entry.name,
                }
            end
        end
    end

    -- Check if Housing Catalog API is available
    if C_HousingCatalog and C_HousingCatalog.GetNumCategories then
        local anyData = false

        -- Scan multiple catalog roots when available to avoid missing entries.
        local catalogRoots = { 1, 2, 3, 4, 5, 6 }
        for _, rootIndex in ipairs(catalogRoots) do
            local okCategories, numCategories = pcall(C_HousingCatalog.GetNumCategories, rootIndex)
            if okCategories and type(numCategories) == "number" and numCategories > 0 then
                for catIndex = 1, numCategories do
                    local okItems, numItems = pcall(C_HousingCatalog.GetNumCatalogEntriesInCategory, rootIndex, catIndex)
                    if okItems and type(numItems) == "number" and numItems > 0 then
                        for itemIndex = 1, numItems do
                            local okInfo, info = pcall(C_HousingCatalog.GetCatalogEntryInfoByIndex, rootIndex, catIndex, itemIndex)
                            if okInfo and info then
                                mergeCollectionEntry(info)
                                anyData = true
                            end
                        end
                    end
                end
            end
        end

        -- Fallback to legacy root if multi-root scan returned no data.
        if not anyData then
            local numCategories = C_HousingCatalog.GetNumCategories(1) or 0
            for catIndex = 1, numCategories do
                local numItems = C_HousingCatalog.GetNumCatalogEntriesInCategory(1, catIndex) or 0
                for itemIndex = 1, numItems do
                    local info = C_HousingCatalog.GetCatalogEntryInfoByIndex(1, catIndex, itemIndex)
                    if info then
                        mergeCollectionEntry(info)
                    end
                end
            end
        end

        self.catalogReady = true
    end
end

function HC:IsDecorCollected(decorName)
    -- Check if a decor item is collected by name
    local key = self:NormalizeItemName(decorName)
    if key and self.collectionNameCache and self.collectionNameCache[key] then
        local info = self.collectionNameCache[key]
        return info.collected, info.count
    end

    -- Backward-compatible fallback for legacy cache shapes.
    if type(decorName) == "string" then
        for _, info in pairs(self.collectionCache or {}) do
            if info.name and info.name:lower() == decorName:lower() then
                return info.collected, info.count
            end
        end
    end

    return false, 0
end

function HC:IsDecorCollectedByID(itemID)
    if not itemID then return false, 0 end
    local info = self.collectionItemIDCache and self.collectionItemIDCache[itemID]
    if info then
        return info.collected, info.count
    end
    return false, 0
end

function HC:IsItemCollected(itemID, itemName)
    local collectedByName, countByName = self:IsDecorCollected(itemName)
    if collectedByName then
        return true, countByName or 0
    end
    local collectedByID, countByID = self:IsDecorCollectedByID(itemID)
    if collectedByID then
        return true, countByID or 0
    end
    return false, 0
end


---------------------------------------------------
-- Item-first Index (Items -> Sources)
---------------------------------------------------
function HC:BuildItemIndex(force)
    -- Build a unique item list where each item can have multiple sources.
    -- force=true rebuilds even if already built.
    if self.ItemList and not force then return end

    self.ItemIndex = {}
    self.ItemList = {}

    local function addEntry(entry)
        if not entry then return end
        local name = entry.name
        if not name or name == "" then return end
        local resolvedItemID = entry.itemID or self:ResolveItemIDByName(name)

        local item = self.ItemIndex[name]
        if not item then
            item = { name = name, itemID = resolvedItemID, sources = {} }
            self.ItemIndex[name] = item
            table.insert(self.ItemList, item)
        end

        if (not item.itemID) and resolvedItemID then
            item.itemID = resolvedItemID
        end
        if item.itemID then
            self:EnsureItemCached(item.itemID)
        end

        local vendorData
        if entry.vendor then
            vendorData = self:GetVendorByName(entry.vendor)
        end

        local sourceCoords = entry.coords
        if (not sourceCoords) and vendorData and vendorData.x and vendorData.y then
            sourceCoords = { vendorData.x, vendorData.y }
        end

        local normalizedSourceType = self:NormalizeSourceType(entry.sourceType or entry.type or "unknown")

        table.insert(item.sources, {
            sourceType = normalizedSourceType,
            source = entry.source or entry.achievement or entry.quest or entry.faction,
            vendor = entry.vendor,
            cost = entry.cost,
            zone = entry.zone or (vendorData and vendorData.zone) or nil,
            coords = sourceCoords,
            mapID = entry.mapID or (vendorData and vendorData.mapID) or nil,
            faction = entry.faction or (vendorData and vendorData.faction) or nil,
            expansion = entry.expansion,
            notes = entry.notes,
            standing = entry.standing,
            profession = entry.profession,
            vendorData = vendorData,
        })
    end

    -- Primary combined table (if present)
    for _, entry in ipairs(HC.DecorItems or {}) do addEntry(entry) end
    -- Imported sources (generated from wowdb exports)
    for _, entry in ipairs(HC.ImportedDecorItems or {}) do addEntry(entry) end

    -- Back-compat tables (many projects still populate these)
    for _, entry in ipairs(HC.AchievementItems or {}) do
        addEntry({
            name = entry.name, itemID = entry.itemID,
            sourceType = "achievement", source = entry.achievement,
            vendor = entry.vendor, cost = entry.cost, zone = entry.zone,
            coords = entry.coords, mapID = entry.mapID, faction = entry.faction,
            expansion = entry.expansion, notes = entry.notes
        })
    end
    for _, entry in ipairs(HC.QuestItems or {}) do
        addEntry({
            name = entry.name, itemID = entry.itemID,
            sourceType = "quest", source = entry.quest,
            vendor = entry.vendor, cost = entry.cost, zone = entry.zone,
            coords = entry.coords, mapID = entry.mapID, faction = entry.faction,
            expansion = entry.expansion, notes = entry.notes
        })
    end
    for _, entry in ipairs(HC.ReputationItems or {}) do
        addEntry({
            name = entry.name, itemID = entry.itemID,
            sourceType = "reputation", source = (entry.faction and entry.standing) and (entry.faction .. " - " .. entry.standing) or entry.faction,
            vendor = entry.vendor, cost = entry.cost, zone = entry.zone,
            coords = entry.coords, mapID = entry.mapID, faction = entry.faction,
            expansion = entry.expansion, notes = entry.notes, standing = entry.standing
        })
    end
    for _, entry in ipairs(HC.ProfessionItems or {}) do
        addEntry({
            name = entry.name, itemID = entry.itemID,
            sourceType = "profession", source = entry.profession,
            vendor = entry.vendor, cost = entry.cost, zone = entry.zone,
            coords = entry.coords, mapID = entry.mapID, faction = entry.faction,
            expansion = entry.expansion, notes = entry.notes, profession = entry.profession
        })
    end
    for _, entry in ipairs(HC.AuctionItems or {}) do
        addEntry({
            name = entry.name, itemID = entry.itemID,
            sourceType = "auction", source = "Auction House",
            vendor = entry.vendor, cost = entry.cost, zone = entry.zone,
            coords = entry.coords, mapID = entry.mapID, faction = entry.faction,
            expansion = entry.expansion, notes = entry.notes
        })
    end

    table.sort(self.ItemList, function(a, b) return (a.name or "") < (b.name or "") end)
end

function HC:GetBestWaypointForItem(item)
    if not item or not item.sources then return nil end

    -- Prefer coordinate-bearing sources first (vendor-like), but any with coords works.
    local preferred = {
        vendor = 1, achievement = 2, reputation = 2, quest = 2, profession = 3, auction = 4, drop = 5, unknown = 9,
    }

    local best
    for _, s in ipairs(item.sources) do
        local mapID = s.mapID
        local x, y
        if s.coords and type(s.coords) == "table" then
            x, y = s.coords[1], s.coords[2]
        end
        if mapID and x and y then
            local score = preferred[s.sourceType or "unknown"] or 9
            if not best or score < best.score then
                best = { mapID = mapID, x = x, y = y, title = (s.vendor or s.source or item.name), score = score }
            end
        end
    end

    if best then
        return best.mapID, best.x, best.y, best.title
    end
    return nil
end

function HC:SetItemWaypoint(itemData)
    if not itemData then return end
    local wp = itemData.waypoint
    if wp and wp.mapID and wp.x and wp.y then
        self:SetSmartWaypoint(wp.x, wp.y, wp.mapID, wp.title)
    else
        print("|cff00ff99Housing Completed|r: No waypoint available for this item.")
    end
end

function HC:ResultHasWaypoint(resultData)
    local mapID, x, y = self:GetResultWaypoint(resultData)
    return mapID and x and y and true or false
end

function HC:SetResultWaypoint(resultData)
    if not resultData then
        print("|cff00ff99Housing Completed|r: Select an item first.")
        return false
    end

    local mapID, x, y, title = self:GetResultWaypoint(resultData)
    if mapID and x and y then
        self:SetSmartWaypoint(x, y, mapID, title or resultData.name)
        return true
    end

    print("|cff00ff99Housing Completed|r: No waypoint available for this item.")
    return false
end

---------------------------------------------------
-- Search Functions
---------------------------------------------------
function HC:IsReputationRequirementText(text)
    if type(text) ~= "string" then return false end
    local t = text:lower()
    if t:find("friendly", 1, true) then return true end
    if t:find("honored", 1, true) then return true end
    if t:find("revered", 1, true) then return true end
    if t:find("exalted", 1, true) then return true end
    if t:find("renown", 1, true) then return true end
    if t:find("rank", 1, true) then return true end
    if t:find("reputation", 1, true) then return true end
    if t:find("require", 1, true) then return true end
    return false
end

function HC:ExtractReputationRequirement(text, fallbackFaction, fallbackStanding)
    local faction = fallbackFaction
    local standing = fallbackStanding
    if type(text) ~= "string" or text == "" then
        return faction, standing
    end

    local t = text
    if not standing or standing == "" then
        standing = t:match("([Rr]enown%s*%d+)")
            or t:match("([Rr]ank%s*%d+)")
            or t:match("([Ee]xalted)")
            or t:match("([Rr]evered)")
            or t:match("([Hh]onored)")
            or t:match("([Ff]riendly)")
    end

    if not faction or faction == "" then
        faction = t:match("[Ww]ith%s+([^,%.]+)")
        if faction then
            faction = faction:gsub("^%s+", ""):gsub("%s+$", "")
        end
    end

    return faction, standing
end

function HC:IsPlayerFactionRestricted(itemFaction)
    if type(itemFaction) ~= "string" then return false end
    local f = itemFaction:lower()
    return f == "alliance" or f == "horde" or f == "neutral"
end

function HC:IsReputationSource(source)
    if not source then return false end
    if source.sourceType == "reputation" then return true end
    if source.standing and source.standing ~= "" then return true end
    if self:IsReputationRequirementText(source.notes) then return true end
    return false
end

function HC:SourceMatchesType(source, wantedType)
    if not source or not wantedType then return false end
    wantedType = self:NormalizeSourceType(wantedType)
    local sourceType = self:NormalizeSourceType(source.sourceType or "unknown")
    if wantedType == "reputation" then
        return self:IsReputationSource(source)
    end
    return sourceType == wantedType
end

function HC:GetItemCategories()
    return {
        { id = "all", name = "All Item Types" },
        { id = "vendor", name = "Vendor" },
        { id = "chair", name = "Chair" },
        { id = "plant", name = "Plant" },
        { id = "table", name = "Table" },
        { id = "bed", name = "Bed" },
        { id = "lighting", name = "Lighting" },
        { id = "rug", name = "Rug" },
        { id = "storage", name = "Storage" },
        { id = "banner", name = "Banner" },
        { id = "fountain", name = "Fountain" },
        { id = "book", name = "Book/Scroll" },
        { id = "misc", name = "Misc" },
    }
end

function HC:GetItemCategoryByName(itemName)
    local name = type(itemName) == "string" and itemName:lower() or ""
    if name == "" then return "misc" end

    local keywordGroups = {
        { id = "chair", terms = { "chair", "seat", "stool", "recliner", "bench", "throne" } },
        { id = "plant", terms = { "plant", "flower", "tree", "vine", "trellis", "shrub", "bush", "garden", "herb" } },
        { id = "table", terms = { "table", "desk", "counter", "workbench", "work table" } },
        { id = "bed", terms = { "bed", "bunk", "cot", "mattress" } },
        { id = "lighting", terms = { "lamp", "lantern", "brazier", "torch", "candle", "sconce", "chandelier", "light" } },
        { id = "rug", terms = { "rug", "carpet", "mat" } },
        { id = "storage", terms = { "crate", "chest", "cabinet", "shelf", "bookcase", "locker", "barrel", "box", "storage" } },
        { id = "banner", terms = { "banner", "flag", "standard", "emblem", "pennant" } },
        { id = "fountain", terms = { "fountain", "well", "waterfall" } },
        { id = "book", terms = { "book", "tome", "scroll", "map", "painting" } },
    }

    for _, group in ipairs(keywordGroups) do
        for _, term in ipairs(group.terms) do
            if name:find(term, 1, true) then
                return group.id
            end
        end
    end

    return "misc"
end

function HC:GetSourceTags(sources)
    local tags = {}
    local seen = {}
    if type(sources) ~= "table" then return tags end

    for _, s in ipairs(sources) do
        local sourceType = s and self:NormalizeSourceType(s.sourceType or "unknown")
        local tag = sourceType and self:GetSourceTypeInfo(sourceType).name or nil
        if (sourceType == "reputation") or (self.IsReputationSource and self:IsReputationSource(s)) then
            tag = "Rep"
        end
        if tag and not seen[tag] then
            seen[tag] = true
            table.insert(tags, tag)
        end
    end

    if #tags == 0 then
        table.insert(tags, "Unknown")
    end
    return tags
end

function HC:ItemMatchesCategory(item, categoryID)
    if not item then return false end
    if not categoryID or categoryID == "all" then return true end
    if categoryID == "vendor" then
        for _, s in ipairs(item.sources or {}) do
            if (s.sourceType == "vendor") or s.vendor then
                return true
            end
        end
        return false
    end
    return self:GetItemCategoryByName(item.name) == categoryID
end

function HC:SearchAll(query, filters)
    local results = {}
    local hasQuery = query and query:gsub("%s+", "") ~= ""
    local queryNumber = nil
    if hasQuery then query = query:lower() end
    if hasQuery then queryNumber = tonumber(query) end
    filters = filters or {}
    local seenNameKeys = {}
    local seenItemIDs = {}

    if (not self.ItemList) or (#self.ItemList == 0) then
        self:BuildItemIndex(true)
    end

    for _, item in ipairs(self.ItemList or {}) do
        local name = item.name or ""
        local nameMatch = (not hasQuery) or (name:lower():find(query, 1, true) ~= nil)
        local sourceMatch = false

        local primaryType
        local primarySource
        local primaryVendor
        local primaryCost
        local primaryZone
        local primaryExpansion
        local primaryFaction
        local primaryStanding
        local primaryVendorData

        for _, s in ipairs(item.sources or {}) do
            local parts = {}
            if s.source then table.insert(parts, s.source) end
            if s.vendor then table.insert(parts, s.vendor) end
            if s.zone then table.insert(parts, s.zone) end
            local blob = table.concat(parts, " "):lower()
            if hasQuery and blob:find(query, 1, true) then
                sourceMatch = true
            end

            if not primaryType then
                primaryType = self:NormalizeSourceType(s.sourceType or "unknown")
                primarySource = s.source
                primaryVendor = s.vendor
                primaryCost = s.cost
                primaryZone = s.zone
                primaryExpansion = s.expansion
                primaryFaction = s.faction
                primaryStanding = s.standing
                primaryVendorData = s.vendorData
            end
        end

        local matches = nameMatch or sourceMatch
        if matches then
            -- Source-level filters: if ANY source passes, keep the item
            local passes = true

            if filters.sourceTypes and next(filters.sourceTypes) then
                passes = false
                for _, s in ipairs(item.sources or {}) do
                    for wantedType in pairs(filters.sourceTypes) do
                        if self:SourceMatchesType(s, wantedType) then
                            passes = true
                            -- Prefer a filter-matching source for row/preview fields.
                            primaryType = self:NormalizeSourceType(wantedType)
                            primarySource = s.source
                            primaryVendor = s.vendor
                            primaryCost = s.cost
                            primaryZone = s.zone
                            primaryExpansion = s.expansion
                            primaryFaction = s.faction
                            primaryStanding = s.standing
                            primaryVendorData = s.vendorData
                            break
                        end
                    end
                    if passes then
                        break
                    end
                end
            end

            if passes and filters.expansions and next(filters.expansions) then
                passes = false
                for _, s in ipairs(item.sources or {}) do
                    local exp = s.expansion
                    if exp and filters.expansions[exp] then
                        passes = true
                        break
                    end
                end
            end

            if passes and filters.faction then
                for _, s in ipairs(item.sources or {}) do
                    local f = s.faction
                    if self:IsPlayerFactionRestricted(f) and f ~= "neutral" and f ~= filters.faction then
                        passes = false
                        break
                    end
                end
            end

            if passes and filters.itemCategory and filters.itemCategory ~= "all" then
                passes = self:ItemMatchesCategory(item, filters.itemCategory)
            end

            if passes and filters.zoneMapID then
                passes = false
                for _, s in ipairs(item.sources or {}) do
                    local sMapID = s.mapID or (s.vendorData and s.vendorData.mapID)
                    if sMapID and sMapID == filters.zoneMapID then
                        passes = true
                        break
                    end
                end
            end

            if passes then
                local wpMapID, wpX, wpY, wpTitle = self:GetBestWaypointForItem(item)
                local collected = self:IsItemCollected(item.itemID, name)
                local resolvedItemID = item.itemID or self:ResolveItemIDByName(item.name)
                local itemCategory = self:GetItemCategoryByName(item.name)
                local sourceTags = self:GetSourceTags(item.sources)
                if resolvedItemID then
                    item.itemID = resolvedItemID
                    self:EnsureItemCached(resolvedItemID)
                end
                table.insert(results, {
                    type = self:NormalizeSourceType(primaryType or "unknown"),
                    data = {
                        name = item.name,
                        itemID = item.itemID,
                        sources = item.sources,
                        sourceCount = #(item.sources or {}),
                        vendorData = primaryVendorData,
                        faction = primaryFaction,
                        standing = primaryStanding,
                        itemCategory = itemCategory,
                        sourceTags = sourceTags,
                        waypoint = (wpMapID and wpX and wpY) and { mapID = wpMapID, x = wpX, y = wpY, title = wpTitle } or nil,
                    },
                    name = item.name,
                    source = primarySource,
                    vendor = primaryVendor,
                    zone = primaryZone,
                    cost = primaryCost,
                    expansion = primaryExpansion,
                    faction = primaryFaction,
                    sourceCount = #(item.sources or {}),
                    vendorData = primaryVendorData,
                    itemCategory = itemCategory,
                    sourceTags = sourceTags,
                    collected = collected,
                })
                local itemNameKey = self:NormalizeItemName(item.name)
                if itemNameKey then
                    seenNameKeys[itemNameKey] = true
                end
                if item.itemID then
                    seenItemIDs[item.itemID] = true
                end
            end
        end
    end

    -- Search vendors (as results) - keep vendor browsing available
    for _, vendor in ipairs(HC.Vendors or {}) do
        local matches = (not hasQuery) or
            (vendor.name and vendor.name:lower():find(query, 1, true)) or
            (vendor.zone and vendor.zone:lower():find(query, 1, true))
        if (not filters.hideVendorEntries)
            and matches
            and self:PassesFilters(vendor, filters, "vendor")
            and ((not filters.zoneMapID) or (vendor.mapID == filters.zoneMapID)) then
            table.insert(results, {
                type = "vendor",
                data = vendor,
                name = vendor.name,
                zone = vendor.zone,
                expansion = vendor.expansion,
                vendor = vendor.name,
                source = vendor.zone,
                cost = nil,
                sourceCount = 1,
                vendorData = vendor,
                itemCategory = "vendor",
                sourceTags = { "Vendor" },
                collected = false,
            })
        end
    end

    -- Include additional known items from AllItems cache as unknown entries.
    -- This lets newly-known itemIDs be searchable/previewable before sources are curated.
    for itemID, itemData in pairs(self.allItemCache or {}) do
        if not seenItemIDs[itemID] then
            local cachedName = itemData and itemData.name
            local displayName = cachedName or ("Item #" .. tostring(itemID))
            local key = self:NormalizeItemName(displayName)
            local match = (not hasQuery)
                or (cachedName and cachedName:lower():find(query, 1, true) ~= nil)
                or (queryNumber and itemID == queryNumber)

            if key and (not seenNameKeys[key]) and match and self:PassesFilters({ expansion = nil, faction = nil }, filters, "unknown") then
                local unknown = self:GetUnknownItemResult(itemID, displayName)
                unknown.source = cachedName and "Currently Unknown" or "Unresolved Item Data"
                unknown.sourceCount = 0
                table.insert(results, unknown)
                seenNameKeys[key] = true
                seenItemIDs[itemID] = true
            end
        end
    end

    -- Include items already in player's collection that are not in curated/imported data yet.
    for _, collectionInfo in pairs(self.collectionCache or {}) do
        local collectedName = collectionInfo and collectionInfo.name
        if collectedName and collectedName ~= "" then
            local key = self:NormalizeItemName(collectedName)
            if key and not seenNameKeys[key] then
                local match = (not hasQuery) or (collectedName:lower():find(query, 1, true) ~= nil)
                if match and self:PassesFilters({ expansion = nil, faction = nil }, filters, "unknown") then
                    local resolvedID = self:ResolveItemIDByName(collectedName)
                    if (not resolvedID) or (not seenItemIDs[resolvedID]) then
                        local unknown = self:GetUnknownItemResult(resolvedID, collectedName)
                        unknown.source = "In Your Collection"
                        unknown.sourceCount = 1
                        unknown.collected = true
                        table.insert(results, unknown)
                        seenNameKeys[key] = true
                        if resolvedID then
                            seenItemIDs[resolvedID] = true
                        end
                    end
                end
            end
        end
    end

    return results
end

function HC:PassesFilters(item, filters, sourceType)
    sourceType = self:NormalizeSourceType(sourceType or "unknown")
    -- Check source type filter
    if filters.sourceTypes and next(filters.sourceTypes) then
        if not filters.sourceTypes[sourceType] then
            return false
        end
    end
    
    -- Check expansion filter
    if filters.expansions and next(filters.expansions) then
        local expansion = item.expansion
        if expansion and not filters.expansions[expansion] then
            return false
        end
    end
    
    -- Check faction filter
    if filters.faction then
        local itemFaction = item.faction
        if self:IsPlayerFactionRestricted(itemFaction) and itemFaction ~= "neutral" and itemFaction ~= filters.faction then
            return false
        end
    end
    
    return true
end

function HC:GetResultWaypoint(resultData)
    if not resultData then return nil end

    local data = resultData.data
    if resultData.type == "vendor" and data and data.mapID and data.x and data.y then
        return data.mapID, data.x, data.y, data.name or resultData.name
    end

    if data and data.waypoint and data.waypoint.mapID and data.waypoint.x and data.waypoint.y then
        return data.waypoint.mapID, data.waypoint.x, data.waypoint.y, data.waypoint.title or resultData.name
    end

    if data and data.vendorData and data.vendorData.mapID and data.vendorData.x and data.vendorData.y then
        return data.vendorData.mapID, data.vendorData.x, data.vendorData.y, data.vendorData.name or resultData.name
    end

    if resultData.vendor then
        local vendor = self:GetVendorByName(resultData.vendor)
        if vendor and vendor.mapID and vendor.x and vendor.y then
            return vendor.mapID, vendor.x, vendor.y, vendor.name or resultData.name
        end
    end

    return nil
end

function HC:MapWaypointsForResults(results)
    if type(results) ~= "table" or #results == 0 then
        print("|cff00ff99Housing Completed|r: No results to map.")
        return false
    end

    local tt = _G.TomTom
    local hasTomTom = tt and type(tt.AddWaypoint) == "function"
    local seen = {}
    local mapped = 0
    local first

    for _, resultData in ipairs(results) do
        local mapID, x, y, title = self:GetResultWaypoint(resultData)
        if mapID and x and y then
            local nx, ny = x, y
            if nx > 1 or ny > 1 then
                nx, ny = x / 100, y / 100
            end
            if nx > 0 and ny > 0 and nx <= 1 and ny <= 1 then
                local key = string.format("%d:%.4f:%.4f", mapID, nx, ny)
                if not seen[key] then
                    seen[key] = true
                    if not first then
                        first = { mapID = mapID, x = x, y = y, title = title }
                    end
                    if hasTomTom then
                        tt:AddWaypoint(mapID, nx, ny, {
                            title = title or "Housing Vendor",
                            persistent = false,
                            minimap = true,
                            world = true,
                        })
                    end
                    mapped = mapped + 1
                end
            end
        end
    end

    if mapped == 0 then
        print("|cff00ff99Housing Completed|r: No waypoint coordinates found in these results.")
        return false
    end

    if hasTomTom then
        print("|cff00ff99Housing Completed|r: Added " .. mapped .. " TomTom waypoint" .. (mapped == 1 and "." or "s."))
        return true
    end

    if first then
        self:SetSmartWaypoint(first.x, first.y, first.mapID, first.title)
        print("|cff00ff99Housing Completed|r: TomTom not detected, set the first available waypoint only.")
        return true
    end

    return false
end

function HC:GetVendorByID(vendorID)
    if not vendorID then return nil end
    for _, vendor in ipairs(HC.Vendors or {}) do
        if vendor.id == vendorID then
            return vendor
        end
    end
    return nil
end

function HC:GetVendorByName(vendorName)
    if not vendorName then return nil end
    vendorName = vendorName:lower()
    for _, vendor in ipairs(HC.Vendors or {}) do
        if vendor.name and vendor.name:lower() == vendorName then
            return vendor
        end
    end
    return nil
end

---------------------------------------------------
-- Waypoint Functions (TomTom + Blizzard fallback)
---------------------------------------------------

-- Preferred navigation: TomTom (full routing). Falls back to Blizzard user waypoint.
function HC:SetSmartWaypoint(x, y, mapID, title)
    if not x or not y or not mapID then
        print("|cff00ff99Housing Completed|r: No coordinates available for this location.")
        return
    end

    -- Normalize safely (accept either 0-100 or 0-1).
    local nx, ny = x, y
    if nx > 1 or ny > 1 then
        nx, ny = (x / 100), (y / 100)
    end
    if nx <= 0 or ny <= 0 or nx > 1 or ny > 1 then
        print("|cff00ff99Housing Completed|r: Invalid coordinates for this location.")
        return
    end

    local forceTomTom = (HousingCompletedDB and HousingCompletedDB.navigation and HousingCompletedDB.navigation.forceTomTom) and true or false
    local tt = _G.TomTom
    local hasTomTom = tt and type(tt.AddWaypoint) == "function"

    -- If forced, ALWAYS try TomTom first (warn once if missing)
    if forceTomTom then
        if hasTomTom then
            if self._tomtomWaypoint and type(tt.RemoveWaypoint) == "function" then
                tt:RemoveWaypoint(self._tomtomWaypoint)
                self._tomtomWaypoint = nil
            end

            self._tomtomWaypoint = tt:AddWaypoint(mapID, nx, ny, {
                title = title or "Housing Destination",
                persistent = false,
                minimap = true,
                world = true,
            })

            print("|cff00ff99Housing Completed|r: TomTom route set" .. (title and (" for " .. title) or "") .. ".")
            return
        else
            if not self._warnedTomTomMissing then
                self._warnedTomTomMissing = true
                print("|cff00ff99Housing Completed|r: |cffffff00TomTom|r not detected. Install/enable TomTom for advanced navigation.")
            end
        end
    end

    -- If not forcing, use TomTom when available, otherwise fallback
    if (not forceTomTom) and hasTomTom then
        if self._tomtomWaypoint and type(tt.RemoveWaypoint) == "function" then
            tt:RemoveWaypoint(self._tomtomWaypoint)
            self._tomtomWaypoint = nil
        end

        self._tomtomWaypoint = tt:AddWaypoint(mapID, nx, ny, {
            title = title or "Housing Destination",
            persistent = false,
            minimap = true,
            world = true,
        })

        print("|cff00ff99Housing Completed|r: TomTom route set" .. (title and (" for " .. title) or "") .. ".")
        return
    end

    -- Fallback: Blizzard waypoint (limited routing).
    self:SetWaypoint(nx, ny, mapID, title)
end

-- Blizzard user waypoint (fallback). Note: This does NOT provide full quest-style routing.
function HC:SetWaypoint(x, y, mapID, title)
    if not x or not y or not mapID then
        print("|cff00ff99Housing Completed|r: No coordinates available for this location.")
        return
    end

    -- Coordinates are expected normalized here (0-1). If caller passes 0-100, normalize.
    local nx, ny = x, y
    if nx > 1 or ny > 1 then
        nx, ny = (x / 100), (y / 100)
    end
    if nx <= 0 or ny <= 0 or nx > 1 or ny > 1 then
        print("|cff00ff99Housing Completed|r: Invalid coordinates for this location.")
        return
    end

    -- Some maps don't allow user waypoints; walk up parent chain to find a valid waypoint map.
    local function FindWaypointMap(startMapID)
        local cur = startMapID
        local guard = 0
        while cur and guard < 15 do
            if C_Map and C_Map.CanSetUserWaypointOnMap and C_Map.CanSetUserWaypointOnMap(cur) then
                return cur
            end
            local info = C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(cur)
            cur = info and info.parentMapID or nil
            guard = guard + 1
        end
        return startMapID
    end

    local wpMapID = FindWaypointMap(mapID)

    if C_Map and C_Map.ClearUserWaypoint then
        C_Map.ClearUserWaypoint()
    end

    local waypoint = UiMapPoint.CreateFromCoordinates(wpMapID, nx, ny)
    if not waypoint then
        print("|cff00ff99Housing Completed|r: Failed to create waypoint.")
        return
    end

    if C_Map and C_Map.SetUserWaypoint then
        C_Map.SetUserWaypoint(waypoint)
    end
    if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then
        C_SuperTrack.SetSuperTrackedUserWaypoint(true)
    end

    if WorldMapFrame and WorldMapFrame.RefreshAllDataProviders then
        WorldMapFrame:RefreshAllDataProviders()
    end

    print("|cff00ff99Housing Completed|r: Waypoint set" .. (title and (" for " .. title) or "") .. ".")
end

function HC:ClearWaypoint()
    -- Clear TomTom waypoint if we created one
    if TomTom and self._tomtomWaypoint and TomTom.RemoveWaypoint then
        TomTom:RemoveWaypoint(self._tomtomWaypoint)
        self._tomtomWaypoint = nil
    end

    -- Clear Blizzard waypoint too
    if C_Map and C_Map.ClearUserWaypoint then
        C_Map.ClearUserWaypoint()
    end
    if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then
        C_SuperTrack.SetSuperTrackedUserWaypoint(false)
    end

    print("|cff00ff99Housing Completed|r: Waypoint cleared.")
end

---------------------------------------------------
-- Utility Functions
---------------------------------------------------
function HC:GetSourceTypeInfo(sourceType)
    sourceType = self:NormalizeSourceType(sourceType or "unknown")
    for _, info in ipairs(HC.SourceTypes or {}) do
        if info.id == sourceType then
            return info
        end
    end
    return { id = sourceType, name = sourceType, icon = "Interface\\Icons\\INV_Misc_QuestionMark", color = {1, 1, 1} }
end

function HC:GetExpansionInfo(expansion)
    for _, info in ipairs(HC.Expansions or {}) do
        if info.id == expansion then
            return info
        end
    end
    return { id = expansion, name = expansion or "Unknown", color = {1, 1, 1} }
end

function HC:GetFactionIcon(faction)
    if faction == "alliance" then
        return "Interface\\Icons\\Inv_misc_tournaments_banner_human"
    elseif faction == "horde" then
        return "Interface\\Icons\\Inv_misc_tournaments_banner_orc"
    else
        return "Interface\\Icons\\Achievement_Reputation_05"
    end
end

function HC:GetPlayerFaction()
    local faction = UnitFactionGroup("player")
    return faction and faction:lower() or "neutral"
end

---------------------------------------------------
-- Statistics
---------------------------------------------------
function HC:GetStatistics()
    local stats = {
        totalItems = 0,
        collected = 0,
        knownTotal = 0,
        trackableTotal = 0,
        collectedTrackable = 0,
        collectedKnown = 0,
        unknownSourceItems = 0,
        bySource = {},
        byExpansion = {},
    }

    if (not self.ItemList) or (#self.ItemList == 0) then
        self:BuildItemIndex(true)
    end

    local knownIDKeys = {}
    local knownNameKeysFromIDs = {}
    local trackableIDKeys = {}
    local trackableNoIDNameKeys = {}
    local allTrackableNameKeys = {}
    local collectionExtraNameKeys = {}

    local function addStatRow(sourceType, expansion, collected)
        local sourceKey = sourceType or "unknown"
        stats.bySource[sourceKey] = stats.bySource[sourceKey] or { total = 0, collected = 0 }
        stats.bySource[sourceKey].total = stats.bySource[sourceKey].total + 1
        if collected then
            stats.bySource[sourceKey].collected = stats.bySource[sourceKey].collected + 1
        end

        local expansionKey = expansion or "unknown"
        stats.byExpansion[expansionKey] = stats.byExpansion[expansionKey] or { total = 0, collected = 0 }
        stats.byExpansion[expansionKey].total = stats.byExpansion[expansionKey].total + 1
        if collected then
            stats.byExpansion[expansionKey].collected = stats.byExpansion[expansionKey].collected + 1
        end
    end

    -- Known universe from all item IDs cache.
    for itemID, itemData in pairs(self.allItemCache or {}) do
        if not knownIDKeys[itemID] then
            knownIDKeys[itemID] = true
            stats.knownTotal = stats.knownTotal + 1

            local collected = self:IsItemCollected(itemID, itemData and itemData.name)
            if collected then
                stats.collectedKnown = stats.collectedKnown + 1
            end

            local cachedName = itemData and itemData.name
            if cachedName and cachedName ~= "" then
                local key = self:NormalizeItemName(cachedName)
                if key then
                    knownNameKeysFromIDs[key] = true
                end
            end
        end
    end

    -- Trackable universe from curated/imported item index.
    for _, item in ipairs(self.ItemList or {}) do
        local primary = (item.sources and item.sources[1]) or {}
        local collected = self:IsItemCollected(item.itemID, item.name)
        addStatRow(primary.sourceType or "unknown", primary.expansion, collected)

        local key = self:NormalizeItemName(item.name)
        if key then
            allTrackableNameKeys[key] = true
        end

        if item.itemID then
            if not trackableIDKeys[item.itemID] then
                trackableIDKeys[item.itemID] = true
                stats.trackableTotal = stats.trackableTotal + 1
                if collected then
                    stats.collectedTrackable = stats.collectedTrackable + 1
                end
            end
        elseif key and not trackableNoIDNameKeys[key] then
            trackableNoIDNameKeys[key] = true
            stats.trackableTotal = stats.trackableTotal + 1
            if collected then
                stats.collectedTrackable = stats.collectedTrackable + 1
            end

            -- Source-known no-ID items should still count as known when absent from known ID name set.
            if not knownNameKeysFromIDs[key] then
                stats.knownTotal = stats.knownTotal + 1
                if collected then
                    stats.collectedKnown = stats.collectedKnown + 1
                end
            end
        end
    end

    -- Player-collected names not present in known IDs nor trackable index.
    for nameKey, info in pairs(self.collectionNameCache or {}) do
        if not knownNameKeysFromIDs[nameKey] and not allTrackableNameKeys[nameKey] and not collectionExtraNameKeys[nameKey] then
            collectionExtraNameKeys[nameKey] = true
            stats.knownTotal = stats.knownTotal + 1
            if info and info.collected then
                stats.collectedKnown = stats.collectedKnown + 1
            end

            addStatRow("unknown", nil, info and info.collected)
        end
    end

    stats.unknownSourceItems = math.max(0, stats.knownTotal - stats.trackableTotal)

    -- Legacy fields retained for compatibility.
    stats.totalItems = stats.trackableTotal
    stats.collected = stats.collectedTrackable

    return stats
end


---------------------------------------------------
-- Master Item Database (All Items)
---------------------------------------------------
function HC:ResolveAllItems()
    -- Build a runtime cache of itemID -> name/icon for searching.
    -- Prefer persisted SavedVariables cache so names/icons are instant on login.
    self.allItemCache = self.allItemCache or {}
    local allIDs = {}
    if HC.AllItems and HC.AllItems.IDs then
        for _, itemID in ipairs(HC.AllItems.IDs) do
            allIDs[itemID] = true
        end
    end
    if HC.ImportedAllItems and HC.ImportedAllItems.IDs then
        for _, itemID in ipairs(HC.ImportedAllItems.IDs) do
            allIDs[itemID] = true
        end
    end

    for itemID in pairs(allIDs) do
        if not self.allItemCache[itemID] then
            local cachedName, cachedIcon = self:GetCachedItemInfo(itemID)

            local name = (C_Item and C_Item.GetItemNameByID and C_Item.GetItemNameByID(itemID)) or cachedName
            local icon = (C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(itemID)) or cachedIcon

            self.allItemCache[itemID] = { itemID = itemID, name = name, icon = icon }

            if name or icon then
                self:UpdateItemCache(itemID, name, icon)
            end

            if not name or not icon then
                self:EnsureItemCached(itemID)
            end
        end
    end

    self:BuildItemNameLookup()
end

function HC:GetUnknownItemResult(itemID, itemName)
    local collected = self:IsItemCollected(itemID, itemName or ("Item " .. tostring(itemID)))
    return {
        type = "unknown",
        data = {
            name = itemName or ("Item " .. tostring(itemID)),
            itemID = itemID,
            sources = {},
            waypoint = nil,
        },
        name = itemName or ("Item " .. tostring(itemID)),
        source = "Currently Unknown",
        vendor = nil,
        zone = nil,
        cost = nil,
        expansion = nil,
        faction = nil,
        collected = collected,
    }
end
