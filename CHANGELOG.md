# Changelog

All notable changes to Housing Completed will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.3.7] - 2026-02-12

### Added
- Broader catalog collection scan across multiple housing catalog roots, with safe fallback to legacy root scan.
- New collection lookup caches by normalized item name and by itemID for more reliable collected detection.
- New primary `Set Waypoint` button in the results footer (select item first, then click once).

### Changed
- Statistics now count the full indexed item universe (curated + imported + `AllItems` cache + uncatalogued collected names), not only curated source tables.
- Collection stats UI now shows three metrics: `Collected/Trackable`, `Trackable/Known`, and `Unknown Sources`.
- Unknown-item search now includes unresolved IDs from the full all-item cache, so tracking is no longer capped to a small subset.
- Collected detection now checks both item name and itemID where available.
- Row waypoint icons now use a map icon (instead of quest-style icon) to reduce navigation confusion.
- Waypoint routing logic is now unified for row buttons and the footer button, with consistent fallback behavior.

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
