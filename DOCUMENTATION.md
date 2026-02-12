# Housing Completed Documentation

## Table of Contents
1. [Getting Started](#getting-started)
2. [User Interface Guide](#user-interface-guide)
3. [Configuration Options](#configuration-options)
4. [Data Structure](#data-structure)
5. [API Documentation](#api-documentation)
6. [Contributing Guide](#contributing-guide)

---

## Getting Started

### System Requirements
- World of Warcraft: Retail (12.0.1 or higher)
- Optional: TomTom addon for enhanced waypoint support

### Installation Methods

#### Method 1: CurseForge App
1. Open CurseForge app
2. Navigate to World of Warcraft > Get More Addons
3. Search "Housing Completed"
4. Click Install

#### Method 2: Manual Installation
1. Download the latest release from GitHub
2. Extract the ZIP file
3. Copy the `HousingCompleted` folder to:
   ```
   World of Warcraft/_retail_/Interface/AddOns/
   ```
4. Restart World of Warcraft or type `/reload`

### First Launch
1. Log into any character
2. Type `/hc` to open the addon
3. The addon will automatically scan your housing collection
4. Browse items or use the search box to find specific decor

---

## User Interface Guide

### Main Window Layout

```
┌─────────────────────────────────────────────────────────────┐
│  Housing Completed v1.0.0                    [⚙️] [X]      │
│  Collection: 45 / 400 (11%)                                 │
├──────────────┬──────────────────────────────────────────────┤
│              │                                              │
│  [Search...] │  ┌─────────────────────────────────────────┐ │
│              │  │ Item Name              Source    [📍]   │ │
│  CATEGORIES  │  │ Achievement Name       Zone             │ │
│  ○ All Items │  │ Cost • Vendor                          │ │
│  ○ Vendors   │  ├─────────────────────────────────────────┤ │
│  ○ Achieve.. │  │ Item Name              Source    [📍]   │ │
│  ○ Quests    │  │ ...                                     │ │
│  ○ Reputat.. │  └─────────────────────────────────────────┘ │
│  ○ Profess.. │                                              │
│              │                                              │
│  ──────────  │                                              │
│  FILTERS     │                                              │
│  ☑ Collected │                                              │
│  ☑ Uncollect │       [< Prev]  Page 1 of 50  [Next >]      │
│              │       150 results                            │
│  PROGRESS    │                                              │
│  45 / 400    │                                              │
└──────────────┴──────────────────────────────────────────────┘
```

### Sidebar Components

#### Search Box
- Type any text to filter results instantly
- Searches item names, vendor names, and zone names
- Press Enter or wait 0.3 seconds for auto-search
- Clear the box to show all items

#### Category Tabs
| Tab | Description |
|-----|-------------|
| All Items | Shows all sources combined |
| Vendors | Items purchased from NPCs |
| Achievements | Items earned from achievements |
| Quests | Items rewarded from quests |
| Reputation | Items requiring faction standing |
| Professions | Items crafted by professions |

#### Filter Checkboxes
- **Show Collected**: Toggle visibility of items you own
- **Show Uncollected**: Toggle visibility of items you need

#### Progress Display
Shows your current collection count vs total available items.

### Result Row Components

Each item row displays:
1. **Type Icon**: Visual indicator of source type
2. **Collected Checkmark**: Green checkmark if you own the item
3. **Item Name**: Name of the decor item (green if collected)
4. **Source Info**: Achievement name, quest name, or zone
5. **Details**: Cost, vendor name, and location
6. **Type Badge**: Color-coded source type label
7. **Waypoint Button**: Click to set a navigation waypoint

### Color Coding

| Color | Meaning |
|-------|---------|
| Green Text | Item is collected |
| White Text | Item not collected |
| Yellow Badge | Achievement source |
| Green Badge | Vendor source |
| Purple Badge | Reputation source |
| Orange Badge | Profession source |
| Blue Badge | Drop source |

---

## Configuration Options

### Accessing Settings
- Click the gear icon (⚙️) in the header
- Or type `/hc settings`

### Waypoint System
Choose how waypoints are created when you click the map pin:

| Option | Behavior |
|--------|----------|
| TomTom Only | Creates TomTom arrow waypoint |
| Blizzard Only | Creates native map pin |
| Both | Creates waypoints in both systems |

**Note**: TomTom option requires TomTom addon to be installed.

### UI Scale
Adjust the window size from 50% to 150% of default.

### Minimap Button
Toggle the minimap button on/off. You can also use `/hc minimap`.

---

## Data Structure

### File Organization
```
HousingCompleted/
├── HousingCompleted.toc    # Addon metadata
├── Core.lua                # Main addon logic
├── UI.lua                  # User interface
├── Data/
│   ├── Categories.lua      # Source types & expansions
│   ├── Vendors.lua         # Vendor database
│   ├── Achievements.lua    # Achievement items
│   ├── Quests.lua          # Quest reward items
│   ├── Reputation.lua      # Reputation items
│   ├── Professions.lua     # Crafted items
│   └── Sources.lua         # Drop sources
└── Libs/
    ├── LibStub.lua
    ├── CallbackHandler-1.0.lua
    ├── LibDataBroker-1.1.lua
    └── LibDBIcon-1.0.lua
```

### Data Formats

#### Vendor Entry
```lua
{
    id = 12345,           -- NPC ID (optional)
    name = "Vendor Name", -- Display name
    zone = "Zone Name",   -- Parent zone
    subzone = "Subzone",  -- Specific location (optional)
    x = 50.0,             -- X coordinate (0-100)
    y = 50.0,             -- Y coordinate (0-100)
    mapID = 123,          -- Map ID for waypoints
    faction = "neutral",  -- "alliance", "horde", or "neutral"
    expansion = "tww",    -- Expansion code
    notes = "Extra info"  -- Additional notes (optional)
}
```

#### Achievement Item Entry
```lua
{
    name = "Decor Item Name",
    achievement = "Achievement Name",
    vendor = "Vendor Name",     -- Who sells it after achievement
    zone = "Zone Name",
    cost = "500 Currency Name",
    expansion = "tww"
}
```

#### Quest Item Entry
```lua
{
    name = "Decor Item Name",
    quest = "Quest Name",
    vendor = "Vendor Name",     -- Alternative vendor (optional)
    zone = "Zone Name",
    cost = "100 Gold",          -- If purchasable (optional)
    expansion = "tww"
}
```

#### Reputation Item Entry
```lua
{
    name = "Decor Item Name",
    faction = "Faction Name",
    standing = "Revered",       -- Required reputation level
    vendor = "Vendor Name",
    zone = "Zone Name",
    cost = "500 Currency"
}
```

#### Profession Item Entry
```lua
{
    name = "Decor Item Name",
    profession = "Blacksmithing",
    expansion = "tww",
    skill = 80,                 -- Skill level required
    notes = "Special notes"     -- Optional
}
```

### Expansion Codes
| Code | Expansion |
|------|-----------|
| classic | Classic (Vanilla) |
| tbc | The Burning Crusade |
| wotlk | Wrath of the Lich King |
| cata | Cataclysm |
| mop | Mists of Pandaria |
| wod | Warlords of Draenor |
| legion | Legion |
| bfa | Battle for Azeroth |
| sl | Shadowlands |
| df | Dragonflight |
| tww | The War Within |
| midnight | Midnight |

---

## API Documentation

Housing Completed exposes several functions for addon developers:

### HC:IsDecorCollected(name)
Check if a decor item is in the player's collection.

**Parameters:**
- `name` (string): The name of the decor item

**Returns:**
- `collected` (boolean): Whether the item is collected
- `count` (number): How many of this item the player owns

**Example:**
```lua
local collected, count = HousingCompleted:IsDecorCollected("Stormwind Lamppost")
if collected then
    print("You own " .. count .. " of these!")
end
```

### HC:SearchAll(query, filters)
Search the entire database with optional filters.

**Parameters:**
- `query` (string): Search text (empty string for all)
- `filters` (table): Optional filter table

**Filter Table:**
```lua
{
    showCollected = true,      -- Include collected items
    showUncollected = true,    -- Include uncollected items
    sourceTypes = {            -- Limit to specific source types
        vendor = true,
        achievement = true,
    },
    faction = "alliance",      -- Player faction for filtering
}
```

**Returns:**
- `results` (table): Array of matching items

### HC:SetWaypoint(x, y, mapID, title)
Create a waypoint to a location.

**Parameters:**
- `x` (number): X coordinate (0-100)
- `y` (number): Y coordinate (0-100)
- `mapID` (number): Map ID
- `title` (string): Waypoint label

### HC:GetVendorByName(name)
Find a vendor by their name.

**Parameters:**
- `name` (string): Vendor's name

**Returns:**
- `vendor` (table): Vendor data or nil if not found

### HC:GetStatistics()
Get collection statistics.

**Returns:**
```lua
{
    totalItems = 400,
    collected = 45,
    bySource = {
        vendor = { total = 100, collected = 20 },
        achievement = { total = 80, collected = 10 },
        -- ...
    },
    byExpansion = {
        tww = { total = 50, collected = 5 },
        -- ...
    }
}
```

---

## Contributing Guide

### Reporting Bugs
1. Check if the issue already exists
2. Create a new issue with:
   - WoW version
   - Addon version
   - Steps to reproduce
   - Error message (if any)
   - Screenshot (if applicable)

### Adding Missing Items
1. Fork the repository
2. Find the correct data file in `/Data/`
3. Add entries following the format above
4. Test in-game
5. Submit a pull request

### Code Contributions
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request with description

### Code Style
- Use 4-space indentation
- Comment complex logic
- Follow existing naming conventions
- Keep functions focused and small

---

## Frequently Asked Questions

**Q: Why don't I see any collected items?**
A: Open your Housing Catalog in-game first to populate the collection data, then `/reload`.

**Q: Can I track items across characters?**
A: Housing collections are account-wide in WoW, so yes!

**Q: The waypoint button is grayed out?**
A: That item doesn't have coordinate data yet. Consider contributing!

**Q: How do I request a new feature?**
A: Open a GitHub issue with the "enhancement" label.
