---
phase: 56-pkgdown-content-and-widget-build-contract
plan: "02"
subsystem: docs
tags: [pkgdown, github-actions, documentation, website]
requires:
  - phase: 56-pkgdown-content-and-widget-build-contract
    provides: Phase context, research, validation strategy, and pattern map
provides:
  - Pkgdown artifact taxonomy in README, diagnostics, and NEWS
  - GitHub Actions website dependency evidence before pkgdown build
affects: [pkgdown, github-actions, docs, release-evidence]
tech-stack:
  added: []
  patterns: [artifact taxonomy, visible dependency classification, setup-r-dependencies route]
key-files:
  created:
    - .planning/phases/56-pkgdown-content-and-widget-build-contract/56-02-SUMMARY.md
  modified:
    - README.Rmd
    - vignettes/d3-drawing-diagnostics.md
    - NEWS.md
    - .github/workflows/pkgdown.yaml
key-decisions:
  - "Preserved setup-r-dependencies with needs: website instead of adding install.packages machinery."
  - "Kept pkgdown generated-site evidence distinct from browser visual smoke artifacts."
patterns-established:
  - "Docs classify source docs, generated docs, GitHub Pages output, and browser smoke by release-readiness question."
  - "The pkgdown workflow reports required and optional website package availability before build."
requirements-completed: [DOCS-03, BUILD-01]
duration: 3min
completed: 2026-05-31
---

# Phase 56-02: Pkgdown Evidence Taxonomy Summary

**Maintainers now have explicit docs and CI output separating pkgdown site evidence from browser visual smoke evidence.**

## Performance

- **Duration:** 3 min
- **Started:** 2026-05-31T19:33:56Z
- **Completed:** 2026-05-31T19:36:18Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Added source/generated/deploy/browser artifact roles to README and diagnostics.
- Added a v1.14 NEWS note for pkgdown publication-surface evidence without claiming new rendering support.
- Added a `Verify website dependencies` workflow step that prints package versions, fails for missing required website packages, and classifies missing optional spatial packages.

## Task Commits

1. **Task 1: Add pkgdown artifact taxonomy to source docs and NEWS** - `8c7827c` (docs)
2. **Task 2: Prove the GitHub Actions website dependency route visibly** - `1a616fe` (ci)

## Files Created/Modified

- `README.Rmd` - Public pointer to pkgdown artifact taxonomy and generated `docs/` role.
- `vignettes/d3-drawing-diagnostics.md` - Maintainer-facing `Pkgdown site evidence` section.
- `NEWS.md` - v1.14 development note for publication-surface evidence.
- `.github/workflows/pkgdown.yaml` - Pre-build website dependency evidence step.

## Decisions Made

The workflow keeps `r-lib/actions/setup-r-dependencies@v2`, `extra-packages: any::pkgdown, local::.`, and `needs: website` as the dependency route. The new step proves what that route produced before invoking pkgdown.

## Deviations from Plan

None - plan executed exactly as written.

**Total deviations:** 0 auto-fixed.
**Impact on plan:** No scope changes.

## Issues Encountered

The first taxonomy `rg` probe used shell double quotes around a pattern containing backticks, which triggered command substitution in zsh. The command was rerun with single quotes and passed; no files were changed because of this.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 56-03 can rebuild README/help/pkgdown output from the edited sources and activate generated-file checks against current `docs/`.

## Self-Check: PASSED

---
*Phase: 56-pkgdown-content-and-widget-build-contract*
*Completed: 2026-05-31*
