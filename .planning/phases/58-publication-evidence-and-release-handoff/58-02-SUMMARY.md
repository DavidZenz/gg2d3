---
phase: 58-publication-evidence-and-release-handoff
plan: "02"
subsystem: docs
tags: [pkgdown, publication, release-evidence, readme, news]
requires:
  - phase: 58-publication-evidence-and-release-handoff
    provides: validation-backed pkgdown artifact upload and publication inspector
provides:
  - Publication artifact inspection runbook
  - README pointer to publication inspection
  - Verified release messaging boundary for v1.14 publication evidence
affects: [pkgdown, release-evidence, maintainer-docs]
tech-stack:
  added: []
  patterns: [source-derived README update, command-level maintainer runbook, scoped release wording scan]
key-files:
  created:
    - .planning/phases/58-publication-evidence-and-release-handoff/58-02-SUMMARY.md
  modified:
    - vignettes/d3-drawing-diagnostics.md
    - README.Rmd
    - README.md
key-decisions:
  - "Kept detailed `gh` trigger/download/fallback commands in diagnostics rather than NEWS."
  - "Left NEWS unchanged because it already describes publication-surface evidence without implying new rendering support."
patterns-established:
  - "Downloaded `test_output/github-run-*` artifacts are local inspection evidence and must not be committed."
requirements-completed: [SITE-02, SITE-03]
duration: 3 min
completed: 2026-06-01
---

# Phase 58-02: Publication Inspection Runbook Summary

Maintainer docs now explain how to trigger, download, and inspect pkgdown publication artifacts while keeping release wording scoped to evidence hardening.

## Performance

- **Started:** 2026-06-01T08:23:26Z
- **Completed:** 2026-06-01T08:26:23Z
- **Tasks:** 3
- **Files modified:** 3

## Accomplishments

- Added a `Publication artifact inspection` diagnostics subsection with `gh workflow run`, run lookup, artifact download, inspector command, `gh auth status` fallback, GitHub Actions UI fallback, and `origin/gh-pages` checkout guidance.
- Added a concise README pointer to `tools/inspect-pkgdown-publication.R --site-root <site-root>` and regenerated `README.md` from `README.Rmd`.
- Verified NEWS and public docs avoid phrasing that implies new `geom_sf()`, annotation, renderer, or htmlwidget support.

## Task Commits

1. **Task 1: Add the publication artifact inspection runbook** - `0ecfd76`
2. **Task 2: Add README pointer and regenerate README** - `089c5d8`
3. **Task 3: Verify release messaging boundary** - verification-only; no code change required

## Verification

- `rtk rg -n "Publication artifact inspection|gh workflow run pkgdown.yaml|gh run download <run-id>|inspect-pkgdown-publication|origin/gh-pages" vignettes/d3-drawing-diagnostics.md README.Rmd README.md` - passed.
- `rtk Rscript --vanilla -e 'devtools::build_readme()'` - passed; reported out-of-date dev dependencies `bslib` and `cpp11`.
- `rtk Rscript --vanilla -e 'pattern <- "new (geom_sf|geom_sf_text|geom_sf_label|renderer|htmlwidget) support"; ...'` - passed with no forbidden phrasing.

## Deviations from Plan

Task 3 was verification-only because `NEWS.md` already contained the scoped v1.14 wording: publication-surface evidence without implying new rendering support.

## Issues Encountered

`devtools::build_readme()` reported out-of-date local development dependencies (`bslib`, `cpp11`) but exited successfully and regenerated the README.

## Next Phase Readiness

Plan 58-03 can assemble final release-readiness evidence from the local validation commands, publication inspector, and remote/deploy inspection path. `gh auth status` is still expected to be the main remote-evidence gate.

## Self-Check: PASSED
