---
phase: 41
slug: release-blocking-debt-triage
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-23
---

# Phase 41 Validation Strategy

## Test Infrastructure

| Property | Value |
|----------|-------|
| Framework | testthat plus source-level `rtk rg` checks |
| Config file | DESCRIPTION and tests/testthat |
| Quick run command | `rtk Rscript --vanilla -e 'read.dcf("DESCRIPTION"); cat("DESCRIPTION parse ok\n")'` |
| Full suite command | Deferred to Phase 42 release validation |
| Estimated runtime | Under 30 seconds for focused checks |

## Sampling Rate

- After every task commit: run the task's focused `rtk rg` or `rtk Rscript` verification.
- After every plan wave: confirm `41-DEBT-AUDIT.md` contains the expected debt items and statuses.
- Before completion: verify all `DEBT-01` and `DEBT-02` items are covered by plans and audit entries.
- Max feedback latency: 30 seconds for source-level checks.

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 41-01-01 | 01 | 1 | DEBT-01 | T-41-01 | N/A | metadata/source | `rtk Rscript --vanilla -e 'd <- read.dcf("DESCRIPTION"); suggests <- d[1, "Suggests"]; stopifnot(grepl("pkgload", suggests, fixed = TRUE), grepl("rprojroot", suggests, fixed = TRUE))'` | yes | pending |
| 41-01-02 | 01 | 1 | DEBT-01 | T-41-02 | N/A | source | `rtk rg -n "phase35-sf-facet-grid.html|c\\(1L, 0L, 0L, 1L\\)|expect_equal\\(panel_counts, expected_panel_counts" tests/testthat/test-sf-browser.R` | yes | pending |
| 41-02-01 | 02 | 2 | DEBT-02 | T-41-03 | N/A | docs/source | `rtk rg -n "ordinary geom_polygon|geom_sf\\(\\).*polygon-family|unsupported" README.Rmd vignettes/gg2d3.Rmd vignettes/d3-drawing-diagnostics.md` | yes | pending |
| 41-02-02 | 02 | 2 | DEBT-02 | T-41-04 | N/A | docs/source | `rtk rg -n "geom_rect|geom_tile|out-of-bounds|Math\\.abs|clip" vignettes/d3-drawing-diagnostics.md inst/htmlwidgets/modules/geoms/rect.js` | yes | pending |

## Wave 0 Requirements

Existing infrastructure covers all phase requirements.

## Manual-Only Verifications

None. All Phase 41 outcomes are source, metadata, test, or audit-artifact checks.

## Validation Sign-Off

- [ ] All tasks have automated verify commands.
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify.
- [ ] No watch-mode flags.
- [ ] Feedback latency under 30 seconds.
- [ ] `nyquist_compliant: true` set in frontmatter.

Approval: pending
