# Codebase Concerns

**Analysis Date:** 2026-03-11

## Tech Debt

**Private API Dependency:**
- Issue: Core IR extraction relies on `ggplot2:::calc_element()` to resolve inherited theme elements
- Files: `R/as_d3_ir.R` (lines 75, 619, 825, 942, 1061)
- Impact: Private API could change in ggplot2 releases (currently on ggplot2 3.x), breaking theme translation. Will create maintenance burden on future ggplot2 updates.
- Fix approach: Monitor ggplot2 releases; consider wrapping in error handler with fallback to manual theme resolution; could contribute fix upstream to make theme API public

**Missing Package Dependencies Declaration:**
- Issue: `DESCRIPTION` file lacks explicit `Imports:` or `Depends:` sections. Code uses `ggplot2`, `htmlwidgets`, `grid`, `scales` but doesn't declare them
- Files: `DESCRIPTION`
- Impact: Package installation may fail if dependencies aren't installed; CRAN submission will fail; users won't know what to install
- Fix approach: Add `Imports: ggplot2, htmlwidgets, grid, scales` to DESCRIPTION and re-run `devtools::document()`

**Incomplete Package Metadata:**
- Issue: DESCRIPTION file contains placeholder values (`<you>` in URL/BugReports, generic Authors@R)
- Files: `DESCRIPTION` (lines 5-6, 10-11)
- Impact: Package metadata missing; users can't report issues; GitHub URL is incomplete
- Fix approach: Update author information, fix GitHub URL, set real bug report location

**Large Monolithic IR Conversion Function:**
- Issue: `as_d3_ir()` is 1151 lines (entire file), combines 3 concerns: scale extraction, theme processing, facet metadata
- Files: `R/as_d3_ir.R`
- Impact: Hard to test individual concerns; difficult to debug; error handling scattered throughout; makes modifications risky
- Fix approach: Extract theme conversion to `extract_theme_ir()` function; extract facet metadata to `extract_facets_ir()` function; extract scale info to `extract_scales_ir()` function

## Known Limitations (Not Bugs, But Constraints)

**Geom Coverage Gaps:**
- Unsupported geoms: `geom_polygon`, `geom_contour`, `geom_sf`, and any extensions (ggridges, ggrepel, ggforce, etc.)
- Files: `vignettes/d3-drawing-diagnostics.md` (lines 7-12), `R/as_d3_ir.R` (lines 169-200)
- Warning: Unrecognized geoms log warning but don't error; renders silently as blank (could confuse users)
- Workaround: Document clearly; consider adding strict mode that errors instead of warns

**Text Rendering Limitations:**
- Missing features: rotation (`angle`), justification (`hjust`/`vjust`), font family
- Files: `vignettes/d3-drawing-diagnostics.md` (lines 14-17)
- Impact: Text labels won't match ggplot2 output exactly; user-facing limitation

**Discrete-Continuous Scale Edge Cases:**
- Issue: `map_discrete()` function (lines 53-71 in `R/as_d3_ir.R`) checks if values are integers to decide if they're indices. May fail with floating-point precision issues.
- Files: `R/as_d3_ir.R` (lines 53-71)
- Impact: Rare edge case where intentional floating-point data could be mistaken for discrete indices
- Risk: Low (requires both discrete scale and numeric data that happens to be integers)

**Panel Clipping Edge Case:**
- Issue: `geom_rect` and `geom_tile` may render incorrectly when coordinates extend outside panel area
- Files: `vignettes/d3-drawing-diagnostics.md` (lines 33-37)
- Impact: Negative widths/heights break rendering; clipping applied at boundary may cause visual artifacts
- Mitigation: Document; validate rect dimensions in IR extraction

**Theme Element Arrow Support Missing:**
- Issue: `element_line(arrow = ...)` is not translated to D3
- Files: `R/as_d3_ir.R` (lines 98-109), `vignettes/d3-drawing-diagnostics.md` (lines 28-31)
- Impact: Axis arrows won't render; minor visual difference from ggplot2
- Fix approach: Would need arrow rendering in D3 theme module

## Security Considerations

**No Input Validation:**
- Risk: IR is not validated before being passed to D3/JavaScript
- Files: `R/as_d3_ir.R` (calls `validate_ir()` at line 1150, which validates structure but not data values)
- Current mitigation: `validate_ir()` in `R/validate_ir.R` checks structure but not content (colors, scales, etc.)
- Recommendations:
  - Validate that color values are valid CSS colors (could be malformed hex strings)
  - Validate that domain values are finite numbers
  - Validate that data arrays don't contain circular references (could break JSON serialization)

**D3 XSS Risk:**
- Risk: SVG rendering could be vulnerable to XSS if any user data (labels, titles, legend values) isn't properly escaped
- Files: `inst/htmlwidgets/gg2d3.js`, `inst/htmlwidgets/modules/*.js`
- Current state: Text is set via D3's `.text()` method which auto-escapes, but SVG attributes set via `.attr()` could be vulnerable if color/style values come from user data
- Recommendations: Never use `.html()`, always use `.text()`; validate color values before setting as CSS

## Performance Bottlenecks

**Large Dataset Rendering:**
- Problem: No data pagination or streaming; entire dataset must be converted to IR and sent to browser
- Files: `R/as_d3_ir.R` (lines 143-286: entire dataset converted to rows), `inst/htmlwidgets/gg2d3.js` (all data rendered at once)
- Cause: Naive `to_rows()` function iterates every row twice (once for coercion, once for conversion to scalar list)
- Improvement path:
  - Implement downsampling for large datasets (100k+ rows)
  - Use server-side filtering with interactive drill-down
  - Stream data in chunks for faceted plots

**Scale Domain Fallback Extraction:**
- Problem: If `panel_params` doesn't have `continuous_range`, code falls back to scale limits and applies manual 5% expansion
- Files: `R/as_d3_ir.R` (lines 361-386)
- Cause: ggplot2's internal structure varies; fallback is inefficient loop for expansion
- Impact: Slow for plots with many scales
- Improvement: Cache expanded range during ggplot_build or compute once instead of per-scale

**Layout Calculation in JavaScript:**
- Problem: `layout.js` (689 lines) recalculates all positions on every render, including resize
- Files: `inst/htmlwidgets/modules/layout.js`
- Impact: Smooth resizing for small plots; may stutter with many facets (100+ panels)
- Improvement: Cache layout for non-resizing renders; use CSS flexbox for facet layouts instead of manual calculation

**Guide/Legend Rendering:**
- Problem: Legend guide extraction iterates over all scales, applies mapping, merges guides by title
- Files: `R/as_d3_ir.R` (lines 628-817)
- Impact: O(n*m) complexity where n=scales, m=aesthetics. Slow for plots with many legend entries (1000+)
- Improvement: Use set operations instead of loops; cache guide data

## Fragile Areas

**Coordinate System Flipping:**
- Files: `R/as_d3_ir.R` (lines 474-486, 575-589)
- Why fragile: coord_flip swaps panel_params but not panel_scales; code has manual un-swapping logic that assumes single panel. Multiple conditions that could break if ggplot2's structure changes.
- Safe modification: Add comprehensive tests for each coord type with facets; document why un-swapping is needed; consider refactoring into helper function
- Test coverage: `tests/testthat/test-layout.R` covers basic coord_flip but not with facets or secondary axes

**Scale Metadata Extraction:**
- Files: `R/as_d3_ir.R` (lines 314-464)
- Why fragile: Navigates deep into scale object closures to extract date_labels and timezone (lines 416-430, 434-451). Uses `tryCatch` with NULL fallbacks that hide failures.
- Safe modification: Add explicit tests for each scale type (date, time, log, sqrt); validate extracted values match ggplot2's output
- Test coverage: Date scales tested in `tests/testthat/test-date-scales.R` but timezone extraction not verified

**Facet Layout Panel Mapping:**
- Files: `R/as_d3_ir.R` (lines 867-1126)
- Why fragile: 146 lines of facet metadata extraction with nested conditionals and two parallel structures (facets_ir and panels_ir). If ggplot2 changes layout structure, entire block could fail silently.
- Safe modification: Extract facet detection into helper; add validation that layout PANEL values match data PANEL values
- Test coverage: `tests/testthat/test-facets.R` and `test-facet-grid.R` cover happy path but not edge cases (empty panels, out-of-order data)

**Private API Theme Resolution Chain:**
- Files: `R/as_d3_ir.R` (lines 74-141)
- Why fragile: `ggplot2:::calc_element()` is private API; its behavior depends on theme inheritance rules. If ggplot2 changes this, all theme translation breaks.
- Safe modification: Wrap in error handler; test against multiple ggplot2 versions; document which elements fail gracefully
- Test coverage: Basic theme extraction tested but no coverage for theme inheritance edge cases (e.g., custom complete themes)

## Test Coverage Gaps

**Untested Scenario: Empty Data Layers:**
- What's not tested: A layer with empty data (0 rows after ggplot_build filtering)
- Files: `R/as_d3_ir.R` (lines 143-286), `R/validate_ir.R` (line 67)
- Risk: Unknown if IR renders correctly or fails silently. `validate_ir()` warns but doesn't error.
- Priority: Medium (could happen with filtered ggplot data)

**Untested Scenario: Non-Finite Values:**
- What's not tested: Data with NaN, Inf, -Inf in coordinates
- Files: `R/as_d3_ir.R` (scale domain extraction lines 361-386), `inst/htmlwidgets/modules/scales.js`
- Risk: D3 scale domain could become invalid (NaN domain breaks axis rendering)
- Priority: High (common with log scales, division by zero)

**Untested Scenario: Coordinate Flip with Facet Grid:**
- What's not tested: coord_flip() + facet_grid() combination
- Files: `R/as_d3_ir.R` (lines 474-486 for flip, 970-1090 for grid)
- Risk: Panel parameter un-swapping logic not tested against grid layout (may produce wrong axis for some panels)
- Priority: Medium (specific edge case)

**Untested Scenario: Secondary Axes:**
- What's not tested: sec.axis on primary scales; reserved layout space but not rendered
- Files: `R/as_d3_ir.R` (lines 605-614)
- Risk: Layout engine reserves space (good), but D3 side doesn't render secondary axis labels/ticks (incomplete feature)
- Priority: High (marks feature as "supported" in README but doesn't work)

**Untested Scenario: Large Datasets (100k+ rows):**
- What's not tested: Performance; IR serialization time; browser rendering with many marks
- Files: `R/as_d3_ir.R` (entire file), `inst/htmlwidgets/gg2d3.js` (entire file)
- Risk: Could timeout/hang browser; user has no warning
- Priority: Medium (affects real-world usage with big data)

**Untested Scenario: Unicode/Non-ASCII Labels:**
- What's not tested: Axis labels, legend titles with non-ASCII characters
- Files: `R/as_d3_ir.R` (lines 584-603 for tick labels), `inst/htmlwidgets/modules/tooltip.js`
- Risk: Encoding issues on Windows; D3 text measurement could fail
- Priority: Low (modern JS/D3 handles UTF-8, but edge cases possible)

## Scaling Limits

**Single Panel Assumption:**
- Current capacity: Code assumes `b$layout$panel_params[[1]]` is the canonical panel for scale extraction
- Limit: Works for non-faceted plots. Faceted plots extract per-panel scales but canonical scales still from panel 1.
- Scaling path: For very large faceted plots (1000+ panels with free scales), IR could become very large. Consider lazy scale extraction.

**In-Memory IR Size:**
- Current capacity: Entire dataset must fit in R memory and be serialized to JSON
- Limit: Typical limit ~100MB JSON (browser memory constraint). Data with 100k rows × 20 columns = ~10MB JSON
- Scaling path: Implement server-side filtering; add data sampling for preview; cache IR results

**D3 Rendering Performance:**
- Current capacity: Browser can render ~5000 marks smoothly (geom_point, geom_path)
- Limit: More complex geoms (geom_polygon with fill) or many facets (50+) may stutter
- Scaling path: Implement mark aggregation; use canvas instead of SVG for large datasets; lazy render off-screen panels

## Dependencies at Risk

**htmlwidgets Package (Implicit Dependency):**
- Risk: Code uses htmlwidgets infrastructure but not explicitly declared in DESCRIPTION
- Impact: Package cannot be installed if htmlwidgets is missing; CRAN submission fails
- Migration plan: Add `htmlwidgets` to Imports; verify min version compatible with D3 v7 binding

**ggplot2 Version Compatibility:**
- Risk: Code tested with ggplot2 3.4.x; private API (`calc_element`) could break in ggplot2 4.x
- Impact: Package breaks when users update ggplot2
- Migration plan: Add version constraint `ggplot2 (>= 3.4.0, < 4.0.0)` temporarily; monitor ggplot2 dev releases

**D3.js Version Pin:**
- Risk: Vendored D3 v7.min.js (lines 102-104 in README); v8+ not supported
- Impact: No access to new D3 features; security updates to D3 not applied
- Migration plan: Test with D3 v8; update binding in `inst/htmlwidgets/gg2d3.yaml`; document breaking changes

## Missing Critical Features

**Feature Gap: Color Space Customization:**
- Problem: Hardcoded color scales in JavaScript (`d3.interpolateTurbo` for continuous, `d3.schemeTableau10` for categorical)
- Blocks: Users cannot apply custom color palettes (viridis, RColorBrewer, etc.)
- Workaround: Would require passing ggplot2 color mapping to IR; implement in Phase N

**Feature Gap: Legend Colorbars Incomplete:**
- Problem: Colorbar legend type generated in IR but not fully rendered in D3
- Blocks: Continuous color legends render as legend keys instead of gradient bars
- Workaround: Implement colorbar rendering in `inst/htmlwidgets/modules/legend.js`

**Feature Gap: Error Handling in Browser:**
- Problem: D3 rendering errors are logged to console but don't display error message to user
- Blocks: Users with unsupported ggplot combinations see blank widgets with console errors
- Workaround: Add error boundary in `gg2d3.js`; display user-friendly message in widget

---

*Concerns audit: 2026-03-11*
