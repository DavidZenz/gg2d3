---
phase: "59"
phase_name: "release-hygiene-and-local-spatial-recovery"
depth: standard
files_reviewed: 4
files_reviewed_list:
  - .github/workflows/pkgdown.yaml
  - .github/workflows/browser-visual-smoke.yaml
  - tools/diagnose-spatial-stack.R
  - vignettes/d3-drawing-diagnostics.md
findings:
  critical: 0
  warning: 3
  info: 4
  total: 7
status: issues_found
---

# Phase 59: Code Review Report

**Reviewed:** 2026-07-23T00:00:00Z
**Depth:** standard
**Files Reviewed:** 4
**Status:** issues_found

## Summary

Four files were reviewed: two GitHub Actions workflows (`pkgdown.yaml`, `browser-visual-smoke.yaml`), the spatial-stack diagnostics tool (`tools/diagnose-spatial-stack.R`), and the D3 drawing diagnostics vignette. The workflows are structurally sound and follow the r-lib template conventions. The diagnostics tool works correctly but carries a hidden coupling to a testthat internal helper that will silently break if that helper is moved or renamed. No security vulnerabilities or data-loss risks were found. Three warnings and four informational items are recorded below.

---

## Warnings

### WR-001 · Warning: diagnose-spatial-stack.R sources a testthat internal helper at runtime

**File:** `tools/diagnose-spatial-stack.R:69`

**Issue:** The tool does `source(file.path(root, "tests", "testthat", "helper-pkgdown-site.R"))` and then calls `pkgdown_site_sf_outcome()` which is defined there. This couples a user-facing CLI diagnostic to a testthat helper file that has no stability contract outside the test suite. If that helper is renamed, restructured, or its `pkgdown_site_sf_outcome()` signature changes, `diagnose-spatial-stack.R` breaks silently at the `source()` call or at the subsequent function call with no clear error pointing to the coupling. The helper also pulls in `testthat::skip_if_not()` and `testthat::expect_true()` call sites, which means loading the helper as a side effect in a non-test context requires testthat to be installed.

**Fix:** Either (a) move the `pkgdown_site_sf_outcome()` logic into a standalone internal helper under `tools/` that both the test helper and the diagnostic script source, or (b) inline the minimal sf-outcome logic directly in `diagnose-spatial-stack.R` so it has no cross-directory dependency on the test suite. Option (b) is ~20 lines of HTML text scanning and avoids any new shared file.

---

### WR-002 · Warning: browser-visual-smoke exit-status check uses vectorized OR and misses top-level R errors

**File:** `.github/workflows/browser-visual-smoke.yaml:44`

**Issue:** The inline Rscript is:
```
res <- testthat::test_file(...); df <- as.data.frame(res); if (any(df$failed > 0 | df$error)) quit(status = 1)
```
Two problems: (1) `|` is the vectorized bitwise OR; `any(df$failed > 0 | df$error)` happens to work because `any()` collapses the result, but the scalar `||` is the correct operator for this intent and the current form is fragile if `df$error` is not a logical vector. (2) If `testthat::test_file()` itself throws an uncaught top-level R error (e.g., package fails to load), the `as.data.frame(res)` call will fail before `quit(status = 1)` is reached. The shell step will still exit non-zero from the R error, but the exit-code path is accidental rather than deliberate, and the error output will not be attributed to a test failure.

**Fix:**
```bash
Rscript --vanilla -e '
  tryCatch({
    pkgload::load_all(quiet=TRUE)
    res <- testthat::test_file("tests/testthat/test-browser-visual-smoke.R")
    df <- as.data.frame(res)
    if (any(df$failed > 0) || any(df$error)) quit(status = 1)
  }, error = function(e) { message("FATAL: ", conditionMessage(e)); quit(status = 1) })
'
```

---

### WR-003 · Warning: pkgdown workflow `clean: false` will accumulate stale gh-pages content

**File:** `.github/workflows/pkgdown.yaml:88`

**Issue:** The `JamesIves/github-pages-deploy-action` is configured with `clean: false`. This means files removed from the built `docs/` directory are never deleted from the `gh-pages` branch. Over time, renamed articles, removed reference pages, and old asset paths will persist on the published site as orphaned HTML. Users visiting old URLs will receive stale rendered content rather than a 404, and the published site will silently diverge from the current package documentation.

**Fix:** Change `clean: false` to `clean: true` unless there is a deliberate reason to preserve orphaned files (e.g., external inbound links to legacy article paths). If specific paths must be preserved, use the `clean-exclude` option.

---

## Info

### IN-001 · Info: Workflow `name` fields set to the literal filename

**File:** `.github/workflows/pkgdown.yaml:11`, `.github/workflows/browser-visual-smoke.yaml:5`

**Issue:** Both workflows set `name:` to the literal filename (`pkgdown.yaml`, `browser-visual-smoke.yaml`). GitHub Actions displays this value in the Actions tab, PR status check labels, and notification emails. The filename-as-name produces redundant labels in the UI (e.g., the check appears as "pkgdown.yaml / pkgdown").

**Fix:** Use descriptive names: `name: pkgdown` and `name: Browser visual smoke` (or longer equivalents). The r-lib template from which these were derived uses `name: pkgdown` for the pkgdown workflow.

---

### IN-002 · Info: diagnose-spatial-stack.R calls setwd() as a process-level side effect

**File:** `tools/diagnose-spatial-stack.R:67`

**Issue:** `setwd(root)` mutates the working directory for the entire R process. When the script is executed standalone this has no visible impact, but if it were ever sourced from another script (e.g., in a composite tool), the caller's working directory would be silently changed. The script already has `root` available as a variable; the `setwd()` is only needed because downstream calls use relative paths.

**Fix:** Remove `setwd(root)` and pass `root` explicitly to all path-building calls. The `source()` call at line 69 already uses an absolute path, so the only consumer of the implicit working directory is the `site_root_input` resolution block at lines 72-78, which can be rewritten to use `file.path(root, site_root_input)` directly.

---

### IN-003 · Info: --site-root path rejection is silent

**File:** `tools/diagnose-spatial-stack.R:71-78`

**Issue:** If the user passes `--site-root /nonexistent/path`, neither `dir.exists(site_root_input)` nor `dir.exists(file.path(root, site_root_input))` will match, `site_root` becomes `NULL`, and the script reports `pkgdown sf outcome: site_root_unavailable` with no message indicating that the given path was not found. The user may not realize their argument was silently discarded and may interpret `site_root_unavailable` as a site-build problem rather than a path-resolution problem.

**Fix:** Add an explicit warning when the user provided a `--site-root` value that could not be resolved:
```r
if (!is.null(value_after("--site-root")) && is.null(site_root)) {
  warning("--site-root path not found: ", site_root_input, "; reporting site_root_unavailable", call. = FALSE)
}
```

---

### IN-004 · Info: Vignette embeds a hardcoded release version number

**File:** `vignettes/d3-drawing-diagnostics.md:18`

**Issue:** The vignette refers to "v1.13 release validation" and "v1.13 future-work IDs" throughout. When the package version advances, this vignette content will describe a past release without any indication that it is historical. Embedded version numbers in vignette prose create a recurring maintenance gap — the prose will drift from the actual package version unless every release includes a vignette edit.

**Fix:** Replace hardcoded version references with relative language ("current release", "this release") or limit the version reference to a clearly dated historical note. The future-work ID block (FUT-01 through FUT-06) can remain version-independent by removing the "v1.13" prefix from the section heading.

---

_Reviewed: 2026-07-23T00:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
