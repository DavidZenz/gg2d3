# Phase 42: Release Validation Gate - Context

## Phase Summary

Maintainers need a repeatable local release gate that runs and explains the checks required for v1.10 release confidence: package tests, documentation generation, package check behavior, representative feature coverage, browser smoke behavior, and failure artifacts.

## Decisions

### Release gate scope

- Define two local validation tiers rather than one monolithic workflow.
- The quick tier should support day-to-day confidence checks and may focus on package tests plus targeted source/IR validations.
- The full release gate should cover documentation generation, package tests, and an `R CMD check`-style package validation path.
- Phase 42 execution should run the full release gate where local tooling permits and record any expected optional skips.

### Browser smoke behavior

- Preserve CRAN-compatible browser and spatial skip behavior from Phase 40.
- Browser smoke should be attempted locally when `chromote`, Chrome/Chromium, `sf`, and `geojsonsf` are available.
- Missing optional browser/spatial tooling is not a release failure when the skip message is explicit and matches the documented gate expectations.
- The gate documentation must explain which browser smoke checks require local Chrome/chromote and which non-browser checks still exercise source-level sf behavior.

### Coverage evidence

- Use an explicit validation matrix that maps release-representative behavior to commands, test files, and artifacts.
- The matrix must cover representative non-sf plots, polygon/point/line `geom_sf()` behavior, facets, legends, dates, `coord_flip`, and browser smoke behavior.
- Do not rely on maintainers inferring coverage from a single command's output; the release gate should link behavior areas to the tests that prove them.

### Failure artifacts

- Document predictable, ignored artifact locations established by Phase 40.
- Browser smoke failures should point maintainers to `test_output/browser-sf/` HTML fixtures and `*-page-errors.log` files.
- Package check failures should point maintainers to local `*.Rcheck/` output and check logs.
- Documentation/build failures should identify the command that failed and whether generated docs/README artifacts need regeneration.

### Repair policy

- During Phase 42 execution, repair release-blocking failures found by the gate.
- Do not expand the phase into new renderer features or broad parity work.
- Optional-tool skips, known deferred non-blockers, and future visual-diff infrastructure should be recorded with rationale rather than treated as failures.
- Phase 41 deferred items remain non-blocking unless the release gate exposes a concrete regression.

## Constraints

- Preserve the Phase 40 package hygiene guarantees: optional dependencies skip cleanly, generated artifacts stay ignored, and source package builds exclude local planning/debug output.
- Preserve the Phase 41 release-debt classifications unless new validation evidence proves a release blocker.
- Keep the validation gate runnable by maintainers on a normal local checkout without requiring Playwright, Puppeteer, Selenium, screenshot diffing, or Node browser infrastructure.
- Prefer documented command sequences and targeted checks over hidden ad hoc validation steps.

## User Preferences

- User accepted the recommended defaults for all five discussed gray areas.
- Favor a pragmatic release gate with explicit evidence, skip semantics, and artifact paths.
- Recommendations are acceptable where the existing codebase already establishes a clear pattern.

## Open Questions

- Exact command spelling for the quick and full tiers should be decided during planning.
- Whether the full gate should use `devtools::check()` or an explicit package build plus `R CMD check` command remains a planning choice.
- The final filename/location for release-gate documentation can be chosen during planning, but it should be easy for maintainers to find before Phase 43 documentation polish.

## Canonical References

### Phase Requirements

- `.planning/ROADMAP.md` - Phase 42 goal, dependencies, success criteria, and expected plans.
- `.planning/REQUIREMENTS.md` - VAL-01, VAL-02, and VAL-03 acceptance requirements.
- `.planning/PROJECT.md` - v1.10 release hardening scope and out-of-scope boundaries.
- `.planning/STATE.md` - current milestone state and Phase 42 position.

### Prior Hardening Evidence

- `.planning/phases/40-package-hygiene/40-SKIP-AUDIT.md` - optional browser/spatial skip order, messages, and non-browser coverage split.
- `.planning/phases/40-package-hygiene/40-ARTIFACT-AUDIT.md` - ignored generated-output paths and package-build exclusions.
- `.planning/phases/41-release-blocking-debt-triage/41-DEBT-AUDIT.md` - resolved advisory follow-ups and deferred non-blocking renderer/documentation debt.
- `.planning/phases/41-release-blocking-debt-triage/41-VERIFICATION.md` - Phase 41 validation evidence and remaining deferred non-blockers.

### Existing Commands And Package Metadata

- `README.Rmd` - contributor development commands: `devtools::document()`, `devtools::load_all()`, `devtools::test()`, and `devtools::build_readme()` guidance.
- `DESCRIPTION` - package imports, suggests, testthat edition, roxygen config, and vignette builder.
- `.planning/codebase/TESTING.md` - test framework notes and existing test execution patterns.

### Coverage Anchors

- `tests/testthat/test-regression-core.R` - bounded regression matrix for representative non-sf geoms, sf families, facets, legends, dates, `coord_flip`, and renderer source contracts.
- `tests/testthat/test-sf-browser.R` - live chromote/browser smoke tests, sf fixture counts, facet panel identity assertions, interaction payload checks, and failure artifact checks.
- `tests/testthat/helper-browser-sf.R` - shared browser skip gate, artifact directory helper, chromote session helpers, and browser error log writer.
- `tests/testthat/test-sf-ir.R` - non-browser sf IR extraction and geometry family coverage.
- `tests/testthat/test-sf-renderer.R` - renderer-side sf source contracts.
- `tests/testthat/test-sf-utils.R` - sf helper behavior, skipped-row diagnostics, and optional spatial edge cases.
- `tests/testthat/test-facets.R` and `tests/testthat/test-facet-grid.R` - facet IR structure and sf facet bbox isolation.
- `tests/testthat/test-legends.R` - legend and interactive legend IR contracts.
- `tests/testthat/test-date-scales.R` - date/datetime scale coverage, visual artifact generation, and date plus `coord_flip` behavior.
- `tests/testthat/test-coord-flip.R` - `coord_flip` IR behavior and facet combinations.

## Existing Code Insights

### Reusable Assets

- `skip_browser_sf_smoke()` already centralizes CRAN/browser/spatial gating with explicit skip messages.
- `browser_sf_artifact_dir()` writes browser smoke artifacts under `test_output/browser-sf/`.
- `write_browser_failure_artifacts()` records failing browser pages and page-error logs for inspection.
- `test-regression-core.R` already functions as a compact release-surface matrix for non-browser validation.

### Established Patterns

- Browser smoke remains optional and R/testthat/chromote-based, not a required Node/browser stack.
- Non-browser sf tests preserve useful validation even when live Chrome is unavailable.
- Generated local artifacts belong under ignored paths such as `test_output/`, `test_*_files/`, root-level debug HTML/PNG/PDF files, and `*.Rcheck/`.
- Release hardening work should classify and document non-blockers instead of broadening into new feature implementation.

### Integration Points

- Release-gate documentation should connect maintainer commands to existing test files rather than duplicating test logic.
- If execution adds a script/helper, it should reuse existing R package tooling and artifact conventions.
- Any package check path must respect `.Rbuildignore` exclusions for `.planning/`, `.claude/`, `AGENTS.md`, local output directories, and generated debug files.

## Specific Ideas

- Create a release validation matrix with columns similar to: behavior area, command, test/artifact, requirement, expected optional skips, failure artifact.
- Include a short "expected skips" section that names the browser/spatial skip messages from Phase 40.
- Record Phase 42 execution evidence in a dedicated verification artifact so Phase 43 release notes can reuse it.

## Deferred Ideas

- Adding screenshot-diff or perceptual visual regression infrastructure remains deferred beyond v1.10.
- Adding ordinary `geom_polygon()` renderer support remains deferred unless future parity work explicitly scopes it.
- Broad rect/tile renderer rewrites remain deferred unless a focused future reproduction proves release-blocking behavior.

---

*Phase: 42-release-validation-gate*
*Context gathered: 2026-05-23*
