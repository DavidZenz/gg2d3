---
phase: 57-generated-site-validation-gate
status: passed
verified: 2026-06-01
sf_outcome: "classified_skip"
---

# Phase 57 Verification

Phase 57 passed its generated-site validation gate. Maintainers now have one reusable validation core, a local/release/CI command wrapper, CI enforcement before pkgdown deploy, and documented interpretation/repair guidance.

## Commands Run

| Command | Outcome |
|---------|---------|
| `rtk Rscript --vanilla tools/validate-pkgdown-site.R --mode quick` | Passed with `sf outcome: classified_skip`. |
| `rtk Rscript --vanilla tools/validate-pkgdown-site.R --mode release` | Passed with `sf outcome: classified_skip`; only `README.md` changed among tracked files after rebuild. |
| `rtk Rscript --vanilla -e 'testthat::test_file("tests/testthat/test-pkgdown-site.R")'` | Passed with 42 expectations. |
| `rtk Rscript --vanilla -e 'devtools::test(filter = "pkgdown-site")'` | Passed with 42 expectations. |
| `rtk Rscript --vanilla -e 'devtools::test()'` | Passed with 2151 expectations, 6 existing warnings, and 47 expected skips. |
| `rtk Rscript --vanilla -e 'devtools::build_readme()'` | Passed and regenerated `README.md`; reported existing out-of-date development dependencies `bslib` and `cpp11`. |

## Requirement Coverage

| Requirement | Status | Evidence |
|-------------|--------|----------|
| SITE-01 | Passed | `tools/validate-pkgdown-site.R` provides quick/release/ci modes; `tests/testthat/helper-pkgdown-site.R` holds reusable marker, asset, and sf outcome checks; `tests/testthat/test-pkgdown-site.R` keeps testthat canonical; `.github/workflows/pkgdown.yaml` runs `Rscript tools/validate-pkgdown-site.R --mode ci` after build and before deploy; `vignettes/d3-drawing-diagnostics.md` and `README.md` document run, interpretation, and repair paths. |

## Threat Mitigation

| Threat | Status | Mitigation Evidence |
|--------|--------|---------------------|
| T-57-01 | Mitigated | `tests/testthat/helper-pkgdown-site.R` centralizes generated-site validation and is reused by focused tests and the script. |
| T-57-02 | Mitigated | `tests/testthat/test-pkgdown-site.R` and quick/release validation require exact sf support text, htmlwidget markers, D3 dependency marker, module marker, and module asset path. |
| T-57-03 | Mitigated | `tools/validate-pkgdown-site.R` classifies local sf output as `classified_skip` and requires rendered sf only when `sf` and `geojsonsf` are loadable in release/CI mode. |
| T-57-04 | Mitigated | `.github/workflows/pkgdown.yaml` validates generated pkgdown output before the deploy step. |
| T-57-05 | Mitigated | `vignettes/d3-drawing-diagnostics.md` documents quick, release, CI, failure classes, `PKGDOWN_SF_OPTIONAL_SKIP`, repair flow, and the Phase 58 boundary for GitHub Pages artifact inspection. |

## Notes

- Local `sf` remains not loadable because of the known GDAL dylib issue, so local and release validation prove the classified skip path rather than rendered sf widget evidence.
- The CI/release command will require rendered sf evidence automatically when both `sf` and `geojsonsf` are loadable.
- GitHub Pages artifact download/inspection remains Phase 58 scope.
- Raw logs, browser visual smoke artifacts, package-check logs, and local temporary paths are intentionally excluded from this verification document.
