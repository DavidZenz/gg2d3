---
status: complete
phase: 60-pkgdown-visual-regression-depth
source:
  - 60-01-SUMMARY.md
  - 60-02-SUMMARY.md
  - 60-03-SUMMARY.md
  - 60-06-SUMMARY.md
started: 2026-08-12T06:52:44Z
updated: 2026-09-30T18:15:26Z
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
| 1 | Skip behavior when env var is unset | pass | The opt-out path exits successfully with the intentional browser-visual skip. |
| 2 | Opt-in capture runs and produces artifacts | pass | Local Chromote classified the unavailable-browser path as the documented skip (`Cannot find an available port`); CI run 30992820343 produced PNG, DOM summary, and browser-log artifacts, and the cache-busted in-app browser review passed. |
| 3 | DOM counts show all widgets rendered | pass | CI DOM summary recorded `widgetCount: 49`, `renderedSvgCount: 49`, `blankWidgetCount: 0`, `geomSfCount: 100`, and `crosstalkGroupCount: 2`; the approved browser review showed the sf tooltip `NAME: Ashe` and `AREA: 0.114`. |
| 4 | pkgdown.yaml CI wiring is correct | pass | The workflow keeps Chrome discovery non-fatal, scopes `GG2D3_BROWSER_VISUAL_CI=true` to capture, and uploads visual artifacts with `if: always()`; run 30992820343 completed capture/uploads/Pages deployment. |
| 5 | Public site keeps maintainer diagnostics internal | pass | Generated-site validation completed with 80 passes; sf and Crosstalk were rendered/interactive, the diagnostics article path was absent, and cleanup deployment run 30999489653 passed. |

## Issues

(none; local Chrome/chromote availability remains an environment caveat, not a product failure)
