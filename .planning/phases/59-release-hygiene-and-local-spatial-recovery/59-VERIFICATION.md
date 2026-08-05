---
phase: 59-release-hygiene-and-local-spatial-recovery
verified: 2026-08-05T07:29:26Z
status: partial
score: 2/4 must-haves verified
behavior_unverified: 2
overrides_applied: 0
actions_advisory: mitigated_source_level
local_spatial: diagnosed_classified_skip
pkgdown_quick: passed
browser_visual: classified_skip
remote_workflows: pending_push_and_run_inspection
re_verification:
  previous_status: human_needed
  gaps_closed:
    - "The upload-artifact v6 tag was verified against the official GitHub repository and restored in pkgdown.yaml."
    - "The ledger no longer claims that the current local branch is synchronized with origin/master."
    - "The ledger now records concrete remote run IDs, head SHAs, conclusions, and their limited relevance."
  gaps_remaining:
    - "The corrected local tree is not pushed, so no remote run verifies the current action changes."
human_verification:

  - test: "After pushing the corrected tree, inspect pkgdown.yaml and browser-visual-smoke.yaml runs whose headSha matches the pushed correction commit. Confirm success, artifact upload, and no unclassified runtime advisory."
    expected: "Both workflows complete successfully or classify optional browser/spatial skips explicitly; expected artifacts are uploaded; any remaining advisory is documented as upstream-known."
    why_human: "The current correction is local and the latest remote runs target older SHAs."

  - test: "After pushing, inspect the pkgdown and browser visual artifacts for the matching run IDs."
    expected: "pkgdown-site-<run_id> and browser-visual-smoke-<run_id> are available with the existing paths and retention settings."
    why_human: "Artifact availability is observable only after a workflow run for the corrected SHA."
---

# Phase 59: Release Hygiene And Local Spatial Recovery — Verification Report

**Phase Goal:** Resolve or mitigate release-readiness advisories and make local spatial validation repairable.
**Verified:** 2026-08-05T07:29:26Z
**Status:** human_needed
**Re-verification:** Yes — after security-audit findings were reconciled

## Verification Context

The security audit found stale source and evidence claims. The corrections are recorded
here without treating unpushed work as remote evidence.

- Before this correction, local `HEAD` was `d8738ae2d40b511faeae80e0733e7f4b14bc5fe0`.
- `origin/master` was `26a68990f039fcbcd51dc225d72009eadc21254f`.
- The branch was therefore ahead of origin; the corrected tree still requires a push before current workflow evidence exists.
- Official tag checks confirmed `actions/upload-artifact@v6` and `actions/checkout@v6` exist.

### Latest Remote Evidence Before This Correction

Commands run:

```sh
gh run list --workflow pkgdown.yaml --branch master --limit 5 --json databaseId,status,conclusion,url,headSha,event,createdAt
gh run list --workflow browser-visual-smoke.yaml --branch master --limit 5 --json databaseId,status,conclusion,url,headSha,event,createdAt
```

| Workflow | Run ID | Head SHA | Conclusion | Relevance |
|----------|--------|----------|------------|-----------|
| `pkgdown.yaml` | `29996373249` | `26a68990f039fcbcd51dc225d72009eadc21254f` | success | Latest remote run, but predates the current local correction. |
| `browser-visual-smoke.yaml` | `26575140296` | `4d77eada2a35a4edcfd8bfba0784647e8e48d0f2` | success | Latest remote run, but predates the current local correction. |
| `browser-visual-smoke.yaml` | `26574739539` | `0077ef799b134f51670e3716e7d0523ed2aa8f0c` | failure | Historical run; not evidence for the current tree. |

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | GitHub Actions runtime advisories are resolved through action/runtime updates or recorded as an upstream-known mitigation with a tested workflow outcome. | PRESENT_BEHAVIOR_UNVERIFIED | Both workflows use `actions/upload-artifact@v6`; official tags confirm v6 exists. Current-SHA runtime evidence remains pending push. |
| 2 | Local `sf`/GDAL failure mode is documented with diagnostic commands and repair guidance that explains how to turn local `classified_skip` into rendered sf evidence. | VERIFIED | `tools/diagnose-spatial-stack.R`, the diagnostics vignette, and both README forms contain the diagnostic and repair path. |
| 3 | Pkgdown and browser visual workflows still pass or classify skips explicitly after the release-hygiene changes. | PRESENT_BEHAVIOR_UNVERIFIED | Local workflow source is structurally corrected; the recorded remote runs predate the current correction. |
| 4 | Maintainer docs distinguish local environment repair from package/runtime regressions. | VERIFIED | The vignette explicitly classifies the missing GDAL library as local environment repair, not a gg2d3 regression. |

**Score:** 2/4 truths fully verified; 2/4 remain present but require a run for the corrected SHA.

## Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `.github/workflows/pkgdown.yaml` | v6 checkout and artifact actions with stable artifact settings | VERIFIED | `actions/checkout@v6` and both `actions/upload-artifact@v6` steps; names, paths, warning/error behavior, retention, and deploy cleanup are preserved. |
| `.github/workflows/browser-visual-smoke.yaml` | v6 checkout and artifact actions with stable artifact settings | VERIFIED | `actions/checkout@v6` and `actions/upload-artifact@v6`; artifact name, path, warning behavior, and retention are preserved. |
| `59-ACTIONS-ADVISORY.md` | Current source outcome and remote evidence handoff | VERIFIED | Advisory matches the v6 source state and records that the corrected branch still needs a pushed workflow run. |
| `tools/diagnose-spatial-stack.R` | Package loadability, pkgdown sf outcome, and recommendation markers | VERIFIED | Standalone load checks are guarded and the four stable output markers are present. |
| `vignettes/d3-drawing-diagnostics.md` | Repair commands and skip classification semantics | VERIFIED | The local sf/GDAL diagnostic section distinguishes environment repair from package regression. |
| `README.Rmd` and `README.md` | Discoverable pointer to the diagnostic | VERIFIED | Both README forms point to the command and diagnostics vignette. |

## Behavioral Spot-Checks

| Behavior | Command or evidence | Result | Status |
|----------|---------------------|--------|--------|
| Official artifact action tag | `gh api repos/actions/upload-artifact/tags?per_page=100` | `v6` present | PASS |
| Official checkout action tag | `gh api repos/actions/checkout/tags?per_page=50` | `v6` present | PASS |
| Local branch classification | `git rev-parse HEAD origin/master` | local branch ahead; current correction not pushed | BLOCKED |
| Latest remote workflow evidence | Two `gh run list` commands above | concrete runs recorded, but none match current correction | PARTIAL |
| Local spatial diagnostic | `rtk Rscript --vanilla tools/diagnose-spatial-stack.R` | `sf` loadable 1.1.2; `geojsonsf` loadable 2.0.5; pkgdown sf classified skip; recommendation is to rerun release validation | PASS |
| Pkgdown site tests | Phase 59 self-check | 76 passes | PASS |
| Browser visual smoke | Phase 59 self-check | expected local opt-in skip | CLASSIFIED_SKIP |

## Requirements Coverage

| Requirement | Description | Status | Evidence |
|-------------|-------------|--------|----------|
| REL-01 | Maintainers can run the release workflows without unresolved runtime advisories, or with a documented tested mitigation. | PARTIALLY MET | Source mitigation and advisory are corrected; current-SHA workflow evidence remains pending push. |
| REL-02 | Maintainers can diagnose and repair local sf/GDAL failures to turn `classified_skip` into rendered evidence. | MET | Diagnostic script, vignette, README pointers, and local validation evidence are present. |

## Threat Mitigation

| Threat | Mitigation | Status |
|--------|------------|--------|
| T-59-01: `actions/upload-artifact@v6` runner requirement | Both release workflows use the verified v6 action on `ubuntu-latest`; current-SHA runtime evidence is explicitly pending. | CLOSED |
| T-59-02: advisory classification | Advisory records the current v6 source outcome and the next remote evidence step. | CLOSED |
| T-59-03: artifact upload paths | Artifact names, paths, `if-no-files-found`, and retention are preserved. | CLOSED |
| T-59-04: local spatial classification | Diagnostic command prints package loadability, pkgdown outcome, and recommendation. | CLOSED |
| T-59-05: broken local `sf` load | Quiet `loadNamespace()` and `tryCatch()` guards prevent a dynamic-library error from aborting the diagnostic. | CLOSED |
| T-59-06: stale README pointer | Both README forms carry the diagnostic pointer. | CLOSED |
| T-59-07: final verification ledger | This ledger records exact commands, run IDs, head SHAs, conclusions, classifications, and residual risks. | CLOSED |
| T-59-08: raw workflow/browser logs | Evidence is summarized; the Phase 59 raw-log leakage scan passed. | CLOSED |
| T-59-09: remote workflow blocker | The ahead-of-origin state is recorded as blocked/partial, never as passed current-SHA evidence. | CLOSED |

## Residual Risks

1. The corrected local branch is not pushed. Remote workflow runs must be collected for the pushed correction SHA before release-readiness can be called complete.
2. Local `sf` is now loadable with GDAL 3.13.1, but the checked-in generated site still reports `classified_skip`; rerun release validation after rebuilding the site to collect rendered sf evidence.
3. Other actions may emit runtime advisories; classify them from the matching workflow logs rather than from source inspection alone.

---

*Phase: 59-release-hygiene-and-local-spatial-recovery*
*Verification recorded: 2026-08-05T07:29:26Z*
*Verifier: Codex security correction*
