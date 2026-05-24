# Phase 45 Rect/Tile Classification

This artifact records the Plan 45-01 evidence used to separate ggplot2-compatible rect/tile behavior from source-measurable renderer/update candidates for Plan 45-02.

Transformed scales: skipped per D-03 unless later evidence requires them.

## Fixture Matrix

| Case | Decision | Observed ggplot2 behavior | Observed gg2d3 IR/source behavior | Plan 45-02 action |
|------|----------|---------------------------|-----------------------------------|-------------------|
| continuous_scale_limits | non-issue | Scale limits censor out-of-range rect bounds to `NA` before rendering; this is distinct from coordinate clipping per D-02. | `as_d3_ir()` preserves the built-data `NA` pattern and `rect.js` filters rows missing any of `xmin`, `xmax`, `ymin`, or `ymax`. | closed as non-issue with tests |
| coord_cartesian_limits | non-issue | `coord_cartesian(xlim, ylim)` preserves complete rect bounds and expects panel clipping rather than data censoring. | IR rows retain finite bounds, and widget panels render layer marks inside an SVG clip-path group. | closed as non-issue with tests |
| discrete_tile_grid_limits | fix | Discrete scale limits drop/censor tiles outside the kept factor levels while retained tiles have complete finite bounds. | IR mirrors kept versus censored tile rows. Plan 45-02 fixed band-scale geometry so `rect.js` and `geom-registry.js` use tile center labels for position and `bandwidth()` for dimensions. | fixed in rect.js |
| reversed_scale_rect | non-issue | Reversed x scales produce finite built rect bounds, but tests should not assume original data-space ordering. | IR bounds remain finite and source uses `Math.abs` for continuous width/height; Plan 45-02 retained finite min/absolute geometry in renderer/update source. | closed as non-issue with tests |
| coord_flip_rect | fix | `coord_flip()` preserves finite built bounds while visual axes are flipped. | Plan 45-02 aligned `geom-registry.js` with the rect renderer by adding explicit `if (flip)` geometry branches for `rect.geom-rect`. | fixed in geom-registry.js |
| faceted_rect_tile | non-issue | Faceted rect rows span at least two `PANEL` values and keep complete bounds. | IR preserves `PANEL`, and widget panel filtering routes each panel's rows to clipped panel groups. | closed as non-issue with tests |

## Source Contract Notes

| Source | Decision | Evidence | Plan 45-02 action |
|--------|----------|----------|-------------------|
| `inst/htmlwidgets/modules/geoms/rect.js` | fix | Initial render registers `['rect', 'tile']`, filters all four bounds, branches on `bandwidth` and `options.flip`, and uses `Math.abs`; Plan 45-02 added registry `strokeColor`, linewidth conversion, and band-center positioning for categorical tiles. | fixed in rect.js |
| `inst/htmlwidgets/modules/geom-registry.js` | fix | Update path targets `rect.geom-rect` and computes `x`, `y`, `width`, and `height`; Plan 45-02 added explicit band-scale `bandwidth()` logic and `if (flip)` branches matching the rect renderer. | fixed in geom-registry.js |

## Scale Limits Versus Coordinate Limits

Scale limits are classified separately from coordinate limits per D-02. Scale limits can censor built rect bounds before gg2d3 sees the data, so missing rendered rows in those cases are ggplot2-compatible. Coordinate limits preserve complete bounds and depend on SVG panel clipping, so off-panel SVG coordinates are not a mismatch by themselves.

## Browser Smoke Disposition

Browser smoke: not required for Plan 45-02 closure. The remaining questions were source-measurable at the renderer/update boundary: `rect.js` now uses finite band-center geometry for categorical tiles, stroke/linewidth accessors for rect borders, and `geom-registry.js` now mirrors band-scale and `coord_flip()` rect geometry. No unresolved browser-smoke gate remains in the classification.
