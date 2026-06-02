# Phase 59: Release Hygiene And Local Spatial Recovery - Research

**Researched:** 2026-06-02
**Status:** Complete

## Research Question

What needs to be known to plan Phase 59 well?

## Phase Summary

Phase 59 is maintenance and release hygiene, not new feature expansion. It must:

- Resolve or mitigate GitHub Actions runtime advisory noise for the pkgdown and browser visual workflows.
- Make the local `sf`/GDAL failure mode diagnosable and repairable without treating a machine-local dynamic-library failure as a gg2d3 regression.
- Re-run pkgdown and browser visual gates, then record concise evidence and residual risk.

## Current Workflow Findings

The repository has two active workflow files:

- `.github/workflows/pkgdown.yaml`
- `.github/workflows/browser-visual-smoke.yaml`

Both workflows already use `actions/checkout@v6`. Both still upload artifacts with `actions/upload-artifact@v4`.

GitHub's Node 20 runner deprecation changelog says Node 20 reached EOL in April 2026, runners begin using Node 24 by default on June 16, 2026, and users should update workflows to action versions that run on Node 24. Source: <https://github.blog/changelog/2025-09-19-deprecation-of-node-20-on-github-actions-runners/>

The official `actions/upload-artifact` releases page lists `v6.0.0` as a Node 24 runtime release and notes it requires Actions Runner `2.327.1` or newer. Source: <https://github.com/actions/upload-artifact/releases/tag/v6.0.0>

GitHub-hosted `ubuntu-latest` runners should satisfy the runner-version requirement, but the executor should still verify the current release notes and workflow behavior before considering the advisory closed.

## Local Spatial Findings

Existing helpers already classify generated-site spatial output:

- `pkgdown_site_spatial_loadable()` checks whether `sf` and `geojsonsf` can load.
- `pkgdown_site_sf_outcome()` classifies generated or downloaded pkgdown output as `rendered`, `classified_skip`, or `missing`.
- `tools/validate-pkgdown-site.R` and `tools/inspect-pkgdown-publication.R` already consume those helpers.

The missing piece is a maintainer-oriented diagnostic command that explains the local package loadability state directly, before maintainers infer package regressions from `classified_skip`.

## Implementation Direction

### Actions

Update `actions/upload-artifact@v4` to a current Node 24-capable stable version when viable. As of this research pass, the expected candidate is `actions/upload-artifact@v6`. Keep `actions/checkout@v6`. Audit third-party actions and r-lib actions for any remaining Node 20 warnings during a real workflow run; if a latest viable action still emits warning noise, record it as upstream-known with the tested green run.

### Local Spatial Diagnostics

Add `tools/diagnose-spatial-stack.R` with concise output:

- Package loadability for `sf` and `geojsonsf`.
- `sf::sf_extSoftVersion()` values when `sf` loads.
- Existing pkgdown sf outcome when a site root is available.
- A recommendation that distinguishes local dynamic-library repair from gg2d3 regressions.

Document the command in `vignettes/d3-drawing-diagnostics.md` and point to it from README source if appropriate.

### Evidence

Create a Phase 59 verification ledger that records:

- Actions advisory audit and update/mitigation status.
- Local spatial diagnostic outcome.
- Pkgdown quick validation outcome.
- Focused pkgdown-site test outcome.
- Browser visual smoke local or CI outcome.
- Residual risks, especially any local machine spatial stack issue or upstream action warning that remains.

## Validation Architecture

| Validation ID | Requirement | Threat | Evidence Type | Command Or Probe | Expected Result |
|---------------|-------------|--------|---------------|------------------|-----------------|
| 59-VAL-01 | REL-01 | Node 20 advisory persists silently | workflow/source audit | `rg -n "upload-artifact@v4|upload-artifact@v6|checkout@v6" .github/workflows` | No `upload-artifact@v4` remains unless mitigation is documented. |
| 59-VAL-02 | REL-01 | Updated workflows fail remotely | GitHub Actions check | `gh run list --workflow <workflow> --branch master --limit 5 --json databaseId,status,conclusion,url` | Relevant run concludes `success`, or blocker is recorded. |
| 59-VAL-03 | REL-02 | Local `sf` failure misclassified as package regression | diagnostic command | `rtk Rscript --vanilla tools/diagnose-spatial-stack.R` | Output contains `sf:`, `geojsonsf:`, and `recommendation:`. |
| 59-VAL-04 | REL-02 | Pkgdown sf classification regresses | pkgdown quick validation | `rtk Rscript --vanilla tools/validate-pkgdown-site.R --mode quick` | Exits 0 and reports `sf outcome: rendered` or `classified_skip`. |
| 59-VAL-05 | REL-01, REL-02 | Evidence is unreviewable or raw-log-heavy | verification ledger scan | `rg -n "REL-01|REL-02|Actions advisory|Spatial stack|pkgdown|browser visual|Residual" 59-VERIFICATION.md` | Ledger contains concise evidence sections and no raw bulky logs. |

## Risks And Mitigations

| Risk | Mitigation |
|------|------------|
| `actions/upload-artifact@v6` has a runner-version requirement. | Use GitHub-hosted runners or verify self-hosted runner version before upgrading; record blocker if incompatible. |
| Third-party deploy action still emits advisory noise. | Audit actual run warnings and document upstream-known mitigation if no newer viable action exists. |
| Local `sf` cannot load due to GDAL dynamic-library mismatch. | Diagnostic command reports package loadability and repair guidance; local skip remains classified. |
| Browser visual smoke remains locally browser-dependent. | Phase 59 records pass or explicit skip/classification only; deeper visual capture remains Phase 60. |

## References

- GitHub Actions Node 20 deprecation changelog: <https://github.blog/changelog/2025-09-19-deprecation-of-node-20-on-github-actions-runners/>
- `actions/upload-artifact` releases: <https://github.com/actions/upload-artifact/releases>
- GitHub artifact documentation: <https://docs.github.com/en/actions/tutorials/store-and-share-data>
- `.planning/phases/59-release-hygiene-and-local-spatial-recovery/59-CONTEXT.md`
- `.github/workflows/pkgdown.yaml`
- `.github/workflows/browser-visual-smoke.yaml`
- `tests/testthat/helper-pkgdown-site.R`
- `tools/validate-pkgdown-site.R`
- `tools/inspect-pkgdown-publication.R`

## RESEARCH COMPLETE
