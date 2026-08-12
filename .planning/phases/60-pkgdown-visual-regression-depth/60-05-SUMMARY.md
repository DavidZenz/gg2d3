---
phase: 60-pkgdown-visual-regression-depth
plan: "05"
subsystem: testing
tags: [pkgdown, github-actions, chromote, browser-visual, diagnostics]

# Dependency graph
requires:
  - phase: 60-pkgdown-visual-regression-depth
    provides: Opt-in pkgdown browser capture, named-region/live-payload checks, and CI invocation
  - phase: 60-pkgdown-visual-regression-depth
    provides: Named region freshness contracts and full-page artifact expectations
provides:
  - Explicit successful no-browser Chrome discovery in the pkgdown workflow
  - Accurate local-skip and CI capture-failure documentation for maintainers
  - Bounded documentation of named-region DOM and live-payload evidence
affects: [pkgdown workflow, visual regression, VIS-01, VIS-02, VIS-03]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Four-command Chrome discovery exports the first executable through GITHUB_ENV and exits successfully when none is found
    - Browser-unavailable local skips are escalated only by the capture step's GG2D3_BROWSER_VISUAL_CI environment
    - Diagnostics documentation states the named-region/live-payload evidence boundary without claiming perceptual-diff coverage

key-files:
  created:
    - .planning/phases/60-pkgdown-visual-regression-depth/60-05-SUMMARY.md
  modified:
    - .github/workflows/pkgdown.yaml
    - vignettes/d3-drawing-diagnostics.md

key-decisions:
  - "Keep Chrome discovery non-fatal with an explicit exit 0 so the capture step determines CI browser-gate outcome."
  - "Keep GG2D3_BROWSER_VISUAL_CI scoped to the capture step and preserve always-run visual artifact upload."
  - "Describe visual evidence as named-region DOM and live-payload checks, not as a general pixel-fidelity or perceptual-diff guarantee."
  - "Retain the diagnostics vignette as maintainer-only guidance rather than publishing it as a pkgdown article."

patterns-established:
  - "Workflow discovery and capture are separate stages: discovery may succeed without Chrome, while CI capture escalates the shared helper skip."
  - "Optional sf/Crosstalk outcomes are documented as rendered, classified_skip, or missing, with missing treated as a gate failure."

requirements-completed: [VIS-01, VIS-02, VIS-03]

coverage:
  - id: D1
    description: "Pkgdown workflow preserves four distinct Chrome candidates, exports CHROMOTE_CHROME, uses capture-step CI escalation, and always uploads visual artifacts."
    requirement: VIS-03
    verification:
      - kind: unit
        ref: "rtk python3 workflow YAML structure assertion"
        status: pass
    human_judgment: false
  - id: D2
    description: "Diagnostics runbook documents local skips, CI escalation, named-region/live-payload checks, artifacts, and optional outcomes without publishing the diagnostics article."
    requirement: VIS-01
    verification:
      - kind: unit
        ref: "rtk python3 Pkgdown visual regression vignette section assertion"
        status: pass
    human_judgment: false
  - id: D3
    description: "Browser capture remains opt-in locally and escalates unavailable browser execution in CI."
    requirement: VIS-02
    verification:
      - kind: e2e
        ref: "NOT_CRAN=true GG2D3_BROWSER_VISUAL_SMOKE=true testthat::test_file(tests/testthat/test-pkgdown-visual.R)"
        status: unknown
    human_judgment: true
    rationale: "The local run reached the shared browser helper but Chrome/chromote could not launch; a browser-capable CI or maintainer run is still needed for rendered PNG/JSON evidence and CI failure escalation."

# Metrics
duration: 4m
completed: 2026-08-12
status: complete
---

# Phase 60 Plan 05: Pkgdown Visual Regression Depth Summary

**Pkgdown visual regression now has an explicit non-fatal Chrome discovery fallback and a maintainer runbook for local skips, CI escalation, and bounded live-payload evidence.**

## Performance

- **Duration:** 4 min
- **Started:** 2026-08-12T10:25:38Z
- **Completed:** 2026-08-12T10:29:00Z
- **Tasks:** 2 completed
- **Files modified:** 2 task files; 1 planning summary created

## Accomplishments

- Added an explicit `exit 0` to the no-browser branch of `Locate Chrome for chromote (pkgdown visual)` while preserving the four candidate names, `CHROMOTE_CHROME` export, step order, capture invocation, and always-run artifact upload.
- Corrected the `Pkgdown visual regression` runbook to distinguish local browser skips from the capture-step-only `GG2D3_BROWSER_VISUAL_CI=true` failure path in CI.
- Documented named core/sf/Crosstalk regions, SVG child-count checks, widget-to-`application/json` payload matching, optional skip markers, artifact names, and the internal-only diagnostics publication boundary without overclaiming stale detection or pixel parity.

## Task Commits

Each task was committed atomically:

1. **Task 1: Make pkgdown Chrome discovery and CI escalation executable and explicit** - `9658431` (fix)
2. **Task 2: Correct the diagnostics runbook's local and CI contract** - `2f7d991` (docs)

**Plan metadata:** pending final metadata commit.

## Files Created/Modified

- `.github/workflows/pkgdown.yaml` - Explicitly succeeds when no Chrome candidate is found while retaining capture-step CI escalation and artifact upload behavior.
- `vignettes/d3-drawing-diagnostics.md` - Maintainer-facing local/CI runbook for pkgdown visual capture and bounded evidence interpretation.
- `.planning/phases/60-pkgdown-visual-regression-depth/60-05-SUMMARY.md` - This execution summary.

## Decisions Made

- Chrome discovery remains non-fatal; the subsequent capture step is responsible for converting unavailable-browser skips into CI failures.
- `GG2D3_BROWSER_VISUAL_CI` remains scoped only to `Run pkgdown visual capture`, preventing unrelated workflow steps from inheriting the escalation.
- The diagnostics claim is limited to named-region DOM and live-generated-payload checks; pixel baselines and perceptual diffs remain out of scope.
- The diagnostics article remains internal maintainer guidance and is not added to the public pkgdown article surface.

## Verification Results

- Workflow YAML structure assertion — PASS (`PKGDOWN_WORKFLOW_FOUR_DISTINCT_CANDIDATES_OK`).
- Diagnostics vignette section assertion — PASS (`PKGDOWN_DOCS_OK`).
- `git diff --check` on both task files — PASS.
- Opt-in local capture command — PASS through the intended skip path: `[ FAIL 0 | WARN 0 | SKIP 1 | PASS 0 ]`; chromote reported `Cannot find an available port` and Chrome was not runnable. No rendered PNG/JSON artifact was fabricated or inspected.
- A browser-capable CI or maintainer run remains the source of rendered screenshot/DOM artifact evidence and direct confirmation that CI escalation fails the capture step.

## Deviations from Plan

None - plan executed exactly as written. The unavailable local browser followed the planned skip behavior and is recorded as an environment limitation rather than treated as a rendered pass.

## Issues Encountered

- The sandbox initially denied the repository index lock write during the first commit attempt. The same scoped commits succeeded after requesting repository-write permission; no files outside the task scopes were staged.
- Local Chrome/chromote launch is unavailable, so the rendered branch and browser-capable CI conclusion remain unrun. The existing `.planning/WINDOWS.md` entry for this same unrun rendered verification already records the limitation; no duplicate ledger entry was added.

## Known Stubs

None.

## Authentication Gates

None encountered.

## Threat Flags

None. The workflow and documentation changes implement the plan's registered mitigations for fixed browser candidate discovery, scoped CI failure escalation, artifact retention, and internal-only diagnostics guidance.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 60-05 is complete. The workflow and maintainer documentation are aligned; Plan 60-06 can provide the browser-capable human/CI verification for rendered screenshot and DOM-summary evidence. Local `sf`/GDAL and Chrome availability limitations remain documented project concerns.

## Self-Check: PASSED

| Item | Status |
|------|--------|
| Summary file created | FOUND |
| Task commit `9658431` exists | FOUND |
| Task commit `2f7d991` exists | FOUND |
| Workflow and diagnostics files exist | FOUND |
| Static acceptance assertions pass | PASS |
| Browser limitation recorded without fabricated artifacts | PASS |

---
*Phase: 60-pkgdown-visual-regression-depth*
*Plan: 05*
*Completed: 2026-08-12*
