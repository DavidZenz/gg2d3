---
phase: 57-generated-site-validation-gate
status: complete
researched: 2026-06-01
requirements: [SITE-01]
---

# Phase 57 Research: Generated Site Validation Gate

## Research Question

What does the executor need to know to plan a repeatable generated pkgdown site validation gate?

## Current State

Phase 56 created the minimum generated-site evidence:

- `tests/testthat/test-pkgdown-site.R` reads generated files and asserts exact markers.
- `docs/articles/gg2d3.html` and `docs/articles/gg2d3.md` contain current sf support text and either `PKGDOWN_SF_OPTIONAL_SKIP` or rendered widget evidence.
- `docs/articles/gg2d3_files/gg2d3-modules-0.0.1` is tracked as widget dependency evidence.
- `.github/workflows/pkgdown.yaml` installs website dependencies, verifies dependency availability, builds pkgdown, and deploys `docs/`.
- Local `sf` is installed but not loadable because of a missing GDAL dylib, so local generated output currently proves the explicit optional-skip path.

The existing focused test is the right canonical validation core, but it is still shaped like an ordinary test file rather than a reusable validation gate.

## Implementation Findings

### Canonical Validation Logic

The core assertions should be extracted from `tests/testthat/test-pkgdown-site.R` into a test helper such as `tests/testthat/helper-pkgdown-site.R`.

Why:

- `testthat::test_file("tests/testthat/test-pkgdown-site.R")` remains the canonical suite entry.
- A maintainer-facing script can source the same helper instead of duplicating marker logic.
- Failure messages stay file/marker-specific.

The helper should expose deterministic validation functions:

- `pkgdown_site_validate_quick(root = ".")`
- `pkgdown_site_validate_sf_outcome(root = ".", require_rendered_sf = FALSE)`
- `pkgdown_site_spatial_loadable()`
- focused lower-level helpers for reading text, resolving files, checking markers, and checking asset paths.

### Validation Command Shape

A thin script under `tools/` is appropriate for maintainer ergonomics. Recommended file:

- `tools/validate-pkgdown-site.R`

Recommended modes:

- `--mode quick`: inspect committed/generated `docs/` without rebuilding.
- `--mode release`: run `devtools::document()`, `devtools::build_readme()`, `pkgdown::build_site_github_pages(new_process = FALSE, install = FALSE)`, then inspect generated `docs/`.
- `--mode ci`: inspect the just-built `docs/` in GitHub Actions and classify rendered sf evidence based on dependency availability.

The script should default to quick mode so the lowest-friction command is:

```bash
rtk Rscript --vanilla tools/validate-pkgdown-site.R
```

Release mode should be:

```bash
rtk Rscript --vanilla tools/validate-pkgdown-site.R --mode release
```

### Optional sf Classification

The helper should separate three outcomes:

| Outcome | Meaning | Gate behavior |
| --- | --- | --- |
| rendered | A `gg2d3 html-widget` appears after the `sf family maps with` heading. | Pass in all modes. |
| classified_skip | `PKGDOWN_SF_OPTIONAL_SKIP` appears in generated article output. | Pass in local quick mode; fail in CI/release only when spatial deps are loadable or explicitly required. |
| missing | Neither skip nor rendered evidence exists. | Fail in all modes. |

Release/CI mode should not blindly fail local broken `sf` setups. It should require rendered sf only when `requireNamespace("sf")` and `requireNamespace("geojsonsf")` both succeed and both packages can actually load. This matters because local `sf` can be installed but unloadable.

For CI, the pkgdown workflow can pass an explicit environment variable such as:

```yaml
GG2D3_PKGDOWN_VALIDATION_MODE: ci
```

The script should still compute package loadability itself, so workflow logs and local behavior use the same classification.

### Stale Generated-Site Checks

SITE-01 requires stale content detection. Marker checks cover missing support text, widgets, and assets, but stale source-vs-generated drift needs at least one explicit source/generated parity check.

Recommended first-pass parity:

- Source article markers in `vignettes/gg2d3.Rmd`: `sf family maps with`, `geom_sf() supports polygon-family`, `PKGDOWN_SF_OPTIONAL_SKIP`.
- Generated article markers in `docs/articles/gg2d3.html` and `docs/articles/gg2d3.md`: `sf family maps with`, `geom_sf() supports polygon-family`.
- Widget markers in generated HTML: `gg2d3 html-widget`, `d3.v7.min.js`, `gg2d3-modules`.
- Asset path: `docs/articles/gg2d3_files/gg2d3-modules-0.0.1`.
- Reference/NEWS markers: same paths already checked in Phase 56.

If release mode rebuilds first and then `git diff --exit-code` is used by the maintainer or CI, source-derived stale files become visible. The validation script itself can also report that release mode rebuild changed files by running `git status --short` only if `git` is available, but the first implementation can leave the diff gate as a documented command to avoid over-coupling the script to git state.

### CI Integration

The existing `.github/workflows/pkgdown.yaml` already builds the site. Phase 57 should add a validation step after `Build site` and before deploy:

```yaml
- name: Validate generated pkgdown site
  run: tools/validate-pkgdown-site.R --mode ci
  shell: Rscript {0}
```

This keeps CI from deploying a stale or asset-incomplete site.

### Documentation

Maintainer diagnostics should be added to `vignettes/d3-drawing-diagnostics.md`:

- quick validation command;
- release validation command;
- CI mode behavior;
- how to interpret `PKGDOWN_SF_OPTIONAL_SKIP`;
- repair path: edit source docs, rebuild generated outputs, rerun validation.

README can include a short pointer; the detailed interpretation belongs in diagnostics.

## Validation Architecture

| Layer | Gate | Command |
| --- | --- | --- |
| Fast local | Inspect committed generated docs | `rtk Rscript --vanilla tools/validate-pkgdown-site.R --mode quick` |
| Focused test | Canonical testthat assertions | `rtk Rscript --vanilla -e 'testthat::test_file("tests/testthat/test-pkgdown-site.R")'` |
| Release local | Rebuild source-derived docs/site then inspect | `rtk Rscript --vanilla tools/validate-pkgdown-site.R --mode release` |
| Full suite | Ensure helper/test integration does not break package tests | `rtk Rscript --vanilla -e 'devtools::test()'` |
| CI pkgdown | Validate just-built site before deploy | `.github/workflows/pkgdown.yaml` validation step |

## Risks And Mitigations

| Risk | Mitigation |
| --- | --- |
| Duplicated script/test logic drifts | Put validation functions in a helper sourced by both tests and script. |
| Local broken `sf` blocks release preparation | Classify skip vs missing; require rendered sf only when spatial packages are loadable or explicitly required. |
| Generated docs are ignored by git | Keep explicit generated evidence paths and document when force-adding is required. |
| Validation messages become opaque | Keep exact file/path and marker names in every failure. |
| CI deploys before validation | Put validation step after build and before deploy. |

## Recommended Plan Split

1. Validation core extraction: helper plus focused tests.
2. Maintainer/CI command: `tools/validate-pkgdown-site.R` plus pkgdown workflow validation step.
3. Diagnostics and evidence: update maintainer docs and record Phase 57 verification mapping.

## RESEARCH COMPLETE
