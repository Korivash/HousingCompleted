---------------------------------------------------
-- Housing Completed - Arrow.lua
-- On-screen directional arrow for waypoint navigation
-- Author: Korivash
---------------------------------------------------
local addonName, HC = ...

-- Arrow state
HC.Arrow = {
    active = false,
    targetX = 0,
    targetY = 0,
    targetMapID = 0,
    targetName = "",
}

-- Arrow frame
local arrowFrame = nil
local arrowTexture = nil
local distanceText = nil
local titleText = nil
local arriveThreshold = 15 -- yards

-- Arrow texture coordinates for rotation (8 directions)
local ARROW_COORDS = {
    -- Each entry: {left, right, top, bottom} for the texture
    -- We'll use a simple rotation approach instead
}

---------------------------------------------------
-- Arrow Creation
---------------------------------------------------
function HC:CreateArrow()
    if arrowFrame then return end
    
    -- Main frame
    arrowFrame = CreateFrame("Frame", "HousingCompletedArrow", UIParent)
    arrowFrame:SetSize(56, 70)
    arrowFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 200)
    arrowFrame:SetMovable(true)
    arrowFrame:EnableMouse(true)
    arrowFrame:RegisterForDrag("LeftButton")
    arrowFrame:SetClampedToScreen(true)
    
    arrowFrame:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)
    arrowFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        -- Save position
        local point, _, _, x, y = self:GetPoint()
        HousingCompletedDB.arrowPos = {point, x, y}
    end)
    
    -- Background
    local bg = arrowFrame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0, 0.5)
    arrowFrame.bg = bg
    
    -- Arrow texture (we'll create a simple arrow using the built-in raid marker)
    arrowTexture = arrowFrame:CreateTexture(nil, "ARTWORK")
    arrowTexture:SetSize(42, 42)
    arrowTexture:SetPoint("TOP", 0, -5)
    -- Use a navigation arrow texture
    arrowTexture:SetTexture("Interface\\Minimap\\MinimapArrow")
    arrowTexture:SetVertexColor(0.2, 0.9, 0.5, 1) -- Green tint
    arrowFrame.arrow = arrowTexture
    
    -- Title text (target name)
    titleText = arrowFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    titleText:SetPoint("TOP", arrowTexture, "BOTTOM", 0, -2)
    titleText:SetTextColor(1, 1, 1)
    titleText:SetText("")
    titleText:SetWidth(100)
    titleText:SetWordWrap(false)
    arrowFrame.title = titleText
    
    -- Distance text
    distanceText = arrowFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    distanceText:SetPoint("TOP", titleText, "BOTTOM", 0, -2)
    distanceText:SetTextColor(0.2, 0.9, 0.5)
    distanceText:SetText("0 yds")
    arrowFrame.distance = distanceText
    
    -- Close button
    local closeBtn = CreateFrame("Button", nil, arrowFrame)
    closeBtn:SetSize(16, 16)
    closeBtn:SetPoint("TOPRIGHT", 2, 2)
    closeBtn:SetNormalTexture("Interface\\Buttons\\UI-StopButton")
    closeBtn:SetHighlightTexture("Interface\\Buttons\\UI-StopButton", "ADD")
    closeBtn:SetScript("OnClick", function()
        HC:HideArrow()
    end)
    closeBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine("Close Arrow")
        GameTooltip:AddLine("Click to hide the navigation arrow", 0.7, 0.7, 0.7, true)
        GameTooltip:Show()
    end)
    closeBtn:SetScript("OnLeave", GameTooltip_Hide)
    
    -- Restore saved position
    if HousingCompletedDB and HousingCompletedDB.arrowPos then
        local pos = HousingCompletedDB.arrowPos
        arrowFrame:ClearAllPoints()
        arrowFrame:SetPoint(pos[1], UIParent, "CENTER", pos[2], pos[3])
    end
    
    -- Update script
    arrowFrame:SetScript("OnUpdate", function(self, elapsed)
        HC:UpdateArrow(elapsed)
    end)
    
    arrowFrame:Hide()
    self.arrowFrame = arrowFrame
end

---------------------------------------------------
-- Arrow Update Logic
---------------------------------------------------
local updateTimer = 0
local UPDATE_INTERVAL = 0.05 -- 20 FPS for smooth rotation

function HC:UpdateArrow(elapsed)
    if not self.Arrow.active then return end
    
    updateTimer = updateTimer + elapsed
    if updateTimer < UPDATE_INTERVAL then return end
    updateTimer = 0
    
    local playerMapID = C_Map.GetBestMapForUnit("player")
    if not playerMapID then return end
    
    local playerPos = C_Map.GetPlayerMapPosition(playerMapID, "player")
    if not playerPos then return end
    
    local playerX, playerY = playerPos:GetXY()
    
    -- Check if we're on the same map
    if playerMapID ~= self.Arrow.targetMapID then
        -- Different map - show a "?" or generic direction
        arrowTexture:SetVertexColor(0.7, 0.7, 0.3) -- Yellow for different zone
        distanceText:SetText("Different Zone")
        distanceText:SetTextColor(0.7, 0.7, 0.3)
        return
    end
    
    -- Calculate direction and distance
    local dx = self.Arrow.targetX - playerX
    local dy = self.Arrow.targetY - playerY
    
    -- Convert map coordinates to approximate yards (rough estimate)
    -- This varies by zone, but roughly 1000 yards per 1.0 map coordinate
    local mapInfo = C_Map.GetMapInfo(playerMapID)
    local distanceYards = math.sqrt(dx*dx + dy*dy) * 1000
    
    -- Calculate angle
    local angle = math.atan2(dx, dy)
    
    -- Get player facing
    local playerFacing = GetPlayerFacing()
    if playerFacing then
        angle = angle - playerFacing
    end
    
    -- Rotate arrow texture
    -- WoW textures rotate around center, SetRotation uses radians
    arrowTexture:SetRotation(angle)
    
    -- Update distance text
    if distanceYards < 1000 then
        distanceText:SetText(string.format("%.0f yds", distanceYards))
    else
        distanceText:SetText(string.format("%.1f km", distanceYards / 1000))
    end
    
    -- Color based on distance
    if distanceYards < arriveThreshold then
        -- Arrived!
        arrowTexture:SetVertexColor(0.2, 1, 0.2) -- Bright green
        distanceText:SetText("Arrived!")
        distanceText:SetTextColor(0.2, 1, 0.2)
        
        -- Pulse effect when arrived
        local pulse = (math.sin(GetTime() * 5) + 1) / 2
        arrowTexture:SetAlpha(0.5 + pulse * 0.5)
    elseif distanceYards < 100 then
        arrowTexture:SetVertexColor(0.2, 0.9, 0.5) -- Green - close
        distanceText:SetTextColor(0.2, 0.9, 0.5)
        arrowTexture:SetAlpha(1)
    elseif distanceYards < 500 then
        arrowTexture:SetVertexColor(0.9, 0.9, 0.2) -- Yellow - medium
        distanceText:SetTextColor(0.9, 0.9, 0.2)
        arrowTexture:SetAlpha(1)
    else
        arrowTexture:SetVertexColor(0.9, 0.5, 0.2) -- Orange - far
        distanceText:SetTextColor(0.9, 0.5, 0.2)
        arrowTexture:SetAlpha(1)
    end
end

---------------------------------------------------
-- Arrow Control Functions
---------------------------------------------------
function HC:ShowArrow(x, y, mapID, name)
    if not arrowFrame then
        self:CreateArrow()
    end
    
    -- Store target
    self.Arrow.targetX = x / 100 -- Convert from percentage to 0-1
    self.Arrow.targetY = y / 100
    self.Arrow.targetMapID = mapID
    self.Arrow.targetName = name or "Waypoint"
    self.Arrow.active = true
    
    -- Update title
    titleText:SetText(self.Arrow.targetName)
    
    -- Show frame
    arrowFrame:Show()
    
    print("|cff00ff99Housing Completed|r: Arrow pointing to " .. self.Arrow.targetName)
end

function HC:HideArrow()
    self.Arrow.active = false
    if arrowFrame then
        arrowFrame:Hide()
    end
    print("|cff00ff99Housing Completed|r: Arrow hidden")
end

function HC:ToggleArrow()
    if arrowFrame and arrowFrame:IsShown() then
        self:HideArrow()
    elseif self.Arrow.targetMapID > 0 then
        arrowFrame:Show()
        self.Arrow.active = true
    end
end

function HC:IsArrowActive()
    return self.Arrow.active and arrowFrame and arrowFrame:IsShown()
end

---------------------------------------------------
-- Integration with SetWaypoint
---------------------------------------------------
-- Override the original SetWaypoint to also show arrow
local originalSetWaypoint = HC.SetWaypoint
function HC:SetWaypoint(x, y, mapID, title)
    -- Call original if it exists in Core.lua
    if not x or not y or not mapID then
        print("|cff00ff99Housing Completed|r: No coordinates available.")
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
    end
    
    if useBlizzard then
        C_Map.SetUserWaypoint(UiMapPoint.CreateFromCoordinates(mapID, x / 100, y / 100))
        C_SuperTrack.SetSuperTrackedUserWaypoint(true)
    end
    
    if not useTomTom and not useBlizzard then
        C_Map.SetUserWaypoint(UiMapPoint.CreateFromCoordinates(mapID, x / 100, y / 100))
        C_SuperTrack.SetSuperTrackedUserWaypoint(true)
    end
    
    -- Always show our arrow
    if HousingCompletedDB.showArrow ~= false then
        self:ShowArrow(x, y, mapID, title)
    end
    
    print("|cff00ff99Housing Completed|r: Waypoint set for " .. (title or "location"))
end

---------------------------------------------------
-- Slash Command Extension
---------------------------------------------------
-- Add arrow commands
local function HandleArrowCommand(msg)
    local cmd = msg:lower():trim()
    if cmd == "arrow" or cmd == "arrow toggle" then
        HC:ToggleArrow()
    elseif cmd == "arrow hide" or cmd == "arrow off" then
        HC:HideArrow()
    elseif cmd == "arrow show" or cmd == "arrow on" then
        if HC.Arrow.targetMapID > 0 then
            HC.arrowFrame:Show()
            HC.Arrow.active = true
        else
            print("|cff00ff99Housing Completed|r: No waypoint set. Set a waypoint first.")
        end
    end
end

-- Hook into main slash command handler
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, addon)
    if addon == addonName then
        -- Extend slash command
        local originalHandler = SlashCmdList["HOUSINGCOMPLETED"]
        SlashCmdList["HOUSINGCOMPLETED"] = function(msg)
            if msg:lower():find("^arrow") then
                HandleArrowCommand(msg)
            elseif originalHandler then
                originalHandler(msg)
            end
        end
        
        -- Initialize arrow on load
        HC:CreateArrow()
    end
end)
