---------------------------------------------------
-- Housing Completed - Arrow.lua
-- On-screen directional arrow for waypoint navigation
-- Author: Korivash
---------------------------------------------------
local addonName, HC = ...

-- Arrow frame reference
local arrowFrame = nil
local UPDATE_INTERVAL = 0.05

---------------------------------------------------
-- Arrow Creation
---------------------------------------------------
function HC:CreateArrow()
    if arrowFrame then return arrowFrame end
    
    -- Main frame
    arrowFrame = CreateFrame("Frame", "HousingCompletedArrow", UIParent, "BackdropTemplate")
    arrowFrame:SetSize(80, 80)
    arrowFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 200)
    arrowFrame:SetMovable(true)
    arrowFrame:EnableMouse(true)
    arrowFrame:RegisterForDrag("LeftButton")
    arrowFrame:SetClampedToScreen(true)
    arrowFrame:SetFrameStrata("HIGH")
    
    -- Background
    arrowFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    arrowFrame:SetBackdropColor(0, 0, 0, 0.7)
    arrowFrame:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    
    -- Arrow texture
    local arrow = arrowFrame:CreateTexture(nil, "ARTWORK")
    arrow:SetSize(48, 48)
    arrow:SetPoint("TOP", 0, -5)
    arrow:SetTexture("Interface\\Minimap\\MinimapArrow")
    arrow:SetVertexColor(0.2, 0.9, 0.5, 1)
    arrowFrame.arrow = arrow
    
    -- Title text
    local title = arrowFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    title:SetPoint("TOP", arrow, "BOTTOM", 0, -2)
    title:SetTextColor(1, 1, 1)
    title:SetText("")
    title:SetWidth(100)
    title:SetJustifyH("CENTER")
    arrowFrame.title = title
    
    -- Distance text
    local distance = arrowFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    distance:SetPoint("TOP", title, "BOTTOM", 0, -1)
    distance:SetTextColor(0.2, 0.9, 0.5)
    distance:SetText("")
    arrowFrame.distance = distance
    
    -- Close button
    local closeBtn = CreateFrame("Button", nil, arrowFrame, "UIPanelCloseButton")
    closeBtn:SetSize(20, 20)
    closeBtn:SetPoint("TOPRIGHT", 3, 3)
    closeBtn:SetScript("OnClick", function()
        HC:HideArrow()
    end)
    
    -- Drag handlers
    arrowFrame:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)
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

---------------------------------------------------
-- Arrow Update
---------------------------------------------------
function HC:UpdateArrow()
    if not arrowFrame or not arrowFrame:IsShown() then return end
    if not self.currentWaypoint then return end
    
    local wp = self.currentWaypoint
    local playerMapID = C_Map.GetBestMapForUnit("player")
    if not playerMapID then return end
    
    local playerPos = C_Map.GetPlayerMapPosition(playerMapID, "player")
    if not playerPos then return end
    
    local playerX, playerY = playerPos:GetXY()
    
    -- Different map check
    if playerMapID ~= wp.mapID then
        arrowFrame.arrow:SetVertexColor(0.7, 0.7, 0.3)
        arrowFrame.distance:SetText("Different Zone")
        arrowFrame.distance:SetTextColor(0.7, 0.7, 0.3)
        arrowFrame.arrow:SetRotation(0)
        return
    end
    
    -- Calculate direction
    local dx = wp.x - playerX
    local dy = wp.y - playerY
    
    -- Distance (rough estimate - about 1000 yards per 1.0 map unit)
    local dist = math.sqrt(dx*dx + dy*dy) * 1000
    
    -- Angle calculation
    local angle = math.atan2(dx, dy)
    local facing = GetPlayerFacing()
    if facing then
        angle = angle - facing
    end
    
    arrowFrame.arrow:SetRotation(angle)
    
    -- Update distance text
    if dist < 15 then
        arrowFrame.distance:SetText("Arrived!")
        arrowFrame.distance:SetTextColor(0.2, 1, 0.2)
        arrowFrame.arrow:SetVertexColor(0.2, 1, 0.2)
        -- Pulse effect
        local pulse = (math.sin(GetTime() * 5) + 1) / 2
        arrowFrame.arrow:SetAlpha(0.5 + pulse * 0.5)
    else
        arrowFrame.arrow:SetAlpha(1)
        if dist < 1000 then
            arrowFrame.distance:SetText(string.format("%.0f yds", dist))
        else
            arrowFrame.distance:SetText(string.format("%.1f km", dist / 1000))
        end
        
        -- Color by distance
        if dist < 100 then
            arrowFrame.arrow:SetVertexColor(0.2, 0.9, 0.5)
            arrowFrame.distance:SetTextColor(0.2, 0.9, 0.5)
        elseif dist < 500 then
            arrowFrame.arrow:SetVertexColor(0.9, 0.9, 0.2)
            arrowFrame.distance:SetTextColor(0.9, 0.9, 0.2)
        else
            arrowFrame.arrow:SetVertexColor(0.9, 0.5, 0.2)
            arrowFrame.distance:SetTextColor(0.9, 0.5, 0.2)
        end
    end
end

---------------------------------------------------
-- Arrow Control
---------------------------------------------------
function HC:ShowArrow(x, y, mapID, name)
    if HousingCompletedDB.showArrow == false then return end
    
    if not arrowFrame then
        self:CreateArrow()
    end
    
    -- Store waypoint (coordinates are 0-100, convert to 0-1)
    self.currentWaypoint = {
        x = x / 100,
        y = y / 100,
        mapID = mapID,
        name = name or "Waypoint"
    }
    
    arrowFrame.title:SetText(self.currentWaypoint.name)
    arrowFrame:Show()
    
    print("|cff00ff99Housing Completed|r: Arrow pointing to " .. self.currentWaypoint.name)
end

function HC:HideArrow()
    if arrowFrame then
        arrowFrame:Hide()
    end
    print("|cff00ff99Housing Completed|r: Arrow hidden")
end

function HC:ToggleArrow()
    if arrowFrame and arrowFrame:IsShown() then
        self:HideArrow()
    elseif self.currentWaypoint then
        if not arrowFrame then self:CreateArrow() end
        arrowFrame:Show()
        print("|cff00ff99Housing Completed|r: Arrow shown")
    else
        print("|cff00ff99Housing Completed|r: No waypoint set. Click a waypoint button in /hc first.")
    end
end

function HC:HasWaypoint()
    return self.currentWaypoint ~= nil
end
