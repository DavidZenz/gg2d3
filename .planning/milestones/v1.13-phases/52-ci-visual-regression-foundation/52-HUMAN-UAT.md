---
phase: 52
slug: ci-visual-regression-foundation
created: 2026-05-28T06:44:35Z
completed: 2026-05-28T12:57:46Z
status: passed
pending_count: 0
approved_run: 26575140296
---

# Phase 52 Human UAT

## Completed Checks

1. Trigger `.github/workflows/browser-visual-smoke.yaml` from GitHub Actions using `workflow_dispatch` or by opening/updating a pull request.
   - Result: workflow run `26575140296` passed on commit `4d77eada2a35a4edcfd8bfba0784647e8e48d0f2`.
   - Result: the workflow opted into `GG2D3_BROWSER_VISUAL_SMOKE=true` and `GG2D3_BROWSER_VISUAL_CI=true`.
   - Result: Chrome/chromote was available on the runner and the browser visual smoke test completed.

2. Download/open the uploaded artifact.
   - Result: artifact downloaded to `test_output/github-run-26575140296/browser-visual-smoke-26575140296/`.
   - Result: artifact includes `index.html`, `index.json`, fixture HTML files, PNG screenshots, DOM summaries, and browser log files.
   - Result: `index.json` reports all 9 fixtures passed.

## Visual Approval

Approved after inspecting the regenerated `sf` fixtures:

- `sf-facet-wrap`: red point in A, black line in B, blue polygon/rectangle in C.
- `sf-annotations-text-label`: red text bottom-left, blue text in a white rectangle top-right.
- `sf-annotations-skipped-row`: red `ok` text bottom-left; unsupported row is intentionally skipped.
