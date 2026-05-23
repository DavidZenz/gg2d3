# Phase 40 Dependency Audit

## Scan Commands

Executed during Phase 40 package hygiene:

```bash
rtk rg --no-filename -o "[A-Za-z][A-Za-z0-9.]*::" R tests vignettes README.Rmd -g "*.R" -g "*.Rmd" | sed 's/::$//' | sort -u
rtk rg -n "library\\(|requireNamespace\\(|skip_if_not_installed\\(" R tests vignettes README.Rmd -g "*.R" -g "*.Rmd"
rtk Rscript --vanilla -e 'd <- read.dcf("DESCRIPTION"); cat(d[1, "Imports"], "\n---SUGGESTS---\n", d[1, "Suggests"], "\n")'
```

## Direct Namespace Usage

The namespace scan found these direct `pkg::` references:

`V8`, `chromote`, `crosstalk`, `devtools`, `geojsonsf`, `gg2d3`, `ggplot2`, `grid`, `htmltools`, `htmlwidgets`, `jsonlite`, `knitr`, `pkgload`, `rlang`, `rmarkdown`, `rnaturalearth`, `rprojroot`, `scales`, `sf`, `testthat`, `tools`, and `utils`.

Additional direct dependency gates from `library()`, `requireNamespace()`, and `skip_if_not_installed()` include `maps` and `mgcv`.

Notable references:

- Runtime package code uses `ggplot2`, `htmlwidgets`, `jsonlite`, `grid`, and `rlang` unconditionally or as package internals.
- Runtime crosstalk support is guarded by `requireNamespace("crosstalk", quietly = TRUE)` before `crosstalk::` calls.
- Runtime sf conversion paths check for `sf` and `geojsonsf` and fail with explicit messages when absent.
- Tests and helpers directly use `chromote`, `testthat`, `pkgload`, `rprojroot`, `sf`, `geojsonsf`, `rnaturalearth`, `htmltools`, `V8`, `scales`, and `mgcv`.
- Vignettes and README generation directly use `knitr`, `rmarkdown`, `crosstalk`, `maps`, and `devtools` in chunks or documented development commands.

## DESCRIPTION Classification

Added to Imports:

- No new packages. Existing `ggplot2`, `htmlwidgets`, `jsonlite`, `grid`, and `rlang` remain the direct runtime Imports.

Added to Depends:

- `R (>= 4.1.0)` because package tests/source use the native pipe operator and `R CMD build` otherwise injects this dependency implicitly.

Added to Suggests:

- `devtools` for README and helper-driven development commands.
- `htmltools` for visual checks and vignette examples.
- `knitr` and `rmarkdown` for README/vignette rendering, with `VignetteBuilder: knitr`.
- `maps` for the optional vignette map example guarded by `requireNamespace("maps")`.
- `mgcv` for the optional smooth/stat test guarded by `skip_if_not_installed("mgcv")`.
- `scales` for tests that call `scales::trans_new()` and `scales::squish`.
- `V8` for JavaScript layout tests guarded by `skip_if_not_installed("V8")`.

Already declared in the expected class:

- Imports: `ggplot2`, `htmlwidgets`, `jsonlite`, `grid`, `rlang`.
- Suggests: `chromote`, `crosstalk`, `testthat`, `pkgload`, `rprojroot`, `sf`, `geojsonsf`, and `rnaturalearth`.

No action:

- `gg2d3` is the package itself and appears in README/vignettes/tests.
- `tools` and `utils` are base/recommended R packages and do not require DESCRIPTION dependency entries here.

Deferred:

- None for direct dependency declarations. Browser and visual infrastructure choices remain in later validation phases, with no Node browser stack added.

## Follow-up Decisions

- Keep `crosstalk` in `Suggests` because runtime code checks availability before using it and the package should still load without crosstalk installed.
- Keep `sf` and `geojsonsf` in `Suggests` because `geom_sf()` conversion paths produce explicit optional-dependency errors and tests skip when they are unavailable.
- Keep `chromote` in `Suggests` because live browser smoke validation is optional and CRAN-friendly skip behavior is required.
- Do not add Playwright, Puppeteer, Selenium, or any node browser stack to DESCRIPTION.
