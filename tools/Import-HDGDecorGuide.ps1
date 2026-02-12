param(
    [string]$InputAllDecor = "HousingDecorGuide/data/HDG_AllDecorDB.lua",
    [string]$InputVendorDB = "HousingDecorGuide/data/HDG_VendorDB.lua",
    [string]$OutputSources = "Data/ImportedSources.lua",
    [string]$OutputAllItems = "Data/ImportedAllItems.lua"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not (Test-Path $InputAllDecor)) {
    throw "HDG AllDecor DB not found: $InputAllDecor"
}

function Escape-LuaString {
    param([string]$Value)
    if ($null -eq $Value) { return $null }
    $v = $Value.Replace("\", "\\").Replace('"', '\"')
    return '"' + $v + '"'
}

function Split-LuaTopLevel {
    param([string]$Text)

    $parts = New-Object System.Collections.Generic.List[string]
    if ([string]::IsNullOrWhiteSpace($Text)) {
        return $parts
    }

    $sb = New-Object System.Text.StringBuilder
    $inString = $false
    $escape = $false
    $braceDepth = 0

    for ($i = 0; $i -lt $Text.Length; $i++) {
        $ch = $Text[$i]

        if ($inString) {
            [void]$sb.Append($ch)
            if ($escape) {
                $escape = $false
            } elseif ($ch -eq '\\') {
                $escape = $true
            } elseif ($ch -eq '"') {
                $inString = $false
            }
            continue
        }

        switch ($ch) {
            '"' {
                $inString = $true
                [void]$sb.Append($ch)
            }
            '{' {
                $braceDepth++
                [void]$sb.Append($ch)
            }
            '}' {
                if ($braceDepth -gt 0) { $braceDepth-- }
                [void]$sb.Append($ch)
            }
            ',' {
                if ($braceDepth -eq 0) {
                    $token = $sb.ToString().Trim()
                    if ($token -ne "") { $parts.Add($token) | Out-Null }
                    [void]$sb.Clear()
                } else {
                    [void]$sb.Append($ch)
                }
            }
            default {
                [void]$sb.Append($ch)
            }
        }
    }

    $last = $sb.ToString().Trim()
    if ($last -ne "") { $parts.Add($last) | Out-Null }

    return $parts
}

function Unquote-LuaString {
    param([string]$Value)
    if ($null -eq $Value) { return $null }
    $v = $Value.Trim()
    if ($v.Length -ge 2 -and $v.StartsWith('"') -and $v.EndsWith('"')) {
        $v = $v.Substring(1, $v.Length - 2)
        $v = $v.Replace('\\"', '"').Replace('\"', '"').Replace('\\', '\')
    }
    return $v
}

function Normalize-SourceType {
    param([int]$TypeNum)
    switch ($TypeNum) {
        1 { return "achievement" }
        2 { return "quest" }
        3 { return "quest" }
        4 { return "drop" }
        5 { return "vendor" }
        6 { return "profession" }
        7 { return "profession" }
        8 { return "drop" }
        9 { return "drop" }
        10 { return "promo" }
        11 { return "profession" }
        default { return "unknown" }
    }
}

function Normalize-Expansion {
    param([string]$Exp)
    if (-not $Exp) { return $null }
    $map = @{
        "Classic" = "classic"
        "The Burning Crusade" = "tbc"
        "Wrath of the Lich King" = "wotlk"
        "Cataclysm" = "cata"
        "Mists of Pandaria" = "mop"
        "Warlords of Draenor" = "wod"
        "Legion" = "legion"
        "Battle for Azeroth" = "bfa"
        "Shadowlands" = "sl"
        "Dragonflight" = "df"
        "The War Within" = "tww"
        "Midnight" = "midnight"
    }
    if ($map.ContainsKey($Exp)) { return $map[$Exp] }
    $fallback = $Exp.ToLowerInvariant().Trim()
    $fallback = $fallback -replace "\s+", " "
    return $fallback
}

function Normalize-Faction {
    param([string]$Code)
    switch ($Code) {
        "A" { return "alliance" }
        "H" { return "horde" }
        default { return "neutral" }
    }
}

$vendorByNameZone = @{}
$vendorByName = @{}

if (Test-Path $InputVendorDB) {
    $vendorPattern = '^\s*\[(\d+)\]\s*=\s*\{"((?:\\.|[^"\\])*)",\s*"((?:\\.|[^"\\])*)",\s*(\d+),\s*([0-9.\-]+),\s*([0-9.\-]+),\s*"([AHN])"'
    foreach ($line in (Get-Content -Path $InputVendorDB)) {
        $m = [regex]::Match($line, $vendorPattern)
        if (-not $m.Success) { continue }

        $name = Unquote-LuaString ('"' + $m.Groups[2].Value + '"')
        $zone = Unquote-LuaString ('"' + $m.Groups[3].Value + '"')
        $mapID = [int]$m.Groups[4].Value
        $x = [double]::Parse($m.Groups[5].Value, [Globalization.CultureInfo]::InvariantCulture)
        $y = [double]::Parse($m.Groups[6].Value, [Globalization.CultureInfo]::InvariantCulture)
        $faction = Normalize-Faction $m.Groups[7].Value

        $entry = [pscustomobject]@{
            name = $name
            zone = $zone
            mapID = $(if ($mapID -gt 0) { $mapID } else { $null })
            x = $(if ($x -gt 0) { $x } else { $null })
            y = $(if ($y -gt 0) { $y } else { $null })
            faction = $faction
        }

        $key = ("{0}|{1}" -f $name.ToLowerInvariant(), $zone.ToLowerInvariant())
        $vendorByNameZone[$key] = $entry

        $nameKey = $name.ToLowerInvariant()
        if (-not $vendorByName.ContainsKey($nameKey)) {
            $vendorByName[$nameKey] = New-Object System.Collections.Generic.List[object]
        }
        $vendorByName[$nameKey].Add($entry) | Out-Null
    }
}

$imported = New-Object System.Collections.Generic.List[object]
$allItemIDs = New-Object "System.Collections.Generic.HashSet[int]"
$seenRows = New-Object "System.Collections.Generic.HashSet[string]"

$entryPattern = '^\s*\[(\d+)\]\s*=\s*\{(.*)\},\s*$'
foreach ($line in (Get-Content -Path $InputAllDecor)) {
    $m = [regex]::Match($line, $entryPattern)
    if (-not $m.Success) { continue }

    $itemID = [int]$m.Groups[1].Value
    $inner = $m.Groups[2].Value
    $tokens = Split-LuaTopLevel $inner
    if ($tokens.Count -lt 5) { continue }

    $typeNum = 0
    [void][int]::TryParse($tokens[1], [ref]$typeNum)
    $sourceType = Normalize-SourceType $typeNum

    $sourceName = Unquote-LuaString $tokens[2]
    $sourceDetail = Unquote-LuaString $tokens[3]

    $expansion = $null
    for ($i = 5; $i -lt $tokens.Count; $i++) {
        $tok = $tokens[$i]
        if ($tok -match '^\s*exp\s*=\s*(.+)$') {
            $expansion = Normalize-Expansion (Unquote-LuaString $matches[1])
            break
        }
    }

    $vendor = $null
    $source = $null
    $zone = $null
    $mapID = $null
    $coords = $null
    $faction = $null

    if ($sourceType -eq "vendor") {
        $vendor = $sourceName
        $zone = $sourceDetail

        $vendorHit = $null
        if ($vendor -and $zone) {
            $k = ("{0}|{1}" -f $vendor.ToLowerInvariant(), $zone.ToLowerInvariant())
            if ($vendorByNameZone.ContainsKey($k)) {
                $vendorHit = $vendorByNameZone[$k]
            }
        }

        if (-not $vendorHit -and $vendor) {
            $nameKey = $vendor.ToLowerInvariant()
            if ($vendorByName.ContainsKey($nameKey) -and $vendorByName[$nameKey].Count -eq 1) {
                $vendorHit = $vendorByName[$nameKey][0]
            }
        }

        if ($vendorHit) {
            if (-not $zone -or $zone -eq "") { $zone = $vendorHit.zone }
            $mapID = $vendorHit.mapID
            if ($vendorHit.x -and $vendorHit.y) {
                $coords = @($vendorHit.x, $vendorHit.y)
            }
            $faction = $vendorHit.faction
        }

        if (-not $source -and $vendor) { $source = $vendor }
    } else {
        $source = $sourceName
        $zone = $sourceDetail
    }

    $sourceKey = if ($source) { $source } else { "" }
    $vendorKey = if ($vendor) { $vendor } else { "" }
    $zoneKey = if ($zone) { $zone } else { "" }
    $expKey = if ($expansion) { $expansion } else { "" }
    $rowKey = ("{0}|{1}|{2}|{3}|{4}|{5}" -f $itemID, $sourceType, $sourceKey, $vendorKey, $zoneKey, $expKey).ToLowerInvariant()
    if ($seenRows.Contains($rowKey)) { continue }
    [void]$seenRows.Add($rowKey)

    [void]$allItemIDs.Add($itemID)

    $imported.Add([pscustomobject]@{
        itemID = $itemID
        name = $null
        sourceType = $sourceType
        source = $source
        vendor = $vendor
        zone = $zone
        coords = $coords
        mapID = $mapID
        faction = $faction
        expansion = $expansion
    }) | Out-Null
}

$sorted = $imported | Sort-Object itemID, sourceType, source, vendor, zone

$sourceLines = New-Object System.Collections.Generic.List[string]
$sourceLines.Add("---------------------------------------------------") | Out-Null
$sourceLines.Add("-- Housing Completed - ImportedSources.lua") | Out-Null
$sourceLines.Add("-- Generated by tools/Import-HDGDecorGuide.ps1") | Out-Null
$sourceLines.Add("---------------------------------------------------") | Out-Null
$sourceLines.Add("local addonName, HC = ...") | Out-Null
$sourceLines.Add("") | Out-Null
$sourceLines.Add("HC.ImportedDecorItems = {") | Out-Null

foreach ($r in $sorted) {
    $parts = New-Object System.Collections.Generic.List[string]
    if ($r.itemID) { $parts.Add("itemID = $($r.itemID)") | Out-Null }
    if ($r.sourceType) { $parts.Add("sourceType = $(Escape-LuaString $r.sourceType)") | Out-Null }
    if ($r.source) { $parts.Add("source = $(Escape-LuaString $r.source)") | Out-Null }
    if ($r.vendor) { $parts.Add("vendor = $(Escape-LuaString $r.vendor)") | Out-Null }
    if ($r.zone) { $parts.Add("zone = $(Escape-LuaString $r.zone)") | Out-Null }
    if ($r.coords -and $r.coords.Count -eq 2) {
        $x = [string]::Format([Globalization.CultureInfo]::InvariantCulture, "{0:0.###}", [double]$r.coords[0])
        $y = [string]::Format([Globalization.CultureInfo]::InvariantCulture, "{0:0.###}", [double]$r.coords[1])
        $parts.Add("coords = {$x, $y}") | Out-Null
    }
    if ($r.mapID) { $parts.Add("mapID = $($r.mapID)") | Out-Null }
    if ($r.faction) { $parts.Add("faction = $(Escape-LuaString $r.faction)") | Out-Null }
    if ($r.expansion) { $parts.Add("expansion = $(Escape-LuaString $r.expansion)") | Out-Null }

    $sourceLines.Add("    { " + ($parts -join ", ") + " },") | Out-Null
}

$sourceLines.Add("}") | Out-Null

$ids = @($allItemIDs)
[array]::Sort($ids)

$idLines = New-Object System.Collections.Generic.List[string]
$idLines.Add("---------------------------------------------------") | Out-Null
$idLines.Add("-- Housing Completed - ImportedAllItems.lua") | Out-Null
$idLines.Add("-- Generated by tools/Import-HDGDecorGuide.ps1") | Out-Null
$idLines.Add("---------------------------------------------------") | Out-Null
$idLines.Add("local addonName, HC = ...") | Out-Null
$idLines.Add("") | Out-Null
$idLines.Add("HC.ImportedAllItems = HC.ImportedAllItems or {}") | Out-Null
$idLines.Add("HC.ImportedAllItems.IDs = {") | Out-Null
foreach ($id in $ids) {
    $idLines.Add("    $id,") | Out-Null
}
$idLines.Add("}") | Out-Null

$sourceLines | Set-Content -Path $OutputSources -Encoding UTF8
$idLines | Set-Content -Path $OutputAllItems -Encoding UTF8

Write-Output ("Imported {0} source rows and {1} unique itemIDs from HousingDecorGuide." -f $sorted.Count, $ids.Count)
Write-Output ("Wrote: {0}" -f $OutputSources)
Write-Output ("Wrote: {0}" -f $OutputAllItems)



