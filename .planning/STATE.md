# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-02-07)

**Core value:** Any ggplot2 plot should render identically in D3 — same visual output, but now interactive and web-native.

**Current focus:** Phase 6 - Layout Engine (next up)

## Current Position

Phase: 6 of 11 (Layout Engine)
Plan: 0 of 4 in Phase 6
Status: Not started
Last activity: 2026-02-09 — Completed Phase 5 (Statistical Geoms)

Progress: [████░░░░░░] 43% (22/51 plans complete)

## Performance Metrics

**Velocity:**
- Total plans completed: 22
- Average duration: ~10.2 min
- Total execution time: ~3.7 hours

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 01-foundation-refactoring | 5/5 | 70.4 min | 14.1 min |
| 02-core-scale-system | 3/3 | ~20 min | ~6.7 min |
| 03-coordinate-systems | 3/3 | ~22 min | ~7.3 min |
| 04-essential-geoms | 4/4 | ~80 min | ~20 min |
| 05-statistical-geoms | 4/4 | ~22 min | ~5.5 min |

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

Last session: 2026-02-09
Stopped at: Phase 5 complete. All statistical geoms implemented and verified.
Resume file: .planning/phases/05-statistical-geoms/05-04-SUMMARY.md
Next action: Plan and execute Phase 6 (Layout Engine).

---
*State initialized: 2026-02-07*
*Phase 1 completed: 2026-02-07*
*Phase 2 completed: 2026-02-08*
*Phase 3 completed: 2026-02-08*
*Phase 4 started: 2026-02-08*
*Phase 4 completed: 2026-02-09*
*Phase 5 started: 2026-02-09*
*Phase 5 completed: 2026-02-09*
