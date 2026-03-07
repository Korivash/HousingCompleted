# Changelog

## [1.7.0] - 2026-03-06

### Added
- Advanced systems foundation in `Systems/Advanced.lua` with automation, blueprint, routing, and planning hooks integrated into the main UI flow.
- Enhanced vendor and acquisition workflows, including broader filtering, mapping, and source visibility.
- Richer crafting and planning surfaces with stronger reagent tracking and shopping support.
- Additional quality-of-life integrations across route planning, export dialogs, and action panel operations.

### Changed
- Recipes materials interaction updated to Shift-Click tracking for reagents in recipe material displays.
- Removed Ctrl-Click tracking behavior from recipe material rows.
- Collection checks centralized so tabs and filters use consistent ownership logic.
- Version aligned to `1.7.0` across addon metadata and runtime constants.

### Fixed
- Collection false-positives corrected for non-crafted items (vendor, promotion, quest, and similar sources).
- Crafted-only fallback handling applied so `firstAcquisitionBonus` no longer marks non-crafted items as collected.
- Styles tab uncollected filter now uses centralized collection validation instead of inline fallback checks.
- Materials list now refreshes immediately after tracking or untracking reagents.
- Fixed startup error in advanced actions (`IsResultCraftable` nil method path).
- Fixed blueprint dialog/editbox height error (`GetStringHeight` nil call path).
- Stabilized result and item-resolution flows after API-oriented behavior updates that caused missing-item scenarios.

### Performance
- Reduced memory pressure by removing duplicate all-item cache dependence in search/index paths.
- Introduced lightweight known-item ID indexing for broad item resolution without duplicating full item objects.
- Optimized statistics/search loops to iterate compact ID lists and cached item metadata.
- Added source-table release support after index/materialized lookup build to reduce retained memory footprint.

### UI
- Fixed overlapping text in item crafting/material requirement displays.
- Prevented simultaneous overdraw of material text and reagent button overlays in preview.
- Applied single-line clamping in relevant shopping/tracked reagent rows to avoid row collision on long labels.

### Notes
- This release includes broad data, UI, systems, and performance updates delivered as one consolidated update.



## [1.6.1] - 2026-03-05

### Fixed
- Unknown source/expansion column categorization caused by mixed imported metadata formats.
- Expansion filter mismatches caused by mixed expansion values (short IDs vs full names).

### Changed
- Updated addon version metadata to `1.6.1`.
- Core item-source ingest now normalizes expansion IDs and infers missing expansion from vendor/map metadata.
- Core source ingest now infers source type from available fields when imported type is missing/unknown.
- Statistics and filter checks now normalize source/expansion keys before bucketing/comparison.

## [1.6.0] - 2026-03-03

### Added
- Modernized 2026 UI shell with deep-charcoal + blue-accent theme.
- New top primary tabs: `Overview`, `Items`, `Sources`, `Filters`, `Favorites`, `Profiles`.
- Completion header bar with overall % and quick metrics.
- Grid/List view toggle for item browsing.
- Favorites system with star/unstar actions and favorites-only tab filtering.
- Expansion filter panel in sidebar.
- Slide-in animation for right detail panel updates.
- Streamer mode and performance mode settings.

### Changed
- Refreshed layout sizing and visual styling for cleaner, less-cluttered presentation.
- Updated right panel action labels for goal tracking (`Track This`).
- Updated addon version metadata to `1.6.0`.

## [1.5.2] - 2026-03-03

### Added
- Added `automation/Refresh-HDGImports.ps1` for one-command import refresh from `HousingDecorGuide`.
- Added `automation/Build-CurseForgeRelease.ps1` to build a clean package from `.toc` runtime files.

### Changed
- Updated addon version metadata to `1.5.2`.
- Refreshed imported decor datasets from latest `HousingDecorGuide`, including new Midnight items.

### Packaging
- Built CurseForge-ready zip from runtime addon files only.

## [1.5.1] - 2026-02-25

### Changed
- Updated addon version metadata to `1.5.1`.
- Confirmed retail TOC interface value remains `120001` (WoW `12.0.1`).

### Packaging
- Prepared new CurseForge release package zip.

## [1.5.0] - 2026-02-18

### Added
- Vendor Inventory panel with vendor item browsing and item preview actions.
- Preview button: `Browse Vendor Items`.
- Internal vendor inventory data integration (`Data/VendorInventory.lua`).
- Internal recipe/reagent datasets for improved crafting material resolution:
  - `Data/DecorRecipes.lua`
  - `Data/ProfessionRecipes.lua`
  - `Data/ReagentSources.lua`

### Changed
- Removed external addon dependency declarations.
- Removed compatibility bridge and external runtime references.
- Preview flow now uses built-in housing preview paths with Dressing Room fallback.
- Economics now resolves fallback materials/prices from internal datasets.

### Packaging
- CurseForge package includes only runtime addon files.
