---
phase: 27
slug: r-ir-extraction-feasibility
status: draft
nyquist_compliant: false
wave_0_complete: false
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

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 27-01-01 | 01 | 0 | FEAS-01 | unit | `testthat::test_file("tests/testthat/test-sf-utils.R")` | ❌ W0 | ⬜ pending |
| 27-01-02 | 01 | 0 | FEAS-02 | unit | `testthat::test_file("tests/testthat/test-sf-utils.R")` | ❌ W0 | ⬜ pending |
| 27-01-03 | 01 | 0 | FEAS-03 | unit | `testthat::test_file("tests/testthat/test-sf-utils.R")` | ❌ W0 | ⬜ pending |
| 27-02-01 | 02 | 1 | FEAS-01 | unit | `testthat::test_file("tests/testthat/test-sf-utils.R")` | ❌ W0 | ⬜ pending |
| 27-02-02 | 02 | 1 | FEAS-02 | unit | `testthat::test_file("tests/testthat/test-sf-utils.R")` | ❌ W0 | ⬜ pending |
| 27-02-03 | 02 | 1 | FEAS-03 | unit | `testthat::test_file("tests/testthat/test-sf-utils.R")` | ❌ W0 | ⬜ pending |
| 27-03-01 | 03 | 2 | FEAS-04 | integration | `testthat::test_file("tests/testthat/test-sf-ir.R")` | ❌ W0 | ⬜ pending |
| 27-03-02 | 03 | 2 | FEAS-04 | integration | `testthat::test_file("tests/testthat/test-sf-ir.R")` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `tests/testthat/test-sf-utils.R` — unit tests for `normalize_to_wgs84()`, `extract_sf_geometries()`, `detect_dominant_geom_type()`, `get_layer_crs()`; covers FEAS-01, FEAS-02, FEAS-03
- [ ] `tests/testthat/test-sf-ir.R` — integration tests for `as_d3_ir()` on geom_sf plots; covers FEAS-04
- [ ] Install geojsonsf: `install.packages("geojsonsf")` — required before FEAS-02 tests can run without skip annotation

*All test files are new — no existing infrastructure covers sf-specific behaviors.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| IR schema annotated JSON document | FEAS-04 | Documentation artifact, not code | Review `27-IR-SCHEMA.md` for completeness of `geometries[]`, `crs`, `geom_type`, `coord.type`, `coord.bbox` fields |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 15s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
