---
phase: 27
slug: r-ir-extraction-feasibility
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-04
---

# Phase 27 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | testthat 3.3.2 |
| **Config file** | `tests/testthat/` (existing directory) |
| **Quick run command** | `testthat::test_file("tests/testthat/test-sf-utils.R")` |
| **Full suite command** | `pkgload::load_all(); devtools::test()` |
| **Estimated runtime** | ~15 seconds |

---

## Sampling Rate

- **After every task commit:** Run `testthat::test_file("tests/testthat/test-sf-utils.R")`
- **After every plan wave:** Run `pkgload::load_all(); devtools::test()`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 15 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | Status |
|---------|------|------|-------------|-----------|-------------------|--------|
| 27-01-01 | 01 | 1 | FEAS-01 | setup | `Rscript -e "requireNamespace('geojsonsf', quietly=TRUE)"` | pending |
| 27-01-02 | 01 | 1 | FEAS-01, FEAS-02, FEAS-03 | unit (RED) | `Rscript -e "cat('exists:', file.exists('tests/testthat/test-sf-utils.R'))"` | pending |
| 27-01-03 | 01 | 1 | FEAS-01, FEAS-02, FEAS-03 | unit (GREEN) | `testthat::test_file("tests/testthat/test-sf-utils.R")` | pending |
| 27-02-01 | 02 | 2 | FEAS-01, FEAS-04 | integration | `Rscript -e "pkgload::load_all(); nc <- sf::st_read(system.file('shape/nc.shp', package='sf'), quiet=TRUE); ir <- as_d3_ir(ggplot2::ggplot(nc) + ggplot2::geom_sf()); stopifnot(ir$coord$type == 'sf')"` | pending |
| 27-02-02 | 02 | 2 | FEAS-04 | integration | `testthat::test_file("tests/testthat/test-sf-ir.R")` | pending |

*Status: pending / green / red / flaky*

---

## Wave 0 Requirements

Test files are created as TDD RED-phase tasks within Plan 01 (Task 2) and Plan 02 (Task 2). No separate Wave 0 is needed because:

- Plan 01 Task 2 creates `tests/testthat/test-sf-utils.R` as a dedicated RED-phase task before Task 3 implements the code
- Plan 02 Task 2 creates `tests/testthat/test-sf-ir.R` alongside implementation (integration tests that verify the full pipeline)

Both test files are created by tasks with `<automated>` verify commands. Nyquist compliance is satisfied.

Prerequisites:
- [ ] Install geojsonsf: `install.packages("geojsonsf")` — handled by Plan 01 Task 1

*All test files are new — no existing infrastructure covers sf-specific behaviors.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| IR schema annotated JSON document | FEAS-04 | Documentation artifact, not code | Review `IR-SCHEMA-SF.md` for completeness of `geometries[]`, `crs`, `geom_type`, `coord.type`, `coord.bbox` fields |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify commands
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] TDD RED-phase tasks create test files before implementation tasks
- [x] No watch-mode flags
- [x] Feedback latency < 15s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved
