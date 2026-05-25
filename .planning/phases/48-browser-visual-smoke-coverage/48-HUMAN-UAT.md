---
status: partial
phase: 48-browser-visual-smoke-coverage
source: [48-VERIFICATION.md]
started: 2026-05-25T19:34:25Z
updated: 2026-05-25T19:34:25Z
---

## Current Test

awaiting human testing

## Tests

### 1. Browser-available artifact run

expected: The full browser visual smoke command runs on a machine where chromote can launch Chrome, then `test_output/browser-visual-smoke/index.html` lists representative non-skipped fixture rows with linked HTML, PNG screenshot, DOM summary JSON, and browser-log JSON artifacts.

command:

```bash
NOT_CRAN=true GG2D3_BROWSER_VISUAL_SMOKE=true Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-browser-visual-smoke.R")'
```

result: pending

### 2. Visual inspection

expected: Generated screenshots and linked HTML show plausible visible marks for Cartesian, facet, interactivity, polygon, sf, and sf annotation fixtures, with browser logs available for failures.

result: pending

## Summary

total: 2
passed: 0
issues: 0
pending: 2
skipped: 0
blocked: 0

## Gaps
