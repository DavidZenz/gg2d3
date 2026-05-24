# Phase 45 Rect/Tile Classification

This artifact records the Plan 45-01 evidence used to separate ggplot2-compatible rect/tile behavior from source-measurable renderer/update candidates for Plan 45-02.

Transformed scales: skipped per D-03 unless later evidence requires them.

## Fixture Matrix

| Case | Decision | Observed ggplot2 behavior | Observed gg2d3 IR/source behavior | Plan 45-02 action |
|------|----------|---------------------------|-----------------------------------|-------------------|
| continuous_scale_limits | non-issue | Scale limits censor out-of-range rect bounds to `NA` before rendering; this is distinct from coordinate clipping per D-02. | `as_d3_ir()` preserves the built-data `NA` pattern and `rect.js` filters rows missing any of `xmin`, `xmax`, `ymin`, or `ymax`. | Keep as locked classification evidence; no renderer fix for scale-limit censoring. |
| coord_cartesian_limits | non-issue | `coord_cartesian(xlim, ylim)` preserves complete rect bounds and expects panel clipping rather than data censoring. | IR rows retain finite bounds, and widget panels render layer marks inside an SVG clip-path group. | Preserve clipping contract; only investigate if DOM evidence later shows unclipped rects. |
| discrete_tile_grid_limits | non-issue | Discrete scale limits drop/censor tiles outside the kept factor levels while retained tiles have complete finite bounds. | IR mirrors kept versus censored tile rows; initial `rect.js` has band-scale `bandwidth()` branches for renderable rows. | No initial-render fix; include in update-path review because `geom-registry.js` lacks band-scale width/height logic. |
| reversed_scale_rect | non-issue | Reversed x scales produce finite built rect bounds, but tests should not assume original data-space ordering. | IR bounds remain finite and source uses `Math.abs` for continuous width/height. | No fix from IR evidence; Plan 45-02 may verify DOM/update parity if touching rect geometry. |
| coord_flip_rect | fix | `coord_flip()` preserves finite built bounds while visual axes are flipped. | Initial `rect.js` branches on `options.flip`; `geom-registry.js` uses swapped scale functions but lacks an explicit flip branch aligned with initial rect geometry. Update-path mismatch candidate: `geom-registry.js`. | Patch or prove update-path parity in Plan 45-02 before closure. |
| faceted_rect_tile | non-issue | Faceted rect rows span at least two `PANEL` values and keep complete bounds. | IR preserves `PANEL`, and widget panel filtering routes each panel's rows to clipped panel groups. | No fixture-specific fix; preserve PANEL regression coverage. |

## Source Contract Notes

| Source | Decision | Evidence | Plan 45-02 action |
|--------|----------|----------|-------------------|
| `inst/htmlwidgets/modules/geoms/rect.js` | fix | Initial render registers `['rect', 'tile']`, filters all four bounds, branches on `bandwidth` and `options.flip`, and uses `Math.abs`; it uses fill/opacity accessors but does not currently apply the registry `strokeColor` accessor. Initial render stroke accessor mismatch candidate. | Decide whether rect/tile should honor stroke/colour parity and patch `rect.js` if confirmed. |
| `inst/htmlwidgets/modules/geom-registry.js` | fix | Update path targets `rect.geom-rect` and computes `x`, `y`, `width`, and `height`, but does not contain explicit band-scale `bandwidth()` logic or an `if (flip)` branch matching the initial renderer. Update-path mismatch candidate: `geom-registry.js`. | Patch or prove update-path parity in Plan 45-02; treat this as the remaining update-path mismatch candidate. |

## Scale Limits Versus Coordinate Limits

Scale limits are classified separately from coordinate limits per D-02. Scale limits can censor built rect bounds before gg2d3 sees the data, so missing rendered rows in those cases are ggplot2-compatible. Coordinate limits preserve complete bounds and depend on SVG panel clipping, so off-panel SVG coordinates are not a mismatch by themselves.
