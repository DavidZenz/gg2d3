---
phase: 42
slug: release-validation-gate
status: draft
created: 2026-05-23
---

# Phase 42 - Release Validation Gate

## Purpose

This document defines the local release validation contract for VAL-01, VAL-02, and VAL-03. It gives maintainers a quick local gate for day-to-day confidence, a full release gate for release evidence, the expected optional skip semantics, the behavior coverage map, and the artifact paths to inspect when validation fails.

## Quick Local Gate

Run this gate from the repository root:

```bash
rtk Rscript --vanilla -e 'devtools::load_all(quiet = TRUE); testthat::test_file("tests/testthat/test-regression-core.R"); testthat::test_file("tests/testthat/test-sf-browser.R")'
```

This quick tier covers the bounded release-surface regression matrix and the browser smoke source/artifact contract. Browser and spatial checks may skip when optional local tooling is absent, provided the skip message is explicit.

## Full Release Gate

Run this sequence for release evidence. Read the tarball version from `DESCRIPTION` before the `R CMD check` command:

```bash
rtk Rscript --vanilla -e 'devtools::document(); devtools::build_readme(); devtools::test()'
rtk Rscript --vanilla -e 'cat(read.dcf("DESCRIPTION")[1, "Version"])'
cd /private/tmp
rtk R CMD build --no-manual /Users/davidzenz/R/gg2d3
rtk R CMD check --as-cran gg2d3_0.0.0.9000.tar.gz
```

Replace gg2d3_0.0.0.9000.tar.gz with the package version printed from DESCRIPTION when the version changes.

## Expected Optional Skips

The quick and full gates preserve optional browser and spatial skip behavior for local machines that do not have every smoke-test dependency installed.

## Coverage Matrix

The release gate maps each required behavior area to concrete commands, test files, source files, and failure artifacts.

## Failure Artifacts

Validation failures should leave actionable local files or diffs that identify the failing gate and the next inspection point.

## Phase 42 Evidence Files

- `.planning/phases/42-release-validation-gate/42-VALIDATION-GATE.md` records the maintainer-facing command and interpretation contract.
- `.planning/phases/42-release-validation-gate/42-GATE-RUN.md` records execution evidence when the full release gate is run.
- `.planning/phases/42-release-validation-gate/42-VERIFICATION.md` records final Phase 42 verification evidence.

## Out Of Scope

- New scripts, package dependencies, or hidden release wrappers.
- Node/browser automation stacks such as Playwright, Puppeteer, or Selenium.
- screenshot diff or pixel diff infrastructure.
- Renderer feature work or broad parity fixes.
