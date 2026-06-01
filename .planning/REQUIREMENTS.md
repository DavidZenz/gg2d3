# Requirements: gg2d3 v1.14 Pkgdown Site Verification

**Defined:** 2026-05-31
**Core Value:** Any ggplot2 plot should render identically in D3 -- same visual output, but now interactive and web-native.

## v1.14 Requirements

### Pkgdown Content

- [x] **DOCS-01
**: Maintainers can build a generated pkgdown site whose articles, reference pages, NEWS, and support-contract text reflect the current v1.13/v1.14 source documentation.
- [x] **DOCS-02
**: Users can find the current `geom_sf()` polygon, point, line, and sf annotation support contract in the generated pkgdown site, not only in source files.
- [x] **DOCS-03
**: Maintainers can distinguish source documentation, generated `docs/`, GitHub Pages output, and browser visual smoke artifacts when checking release readiness.

### Pkgdown Build And Rendering

- [x] **BUILD-01
**: Maintainers can run the pkgdown build locally and in GitHub Actions with website dependencies configured so representative `gg2d3` article chunks render consistently.
- [x] **BUILD-02
**: Pkgdown articles include rendered `gg2d3` htmlwidget scaffolding, dependencies, and assets for representative examples rather than static or missing placeholders.
- [x] **BUILD-03
**: The `geom_sf()` pkgdown example renders when `sf` and `geojsonsf` are available, and any dependency-based non-rendering is surfaced as an explicit classified outcome.

### Site Validation And Publication

- [x] **SITE-01**: Maintainers have a repeatable validation gate that detects stale generated-site content, missing sf support text, missing htmlwidget outputs, and missing widget dependencies/assets.
- [x] **SITE-02**: Maintainers can download or inspect the pkgdown/GitHub Pages build artifact and verify that it contains the current sf/widget documentation evidence.
- [x] **SITE-03**: Release-readiness evidence includes pkgdown source/build/deploy validation alongside package tests, generated help, browser visual smoke, and package check outcomes.

## Future Requirements

Deferred beyond v1.14.

### Website Experience

- **FUT-01**: Add public pull-request preview links for pkgdown sites if GitHub Pages artifacts are not ergonomic enough for review.
- **FUT-02**: Add screenshot or perceptual regression coverage for selected pkgdown article pages after generated-site content and widget rendering are stable.
- **FUT-03**: Add external uptime/freshness monitoring for the published GitHub Pages URL after the release workflow is proven.

## Out of Scope

| Feature | Reason |
|---------|--------|
| New gg2d3 rendering features | v1.14 is about publication and verification of existing support, not expanding geom behavior. |
| Mandatory pixel diffs for pkgdown pages | First prove content freshness and widget rendering before enforcing image thresholds. |
| Replacing pkgdown or GitHub Pages | The existing publication stack is already configured; this milestone should harden it rather than migrate it. |
| Tile basemaps and slippy map controls | Still outside gg2d3's SVG/htmlwidgets ggplot parity focus. |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| DOCS-01 | Phase 56 | Complete |
| DOCS-02 | Phase 56 | Complete |
| DOCS-03 | Phase 56 | Complete |
| BUILD-01 | Phase 56 | Complete |
| BUILD-02 | Phase 56 | Complete |
| BUILD-03 | Phase 56 | Complete |
| SITE-01 | Phase 57 | Complete |
| SITE-02 | Phase 58 | Complete |
| SITE-03 | Phase 58 | Complete |

**Coverage:**
- v1.14 requirements: 9 total
- Mapped to phases: 9
- Unmapped: 0

---
*Requirements defined: 2026-05-31*
*Last updated: 2026-06-01 after Phase 58 execution*
