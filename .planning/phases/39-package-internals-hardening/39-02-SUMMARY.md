---
phase: 39-package-internals-hardening
plan: 02
subsystem: internals
tags: [ggplot2, compatibility, theme, layout, ir]
requires:
  - phase: 39-package-internals-hardening
    provides: "39-01 sf helper boundaries"
provides:
  - "internal ggplot2 compatibility wrappers"
  - "characterization tests for theme and panel parameter access"
  - "as_d3_ir() call sites free of raw private ggplot2 access"
affects: [as_d3_ir, layout, legends, date-scales, coord-flip]
tech-stack:
  added: []
  patterns: ["ggplot2 compatibility helper quarantine", "version-sensitive panel access wrappers"]
key-files:
  created:
    - R/ggplot2_compat.R
    - tests/testthat/test-ggplot2-compat.R
  modified:
    - R/as_d3_ir.R
key-decisions:
  - "Private ggplot2 calls remain only in R/ggplot2_compat.R with inline comments because no exported equivalent exists."
  - "Panel label and continuous range extraction now route through small compatibility helpers."
patterns-established:
  - "gg2d3_plot_theme() and gg2d3_calc_element() quarantine private ggplot2 theme access."
  - "gg2d3_panel_axis(), gg2d3_continuous_range(), and gg2d3_panel_labels() guard version-sensitive panel params."
requirements-completed: [HARD-02]
duration: 4min
completed: 2026-05-22
---

# Phase 39 Plan 02: ggplot2 Compatibility Summary

**ggplot2 private/theme/layout access centralized behind tested internal compatibility wrappers**

## Performance

- **Duration:** 4 min
- **Started:** 2026-05-22T11:30:00Z
- **Completed:** 2026-05-22T11:33:56Z
- **Tasks:** 3
- **Files modified:** 3

## Accomplishments

- Added `R/ggplot2_compat.R` with wrappers for theme resolution, element calculation, panel axes, continuous ranges, and panel labels.
- Added `tests/testthat/test-ggplot2-compat.R` covering wrapper fallbacks and representative ggplot2 panel access.
- Replaced raw private ggplot2 theme access in `R/as_d3_ir.R` with compatibility wrappers while preserving layout, legend, date-scale, and coord_flip behavior.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add ggplot2 compatibility characterization tests** - `7f04778` (test)
2. **Task 2: Implement compatibility helpers and replace private theme access** - `9782634` (refactor)
3. **Task 3: Protect layout, legend, date, and coord_flip behavior after wrapper adoption** - `4e5e2c8` (chore)

## Files Created/Modified

- `R/ggplot2_compat.R` - Internal wrappers around private or version-sensitive ggplot2 access.
- `R/as_d3_ir.R` - Uses compatibility helpers for theme and panel param extraction.
- `tests/testthat/test-ggplot2-compat.R` - Characterization coverage for wrapper behavior.

## Decisions Made

- Kept the two unavoidable `ggplot2:::` calls in the compatibility helper only, with inline comments explaining the lack of exported alternatives.
- Preserved existing fallback values: legend position `"right"`, panel spacing `7.3`, and legend key size `23`.

## Deviations from Plan

None - plan executed exactly as written.

---

**Total deviations:** 0 auto-fixed.
**Impact on plan:** No scope change.

## Issues Encountered

- `rtk rg -n "ggplot2:::" R` still finds two matches by design, both inside `R/ggplot2_compat.R` and accompanied by inline comments explaining the private-access boundary.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Wave 3 can now add a bounded cross-surface regression gate against the hardened sf and ggplot2 compatibility seams.

## Self-Check: PASSED

- `rtk Rscript --vanilla -e 'testthat::test_file("tests/testthat/test-ggplot2-compat.R")'`
- `rtk Rscript --vanilla -e 'testthat::test_file("tests/testthat/test-layout.R"); testthat::test_file("tests/testthat/test-legends.R"); testthat::test_file("tests/testthat/test-date-scales.R"); testthat::test_file("tests/testthat/test-coord-flip.R")'`
- `rtk rg -n "ggplot2:::" R/as_d3_ir.R` found no matches.
- `rtk rg -n "ggplot2:::" R` finds only commented compatibility-helper calls in `R/ggplot2_compat.R`.

---
*Phase: 39-package-internals-hardening*
*Completed: 2026-05-22*
