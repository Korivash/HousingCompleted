# Changelog

All notable changes to Housing Completed will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.3.5] - 2026-02-12

### Added
- Runtime item name-to-itemID resolution from `AllItems` cache.
- Preview panel details for `Item ID` and total `Sources`.
- Row-level `REP` badge for items with reputation requirements.
- REP badge tooltip showing faction/standing or requirement notes.
- Bulk CSV importer: `tools/Import-WowDbDecor.ps1`.
- Runtime support for generated import files:
  - `Data/ImportedSources.lua`
  - `Data/ImportedAllItems.lua`
- Search fallback to include cache-known unknown items and items already in player collection.

### Changed
- Item tooltip, icon lookup, and row-click preview now use resolved itemIDs.
- Preview opening now safely falls back in order:
  - Housing catalog preview
  - Dressing Room
  - Modified item click handler
- Index/search data now enriches source rows with vendor-derived waypoint fields when available.
- Reputation tab now includes items with reputation requirements even when source type is not explicitly `reputation`.

## [1.3.4] - 2026-02-12

### Added
- Setting to force TomTom routing for navigation (with Blizzard fallback).

## [1.0.0] - 2025-02-11

### Added
- Initial release of Housing Completed.
- Complete housing decor database with 400+ items.
- Modern, dark-themed user interface.
- Category filtering (Vendors, Achievements, Quests, Reputation, Professions).
- Real-time search functionality.
- Collection tracking via Housing Catalog API.
- TomTom and Blizzard waypoint integration.
- Minimap button with LibDBIcon.
- Settings panel with UI customization options.
- Support for WoW 12.0.1 (Midnight prepatch).
