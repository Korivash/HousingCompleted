---------------------------------------------------
-- Housing Completed - Arrow.lua
-- Cross-zone directional arrow navigation
-- Author: Korivash
---------------------------------------------------
local addonName, HC = ...

local arrowFrame = nil
local UPDATE_INTERVAL = 0.05

-- Portal/travel locations for smart routing
local PORTAL_HUBS = {
    -- Stormwind portals
    { name = "Stormwind Portal Room", mapID = 84, x = 49.0, y = 87.0, faction = "alliance", connections = {"orgrimmar", "dornogal", "valdrakken", "oribos", "boralus"} },
    -- Orgrimmar portals
    { name = "Orgrimmar Portal Room", mapID = 85, x = 55.0, y = 12.0, faction = "horde", connections = {"stormwind", "dornogal", "valdrakken", "oribos", "dazaralor"} },
    -- Valdrakken
    { name = "Valdrakken", mapID = 2112, x = 59.0, y = 35.0, faction = "neutral", connections = {"stormwind", "orgrimmar", "dornogal"} },
    -- Dornogal
    { name = "Dornogal", mapID = 2339, x = 47.0, y = 50.0, faction = "neutral", connections = {"stormwind", "orgrimmar", "valdrakken"} },
}

-- Map ID to zone name mapping for common zones
local MAP_NAMES = {
    [84] = "Stormwind",
    [85] = "Orgrimmar",
    [87] = "Ironforge",
    [88] = "Thunder Bluff",
    [89] = "Darnassus",
    [90] = "Undercity",
    [103] = "Exodar",
    [110] = "Silvermoon",
    [111] = "Shattrath",
    [125] = "Dalaran",
    [627] = "Dalaran (Legion)",
    [2112] = "Valdrakken",
    [2339] = "Dornogal",
}

function HC:CreateArrow()
    if arrowFrame then return arrowFrame end
    
    arrowFrame = CreateFrame("Frame", "HousingCompletedArrow", UIParent, "BackdropTemplate")
    arrowFrame:SetSize(64, 64)
    arrowFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 200)
    arrowFrame:SetMovable(true)
    arrowFrame:EnableMouse(true)
    arrowFrame:RegisterForDrag("LeftButton")
    arrowFrame:SetClampedToScreen(true)
    arrowFrame:SetFrameStrata("HIGH")
    
    arrowFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    arrowFrame:SetBackdropColor(0, 0, 0, 0.6)
    arrowFrame:SetBackdropBorderColor(0.2, 0.8, 0.5, 0.8)
    
    -- Arrow texture - larger and cleaner
    local arrow = arrowFrame:CreateTexture(nil, "ARTWORK")
    arrow:SetSize(56, 56)
    arrow:SetPoint("CENTER", 0, 0)
    arrow:SetTexture("Interface\\Minimap\\MinimapArrow")
    arrow:SetVertexColor(0.2, 0.9, 0.5, 1)
    arrowFrame.arrow = arrow
    
    -- Close button (small X in corner)
    local closeBtn = CreateFrame("Button", nil, arrowFrame)
    closeBtn:SetSize(14, 14)
    closeBtn:SetPoint("TOPRIGHT", 2, 2)
    closeBtn:SetNormalTexture("Interface\\Buttons\\UI-StopButton")
    closeBtn:SetAlpha(0.5)
    closeBtn:SetScript("OnEnter", function(self) self:SetAlpha(1) end)
    closeBtn:SetScript("OnLeave", function(self) self:SetAlpha(0.5) end)
    closeBtn:SetScript("OnClick", function() HC:HideArrow() end)
    
    -- Drag handlers
    arrowFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    arrowFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, _, x, y = self:GetPoint()
        HousingCompletedDB.arrowPos = {point, x, y}
    end)
    
    -- Restore position
    if HousingCompletedDB and HousingCompletedDB.arrowPos then
        local pos = HousingCompletedDB.arrowPos
        arrowFrame:ClearAllPoints()
        arrowFrame:SetPoint(pos[1], UIParent, "CENTER", pos[2], pos[3])
    end
    
    -- Update timer
    local elapsed = 0
    arrowFrame:SetScript("OnUpdate", function(self, delta)
        elapsed = elapsed + delta
        if elapsed >= UPDATE_INTERVAL then
            elapsed = 0
            HC:UpdateArrow()
        end
    end)
    
    arrowFrame:Hide()
    self.arrowFrame = arrowFrame
    return arrowFrame
end

function HC:GetPlayerContinent()
    local mapID = C_Map.GetBestMapForUnit("player")
    if not mapID then return nil end
    
    local info = C_Map.GetMapInfo(mapID)
    while info and info.parentMapID and info.parentMapID > 0 do
        local parentInfo = C_Map.GetMapInfo(info.parentMapID)
        if parentInfo and parentInfo.mapType == Enum.UIMapType.Continent then
            return info.parentMapID
        end
        info = parentInfo
    end
    return nil
end

function HC:GetZoneName(mapID)
    if MAP_NAMES[mapID] then return MAP_NAMES[mapID] end
    local info = C_Map.GetMapInfo(mapID)
    return info and info.name or "Unknown"
end

function HC:UpdateArrow()
    if not arrowFrame or not arrowFrame:IsShown() then return end
    if not self.currentWaypoint then return end
    
    local wp = self.currentWaypoint
    local playerMapID = C_Map.GetBestMapForUnit("player")
    if not playerMapID then return end
    
    local playerPos = C_Map.GetPlayerMapPosition(playerMapID, "player")
    if not playerPos then 
        -- Probably in an instance, just point forward
        arrowFrame.arrow:SetRotation(0)
        arrowFrame.arrow:SetVertexColor(0.5, 0.5, 0.5)
        return
    end
    
    local playerX, playerY = playerPos:GetXY()
    
    -- Same map - direct navigation
    if playerMapID == wp.mapID then
        local dx = wp.x - playerX
        local dy = wp.y - playerY
        local dist = math.sqrt(dx*dx + dy*dy) * 1000
        
        local angle = math.atan2(dx, dy)
        local facing = GetPlayerFacing()
        if facing then angle = angle - facing end
        
        arrowFrame.arrow:SetRotation(angle)
        
        -- Color by distance
        if dist < 15 then
            arrowFrame.arrow:SetVertexColor(0.2, 1, 0.2)
            local pulse = (math.sin(GetTime() * 5) + 1) / 2
            arrowFrame.arrow:SetAlpha(0.5 + pulse * 0.5)
        else
            arrowFrame.arrow:SetAlpha(1)
            if dist < 100 then
                arrowFrame.arrow:SetVertexColor(0.2, 0.9, 0.5)
            elseif dist < 300 then
                arrowFrame.arrow:SetVertexColor(0.9, 0.9, 0.2)
            else
                arrowFrame.arrow:SetVertexColor(0.9, 0.5, 0.2)
            end
        end
    else
        -- Different zone - point towards best exit/portal
        -- For now, just use world coordinates approach
        local targetWorldPos = self:GetWorldPosition(wp.mapID, wp.x, wp.y)
        local playerWorldPos = self:GetWorldPosition(playerMapID, playerX, playerY)
        
        if targetWorldPos and playerWorldPos then
            local dx = targetWorldPos.x - playerWorldPos.x
            local dy = targetWorldPos.y - playerWorldPos.y
            
            local angle = math.atan2(dx, -dy) -- Note: world Y is inverted
            local facing = GetPlayerFacing()
            if facing then angle = angle - facing end
            
            arrowFrame.arrow:SetRotation(angle)
            arrowFrame.arrow:SetVertexColor(0.4, 0.7, 1) -- Blue for cross-zone
            arrowFrame.arrow:SetAlpha(1)
        else
            -- Can't determine direction, point forward
            arrowFrame.arrow:SetRotation(0)
            arrowFrame.arrow:SetVertexColor(0.5, 0.5, 0.5)
        end
    end
end

function HC:GetWorldPosition(mapID, x, y)
    -- Convert map position to world position
    local _, worldPos = C_Map.GetWorldPosFromMapPos(mapID, CreateVector2D(x, y))
    if worldPos then
        return { x = worldPos.x, y = worldPos.y }
    end
    return nil
end

function HC:ShowArrow(x, y, mapID, name)
    if HousingCompletedDB.showArrow == false then return end
    
    if not arrowFrame then
        self:CreateArrow()
    end
    
    self.currentWaypoint = {
        x = x / 100,
        y = y / 100,
        mapID = mapID,
        name = name or "Waypoint"
    }
    
    arrowFrame:Show()
end

function HC:HideArrow()
    if arrowFrame then
        arrowFrame:Hide()
    end
end

function HC:ToggleArrow()
    if arrowFrame and arrowFrame:IsShown() then
        self:HideArrow()
    elseif self.currentWaypoint then
        if not arrowFrame then self:CreateArrow() end
        arrowFrame:Show()
    else
        print("|cff00ff99Housing Completed|r: No waypoint set. Use /hc and click a waypoint button.")
    end
end

function HC:HasWaypoint()
    return self.currentWaypoint ~= nil
end
