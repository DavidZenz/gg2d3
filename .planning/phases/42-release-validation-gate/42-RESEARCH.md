# Phase 42: Release Validation Gate - Research

**Researched:** 2026-05-23 [VERIFIED: local date context]  
**Domain:** R package release validation for gg2d3 test, documentation, package-check, and optional browser smoke behavior [VERIFIED: .planning/ROADMAP.md, .planning/phases/42-release-validation-gate/42-CONTEXT.md]  
**Confidence:** HIGH for local architecture and commands; MEDIUM for final `R CMD check` runtime behavior because the full gate has not been executed in this research step [VERIFIED: local file audit, local R tooling probes]

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

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

### Claude's Discretion

- Exact command spelling for the quick and full tiers should be decided during planning.
- Whether the full gate should use `devtools::check()` or an explicit package build plus `R CMD check` command remains a planning choice.
- The final filename/location for release-gate documentation can be chosen during planning, but it should be easy for maintainers to find before Phase 43 documentation polish.

### Deferred Ideas (OUT OF SCOPE)

- Adding screenshot-diff or perceptual visual regression infrastructure remains deferred beyond v1.10.
- Adding ordinary `geom_polygon()` renderer support remains deferred unless future parity work explicitly scopes it.
- Broad rect/tile renderer rewrites remain deferred unless a focused future reproduction proves release-blocking behavior.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| VAL-01 | Maintainer can run a documented local release gate that covers package tests, documentation generation, and an `R CMD check`-style package check with expected optional skips. [VERIFIED: .planning/REQUIREMENTS.md] | Use two tiers: quick `testthat::test_file()`/`devtools::test()` checks, and full `devtools::document(); devtools::build_readme(); devtools::test(); R CMD build; R CMD check` evidence. [VERIFIED: README.Rmd, .planning/phases/42-release-validation-gate/42-CONTEXT.md, .planning/phases/40-package-hygiene/40-ARTIFACT-AUDIT.md] |
| VAL-02 | Release validation exercises representative non-sf plots, polygon/point/line sf plots, facet/legend/date/coord_flip behavior, and browser smoke coverage without weakening CRAN-compatible skip behavior. [VERIFIED: .planning/REQUIREMENTS.md] | Map coverage to `test-regression-core.R`, sf IR/renderer/browser tests, facet/legend/date/coord_flip tests, and existing browser skip helper. [VERIFIED: tests/testthat/test-regression-core.R, tests/testthat/test-sf-browser.R, tests/testthat/helper-browser-sf.R] |
| VAL-03 | Validation failures leave actionable logs or artifacts, and the documented release gate explains where to inspect failures. [VERIFIED: .planning/REQUIREMENTS.md] | Document `test_output/browser-sf/`, `*-page-errors.log`, `*-browser-log.json`, `*.Rcheck/`, docs generation output, and generated README/help diffs as inspection points. [VERIFIED: tests/testthat/helper-browser-sf.R, .planning/phases/40-package-hygiene/40-ARTIFACT-AUDIT.md] |
</phase_requirements>

## Summary

Phase 42 should plan a release gate that composes existing project validation assets instead of building new validation infrastructure. [VERIFIED: .planning/phases/42-release-validation-gate/42-CONTEXT.md, tests/testthat/test-regression-core.R, tests/testthat/test-sf-browser.R] The project already has a compact representative regression matrix, optional chromote browser smoke tests, deterministic browser artifact writers, and ignored package-check artifact paths. [VERIFIED: tests/testthat/test-regression-core.R, tests/testthat/helper-browser-sf.R, .planning/phases/40-package-hygiene/40-ARTIFACT-AUDIT.md]

The planner should define a quick tier for frequent local confidence and a full tier for release evidence. [VERIFIED: .planning/phases/42-release-validation-gate/42-CONTEXT.md] The full tier should prefer explicit `R CMD build` plus `R CMD check` from a temporary directory because Phase 40 already validated tarball exclusion behavior and because VAL-03 requires maintainers to inspect local `*.Rcheck/` output. [VERIFIED: .planning/phases/40-package-hygiene/40-ARTIFACT-AUDIT.md, .planning/REQUIREMENTS.md]

**Primary recommendation:** Plan an R-only release gate with no new dependencies: quick tests for `test-regression-core.R` plus targeted browser-source/artifact checks, and a full release run of docs generation, README generation, `devtools::test()`, source package build, and `R CMD check`, with optional browser/spatial skips recorded rather than failed. [VERIFIED: .planning/phases/42-release-validation-gate/42-CONTEXT.md, README.Rmd, DESCRIPTION, local package-version probe]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Release gate command documentation | R package maintainer workflow | Planning docs | Maintainer-facing commands already live in README contributor guidance, and Phase 42 asks for documented local commands rather than runtime product behavior. [VERIFIED: README.Rmd, .planning/ROADMAP.md] |
| Package tests and targeted regression matrix | R/testthat | R package source | Test execution is implemented through `testthat`, with package loading handled by `tests/testthat.R` and helpers. [VERIFIED: tests/testthat.R, DESCRIPTION] |
| Documentation generation | R package tooling | Generated docs/README artifacts | Existing contributor commands use `devtools::document()` and `devtools::build_readme()`. [VERIFIED: README.Rmd, AGENTS.md] |
| Package check evidence | R package build/check tooling | Local filesystem artifacts | Phase 40 established `*.Rcheck/` as ignored local output and verified source package exclusions from `/private/tmp`. [VERIFIED: .planning/phases/40-package-hygiene/40-ARTIFACT-AUDIT.md, .Rbuildignore] |
| Browser smoke behavior | R/testthat/chromote | Browser runtime | Browser tests use optional `chromote` and local Chrome/Chromium through testthat helpers, not Node browser tooling. [VERIFIED: tests/testthat/helper-browser-sf.R, .planning/phases/40-package-hygiene/40-SKIP-AUDIT.md] |
| Browser failure artifacts | Local filesystem | Browser runtime | The helper writes HTML, console logs, page-error logs, and JSON logs under `test_output/browser-sf/`. [VERIFIED: tests/testthat/helper-browser-sf.R] |

## Project Constraints (from AGENTS.md)

- Use `rtk` as the command prefix for shell commands in this repository. [VERIFIED: AGENTS.md, /Users/davidzenz/.codex/RTK.md]
- Keep D3 v7 vendored locally under `inst/htmlwidgets/lib/d3/d3.v7.min.js`. [VERIFIED: AGENTS.md]
- Preserve the three-layer ggplot2-to-IR-to-D3 architecture. [VERIFIED: AGENTS.md]
- Use the existing development commands: `devtools::load_all()`, `devtools::document()`, `devtools::test()`, `testthat::test_file(...)`, and `devtools::build_readme()`. [VERIFIED: AGENTS.md, README.Rmd]
- Do not treat current known limitations such as facets/legends/browser smoke constraints as new feature work in this release-validation phase. [VERIFIED: AGENTS.md, .planning/phases/42-release-validation-gate/42-CONTEXT.md]

## Standard Stack

### Core

| Tool/Library | Version | Purpose | Why Standard |
|--------------|---------|---------|--------------|
| R | local 4.6.0; DESCRIPTION requires >= 4.1.0 | Execute package tooling and tests. [VERIFIED: local `Rscript --version`, DESCRIPTION] | This is an R package and all release-gate commands run through R package tooling. [VERIFIED: DESCRIPTION, README.Rmd] |
| testthat | local 3.3.2; DESCRIPTION requires >= 3.0.0; edition 3 | Run unit, integration, source-contract, and optional browser tests. [VERIFIED: local package-version probe, DESCRIPTION, tests/testthat.R] | Existing tests are testthat files under `tests/testthat/`. [VERIFIED: `rtk rg --files tests/testthat`] |
| devtools | local 2.5.2; listed in Suggests | Run maintainer docs/test/readme helpers. [VERIFIED: local package-version probe, DESCRIPTION, README.Rmd] | Existing contributor workflow already names `devtools::document()`, `devtools::test()`, and `devtools::build_readme()`. [VERIFIED: README.Rmd] |
| roxygen2 | local 8.0.0; DESCRIPTION config 8.0.0 | Generate `man/*.Rd` and NAMESPACE from roxygen comments. [VERIFIED: local package-version probe, DESCRIPTION] | Documentation generation is part of VAL-01. [VERIFIED: .planning/REQUIREMENTS.md] |
| R CMD build/check | local R installation | Build source tarball and run package checks. [VERIFIED: local `R CMD config CC`, .planning/phases/40-package-hygiene/40-ARTIFACT-AUDIT.md] | The full gate must include an `R CMD check`-style validation path. [VERIFIED: .planning/REQUIREMENTS.md, .planning/ROADMAP.md] |

### Supporting

| Tool/Library | Version | Purpose | When to Use |
|--------------|---------|---------|-------------|
| chromote | local 0.5.1; DESCRIPTION requires >= 0.5.1 | Drive optional browser smoke tests. [VERIFIED: local package-version probe, DESCRIPTION, helper-browser-sf.R] | Use when Chrome/Chromium and spatial packages are available; otherwise expect documented skips. [VERIFIED: .planning/phases/40-package-hygiene/40-SKIP-AUDIT.md] |
| Chrome/Chromium | local Google Chrome path found | Browser runtime for chromote tests. [VERIFIED: local `chromote::find_chrome()` probe] | Required only for live browser smoke checks. [VERIFIED: tests/testthat/helper-browser-sf.R] |
| sf | local NOT_INSTALLED; DESCRIPTION requires >= 1.0.0 | Spatial fixtures and sf IR/browser tests. [VERIFIED: local package-version probe, DESCRIPTION] | Missing `sf` should produce expected optional spatial/browser skips, not a release failure by itself. [VERIFIED: .planning/phases/42-release-validation-gate/42-CONTEXT.md, tests/testthat/helper-browser-sf.R] |
| geojsonsf | local 2.0.5; DESCRIPTION requires >= 2.0.0 | Serialize sf geometries to GeoJSON in sf validation paths. [VERIFIED: local package-version probe, DESCRIPTION] | Required with `sf` for non-browser sf tests and browser fixture generation. [VERIFIED: .planning/phases/40-package-hygiene/40-SKIP-AUDIT.md] |
| knitr/rmarkdown | local knitr 1.51, rmarkdown 2.31 | Build README/vignettes/docs outputs. [VERIFIED: local package-version probe, DESCRIPTION] | Use in docs generation and package check workflows. [VERIFIED: DESCRIPTION, README.Rmd] |
| pkgload/rprojroot | local pkgload 1.5.2, rprojroot 2.1.1 | Support test helper loading and project-root artifact paths. [VERIFIED: local package-version probe, DESCRIPTION, helper-sf-fixtures.R] | Keep as declared optional helpers for tests and artifact roots. [VERIFIED: .planning/phases/41-release-blocking-debt-triage/41-DEBT-AUDIT.md] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Explicit `R CMD build` plus `R CMD check` | `devtools::check()` | `devtools::check()` is acceptable as an R package check wrapper, but explicit build/check better matches Phase 40 tarball verification and VAL-03 `*.Rcheck/` artifact inspection. [VERIFIED: .planning/phases/42-release-validation-gate/42-CONTEXT.md, .planning/phases/40-package-hygiene/40-ARTIFACT-AUDIT.md] |
| Existing chromote/testthat browser smoke | Playwright, Puppeteer, Selenium, screenshot-diff | Node/browser and screenshot-diff infrastructure is explicitly out of scope for v1.10. [VERIFIED: .planning/phases/42-release-validation-gate/42-CONTEXT.md, .planning/phases/40-package-hygiene/40-SKIP-AUDIT.md] |
| Existing testthat/source-contract coverage | New custom release-test framework | Existing tests already cover the required behavior areas and artifact paths, so a custom framework would duplicate coverage rather than satisfy a gap. [VERIFIED: tests/testthat/test-regression-core.R, tests/testthat/test-sf-browser.R] |

**Installation:** No new package dependencies should be added for Phase 42 unless the release gate exposes a concrete blocker in existing tooling. [VERIFIED: .planning/phases/42-release-validation-gate/42-CONTEXT.md, DESCRIPTION]

**Version verification:** Tool versions above were verified locally with `rtk Rscript --vanilla -e 'packageVersion(...)'` probes, and `sf` was not installed in the local environment at research time. [VERIFIED: local package-version probe]

## Architecture Patterns

### System Architecture Diagram

```text
Maintainer command
  -> Quick tier
     -> testthat targeted files
     -> release-surface matrix evidence
     -> optional browser smoke source/artifact checks
  -> Full tier
     -> devtools::document()
     -> devtools::build_readme()
     -> devtools::test()
     -> R CMD build from clean temp directory
     -> R CMD check source tarball
  -> Results
     -> PASS
     -> Expected optional skips recorded
     -> FAIL with artifact pointer:
        docs diffs / testthat output / test_output/browser-sf/* / *.Rcheck/*
```

The data flow above follows the two-tier decision and routes failures to the artifact paths already established in Phases 40 and 42 context. [VERIFIED: .planning/phases/42-release-validation-gate/42-CONTEXT.md, .planning/phases/40-package-hygiene/40-ARTIFACT-AUDIT.md]

### Recommended Project Structure

```text
.planning/phases/42-release-validation-gate/
├── 42-RESEARCH.md          # this research artifact
├── 42-VALIDATION-GATE.md   # recommended maintainer command/matrix doc
├── 42-GATE-RUN.md          # recommended execution evidence from full gate
└── 42-VERIFICATION.md      # expected GSD verification output
```

The final filename is not locked by context, but the documentation should live in the Phase 42 directory unless planning chooses a maintainer-facing root/vignette handoff for Phase 43. [VERIFIED: .planning/phases/42-release-validation-gate/42-CONTEXT.md]

### Pattern 1: Two-Tier Gate

**What:** Quick tier gives day-to-day confidence; full tier gives release evidence. [VERIFIED: .planning/phases/42-release-validation-gate/42-CONTEXT.md]  
**When to use:** Use quick tier after small code/doc changes; use full tier before Phase 42 verification and before Phase 43 release docs consume the evidence. [VERIFIED: .planning/ROADMAP.md, .planning/phases/42-release-validation-gate/42-CONTEXT.md]

**Recommended quick command:**

```bash
rtk Rscript --vanilla -e 'devtools::load_all(quiet = TRUE); testthat::test_file("tests/testthat/test-regression-core.R"); testthat::test_file("tests/testthat/test-sf-browser.R")'
```

This command covers the compact release-surface matrix plus browser artifact/skip contracts, with live browser tests skipped when optional tooling is unavailable. [VERIFIED: tests/testthat/test-regression-core.R, tests/testthat/test-sf-browser.R, helper-browser-sf.R]

**Recommended full command sequence:**

```bash
rtk Rscript --vanilla -e 'devtools::document(); devtools::build_readme(); devtools::test()'
cd /private/tmp
rtk R CMD build --no-manual /Users/davidzenz/R/gg2d3
rtk R CMD check --as-cran gg2d3_0.0.0.9000.tar.gz
```

The package version in the tarball name should be read from `DESCRIPTION` during execution rather than hard-coded in a reusable script. [VERIFIED: DESCRIPTION]

### Pattern 2: Validation Matrix

**What:** A table links behavior areas to command, test file, artifact, expected skips, and requirement ID. [VERIFIED: .planning/phases/42-release-validation-gate/42-CONTEXT.md]  
**When to use:** Use it in `42-VALIDATION-GATE.md` so maintainers do not infer coverage from command names. [VERIFIED: .planning/phases/42-release-validation-gate/42-CONTEXT.md]

Recommended matrix anchors:

| Behavior Area | Primary Evidence |
|---------------|------------------|
| Representative non-sf plots | `tests/testthat/test-regression-core.R` covers point, line, col, rect, text, segment, boxplot, and smooth plots. [VERIFIED: tests/testthat/test-regression-core.R] |
| polygon/point/line sf families | `test-regression-core.R`, `test-sf-ir.R`, and `test-sf-renderer.R` cover sf family IR and renderer contracts. [VERIFIED: tests/testthat/test-regression-core.R, tests/testthat/test-sf-ir.R, tests/testthat/test-sf-renderer.R] |
| Facets | `test-regression-core.R`, `test-facets.R`, `test-facet-grid.R`, and browser panel-count tests cover facet structures and sf panel isolation. [VERIFIED: tests/testthat/test-regression-core.R, `rtk rg` test name scan, tests/testthat/test-sf-browser.R] |
| Legends | `test-regression-core.R` and `test-legends.R` cover guide presence and legend contracts. [VERIFIED: tests/testthat/test-regression-core.R, `rtk rg` test name scan] |
| Dates | `test-regression-core.R` and `test-date-scales.R` cover date transforms, timezone behavior, and date plus `coord_flip`. [VERIFIED: tests/testthat/test-regression-core.R, tests/testthat/test-date-scales.R] |
| `coord_flip` | `test-regression-core.R` and `test-coord-flip.R` cover flipped coord IR and facet combinations. [VERIFIED: tests/testthat/test-regression-core.R, `rtk rg` test name scan] |
| Browser smoke | `test-sf-browser.R` covers live DOM sf marks, panel-local counts, sanitized payloads, browser error capture, and artifact contracts. [VERIFIED: tests/testthat/test-sf-browser.R] |

### Anti-Patterns to Avoid

- **Treating missing optional `sf`/Chrome/chromote as release failure:** Phase 42 explicitly preserves optional skip semantics when messages are explicit. [VERIFIED: .planning/phases/42-release-validation-gate/42-CONTEXT.md]
- **Adding Node browser infrastructure:** Phase 40 and Phase 42 keep Playwright, Puppeteer, Selenium, screenshot-diff, and visual diff infrastructure out of scope. [VERIFIED: .planning/phases/40-package-hygiene/40-SKIP-AUDIT.md, .planning/phases/42-release-validation-gate/42-CONTEXT.md]
- **Using a single command output as undocumented coverage proof:** Phase 42 requires an explicit matrix mapping behaviors to tests/artifacts. [VERIFIED: .planning/phases/42-release-validation-gate/42-CONTEXT.md]
- **Deleting artifacts automatically after failures:** Phase 40 verified failure artifacts remain available for debugging under ignored paths. [VERIFIED: .planning/phases/40-package-hygiene/40-VERIFICATION.md]
- **Expanding into renderer parity work:** Ordinary `geom_polygon()` and broad rect/tile rewrites remain deferred unless the gate exposes a concrete blocker. [VERIFIED: .planning/phases/41-release-blocking-debt-triage/41-DEBT-AUDIT.md, .planning/phases/42-release-validation-gate/42-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| R package test runner | Custom shell loop over test files | `devtools::test()` and `testthat::test_file()` | Existing tests and package setup are already wired through testthat edition 3. [VERIFIED: DESCRIPTION, tests/testthat.R] |
| Browser automation | Playwright/Puppeteer/Selenium wrapper | Existing `chromote` helpers | Project decisions keep browser smoke R/testthat/chromote-based and optional. [VERIFIED: .planning/phases/42-release-validation-gate/42-CONTEXT.md, helper-browser-sf.R] |
| Browser failure logging | New log format | `write_browser_failure_artifacts()` | Helper already writes HTML, console logs, page-error logs, and JSON logs under `test_output/browser-sf/`. [VERIFIED: helper-browser-sf.R] |
| Package check wrapper | New bespoke check framework | `R CMD build` plus `R CMD check` | This produces standard local `*.Rcheck/` output already ignored by the repo. [VERIFIED: .planning/phases/40-package-hygiene/40-ARTIFACT-AUDIT.md, .gitignore] |
| Coverage traceability | Narrative-only release notes | Validation matrix | Context requires explicit behavior-to-command/test/artifact mapping. [VERIFIED: .planning/phases/42-release-validation-gate/42-CONTEXT.md] |

**Key insight:** Phase 42 is integration and evidence work over existing validation assets, not a new test framework or renderer feature phase. [VERIFIED: .planning/ROADMAP.md, .planning/phases/42-release-validation-gate/42-CONTEXT.md]

## Common Pitfalls

### Pitfall 1: Optional Tooling Misclassified As Failure

**What goes wrong:** The gate fails because `sf`, `chromote`, Chrome/Chromium, or `geojsonsf` is unavailable. [VERIFIED: .planning/phases/40-package-hygiene/40-SKIP-AUDIT.md]  
**Why it happens:** Browser smoke tests depend on optional local tools, and local research found `sf` is not installed even though `chromote`, Chrome, and `geojsonsf` are available. [VERIFIED: local package-version and Chrome probes]  
**How to avoid:** Treat explicit skip messages as expected optional skips and record them in gate evidence. [VERIFIED: .planning/phases/42-release-validation-gate/42-CONTEXT.md]  
**Warning signs:** Output includes missing-package skips, `Chrome/Chromium not available for chromote sf smoke tests`, or `chromote session launch unavailable:`. [VERIFIED: helper-browser-sf.R, 40-SKIP-AUDIT.md]

### Pitfall 2: Documentation Generation Changes Files Silently

**What goes wrong:** `devtools::document()` or `devtools::build_readme()` updates generated files and leaves unreviewed diffs. [VERIFIED: README.Rmd, .planning/RETROSPECTIVE.md]  
**Why it happens:** README.md is generated from README.Rmd, and roxygen output is generated from source comments. [VERIFIED: README.Rmd, DESCRIPTION]  
**How to avoid:** Run docs generation before the package check, then inspect `git diff` for README/help/NAMESPACE changes. [VERIFIED: README.Rmd, AGENTS.md]  
**Warning signs:** `README.md`, `man/*.Rd`, or `NAMESPACE` changes appear after docs commands. [VERIFIED: README.Rmd, DESCRIPTION]

### Pitfall 3: Package Check Artifacts Pollute Source Or Get Lost

**What goes wrong:** `R CMD check` output either lands in the repo unintentionally or maintainers cannot find the logs. [VERIFIED: .planning/phases/40-package-hygiene/40-ARTIFACT-AUDIT.md]  
**Why it happens:** Package checks create `*.Rcheck/` directories near the check command working directory. [VERIFIED: .planning/phases/40-package-hygiene/40-ARTIFACT-AUDIT.md]  
**How to avoid:** Run build/check from `/private/tmp` or another explicit scratch directory, and document the resulting `*.Rcheck/` path. [VERIFIED: .planning/phases/40-package-hygiene/40-ARTIFACT-AUDIT.md]  
**Warning signs:** New `*.Rcheck/`, root HTML, PNG, PDF, or `test_output/` files appear in `git status`. [VERIFIED: .gitignore, .Rbuildignore]

### Pitfall 4: Coverage Matrix Drifts From Actual Test Files

**What goes wrong:** The release-gate doc claims behavior coverage that is not tied to a real test or artifact. [VERIFIED: .planning/phases/42-release-validation-gate/42-CONTEXT.md]  
**Why it happens:** Test file names and coverage areas are easy to infer incorrectly from a full-suite run. [VERIFIED: .planning/phases/42-release-validation-gate/42-CONTEXT.md]  
**How to avoid:** Use source checks over named files and test names when building the matrix. [VERIFIED: local `rtk rg` test-name scan]  
**Warning signs:** Matrix rows have behavior names but no file path, command, artifact path, or expected skip column. [VERIFIED: .planning/phases/42-release-validation-gate/42-CONTEXT.md]

## Code Examples

### Quick Release-Surface Gate

```bash
rtk Rscript --vanilla -e 'devtools::load_all(quiet = TRUE); testthat::test_file("tests/testthat/test-regression-core.R"); testthat::test_file("tests/testthat/test-sf-browser.R")'
```

This uses the bounded regression matrix plus browser smoke/artifact tests without adding new infrastructure. [VERIFIED: tests/testthat/test-regression-core.R, tests/testthat/test-sf-browser.R]

### Full Local Release Gate

```bash
rtk Rscript --vanilla -e 'devtools::document(); devtools::build_readme(); devtools::test()'
cd /private/tmp
rtk R CMD build --no-manual /Users/davidzenz/R/gg2d3
rtk R CMD check --as-cran gg2d3_0.0.0.9000.tar.gz
```

The planner should make the tarball name dynamic or require reading `DESCRIPTION` before execution. [VERIFIED: DESCRIPTION]

### Expected Skip Source Check

```bash
rtk rg -n "skip_browser_sf_smoke|skip_on_cran|Chrome/Chromium not available|chromote session launch unavailable|skip_if_not_installed\\(\"sf\"\\)|skip_if_not_installed\\(\"geojsonsf\"\\)" tests/testthat/helper-browser-sf.R tests/testthat/test-sf-browser.R tests/testthat/test-sf-ir.R tests/testthat/test-sf-renderer.R tests/testthat/test-sf-utils.R
```

This confirms the gate documentation still matches the optional skip paths. [VERIFIED: helper-browser-sf.R, 40-SKIP-AUDIT.md]

### Artifact Path Source Check

```bash
rtk rg -n "browser_sf_artifact_dir|write_browser_failure_artifacts|test_output/browser-sf|Rcheck|test_.*_files|/\\*\\.pdf" tests .gitignore .Rbuildignore .planning/phases/40-package-hygiene/40-ARTIFACT-AUDIT.md
```

This confirms documented artifact paths still match source and ignore rules. [VERIFIED: helper-browser-sf.R, .gitignore, .Rbuildignore, 40-ARTIFACT-AUDIT.md]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Informal contributor command list | Two-tier quick/full release gate with explicit validation matrix | Phase 42 decision context, 2026-05-23 | Maintainers get repeatable commands plus interpretable behavior coverage. [VERIFIED: README.Rmd, 42-CONTEXT.md] |
| Browser validation as optional ad hoc local behavior | Optional R/testthat/chromote smoke harness with deterministic artifacts | v1.9 Phase 36 and v1.10 Phase 40 | Browser failures have inspectable HTML/log/JSON artifacts under `test_output/browser-sf/`. [VERIFIED: helper-browser-sf.R, 40-ARTIFACT-AUDIT.md] |
| Package hygiene and release debt mixed into release check | Package hygiene and release debt already classified before validation gate | Phases 40 and 41 | Phase 42 should repair only concrete release-blocking failures exposed by the gate. [VERIFIED: 40-VERIFICATION.md, 41-DEBT-AUDIT.md, 42-CONTEXT.md] |

**Deprecated/outdated:**
- Node browser stacks, screenshot diffing, and perceptual visual regression are not part of the v1.10 release gate. [VERIFIED: 40-SKIP-AUDIT.md, 42-CONTEXT.md]
- Broad renderer parity work for ordinary `geom_polygon()` and rect/tile out-of-bounds behavior remains deferred unless the gate exposes a concrete regression. [VERIFIED: 41-DEBT-AUDIT.md, 42-CONTEXT.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The research should be considered current until 2026-06-22. [ASSUMED] | Metadata | Low; re-probing installed package versions before execution mitigates stale local tooling assumptions. [VERIFIED: local package-version probe] |

## Open Questions

1. **Should the full release gate run `--as-cran` by default?** [VERIFIED: 42-CONTEXT.md]
   What we know: Phase 42 requires an `R CMD check`-style path, and Phase 40 verified a source build with `--no-build-vignettes --no-manual`. [VERIFIED: .planning/REQUIREMENTS.md, 40-ARTIFACT-AUDIT.md]  
   What's unclear: The exact strictness flags for the final local gate are not locked. [VERIFIED: 42-CONTEXT.md]  
   Recommendation: Use `R CMD check --as-cran` for the full gate when local dependencies permit, and record expected optional skips separately from failures. [VERIFIED: .planning/ROADMAP.md, 42-CONTEXT.md]

2. **Where should maintainer-facing gate documentation live long term?** [VERIFIED: 42-CONTEXT.md]
   What we know: Phase 42 may choose the filename/location, and Phase 43 owns documentation polish. [VERIFIED: 42-CONTEXT.md, .planning/ROADMAP.md]  
   What's unclear: Whether the gate doc should stay phase-local or be promoted into README/vignettes in Phase 43. [VERIFIED: 42-CONTEXT.md]  
   Recommendation: Create phase-local `42-VALIDATION-GATE.md` now, then let Phase 43 decide what becomes release-facing documentation. [VERIFIED: .planning/ROADMAP.md]

3. **Will the current local environment run live sf browser smoke?** [VERIFIED: local package-version probe]
   What we know: `chromote`, Chrome, and `geojsonsf` are available locally; `sf` is not installed locally. [VERIFIED: local package-version and Chrome probes]  
   What's unclear: Whether Phase 42 execution will install `sf` or accept the documented optional skip. [VERIFIED: local package-version probe, 42-CONTEXT.md]  
   Recommendation: Do not install optional tooling as part of the plan unless the maintainer explicitly wants live browser smoke locally; record the `sf` skip as expected if absent. [VERIFIED: 42-CONTEXT.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| R/Rscript | All gate commands | yes | 4.6.0 | None needed. [VERIFIED: local `Rscript --version`] |
| R CMD toolchain | Source build/check | yes | CC `/opt/homebrew/opt/llvm/bin/clang` | None needed for planning; full check must still run. [VERIFIED: local `R CMD config CC`] |
| devtools | Docs/test/readme commands | yes | 2.5.2 | Use roxygen2/testthat direct calls only if devtools fails. [VERIFIED: local package-version probe, README.Rmd] |
| testthat | Package tests | yes | 3.3.2 | None needed. [VERIFIED: local package-version probe] |
| roxygen2 | Documentation generation | yes | 8.0.0 | None needed. [VERIFIED: local package-version probe, DESCRIPTION] |
| chromote | Browser smoke | yes | 0.5.1 | Skip live browser tests if unavailable. [VERIFIED: local package-version probe, helper-browser-sf.R] |
| Chrome/Chromium | Browser smoke runtime | yes | Google Chrome path found | Skip live browser tests if unavailable. [VERIFIED: local `chromote::find_chrome()` probe, helper-browser-sf.R] |
| sf | Spatial/browser tests | no | not installed | Expected optional skip unless maintainer installs it. [VERIFIED: local package-version probe, helper-browser-sf.R] |
| geojsonsf | Spatial/browser tests | yes | 2.0.5 | Expected optional skip if unavailable. [VERIFIED: local package-version probe, helper-browser-sf.R] |
| knitr/rmarkdown | README/vignette docs | yes | knitr 1.51; rmarkdown 2.31 | None needed. [VERIFIED: local package-version probe, DESCRIPTION] |

**Missing dependencies with no fallback:** None for a CRAN-compatible documented gate, because missing optional spatial/browser dependencies are expected skips. [VERIFIED: 42-CONTEXT.md, helper-browser-sf.R]

**Missing dependencies with fallback:** `sf` is missing locally; browser and non-browser sf paths that require it should skip with explicit messages unless the maintainer installs it before a live smoke run. [VERIFIED: local package-version probe, 40-SKIP-AUDIT.md]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | testthat 3.3.2, edition 3. [VERIFIED: local package-version probe, DESCRIPTION] |
| Config file | `tests/testthat.R`. [VERIFIED: tests/testthat.R] |
| Quick run command | `rtk Rscript --vanilla -e 'devtools::load_all(quiet = TRUE); testthat::test_file("tests/testthat/test-regression-core.R"); testthat::test_file("tests/testthat/test-sf-browser.R")'` [VERIFIED: tests/testthat/test-regression-core.R, tests/testthat/test-sf-browser.R] |
| Full suite command | `rtk Rscript --vanilla -e 'devtools::document(); devtools::build_readme(); devtools::test()'` followed by `R CMD build` and `R CMD check`. [VERIFIED: README.Rmd, .planning/REQUIREMENTS.md] |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| VAL-01 | Package tests, docs generation, README generation, and package check path run locally. [VERIFIED: .planning/REQUIREMENTS.md] | integration/package | `rtk Rscript --vanilla -e 'devtools::document(); devtools::build_readme(); devtools::test()'` plus `rtk R CMD build` and `rtk R CMD check`. [VERIFIED: README.Rmd, 40-ARTIFACT-AUDIT.md] | yes for source files; package-check output generated during execution. [VERIFIED: README.Rmd, DESCRIPTION] |
| VAL-02 | Representative non-sf, sf families, facets, legends, dates, coord_flip, and browser smoke remain covered. [VERIFIED: .planning/REQUIREMENTS.md] | unit/integration/browser-smoke | `rtk Rscript --vanilla -e 'devtools::load_all(quiet = TRUE); testthat::test_file("tests/testthat/test-regression-core.R"); testthat::test_file("tests/testthat/test-sf-browser.R")'` plus full `devtools::test()`. [VERIFIED: test-regression-core.R, test-sf-browser.R] | yes. [VERIFIED: `rtk rg --files tests/testthat`] |
| VAL-03 | Failures leave inspectable logs/artifacts and docs explain locations. [VERIFIED: .planning/REQUIREMENTS.md] | source/artifact contract | `rtk rg -n "browser_sf_artifact_dir|write_browser_failure_artifacts|page-errors|browser-log|Rcheck" tests .gitignore .Rbuildignore .planning/phases/40-package-hygiene/40-ARTIFACT-AUDIT.md` [VERIFIED: helper-browser-sf.R, .gitignore, .Rbuildignore] | yes. [VERIFIED: helper-browser-sf.R, 40-ARTIFACT-AUDIT.md] |

### Sampling Rate

- **Per task commit:** Run the quick command or narrower source checks for files touched by the task. [VERIFIED: 42-CONTEXT.md, test-regression-core.R]
- **Per wave merge:** Run docs generation plus the quick command; run full `devtools::test()` when validation docs or test files change. [VERIFIED: README.Rmd, 42-CONTEXT.md]
- **Phase gate:** Run the full release command sequence and record output, expected skips, and artifact paths before `/gsd-verify-work`. [VERIFIED: .planning/ROADMAP.md, 42-CONTEXT.md]

### Wave 0 Gaps

- [ ] `42-VALIDATION-GATE.md` or equivalent phase-local documentation does not exist yet and should be created. [VERIFIED: `rtk rg --files .planning/phases/42-release-validation-gate`]
- [ ] `42-GATE-RUN.md` or equivalent execution-evidence artifact does not exist yet and should be created after running the full gate. [VERIFIED: `rtk rg --files .planning/phases/42-release-validation-gate`]
- [ ] No new test framework is needed. [VERIFIED: DESCRIPTION, tests/testthat.R]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | no | The phase does not add authentication behavior. [VERIFIED: .planning/ROADMAP.md, README.Rmd] |
| V3 Session Management | no | The phase does not add server sessions or auth cookies. [VERIFIED: .planning/ROADMAP.md, README.Rmd] |
| V4 Access Control | no | The phase does not add access-control decisions. [VERIFIED: .planning/ROADMAP.md] |
| V5 Input Validation | yes, for maintainer command inputs and artifact paths | Use fixed local commands and existing testthat helpers; do not eval arbitrary user-provided paths in a new script unless quoted safely. [VERIFIED: existing commands in README.Rmd, helper-browser-sf.R] |
| V6 Cryptography | no | The phase does not add cryptographic behavior. [VERIFIED: .planning/ROADMAP.md] |

### Known Threat Patterns for This Phase

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Command injection in a new gate helper script | Tampering/Elevation of privilege | Prefer documented fixed commands; if a script is added, derive package version from `DESCRIPTION` through R APIs and quote shell paths. [VERIFIED: DESCRIPTION, 42-CONTEXT.md] |
| Source package accidentally includes local planning/debug artifacts | Information disclosure | Preserve `.Rbuildignore` exclusions for `.planning/`, `.claude/`, `AGENTS.md`, `test_output/`, `test_*_files/`, root HTML/PNG/PDF, and `*.Rcheck`. [VERIFIED: .Rbuildignore, 40-ARTIFACT-AUDIT.md] |
| Browser artifact logs leak private local data | Information disclosure | Keep artifacts local and ignored under `test_output/browser-sf/`; do not publish them in generated docs. [VERIFIED: .gitignore, helper-browser-sf.R, 42-CONTEXT.md] |

## Sources

### Primary (HIGH confidence)

- `.planning/phases/42-release-validation-gate/42-CONTEXT.md` - locked Phase 42 decisions, constraints, coverage anchors, and deferred ideas. [VERIFIED: local file read]
- `.planning/REQUIREMENTS.md` - VAL-01, VAL-02, VAL-03 definitions. [VERIFIED: local file read]
- `.planning/ROADMAP.md` - Phase 42 goal, success criteria, expected plans, and dependency on Phase 41. [VERIFIED: local file read]
- `.planning/phases/40-package-hygiene/40-SKIP-AUDIT.md` - optional browser/spatial skip behavior. [VERIFIED: local file read]
- `.planning/phases/40-package-hygiene/40-ARTIFACT-AUDIT.md` - artifact paths, ignore rules, and prior package build verification. [VERIFIED: local file read]
- `.planning/phases/41-release-blocking-debt-triage/41-DEBT-AUDIT.md` - release debt status and deferred non-blockers. [VERIFIED: local file read]
- `tests/testthat/test-regression-core.R`, `tests/testthat/test-sf-browser.R`, `tests/testthat/helper-browser-sf.R`, and `tests/testthat/helper-sf-fixtures.R` - validation implementation anchors. [VERIFIED: local file read]
- `README.Rmd`, `DESCRIPTION`, `tests/testthat.R`, `.gitignore`, `.Rbuildignore`, and `AGENTS.md` - commands, package metadata, test setup, ignore rules, and project instructions. [VERIFIED: local file read]

### Secondary (MEDIUM confidence)

- Local R tooling probes for installed versions and availability. [VERIFIED: local command output]
- `.planning/codebase/TESTING.md` - older test architecture notes; useful for context but stale relative to the current expanded test suite. [VERIFIED: local file read]

### Tertiary (LOW confidence)

- None. [VERIFIED: local-only research scope]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - verified from `DESCRIPTION`, README commands, and local installed versions. [VERIFIED: DESCRIPTION, README.Rmd, local package-version probe]
- Architecture: HIGH - Phase 42 is composition over existing R/testthat/chromote/package-check assets. [VERIFIED: 42-CONTEXT.md, test-regression-core.R, helper-browser-sf.R]
- Pitfalls: HIGH - skip behavior, artifacts, and deferred debt were already audited in Phases 40 and 41. [VERIFIED: 40-SKIP-AUDIT.md, 40-ARTIFACT-AUDIT.md, 41-DEBT-AUDIT.md]
- Full gate runtime: MEDIUM - local tooling was probed, but the full release gate was not executed during research. [VERIFIED: local package-version probe]

**Research date:** 2026-05-23 [VERIFIED: local date context]  
**Valid until:** 2026-06-22 for local project architecture; re-probe installed package versions before execution. [ASSUMED]
