# Changelog

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
