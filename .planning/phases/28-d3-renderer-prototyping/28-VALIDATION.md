---
phase: 28
slug: d3-renderer-prototyping
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-04
---

# Phase 28 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | testthat 3.x (already configured) |
| **Config file** | `tests/testthat.R` |
| **Quick run command** | `testthat::test_file("tests/testthat/test-sf-ir.R")` |
| **Full suite command** | `devtools::test()` |
| **Estimated runtime** | ~15 seconds |

---

## Sampling Rate

- **After every task commit:** Run `testthat::test_file("tests/testthat/test-sf-ir.R")`
- **After every plan wave:** Run `devtools::test()`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 15 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 28-01-01 | 01 | 0 | REND-03 | unit | `testthat::test_file("tests/testthat/test-sf-renderer.R")` | ❌ W0 | ⬜ pending |
| 28-01-02 | 01 | 1 | REND-01 | unit+visual | `testthat::test_file("tests/testthat/test-sf-ir.R")` | ✅ | ⬜ pending |
| 28-01-03 | 01 | 1 | REND-01 | visual | HTML: `test_output/phase28-nc-choropleth.html` | ❌ W0 | ⬜ pending |
| 28-02-01 | 02 | 1 | REND-01, REND-02 | visual | HTML: `test_output/phase28-world-holes.html` | ❌ W0 | ⬜ pending |
| 28-02-02 | 02 | 1 | REND-03 | visual | Browser devtools inspection of `<path>` fill/stroke attrs | N/A | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `tests/testthat/test-sf-renderer.R` — stubs for REND-03 (aesthetic passthrough verification via IR structure)
- [ ] `test_output/` directory existence (already gitignored; ensure `dir.create("test_output", showWarnings = FALSE)` in visual test scripts)

*Existing `test-sf-ir.R` and `test-sf-utils.R` cover Phase 27 IR correctness and are already passing — no gaps there.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| NC counties render as filled choropleth matching ggplot2 output | REND-01 | Visual shape comparison cannot be automated | Open `test_output/phase28-nc-choropleth.html` in browser; compare side-by-side with `ggplot(nc, aes(fill=BIR74)) + geom_sf()` |
| Multipolygon holes render transparent (not filled) | REND-02 | Hole transparency requires visual inspection | Open `test_output/phase28-world-holes.html`; zoom to Canada/Indonesia; verify interior rings are transparent |
| Fill/stroke hex colors on path elements match IR values | REND-03 | DOM attribute inspection requires browser devtools | Open choropleth HTML; inspect a `<path>` element; verify `fill` attr matches hex value from IR `layer.data[i].fill` |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 15s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
