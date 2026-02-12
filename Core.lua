---------------------------------------------------
-- Housing Completed - Core.lua
-- Main addon logic and initialization
-- Author: Korivash
---------------------------------------------------
local addonName, HC = ...
_G["HousingCompleted"] = HC

HC.version = "1.2.0"
HC.searchResults = {}
HC.collectionCache = {}

-- Default saved variables
local defaults = {
    minimap = { hide = false },
    showMinimapButton = true,
    waypointSystem = "tomtom",
    showArrow = true,
    arrowPos = nil,
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
        elseif cmd == "arrow" then
            HC:ToggleArrow()
        elseif cmd == "arrow hide" or cmd == "arrow off" then
            HC:HideArrow()
        elseif cmd == "arrow show" or cmd == "arrow on" then
            if HC:HasWaypoint() then
                if not HC.arrowFrame then HC:CreateArrow() end
                HC.arrowFrame:Show()
                print("|cff00ff99Housing Completed|r: Arrow shown")
            else
                print("|cff00ff99Housing Completed|r: No waypoint set. Click a waypoint button in /hc first.")
            end
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
-- Search Functions
---------------------------------------------------
function HC:SearchAll(query, filters)
    local results = {}
    local hasQuery = query and query:gsub("%s+", "") ~= ""
    if hasQuery then
        query = query:lower()
    end
    
    filters = filters or {}
    
    -- Search vendors
    for _, vendor in ipairs(HC.Vendors or {}) do
        local matches = not hasQuery or 
                       (vendor.name and vendor.name:lower():find(query, 1, true)) or
                       (vendor.zone and vendor.zone:lower():find(query, 1, true))
        
        if matches and self:PassesFilters(vendor, filters, "vendor") then
            table.insert(results, {
                type = "vendor",
                data = vendor,
                name = vendor.name,
                zone = vendor.zone,
                expansion = vendor.expansion,
            })
        end
    end
    
    -- Search achievement items
    for _, item in ipairs(HC.AchievementItems or {}) do
        local matches = not hasQuery or
                       (item.name and item.name:lower():find(query, 1, true)) or
                       (item.achievement and item.achievement:lower():find(query, 1, true))
        
        if matches and self:PassesFilters(item, filters, "achievement") then
            local collected = self:IsDecorCollected(item.name)
            table.insert(results, {
                type = "achievement",
                data = item,
                name = item.name,
                source = item.achievement,
                vendor = item.vendor,
                zone = item.zone,
                cost = item.cost,
                collected = collected,
            })
        end
    end
    
    -- Search quest items
    for _, item in ipairs(HC.QuestItems or {}) do
        local matches = not hasQuery or
                       (item.name and item.name:lower():find(query, 1, true)) or
                       (item.quest and item.quest:lower():find(query, 1, true))
        
        if matches and self:PassesFilters(item, filters, "quest") then
            local collected = self:IsDecorCollected(item.name)
            table.insert(results, {
                type = "quest",
                data = item,
                name = item.name,
                source = item.quest,
                vendor = item.vendor,
                zone = item.zone,
                cost = item.cost,
                expansion = item.expansion,
                collected = collected,
            })
        end
    end
    
    -- Search reputation items
    for _, item in ipairs(HC.ReputationItems or {}) do
        local matches = not hasQuery or
                       (item.name and item.name:lower():find(query, 1, true)) or
                       (item.faction and item.faction:lower():find(query, 1, true))
        
        if matches and self:PassesFilters(item, filters, "reputation") then
            local collected = self:IsDecorCollected(item.name)
            table.insert(results, {
                type = "reputation",
                data = item,
                name = item.name,
                source = item.faction .. " - " .. item.standing,
                vendor = item.vendor,
                zone = item.zone,
                cost = item.cost,
                collected = collected,
            })
        end
    end
    
    -- Search profession items
    for _, item in ipairs(HC.ProfessionItems or {}) do
        local matches = not hasQuery or
                       (item.name and item.name:lower():find(query, 1, true)) or
                       (item.profession and item.profession:lower():find(query, 1, true))
        
        if matches and self:PassesFilters(item, filters, "profession") then
            local collected = self:IsDecorCollected(item.name)
            table.insert(results, {
                type = "profession",
                data = item,
                name = item.name,
                source = item.profession,
                expansion = item.expansion,
                skill = item.skill,
                collected = collected,
            })
        end
    end
    
    self.searchResults = results
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
    
    local system = HousingCompletedDB.waypointSystem or "tomtom"
    local useTomTom = (system == "tomtom" or system == "both") and TomTom
    local useBlizzard = (system == "blizzard" or system == "both")
    
    if useTomTom then
        TomTom:AddWaypoint(mapID, x / 100, y / 100, {
            title = title or "Housing Vendor",
            persistent = false,
            minimap = true,
            world = true,
        })
        print("|cff00ff99Housing Completed|r: TomTom waypoint set for " .. (title or "location"))
    end
    
    if useBlizzard then
        C_Map.SetUserWaypoint(UiMapPoint.CreateFromCoordinates(mapID, x / 100, y / 100))
        C_SuperTrack.SetSuperTrackedUserWaypoint(true)
        print("|cff00ff99Housing Completed|r: Map pin set for " .. (title or "location"))
    end
    
    if not useTomTom and not useBlizzard then
        -- Fallback to Blizzard
        C_Map.SetUserWaypoint(UiMapPoint.CreateFromCoordinates(mapID, x / 100, y / 100))
        C_SuperTrack.SetSuperTrackedUserWaypoint(true)
        print("|cff00ff99Housing Completed|r: Map pin set for " .. (title or "location"))
    end
    
    -- Show arrow (Arrow.lua checks showArrow setting)
    self:ShowArrow(x, y, mapID, title)
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
