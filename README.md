# Housing Completed

![Version](https://img.shields.io/badge/version-1.4.0-green)
![WoW Version](https://img.shields.io/badge/WoW-12.0.1%20Midnight-blue)
![License](https://img.shields.io/badge/license-MIT-orange)

A comprehensive World of Warcraft addon for tracking and collecting all housing decor items. Find vendors, complete achievements, finish quests, and craft your way to a fully decorated home!

## Features

### 📦 Complete Database
- **150+ Vendors** with exact coordinates across all expansions
- **80+ Achievement Items** - Order Hall, PvP, exploration rewards
- **150+ Quest Rewards** - From Classic through The War Within
- **70+ Reputation Items** - 25+ factions with standing requirements
- **25+ Profession Items** - All crafting professions covered
- **Drop Sources** - Dungeons, raids, and world content

### 🎯 Modern Interface
- Clean, dark theme with intuitive navigation
- **Platform Tabs**: Acquire, Craft, Economy, Planner, Collection
- **Source Views**: All Items, Item Browser, Vendors, Professions, Reputation, Achievements, Quests, Drops, Auction House, Promotions, Unknown
- **Mode Toggle**: Collector, Hybrid, Goblin
- **Real-time Search**: Find items by name, vendor, or zone instantly
- **Collection Tracking**: Visual indicators for collected/uncollected items
- **Progress Stats**: Track your overall collection completion
- **Split Progress Metrics**: `Collected/Trackable`, `Trackable/Known`, and `Unknown Sources`
- **REP Requirement Badge**: Shows when an item has a reputation requirement
- **REP Tooltip**: Hover badge to see faction/standing or requirement notes
- **Preview Fallbacks**: Housing preview, Dressing Room, then modified-click fallback
- **Sortable Economics Columns**: `AH Price`, `Craft Cost`, `Profit`, and `Margin`

### Optional Auctionator Integration
- Automatic Auctionator detection with graceful fallback if unavailable
- Live AH pricing via Auctionator API v1
- Session price cache with DB-update invalidation
- Shared cost/profit engine across results, shopping list, and goblin profitability view
- In-addon tooltip economics (AH/Vendor/Total/Profit/Margin)
- Export missing crafting materials to an Auctionator shopping list

### 🗺️ Waypoint Integration
- **One-Click Set Waypoint Button**: Select an item, then click `Set Waypoint`
- **TomTom Support**: One-click waypoints to any vendor
- **Blizzard Map Pins**: Native map pin support
- **Configurable**: Choose TomTom, Blizzard, or both

### ⚙️ Customization
- Adjustable UI scale (50% - 150%)
- Toggleable minimap button
- Filter by collected/uncollected status
- Persistent window position

## Installation

### Manual Installation
1. Download the latest release
2. Extract `HousingCompleted` folder to `World of Warcraft/_retail_/Interface/AddOns/`
3. Restart WoW or `/reload`

### CurseForge / WowUp
Search for "Housing Completed" in your addon manager.

## Usage

### Slash Commands
| Command | Description |
|---------|-------------|
| `/hc` | Toggle the main window |
| `/housing` | Toggle the main window |
| `/hc settings` | Open settings panel |
| `/hc minimap` | Toggle minimap button |

### Navigation
1. **Search Box**: Type to filter results in real-time
2. **Platform Tabs**: Switch between Acquire, Craft, Economy, Planner, and Collection
3. **Source View Rail**: Filter by source type with per-view counts
4. **Mode Toggle**: Choose Collector, Hybrid, or Goblin behavior
5. **Item Types**: In `Item Browser`, filter decor item categories
6. **Filter Checkboxes**: Show/hide collected or uncollected items
7. **Select a Row**: Click the item you want to track
8. **Set Waypoint Button**: Click `Set Waypoint` in the footer to route to that item's best known source
9. **Row Map Icon**: Optional quick action per row using the map icon button
10. **REP Badge Hover**: Hover `REP` on a row for exact reputation requirement details
11. **Economics Sort**: Click `AH Price`, `Craft Cost`, `Profit`, or `Margin` column headers
12. **Economy + Planner**: Use these tabs for profitability and planning workflows

### Mode Differences
- **Collector Mode**
  - Hides `Economy` and `Planner` platform tabs.
  - Keeps focus on acquisition, sources, and completion tracking.
- **Hybrid Mode** (default)
  - Shows all platform tabs.
  - Balanced workflow for collection plus economy insights.
- **Goblin Mode**
  - Hides `Collection` platform tab.
  - Prioritizes economy filters, profit views, and planning tools.

### Waypoints
- Preferred flow: click an item row, then click `Set Waypoint` at the bottom of the results panel
- Quick flow: click the map icon on an item row
- Works with TomTom (if installed) or Blizzard's native map pins
- Configure your preferred waypoint system in Settings

### Auctionator Workflow (Optional)
- Install/enable Auctionator.
- Browse items normally in Housing Completed.
- Use pricing columns and preview economics fields to evaluate outcomes.
- Open `Shopping List` and click `Send Missing Mats` to export missing materials.
- If the Auction House is open, Auctionator search can be triggered automatically.

## Data Sources

Housing Completed includes data from:
- [Blizzard Forums Master List](https://us.forums.blizzard.com/en/wow/t/decor-sources-master-list/2219573)
- [Wowhead Housing Database](https://www.wowhead.com/guide/housing)
- Community contributions

### Expansion Coverage
| Expansion | Vendors | Items |
|-----------|---------|-------|
| Classic | 26 | ✓ |
| The Burning Crusade | 1 | ✓ |
| Wrath of the Lich King | 3 | ✓ |
| Cataclysm | 4 | ✓ |
| Mists of Pandaria | 6 | ✓ |
| Warlords of Draenor | 10 | ✓ |
| Legion | 20+ | ✓ |
| Battle for Azeroth | 10 | ✓ |
| Shadowlands | 2 | ✓ |
| Dragonflight | 12 | ✓ |
| The War Within | 15 | ✓ |
| Midnight | 3 | ✓ |

## Configuration

### Settings Panel
Access via `/hc settings` or the gear icon:

- **Waypoint System**
  - TomTom Only: Uses TomTom for all waypoints
  - Blizzard Only: Uses native map pins
  - Both: Sets waypoints in both systems

- **UI Scale**: Adjust the addon window size

- **Minimap Button**: Show/hide the minimap icon

## API Reference

Housing Completed exposes some functions for other addon developers:

```lua
-- Check if an item is collected
local collected, count = HousingCompleted:IsDecorCollected("Item Name")

-- Search the database
local results = HousingCompleted:SearchAll("search query", filters)

-- Set a waypoint programmatically
HousingCompleted:SetWaypoint(x, y, mapID, "Title")

-- Get vendor by name
local vendor = HousingCompleted:GetVendorByName("Vendor Name")
```

## Contributing

Contributions are welcome! Here's how you can help:

### Reporting Issues
1. Check existing issues first
2. Include your WoW version and addon version
3. Provide steps to reproduce the issue
4. Include any Lua error messages

### Adding Data
1. Fork the repository
2. Add items to the appropriate data file in `/Data/`
3. Follow the existing format
4. Submit a pull request

### Bulk Import (wowdb list export)
Use the importer to generate addon-ready files from a CSV export:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\Import-WowDbDecor.ps1 -InputCsv .\decor-export.csv
```

This writes:
- `Data/ImportedSources.lua`
- `Data/ImportedAllItems.lua`

Imported rows are automatically merged at runtime with curated data.
Items from your collection and cache can also appear as fallback searchable rows even before source curation is complete.

### Data File Formats

**Vendors.lua**
```lua
{ id = 12345, name = "Vendor Name", zone = "Zone", subzone = "Subzone", x = 50.0, y = 50.0, mapID = 123, faction = "neutral", expansion = "tww" }
```

**Achievements.lua**
```lua
{ name = "Item Name", achievement = "Achievement Name", vendor = "Vendor Name", zone = "Zone", cost = "100 Currency" }
```

## Troubleshooting

### Addon shows "Incompatible"
- Ensure you have the correct version for your WoW patch
- Check that the folder is named exactly `HousingCompleted`

### No results showing
- Try clearing the search box
- Check your filter settings (collected/uncollected)
- Ensure you're on the correct category tab

### Waypoints not working
- Install TomTom for TomTom waypoints
- Check Settings to ensure your preferred system is selected
- Some items may not have coordinate data yet

### Pricing columns show "-"
- Ensure Auctionator is installed and enabled.
- Ensure Auctionator has price scan data available.
- Some materials/items may have no market data and will remain unknown.

### Collection not tracking
- The Housing Catalog API requires you to open your housing catalog once
- Collection data updates on `/reload` or zone change

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Credits

- **Author**: Korivash
- **Data Sources**: Blizzard Forums community, Wowhead
- **Libraries**: LibStub, LibDataBroker, LibDBIcon, CallbackHandler

## Support

- **Discord**: [Korivash's Discord](https://discord.gg/JbQQTbH4hR)
- **GitHub Issues**: [Report a Bug](https://github.com/Korivash/HousingCompleted/issues)
- **CurseForge**: [Housing Completed](https://www.curseforge.com/wow/addons/housing-completed)

---

Made with ❤️ for the WoW Housing community
