# Codebase Concerns

**Analysis Date:** 2026-02-07

## Tech Debt

**Monolithic as_d3_ir function:**
- Issue: The main conversion function `as_d3_ir()` in `R/as_d3_ir.R` is 353 lines with multiple nested helper functions (`to_rows`, `map_discrete`, `extract_theme_element`, `get_scale_info`), making it difficult to test, reuse, and maintain individually.
- Files: `R/as_d3_ir.R` (lines 3-353)
- Impact: Hard to unit test individual conversion steps. Changes to one aesthetic or scale type require understanding the entire function. New developers cannot easily extract and test specific behaviors.
- Fix approach: Extract helper functions to module-level (or at minimum to separate clearly delimited sections). Create dedicated functions for scale conversion, aesthetic mapping, and theme extraction.

**Duplicated to_rows function:**
- Issue: The `to_rows()` helper is defined twice within `as_d3_ir()` — once at line 16 and again at line 194 with nearly identical code.
- Files: `R/as_d3_ir.R` (lines 16-35, 194-210)
- Impact: Code duplication creates maintenance burden. Bug fixes must be applied in two places. Harder to reason about correctness.
- Fix approach: Define `to_rows()` once at the top level of `as_d3_ir()` and reuse both times, or extract to a standalone helper function.

**Heavy reliance on ggplot2 private APIs:**
- Issue: Code calls `ggplot2:::calc_element()` (line 64) which is a private internal function (uses `:::` notation). This function is not part of the public API and may change without notice in ggplot2 updates.
- Files: `R/as_d3_ir.R` (line 64)
- Impact: Package may break silently when ggplot2 is updated. No warning in documentation about this fragility.
- Fix approach: Document this dependency clearly. Consider wrapping the call in a try-catch with a meaningful error message. Monitor ggplot2 release notes for changes to theme element extraction.

**Hardcoded unit conversions:**
- Issue: Conversion factors (e.g., `3.7795275591` for mm to pixels at 96 DPI) are hardcoded throughout `R/as_d3_ir.R` and `inst/htmlwidgets/gg2d3.js` without centralized definition or documentation of the assumptions.
- Files: `R/as_d3_ir.R` (lines 76, 89), `inst/htmlwidgets/gg2d3.js` (lines 452, 519, 596)
- Impact: Inconsistent DPI assumptions can cause mismatches between R and JavaScript rendering. Changes require updates in multiple files.
- Fix approach: Define unit conversion constants in a shared location (or in a JavaScript module) with clear documentation of DPI assumptions (96 DPI web standard). Add comments explaining the conversion formula.

## Known Bugs

**coord_flip axes on wrong sides:**
- Symptoms: When `coord_flip()` is used, axes appear on incorrect sides. The code reverses scale ranges but continues rendering x-axis at bottom and y-axis at left.
- Files: `inst/htmlwidgets/gg2d3.js` (lines 316-318, 670-689)
- Trigger: Create any ggplot with `coord_flip()` and observe axis positions.
- Workaround: Currently no workaround; feature does not match ggplot2 output.
- Related documentation: `vignettes/d3-drawing-diagnostics.md` (lines 15-18)

**geom_path always sorts by x:**
- Symptoms: `geom_path()` plots sort points by x value, destroying intentional ordering for spiral or looping patterns.
- Files: `inst/htmlwidgets/gg2d3.js` (lines 509-512) — only sorts for `geom_line`, not `geom_path`; however, may still have issues with categorical x-axes.
- Trigger: Create a path that intentionally revisits x values (e.g., a spiral) and render with D3.
- Workaround: Use `geom_line()` instead if order matters.
- Related documentation: `vignettes/d3-drawing-diagnostics.md` (lines 37-40)

**Bar height calculation fails for non-zero baselines:**
- Symptoms: Bar charts where the domain does not include 0, or where 0 is off-scale due to transformations, render with incorrect heights or clipped rectangles.
- Files: `inst/htmlwidgets/gg2d3.js` (lines 545-559) — has logic to handle this but depends on scale domain checks.
- Trigger: Create bar chart with y-axis range like `c(10, 20)` and render.
- Workaround: Ensure domain includes 0.
- Related documentation: `vignettes/d3-drawing-diagnostics.md` (lines 47-50)

**Rectangle dimensions wrong with categorical scales:**
- Symptoms: Heatmaps (rect/tile geoms) using categorical scales calculate negative widths/heights or collapse entirely.
- Files: `inst/htmlwidgets/gg2d3.js` (lines 620-630) — now uses `bandwidth()` check to handle this.
- Trigger: Create a 2D grid with categorical x and y.
- Workaround: Currently fixed in code; was a Phase 1 issue.
- Related documentation: `PHASE1_COMPLETE.md` (lines 25-30)

**Missing factoring in axis label mapping:**
- Symptoms: When mapping discrete values to labels, the code assumes integer indices match factor level positions. If a subset of levels is present in the data, indices may be out of bounds.
- Files: `R/as_d3_ir.R` (lines 42-60) — includes safety checks but may still fail with unusual factor level orderings.
- Trigger: Create a plot with a factor that has unused levels, then filter data before plotting.
- Workaround: Explicitly drop unused levels with `forcats::fct_drop()`.
- Impact: Could cause rendering to fail or show incorrect labels.

## Security Considerations

**No input validation on IR JSON:**
- Risk: The IR (intermediate representation) is passed directly from R to JavaScript without validation. A malformed IR could cause JavaScript errors or unexpected behavior.
- Files: `R/gg2d3.R` (line 16), `inst/htmlwidgets/gg2d3.js` (lines 699-710)
- Current mitigation: Basic checks for `ir.scales` and `ir.layers` exist; defensive coding in helpers (`val()`, `num()`, `isValidColor()`).
- Recommendations: Add schema validation to IR before widget creation. Document IR structure formally (currently only in comments).

**Unescaped user text in SVG:**
- Risk: Plot titles and axis labels are directly inserted into SVG text elements without HTML/XML escaping. SVG injection could occur if user data contains special characters.
- Files: `inst/htmlwidgets/gg2d3.js` (lines 376-385 for title, various for axis labels)
- Current mitigation: D3's `.text()` method auto-escapes, but `.html()` or direct attribute assignment would not.
- Recommendations: Document that only `.text()` is used (not `.html()`). Add tests with special characters in labels.

**No limits on data size:**
- Risk: Large datasets could cause browser memory exhaustion or DOM explosion. No limits on number of points, bars, or text elements rendered.
- Files: `inst/htmlwidgets/gg2d3.js` (lines 398-663) — loops through all layer data without throttling or sampling.
- Current mitigation: None.
- Recommendations: Add optional `maxPointsWarning` parameter or document browser limitations.

## Performance Bottlenecks

**Full re-render on every update:**
- Problem: The `draw()` function clears all SVG content with `d3.select(el).selectAll("*").remove()` (line 226) and rebuilds from scratch on every resize or data update, even if only a small part changed.
- Files: `inst/htmlwidgets/gg2d3.js` (lines 225-226)
- Cause: No retained state for incremental updates. D3 selections are not reused.
- Improvement path: Implement update patterns for `resize()` function (currently a no-op at line 713). Cache scales and group selections.

**Direct attribute access without caching:**
- Problem: Aesthetic properties (color, size, opacity) are extracted per data point in tight loops (`strokeColor()`, `fillColor()` at lines 404-427) without memoization.
- Files: `inst/htmlwidgets/gg2d3.js` (lines 404-434)
- Cause: Functions are called in `attr()` or `style()` chaining, which re-evaluates for each element.
- Improvement path: Pre-compute aesthetic values into data array before rendering; use indexed lookups.

**Multiple filter passes on layer data:**
- Problem: Layer data is filtered multiple times to remove null values (e.g., lines 440-444, 536-540, 602-605).
- Files: `inst/htmlwidgets/gg2d3.js` (throughout geom rendering)
- Cause: Each geom re-implements `d => d.x != null && d.y != null` checks.
- Improvement path: Create a single filtered dataset per geom type in a preprocessing step.

## Fragile Areas

**Scale object introspection:**
- Files: `R/as_d3_ir.R` (lines 238-269)
- Why fragile: The code relies on `inherits(scale_obj, "ScaleDiscrete")` and calls `scale_obj$get_limits()` without checking if the scale object exists or has the expected structure. If ggplot2 refactors scale objects, this breaks.
- Safe modification: Wrap in `tryCatch()` with fallback to numeric scale inference. Add defensive checks for null/missing fields before accessing.
- Test coverage: Minimal — only one basic test in `tests/testthat/test-ir.R` (line 1-9).

**Theme element extraction:**
- Files: `R/as_d3_ir.R` (lines 63-130)
- Why fragile: Calls `ggplot2:::calc_element()` (private API), then assumes returned object has specific class and field names. A missing theme element returns NULL without error context.
- Safe modification: Document which theme elements are supported. Test with various ggplot2 themes (theme_bw, theme_minimal, custom). Wrap in try-catch with informative error messages.
- Test coverage: None — no tests for theme extraction.

**Discrete value mapping logic:**
- Files: `R/as_d3_ir.R` (lines 42-60)
- Why fragile: The logic assumes that integer indices `1, 2, 3, ...` correspond directly to factor level positions. This breaks if:
  - Scale limits are a subset of factor levels
  - Factor has gaps (e.g., levels dropped)
  - User provides a scale with custom breaks
- Safe modification: Use `scale_obj$get_limits()` to extract actual domain labels and match against data values, rather than assuming integer indexing.
- Test coverage: Not tested with unusual factor scenarios.

**Padding and margin calculations:**
- Files: `inst/htmlwidgets/gg2d3.js` (lines 269-282)
- Why fragile: Hard-coded additions (`pad.top + 30`, `pad.left + 50`) assume standard label/title sizes. Unusually long labels or multi-line titles break layout.
- Safe modification: Measure rendered text width/height dynamically, or expose padding as a widget parameter.
- Test coverage: Limited to default examples.

**JavaScript color validation:**
- Files: `inst/htmlwidgets/gg2d3.js` (lines 13-20)
- Why fragile: `isValidColor()` creates a test DOM element to check CSS color validity. This assumes CSS color parsing is available and consistent across browsers.
- Safe modification: Use a whitelist of known valid colors or a more robust color library.
- Test coverage: Not tested with unusual color formats.

## Scaling Limits

**No support for facets:**
- Current capacity: Single panel only
- Limit: Any plot with `facet_wrap()` or `facet_grid()` only shows the first panel
- Scaling path: Extend IR to include all panel data; update JavaScript to render grid of subplots
- Files: `R/as_d3_ir.R` (line 346-347 — hardcoded to 1x1), `inst/htmlwidgets/gg2d3.js` (no facet support)

**No legend support:**
- Current capacity: Aesthetics rendered but no legend shown
- Limit: Users cannot identify what colors/sizes mean
- Scaling path: Extract aesthetic mappings from IR; generate legend SVG
- Files: `R/as_d3_ir.R` (line 350 — legend enabled flag not used), `inst/htmlwidgets/gg2d3.js` (no legend rendering)

**Limited geom coverage:**
- Current capacity: point, line, path, bar, col, rect, tile, text
- Limit: Missing area, violin, boxplot, segment, ribbon, smooth, density, etc. — renders as placeholder tomato circle
- Scaling path: Implement one geom at a time; add tests for each
- Files: `inst/htmlwidgets/gg2d3.js` (lines 436-662 — only these 8 handled; line 691-693 shows placeholder)

**No animation or interactivity:**
- Current capacity: Static SVG only
- Limit: No hover tooltips, brushing, or transitions
- Scaling path: Add D3 event handlers; expose `on_*` callbacks via htmlwidgets
- Files: `inst/htmlwidgets/gg2d3.js` (no event handlers)

## Dependencies at Risk

**ggplot2 private API usage:**
- Risk: `ggplot2:::calc_element()` is an internal function. ggplot2 developers may refactor or remove it without notice.
- Impact: Package will break silently on ggplot2 updates (likely > 3.5.x).
- Migration plan: Research public alternatives (may not exist); fork the function locally if needed; consider contributing theme extraction to ggplot2.

**D3 v7 vendored locally:**
- Risk: D3 is shipped as a static file at `inst/htmlwidgets/lib/d3/d3.v7.min.js`. Updates require manual download.
- Impact: Security vulnerabilities in D3 are not automatically patched.
- Migration plan: Use CDN with version pinning and hash verification, or set up automated update checks.
- Files: `inst/htmlwidgets/lib/d3/d3.v7.min.js` (279 KB minified)

**htmlwidgets framework tightly coupled:**
- Risk: Widget structure assumes htmlwidgets rendering flow. Changes to htmlwidgets API (v1.x → v2.x) could break.
- Impact: Widget becomes unmaintainable if htmlwidgets evolves incompatibly.
- Migration plan: Monitor htmlwidgets releases; consider using native R/JavaScript integration in newer versions (like Quarto).

## Missing Critical Features

**No legends:**
- Problem: Color and size aesthetics are rendered but unmapped to a legend, making the visualization impossible to interpret.
- Blocks: Any publication-quality visualization.
- Priority: High

**No facets:**
- Problem: Faceted plots only show the first panel.
- Blocks: Exploratory analysis with faceting; small multiples.
- Priority: High

**No text rotation or alignment:**
- Problem: `angle`, `hjust`, `vjust` parameters are not applied; all text renders horizontal and centered.
- Blocks: Angled axis labels; rotated geom_text.
- Priority: Medium

**No support for statistical transformations:**
- Problem: Smooth, density, binning (histogram), and other stat layers render as placeholders.
- Blocks: Common exploratory plots like histograms, density curves.
- Priority: High

## Test Coverage Gaps

**as_d3_ir() function:**
- What's not tested: Theme extraction, discrete scale mapping, margin/padding calculations, edge cases (empty data, single point, all-NA columns).
- Files: `R/as_d3_ir.R`
- Risk: Regressions in theme or scale handling go undetected.
- Priority: High

**D3 rendering engine:**
- What's not tested: Edge cases (no data, very large data, unusual coordinate systems, mismatched scale domains), all geom types, all aesthetic combinations.
- Files: `inst/htmlwidgets/gg2d3.js`
- Risk: Visual mismatches and silent failures with real-world data.
- Priority: High

**Color conversion:**
- What's not tested: Grey scale (`grey0`-`grey100`), named colors, hex colors, edge cases (NA, NULL, empty string).
- Files: `inst/htmlwidgets/gg2d3.js` (lines 178-193)
- Risk: Color mapping failures or incorrect rendering.
- Priority: Medium

**Input validation:**
- What's not tested: Malformed IR, missing aesthetic columns, NULL scales, non-ggplot inputs.
- Files: `R/gg2d3.R`, `inst/htmlwidgets/gg2d3.js`
- Risk: Cryptic error messages or crashes.
- Priority: Medium

**Cross-browser compatibility:**
- What's not tested: Internet Explorer, Safari (older versions), mobile browsers.
- Files: `inst/htmlwidgets/gg2d3.js` (uses modern JavaScript syntax)
- Risk: Widget fails silently in unsupported browsers.
- Priority: Low (modern browsers only, but undocumented)

---

*Concerns audit: 2026-02-07*
