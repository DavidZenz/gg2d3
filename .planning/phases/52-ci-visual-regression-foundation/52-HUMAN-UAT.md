---
phase: 52
slug: ci-visual-regression-foundation
created: 2026-05-28T06:44:35Z
status: pending
pending_count: 2
---

# Phase 52 Human UAT

## Pending Checks

1. Trigger `.github/workflows/browser-visual-smoke.yaml` from GitHub Actions using `workflow_dispatch` or by opening/updating a pull request.
   - Expected: the workflow opts into `GG2D3_BROWSER_VISUAL_SMOKE=true` and `GG2D3_BROWSER_VISUAL_CI=true`.
   - Expected when Chrome/chromote is available: the browser visual smoke test runs and uploads a `browser-visual-smoke-${run_id}` artifact.
   - Expected when Chrome/chromote is unavailable: the workflow fails rather than silently skipping browser-level setup.

2. Download/open the uploaded artifact.
   - Expected files: `index.html`, `index.json`, fixture HTML files, PNG screenshots, DOM captures, and browser log files under `test_output/browser-visual-smoke/`.
   - Expected report content: metadata includes CI/run fields and browser metadata; rows include screenshot, DOM, HTML, browser log paths, and explicit skip reasons only for optional spatial dependencies.

## Approval Prompt

Reply `approved` if the GitHub Actions artifact behavior matches the expectations above, or describe the mismatch and Phase 52 should reopen a gap-fix task.
