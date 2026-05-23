# Requirements: gg2d3

**Defined:** 2026-05-22
**Core Value:** Any ggplot2 plot should render identically in D3 — same visual output, but now interactive and web-native.

## v1.10 Requirements

Requirements for the Release Hardening milestone. Each maps to exactly one roadmap phase.

### Package Hygiene

- [x] **HYG-01**: Maintainer can run package tests, helper code, examples, and documentation generation without undeclared direct package usage; DESCRIPTION records direct runtime, test, browser, and documentation dependencies in the appropriate fields.
- [x] **HYG-02**: Optional browser and spatial validation tooling skips cleanly with clear messages when unavailable and does not force heavyweight local dependencies in CRAN-like environments.
- [x] **HYG-03**: Generated browser fixtures, logs, check outputs, and local validation artifacts are written to predictable ignored paths so routine checks and local smoke runs do not pollute package sources.

### Release-Blocking Debt

- [x] **DEBT-01**: Recent advisory follow-ups are either fixed or explicitly classified as non-blocking, including direct `pkgload`/`rprojroot` dependency declarations and facet browser assertions that preserve panel identity.
- [x] **DEBT-02**: Known release-facing renderer/documentation debt is triaged and addressed where blocking, including stale `GeomPolygon` references and rect out-of-bounds behavior; any deferred items are documented with rationale.

### Validation Gate

- [x] **VAL-01**: Maintainer can run a documented local release gate that covers package tests, documentation generation, and an `R CMD check`-style package check with expected optional skips.
- [x] **VAL-02**: Release validation exercises representative non-sf plots, polygon/point/line sf plots, facet/legend/date/coord_flip behavior, and browser smoke coverage without weakening CRAN-compatible skip behavior.
- [x] **VAL-03**: Validation failures leave actionable logs or artifacts, and the documented release gate explains where to inspect failures.

### Documentation And Release Notes

- [x] **DOC-01**: README, vignettes, diagnostics docs, roxygen source, and generated help consistently describe the shipped polygon/point/line `geom_sf()` contract, optional browser validation, map anti-features, and release-support status without stale milestone language.
- [x] **DOC-02**: A v1.10 release checklist or notes artifact records checks run, residual risks, deferred non-blockers, and recommended next-milestone candidates.

## Future Requirements

Deferred beyond v1.10.

### Larger Architecture And Feature Work

- **FUT-01**: Continue modularizing the non-sf portions of `as_d3_ir()` after release gates are stable.
- **FUT-02**: Add screenshot-diff or perceptual visual regression testing if DOM/source guards prove insufficient.
- **FUT-03**: Add advanced sf features such as `GEOMETRYCOLLECTION`, `geom_sf_text()`, `geom_sf_label()`, or projection-aware map interactions.
- **FUT-04**: Establish large-dataset performance budgets and simplification guidance for complex SVG outputs.

## Out of Scope

Explicit exclusions for this milestone.

| Feature | Reason |
|---------|--------|
| New geom families or new user-facing interactivity APIs | v1.10 is a hardening milestone, not a feature expansion milestone. |
| Actual CRAN submission | This milestone prepares a release-quality checkpoint; submission mechanics can follow once checks and notes are clean. |
| Major `as_d3_ir()` rewrite | Broader modularization is worthwhile but too invasive for a release-hardening pass. |
| Advanced map engine behavior | Tile basemaps, slippy-map controls, JS reprojection, and geometry-overlap brushing remain outside gg2d3's current SVG/htmlwidgets scope. |
| Full visual screenshot-diff infrastructure | Useful later, but v1.10 should first stabilize documented package and browser validation gates. |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| HYG-01 | Phase 40 | Complete |
| HYG-02 | Phase 40 | Complete |
| HYG-03 | Phase 40 | Complete |
| DEBT-01 | Phase 41 | Complete |
| DEBT-02 | Phase 41 | Complete |
| VAL-01 | Phase 42 | Complete |
| VAL-02 | Phase 42 | Complete |
| VAL-03 | Phase 42 | Complete |
| DOC-01 | Phase 43 | Complete |
| DOC-02 | Phase 43 | Pending |

**Coverage:**
- v1.10 requirements: 10 total
- Mapped to phases: 10
- Unmapped: 0

---
*Requirements defined: 2026-05-22*
*Last updated: 2026-05-23 after completing Phase 40 Package Hygiene*
