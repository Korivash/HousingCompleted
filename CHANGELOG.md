# Changelog

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
