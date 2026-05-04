# Roadmap: gg2d3

## Milestones

- ✅ **v1.0 MVP** — Phases 1-12 (shipped 2026-02-16)
- 🚧 **v1.1 Release Hardening** — Phases 13-18 (started 2026-03-11)

## Phases

<details>
<summary>✅ v1.0 MVP (Phases 1-12) — SHIPPED 2026-02-16</summary>

- [x] Phase 1: Foundation Refactoring (5/5 plans) — completed 2026-02-07
- [x] Phase 2: Core Scale System (3/3 plans) — completed 2026-02-08
- [x] Phase 3: Coordinate Systems (3/3 plans) — completed 2026-02-08
- [x] Phase 4: Essential Geoms (4/4 plans) — completed 2026-02-09
- [x] Phase 5: Statistical Geoms (4/4 plans) — completed 2026-02-09
- [x] Phase 6: Layout Engine (3/3 plans) — completed 2026-02-09
- [x] Phase 7: Legend System (4/4 plans) — completed 2026-02-09
- [x] Phase 8: Basic Faceting (4/4 plans) — completed 2026-02-13
- [x] Phase 9: Advanced Faceting (4/4 plans) — completed 2026-02-13
- [x] Phase 10: Interactivity Foundation (3/3 plans) — completed 2026-02-14
- [x] Phase 11: Advanced Interactivity (4/4 plans) — completed 2026-02-16
- [x] Phase 12: Date/Time Scales (3/3 plans) — completed 2026-02-16

Full details: .planning/milestones/v1.0-ROADMAP.md

</details>

### v1.1 Release Hardening (Phases 13-18)

- [ ] **Phase 13: Internals Refactor** — Modularize `as_d3_ir()` and harden private-API usage so subsequent v1.1 work has clean seams.
- [ ] **Phase 14: Color Fidelity** — ggplot2 color/fill scales (viridis, brewer, manual) render with identical hex codes; continuous color renders as a colorbar legend.
- [ ] **Phase 15: Secondary Axes** — `sec.axis` produces a real rendered secondary axis (ticks, labels, title) on the D3 side.
- [ ] **Phase 16: Robustness & Edge Cases** — Non-finite handling, browser/R error surfacing, rect clipping, GeomPolygon dispatch fix, coord_flip + facet_grid regression.
- [ ] **Phase 17: CRAN Packaging** — DESCRIPTION imports, full metadata, `R CMD check --as-cran` clean.
- [ ] **Phase 18: Documentation Refresh** — README, CLAUDE.md, vignettes match v1.1 reality.

## Phase Details

### Phase 13: Internals Refactor
**Goal**: `as_d3_ir()` is split into per-concern modules with isolated, testable helpers, and `ggplot2:::calc_element()` usage is wrapped behind a fallback so a private-API change does not break gg2d3.
**Depends on**: Nothing (first v1.1 phase; v1.0 codebase is stable baseline)
**Requirements**: REFACTOR-01, REFACTOR-02
**Success Criteria** (what must be TRUE):
  1. Top-level `as_d3_ir()` is under ~200 lines and delegates to named helpers (`extract_scales_ir()`, `extract_theme_ir()`, `extract_facets_ir()`, `extract_layers_ir()` or equivalent).
  2. Each extraction helper has its own dedicated test file in `tests/testthat/` and can be exercised without running the full pipeline.
  3. All `ggplot2:::calc_element()` call sites route through a single `calc_element_safe()` helper that falls back to a public-API path on error.
  4. Existing v1.0 visual regression and unit tests continue to pass against the refactored code (no behavior change observable to consumers).
**Plans**: 7 plans
- [ ] 13-01-foundation-PLAN.md — Wave 0 test stubs, R/zzz.R pkgenv, R/ir_utils.R utilities
- [ ] 13-02-theme-PLAN.md — R/ir_theme.R + calc_element_safe (REFACTOR-02 chokepoint)
- [ ] 13-03-scales-PLAN.md — R/ir_scales.R lift (map_discrete, get_scale_info, validate_log_domain, get_scale_transform)
- [ ] 13-04-layers-PLAN.md — R/ir_layers.R lift (extract_layers_ir, to_rows dedup, keep_aes lift)
- [ ] 13-05-legends-PLAN.md — R/ir_legends.R lift (extract_legends_ir using public get_guide_data)
- [ ] 13-06-facets-PLAN.md — R/ir_facets.R lift (extract_facets_ir, removes <<- per Pitfall 2)
- [ ] 13-07-orchestrator-shrink-PLAN.md — Final shrink to ≤~200 lines + visual diff checkpoint

### Phase 14: Color Fidelity
**Goal**: ggplot2 color and fill scales (viridis, brewer, manual) render in D3 with the exact colors ggplot2 produces, and continuous color legends render as a true colorbar gradient.
**Depends on**: Phase 13 (clean scale extraction module)
**Requirements**: COLOR-01, COLOR-02
**Success Criteria** (what must be TRUE):
  1. A ggplot using `scale_color_viridis_c()` produces marks whose `fill`/`stroke` hex values in the rendered DOM match `ggplot_build()`'s palette output exactly.
  2. `scale_color_brewer()` and `scale_fill_manual()` likewise round-trip to identical hex codes in the D3 output.
  3. A plot with a continuous color aesthetic renders a colorbar legend (gradient rectangle with axis ticks and labels), not a stack of discrete keys.
  4. Discrete color legends from v1.0 still render correctly (no regression).
**Plans**: TBD

### Phase 15: Secondary Axes
**Goal**: `sec.axis` on x or y produces a fully rendered secondary axis in D3 — ticks, tick labels, and axis title — using the user-supplied transformation, not just reserved layout space.
**Depends on**: Phase 13 (refactor exposes a clean place to attach sec-axis IR)
**Requirements**: AXIS-01
**Success Criteria** (what must be TRUE):
  1. A ggplot with `sec.axis = sec_axis(~ . * k)` renders a second axis on the opposite side of the panel with ticks placed at the transformed positions.
  2. Secondary axis title from the ggplot spec appears in the D3 output.
  3. Reserved layout space matches the actually-rendered axis width (no stale gap when there is no `sec.axis`, no overflow when there is one).
  4. Plots without `sec.axis` are unchanged.
**Plans**: TBD
**UI hint**: yes

### Phase 16: Robustness & Edge Cases
**Goal**: gg2d3 fails gracefully and visibly: non-finite values become visual gaps with a single warning, runtime errors render an in-widget message, and known v1.0 edge cases (rect overflow, orphaned GeomPolygon, coord_flip + facet_grid) are fixed.
**Depends on**: Phase 13 (safer to add filtering and dispatch logic on top of modular helpers)
**Requirements**: ROBUST-01, ROBUST-02, ROBUST-03, ROBUST-04, ROBUST-05
**Success Criteria** (what must be TRUE):
  1. A layer with `NA`/`NaN`/`Inf` in mapped aesthetics emits exactly one warning per layer and renders the remaining points/segments with visible gaps where data was non-finite.
  2. An R-side or JS-side runtime error inside the rendering pipeline produces a visible error message inside the widget container instead of a blank widget.
  3. `geom_rect` with bounds outside the panel's plotting region renders clipped rectangles without negative-dimension or off-canvas artifacts.
  4. The `GeomPolygon` dispatch path either renders a real polygon or shows a user-facing "unsupported geom: polygon" message — no silent blanking.
  5. `coord_flip()` combined with `facet_grid()` renders panel axes on the same sides as `coord_flip()` alone, on every panel.
**Plans**: TBD
**UI hint**: yes

### Phase 17: CRAN Packaging
**Goal**: Package is mechanically ready for CRAN submission — DESCRIPTION declares all runtime dependencies with version floors, all metadata is real and CRAN-valid, and `R CMD check --as-cran` is clean.
**Depends on**: Phases 13–16 (don't lock down package surface until refactor and feature work has settled)
**Requirements**: PKG-01, PKG-02, PKG-03
**Success Criteria** (what must be TRUE):
  1. `R CMD check --as-cran` reports 0 ERRORs and 0 WARNINGs on the package as built from `master`.
  2. DESCRIPTION's `Imports:` field lists every package the runtime code actually loads (ggplot2, htmlwidgets, grid, scales, plus any others discovered) with sensible version floors.
  3. DESCRIPTION's Title, Description, Authors@R, URL, and BugReports fields contain real values (no `<you>` or generic placeholders) that render correctly in `?gg2d3` and on a CRAN-style package page.
  4. `devtools::check()` from a clean session reproduces the same clean result.
**Plans**: TBD

### Phase 18: Documentation Refresh
**Goal**: User-facing documentation accurately describes v1.1 behavior — no stale "no legends or facets" claims, the limitations section reflects what is actually still unsupported after Phases 13–17.
**Depends on**: Phases 13–17 (docs describe the post-hardening state)
**Requirements**: DOCS-01
**Success Criteria** (what must be TRUE):
  1. `README.md` (or `README.Rmd` rebuilt) lists v1.0+v1.1 supported features (15 geoms, legends, facets, sec.axis, color fidelity, error handling) and the current real limitations.
  2. `CLAUDE.md`'s "Current Feature Support" and "Known Limitations" sections reflect the post-v1.1 state (no obsolete "no legends or facets" wording).
  3. `vignettes/d3-drawing-diagnostics.md` (or successor vignettes) is updated so every claim still matches observable behavior of the package.
  4. A user reading only the README + vignettes can correctly predict whether a given ggplot will render in v1.1.
**Plans**: TBD

## Progress

| Phase | Milestone | Plans | Status | Completed |
|-------|-----------|-------|--------|-----------|
| 1. Foundation Refactoring | v1.0 | 5/5 | Complete | 2026-02-07 |
| 2. Core Scale System | v1.0 | 3/3 | Complete | 2026-02-08 |
| 3. Coordinate Systems | v1.0 | 3/3 | Complete | 2026-02-08 |
| 4. Essential Geoms | v1.0 | 4/4 | Complete | 2026-02-09 |
| 5. Statistical Geoms | v1.0 | 4/4 | Complete | 2026-02-09 |
| 6. Layout Engine | v1.0 | 3/3 | Complete | 2026-02-09 |
| 7. Legend System | v1.0 | 4/4 | Complete | 2026-02-09 |
| 8. Basic Faceting | v1.0 | 4/4 | Complete | 2026-02-13 |
| 9. Advanced Faceting | v1.0 | 4/4 | Complete | 2026-02-13 |
| 10. Interactivity Foundation | v1.0 | 3/3 | Complete | 2026-02-14 |
| 11. Advanced Interactivity | v1.0 | 4/4 | Complete | 2026-02-16 |
| 12. Date/Time Scales | v1.0 | 3/3 | Complete | 2026-02-16 |
| 13. Internals Refactor | v1.1 | 0/7 | Ready to execute | - |
| 14. Color Fidelity | v1.1 | 0/0 | Not started | - |
| 15. Secondary Axes | v1.1 | 0/0 | Not started | - |
| 16. Robustness & Edge Cases | v1.1 | 0/0 | Not started | - |
| 17. CRAN Packaging | v1.1 | 0/0 | Not started | - |
| 18. Documentation Refresh | v1.1 | 0/0 | Not started | - |

---
*Roadmap created: 2026-02-07*
*v1.0 shipped: 2026-02-16*
*v1.1 roadmap added: 2026-05-02*
*Total phases: 18 (12 v1.0 complete, 6 v1.1 pending)*
