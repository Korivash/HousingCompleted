---------------------------------------------------
-- Housing Completed - UI.lua
-- Modern, comprehensive user interface
-- Author: Korivash
---------------------------------------------------
local addonName, HC = ...

-- UI Constants
local FRAME_WIDTH = 950
local FRAME_HEIGHT = 650
local SIDEBAR_WIDTH = 220
local HEADER_HEIGHT = 70
local ITEM_HEIGHT = 55
local ITEMS_PER_PAGE = 8

-- Modern Color Scheme
local COLORS = {
    background = {0.05, 0.05, 0.08, 0.98},
    headerBg = {0.08, 0.08, 0.12, 1},
    sidebar = {0.04, 0.04, 0.06, 1},
    accent = {0.2, 0.9, 0.6, 1},
    accentAlt = {0.4, 0.8, 1, 1},
    gold = {1, 0.82, 0, 1},
    text = {1, 1, 1, 1},
    textMuted = {0.5, 0.5, 0.55, 1},
    textDim = {0.35, 0.35, 0.4, 1},
    collected = {0.2, 0.9, 0.4, 1},
    notCollected = {0.7, 0.3, 0.3, 1},
    button = {0.12, 0.12, 0.18, 1},
    buttonHover = {0.18, 0.18, 0.28, 1},
    buttonActive = {0.15, 0.4, 0.3, 1},
    border = {0.2, 0.2, 0.25, 1},
    row = {0.08, 0.08, 0.12, 0.8},
    rowHover = {0.12, 0.12, 0.18, 1},
    achievement = {1, 0.8, 0.2, 1},
    quest = {1, 1, 0.4, 1},
    vendor = {0.3, 0.9, 0.3, 1},
    reputation = {0.6, 0.4, 1, 1},
    profession = {1, 0.5, 0.2, 1},
    drop = {0.4, 0.7, 1, 1},
}

-- Local variables
local currentPage = 1
local totalPages = 1
local currentResults = {}
local currentTab = "all"
local currentFilters = {}

-- Helper function for checkbox/radio text compatibility
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

---------------------------------------------------
-- UI Helper Functions
---------------------------------------------------
local function CreateStyledButton(parent, text, width, height)
    local btn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    btn:SetSize(width or 120, height or 28)
    btn:SetText(text)
    btn:SetNormalFontObject(GameFontNormalSmall)
    btn:SetHighlightFontObject(GameFontHighlightSmall)
    return btn
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
    placeholder:SetText("Search items, vendors, zones...")
    placeholder:SetTextColor(0.4, 0.4, 0.45)
    
    editBox:SetScript("OnTextChanged", function(self)
        if self:GetText() ~= "" then
            placeholder:Hide()
        else
            placeholder:Show()
        end
    end)
    
    editBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)
    
    container.editBox = editBox
    container.placeholder = placeholder
    return container
end

---------------------------------------------------
-- Main UI Creation
---------------------------------------------------
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
    
    if HousingCompletedDB and HousingCompletedDB.windowPos 
       and HousingCompletedDB.windowPos[1] 
       and HousingCompletedDB.windowPos[3]
       and HousingCompletedDB.windowPos[4] then
        local pos = HousingCompletedDB.windowPos
        frame:ClearAllPoints()
        frame:SetPoint(pos[1], UIParent, pos[2], pos[3], pos[4])
    end
    
    frame:SetScale(HousingCompletedDB.scale or 1.0)
    frame:Hide()
    self.mainFrame = frame
    
    self:CreateHeader(frame)
    self:CreateSidebar(frame)
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
    stats:SetText("Loading collection data...")
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
        if self:GetText() ~= "" then
            searchBox.placeholder:Hide()
        else
            searchBox.placeholder:Show()
        end
        if userInput then
            C_Timer.After(0.3, function() HC:DoSearch() end)
        end
    end)
    self.searchBox = searchBox.editBox
    y = y - 50
    
    local tabLabel = sidebar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    tabLabel:SetPoint("TOPLEFT", 15, y)
    tabLabel:SetText("CATEGORIES")
    tabLabel:SetTextColor(unpack(COLORS.accentAlt))
    y = y - 25
    
    local tabs = {
        { id = "all", name = "All Items", icon = "Interface\\Icons\\INV_Misc_Bag_10" },
        { id = "vendor", name = "Vendors", icon = "Interface\\Icons\\INV_Misc_Coin_01" },
        { id = "achievement", name = "Achievements", icon = "Interface\\Icons\\Achievement_General_100kQuests" },
        { id = "quest", name = "Quests", icon = "Interface\\Icons\\INV_Misc_Book_07" },
        { id = "reputation", name = "Reputation", icon = "Interface\\Icons\\Achievement_Reputation_01" },
        { id = "profession", name = "Professions", icon = "Interface\\Icons\\Trade_BlackSmithing" },
    }
    
    self.tabButtons = {}
    for _, tabInfo in ipairs(tabs) do
        local btn = CreateFrame("Button", nil, sidebar)
        btn:SetSize(SIDEBAR_WIDTH - 20, 28)
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
        
        local label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetPoint("LEFT", icon, "RIGHT", 8, 0)
        label:SetText(tabInfo.name)
        label:SetTextColor(0.8, 0.8, 0.8)
        btn.label = label
        
        btn:SetScript("OnEnter", function(self)
            if currentTab ~= self.tabID then
                self.bg:SetColorTexture(0.15, 0.15, 0.2, 1)
            end
        end)
        btn:SetScript("OnLeave", function(self)
            if currentTab ~= self.tabID then
                self.bg:SetColorTexture(0, 0, 0, 0)
            end
        end)
        btn:SetScript("OnClick", function(self)
            currentTab = self.tabID
            HC:UpdateTabButtons()
            HC:DoSearch()
        end)
        
        self.tabButtons[tabInfo.id] = btn
        y = y - 30
    end
    y = y - 15
    
    local divider = sidebar:CreateTexture(nil, "ARTWORK")
    divider:SetSize(SIDEBAR_WIDTH - 30, 1)
    divider:SetPoint("TOP", 0, y)
    divider:SetColorTexture(0.2, 0.2, 0.25, 1)
    y = y - 20
    
    local filterLabel = sidebar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    filterLabel:SetPoint("TOPLEFT", 15, y)
    filterLabel:SetText("FILTERS")
    filterLabel:SetTextColor(unpack(COLORS.accentAlt))
    y = y - 25
    
    local collectedCb = CreateFrame("CheckButton", nil, sidebar, "UICheckButtonTemplate")
    collectedCb:SetPoint("TOPLEFT", 10, y)
    SetButtonText(collectedCb, "Show Collected", 0.7, 0.7, 0.7)
    collectedCb:SetChecked(true)
    collectedCb:SetScript("OnClick", function(self)
        currentFilters.showCollected = self:GetChecked()
        HC:DoSearch()
    end)
    self.collectedCb = collectedCb
    y = y - 26
    
    local uncollectedCb = CreateFrame("CheckButton", nil, sidebar, "UICheckButtonTemplate")
    uncollectedCb:SetPoint("TOPLEFT", 10, y)
    SetButtonText(uncollectedCb, "Show Uncollected", 0.7, 0.7, 0.7)
    uncollectedCb:SetChecked(true)
    uncollectedCb:SetScript("OnClick", function(self)
        currentFilters.showUncollected = self:GetChecked()
        HC:DoSearch()
    end)
    self.uncollectedCb = uncollectedCb
    y = y - 40
    
    local quickLabel = sidebar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    quickLabel:SetPoint("TOPLEFT", 15, y)
    quickLabel:SetText("PROGRESS")
    quickLabel:SetTextColor(unpack(COLORS.accentAlt))
    y = y - 25
    
    local progressText = sidebar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    progressText:SetPoint("TOPLEFT", 15, y)
    progressText:SetText("Collected: 0 / 0")
    progressText:SetTextColor(0.7, 0.7, 0.7)
    self.progressText = progressText
    
    self.sidebar = sidebar
end

function HC:CreateContent(parent)
    local content = CreateFrame("Frame", nil, parent)
    content:SetPoint("TOPLEFT", SIDEBAR_WIDTH, -HEADER_HEIGHT)
    content:SetPoint("BOTTOMRIGHT", 0, 0)
    
    local resultsFrame = CreateFrame("Frame", nil, content, "BackdropTemplate")
    resultsFrame:SetPoint("TOPLEFT", 15, -15)
    resultsFrame:SetPoint("BOTTOMRIGHT", -15, 60)
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
    
    local prevBtn = CreateStyledButton(pagination, "< Prev", 80, 28)
    prevBtn:SetPoint("LEFT", 0, 0)
    prevBtn:SetScript("OnClick", function()
        if currentPage > 1 then
            currentPage = currentPage - 1
            HC:UpdateResults()
        end
    end)
    self.prevBtn = prevBtn
    
    local nextBtn = CreateStyledButton(pagination, "Next >", 80, 28)
    nextBtn:SetPoint("RIGHT", 0, 0)
    nextBtn:SetScript("OnClick", function()
        if currentPage < totalPages then
            currentPage = currentPage + 1
            HC:UpdateResults()
        end
    end)
    self.nextBtn = nextBtn
    
    local pageText = pagination:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    pageText:SetPoint("CENTER")
    pageText:SetText("Page 1 of 1")
    pageText:SetTextColor(unpack(COLORS.textMuted))
    self.pageText = pageText
    
    local statusText = pagination:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    statusText:SetPoint("LEFT", prevBtn, "RIGHT", 15, 0)
    statusText:SetText("0 results")
    statusText:SetTextColor(unpack(COLORS.textDim))
    self.statusText = statusText
    
    self.content = content
    self.pagination = pagination
end

function HC:CreateResultRow(parent, index)
    local row = CreateFrame("Button", nil, parent, "BackdropTemplate")
    row:SetHeight(ITEM_HEIGHT - 5)
    row:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
    row:SetBackdropColor(unpack(COLORS.row))
    
    row:SetScript("OnEnter", function(self)
        self:SetBackdropColor(unpack(COLORS.rowHover))
    end)
    row:SetScript("OnLeave", function(self)
        self:SetBackdropColor(unpack(COLORS.row))
    end)
    
    local typeIcon = row:CreateTexture(nil, "ARTWORK")
    typeIcon:SetSize(32, 32)
    typeIcon:SetPoint("LEFT", 10, 0)
    row.typeIcon = typeIcon
    
    local collectedIcon = row:CreateTexture(nil, "OVERLAY")
    collectedIcon:SetSize(16, 16)
    collectedIcon:SetPoint("TOPLEFT", typeIcon, "TOPRIGHT", -8, 4)
    collectedIcon:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
    collectedIcon:Hide()
    row.collectedIcon = collectedIcon
    
    local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameText:SetPoint("TOPLEFT", typeIcon, "TOPRIGHT", 10, -4)
    nameText:SetPoint("RIGHT", -180, 0)
    nameText:SetJustifyH("LEFT")
    nameText:SetWordWrap(false)
    row.nameText = nameText
    
    local sourceText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    sourceText:SetPoint("TOPLEFT", nameText, "BOTTOMLEFT", 0, -2)
    sourceText:SetPoint("RIGHT", -180, 0)
    sourceText:SetJustifyH("LEFT")
    sourceText:SetTextColor(unpack(COLORS.textMuted))
    row.sourceText = sourceText
    
    local infoText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    infoText:SetPoint("TOPLEFT", sourceText, "BOTTOMLEFT", 0, -2)
    infoText:SetPoint("RIGHT", -180, 0)
    infoText:SetJustifyH("LEFT")
    infoText:SetTextColor(unpack(COLORS.textDim))
    row.infoText = infoText
    
    local waypointBtn = CreateFrame("Button", nil, row)
    waypointBtn:SetSize(28, 28)
    waypointBtn:SetPoint("RIGHT", -10, 0)
    waypointBtn:SetNormalTexture("Interface\\Minimap\\Tracking\\TrivialQuests")
    waypointBtn:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    waypointBtn:SetScript("OnClick", function()
        if row.vendorData then
            local v = row.vendorData
            if v.x and v.y and v.mapID then
                HC:SetWaypoint(v.x, v.y, v.mapID, v.name)
            end
        elseif row.vendorName then
            local vendor = HC:GetVendorByName(row.vendorName)
            if vendor and vendor.x and vendor.y and vendor.mapID then
                HC:SetWaypoint(vendor.x, vendor.y, vendor.mapID, vendor.name)
            else
                print("|cff00ff99Housing Completed|r: No coordinates available.")
            end
        end
    end)
    waypointBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine("Set Waypoint")
        GameTooltip:Show()
    end)
    waypointBtn:SetScript("OnLeave", GameTooltip_Hide)
    row.waypointBtn = waypointBtn
    
    local typeBadge = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    typeBadge:SetPoint("RIGHT", waypointBtn, "LEFT", -10, 0)
    typeBadge:SetJustifyH("RIGHT")
    row.typeBadge = typeBadge
    
    row:Hide()
    return row
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
    waypointLabel:SetTextColor(1, 1, 1)
    y = y - 30
    
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
        y = y - 26
    end
    y = y - 20
    
    local scaleLabel = settings:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    scaleLabel:SetPoint("TOPLEFT", 20, y)
    scaleLabel:SetText("UI Scale:")
    scaleLabel:SetTextColor(1, 1, 1)
    y = y - 30
    
    local scaleSlider = CreateFrame("Slider", nil, settings, "OptionsSliderTemplate")
    scaleSlider:SetPoint("TOPLEFT", 30, y)
    scaleSlider:SetWidth(200)
    scaleSlider:SetMinMaxValues(0.5, 1.5)
    scaleSlider:SetValueStep(0.05)
    scaleSlider:SetValue(HousingCompletedDB.scale or 1.0)
    scaleSlider.Low:SetText("50%")
    scaleSlider.High:SetText("150%")
    local sliderText = GetButtonText(scaleSlider)
    if sliderText then
        sliderText:SetText(string.format("%.0f%%", (HousingCompletedDB.scale or 1.0) * 100))
    end
    scaleSlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value * 20 + 0.5) / 20
        HousingCompletedDB.scale = value
        local text = GetButtonText(self)
        if text then
            text:SetText(string.format("%.0f%%", value * 100))
        end
        HC.mainFrame:SetScale(value)
    end)
    self.scaleSlider = scaleSlider
    y = y - 50
    
    local minimapCb = CreateFrame("CheckButton", nil, settings, "UICheckButtonTemplate")
    minimapCb:SetPoint("TOPLEFT", 20, y)
    SetButtonText(minimapCb, "Show Minimap Button", 0.8, 0.8, 0.8)
    minimapCb:SetChecked(HousingCompletedDB.showMinimapButton ~= false)
    minimapCb:SetScript("OnClick", function(self)
        HousingCompletedDB.showMinimapButton = self:GetChecked()
        local LibDBIcon = LibStub("LibDBIcon-1.0", true)
        if LibDBIcon then
            if HousingCompletedDB.showMinimapButton then
                LibDBIcon:Show("HousingCompleted")
            else
                LibDBIcon:Hide("HousingCompleted")
            end
            HousingCompletedDB.minimap.hide = not HousingCompletedDB.showMinimapButton
        end
    end)
    y = y - 30
    
    -- Show Arrow checkbox
    local arrowCb = CreateFrame("CheckButton", nil, settings, "UICheckButtonTemplate")
    arrowCb:SetPoint("TOPLEFT", 20, y)
    SetButtonText(arrowCb, "Show Navigation Arrow", 0.8, 0.8, 0.8)
    arrowCb:SetChecked(HousingCompletedDB.showArrow ~= false)
    arrowCb:SetScript("OnClick", function(self)
        HousingCompletedDB.showArrow = self:GetChecked()
        if not self:GetChecked() and HC.HideArrow then
            HC:HideArrow()
        end
    end)
    y = y - 50
    
    local backBtn = CreateStyledButton(settings, "Back", 100, 32)
    backBtn:SetPoint("BOTTOMLEFT", 20, 20)
    backBtn:SetScript("OnClick", function() HC:ToggleSettings() end)
    
    self.settingsPanel = settings
end

function HC:UpdateWaypointRadios()
    local currentOpt = HousingCompletedDB.waypointSystem or "tomtom"
    for i = 1, 3 do
        local radio = self["waypointRadio" .. i]
        if radio then
            radio:SetChecked(radio.option == currentOpt)
        end
    end
end

---------------------------------------------------
-- Search and Display
---------------------------------------------------
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
    
    local filteredResults = {}
    for _, result in ipairs(results) do
        local show = true
        if result.collected and not filters.showCollected then
            show = false
        elseif not result.collected and not filters.showUncollected then
            show = false
        end
        if show then
            table.insert(filteredResults, result)
        end
    end
    
    currentResults = filteredResults
    currentPage = 1
    totalPages = math.max(1, math.ceil(#currentResults / ITEMS_PER_PAGE))
    
    self:UpdateResults()
    self:UpdateStats()
end

function HC:UpdateResults()
    for i = 1, ITEMS_PER_PAGE do
        self.resultRows[i]:Hide()
    end
    
    local startIdx = (currentPage - 1) * ITEMS_PER_PAGE + 1
    local endIdx = math.min(startIdx + ITEMS_PER_PAGE - 1, #currentResults)
    
    for i = startIdx, endIdx do
        local rowIndex = i - startIdx + 1
        local row = self.resultRows[rowIndex]
        local data = currentResults[i]
        
        if data then
            local sourceInfo = self:GetSourceTypeInfo(data.type)
            row.typeIcon:SetTexture(sourceInfo.icon)
            
            row.nameText:SetText(data.name or "Unknown")
            if data.collected then
                row.nameText:SetTextColor(unpack(COLORS.collected))
                row.collectedIcon:Show()
            else
                row.nameText:SetTextColor(1, 1, 1)
                row.collectedIcon:Hide()
            end
            
            local sourceText = data.source or ""
            if data.type == "vendor" then
                sourceText = data.zone or ""
                if data.data and data.data.subzone then
                    sourceText = sourceText .. " - " .. data.data.subzone
                end
            end
            row.sourceText:SetText(sourceText)
            row.sourceText:SetTextColor(unpack(sourceInfo.color))
            
            local infoText = ""
            if data.cost then
                infoText = "|cffffd700" .. data.cost .. "|r"
            end
            if data.vendor then
                if infoText ~= "" then infoText = infoText .. " - " end
                infoText = infoText .. data.vendor
            end
            if data.zone and data.type ~= "vendor" then
                if infoText ~= "" then infoText = infoText .. " - " end
                infoText = infoText .. data.zone
            end
            row.infoText:SetText(infoText)
            
            row.typeBadge:SetText(sourceInfo.name)
            row.typeBadge:SetTextColor(unpack(sourceInfo.color))
            
            if data.type == "vendor" then
                row.vendorData = data.data
                row.vendorName = nil
            else
                row.vendorData = nil
                row.vendorName = data.vendor
            end
            
            if data.type == "vendor" and data.data and data.data.x and data.data.y and data.data.mapID then
                row.waypointBtn:Enable()
                row.waypointBtn:SetAlpha(1)
            elseif data.vendor then
                local vendor = self:GetVendorByName(data.vendor)
                if vendor and vendor.x and vendor.y and vendor.mapID then
                    row.waypointBtn:Enable()
                    row.waypointBtn:SetAlpha(1)
                else
                    row.waypointBtn:Disable()
                    row.waypointBtn:SetAlpha(0.3)
                end
            else
                row.waypointBtn:Disable()
                row.waypointBtn:SetAlpha(0.3)
            end
            
            row:Show()
        end
    end
    
    self.pageText:SetText(string.format("Page %d of %d", currentPage, totalPages))
    self.prevBtn:SetEnabled(currentPage > 1)
    self.nextBtn:SetEnabled(currentPage < totalPages)
    self.statusText:SetText(string.format("%d results", #currentResults))
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
        local percent = stats.totalItems > 0 and math.floor((stats.collected / stats.totalItems) * 100) or 0
        self.statsText:SetText(string.format("Collection: %d / %d (%d%%)", stats.collected, stats.totalItems, percent))
    end
    
    if self.progressText then
        self.progressText:SetText(string.format("Collected: %d / %d", stats.collected, stats.totalItems))
    end
end

function HC:RefreshUI()
    if self.mainFrame and self.mainFrame:IsShown() then
        self:DoSearch()
    end
end

---------------------------------------------------
-- Toggle Functions
---------------------------------------------------
function HC:ToggleUI()
    if not self.mainFrame then
        self:CreateUI()
    end
    
    if self.mainFrame:IsShown() then
        self.mainFrame:Hide()
    else
        self.mainFrame:Show()
        self.settingsPanel:Hide()
        self.content:Show()
        self:UpdateTabButtons()
        self:DoSearch()
    end
end

function HC:ToggleSettings()
    if self.settingsPanel:IsShown() then
        self.settingsPanel:Hide()
        self.content:Show()
    else
        self.settingsPanel:Show()
        self.content:Hide()
    end
end

function HC:OpenSettings()
    if not self.mainFrame then
        self:CreateUI()
    end
    self.mainFrame:Show()
    self.settingsPanel:Show()
    self.content:Hide()
end
