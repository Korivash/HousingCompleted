---------------------------------------------------
-- Housing Completed - UI.lua
-- Modern interface with Blizzard item/NPC previews
-- Author: Korivash
---------------------------------------------------
local addonName, HC = ...

local FRAME_WIDTH = 1100
local FRAME_HEIGHT = 700
local SIDEBAR_WIDTH = 220
local PREVIEW_WIDTH = 280
local HEADER_HEIGHT = 70
local ITEM_HEIGHT = 60
local ITEMS_PER_PAGE = 8

local COLORS = {
    background = {0.05, 0.05, 0.08, 0.98},
    headerBg = {0.08, 0.08, 0.12, 1},
    sidebar = {0.04, 0.04, 0.06, 1},
    preview = {0.06, 0.06, 0.09, 1},
    accent = {0.2, 0.9, 0.6, 1},
    accentAlt = {0.4, 0.8, 1, 1},
    gold = {1, 0.82, 0, 1},
    text = {1, 1, 1, 1},
    textMuted = {0.5, 0.5, 0.55, 1},
    textDim = {0.35, 0.35, 0.4, 1},
    collected = {0.2, 0.9, 0.4, 1},
    row = {0.08, 0.08, 0.12, 0.8},
    rowHover = {0.12, 0.12, 0.18, 1},
    rowSelected = {0.15, 0.25, 0.2, 1},
}

local currentPage = 1
local totalPages = 1
local currentResults = {}
local currentTab = "all"
local selectedItem = nil

local function GetButtonText(button)
    return button.Text or button.text
end

local function SetButtonText(button, text, r, g, b)
    local textObj = GetButtonText(button)
    if textObj then
        textObj:SetText(text)
        if r then textObj:SetTextColor(r, g, b) end
    end
end

local function CreateSearchBox(parent, width)
    local container = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    container:SetSize(width, 32)
    container:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    container:SetBackdropColor(0.1, 0.1, 0.15, 1)
    container:SetBackdropBorderColor(0.25, 0.25, 0.3, 1)
    
    local icon = container:CreateTexture(nil, "ARTWORK")
    icon:SetSize(16, 16)
    icon:SetPoint("LEFT", 10, 0)
    icon:SetTexture("Interface\\Common\\UI-Searchbox-Icon")
    icon:SetVertexColor(0.6, 0.6, 0.6)
    
    local editBox = CreateFrame("EditBox", nil, container)
    editBox:SetPoint("LEFT", icon, "RIGHT", 8, 0)
    editBox:SetPoint("RIGHT", -10, 0)
    editBox:SetHeight(20)
    editBox:SetFontObject(ChatFontNormal)
    editBox:SetAutoFocus(false)
    editBox:SetTextColor(1, 1, 1)
    
    local placeholder = editBox:CreateFontString(nil, "ARTWORK", "GameFontDisable")
    placeholder:SetPoint("LEFT", 0, 0)
    placeholder:SetText("Search...")
    placeholder:SetTextColor(0.4, 0.4, 0.45)
    
    editBox:SetScript("OnTextChanged", function(self)
        placeholder:SetShown(self:GetText() == "")
    end)
    editBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    
    container.editBox = editBox
    container.placeholder = placeholder
    return container
end

function HC:CreateUI()
    if self.mainFrame then return end
    
    local frame = CreateFrame("Frame", "HousingCompletedFrame", UIParent, "BackdropTemplate")
    frame:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
    frame:SetPoint("CENTER")
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 2,
    })
    frame:SetBackdropColor(unpack(COLORS.background))
    frame:SetBackdropBorderColor(0.15, 0.15, 0.2, 1)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetClampedToScreen(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, _, x, y = self:GetPoint()
        HousingCompletedDB.windowPos = {point, "CENTER", x, y}
    end)
    
    if HousingCompletedDB and HousingCompletedDB.windowPos and HousingCompletedDB.windowPos[1] then
        local pos = HousingCompletedDB.windowPos
        frame:ClearAllPoints()
        frame:SetPoint(pos[1], UIParent, pos[2], pos[3] or 0, pos[4] or 0)
    end
    
    frame:SetScale(HousingCompletedDB.scale or 1.0)
    frame:Hide()
    self.mainFrame = frame
    
    self:CreateHeader(frame)
    self:CreateSidebar(frame)
    self:CreatePreviewPanel(frame)
    self:CreateContent(frame)
    self:CreateSettingsPanel(frame)
    
    tinsert(UISpecialFrames, "HousingCompletedFrame")
end

function HC:CreateHeader(parent)
    local header = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    header:SetPoint("TOPLEFT", 0, 0)
    header:SetPoint("TOPRIGHT", 0, 0)
    header:SetHeight(HEADER_HEIGHT)
    header:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
    header:SetBackdropColor(unpack(COLORS.headerBg))
    
    local title = header:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("LEFT", 20, 8)
    title:SetText("|cff00ff99Housing|r |cffffffffCompleted|r")
    
    local version = header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    version:SetPoint("LEFT", title, "RIGHT", 10, 0)
    version:SetText("v" .. HC.version)
    version:SetTextColor(0.5, 0.5, 0.5)
    
    local stats = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    stats:SetPoint("LEFT", 20, -15)
    stats:SetText("Loading...")
    stats:SetTextColor(unpack(COLORS.textMuted))
    self.statsText = stats
    
    local closeBtn = CreateFrame("Button", nil, header, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", -5, -5)
    closeBtn:SetScript("OnClick", function() parent:Hide() end)
    
    local settingsBtn = CreateFrame("Button", nil, header)
    settingsBtn:SetSize(24, 24)
    settingsBtn:SetPoint("RIGHT", closeBtn, "LEFT", -5, 0)
    settingsBtn:SetNormalTexture("Interface\\Icons\\INV_Misc_Gear_01")
    settingsBtn:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    settingsBtn:SetScript("OnClick", function() HC:ToggleSettings() end)
    
    self.header = header
end

function HC:CreateSidebar(parent)
    local sidebar = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    sidebar:SetPoint("TOPLEFT", 0, -HEADER_HEIGHT)
    sidebar:SetPoint("BOTTOMLEFT", 0, 0)
    sidebar:SetWidth(SIDEBAR_WIDTH)
    sidebar:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
    sidebar:SetBackdropColor(unpack(COLORS.sidebar))
    
    local y = -15
    
    local searchBox = CreateSearchBox(sidebar, SIDEBAR_WIDTH - 20)
    searchBox:SetPoint("TOP", 0, y)
    searchBox.editBox:SetScript("OnEnterPressed", function(self)
        HC:DoSearch()
        self:ClearFocus()
    end)
    searchBox.editBox:SetScript("OnTextChanged", function(self, userInput)
        searchBox.placeholder:SetShown(self:GetText() == "")
        if userInput then C_Timer.After(0.3, function() HC:DoSearch() end) end
    end)
    self.searchBox = searchBox.editBox
    y = y - 50
    
    local tabLabel = sidebar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    tabLabel:SetPoint("TOPLEFT", 15, y)
    tabLabel:SetText("CATEGORIES")
    tabLabel:SetTextColor(unpack(COLORS.accentAlt))
    y = y - 22
    
    -- Category tabs with correct icons
    local tabs = {
        { id = "all", name = "All Items", icon = "Interface\\Icons\\INV_Misc_Bag_10" },
        { id = "vendor", name = "Vendors", icon = "Interface\\Icons\\INV_Misc_Coin_01" },
        { id = "achievement", name = "Achievements", icon = "Interface\\Icons\\Achievement_General_100kQuests" },
        { id = "quest", name = "Quests", icon = "Interface\\Icons\\INV_Misc_Book_07" },
        { id = "reputation", name = "Reputation", icon = "Interface\\Icons\\Achievement_Reputation_08" },
        { id = "profession", name = "Professions", icon = "Interface\\Icons\\INV_Misc_Note_01" },
        { id = "auction", name = "Auction House", icon = "Interface\\Icons\\INV_Misc_Coin_02" },
    }
    
    self.tabButtons = {}
    for _, tabInfo in ipairs(tabs) do
        local btn = CreateFrame("Button", nil, sidebar)
        btn:SetSize(SIDEBAR_WIDTH - 20, 26)
        btn:SetPoint("TOP", 0, y)
        btn.tabID = tabInfo.id
        
        local bg = btn:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(0, 0, 0, 0)
        btn.bg = bg
        
        local icon = btn:CreateTexture(nil, "ARTWORK")
        icon:SetSize(18, 18)
        icon:SetPoint("LEFT", 10, 0)
        icon:SetTexture(tabInfo.icon)
        
        local label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        label:SetPoint("LEFT", icon, "RIGHT", 6, 0)
        label:SetText(tabInfo.name)
        label:SetTextColor(0.75, 0.75, 0.75)
        btn.label = label
        
        btn:SetScript("OnEnter", function(self)
            if currentTab ~= self.tabID then self.bg:SetColorTexture(0.15, 0.15, 0.2, 1) end
        end)
        btn:SetScript("OnLeave", function(self)
            if currentTab ~= self.tabID then self.bg:SetColorTexture(0, 0, 0, 0) end
        end)
        btn:SetScript("OnClick", function(self)
            currentTab = self.tabID
            HC:UpdateTabButtons()
            HC:DoSearch()
        end)
        
        self.tabButtons[tabInfo.id] = btn
        y = y - 26
    end
    y = y - 12
    
    local divider = sidebar:CreateTexture(nil, "ARTWORK")
    divider:SetSize(SIDEBAR_WIDTH - 30, 1)
    divider:SetPoint("TOP", 0, y)
    divider:SetColorTexture(0.2, 0.2, 0.25, 1)
    y = y - 15
    
    local filterLabel = sidebar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    filterLabel:SetPoint("TOPLEFT", 15, y)
    filterLabel:SetText("FILTERS")
    filterLabel:SetTextColor(unpack(COLORS.accentAlt))
    y = y - 22
    
    local collectedCb = CreateFrame("CheckButton", nil, sidebar, "UICheckButtonTemplate")
    collectedCb:SetPoint("TOPLEFT", 10, y)
    collectedCb:SetSize(24, 24)
    SetButtonText(collectedCb, "Collected", 0.7, 0.7, 0.7)
    collectedCb:SetChecked(true)
    collectedCb:SetScript("OnClick", function() HC:DoSearch() end)
    self.collectedCb = collectedCb
    y = y - 24
    
    local uncollectedCb = CreateFrame("CheckButton", nil, sidebar, "UICheckButtonTemplate")
    uncollectedCb:SetPoint("TOPLEFT", 10, y)
    uncollectedCb:SetSize(24, 24)
    SetButtonText(uncollectedCb, "Uncollected", 0.7, 0.7, 0.7)
    uncollectedCb:SetChecked(true)
    uncollectedCb:SetScript("OnClick", function() HC:DoSearch() end)
    self.uncollectedCb = uncollectedCb
    y = y - 35
    
    local progressLabel = sidebar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    progressLabel:SetPoint("TOPLEFT", 15, y)
    progressLabel:SetText("PROGRESS")
    progressLabel:SetTextColor(unpack(COLORS.accentAlt))
    y = y - 20
    
    local progressText = sidebar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    progressText:SetPoint("TOPLEFT", 15, y)
    progressText:SetText("0 / 0")
    progressText:SetTextColor(0.7, 0.7, 0.7)
    self.progressText = progressText
    
    self.sidebar = sidebar
end

function HC:CreateContent(parent)
    local content = CreateFrame("Frame", nil, parent)
    content:SetPoint("TOPLEFT", SIDEBAR_WIDTH, -HEADER_HEIGHT)
    content:SetPoint("BOTTOMRIGHT", -PREVIEW_WIDTH, 0)
    
    local resultsFrame = CreateFrame("Frame", nil, content, "BackdropTemplate")
    resultsFrame:SetPoint("TOPLEFT", 15, -15)
    resultsFrame:SetPoint("BOTTOMRIGHT", -15, 55)
    resultsFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    resultsFrame:SetBackdropColor(0.06, 0.06, 0.09, 1)
    resultsFrame:SetBackdropBorderColor(0.15, 0.15, 0.2, 1)
    
    self.resultRows = {}
    for i = 1, ITEMS_PER_PAGE do
        local row = self:CreateResultRow(resultsFrame, i)
        row:SetPoint("TOPLEFT", 5, -5 - (i-1) * ITEM_HEIGHT)
        row:SetPoint("TOPRIGHT", -5, -5 - (i-1) * ITEM_HEIGHT)
        self.resultRows[i] = row
    end
    
    self.resultsFrame = resultsFrame
    
    local pagination = CreateFrame("Frame", nil, content)
    pagination:SetPoint("BOTTOMLEFT", 15, 15)
    pagination:SetPoint("BOTTOMRIGHT", -15, 15)
    pagination:SetHeight(35)
    
    local prevBtn = CreateFrame("Button", nil, pagination, "UIPanelButtonTemplate")
    prevBtn:SetSize(70, 26)
    prevBtn:SetPoint("LEFT", 0, 0)
    prevBtn:SetText("< Prev")
    prevBtn:SetScript("OnClick", function()
        if currentPage > 1 then currentPage = currentPage - 1; HC:UpdateResults() end
    end)
    self.prevBtn = prevBtn
    
    local nextBtn = CreateFrame("Button", nil, pagination, "UIPanelButtonTemplate")
    nextBtn:SetSize(70, 26)
    nextBtn:SetPoint("RIGHT", 0, 0)
    nextBtn:SetText("Next >")
    nextBtn:SetScript("OnClick", function()
        if currentPage < totalPages then currentPage = currentPage + 1; HC:UpdateResults() end
    end)
    self.nextBtn = nextBtn
    
    local pageText = pagination:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    pageText:SetPoint("CENTER")
    pageText:SetText("Page 1 of 1")
    pageText:SetTextColor(unpack(COLORS.textMuted))
    self.pageText = pageText
    
    local statusText = pagination:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    statusText:SetPoint("LEFT", prevBtn, "RIGHT", 10, 0)
    statusText:SetText("0 results")
    statusText:SetTextColor(unpack(COLORS.textDim))
    self.statusText = statusText
    
    self.content = content
end

function HC:CreateResultRow(parent, index)
    local row = CreateFrame("Button", nil, parent, "BackdropTemplate")
    row:SetHeight(ITEM_HEIGHT - 5)
    row:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
    row:SetBackdropColor(unpack(COLORS.row))
    
    row:SetScript("OnEnter", function(self)
        if selectedItem ~= self.itemData then
            self:SetBackdropColor(unpack(COLORS.rowHover))
        end
        -- Show item tooltip if we have itemID
        if self.itemData and self.itemData.data and self.itemData.data.itemID then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetItemByID(self.itemData.data.itemID)
            GameTooltip:Show()
        end
    end)
    row:SetScript("OnLeave", function(self)
        if selectedItem ~= self.itemData then
            self:SetBackdropColor(unpack(COLORS.row))
        end
        GameTooltip:Hide()
    end)
    row:SetScript("OnClick", function(self)
        selectedItem = self.itemData
        HC:UpdatePreview(self.itemData)
        HC:UpdateRowSelection()
    end)
    
    local typeIcon = row:CreateTexture(nil, "ARTWORK")
    typeIcon:SetSize(36, 36)
    typeIcon:SetPoint("LEFT", 10, 0)
    row.typeIcon = typeIcon
    
    local collectedIcon = row:CreateTexture(nil, "OVERLAY")
    collectedIcon:SetSize(16, 16)
    collectedIcon:SetPoint("TOPLEFT", typeIcon, "TOPRIGHT", -8, 4)
    collectedIcon:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
    collectedIcon:Hide()
    row.collectedIcon = collectedIcon
    
    local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameText:SetPoint("TOPLEFT", typeIcon, "TOPRIGHT", 10, -2)
    nameText:SetPoint("RIGHT", -150, 0)
    nameText:SetJustifyH("LEFT")
    row.nameText = nameText
    
    local sourceText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    sourceText:SetPoint("TOPLEFT", nameText, "BOTTOMLEFT", 0, -2)
    sourceText:SetPoint("RIGHT", -150, 0)
    sourceText:SetJustifyH("LEFT")
    sourceText:SetTextColor(unpack(COLORS.textMuted))
    row.sourceText = sourceText
    
    local infoText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    infoText:SetPoint("TOPLEFT", sourceText, "BOTTOMLEFT", 0, -2)
    infoText:SetPoint("RIGHT", -150, 0)
    infoText:SetJustifyH("LEFT")
    infoText:SetTextColor(unpack(COLORS.textDim))
    row.infoText = infoText
    
    local waypointBtn = CreateFrame("Button", nil, row)
    waypointBtn:SetSize(28, 28)
    waypointBtn:SetPoint("RIGHT", -10, 0)
    waypointBtn:SetNormalTexture("Interface\\Minimap\\Tracking\\TrivialQuests")
    waypointBtn:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    waypointBtn:SetScript("OnClick", function()
        if row.vendorData and row.vendorData.x and row.vendorData.y and row.vendorData.mapID then
            HC:SetWaypoint(row.vendorData.x, row.vendorData.y, row.vendorData.mapID, row.vendorData.name)
        elseif row.vendorName then
            local vendor = HC:GetVendorByName(row.vendorName)
            if vendor and vendor.x and vendor.y and vendor.mapID then
                HC:SetWaypoint(vendor.x, vendor.y, vendor.mapID, vendor.name)
            end
        end
    end)
    row.waypointBtn = waypointBtn
    
    local typeBadge = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    typeBadge:SetPoint("RIGHT", waypointBtn, "LEFT", -10, 0)
    row.typeBadge = typeBadge
    
    row:Hide()
    return row
end

function HC:CreatePreviewPanel(parent)
    local preview = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    preview:SetPoint("TOPRIGHT", 0, -HEADER_HEIGHT)
    preview:SetPoint("BOTTOMRIGHT", 0, 0)
    preview:SetWidth(PREVIEW_WIDTH)
    preview:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
    preview:SetBackdropColor(unpack(COLORS.preview))
    
    local y = -15
    
    local title = preview:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    title:SetPoint("TOPLEFT", 15, y)
    title:SetText("PREVIEW")
    title:SetTextColor(unpack(COLORS.accentAlt))
    y = y - 25
    
    -- Model container
    local modelContainer = CreateFrame("Frame", nil, preview, "BackdropTemplate")
    modelContainer:SetSize(PREVIEW_WIDTH - 30, 180)
    modelContainer:SetPoint("TOP", 0, y)
    modelContainer:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
    modelContainer:SetBackdropColor(0.03, 0.03, 0.05, 1)
    
    -- Use ModelScene for better model display
    local modelFrame = CreateFrame("ModelScene", nil, modelContainer, "WrappedAndUnwrappedModelScene")
    if not modelFrame then
        -- Fallback to PlayerModel if ModelScene unavailable
        modelFrame = CreateFrame("PlayerModel", nil, modelContainer)
    end
    modelFrame:SetAllPoints()
    modelFrame:EnableMouse(true)
    modelFrame:EnableMouseWheel(true)
    
    local isDragging = false
    local lastX = 0
    modelFrame:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            isDragging = true
            lastX = GetCursorPosition()
        end
    end)
    modelFrame:SetScript("OnMouseUp", function() isDragging = false end)
    modelFrame:SetScript("OnUpdate", function(self)
        if isDragging then
            local x = GetCursorPosition()
            if self.SetFacing then
                local facing = self:GetFacing() or 0
                self:SetFacing(facing + (x - lastX) * 0.02)
            end
            lastX = x
        end
    end)
    
    self.modelFrame = modelFrame
    self.modelContainer = modelContainer
    y = y - 190
    
    -- Item name
    local itemName = preview:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    itemName:SetPoint("TOPLEFT", 15, y)
    itemName:SetPoint("TOPRIGHT", -15, y)
    itemName:SetJustifyH("CENTER")
    itemName:SetText("Select an item")
    itemName:SetTextColor(1, 1, 1)
    self.previewName = itemName
    y = y - 22
    
    -- Source type badge
    local sourceType = preview:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    sourceType:SetPoint("TOP", 0, y)
    sourceType:SetText("")
    self.previewSourceType = sourceType
    y = y - 25
    
    -- Details frame
    local detailsFrame = CreateFrame("Frame", nil, preview)
    detailsFrame:SetPoint("TOPLEFT", 15, y)
    detailsFrame:SetPoint("TOPRIGHT", -15, y)
    detailsFrame:SetHeight(180)
    
    local dy = 0
    
    -- Vendor
    local vendorLabel = detailsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    vendorLabel:SetPoint("TOPLEFT", 0, dy)
    vendorLabel:SetText("|cff888888Vendor:|r")
    local vendorValue = detailsFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    vendorValue:SetPoint("TOPLEFT", 55, dy)
    vendorValue:SetPoint("RIGHT", 0, 0)
    vendorValue:SetJustifyH("LEFT")
    vendorValue:SetText("-")
    self.previewVendor = vendorValue
    dy = dy - 16
    
    -- Location
    local locLabel = detailsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    locLabel:SetPoint("TOPLEFT", 0, dy)
    locLabel:SetText("|cff888888Location:|r")
    local locValue = detailsFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    locValue:SetPoint("TOPLEFT", 55, dy)
    locValue:SetPoint("RIGHT", 0, 0)
    locValue:SetJustifyH("LEFT")
    locValue:SetText("-")
    self.previewLocation = locValue
    dy = dy - 16
    
    -- Cost
    local costLabel = detailsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    costLabel:SetPoint("TOPLEFT", 0, dy)
    costLabel:SetText("|cff888888Cost:|r")
    local costValue = detailsFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    costValue:SetPoint("TOPLEFT", 55, dy)
    costValue:SetPoint("RIGHT", 0, 0)
    costValue:SetJustifyH("LEFT")
    costValue:SetText("-")
    self.previewCost = costValue
    dy = dy - 20
    
    -- Reputation section
    local repHeader = detailsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    repHeader:SetPoint("TOPLEFT", 0, dy)
    repHeader:SetText("|cffaa88ffReputation Required:|r")
    repHeader:Hide()
    self.previewRepHeader = repHeader
    dy = dy - 14
    
    local repFaction = detailsFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    repFaction:SetPoint("TOPLEFT", 10, dy)
    repFaction:SetPoint("RIGHT", 0, 0)
    repFaction:SetJustifyH("LEFT")
    repFaction:SetText("")
    repFaction:Hide()
    self.previewRepFaction = repFaction
    dy = dy - 14
    
    local repStanding = detailsFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    repStanding:SetPoint("TOPLEFT", 10, dy)
    repStanding:SetText("")
    repStanding:Hide()
    self.previewRepStanding = repStanding
    
    self.detailsFrame = detailsFrame
    
    -- Waypoint button at bottom
    local wpBtn = CreateFrame("Button", nil, preview, "UIPanelButtonTemplate")
    wpBtn:SetSize(PREVIEW_WIDTH - 30, 28)
    wpBtn:SetPoint("BOTTOM", 0, 15)
    wpBtn:SetText("Set Waypoint")
    wpBtn:SetScript("OnClick", function()
        if selectedItem then
            local data = selectedItem.data
            if selectedItem.type == "vendor" and data and data.x and data.y and data.mapID then
                HC:SetWaypoint(data.x, data.y, data.mapID, data.name)
            elseif selectedItem.vendor then
                local v = HC:GetVendorByName(selectedItem.vendor)
                if v and v.x and v.y and v.mapID then
                    HC:SetWaypoint(v.x, v.y, v.mapID, v.name)
                end
            end
        end
    end)
    self.previewWaypointBtn = wpBtn
    
    self.previewPanel = preview
end

function HC:UpdatePreview(data)
    if not self.previewName then return end
    
    -- Reset all
    self.previewRepHeader:Hide()
    self.previewRepFaction:Hide()
    self.previewRepStanding:Hide()
    
    if not data then
        self.previewName:SetText("Select an item")
        self.previewName:SetTextColor(0.6, 0.6, 0.6)
        self.previewSourceType:SetText("")
        self.previewVendor:SetText("-")
        self.previewLocation:SetText("-")
        self.previewCost:SetText("-")
        if self.modelFrame.ClearModel then self.modelFrame:ClearModel() end
        return
    end
    
    -- Name
    self.previewName:SetText(data.name or "Unknown")
    if data.collected then
        self.previewName:SetTextColor(unpack(COLORS.collected))
    else
        self.previewName:SetTextColor(1, 1, 1)
    end
    
    -- Source type
    local sourceInfo = self:GetSourceTypeInfo(data.type)
    self.previewSourceType:SetText(sourceInfo.name)
    self.previewSourceType:SetTextColor(unpack(sourceInfo.color))
    
    -- Vendor
    if data.type == "vendor" and data.data then
        self.previewVendor:SetText(data.data.name or "-")
    else
        self.previewVendor:SetText(data.vendor or "-")
    end
    
    -- Location
    local loc = data.zone or ""
    if data.data and data.data.subzone then
        loc = loc .. ", " .. data.data.subzone
    end
    if data.data and data.data.x and data.data.y then
        loc = loc .. string.format(" (%.1f, %.1f)", data.data.x, data.data.y)
    end
    self.previewLocation:SetText(loc ~= "" and loc or "-")
    
    -- Cost
    if data.cost then
        self.previewCost:SetText("|cffffd700" .. data.cost .. "|r")
    else
        self.previewCost:SetText("-")
    end
    
    -- Reputation details
    if data.type == "reputation" and data.data then
        self.previewRepHeader:Show()
        self.previewRepFaction:Show()
        self.previewRepStanding:Show()
        
        self.previewRepFaction:SetText(data.data.faction or "Unknown Faction")
        
        local standing = data.data.standing or "Unknown"
        local standingColors = {
            ["Exalted"] = {0.2, 1, 0.2},
            ["Revered"] = {0.2, 0.8, 1},
            ["Honored"] = {0.4, 0.6, 1},
            ["Friendly"] = {0.2, 0.9, 0.2},
            ["Neutral"] = {1, 1, 0.2},
        }
        local color = standingColors[standing] or {0.7, 0.7, 0.7}
        self.previewRepStanding:SetText(standing .. " Required")
        self.previewRepStanding:SetTextColor(unpack(color))
    end
    
    -- Model - try to show NPC for vendors
    if self.modelFrame then
        if data.type == "vendor" and data.data and data.data.id then
            if self.modelFrame.SetCreature then
                self.modelFrame:SetCreature(data.data.id)
                self.modelFrame:SetPosition(0, 0, 0)
                self.modelFrame:SetFacing(0)
            end
        else
            if self.modelFrame.ClearModel then
                self.modelFrame:ClearModel()
            end
        end
    end
end

function HC:UpdateRowSelection()
    for _, row in ipairs(self.resultRows) do
        if row.itemData == selectedItem then
            row:SetBackdropColor(unpack(COLORS.rowSelected))
        else
            row:SetBackdropColor(unpack(COLORS.row))
        end
    end
end

function HC:CreateSettingsPanel(parent)
    local settings = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    settings:SetPoint("TOPLEFT", SIDEBAR_WIDTH, -HEADER_HEIGHT)
    settings:SetPoint("BOTTOMRIGHT", 0, 0)
    settings:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
    settings:SetBackdropColor(unpack(COLORS.background))
    settings:Hide()
    
    local y = -20
    
    local title = settings:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 20, y)
    title:SetText("Settings")
    title:SetTextColor(unpack(COLORS.accentAlt))
    y = y - 40
    
    local waypointLabel = settings:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    waypointLabel:SetPoint("TOPLEFT", 20, y)
    waypointLabel:SetText("Waypoint System:")
    y = y - 28
    
    local waypointOptions = {"tomtom", "blizzard", "both"}
    local waypointLabels = {"TomTom Only", "Blizzard Only", "Both"}
    
    for i, opt in ipairs(waypointOptions) do
        local radio = CreateFrame("CheckButton", nil, settings, "UIRadioButtonTemplate")
        radio:SetPoint("TOPLEFT", 30, y)
        SetButtonText(radio, waypointLabels[i], 0.8, 0.8, 0.8)
        radio:SetChecked((HousingCompletedDB.waypointSystem or "tomtom") == opt)
        radio:SetScript("OnClick", function()
            HousingCompletedDB.waypointSystem = opt
            HC:UpdateWaypointRadios()
        end)
        radio.option = opt
        self["waypointRadio" .. i] = radio
        y = y - 24
    end
    y = y - 15
    
    local scaleLabel = settings:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    scaleLabel:SetPoint("TOPLEFT", 20, y)
    scaleLabel:SetText("UI Scale:")
    y = y - 28
    
    local scaleSlider = CreateFrame("Slider", nil, settings, "OptionsSliderTemplate")
    scaleSlider:SetPoint("TOPLEFT", 30, y)
    scaleSlider:SetWidth(180)
    scaleSlider:SetMinMaxValues(0.5, 1.5)
    scaleSlider:SetValueStep(0.05)
    scaleSlider:SetValue(HousingCompletedDB.scale or 1.0)
    scaleSlider.Low:SetText("50%")
    scaleSlider.High:SetText("150%")
    scaleSlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value * 20 + 0.5) / 20
        HousingCompletedDB.scale = value
        local text = GetButtonText(self)
        if text then text:SetText(string.format("%.0f%%", value * 100)) end
        if HC.mainFrame then HC.mainFrame:SetScale(value) end
    end)
    y = y - 45
    
    local minimapCb = CreateFrame("CheckButton", nil, settings, "UICheckButtonTemplate")
    minimapCb:SetPoint("TOPLEFT", 20, y)
    SetButtonText(minimapCb, "Show Minimap Button", 0.8, 0.8, 0.8)
    minimapCb:SetChecked(HousingCompletedDB.showMinimapButton ~= false)
    minimapCb:SetScript("OnClick", function(self)
        HousingCompletedDB.showMinimapButton = self:GetChecked()
        local LibDBIcon = LibStub("LibDBIcon-1.0", true)
        if LibDBIcon then
            if self:GetChecked() then LibDBIcon:Show("HousingCompleted")
            else LibDBIcon:Hide("HousingCompleted") end
        end
    end)
    y = y - 26
    
    local arrowCb = CreateFrame("CheckButton", nil, settings, "UICheckButtonTemplate")
    arrowCb:SetPoint("TOPLEFT", 20, y)
    SetButtonText(arrowCb, "Show Navigation Arrow", 0.8, 0.8, 0.8)
    arrowCb:SetChecked(HousingCompletedDB.showArrow ~= false)
    arrowCb:SetScript("OnClick", function(self)
        HousingCompletedDB.showArrow = self:GetChecked()
        if not self:GetChecked() and HC.HideArrow then HC:HideArrow() end
    end)
    y = y - 45
    
    local backBtn = CreateFrame("Button", nil, settings, "UIPanelButtonTemplate")
    backBtn:SetSize(100, 28)
    backBtn:SetPoint("BOTTOMLEFT", 20, 20)
    backBtn:SetText("Back")
    backBtn:SetScript("OnClick", function() HC:ToggleSettings() end)
    
    self.settingsPanel = settings
end

function HC:UpdateWaypointRadios()
    local opt = HousingCompletedDB.waypointSystem or "tomtom"
    for i = 1, 3 do
        local radio = self["waypointRadio" .. i]
        if radio then radio:SetChecked(radio.option == opt) end
    end
end

function HC:DoSearch()
    local query = self.searchBox and self.searchBox:GetText() or ""
    local filters = {
        showCollected = self.collectedCb and self.collectedCb:GetChecked(),
        showUncollected = self.uncollectedCb and self.uncollectedCb:GetChecked(),
        faction = self:GetPlayerFaction(),
    }
    if currentTab ~= "all" then 
        filters.sourceTypes = { [currentTab] = true } 
    end
    
    local results = self:SearchAll(query, filters)
    local filtered = {}
    for _, r in ipairs(results) do
        local show = true
        if r.collected and not filters.showCollected then show = false end
        if not r.collected and not filters.showUncollected then show = false end
        if show then table.insert(filtered, r) end
    end
    
    currentResults = filtered
    currentPage = 1
    totalPages = math.max(1, math.ceil(#currentResults / ITEMS_PER_PAGE))
    selectedItem = nil
    
    self:UpdateResults()
    self:UpdateStats()
    self:UpdatePreview(nil)
end

function HC:UpdateResults()
    for i = 1, ITEMS_PER_PAGE do
        if self.resultRows[i] then self.resultRows[i]:Hide() end
    end
    
    local startIdx = (currentPage - 1) * ITEMS_PER_PAGE + 1
    local endIdx = math.min(startIdx + ITEMS_PER_PAGE - 1, #currentResults)
    
    for i = startIdx, endIdx do
        local rowIndex = i - startIdx + 1
        local row = self.resultRows[rowIndex]
        local data = currentResults[i]
        
        if row and data then
            row.itemData = data
            
            -- Get icon based on source type and profession
            local sourceInfo = self:GetSourceTypeInfo(data.type)
            local icon = sourceInfo.icon
            
            -- Use profession-specific icon
            if data.type == "profession" and data.data and data.data.profession then
                local profIcon = HC.ProfessionIcons and HC.ProfessionIcons[data.data.profession:lower()]
                if profIcon then icon = profIcon end
            end
            
            row.typeIcon:SetTexture(icon)
            
            row.nameText:SetText(data.name or "Unknown")
            if data.collected then
                row.nameText:SetTextColor(unpack(COLORS.collected))
            else
                row.nameText:SetTextColor(1, 1, 1)
            end
            row.collectedIcon:SetShown(data.collected)
            
            local sourceText = data.source or ""
            if data.type == "vendor" and data.data then
                sourceText = data.zone or ""
                if data.data.subzone then sourceText = sourceText .. " - " .. data.data.subzone end
            elseif data.type == "reputation" and data.data then
                sourceText = (data.data.faction or "") .. " (" .. (data.data.standing or "") .. ")"
            end
            row.sourceText:SetText(sourceText)
            row.sourceText:SetTextColor(unpack(sourceInfo.color))
            
            local infoText = ""
            if data.cost then infoText = "|cffffd700" .. data.cost .. "|r" end
            if data.vendor then
                if infoText ~= "" then infoText = infoText .. " - " end
                infoText = infoText .. data.vendor
            end
            row.infoText:SetText(infoText)
            
            row.typeBadge:SetText(sourceInfo.name)
            row.typeBadge:SetTextColor(unpack(sourceInfo.color))
            
            row.vendorData = data.type == "vendor" and data.data or nil
            row.vendorName = data.vendor
            
            local hasCoords = (data.type == "vendor" and data.data and data.data.x) or 
                              (data.vendor and HC:GetVendorByName(data.vendor))
            row.waypointBtn:SetEnabled(hasCoords ~= nil)
            row.waypointBtn:SetAlpha(hasCoords and 1 or 0.3)
            
            row:SetBackdropColor(unpack(COLORS.row))
            row:Show()
        end
    end
    
    if self.pageText then
        self.pageText:SetText(string.format("Page %d of %d", currentPage, totalPages))
    end
    if self.prevBtn then self.prevBtn:SetEnabled(currentPage > 1) end
    if self.nextBtn then self.nextBtn:SetEnabled(currentPage < totalPages) end
    if self.statusText then self.statusText:SetText(string.format("%d results", #currentResults)) end
end

function HC:UpdateTabButtons()
    for tabID, btn in pairs(self.tabButtons) do
        if tabID == currentTab then
            btn.bg:SetColorTexture(0.1, 0.3, 0.2, 1)
            btn.label:SetTextColor(unpack(COLORS.accent))
        else
            btn.bg:SetColorTexture(0, 0, 0, 0)
            btn.label:SetTextColor(0.7, 0.7, 0.7)
        end
    end
end

function HC:UpdateStats()
    local stats = self:GetStatistics()
    if self.statsText then
        local pct = stats.totalItems > 0 and math.floor((stats.collected / stats.totalItems) * 100) or 0
        self.statsText:SetText(string.format("Collection: %d / %d (%d%%)", stats.collected, stats.totalItems, pct))
    end
    if self.progressText then
        self.progressText:SetText(string.format("Collected: %d / %d", stats.collected, stats.totalItems))
    end
end

function HC:ToggleUI()
    if not self.mainFrame then self:CreateUI() end
    if self.mainFrame:IsShown() then
        self.mainFrame:Hide()
    else
        self.mainFrame:Show()
        if self.settingsPanel then self.settingsPanel:Hide() end
        if self.content then self.content:Show() end
        if self.previewPanel then self.previewPanel:Show() end
        self:UpdateTabButtons()
        self:DoSearch()
    end
end

function HC:ToggleSettings()
    if not self.settingsPanel then return end
    if self.settingsPanel:IsShown() then
        self.settingsPanel:Hide()
        if self.content then self.content:Show() end
        if self.previewPanel then self.previewPanel:Show() end
    else
        self.settingsPanel:Show()
        if self.content then self.content:Hide() end
        if self.previewPanel then self.previewPanel:Hide() end
    end
end

function HC:OpenSettings()
    if not self.mainFrame then self:CreateUI() end
    self.mainFrame:Show()
    if self.settingsPanel then self.settingsPanel:Show() end
    if self.content then self.content:Hide() end
    if self.previewPanel then self.previewPanel:Hide() end
end
