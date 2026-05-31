# Phase 52: CI Visual Regression Foundation - Pattern Map

**Mapped:** 2026-05-27
**Status:** Complete

## Files To Modify Or Create

| File | Role | Closest Existing Analog | Pattern To Follow |
|------|------|-------------------------|-------------------|
| `tests/testthat/helper-browser-visual.R` | Shared browser artifact/report helper | Same file from Phase 48 | Keep helper-owned functions, static JS strings, `test_output/browser-visual-smoke/` paths, and `testthat` failures/skips. |
| `tests/testthat/test-browser-visual-smoke.R` | Opt-in fixture runner and report assertions | Same file from Phase 48 | Keep one `test_that()` runner, fixture list rows, stable minimum selector counts, and per-row sf skip semantics. |
| `.github/workflows/browser-visual-smoke.yaml` | Dedicated CI workflow | `.github/workflows/pkgdown.yaml` | Use separate workflow, `permissions: read-all`, `runs-on: ubuntu-latest`, `actions/checkout@v6`, `r-lib/actions/setup-r@v2`, and `r-lib/actions/setup-r-dependencies@v2`. |
| `vignettes/d3-drawing-diagnostics.md` | Maintainer docs | Existing `## Browser visual smoke artifacts` section | Update source docs with exact commands, artifact contract, CI inspection, troubleshooting, and pixel deferral. |

## Concrete Existing Patterns

### Browser Artifact Root

`tests/testthat/helper-browser-visual.R` already uses:

```r
browser_visual_artifact_dir <- function() {
  out_dir <- file.path(.test_output_dir(), "browser-visual-smoke")
  dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)
  out_dir
}
```

Phase 52 should keep this root and upload it unchanged from CI.

### Fixture Selector Contract

`tests/testthat/test-browser-visual-smoke.R` already defines per-fixture `expected` selector counts. `capture_browser_visual_fixture()` checks `actual < expected` and fails with:

```r
"Expected at least %s nodes for selector %s in %s; found %s"
```

Phase 52 should preserve minimum-count assertions and add report/index validation around the rows.

### Local Skip Gate

`browser_visual_require_opt_in()` currently skips unless:

```r
identical(Sys.getenv("GG2D3_BROWSER_VISUAL_SMOKE"), "true")
```

Phase 52 should keep this as the local/default gate and add a separate CI-mode distinction for browser-level failures.

### Existing Workflow Style

`.github/workflows/pkgdown.yaml` uses:

```yaml
permissions: read-all
jobs:
  pkgdown:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
      - uses: r-lib/actions/setup-r@v2
      - uses: r-lib/actions/setup-r-dependencies@v2
```

The new workflow should look like a sibling, not a replacement.

## Landmines

- Do not use `git add .`; generated `test_output/` artifacts must stay untracked.
- Do not change `.Rbuildignore` to include `.github`; it already excludes `.github`, `.planning`, `.claude`, and `test_output`.
- Do not source `test-*.R` files from the visual smoke test; those files execute tests as a side effect.
- Do not introduce Playwright, Puppeteer, Selenium, webshot2, Node tooling, pixel diffs, or committed goldens.
- Do not make `CI=true` alone force browser failures; use a dedicated env var so other CI/package checks do not unexpectedly fail browser skips.

## Pattern Mapping Complete
