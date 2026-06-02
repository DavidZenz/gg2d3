---
status: partial
actions_advisory: blocked_remote_evidence
local_spatial: diagnosed_classified_skip
pkgdown_quick: passed
browser_visual: classified_skip
remote_workflows: blocked_unpushed_branch
---

# Phase 59 Verification

**Verified:** 2026-06-02
**Scope:** Release hygiene and local spatial recovery (`REL-01`, `REL-02`)

## Commands Run

| Command | Outcome | Evidence |
|---------|---------|----------|
| `rtk Rscript --vanilla tools/diagnose-spatial-stack.R` | Passed | Reported `sf: not_loadable`, `geojsonsf: loadable version 2.0.5`, `pkgdown sf outcome: classified_skip`, and a repair recommendation. |
| `rtk Rscript --vanilla tools/validate-pkgdown-site.R --mode quick` | Passed | Reported `sf outcome: classified_skip` and `crosstalk outcome: rendered`. |
| `rtk Rscript --vanilla -e 'testthat::test_file("tests/testthat/test-pkgdown-site.R")'` | Passed | Focused pkgdown-site test completed with 76 passes, 0 failures, 0 skips. |
| `rtk Rscript --vanilla -e 'testthat::test_file("tests/testthat/test-browser-visual-smoke.R")'` | Classified skip | Local run skipped because `GG2D3_BROWSER_VISUAL_SMOKE=true` was not set. This is expected for local default mode. |
| `git status --short --branch` | Remote evidence blocked | Current branch is `master...origin/master [ahead 7]`; workflow runs for the new action changes cannot be triggered against pushed source yet. |

## Actions Advisory

`REL-01` source-level mitigation is in place:

- `.github/workflows/pkgdown.yaml` now uses `actions/upload-artifact@v6`.
- `.github/workflows/browser-visual-smoke.yaml` now uses `actions/upload-artifact@v6`.
- `59-ACTIONS-ADVISORY.md` records the Node 20 to Node 24 context, workflow audit, source outcome, and remote evidence handoff.

Actions advisory status: **blocked** for final remote evidence because the current branch is ahead of `origin/master` by 7 commits. The source mitigation is ready, but `pkgdown.yaml` and `browser-visual-smoke.yaml` must be run after pushing these commits before the advisory can be classified as resolved or mitigated by workflow evidence.

Current local HEAD: `450689854100ba01a4f19d955a8892374d176555`
Current `origin/master`: `2e026878cfe093c6cf41b763671ab492a4b99656`

## Spatial Stack

`REL-02` local diagnostics are in place and runnable.

The diagnostic command reports:

- `sf` is not loadable locally because the installed `sf` shared object references missing GDAL library `libgdal.38.dylib`.
- `geojsonsf` is loadable at version `2.0.5`.
- The current generated pkgdown sf outcome is `classified_skip`.
- The recommendation is to repair the local sf/GDAL dynamic-library stack before expecting rendered local sf evidence.

This is classified as local environment repair, not a gg2d3 regression.

## Pkgdown And Browser Visual

Pkgdown quick validation passed against the committed generated site and classified local sf as `classified_skip`. Crosstalk evidence remains rendered.

The focused pkgdown-site test passed. Local browser visual smoke was classified as an expected local default skip because the opt-in environment variable was not set. Phase 59 does not require screenshot/widget-region depth; Phase 60 owns that deeper visual evidence.

## Requirement Coverage

| Requirement | Evidence | Status |
|-------------|----------|--------|
| `REL-01` | Source workflow upload action mitigation, advisory audit, remote-evidence blocker recorded. | Partial until pushed workflow runs are inspected. |
| `REL-02` | Spatial diagnostic command, docs, README pointer, local diagnostic output, pkgdown quick classification. | Passed. |

## Threat Mitigation

| Threat | Mitigation | Status |
|--------|------------|--------|
| T-59-01: `actions/upload-artifact@v6` runner requirement | Source updated; remote workflow run still required to prove hosted runner compatibility. | blocked |
| T-59-02: advisory classification | `59-ACTIONS-ADVISORY.md` records source outcome and required next evidence. | passed |
| T-59-03: artifact upload paths | Artifact names, paths, `if-no-files-found`, and retention settings preserved. | passed |
| T-59-04: local spatial classification | Diagnostic command prints package loadability, pkgdown outcome, and recommendation. | passed |
| T-59-05: broken local `sf` load | Diagnostic handles the dynamic-library failure without aborting. | passed |
| T-59-08: raw workflow/browser logs | Verification records concise outcomes only. | passed |

## Residual Risks

- Remote workflow evidence is blocked until the 7 local commits ahead of `origin/master` are pushed. After push, run or inspect `pkgdown.yaml` and `browser-visual-smoke.yaml` and record run IDs, conclusions, SHAs, URLs, and advisory state.
- Local `sf` remains not loadable until the local GDAL/R spatial stack is repaired. Local generated-site evidence remains `classified_skip`; CI or a repaired local machine is needed for rendered local sf proof.
- Local browser visual smoke remains opt-in and skipped by default. This is acceptable for Phase 59; Phase 60 will deepen visual regression evidence.

---

*Phase: 59-release-hygiene-and-local-spatial-recovery*
*Verification recorded: 2026-06-02*
