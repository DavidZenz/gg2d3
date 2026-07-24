---
phase: 60-pkgdown-visual-regression-depth
plan: "03"
subsystem: documentation
tags: [docs, vignette, readme, pkgdown-visual, visual-regression, VIS-03]
status: complete

dependency_graph:
  requires:
    - tests/testthat/test-pkgdown-visual.R (Plan 01)
    - .github/workflows/pkgdown.yaml (Plan 02)
    - vignettes/d3-drawing-diagnostics.md (target)
    - README.md (target)
  provides:
    - vignettes/d3-drawing-diagnostics.md (new ## Pkgdown visual regression section)
    - README.md (updated v1.13 support section with pkgdown visual regression bullet)
    - .planning/phases/60-pkgdown-visual-regression-depth/60-03-SUMMARY.md
  affects: []

tech_stack:
  added: []
  patterns:
    - Documentation placed adjacent to related evidence type (Browser visual smoke artifacts)
    - Explicit scope boundary: DOM-based detection only; pixel/perceptual diff is FUT-01

key_files:
  created: []
  modified:
    - vignettes/d3-drawing-diagnostics.md
    - README.md

decisions:
  - "New vignette section placed adjacent to ## Browser visual smoke artifacts so both related evidence types are readable together"
  - "Perceptual/pixel-diff coverage explicitly negated in vignette text to satisfy the plan prohibition on FUT-01 overclaiming"
  - "README bullet points to the vignette for the full run/CI details rather than duplicating them"
  - "Interactivity article not mentioned as captured anywhere in the new documentation (D-07/D-08)"

metrics:
  duration: "10m"
  completed: "2026-07-24"
  tasks_completed: 2
  tasks_total: 2
  files_created: 0
  files_modified: 2
  tests_passing: 0
---

# Phase 60 Plan 03: Documentation and Validation Evidence Summary

**One-liner:** Added a complete `## Pkgdown visual regression` section to the diagnostics vignette documenting prerequisites, local run command, DOM-based SVG child count detection, sf/Crosstalk skip classification, artifact paths, and CI step order; updated README to surface the new evidence type.

## What Was Built

### Task 1: Documentation (COMPLETE — commit 8a248cf)

**`vignettes/d3-drawing-diagnostics.md`** — new `## Pkgdown visual regression` section
placed adjacent to `## Browser visual smoke artifacts`. Covers:

- **Prerequisite:** `pkgdown::build_site()` must populate `docs/`; test skips with "generated docs site is not available" otherwise (D-02).
- **Local run command:** `NOT_CRAN=true GG2D3_BROWSER_VISUAL_SMOKE=true Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-pkgdown-visual.R")'` — reuses existing opt-in env var (D-10).
- **Detection mechanism:** DOM-based SVG child count (>= 3 per widget, >= 10 total); explicitly NOT pixel/perceptual diff (FUT-01 is future work).
- **sf/Crosstalk classification:** `rendered` or `classified_skip` (PKGDOWN_SF_OPTIONAL_SKIP) semantics matching existing pkgdown-site validation (D-06).
- **Artifacts:** `pkgdown-main-article.png`, `-dom-summary.json`, `-browser-log.json` under `test_output/pkgdown-visual/` (gitignored, Rbuildignored) (D-11).
- **CI behavior:** three new steps in `pkgdown.yaml` (Locate Chrome non-fatal, Run capture with step-scoped `GG2D3_BROWSER_VISUAL_CI`, Upload artifacts with `if: always()`).
- **Scope note:** only `docs/articles/gg2d3.html` captured; interactivity article out of scope (D-07/D-08).

**`README.md`** — new bullet added to the `v1.13 support and validation contract` section noting that pkgdown visual regression evidence (deterministic DOM-based widget-render checks, PNG + JSON artifacts under `test_output/pkgdown-visual/`) supplements the marker-based pkgdown validation, with a pointer to `vignettes/d3-drawing-diagnostics.md`.

### Task 2: Validation Evidence (COMPLETE — human approved)

The human-verify checkpoint was approved after the user confirmed:

1. **Opt-in test passes (or classifies its skip):** The capture test (`test-pkgdown-visual.R`) ran under `NOT_CRAN=true GG2D3_BROWSER_VISUAL_SMOKE=true` and passed, classifying the sf branch as `classified_skip` (PKGDOWN_SF_OPTIONAL_SKIP present due to local GDAL unavailability), which is the expected and accepted local behavior for the sf outcome (D-06).
2. **Artifacts written:** `test_output/pkgdown-visual/pkgdown-main-article.png`, `-dom-summary.json`, and `-browser-log.json` were confirmed written.
3. **DOM counts verified:** `renderedSvgCount >= 10` and `blankWidgetCount == 0` confirmed in `-dom-summary.json`; the PNG screenshot showed pkgdown article rendering gg2d3 widgets (not a blank page).
4. **Full test suite green:** Running the full `tests/testthat/` directory with no smoke env var set confirms the new opt-in test SKIPs cleanly, leaving 0 regressions.
5. **pkgdown.yaml step order correct:** The three new CI steps (Locate Chrome non-fatal, Run capture with step-scoped `GG2D3_BROWSER_VISUAL_CI`, Upload artifacts with `if: always()`) appear in the correct order after the site build step.
6. **Documentation accurate:** The new `## Pkgdown visual regression` vignette section was read and confirmed to match actual test behavior and scope (prerequisites, threshold, artifact paths, skip classification, CI behavior, interactivity article exclusion).

## Tasks

| # | Task | Status | Commit |
|---|------|--------|--------|
| 1 | Document pkgdown visual regression in vignette and README | DONE | 8a248cf |
| 2 | Record pkgdown visual regression validation evidence | DONE | (checkpoint) |

## Verification Results

**Automated grep chain (from plan `<verify>`):**
```
DOC_OK
```

All individual checks passed:
- `grep -q "Pkgdown visual regression" vignettes/d3-drawing-diagnostics.md` — PASS
- `grep -q "test-pkgdown-visual.R" vignettes/d3-drawing-diagnostics.md` — PASS
- `grep -q "test_output/pkgdown-visual" vignettes/d3-drawing-diagnostics.md` — PASS
- `grep -q "GG2D3_BROWSER_VISUAL_SMOKE" vignettes/d3-drawing-diagnostics.md` — PASS
- `grep -q "pkgdown-visual" README.md` — PASS
- `! grep -q "gg2d3-interactivity.html" vignettes/d3-drawing-diagnostics.md` — PASS (interactivity article NOT mentioned)
- `grep -q "PKGDOWN_SF_OPTIONAL_SKIP" vignettes/d3-drawing-diagnostics.md` — PASS
- `grep -q "SVG child" vignettes/d3-drawing-diagnostics.md` — PASS
- `grep -q "DOM-based" vignettes/d3-drawing-diagnostics.md` — PASS
- `grep -i "perceptual" vignettes/d3-drawing-diagnostics.md` — only negating mention ("not pixel brightness, brightness histograms, or perceptual difference scores") — PASS

## Acceptance Criteria Verification

| Criterion | Result |
|-----------|--------|
| `## Pkgdown visual regression` heading present | PASS |
| `test-pkgdown-visual.R` referenced | PASS |
| `test_output/pkgdown-visual` documented | PASS |
| `GG2D3_BROWSER_VISUAL_SMOKE` documented | PASS |
| `PKGDOWN_SF_OPTIONAL_SKIP` documented | PASS |
| SVG child count threshold and DOM-based detection described | PASS |
| `gg2d3-interactivity.html` not referenced in pkgdown-visual section | PASS |
| README contains `pkgdown-visual` reference | PASS |
| Neither file claims perceptual-diff / pixel-threshold coverage | PASS |
| Automated grep chain prints `DOC_OK` | PASS |

## Validation Evidence

Task 2 (`checkpoint:human-verify`) was approved — see "Task 2: Validation Evidence" section above for the complete record of the validated local capture run. The approval satisfies the VIS-03 documentation requirement: maintainers can reproduce the capture, interpret pass/classified_skip/fail, and distinguish the deterministic DOM-based gate from future perceptual-diff work (FUT-01).

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None. Both documentation files accurately reflect the already-built test and CI step.

## Threat Flags

None. Documentation references only local files and the existing opt-in env var; no secrets or credentials appear in docs (T-60-08 accepted).

## Self-Check: PASSED

| Item | Status |
|------|--------|
| `vignettes/d3-drawing-diagnostics.md` modified with `## Pkgdown visual regression` section | FOUND |
| `README.md` modified with pkgdown visual bullet | FOUND |
| Commit `8a248cf` exists | FOUND |
| Automated grep chain prints `DOC_OK` | PASS |
| Task 2 human-verify checkpoint approved | APPROVED |
| Validation evidence recorded in SUMMARY.md | DONE |
| All 2 tasks complete | PASS |
