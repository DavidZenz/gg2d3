---
phase: 59-release-hygiene-and-local-spatial-recovery
plan: "01"
subsystem: ci
tags: [github-actions, node24, artifacts, release-hygiene]
requires:
  - phase: 59-release-hygiene-and-local-spatial-recovery
    provides: Phase 59 context and advisory decisions
provides:
  - Node 20 to Node 24 artifact-upload advisory audit
  - Updated pkgdown and browser visual artifact upload action versions
  - Remote workflow evidence handoff for Phase 59 verification
affects: [pkgdown-workflow, browser-visual-smoke, release-evidence]
tech-stack:
  added: []
  patterns: [source-level advisory audit before remote workflow evidence]
key-files:
  created:
    - .planning/phases/59-release-hygiene-and-local-spatial-recovery/59-ACTIONS-ADVISORY.md
  modified:
    - .github/workflows/pkgdown.yaml
    - .github/workflows/browser-visual-smoke.yaml
key-decisions:
  - "Upgrade artifact upload steps to actions/upload-artifact@v6 while preserving artifact behavior."
  - "Classify any remaining advisory only after real workflow evidence in 59-VERIFICATION.md."
patterns-established:
  - "Actions advisory records include source outcome plus next remote evidence step."
requirements-completed:
  - REL-01
duration: 5 min
completed: 2026-06-02
---

# Phase 59 Plan 01: Actions Advisory Hygiene Summary

**Node 20 runtime advisory audit with artifact upload actions moved to `actions/upload-artifact@v6`**

## Performance

- **Duration:** 5 min
- **Started:** 2026-06-02T11:12:13Z
- **Completed:** 2026-06-02T11:17:28Z
- **Tasks:** 3
- **Files modified:** 3

## Accomplishments

- Created `59-ACTIONS-ADVISORY.md` with the Node 20/Node 24 runtime context, workflow audit, mitigation decision, verification plan, and residual risks.
- Updated both artifact upload steps from `actions/upload-artifact@v4` to `actions/upload-artifact@v6`.
- Preserved existing artifact names, paths, `if-no-files-found` behavior, and `retention-days: 14`.

## Task Commits

1. **Tasks 1-3: audit advisory, upgrade artifact upload actions, record source outcome** - `b4e39e8` (chore)

## Files Created/Modified

- `.planning/phases/59-release-hygiene-and-local-spatial-recovery/59-ACTIONS-ADVISORY.md` - Records Actions runtime advisory audit, source outcome, and remote evidence handoff.
- `.github/workflows/pkgdown.yaml` - Uses `actions/upload-artifact@v6` for the pkgdown site artifact.
- `.github/workflows/browser-visual-smoke.yaml` - Uses `actions/upload-artifact@v6` for browser visual smoke artifacts.

## Decisions Made

- Kept `actions/checkout@v6`, r-lib actions, and the pinned JamesIves deploy action unchanged at source level; final warning classification belongs to remote run evidence.
- Preserved artifact behavior exactly while changing only the artifact upload action version.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required for source-level mitigation. Remote workflow evidence still requires authenticated `gh` access and pushed commits in Plan 59-03.

## Next Phase Readiness

Plan 59-03 can now run both workflows after this commit is pushed and record advisory status in `59-VERIFICATION.md`.

## Self-Check: PASSED

- `rtk rg -n "Runtime Context|Workflow Audit|Mitigation Decision|Verification Plan|Residual Risks|Node 20|Node 24|June 16, 2026|actions/upload-artifact@v6" .planning/phases/59-release-hygiene-and-local-spatial-recovery/59-ACTIONS-ADVISORY.md` passed.
- `rtk rg -n "pkgdown.yaml|browser-visual-smoke.yaml|actions/checkout@v6|actions/upload-artifact@v4|r-lib/actions/setup-r@v2|r-lib/actions/setup-r-dependencies@v2|JamesIves" .planning/phases/59-release-hygiene-and-local-spatial-recovery/59-ACTIONS-ADVISORY.md` passed.
- `rtk rg -n "actions/upload-artifact@v6|pkgdown-site-|browser-visual-smoke-|retention-days: 14|if-no-files-found" .github/workflows/pkgdown.yaml .github/workflows/browser-visual-smoke.yaml` passed.
- `rtk rg -n "actions/upload-artifact@v4" .github/workflows/pkgdown.yaml .github/workflows/browser-visual-smoke.yaml` returned no matches.
- `rtk rg -n "source outcome: artifact upload actions upgraded to actions/upload-artifact@v6|source outcome: v6 blocker documented|Run pkgdown.yaml and browser-visual-smoke.yaml after this commit" .planning/phases/59-release-hygiene-and-local-spatial-recovery/59-ACTIONS-ADVISORY.md` passed.

---
*Phase: 59-release-hygiene-and-local-spatial-recovery*
*Completed: 2026-06-02*
