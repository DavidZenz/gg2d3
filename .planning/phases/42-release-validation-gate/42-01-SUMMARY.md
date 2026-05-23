---
phase: 42-release-validation-gate
plan: "01"
subsystem: testing
tags: [release-gate, testthat, r-cmd-check, chromote, documentation]
requires:
  - phase: 40-package-hygiene
    provides: optional browser/spatial skip semantics and generated artifact boundaries
  - phase: 41-release-blocking-debt-triage
    provides: release-blocking debt classifications and deferred non-blocker rationale
provides:
  - phase-local release validation gate contract
  - quick and full maintainer command tiers
  - optional skip, coverage matrix, and artifact path documentation
affects: [phase-42-release-validation-gate, phase-43-documentation-and-release-notes]
tech-stack:
  added: []
  patterns: [two-tier release validation gate, behavior-to-artifact coverage matrix]
key-files:
  created:
    - .planning/phases/42-release-validation-gate/42-VALIDATION-GATE.md
    - .planning/phases/42-release-validation-gate/42-01-SUMMARY.md
  modified: []
key-decisions:
  - "42-01: Documented the release gate as fixed maintainer commands rather than adding executable wrapper scripts."
  - "42-01: Preserved Phase 40 optional browser/spatial skip semantics as expected evidence when messages are explicit."
patterns-established:
  - "Release validation is documented as quick and full tiers with exact rtk-prefixed commands."
  - "Coverage claims must map behavior areas to requirement IDs, test/source files, expected skips, and failure artifacts."
requirements-completed: [VAL-01, VAL-02, VAL-03]
duration: 3m
completed: 2026-05-23
---

# Phase 42 Plan 01: Release Validation Gate Summary

**Two-tier local release validation contract with preserved browser/spatial skip semantics and artifact-backed coverage mapping**

## Performance

- **Duration:** 3m
- **Started:** 2026-05-23T18:44:08Z
- **Completed:** 2026-05-23T18:47:09Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Created `.planning/phases/42-release-validation-gate/42-VALIDATION-GATE.md` with the exact quick local gate and full release gate commands.
- Documented the preserved optional skip order from `skip_browser_sf_smoke()` and classified explicit optional browser/spatial skips as non-blocking release evidence.
- Added a coverage matrix linking VAL-01, VAL-02, and VAL-03 to concrete test/source files and failure artifacts.
- Listed actionable browser smoke, package check, and documentation generation artifact paths.

## Task Commits

1. **Task 1: Define quick and full release gate commands** - `17fff38` (docs)
2. **Task 2: Document expected skips and coverage matrix** - `d9ad81e` (docs)

## Files Created/Modified

- `.planning/phases/42-release-validation-gate/42-VALIDATION-GATE.md` - Maintainer-facing release gate commands, skip semantics, coverage matrix, artifact paths, evidence files, and out-of-scope boundaries.
- `.planning/phases/42-release-validation-gate/42-01-SUMMARY.md` - Execution summary for plan 42-01.

## Decisions Made

- Kept the gate as documentation-only fixed commands, satisfying T-42-01-01 without introducing a shell script that interpolates user input.
- Kept browser artifacts local and under ignored `test_output/browser-sf/` paths, satisfying T-42-01-02 without instructing maintainers to publish logs.
- Preserved the explicit `DESCRIPTION` version lookup before `R CMD check` so future version changes do not require maintainers to infer tarball naming.

## Verification

Commands run:

```bash
rtk rg -n "Quick Local Gate|Full Release Gate|devtools::document\(\)|devtools::build_readme\(\)|devtools::test\(\)|R CMD build --no-manual|R CMD check --as-cran|Replace gg2d3_0.0.0.9000.tar.gz" .planning/phases/42-release-validation-gate/42-VALIDATION-GATE.md
rtk rg -n "skip_if_not_installed\(\"chromote\", \"0.5.1\"\)|skip_if_not_installed\(\"sf\"\)|skip_if_not_installed\(\"geojsonsf\"\)|Chrome/Chromium not available|chromote session launch unavailable|Representative non-sf plots|polygon/point/line geom_sf families|test-regression-core.R|test-sf-browser.R|test-sf-ir.R|test-sf-renderer.R|test-legends.R|test-date-scales.R|test-coord-flip.R|test_output/browser-sf|page-errors.log|browser-log.json|00check.log" .planning/phases/42-release-validation-gate/42-VALIDATION-GATE.md
rtk rg -n "VAL-01|VAL-02|VAL-03|Quick Local Gate|Full Release Gate|Coverage Matrix|Failure Artifacts" .planning/phases/42-release-validation-gate/42-VALIDATION-GATE.md
rtk Rscript --vanilla -e 'txt <- readLines(".planning/phases/42-release-validation-gate/42-VALIDATION-GATE.md"); out <- grep("^## Out Of Scope$", txt); stopifnot(length(out) == 1L); before <- txt[seq_len(out - 1L)]; banned <- c("Playwright", "Puppeteer", "Selenium", "screenshot diff", "pixel diff"); hit <- banned[vapply(banned, function(x) any(grepl(x, before, fixed = TRUE)), logical(1))]; if (length(hit)) stop(paste("forbidden outside Out Of Scope:", paste(hit, collapse = ", "))); expected <- c("| Representative non-sf plots |", "| polygon/point/line geom_sf families |", "| Facets |", "| Legends |", "| Dates |", "| coord_flip |", "| Browser smoke DOM rendering |", "| Browser smoke interaction payloads |", "| Package documentation generation |", "| R CMD check output |"); present <- vapply(expected, function(x) any(grepl(x, txt, fixed = TRUE)), logical(1)); stopifnot(all(present)); behavior_rows <- txt[Reduce(`|`, lapply(expected, function(x) grepl(x, txt, fixed = TRUE)))]; stopifnot(length(behavior_rows) == 10L, all(grepl("VAL-0[123]", behavior_rows))); cat("matrix and forbidden string checks ok\n")'
```

Outcome: all planned source checks passed.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- An extra R sanity-check command initially had local quoting mistakes around Markdown table pipes. The planned `rtk rg` verification had already passed; the R command was corrected and passed before Task 2 was committed.

## Known Stubs

None. Stub scan found only the required literal skip message `Chrome/Chromium not available for chromote sf smoke tests`, which is release-gate evidence text rather than incomplete content.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 42-02 can run the documented release gate and record execution evidence in `.planning/phases/42-release-validation-gate/42-GATE-RUN.md`.

## Self-Check: PASSED

- Found `.planning/phases/42-release-validation-gate/42-VALIDATION-GATE.md`.
- Found `.planning/phases/42-release-validation-gate/42-01-SUMMARY.md`.
- Found task commit `17fff38`.
- Found task commit `d9ad81e`.

---
*Phase: 42-release-validation-gate*
*Completed: 2026-05-23*
