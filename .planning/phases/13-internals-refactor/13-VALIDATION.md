---
phase: 13
slug: internals-refactor
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-04
---

# Phase 13 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | testthat 3.0+ (edition 3) — verified in `DESCRIPTION` (`Config/testthat/edition: 3`) |
| **Config file** | `tests/testthat.R` (standard testthat bootstrap) |
| **Quick run command** | `Rscript -e 'pkgload::load_all(); testthat::test_file("tests/testthat/test-ir-<area>.R")'` |
| **Full suite command** | `Rscript -e 'devtools::test()'` (fallback: `Rscript -e 'pkgload::load_all(); testthat::test_dir("tests/testthat")'`) |
| **Estimated runtime** | ~30s full suite (10 test files); ~3–5s per single file |

---

## Sampling Rate

- **After every task commit:** Run the relevant `test-ir-<area>.R` file plus existing `test-ir.R` and `test-validate-ir.R` (cheap; full IR pipeline still exercised).
- **After every plan wave:** Run `Rscript -e 'devtools::test()'` (full suite, all 10+ test files).
- **Before `/gsd-verify-work`:** Full suite must be green AND visual diff on `test_output/` corpus inspected.
- **Max feedback latency:** ~30 seconds (full suite).

---

## Per-Task Verification Map

> Concrete task IDs are filled in by gsd-planner from PLAN.md task lists. The map below is the per-requirement contract; planner expands each row into one entry per task that touches that requirement.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| TBD | TBD | 0 | REFACTOR-01 | — | N/A | unit (stub) | `Rscript -e 'pkgload::load_all(); testthat::test_file("tests/testthat/test-ir-scales.R")'` | ❌ W0 | ⬜ pending |
| TBD | TBD | 0 | REFACTOR-01 | — | N/A | unit (stub) | `... test-ir-theme.R'` | ❌ W0 | ⬜ pending |
| TBD | TBD | 0 | REFACTOR-01 | — | N/A | unit (stub) | `... test-ir-layers.R'` | ❌ W0 | ⬜ pending |
| TBD | TBD | 0 | REFACTOR-01 | — | N/A | unit (stub) | `... test-ir-legends.R'` | ❌ W0 | ⬜ pending |
| TBD | TBD | 0 | REFACTOR-01 | — | N/A | unit (stub) | `... test-ir-facets.R'` | ❌ W0 | ⬜ pending |
| TBD | TBD | 1+ | REFACTOR-01 | — | `as_d3_ir()` ≤ ~200 lines, delegates to extractors | structure | `wc -l R/as_d3_ir.R` + `grep -E 'extract_(scales|theme|layers|legends|facets)_ir' R/as_d3_ir.R` | ✅ exists | ⬜ pending |
| TBD | TBD | 1+ | REFACTOR-02 | — | `calc_element_safe` is the only call site of `ggplot2:::calc_element` | static check | `grep -rn 'ggplot2:::calc_element' R/` matches only `R/ir_theme.R` (or wherever `calc_element_safe` lives) | ✅ exists | ⬜ pending |
| TBD | TBD | 1+ | REFACTOR-02 | — | Public-API fallback when private call errors | unit (mock failure) | `... test-ir-theme.R'` | ❌ W0 | ⬜ pending |
| TBD | TBD | 1+ | REFACTOR-02 | — | Warn-once on fallback per session | unit (`expect_warning` + `expect_silent` on repeat) | `... test-ir-theme.R'` | ❌ W0 | ⬜ pending |
| TBD | TBD | gate | REFACTOR-01/02 (D-09) | — | Behavior preserved on full pipeline | regression | `Rscript -e 'devtools::test()'` | ✅ existing 10 test files | ⬜ pending |
| TBD | TBD | gate | D-11 | — | Visual output unchanged on corpus | manual visual diff | render `test_output/` corpus + eyeball against v1.0 baseline | ✅ baselines exist (gitignored) | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `tests/testthat/test-ir-scales.R` — REFACTOR-01 (scales extractor) stubs
- [ ] `tests/testthat/test-ir-theme.R` — REFACTOR-01 (theme extractor) + REFACTOR-02 (`calc_element_safe` fallback + warn-once) stubs
- [ ] `tests/testthat/test-ir-layers.R` — REFACTOR-01 (layers extractor) stubs
- [ ] `tests/testthat/test-ir-legends.R` — REFACTOR-01 (legends extractor) stubs
- [ ] `tests/testthat/test-ir-facets.R` — REFACTOR-01 (facets extractor) stubs
- [ ] Document/build corpus-rendering harness for `test_output/` visual diff (Open Question 1) — if no script exists, plan must specify a manual diff procedure as the gate

*No new fixtures/conftest needed — testthat uses inline `library(ggplot2)` + built-in datasets per existing convention (see `.planning/codebase/TESTING.md`).*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Visual SVG output unchanged on corpus | D-11 | No automated pixel-diff harness verified in v1.0 (Open Question 1); D3 rendering happens in browser/headless context. | Render every example in `test_output/` corpus before refactor (baseline) and after each plan completes; eyeball-diff against baseline. Surface any visible delta as a regression. |
| `as_d3_ir()` line count ≤ ~200 | REFACTOR-01 | Structural metric, not behavioral. | `wc -l R/as_d3_ir.R`'s top-level function (excluding helpers in same file if any) — manual inspection against the ~200 target. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING test files (5 new `test-ir-*.R` files)
- [ ] No watch-mode flags (`devtools::test()` is one-shot)
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter once planner expands task IDs

**Approval:** pending
