---
phase: 56
slug: pkgdown-content-and-widget-build-contract
status: executed
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-31
---

# Phase 56 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | testthat edition 3 plus R/pkgdown generated-file checks |
| **Config file** | `DESCRIPTION` (`Config/testthat/edition: 3`) |
| **Quick run command** | `rtk Rscript -e 'testthat::test_file("tests/testthat/test-pkgdown-site.R")'` |
| **Full suite command** | `rtk Rscript -e 'devtools::test()'` |
| **Estimated runtime** | ~30-90 seconds for focused generated-site checks; longer when rebuilding pkgdown |

---

## Sampling Rate

- **After every task commit:** Run `rtk Rscript -e 'testthat::test_file("tests/testthat/test-pkgdown-site.R")'` once the focused file exists; before Wave 0 lands, run equivalent `rg`/R generated-file probes.
- **After every plan wave:** Run `rtk Rscript -e 'devtools::test()'` plus the relevant docs command for changed artifacts.
- **Before `$gsd-verify-work`:** Regenerate docs/site and verify generated article text, reference/news pages, htmlwidget scaffolding, dependency assets, and visible sf render/skip classification.
- **Max feedback latency:** 120 seconds for focused probes; pkgdown rebuild latency is accepted for wave/phase gates.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 56-01-01 | 01 | 1 | DOCS-01 | T-56-01 | Generated docs are regenerated from source, not hand-edited | generated-file smoke | `rtk Rscript -e 'testthat::test_file("tests/testthat/test-pkgdown-site.R")'` | ✅ | ✅ green |
| 56-01-02 | 01 | 1 | DOCS-02 | T-56-01 | Generated article exposes the current sf support contract | generated-file smoke | `rtk Rscript -e 'testthat::test_file("tests/testthat/test-pkgdown-site.R")'` | ✅ | ✅ green |
| 56-01-03 | 01 | 1 | BUILD-03 | T-56-02 | Missing optional sf dependencies produce a visible classified outcome | vignette/generated article smoke | `rtk Rscript -e 'testthat::test_file("tests/testthat/test-pkgdown-site.R")'` | ✅ | ✅ green |
| 56-02-01 | 02 | 2 | BUILD-01 | T-56-03 | Pkgdown build command completes or records classified dependency behavior | integration | `rtk Rscript -e 'pkgdown::build_site_github_pages(new_process = FALSE, install = FALSE)'` | ✅ | ✅ green |
| 56-02-02 | 02 | 2 | BUILD-02 | T-56-04 | Generated article contains widget containers and dependency assets | generated HTML smoke | `rtk Rscript -e 'testthat::test_file("tests/testthat/test-pkgdown-site.R")'` | ✅ | ✅ green |
| 56-03-01 | 03 | 2 | DOCS-03 | T-56-05 | Maintainers can distinguish source docs, generated site, GH Pages output, and browser smoke artifacts | documentation smoke | `rtk Rscript -e 'testthat::test_file("tests/testthat/test-pkgdown-site.R")'` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `tests/testthat/test-pkgdown-site.R` — focused checks for generated-site freshness, sf support text, htmlwidget scaffolding, dependency assets, and visible sf render/skip classification.
- [x] `vignettes/gg2d3.Rmd` — evaluated sf section emits either a rendered widget or a visible classified optional dependency outcome.
- [x] Generated-site probes check exact markers such as `sf family maps with`, `geom_sf() supports polygon-family`, `gg2d3 html-widget`, `d3.v7.min.js`, `gg2d3-modules`, and `PKGDOWN_SF_OPTIONAL_SKIP` or equivalent classification.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Visual inspection of generated article widget placement | BUILD-02 | Phase 56 defers pixel/screenshot thresholds | Open `docs/articles/gg2d3.html` after rebuild and confirm representative widgets are present; automated checks remain the source of truth for scaffolding/assets. |
| Rendered sf widget when local `sf` is unavailable | BUILD-03 | Local machine currently lacks `sf`; rendered sf evidence may require CI or an approved dependency install | If `sf` is not installed locally, accept only a visible classified local skip and verify rendered sf evidence in an environment where `sf` and `geojsonsf` are installed. |

---

## Threat Model Anchors

| Threat | Mitigation Required In Plans |
|--------|------------------------------|
| T-56-01: Published site makes stale or misleading support claims | Regenerate from source and test exact generated markers before completion. |
| T-56-02: Optional sf dependency skip disappears silently | Emit visible classified skip/failure text in generated article output. |
| T-56-03: CI/pkgdown dependency route is assumed rather than proven | Capture local/CI build evidence and classify local dependency availability. |
| T-56-04: Widget embedding is inferred from source code only | Inspect generated HTML containers and dependency assets. |
| T-56-05: Release artifacts are confused with browser smoke artifacts | Document artifact taxonomy in maintainer-facing docs. |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 120s for focused probes
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-05-31 for planning

**Execution result:** passed 2026-05-31. Local `sf` cannot be loaded because its GDAL dynamic library is unavailable, so the generated article records `PKGDOWN_SF_OPTIONAL_SKIP: sf example not rendered; missing sf.` while all required widget scaffolding markers remain present.
