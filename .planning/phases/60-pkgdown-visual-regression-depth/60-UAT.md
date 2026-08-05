---
status: complete
phase: 60-pkgdown-visual-regression-depth
source:
  - 60-01-SUMMARY.md
  - 60-02-SUMMARY.md
  - 60-03-SUMMARY.md
started: 2026-07-24T00:00:00Z
updated: 2026-08-05T10:56:27Z
tests_total: 5
tests_passed: 5
tests_failed: 0
tests_skipped: 0
tests_blocked: 0
---

## Current Test
<!-- OVERWRITE each test - shows where we are -->

number: 5
name: Public site keeps maintainer diagnostics internal
expected: |
  The generated public site does not publish `d3-drawing-diagnostics.html` or
  expose a maintainer diagnostics navbar entry. Public SF and Crosstalk caveats
  remain in the main user-facing vignettes.

## Tests

| # | Name | Result | Notes |
|---|------|--------|-------|
| 1 | Skip behavior when env var is unset | pass | exit 0; one expected skip mentioning GG2D3_BROWSER_VISUAL_SMOKE |
| 2 | Opt-in capture runs and produces artifacts | pass | CI run 30994335555 completed visual capture and uploaded PNG, DOM summary, and browser log artifacts |
| 3 | DOM counts show all widgets rendered | pass | Online approval; CI artifact confirms `widgetCount: 49`, `renderedSvgCount: 49`, `blankWidgetCount: 0`, `geomSfCount: 100`, and `crosstalkGroupCount: 2` |
| 4 | pkgdown.yaml CI wiring is correct | pass | Run 30992820343 succeeded through visual capture, both artifact uploads, and Pages deployment; user approved |
| 5 | Public site keeps maintainer diagnostics internal | pass | Diagnostics article wrapper removed; rebuilt site has no diagnostics article or navbar entry, while the public SF/Crosstalk documentation remains present |

## Issues

(none; the initial diagnostics-article 404 was fixed and verified online)
