local addonName, HC = ...

local function SafeLower(v)
    return type(v) == "string" and string.lower(v) or ""
end

local function Clamp(v, lo, hi)
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

local function Dist(aMap, ax, ay, bMap, bx, by)
    if not aMap or not bMap or aMap ~= bMap then
        return 999999
    end
    local dx = (tonumber(ax) or 0) - (tonumber(bx) or 0)
    local dy = (tonumber(ay) or 0) - (tonumber(by) or 0)
    return math.sqrt(dx * dx + dy * dy)
end

function HC:GetAdvancedState()
    if type(HousingCompletedDB) ~= "table" then
        return nil
    end
    HousingCompletedDB.advanced = HousingCompletedDB.advanced or {}
    HousingCompletedDB.advanced.profiles = HousingCompletedDB.advanced.profiles or {}
    HousingCompletedDB.advanced.activeProfile = HousingCompletedDB.advanced.activeProfile or "default"
    if HousingCompletedDB.advanced.rulesEnabled == nil then
        HousingCompletedDB.advanced.rulesEnabled = false
    else
        HousingCompletedDB.advanced.rulesEnabled = HousingCompletedDB.advanced.rulesEnabled and true or false
    end
    HousingCompletedDB.advanced.telemetry = HousingCompletedDB.advanced.telemetry or {}
    HousingCompletedDB.advanced.snapshots = HousingCompletedDB.advanced.snapshots or {}
    HousingCompletedDB.advanced.blueprints = HousingCompletedDB.advanced.blueprints or {}
    if not HousingCompletedDB.advanced.profiles.default then
        HousingCompletedDB.advanced.profiles.default = {
            scoring = { profitability = 1.0, completion = 1.0, travel = 1.0, risk = 1.0 },
            rules = {},
        }
    end
    if not HousingCompletedDB.advanced.profiles[HousingCompletedDB.advanced.activeProfile] then
        HousingCompletedDB.advanced.profiles[HousingCompletedDB.advanced.activeProfile] = CopyTable(HousingCompletedDB.advanced.profiles.default)
    end
    return HousingCompletedDB.advanced
end

function HC:AdvancedRulesEnabled()
    local adv = self:GetAdvancedState()
    return adv and adv.rulesEnabled == true or false
end

function HC:SetAdvancedRulesEnabled(enabled)
    local adv = self:GetAdvancedState()
    if not adv then return false end
    adv.rulesEnabled = enabled and true or false
    return true
end

function HC:GetAdvancedProfileName()
    local adv = self:GetAdvancedState()
    return adv and adv.activeProfile or "default"
end

function HC:GetAdvancedProfile()
    local adv = self:GetAdvancedState()
    if not adv then
        return nil
    end
    return adv.profiles[adv.activeProfile]
end

function HC:SetAdvancedProfile(name)
    local adv = self:GetAdvancedState()
    if not adv then
        return false, "default"
    end
    local cleaned = tostring(name or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if cleaned == "" then
        cleaned = "default"
    end
    if not adv.profiles[cleaned] then
        local base = adv.profiles.default or {
            scoring = { profitability = 1.0, completion = 1.0, travel = 1.0, risk = 1.0 },
            rules = {},
        }
        adv.profiles[cleaned] = CopyTable(base)
    end
    adv.activeProfile = cleaned
    return true, cleaned
end

function HC:GetScoringConfig()
    local profile = self:GetAdvancedProfile() or {}
    profile.scoring = profile.scoring or {}
    local cfg = profile.scoring
    cfg.profitability = tonumber(cfg.profitability) or 1.0
    cfg.completion = tonumber(cfg.completion) or 1.0
    cfg.travel = tonumber(cfg.travel) or 1.0
    cfg.risk = tonumber(cfg.risk) or 1.0
    return cfg
end

function HC:SetScoringConfig(config)
    local profile = self:GetAdvancedProfile()
    if not profile then return false end
    profile.scoring = profile.scoring or {}
    for k, v in pairs(config or {}) do
        if profile.scoring[k] ~= nil then
            profile.scoring[k] = tonumber(v) or profile.scoring[k]
        end
    end
    return true
end

function HC:GetAdvancedRules()
    local profile = self:GetAdvancedProfile()
    if not profile then return {} end
    profile.rules = profile.rules or {}
    return profile.rules
end

function HC:AddAdvancedRule(rule)
    if type(rule) ~= "table" then return false end
    local rules = self:GetAdvancedRules()
    rules[#rules + 1] = {
        key = tostring(rule.key or ""),
        op = tostring(rule.op or ""),
        value = rule.value,
        enabled = rule.enabled ~= false,
    }
    return true
end

function HC:ClearAdvancedRules()
    local profile = self:GetAdvancedProfile()
    if not profile then return end
    profile.rules = {}
end

function HC:EvaluateRules(resultData, economics)
    local rules = self:GetAdvancedRules()
    if #rules == 0 then return true end
    local values = {
        profit = economics and tonumber(economics.profit) or 0,
        margin = economics and tonumber(economics.margin) or 0,
        risk = economics and tonumber(economics.risk) or 100,
        craftable = self:IsResultCraftable(resultData) and 1 or 0,
        collected = (resultData and resultData.collected) and 1 or 0,
        source = self.NormalizeSourceType and self:NormalizeSourceType(resultData and resultData.type or "unknown") or (resultData and resultData.type or "unknown"),
    }
    for _, rule in ipairs(rules) do
        if rule.enabled ~= false then
            local key = tostring(rule.key or "")
            local op = tostring(rule.op or "")
            local v = rule.value
            local cur = values[key]
            local pass = true
            if op == ">=" then
                pass = (tonumber(cur) or 0) >= (tonumber(v) or 0)
            elseif op == "<=" then
                pass = (tonumber(cur) or 0) <= (tonumber(v) or 0)
            elseif op == "==" then
                pass = tostring(cur) == tostring(v)
            elseif op == "!=" then
                pass = tostring(cur) ~= tostring(v)
            elseif op == "contains" then
                pass = tostring(cur):find(tostring(v), 1, true) ~= nil
            end
            if not pass then
                return false
            end
        end
    end
    return true
end

function HC:IsResultAllowedByRules(resultData)
    if not self:AdvancedRulesEnabled() then
        return true
    end
    local econ = self.GetResultEconomics and self:GetResultEconomics(resultData) or nil
    return self:EvaluateRules(resultData, econ)
end

function HC:IsResultCraftable(resultData)
    if not resultData then
        return false
    end
    local rt = self.NormalizeSourceType and self:NormalizeSourceType(resultData.type or "unknown") or (resultData.type or "unknown")
    if rt == "profession" then
        return true
    end
    local econ = self.GetResultEconomics and self:GetResultEconomics(resultData) or nil
    if econ and econ.craftCost and econ.craftCost > 0 then
        return true
    end
    local sources = resultData.data and resultData.data.sources
    if type(sources) == "table" then
        for _, s in ipairs(sources) do
            local st = self.NormalizeSourceType and self:NormalizeSourceType((s and (s.sourceType or s.type)) or "unknown") or ((s and (s.sourceType or s.type)) or "unknown")
            if st == "profession" then
                return true
            end
        end
    end
    return false
end

function HC:GenerateConstraintPlan(results, opts)
    opts = opts or {}
    local budget = tonumber(opts.budget) or 0
    local onlyUncollected = opts.onlyUncollected ~= false
    local sourceAllow = opts.sourceAllow
    local w = self:GetScoringConfig()
    local filtered = {}
    for _, r in ipairs(results or {}) do
        local keep = true
        if onlyUncollected and r.collected then
            keep = false
        end
        if keep and type(sourceAllow) == "table" and next(sourceAllow) ~= nil then
            local rt = self.NormalizeSourceType and self:NormalizeSourceType(r.type or "unknown") or (r.type or "unknown")
            keep = sourceAllow[rt] == true
        end
        if keep then
            local econ = self.GetResultEconomics and self:GetResultEconomics(r) or nil
            if not self:EvaluateRules(r, econ) then
                keep = false
            end
        end
        if keep then
            local econ = self.GetResultEconomics and self:GetResultEconomics(r) or nil
            local cost = (econ and econ.totalCost) or self:ParseMoneyToCopper(r.cost) or 0
            local profit = (econ and econ.profit) or 0
            local margin = (econ and econ.margin) or 0
            local missingBoost = r.collected and 0 or 1
            local riskPenalty = econ and (econ.risk or 50) or 50
            local score = (profit * w.profitability) + (margin * 200 * w.profitability) + (missingBoost * 250 * w.completion) - (cost * 0.15 * w.travel) - (riskPenalty * 18 * w.risk)
            table.insert(filtered, {
                result = r,
                cost = cost,
                profit = profit,
                margin = margin,
                score = score,
            })
        end
    end
    table.sort(filtered, function(a, b)
        if a.score == b.score then
            return (a.cost or 0) < (b.cost or 0)
        end
        return (a.score or 0) > (b.score or 0)
    end)

    local picks, alternates = {}, {}
    local spent, projectedProfit = 0, 0
    for _, e in ipairs(filtered) do
        if budget <= 0 or (spent + e.cost) <= budget then
            table.insert(picks, e)
            spent = spent + e.cost
            projectedProfit = projectedProfit + (e.profit or 0)
        else
            table.insert(alternates, e)
        end
    end

    return {
        picks = picks,
        alternates = alternates,
        spent = spent,
        projectedProfit = projectedProfit,
        remaining = math.max(0, budget - spent),
    }
end

function HC:CaptureHouseSnapshot(label)
    self:CacheCollection()
    local items = {}
    for _, info in pairs(self.collectionItemIDCache or {}) do
        if info and info.collected then
            table.insert(items, {
                itemID = info.itemID,
                name = info.name,
                count = info.count or 0,
            })
        end
    end
    table.sort(items, function(a, b)
        return tostring(a.name or "") < tostring(b.name or "")
    end)
    return {
        label = label or ("Snapshot " .. date("%Y-%m-%d %H:%M:%S")),
        timestamp = time(),
        items = items,
    }
end

function HC:BuildSnapshotDiff(snapshot, targetResults)
    local have = {}
    for _, row in ipairs((snapshot and snapshot.items) or {}) do
        if row and row.itemID then
            have[row.itemID] = row.count or 0
        end
    end
    local missing = {}
    for _, r in ipairs(targetResults or {}) do
        local itemID = self:GetResolvedItemID(r)
        if itemID and (have[itemID] or 0) <= 0 then
            local econ = self.GetResultEconomics and self:GetResultEconomics(r) or nil
            table.insert(missing, {
                itemID = itemID,
                name = r.name,
                cost = econ and econ.totalCost or self:ParseMoneyToCopper(r.cost),
                sourceType = r.type,
                result = r,
            })
        end
    end
    table.sort(missing, function(a, b)
        local ac, bc = tonumber(a.cost) or math.huge, tonumber(b.cost) or math.huge
        if ac == bc then
            return tostring(a.name or "") < tostring(b.name or "")
        end
        return ac < bc
    end)
    return missing
end

function HC:EstimateRouteLegCost(fromStop, toStop, opts)
    opts = opts or {}
    local base = Dist(fromStop and fromStop.mapID, fromStop and fromStop.x, fromStop and fromStop.y, toStop and toStop.mapID, toStop and toStop.x, toStop and toStop.y)
    local transition = ((fromStop and fromStop.mapID) ~= (toStop and toStop.mapID)) and 0.85 or 0
    local hearthBonus = opts.useHearth and transition > 0 and -0.2 or 0
    local portalBonus = opts.usePortals and transition > 0 and -0.25 or 0
    local flightPenalty = opts.useFlightPaths == false and transition > 0 and 0.4 or 0
    return base + transition + flightPenalty + hearthBonus + portalBonus
end

function HC:OptimizeVendorRoute(results, startMapID, startX, startY)
    local stops, seen = {}, {}
    for _, r in ipairs(results or {}) do
        local mapID, x, y, title = self:GetResultWaypoint(r)
        if mapID and x and y then
            local nx, ny = x, y
            if nx > 1 or ny > 1 then
                nx, ny = nx / 100, ny / 100
            end
            if nx > 0 and ny > 0 and nx <= 1 and ny <= 1 then
                local key = string.format("%d:%.5f:%.5f", mapID, nx, ny)
                if not seen[key] then
                    seen[key] = true
                    table.insert(stops, {
                        mapID = mapID,
                        x = nx,
                        y = ny,
                        title = title or r.name or "Target",
                        result = r,
                    })
                end
            end
        end
    end

    local route, remaining = {}, {}
    for _, s in ipairs(stops) do table.insert(remaining, s) end
    local curMap, curX, curY = startMapID, startX, startY
    if not curMap or not curX or not curY then
        local first = remaining[1]
        if first then
            curMap, curX, curY = first.mapID, first.x, first.y
        end
    end
    local routeOpts = {
        useHearth = true,
        usePortals = true,
        useFlightPaths = true,
    }
    while #remaining > 0 do
        local bestIdx, bestDist = 1, math.huge
        for i, s in ipairs(remaining) do
            local d = self:EstimateRouteLegCost({ mapID = curMap, x = curX, y = curY }, s, routeOpts)
            if d < bestDist then
                bestDist = d
                bestIdx = i
            end
        end
        local pick = table.remove(remaining, bestIdx)
        table.insert(route, pick)
        curMap, curX, curY = pick.mapID, pick.x, pick.y
    end
    return route
end

function HC:BuildCraftExecutor(list)
    local out = {}
    for _, entry in ipairs(list or {}) do
        local resultData = self:BuildResultFromQueueEntry(entry)
        local plan = self.ResolveCheapestPathForResult and self:ResolveCheapestPathForResult(resultData) or nil
        table.insert(out, {
            name = resultData and resultData.name or entry.name,
            itemID = resultData and (resultData.itemID or (resultData.data and resultData.data.itemID)) or entry.itemID,
            plan = plan,
        })
    end
    return out
end

function HC:BuildCraftDependencyGraph(list)
    local graph = {
        nodes = {},
        edges = {},
    }
    local index = {}
    local function addNode(id, name, kind)
        local key = tostring(id or name or "unknown")
        if not index[key] then
            index[key] = true
            graph.nodes[#graph.nodes + 1] = {
                key = key,
                itemID = id,
                name = name or ("Item #" .. tostring(id)),
                kind = kind or "item",
            }
        end
        return key
    end

    for _, entry in ipairs(list or {}) do
        local resultData = self:BuildResultFromQueueEntry(entry)
        if resultData then
            local targetID = resultData.itemID or (resultData.data and resultData.data.itemID)
            local targetKey = addNode(targetID, resultData.name, "target")
            local plan = self.ResolveCheapestPathForResult and self:ResolveCheapestPathForResult(resultData) or nil
            for _, r in ipairs((plan and plan.reagentDecisions) or {}) do
                local rKey = addNode(r.itemID, r.name, "reagent")
                graph.edges[#graph.edges + 1] = {
                    from = rKey,
                    to = targetKey,
                    qty = tonumber(r.qty) or 1,
                    decision = r.decision or "Unknown",
                }
            end
        end
    end
    return graph
end

function HC:GetPriceTimingSignal(resultData)
    local econ = self.GetResultEconomics and self:GetResultEconomics(resultData) or nil
    if not econ or not econ.trend then
        return "Unknown", 50
    end
    local chg = tonumber(econ.trend.changePct) or 0
    local risk = tonumber(econ.risk) or 50
    if risk <= 30 and chg >= 4 then
        return "Craft Now", 85
    end
    if risk <= 45 and chg >= 1 then
        return "Buy Inputs Now", 70
    end
    if chg <= -6 then
        return "Hold", 65
    end
    return "Watch", Clamp(60 - risk + math.abs(chg), 35, 80)
end

function HC:DetectMarketRegime(results)
    local n, up, down, riskSum = 0, 0, 0, 0
    for _, r in ipairs(results or {}) do
        local econ = self.GetResultEconomics and self:GetResultEconomics(r) or nil
        if econ and econ.trend then
            n = n + 1
            local chg = tonumber(econ.trend.changePct) or 0
            if chg >= 1 then up = up + 1 end
            if chg <= -1 then down = down + 1 end
            riskSum = riskSum + (tonumber(econ.risk) or 50)
        end
    end
    if n == 0 then
        return { regime = "Unknown", confidence = 40, avgRisk = 50 }
    end
    local avgRisk = riskSum / n
    local upPct = up / n
    local downPct = down / n
    if avgRisk >= 65 then
        return { regime = "Volatile", confidence = math.floor(55 + math.min(40, avgRisk - 50)), avgRisk = avgRisk, upPct = upPct, downPct = downPct }
    end
    if downPct >= 0.55 then
        return { regime = "Bearish", confidence = math.floor(50 + (downPct * 50)), avgRisk = avgRisk, upPct = upPct, downPct = downPct }
    end
    if upPct >= 0.55 then
        return { regime = "Bullish", confidence = math.floor(50 + (upPct * 50)), avgRisk = avgRisk, upPct = upPct, downPct = downPct }
    end
    return { regime = "Stable", confidence = math.floor(70 - math.min(25, avgRisk / 3)), avgRisk = avgRisk, upPct = upPct, downPct = downPct }
end

function HC:GetCompatibilityScore(resultA, resultB)
    if not resultA or not resultB then return 0 end
    local tagsA = {}
    for _, t in ipairs(resultA.sourceTags or {}) do tagsA[SafeLower(t)] = true end
    local tagsB = {}
    for _, t in ipairs(resultB.sourceTags or {}) do tagsB[SafeLower(t)] = true end
    local intersect, union = 0, 0
    for k in pairs(tagsA) do
        union = union + 1
        if tagsB[k] then intersect = intersect + 1 end
    end
    for k in pairs(tagsB) do
        if not tagsA[k] then union = union + 1 end
    end
    if union == 0 then
        return 0
    end
    return math.floor((intersect / union) * 100)
end

function HC:SuggestCompatibleAlternatives(targetResult, pool, maxResults)
    local scored = {}
    for _, r in ipairs(pool or {}) do
        if r ~= targetResult then
            local s = self:GetCompatibilityScore(targetResult, r)
            if s > 0 then
                table.insert(scored, { result = r, score = s })
            end
        end
    end
    table.sort(scored, function(a, b)
        if a.score == b.score then
            return tostring(a.result and a.result.name or "") < tostring(b.result and b.result.name or "")
        end
        return a.score > b.score
    end)
    local out = {}
    for i = 1, math.min(maxResults or 8, #scored) do
        out[#out + 1] = scored[i]
    end
    return out
end

function HC:BuildRoomBundle(roomType, results, maxItems)
    local want = SafeLower(roomType or "")
    local scored = {}
    for _, r in ipairs(results or {}) do
        local name = SafeLower(r.name)
        local category = SafeLower((r.data and r.data.itemCategory) or r.itemCategory or "")
        local score = 0
        if want ~= "" then
            if name:find(want, 1, true) then score = score + 45 end
            if category:find(want, 1, true) then score = score + 35 end
        end
        if r.collected then score = score + 10 end
        if self:IsResultCraftable(r) then score = score + 8 end
        if score > 0 then
            scored[#scored + 1] = { result = r, score = score }
        end
    end
    table.sort(scored, function(a, b) return a.score > b.score end)
    local out = {}
    for i = 1, math.min(maxItems or 20, #scored) do
        out[#out + 1] = scored[i]
    end
    return out
end

function HC:ExportBlueprint(data)
    if type(data) ~= "table" then
        return nil
    end
    local rows = { "HCBP1" }
    local label = tostring(data.label or "Blueprint")
    rows[#rows + 1] = "L=" .. label:gsub("[\r\n|]", " ")
    local items = data.items or {}
    for _, it in ipairs(items) do
        local itemID = tonumber(it.itemID)
        if itemID then
            local qty = math.max(1, math.floor((tonumber(it.qty) or 1) + 0.5))
            rows[#rows + 1] = "I=" .. tostring(itemID) .. ":" .. tostring(qty)
        end
    end
    return table.concat(rows, "|")
end

function HC:ImportBlueprint(encoded)
    if type(encoded) ~= "string" or encoded == "" then
        return nil, "Invalid blueprint."
    end
    local parts = {}
    for token in string.gmatch(encoded, "([^|]+)") do
        parts[#parts + 1] = token
    end
    if parts[1] ~= "HCBP1" then
        return nil, "Unsupported blueprint format."
    end
    local out = { label = "Blueprint", items = {} }
    for i = 2, #parts do
        local p = parts[i]
        if string.sub(p, 1, 2) == "L=" then
            out.label = string.sub(p, 3)
        elseif string.sub(p, 1, 2) == "I=" then
            local a = string.sub(p, 3)
            local idText, qtyText = string.match(a, "^(%d+):(%d+)$")
            local itemID = tonumber(idText)
            local qty = tonumber(qtyText) or 1
            if itemID then
                out.items[#out.items + 1] = { itemID = itemID, qty = qty }
            end
        end
    end
    return out
end

function HC:DiffBlueprints(baseBlueprint, targetBlueprint)
    local a, b = {}, {}
    for _, row in ipairs((baseBlueprint and baseBlueprint.items) or {}) do
        local id = tonumber(row.itemID)
        if id then
            a[id] = (a[id] or 0) + (tonumber(row.qty) or 1)
        end
    end
    for _, row in ipairs((targetBlueprint and targetBlueprint.items) or {}) do
        local id = tonumber(row.itemID)
        if id then
            b[id] = (b[id] or 0) + (tonumber(row.qty) or 1)
        end
    end
    local out = {}
    for id, qty in pairs(b) do
        local delta = qty - (a[id] or 0)
        if delta ~= 0 then
            out[#out + 1] = { itemID = id, qtyDelta = delta }
        end
    end
    for id, qty in pairs(a) do
        if b[id] == nil then
            out[#out + 1] = { itemID = id, qtyDelta = -qty }
        end
    end
    table.sort(out, function(x, y) return (x.itemID or 0) < (y.itemID or 0) end)
    return out
end

function HC:MergeBlueprints(baseBlueprint, incomingBlueprint, mode)
    local merged = { label = (incomingBlueprint and incomingBlueprint.label) or "Merged Blueprint", items = {} }
    local acc = {}
    for _, row in ipairs((baseBlueprint and baseBlueprint.items) or {}) do
        local id = tonumber(row.itemID)
        if id then
            acc[id] = tonumber(row.qty) or 1
        end
    end
    for _, row in ipairs((incomingBlueprint and incomingBlueprint.items) or {}) do
        local id = tonumber(row.itemID)
        local qty = tonumber(row.qty) or 1
        if id then
            if mode == "incoming_wins" then
                acc[id] = qty
            elseif mode == "max" then
                acc[id] = math.max(acc[id] or 0, qty)
            elseif mode == "missing_only" then
                if not acc[id] then acc[id] = qty end
            else
                acc[id] = (acc[id] or 0) + qty
            end
        end
    end
    for id, qty in pairs(acc) do
        merged.items[#merged.items + 1] = { itemID = id, qty = qty }
    end
    table.sort(merged.items, function(x, y) return (x.itemID or 0) < (y.itemID or 0) end)
    return merged
end

function HC:GetRoomTemplates()
    return {
        { id = "entryway", label = "Entryway", terms = { "banner", "rug", "lamp", "chair", "table" } },
        { id = "kitchen", label = "Kitchen", terms = { "table", "stove", "cook", "shelf", "barrel" } },
        { id = "study", label = "Study", terms = { "book", "desk", "chair", "lamp", "scroll" } },
        { id = "workshop", label = "Workshop", terms = { "forge", "anvil", "tool", "bench", "rack" } },
        { id = "garden", label = "Garden", terms = { "plant", "tree", "bush", "stone", "fence" } },
    }
end

function HC:BuildRoomTemplateBundle(templateID, results, budget)
    local terms = nil
    for _, t in ipairs(self:GetRoomTemplates()) do
        if t.id == templateID then
            terms = t.terms
            break
        end
    end
    if not terms then
        return {}
    end
    local scored = {}
    for _, r in ipairs(results or {}) do
        local name = SafeLower(r.name)
        local s = 0
        for _, term in ipairs(terms) do
            if name:find(term, 1, true) then
                s = s + 20
            end
        end
        if s > 0 then
            local econ = self.GetResultEconomics and self:GetResultEconomics(r) or nil
            local cost = econ and econ.totalCost or self:ParseMoneyToCopper(r.cost) or 0
            scored[#scored + 1] = { result = r, score = s, cost = cost }
        end
    end
    table.sort(scored, function(a, b)
        if a.score == b.score then return a.cost < b.cost end
        return a.score > b.score
    end)
    local out, spent = {}, 0
    for _, e in ipairs(scored) do
        if not budget or budget <= 0 or (spent + e.cost) <= budget then
            out[#out + 1] = e
            spent = spent + e.cost
        end
    end
    return out
end

function HC:RecordAdvancedDecision(actionType, payload)
    local adv = self:GetAdvancedState()
    if not adv then return end
    local t = adv.telemetry
    t[#t + 1] = {
        ts = time(),
        profile = self:GetAdvancedProfileName(),
        actionType = actionType,
        payload = payload or {},
    }
    if #t > 600 then
        table.remove(t, 1)
    end
end

function HC:GetAdvancedTelemetryStats()
    local adv = self:GetAdvancedState()
    local out = {
        total = 0,
        byType = {},
        lastAt = nil,
    }
    for _, e in ipairs((adv and adv.telemetry) or {}) do
        out.total = out.total + 1
        local k = tostring(e.actionType or "unknown")
        out.byType[k] = (out.byType[k] or 0) + 1
        out.lastAt = e.ts or out.lastAt
    end
    return out
end

function HC:RunAutomationAction(action, results)
    local act = tostring(action or "")
    local pool = results or self.lastComputedResults or {}
    if act == "next_best" then
        local pick = self:GetNextBestAction(pool)
        if not pick then
            return { ok = false, message = "No next action target." }
        end
        if pick.mapID and pick.x and pick.y and self.SetSmartWaypoint then
            self:SetSmartWaypoint(pick.x, pick.y, pick.mapID, pick.title or pick.name)
        end
        self:RecordAdvancedDecision("next_best", { itemID = pick.itemID, name = pick.name })
        return { ok = true, message = "Mapped next best target: " .. tostring(pick.name or "Unknown") }
    elseif act == "track_missing_mats" then
        local missing = self.GetCraftingQueueMissingMaterials and self:GetCraftingQueueMissingMaterials() or {}
        local added = 0
        for _, m in ipairs(missing) do
            if m.itemID then
                local ok = self:TrackReagent(m.itemID, m.name, m.quantity or 0)
                if ok then added = added + 1 end
            end
        end
        self:RecordAdvancedDecision("track_missing_mats", { added = added })
        return { ok = true, message = "Tracked " .. tostring(added) .. " missing reagent(s)." }
    elseif act == "export_shopping" then
        local text = self:BuildResultsCSV(pool)
        self:RecordAdvancedDecision("export_shopping", { rows = #(pool or {}) })
        return { ok = true, message = "Prepared optimized shopping export.", text = text }
    elseif act == "queue_best_crafts" then
        local plan = self:GenerateConstraintPlan(pool, { budget = 0, onlyUncollected = true })
        local added = 0
        for i = 1, math.min(15, #(plan.picks or {})) do
            local r = plan.picks[i] and plan.picks[i].result
            if r then
                local ok = self:AddResultToShoppingList(r)
                if ok then added = added + 1 end
            end
        end
        self:RecordAdvancedDecision("queue_best_crafts", { added = added })
        return { ok = true, message = "Queued " .. tostring(added) .. " best craft targets into shopping list." }
    end
    return { ok = false, message = "Unknown automation action." }
end

function HC:GetNextBestAction(results)
    local w = self:GetScoringConfig()
    local best = nil
    for _, r in ipairs(results or {}) do
        if not r.collected then
            local econ = self.GetResultEconomics and self:GetResultEconomics(r) or nil
            if self:EvaluateRules(r, econ) then
            local signal, confidence = self:GetPriceTimingSignal(r)
            local mapID, x, y, title = self:GetResultWaypoint(r)
            local value = ((econ and econ.profit or 0) * w.profitability) + ((confidence or 0) * 80 * w.completion)
            if self.ResultHasWaypoint and self:ResultHasWaypoint(r) then
                value = value + (1200 * w.travel)
            end
            if self:IsResultCraftable(r) then
                value = value + (300 * w.completion)
            end
            value = value - ((econ and econ.risk or 50) * 10 * w.risk)
            local candidate = {
                value = value,
                action = signal,
                confidence = confidence,
                name = r.name,
                itemID = self:GetResolvedItemID(r),
                mapID = mapID,
                x = x,
                y = y,
                title = title,
                result = r,
            }
            if not best or candidate.value > best.value then
                best = candidate
            end
            end
        end
    end
    return best
end

function HC:GetAdvancedAnalytics(results)
    local stats = self:GetStatistics()
    local shopping = self:GetShoppingList()
    local tracked = self:GetTrackedReagents()
    local trackedCount = 0
    for _ in pairs(tracked) do trackedCount = trackedCount + 1 end

    local totalCost, totalProfit, profitableCount, craftableCount = 0, 0, 0, 0
    local trendUp, trendDown = 0, 0
    for _, r in ipairs(results or {}) do
        local econ = self.GetResultEconomics and self:GetResultEconomics(r) or nil
        if self:EvaluateRules(r, econ) then
            if econ and econ.totalCost then totalCost = totalCost + econ.totalCost end
            if econ and econ.profit then
                totalProfit = totalProfit + econ.profit
                if econ.profit > 0 then profitableCount = profitableCount + 1 end
            end
            if self:IsResultCraftable(r) then craftableCount = craftableCount + 1 end
            if econ and econ.trend and econ.trend.changePct then
                if econ.trend.changePct >= 1 then trendUp = trendUp + 1 end
                if econ.trend.changePct <= -1 then trendDown = trendDown + 1 end
            end
        end
    end

    local roi = totalCost > 0 and ((totalProfit / totalCost) * 100) or 0
    local regime = self:DetectMarketRegime(results)
    local telemetry = self:GetAdvancedTelemetryStats()
    return {
        collectedTrackable = stats.collectedTrackable or 0,
        trackableTotal = stats.trackableTotal or 0,
        unknownSourceItems = stats.unknownSourceItems or 0,
        shoppingItems = #shopping,
        trackedReagents = trackedCount,
        totalResults = #(results or {}),
        craftableCount = craftableCount,
        profitableCount = profitableCount,
        totalCost = totalCost,
        totalProfit = totalProfit,
        roi = roi,
        trendUp = trendUp,
        trendDown = trendDown,
        marketRegime = regime.regime,
        marketConfidence = regime.confidence,
        avgRisk = regime.avgRisk,
        telemetryTotal = telemetry.total,
        telemetryByType = telemetry.byType,
        activeProfile = self:GetAdvancedProfileName(),
    }
end
