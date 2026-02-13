---------------------------------------------------
-- Housing Completed - Systems/Planner.lua
-- Economy planner and craft-tree helpers
---------------------------------------------------
local addonName, HC = ...

local function SafeDiv(a, b)
    if not a or not b or b == 0 then return 0 end
    return a / b
end

function HC:GetEconomyCandidates(results, opts)
    opts = opts or {}
    local candidates = {}
    for _, resultData in ipairs(results or {}) do
        local econ = self:GetResultEconomics(resultData)
        if econ and econ.ahPrice and econ.totalCost and econ.profit and econ.profit > 0 then
            if (not opts.minProfit) or econ.profit >= opts.minProfit then
                if (not opts.minMargin) or ((econ.margin or 0) >= opts.minMargin) then
                    table.insert(candidates, {
                        result = resultData,
                        economics = econ,
                        itemID = resultData.itemID or (resultData.data and resultData.data.itemID),
                        name = resultData.name,
                        cost = econ.totalCost,
                        profit = econ.profit,
                        margin = econ.margin or 0,
                        roi = SafeDiv(econ.profit, econ.totalCost),
                    })
                end
            end
        end
    end
    return candidates
end

function HC:BuildCapitalAllocationPlan(results, budgetCopper, opts)
    opts = opts or {}
    local budget = tonumber(budgetCopper) or 0
    if budget <= 0 then
        return { picks = {}, spent = 0, projectedProfit = 0, remaining = budget, summary = "Budget is zero." }
    end

    local candidates = self:GetEconomyCandidates(results, opts)
    table.sort(candidates, function(a, b)
        if a.roi == b.roi then
            return (a.profit or 0) > (b.profit or 0)
        end
        return (a.roi or 0) > (b.roi or 0)
    end)

    local picks = {}
    local spent = 0
    local projectedProfit = 0
    for _, c in ipairs(candidates) do
        local maxQty = math.floor((budget - spent) / (c.cost or math.huge))
        if maxQty > 0 then
            local qty = maxQty
            if opts.maxPerItem and opts.maxPerItem > 0 then
                qty = math.min(qty, opts.maxPerItem)
            end
            if qty > 0 then
                table.insert(picks, {
                    name = c.name,
                    itemID = c.itemID,
                    qty = qty,
                    unitCost = c.cost,
                    unitProfit = c.profit,
                    totalCost = qty * c.cost,
                    totalProfit = qty * c.profit,
                    margin = c.margin,
                    roi = c.roi,
                    result = c.result,
                })
                spent = spent + (qty * c.cost)
                projectedProfit = projectedProfit + (qty * c.profit)
            end
        end
    end

    return {
        picks = picks,
        spent = spent,
        projectedProfit = projectedProfit,
        remaining = budget - spent,
        summary = string.format("Spent %s for projected %s profit.", self:FormatMoney(spent), self:FormatMoney(projectedProfit)),
    }
end

function HC:DetectSupplyBottlenecks(plan)
    local demand = {}
    for _, pick in ipairs((plan and plan.picks) or {}) do
        local econ = self:GetResultEconomics(pick.result)
        for _, reagent in ipairs((econ and econ.reagents) or {}) do
            local key = tostring(reagent.itemID or reagent.name or "unknown")
            local row = demand[key]
            if not row then
                row = {
                    itemID = reagent.itemID,
                    name = reagent.name or ("Item #" .. tostring(reagent.itemID)),
                    totalQty = 0,
                    crafts = 0,
                    source = reagent.source,
                }
                demand[key] = row
            end
            row.totalQty = row.totalQty + ((reagent.qty or 1) * (pick.qty or 1))
            row.crafts = row.crafts + 1
        end
        for _, missing in ipairs((econ and econ.missingMaterials) or {}) do
            local key = tostring(missing.itemID or missing.name or "unknown")
            local row = demand[key]
            if not row then
                row = {
                    itemID = missing.itemID,
                    name = missing.name or ("Item #" .. tostring(missing.itemID)),
                    totalQty = 0,
                    crafts = 0,
                    source = "missing",
                }
                demand[key] = row
            end
            row.totalQty = row.totalQty + ((missing.quantity or 1) * (pick.qty or 1))
            row.crafts = row.crafts + 1
            row.source = "missing"
        end
    end

    local out = {}
    for _, row in pairs(demand) do
        table.insert(out, row)
    end
    table.sort(out, function(a, b)
        if a.source == b.source then
            return (a.totalQty or 0) > (b.totalQty or 0)
        end
        return a.source == "missing"
    end)
    return out
end

function HC:ResolveCheapestPathForResult(resultData)
    local econ = self:GetResultEconomics(resultData)
    if not econ then return nil end

    local plan = {
        name = resultData.name,
        itemID = resultData.itemID or (resultData.data and resultData.data.itemID),
        ahPrice = econ.ahPrice,
        craftCost = econ.craftCost,
        vendorCost = econ.vendorCost,
        totalCost = econ.totalCost,
        recommendation = "Unknown",
        reagentDecisions = {},
    }

    local craftVsBuy = econ.craftVsBuy or "Unknown"
    if craftVsBuy == "Craft" then
        plan.recommendation = "Craft"
    elseif craftVsBuy == "BuyAH" or craftVsBuy == "BuyVendor" then
        plan.recommendation = "Buy"
    end

    for _, r in ipairs(econ.reagents or {}) do
        local decision = "Farm"
        if r.source == "vendor" then
            decision = "BuyVendor"
        elseif r.source == "auction" then
            decision = "BuyAH"
        elseif r.source == "fixed" then
            decision = "BuyFixed"
        end
        table.insert(plan.reagentDecisions, {
            itemID = r.itemID,
            name = r.name,
            qty = r.qty,
            unitCost = r.unitCost,
            totalCost = r.totalCost,
            decision = decision,
        })
    end

    return plan
end
