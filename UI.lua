---------------------------------------------------
-- Housing Completed - UI.lua
-- Modern interface with Blizzard item/NPC previews
-- Author: Korivash
---------------------------------------------------
local addonName, HC = ...

local FRAME_WIDTH = 1480
local FRAME_HEIGHT = 860
local SIDEBAR_WIDTH = 260
local PREVIEW_WIDTH = 360
local HEADER_HEIGHT = 86
local ITEM_HEIGHT = 58
local ITEMS_PER_PAGE = 10

local COLORS = {
    background = {0.07, 0.055, 0.035, 0.98},
    headerBg = {0.12, 0.085, 0.05, 1},
    sidebar = {0.09, 0.065, 0.04, 1},
    preview = {0.08, 0.06, 0.04, 1},
    accent = {0.98, 0.80, 0.38, 1},
    accentAlt = {0.93, 0.72, 0.30, 1},
    gold = {1, 0.82, 0, 1},
    text = {1, 1, 1, 1},
    textMuted = {0.76, 0.69, 0.57, 1},
    textDim = {0.58, 0.50, 0.40, 1},
    collected = {0.56, 0.95, 0.54, 1},
    row = {0.13, 0.09, 0.06, 0.86},
    rowHover = {0.18, 0.12, 0.08, 1},
    rowSelected = {0.23, 0.16, 0.09, 1},
    border = {0.34, 0.24, 0.12, 1},
}

local currentPage = 1
local totalPages = 1
local currentResults = {}
local currentTab = "all"
local currentItemCategory = "all"
local selectedItem = nil

local function EscapeCSV(value)
    if value == nil then return "" end
    local s = tostring(value)
    s = s:gsub('"', '""')
    if s:find("[,\n\"]") then
        s = '"' .. s .. '"'
    end
    return s
end

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
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    frame:SetBackdropColor(unpack(COLORS.background))
    frame:SetBackdropBorderColor(unpack(COLORS.border))
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

    local vignetteTop = frame:CreateTexture(nil, "BACKGROUND")
    vignetteTop:SetPoint("TOPLEFT", 2, -2)
    vignetteTop:SetPoint("TOPRIGHT", -2, -2)
    vignetteTop:SetHeight(220)
    vignetteTop:SetTexture("Interface\\Buttons\\WHITE8x8")
    if vignetteTop.SetGradientAlpha then
        vignetteTop:SetGradientAlpha("VERTICAL", 0.24, 0.17, 0.09, 0.45, 0.24, 0.17, 0.09, 0.02)
    else
        vignetteTop:SetVertexColor(0.24, 0.17, 0.09, 0.22)
    end

    local vignetteBottom = frame:CreateTexture(nil, "BACKGROUND")
    vignetteBottom:SetPoint("BOTTOMLEFT", 2, 2)
    vignetteBottom:SetPoint("BOTTOMRIGHT", -2, 2)
    vignetteBottom:SetHeight(180)
    vignetteBottom:SetTexture("Interface\\Buttons\\WHITE8x8")
    if vignetteBottom.SetGradientAlpha then
        vignetteBottom:SetGradientAlpha("VERTICAL", 0.18, 0.12, 0.06, 0.02, 0.18, 0.12, 0.06, 0.35)
    else
        vignetteBottom:SetVertexColor(0.18, 0.12, 0.06, 0.18)
    end
    
    self:CreateHeader(frame)
    self:CreateSidebar(frame)
    self:CreateContent(frame)
    self:CreatePreviewPanel(frame)
    self:CreateSettingsPanel(frame)
    self:CreateShoppingListPanel(frame)
    
    tinsert(UISpecialFrames, "HousingCompletedFrame")
end

function HC:CreateHeader(parent)
    local header = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    header:SetPoint("TOPLEFT", 0, 0)
    header:SetPoint("TOPRIGHT", 0, 0)
    header:SetHeight(HEADER_HEIGHT)
    header:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
    header:SetBackdropColor(unpack(COLORS.headerBg))

    local bottomBorder = header:CreateTexture(nil, "BORDER")
    bottomBorder:SetPoint("BOTTOMLEFT", 0, 0)
    bottomBorder:SetPoint("BOTTOMRIGHT", 0, 0)
    bottomBorder:SetHeight(1)
    bottomBorder:SetColorTexture(unpack(COLORS.border))
    
    local title = header:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("LEFT", 20, 10)
    title:SetText("|cfff4d38aHousing|r |cfffff8e7Completed|r")

    local subtitle = header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    subtitle:SetPoint("LEFT", 20, -12)
    subtitle:SetText("By Korivash")
    subtitle:SetTextColor(0.82, 0.72, 0.56)
    
    local version = header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    version:SetPoint("LEFT", title, "RIGHT", 10, 0)
    version:SetText("v" .. HC.version)
    version:SetTextColor(0.5, 0.5, 0.5)
    
    local stats = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    stats:SetPoint("LEFT", 190, -2)
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
    sidebar:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    sidebar:SetBackdropColor(unpack(COLORS.sidebar))
    sidebar:SetBackdropBorderColor(unpack(COLORS.border))
    
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

    local scrollFrame = CreateFrame("ScrollFrame", nil, sidebar, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 6, y)
    scrollFrame:SetPoint("BOTTOMRIGHT", -28, 10)
    scrollFrame:EnableMouseWheel(true)
    self.sidebarScrollFrame = scrollFrame

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(SIDEBAR_WIDTH - 36, 500)
    scrollFrame:SetScrollChild(scrollChild)

    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local current = self:GetVerticalScroll() or 0
        local step = 28
        local minVal, maxVal = 0, 0
        if self.ScrollBar and self.ScrollBar.GetMinMaxValues then
            minVal, maxVal = self.ScrollBar:GetMinMaxValues()
        end
        local nextVal = current - (delta * step)
        if nextVal < minVal then nextVal = minVal end
        if nextVal > maxVal then nextVal = maxVal end
        self:SetVerticalScroll(nextVal)
    end)

    y = -8

    local tabLabel = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    tabLabel:SetPoint("TOPLEFT", 15, y)
    tabLabel:SetText("CATEGORIES")
    tabLabel:SetTextColor(unpack(COLORS.accentAlt))
    y = y - 22
    
    -- Category tabs with correct icons
    local tabs = {
        { id = "items", name = "Items", icon = "Interface\\Icons\\INV_Misc_Bag_10_Blue" },
        { id = "all", name = "All Items", icon = "Interface\\Icons\\INV_Misc_Bag_10" },
        { id = "vendor", name = "Vendors", icon = "Interface\\Icons\\INV_Misc_Coin_01" },
        { id = "achievement", name = "Achievements", icon = "Interface\\Icons\\Achievement_General_100kQuests" },
        { id = "quest", name = "Quests", icon = "Interface\\Icons\\INV_Misc_Book_07" },
        { id = "reputation", name = "Reputation", icon = "Interface\\Icons\\Achievement_Reputation_08" },
        { id = "profession", name = "Professions", icon = "Interface\\Icons\\INV_Misc_Note_01" },
        { id = "drop", name = "Drops", icon = "Interface\\Icons\\INV_Misc_Bag_10_Blue" },
        { id = "promo", name = "Promotions", icon = "Interface\\Icons\\INV_Misc_Gift_05" },
        { id = "unknown", name = "Unknown", icon = "Interface\\Icons\\INV_Misc_QuestionMark" },
        { id = "auction", name = "Auction House", icon = "Interface\\Icons\\INV_Misc_Coin_02" },
    }
    
    self.tabButtons = {}
    for _, tabInfo in ipairs(tabs) do
        local btn = CreateFrame("Button", nil, scrollChild)
        btn:SetSize(SIDEBAR_WIDTH - 44, 26)
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
    
    local divider = scrollChild:CreateTexture(nil, "ARTWORK")
    divider:SetSize(SIDEBAR_WIDTH - 52, 1)
    divider:SetPoint("TOP", 0, y)
    divider:SetColorTexture(0.2, 0.2, 0.25, 1)
    y = y - 15
    
    local filterLabel = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    filterLabel:SetPoint("TOPLEFT", 15, y)
    filterLabel:SetText("FILTERS")
    filterLabel:SetTextColor(unpack(COLORS.accentAlt))
    y = y - 22
    
    local collectedCb = CreateFrame("CheckButton", nil, scrollChild, "UICheckButtonTemplate")
    collectedCb:SetPoint("TOPLEFT", 10, y)
    collectedCb:SetSize(24, 24)
    SetButtonText(collectedCb, "Collected", 0.7, 0.7, 0.7)
    collectedCb:SetChecked(true)
    collectedCb:SetScript("OnClick", function() HC:DoSearch() end)
    self.collectedCb = collectedCb
    y = y - 24
    
    local uncollectedCb = CreateFrame("CheckButton", nil, scrollChild, "UICheckButtonTemplate")
    uncollectedCb:SetPoint("TOPLEFT", 10, y)
    uncollectedCb:SetSize(24, 24)
    SetButtonText(uncollectedCb, "Uncollected", 0.7, 0.7, 0.7)
    uncollectedCb:SetChecked(true)
    uncollectedCb:SetScript("OnClick", function() HC:DoSearch() end)
    self.uncollectedCb = uncollectedCb
    y = y - 30

    local zoneOnlyCb = CreateFrame("CheckButton", nil, scrollChild, "UICheckButtonTemplate")
    zoneOnlyCb:SetPoint("TOPLEFT", 10, y)
    zoneOnlyCb:SetSize(24, 24)
    SetButtonText(zoneOnlyCb, "Current Zone Only", 0.7, 0.7, 0.7)
    zoneOnlyCb:SetChecked(false)
    zoneOnlyCb:SetScript("OnClick", function() HC:DoSearch() end)
    self.zoneOnlyCb = zoneOnlyCb
    y = y - 28

    local itemCategoryLabel = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    itemCategoryLabel:SetPoint("TOPLEFT", 15, y)
    itemCategoryLabel:SetText("ITEM TYPES")
    itemCategoryLabel:SetTextColor(unpack(COLORS.accentAlt))
    self.itemCategoryLabel = itemCategoryLabel
    y = y - 20

    self.itemCategoryButtons = {}
    local categories = self.GetItemCategories and self:GetItemCategories() or {
        { id = "all", name = "All Item Types" },
    }
    for _, cat in ipairs(categories) do
        local btn = CreateFrame("Button", nil, scrollChild)
        btn:SetSize(SIDEBAR_WIDTH - 44, 18)
        btn:SetPoint("TOPLEFT", 10, y)
        btn.categoryID = cat.id

        local bg = btn:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(0, 0, 0, 0)
        btn.bg = bg

        local label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        label:SetPoint("LEFT", 8, 0)
        label:SetText(cat.name)
        label:SetTextColor(0.7, 0.7, 0.7)
        btn.label = label

        btn:SetScript("OnEnter", function(self)
            if currentItemCategory ~= self.categoryID then
                self.bg:SetColorTexture(0.12, 0.12, 0.18, 1)
            end
        end)
        btn:SetScript("OnLeave", function(self)
            if currentItemCategory ~= self.categoryID then
                self.bg:SetColorTexture(0, 0, 0, 0)
            end
        end)
        btn:SetScript("OnClick", function(self)
            currentItemCategory = self.categoryID
            HC:UpdateItemCategoryButtons()
            HC:DoSearch()
        end)

        self.itemCategoryButtons[cat.id] = btn
        y = y - 18
    end
    y = y - 12
    
    local progressLabel = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    progressLabel:SetPoint("TOPLEFT", 15, y)
    progressLabel:SetText("PROGRESS")
    progressLabel:SetTextColor(unpack(COLORS.accentAlt))
    y = y - 20
    
    local progressText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    progressText:SetPoint("TOPLEFT", 15, y)
    progressText:SetText("0 / 0")
    progressText:SetTextColor(0.7, 0.7, 0.7)
    self.progressText = progressText
    
    scrollChild:SetHeight(math.max(520, -y + 30))
    if scrollFrame.ScrollBar and scrollFrame.ScrollBar.SetValueStep then
        scrollFrame.ScrollBar:SetValueStep(20)
    end

    self.sidebar = sidebar
    self:UpdateItemCategoryButtons()
end

function HC:CreateContent(parent)
    local content = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    content:SetPoint("TOPLEFT", SIDEBAR_WIDTH, -HEADER_HEIGHT)
    content:SetPoint("BOTTOMRIGHT", -PREVIEW_WIDTH, 0)
    content:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
    content:SetBackdropColor(0.06, 0.045, 0.03, 0.9)
    
    local resultsFrame = CreateFrame("Frame", nil, content, "BackdropTemplate")
    resultsFrame:SetPoint("TOPLEFT", 15, -15)
    resultsFrame:SetPoint("BOTTOMRIGHT", -15, 80)
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
    
    local pagination = CreateFrame("Frame", nil, content, "BackdropTemplate")
    pagination:SetPoint("BOTTOMLEFT", 15, 15)
    pagination:SetPoint("BOTTOMRIGHT", -15, 15)
    pagination:SetHeight(58)
    pagination:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
    pagination:SetBackdropColor(0.08, 0.06, 0.04, 0.92)
    
    local exportBtn = CreateFrame("Button", nil, pagination, "UIPanelButtonTemplate")
    exportBtn:SetSize(96, 26)
    exportBtn:SetPoint("LEFT", 0, 0)
    exportBtn:SetText("Export CSV")
    exportBtn:SetScript("OnClick", function()
        HC:ShowResultsExportDialog()
    end)
    self.exportBtn = exportBtn

    local shoppingBtn = CreateFrame("Button", nil, pagination, "UIPanelButtonTemplate")
    shoppingBtn:SetSize(108, 26)
    shoppingBtn:SetPoint("LEFT", exportBtn, "RIGHT", 8, 0)
    shoppingBtn:SetText("Shopping List")
    shoppingBtn:SetScript("OnClick", function()
        HC:ToggleShoppingListPanel()
    end)
    self.shoppingBtn = shoppingBtn

    local prevBtn = CreateFrame("Button", nil, pagination, "UIPanelButtonTemplate")
    prevBtn:SetSize(70, 26)
    prevBtn:SetPoint("LEFT", shoppingBtn, "RIGHT", 12, 12)
    prevBtn:SetText("< Prev")
    prevBtn:SetScript("OnClick", function()
        if currentPage > 1 then currentPage = currentPage - 1; HC:UpdateResults() end
    end)
    self.prevBtn = prevBtn
    
    local nextBtn = CreateFrame("Button", nil, pagination, "UIPanelButtonTemplate")
    nextBtn:SetSize(70, 26)
    nextBtn:SetPoint("LEFT", prevBtn, "RIGHT", 8, 0)
    nextBtn:SetText("Next >")
    nextBtn:SetScript("OnClick", function()
        if currentPage < totalPages then currentPage = currentPage + 1; HC:UpdateResults() end
    end)
    self.nextBtn = nextBtn

    local setWaypointBtn = CreateFrame("Button", nil, pagination, "UIPanelButtonTemplate")
    setWaypointBtn:SetSize(130, 26)
    setWaypointBtn:SetPoint("RIGHT", -8, 12)
    setWaypointBtn:SetText("Set Waypoint")
    setWaypointBtn:SetScript("OnClick", function()
        HC:SetResultWaypoint(selectedItem)
        HC:UpdateSetWaypointButton()
    end)
    self.setWaypointBtn = setWaypointBtn

    local addShoppingBtn = CreateFrame("Button", nil, pagination, "UIPanelButtonTemplate")
    addShoppingBtn:SetSize(110, 26)
    addShoppingBtn:SetPoint("RIGHT", setWaypointBtn, "LEFT", -8, 0)
    addShoppingBtn:SetText("Add To List")
    addShoppingBtn:SetScript("OnClick", function()
        local ok, msg = HC:AddResultToShoppingList(selectedItem)
        if msg then
            print("|cff00ff99Housing Completed|r: " .. msg)
        end
        if ok then
            HC:RefreshShoppingListPanel()
            HC:UpdateAddShoppingButton()
        end
    end)
    self.addShoppingBtn = addShoppingBtn

    local mapAllBtn = CreateFrame("Button", nil, pagination, "UIPanelButtonTemplate")
    mapAllBtn:SetSize(96, 26)
    mapAllBtn:SetPoint("RIGHT", addShoppingBtn, "LEFT", -8, 0)
    mapAllBtn:SetText("Map All")
    mapAllBtn:SetScript("OnClick", function()
        HC:MapWaypointsForResults(currentResults)
        HC:UpdateMapAllButton()
    end)
    self.mapAllBtn = mapAllBtn
    
    local pageText = pagination:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    pageText:SetPoint("TOP", 0, -10)
    pageText:SetText("Page 1 of 1")
    pageText:SetTextColor(unpack(COLORS.textMuted))
    self.pageText = pageText
    
    local statusText = pagination:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    statusText:SetPoint("LEFT", 10, -14)
    statusText:SetText("0 results")
    statusText:SetTextColor(unpack(COLORS.textDim))
    self.statusText = statusText
    self:UpdateSetWaypointButton()
    self:UpdateAddShoppingButton()
    self:UpdateMapAllButton()
    
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
        local itemID = HC:GetResolvedItemID(self.itemData)
        if itemID then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetItemByID(itemID)
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
        HC:UpdateRowSelection()
        HC:UpdateSetWaypointButton()
        HC:UpdateAddShoppingButton()
        if HC.UpdatePreview then
            HC:UpdatePreview(self.itemData)
        end

        -- If this entry has an itemID, open the Blizzard preview (DecorVendor-style)
        local itemID = HC:GetResolvedItemID(self.itemData)
        if itemID then
            HC:OpenItemPreview(itemID)
        end
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
    waypointBtn:SetNormalTexture("Interface\\Icons\\INV_Misc_Map07")
    waypointBtn:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    waypointBtn:SetScript("OnClick", function()
        HC:SetResultWaypoint(row.itemData)
        selectedItem = row.itemData
        HC:UpdateRowSelection()
        HC:UpdateSetWaypointButton()
    end)
    row.waypointBtn = waypointBtn
    
    local typeBadge = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    typeBadge:SetPoint("RIGHT", waypointBtn, "LEFT", -10, 0)
    row.typeBadge = typeBadge

    local repBadge = CreateFrame("Button", nil, row, "BackdropTemplate")
    repBadge:SetSize(34, 16)
    repBadge:SetPoint("RIGHT", typeBadge, "LEFT", -8, 0)
    repBadge:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    repBadge:SetBackdropColor(0.30, 0.22, 0.45, 0.95)
    repBadge:SetBackdropBorderColor(0.55, 0.45, 0.75, 1)
    repBadge:Hide()

    local repBadgeText = repBadge:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    repBadgeText:SetPoint("CENTER", 0, 0)
    repBadgeText:SetText("REP")
    repBadgeText:SetTextColor(0.95, 0.88, 1)

    repBadge:SetScript("OnEnter", function(self)
        if not self.repRequirements or #self.repRequirements == 0 then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("Reputation Required", 0.9, 0.8, 1)
        for _, req in ipairs(self.repRequirements) do
            local line
            if req.faction or req.standing then
                line = (req.faction or "Reputation") .. " - " .. (req.standing or "Required")
            elseif req.note then
                line = req.note
            else
                line = "Requirement in source data"
            end
            GameTooltip:AddLine(line, 0.85, 0.85, 0.95, true)
        end
        GameTooltip:Show()
    end)
    repBadge:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    repBadge:SetScript("OnClick", function()
        if row:GetScript("OnClick") then
            row:GetScript("OnClick")(row)
        end
    end)
    row.repBadge = repBadge
    
    row:Hide()
    return row
end

function HC:GetResolvedItemID(resultData)
    if not resultData then return nil end

    local directID = resultData.itemID or (resultData.data and resultData.data.itemID)
    if directID then
        return directID
    end

    local itemName = resultData.name or (resultData.data and resultData.data.name)
    if not itemName or not self.ResolveItemIDByName then
        return nil
    end

    local resolvedID = self:ResolveItemIDByName(itemName)
    if resolvedID then
        resultData.itemID = resolvedID
        resultData.data = resultData.data or {}
        resultData.data.itemID = resolvedID
        if self.EnsureItemCached then
            self:EnsureItemCached(resolvedID)
        end
    end
    return resolvedID
end

function HC:GetReputationRequirements(resultData)
    local reqs = {}
    local seen = {}
    local sources = resultData and resultData.data and resultData.data.sources
    if type(sources) ~= "table" then
        return reqs
    end

    for _, s in ipairs(sources) do
        local isRepSource = false
        if self.IsReputationSource then
            isRepSource = self:IsReputationSource(s)
        else
            isRepSource = (s.sourceType == "reputation") or (s.standing and s.standing ~= "")
        end

        if isRepSource then
            local faction = s.faction
            local standing = s.standing
            local note = nil
            if self.IsReputationRequirementText and self:IsReputationRequirementText(s.notes) then
                note = s.notes
            end

            local key = tostring(faction or "") .. "|" .. tostring(standing or "") .. "|" .. tostring(note or "")
            if not seen[key] then
                seen[key] = true
                table.insert(reqs, {
                    faction = faction,
                    standing = standing,
                    note = note,
                })
            end
        end
    end

    return reqs
end

function HC:GetItemCategoryName(categoryID)
    if not self.GetItemCategories then return categoryID or "Misc" end
    for _, cat in ipairs(self:GetItemCategories()) do
        if cat.id == categoryID then
            return cat.name
        end
    end
    return "Misc"
end

function HC:CreatePreviewPanel(parent)
    local preview = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    preview:SetPoint("TOPRIGHT", 0, -HEADER_HEIGHT)
    preview:SetPoint("BOTTOMRIGHT", 0, 0)
    preview:SetWidth(PREVIEW_WIDTH)
    preview:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 10,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    preview:SetBackdropColor(unpack(COLORS.preview))
    preview:SetBackdropBorderColor(unpack(COLORS.border))
    
    local y = -15
    
    local title = preview:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    title:SetPoint("TOPLEFT", 15, y)
    title:SetText("RESIDENCE PREVIEW")
    title:SetTextColor(unpack(COLORS.accentAlt))
    y = y - 25

    local headerLine = preview:CreateTexture(nil, "ARTWORK")
    headerLine:SetPoint("TOPLEFT", 12, y)
    headerLine:SetPoint("TOPRIGHT", -12, y)
    headerLine:SetHeight(1)
    headerLine:SetColorTexture(0.42, 0.29, 0.16, 0.9)
    y = y - 10
    
    -- Model container
    local modelContainer = CreateFrame("Frame", nil, preview, "BackdropTemplate")
    modelContainer:SetSize(PREVIEW_WIDTH - 24, 214)
    modelContainer:SetPoint("TOP", 0, y)
    modelContainer:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    modelContainer:SetBackdropColor(0.06, 0.05, 0.04, 1)
    modelContainer:SetBackdropBorderColor(0.3, 0.22, 0.12, 1)
    
    -- Prefer DressUpModel behavior so preview matches Dressing Room rendering.
    local modelFrame = CreateFrame("DressUpModel", nil, modelContainer)
    if not modelFrame then
        modelFrame = CreateFrame("PlayerModel", nil, modelContainer)
    end
    modelFrame:SetAllPoints()
    modelFrame:EnableMouse(true)
    modelFrame:EnableMouseWheel(true)
    if modelFrame.SetUnit then
        pcall(modelFrame.SetUnit, modelFrame, "player")
    end
    
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

    local modelFallbackIcon = modelContainer:CreateTexture(nil, "ARTWORK")
    modelFallbackIcon:SetSize(56, 56)
    modelFallbackIcon:SetPoint("CENTER")
    modelFallbackIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    modelFallbackIcon:SetVertexColor(0.8, 0.8, 0.8, 0.9)
    modelFallbackIcon:Hide()
    self.modelFallbackIcon = modelFallbackIcon

    y = y - 224
    
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
    detailsFrame:SetHeight(220)
    
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
    dy = dy - 16

    -- Item ID
    local itemIDLabel = detailsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    itemIDLabel:SetPoint("TOPLEFT", 0, dy)
    itemIDLabel:SetText("|cff888888Item ID:|r")
    local itemIDValue = detailsFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    itemIDValue:SetPoint("TOPLEFT", 55, dy)
    itemIDValue:SetPoint("RIGHT", 0, 0)
    itemIDValue:SetJustifyH("LEFT")
    itemIDValue:SetText("-")
    self.previewItemID = itemIDValue
    dy = dy - 16

    -- Sources
    local sourcesLabel = detailsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    sourcesLabel:SetPoint("TOPLEFT", 0, dy)
    sourcesLabel:SetText("|cff888888Sources:|r")
    local sourcesValue = detailsFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    sourcesValue:SetPoint("TOPLEFT", 55, dy)
    sourcesValue:SetPoint("RIGHT", 0, 0)
    sourcesValue:SetJustifyH("LEFT")
    sourcesValue:SetText("-")
    self.previewSources = sourcesValue
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
                HC:SetSmartWaypoint(data.x, data.y, data.mapID, data.name)
            elseif data and data.vendorData and data.vendorData.x and data.vendorData.y and data.vendorData.mapID then
                HC:SetSmartWaypoint(data.vendorData.x, data.vendorData.y, data.vendorData.mapID, data.vendorData.name)
            elseif selectedItem.vendor then
                local v = HC:GetVendorByName(selectedItem.vendor)
                if v and v.x and v.y and v.mapID then
                    HC:SetSmartWaypoint(v.x, v.y, v.mapID, v.name)
                end
            end
        end
    end)
    self.previewWaypointBtn = wpBtn

    local addListBtn = CreateFrame("Button", nil, preview, "UIPanelButtonTemplate")
    addListBtn:SetSize(PREVIEW_WIDTH - 30, 24)
    addListBtn:SetPoint("BOTTOM", 0, 48)
    addListBtn:SetText("Add To Shopping List")
    addListBtn:SetScript("OnClick", function()
        local ok, msg = HC:AddResultToShoppingList(selectedItem)
        if msg then
            print("|cff00ff99Housing Completed|r: " .. msg)
        end
        if ok then
            HC:RefreshShoppingListPanel()
        end
    end)
    self.previewAddShoppingBtn = addListBtn
    
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
        if self.previewItemID then self.previewItemID:SetText("-") end
        if self.previewSources then self.previewSources:SetText("-") end
        if self.modelFrame.ClearModel then self.modelFrame:ClearModel() end
        if self.modelFallbackIcon then self.modelFallbackIcon:Show() end
        if self.previewAddShoppingBtn then
            self.previewAddShoppingBtn:SetEnabled(false)
            self.previewAddShoppingBtn:SetAlpha(0.45)
        end
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

    local itemID = self:GetResolvedItemID(data)
    if self.previewItemID then
        self.previewItemID:SetText(itemID and tostring(itemID) or "-")
    end

    if self.previewSources then
        local sourceCount = (data.data and data.data.sourceCount) or (data.sourceCount) or ((data.data and data.data.sources and #data.data.sources) or nil)
        self.previewSources:SetText(sourceCount and tostring(sourceCount) or "-")
    end
    
    -- Reputation details
    if data.type == "reputation" and data.data and (data.data.faction or data.data.standing) then
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
    
    -- Model - dressing-room style try-on first, with safe fallbacks.
    if self.modelFrame then
        local showedModel = false
        if itemID then
            if self.modelFrame.SetUnit then
                pcall(self.modelFrame.SetUnit, self.modelFrame, "player")
            end
            if self.modelFrame.Undress then
                pcall(self.modelFrame.Undress, self.modelFrame)
            end

            local itemLink = (C_Item and C_Item.GetItemLinkByID and C_Item.GetItemLinkByID(itemID)) or ("item:" .. itemID)
            if self.modelFrame.TryOn then
                local ok = pcall(self.modelFrame.TryOn, self.modelFrame, itemLink)
                showedModel = ok and true or false
            end
        end

        if (not showedModel) and data.type == "vendor" and data.data and data.data.id then
            if self.modelFrame.SetCreature then
                local ok = pcall(self.modelFrame.SetCreature, self.modelFrame, data.data.id)
                if ok then
                    showedModel = true
                end
            end
        end

        if self.modelFallbackIcon then
            self.modelFallbackIcon:SetShown(not showedModel)
        end

        if not showedModel then
            if self.modelFrame.ClearModel then
                pcall(self.modelFrame.ClearModel, self.modelFrame)
            end
            local icon = (itemID and C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(itemID))
                or "Interface\\Icons\\INV_Misc_QuestionMark"
            if self.modelFallbackIcon then
                self.modelFallbackIcon:SetTexture(icon)
            end
        end
    end

    if self.previewAddShoppingBtn then
        self.previewAddShoppingBtn:SetEnabled(true)
        self.previewAddShoppingBtn:SetAlpha(1)
    end
end

function HC:OpenItemPreview(itemID)
    if not itemID then return false end

    -- Housing-native preview if available
    if C_HousingCatalog and C_HousingCatalog.OpenToItemID then
        local ok = pcall(C_HousingCatalog.OpenToItemID, itemID)
        if ok then
            return true
        end
    end

    -- Fallback: Dressing Room
    if DressUpItemLink then
        local ok = pcall(DressUpItemLink, "item:" .. itemID)
        if ok then
            return true
        end
    end

    -- Last fallback: use modified-click handler when available.
    if HandleModifiedItemClick then
        local ok = pcall(HandleModifiedItemClick, "item:" .. itemID)
        if ok then
            return true
        end
    end

    return false
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

function HC:UpdateSetWaypointButton()
    if not self.setWaypointBtn then return end

    local hasSelection = selectedItem ~= nil
    local canWaypoint = hasSelection and self.ResultHasWaypoint and self:ResultHasWaypoint(selectedItem)
    self.setWaypointBtn:SetEnabled(canWaypoint and true or false)
    self.setWaypointBtn:SetAlpha(canWaypoint and 1 or 0.45)
end

function HC:UpdateAddShoppingButton()
    if not self.addShoppingBtn then return end
    local canAdd = selectedItem ~= nil
    self.addShoppingBtn:SetEnabled(canAdd and true or false)
    self.addShoppingBtn:SetAlpha(canAdd and 1 or 0.45)
end

function HC:UpdateMapAllButton()
    if not self.mapAllBtn then return end
    local hasAnyWaypoint = false
    for _, resultData in ipairs(currentResults or {}) do
        if self.ResultHasWaypoint and self:ResultHasWaypoint(resultData) then
            hasAnyWaypoint = true
            break
        end
    end

    self.mapAllBtn:SetEnabled(hasAnyWaypoint and true or false)
    self.mapAllBtn:SetAlpha(hasAnyWaypoint and 1 or 0.45)
end

function HC:BuildResultsCSV(results)
    local lines = {
        "Name,Type,Source,Vendor,Zone,Cost,Expansion,Faction,Collected,ItemID,SourceCount",
    }

    for _, r in ipairs(results or {}) do
        local row = {
            EscapeCSV(r.name or (r.data and r.data.name) or ""),
            EscapeCSV(r.type or ""),
            EscapeCSV(r.source or ""),
            EscapeCSV(r.vendor or ""),
            EscapeCSV(r.zone or ""),
            EscapeCSV(r.cost or ""),
            EscapeCSV(r.expansion or ""),
            EscapeCSV(r.faction or ""),
            EscapeCSV(r.collected and "Yes" or "No"),
            EscapeCSV((r.data and r.data.itemID) or r.itemID or ""),
            EscapeCSV(r.sourceCount or (r.data and r.data.sourceCount) or ""),
        }
        table.insert(lines, table.concat(row, ","))
    end

    return table.concat(lines, "\n")
end

function HC:ShowTextExportDialog(title, text)
    if not self.exportFrame then
        local f = CreateFrame("Frame", "HousingCompletedExportFrame", UIParent, "BackdropTemplate")
        f:SetSize(900, 560)
        f:SetPoint("CENTER")
        f:SetFrameStrata("DIALOG")
        f:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        f:SetBackdropColor(0.04, 0.04, 0.06, 0.98)
        f:SetBackdropBorderColor(0.2, 0.2, 0.25, 1)
        f:Hide()

        local header = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        header:SetPoint("TOPLEFT", 16, -12)
        header:SetTextColor(unpack(COLORS.accentAlt))
        f.header = header

        local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
        closeBtn:SetPoint("TOPRIGHT", -4, -4)

        local helpText = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        helpText:SetPoint("TOPLEFT", 16, -36)
        helpText:SetTextColor(unpack(COLORS.textMuted))
        helpText:SetText("Click in the box, press Ctrl+A, then Ctrl+C.")

        local scroll = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", 16, -58)
        scroll:SetPoint("BOTTOMRIGHT", -34, 16)

        local edit = CreateFrame("EditBox", nil, scroll)
        edit:SetMultiLine(true)
        edit:SetAutoFocus(true)
        edit:SetFontObject(ChatFontNormal)
        edit:SetTextInsets(8, 8, 8, 8)
        edit:SetWidth(830)
        edit:SetScript("OnEscapePressed", function() f:Hide() end)
        edit:SetScript("OnTextChanged", function(self)
            self:SetHeight(math.max(1, self:GetStringHeight() + 20))
        end)
        scroll:SetScrollChild(edit)

        f.editBox = edit
        self.exportFrame = f
    end

    self.exportFrame.header:SetText(title or "Export")
    self.exportFrame.editBox:SetText(text or "")
    self.exportFrame.editBox:HighlightText()
    self.exportFrame:Show()
end

function HC:ShowResultsExportDialog()
    local csv = self:BuildResultsCSV(currentResults or {})
    self:ShowTextExportDialog("Export Results CSV", csv)
end

function HC:CreateShoppingListPanel(parent)
    local frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    frame:SetPoint("TOPLEFT", SIDEBAR_WIDTH + 30, -HEADER_HEIGHT - 30)
    frame:SetPoint("BOTTOMRIGHT", -30, 30)
    frame:SetFrameStrata("DIALOG")
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 10,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    frame:SetBackdropColor(0.06, 0.045, 0.03, 0.98)
    frame:SetBackdropBorderColor(unpack(COLORS.border))
    frame:Hide()

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 14, -10)
    title:SetText("Shopping List")
    title:SetTextColor(unpack(COLORS.accentAlt))
    frame.title = title

    local countText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    countText:SetPoint("TOPLEFT", 16, -34)
    countText:SetTextColor(unpack(COLORS.textMuted))
    frame.countText = countText

    local closeBtn = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", -4, -4)
    closeBtn:SetScript("OnClick", function()
        frame:Hide()
    end)

    local mapBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    mapBtn:SetSize(90, 24)
    mapBtn:SetPoint("TOPRIGHT", -36, -32)
    mapBtn:SetText("Map All")
    mapBtn:SetScript("OnClick", function()
        HC:MapWaypointsForShoppingList()
    end)
    frame.mapBtn = mapBtn

    local clearBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    clearBtn:SetSize(90, 24)
    clearBtn:SetPoint("RIGHT", mapBtn, "LEFT", -8, 0)
    clearBtn:SetText("Clear")
    clearBtn:SetScript("OnClick", function()
        HC:ClearShoppingList()
        HC:RefreshShoppingListPanel()
    end)
    frame.clearBtn = clearBtn

    local scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 12, -62)
    scroll:SetPoint("BOTTOMRIGHT", -30, 12)
    frame.scroll = scroll

    local child = CreateFrame("Frame", nil, scroll)
    child:SetSize(1, 1)
    scroll:SetScrollChild(child)
    frame.child = child
    frame.rows = {}

    self.shoppingListPanel = frame
end

function HC:RefreshShoppingListPanel()
    if not self.shoppingListPanel then return end

    local panel = self.shoppingListPanel
    local list = self:GetShoppingList()

    panel.countText:SetText(string.format("%d item%s", #list, #list == 1 and "" or "s"))
    panel.mapBtn:SetEnabled(#list > 0)
    panel.mapBtn:SetAlpha(#list > 0 and 1 or 0.45)
    panel.clearBtn:SetEnabled(#list > 0)
    panel.clearBtn:SetAlpha(#list > 0 and 1 or 0.45)

    for _, row in ipairs(panel.rows) do
        row:Hide()
    end

    local rowHeight = 28
    local y = -6
    for i, entry in ipairs(list) do
        local row = panel.rows[i]
        if not row then
            row = CreateFrame("Frame", nil, panel.child, "BackdropTemplate")
            row:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8x8",
                edgeFile = "Interface\\Buttons\\WHITE8x8",
                edgeSize = 1,
            })
            row:SetBackdropColor(0.12, 0.09, 0.06, 0.92)
            row:SetBackdropBorderColor(0.25, 0.18, 0.1, 1)
            row:SetHeight(rowHeight - 2)

            local txt = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            txt:SetPoint("LEFT", 8, 0)
            txt:SetPoint("RIGHT", -96, 0)
            txt:SetJustifyH("LEFT")
            row.text = txt

            local del = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
            del:SetSize(78, 20)
            del:SetPoint("RIGHT", -8, 0)
            del:SetText("Remove")
            del:SetScript("OnClick", function(selfBtn)
                local idx = selfBtn.rowIndex
                HC:RemoveShoppingListEntry(idx)
                HC:RefreshShoppingListPanel()
            end)
            row.deleteBtn = del

            panel.rows[i] = row
        end

        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", 0, y)
        row:SetPoint("TOPRIGHT", -8, y)
        local vendorPart = entry.vendor and entry.vendor ~= "" and (" |cffaaaaaa- " .. entry.vendor .. "|r") or ""
        local zonePart = entry.zone and entry.zone ~= "" and (" |cff888888(" .. entry.zone .. ")|r") or ""
        row.text:SetText((entry.name or "Unknown") .. vendorPart .. zonePart)
        row.deleteBtn.rowIndex = i
        row:Show()

        y = y - rowHeight
    end

    panel.child:SetWidth(math.max(1, panel.scroll:GetWidth() - 18))
    panel.child:SetHeight(math.max(1, -y + 8))
end

function HC:ToggleShoppingListPanel()
    if not self.shoppingListPanel then return end
    if self.shoppingListPanel:IsShown() then
        self.shoppingListPanel:Hide()
    else
        self:RefreshShoppingListPanel()
        self.shoppingListPanel:Show()
    end
end

function HC:CreateSettingsPanel(parent)
    local settings = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    settings:SetPoint("TOPLEFT", SIDEBAR_WIDTH, -HEADER_HEIGHT)
    settings:SetPoint("BOTTOMRIGHT", -PREVIEW_WIDTH, 0)
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
    waypointLabel:SetText("Waypoints: Blizzard or TomTom (if enabled)")
    y = y - 35


    -- Force TomTom routing toggle
    local forceTomTomCheck = CreateFrame("CheckButton", nil, settings, "InterfaceOptionsCheckButtonTemplate")
    forceTomTomCheck:SetPoint("TOPLEFT", 20, y)
    forceTomTomCheck.Text:SetText("Force TomTom Routing (recommended)")
    forceTomTomCheck:SetChecked(HousingCompletedDB and HousingCompletedDB.navigation and HousingCompletedDB.navigation.forceTomTom)

    forceTomTomCheck:SetScript("OnClick", function(selfBtn)
        if not HousingCompletedDB.navigation then HousingCompletedDB.navigation = {} end
        HousingCompletedDB.navigation.forceTomTom = selfBtn:GetChecked() and true or false

        if HousingCompletedDB.navigation.forceTomTom and not _G.TomTom then
            print("|cff00ff99Housing Completed|r: |cffffff00TomTom|r not detected. Install/enable TomTom for advanced navigation.")
        end
    end)
    y = y - 40
    local scaleLabel = settings:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    scaleLabel:SetPoint("TOPLEFT", 20, y)
    scaleLabel:SetText("UI Scale:")
    y = y - 28
    
    local scaleSlider = CreateFrame("Slider", nil, settings, "OptionsSliderTemplate")
scaleSlider:SetPoint("TOPLEFT", 30, y)
scaleSlider:SetWidth(320)

scaleSlider:SetMinMaxValues(0.5, 1.5)
scaleSlider:SetValueStep(0.01)
scaleSlider:SetObeyStepOnDrag(true)

scaleSlider:SetValue(HousingCompletedDB.scale or 1.0)

scaleSlider.Low:SetText("50%")
scaleSlider.High:SetText("150%")

scaleSlider:SetScript("OnValueChanged", function(self, value)
    value = tonumber(string.format("%.2f", value))
    HousingCompletedDB.scale = value

    if self.Text then
        self.Text:SetText(string.format("%.0f%%", value * 100))
    end

    if HC.mainFrame then
        HC.mainFrame:SetScale(value)
    end
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
local backBtn = CreateFrame("Button", nil, settings, "UIPanelButtonTemplate")
    backBtn:SetSize(100, 28)
    backBtn:SetPoint("BOTTOMLEFT", 20, 20)
    backBtn:SetText("Back")
    backBtn:SetScript("OnClick", function() HC:ToggleSettings() end)
    
    self.settingsPanel = settings
end


function HC:DoSearch()
    local query = self.searchBox and self.searchBox:GetText() or ""
    local zoneMapID = nil
    if self.zoneOnlyCb and self.zoneOnlyCb:GetChecked() then
        zoneMapID = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player") or nil
    end
    local filters = {
        showCollected = self.collectedCb and self.collectedCb:GetChecked(),
        showUncollected = self.uncollectedCb and self.uncollectedCb:GetChecked(),
        faction = self:GetPlayerFaction(),
        zoneMapID = zoneMapID,
    }
    if currentTab == "items" then
        filters.itemCategory = currentItemCategory
        filters.hideVendorEntries = true
    elseif currentTab ~= "all" then 
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
    self:UpdateSetWaypointButton()
    self:UpdateAddShoppingButton()
    self:UpdateMapAllButton()
    if self.UpdatePreview then
        self:UpdatePreview(nil)
    end
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
            local resolvedItemID = self:GetResolvedItemID(data)
            
            -- Prefer the actual item icon when we have an itemID
            if resolvedItemID then
                local itemIcon
                if C_Item and C_Item.GetItemIconByID then
                    itemIcon = C_Item.GetItemIconByID(resolvedItemID)
                elseif GetItemIcon then
                    itemIcon = GetItemIcon(resolvedItemID)
                end
                if itemIcon then icon = itemIcon end
            end

            -- Use profession-specific icon (scan sources for profession name)
            if data.type == "profession" and data.data and data.data.sources and HC.ProfessionIcons then
                for _, s in ipairs(data.data.sources) do
                    if s.profession and type(s.profession) == "string" then
                        local profIcon = HC.ProfessionIcons[s.profession:lower()]
                        if profIcon then
                            icon = profIcon
                            break
                        end
                    end
                end
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
            if currentTab == "items" then
                sourceText = "Category: " .. self:GetItemCategoryName(data.itemCategory or (data.data and data.data.itemCategory))
            end
            if data.type == "vendor" and data.data then
                sourceText = data.zone or ""
                if data.data.subzone then sourceText = sourceText .. " - " .. data.data.subzone end
            elseif data.type == "reputation" and data.data then
                if data.data.faction or data.data.standing then
                    sourceText = (data.data.faction or "Reputation") .. " (" .. (data.data.standing or "Required") .. ")"
                end
            end
            row.sourceText:SetText(sourceText)
            row.sourceText:SetTextColor(unpack(sourceInfo.color))
            
            local infoText = ""
            if data.cost then infoText = "|cffffd700" .. data.cost .. "|r" end
            if data.vendor then
                if infoText ~= "" then infoText = infoText .. " - " end
                infoText = infoText .. data.vendor
            end
            if data.sourceTags and #data.sourceTags > 0 then
                local tagText = table.concat(data.sourceTags, ", ")
                if infoText ~= "" then
                    infoText = infoText .. " |cff666666| |r"
                end
                infoText = infoText .. "|cff999999Tags:|r " .. tagText
            end
            row.infoText:SetText(infoText)
            
            row.typeBadge:SetText(sourceInfo.name)
            row.typeBadge:SetTextColor(unpack(sourceInfo.color))

            local repRequirements = self:GetReputationRequirements(data)
            if row.repBadge then
                row.repBadge.repRequirements = repRequirements
                row.repBadge:SetShown(#repRequirements > 0)
            end
            
            row.vendorData = data.type == "vendor" and data.data or nil
            row.vendorName = data.vendor
            
            local hasCoords = self.ResultHasWaypoint and self:ResultHasWaypoint(data)
            row.waypointBtn:SetEnabled(hasCoords and true or false)
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
    self:UpdateSetWaypointButton()
    self:UpdateAddShoppingButton()
    self:UpdateMapAllButton()
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
    self:UpdateItemCategoryButtons()
end

function HC:UpdateItemCategoryButtons()
    local showCategories = currentTab == "items"
    if self.itemCategoryLabel then
        self.itemCategoryLabel:SetShown(showCategories)
    end
    for catID, btn in pairs(self.itemCategoryButtons or {}) do
        btn:SetShown(showCategories)
        if showCategories and catID == currentItemCategory then
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
        local pctCollectedTrackable = stats.trackableTotal > 0 and math.floor((stats.collectedTrackable / stats.trackableTotal) * 100) or 0
        local pctTrackableKnown = stats.knownTotal > 0 and math.floor((stats.trackableTotal / stats.knownTotal) * 100) or 0
        self.statsText:SetText(string.format(
            "Collected/Trackable: %d/%d (%d%%)  |  Trackable/Known: %d/%d (%d%%)",
            stats.collectedTrackable, stats.trackableTotal, pctCollectedTrackable,
            stats.trackableTotal, stats.knownTotal, pctTrackableKnown
        ))
    end
    if self.progressText then
        self.progressText:SetText(string.format(
            "C/T: %d/%d  |  T/K: %d/%d  |  Unknown Sources: %d",
            stats.collectedTrackable, stats.trackableTotal,
            stats.trackableTotal, stats.knownTotal,
            stats.unknownSourceItems
        ))
    end
end

function HC:ToggleUI()
    if not self.mainFrame then self:CreateUI() end
    if self.mainFrame:IsShown() then
        self.mainFrame:Hide()
        if self.shoppingListPanel then self.shoppingListPanel:Hide() end
    else
        self.mainFrame:Show()
        if self.settingsPanel then self.settingsPanel:Hide() end
        if self.content then self.content:Show() end
        if self.previewPanel then self.previewPanel:Show() end
        if self.CacheCollection and not self.catalogReady then
            self:CacheCollection()
        end
        self:UpdateTabButtons()
        self:DoSearch()
        if self.UpdatePreview then
            self:UpdatePreview(selectedItem)
        end
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
