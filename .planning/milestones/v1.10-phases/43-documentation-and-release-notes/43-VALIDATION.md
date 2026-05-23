---
phase: 43
slug: documentation-and-release-notes
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-23
---

# Phase 43 - Validation Strategy

> Per-phase validation contract for documentation and release-note execution.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | R 4.6.0, devtools, roxygen2, testthat 3e, source-level `rtk rg` checks |
| **Config file** | `DESCRIPTION` (`Config/testthat/edition: 3`, `VignetteBuilder: knitr`) |
| **Quick run command** | `rtk Rscript --vanilla -e 'devtools::document(); devtools::build_readme()'` |
| **Full suite command** | `rtk Rscript --vanilla -e 'devtools::document(); devtools::build_readme(); devtools::test()'` |
| **Estimated runtime** | ~30-90 seconds for docs generation and source scans; full suite depends on optional skips |

## Sampling Rate

- **After every task commit:** Run the plan-specific source/doc scans for touched files.
- **After docs source edits:** Run `rtk Rscript --vanilla -e 'devtools::document(); devtools::build_readme()'`.
- **After every plan wave:** Run the plan verification commands, including stale-language and release-notes coverage scans.
- **Before `$gsd-verify-work`:** Run at least the docs generation command and DOC-01/DOC-02 scans. Reuse Phase 42 full gate evidence unless Phase 43 changes examples or test behavior materially.
- **Max feedback latency:** 90 seconds for required Phase 43 checks.

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 43-01-01 | 01 | 1 | DOC-01 | T-43-01 | User-facing docs do not overclaim unsupported map or renderer behavior. | source/doc | `rtk rg -n "polygon-family|point-family|line-family|POLYGON|MULTIPOLYGON|POINT|MULTIPOINT|LINESTRING|MULTILINESTRING|map anti-features|ordinary geom_polygon" README.Rmd README.md vignettes R man` | yes | pending |
| 43-01-02 | 01 | 1 | DOC-01 | T-43-01 | Source docs and generated docs stay aligned. | generation | `rtk Rscript --vanilla -e 'devtools::document(); devtools::build_readme()'` | yes | pending |
| 43-01-03 | 01 | 1 | DOC-01 | T-43-02 | Stale milestone and forbidden browser-stack wording are absent from release-facing docs. | source/doc | `rtk rg -n "The v1\\.9 .*geom_sf\\(\\).* support contract|core Cartesian geoms below plus polygon-family .*geom_sf\\(\\)|Playwright|Puppeteer|Selenium|screenshot-diff|screenshot diff|visual diff" README.Rmd README.md vignettes R man` | yes | pending |
| 43-02-01 | 02 | 2 | DOC-02 | T-43-03 | Release notes summarize outcomes without publishing local logs. | artifact scan | `rtk rg -n "PASSED WITH EXPECTED OPTIONAL SKIPS|817 passed|40 skipped|6 warnings|4 NOTEs|no ERROR/WARNING|Deferred non-blocker|ordinary geom_polygon|rect/tile out-of-bounds|next-milestone" .planning/phases/43-documentation-and-release-notes` | no - created by 43-02 | pending |
| 43-02-02 | 02 | 2 | DOC-02 | T-43-03 | Local artifact paths are referenced only as wildcard debugging locations. | artifact scan | `rtk rg -n "test_output/browser-sf/\\*\\.html|test_output/browser-sf/\\*-console\\.log|test_output/browser-sf/\\*-page-errors\\.log|test_output/browser-sf/\\*-browser-log\\.json|/private/tmp/gg2d3_\\*\\.Rcheck/00check\\.log" .planning/phases/43-documentation-and-release-notes` | no - created by 43-02 | pending |
| 43-02-03 | 02 | 2 | DOC-02 | T-43-03 | Release notes do not paste exact local logs or concrete browser log filenames. | artifact scan | `rtk rg -n "/private/tmp/gg2d3.Rcheck/00check.log|test_output/browser-sf/[A-Za-z0-9_-]+-(console|page-errors|browser-log)\\.(log|json)|Playwright|Puppeteer|Selenium" .planning/phases/43-documentation-and-release-notes/43-RELEASE-NOTES.md; test $? -eq 1` | no - created by 43-02 | pending |

## Wave 0 Requirements

Existing infrastructure covers all phase requirements.

## Manual-Only Verifications

All phase behaviors have automated verification. Optional reviewer judgment remains useful for prose quality, but DOC-01 and DOC-02 acceptance must be backed by source/doc scans and generation commands.

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all missing references
- [x] No watch-mode flags
- [x] Feedback latency < 90s for required checks
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-05-23
