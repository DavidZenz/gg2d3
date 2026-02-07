# Pitfalls Research

**Domain:** ggplot2-to-D3.js translation
**Researched:** 2026-02-07
**Confidence:** HIGH

## Critical Pitfalls

### Pitfall 1: Unit Conversion Inconsistencies (mm to pixels)

**What goes wrong:**
Hardcoded conversion factors scattered across R and JavaScript code lead to visual mismatches. ggplot2 uses mm internally, browsers use pixels. The conversion factor (3.7795275591) appears without context in multiple files, and any inconsistency causes line widths, point sizes, and spacing to differ between ggplot2 and D3 output.

**Why it happens:**
Developers hardcode the magic number without understanding the DPI assumptions. ggplot2 assumes 72 DPI for calculations, browsers assume 96 DPI. The conversion formula `pixels = mm × (96 DPI / 25.4 mm/inch)` is not documented, leading to copy-paste errors and inconsistent application.

**How to avoid:**
- Define conversion constants in a single location with clear documentation
- Document the DPI assumption (96 for web) explicitly
- Create helper functions for all unit conversions (mm→px, pt→px, lines→px)
- Add tests that verify conversion accuracy across all rendering contexts
- Consider parameterizing DPI for high-resolution displays

**Warning signs:**
- Lines appear thicker or thinner than ggplot2 output
- Grid lines don't match ggplot2 thickness
- Point sizes are visually wrong
- Different conversion factors in R vs JavaScript code
- Text sizes don't match between outputs

**Phase to address:**
Phase 1 (Foundation) - Must be correct before building other features. Current codebase has this partially addressed but inconsistently applied.

---

### Pitfall 2: ggplot2 Private API Dependency (`calc_element()`)

**What goes wrong:**
Using `ggplot2:::calc_element()` creates fragile dependency on internal implementation. ggplot2 developers can change or remove private functions without notice. When ggplot2 updates (e.g., v3.4.0 → v3.5.0 → v4.0.0), the package breaks silently with cryptic errors.

**Why it happens:**
No public API exists for extracting resolved theme elements. `calc_element()` is the only way to get inherited theme properties (e.g., panel.grid.major inherits from line element). Developers use `:::` to access it because it's the only solution.

**How to avoid:**
- Wrap all private API calls in try-catch with informative error messages
- Document the dependency prominently in package documentation
- Monitor ggplot2 releases and changelogs for breaking changes
- Create compatibility shims for different ggplot2 versions
- Consider contributing theme extraction as public API to ggplot2
- Add CI tests against multiple ggplot2 versions (current, devel, previous)

**Warning signs:**
- "object 'calc_element' not found" errors after ggplot2 updates
- Theme extraction returns NULL unexpectedly
- Different theme behavior across ggplot2 versions
- GitHub issues reporting breakage after ggplot2 upgrades

**Phase to address:**
Phase 1 (Foundation) - Critical infrastructure that affects all subsequent phases. Already implemented but needs defensive coding and version testing.

---

### Pitfall 3: Statistical Transformation Trap

**What goes wrong:**
Attempting to translate stat layers (stat_smooth, stat_density, stat_bin) by extracting ggplot2's computed data fails because you lose the ability to update with new data. Stat layers compute derived variables (density, count, ymin, ymax) that don't exist in original data. Extracting post-stat data creates static visualizations that can't be re-computed in JavaScript.

**Why it happens:**
Developers try to serialize the post-stat data from `ggplot_build()` to avoid re-implementing statistical algorithms in JavaScript. This works for static plots but breaks interactivity - you can't recompute density curves when the user filters data or changes binwidth.

**How to avoid:**
- For stat layers, must choose: (1) pre-compute in R and lose interactivity, or (2) implement stat algorithms in JavaScript
- Document which stats are supported and limitations
- For MVP, focus on geometric layers only (point, line, bar, rect, text)
- Phase in stat support gradually, starting with simple ones (count, identity)
- Consider hybrid approach: compute initial state in R, provide JavaScript implementation for updates

**Warning signs:**
- "Computed variable not found" errors
- Histograms show wrong bin counts
- Smooth lines don't match ggplot2
- Interactive updates fail for stat layers
- Loss of after_stat() aesthetic mappings

**Phase to address:**
Phase 3-4 (Advanced Geoms) - Not needed for MVP. Stat layers are complex and should be deferred until core geoms work perfectly.

---

### Pitfall 4: Coordinate System Transformation Complexity

**What goes wrong:**
coord_flip() is deceptively simple (just swap x and y) but actually requires repositioning axes, rotating labels, and transforming the entire layout. Simply reversing scale ranges puts axes on wrong sides, breaks axis label orientation, and confuses geom positioning logic.

**Why it happens:**
Developers think coordinate flipping is a scale transformation when it's actually a layout transformation. ggplot2's coord system affects scale positioning, axis placement, panel layout, and geom rendering order. Partial implementation (just swapping scales) creates incorrect but seemingly-working output.

**How to avoid:**
- Treat coord as first-class IR concept, not scale manipulation
- Pass coord info separately in IR (type, flip status, trans functions)
- In D3, restructure entire rendering pipeline based on coord type
- Don't just swap x/y scales - actually reposition axis groups
- Test with all coord variants: cartesian, flip, trans, polar, fixed

**Warning signs:**
- Axes appear on wrong sides after coord_flip
- Axis labels point wrong direction
- Geom positioning works but layout is wrong
- Grid lines are horizontal when they should be vertical
- Title and axis labels are misaligned

**Phase to address:**
Phase 2 (Core Coordinate Systems) - Must be fixed before adding complex geoms. Currently broken in codebase, documented in CONCERNS.md.

---

### Pitfall 5: Scale Expansion Mismatch

**What goes wrong:**
ggplot2 adds 5% padding (multiplicative) plus small additive padding to all axes by default. Missing or incorrect expansion in D3 causes data to touch axis edges, cuts off points at boundaries, or creates too much white space. Discrete scales use different expansion (0.6 units) than continuous scales (5%).

**Why it happens:**
Developers forget that ggplot2's scale domain includes invisible padding. Extracting `scale$range$range` gives pre-expansion values. The expansion calculation happens in `coord$transform()` which is not easily accessible. Different scale types (continuous, discrete, date) have different expansion defaults.

**How to avoid:**
- Extract expansion parameters from scale objects explicitly
- Implement expansion() logic in JavaScript matching ggplot2's formula
- Apply different expansion for discrete vs continuous scales
- Handle `expand = c(0, 0)` override case
- Test edge cases: single data point, data at exact limits, all-same values

**Warning signs:**
- Points touching axis lines (should have space)
- Bars extend beyond plot boundary
- Too much white space around data
- Categorical bars not centered on band
- First/last data points appear cut off

**Phase to address:**
Phase 1 (Foundation) - Critical for visual parity. Not yet implemented in current codebase.

---

### Pitfall 6: Discrete Scale Index Mapping

**What goes wrong:**
Categorical data gets converted to integer indices (1, 2, 3) during ggplot_build(). Mapping these back to factor labels fails when factor levels are reordered, subsetted, or have gaps. Using `labels[index]` assumes continuous 1-based indexing, but factors can have unused levels or custom orderings.

**Why it happens:**
ggplot2's internal scale machinery converts factors to integers for positioning. Extracting scale limits gives all possible levels, but data may only use subset. Developer assumes indices match factor positions without checking for gaps or reordering.

**How to avoid:**
- Store both numeric positions and original labels in IR
- Use scale$get_limits() for authoritative label list
- Validate index bounds before lookup
- Handle dropped factor levels explicitly
- Test with: subsetted factors, reordered levels, unused levels, custom breaks

**Warning signs:**
- Wrong category labels on axes
- "Index out of bounds" errors
- Missing or extra tick marks
- Labels appear in wrong order
- NA labels when data exists

**Phase to address:**
Phase 1 (Foundation) - Already partially implemented with safety checks, but needs comprehensive testing.

---

### Pitfall 7: Color Name Translation (Grey vs Gray)

**What goes wrong:**
ggplot2 accepts "grey50" (British spelling), CSS accepts "gray50" (American spelling). Some colors work, others fail silently. R color names (all 657 of them) don't all have CSS equivalents. Named colors like "grey92" (ggplot2 default panel background) may not render correctly.

**Why it happens:**
R's color system and CSS color systems evolved independently. ggplot2 inherited R's British spellings. Developers test with hex colors (#RRGGBB) that work everywhere, miss the named color edge cases.

**How to avoid:**
- Create color translation map for R → CSS conversions
- Handle "grey" → "gray" spelling conversion explicitly
- Convert all colors to hex format during IR generation for consistency
- Add color validation in JavaScript with fallback to hex
- Test with: grey scale (grey0-grey100), named colors, transparency, NA

**Warning signs:**
- Panel backgrounds are wrong color or transparent
- Grid lines not visible (wrong color)
- Some geoms render in unexpected colors
- Axis text disappears (defaulting to "currentColor")
- Transparent fills when solid expected

**Phase to address:**
Phase 1 (Foundation) - Color fidelity is critical for visual parity. Partially addressed in current theme implementation.

---

### Pitfall 8: SVG Coordinate Precision (Sub-pixel Rendering)

**What goes wrong:**
SVG coordinates like `x="10.5"` cause blurry lines because browsers anti-alias across pixel boundaries. A 1-pixel line at half-pixel position renders as fuzzy 2-pixel line. Different browsers (Chrome, Firefox, Safari) handle sub-pixel rendering differently, causing inconsistent appearance.

**Why it happens:**
ggplot2 calculates positions in continuous coordinates, D3 scale functions return floating point values. Developer doesn't round to integer pixels before setting SVG attributes. Browser tries to be helpful by anti-aliasing but makes lines blurry.

**How to avoid:**
- Round line positions to integer pixels: `Math.round(xScale(d.x))`
- Keep fractional coordinates for area fills and points (anti-aliasing is good there)
- Use `shape-rendering="crispEdges"` for grid lines and axes
- Test on multiple browsers (Chrome, Firefox, Safari)
- Consider retina/high-DPI displays (may need half-pixel precision there)

**Warning signs:**
- Grid lines appear blurry or double-width
- Axis lines are fuzzy
- Vertical/horizontal lines inconsistent thickness
- Plot looks sharp in one browser, blurry in another
- Lines "wiggle" during zoom/resize

**Phase to address:**
Phase 2 (Polish) - Affects visual quality but not correctness. Can be addressed after core features work.

---

### Pitfall 9: Facet Data Structure Complexity

**What goes wrong:**
Faceting creates multiple panels with separate scales, axes, and data subsets. Naively implementing facets by rendering N separate plots creates wrong spacing, shared axes problems, and misaligned strips. Each panel needs its own scale domain but shared axis labels. Layout math is complex.

**Why it happens:**
Developers underestimate faceting complexity. It looks like "just make multiple subplots" but actually requires:
- Calculating panel positions in grid layout
- Sharing or separating scales across panels
- Handling strip labels (facet labels)
- Synchronizing axes across rows/columns
- Dealing with missing combinations (facet_grid with gaps)
- Managing free vs fixed scales

**How to avoid:**
- Study ggplot2's Facet class implementation carefully
- Extract panel layout metadata from ggplot_build() (Layout object)
- Store panel assignments per data point in IR
- Implement D3 grid layout with proper spacing calculations
- Handle scales="free", scales="fixed", scales="free_x", scales="free_y" separately
- Start with facet_wrap (simpler) before facet_grid (matrix layout)

**Warning signs:**
- Panels overlap or have wrong spacing
- Strip labels missing or mispositioned
- Axes not aligned across panels
- Data shows in wrong panel
- Gaps in grid when combinations don't exist

**Phase to address:**
Phase 4-5 (Faceting) - Complex feature requiring solid foundation. Defer until core geoms, scales, and coords work perfectly.

---

### Pitfall 10: Legend Generation Without Scales

**What goes wrong:**
Generating legends requires reverse-mapping from aesthetic values back to data values. Developer tries to create legends from layer data alone, but can't determine which aesthetic mappings should appear in legend, how to merge legends for multiple layers, or what order to show legend keys.

**Why it happens:**
ggplot2's legend system is complex: it extracts scale guides, merges compatible legends, applies breaks/labels from scales, handles continuous vs discrete differently. The information isn't in the layer data - it's in the scales and guide specifications. Simply listing unique colors doesn't produce correct legend.

**How to avoid:**
- Extract scale guide information from ggplot_build()$plot$scales
- Store aesthetic mappings (not just values) in IR
- Implement legend merging logic (combine color + size into one legend)
- Handle legend positioning (right, left, top, bottom, inside)
- Support guide_legend() vs guide_colorbar() distinctions
- Test with: multiple aesthetics, overlapping legends, custom breaks, no legend

**Warning signs:**
- Legends show internal factor levels instead of formatted labels
- Multiple legends when ggplot2 shows one
- Legend order differs from ggplot2
- Legend keys don't match actual colors/sizes in plot
- Continuous legends show discrete colors

**Phase to address:**
Phase 5-6 (Legends) - High priority for usability but depends on scales working correctly. Major undertaking requiring 2-3 weeks.

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Hardcoding theme_gray colors instead of extracting theme | Fast initial implementation | Breaks with custom themes, hard to extend | MVP only - must be refactored |
| Using ggplot_build() computed data for stat layers | Avoid implementing stat algorithms | Loses interactivity, can't update with new data | Acceptable for static-only MVP |
| Converting all scales to linear in D3 | Simplifies scale logic | Breaks log scales, date scales, custom trans | Never acceptable - causes wrong math |
| Skipping scale expansion | Fewer calculations | Visual mismatch, data touches axes | Never acceptable - breaks visual parity |
| Using `:first-child` for all z-ordering | Simple rendering order | Fragile when adding new elements | Acceptable short-term, needs proper layering system |
| Monolithic as_d3_ir() function | Fast development | Hard to test/maintain individual components | Acceptable during prototyping, refactor for Phase 2 |
| Vendoring D3.v7 instead of using CDN | Works offline, version pinned | Security patches require manual update | Acceptable - security over convenience |
| No input validation on IR | Faster IR generation | Cryptic errors in JavaScript | Never acceptable - add validation before Phase 1 complete |

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| htmlwidgets sizing | Hardcoding width/height in SVG | Use htmlwidgets resize mechanism, dynamic viewBox |
| RStudio Viewer | Assuming full browser features | Test in RStudio Viewer (limited HTML/CSS support) |
| R Markdown output | Assuming JavaScript always runs | Handle non-interactive contexts (PDF/Word output) |
| Shiny integration | Not handling reactive updates | Implement renderValue() to handle data updates |
| ggplot_build() timing | Extracting before build completes | Always call ggplot_build() explicitly, don't rely on print method |
| Theme extraction | Accessing theme before plot complete | Use calc_element() after ggplot_build() to get resolved theme |
| Scale limits | Extracting training data | Use trained scale objects from built plot, not raw data |

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Re-rendering entire SVG on resize | Slow resize, flashing | Implement update pattern with D3 selections, only re-scale | >500 points |
| Extracting aesthetics per data point in loop | Slow rendering with large data | Pre-compute aesthetic arrays before rendering | >1000 points |
| Creating D3 scales for every layer | Redundant scale objects | Create scales once, reuse for all layers | >10 layers |
| No data filtering before render | Rendering null/NA values | Filter data in preprocessing step | Any nulls |
| Repeated DOM queries | Slow layer rendering | Cache D3 selections (.select() is expensive) | >50 layers |
| Converting factors repeatedly | Slow IR generation | Convert factors once in to_rows() | >10,000 rows |
| Deep theme object access | Slow theme application | Flatten theme into lookup object | Every render |

## Security Mistakes

| Mistake | Risk | Prevention |
|---------|------|------------|
| No validation on IR JSON structure | Malformed IR crashes JavaScript | Add JSON schema validation before passing to widget |
| Unescaped text in SVG labels | SVG injection attack | Use D3's `.text()` not `.html()`, never use innerHTML |
| No size limits on data | Browser memory exhaustion | Warn or error on >10,000 points, document limits |
| Eval-ing user expressions | Code injection if user controls plot code | Never use eval() on user input, only on trusted ggplot objects |
| Exposing internal R objects | Information leakage | Serialize only necessary data to IR, not full ggplot object |

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| Cryptic JavaScript errors in console | User sees blank plot, no idea why | Catch errors, show friendly message in plot area with troubleshooting |
| Silent rendering failures | Plot looks wrong but no warning | Log warnings for unsupported features, show placeholder |
| Inconsistent sizing across outputs | Plot looks different in RStudio vs browser | Document size behavior, provide ggpreview() helper |
| No loading indicator | User thinks plot is broken during render | Show "Rendering..." spinner for complex plots |
| Tooltips that hide data | Hovering blocks view of other points | Use semi-transparent tooltips, position away from cursor |
| Missing feature with no message | User expects legend, plot just missing it | Add text annotation "Legend not yet supported" for unsupported features |

## "Looks Done But Isn't" Checklist

- [ ] **Coordinate flip:** Axes swap but are on wrong sides - verify axis positioning, not just scale swap
- [ ] **Theme translation:** Colors match but spacing wrong - verify margins, padding, and expansion match ggplot2
- [ ] **Bar charts:** Work with positive data but fail with negative - test diverging bars, zero baseline
- [ ] **Point colors:** Mapped colors work but default colors wrong - verify geom default color extraction
- [ ] **Categorical axes:** Labels show but don't match factor order - test with reordered factors, dropped levels
- [ ] **Grid lines:** Visible but wrong thickness - verify mm→px conversion matches ggplot2
- [ ] **Text size:** Readable but not matching ggplot2 - verify pt→px conversion at 96 DPI
- [ ] **Line smoothness:** Looks smooth but wrong algorithm - verify same stat computation as ggplot2
- [ ] **Facets:** Multiple panels render but spacing wrong - verify panel layout math matches ggplot2
- [ ] **Legends:** Keys show but merged wrong - verify legend merging logic for multiple aesthetics

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Hardcoded unit conversions | MEDIUM | Create constants file, find/replace all instances, add tests |
| Private API breaks | HIGH | Fork function locally, submit PR to ggplot2, maintain compatibility shim |
| Wrong stat computation | HIGH | Re-implement stat in JavaScript from ggplot2 source, extensive testing |
| Scale expansion missing | LOW | Add expansion calculation, test against ggplot2 output |
| Color translation wrong | LOW | Add color mapping table, convert to hex in IR generation |
| Sub-pixel blurriness | LOW | Add Math.round() to line positioning, test cross-browser |
| Monolithic IR function | MEDIUM | Refactor into modular functions, add unit tests for each |
| No facet support | HIGH | Complete redesign of rendering pipeline for panel layout |
| Legend system missing | HIGH | Extract guide data, implement legend rendering from scratch |
| Coord flip broken | MEDIUM | Restructure D3 rendering to reposition axes based on coord type |

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| Unit conversion inconsistencies | Phase 1 (Foundation) | Visual diff tests comparing line widths, point sizes |
| Private API dependency | Phase 1 (Foundation) | CI tests against multiple ggplot2 versions |
| Statistical transformation trap | Phase 3-4 (Stat layers) | Compare computed variables against ggplot2 build data |
| Coordinate system complexity | Phase 2 (Coordinate systems) | Test suite with all coord variants, visual regression |
| Scale expansion mismatch | Phase 1 (Foundation) | Measure data-to-axis distance, compare to ggplot2 |
| Discrete scale mapping | Phase 1 (Foundation) | Test with unusual factor scenarios, unused levels |
| Color name translation | Phase 1 (Foundation) | Test suite with all R color names, grey variations |
| SVG sub-pixel blur | Phase 2 (Polish) | Visual inspection across browsers, automated screenshot comparison |
| Facet data structure | Phase 4-5 (Faceting) | Compare panel positions and axes with ggplot2 output |
| Legend generation | Phase 5-6 (Legends) | Compare legend layout and content with ggplot2 |

## Sources

### ggplot2 Translation Research
- [Reproducing a Mike Bostock d3.js Specialty with ggplot2](https://daranzolin.github.io/2018-05-11-ages-ggplot/) - Domain knowledge about translation challenges
- [GitHub - johnjosephhorton/gg2d3](https://github.com/johnjosephhorton/gg2d3) - Prior art in this domain

### R Graphics and SVG Rendering
- [Superior svg graphics rendering in R, and why it matters](https://ropensci.org/blog/2020/05/28/rsvg2/) - SVG rendering in R ecosystem
- [Why Is My SVG Blurry? Fixing Common SVG Rendering Issues](https://www.svggenie.com/blog/svg-blurry-fixes) - Sub-pixel rendering pitfalls
- [Scaling Issues - svglite vignette](https://cran.r-project.org/web/packages/svglite/vignettes/scaling.html) - Unit conversion in R SVG output

### ggplot2 Internals
- [ggplot2 Changelog](https://ggplot2.tidyverse.org/news/index.html) - Breaking changes in ggplot2 versions
- [ggplot2 3.4.0 release notes](https://tidyverse.org/blog/2022/11/ggplot2-3-4-0/) - Internal API changes
- [Using ggplot2 in packages](https://cran.r-project.org/web/packages/ggplot2/vignettes/ggplot2-in-packages.html) - API stability guidance

### Unit Conversion and DPI
- [Understanding text size and resolution in ggplot2](https://www.christophenicault.com/post/understand_size_dimension_ggplot2/) - DPI and unit conversion details
- [Taking Control of Plot Scaling](https://tidyverse.org/blog/2020/08/taking-control-of-plot-scaling/) - ggplot2 sizing system

### Coordinate Systems
- [coord_flip documentation](https://ggplot2.tidyverse.org/reference/coord_flip.html) - Coordinate flipping behavior
- [Coord_flip also flip the axes side - Issue #1784](https://github.com/tidyverse/ggplot2/issues/1784) - Known coordinate flip issues

### Scale Systems
- [Generate expansion vector for scales](https://ggplot2.tidyverse.org/reference/expansion.html) - Scale expansion defaults
- [Position scales for continuous data](https://ggplot2.tidyverse.org/reference/scale_continuous.html) - Scale expansion behavior

### Statistical Transformations
- [Layer statistical transformations](https://ggplot2.tidyverse.org/reference/layer_stats.html) - Stat layer documentation
- [Statistical summaries chapter](https://ggplot2-book.org/statistical-summaries.html) - Computed variables system

### Faceting
- [facet_grid documentation](https://ggplot2.tidyverse.org/reference/facet_grid.html) - Grid layout specification
- [facet_wrap documentation](https://ggplot2.tidyverse.org/reference/facet_wrap.html) - Wrap layout specification
- [Faceting chapter](https://ggplot2-book.org/facet.html) - Faceting system deep dive

### Visual Testing
- [vdiffr: Visual Regression Testing](https://vdiffr.r-lib.org/) - Pixel-perfect testing for R graphics
- [vdiffr 0.3.0 announcement](https://www.tidyverse.org/blog/2019/01/vdiffr-0-3-0/) - SVG-based visual comparison

### Codebase-Specific
- `/Users/davidzenz/R/gg2d3/vignettes/d3-drawing-diagnostics.md` - Current known issues
- `/Users/davidzenz/R/gg2d3/.planning/codebase/CONCERNS.md` - Technical debt and bugs
- `/Users/davidzenz/R/gg2d3/THEME_IMPLEMENTATION.md` - Theme extraction implementation
- `/Users/davidzenz/R/gg2d3/GEOM_DEFAULTS_SUMMARY.md` - Geom defaults implementation

---
*Pitfalls research for: ggplot2-to-D3.js translation*
*Researched: 2026-02-07*
