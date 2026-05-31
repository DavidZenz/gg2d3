# gg2d3 (development version)

## v1.14 development notes
* **Pkgdown publication-surface evidence**: Repaired the documentation evidence contract so source docs, generated `docs/`, GitHub Pages output, and browser visual smoke artifacts have distinct release-readiness roles. This clarifies how the generated site proves current pkgdown content and widget embedding without implying new rendering support.

## v1.13 release notes
* **CI/browser visual smoke validation**: Added a dedicated browser visual smoke workflow with CI-mode behavior, stable DOM/report metadata checks, and downloadable artifact bundles. Browser visual artifacts remain inspection evidence under ignored paths such as `test_output/browser-visual-smoke/` and downloaded GitHub run artifact directories; screenshots, DOM summaries, browser logs, and report JSON are not committed as release notes.
* **Renderer and IR contract consolidation**: Hardened renderer wiring around `geom-contracts.js`, source gates for module load order, render/update/interaction selectors, and shared public-payload sanitization. High-risk R-side IR responsibilities now have focused helper-boundary tests while full `as_d3_ir()` modularization remains future work.
* **Geometry polish closure**: Shipped bounded ordinary `geom_label()` SVG boxes with text placement fields, kept ordinary `geom_polygon()` subgroup/hole topology as an explicit fixture-backed non-goal, and added finite transformed-bound filtering for `geom_rect()` and `geom_tile()` before invalid SVG attributes are emitted. Collision avoidance, rich text, and path-following text remain deferred.
* **Release-readiness gate**: Phase 55 evidence records focused renderer/IR/geometry source gates, documentation generation, `devtools::test()`, browser visual smoke behavior, source package build, and `R CMD check --as-cran` command classes. Optional spatial and browser skips are documented as evidence classifications, not release success by themselves; package-check ERROR or WARNING outcomes remain release blockers. Package-check artifacts live in uncommitted package-check directories and raw local command output, browser logs, `00check.log` excerpts, DOM dumps, and report JSON contents are not published in `NEWS.md`.
* **Residual risks and future candidates**: FUT-01 committed golden screenshots and pixel-diff thresholds, FUT-02 hosted pull-request visual reports, FUT-03 full `as_d3_ir()` modularization, FUT-04 generated renderer documentation from contracts, FUT-05 full ggrepel-compatible label placement, and FUT-06 broad GIS-style polygon topology repair remain future candidates rather than shipped v1.13 support.

## gg2d3 0.6.0 (2026-03-31)
* **Specialized Geoms**: Added support for `geom_dotplot`, `geom_rug`, `geom_errorbar`, `geom_linerange`, and `geom_pointrange`.
* **API Polish**: Standardized interactivity attachment and optimized rendering performance for state updates.

## gg2d3 0.5.0 (2026-03-31)
* **Non-Cartesian Systems**: Full support for `coord_polar`, including specialized radial/circular axes and pie/coxcomb charts.
* **Advanced Stats**: High-fidelity rendering for `geom_density` and complex `geom_smooth` (loess, gam).

## gg2d3 0.4.0 (2026-03-31)
* **Theme Parity**: Implemented deep theme inheritance and support for complex element styling (margins, justifications, rotation).
* **Reference Geoms**: Added `geom_hline`, `geom_vline`, and `geom_abline` with robust clipping.

## gg2d3 0.3.0 (2026-03-31)
* **Advanced Facets**: Support for hierarchical facet headers and multiple nesting variables.
* **Custom Interactivity**: New R API `d3_handlers` for injecting custom JS logic and Shiny synchronization.

## gg2d3 0.2.0 (2026-03-31)
* **Smooth Transitions**: Object-constant enter/update/exit animations for marks and axes.
* **Scale Parity**: Enhanced support for custom breaks, minor breaks, expansion, and OOB logic.

## gg2d3 0.1.0 (2026-02-16)
* **MVP Release**: Core support for 15 basic geoms, faceting, and pipe-based interactivity API (tooltip, zoom, brush, crosstalk).
