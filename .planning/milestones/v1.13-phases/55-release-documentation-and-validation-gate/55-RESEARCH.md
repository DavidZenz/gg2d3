# Phase 55: Release Documentation And Validation Gate - Research

**Researched:** 2026-05-28  
**Domain:** R package release documentation, generated artifacts, browser visual smoke evidence, and release-readiness validation  
**Confidence:** HIGH for repo surface and local commands; MEDIUM for live GitHub artifact refresh because `gh` is installed but current auth is invalid. [VERIFIED: local file audit; local command probes]

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
### Documentation Alignment
- **D-01:** Use a source-first documentation path: update `README.Rmd`, roxygen source, and vignettes/diagnostics first, then regenerate derived files such as `README.md` and `.Rd` help.
- **D-02:** Keep public support language conservative. Clearly list shipped v1.13 support and explicit deferrals rather than making broad release-readiness claims.
- **D-03:** Run `devtools::document()` and verify generated help alignment when roxygen source changes.

### Validation Gate Shape
- **D-04:** The release-readiness gate should include `devtools::test()`, focused source/contract gates, documentation generation, browser visual smoke behavior, and `R CMD check` evidence.
- **D-05:** Browser visual smoke evidence should include the local skip-friendly command and, if feasible, CI-equivalent or GitHub Actions artifact evidence.
- **D-06:** Record artifact paths and result summaries in validation evidence, but do not commit generated browser/check outputs.

### Skip And Failure Policy
- **D-07:** Explicit optional browser/spatial skips are acceptable when documented; true test, documentation, or package-check failures block release readiness.
- **D-08:** Local browser launch failure may be documented as a skip, but the dedicated CI browser workflow should either pass or have downloaded artifact evidence explaining the result.
- **D-09:** Keep `FUT-01` through `FUT-06` as explicit future work in release notes and validation handoff.

### Release Notes And Evidence
- **D-10:** Add a `NEWS.md` v1.13 section covering shipped support, validation commands, artifact guidance, and residual risks.
- **D-11:** Final Phase 55 validation should map every v1.13 requirement, not only `REL-01` through `REL-03`, to source, tests, docs, and gate results.
- **D-12:** After Phase 55 passes, the expected posture is to proceed to `$gsd-complete-milestone`.

### Claude's Discretion
- Planning may choose the exact split between documentation, validation, release notes, and final evidence plans.
- The exact release-gate script or command grouping is flexible if it records the required evidence without committing generated outputs.
- The planner may decide whether GitHub Actions artifact checking is a separate task or part of the browser visual validation task, depending on current workflow availability.

### Deferred Ideas (OUT OF SCOPE)
- Committed golden screenshots and pixel-diff thresholds remain future work (`FUT-01`).
- Public hosted visual reports for pull requests remain future work (`FUT-02`).
- Full `as_d3_ir()` modularization remains future work (`FUT-03`).
- Generated renderer documentation from contracts remains future work (`FUT-04`).
- Full ggrepel-compatible placement and broad GIS topology repair remain future work (`FUT-05`, `FUT-06`).
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| REL-01 | README, vignettes, diagnostics docs, roxygen source, and generated help describe the v1.13 validation, architecture, and geometry support contract from source-first documentation. [VERIFIED: .planning/REQUIREMENTS.md] | Source/generated documentation map identifies `README.Rmd`, `vignettes/gg2d3.Rmd`, `vignettes/d3-drawing-diagnostics.md`, `R/gg2d3.R`, `README.md`, and `man/gg2d3.Rd` as the alignment surface. [VERIFIED: 55-CONTEXT.md; file audit] |
| REL-02 | A repeatable release-readiness gate covers package tests, docs generation, browser visual smoke behavior, optional dependency skips, and package check evidence. [VERIFIED: .planning/REQUIREMENTS.md] | Validation command set reuses project commands, Phase 42 release-gate precedent, Phase 52 browser workflow, and current local tool availability. [VERIFIED: AGENTS.md; 42-GATE-RUN.md; .github/workflows/browser-visual-smoke.yaml; local command probes] |
| REL-03 | v1.13 release notes summarize shipped support, validation commands, artifact locations, residual risks, and future candidates without publishing local logs. [VERIFIED: .planning/REQUIREMENTS.md] | `NEWS.md` currently has a development heading and older 0.1.0-0.6.0 entries, so v1.13 content should be inserted under the development heading rather than in a separate release artifact. [VERIFIED: NEWS.md] |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

- Use the R package development commands `devtools::load_all()`, `devtools::document()`, `devtools::test()`, `testthat::test_file(...)`, and `devtools::build_readme()` for local package workflows. [VERIFIED: CLAUDE.md; AGENTS.md]
- Keep the three-layer architecture framing: R layer `R/as_d3_ir.R`, JSON-serializable IR layer, and D3 renderer `inst/htmlwidgets/gg2d3.js`. [VERIFIED: CLAUDE.md; AGENTS.md]
- D3 v7 is vendored under `inst/htmlwidgets/lib/d3/d3.v7.min.js` and declared by `inst/htmlwidgets/gg2d3.yaml`. [VERIFIED: CLAUDE.md; README.Rmd]
- Current public support language must stay scoped around shipped geoms, supported sf families, known browser validation skips, and explicit non-goals. [VERIFIED: README.Rmd; vignettes/d3-drawing-diagnostics.md; R/gg2d3.R]
- `CLAUDE.md` and `AGENTS.md` are excluded from package builds by `.Rbuildignore`; `CLAUDE.md` is ignored by `.gitignore`, while `AGENTS.md` is currently untracked and should not be folded into Phase 55 commits unless the user explicitly wants it committed. [VERIFIED: .Rbuildignore; .gitignore; git status]

## Summary

Phase 55 should be planned as a documentation and validation closure phase, not as a feature phase. [VERIFIED: 55-CONTEXT.md] The repository already contains v1.13-era support language in `README.Rmd`, `README.md`, `vignettes/gg2d3.Rmd`, `vignettes/d3-drawing-diagnostics.md`, `R/gg2d3.R`, and `man/gg2d3.Rd`, but Phase 55 must sweep these files for consistent wording about validation, renderer/IR contracts, ordinary `geom_label()`, ordinary `geom_polygon()`, rect/tile transformed bounds, sf support, and explicit future work. [VERIFIED: repo grep]

The release gate should reuse the established R-package toolchain rather than introduce a wrapper framework. [VERIFIED: AGENTS.md; 42-VALIDATION-GATE.md] The gate should run documentation generation, full tests, focused source gates, local browser visual smoke behavior, and an explicit source package build plus `R CMD check --as-cran` from `/private/tmp`. [VERIFIED: 55-CONTEXT.md; 42-GATE-RUN.md; local R package-version probe]

`NEWS.md` is the release notes target and currently lacks a v1.13 entry. [VERIFIED: NEWS.md; 55-CONTEXT.md] The new v1.13 section should summarize shipped CI/browser validation, renderer/IR contract consolidation, bounded geometry polish, release-gate commands, artifact paths, retained optional skips, residual risks, and `FUT-01` through `FUT-06` without embedding local logs or raw browser output. [VERIFIED: 55-CONTEXT.md; .planning/REQUIREMENTS.md]

**Primary recommendation:** plan four scoped tracks: documentation source/generated alignment, release gate execution and evidence, `NEWS.md` v1.13 notes, and final all-requirements evidence mapping for `$gsd-complete-milestone`. [VERIFIED: 55-CONTEXT.md; 42-GATE-RUN.md; 52-54 verification files]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Source-first public docs | R package source/docs | Generated docs | `README.Rmd`, roxygen in `R/gg2d3.R`, and vignettes are edited first; `README.md` and `man/gg2d3.Rd` are generated/verified outputs. [VERIFIED: README.Rmd; man/gg2d3.Rd; 55-CONTEXT.md] |
| Release-readiness gate | Local R package tooling | Scratch filesystem and GitHub Actions | `devtools`, `testthat`, `R CMD build/check`, browser smoke, and CI artifacts produce evidence; source code should not implement a new gate runtime. [VERIFIED: AGENTS.md; 42-VALIDATION-GATE.md; .github/workflows/browser-visual-smoke.yaml] |
| Browser visual smoke evidence | GitHub Actions / local chromote test | Ignored artifact storage | The browser workflow runs `test-browser-visual-smoke.R` and uploads `test_output/browser-visual-smoke/`; local runs write the same ignored path. [VERIFIED: .github/workflows/browser-visual-smoke.yaml; helper-browser-visual.R; .gitignore; .Rbuildignore] |
| Release notes | Package documentation | Phase validation evidence | `NEWS.md` is the chosen public release-note target and should summarize evidence paths, not embed generated logs. [VERIFIED: 55-CONTEXT.md; NEWS.md] |
| Final requirement traceability | Planning artifacts | Source/tests/docs | Final Phase 55 evidence must map all v1.13 requirements to source, tests, docs, and gate outcomes. [VERIFIED: 55-CONTEXT.md; .planning/REQUIREMENTS.md] |

## Standard Stack

### Core

| Library/Tool | Version | Purpose | Why Standard |
|--------------|---------|---------|--------------|
| R | 4.6.0 | Runs package code, tests, docs, build, and check commands. | Installed runtime for this package workflow. [VERIFIED: `rtk R --version`] |
| devtools | 2.5.2 | Runs `document()`, `build_readme()`, and `test()` during the release gate. | Project development commands already use devtools. [VERIFIED: local R probe; AGENTS.md] |
| testthat | 3.3.2 | Executes focused and full test gates. | `DESCRIPTION` declares testthat edition 3 and tests use `testthat::test_file()`. [VERIFIED: DESCRIPTION; local R probe] |
| roxygen2 | 8.0.0 | Generates `.Rd` help and `NAMESPACE` from roxygen source. | `DESCRIPTION` records `Config/roxygen2/version: 8.0.0`, and generated Rd files identify roxygen output. [VERIFIED: DESCRIPTION; man/gg2d3.Rd; local R probe] |
| R CMD build/check | R 4.6.0 toolchain | Produces source tarball and `*.Rcheck/00check.log` release evidence. | Phase 42 precedent used explicit build/check and retained only summarized outcomes. [VERIFIED: 42-GATE-RUN.md; local R probe] |

### Supporting

| Library/Tool | Version | Purpose | When to Use |
|--------------|---------|---------|-------------|
| pkgload | 1.5.2 | Loads package during focused source and browser smoke tests. | Use in focused `testthat::test_file()` commands. [VERIFIED: local R probe; tests/testthat/helper-browser-visual.R] |
| chromote | 0.5.1 | Drives optional browser visual smoke. | Use only when `GG2D3_BROWSER_VISUAL_SMOKE=true`; local Chrome exists but launch may still fail and be documented. [VERIFIED: DESCRIPTION; local R probe; chromote::find_chrome probe; 54-VALIDATION.md] |
| htmlwidgets | 1.6.4 | Saves browser smoke widgets and renders package widgets. | Browser smoke helpers call `htmlwidgets::saveWidget()`. [VERIFIED: local R probe; helper-browser-visual.R] |
| gh CLI | 2.93.0 | Lists/downloads GitHub Actions workflow artifacts. | Use for CI artifact evidence if auth is valid; current auth is invalid. [VERIFIED: `rtk gh --version`; `rtk gh auth status`; `gh run download --help`] |
| sf | Not installed locally | Optional spatial tests and browser smoke rows. | Missing `sf` is an expected optional skip when explicitly recorded. [VERIFIED: local R probe; helper-browser-visual.R; 54-VALIDATION.md] |
| geojsonsf | 2.0.5 | Optional sf conversion dependency. | Available locally, but sf-dependent rows still skip if `sf` is absent. [VERIFIED: local R probe; helper-browser-visual.R] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Explicit `R CMD build` plus `R CMD check` | `devtools::check()` | Explicit build/check gives concrete tarball and `*.Rcheck/00check.log` paths that match Phase 42 release evidence. [VERIFIED: 42-VALIDATION-GATE.md; 42-GATE-RUN.md] |
| Existing browser visual smoke workflow and artifacts | New Playwright/Selenium stack | New browser stacks are out of scope and would duplicate the chromote/testthat path already built in Phase 52. [VERIFIED: 52-CONTEXT.md; DESCRIPTION; .github/workflows/browser-visual-smoke.yaml] |
| `NEWS.md` release notes | Separate phase-local release notes file | User locked `NEWS.md` as the release notes target. [VERIFIED: 55-CONTEXT.md] |

**Installation:** No new dependencies should be planned unless the gate exposes a concrete release blocker in existing tooling. [VERIFIED: 55-CONTEXT.md; DESCRIPTION]

**Version verification:** Versions above were verified locally with `rtk Rscript --vanilla -e 'packageVersion(...)'`, `rtk R --version`, and `rtk gh --version`; npm registry verification is not applicable because this is an R package phase. [VERIFIED: local command probes]

## Documentation Surface

| File | Type | Source/Generated | Phase 55 Action |
|------|------|------------------|-----------------|
| `README.Rmd` | Public README source | Source | Update first for v1.13 validation, architecture, geometry support, release gate pointers, and conservative limitations. [VERIFIED: README.Rmd; 55-CONTEXT.md] |
| `README.md` | GitHub README | Generated from `README.Rmd` | Regenerate with `devtools::build_readme()` and inspect generated diff. [VERIFIED: README.Rmd] |
| `vignettes/gg2d3.Rmd` | Main vignette source | Source | Align support and caveat summary with diagnostics and README. [VERIFIED: vignettes/gg2d3.Rmd] |
| `vignettes/d3-drawing-diagnostics.md` | Diagnostics documentation | Source markdown | Keep browser smoke commands, artifact paths, renderer/IR contract boundaries, geometry caveats, and deferred pixel/golden scope current. [VERIFIED: vignettes/d3-drawing-diagnostics.md] |
| `R/gg2d3.R` | Exported roxygen source | Source | Add/align concise v1.13 validation and caveat language if needed. [VERIFIED: R/gg2d3.R] |
| `man/gg2d3.Rd` | Help page | Generated by roxygen2 | Verify after `devtools::document()`; do not edit by hand. [VERIFIED: man/gg2d3.Rd] |
| `NAMESPACE` | Package namespace | Generated by roxygen2 | Inspect after `devtools::document()`; keep changes only if source-backed. [VERIFIED: project roxygen workflow in AGENTS.md; DESCRIPTION] |
| `NEWS.md` | Release notes | Source | Insert a v1.13 section under the development heading. [VERIFIED: NEWS.md; 55-CONTEXT.md] |

## Architecture Patterns

### System Architecture Diagram

```text
Source docs + roxygen edits
  -> devtools::document() / devtools::build_readme()
  -> generated README.md + man/*.Rd + NAMESPACE diff inspection
  -> docs alignment gate

Focused source gates + devtools::test()
  -> testthat results with expected optional skips
  -> release gate evidence summary

Browser visual smoke command
  -> local skip/pass/fail behavior OR GitHub Actions run
  -> ignored test_output/browser-visual-smoke/ artifacts
  -> summarized artifact paths and outcome only

R CMD build/check from /private/tmp
  -> source tarball + gg2d3.Rcheck/00check.log
  -> summarized package-check outcome only

All evidence
  -> NEWS.md v1.13 summary
  -> Phase 55 final VALIDATION/VERIFICATION evidence
  -> ready for $gsd-complete-milestone
```

### Recommended Project Structure

```text
.planning/phases/55-release-documentation-and-validation-gate/
├── 55-RESEARCH.md          # this planning research
├── 55-VALIDATION.md        # orchestrator validation architecture / gate map
├── 55-GATE-RUN.md          # recommended execution evidence artifact
└── 55-VERIFICATION.md      # final all-requirements evidence map

README.Rmd                 # source README
README.md                  # generated README
R/gg2d3.R                  # roxygen source
man/gg2d3.Rd               # generated help
vignettes/                 # source docs
NEWS.md                    # public v1.13 release notes
test_output/               # ignored generated browser artifacts
/private/tmp/*.Rcheck      # uncommitted package-check artifacts
```

### Pattern 1: Source-First Generated Docs

**What:** edit source docs first, regenerate derived artifacts, then inspect diffs for consistency. [VERIFIED: README.Rmd; man/gg2d3.Rd; 55-CONTEXT.md]  
**When to use:** any change to README language, exported help text, or generated `.Rd` files. [VERIFIED: AGENTS.md; 55-CONTEXT.md]  
**Example:**

```bash
rtk Rscript --vanilla -e 'devtools::document(); devtools::build_readme()'
rtk git diff -- README.Rmd README.md R/gg2d3.R man/gg2d3.Rd NAMESPACE
```

### Pattern 2: Two-Tier Release Gate

**What:** run fast focused gates before the full package release gate. [VERIFIED: 53-VALIDATION.md; 54-VALIDATION.md; 42-VALIDATION-GATE.md]  
**When to use:** after docs/release-note changes and before final Phase 55 verification. [VERIFIED: 55-CONTEXT.md]  
**Example:**

```bash
rtk Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-renderer-wiring-contracts.R"); testthat::test_file("tests/testthat/test-ir-helper-boundaries.R")'
rtk Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-text-label-polish.R"); testthat::test_file("tests/testthat/test-polygon-ir.R"); testthat::test_file("tests/testthat/test-rect-tile-ir.R")'
rtk Rscript --vanilla -e 'devtools::document(); devtools::build_readme(); devtools::test()'
```

### Pattern 3: Evidence Without Artifact Leakage

**What:** record artifact paths, run IDs, counts, and summaries in planning evidence while leaving generated files under ignored roots. [VERIFIED: 55-CONTEXT.md; .gitignore; .Rbuildignore; helper-browser-visual.R]  
**When to use:** browser smoke outputs, `R CMD check` directories, package tarballs, and local generated report files. [VERIFIED: 42-GATE-RUN.md; 52-VERIFICATION.md]  
**Example:**

```bash
rtk git status --short
rtk rg -n "test_output|Rcheck|*.tar.gz|index.json|00check.log" .gitignore .Rbuildignore
```

### Anti-Patterns to Avoid

- **Editing generated docs by hand:** `README.md` and `man/gg2d3.Rd` are generated artifacts, so source edits belong in `README.Rmd` and roxygen comments. [VERIFIED: README.Rmd; man/gg2d3.Rd]
- **Overclaiming ggplot2 parity:** public docs must keep topology repair, ggrepel collision avoidance, rich text, path-following text, pixel thresholds, and generated renderer docs as explicit deferrals. [VERIFIED: README.Rmd; vignettes/d3-drawing-diagnostics.md; .planning/REQUIREMENTS.md]
- **Treating local browser failure as a silent pass:** local browser launch failure can be documented as a skip, but CI mode should fail browser-level skips or provide downloaded artifact evidence. [VERIFIED: 55-CONTEXT.md; helper-browser-visual.R; 52-VERIFICATION.md]
- **Committing generated browser/check outputs:** `test_output/`, root HTML/PNG/PDF outputs, `*.Rcheck/`, and related generated roots are ignored or build-excluded and should stay uncommitted. [VERIFIED: .gitignore; .Rbuildignore]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Documentation generation | Custom README/Rd renderer | `devtools::document()` and `devtools::build_readme()` | Existing project commands and generated-file markers already define the source/output relationship. [VERIFIED: AGENTS.md; README.Rmd; man/gg2d3.Rd] |
| Package check | Bespoke package validator | `R CMD build --no-manual` plus `R CMD check --as-cran` | Produces standard tarball and `.Rcheck/00check.log` evidence used in prior release gates. [VERIFIED: 42-GATE-RUN.md] |
| Browser evidence | New browser automation framework | Existing `test-browser-visual-smoke.R` plus `.github/workflows/browser-visual-smoke.yaml` | Existing harness already writes HTML, PNG, DOM summary, browser log, index JSON, and report HTML artifacts. [VERIFIED: helper-browser-visual.R; test-browser-visual-smoke.R; browser-visual-smoke.yaml] |
| Release notes | Separate local log dump | `NEWS.md` with summarized outcomes | User locked `NEWS.md`, and local logs must not be published. [VERIFIED: 55-CONTEXT.md] |
| Requirement traceability | Ad hoc prose only | Table mapping requirement -> source/tests/docs/gate result | Phase 55 must map every v1.13 requirement to evidence, not just REL-01 through REL-03. [VERIFIED: 55-CONTEXT.md; .planning/REQUIREMENTS.md] |

**Key insight:** Phase 55 is mainly about making existing source, generated docs, tests, workflows, and evidence agree; new automation would increase release risk unless it directly fixes a discovered blocker. [VERIFIED: 55-CONTEXT.md; 42-GATE-RUN.md]

## Common Pitfalls

### Pitfall 1: Generated Docs Drift
**What goes wrong:** README/help text claims a different support boundary than source docs. [VERIFIED: 55-CONTEXT.md]  
**Why it happens:** source files and generated files are both present in the repo. [VERIFIED: README.Rmd; man/gg2d3.Rd]  
**How to avoid:** regenerate with `devtools::document(); devtools::build_readme()` after source edits and inspect diffs. [VERIFIED: AGENTS.md]  
**Warning signs:** `README.Rmd` and `README.md` mention different geoms, skips, or caveats. [VERIFIED: repo grep]

### Pitfall 2: Browser Evidence Misclassified
**What goes wrong:** optional local browser launch failure is treated the same as CI browser workflow evidence. [VERIFIED: 55-CONTEXT.md; 52-VERIFICATION.md]  
**Why it happens:** local smoke can skip, but CI mode intentionally hard-errors browser-level unavailability. [VERIFIED: helper-browser-visual.R]  
**How to avoid:** record local skip-friendly command output separately from CI-equivalent command or downloaded artifact evidence. [VERIFIED: 52-VERIFICATION.md]  
**Warning signs:** validation evidence says “browser passed” without `index.json`, workflow run ID, or explicit skip reason. [VERIFIED: 52-VERIFICATION.md; helper-browser-visual.R]

### Pitfall 3: Publishing Logs Instead Of Summaries
**What goes wrong:** `NEWS.md` includes raw local logs, check output, or browser log details. [VERIFIED: 55-CONTEXT.md]  
**Why it happens:** release-gate evidence naturally produces long generated outputs. [VERIFIED: 42-GATE-RUN.md; helper-browser-visual.R]  
**How to avoid:** put summaries, counts, paths, run IDs, and artifact names in docs; keep logs in ignored locations. [VERIFIED: .gitignore; .Rbuildignore; 42-GATE-RUN.md]  
**Warning signs:** `NEWS.md` contains `00check.log` excerpts, browser console JSON, or local absolute log dumps beyond artifact path summaries. [VERIFIED: 55-CONTEXT.md]

### Pitfall 4: Package Check Runs From The Repo Root
**What goes wrong:** build/check artifacts pollute the source tree or package tarball assumptions are unclear. [VERIFIED: 42-GATE-RUN.md]  
**Why it happens:** `R CMD check` writes `*.Rcheck/` next to the tarball by default. [VERIFIED: 42-GATE-RUN.md]  
**How to avoid:** build and check from `/private/tmp`, then summarize `/private/tmp/gg2d3.Rcheck/00check.log`. [VERIFIED: 42-VALIDATION-GATE.md; 42-GATE-RUN.md]  
**Warning signs:** `git status --short` shows `*.Rcheck/`, tarballs, root HTML, root PNG, or `test_output` files. [VERIFIED: .gitignore; .Rbuildignore]

## Code Examples

### Documentation Generation Gate

```bash
rtk Rscript --vanilla -e 'devtools::document(); devtools::build_readme()'
rtk git diff -- README.Rmd README.md R/gg2d3.R man/gg2d3.Rd NAMESPACE vignettes/gg2d3.Rmd vignettes/d3-drawing-diagnostics.md NEWS.md
```

Source: project commands and source/generated doc markers. [VERIFIED: AGENTS.md; README.Rmd; man/gg2d3.Rd]

### Focused v1.13 Source Gates

```bash
rtk Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-renderer-wiring-contracts.R"); testthat::test_file("tests/testthat/test-ir-helper-boundaries.R")'
rtk Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-text-label-polish.R"); testthat::test_file("tests/testthat/test-polygon-ir.R"); testthat::test_file("tests/testthat/test-polygon-renderer.R"); testthat::test_file("tests/testthat/test-rect-tile-ir.R"); testthat::test_file("tests/testthat/test-rect-tile-renderer.R")'
```

Source: Phase 53 and 54 validation gates. [VERIFIED: 53-VALIDATION.md; 54-VALIDATION.md]

### Full R Package Gate

```bash
rtk Rscript --vanilla -e 'devtools::document(); devtools::build_readme(); devtools::test()'

# Run from /private/tmp; replace tarball name if DESCRIPTION Version changes.
rtk R CMD build --no-manual /Users/davidzenz/R/gg2d3
rtk R CMD check --as-cran gg2d3_0.0.0.9000.tar.gz
```

Source: Phase 42 release-gate precedent and current `DESCRIPTION` version. [VERIFIED: 42-VALIDATION-GATE.md; 42-GATE-RUN.md; DESCRIPTION]

### Browser Visual Smoke Commands

```bash
# Skip-friendly local command.
rtk Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-browser-visual-smoke.R")'

# Local artifact command.
rtk env NOT_CRAN=true GG2D3_BROWSER_VISUAL_SMOKE=true Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-browser-visual-smoke.R")'

# CI-equivalent local command.
rtk env NOT_CRAN=true GG2D3_BROWSER_VISUAL_SMOKE=true GG2D3_BROWSER_VISUAL_CI=true Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); res <- testthat::test_file("tests/testthat/test-browser-visual-smoke.R"); df <- as.data.frame(res); if (any(df$failed > 0 | df$error)) quit(status = 1)'
```

Source: diagnostics docs and workflow command. [VERIFIED: vignettes/d3-drawing-diagnostics.md; .github/workflows/browser-visual-smoke.yaml]

### CI Artifact Evidence Commands

```bash
rtk gh run list --workflow browser-visual-smoke.yaml --limit 5 --json databaseId,status,conclusion,headSha,createdAt,url
rtk gh run download <run-id> --name browser-visual-smoke-<run-id> --dir test_output/github-run-<run-id>
rtk Rscript --vanilla -e 'x <- jsonlite::read_json("test_output/github-run-<run-id>/browser-visual-smoke-<run-id>/index.json", simplifyVector=TRUE); print(table(x$rows$status)); stopifnot(all(x$rows$status == "passed" | startsWith(x$rows$id, "sf-")))'
```

Source: `gh` help output, workflow artifact naming, and downloaded Phase 52 artifact shape. [VERIFIED: gh help probes; .github/workflows/browser-visual-smoke.yaml; 52-VERIFICATION.md; test_output/github-run-26575140296]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Local browser smoke only | Dedicated GitHub Actions browser workflow plus local skip-friendly command | Phase 52, 2026-05-28 | Release evidence can reference CI artifact bundle and local skip behavior separately. [VERIFIED: 52-VERIFICATION.md] |
| Renderer assumptions spread across modules | Source-level geom contract and focused drift tests | Phase 53, 2026-05-28 | Release docs can cite `geom-contracts.js` and `test-renderer-wiring-contracts.R` as maintained architecture boundaries. [VERIFIED: 53-VERIFICATION.md] |
| Geometry polish as open debt | Bounded `geom_label()`, explicit ordinary polygon topology non-goal, and rect/tile transformed-bound filtering | Phase 54, 2026-05-28 | Public docs must distinguish shipped support from residual risks. [VERIFIED: 54-VERIFICATION.md] |
| Separate phase-local release notes artifact | `NEWS.md` v1.13 entry | Phase 55 decision, 2026-05-28 | Planner should update package release notes directly. [VERIFIED: 55-CONTEXT.md] |

**Deprecated/outdated:**
- Raw local logs in release-facing notes are not appropriate for Phase 55; use summarized outcomes and paths only. [VERIFIED: 55-CONTEXT.md]
- Pixel-diff thresholds and committed golden screenshots remain deferred. [VERIFIED: .planning/REQUIREMENTS.md; vignettes/d3-drawing-diagnostics.md]
- Generated renderer documentation remains deferred to FUT-04. [VERIFIED: .planning/REQUIREMENTS.md; vignettes/d3-drawing-diagnostics.md]

## Recommended Plan Split

| Plan | Scope | Key Outputs |
|------|-------|-------------|
| 55-01 Documentation alignment | Sweep source docs and generated outputs for v1.13 validation, architecture, and geometry support contract. [VERIFIED: 55-CONTEXT.md] | `README.Rmd`, `README.md`, `vignettes/gg2d3.Rmd`, `vignettes/d3-drawing-diagnostics.md`, `R/gg2d3.R`, `man/gg2d3.Rd`, `NAMESPACE` only if regenerated. [VERIFIED: file audit] |
| 55-02 Release gate evidence | Run focused gates, docs generation, full tests, browser smoke behavior, and package build/check; record summaries and artifact paths. [VERIFIED: 55-CONTEXT.md; 42-GATE-RUN.md] | Recommended `.planning/phases/55-release-documentation-and-validation-gate/55-GATE-RUN.md` plus generated docs if source-backed. [VERIFIED: 42-GATE-RUN.md pattern] |
| 55-03 NEWS v1.13 | Insert conservative v1.13 release notes under `NEWS.md` development heading. [VERIFIED: NEWS.md; 55-CONTEXT.md] | `NEWS.md` with shipped support, commands, artifact locations, residual risks, and FUT candidates. [VERIFIED: 55-CONTEXT.md] |
| 55-04 Final validation map | Map CI/ARCH/GEOM/REL requirements to source, tests, docs, and gate outcomes. [VERIFIED: 55-CONTEXT.md; .planning/REQUIREMENTS.md] | `55-VALIDATION.md` / `55-VERIFICATION.md` evidence suitable for `$gsd-complete-milestone`. [VERIFIED: 52-54 verification file patterns] |

## Current NEWS.md Insertion Guidance

`NEWS.md` currently starts with `# gg2d3 (development version)` and then older sections `gg2d3 0.6.0` through `gg2d3 0.1.0`. [VERIFIED: NEWS.md] Insert the v1.13 release-note material immediately under the development heading, using bullets that summarize:

- CI/browser visual smoke support, artifact bundle names, local/CI commands, and retained pixel/golden deferral. [VERIFIED: 52-VERIFICATION.md; .planning/REQUIREMENTS.md]
- Renderer/IR contract consolidation through `geom-contracts.js`, renderer wiring tests, and helper-boundary tests. [VERIFIED: 53-VERIFICATION.md]
- Geometry polish support for bounded ordinary labels, explicit ordinary polygon topology non-goal, and rect/tile transformed-bound filtering. [VERIFIED: 54-VERIFICATION.md]
- Release gate commands and artifact paths without raw local logs. [VERIFIED: 55-CONTEXT.md; 42-GATE-RUN.md]
- Future candidates `FUT-01` through `FUT-06`. [VERIFIED: .planning/REQUIREMENTS.md]

## Resolved Questions

1. **RESOLVED: How should CI artifact evidence be refreshed if `gh` auth remains invalid?**
   Accepted resolution: `gh` artifact download remains preferred when authentication is valid; if `gh auth status` is invalid during execution, the GitHub artifact fallback is accepted. The executor should record the auth limitation and use the existing downloaded Phase 52 artifact path `test_output/github-run-26575140296/browser-visual-smoke-26575140296/` when live refresh is unavailable. [VERIFIED: 52-VERIFICATION.md; test_output audit; checker revision decision]

2. **RESOLVED: How should package-check ERROR/WARNING/NOTE outcomes be classified?**
   Accepted resolution: package-check ERROR or WARNING outcomes block release readiness. NOTEs are not pre-classified during planning; they must be classified after execution with the exact NOTE class, summary, and rationale in gate evidence. Broad metadata cleanup should not be planned unless the executed gate exposes a release-blocking ERROR/WARNING or a NOTE the maintainer chooses to treat as blocking. [VERIFIED: 55-CONTEXT.md; 42-GATE-RUN.md; checker revision decision]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| R | All package commands | ✓ | 4.6.0 | None needed. [VERIFIED: `rtk R --version`] |
| devtools | Docs/test gate | ✓ | 2.5.2 | Use base `R CMD` only for build/check if devtools fails. [VERIFIED: local R probe] |
| testthat | Focused and full tests | ✓ | 3.3.2 | None; package test infrastructure depends on it. [VERIFIED: local R probe; DESCRIPTION] |
| roxygen2 | Generated help | ✓ | 8.0.0 | None; `devtools::document()` uses roxygen. [VERIFIED: local R probe; DESCRIPTION] |
| chromote | Browser smoke | ✓ | 0.5.1 | Document local skip/failure and rely on CI artifact evidence. [VERIFIED: local R probe; helper-browser-visual.R; 55-CONTEXT.md] |
| Chrome | Browser smoke | ✓ found | `/Applications/Google Chrome.app/Contents/MacOS/Google Chrome` | Use `CHROMOTE_CHROME` override or CI workflow if launch fails. [VERIFIED: chromote::find_chrome probe; diagnostics docs] |
| sf | Optional spatial tests | ✗ | — | Expected optional skip with explicit message. [VERIFIED: local R probe; helper-browser-visual.R] |
| geojsonsf | Optional spatial tests | ✓ | 2.0.5 | Still skipped for sf rows if `sf` is absent. [VERIFIED: local R probe; helper-browser-visual.R] |
| gh | CI artifact evidence | ✓ but auth invalid | 2.93.0 | Use existing downloaded artifact evidence or reauthenticate before live artifact refresh. [VERIFIED: `rtk gh --version`; `rtk gh auth status`; 52-VERIFICATION.md] |
| rtk | Project command wrapper | ✓ | 0.42.0 | Project rules require `rtk` prefix. [VERIFIED: RTK.md; `rtk rtk --version`] |

**Missing dependencies with no fallback:**
- None for planning; live GitHub artifact refresh is blocked by invalid auth but has a fallback to existing downloaded artifact evidence. [VERIFIED: gh auth status; 52-VERIFICATION.md]

**Missing dependencies with fallback:**
- `sf` is absent locally; optional spatial/browser rows should be documented as skips unless CI artifact evidence covers sf rows. [VERIFIED: local R probe; helper-browser-visual.R]
- GitHub auth is invalid; `gh` commands should be attempted only if auth is repaired, otherwise use existing downloaded artifact evidence. [VERIFIED: gh auth status; test_output audit]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | testthat 3.3.2, devtools 2.5.2, roxygen2 8.0.0, R CMD build/check, chromote 0.5.1 for optional browser smoke. [VERIFIED: local R probe; DESCRIPTION] |
| Config file | `DESCRIPTION` with `Config/testthat/edition: 3` and `Config/roxygen2/version: 8.0.0`. [VERIFIED: DESCRIPTION] |
| Quick run command | `rtk Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-renderer-wiring-contracts.R"); testthat::test_file("tests/testthat/test-ir-helper-boundaries.R"); testthat::test_file("tests/testthat/test-text-label-polish.R")'` [VERIFIED: 53-VALIDATION.md; 54-VALIDATION.md] |
| Full suite command | `rtk Rscript --vanilla -e 'devtools::document(); devtools::build_readme(); devtools::test()'` followed from `/private/tmp` by `rtk R CMD build --no-manual /Users/davidzenz/R/gg2d3` and `rtk R CMD check --as-cran gg2d3_0.0.0.9000.tar.gz`. [VERIFIED: 42-VALIDATION-GATE.md; DESCRIPTION] |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| REL-01 | Source docs and generated docs align on v1.13 validation, architecture, and geometry contract. [VERIFIED: .planning/REQUIREMENTS.md] | docs/source/generated | `rtk Rscript --vanilla -e 'devtools::document(); devtools::build_readme()'` plus `rtk rg -n "v1.13|browser visual|geom_label|geom_polygon|rect|tile|geom-contracts|FUT-" README.Rmd README.md vignettes/gg2d3.Rmd vignettes/d3-drawing-diagnostics.md R/gg2d3.R man/gg2d3.Rd NEWS.md` [VERIFIED: file audit] | ✅ |
| REL-02 | Release gate covers package tests, focused source gates, docs generation, browser smoke behavior, optional skips, and package check evidence. [VERIFIED: .planning/REQUIREMENTS.md] | integration/release | Use focused gates, full R gate, browser commands, and `/private/tmp` package check commands listed in Code Examples. [VERIFIED: 42-GATE-RUN.md; 52-54 validation files] | ✅ source exists; output generated during execution. |
| REL-03 | `NEWS.md` summarizes shipped support, commands, artifact paths, residual risks, and future candidates without local logs. [VERIFIED: .planning/REQUIREMENTS.md] | docs/source | `rtk rg -n "v1.13|browser visual|R CMD check|test_output/browser-visual-smoke|FUT-01|FUT-06|residual|geom_label|geom_polygon|rect|tile" NEWS.md` [VERIFIED: NEWS.md; 55-CONTEXT.md] | ✅ |

### Sampling Rate

- **Per task commit:** run the narrow command for touched docs/tests plus `rtk git diff --check`. [VERIFIED: project workflow practice from phase validations]
- **Per wave merge:** run focused source gates and docs generation; inspect generated diffs. [VERIFIED: 53-VALIDATION.md; 54-VALIDATION.md]
- **Phase gate:** run full release gate, browser skip/artifact evidence, package build/check, and all-requirements traceability before `/gsd-verify-work`. [VERIFIED: 55-CONTEXT.md]

### Wave 0 Gaps

- [ ] `.planning/phases/55-release-documentation-and-validation-gate/55-GATE-RUN.md` — recommended execution evidence artifact for REL-02, modeled on Phase 42. [VERIFIED: 42-GATE-RUN.md pattern]
- [ ] `NEWS.md` v1.13 section — target file exists but v1.13 entry does not yet exist. [VERIFIED: NEWS.md]
- [ ] Final all-requirements evidence table — required by D-11 and not yet created for Phase 55. [VERIFIED: 55-CONTEXT.md]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | no | No auth feature is implemented in this phase; GitHub auth is only an operator prerequisite for artifact download. [VERIFIED: phase scope; gh auth probe] |
| V3 Session Management | no | No sessions are added or changed. [VERIFIED: 55-CONTEXT.md] |
| V4 Access Control | no | No runtime access-control behavior is added. [VERIFIED: 55-CONTEXT.md] |
| V5 Input Validation | yes | Continue using existing source/test contracts for sanitized browser payloads and `htmltools::htmlEscape()` in generated browser report HTML. [VERIFIED: helper-browser-visual.R; test-renderer-wiring-contracts.R] |
| V6 Cryptography | no | No cryptographic behavior is added. [VERIFIED: 55-CONTEXT.md] |

### Known Threat Patterns for This Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Release notes expose local absolute logs or browser output | Information Disclosure | Summarize outcomes and artifact paths only; leave generated logs in ignored roots. [VERIFIED: 55-CONTEXT.md; .gitignore; .Rbuildignore] |
| Browser report HTML injection through fixture/status fields | Tampering / XSS | Existing report writer escapes row fields with `htmltools::htmlEscape()`. [VERIFIED: helper-browser-visual.R] |
| Public interactivity payload leaks renderer-private fields | Information Disclosure | Existing `publicData.sanitizeDatum()` contract and tests cover private-field sanitization. [VERIFIED: public-data.js; test-renderer-wiring-contracts.R] |
| Package check uses source-tree-only paths | Tampering / Reliability | Run `R CMD check` from built tarball and keep installed-package path assumptions covered by tests. [VERIFIED: 42-GATE-RUN.md; 53-VERIFICATION.md] |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | A new `55-GATE-RUN.md` is the best evidence artifact name for Phase 55. [ASSUMED] | Recommended Plan Split / Validation Architecture | Low: planner can rename the artifact as long as REL-02 evidence captures commands, outcomes, and paths. |

## Sources

### Primary (HIGH confidence)

- `.planning/phases/55-release-documentation-and-validation-gate/55-CONTEXT.md` - locked user decisions and phase boundaries. [VERIFIED: file read]
- `.planning/REQUIREMENTS.md` - v1.13 requirements, REL-01 through REL-03, and FUT-01 through FUT-06. [VERIFIED: file read]
- `.planning/ROADMAP.md` and `.planning/STATE.md` - Phase 55 goal, success criteria, dependency, and milestone posture. [VERIFIED: file read]
- `AGENTS.md`, `CLAUDE.md`, `/Users/davidzenz/.codex/RTK.md` - project commands, architecture, and required `rtk` command prefix. [VERIFIED: file read]
- `README.Rmd`, `README.md`, `vignettes/gg2d3.Rmd`, `vignettes/d3-drawing-diagnostics.md`, `R/gg2d3.R`, `man/gg2d3.Rd`, `NEWS.md` - docs alignment surface. [VERIFIED: file read and repo grep]
- `.github/workflows/browser-visual-smoke.yaml`, `tests/testthat/helper-browser-visual.R`, `tests/testthat/test-browser-visual-smoke.R` - browser smoke commands, artifacts, skip/fail semantics, and workflow upload behavior. [VERIFIED: file read]
- `.gitignore`, `.Rbuildignore` - generated artifact boundaries. [VERIFIED: file read]
- `DESCRIPTION` - package dependencies and test/roxygen configuration. [VERIFIED: file read]
- Phase 52-54 validation and verification artifacts - prior evidence for CI, architecture, and geometry requirements. [VERIFIED: file reads / repo grep]

### Secondary (MEDIUM confidence)

- Local command probes for R, R packages, Chrome, `gh`, `rtk`, and GitHub auth status. [VERIFIED: local command probes]
- Existing downloaded browser artifact under `test_output/github-run-26575140296/browser-visual-smoke-26575140296/`. [VERIFIED: test_output audit; 52-VERIFICATION.md]

### Tertiary (LOW confidence)

- None; no web-only unverified findings were used. [VERIFIED: no web search used]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - versions and availability were verified locally. [VERIFIED: local command probes]
- Architecture: HIGH - docs, workflows, tests, and prior phase evidence are present in repo. [VERIFIED: file audit]
- Pitfalls: HIGH - each pitfall is tied to existing project artifacts or prior release-gate evidence. [VERIFIED: 42-GATE-RUN.md; 52-54 verification files]
- Live CI artifact refresh: MEDIUM - `gh` is installed, but current auth is invalid; existing downloaded artifact evidence is available. [VERIFIED: gh auth status; test_output audit]

**Research date:** 2026-05-28  
**Valid until:** 2026-06-04 for live CI/browser artifact assumptions; 2026-06-27 for stable repo documentation and command structure. [ASSUMED]
