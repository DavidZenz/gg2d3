# gg2d3 v1.10 Release Checklist And Notes

**Release status:** PASSED WITH EXPECTED OPTIONAL SKIPS

This artifact is the DOC-02 release-facing handoff for the v1.10 release
hardening checkpoint. It summarizes the final gate evidence from Phase 42,
residual risks, and the deferred non-blockers from Phase 41 without copying
machine-local logs.

## Package Version

| Source | Version |
|--------|---------|
| `DESCRIPTION` | `0.0.0.9000` |

## Checks Run

| Gate | Command class | Outcome | Source artifact |
|------|---------------|---------|-----------------|
| Quick local release gate | `devtools::load_all()` plus targeted `testthat::test_file()` runs for `test-regression-core.R` and `test-sf-browser.R` | Passed with expected optional skips. | `.planning/phases/42-release-validation-gate/42-GATE-RUN.md` |
| Documentation and full package tests | `devtools::document(); devtools::build_readme(); devtools::test()` | Final run passed with 817 passed, 40 skipped, and 6 warnings. | `.planning/phases/42-release-validation-gate/42-GATE-RUN.md` |
| Source package build | `R CMD build --no-manual` from a package version read from `DESCRIPTION` | Final build passed. | `.planning/phases/42-release-validation-gate/42-GATE-RUN.md` |
| Package check | `R CMD check --as-cran` on the built source package | Final check passed with 4 NOTEs and no ERROR/WARNING. | `.planning/phases/42-release-validation-gate/42-GATE-RUN.md` |

## Expected Optional Skips

The gate treats optional skips as expected release evidence only when their
messages match the Phase 42 validation contract:

- Missing `sf` remains an expected optional spatial skip when the local
  environment cannot load `sf`.
- Browser smoke validation may skip in CRAN-like contexts via `skip_on_cran()`.
- Browser validation may also skip when optional `chromote`, `sf`,
  `geojsonsf`, Chrome/Chromium, or chromote launch gates are unavailable.
- Default local visual-test skips and the empty crosstalk test skip remain
  non-blocking evidence, not browser or spatial failures.

Source: `.planning/phases/42-release-validation-gate/42-VALIDATION-GATE.md`.

## Final R CMD Check Outcome

Final `R CMD check --as-cran` status: passed with 4 NOTEs and no
ERROR/WARNING.

The 4 NOTEs are retained as release evidence from Phase 42 after scoped
release-blocking failures were repaired. They are not reclassified here.

## Documentation Sweep Status

Documentation sweep status: DOC-01 complete.

The source/generated documentation sweep in
`.planning/phases/43-documentation-and-release-notes/43-DOC-SWEEP.md` records
that README, vignette, diagnostics, roxygen source, generated README, and
generated Rd help describe the shipped polygon-family, point-family, and
line-family `geom_sf()` contract, optional browser validation, map
anti-features, representative-anchor brushing, sanitized source-row payloads,
and zoom suppression language.

## Residual Risks

- Optional live browser validation is environment-dependent and remains
  skip-aware by design.
- Private ggplot2 theme API compatibility remains quarantined behind internal
  compatibility helpers.
- Final package check retained 4 NOTEs as release evidence.

## Deferred Non-Blockers

- Deferred non-blocker: ordinary `geom_polygon()` support signaling remains
  separate from supported `geom_sf()` polygon-family rendering.
- Deferred non-blocker: rect/tile out-of-bounds behavior remains future
  renderer debt pending focused evidence.

Source: `.planning/phases/41-release-blocking-debt-triage/41-DEBT-AUDIT.md`.

## Local Artifact Classes

Use artifact classes for local debugging only; do not paste raw logs into
release notes:

- `test_output/browser-sf/*.html`
- `test_output/browser-sf/*-console.log`
- `test_output/browser-sf/*-page-errors.log`
- `test_output/browser-sf/*-browser-log.json`
- `/private/tmp/gg2d3_*.Rcheck/00check.log`
- `/private/tmp/gg2d3_0.0.0.9000.tar.gz`

## Recommended Next-Milestone Candidates

These candidates are outside the v1.10 release hardening scope:

- Plan ordinary `geom_polygon()` renderer parity as a separate future phase if
  parity coverage requires it.
- Add a focused rect/tile out-of-bounds reproduction before changing renderer
  behavior.
- Consider advanced sf features after the current polygon/point/line family
  contract stays stable.
- Define large-dataset performance budgets for complex SVG outputs.
- Consider future screenshot or perceptual regression checks after DOM/source
  guards are stable.

## Source Artifacts

- `.planning/phases/42-release-validation-gate/42-GATE-RUN.md`
- `.planning/phases/42-release-validation-gate/42-VALIDATION-GATE.md`
- `.planning/phases/42-release-validation-gate/42-VERIFICATION.md`
- `.planning/phases/41-release-blocking-debt-triage/41-DEBT-AUDIT.md`
- `.planning/phases/43-documentation-and-release-notes/43-DOC-SWEEP.md`
