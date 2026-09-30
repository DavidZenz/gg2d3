---
status: partial
phase: 60-pkgdown-visual-regression-depth
source:
  - 60-01-SUMMARY.md
  - 60-02-SUMMARY.md
  - 60-03-SUMMARY.md
started: 2026-08-12T06:52:44Z
updated: 2026-09-30T00:00:00Z
---

## Current Test
<!-- OVERWRITE each test - shows where we are -->

[testing paused — 2 items blocked]

## Tests

### 1. Skip behavior when env var is unset
expected: Running the pkgdown visual test without `GG2D3_BROWSER_VISUAL_SMOKE` exits successfully and reports one intentional skip explaining how to opt in.
result: pass

### 2. Opt-in capture runs and produces artifacts
expected: With the opt-in environment variable enabled and the generated pkgdown site available, the browser capture exits successfully and writes a PNG, DOM summary, and browser log under `test_output/pkgdown-visual/`.
result: blocked
blocked_by: other
reason: "Automated opt-in run exited 0 but skipped before capture because chromote could not launch Chrome: Cannot find an available port. Existing artifacts were not treated as fresh evidence."

### 3. DOM counts show all widgets rendered
expected: The DOM summary reports the representative widgets rendered, `blankWidgetCount: 0`, and the expected sf/Crosstalk outcomes without blank or stale widget regions.
result: blocked
blocked_by: other
reason: "The only available DOM artifact is dated 2026-07-24 and lacks the current freshness/payload fields; a fresh capture could not be produced because chromote could not launch Chrome."

### 4. pkgdown.yaml CI wiring is correct
expected: The workflow installs chromote, locates Chrome non-fatally, runs the visual capture with step-scoped `GG2D3_BROWSER_VISUAL_CI`, and uploads visual artifacts with an always-run guard in the documented order.
result: pass

### 5. Public site keeps maintainer diagnostics internal
expected: The generated public site does not publish `d3-drawing-diagnostics.html` or expose a maintainer diagnostics navbar entry, while public sf and Crosstalk caveats remain in the user-facing documentation.
result: pass

## Summary

total: 5
passed: 3
issues: 0
pending: 0
skipped: 0
blocked: 2

## Gaps

(none yet)
