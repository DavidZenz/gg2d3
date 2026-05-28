# Requirements: gg2d3 v1.13 Regression & Release Polish

**Defined:** 2026-05-27
**Core Value:** Any ggplot2 plot should render identically in D3 -- same visual output, but now interactive and web-native.

## v1.13 Requirements

### CI Visual Regression

- [x] **CI-01**: Maintainers can run browser visual smoke coverage in CI or a CI-equivalent local mode with deterministic artifact paths and explicit dependency skip outcomes.
- [x] **CI-02**: Browser visual artifacts include enough stable DOM summary, screenshot, browser-log, and report metadata for CI failures to be inspected without committing generated outputs.
- [x] **CI-03**: Representative CI/browser assertions validate stable rendered structure and fixture health before any pixel-diff threshold is introduced.

### Renderer Architecture

- [x] **ARCH-01**: Renderer registration, update selectors, interaction selectors, and public payload sanitization expectations are driven by a single declarative geom contract or a source-of-truth validation gate.
- [x] **ARCH-02**: Additional high-risk `as_d3_ir()` responsibilities are isolated behind focused helpers without changing representative non-sf, sf, facet, scale, and annotation IR output.
- [x] **ARCH-03**: Contract tests fail with actionable messages when renderer metadata, module loading, update handling, or interaction payload behavior drifts.

### Geometry Polish

- [x] **GEOM-01**: Ordinary `geom_label()` box, padding, fill, stroke, and text behavior is either implemented for the supported text renderer path or explicitly deferred with source-backed evidence and user-facing diagnostics.
- [x] **GEOM-02**: Ordinary `geom_polygon()` subgroup/hole behavior is either supported for a bounded ggplot2-compatible subset or documented as an explicit non-goal with fixtures proving the boundary.
- [x] **GEOM-03**: Transformed-scale rect/tile edge parity is addressed at the shared scale/axis semantics boundary or carried forward with narrower implementation-ready evidence than the v1.12 classification.
- [x] **GEOM-04**: Collision avoidance, path-following text, rotation, and justification candidates are triaged into small verified improvements or future requirements without implying unsupported label-placement parity.

### Release And Documentation

- [ ] **REL-01**: README, vignettes, diagnostics docs, roxygen source, and generated help describe the v1.13 validation, architecture, and geometry support contract from source-first documentation.
- [ ] **REL-02**: A repeatable release-readiness gate covers package tests, docs generation, browser visual smoke behavior, optional dependency skips, and package check evidence.
- [ ] **REL-03**: v1.13 release notes summarize shipped support, validation commands, artifact locations, residual risks, and future candidates without publishing local logs.

## Future Requirements

Deferred beyond v1.13.

### Visual Validation

- **FUT-01**: Add committed golden screenshots and pixel-diff thresholds once local and CI visual artifacts prove stable across operating systems.
- **FUT-02**: Add public hosted visual reports for pull requests if CI artifacts alone are not ergonomic enough for maintainers.

### Architecture

- **FUT-03**: Complete the full `as_d3_ir()` modularization after the remaining high-risk helper boundaries are stable.
- **FUT-04**: Generate renderer documentation directly from declarative geom contracts if the contract table becomes the long-term source of truth.

### Geometry

- **FUT-05**: Add full ggrepel-compatible label placement if demand justifies the dependency and algorithmic complexity.
- **FUT-06**: Add broad GIS-style polygon topology repair only if gg2d3 intentionally expands beyond ggplot2 rendering parity.

## Out of Scope

| Feature | Reason |
|---------|--------|
| Mandatory CI pixel diffs | v1.13 should first prove CI/browser artifact stability before enforcing cross-platform image thresholds. |
| Full `as_d3_ir()` rewrite | The milestone should continue extracting high-risk boundaries without destabilizing the entire IR path. |
| Full ggrepel clone | Label-placement parity is too broad for one polish milestone; v1.13 should ship bounded improvements or implementation-ready deferrals. |
| Full GIS topology repair | gg2d3 should render ggplot2 output, not become a spatial data cleaning library. |
| Tile basemaps and slippy map controls | Still outside gg2d3's SVG/htmlwidgets ggplot parity focus. |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| CI-01 | Phase 52 | Complete |
| CI-02 | Phase 52 | Complete |
| CI-03 | Phase 52 | Complete |
| ARCH-01 | Phase 53 | Complete |
| ARCH-02 | Phase 53 | Complete |
| ARCH-03 | Phase 53 | Complete |
| GEOM-01 | Phase 54 | Complete |
| GEOM-02 | Phase 54 | Complete |
| GEOM-03 | Phase 54 | Complete |
| GEOM-04 | Phase 54 | Complete |
| REL-01 | Phase 55 | Pending |
| REL-02 | Phase 55 | Pending |
| REL-03 | Phase 55 | Pending |

**Coverage:**
- v1.13 requirements: 13 total
- Mapped to phases: 13
- Unmapped: 0

---
*Requirements defined: 2026-05-27*
*Last updated: 2026-05-28 after completing Phase 53 renderer and IR contract consolidation*
