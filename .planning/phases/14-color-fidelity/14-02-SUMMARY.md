---
phase: 14-color-fidelity
plan: 02
subsystem: js-color
tags: [js, regex, hex, rgba, color-fidelity, tdd]

# Dependency graph
requires:
  - phase: 14-color-fidelity
    plan: 01
    provides: skip-pending stub "isHexColor accepts 4 and 8 digit hex (constants.js regex)"
provides:
  - "isHexColor regex now accepts #RGB, #RGBA, #RRGGBB, #RRGGBBAA (CSS Color 4)"
  - "Unblocks viridis_d 8-hex RGBA strings (#440154FF) from falling through to colorScale"
  - "Unblocks D-13 alpha-resolved RGBA hex round-trip (e.g. #FF000080)"
affects: [14-03, 14-05, 14-06, 14-07]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "CSS Color 4 hex notation (#RGBA, #RRGGBBAA) supported in fast-path validator"

key-files:
  created: []
  modified:
    - inst/htmlwidgets/modules/constants.js
    - tests/testthat/test-color-fidelity.R

key-decisions:
  - "Use `[0-9a-f]{3,4}|[0-9a-f]{6}|[0-9a-f]{8}` (rather than a single `{3,8}` quantifier) so 5/7-digit garbage is still rejected"
  - "Auto-fix the planned static-grep extractor: lazy `[\\s\\S]*?\\}` terminated at the first inner `{3,4}` brace and never reached the outer regex; anchor end on `\\n  \\}` instead"

patterns-established:
  - "Static grep against vendored JS source as a no-Node assertion path for regex-shape changes"

requirements-completed: []  # COLOR-01 progresses but not closed (full per-row hex parity lands in 14-07)

# Metrics
duration: 2min
completed: 2026-05-06
---

# Phase 14 Plan 02: RGBA Hex Summary

**Widened `isHexColor` regex from `{3}|{6}` to `{3,4}|{6}|{8}` so CSS Color 4 short-RGBA and full-RGBA hex strings (e.g. `#440154FF`, `#FF000080`) flow through the fast-path validator instead of falling through to discrete colorScale.**

## Performance

- **Duration:** ~2 min
- **Started:** 2026-05-06T20:12:43Z
- **Completed:** 2026-05-06T20:14:54Z
- **Tasks:** 2 (TDD: RED, GREEN)
- **Files modified:** 2

## Regex Change

**Before** (`inst/htmlwidgets/modules/constants.js:189`):
```js
return typeof s === "string" && /^#([0-9a-f]{3}|[0-9a-f]{6})$/i.test(s);
```

**After**:
```js
// Accept #RGB, #RGBA (CSS Color 4 short), #RRGGBB, #RRGGBBAA (full RGBA).
return typeof s === "string" && /^#([0-9a-f]{3,4}|[0-9a-f]{6}|[0-9a-f]{8})$/i.test(s);
```

JSDoc on the function now reads `True if valid hex color (#RGB, #RGBA, #RRGGBB, or #RRGGBBAA)`.

## Task Commits

1. **Task 1 RED — assert isHexColor accepts 4/8-digit hex** — `f0e7d66` (test)
2. **Task 2 GREEN — widen regex; fix test extractor** — `3f123a2` (fix)

## TDD Cycle

| Phase  | Test count                                     | Outcome   |
| ------ | ---------------------------------------------- | --------- |
| RED    | 2 expectation_failure (no `{8}`, no `{4}` pattern) | failed as designed |
| GREEN  | 3 PASS (length 1, `{8}` present, `{4}` covered)   | passes    |

## Files Modified

- `inst/htmlwidgets/modules/constants.js` — 1 line of code + 1 line of JSDoc + 1 inline comment
- `tests/testthat/test-color-fidelity.R` — flipped 1 skip-pending stub to 9 lines of static-grep assertions (skip count 21 → 20, pass +3)

## Suite Status

- Baseline preserved: **PASS 554 / FAIL 8 / SKIP 20**
- Phase 13 baseline was 551/8/21 — delta is +3 PASS / -1 SKIP, identical FAIL set (8 pre-existing coord_fixed/coord_trans failures, out of scope)

## Decisions Made

- Chose alternation `[0-9a-f]{3,4}|[0-9a-f]{6}|[0-9a-f]{8}` over a permissive `[0-9a-f]{3,8}` so 5- and 7-digit malformed strings remain invalid (matches CSS Color 4 spec which only defines 3/4/6/8)
- Used `pkgload::load_all()` for verification (CLAUDE.md / project memory: devtools may not be installed)
- `R_MAKEVARS_USER=/tmp/empty_makevars` to bypass Makevars conflicts noted in phase context

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 — Bug] Plan's RED-test extractor regex truncated function body at inner brace**
- **Found during:** Task 2 verification (GREEN run)
- **Issue:** Plan-supplied test used `regexpr("function isHexColor[\\s\\S]*?\\}", ..., perl=TRUE)`. The lazy `\\}` matched the first `}` it saw — which was the inner `{3,4}` quantifier closer in the new regex literal — so the captured function body string was 157 chars and stopped at `/^#([0-9a-f]{3,4}` (the rest of the regex never visible).
- **Symptom:** Both `expect_match` calls failed against the GREEN impl even though the source obviously contained `[0-9a-f]{8}`.
- **Fix:** Replaced terminator `\\}` with `\\n  \\}` so the lazy match seeks the line-anchored `}` that closes the function body (not nested quantifier braces).
- **Files modified:** `tests/testthat/test-color-fidelity.R` (1 line within Task 2 scope)
- **Commit:** `3f123a2` (bundled with the regex widening commit, since the test wouldn't pass against any correct impl without this fix)

No other deviations. Pre-existing 8 baseline failures remain out of scope as per phase context.

## Issues Encountered

None beyond the auto-fix above. RED was clean (2 failures), GREEN clean (3 passes), full-suite delta clean (PASS +3, SKIP -1, FAIL ±0).

## Next Phase Readiness

- Wave 1 plans 14-03 and 14-04 unaffected by this change but can run in parallel as planned
- Plan 14-07 (corpus snapshots) will exercise this regex via `viridis_d` (D-05) and D-13 RGBA round-trip cases
- `isHexColor` fast-path in `geom-registry.js::makeColorAccessors` now correctly recognises the full ggplot2 viridis_d palette output

## Self-Check: PASSED

- `inst/htmlwidgets/modules/constants.js` modified, contains `[0-9a-f]{8}` (verified via grep)
- `tests/testthat/test-color-fidelity.R` modified, no longer contains `skip("pending plan 14-02")` for isHexColor test
- Commit `f0e7d66` exists in git log (test RED)
- Commit `3f123a2` exists in git log (fix GREEN)
- Color-fidelity test file: 0 FAIL / 3 PASS / 19 SKIP (verified)
- Full suite baseline: 554 PASS / 8 FAIL / 20 SKIP (verified; 8 FAIL identical to Phase 13 baseline)

---
*Phase: 14-color-fidelity*
*Completed: 2026-05-06*
