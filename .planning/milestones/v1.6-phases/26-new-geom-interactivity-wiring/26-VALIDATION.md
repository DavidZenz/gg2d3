---
phase: 26
slug: new-geom-interactivity-wiring
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-03
---

# Phase 26 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | testthat 3.x |
| **Config file** | tests/testthat.R |
| **Quick run command** | `devtools::test_file("tests/testthat/test-geoms-phase4.R")` |
| **Full suite command** | `devtools::test()` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run `devtools::test_file("tests/testthat/test-geoms-phase4.R")`
- **After every plan wave:** Run `devtools::test()`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 26-01-01 | 01 | 1 | GEOM-20 | unit (JS contract) | `devtools::test_file("tests/testthat/test-interactivity.R")` | ❌ W0 | ⬜ pending |
| 26-01-02 | 01 | 1 | GEOM-21 | unit (JS contract) | `devtools::test_file("tests/testthat/test-interactivity.R")` | ❌ W0 | ⬜ pending |
| 26-01-03 | 01 | 1 | GEOM-22 | unit (JS contract) | `devtools::test_file("tests/testthat/test-zoom-brush.R")` | ❌ W0 | ⬜ pending |
| 26-01-04 | 01 | 1 | GEOM-22 | unit (JS contract) | `devtools::test_file("tests/testthat/test-zoom-brush.R")` | ❌ W0 | ⬜ pending |
| 26-02-01 | 02 | 1 | API-02 | manual | `diff README.md <(Rscript -e "rmarkdown::render('README.Rmd')")` | N/A | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `tests/testthat/test-interactivity.R` — add R-side checks that dotplot/rug IR layer data includes correct geom type and CSS class selectors
- [ ] `tests/testthat/test-zoom-brush.R` — add R-side check that interval geom IR has ymin/ymax/xmin/xmax fields needed by updateGeoms

*Note: The project has no JS test framework. JavaScript interactivity correctness is verified visually via `test_output/` HTML snapshots per project convention.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Dotplot marks respond to brush/hover/tooltip | GEOM-20 | JS DOM interaction not testable in R | Create dotplot, verify brush selects dots, hover highlights, tooltip shows data |
| Rug marks respond to brush/hover/tooltip | GEOM-21 | JS DOM interaction not testable in R | Create rug plot, verify brush selects marks, hover highlights, tooltip shows data |
| Interval geoms reposition on zoom/reset | GEOM-22 | JS DOM interaction not testable in R | Create errorbar plot with zoom, verify marks reposition correctly on zoom/reset |
| README.md reflects v1.6 features | API-02 | Content comparison | Verify README.md contains v1.6 feature table and interactivity API docs |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
