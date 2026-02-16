---
phase: 04-essential-geoms
plan: 01
subsystem: ir-extraction
tags: [infrastructure, geoms, validation]
completed_date: 2026-02-08
duration_minutes: 2

dependency_graph:
  requires: [03-coordinate-systems]
  provides: [ir-reference-lines, ir-area-ribbon-segment]
  affects: [validate_ir, as_d3_ir, htmlwidgets-modules]

tech_stack:
  added: []
  patterns: [placeholder-modules, geom-registry-registration]

key_files:
  created:
    - inst/htmlwidgets/modules/geoms/area.js
    - inst/htmlwidgets/modules/geoms/ribbon.js
    - inst/htmlwidgets/modules/geoms/segment.js
    - inst/htmlwidgets/modules/geoms/reference.js
  modified:
    - R/as_d3_ir.R
    - R/validate_ir.R
    - inst/htmlwidgets/gg2d3.yaml

decisions:
  - id: reference-line-data-in-rows
    title: Reference line position data stored in layer data rows
    rationale: ggplot_build() computes reference line positions (yintercept, slope, etc.) as data frame columns, not params
    impact: JS renderers read position data from data rows, not layer.params
  - id: placeholder-geom-modules
    title: Create placeholder JS modules that register but return 0
    rationale: Prevents widget load errors before Wave 2 implements actual rendering
    impact: All Phase 4 geoms can be added to IR/validation/YAML immediately

metrics:
  tasks_completed: 2
  commits: 2
  tests_added: 0
  lines_added: 76
---

# Phase 4 Plan 1: R-Side Infrastructure for New Geoms Summary

**One-liner:** Added IR extraction, validation, and module loading for 7 new geom types (hline, vline, abline, area, ribbon, segment, polygon) with placeholder JS modules.

## What Was Built

### Task 1: R-Side IR Extraction
Updated `as_d3_ir.R` to recognize and extract data for new geom types:

**Reference lines (GeomHline, GeomVline, GeomAbline):**
- Added `slope`, `intercept`, `xintercept`, `yintercept` to both `keep_aes` vectors
- Added geom name mappings in switch statement
- Added aes mappings for reference line position columns
- Position data preserved in layer data rows (as computed by ggplot_build)

**Area/ribbon/segment:**
- Added GeomArea, GeomRibbon, GeomSegment to geom name switch (Area was already there, verified others)
- GeomPolygon added for completeness (deferred rendering)

**Verification:** All reference line geoms extract correct IR with position data in layer.data rows.

### Task 2: Validation and Module Infrastructure
Updated validation and module loading:

**validate_ir.R:**
- Added `hline`, `vline`, `abline`, `polygon` to known_geoms list
- Eliminates unrecognized geom warnings

**gg2d3.yaml:**
- Added 4 new module files to dependency script list:
  - `geoms/area.js`
  - `geoms/ribbon.js`
  - `geoms/segment.js`
  - `geoms/reference.js`

**Placeholder JS modules:**
- Created 4 files with IIFE pattern
- Each registers with geom registry using no-op function (returns 0)
- `reference.js` registers all 3 reference line geoms: `['hline', 'vline', 'abline']`

**Verification:** Widget loads without errors; IR validation passes without warnings.

## Deviations from Plan

None - plan executed exactly as written.

## Test Results

**IR Extraction Tests (Task 1):**
```r
# All tests passed:
- geom_hline() → ir$layers[[2]]$geom == "hline", yintercept in data
- geom_vline() → ir$layers[[2]]$geom == "vline", xintercept in data
- geom_abline() → ir$layers[[2]]$geom == "abline", slope/intercept in data
- geom_area() → ir$layers[[1]]$geom == "area"
```

**Widget Loading Tests (Task 2):**
```r
# Widget creation succeeded without errors
gg2d3(p) → htmlwidget object created
```

## Key Technical Decisions

**Reference Line Data Location:**
Unlike params-based geoms (point, line), reference lines store their position data in the built data frame. This is how ggplot2 works internally - `ggplot_build()` computes `yintercept`, `slope`, etc. as data columns. The JS renderers will read these from `layer.data[i].yintercept` rather than `layer.params.yintercept`.

**Placeholder Module Pattern:**
Rather than waiting for Wave 2 implementations, we created placeholder modules immediately. This allows:
1. The widget to load without module reference errors
2. IR validation to pass without warnings
3. Wave 2 plans to focus purely on rendering logic (no infrastructure work)

## Next Phase Readiness

**Phase 4 Plan 2+ (Wave 2) ready:**
- IR extraction complete for all new geoms
- Validation infrastructure in place
- Module loading configured
- Geom registry pattern established

**Blockers:** None

**Dependencies satisfied:**
- Phase 3 (coord systems) complete
- Geom registry pattern from Phase 1 available

## Commits

| Hash | Message |
|------|---------|
| 6547a9f | feat(04-01): add IR extraction for reference line and area geoms |
| bc1995c | feat(04-01): add IR validation and JS module infrastructure for new geoms |

## Self-Check: PASSED

**Created files verified:**
```bash
✓ inst/htmlwidgets/modules/geoms/area.js
✓ inst/htmlwidgets/modules/geoms/ribbon.js
✓ inst/htmlwidgets/modules/geoms/segment.js
✓ inst/htmlwidgets/modules/geoms/reference.js
```

**Modified files verified:**
```bash
✓ R/as_d3_ir.R - contains "slope", "intercept", "xintercept", "yintercept"
✓ R/as_d3_ir.R - contains GeomHline, GeomVline, GeomAbline
✓ R/validate_ir.R - contains "hline", "vline", "abline"
✓ inst/htmlwidgets/gg2d3.yaml - contains geoms/area.js, reference.js
```

**Commits verified:**
```bash
✓ 6547a9f found in git log
✓ bc1995c found in git log
```
