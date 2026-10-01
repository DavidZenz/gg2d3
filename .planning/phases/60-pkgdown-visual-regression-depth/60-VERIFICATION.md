---
phase: 60-pkgdown-visual-regression-depth
verified: 2026-09-30
status: passed
score: 13/13 must-haves verified
behavior_unverified: 0
overrides_applied: 1
gaps: []
---

# Phase 60: Pkgdown Visual Regression Depth Verification Report

**Phase goal:** Add representative browser visual evidence for pkgdown pages and
widget regions beyond marker checks.

**Result:** **Passed.** The implementation, generated-site checks, CI evidence,
and the final human browser review jointly satisfy VIS-01, VIS-02, and VIS-03.

## Goal Achievement

| # | Observable truth | Status | Evidence |
|---|---|---|---|
| 1 | A repeatable opt-in command captures browser evidence for the built pkgdown article. | PASS | `tests/testthat/test-pkgdown-visual.R` is wired into `.github/workflows/pkgdown.yaml`, writes PNG/DOM/browser-log artifacts, and the approved cache-busted in-app browser review confirmed the current article renders. |
| 2 | The gate detects blank, missing, and stale representative widget regions. | PASS | Named `basic-usage`, `sf-family-maps-with-geom_sf`, and `linked-views-with-crosstalk` contracts require expected widget/SVG counts; each widget must match a current `application/json[data-for]` payload; expected titles, axes, layer/row counts, geometry markers, and live marks are compared with zero freshness mismatches required. |
| 3 | PNG/JSON artifacts are reviewable, deterministic enough for the DOM gate, ignored, and excluded from builds. | PASS | The test writes the three named artifacts under `test_output/pkgdown-visual/`; `.gitignore` and `.Rbuildignore` exclude that path. Rendered captures enforce a readable PNG and height greater than the 900px viewport. |
| 4 | Documentation accurately explains local/CI behavior, locations, and skip classifications. | PASS | `vignettes/d3-drawing-diagnostics.md` documents named-region/live-payload evidence, local skip behavior, CI escalation, artifact paths, and the bounded non-perceptual claim; README source/output carry the scoped pointer. |
| 5 | The main article covers representative core, sf, and Crosstalk regions. | PASS | CI run `30992820343` recorded `widgetCount: 49`, `renderedSvgCount: 49`, `blankWidgetCount: 0`, `geomSfCount: 100`, and `crosstalkGroupCount: 2`; the current cache-busted browser review found the article rendered rather than blank. |
| 6 | The sf branch accepts rendered evidence or an explicit optional skip and fails on missing. | PASS | The generated-site classification was `SF_OUTCOME=rendered`; the browser review showed the sf map tooltip `NAME: Ashe` and numeric `AREA: 0.114`, and the test requires `.geom-sf`/`.geom-sf-group` evidence for the rendered branch. |
| 7 | The Crosstalk branch accepts rendered/unlinked-assets evidence or a classified skip and rejects missing. | PASS | The generated-site classification was `CROSSTALK_OUTCOME=rendered`; CI recorded two Crosstalk groups and the test requires the linked region's two widgets/SVGs and a Crosstalk group marker. |
| 8 | Opt-out and local unavailable-browser paths skip cleanly. | PASS | The opt-out path and local opt-in path both exit successfully with the documented skip classification when Chromote cannot launch Chrome (`Cannot find an available port`). |
| 9 | CI installs chromote. | PASS | `any::chromote` is included in the website dependency setup. |
| 10 | CI runs capture after site build/validation and before deployment. | PASS | Workflow order is build site, validate generated site, locate Chrome, run capture, upload visual artifacts, upload site, deploy. |
| 11 | CI escalation is scoped to capture and artifacts upload with an always-run guard. | PASS | `GG2D3_BROWSER_VISUAL_CI=true` is capture-step scoped; visual artifact upload uses `if: always()` and `test_output/pkgdown-visual/`. |
| 12 | README surfaces the new evidence type and maintainer runbook. | PASS | `README.Rmd` and generated `README.md` contain the same `pkgdown visual regression`, `test_output/pkgdown-visual`, and `d3-drawing-diagnostics.md` markers. |
| 13 | Phase validation records current capture classification and workflow wiring. | PASS | Focused generated-site validation passed with 80 assertions; the summary records `SF_OUTCOME=rendered`, `SF_INTERACTIVITY=interactive`, `CROSSTALK_OUTCOME=rendered`, and `DIAGNOSTICS_ARTICLE_PRESENT=FALSE`; UAT is 5/5 passed. |

**Score:** 13/13 must-haves verified.

## Requirement Coverage

| Requirement | Status | Evidence |
|---|---|---|
| VIS-01 | PASS | CI browser artifact evidence, current generated-site classifications, and the approved in-app browser review cover core, sf, Crosstalk, and browser-visual-smoke-linked content. |
| VIS-02 | PASS | Named-region contracts, live payload matching, expected-content comparisons, SVG child checks, and sf/Crosstalk branch assertions reject blank, detached, missing, or stale representative content. |
| VIS-03 | PASS | Artifact ignore/build exclusion, source-first README pointer, diagnostics runbook, local skip classification, CI escalation semantics, and always-run upload are verified. |

## Human Verification

The final cache-busted browser URL was:

```text
http://127.0.0.1:8765/articles/gg2d3.html?nocache=20260930-2005#sf-family-maps-with-geom_sf
```

The user reviewed the generated article, approved the other plots and checks,
confirmed the sf tooltip, and responded **`perfect, pass`**. The visible sf
tooltip values were:

```text
NAME: Ashe
AREA: 0.114
```

This closes the blocking human checkpoint.

## Evidence Caveats

- The local opt-in Chromote run classified the unavailable browser as a local
  skip; no absent local PNG or JSON was treated as fresh evidence.
- CI run `30992820343` supplied successful DOM/artifact evidence. Its retained
  historical PNG is `1265 x 885` and predates the later full-page artifact
  fields, so it is not claimed as the current D-05 dimension proof. The current
  test enforces the full-page height contract for every future rendered capture,
  while the approved browser review supplies current visual sign-off.
- The diagnostics article remains maintainer-only: generated-site validation
  found `DIAGNOSTICS_ARTICLE_PRESENT=FALSE`, and no public navbar entry was added.
- Any unrelated full-suite sf annotation failures remain outside this phase's
  focused pkgdown gate and were not introduced by the Phase 60 changes.

## Verification Self-Check

| Check | Status |
|---|---|
| Canonical verification report refreshed after the final human approval | PASS |
| Plan 60-06 summary exists and records the approval | PASS |
| UAT records 5/5 passed and 0 blocked | PASS |
| Focused generated-site test | PASS: 80 assertions |
| README source/output pointer | PASS |
| Public diagnostics article/navbar exclusion | PASS |
| Human browser checkpoint | PASS: `perfect, pass` |

---
*Phase: 60-pkgdown-visual-regression-depth*
*Verifier: Codex canonical closeout*
