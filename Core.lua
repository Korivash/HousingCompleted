---------------------------------------------------
-- Housing Completed - Core.lua
-- Main addon logic and initialization
-- Author: Korivash
---------------------------------------------------
local addonName, HC = ...
_G["HousingCompleted"] = HC

HC.version = "1.3.0"
HC.searchResults = {}
HC.collectionCache = {}

-- Default saved variables
local defaults = {
    minimap = { hide = false },
    showMinimapButton = true,
scale = 1.0,
    windowPos = nil,
    filters = {
        showCollected = true,
        showUncollected = true,
        sourceTypes = {},
        expansions = {},
    },
    lastTab = "all",
}

---------------------------------------------------
-- Initialization
---------------------------------------------------
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")

frame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        HC:Initialize()
    elseif event == "PLAYER_ENTERING_WORLD" then
        C_Timer.After(2, function()
            HC:CacheCollection()
        end)
    end
end)

function HC:Initialize()
    -- Initialize saved variables
    if not HousingCompletedDB then
        HousingCompletedDB = CopyTable(defaults)
    else
        -- Merge defaults for any missing keys
        for k, v in pairs(defaults) do
            if HousingCompletedDB[k] == nil then
                HousingCompletedDB[k] = v
            end
        end
    end
    
    -- Setup minimap button
    self:SetupMinimapButton()

    -- Build item-first index (items -> sources)
    self:BuildItemIndex()
    
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
    self.catalogReady = false
    
    -- Check if Housing Catalog API is available
    if C_HousingCatalog and C_HousingCatalog.GetNumCategories then
        local numCategories = C_HousingCatalog.GetNumCategories(1) or 0
        for catIndex = 1, numCategories do
            local numItems = C_HousingCatalog.GetNumCatalogEntriesInCategory(1, catIndex) or 0
            for itemIndex = 1, numItems do
                local info = C_HousingCatalog.GetCatalogEntryInfoByIndex(1, catIndex, itemIndex)
                if info then
                    self.collectionCache[info.decorID] = {
                        collected = info.isCollected,
                        count = info.count or 0,
                        name = info.name,
                    }
                end
            end
        end
        self.catalogReady = true
    end
end

function HC:IsDecorCollected(decorName)
    -- Check if a decor item is collected by name
    for decorID, info in pairs(self.collectionCache) do
        if info.name and info.name:lower() == decorName:lower() then
            return info.collected, info.count
        end
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

        local item = self.ItemIndex[name]
        if not item then
            item = { name = name, itemID = entry.itemID, sources = {} }
            self.ItemIndex[name] = item
            table.insert(self.ItemList, item)
        end

        if (not item.itemID) and entry.itemID then
            item.itemID = entry.itemID
        end

        table.insert(item.sources, {
            sourceType = entry.sourceType or entry.type or "unknown",
            source = entry.source or entry.achievement or entry.quest or entry.faction,
            vendor = entry.vendor,
            cost = entry.cost,
            zone = entry.zone,
            coords = entry.coords,
            mapID = entry.mapID,
            faction = entry.faction,
            expansion = entry.expansion,
            notes = entry.notes,
            standing = entry.standing,
            profession = entry.profession,
        })
    end

    -- Primary combined table (if present)
    for _, entry in ipairs(HC.DecorItems or {}) do addEntry(entry) end

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
        self:SetWaypoint(wp.x, wp.y, wp.mapID, wp.title)
    else
        print("|cff00ff99Housing Completed|r: No waypoint available for this item.")
    end
end

---------------------------------------------------
-- Search Functions
---------------------------------------------------
function HC:SearchAll(query, filters)
    local results = {}
    local hasQuery = query and query:gsub("%s+", "") ~= ""
    if hasQuery then query = query:lower() end
    filters = filters or {}

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
                primaryType = s.sourceType or "unknown"
                primarySource = s.source
                primaryVendor = s.vendor
                primaryCost = s.cost
                primaryZone = s.zone
                primaryExpansion = s.expansion
                primaryFaction = s.faction
            end
        end

        local matches = nameMatch or sourceMatch
        if matches then
            -- Source-level filters: if ANY source passes, keep the item
            local passes = true

            if filters.sourceTypes and next(filters.sourceTypes) then
                passes = false
                for _, s in ipairs(item.sources or {}) do
                    if filters.sourceTypes[s.sourceType or "unknown"] then
                        passes = true
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
                    if f and f ~= "neutral" and f ~= filters.faction then
                        passes = false
                        break
                    end
                end
            end

            if passes then
                local wpMapID, wpX, wpY, wpTitle = self:GetBestWaypointForItem(item)
                local collected = self:IsDecorCollected(name)
                table.insert(results, {
                    type = primaryType or "unknown",
                    data = {
                        name = item.name,
                        itemID = item.itemID,
                        sources = item.sources,
                        waypoint = (wpMapID and wpX and wpY) and { mapID = wpMapID, x = wpX, y = wpY, title = wpTitle } or nil,
                    },
                    name = item.name,
                    source = primarySource,
                    vendor = primaryVendor,
                    zone = primaryZone,
                    cost = primaryCost,
                    expansion = primaryExpansion,
                    faction = primaryFaction,
                    collected = collected,
                })
            end
        end
    end

    -- Search vendors (as results) - keep vendor browsing available
    for _, vendor in ipairs(HC.Vendors or {}) do
        local matches = (not hasQuery) or
            (vendor.name and vendor.name:lower():find(query, 1, true)) or
            (vendor.zone and vendor.zone:lower():find(query, 1, true))
        if matches and self:PassesFilters(vendor, filters, "vendor") then
            table.insert(results, {
                type = "vendor",
                data = vendor,
                name = vendor.name,
                zone = vendor.zone,
                expansion = vendor.expansion,
                vendor = vendor.name,
                source = vendor.zone,
                cost = nil,
                collected = false,
            })
        end
    end

    return results
end

function HC:PassesFilters(item, filters, sourceType)
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
        if itemFaction and itemFaction ~= "neutral" and itemFaction ~= filters.faction then
            return false
        end
    end
    
    return true
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
-- Waypoint Functions
---------------------------------------------------
function HC:SetWaypoint(x, y, mapID, title)
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

    -- Clear existing SuperTrack content first (helps routing refresh)
    if C_SuperTrack and C_SuperTrack.ClearSuperTrackedContent then
        C_SuperTrack.ClearSuperTrackedContent()
    end
    if C_Map and C_Map.ClearUserWaypoint then
        C_Map.ClearUserWaypoint()
    end

    local waypoint = UiMapPoint.CreateFromCoordinates(mapID, nx, ny)
    C_Map.SetUserWaypoint(waypoint)
    C_SuperTrack.SetSuperTrackedUserWaypoint(true)

    if WorldMapFrame and WorldMapFrame.RefreshAllDataProviders then
        WorldMapFrame:RefreshAllDataProviders()
    end

    if title then
        print("|cff00ff99Housing Completed|r: Waypoint set for " .. title)
    else
        print("|cff00ff99Housing Completed|r: Waypoint set.")
    end
end

function HC:ClearWaypoint()
    C_Map.ClearUserWaypoint()
    C_SuperTrack.SetSuperTrackedUserWaypoint(false)
end


---------------------------------------------------
-- Utility Functions
---------------------------------------------------
function HC:GetSourceTypeInfo(sourceType)
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
        bySource = {},
        byExpansion = {},
    }
    
    -- Count all items
    local allItems = {}
    
    for _, item in ipairs(HC.AchievementItems or {}) do
        allItems[item.name] = { type = "achievement", data = item }
    end
    for _, item in ipairs(HC.QuestItems or {}) do
        allItems[item.name] = { type = "quest", data = item }
    end
    for _, item in ipairs(HC.ReputationItems or {}) do
        allItems[item.name] = { type = "reputation", data = item }
    end
    for _, item in ipairs(HC.ProfessionItems or {}) do
        allItems[item.name] = { type = "profession", data = item }
    end
    
    for name, item in pairs(allItems) do
        stats.totalItems = stats.totalItems + 1
        
        local collected = self:IsDecorCollected(name)
        if collected then
            stats.collected = stats.collected + 1
        end
        
        -- Count by source
        local sourceType = item.type
        stats.bySource[sourceType] = stats.bySource[sourceType] or { total = 0, collected = 0 }
        stats.bySource[sourceType].total = stats.bySource[sourceType].total + 1
        if collected then
            stats.bySource[sourceType].collected = stats.bySource[sourceType].collected + 1
        end
        
        -- Count by expansion
        local expansion = item.data.expansion or "unknown"
        stats.byExpansion[expansion] = stats.byExpansion[expansion] or { total = 0, collected = 0 }
        stats.byExpansion[expansion].total = stats.byExpansion[expansion].total + 1
        if collected then
            stats.byExpansion[expansion].collected = stats.byExpansion[expansion].collected + 1
        end
    end
    
    return stats
end
