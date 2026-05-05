# Phase 14: Color Fidelity — Context

**Gathered:** 2026-05-05
**Status:** Ready for planning

<domain>
## Phase Boundary

Closes COLOR-01 and COLOR-02 from `.planning/REQUIREMENTS.md`. Specifically:

1. **COLOR-01** — ggplot2 color/fill scales (viridis, brewer, manual) render in D3 with hex codes that match `ggplot_build()`'s resolved colors *char-for-char*.
2. **COLOR-02** — Plots with continuous color render a colorbar legend (gradient + ticks), not a discrete-key fallback.
3. Discrete legends from v1.0 keep working — no regression.

Phase 13 already shipped clean per-concern extractors (`R/ir_scales.R`, `R/ir_legends.R`) and the JS side already has a `linearGradient` colorbar renderer in `inst/htmlwidgets/modules/legend.js`. This phase fills the *gaps* between that infrastructure and the requirement.

</domain>

<decisions>
## Implementation Decisions

### Gap focus (what this phase actually fixes)
- **D-01:** Phase 14 closes three concrete gaps simultaneously: (a) per-row hex parity for viridis/brewer/manual palettes, (b) the continuous-color → colorbar trigger correctly firing instead of falling back to discrete keys, (c) colorbar quality (ticks, labels, orientation, title placement) matching ggplot2.
- **D-02:** Researcher's first task is to render a corpus and produce a concrete defect list per scale type; planner uses that list to decide the per-plan task split. No assumption that all three gaps require equal work.

### Fidelity contract
- **D-03:** "Identical hex codes" for COLOR-01 means **exact string equality** between the rendered DOM's `fill`/`stroke` attributes and `ggplot_build()`'s resolved color column. No color-distance tolerance, no perceptual delta. Char-for-char.
- **D-04:** Source of truth is the per-row resolved-color column from `ggplot_build()` for layer marks, and `scale_obj$map(scale_obj$breaks)` for legend swatches/colorbar stops. Both are exposed via the post-Phase-13 extractors.

### Scale scope (what's in)
- **D-05:** In scope: `scale_*_viridis_c`, `scale_*_viridis_d`, `scale_*_brewer`, `scale_*_distiller`, `scale_*_manual` (named and unnamed values vectors), `scale_*_steps` / `scale_*_binned`.
- **D-06:** Steps/binned legends render as a **banded colorbar** (matches ggplot2's `guide_coloursteps` — single rectangle with hard color stops at bin boundaries, no smooth gradient). Same orientation/sizing as the continuous colorbar.
- **D-07:** `scale_*_gradient`, `scale_*_gradient2`, `scale_*_gradientn` are *not* explicitly listed in the roadmap but are the building blocks the others use; if research shows they fall out for free with viridis_c fixes, ship them. Otherwise defer.

### Colorbar quality
- **D-08:** Colorbar ticks mirror `guide_colorbar()` exactly — pull `breaks` and `labels` from the scale object (already extracted in `R/ir_scales.R`) rather than letting `d3.axisRight` generate its own ticks. This keeps tick count, positions, and label formatting in lockstep with ggplot2.
- **D-09:** Existing 30-stop gradient sampling in `R/ir_legends.R:108` is a starting point; researcher must verify 30 stops produces visually smooth output across viridis/brewer continuous palettes. If banding visible, increase. Final stop count is Claude's discretion.
- **D-10:** Legend title, orientation (vertical default, horizontal when `legend.position` is top/bottom), and sizing follow ggplot2's defaults from the theme — no new theme APIs introduced this phase.

### Edge cases (locked in)
- **D-11:** **NA values** must render with the scale's `na.value` (default `"grey50"`). Verified by a snapshot test that includes a row with `NA` in the color/fill aesthetic.
- **D-12:** **Both `scale_color_*` and `scale_fill_*` in the same plot** must produce two correct legends with no overlap and no shared-state bugs. Verified by a snapshot test combining them.
- **D-13:** **Alpha-resolved fills** — when `aes(alpha = ...)` is resolved into the fill column by `ggplot_build()`, the resulting RGBA hex (e.g. `#FF000080`) must round-trip identically to the DOM. Don't strip the alpha byte.
- **D-14:** **Out-of-range factor levels** in `scale_*_manual(values = c(...))` map to NA color in ggplot2 (NULL in `values_resolved`); D3 must match — same `na.value` rendering as D-11.

### Verification strategy
- **D-15:** Test artifact: `tests/testthat/_snaps/color/<plot-id>.json` per plot, containing `{expected_hex_per_row, expected_legend_hex}`. Use `testthat`'s built-in snapshot machinery for diffing/updating. NOT a PNG visual diff — those are deferred to a later phase if needed.
- **D-16:** Test corpus is **one geom per scale variant**: `geom_point` against each of `viridis_c`, `viridis_d`, `brewer` (discrete), `distiller` (continuous), `manual` (named), `manual` (unnamed), `steps` / `binned`. ~7–8 snapshots. Plus the four edge cases (D-11–D-14) as additional dedicated snapshots.
- **D-17:** Each snapshot test renders via the existing pipeline, walks the DOM (using the same approach as v1.0's `test-legends.R`) to extract `fill`/`stroke` attributes, and compares to the snapshot. The snapshot file is committed; updates require explicit `testthat::snapshot_accept()`.

### Claude's Discretion
- Final gradient stop count (D-09 ceiling: bumped if research finds banding).
- Number of ticks on the colorbar — driven by ggplot2's pretty-break logic but actual rendering math is implementation detail.
- Whether to share rendering code between continuous (smooth) and binned (banded) colorbars or split them — both produce a `linearGradient` SVG primitive; banded just uses 2 stops per bin instead of N over a domain.
- Whether color extraction lives in `R/ir_scales.R` or a new `R/ir_colors.R`. Default: extend `R/ir_scales.R` (color is conceptually a scale concern); split only if file grows past Phase 13's size envelope.
- Per-row layer color flow is already correct (`ggplot_build()` resolves; `R/ir_layers.R` passes the `colour`/`fill` columns through). Confirm this in research; if it's actually a passthrough hole, planner adds a fix task.

</decisions>

<specifics>
## Specific Ideas

- ggplot2's `guide_colorbar()` is the visual reference for colorbar look. When in doubt about layout, render the same plot in ggplot2 and match.
- The existing `R/ir_legends.R:101–122` colorbar branch and `inst/htmlwidgets/modules/legend.js:424–520` gradient renderer are starting points, not throwaways — keep them and fill in gaps. New code only where the gap demands it.
- v1.0 visual baseline: the user-approved Phase 13 visual corpus (`test_output/phase13/`) renders discrete legends correctly. Use those as regression references for "discrete legends still work".

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase boundary and requirements
- `.planning/REQUIREMENTS.md` — COLOR-01, COLOR-02 acceptance criteria
- `.planning/ROADMAP.md` §"Phase 14: Color Fidelity" — success criteria 1–4

### Existing implementation (post-Phase-13)
- `R/ir_scales.R` — color scale extraction (`scales$color` block at line 296), `map_discrete`, `get_scale_info` helpers
- `R/ir_legends.R` — colorbar branch lines 101–122, builds `colors_array` via `scale_obj$map(seq(domain[1], domain[2], length.out = 30))`
- `R/ir_layers.R` lines 92–94 — per-row `colour`/`fill` passthrough into IR
- `inst/htmlwidgets/modules/legend.js:166` — colorbar guide-type dispatch
- `inst/htmlwidgets/modules/legend.js:424–520` — `linearGradient` rendering, ticks, labels
- `inst/htmlwidgets/gg2d3.js:79–101` — colorScale wiring on the JS side from `ir.scales.color`

### Test references
- `tests/testthat/test-ir-legends.R` — Phase 13 added 5 assertions covering legend extraction
- `tests/testthat/test-legends.R` — v1.0 discrete legend tests (regression baseline)

### Phase 13 takeaways (relevant)
- `.planning/phases/13-internals-refactor/13-RESEARCH.md` — Pitfall 1 (`keep_aes` lift) is relevant if color extraction needs an aesthetic-name list
- `.planning/phases/13-internals-refactor/13-VERIFICATION.md` — confirms `R/ir_*.R` modules are the right home for new color logic

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `R/ir_scales.R::map_discrete` — already handles factor → integer index mapping; usable for any palette that goes via discrete domain.
- `R/ir_scales.R` `scales$color` block (line 296) — already reads `colour` columns from layer data; extension point for `fill` and for stashing `breaks`/`labels` for the colorbar.
- `R/ir_legends.R` colorbar branch — already produces `colors_array`; needs `breaks`, `labels`, `title` siblings for tick rendering.
- `inst/htmlwidgets/modules/legend.js` `renderColorbar` (around line 424) — already produces a `linearGradient` rectangle with axis; takes guide IR.

### Established Patterns
- Per-concern extractor pattern (Phase 13): a single `extract_<concern>_ir(b, ...)` function returns a list, orchestrator wires it in. New color logic follows the same shape if it needs its own module.
- Snapshot tests via `testthat::expect_snapshot_value()` — already used elsewhere; new color snapshots fit cleanly.
- DOM-walk verification — `tests/testthat/test-legends.R` already extracts attributes from the rendered SVG; reuse that pattern for hex assertions.

### Integration Points
- `R/ir_scales.R` (extend `scales$color` block) — add `breaks`, `labels`, `title`, `na.value`, `is_continuous`, `is_steps` fields.
- `R/ir_legends.R` colorbar branch — pass through new fields; downstream JS reads them for tick rendering and banded-vs-smooth gradient choice.
- `inst/htmlwidgets/modules/legend.js::renderColorbar` — accept `breaks`/`labels` and use them instead of d3-generated ticks; accept a `banded` flag for steps scales.
- `inst/htmlwidgets/gg2d3.js:79–101` — verify `ir.scales.color` is propagated for `fill` aesthetic (currently named `color`; may need a parallel `fill` entry if both scales coexist per D-12).

</code_context>

<deferred>
## Deferred Ideas

- Visual PNG diff testing (webshot/headless render → golden image compare) — out of scope; snapshot-of-hex strings is sufficient for COLOR-01/02. Revisit in CRAN-prep or v1.2.
- `scale_*_gradient`, `scale_*_gradient2`, `scale_*_gradientn` as a named requirement — not in roadmap; D-07 says ship them only if they fall out for free.
- Custom `guide_colorbar(barwidth=, barheight=, title.position=, ...)` argument support — keep ggplot2 defaults this phase; per-guide overrides are a v1.2 theming concern.
- Color blending for overlapping geom_density / geom_polygon fills — not in scope; Phase 16 (Robustness) tracks `GeomPolygon dispatch fix`.
- Interactive legend (click-to-filter, hover-to-highlight) — interactivity already exists for v1.0 plots; legends specifically remain static.

</deferred>

---

*Phase: 14-color-fidelity*
