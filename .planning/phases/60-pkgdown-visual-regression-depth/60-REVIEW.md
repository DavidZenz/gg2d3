---
phase: 60-pkgdown-visual-regression-depth
reviewed: 2026-07-24T00:00:00Z
depth: standard
files_reviewed: 4
files_reviewed_list:
  - tests/testthat/test-pkgdown-visual.R
  - .github/workflows/pkgdown.yaml
  - vignettes/d3-drawing-diagnostics.md
  - README.md
findings:
  critical: 2
  warning: 4
  info: 2
  total: 8
status: issues_found
---

# Phase 60: Code Review Report

**Reviewed:** 2026-07-24
**Depth:** standard
**Files Reviewed:** 4
**Status:** issues_found

## Summary

Phase 60 adds browser-based visual regression for the generated pkgdown article. The
approach is sound: chromote loads `docs/articles/gg2d3.html`, polls for widgets, evaluates
a JS IIFE for DOM counts, and writes a PNG + two JSON artifacts. The sf / Crosstalk
branching logic is carefully structured and the GitHub Actions workflow inserts the three
new steps in the right order.

Two blockers are present:

1. `actions/checkout@v6` does not exist — v6 is fictional; the current stable release is
   v4. This will cause every pkgdown CI run to fail with an action-resolution error.
2. The Crosstalk `classified_skip` branch performs no DOM verification — the skip notice
   is never confirmed to be visible in the browser, creating a silent false-positive path
   that is asymmetric with the sf branch.

Four warnings cover: the `%||%` operator being used before it is guaranteed to be in
scope when helpers are missing; the `assert_no_browser_visual_errors` call silently
passing when the log collector never fires (the `Runtime.enable()` race); the vignette
claiming `PASS 7` which is wrong when `classified_skip` applies to the Crosstalk branch;
and the `actions/upload-artifact@v6` version being non-existent for the same reason as
checkout.

---

## Critical Issues

### CR-01: `actions/checkout@v6` does not exist — CI will fail on every run

**File:** `.github/workflows/pkgdown.yaml:25`

**Issue:** The step `uses: actions/checkout@v6` references a version tag that does not
exist in the `actions/checkout` repository. GitHub Actions will fail to resolve the
action and every run of the pkgdown workflow will immediately error out before any R
code executes. The current stable major version is `v4`.

The same non-existent version is used in `browser-visual-smoke.yaml:17` (out of scope
for this phase but introduced by the same pattern).

**Fix:**
```yaml
      - uses: actions/checkout@v4
```

---

### CR-02: Crosstalk `classified_skip` branch accepts the outcome without any DOM verification

**File:** `tests/testthat/test-pkgdown-visual.R:175-176`

**Issue:** When `ct_outcome == "classified_skip"`, the test body is an empty comment
with no assertion:

```r
} else if (ct_outcome == "classified_skip") {
  # Accept: skip notice is in place; no DOM assertion required.
}
```

The sf `classified_skip` branch (lines 150-158) correctly verifies the skip notice is
visible in the browser via `innerText.includes('PKGDOWN_SF_OPTIONAL_SKIP')`. The
Crosstalk branch does not perform the symmetric check for
`PKGDOWN_CROSSTALK_OPTIONAL_SKIP`. This creates a silent false-positive: if the
Crosstalk section of the article is genuinely broken (e.g., the skip notice was removed
from the source Rmd), `pkgdown_site_crosstalk_outcome()` reading the disk HTML may still
return `"classified_skip"` based on marker detection in the `.md` companion file, while
the rendered browser page shows a blank or broken section. The test passes without ever
opening a browser assertion.

**Fix:**
```r
} else if (ct_outcome == "classified_skip") {
  has_ct_skip <- eval_js_value(
    session,
    "document.body.innerText.includes('PKGDOWN_CROSSTALK_OPTIONAL_SKIP')"
  )
  testthat::expect_true(
    has_ct_skip,
    label = "Crosstalk skip notice (PKGDOWN_CROSSTALK_OPTIONAL_SKIP) must be visible in page body text"
  )
}
```

---

## Warnings

### WR-01: `%||%` is used inside `.pkgdown_visual_wait_for_widgets` before it is guaranteed to be in scope

**File:** `tests/testthat/test-pkgdown-visual.R:66`

**Issue:** `.pkgdown_visual_wait_for_widgets` is defined at lines 55-68, before the
helper-loading guard at lines 13-22 has had any effect on `%||%`. The guard at line 13
only sources `helper-browser-visual.R` when `skip_browser_visual_smoke` does not exist;
`%||%` is defined inside that helper. When `devtools::test()` runs and helpers are
pre-sourced, `%||%` is available. However if the test file is invoked in a context
where `skip_browser_visual_smoke` already exists (e.g., after a partial environment
load that defines only that function but not `%||%`), the `%||%` fallback at line 66
will throw `"could not find function \"%||%\""`.

The function is only reachable when the opt-in guard passes (line 99 calls
`skip_browser_visual_smoke()` inside the test body, after which `%||%` would be loaded
via the same helper), but the function definition itself executes at parse/source time
and the body refers to `%||%` which R does not validate until call time. This is a
latent reliability issue in `test_file()` invocations that partially pre-load helpers.

**Fix:** Define `%||%` locally at the top of the file (before the function definitions)
with the same guard pattern used in `helper-browser-visual.R`:

```r
if (!exists("%||%", mode = "function")) {
  `%||%` <- function(x, y) if (is.null(x)) y else x
}
```

---

### WR-02: `Runtime.enable()` is called after registering callbacks — callback registration race

**File:** `tests/testthat/helper-browser-visual.R:274`

**Issue:** `browser_visual_console_collector` registers `Runtime.consoleAPICalled` and
`Runtime.exceptionThrown` callbacks (lines 275-302) and then calls
`session$Runtime$enable()` at line 274. In the chromote CDP protocol, events are only
dispatched after `Runtime.enable` is acknowledged. If the sequence is synchronous this
is fine, but chromote uses an async WebSocket under the hood. Events that fire during
page navigation may arrive before the `enable` acknowledgement completes, causing early
console output to be silently dropped. The callbacks are registered before `enable` is
called, which means there is a window where the enable acknowledgement has not yet been
received and events may not be routed.

This is relevant for `test-pkgdown-visual.R` which calls
`browser_visual_console_collector(session)` at line 111 and then navigates immediately
at line 117. JS errors during navigation (before widgets render) will be missed.

The correct order is: call `Runtime.enable()` first and wait for its acknowledgement,
then register the callbacks.

**Fix:**
```r
browser_visual_console_collector <- function(session) {
  logs <- new.env(parent = emptyenv())
  logs$entries <- list()
  append_log <- function(entry) {
    logs$entries[[length(logs$entries) + 1L]] <- entry
  }
  # Enable Runtime domain first and wait for acknowledgement before subscribing
  session$Runtime$enable(wait_ = TRUE)
  session$Runtime$consoleAPICalled(callback_ = function(...) { ... }, wait_ = FALSE)
  session$Runtime$exceptionThrown(callback_ = function(...) { ... }, wait_ = FALSE)
  function() logs$entries
}
```

This is a shared-helper issue but the pkgdown test is the only new test that calls this
collector immediately before navigation.

---

### WR-03: `actions/upload-artifact@v6` does not exist

**File:** `.github/workflows/pkgdown.yaml:107` and `115`

**Issue:** Both `Upload pkgdown visual artifacts` and `Upload pkgdown site artifact`
steps use `actions/upload-artifact@v6`, which does not exist. The current stable version
is `v4`. This is distinct from CR-01 (checkout) but will also cause CI failures once
checkout is fixed.

**Fix:**
```yaml
      - uses: actions/upload-artifact@v4
```
Apply to both lines 107 and 115.

---

### WR-04: Vignette claims `PASS 7` but assertion count varies by sf/Crosstalk branch

**File:** `vignettes/d3-drawing-diagnostics.md:345`

**Issue:** The vignette states:

> Expect `[ FAIL 0 | WARN 0 | SKIP 0 | PASS 7 ]` when Chrome is available and the site
> is built.

Counting assertions in `test-pkgdown-visual.R`:
- 2 core assertions (renderedSvgCount, blankWidgetCount)
- 1 conditional sf assertion (either `expect_gte` for rendered OR `expect_true` for
  classified_skip — always 1)
- 1 conditional Crosstalk assertion (only `expect_gte` for rendered/rendered_unlinked;
  zero assertions for classified_skip per CR-02)
- 1 `assert_no_browser_visual_errors` (internally calls `testthat::fail` only when
  errors exist — 0 passing expectations when no errors)
- 3 artifact existence assertions (PNG, JSON, log)

Total passing expectations when both sf and Crosstalk are `"rendered"` and no JS errors:
2 + 1 + 1 + 3 = 7. But when Crosstalk outcome is `"classified_skip"` the count drops to
6 (the Crosstalk branch has no assertion). And `assert_no_browser_visual_errors` adds
zero pass credits when the log is empty.

The claim of exactly 7 is contingent on both sf and Crosstalk being in the `"rendered"`
path. In CI on ubuntu-latest, both packages are typically available, so this will usually
hold, but the claim is inaccurate as stated for the general case.

**Fix:** Either qualify the claim or remove the exact count:

```markdown
Expect `[ FAIL 0 | WARN 0 | SKIP 0 | PASS 6-7 ]` when Chrome is available and the site
is built (exact count depends on sf/Crosstalk render outcome).
```

---

## Info

### IN-01: `rtk` prefix in public documentation commands is a private developer alias

**File:** `vignettes/d3-drawing-diagnostics.md:75,82,89,125,131,151,181,190`
**File:** `README.md:65,68,72`

**Issue:** Commands documented with the `rtk` prefix (e.g., `rtk Rscript --vanilla
tools/validate-pkgdown-site.R --mode quick`) are only meaningful on machines where the
`rtk` (Rust Token Killer) proxy is installed. This is a personal developer tool not
listed in the package dependencies or development setup instructions. Any contributor or
user following these commands will get `command not found: rtk` on a fresh checkout.
The standard equivalent is `Rscript --vanilla`.

**Fix:** Replace all `rtk Rscript` occurrences with `Rscript` in public-facing
documentation, or add a note that `rtk` can be replaced by `Rscript` directly.

---

### IN-02: `blankWidgetCount` assertion uses `expect_equal` which produces a diff-style failure message rather than `expect_identical` or `expect_lte`

**File:** `tests/testthat/test-pkgdown-visual.R:132-140`

**Issue:** The assertion `testthat::expect_equal(dom_summary$blankWidgetCount, 0L, ...)`
will fail with a numeric diff output when blank widgets are found. The intent is a
zero-check; `expect_equal` also performs near-equality comparison for numerics
(tolerance-based), which is semantically wrong for an integer count. Using
`testthat::expect_identical(dom_summary$blankWidgetCount, 0L)` or
`testthat::expect_lte(dom_summary$blankWidgetCount, 0L)` would be more semantically
precise.

In practice `blankWidgetCount` comes from JavaScript as a plain integer, so the
tolerance issue is unlikely to trigger, but it is a quality defect.

**Fix:**
```r
testthat::expect_identical(
  dom_summary$blankWidgetCount,
  0L,
  label = paste0(
    "all rendered gg2d3 SVG widgets must have >= ",
    .PKGDOWN_VISUAL_SVG_CHILD_THRESHOLD,
    " SVG child elements (path/circle/rect/line/g)"
  )
)
```

---

_Reviewed: 2026-07-24_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
