---------------------------------------------------
-- Housing Completed - Systems/Economics.lua
-- Shared acquisition/crafting/profit calculations
---------------------------------------------------
local addonName, HC = ...

local function ToNumber(v)
    local n = tonumber(v)
    if n and n > 0 then
        return n
    end
    return nil
end

local function ParseTokenNumber(text)
    if type(text) ~= "string" then return nil end
    local clean = text:gsub(",", "")
    local n = tonumber(clean)
    if n and n > 0 then
        return n
    end
    return nil
end

local function MinPositive(a, b)
    if a and b then
        return math.min(a, b)
    end
    return a or b
end

local function PushReagent(output, itemID, reagentData)
    if type(reagentData) ~= "table" then
        reagentData = { qty = reagentData }
    end
    local qty = ToNumber(reagentData.qty) or ToNumber(reagentData.amount) or ToNumber(reagentData.count) or 1
    table.insert(output, {
        itemID = itemID,
        qty = math.max(1, math.floor(qty + 0.5)),
        name = reagentData.name,
        vendorPrice = reagentData.vendorPrice or reagentData.vendorCost or reagentData.vendor_cost,
        cost = reagentData.cost,
        itemLink = reagentData.itemLink,
    })
end

function HC:ParseMoneyToCopper(value)
    if value == nil then
        return nil
    end

    if type(value) == "number" then
        if value <= 0 then return nil end
        return math.floor(value + 0.5)
    end

    if type(value) ~= "string" then
        return nil
    end

    local text = value:lower()
    if text == "" then return nil end

    local gold = 0
    local silver = 0
    local copper = 0

    for num in text:gmatch("([%d,%.]+)%s*g") do
        gold = ParseTokenNumber(num) or gold
    end
    for num in text:gmatch("([%d,%.]+)%s*s") do
        silver = ParseTokenNumber(num) or silver
    end
    for num in text:gmatch("([%d,%.]+)%s*c") do
        copper = ParseTokenNumber(num) or copper
    end

    if gold > 0 or silver > 0 or copper > 0 then
        return (gold * 10000) + (silver * 100) + copper
    end

    -- "123 gold 45 silver 6 copper" style
    for num in text:gmatch("([%d,%.]+)%s*gold") do
        gold = ParseTokenNumber(num) or gold
    end
    for num in text:gmatch("([%d,%.]+)%s*silver") do
        silver = ParseTokenNumber(num) or silver
    end
    for num in text:gmatch("([%d,%.]+)%s*copper") do
        copper = ParseTokenNumber(num) or copper
    end

    if gold > 0 or silver > 0 or copper > 0 then
        return (gold * 10000) + (silver * 100) + copper
    end

    local plain = ParseTokenNumber(text)
    if plain then
        return math.floor(plain + 0.5)
    end

    return nil
end

function HC:FormatMoney(copper)
    if not copper or copper <= 0 then
        return "-"
    end

    local g = math.floor(copper / 10000)
    local s = math.floor((copper % 10000) / 100)
    local c = copper % 100

    if g > 0 then
        return string.format("%dg %02ds", g, s)
    elseif s > 0 then
        return string.format("%ds %02dc", s, c)
    else
        return string.format("%dc", c)
    end
end

function HC:GetVendorAcquisitionCost(resultData)
    if not resultData then return nil end

    local best = self:ParseMoneyToCopper(resultData.cost)
    local sources = resultData.data and resultData.data.sources
    if type(sources) == "table" then
        for _, s in ipairs(sources) do
            local sourceType = self.NormalizeSourceType and self:NormalizeSourceType(s.sourceType or "unknown") or (s.sourceType or "unknown")
            if sourceType == "vendor" or s.vendor then
                best = MinPositive(best, self:ParseMoneyToCopper(s.cost))
            end
        end
    end
    return best
end

function HC:GetCraftReagents(resultData)
    local reagents = {}
    if not resultData then return reagents end

    local function Collect(container)
        if type(container) ~= "table" then return end
        if #container > 0 then
            for _, r in ipairs(container) do
                local rid = r.itemID or r.id
                PushReagent(reagents, rid, r)
            end
            return
        end
        for reagentID, reagentData in pairs(container) do
            local rid = tonumber(reagentID) or (type(reagentData) == "table" and (reagentData.itemID or reagentData.id))
            PushReagent(reagents, rid, reagentData)
        end
    end

    local data = resultData.data
    if data then
        Collect(data.reagents)
        if data.recipe then
            Collect(data.recipe.reagents)
        end
        Collect(data.recipeReagents)
    end

    if #reagents == 0 and type(data and data.sources) == "table" then
        for _, s in ipairs(data.sources) do
            Collect(s and s.reagents)
        end
    end

    return reagents
end

function HC:GetAuctionPriceForResult(resultData)
    if not (self.PricingProvider and self.PricingProvider.IsEnabled and self.PricingProvider:IsEnabled()) then
        return nil
    end

    local itemID = (self.GetResolvedItemID and self:GetResolvedItemID(resultData))
        or resultData.itemID
        or (resultData.data and resultData.data.itemID)
    if not itemID then
        return nil
    end

    local itemLink = nil
    if C_Item and C_Item.GetItemLinkByID then
        itemLink = C_Item.GetItemLinkByID(itemID)
    end

    return self.PricingProvider:GetAuctionPrice(itemLink, itemID)
end

function HC:GetReagentUnitCost(reagent)
    if not reagent then return nil, nil end

    local explicitVendor = self:ParseMoneyToCopper(reagent.vendorPrice)
    if explicitVendor and explicitVendor > 0 then
        return explicitVendor, "vendor"
    end

    local itemID = reagent.itemID
    local itemLink = reagent.itemLink
    if not itemLink and itemID and C_Item and C_Item.GetItemLinkByID then
        itemLink = C_Item.GetItemLinkByID(itemID)
    end

    if self.PricingProvider and self.PricingProvider.IsEnabled and self.PricingProvider:IsEnabled() then
        local vendorPrice = self.PricingProvider:GetVendorPrice(itemLink, itemID)
        if vendorPrice and vendorPrice > 0 then
            return vendorPrice, "vendor"
        end

        local ahPrice = self.PricingProvider:GetAuctionPrice(itemLink, itemID)
        if ahPrice and ahPrice > 0 then
            return ahPrice, "auction"
        end
    end

    local explicitCost = self:ParseMoneyToCopper(reagent.cost)
    if explicitCost and explicitCost > 0 then
        return explicitCost, "fixed"
    end

    return nil, nil
end

function HC:ComputeCraftCostForResult(resultData)
    local reagents = self:GetCraftReagents(resultData)
    if #reagents == 0 then
        local sourceType = self.NormalizeSourceType and self:NormalizeSourceType(resultData.type or "unknown") or (resultData.type or "unknown")
        if sourceType == "profession" then
            local bestFallback = self:ParseMoneyToCopper(resultData.cost)
            local sources = resultData.data and resultData.data.sources
            if type(sources) == "table" then
                for _, s in ipairs(sources) do
                    local sType = self.NormalizeSourceType and self:NormalizeSourceType(s.sourceType or "unknown") or (s.sourceType or "unknown")
                    if sType == "profession" then
                        bestFallback = MinPositive(bestFallback, self:ParseMoneyToCopper(s.cost))
                    end
                end
            end
            if bestFallback then
                return bestFallback, {}, {}
            end
        end
        return nil, {}, {}
    end

    local total = 0
    local missing = {}
    local resolved = {}

    for _, reagent in ipairs(reagents) do
        local unitCost, source = self:GetReagentUnitCost(reagent)
        local qty = reagent.qty or 1
        if unitCost and unitCost > 0 then
            local lineTotal = unitCost * qty
            total = total + lineTotal
            table.insert(resolved, {
                itemID = reagent.itemID,
                name = reagent.name,
                qty = qty,
                unitCost = unitCost,
                totalCost = lineTotal,
                source = source,
            })
        else
            table.insert(missing, {
                itemID = reagent.itemID,
                name = reagent.name or (reagent.itemID and ("Item #" .. reagent.itemID) or "Unknown Reagent"),
                quantity = qty,
            })
        end
    end

    if total <= 0 and #resolved == 0 then
        return nil, missing, resolved
    end

    return total, missing, resolved
end

function HC:BuildEconomicsSnapshot(resultData)
    if not resultData then return nil end

    local ahPrice = self:GetAuctionPriceForResult(resultData)
    local vendorCost = self:GetVendorAcquisitionCost(resultData)
    local craftCost, missingMaterials, reagents = self:ComputeCraftCostForResult(resultData)
    local totalCost = MinPositive(vendorCost, craftCost)

    local profit = nil
    local margin = nil
    if ahPrice and totalCost and totalCost > 0 then
        profit = ahPrice - totalCost
        margin = (profit / totalCost) * 100
    end

    return {
        ahPrice = ahPrice,
        vendorCost = vendorCost,
        craftCost = craftCost,
        totalCost = totalCost,
        profit = profit,
        margin = margin,
        missingMaterials = missingMaterials or {},
        reagents = reagents or {},
    }
end

function HC:GetResultEconomics(resultData, opts)
    if not resultData then return nil end
    opts = opts or {}

    local generation = (self.PricingProvider and self.PricingProvider.GetGeneration and self.PricingProvider:GetGeneration()) or 0
    local useCache = not opts.forceRefresh
    if useCache and resultData._economics and resultData._economicsGeneration == generation then
        return resultData._economics
    end

    local economics = self:BuildEconomicsSnapshot(resultData)
    resultData._economics = economics
    resultData._economicsGeneration = generation
    return economics
end

function HC:FindItemForQueueEntry(entry)
    if not entry then return nil end
    if (not self.ItemList) or (#self.ItemList == 0) then
        self:BuildItemIndex(true)
    end

    local wantedID = entry.itemID
    local wantedName = self:NormalizeItemName(entry.name)
    for _, item in ipairs(self.ItemList or {}) do
        if wantedID and item.itemID and item.itemID == wantedID then
            return item
        end
        if wantedName and self:NormalizeItemName(item.name) == wantedName then
            return item
        end
    end
    return nil
end

function HC:BuildResultFromQueueEntry(entry)
    if not entry then return nil end
    local item = self:FindItemForQueueEntry(entry)
    if not item then
        return {
            name = entry.name,
            itemID = entry.itemID,
            type = entry.sourceType or "unknown",
            cost = entry.cost,
            source = entry.source,
            vendor = entry.vendor,
            zone = entry.zone,
            data = {
                name = entry.name,
                itemID = entry.itemID,
                sources = {},
                sourceCount = 0,
            },
        }
    end

    return {
        name = item.name,
        itemID = item.itemID,
        type = (item.sources and item.sources[1] and item.sources[1].sourceType) or "unknown",
        source = item.sources and item.sources[1] and item.sources[1].source or entry.source,
        vendor = item.sources and item.sources[1] and item.sources[1].vendor or entry.vendor,
        zone = item.sources and item.sources[1] and item.sources[1].zone or entry.zone,
        cost = item.sources and item.sources[1] and item.sources[1].cost or entry.cost,
        data = {
            name = item.name,
            itemID = item.itemID,
            sources = item.sources,
            sourceCount = #(item.sources or {}),
        },
    }
end

function HC:GetCraftingQueueMissingMaterials()
    local list = self:GetShoppingList()
    local byKey = {}

    for _, entry in ipairs(list or {}) do
        local resultData = self:BuildResultFromQueueEntry(entry)
        local economics = self:GetResultEconomics(resultData, { forceRefresh = true })
        for _, missing in ipairs((economics and economics.missingMaterials) or {}) do
            local key = tostring(missing.itemID or 0) .. "|" .. tostring((missing.name or ""):lower())
            local bucket = byKey[key]
            if not bucket then
                bucket = {
                    itemID = missing.itemID,
                    name = missing.name,
                    quantity = 0,
                }
                byKey[key] = bucket
            end
            bucket.quantity = bucket.quantity + (missing.quantity or 1)
        end
    end

    local out = {}
    for _, mat in pairs(byKey) do
        table.insert(out, mat)
    end
    table.sort(out, function(a, b)
        return (a.name or "") < (b.name or "")
    end)

    return out
end

function HC:SendCraftingQueueMissingToAuctionator(shoppingListName, triggerSearch)
    if not (self.PricingProvider and self.PricingProvider.SendMissingMaterialsToShoppingList) then
        return false, 0, "Auctionator integration unavailable."
    end

    local missing = self:GetCraftingQueueMissingMaterials()
    return self.PricingProvider:SendMissingMaterialsToShoppingList(missing, shoppingListName, triggerSearch)
end

function HC:GetGoblinProfitRows(results)
    local rows = {}
    for _, resultData in ipairs(results or {}) do
        local economics = self:GetResultEconomics(resultData)
        if economics and economics.ahPrice and economics.totalCost then
            table.insert(rows, {
                name = resultData.name,
                itemID = resultData.itemID or (resultData.data and resultData.data.itemID),
                ahPrice = economics.ahPrice,
                totalCost = economics.totalCost,
                profit = economics.profit,
                margin = economics.margin,
                result = resultData,
            })
        end
    end
    return rows
end
