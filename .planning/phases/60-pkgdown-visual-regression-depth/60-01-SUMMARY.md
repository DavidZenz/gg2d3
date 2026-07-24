---
phase: 60-pkgdown-visual-regression-depth
plan: "01"
subsystem: test-infrastructure
tags: [browser-visual, chromote, pkgdown, dom-assertion, blank-detection]
status: complete

dependency_graph:
  requires:
    - tests/testthat/helper-browser-visual.R
    - tests/testthat/helper-pkgdown-site.R
    - docs/articles/gg2d3.html (built pkgdown site)
  provides:
    - tests/testthat/test-pkgdown-visual.R
    - test_output/pkgdown-visual/ (at test run time)
  affects: []

tech_stack:
  added: []
  patterns:
    - DOM-based SVG child count blank detection for htmlwidget renders
    - File-private .pkgdown_* helpers isolated from shared browser-visual helper
    - sf/Crosstalk outcome branching (rendered vs classified_skip vs missing)

key_files:
  created:
    - tests/testthat/test-pkgdown-visual.R
  modified: []

decisions:
  - "SVG child count threshold set to 3L (.PKGDOWN_VISUAL_SVG_CHILD_THRESHOLD) per CONTEXT.md Claude's discretion; documented as adjustable"
  - "Viewport screenshot (no selector) used per RESEARCH Open Question 2 to avoid oversized full-page capture"
  - "poll timeout = 30s, min_svg_count = 10 for 13MB page with 48 widgets (delay = 2 after go_to)"
  - "sf outcome was classified_skip locally (GDAL unavailable); test correctly accepted PKGDOWN_SF_OPTIONAL_SKIP path"
  - "Crosstalk outcome was rendered; crosstalkGroupCount = 2 confirmed via DOM summary"

metrics:
  duration: "22m"
  completed: "2026-07-24"
  tasks_completed: 1
  tasks_total: 1
  files_created: 1
  files_modified: 0
  tests_passing: 7
---

# Phase 60 Plan 01: Pkgdown Visual Browser Capture Summary

**One-liner:** Opt-in chromote test for docs/articles/gg2d3.html that asserts 48/48 widgets render (SVG child count >= 3) and writes PNG + DOM-summary + browser-log artifacts.

## What Was Built

A new `tests/testthat/test-pkgdown-visual.R` containing test BVIS-PKG-01. It is the end-to-end tracer for Phase 60: loads the pre-built pkgdown article in a headless 1280x900 Chromote session, waits for >= 10 widget SVGs to appear (polling every 0.25s, 30s timeout), evaluates a JS IIFE to collect per-widget SVG child counts, asserts `renderedSvgCount >= 10` and `blankWidgetCount == 0`, branches on sf and Crosstalk outcomes, writes three artifacts to `test_output/pkgdown-visual/`, and skips cleanly when `GG2D3_BROWSER_VISUAL_SMOKE` is unset.

## Tasks

| # | Task | Status | Commit |
|---|------|--------|--------|
| 1 | End-to-end pkgdown visual capture — one article, one path, committed | DONE | 8a244bf |

## Verification Results

**Opt-in run (GG2D3_BROWSER_VISUAL_SMOKE=true):**
- `[ FAIL 0 | WARN 0 | SKIP 0 | PASS 7 ]`
- All 48 widgets rendered (`widgetCount: 48`, `renderedSvgCount: 48`)
- `blankWidgetCount: 0` (all widgets have >= 3 SVG children)
- sf outcome: `classified_skip` (GDAL unavailable locally) — PKGDOWN_SF_OPTIONAL_SKIP path accepted correctly
- Crosstalk outcome: `rendered` — `crosstalkGroupCount: 2` confirmed

**Skip-when-unset run (no env var):**
- `[ FAIL 0 | WARN 0 | SKIP 1 | PASS 0 ]`
- Reason: "Set GG2D3_BROWSER_VISUAL_SMOKE=true to generate browser visual smoke artifacts"

**Artifacts created:**
- `test_output/pkgdown-visual/pkgdown-main-article.png` (111KB viewport screenshot)
- `test_output/pkgdown-visual/pkgdown-main-article-dom-summary.json` (643 bytes)
- `test_output/pkgdown-visual/pkgdown-main-article-browser-log.json` (326 bytes)

## Acceptance Criteria Verification

| Criterion | Result |
|-----------|--------|
| Contains `test_that("BVIS-PKG-01` | PASS |
| Contains `.gg2d3.html-widget svg` and NOT `saveWidget` | PASS |
| Contains `pkgdown_site_sf_outcome()` and `PKGDOWN_SF_OPTIONAL_SKIP` | PASS |
| Contains `blankWidgetCount` and `.PKGDOWN_VISUAL_SVG_CHILD_THRESHOLD` | PASS |
| NOT contains `.html-widget-container` | PASS |
| NOT contains `gg2d3-interactivity.html` | PASS |
| Opt-in run exits 0 and produces 3 artifacts | PASS |
| No-opt-in run reports SKIP | PASS |
| `helper-browser-visual.R` unchanged | PASS |

## File-Private Members Created

| Member | Type | Description |
|--------|------|-------------|
| `.PKGDOWN_VISUAL_SVG_CHILD_THRESHOLD` | constant | Integer 3L; minimum SVG children for non-blank widget |
| `pkgdown_visual_artifact_dir()` | function | Returns/creates `test_output/pkgdown-visual/` |
| `.pkgdown_visual_wait_for_widgets()` | function | Polls for >= N widget SVGs with timeout |
| `.pkgdown_visual_dom_summary_script()` | function | JS IIFE for per-widget SVG child counts + summary |

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None. All DOM assertions use live data from the built pkgdown article.

## Threat Flags

None. The test loads only a locally-built `file://` URL; no new external network surfaces.

## Self-Check: PASSED

| Item | Status |
|------|--------|
| `tests/testthat/test-pkgdown-visual.R` exists | FOUND |
| `60-01-SUMMARY.md` exists | FOUND |
| Commit `8a244bf` exists | FOUND |
