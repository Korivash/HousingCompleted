local addonName, HC = ...

local FRAME_WIDTH = 1680
local FRAME_HEIGHT = 940
local SIDEBAR_WIDTH = 350
local PREVIEW_WIDTH = 390
local HEADER_HEIGHT = 128
local ITEM_HEIGHT = 58
local ITEMS_PER_PAGE = 10
local RESULTS_HEADER_HEIGHT = 22

local COLORS = {
    background = {0.045, 0.05, 0.06, 0.97},
    headerBg = {0.06, 0.075, 0.1, 0.98},
    sidebar = {0.055, 0.065, 0.085, 0.98},
    preview = {0.05, 0.065, 0.09, 0.98},
    accent = {0.23, 0.63, 1.0, 1},
    accentAlt = {0.44, 0.76, 1.0, 1},
    gold = {1, 0.82, 0, 1},
    text = {1, 1, 1, 1},
    textMuted = {0.79, 0.85, 0.94, 1},
    textDim = {0.53, 0.62, 0.75, 1},
    collected = {0.56, 0.95, 0.54, 1},
    row = {0.08, 0.095, 0.125, 0.88},
    rowHover = {0.11, 0.14, 0.19, 1},
    rowSelected = {0.13, 0.19, 0.29, 1},
    border = {0.17, 0.24, 0.35, 1},
}

local currentPage = 1
local totalPages = 1
local currentResults = {}
local currentTab = "acquire"
local currentPrimaryTab = "overview"
local currentViewMode = "grid"
local currentSourceView = "all"
local currentItemCategory = "all"
local selectedItem = nil
local currentSortKey = "name"
local currentSortAscending = true
local TryLoadHousingPreviewModules
local analyticsSummaryText = ""

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

local function FormatMoneyValue(copper)
    if HC and HC.FormatMoney then
        return HC:FormatMoney(copper)
    end
    if not copper or copper <= 0 then return "-" end
    local g = math.floor(copper / 10000)
    local s = math.floor((copper % 10000) / 100)
    if g > 0 then
        return string.format("%dg %02ds", g, s)
    end
    return string.format("%ds", s)
end

local function FormatMarginValue(margin)
    if not margin then
        return "-"
    end
    return string.format("%.1f%%", margin)
end

local function BuildSelectionKey(resultData, getItemID)
    if not resultData then return nil end

    local itemID = getItemID and getItemID(resultData) or nil
    if itemID then
        return "id:" .. tostring(itemID)
    end

    local name = resultData.name or (resultData.data and resultData.data.name)
    if type(name) == "string" and name ~= "" then
        return "name:" .. name:lower()
    end

    return nil
end

local function FindResultBySelectionKey(results, selectionKey, getItemID)
    if type(results) ~= "table" or not selectionKey then
        return nil
    end

    for _, resultData in ipairs(results) do
        if BuildSelectionKey(resultData, getItemID) == selectionKey then
            return resultData
        end
    end

    return nil
end

local function FormatReagentSource(source)
    if source == "vendor" then
        return "Vendor"
    end
    if source == "auction" then
        return "AH/TSM"
    end
    if source == "fixed" then
        return "Fixed"
    end
    return "Unknown"
end

local function FormatCraftMaterialsValue(economics)
    if not economics then
        return "-"
    end

    local reagents = economics.reagents or {}
    local missing = economics.missingMaterials or {}
    local lines = {}

    if economics.craftCost then
        table.insert(lines, "Total: " .. FormatMoneyValue(economics.craftCost))
    end

    local maxShown = 4
    for idx = 1, math.min(maxShown, #reagents) do
        local reagent = reagents[idx]
        local qty = math.max(1, math.floor((tonumber(reagent.qty) or 1) + 0.5))
        local reagentName = reagent.name
            or (reagent.itemID and ("Item #" .. tostring(reagent.itemID)))
            or "Unknown Reagent"
        local lineCost = FormatMoneyValue(reagent.totalCost)
        local sourceText = FormatReagentSource(reagent.source)
        table.insert(lines, string.format("%dx %s (%s, %s)", qty, reagentName, lineCost, sourceText))
    end

    if #reagents > maxShown then
        table.insert(lines, string.format("+%d more reagents", #reagents - maxShown))
    end

    if #missing > 0 then
        local previewMissing = {}
        local maxMissingShown = 2
        for idx = 1, math.min(maxMissingShown, #missing) do
            local mat = missing[idx]
            local qty = math.max(1, math.floor((tonumber(mat.quantity) or 1) + 0.5))
            local matName = mat.name or (mat.itemID and ("Item #" .. tostring(mat.itemID))) or "Unknown"
            table.insert(previewMissing, string.format("%dx %s", qty, matName))
        end
        local missingText = table.concat(previewMissing, ", ")
        if #missing > maxMissingShown then
            missingText = missingText .. string.format(" (+%d more)", #missing - maxMissingShown)
        end
        table.insert(lines, "Missing: " .. missingText)
    end

    if #lines == 0 then
        if economics.craftCost then
            return "Total: " .. FormatMoneyValue(economics.craftCost) .. " (no reagent breakdown)"
        end
        return "-"
    end

    return table.concat(lines, "\n")
end

local function GetCharacterItemCount(itemID)
    if not itemID or not C_Item or not C_Item.GetItemCount then
        return 0
    end
    return C_Item.GetItemCount(itemID, true, false, true, true) or 0
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

local function EnsureUserUIState()
    HousingCompletedDB.ui = HousingCompletedDB.ui or {}
    if type(HousingCompletedDB.ui.primaryTab) ~= "string" or HousingCompletedDB.ui.primaryTab == "" then
        HousingCompletedDB.ui.primaryTab = "overview"
    end
    if HousingCompletedDB.ui.viewMode ~= "grid" and HousingCompletedDB.ui.viewMode ~= "list" then
        HousingCompletedDB.ui.viewMode = "grid"
    end
    HousingCompletedDB.ui.streamerMode = HousingCompletedDB.ui.streamerMode and true or false
    HousingCompletedDB.ui.performanceMode = HousingCompletedDB.ui.performanceMode and true or false
    HousingCompletedDB.ui.showSourceDetails = HousingCompletedDB.ui.showSourceDetails ~= false
    HousingCompletedDB.ui.compactMode = HousingCompletedDB.ui.compactMode and true or false
    HousingCompletedDB.ui.fontScale = tonumber(HousingCompletedDB.ui.fontScale) or 1.0
    HousingCompletedDB.ui.gridScale = tonumber(HousingCompletedDB.ui.gridScale) or 1.0

    HousingCompletedDB.favorites = HousingCompletedDB.favorites or {}
    HousingCompletedDB.favorites.items = HousingCompletedDB.favorites.items or {}
end

function HC:IsItemFavorite(resultData)
    if not resultData then return false end
    EnsureUserUIState()
    local itemID = self:GetResolvedItemID(resultData)
    if itemID then
        return HousingCompletedDB.favorites.items[itemID] == true
    end
    local name = resultData.name or (resultData.data and resultData.data.name)
    if name and name ~= "" then
        return HousingCompletedDB.favorites.items["name:" .. string.lower(name)] == true
    end
    return false
end

function HC:ToggleFavorite(resultData)
    if not resultData then return end
    EnsureUserUIState()
    local itemID = self:GetResolvedItemID(resultData)
    local key = itemID or ("name:" .. string.lower(resultData.name or ""))
    if not key then return end
    HousingCompletedDB.favorites.items[key] = not HousingCompletedDB.favorites.items[key]
    self:UpdateResults()
    self:UpdateStats()
    if self.UpdatePreview then
        self:UpdatePreview(selectedItem)
    end
end

function HC:CreateUI()
    if self.mainFrame then return end
    EnsureUserUIState()
    currentPrimaryTab = HousingCompletedDB.ui.primaryTab or currentPrimaryTab
    currentViewMode = HousingCompletedDB.ui.viewMode or currentViewMode
    
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
    frame:SetAlpha(tonumber(HousingCompletedDB.ui and HousingCompletedDB.ui.opacity) or 0.97)
    frame:Hide()
    self.mainFrame = frame

    local vignetteTop = frame:CreateTexture(nil, "BACKGROUND")
    vignetteTop:SetPoint("TOPLEFT", 2, -2)
    vignetteTop:SetPoint("TOPRIGHT", -2, -2)
    vignetteTop:SetHeight(220)
    vignetteTop:SetTexture("Interface\\Buttons\\WHITE8x8")
    if vignetteTop.SetGradientAlpha then
        vignetteTop:SetGradientAlpha("VERTICAL", 0.14, 0.25, 0.42, 0.28, 0.08, 0.12, 0.18, 0.02)
    else
        vignetteTop:SetVertexColor(0.24, 0.17, 0.09, 0.22)
    end

    local vignetteBottom = frame:CreateTexture(nil, "BACKGROUND")
    vignetteBottom:SetPoint("BOTTOMLEFT", 2, 2)
    vignetteBottom:SetPoint("BOTTOMRIGHT", -2, 2)
    vignetteBottom:SetHeight(180)
    vignetteBottom:SetTexture("Interface\\Buttons\\WHITE8x8")
    if vignetteBottom.SetGradientAlpha then
        vignetteBottom:SetGradientAlpha("VERTICAL", 0.06, 0.09, 0.13, 0.02, 0.09, 0.16, 0.24, 0.35)
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

    local topGlow = header:CreateTexture(nil, "BACKGROUND")
    topGlow:SetPoint("TOPLEFT", 0, 0)
    topGlow:SetPoint("TOPRIGHT", 0, 0)
    topGlow:SetHeight(64)
    topGlow:SetTexture("Interface\\Buttons\\WHITE8x8")
    if topGlow.SetGradientAlpha then
        topGlow:SetGradientAlpha("VERTICAL", 0.22, 0.44, 0.75, 0.2, 0.03, 0.06, 0.1, 0)
    else
        topGlow:SetVertexColor(0.18, 0.32, 0.55, 0.2)
    end

    local title = header:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 20, -12)
    title:SetText("|cff66b8ffHousing|r |cfff5fbffCompleted|r")

    local subtitle = header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    subtitle:SetPoint("TOPLEFT", 20, -34)
    subtitle:SetText("Premium housing collection tracker")
    subtitle:SetTextColor(unpack(COLORS.textMuted))

    local version = header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    version:SetPoint("LEFT", title, "RIGHT", 10, 0)
    version:SetText("v" .. HC.version)
    version:SetTextColor(unpack(COLORS.textDim))

    local closeBtn = CreateFrame("Button", nil, header, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", -5, -5)
    closeBtn:SetScript("OnClick", function() parent:Hide() end)

    local settingsBtn = CreateFrame("Button", nil, header)
    settingsBtn:SetSize(24, 24)
    settingsBtn:SetPoint("RIGHT", closeBtn, "LEFT", -5, 0)
    settingsBtn:SetNormalTexture("Interface\\Icons\\INV_Misc_Gear_01")
    settingsBtn:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    settingsBtn:SetScript("OnClick", function() HC:ToggleSettings() end)

    local tabsHost = CreateFrame("Frame", nil, header, "BackdropTemplate")
    tabsHost:SetPoint("TOPLEFT", 290, -8)
    tabsHost:SetPoint("TOPRIGHT", -72, -8)
    tabsHost:SetHeight(34)
    tabsHost:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
    tabsHost:SetBackdropColor(0.07, 0.09, 0.13, 0.85)

    local topTabs = {
        { id = "overview", label = "Overview", click = function()
            currentPrimaryTab = "overview"
            currentSourceView = "all"
            currentTab = "acquire"
            HC:DoSearch()
        end },
        { id = "items", label = "Items", click = function()
            currentPrimaryTab = "items"
            currentSourceView = "items"
            currentTab = "acquire"
            HC:DoSearch()
        end },
        { id = "sources", label = "Sources", click = function()
            currentPrimaryTab = "sources"
            currentSourceView = "all"
            currentTab = "acquire"
            HC:DoSearch()
        end },
        { id = "filters", label = "Filters", click = function()
            currentPrimaryTab = "filters"
            if HC.sidebarScrollFrame then
                HC.sidebarScrollFrame:SetVerticalScroll(210)
            end
            HC:DoSearch()
        end },
        { id = "favorites", label = "Favorites", click = function()
            currentPrimaryTab = "favorites"
            currentTab = "collection"
            HC:DoSearch()
        end },
        { id = "profiles", label = "Profiles", click = function()
            currentPrimaryTab = "profiles"
            HC:ToggleSettings()
        end },
    }

    self.primaryTabButtons = {}
    local tabWidth = 118
    for idx, tabInfo in ipairs(topTabs) do
        local btn = CreateFrame("Button", nil, tabsHost, "BackdropTemplate")
        btn:SetSize(tabWidth, 30)
        if idx == 1 then
            btn:SetPoint("LEFT", 8, 0)
        else
            btn:SetPoint("LEFT", self.primaryTabButtons[topTabs[idx - 1].id], "RIGHT", 6, 0)
        end
        btn.tabID = tabInfo.id
        btn:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        btn:SetBackdropColor(0.09, 0.11, 0.16, 0.94)
        btn:SetBackdropBorderColor(0.17, 0.24, 0.35, 1)

        local label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        label:SetPoint("CENTER", 0, 2)
        label:SetText(tabInfo.label)
        label:SetTextColor(unpack(COLORS.textMuted))
        btn.label = label

        local underline = btn:CreateTexture(nil, "ARTWORK")
        underline:SetPoint("BOTTOMLEFT", 6, 3)
        underline:SetPoint("BOTTOMRIGHT", -6, 3)
        underline:SetHeight(2)
        underline:SetColorTexture(unpack(COLORS.accent))
        btn.underline = underline

        btn:SetScript("OnEnter", function(selfBtn)
            if currentPrimaryTab ~= selfBtn.tabID then
                selfBtn:SetBackdropColor(0.11, 0.14, 0.2, 0.98)
            end
        end)
        btn:SetScript("OnLeave", function(selfBtn)
            if currentPrimaryTab ~= selfBtn.tabID then
                selfBtn:SetBackdropColor(0.09, 0.11, 0.16, 0.94)
            end
        end)
        btn:SetScript("OnClick", function()
            tabInfo.click()
            if HousingCompletedDB and HousingCompletedDB.ui then
                HousingCompletedDB.ui.primaryTab = currentPrimaryTab
            end
            HC:UpdatePrimaryTabs()
        end)

        self.primaryTabButtons[tabInfo.id] = btn
    end

    local completionContainer = CreateFrame("Frame", nil, header, "BackdropTemplate")
    completionContainer:SetPoint("TOPLEFT", 20, -58)
    completionContainer:SetPoint("TOPRIGHT", -20, -58)
    completionContainer:SetHeight(78)
    completionContainer:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    completionContainer:SetBackdropColor(0.065, 0.085, 0.12, 0.95)
    completionContainer:SetBackdropBorderColor(0.17, 0.24, 0.35, 1)

    local completionLabel = completionContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    completionLabel:SetPoint("TOPLEFT", 12, -8)
    completionLabel:SetText("Housing Completion")
    completionLabel:SetTextColor(unpack(COLORS.textMuted))

    local completionValue = completionContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    completionValue:SetPoint("TOPRIGHT", -12, -8)
    completionValue:SetText("0%")
    completionValue:SetTextColor(unpack(COLORS.accentAlt))
    self.completionValueText = completionValue

    local progressBg = completionContainer:CreateTexture(nil, "ARTWORK")
    progressBg:SetPoint("TOPLEFT", 12, -28)
    progressBg:SetPoint("TOPRIGHT", -12, -28)
    progressBg:SetHeight(12)
    progressBg:SetTexture("Interface\\Buttons\\WHITE8x8")
    progressBg:SetColorTexture(0.11, 0.13, 0.17, 0.95)

    local progressBar = completionContainer:CreateTexture(nil, "ARTWORK")
    progressBar:SetPoint("TOPLEFT", progressBg, "TOPLEFT", 1, -1)
    progressBar:SetHeight(10)
    progressBar:SetWidth(2)
    progressBar:SetTexture("Interface\\Buttons\\WHITE8x8")
    progressBar:SetColorTexture(unpack(COLORS.accent))
    self.completionBar = progressBar
    self.completionBarWidth = 2

    local metrics = completionContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    metrics:SetPoint("TOPLEFT", 12, -45)
    metrics:SetPoint("TOPRIGHT", -12, -45)
    metrics:SetJustifyH("LEFT")
    metrics:SetText("Missing: 0  | Favorites: 0  | Recent: 0")
    metrics:SetTextColor(unpack(COLORS.textDim))
    self.statsText = metrics

    local nextActionText = completionContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    nextActionText:SetPoint("TOPLEFT", 12, -58)
    nextActionText:SetPoint("TOPRIGHT", -12, -58)
    nextActionText:SetJustifyH("LEFT")
    nextActionText:SetTextColor(unpack(COLORS.accentAlt))
    nextActionText:SetText("Next: Scanning best action...")
    self.nextActionText = nextActionText

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

    local clearBtn = CreateFrame("Button", nil, sidebar, "UIPanelButtonTemplate")
    clearBtn:SetSize(120, 22)
    clearBtn:SetPoint("TOPRIGHT", -10, -17)
    clearBtn:SetText("Clear Filters")
    clearBtn:SetScript("OnClick", function()
        if HC.searchBox then HC.searchBox:SetText("") end
        if HC.collectedCb then HC.collectedCb:SetChecked(true) end
        if HC.uncollectedCb then HC.uncollectedCb:SetChecked(true) end
        if HC.zoneOnlyCb then HC.zoneOnlyCb:SetChecked(false) end
        if HousingCompletedDB and HousingCompletedDB.filters then
            HousingCompletedDB.filters.expansions = {}
        end
        for _, cb in pairs(HC.expansionChecks or {}) do
            cb:SetChecked(false)
        end
        currentSourceView = "all"
        currentItemCategory = "all"
        currentPrimaryTab = "overview"
        if HousingCompletedDB and HousingCompletedDB.ui then
            HousingCompletedDB.ui.primaryTab = currentPrimaryTab
        end
        HC:UpdateTabButtons()
        HC:DoSearch()
    end)
    self.clearFiltersBtn = clearBtn

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
    tabLabel:SetText("PLATFORM")
    tabLabel:SetTextColor(unpack(COLORS.accentAlt))
    y = y - 20

    local navPanel = CreateFrame("Frame", nil, scrollChild, "BackdropTemplate")
    navPanel:SetPoint("TOPLEFT", 10, y)
    navPanel:SetSize(SIDEBAR_WIDTH - 44, 188)
    navPanel:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    navPanel:SetBackdropColor(0.09, 0.08, 0.11, 0.8)
    navPanel:SetBackdropBorderColor(0.2, 0.18, 0.24, 1)
    y = y - 194
    
    local tabs = {
        { id = "acquire", name = "Acquire", icon = "Interface\\Icons\\INV_Misc_Map_01" },
        { id = "craft", name = "Craft", icon = "Interface\\Icons\\INV_Misc_Gear_01" },
        { id = "economy", name = "Economy", icon = "Interface\\Icons\\INV_Misc_Coin_18" },
        { id = "planner", name = "Planner", icon = "Interface\\Icons\\INV_Scroll_03" },
        { id = "analytics", name = "Analytics", icon = "Interface\\Icons\\INV_Misc_Spyglass_03" },
        { id = "collection", name = "Collection", icon = "Interface\\Icons\\INV_Misc_Bag_10_Blue" },
    }
    
    self.tabButtons = {}
    local tabButtonWidth = SIDEBAR_WIDTH - 60
    local tabButtonHeight = 30
    for idx, tabInfo in ipairs(tabs) do
        local btn = CreateFrame("Button", nil, navPanel, "BackdropTemplate")
        btn:SetSize(tabButtonWidth, tabButtonHeight)
        btn:SetPoint("TOPLEFT", 8, -8 - (idx - 1) * (tabButtonHeight + 4))
        btn.tabID = tabInfo.id

        btn:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        btn:SetBackdropColor(0.12, 0.11, 0.14, 0.95)
        btn:SetBackdropBorderColor(0.24, 0.22, 0.28, 1)

        local bg = btn:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(0.16, 0.15, 0.19, 0.5)
        btn.bg = bg

        local icon = btn:CreateTexture(nil, "ARTWORK")
        icon:SetSize(16, 16)
        icon:SetPoint("LEFT", 8, 0)
        icon:SetTexture(tabInfo.icon)
        btn.icon = icon
        
        local label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        label:SetPoint("LEFT", icon, "RIGHT", 5, 0)
        label:SetText(tabInfo.name)
        label:SetTextColor(0.88, 0.86, 0.82)
        btn.label = label
        
        btn:SetScript("OnEnter", function(self)
            if currentTab ~= self.tabID then
                self.bg:SetColorTexture(0.22, 0.2, 0.26, 0.9)
                self:SetBackdropBorderColor(0.45, 0.36, 0.18, 1)
            end
        end)
        btn:SetScript("OnLeave", function(self)
            if currentTab ~= self.tabID then
                self.bg:SetColorTexture(0.16, 0.15, 0.19, 0.5)
                self:SetBackdropBorderColor(0.24, 0.22, 0.28, 1)
            end
        end)
        btn:SetScript("OnClick", function(self)
            currentTab = self.tabID
            if HousingCompletedDB then
                HousingCompletedDB.lastTab = currentTab
            end
            if currentTab == "economy" or currentTab == "planner" then
                currentSortKey = "profit"
                currentSortAscending = false
            end
            HC:UpdateTabButtons()
            HC:DoSearch()
        end)
        
        self.tabButtons[tabInfo.id] = btn
    end
    y = y - 4

    local modeLabel = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    modeLabel:SetPoint("TOPLEFT", 15, y)
    modeLabel:SetText("MODE")
    modeLabel:SetTextColor(unpack(COLORS.accentAlt))
    y = y - 18

    local modePanel = CreateFrame("Frame", nil, scrollChild, "BackdropTemplate")
    modePanel:SetPoint("TOPLEFT", 10, y)
    modePanel:SetSize(SIDEBAR_WIDTH - 44, 50)
    modePanel:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    modePanel:SetBackdropColor(0.08, 0.07, 0.1, 0.85)
    modePanel:SetBackdropBorderColor(0.2, 0.18, 0.24, 1)
    y = y - 56

    local modeItems = {
        { key = "hybrid", text = "Hybrid Mode" },
        { key = "goblin", text = "Goblin Mode" },
    }
    self.modeButtons = {}
    local modeButtonWidth = math.floor((SIDEBAR_WIDTH - 58) / 2)
    local modeButtonHeight = 20
    for idx, m in ipairs(modeItems) do
        local b = CreateFrame("Button", nil, modePanel, "BackdropTemplate")
        b:SetSize(modeButtonWidth, modeButtonHeight)
        local row = math.floor((idx - 1) / 2)
        local col = (idx - 1) % 2
        b:SetPoint("TOPLEFT", 4 + col * (modeButtonWidth + 2), -4 - row * (modeButtonHeight + 3))
        b.modeKey = m.key
        b:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        b:SetBackdropColor(0.14, 0.13, 0.16, 0.95)
        b:SetBackdropBorderColor(0.24, 0.22, 0.28, 1)
        local t = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        t:SetPoint("CENTER", 0, 0)
        t:SetText((m.key == "hybrid" and "Hybrid") or "Goblin")
        b.text = t
        b:SetScript("OnClick", function(selfBtn)
            if selfBtn.modeKey ~= "hybrid" and selfBtn.modeKey ~= "goblin" then
                return
            end
            HousingCompletedDB.mode = selfBtn.modeKey
            HC:UpdateTabButtons()
            HC:DoSearch()
        end)
        self.modeButtons[m.key] = b
    end
    y = y - 4

    local expansionLabel = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    expansionLabel:SetPoint("TOPLEFT", 15, y)
    expansionLabel:SetText("EXPANSION")
    expansionLabel:SetTextColor(unpack(COLORS.accentAlt))
    y = y - 18

    local expansionPanel = CreateFrame("Frame", nil, scrollChild, "BackdropTemplate")
    expansionPanel:SetPoint("TOPLEFT", 10, y)
    expansionPanel:SetSize(SIDEBAR_WIDTH - 44, 132)
    expansionPanel:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    expansionPanel:SetBackdropColor(0.08, 0.07, 0.1, 0.85)
    expansionPanel:SetBackdropBorderColor(0.2, 0.18, 0.24, 1)
    y = y - 138

    self.expansionChecks = {}
    local expansions = HC.Expansions or {}
    for idx, exp in ipairs(expansions) do
        local cb = CreateFrame("CheckButton", nil, expansionPanel, "UICheckButtonTemplate")
        local col = (idx - 1) % 2
        local row = math.floor((idx - 1) / 2)
        cb:SetPoint("TOPLEFT", 6 + col * ((SIDEBAR_WIDTH - 60) / 2), -4 - row * 20)
        cb:SetChecked(HousingCompletedDB.filters and HousingCompletedDB.filters.expansions and HousingCompletedDB.filters.expansions[exp.id] and true or false)
        SetButtonText(cb, exp.name, unpack(COLORS.textMuted))
        cb:SetScript("OnClick", function(selfBtn)
            HousingCompletedDB.filters.expansions = HousingCompletedDB.filters.expansions or {}
            HousingCompletedDB.filters.expansions[exp.id] = selfBtn:GetChecked() and true or nil
            HC:DoSearch()
        end)
        self.expansionChecks[exp.id] = cb
    end

    local sourceLabel = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    sourceLabel:SetPoint("TOPLEFT", 15, y)
    sourceLabel:SetText("SOURCE TYPE")
    sourceLabel:SetTextColor(unpack(COLORS.accentAlt))
    y = y - 18

    local sourcePanel = CreateFrame("Frame", nil, scrollChild, "BackdropTemplate")
    sourcePanel:SetPoint("TOPLEFT", 10, y)
    sourcePanel:SetSize(SIDEBAR_WIDTH - 44, 318)
    sourcePanel:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    sourcePanel:SetBackdropColor(0.08, 0.07, 0.1, 0.85)
    sourcePanel:SetBackdropBorderColor(0.2, 0.18, 0.24, 1)
    y = y - 324

    local sourceViews = {
        { id = "all", name = "All Items", icon = "Interface\\Icons\\INV_Misc_Bag_10" },
        { id = "items", name = "Item Browser", icon = "Interface\\Icons\\INV_Misc_Bag_10_Blue" },
        { id = "vendor", name = "Vendors", icon = "Interface\\Icons\\INV_Misc_Coin_01" },
        { id = "profession", name = "Professions", icon = "Interface\\Icons\\INV_Misc_Note_01" },
        { id = "reputation", name = "Reputation", icon = "Interface\\Icons\\Achievement_Reputation_08" },
        { id = "achievement", name = "Achievements", icon = "Interface\\Icons\\Achievement_General_100kQuests" },
        { id = "quest", name = "Quests", icon = "Interface\\Icons\\INV_Misc_Book_07" },
        { id = "drop", name = "Drops", icon = "Interface\\Icons\\INV_Misc_Bag_10_Blue" },
        { id = "auction", name = "Auction House", icon = "Interface\\Icons\\INV_Misc_Coin_02" },
        { id = "promo", name = "Promotions", icon = "Interface\\Icons\\INV_Misc_Gift_05" },
        { id = "unknown", name = "Unknown", icon = "Interface\\Icons\\INV_Misc_QuestionMark" },
    }

    self.sourceViewButtons = {}
    local sourceButtonWidth = SIDEBAR_WIDTH - 60
    local sourceButtonHeight = 24
    for idx, sv in ipairs(sourceViews) do
        local btn = CreateFrame("Button", nil, sourcePanel, "BackdropTemplate")
        btn:SetSize(sourceButtonWidth, sourceButtonHeight)
        btn:SetPoint("TOPLEFT", 8, -8 - (idx - 1) * (sourceButtonHeight + 3))
        btn.sourceID = sv.id
        btn:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        btn:SetBackdropColor(0.14, 0.13, 0.16, 0.95)
        btn:SetBackdropBorderColor(0.24, 0.22, 0.28, 1)
        local bg = btn:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(0.16, 0.15, 0.19, 0.5)
        btn.bg = bg
        local icon = btn:CreateTexture(nil, "ARTWORK")
        icon:SetSize(14, 14)
        icon:SetPoint("LEFT", 6, 0)
        icon:SetTexture(sv.icon)
        btn.icon = icon
        local label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        label:SetPoint("LEFT", icon, "RIGHT", 4, 0)
        label:SetText(sv.name)
        label:SetJustifyH("LEFT")
        label:SetWidth(sourceButtonWidth - 52)
        btn.label = label

        local countText = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        countText:SetPoint("RIGHT", -5, 0)
        countText:SetText("0")
        countText:SetTextColor(unpack(COLORS.textDim))
        btn.countText = countText
        btn:SetScript("OnClick", function(selfBtn)
            currentSourceView = selfBtn.sourceID
            if HousingCompletedDB then
                HousingCompletedDB.lastSourceView = currentSourceView
            end
            if currentSourceView == "items" then
                currentItemCategory = "all"
            end
            HC:UpdateSourceViewButtons()
            HC:DoSearch()
        end)
        self.sourceViewButtons[sv.id] = btn
    end
    y = y - 2
    
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

    local econLabel = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    econLabel:SetPoint("TOPLEFT", 15, y)
    econLabel:SetText("ECON FILTERS")
    econLabel:SetTextColor(unpack(COLORS.accentAlt))
    y = y - 18

    local minProfitBox = CreateFrame("EditBox", nil, scrollChild, "InputBoxTemplate")
    minProfitBox:SetSize(70, 20)
    minProfitBox:SetPoint("TOPLEFT", 16, y)
    minProfitBox:SetAutoFocus(false)
    minProfitBox:SetNumeric(true)
    minProfitBox:SetMaxLetters(12)
    minProfitBox:SetNumber((HousingCompletedDB.filters and HousingCompletedDB.filters.minProfit) or 0)
    minProfitBox:SetScript("OnEnterPressed", function(selfBox)
        HousingCompletedDB.filters.minProfit = tonumber(selfBox:GetText()) or 0
        selfBox:ClearFocus()
        HC:DoSearch()
    end)
    self.minProfitBox = minProfitBox
    local minProfitLabel = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    minProfitLabel:SetPoint("LEFT", minProfitBox, "RIGHT", 6, 0)
    minProfitLabel:SetText("Min Profit (c)")
    y = y - 22

    local minMarginBox = CreateFrame("EditBox", nil, scrollChild, "InputBoxTemplate")
    minMarginBox:SetSize(70, 20)
    minMarginBox:SetPoint("TOPLEFT", 16, y)
    minMarginBox:SetAutoFocus(false)
    minMarginBox:SetNumeric(true)
    minMarginBox:SetMaxLetters(6)
    minMarginBox:SetNumber((HousingCompletedDB.filters and HousingCompletedDB.filters.minMargin) or 0)
    minMarginBox:SetScript("OnEnterPressed", function(selfBox)
        HousingCompletedDB.filters.minMargin = tonumber(selfBox:GetText()) or 0
        selfBox:ClearFocus()
        HC:DoSearch()
    end)
    self.minMarginBox = minMarginBox
    local minMarginLabel = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    minMarginLabel:SetPoint("LEFT", minMarginBox, "RIGHT", 6, 0)
    minMarginLabel:SetText("Min Margin %")
    y = y - 22

    local craftableOnlyCb = CreateFrame("CheckButton", nil, scrollChild, "UICheckButtonTemplate")
    craftableOnlyCb:SetPoint("TOPLEFT", 10, y)
    SetButtonText(craftableOnlyCb, "Craftable only", 0.7, 0.7, 0.7)
    craftableOnlyCb:SetChecked(HousingCompletedDB.filters and HousingCompletedDB.filters.craftableOnly)
    craftableOnlyCb:SetScript("OnClick", function(selfBtn)
        HousingCompletedDB.filters.craftableOnly = selfBtn:GetChecked() and true or false
        HC:DoSearch()
    end)
    self.craftableOnlyCb = craftableOnlyCb
    y = y - 22

    local lowRiskOnlyCb = CreateFrame("CheckButton", nil, scrollChild, "UICheckButtonTemplate")
    lowRiskOnlyCb:SetPoint("TOPLEFT", 10, y)
    SetButtonText(lowRiskOnlyCb, "Low risk only", 0.7, 0.7, 0.7)
    lowRiskOnlyCb:SetChecked(HousingCompletedDB.filters and HousingCompletedDB.filters.lowRiskOnly)
    lowRiskOnlyCb:SetScript("OnClick", function(selfBtn)
        HousingCompletedDB.filters.lowRiskOnly = selfBtn:GetChecked() and true or false
        HC:DoSearch()
    end)
    self.lowRiskOnlyCb = lowRiskOnlyCb
    y = y - 24
    self.econFilterWidgets = {
        econLabel, minProfitBox, minProfitLabel, minMarginBox, minMarginLabel, craftableOnlyCb, lowRiskOnlyCb,
    }

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

    local function CreateSortHeader(label, sortKey, anchorTo, offsetX)
        local btn = CreateFrame("Button", nil, resultsFrame)
        btn:SetHeight(RESULTS_HEADER_HEIGHT)
        btn:SetWidth(86)
        if anchorTo then
            btn:SetPoint("RIGHT", anchorTo, "LEFT", offsetX or -8, 0)
        else
            btn:SetPoint("TOPRIGHT", -42, -2)
        end
        btn.sortKey = sortKey

        local txt = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        txt:SetPoint("CENTER", 0, 0)
        txt:SetText(label)
        btn.text = txt

        btn:SetScript("OnClick", function(selfBtn)
            HC:SetAcquireSort(selfBtn.sortKey)
        end)
        btn:SetScript("OnEnter", function(selfBtn)
            selfBtn.text:SetTextColor(unpack(COLORS.accentAlt))
        end)
        btn:SetScript("OnLeave", function(selfBtn)
            HC:UpdateAcquireSortHeaderState()
        end)
        return btn
    end

    local marginHeader = CreateSortHeader("Margin", "margin")
    local profitHeader = CreateSortHeader("Profit", "profit", marginHeader, -8)
    local cvbHeader = CreateSortHeader("Craft/Buy", "craftVsBuyRank", profitHeader, -8)
    local craftHeader = CreateSortHeader("Craft Cost", "craftCost", cvbHeader, -8)
    local ahHeader = CreateSortHeader("AH Price", "ahPrice", craftHeader, -8)

    self.acquireSortHeaders = {
        ahPrice = ahHeader,
        craftCost = craftHeader,
        craftVsBuyRank = cvbHeader,
        profit = profitHeader,
        margin = marginHeader,
    }

    local viewToggle = CreateFrame("Frame", nil, resultsFrame, "BackdropTemplate")
    viewToggle:SetSize(110, 24)
    viewToggle:SetPoint("TOPLEFT", 6, -2)
    viewToggle:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    viewToggle:SetBackdropColor(0.08, 0.1, 0.14, 0.95)
    viewToggle:SetBackdropBorderColor(0.17, 0.24, 0.35, 1)

    self.viewModeButtons = {}
    local function CreateViewButton(id, label, x)
        local btn = CreateFrame("Button", nil, viewToggle, "BackdropTemplate")
        btn:SetSize(50, 18)
        btn:SetPoint("TOPLEFT", x, -3)
        btn.modeID = id
        btn:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
        btn:SetBackdropColor(0.1, 0.12, 0.18, 1)
        local txt = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        txt:SetPoint("CENTER", 0, 0)
        txt:SetText(label)
        btn.text = txt
        btn:SetScript("OnClick", function(selfBtn)
            currentViewMode = selfBtn.modeID
            if HousingCompletedDB and HousingCompletedDB.ui then
                HousingCompletedDB.ui.viewMode = currentViewMode
            end
            HC:ApplyResultLayout()
            HC:UpdateResults()
        end)
        self.viewModeButtons[id] = btn
    end
    CreateViewButton("grid", "Grid", 4)
    CreateViewButton("list", "List", 56)
    
    self.resultRows = {}
    for i = 1, ITEMS_PER_PAGE do
        local row = self:CreateResultRow(resultsFrame, i)
        row:SetPoint("TOPLEFT", 5, -5 - RESULTS_HEADER_HEIGHT - (i-1) * ITEM_HEIGHT)
        row:SetPoint("TOPRIGHT", -5, -5 - RESULTS_HEADER_HEIGHT - (i-1) * ITEM_HEIGHT)
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
    exportBtn:SetSize(80, 26)
    exportBtn:SetPoint("LEFT", 0, 0)
    exportBtn:SetText("CSV")
    exportBtn:SetScript("OnClick", function()
        HC:ShowResultsExportDialog()
    end)
    self.exportBtn = exportBtn

    local routeBtn = CreateFrame("Button", nil, pagination, "UIPanelButtonTemplate")
    routeBtn:SetSize(86, 26)
    routeBtn:SetPoint("LEFT", exportBtn, "RIGHT", 6, 0)
    routeBtn:SetText("Optimize")
    routeBtn:SetScript("OnClick", function()
        HC:RunAdvancedRoute()
    end)
    self.routeBtn = routeBtn

    local blueprintBtn = CreateFrame("Button", nil, pagination, "UIPanelButtonTemplate")
    blueprintBtn:SetSize(82, 26)
    blueprintBtn:SetPoint("LEFT", routeBtn, "RIGHT", 6, 0)
    blueprintBtn:SetText("Blueprint")
    blueprintBtn:SetScript("OnClick", function()
        HC:ShowBlueprintDialog()
    end)
    self.blueprintBtn = blueprintBtn

    local autoBtn = CreateFrame("Button", nil, pagination, "UIPanelButtonTemplate")
    autoBtn:SetSize(70, 26)
    autoBtn:SetPoint("LEFT", blueprintBtn, "RIGHT", 6, 0)
    autoBtn:SetText("Auto")
    autoBtn:SetScript("OnClick", function()
        HC:RunAutomationCycle()
    end)
    self.autoBtn = autoBtn

    local shoppingBtn = CreateFrame("Button", nil, pagination, "UIPanelButtonTemplate")
    shoppingBtn:SetSize(108, 26)
    shoppingBtn:SetPoint("LEFT", autoBtn, "RIGHT", 6, 0)
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

    local plannerBudgetBox = CreateFrame("EditBox", nil, pagination, "InputBoxTemplate")
    plannerBudgetBox:SetSize(110, 20)
    plannerBudgetBox:SetPoint("LEFT", nextBtn, "RIGHT", 14, 0)
    plannerBudgetBox:SetAutoFocus(false)
    plannerBudgetBox:SetNumeric(true)
    plannerBudgetBox:SetText("100000")
    plannerBudgetBox:Hide()
    self.plannerBudgetBox = plannerBudgetBox

    local plannerRunBtn = CreateFrame("Button", nil, pagination, "UIPanelButtonTemplate")
    plannerRunBtn:SetSize(72, 22)
    plannerRunBtn:SetPoint("LEFT", plannerBudgetBox, "RIGHT", 6, 0)
    plannerRunBtn:SetText("Plan")
    plannerRunBtn:SetScript("OnClick", function()
        HC:RunPlanner()
    end)
    plannerRunBtn:Hide()
    self.plannerRunBtn = plannerRunBtn

    local plannerSummary = pagination:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    plannerSummary:SetPoint("LEFT", plannerRunBtn, "RIGHT", 8, 0)
    plannerSummary:SetPoint("RIGHT", setWaypointBtn, "LEFT", -8, 0)
    plannerSummary:SetJustifyH("LEFT")
    plannerSummary:SetTextColor(unpack(COLORS.textMuted))
    plannerSummary:Hide()
    self.plannerSummaryText = plannerSummary

    self:UpdateSetWaypointButton()
    self:UpdateAddShoppingButton()
    self:UpdateMapAllButton()
    self:UpdateAcquireSortHeaderState()
    self:UpdatePlannerControls()
    self:ApplyResultLayout()

    local analyticsFrame = CreateFrame("Frame", nil, content, "BackdropTemplate")
    analyticsFrame:SetPoint("TOPLEFT", 15, -15)
    analyticsFrame:SetPoint("BOTTOMRIGHT", -15, 80)
    analyticsFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    analyticsFrame:SetBackdropColor(0.05, 0.07, 0.09, 0.95)
    analyticsFrame:SetBackdropBorderColor(unpack(COLORS.border))
    analyticsFrame:Hide()

    local analyticsTitle = analyticsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    analyticsTitle:SetPoint("TOPLEFT", 12, -10)
    analyticsTitle:SetText("Advanced Analytics")
    analyticsTitle:SetTextColor(unpack(COLORS.accentAlt))

    local analyticsBody = analyticsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    analyticsBody:SetPoint("TOPLEFT", 12, -36)
    analyticsBody:SetPoint("BOTTOMRIGHT", -12, 12)
    analyticsBody:SetJustifyH("LEFT")
    analyticsBody:SetJustifyV("TOP")
    analyticsBody:SetTextColor(unpack(COLORS.textMuted))
    analyticsBody:SetText("")
    self.analyticsBodyText = analyticsBody

    local autoMapBtn = CreateFrame("Button", nil, analyticsFrame, "UIPanelButtonTemplate")
    autoMapBtn:SetSize(120, 22)
    autoMapBtn:SetPoint("TOPRIGHT", -12, -10)
    autoMapBtn:SetText("Map Next Run")
    autoMapBtn:SetScript("OnClick", function()
        local r = HC.RunAutomationAction and HC:RunAutomationAction("next_best", currentResults) or nil
        if r and r.message then
            print("|cff00ff99Housing Completed|r: " .. r.message)
        end
    end)

    local autoTrackBtn = CreateFrame("Button", nil, analyticsFrame, "UIPanelButtonTemplate")
    autoTrackBtn:SetSize(120, 22)
    autoTrackBtn:SetPoint("TOPRIGHT", autoMapBtn, "BOTTOMRIGHT", 0, -6)
    autoTrackBtn:SetText("Track Missing")
    autoTrackBtn:SetScript("OnClick", function()
        local r = HC.RunAutomationAction and HC:RunAutomationAction("track_missing_mats", currentResults) or nil
        if r and r.message then
            print("|cff00ff99Housing Completed|r: " .. r.message)
        end
        if HC.RefreshShoppingListPanel and HC.shoppingListPanel and HC.shoppingListPanel:IsShown() then
            HC:RefreshShoppingListPanel()
        end
    end)

    local autoQueueBtn = CreateFrame("Button", nil, analyticsFrame, "UIPanelButtonTemplate")
    autoQueueBtn:SetSize(120, 22)
    autoQueueBtn:SetPoint("TOPRIGHT", autoTrackBtn, "BOTTOMRIGHT", 0, -6)
    autoQueueBtn:SetText("Queue Best")
    autoQueueBtn:SetScript("OnClick", function()
        local r = HC.RunAutomationAction and HC:RunAutomationAction("queue_best_crafts", currentResults) or nil
        if r and r.message then
            print("|cff00ff99Housing Completed|r: " .. r.message)
        end
    end)

    local roomBtn = CreateFrame("Button", nil, analyticsFrame, "UIPanelButtonTemplate")
    roomBtn:SetSize(120, 22)
    roomBtn:SetPoint("TOPRIGHT", autoQueueBtn, "BOTTOMRIGHT", 0, -6)
    roomBtn:SetText("Room Bundle")
    roomBtn:SetScript("OnClick", function()
        HC:ShowRoomBundleDialog("study")
    end)

    local depBtn = CreateFrame("Button", nil, analyticsFrame, "UIPanelButtonTemplate")
    depBtn:SetSize(120, 22)
    depBtn:SetPoint("TOPRIGHT", roomBtn, "BOTTOMRIGHT", 0, -6)
    depBtn:SetText("Deps")
    depBtn:SetScript("OnClick", function()
        HC:ShowDependencyGraphDialog()
    end)

    self.analyticsFrame = analyticsFrame
    
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
        local itemID = HC:GetResolvedItemID(self.itemData)
        if itemID then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetItemByID(itemID)
            HC:AppendPricingTooltip(GameTooltip, self.itemData)
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
        if self.itemData and self.itemData.type == "vendor" and HC.ShowVendorInventoryForResult then
            HC:ShowVendorInventoryForResult(self.itemData)
            return
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

    local favoriteIcon = row:CreateTexture(nil, "OVERLAY")
    favoriteIcon:SetSize(14, 14)
    favoriteIcon:SetPoint("BOTTOMLEFT", typeIcon, "BOTTOMRIGHT", -7, -2)
    favoriteIcon:SetTexture("Interface\\AddOns\\Blizzard_GarrisonUI\\UI_Garrison_CollectionIcon-Check")
    favoriteIcon:SetVertexColor(1, 0.84, 0.2, 1)
    favoriteIcon:Hide()
    row.favoriteIcon = favoriteIcon
    
    local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameText:SetPoint("TOPLEFT", typeIcon, "TOPRIGHT", 10, -2)
    nameText:SetPoint("RIGHT", -470, 0)
    nameText:SetJustifyH("LEFT")
    row.nameText = nameText
    
    local sourceText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    sourceText:SetPoint("TOPLEFT", nameText, "BOTTOMLEFT", 0, -2)
    sourceText:SetPoint("RIGHT", -470, 0)
    sourceText:SetJustifyH("LEFT")
    sourceText:SetTextColor(unpack(COLORS.textMuted))
    row.sourceText = sourceText
    
    local infoText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    infoText:SetPoint("TOPLEFT", sourceText, "BOTTOMLEFT", 0, -2)
    infoText:SetPoint("RIGHT", -470, 0)
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

    local marginText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    marginText:SetPoint("RIGHT", waypointBtn, "LEFT", -8, 0)
    marginText:SetWidth(64)
    marginText:SetJustifyH("RIGHT")
    row.marginText = marginText

    local profitText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    profitText:SetPoint("RIGHT", marginText, "LEFT", -8, 0)
    profitText:SetWidth(82)
    profitText:SetJustifyH("RIGHT")
    row.profitText = profitText

    local craftVsBuyText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    craftVsBuyText:SetPoint("RIGHT", profitText, "LEFT", -8, 0)
    craftVsBuyText:SetWidth(76)
    craftVsBuyText:SetJustifyH("RIGHT")
    row.craftVsBuyText = craftVsBuyText

    local craftCostText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    craftCostText:SetPoint("RIGHT", craftVsBuyText, "LEFT", -8, 0)
    craftCostText:SetWidth(82)
    craftCostText:SetJustifyH("RIGHT")
    row.craftCostText = craftCostText

    local ahPriceText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    ahPriceText:SetPoint("RIGHT", craftCostText, "LEFT", -8, 0)
    ahPriceText:SetWidth(82)
    ahPriceText:SetJustifyH("RIGHT")
    row.ahPriceText = ahPriceText
    
    local typeBadge = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    typeBadge:SetPoint("RIGHT", ahPriceText, "LEFT", -10, 0)
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
            if req.faction and req.standing then
                line = "Requires " .. req.standing .. " with " .. req.faction
            elseif req.standing then
                line = "Requires " .. req.standing
            elseif req.faction then
                line = "Requires reputation with " .. req.faction
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

function HC:GetResultItemLink(resultData)
    if not resultData then return nil, nil end

    local resolvedItemID = self:GetResolvedItemID(resultData)
    if resolvedItemID and C_Item and C_Item.GetItemLinkByID then
        local link = C_Item.GetItemLinkByID(resolvedItemID)
        if link and link ~= "" then
            return link, resolvedItemID
        end
    end

    local itemName = resultData.name or (resultData.data and resultData.data.name)
    if itemName and itemName ~= "" and GetItemInfo then
        local itemLink = select(2, GetItemInfo(itemName))
        if itemLink and itemLink ~= "" then
            local itemID = GetItemInfoInstant and select(1, GetItemInfoInstant(itemName)) or resolvedItemID
            return itemLink, itemID
        end
    end

    if resolvedItemID then
        return "item:" .. tostring(resolvedItemID), resolvedItemID
    end

    return nil, nil
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
            if self.ExtractReputationRequirement then
                faction, standing = self:ExtractReputationRequirement((s.notes or s.source or ""), faction, standing)
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

function HC:AppendPricingTooltip(tooltip, resultData)
    if not tooltip or not resultData or not self.GetResultEconomics then
        return
    end

    local econ = self:GetResultEconomics(resultData)
    if not econ then return end

    tooltip:AddLine(" ")
    tooltip:AddLine("|cff00ff99Housing Completed|r")
    tooltip:AddLine("AH Price: " .. FormatMoneyValue(econ.ahPrice), 0.95, 0.95, 0.95)
    tooltip:AddLine("Vendor Price: " .. FormatMoneyValue(econ.vendorCost), 0.95, 0.95, 0.95)
    tooltip:AddLine("Total Cost: " .. FormatMoneyValue(econ.totalCost), 0.95, 0.95, 0.95)
    if econ.trend then
        tooltip:AddLine(string.format("Trend: %s %.1f%%", econ.trend.arrow or "->", econ.trend.changePct or 0), 0.9, 0.9, 0.95)
        tooltip:AddLine(string.format("Risk Score: %d / 100", econ.risk or 50), 0.9, 0.9, 0.95)
    end
    if econ.auctionAgeSeconds then
        tooltip:AddLine(string.format("Scan Age: %ds", econ.auctionAgeSeconds), 0.8, 0.8, 0.9)
    end

    if econ.profit then
        local prefix = econ.profit >= 0 and "|cff40ff40" or "|cffff5555"
        tooltip:AddLine("Profit: " .. prefix .. FormatMoneyValue(math.abs(econ.profit)) .. "|r", 0.95, 0.95, 0.95)
        tooltip:AddLine("Margin: " .. prefix .. FormatMarginValue(econ.margin) .. "|r", 0.95, 0.95, 0.95)
    else
        tooltip:AddLine("Profit: -", 0.95, 0.95, 0.95)
        tooltip:AddLine("Margin: -", 0.95, 0.95, 0.95)
    end
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

function HC:SetupEmbeddedDressingModel(parent)
    local modelScene = CreateFrame("ModelScene", nil, parent, "PanningModelSceneMixinTemplate")
    modelScene:SetPoint("TOPLEFT", 2, -2)
    modelScene:SetPoint("BOTTOMRIGHT", -2, 36)
    modelScene:Hide()
    self.embeddedDecorModelScene = modelScene

    local ctrlOk, controls = pcall(CreateFrame, "Frame", nil, parent, "ModelSceneControlFrameTemplate")
    if ctrlOk and controls then
        controls:SetPoint("BOTTOM", parent, "BOTTOM", 0, 7)
        pcall(controls.SetModelScene, controls, modelScene)
        controls:Hide()
        self.embeddedDecorControls = controls
    else
        self.embeddedDecorControls = nil
    end
end

function HC:ResetEmbeddedModelView()
    local modelScene = self.embeddedDecorModelScene
    if not modelScene then return end

    if self._embeddedSceneID then
        pcall(function()
            modelScene:TransitionToModelSceneID(self._embeddedSceneID, CAMERA_TRANSITION_TYPE_IMMEDIATE, CAMERA_MODIFICATION_TYPE_DISCARD, true)
        end)
    end
    local actor = modelScene.GetActorByTag and modelScene:GetActorByTag("decor")
    if actor and self._embeddedAssetID then
        actor:SetPreferModelCollisionBounds(true)
        actor:SetModelByFileID(self._embeddedAssetID)
    end
end

function HC:UpdateEmbeddedPreview(itemLink, itemID, itemData)
    local modelScene = self.embeddedDecorModelScene
    if not modelScene then return false end
    TryLoadHousingPreviewModules()
    if self.embeddedDecorControls then
        self.embeddedDecorControls:Hide()
    end
    modelScene:Hide()

    local decorInfo = nil
    if itemID and C_HousingCatalog and C_HousingCatalog.GetCatalogEntryInfoByItem then
        decorInfo = C_HousingCatalog.GetCatalogEntryInfoByItem(itemID, true)
    end
    if (not decorInfo) and itemData and itemData.decorID and C_HousingCatalog and C_HousingCatalog.GetCatalogEntryInfoByRecordID then
        local ok, info = pcall(C_HousingCatalog.GetCatalogEntryInfoByRecordID, 1, itemData.decorID, true)
        if ok and info then
            decorInfo = info
        end
    end

    if not decorInfo or not decorInfo.asset then
        return false
    end

    local sceneID = decorInfo.uiModelSceneID
    if not sceneID and Constants and Constants.HousingCatalogConsts then
        sceneID = Constants.HousingCatalogConsts.HOUSING_CATALOG_DECOR_MODELSCENEID_DEFAULT
    end
    sceneID = sceneID or 859

    local ok = pcall(function()
        modelScene:TransitionToModelSceneID(sceneID, CAMERA_TRANSITION_TYPE_IMMEDIATE, CAMERA_MODIFICATION_TYPE_DISCARD, true)
        local actor = modelScene:GetActorByTag("decor")
        if actor then
            actor:SetPreferModelCollisionBounds(true)
            actor:SetModelByFileID(decorInfo.asset)
        else
            error("decor actor not found")
        end
    end)

    if ok then
        self._embeddedSceneID = sceneID
        self._embeddedAssetID = decorInfo.asset
        modelScene:Show()
        if self.embeddedDecorControls then
            self.embeddedDecorControls:Show()
        end
        return true
    end

    return false
end

TryLoadHousingPreviewModules = function()
    local loader = (C_AddOns and C_AddOns.LoadAddOn) or LoadAddOn
    if type(loader) ~= "function" then
        return
    end

    local names = {
        "Blizzard_HousingUI",
        "Blizzard_HousingCatalog",
        "Blizzard_ResidenceUI",
    }
    for _, name in ipairs(names) do
        pcall(loader, name)
    end
end

local function TryCallWithItemID(owner, fn, itemID)
    if type(fn) ~= "function" then
        return false
    end

    if pcall(fn, itemID) then
        return true
    end

    if owner ~= nil and pcall(fn, owner, itemID) then
        return true
    end

    return false
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
    modelContainer:EnableMouse(true)

    self:SetupEmbeddedDressingModel(modelContainer)

    local modelFallbackIcon = modelContainer:CreateTexture(nil, "ARTWORK")
    modelFallbackIcon:SetSize(72, 72)
    modelFallbackIcon:SetPoint("TOP", 0, -54)
    modelFallbackIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    modelFallbackIcon:SetVertexColor(0.8, 0.8, 0.8, 0.9)
    modelFallbackIcon:Show()
    self.modelFallbackIcon = modelFallbackIcon
    self.modelContainer = modelContainer

    local modelHint = modelContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    modelHint:SetPoint("TOPLEFT", 12, -174)
    modelHint:SetPoint("TOPRIGHT", -12, -174)
    modelHint:SetJustifyH("CENTER")
    modelHint:SetText("Drag to rotate, scroll to zoom, right-drag to pan.")
    modelHint:SetTextColor(0.78, 0.70, 0.56)
    self.previewResidenceHint = modelHint

    local openResidenceBtn = CreateFrame("Button", nil, modelContainer, "UIPanelButtonTemplate")
    openResidenceBtn:SetSize(146, 22)
    openResidenceBtn:SetPoint("BOTTOMLEFT", 10, 8)
    openResidenceBtn:SetText("Open External")
    openResidenceBtn:SetEnabled(false)
    openResidenceBtn:SetAlpha(0.45)
    openResidenceBtn:SetScript("OnClick", function()
        if self.previewResidenceItemID then
            self:OpenItemPreview(self.previewResidenceItemID)
        end
    end)
    self.previewOpenResidenceBtn = openResidenceBtn

    local resetModelBtn = CreateFrame("Button", nil, modelContainer, "UIPanelButtonTemplate")
    resetModelBtn:SetSize(96, 22)
    resetModelBtn:SetPoint("BOTTOMRIGHT", -10, 8)
    resetModelBtn:SetText("Reset View")
    resetModelBtn:SetScript("OnClick", function()
        HC:ResetEmbeddedModelView()
    end)
    self.previewResetModelBtn = resetModelBtn

    y = y - 224
    
    local itemName = preview:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    itemName:SetPoint("TOPLEFT", 15, y)
    itemName:SetPoint("TOPRIGHT", -15, y)
    itemName:SetJustifyH("CENTER")
    itemName:SetText("Select an item")
    itemName:SetTextColor(1, 1, 1)
    self.previewName = itemName
    y = y - 22
    
    local sourceType = preview:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    sourceType:SetPoint("TOP", 0, y)
    sourceType:SetText("")
    self.previewSourceType = sourceType
    y = y - 25
    
    local detailsFrame = CreateFrame("Frame", nil, preview)
    detailsFrame:SetPoint("TOPLEFT", 15, y)
    detailsFrame:SetPoint("TOPRIGHT", -15, y)
    detailsFrame:SetHeight(270)
    
    local dy = 0
    
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

    local ahLabel = detailsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    ahLabel:SetPoint("TOPLEFT", 0, dy)
    ahLabel:SetText("|cff888888AH:|r")
    local ahValue = detailsFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    ahValue:SetPoint("TOPLEFT", 55, dy)
    ahValue:SetPoint("RIGHT", 0, 0)
    ahValue:SetJustifyH("LEFT")
    ahValue:SetText("-")
    self.previewAHPrice = ahValue
    dy = dy - 16

    local totalCostLabel = detailsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    totalCostLabel:SetPoint("TOPLEFT", 0, dy)
    totalCostLabel:SetText("|cff888888Total:|r")
    local totalCostValue = detailsFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    totalCostValue:SetPoint("TOPLEFT", 55, dy)
    totalCostValue:SetPoint("RIGHT", 0, 0)
    totalCostValue:SetJustifyH("LEFT")
    totalCostValue:SetText("-")
    self.previewTotalCost = totalCostValue
    dy = dy - 16

    local profitLabel = detailsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    profitLabel:SetPoint("TOPLEFT", 0, dy)
    profitLabel:SetText("|cff888888Profit:|r")
    local profitValue = detailsFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    profitValue:SetPoint("TOPLEFT", 55, dy)
    profitValue:SetPoint("RIGHT", 0, 0)
    profitValue:SetJustifyH("LEFT")
    profitValue:SetText("-")
    self.previewProfit = profitValue
    dy = dy - 16

    local marginLabel = detailsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    marginLabel:SetPoint("TOPLEFT", 0, dy)
    marginLabel:SetText("|cff888888Margin:|r")
    local marginValue = detailsFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    marginValue:SetPoint("TOPLEFT", 55, dy)
    marginValue:SetPoint("RIGHT", 0, 0)
    marginValue:SetJustifyH("LEFT")
    marginValue:SetText("-")
    self.previewMargin = marginValue
    dy = dy - 16

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

    local sourcesLabel = detailsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    sourcesLabel:SetPoint("TOPLEFT", 0, dy)
    sourcesLabel:SetText("|cff888888Sources:|r")
    local sourcesValue = detailsFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    sourcesValue:SetPoint("TOPLEFT", 55, dy)
    sourcesValue:SetPoint("RIGHT", 0, 0)
    sourcesValue:SetJustifyH("LEFT")
    sourcesValue:SetText("-")
    self.previewSources = sourcesValue
    dy = dy - 16

    local matsLabel = detailsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    matsLabel:SetPoint("TOPLEFT", 0, dy)
    matsLabel:SetText("|cff888888Mats:|r")
    local matsValue = detailsFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    matsValue:SetPoint("TOPLEFT", 55, dy)
    matsValue:SetPoint("RIGHT", 0, 0)
    matsValue:SetJustifyH("LEFT")
    matsValue:SetJustifyV("TOP")
    if matsValue.SetWordWrap then
        matsValue:SetWordWrap(true)
    end
    matsValue:SetText("-")
    self.previewMaterials = matsValue
    local matsButtonsFrame = CreateFrame("Frame", nil, detailsFrame)
    matsButtonsFrame:SetPoint("TOPLEFT", 55, dy - 1)
    matsButtonsFrame:SetSize(PREVIEW_WIDTH - 88, 48)
    matsButtonsFrame:Hide()
    self.previewMaterialsButtonsFrame = matsButtonsFrame
    self.previewMaterialButtons = {}
    dy = dy - 50
    
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
    addListBtn:SetText("Track This")
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

    local favoriteBtn = CreateFrame("Button", nil, preview, "UIPanelButtonTemplate")
    favoriteBtn:SetSize(PREVIEW_WIDTH - 30, 24)
    favoriteBtn:SetPoint("BOTTOM", 0, 104)
    favoriteBtn:SetText("Star Item")
    favoriteBtn:SetScript("OnClick", function()
        if selectedItem then
            HC:ToggleFavorite(selectedItem)
        end
    end)
    self.previewFavoriteBtn = favoriteBtn

    local browseVendorBtn = CreateFrame("Button", nil, preview, "UIPanelButtonTemplate")
    browseVendorBtn:SetSize(PREVIEW_WIDTH - 30, 24)
    browseVendorBtn:SetPoint("BOTTOM", 0, 76)
    browseVendorBtn:SetText("Browse Vendor Items")
    browseVendorBtn:SetEnabled(false)
    browseVendorBtn:SetAlpha(0.45)
    browseVendorBtn:SetScript("OnClick", function()
        if selectedItem and HC.ShowVendorInventoryForResult then
            HC:ShowVendorInventoryForResult(selectedItem)
        end
    end)
    self.previewVendorItemsBtn = browseVendorBtn

    preview.slideIn = preview:CreateAnimationGroup()
    local slide = preview.slideIn:CreateAnimation("Translation")
    slide:SetDuration(0.16)
    slide:SetOffset(-18, 0)
    local fade = preview.slideIn:CreateAnimation("Alpha")
    fade:SetDuration(0.16)
    fade:SetFromAlpha(0.88)
    fade:SetToAlpha(1)
    preview.slideIn:SetToFinalAlpha(true)

    self.previewPanel = preview
end

function HC:RefreshPreviewMaterialButtons(economics)
    if not self.previewMaterialsButtonsFrame then return end
    local frame = self.previewMaterialsButtonsFrame
    local buttons = self.previewMaterialButtons or {}
    self.previewMaterialButtons = buttons

    for _, btn in ipairs(buttons) do
        btn:Hide()
    end

    local reagents = economics and economics.reagents or nil
    if type(reagents) ~= "table" or #reagents == 0 then
        frame:Hide()
        return false
    end

    local maxButtons = math.min(3, #reagents)
    local y = 0
    for idx = 1, maxButtons do
        local reagent = reagents[idx]
        local btn = buttons[idx]
        if not btn then
            btn = CreateFrame("Button", nil, frame, "BackdropTemplate")
            btn:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8x8",
                edgeFile = "Interface\\Buttons\\WHITE8x8",
                edgeSize = 1,
            })
            btn:SetBackdropColor(0.1, 0.11, 0.14, 0.95)
            btn:SetBackdropBorderColor(0.2, 0.25, 0.34, 1)
            btn:SetHeight(15)

            local txt = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            txt:SetPoint("LEFT", 4, 0)
            txt:SetPoint("RIGHT", -4, 0)
            txt:SetJustifyH("LEFT")
            if txt.SetWordWrap then txt:SetWordWrap(false) end
            if txt.SetNonSpaceWrap then txt:SetNonSpaceWrap(false) end
            if txt.SetMaxLines then txt:SetMaxLines(1) end
            btn.text = txt

            buttons[idx] = btn
        end

        local qty = math.max(1, math.floor((tonumber(reagent.qty) or 1) + 0.5))
        local reagentName = reagent.name or (reagent.itemID and ("Item #" .. tostring(reagent.itemID))) or "Unknown"
        btn.reagentID = reagent.itemID
        btn.reagentName = reagentName
        btn.reagentQty = qty
        btn:SetPoint("TOPLEFT", 0, y)
        btn:SetPoint("TOPRIGHT", 0, y)
        btn.text:SetText(string.format("%dx %s", qty, reagentName))
        btn:SetScript("OnClick", function(selfBtn, button)
            if button == "LeftButton" and IsShiftKeyDown() then
                local ok, msg = HC:TrackReagent(selfBtn.reagentID, selfBtn.reagentName, selfBtn.reagentQty)
                if msg then
                    print("|cff00ff99Housing Completed|r: " .. msg)
                end
                if ok and HC.RefreshShoppingListPanel and HC.shoppingListPanel and HC.shoppingListPanel:IsShown() then
                    HC:RefreshShoppingListPanel()
                end
            elseif button == "LeftButton" then
                if not AuctionHouseFrame or not AuctionHouseFrame:IsShown() then
                    print("|cff00ff99Housing Completed|r: Please open the Auction House first.")
                elseif AuctionHouseFrame.SearchBar and AuctionHouseFrame.SearchBar.SearchBox then
                    AuctionHouseFrame.SearchBar.SearchBox:SetText(selfBtn.reagentName)
                    print("|cff00ff99Housing Completed|r: Set AH search text to: " .. selfBtn.reagentName)
                end
            elseif button == "RightButton" then
                local ok, msg = HC:UntrackReagent(selfBtn.reagentID)
                if msg then
                    print("|cff00ff99Housing Completed|r: " .. msg)
                end
                if ok and HC.RefreshShoppingListPanel and HC.shoppingListPanel and HC.shoppingListPanel:IsShown() then
                    HC:RefreshShoppingListPanel()
                end
            end
        end)
        btn:SetScript("OnEnter", function(selfBtn)
            GameTooltip:SetOwner(selfBtn, "ANCHOR_RIGHT")
            GameTooltip:SetText(selfBtn.reagentName, 1, 1, 1)
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("Click to set AH search text", 0.7, 0.7, 0.7)
            GameTooltip:AddLine("Shift-Click to track reagent", 0.7, 0.7, 0.7)
            GameTooltip:AddLine("Right-Click to untrack reagent", 0.7, 0.7, 0.7)
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
        btn:Show()
        y = y - 16
    end

    frame:SetHeight((maxButtons * 16) + 2)
    frame:Show()
    return true
end

function HC:UpdatePreview(data)
    if not self.previewName then return end
    local streamerMode = HousingCompletedDB and HousingCompletedDB.ui and HousingCompletedDB.ui.streamerMode
    
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
        if self.previewAHPrice then self.previewAHPrice:SetText("-") end
        if self.previewTotalCost then self.previewTotalCost:SetText("-") end
        if self.previewProfit then self.previewProfit:SetText("-") end
        if self.previewMargin then self.previewMargin:SetText("-") end
        if self.previewItemID then self.previewItemID:SetText("-") end
        if self.previewSources then self.previewSources:SetText("-") end
        if self.previewMaterials then self.previewMaterials:SetText("-") end
        if self.RefreshPreviewMaterialButtons then
            self:RefreshPreviewMaterialButtons(nil)
        end
        self.previewResidenceItemID = nil
        if self.modelFallbackIcon then
            self.modelFallbackIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
            self.modelFallbackIcon:Show()
        end
        if self.embeddedDecorModelScene then
            self.embeddedDecorModelScene:Hide()
        end
        if self.embeddedDecorControls then
            self.embeddedDecorControls:Hide()
        end
        if self.previewOpenResidenceBtn then
            self.previewOpenResidenceBtn:SetEnabled(false)
            self.previewOpenResidenceBtn:SetAlpha(0.45)
        end
        if self.previewVendorItemsBtn then
            self.previewVendorItemsBtn:SetEnabled(false)
            self.previewVendorItemsBtn:SetAlpha(0.45)
        end
        if self.previewResidenceHint then
            self.previewResidenceHint:SetText("Select an item to preview it in-panel.")
        end
        if self.previewAddShoppingBtn then
            self.previewAddShoppingBtn:SetEnabled(false)
            self.previewAddShoppingBtn:SetAlpha(0.45)
        end
        if self.previewFavoriteBtn then
            self.previewFavoriteBtn:SetEnabled(false)
            self.previewFavoriteBtn:SetAlpha(0.45)
            self.previewFavoriteBtn:SetText("Star Item")
        end
        return
    end

    if self.previewPanel and self.previewPanel.slideIn then
        self.previewPanel.slideIn:Stop()
        self.previewPanel.slideIn:Play()
    end
    
    self.previewName:SetText(data.name or "Unknown")
    if data.collected then
        self.previewName:SetTextColor(unpack(COLORS.collected))
    else
        self.previewName:SetTextColor(1, 1, 1)
    end
    
    local sourceInfo = self:GetSourceTypeInfo(data.type)
    self.previewSourceType:SetText(sourceInfo.name)
    self.previewSourceType:SetTextColor(unpack(sourceInfo.color))
    
    if data.type == "vendor" and data.data then
        self.previewVendor:SetText(data.data.name or "-")
    else
        self.previewVendor:SetText(data.vendor or "-")
    end
    
    local loc = data.zone or ""
    if data.data and data.data.subzone then
        loc = loc .. ", " .. data.data.subzone
    end
    if (not streamerMode) and data.data and data.data.x and data.data.y then
        loc = loc .. string.format(" (%.1f, %.1f)", data.data.x, data.data.y)
    end
    self.previewLocation:SetText(loc ~= "" and loc or "-")
    
    if (not streamerMode) and data.cost then
        self.previewCost:SetText("|cffffd700" .. data.cost .. "|r")
    else
        self.previewCost:SetText("-")
    end

    local economics = self.GetResultEconomics and self:GetResultEconomics(data) or nil
    if self.previewAHPrice then
        self.previewAHPrice:SetText(streamerMode and "-" or FormatMoneyValue(economics and economics.ahPrice))
    end
    if self.previewTotalCost then
        self.previewTotalCost:SetText(streamerMode and "-" or FormatMoneyValue(economics and economics.totalCost))
    end
    if self.previewProfit then
        if streamerMode then
            self.previewProfit:SetText("-")
        elseif economics and economics.profit then
            local absProfit = FormatMoneyValue(math.abs(economics.profit))
            if economics.profit >= 0 then
                self.previewProfit:SetText("|cff40ff40+" .. absProfit .. "|r")
            else
                self.previewProfit:SetText("|cffff5555-" .. absProfit .. "|r")
            end
        else
            self.previewProfit:SetText("-")
        end
    end
    if self.previewMargin then
        if streamerMode then
            self.previewMargin:SetText("-")
        elseif economics and economics.margin then
            if economics.margin >= 0 then
                self.previewMargin:SetText("|cff40ff40" .. FormatMarginValue(economics.margin) .. "|r")
            else
                self.previewMargin:SetText("|cffff5555" .. FormatMarginValue(economics.margin) .. "|r")
            end
        else
            self.previewMargin:SetText("-")
        end
    end
    if self.previewSources and currentTab == "planner" and economics then
        local rec = economics.craftVsBuy or "Unknown"
        local risk = economics.risk or 50
        self.previewSources:SetText(string.format("Plan: %s | Risk %d", rec, risk))
    end

    local itemID = self:GetResolvedItemID(data)
    if self.previewItemID then
        self.previewItemID:SetText(itemID and tostring(itemID) or "-")
    end

    if self.previewSources then
        local sourceCount = (data.data and data.data.sourceCount) or (data.sourceCount) or ((data.data and data.data.sources and #data.data.sources) or nil)
        self.previewSources:SetText(sourceCount and tostring(sourceCount) or "-")
    end
    local materialsText = FormatCraftMaterialsValue(economics)
    local showingMaterialButtons = false
    if self.RefreshPreviewMaterialButtons then
        showingMaterialButtons = self:RefreshPreviewMaterialButtons(economics) and true or false
    end
    if self.previewMaterials then
        self.previewMaterials:SetText(showingMaterialButtons and "-" or materialsText)
    end
    
    local repReqs = self.GetReputationRequirements and self:GetReputationRequirements(data) or {}
    if #repReqs > 0 then
        local req = repReqs[1]
        self.previewRepHeader:Show()
        self.previewRepFaction:Show()
        self.previewRepStanding:Show()
        
        self.previewRepFaction:SetText(req.faction or "Reputation Requirement")
        
        local standing = req.standing or "Unknown"
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
    
    self.previewResidenceItemID = itemID
    local itemLink = self:GetResultItemLink(data)
    local embeddedShown = self:UpdateEmbeddedPreview(itemLink, itemID, data and data.data)
    local icon = (itemID and C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(itemID))
        or "Interface\\Icons\\INV_Misc_QuestionMark"
    if self.modelFallbackIcon then
        self.modelFallbackIcon:SetTexture(icon)
        self.modelFallbackIcon:SetShown(not embeddedShown)
    end
    if self.previewOpenResidenceBtn then
        local canOpenResidence = itemID and (not embeddedShown) and true or false
        self.previewOpenResidenceBtn:SetEnabled(canOpenResidence and true or false)
        self.previewOpenResidenceBtn:SetAlpha(canOpenResidence and 1 or 0.45)
    end
    if self.previewResidenceHint then
        if embeddedShown then
            self.previewResidenceHint:SetText("Drag to rotate and mouse wheel to zoom.")
        elseif itemID then
            self.previewResidenceHint:SetText("Item cannot render in-panel. Use Open External preview.")
        else
            self.previewResidenceHint:SetText("Select an item to preview it in-panel.")
        end
    end

    if self.previewAddShoppingBtn then
        self.previewAddShoppingBtn:SetEnabled(true)
        self.previewAddShoppingBtn:SetAlpha(1)
    end
    if self.previewFavoriteBtn then
        local isFav = self:IsItemFavorite(data)
        self.previewFavoriteBtn:SetEnabled(true)
        self.previewFavoriteBtn:SetAlpha(1)
        self.previewFavoriteBtn:SetText(isFav and "Unstar Item" or "Star Item")
    end

    if self.previewVendorItemsBtn then
        local hasVendorBrowse = (data.type == "vendor")
            or (type(data.vendor) == "string" and data.vendor ~= "")
            or (data.data and data.data.vendorData and (data.data.vendorData.name or data.data.vendorData.id))
        self.previewVendorItemsBtn:SetEnabled(hasVendorBrowse and true or false)
        self.previewVendorItemsBtn:SetAlpha(hasVendorBrowse and 1 or 0.45)
    end
end

function HC:OpenItemPreview(itemRef)
    if not itemRef then return false end

    local itemID = tonumber(itemRef)
    local itemLink = nil
    if type(itemRef) == "string" then
        if tonumber(itemRef) then
            itemID = tonumber(itemRef)
        elseif itemRef:find("item:", 1, true) then
            itemLink = itemRef
            local parsedID = itemRef:match("item:(%d+)")
            if parsedID then
                itemID = tonumber(parsedID)
            end
        end
    elseif type(itemRef) == "number" then
        itemID = itemRef
    end

    if not itemID then
        return false
    end

    if not itemLink and C_Item and C_Item.GetItemLinkByID then
        itemLink = C_Item.GetItemLinkByID(itemID)
    end
    itemLink = itemLink or ("item:" .. tostring(itemID))

    TryLoadHousingPreviewModules()

    if C_HousingCatalog then
        local cFuncs = {
            C_HousingCatalog.OpenToItemID,
            C_HousingCatalog.OpenPreviewForItemID,
            C_HousingCatalog.PreviewItem,
            C_HousingCatalog.OpenItemPreview,
            C_HousingCatalog.ShowItemPreview,
        }
        for _, fn in ipairs(cFuncs) do
            if TryCallWithItemID(C_HousingCatalog, fn, itemID) then
                return true
            end
        end
    end

    if HousingCatalogFrame then
        local frameFuncs = {
            HousingCatalogFrame.OpenToItemID,
            HousingCatalogFrame.OpenPreviewForItemID,
            HousingCatalogFrame.PreviewItem,
            HousingCatalogFrame.OpenItemPreview,
            HousingCatalogFrame.ShowItemPreview,
        }
        for _, fn in ipairs(frameFuncs) do
            if TryCallWithItemID(HousingCatalogFrame, fn, itemID) then
                return true
            end
        end
    end

    if itemLink and DressUpItemLink then
        local ok = pcall(DressUpItemLink, itemLink)
        if ok then
            return true
        end
    end

    if itemLink and HandleModifiedItemClick then
        local ok = pcall(HandleModifiedItemClick, itemLink)
        if ok then
            return true
        end
    end

    return false
end

function HC:OpenResultPreview(resultData)
    if not resultData then return false end
    local itemLink, itemID = self:GetResultItemLink(resultData)
    if itemID then
        if self:OpenItemPreview(itemID) then
            return true
        end
    end
    if itemLink then
        return self:OpenItemPreview(itemLink)
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
        "Name,Type,Source,Vendor,Zone,Cost,AHPrice,CraftCost,CraftVsBuy,Profit,MarginPct,TrendPct,Risk,Expansion,Faction,Collected,ItemID,SourceCount",
    }

    for _, r in ipairs(results or {}) do
        local econ = self.GetResultEconomics and self:GetResultEconomics(r) or nil
        local row = {
            EscapeCSV(r.name or (r.data and r.data.name) or ""),
            EscapeCSV(r.type or ""),
            EscapeCSV(r.source or ""),
            EscapeCSV(r.vendor or ""),
            EscapeCSV(r.zone or ""),
            EscapeCSV(r.cost or ""),
            EscapeCSV(econ and econ.ahPrice or ""),
            EscapeCSV(econ and econ.craftCost or ""),
            EscapeCSV(econ and econ.craftVsBuy or ""),
            EscapeCSV(econ and econ.profit or ""),
            EscapeCSV(econ and econ.margin and string.format("%.2f", econ.margin) or ""),
            EscapeCSV(econ and econ.trend and string.format("%.2f", econ.trend.changePct or 0) or ""),
            EscapeCSV(econ and econ.risk or ""),
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

function HC:CreateVendorInventoryPanel()
    if self.vendorInventoryPanel then return end

    local frame = CreateFrame("Frame", "HousingCompletedVendorInventoryFrame", self.mainFrame or UIParent, "BackdropTemplate")
    frame:SetSize(560, 620)
    frame:SetPoint("CENTER", self.mainFrame or UIParent, "CENTER", 0, 0)
    frame:SetFrameStrata("DIALOG")
    frame:SetFrameLevel(40)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetClampedToScreen(true)
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    frame:SetBackdropColor(0.07, 0.055, 0.035, 0.98)
    frame:SetBackdropBorderColor(unpack(COLORS.border))
    frame:Hide()

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 14, -12)
    title:SetPoint("TOPRIGHT", -46, -12)
    title:SetJustifyH("LEFT")
    title:SetText("Vendor Inventory")
    frame.title = title

    local subtitle = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    subtitle:SetPoint("TOPLEFT", 14, -36)
    subtitle:SetPoint("TOPRIGHT", -46, -36)
    subtitle:SetJustifyH("LEFT")
    subtitle:SetTextColor(unpack(COLORS.textMuted))
    subtitle:SetText("")
    frame.subtitle = subtitle

    local closeBtn = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", -6, -6)

    local listContainer = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    listContainer:SetPoint("TOPLEFT", 12, -62)
    listContainer:SetPoint("TOPRIGHT", -12, -52)
    listContainer:SetHeight(510)
    listContainer:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    listContainer:SetBackdropColor(0.05, 0.04, 0.03, 0.94)
    listContainer:SetBackdropBorderColor(0.28, 0.2, 0.1, 1)
    frame.listContainer = listContainer

    frame.rows = {}
    for i = 1, 12 do
        local row = CreateFrame("Button", nil, listContainer, "BackdropTemplate")
        row:SetHeight(40)
        row:SetPoint("LEFT", 6, 0)
        row:SetPoint("RIGHT", -6, 0)
        if i == 1 then
            row:SetPoint("TOP", 0, -6)
        else
            row:SetPoint("TOP", frame.rows[i - 1], "BOTTOM", 0, -2)
        end
        row:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
        row:SetBackdropColor(0.14, 0.1, 0.06, 0.86)

        local icon = row:CreateTexture(nil, "ARTWORK")
        icon:SetSize(28, 28)
        icon:SetPoint("LEFT", 8, 0)
        row.icon = icon

        local name = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        name:SetPoint("TOPLEFT", icon, "TOPRIGHT", 8, -1)
        name:SetPoint("TOPRIGHT", -8, -1)
        name:SetJustifyH("LEFT")
        row.nameText = name

        local info = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        info:SetPoint("BOTTOMLEFT", icon, "BOTTOMRIGHT", 8, 1)
        info:SetPoint("BOTTOMRIGHT", -8, 1)
        info:SetJustifyH("LEFT")
        info:SetTextColor(unpack(COLORS.textMuted))
        row.infoText = info

        row:SetScript("OnClick", function(selfRow)
            local resultData = selfRow.itemData
            if not resultData then return end
            selectedItem = resultData
            if HC.UpdatePreview then
                HC:UpdatePreview(resultData)
            end
            HC:UpdateSetWaypointButton()
            HC:UpdateAddShoppingButton()
            HC:OpenResultPreview(resultData)
        end)

        row:Hide()
        frame.rows[i] = row
    end

    local prevBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    prevBtn:SetSize(80, 24)
    prevBtn:SetPoint("BOTTOMLEFT", 12, 12)
    prevBtn:SetText("Prev")
    prevBtn:SetScript("OnClick", function()
        local st = HC.vendorInventoryState
        if not st then return end
        st.page = math.max(1, (st.page or 1) - 1)
        HC:RefreshVendorInventoryPanel()
    end)
    frame.prevBtn = prevBtn

    local nextBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    nextBtn:SetSize(80, 24)
    nextBtn:SetPoint("BOTTOMRIGHT", -12, 12)
    nextBtn:SetText("Next")
    nextBtn:SetScript("OnClick", function()
        local st = HC.vendorInventoryState
        if not st then return end
        local totalPages = math.max(1, math.ceil(#(st.items or {}) / (st.perPage or 12)))
        st.page = math.min(totalPages, (st.page or 1) + 1)
        HC:RefreshVendorInventoryPanel()
    end)
    frame.nextBtn = nextBtn

    local pageText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    pageText:SetPoint("BOTTOM", 0, 16)
    pageText:SetTextColor(unpack(COLORS.textMuted))
    pageText:SetText("Page 1 of 1")
    frame.pageText = pageText

    self.vendorInventoryPanel = frame
end

function HC:RefreshVendorInventoryPanel()
    local frame = self.vendorInventoryPanel
    local st = self.vendorInventoryState
    if not frame or not st then return end

    local items = st.items or {}
    local perPage = st.perPage or 12
    local page = math.max(1, st.page or 1)
    local totalPages = math.max(1, math.ceil(#items / perPage))
    if page > totalPages then
        page = totalPages
        st.page = page
    end

    local vendorName = (st.vendorRef and st.vendorRef.name) or "Vendor"
    frame.title:SetText(vendorName .. " Inventory")
    frame.subtitle:SetText(string.format("%d items", #items))
    frame.pageText:SetText(string.format("Page %d of %d", page, totalPages))
    frame.prevBtn:SetEnabled(page > 1)
    frame.nextBtn:SetEnabled(page < totalPages)

    local startIndex = ((page - 1) * perPage) + 1
    for i = 1, 12 do
        local row = frame.rows[i]
        local idx = startIndex + (i - 1)
        local item = items[idx]
        if item then
            local itemID = self:GetResolvedItemID(item)
            local icon = (itemID and C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(itemID))
                or "Interface\\Icons\\INV_Misc_QuestionMark"
            row.icon:SetTexture(icon)
            row.nameText:SetText(item.name or ("Item #" .. tostring(itemID or "?")))
            local infoParts = {}
            if item.cost and item.cost ~= "" then table.insert(infoParts, item.cost) end
            if item.zone and item.zone ~= "" then table.insert(infoParts, item.zone) end
            row.infoText:SetText(#infoParts > 0 and table.concat(infoParts, "  |  ") or "-")
            row.itemData = item
            row:Show()
        else
            row.itemData = nil
            row:Hide()
        end
    end
end

function HC:ShowVendorInventoryForResult(resultData)
    if not resultData or not self.GetVendorInventory then return end

    local vendorRef = nil
    if resultData.type == "vendor" and type(resultData.data) == "table" then
        vendorRef = resultData.data
    elseif type(resultData.vendor) == "string" and resultData.vendor ~= "" then
        vendorRef = self:GetVendorByName(resultData.vendor) or {
            name = resultData.vendor,
            zone = resultData.zone,
            mapID = resultData.mapID,
        }
    elseif resultData.data and resultData.data.vendorData then
        vendorRef = resultData.data.vendorData
    end

    if not vendorRef then
        return
    end

    local items = self:GetVendorInventory(vendorRef)
    if not items or #items == 0 then
        print("|cff00ff99Housing Completed|r: No cataloged items found for this vendor yet.")
        return
    end

    self:CreateVendorInventoryPanel()
    self.vendorInventoryState = {
        vendorRef = vendorRef,
        items = items,
        page = 1,
        perPage = 12,
    }
    self:RefreshVendorInventoryPanel()
    self.vendorInventoryPanel:Show()
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
            local txt = self:GetText() or ""
            local lines = 1
            for _ in string.gmatch(txt, "\n") do
                lines = lines + 1
            end
            self:SetHeight(math.max(200, (lines * 16) + 20))
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

function HC:RunAdvancedRoute()
    local route = self.OptimizeVendorRoute and self:OptimizeVendorRoute(currentResults) or {}
    if not route or #route == 0 then
        print("|cff00ff99Housing Completed|r: No mappable targets for route optimization.")
        return
    end
    local first = route[1]
    if first and self.SetSmartWaypoint then
        self:SetSmartWaypoint(first.x, first.y, first.mapID, first.title)
    end
    if _G.TomTom and _G.TomTom.AddWaypoint then
        for _, stop in ipairs(route) do
            _G.TomTom:AddWaypoint(stop.mapID, stop.x, stop.y, {
                title = stop.title or "Route Stop",
                persistent = false,
                minimap = true,
                world = true,
            })
        end
    end
    if self.RecordAdvancedDecision then
        self:RecordAdvancedDecision("route_optimized", { stops = #route })
    end
    print("|cff00ff99Housing Completed|r: Optimized route with " .. tostring(#route) .. " stop(s).")
end

function HC:ShowBlueprintDialog()
    local items = {}
    for _, r in ipairs(currentResults or {}) do
        local itemID = self:GetResolvedItemID(r)
        if itemID then
            items[#items + 1] = { itemID = itemID, qty = 1 }
        end
    end
    local encoded = self.ExportBlueprint and self:ExportBlueprint({
        label = "Current Filter Blueprint",
        items = items,
    }) or nil
    if not encoded then
        print("|cff00ff99Housing Completed|r: Blueprint export unavailable.")
        return
    end
    local baseText = encoded
    if self.GetAdvancedState and self.ImportBlueprint and self.ExportBlueprint and self.DiffBlueprints and self.MergeBlueprints then
        local adv = self:GetAdvancedState()
        adv.blueprints = adv.blueprints or {}
        local imported = self:ImportBlueprint(encoded)
        if imported then
            local prev = adv.blueprints[#adv.blueprints]
            if prev then
                local diff = self:DiffBlueprints(prev, imported)
                local merged = self:MergeBlueprints(prev, imported, "max")
                local mergedEncoded = self:ExportBlueprint(merged) or ""
                local diffLines = {}
                for i = 1, math.min(12, #diff) do
                    local d = diff[i]
                    diffLines[#diffLines + 1] = string.format("Item %d: %+d", tonumber(d.itemID) or 0, tonumber(d.qtyDelta) or 0)
                end
                baseText = baseText .. "\n\nDIFF VS LAST (" .. tostring(#diff) .. "):\n" .. table.concat(diffLines, "\n") .. "\n\nMERGED(MAX):\n" .. mergedEncoded
            end
            adv.blueprints[#adv.blueprints + 1] = imported
            if #adv.blueprints > 30 then
                table.remove(adv.blueprints, 1)
            end
            if self.RecordAdvancedDecision then
                self:RecordAdvancedDecision("blueprint_export", { items = #items, label = imported.label })
            end
        end
    end
    self:ShowTextExportDialog("Blueprint Export", baseText)
end

function HC:RunAutomationCycle()
    if not self.RunAutomationAction then
        print("|cff00ff99Housing Completed|r: Automation unavailable.")
        return
    end
    local result = self:RunAutomationAction("next_best", currentResults)
    if result and result.message then
        print("|cff00ff99Housing Completed|r: " .. result.message)
    end
    local tracked = self:RunAutomationAction("track_missing_mats", currentResults)
    if tracked and tracked.message then
        print("|cff00ff99Housing Completed|r: " .. tracked.message)
    end
    if self.RefreshShoppingListPanel and self.shoppingListPanel and self.shoppingListPanel:IsShown() then
        self:RefreshShoppingListPanel()
    end
end

function HC:ShowRoomBundleDialog(templateID)
    if not self.BuildRoomTemplateBundle then
        print("|cff00ff99Housing Completed|r: Room templates unavailable.")
        return
    end
    local picks = self:BuildRoomTemplateBundle(templateID or "study", currentResults, 0)
    if not picks or #picks == 0 then
        print("|cff00ff99Housing Completed|r: No items matched that room template.")
        return
    end
    local lines = { "Room Template: " .. tostring(templateID or "study") }
    for i = 1, math.min(40, #picks) do
        local p = picks[i]
        local name = (p.result and p.result.name) or "Unknown"
        local cost = p.cost and FormatMoneyValue(p.cost) or "-"
        lines[#lines + 1] = string.format("%d. %s  [%s]", i, name, cost)
    end
    self:ShowTextExportDialog("Room Bundle", table.concat(lines, "\n"))
end

function HC:ShowDependencyGraphDialog()
    if not self.BuildCraftDependencyGraph then
        print("|cff00ff99Housing Completed|r: Dependency graph unavailable.")
        return
    end
    local graph = self:BuildCraftDependencyGraph(self:GetShoppingList())
    local lines = {
        "Dependency Graph",
        "Nodes: " .. tostring(#(graph.nodes or {})),
        "Edges: " .. tostring(#(graph.edges or {})),
        "",
    }
    for i = 1, math.min(80, #(graph.edges or {})) do
        local e = graph.edges[i]
        lines[#lines + 1] = string.format("%s -> %s x%d [%s]", tostring(e.from), tostring(e.to), tonumber(e.qty) or 1, tostring(e.decision or "Unknown"))
    end
    self:ShowTextExportDialog("Craft Dependency Graph", table.concat(lines, "\n"))
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

    local sendMissingBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    sendMissingBtn:SetSize(180, 24)
    sendMissingBtn:SetPoint("RIGHT", clearBtn, "LEFT", -8, 0)
    sendMissingBtn:SetText("Send Missing Mats")
    sendMissingBtn:SetScript("OnClick", function()
        local ok, count, msg = HC:SendCraftingQueueMissingToAuctionator("HousingCompleted Missing Mats", true)
        if msg then
            print("|cff00ff99Housing Completed|r: " .. msg)
        elseif ok then
            print("|cff00ff99Housing Completed|r: Exported " .. tostring(count or 0) .. " materials to Auctionator.")
        end
    end)
    frame.sendMissingBtn = sendMissingBtn

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
    local tracked = self:GetTrackedReagents()
    local trackedCount = 0
    for _ in pairs(tracked) do
        trackedCount = trackedCount + 1
    end

    panel.countText:SetText(string.format("%d item%s | %d tracked reagent%s", #list, #list == 1 and "" or "s", trackedCount, trackedCount == 1 and "" or "s"))
    panel.mapBtn:SetEnabled(#list > 0)
    panel.mapBtn:SetAlpha(#list > 0 and 1 or 0.45)
    panel.clearBtn:SetEnabled(#list > 0)
    panel.clearBtn:SetAlpha(#list > 0 and 1 or 0.45)
    local hasPricingProvider = self.PricingProvider and self.PricingProvider.IsEnabled and self.PricingProvider:IsEnabled()
    if panel.sendMissingBtn then
        panel.sendMissingBtn:SetEnabled((#list > 0) and hasPricingProvider)
        panel.sendMissingBtn:SetAlpha(((#list > 0) and hasPricingProvider) and 1 or 0.45)
    end

    for _, row in ipairs(panel.rows) do
        row:Hide()
    end
    if panel.trackedHeader then
        panel.trackedHeader:Hide()
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
            if txt.SetWordWrap then txt:SetWordWrap(false) end
            if txt.SetNonSpaceWrap then txt:SetNonSpaceWrap(false) end
            if txt.SetMaxLines then txt:SetMaxLines(1) end
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
        local econ = self.GetResultEconomics and self:GetResultEconomics(self:BuildResultFromQueueEntry(entry), { forceRefresh = true }) or nil
        local econPart = ""
        if econ and econ.totalCost then
            econPart = " |cff888888| |rCost: " .. FormatMoneyValue(econ.totalCost)
            if econ.profit then
                local pSign = econ.profit >= 0 and "+" or "-"
                local pColor = econ.profit >= 0 and "|cff40ff40" or "|cffff5555"
                econPart = econPart .. "  " .. pColor .. "P/L: " .. pSign .. FormatMoneyValue(math.abs(econ.profit)) .. "|r"
            end
        end
        row.text:SetText((entry.name or "Unknown") .. vendorPart .. zonePart .. econPart)
        row.deleteBtn:SetText("Remove")
        row.deleteBtn:SetScript("OnClick", function(selfBtn)
            local idx = selfBtn.rowIndex
            HC:RemoveShoppingListEntry(idx)
            HC:RefreshShoppingListPanel()
        end)
        row.deleteBtn.rowIndex = i
        row:Show()

        y = y - rowHeight
    end

    if trackedCount > 0 then
        if not panel.trackedHeader then
            local hdr = panel.child:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            hdr:SetJustifyH("LEFT")
            hdr:SetTextColor(unpack(COLORS.accentAlt))
            panel.trackedHeader = hdr
        end
        panel.trackedHeader:SetPoint("TOPLEFT", 2, y - 4)
        panel.trackedHeader:SetPoint("TOPRIGHT", -8, y - 4)
        panel.trackedHeader:SetText("Tracked Reagents")
        panel.trackedHeader:Show()
        y = y - 24

        local trackedRows = {}
        for itemID, info in pairs(tracked) do
            table.insert(trackedRows, { itemID = itemID, info = info })
        end
        table.sort(trackedRows, function(a, b)
            return tostring((a.info and a.info.name) or "") < tostring((b.info and b.info.name) or "")
        end)

        for idx, entry in ipairs(trackedRows) do
            local rowIndex = #list + idx
            local row = panel.rows[rowIndex]
            if not row then
                row = CreateFrame("Frame", nil, panel.child, "BackdropTemplate")
                row:SetBackdrop({
                    bgFile = "Interface\\Buttons\\WHITE8x8",
                    edgeFile = "Interface\\Buttons\\WHITE8x8",
                    edgeSize = 1,
                })
                row:SetBackdropColor(0.09, 0.1, 0.07, 0.92)
                row:SetBackdropBorderColor(0.2, 0.28, 0.14, 1)
                row:SetHeight(rowHeight - 2)

                local txt = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                txt:SetPoint("LEFT", 8, 0)
                txt:SetPoint("RIGHT", -96, 0)
                txt:SetJustifyH("LEFT")
                if txt.SetWordWrap then txt:SetWordWrap(false) end
                if txt.SetNonSpaceWrap then txt:SetNonSpaceWrap(false) end
                if txt.SetMaxLines then txt:SetMaxLines(1) end
                row.text = txt

                local del = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
                del:SetSize(78, 20)
                del:SetPoint("RIGHT", -8, 0)
                row.deleteBtn = del
                panel.rows[rowIndex] = row
            end

            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", 0, y)
            row:SetPoint("TOPRIGHT", -8, y)
            local itemID = tonumber(entry.itemID)
            local info = entry.info or {}
            local have = GetCharacterItemCount(itemID)
            local need = math.max(0, math.floor((tonumber(info.targetQty) or 0) + 0.5))
            local name = info.name or (itemID and ("Item #" .. tostring(itemID))) or "Unknown"
            row.text:SetText(string.format("%s |cff888888Have %d / Need %d|r", name, have, need))
            row.deleteBtn:SetText("Untrack")
            row.deleteBtn:SetScript("OnClick", function(selfBtn)
                local reagentID = selfBtn.reagentID
                HC:UntrackReagent(reagentID)
                HC:RefreshShoppingListPanel()
            end)
            row.deleteBtn.reagentID = itemID
            row:Show()
            y = y - rowHeight
        end
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
    scaleSlider:SetWidth(420)

    scaleSlider:SetMinMaxValues(0.5, 1.5)
    scaleSlider:SetValueStep(0.005)
    scaleSlider:SetObeyStepOnDrag(true)

    scaleSlider:SetValue(HousingCompletedDB.scale or 1.0)

    scaleSlider.Low:SetText("50%")
    scaleSlider.High:SetText("150%")

    scaleSlider:SetScript("OnValueChanged", function(self, value)
        value = tonumber(string.format("%.3f", value))
        HousingCompletedDB.scale = value

        if self.Text then
            self.Text:SetText(string.format("%.1f%%", value * 100))
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

    local streamerCb = CreateFrame("CheckButton", nil, settings, "UICheckButtonTemplate")
    streamerCb:SetPoint("TOPLEFT", 20, y)
    SetButtonText(streamerCb, "Streamer Mode (hide sensitive details)", 0.8, 0.8, 0.8)
    streamerCb:SetChecked(HousingCompletedDB.ui and HousingCompletedDB.ui.streamerMode)
    streamerCb:SetScript("OnClick", function(selfBtn)
        EnsureUserUIState()
        HousingCompletedDB.ui.streamerMode = selfBtn:GetChecked() and true or false
        HC:UpdateStats()
        HC:UpdateResults()
        if HC.UpdatePreview then HC:UpdatePreview(selectedItem) end
    end)
    y = y - 24

    local sourceDetailsCb = CreateFrame("CheckButton", nil, settings, "UICheckButtonTemplate")
    sourceDetailsCb:SetPoint("TOPLEFT", 20, y)
    SetButtonText(sourceDetailsCb, "Show Source Details", 0.8, 0.8, 0.8)
    sourceDetailsCb:SetChecked(HousingCompletedDB.ui and HousingCompletedDB.ui.showSourceDetails ~= false)
    sourceDetailsCb:SetScript("OnClick", function(selfBtn)
        EnsureUserUIState()
        HousingCompletedDB.ui.showSourceDetails = selfBtn:GetChecked() and true or false
        HC:UpdateResults()
    end)
    y = y - 24

    local performanceCb = CreateFrame("CheckButton", nil, settings, "UICheckButtonTemplate")
    performanceCb:SetPoint("TOPLEFT", 20, y)
    SetButtonText(performanceCb, "Performance Mode (lighter updates)", 0.8, 0.8, 0.8)
    performanceCb:SetChecked(HousingCompletedDB.ui and HousingCompletedDB.ui.performanceMode)
    performanceCb:SetScript("OnClick", function(selfBtn)
        EnsureUserUIState()
        HousingCompletedDB.ui.performanceMode = selfBtn:GetChecked() and true or false
    end)
    y = y - 30

    local advLabel = settings:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    advLabel:SetPoint("TOPLEFT", 20, y)
    advLabel:SetText("Advanced Profile:")
    y = y - 22

    local profileBox = CreateFrame("EditBox", nil, settings, "InputBoxTemplate")
    profileBox:SetSize(180, 20)
    profileBox:SetPoint("TOPLEFT", 30, y)
    profileBox:SetAutoFocus(false)
    if self.GetAdvancedProfileName then
        profileBox:SetText(self:GetAdvancedProfileName() or "default")
    else
        profileBox:SetText("default")
    end
    profileBox:SetScript("OnEnterPressed", function(selfBox)
        local name = selfBox:GetText()
        if HC.SetAdvancedProfile then
            local ok, active = HC:SetAdvancedProfile(name)
            if ok then
                selfBox:SetText(active)
                print("|cff00ff99Housing Completed|r: Active profile set to '" .. tostring(active) .. "'.")
                HC:DoSearch({ preservePage = true, preserveSelection = true })
            end
        end
        selfBox:ClearFocus()
    end)

    local rulesBtn = CreateFrame("Button", nil, settings, "UIPanelButtonTemplate")
    rulesBtn:SetSize(120, 20)
    rulesBtn:SetPoint("LEFT", profileBox, "RIGHT", 8, 0)
    rulesBtn:SetText("Reset Rules")
    rulesBtn:SetScript("OnClick", function()
        if HC.ClearAdvancedRules then
            HC:ClearAdvancedRules()
            print("|cff00ff99Housing Completed|r: Rules cleared for active profile.")
            HC:DoSearch({ preservePage = true, preserveSelection = true })
        end
    end)
    y = y - 28

    local rulesEnabledCb = CreateFrame("CheckButton", nil, settings, "UICheckButtonTemplate")
    rulesEnabledCb:SetPoint("TOPLEFT", 30, y)
    SetButtonText(rulesEnabledCb, "Enable Rule Engine Filtering", 0.8, 0.8, 0.8)
    rulesEnabledCb:SetChecked(HC.AdvancedRulesEnabled and HC:AdvancedRulesEnabled() or false)
    rulesEnabledCb:SetScript("OnClick", function(selfBtn)
        if HC.SetAdvancedRulesEnabled then
            HC:SetAdvancedRulesEnabled(selfBtn:GetChecked() and true or false)
            HC:DoSearch({ preservePage = true, preserveSelection = true })
        end
    end)
    y = y - 24

    local scoreLabel = settings:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    scoreLabel:SetPoint("TOPLEFT", 20, y)
    scoreLabel:SetText("Scoring Weights (P/C/T/R):")
    y = y - 22

    local scoreBox = CreateFrame("EditBox", nil, settings, "InputBoxTemplate")
    scoreBox:SetSize(220, 20)
    scoreBox:SetPoint("TOPLEFT", 30, y)
    scoreBox:SetAutoFocus(false)
    local sCfg = self.GetScoringConfig and self:GetScoringConfig() or { profitability = 1, completion = 1, travel = 1, risk = 1 }
    scoreBox:SetText(string.format("%.2f %.2f %.2f %.2f", tonumber(sCfg.profitability) or 1, tonumber(sCfg.completion) or 1, tonumber(sCfg.travel) or 1, tonumber(sCfg.risk) or 1))
    scoreBox:SetScript("OnEnterPressed", function(selfBox)
        local p, c, t, r = selfBox:GetText():match("([%-%d%.]+)%s+([%-%d%.]+)%s+([%-%d%.]+)%s+([%-%d%.]+)")
        if p and HC.SetScoringConfig then
            HC:SetScoringConfig({
                profitability = tonumber(p) or 1,
                completion = tonumber(c) or 1,
                travel = tonumber(t) or 1,
                risk = tonumber(r) or 1,
            })
            print("|cff00ff99Housing Completed|r: Scoring weights updated.")
            HC:DoSearch({ preservePage = true, preserveSelection = true })
        end
        selfBox:ClearFocus()
    end)
    y = y - 30

    local opacityLabel = settings:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    opacityLabel:SetPoint("TOPLEFT", 20, y)
    opacityLabel:SetText("Window Opacity:")
    y = y - 24

    local opacitySlider = CreateFrame("Slider", nil, settings, "OptionsSliderTemplate")
    opacitySlider:SetPoint("TOPLEFT", 30, y)
    opacitySlider:SetWidth(420)
    opacitySlider:SetMinMaxValues(0.65, 1.0)
    opacitySlider:SetValueStep(0.01)
    opacitySlider:SetObeyStepOnDrag(true)
    opacitySlider.Low:SetText("65%")
    opacitySlider.High:SetText("100%")
    opacitySlider:SetValue(tonumber(HousingCompletedDB.ui and HousingCompletedDB.ui.opacity) or 0.97)
    opacitySlider:SetScript("OnValueChanged", function(selfSlider, value)
        EnsureUserUIState()
        local v = tonumber(string.format("%.2f", value))
        HousingCompletedDB.ui.opacity = v
        if HC.mainFrame then
            HC.mainFrame:SetAlpha(v)
        end
        if selfSlider.Text then
            selfSlider.Text:SetText(string.format("%.0f%%", v * 100))
        end
    end)
    y = y - 44

    local fontSizeLabel = settings:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fontSizeLabel:SetPoint("TOPLEFT", 20, y)
    fontSizeLabel:SetText("Font Scale:")
    y = y - 24

    local fontSlider = CreateFrame("Slider", nil, settings, "OptionsSliderTemplate")
    fontSlider:SetPoint("TOPLEFT", 30, y)
    fontSlider:SetWidth(420)
    fontSlider:SetMinMaxValues(0.9, 1.25)
    fontSlider:SetValueStep(0.01)
    fontSlider:SetObeyStepOnDrag(true)
    fontSlider.Low:SetText("90%")
    fontSlider.High:SetText("125%")
    fontSlider:SetValue(tonumber(HousingCompletedDB.ui and HousingCompletedDB.ui.fontScale) or 1.0)
    fontSlider:SetScript("OnValueChanged", function(selfSlider, value)
        EnsureUserUIState()
        HousingCompletedDB.ui.fontScale = tonumber(string.format("%.2f", value))
        if selfSlider.Text then
            selfSlider.Text:SetText(string.format("%.0f%%", value * 100))
        end
        HC:UpdateResults()
    end)

    local donateLabel = settings:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    donateLabel:SetPoint("BOTTOMLEFT", 20, 70)
    donateLabel:SetText("Enjoying HousingCompleted? Support ongoing development on Ko-fi.")
    donateLabel:SetTextColor(1, 0.84, 0)

    local donateLink = CreateFrame("EditBox", nil, settings, "InputBoxTemplate")
    donateLink:SetPoint("BOTTOMLEFT", 20, 46)
    donateLink:SetSize(330, 24)
    donateLink:SetAutoFocus(false)
    donateLink:SetText("https://ko-fi.com/korivash")
    donateLink:SetCursorPosition(0)
    donateLink:HighlightText(0, 0)
    donateLink:SetScript("OnEditFocusGained", function(selfBox)
        selfBox:HighlightText()
    end)
    donateLink:SetScript("OnEscapePressed", function(selfBox)
        selfBox:ClearFocus()
    end)
    donateLink:SetScript("OnEnterPressed", function(selfBox)
        selfBox:HighlightText()
    end)
    donateLink:SetScript("OnTextChanged", function(selfBox, userInput)
        if userInput then
            selfBox:SetText("https://ko-fi.com/korivash")
            selfBox:HighlightText()
        end
    end)

    local backBtn = CreateFrame("Button", nil, settings, "UIPanelButtonTemplate")
    backBtn:SetSize(100, 28)
    backBtn:SetPoint("BOTTOMLEFT", 20, 20)
    backBtn:SetText("Back")
    backBtn:SetScript("OnClick", function() HC:ToggleSettings() end)
    
    self.settingsPanel = settings
end


function HC:DoSearch(opts)
    opts = opts or {}
    local preservePage = opts.preservePage == true
    local preserveSelection = opts.preserveSelection == true
    local previousPage = currentPage
    local previousSelectionKey = nil
    if preserveSelection and selectedItem then
        previousSelectionKey = BuildSelectionKey(selectedItem, function(resultData)
            return self:GetResolvedItemID(resultData)
        end)
    end

    local query = self.searchBox and self.searchBox:GetText() or ""
    local performanceMode = HousingCompletedDB and HousingCompletedDB.ui and HousingCompletedDB.ui.performanceMode
    local zoneMapID = nil
    if self.zoneOnlyCb and self.zoneOnlyCb:GetChecked() then
        zoneMapID = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player") or nil
    end
    local filters = {
        showCollected = self.collectedCb and self.collectedCb:GetChecked(),
        showUncollected = self.uncollectedCb and self.uncollectedCb:GetChecked(),
        faction = self:GetPlayerFaction(),
        zoneMapID = zoneMapID,
        expansions = HousingCompletedDB.filters and HousingCompletedDB.filters.expansions or nil,
    }
    if currentTab == "craft" then
        filters.sourceTypes = { profession = true }
    elseif currentTab == "planner" then
    elseif currentTab == "economy" then
    elseif currentTab == "analytics" then
    end

    if currentSourceView == "items" then
        filters.itemCategory = currentItemCategory
        filters.hideVendorEntries = true
    elseif currentSourceView ~= "all" then
        filters.sourceTypes = { [currentSourceView] = true }
    end
    if currentSourceView == "reputation" then
        filters.faction = nil
    end
    
    local results = self:SearchAll(query, filters)
    local filtered = {}
    for _, r in ipairs(results) do
        local show = true
        if r.collected and not filters.showCollected then show = false end
        if not r.collected and not filters.showUncollected then show = false end
        if show and self.IsResultAllowedByRules and not self:IsResultAllowedByRules(r) then
            show = false
        end
        if show and currentPrimaryTab == "favorites" then
            show = self:IsItemFavorite(r)
        end
        if show then table.insert(filtered, r) end
    end
    
    if currentTab == "economy" or currentTab == "planner" then
        local profitable = {}
        local minProfit = tonumber(HousingCompletedDB.filters and HousingCompletedDB.filters.minProfit) or 0
        local minMargin = tonumber(HousingCompletedDB.filters and HousingCompletedDB.filters.minMargin) or 0
        local craftableOnly = HousingCompletedDB.filters and HousingCompletedDB.filters.craftableOnly
        local lowRiskOnly = HousingCompletedDB.filters and HousingCompletedDB.filters.lowRiskOnly
        for _, r in ipairs(filtered) do
            local econ = self.GetResultEconomics and self:GetResultEconomics(r, { forceRefresh = not performanceMode }) or nil
            local keep = econ and econ.ahPrice and econ.totalCost
            if keep and minProfit > 0 then
                keep = (econ.profit or 0) >= minProfit
            end
            if keep and minMargin > 0 then
                keep = (econ.margin or 0) >= minMargin
            end
            if keep and craftableOnly then
                keep = (econ.craftCost ~= nil)
            end
            if keep and lowRiskOnly then
                keep = (econ.risk or 100) <= 35
            end
            if keep then
                table.insert(profitable, r)
            end
        end
        filtered = profitable
    end

    currentResults = filtered
    self.lastComputedResults = currentResults
    for _, r in ipairs(currentResults) do
        if self.GetResultEconomics then
            self:GetResultEconomics(r, { forceRefresh = false })
        end
    end
    self:SortCurrentResults()
    totalPages = math.max(1, math.ceil(#currentResults / ITEMS_PER_PAGE))
    if preservePage then
        currentPage = math.min(math.max(previousPage, 1), totalPages)
    else
        currentPage = 1
    end

    if preserveSelection and previousSelectionKey then
        selectedItem = FindResultBySelectionKey(currentResults, previousSelectionKey, function(resultData)
            return self:GetResolvedItemID(resultData)
        end)
    else
        selectedItem = nil
    end
    
    self:UpdateAcquireSortHeaderState()
    self:UpdateResults()
    self:UpdateStats()
    self:UpdateSourceViewButtons()
    self:UpdateSetWaypointButton()
    self:UpdateAddShoppingButton()
    self:UpdateMapAllButton()
    self:UpdateActionPanel()
    self:RefreshAnalyticsPanel()
    if currentTab == "planner" then
        self:RunPlanner()
    end
    if self.UpdatePreview then
        self:UpdatePreview(selectedItem)
    end
end

function HC:UpdateActionPanel()
    if not self.nextActionText then return end
    local nextAction = self.GetNextBestAction and self:GetNextBestAction(currentResults) or nil
    if not nextAction then
        self.nextActionText:SetText("Next: No actionable target in current filters.")
        return
    end
    local loc = ""
    if nextAction.mapID and nextAction.x and nextAction.y then
        loc = string.format(" @ %.1f, %.1f", (nextAction.x or 0) * 100, (nextAction.y or 0) * 100)
    end
    self.nextActionText:SetText(string.format("Next: %s | %s (%d%%)%s", nextAction.action or "Do", nextAction.name or "Unknown", tonumber(nextAction.confidence) or 0, loc))
end

function HC:RefreshAnalyticsPanel()
    if not self.analyticsBodyText then return end
    local a = self.GetAdvancedAnalytics and self:GetAdvancedAnalytics(currentResults) or nil
    if not a then
        self.analyticsBodyText:SetText("Analytics unavailable.")
        return
    end
    analyticsSummaryText = string.format(
        "Profile: %s\nCollection: %d/%d\nUnknown Sources: %d\nResults: %d\nCraftable: %d\nProfitable: %d\nShopping List: %d\nTracked Reagents: %d\nAggregate Cost: %s\nAggregate Profit: %s\nROI: %.1f%%\nMarket Trend Up: %d\nMarket Trend Down: %d\nRegime: %s (%d%%)\nAverage Risk: %.1f\nTelemetry Events: %d",
        tostring(a.activeProfile or "default"),
        tonumber(a.collectedTrackable) or 0,
        tonumber(a.trackableTotal) or 0,
        tonumber(a.unknownSourceItems) or 0,
        tonumber(a.totalResults) or 0,
        tonumber(a.craftableCount) or 0,
        tonumber(a.profitableCount) or 0,
        tonumber(a.shoppingItems) or 0,
        tonumber(a.trackedReagents) or 0,
        FormatMoneyValue(a.totalCost),
        FormatMoneyValue(a.totalProfit),
        tonumber(a.roi) or 0,
        tonumber(a.trendUp) or 0,
        tonumber(a.trendDown) or 0,
        tostring(a.marketRegime or "Unknown"),
        tonumber(a.marketConfidence) or 0,
        tonumber(a.avgRisk) or 0,
        tonumber(a.telemetryTotal) or 0
    )
    if type(a.telemetryByType) == "table" and next(a.telemetryByType) then
        local parts = {}
        for k, v in pairs(a.telemetryByType) do
            parts[#parts + 1] = tostring(k) .. ":" .. tostring(v)
        end
        table.sort(parts)
        analyticsSummaryText = analyticsSummaryText .. "\nTelemetry Breakdown: " .. table.concat(parts, ", ")
    end
    self.analyticsBodyText:SetText(analyticsSummaryText)
end

function HC:BuildSourceCountFilters()
    local zoneMapID = nil
    if self.zoneOnlyCb and self.zoneOnlyCb:GetChecked() then
        zoneMapID = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player") or nil
    end

    return {
        showCollected = self.collectedCb and self.collectedCb:GetChecked(),
        showUncollected = self.uncollectedCb and self.uncollectedCb:GetChecked(),
        faction = self:GetPlayerFaction(),
        zoneMapID = zoneMapID,
    }
end

function HC:ResultMatchesSourceView(resultData, sourceView)
    if not resultData then return false end
    if sourceView == "all" then return true end

    local resultType = self:NormalizeSourceType(resultData.type or "unknown")

    if sourceView == "items" then
        if resultType == "vendor" then return false end
        local cat = currentItemCategory or "all"
        if cat == "all" then
            return true
        end
        if resultData.data and resultData.data.name then
            return self:ItemMatchesCategory({ name = resultData.data.name, sources = resultData.data.sources }, cat)
        end
        return self:ItemMatchesCategory({ name = resultData.name, sources = (resultData.data and resultData.data.sources) or {} }, cat)
    end

    if resultType == sourceView then
        return true
    end

    local sources = resultData.data and resultData.data.sources
    if type(sources) == "table" then
        for _, s in ipairs(sources) do
            if self:SourceMatchesType(s, sourceView) then
                return true
            end
        end
    end

    return false
end

function HC:ApplyEconomyFilters(results)
    local filtered = {}
    local performanceMode = HousingCompletedDB and HousingCompletedDB.ui and HousingCompletedDB.ui.performanceMode
    local minProfit = tonumber(HousingCompletedDB.filters and HousingCompletedDB.filters.minProfit) or 0
    local minMargin = tonumber(HousingCompletedDB.filters and HousingCompletedDB.filters.minMargin) or 0
    local craftableOnly = HousingCompletedDB.filters and HousingCompletedDB.filters.craftableOnly
    local lowRiskOnly = HousingCompletedDB.filters and HousingCompletedDB.filters.lowRiskOnly

    for _, r in ipairs(results or {}) do
        local econ = self.GetResultEconomics and self:GetResultEconomics(r, { forceRefresh = not performanceMode }) or nil
        local keep = econ and econ.ahPrice and econ.totalCost
        if keep and minProfit > 0 then
            keep = (econ.profit or 0) >= minProfit
        end
        if keep and minMargin > 0 then
            keep = (econ.margin or 0) >= minMargin
        end
        if keep and craftableOnly then
            keep = (econ.craftCost ~= nil)
        end
        if keep and lowRiskOnly then
            keep = (econ.risk or 100) <= 35
        end
        if keep then
            table.insert(filtered, r)
        end
    end

    return filtered
end

function HC:ApplyResultLayout()
    local gridMode = currentViewMode == "grid"
    local rowBaseHeight = gridMode and 84 or (ITEM_HEIGHT - 5)
    local rowW = (self.resultsFrame and self.resultsFrame:GetWidth() or 900) - 10
    local colW = math.floor((rowW - 8) / 2)

    for idx, row in ipairs(self.resultRows or {}) do
        row:ClearAllPoints()
        if gridMode then
            local col = (idx - 1) % 2
            local r = math.floor((idx - 1) / 2)
            row:SetHeight(rowBaseHeight)
            row:SetWidth(colW)
            row:SetPoint("TOPLEFT", self.resultsFrame, "TOPLEFT", 5 + col * (colW + 8), -5 - RESULTS_HEADER_HEIGHT - r * (rowBaseHeight + 6))

            row.nameText:ClearAllPoints()
            row.nameText:SetPoint("TOPLEFT", row.typeIcon, "TOPRIGHT", 10, -2)
            row.nameText:SetPoint("RIGHT", -10, 0)

            row.sourceText:ClearAllPoints()
            row.sourceText:SetPoint("TOPLEFT", row.nameText, "BOTTOMLEFT", 0, -2)
            row.sourceText:SetPoint("RIGHT", -10, 0)

            row.infoText:ClearAllPoints()
            row.infoText:SetPoint("TOPLEFT", row.sourceText, "BOTTOMLEFT", 0, -2)
            row.infoText:SetPoint("RIGHT", -10, 0)

            row.waypointBtn:Hide()
            row.marginText:Hide()
            row.profitText:Hide()
            row.craftVsBuyText:Hide()
            row.craftCostText:Hide()
            row.ahPriceText:Hide()
            row.typeBadge:Hide()
            if row.repBadge then row.repBadge:Hide() end
        else
            row:SetHeight(rowBaseHeight)
            row:SetPoint("TOPLEFT", self.resultsFrame, "TOPLEFT", 5, -5 - RESULTS_HEADER_HEIGHT - (idx - 1) * ITEM_HEIGHT)
            row:SetPoint("TOPRIGHT", self.resultsFrame, "TOPRIGHT", -5, -5 - RESULTS_HEADER_HEIGHT - (idx - 1) * ITEM_HEIGHT)

            row.nameText:ClearAllPoints()
            row.nameText:SetPoint("TOPLEFT", row.typeIcon, "TOPRIGHT", 10, -2)
            row.nameText:SetPoint("RIGHT", -470, 0)

            row.sourceText:ClearAllPoints()
            row.sourceText:SetPoint("TOPLEFT", row.nameText, "BOTTOMLEFT", 0, -2)
            row.sourceText:SetPoint("RIGHT", -470, 0)

            row.infoText:ClearAllPoints()
            row.infoText:SetPoint("TOPLEFT", row.sourceText, "BOTTOMLEFT", 0, -2)
            row.infoText:SetPoint("RIGHT", -470, 0)

            row.waypointBtn:Show()
            row.marginText:Show()
            row.profitText:Show()
            row.craftVsBuyText:Show()
            row.craftCostText:Show()
            row.ahPriceText:Show()
            row.typeBadge:Show()
        end
    end

    for _, h in pairs(self.acquireSortHeaders or {}) do
        h:SetShown(not gridMode)
    end

    for modeID, btn in pairs(self.viewModeButtons or {}) do
        local active = modeID == currentViewMode
        btn:SetBackdropColor(active and 0.14 or 0.1, active and 0.26 or 0.12, active and 0.42 or 0.18, 1)
        btn.text:SetTextColor(active and 1 or 0.76, active and 1 or 0.84, active and 1 or 0.96)
    end
end

function HC:UpdateResults()
    if currentTab == "analytics" then
        for i = 1, ITEMS_PER_PAGE do
            if self.resultRows[i] then self.resultRows[i]:Hide() end
        end
        if self.pageText then self.pageText:SetText("Analytics") end
        if self.prevBtn then self.prevBtn:SetEnabled(false) end
        if self.nextBtn then self.nextBtn:SetEnabled(false) end
        if self.statusText then self.statusText:SetText("Analytics View") end
        self:RefreshAnalyticsPanel()
        return
    end

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
            local streamerMode = HousingCompletedDB and HousingCompletedDB.ui and HousingCompletedDB.ui.streamerMode
            
            local sourceInfo = self:GetSourceTypeInfo(data.type)
            local icon = sourceInfo.icon
            local resolvedItemID = self:GetResolvedItemID(data)
            
            if resolvedItemID then
                local itemIcon
                if C_Item and C_Item.GetItemIconByID then
                    itemIcon = C_Item.GetItemIconByID(resolvedItemID)
                elseif GetItemIcon then
                    itemIcon = GetItemIcon(resolvedItemID)
                end
                if itemIcon then icon = itemIcon end
            end

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
            if row.favoriteIcon then
                row.favoriteIcon:SetShown(self:IsItemFavorite(data))
            end
            
            local sourceText = data.source or ""
            if currentSourceView == "items" then
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
            if HousingCompletedDB and HousingCompletedDB.ui and HousingCompletedDB.ui.showSourceDetails == false then
                row.infoText:SetText("")
            else
                row.infoText:SetText(infoText)
            end

            local economics = self.GetResultEconomics and self:GetResultEconomics(data) or nil
            if streamerMode then
                row.ahPriceText:SetText("-")
                row.craftCostText:SetText("-")
                row.profitText:SetText("-")
                row.marginText:SetText("-")
            else
                row.ahPriceText:SetText(FormatMoneyValue(economics and economics.ahPrice))
                row.craftCostText:SetText(FormatMoneyValue(economics and economics.craftCost))
                row.profitText:SetText(FormatMoneyValue(economics and economics.profit and math.abs(economics.profit) or nil))
                row.marginText:SetText(FormatMarginValue(economics and economics.margin))
            end
            local cvb = economics and economics.craftVsBuy or "-"
            if cvb == "BuyAH" then cvb = "Buy (AH)"
            elseif cvb == "BuyVendor" then cvb = "Buy (V)"
            end
            row.craftVsBuyText:SetText(cvb or "-")

            if (not streamerMode) and economics and economics.trend and economics.trend.arrow then
                local trendText = string.format(" |cff666666| |rTrend: %s %.1f%%  Risk: %d", economics.trend.arrow, economics.trend.changePct or 0, economics.risk or 0)
                row.infoText:SetText((row.infoText:GetText() or "") .. trendText)
            end

            if economics and economics.profit then
                if economics.profit >= 0 then
                    row.profitText:SetTextColor(0.3, 1, 0.3)
                    row.marginText:SetTextColor(0.3, 1, 0.3)
                    row.profitText:SetText("+" .. row.profitText:GetText())
                else
                    row.profitText:SetTextColor(1, 0.35, 0.35)
                    row.marginText:SetTextColor(1, 0.35, 0.35)
                    row.profitText:SetText("-" .. row.profitText:GetText())
                end
            else
                row.profitText:SetTextColor(unpack(COLORS.textMuted))
                row.marginText:SetTextColor(unpack(COLORS.textMuted))
            end
            row.ahPriceText:SetTextColor(unpack(COLORS.textMuted))
            row.craftCostText:SetTextColor(unpack(COLORS.textMuted))
            row.craftVsBuyText:SetTextColor(unpack(COLORS.textMuted))
            
            row.typeBadge:SetText(sourceInfo.name)
            row.typeBadge:SetTextColor(unpack(sourceInfo.color))

            local repRequirements = self:GetReputationRequirements(data)
            if row.repBadge then
                row.repBadge.repRequirements = repRequirements
                row.repBadge:SetShown(#repRequirements > 0 and currentViewMode ~= "grid")
            end
            
            row.vendorData = data.type == "vendor" and data.data or nil
            row.vendorName = data.vendor
            
            local hasCoords = self.ResultHasWaypoint and self:ResultHasWaypoint(data)
            row.waypointBtn:SetEnabled(hasCoords and currentViewMode ~= "grid" and true or false)
            row.waypointBtn:SetAlpha((hasCoords and currentViewMode ~= "grid") and 1 or 0.3)
            
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

function HC:RefreshVisiblePricingData()
    if HousingCompletedDB and HousingCompletedDB.ui and HousingCompletedDB.ui.performanceMode then
        return
    end
    if #currentResults == 0 then
        return
    end

    for _, resultData in ipairs(currentResults) do
        if self.GetResultEconomics then
            self:GetResultEconomics(resultData, { forceRefresh = true })
        end
    end

    if currentTab == "economy" or currentTab == "planner" then
        local filtered = {}
        for _, r in ipairs(currentResults) do
            local econ = self.GetResultEconomics and self:GetResultEconomics(r) or nil
            if econ and econ.ahPrice and econ.totalCost then
                table.insert(filtered, r)
            end
        end
        currentResults = filtered
        totalPages = math.max(1, math.ceil(#currentResults / ITEMS_PER_PAGE))
        if currentPage > totalPages then
            currentPage = totalPages
        end
    end

    self:SortCurrentResults()
    self:UpdateAcquireSortHeaderState()
    self:UpdateResults()
    if selectedItem and self.UpdatePreview then
        self:UpdatePreview(selectedItem)
    end
    self:UpdatePlannerControls()
end

function HC:RunPlanner()
    local budget = tonumber(self.plannerBudgetBox and self.plannerBudgetBox:GetText()) or 0
    local plan = self.BuildCapitalAllocationPlan and self:BuildCapitalAllocationPlan(currentResults, budget, {
        minProfit = tonumber(HousingCompletedDB.filters and HousingCompletedDB.filters.minProfit) or 0,
        minMargin = tonumber(HousingCompletedDB.filters and HousingCompletedDB.filters.minMargin) or 0,
        maxPerItem = 3,
    }) or nil
    if not plan then
        if self.plannerSummaryText then
            self.plannerSummaryText:SetText("Planner unavailable.")
        end
        return
    end

    local bottlenecks = self.DetectSupplyBottlenecks and self:DetectSupplyBottlenecks(plan) or {}
    local bottleneckText = ""
    if bottlenecks[1] then
        bottleneckText = string.format(" Bottleneck: %s x%d", bottlenecks[1].name or "Unknown", bottlenecks[1].totalQty or 0)
    end
    if self.plannerSummaryText then
        self.plannerSummaryText:SetText(plan.summary .. bottleneckText)
    end
end

function HC:UpdatePlannerControls()
    local show = currentTab == "planner"
    if self.plannerBudgetBox then self.plannerBudgetBox:SetShown(show) end
    if self.plannerRunBtn then self.plannerRunBtn:SetShown(show) end
    if self.plannerSummaryText then self.plannerSummaryText:SetShown(show) end
    local analytics = currentTab == "analytics"
    if self.resultsFrame then self.resultsFrame:SetShown(not analytics) end
    if self.analyticsFrame then self.analyticsFrame:SetShown(analytics) end
    if self.pageText then self.pageText:SetShown(not analytics) end
    if self.prevBtn then self.prevBtn:SetShown(not analytics) end
    if self.nextBtn then self.nextBtn:SetShown(not analytics) end
    if self.statusText then
        self.statusText:SetText(analytics and "Analytics View" or string.format("%d results", #currentResults))
    end
end

function HC:UpdatePrimaryTabs()
    for tabID, btn in pairs(self.primaryTabButtons or {}) do
        local active = tabID == currentPrimaryTab
        if active then
            btn:SetBackdropColor(0.12, 0.2, 0.32, 0.98)
            btn:SetBackdropBorderColor(unpack(COLORS.accentAlt))
            btn.label:SetTextColor(1, 1, 1)
            btn.underline:SetAlpha(1)
        else
            btn:SetBackdropColor(0.09, 0.11, 0.16, 0.94)
            btn:SetBackdropBorderColor(0.17, 0.24, 0.35, 1)
            btn.label:SetTextColor(unpack(COLORS.textMuted))
            btn.underline:SetAlpha(0.15)
        end
    end
end

function HC:UpdateTabButtons()
    for tabID, btn in pairs(self.tabButtons) do
        if tabID == currentTab then
            btn.bg:SetColorTexture(0.23, 0.18, 0.07, 0.95)
            btn:SetBackdropBorderColor(unpack(COLORS.accentAlt))
            btn.label:SetTextColor(1, 0.95, 0.8)
            if btn.icon then btn.icon:SetVertexColor(1, 1, 1) end
        else
            btn.bg:SetColorTexture(0.16, 0.15, 0.19, 0.5)
            btn:SetBackdropBorderColor(0.24, 0.22, 0.28, 1)
            btn.label:SetTextColor(0.78, 0.76, 0.72)
            if btn.icon then btn.icon:SetVertexColor(0.82, 0.82, 0.82) end
        end
    end
    self:UpdateModeButtons()
    self:UpdatePrimaryTabs()
    self:UpdateSourceViewButtons()
    self:UpdateItemCategoryButtons()
    self:UpdatePlannerControls()
end

function HC:UpdateSourceViewButtons()
    local counts = {}
    for sourceID in pairs(self.sourceViewButtons or {}) do
        counts[sourceID] = 0
    end

    local query = self.searchBox and self.searchBox:GetText() or ""
    local countFilters = self:BuildSourceCountFilters()
    local countResults = self:SearchAll(query, countFilters) or {}
    local visibleResults = {}

    for _, r in ipairs(countResults) do
        local show = true
        if r.collected and not countFilters.showCollected then show = false end
        if not r.collected and not countFilters.showUncollected then show = false end
        if show then
            table.insert(visibleResults, r)
        end
    end

    if currentTab == "economy" or currentTab == "planner" then
        visibleResults = self:ApplyEconomyFilters(visibleResults)
    end

    for _, r in ipairs(visibleResults) do
        for sourceID in pairs(counts) do
            if self:ResultMatchesSourceView(r, sourceID) then
                counts[sourceID] = counts[sourceID] + 1
            end
        end
    end

    for sourceID, btn in pairs(self.sourceViewButtons or {}) do
        if sourceID == currentSourceView then
            btn.bg:SetColorTexture(0.23, 0.18, 0.07, 0.95)
            btn:SetBackdropBorderColor(unpack(COLORS.accentAlt))
            btn.label:SetTextColor(1, 0.95, 0.8)
            if btn.icon then btn.icon:SetVertexColor(1, 1, 1) end
            if btn.countText then btn.countText:SetTextColor(1, 0.95, 0.8) end
        else
            btn.bg:SetColorTexture(0.16, 0.15, 0.19, 0.5)
            btn:SetBackdropBorderColor(0.24, 0.22, 0.28, 1)
            btn.label:SetTextColor(0.78, 0.76, 0.72)
            if btn.icon then btn.icon:SetVertexColor(0.82, 0.82, 0.82) end
            if btn.countText then btn.countText:SetTextColor(unpack(COLORS.textDim)) end
        end
        if btn.countText then
            btn.countText:SetText(tostring(counts[sourceID] or 0))
        end
    end
end

function HC:UpdateModeButtons()
    local active = (HousingCompletedDB and HousingCompletedDB.mode) or "hybrid"
    if active ~= "hybrid" and active ~= "goblin" then
        active = "hybrid"
        if HousingCompletedDB then
            HousingCompletedDB.mode = active
        end
    end
    for modeKey, btn in pairs(self.modeButtons or {}) do
        if modeKey == active then
            btn:SetBackdropColor(0.25, 0.19, 0.08, 0.95)
            btn:SetBackdropBorderColor(unpack(COLORS.accentAlt))
            btn.text:SetTextColor(1, 0.95, 0.84)
        else
            btn:SetBackdropColor(0.14, 0.13, 0.16, 0.95)
            btn:SetBackdropBorderColor(0.24, 0.22, 0.28, 1)
            btn.text:SetTextColor(0.72, 0.72, 0.72)
        end
    end

    local visibleTabs = {
        acquire = true, craft = true, economy = true, planner = true, analytics = true, collection = true,
    }
    if active == "goblin" then
        visibleTabs.collection = false
    end

    for tabID, btn in pairs(self.tabButtons or {}) do
        btn:SetShown(visibleTabs[tabID] and true or false)
    end
    if not visibleTabs[currentTab] then
        currentTab = active == "goblin" and "economy" or "acquire"
    end
    for _, w in ipairs(self.econFilterWidgets or {}) do
        w:SetShown(true)
    end
end

function HC:UpdateItemCategoryButtons()
    local showCategories = currentSourceView == "items"
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

function HC:UpdateAcquireSortHeaderState()
    for key, btn in pairs(self.acquireSortHeaders or {}) do
        if key == currentSortKey then
            local arrow = currentSortAscending and " ^" or " v"
            btn.text:SetText((key == "ahPrice" and "AH Price")
                or (key == "craftCost" and "Craft Cost")
                or (key == "craftVsBuyRank" and "Craft/Buy")
                or (key == "profit" and "Profit")
                or "Margin")
            btn.text:SetTextColor(unpack(COLORS.accent))
            btn.text:SetText(btn.text:GetText() .. arrow)
        else
            if key == "ahPrice" then
                btn.text:SetText("AH Price")
            elseif key == "craftCost" then
                btn.text:SetText("Craft Cost")
            elseif key == "craftVsBuyRank" then
                btn.text:SetText("Craft/Buy")
            elseif key == "profit" then
                btn.text:SetText("Profit")
            else
                btn.text:SetText("Margin")
            end
            btn.text:SetTextColor(unpack(COLORS.textMuted))
        end
    end
end

function HC:SortCurrentResults()
    local nilSentinel = currentSortAscending and math.huge or -math.huge
    table.sort(currentResults, function(a, b)
        if currentSortKey == "name" then
            local av = (a.name or ""):lower()
            local bv = (b.name or ""):lower()
            if currentSortAscending then
                return av < bv
            end
            return av > bv
        end

        local ae = self.GetResultEconomics and self:GetResultEconomics(a) or nil
        local be = self.GetResultEconomics and self:GetResultEconomics(b) or nil
        local av = ae and ae[currentSortKey] or nil
        local bv = be and be[currentSortKey] or nil
        if currentSortKey == "craftVsBuyRank" then
            local rankMap = { Craft = 3, BuyVendor = 2, BuyAH = 1, Unknown = 0 }
            av = rankMap[ae and ae.craftVsBuy or "Unknown"] or 0
            bv = rankMap[be and be.craftVsBuy or "Unknown"] or 0
        end
        if av == bv then
            local an = (a.name or ""):lower()
            local bn = (b.name or ""):lower()
            return an < bn
        end
        av = av or nilSentinel
        bv = bv or nilSentinel
        if currentSortAscending then
            return av < bv
        end
        return av > bv
    end)
end

function HC:SetAcquireSort(sortKey)
    if currentSortKey == sortKey then
        currentSortAscending = not currentSortAscending
    else
        currentSortKey = sortKey
        currentSortAscending = (sortKey == "name")
    end
    self:SortCurrentResults()
    self:UpdateAcquireSortHeaderState()
    self:UpdateResults()
end

function HC:UpdateStats()
    local stats = self:GetStatistics()
    local pctCollectedTrackable = stats.trackableTotal > 0 and math.floor((stats.collectedTrackable / stats.trackableTotal) * 100) or 0
    local favoriteCount = 0
    if HousingCompletedDB and HousingCompletedDB.favorites and HousingCompletedDB.favorites.items then
        for _, v in pairs(HousingCompletedDB.favorites.items) do
            if v then favoriteCount = favoriteCount + 1 end
        end
    end

    if self.completionBar then
        local maxW = (self.header and self.header:GetWidth() and self.header:GetWidth() > 80) and (self.header:GetWidth() - 64) or (FRAME_WIDTH - 64)
        local barW = math.max(2, math.floor(maxW * (pctCollectedTrackable / 100)))
        self.completionBar:SetWidth(barW)
    end
    if self.completionValueText then
        self.completionValueText:SetText(string.format("%d%%", pctCollectedTrackable))
    end

    if self.statsText then
        local pctTrackableKnown = stats.knownTotal > 0 and math.floor((stats.trackableTotal / stats.knownTotal) * 100) or 0
        if HousingCompletedDB and HousingCompletedDB.ui and HousingCompletedDB.ui.streamerMode then
            self.statsText:SetText(string.format(
                "Missing: %d  | Favorites: %d  | Current Expansion: %d%%",
                math.max(0, stats.trackableTotal - stats.collectedTrackable), favoriteCount, pctCollectedTrackable
            ))
        else
            self.statsText:SetText(string.format(
                "Missing: %d  | Favorites: %d  | Recently Obtained: 0  | Trackable/Known: %d%%",
                math.max(0, stats.trackableTotal - stats.collectedTrackable), favoriteCount, pctTrackableKnown
            ))
        end
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
        if HousingCompletedDB and HousingCompletedDB.lastTab and self.tabButtons and self.tabButtons[HousingCompletedDB.lastTab] then
            currentTab = HousingCompletedDB.lastTab
        end
        if HousingCompletedDB and HousingCompletedDB.lastSourceView and self.sourceViewButtons and self.sourceViewButtons[HousingCompletedDB.lastSourceView] then
            currentSourceView = HousingCompletedDB.lastSourceView
        end
        if HousingCompletedDB and HousingCompletedDB.ui and type(HousingCompletedDB.ui.primaryTab) == "string" then
            currentPrimaryTab = HousingCompletedDB.ui.primaryTab
        end
        if HousingCompletedDB and HousingCompletedDB.ui and (HousingCompletedDB.ui.viewMode == "grid" or HousingCompletedDB.ui.viewMode == "list") then
            currentViewMode = HousingCompletedDB.ui.viewMode
        end
        if self.settingsPanel then self.settingsPanel:Hide() end
        if self.content then self.content:Show() end
        if self.previewPanel then self.previewPanel:Show() end
        if self.CacheCollection and not self.catalogReady then
            self:CacheCollection()
        end
        self:UpdateTabButtons()
        self:ApplyResultLayout()
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
