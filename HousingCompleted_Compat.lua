local function MergeArrayByValue(dst, src)
    if type(dst) ~= "table" or type(src) ~= "table" then
        return
    end

    local seen = {}
    for _, v in ipairs(dst) do
        seen[v] = true
    end
    for _, v in ipairs(src) do
        if not seen[v] then
            table.insert(dst, v)
            seen[v] = true
        end
    end
end

local function MergeArrayByItemID(dst, src)
    if type(dst) ~= "table" or type(src) ~= "table" then
        return
    end

    local seen = {}
    for _, row in ipairs(dst) do
        local id = type(row) == "table" and row.itemID or nil
        if id then seen[id] = true end
    end
    for _, row in ipairs(src) do
        local id = type(row) == "table" and row.itemID or nil
        if id and not seen[id] then
            table.insert(dst, row)
            seen[id] = true
        end
    end
end

local function MergeBackend(ours, legacy)
    if type(ours) ~= "table" or type(legacy) ~= "table" then
        return false
    end

    -- Copy missing members only; do not replace existing UI/backend methods.
    for k, v in pairs(legacy) do
        if ours[k] == nil then
            ours[k] = v
        end
    end

    -- Merge likely backend data sources for item/index/preview usage.
    if type(ours.DecorItems) == "table" and type(legacy.DecorItems) == "table" then
        MergeArrayByItemID(ours.DecorItems, legacy.DecorItems)
    end
    if type(ours.ImportedDecorItems) == "table" and type(legacy.ImportedDecorItems) == "table" then
        MergeArrayByItemID(ours.ImportedDecorItems, legacy.ImportedDecorItems)
    end
    if type(ours.AllItems) == "table" and type(legacy.AllItems) == "table" then
        ours.AllItems.IDs = ours.AllItems.IDs or {}
        MergeArrayByValue(ours.AllItems.IDs, legacy.AllItems.IDs or {})
    end
    if type(ours.ImportedAllItems) == "table" and type(legacy.ImportedAllItems) == "table" then
        ours.ImportedAllItems.IDs = ours.ImportedAllItems.IDs or {}
        MergeArrayByValue(ours.ImportedAllItems.IDs, legacy.ImportedAllItems.IDs or {})
    end

    return true
end

local function RefreshAfterMerge(HC)
    if not HC then return end
    pcall(function() if HC.BuildItemIndex then HC:BuildItemIndex(true) end end)
    pcall(function() if HC.ResolveAllItems then HC:ResolveAllItems() end end)
    pcall(function() if HC.UpdateResults and HC.mainFrame and HC.mainFrame:IsShown() then HC:UpdateResults() end end)
    pcall(function() if HC.UpdatePreview then HC:UpdatePreview(nil) end end)
end

local function TryCompatMerge()
    if not _G.HousingDecorGuide then
        local loader = (C_AddOns and C_AddOns.LoadAddOn) or LoadAddOn
        if type(loader) == "function" then
            pcall(loader, "HousingDecorGuide")
        end
    end

    local HC = _G.HousingCompleted
    local legacy = _G.HousingDecorGuide
    if type(HC) ~= "table" or type(legacy) ~= "table" then
        return
    end

    if MergeBackend(HC, legacy) then
        _G.HousingCompleted = HC
        RefreshAfterMerge(HC)
    end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(_, event, addonName)
    if event ~= "ADDON_LOADED" then
        return
    end

    -- Merge when either addon finishes loading.
    if addonName == "HousingCompleted" or addonName == "HousingDecorGuide" then
        TryCompatMerge()
    end
end)
