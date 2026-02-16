# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-02-07)

**Core value:** Any ggplot2 plot should render identically in D3 — same visual output, but now interactive and web-native.

**Current focus:** All 11 phases complete. Project milestone achieved.

## Current Position

Phase: 11 of 11 (Advanced Interactivity) — COMPLETE
Plan: 4 of 4 in Phase 11
Status: Complete
Last activity: 2026-02-16 — Completed 11-04 (Testing + Visual Verification).

Progress: [██████████] 100% (45/45 plans complete)

## Performance Metrics

**Velocity:**
- Total plans completed: 41
- Average duration: ~10 min
- Total execution time: ~7.08 hours

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 01-foundation-refactoring | 5/5 | 70.4 min | 14.1 min |
| 02-core-scale-system | 3/3 | ~20 min | ~6.7 min |
| 03-coordinate-systems | 3/3 | ~22 min | ~7.3 min |
| 04-essential-geoms | 4/4 | ~80 min | ~20 min |
| 05-statistical-geoms | 4/4 | ~22 min | ~5.5 min |
| 06-layout-engine | 3/3 | 19 min | 6.3 min |
| 07-legend-system | 4/4 | ~30 min | ~7.5 min |
| 08-basic-faceting | 4/4 | 10 min | 2.5 min |
| 09-advanced-faceting | 4/4 | 159 min | 39.75 min |
| 10-interactivity-foundation | 3/3 | 22 min | 7.3 min |
| 11-advanced-interactivity | 4/4 | 188 min | 47 min |

*Updated after each plan completion*

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting current work:

- Geom coverage before visual polish — User priority; broader coverage unlocks more use cases
- Legends early, facets later — Legends needed to verify geom rendering; facets are more complex
- Pipe-based interactivity API — Composable like ggplot layers: `gg2d3(p) |> d3_tooltip() |> d3_link()`
- Pixel-perfect fidelity target — R community expects professional output matching ggplot2

**From Phase 1:**

| Decision ID | Title | Rationale | Impact |
|-------------|-------|-----------|--------|
| namespace-pattern | Use window.gg2d3 namespace for module exports | HTMLWidgets loads scripts in order; global namespace enables module communication | All future modules follow this pattern |
| theme-deep-merge | Theme module uses deep merge for user overrides | Nested objects merge at all levels | Enables partial theme customization |
| helpers-in-constants | Shared utilities in constants.js | Avoids duplication across modules | All modules share utilities via window.gg2d3.helpers |
| geom-dispatch-pattern | Registry-based dispatch for geom rendering | Enables adding new geoms without modifying core | Self-contained geom modules |
| validate-before-js | Validate IR in R before JavaScript | Catch errors early with clear R messages | Better developer experience |

**From Phase 2:**

| Decision ID | Title | Rationale | Impact |
|-------------|-------|-----------|--------|
| transform-first-dispatch | Transform field takes priority over type in scale factory | Ensures {type: "continuous", transform: "log10"} creates log scale | All scale creation checks transform before type |
| ir-breaks-as-ticks | Use IR breaks instead of D3 auto-generated ticks | D3's auto ticks don't match ggplot2 breaks | Axis ticks match ggplot2 exactly |
| panel-params-domains | Use ggplot2's panel_params for pre-computed domains | Replaces hardcoded 5% expansion; ggplot2 already computes correct expansion | Scale domains always match ggplot2 |
| dependency-based-modules | HTMLWidgets modules via dependency entry, not script array | Script array only copies binding file, not subdirectories | All modules correctly loaded in HTML output |
| band-scale-centering | Offset band scale positions by bandwidth/2 | D3 band scales return left edge; ggplot2 centers everything | Grid/geom alignment matches ggplot2 |
| axis-at-panel-bottom | X-axis always at panel bottom (y=h) | ggplot2 doesn't move axis to y=0 | Consistent axis positioning |

**From Phase 3:**

| Decision ID | Title | Rationale | Impact |
|-------------|-------|-----------|--------|
| r-side-label-swap | Swap axis labels in R IR for coord_flip | JS always renders x-label at bottom, y-label at left; R handles the swap | Simplifies D3 rendering code |
| xy-specific-theme-fallback | Extract axis.text.x/y etc. with fallback to generic | Enables per-axis styling while maintaining backward compat | x/y theme elements work end-to-end |
| data-range-aware-aspect | Panel aspect uses ratio * (yRange/xRange) for coord_fixed | Matches ggplot2 behavior where ratio=1 means equal pixel length per data unit | Correct panel sizing for unequal data ranges |
| stored-ir-resize | Store IR in currentIR for resize redraw | Enables responsive widget behavior | Resize recalculates panel while maintaining aspect ratio |
| unswap-panel-params | Un-swap coord_flip panel_params in R to realign with scales | ggplot_build swaps panel_params x↔y but not panel_scales or data | Correct breaks/domains for all coord_flip plots |
| flip-via-options | Pass flip flag to geom renderers via options object | Each geom needs to swap scale-to-attribute mapping | All 5 geom types support coord_flip |

**From Phase 4:**

| Decision ID | Title | Rationale | Impact |
|-------------|-------|-----------|--------|
| reference-line-data-in-rows | Reference line position data stored in layer data rows | ggplot_build() computes reference line positions as data frame columns, not params | JS renderers read position from data rows, not layer.params |
| placeholder-geom-modules | Create placeholder JS modules that register but return 0 | Prevents widget load errors before Wave 2 implements actual rendering | All Phase 4 geoms can be added to IR/validation/YAML immediately |
| area-baseline-calculation | Calculate area baseline as: zero if in domain, else domain min | Matches ggplot2 behavior for non-stacked areas | Area geom renders with correct baseline |
| area-vs-ribbon-distinction | Area uses baseline, ribbon always uses ymin/ymax from data | Reflects ggplot2's semantic difference between the two geoms | Clear separation of concerns between area and ribbon renderers |
| svg-line-elements-for-segments | Use SVG line elements (not path) for segment/reference geoms | Segments and reference lines are single line elements, not multi-point paths | More semantic and efficient than path elements for two-point lines |
| linetype-to-dasharray | Convert ggplot2 linetype to SVG stroke-dasharray | Maps linetype names and integers to corresponding dash patterns | Reference lines support all ggplot2 linetype options |
| panel-clip-path | SVG clipPath on panel group clips geom elements to panel bounds | abline and other geoms can extend beyond panel; clip prevents visual overflow | All geoms render within panel area |
| convert-r-colors-everywhere | Use convertColor() for all R color names in geom renderers | R colors like "grey50" are not valid CSS; must convert to hex | Consistent color rendering across all geoms |
| gClipped-after-grid | Create clipped data group after grid lines for correct z-order | SVG renders later children on top; grid must be below data layers | Grid behind data, data behind axes |

**From Phase 5:**

| Decision ID | Title | Rationale | Impact |
|-------------|-------|-----------|--------|
| smooth-dedicated-geom | Map GeomSmooth to 'smooth' (not 'path') | geom_smooth produces fitted line + confidence ribbon; needs dedicated renderer | Wave 2 smooth renderer can draw line and ribbon separately |
| list-column-serialization | Add I() wrapper for list-columns in inner to_rows() | Boxplot outliers are list-column with vector per row; without I(), lists flatten/drop | Outliers serialize correctly to JSON arrays |
| placeholder-stat-geoms | Create no-op placeholder modules for stat geoms | Prevents widget load errors before full implementations | Incremental development, package loads cleanly |
| density-two-path-rendering | Density renders both fill and stroke as two separate SVG paths | GeomDensity extends GeomArea but adds visible outline; two paths (area + line) achieves this | Density curves have clear borders unlike basic area geoms |
| smooth-opaque-line | Smooth line always fully opaque (opacity 1.0) regardless of ribbon transparency | In ggplot2, geom_smooth line always opaque even when confidence band has alpha < 1.0 | Fitted line clearly visible against semi-transparent ribbon |
| smooth-thick-linewidth | Smooth default linewidth 1mm (2.85px) thicker than regular lines (0.5mm) | ggplot2 default for geom_smooth emphasizes fitted curve over raw data | Smooth lines stand out from raw data lines |
| ggplot-pt-linewidth | Use ggplot2 .pt factor (72.27/25.4) for linewidth conversion | ggplot2 uses .pt not CSS PX_PER_MM; CSS factor renders ~33% too thick | All geoms render correct line thickness |
| boxplot-xmin-xmax-width | Calculate box width from xmin/xmax data columns | ggplot_build pre-computes xmin/xmax from width param; d.width doesn't exist | geom_boxplot(width=0.1) works correctly for overlay plots |
| no-default-staples | No whisker endcaps by default | ggplot2 default staple.width=0 means no endcaps | Boxplots match ggplot2 appearance |

**From Phase 6:**

| Decision ID | Title | Rationale | Impact |
|-------------|-------|-----------|--------|
| estimation-based-layout | Use font-size-based text estimation instead of DOM measurement | Layout engine must be pure function; estimation is fast and accurate enough for typical numeric labels | calculateLayout() has no DOM dependency, can run before rendering |
| secondary-axis-detection | Detect secondary axes via scale.secondary.axis field, not panel_params | panel_params always has .sec ViewScale objects; only scales with actual secondary.axis are enabled | Correctly reserves space only when secondary axes are present |
| legend-space-zero-default | Legend width/height default to 0 until Phase 7 | Prevents empty gaps when legend rendering doesn't exist yet | No visual changes in Phase 6; space reserved when Phase 7 provides dimensions |
| layout-single-source-truth | Layout engine is sole source of positioning data for all components | Eliminates scattered calculations, magic numbers, and hardcoded offsets throughout codebase | All rendering code reads positions from layout object; easier debugging and maintenance |

**From Phase 7:**

| Decision ID | Title | Rationale | Impact |
|-------------|-------|-----------|--------|
| shape-fill-vs-stroke | Filled shapes use fill, open shapes use stroke | ggplot2 shape codes 0-5 are open (stroke only), 15-19 are filled | Legend shape rendering matches ggplot2 visual appearance |
| colorbar-gradient-direction | Colorbar gradient goes bottom-to-top | ggplot2 colorbars render low values at bottom, high at top | SVG linearGradient y1=100% to y2=0% for correct orientation |
| merged-guide-aesthetics | Single guide can represent multiple aesthetics | ggplot2 merges guides when guides(colour = guide_legend()) specified | renderDiscreteLegend checks guide.aesthetics array and combines symbols |
| get-guide-data-extraction | Use ggplot2::get_guide_data() for guide extraction | ggplot2 already computes all legend keys, labels, and aesthetic values through guide training | All guide extraction delegates to ggplot2; gg2d3 only serializes to IR |
| colorbar-30-stops | Generate 30 interpolated color stops for continuous colorbars | get_guide_data() returns breaks (~5 values); smooth gradients need more stops to avoid banding | Colorbar guides include colors array with 30 hex values for SVG gradients |

**From Phase 8:**

| Decision ID | Title | Rationale | Impact |
|-------------|-------|-----------|--------|
| skip-coord-fixed-facets | Skip coord_fixed when faceted | ggplot2 doesn't support coord_fixed with facets | Layout engine skips aspect ratio constraint when isFaceted is true |
| panel-bbox-for-axes | Panel bounding box spans full grid for axis label centering | Axis labels need to center across entire facet grid, not individual panels | Panel updated to union of all panel positions after grid calculation |
| strip-above-panels | One strip row per panel row, positioned above panels | Matches ggplot2 facet_wrap layout pattern | Strip y = panel.y - stripHeight for each panel |

**From Phase 9:**

| Decision ID | Title | Rationale | Impact |
|-------------|-------|-----------|--------|
| row-col-separate-vars | Row and column faceting variables stored separately | facet_grid(cyl ~ am) has distinct row vars and col vars, unlike facet_wrap which has single vars array | JavaScript rendering can position row strips (right) and col strips (top) independently |
| scales-mode-from-free-params | Derive scales mode from free$x and free$y boolean params | ggplot2 stores free scales as list(x=TRUE/FALSE, y=TRUE/FALSE), not as single 'fixed'/'free' string | Map boolean combinations to strings: fixed, free_x, free_y, free for IR clarity |
| concatenated-multi-var-labels | Multi-variable strip labels concatenated with ', ' separator | Phase 9 scope is basic facet_grid support; hierarchical/nested strip layout deferred to future phase | facet_grid(a + b ~ c) produces strip labels like '4, 0' not nested strips |
| separate-wrap-grid-calculations | Separate layout calculations for facet_wrap and facet_grid | facet_grid has different strip positioning (top/right) vs facet_wrap (top only) | Clear code separation, easier to maintain distinct layout patterns |
| strip-width-equals-height | Row strip width equals column strip height for rotated text | Rotated text's visual width equals text height; same font size for both | Consistent visual weight for row and column strips |
| panel-area-subtraction | Subtract strip dimensions from available area before panel calculation | Reserve space for strips first, then divide remaining area by panel count | Correct panel sizing that accounts for strip space |
- [Phase 09-advanced-faceting]: Visual verification confirms facet_grid rendering matches ggplot2 for all test cases
- [Phase 09-advanced-faceting]: 11 unit tests cover IR structure, strips, SCALE_X/SCALE_Y, free scales, multi-variable facets, missing combos, backward compat

**From Phase 10:**

| Decision ID | Title | Rationale | Impact |
|-------------|-------|-----------|--------|
| class-based-event-selectors | Use class-based selectors (.geom-point) instead of broad element selectors (circle) | Broad selectors attached tooltips to all circles/rects including structural elements without bound data; class-based selectors ensure only data elements get interactivity | Event handlers only target geom elements with data |
| d3-event-namespacing | Use D3 event namespacing (.tooltip, .hover) to prevent handler clobbering | Both tooltip and hover use mouseover/mouseleave events; without namespacing, second handler replaces first | Multiple interactivity features can coexist on same elements |
| visual-verify-checkpoints | Visual verification checkpoints catch rendering bugs unit tests miss | Unit tests verify structure correctness but can't detect DOM event targeting issues or browser behavior | Human-verify checkpoints essential for browser-based features |

**From Phase 11:**

| Decision ID | Title | Rationale | Impact |
|-------------|-------|-----------|--------|
| scale-rescale-not-transform | Use scale rescaling instead of SVG transform for zoom | SVG transform would scale stroke widths and other properties; rescaling scales and repositioning elements preserves visual fidelity | More complex implementation but maintains pixel-perfect rendering |
| synchronized-facet-zoom | Synchronized zoom across all facet panels | Users expect coherent exploration across facets; independent zoom would be confusing | All panels zoom together when any panel is zoomed |
| geom-specific-repositioning | Geom-specific element repositioning logic for zoom | Different geom types store position data differently (cx/cy vs x/y vs d attribute) | Each geom type has dedicated repositioning code in zoom.js |
| crosstalk-graceful-degradation | Check for crosstalk library existence before use | Static HTML may not include crosstalk; code must work without it | All crosstalk code guards with typeof checks for graceful degradation |
| shiny-mode-guards | Guard Shiny code with HTMLWidgets.shinyMode check | Prevents errors in static HTML context where Shiny is not available | Shiny message handlers only register when in Shiny mode |
| crosstalk-index-to-key-mapping | Map data indices to crosstalk keys for SelectionHandle | JavaScript iterates data-bound elements by index; SelectionHandle needs keys | Passed keyArray from R enables index-to-key lookup for highlighting |

### Pending Todos

None.

### Pre-existing Issues (from Phase 1 verification)

- ~~**coord_flip rendering broken** — Axes on wrong sides after flip (Phase 3, Plan 03-01)~~ FIXED in 03-01
- **rect geom out of bounds / grid issues** — rect/tile edge cases with rendering (Phase 3)

### Blockers/Concerns

**Phase 1 (Foundation) — COMPLETE**
**Phase 2 (Scales) — COMPLETE**
**Phase 3 (Coordinates) — COMPLETE**
**Phase 4 (Essential Geoms) — COMPLETE**
**Phase 5 (Statistical Geoms) — COMPLETE**

**Remaining concerns:**
- Monolithic as_d3_ir() function (~380 lines) needs modularization before adding features
- Private API dependency on ggplot2:::calc_element() creates fragility
- ggplot2 private API usage may break on updates (mitigation: wrap in try-catch)
- Facet layout complexity (Phase 8-9)

## Session Continuity

Last session: 2026-02-16
Stopped at: Phase 11 complete. All phases done.
Resume file: .planning/phases/11-advanced-interactivity/11-04-SUMMARY.md
Next action: Project milestone complete. Consider /gsd:audit-milestone.

---
*State initialized: 2026-02-07*
*Phase 1 completed: 2026-02-07*
*Phase 2 completed: 2026-02-08*
*Phase 3 completed: 2026-02-08*
*Phase 4 started: 2026-02-08*
*Phase 4 completed: 2026-02-09*
*Phase 5 started: 2026-02-09*
*Phase 5 completed: 2026-02-09*
*Phase 6 completed: 2026-02-09*
*Phase 7 completed: 2026-02-09*
