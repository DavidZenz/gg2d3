---
phase: 60-pkgdown-visual-regression-depth
fixed_at: 2026-07-24T11:27:45Z
review_path: .planning/phases/60-pkgdown-visual-regression-depth/60-REVIEW.md
iteration: 1
findings_in_scope: 6
fixed: 6
skipped: 0
status: all_fixed
---

# Phase 60: Code Review Fix Report

**Fixed at:** 2026-07-24T11:27:45Z
**Source review:** .planning/phases/60-pkgdown-visual-regression-depth/60-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 6
- Fixed: 6
- Skipped: 0

## Fixed Issues

### CR-01: `actions/checkout@v6` does not exist — CI will fail on every run

**Files modified:** `.github/workflows/pkgdown.yaml`
**Commit:** 8ebe695
**Applied fix:** Changed `actions/checkout@v6` to `actions/checkout@v4` at line 25.

---

### CR-02: Crosstalk `classified_skip` branch accepts the outcome without any DOM verification

**Files modified:** `tests/testthat/test-pkgdown-visual.R`
**Commit:** d8c8342
**Applied fix:** Replaced the empty comment-only `classified_skip` branch with a call to `eval_js_value()` checking `document.body.innerText.includes('PKGDOWN_CROSSTALK_OPTIONAL_SKIP')` and an `expect_true()` assertion, symmetric with the sf `classified_skip` branch. This requires human verification that the logic is correct (new condition added).

---

### WR-01: `%||%` is used before it is guaranteed to be in scope

**Files modified:** `tests/testthat/test-pkgdown-visual.R`
**Commit:** 076babd
**Applied fix:** Added a local `%||%` guard (`if (!exists("%||%", mode = "function")) { ... }`) immediately after the package load line, before all helper-loading guards. This ensures `%||%` is always defined regardless of helper sourcing order.

---

### WR-02: `Runtime.enable()` called without waiting for acknowledgement

**Files modified:** `tests/testthat/helper-browser-visual.R`
**Commit:** ca427fb
**Applied fix:** Changed `session$Runtime$enable()` to `session$Runtime$enable(wait_ = TRUE)` in `browser_visual_console_collector`. Added an explanatory comment describing why `wait_ = TRUE` is needed to prevent early console events from being silently dropped. This is a shared helper — the change does not affect existing tests (all callers benefit from the race fix).

---

### WR-03: `actions/upload-artifact@v6` does not exist (both upload steps)

**Files modified:** `.github/workflows/pkgdown.yaml`
**Commit:** eb7e337
**Applied fix:** Changed both occurrences of `actions/upload-artifact@v6` to `actions/upload-artifact@v4` (the "Upload pkgdown visual artifacts" step at line 107 and the "Upload pkgdown site artifact" step at line 115).

---

### WR-04: Vignette claims `PASS 7` but assertion count varies by branch

**Files modified:** `vignettes/d3-drawing-diagnostics.md`
**Commit:** 8da76ee
**Applied fix:** Changed `PASS 7` to `PASS 6-7` and added the qualifier "(exact count depends on sf/Crosstalk render outcome)" to the expected test output line.

---

_Fixed: 2026-07-24T11:27:45Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
