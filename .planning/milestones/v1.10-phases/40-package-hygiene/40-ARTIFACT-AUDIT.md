# Phase 40 Artifact Audit

## Generated Paths

Scan command:

```bash
rtk rg -n "test_output|saveWidget|save_html|writeLines|Rcheck|browser_sf_artifact_dir|\\.test_output_dir" tests R vignettes README.Rmd .gitignore .Rbuildignore
```

Generated local output patterns found:

- `test_output/` in `.gitignore` and visual-check scripts.
- `test_output/browser-sf/` through `browser_sf_artifact_dir()` and sf browser fixture helpers.
- `test_*_files/` from htmlwidgets non-self-contained output directories.
- Root-level `*.html`, `*.png`, and `*.pdf` debug/visual artifacts.
- `*.Rcheck/` from local `R CMD check` runs.
- Browser fixture pages and logs written by `tests/testthat/helper-browser-sf.R` under `test_output/browser-sf/`.

The only ad hoc relative path outside the shared helper convention was `../../test_output` in `tests/testthat/test-date-scales.R`.

## Ignore Coverage

`.gitignore` already covered:

- `test_output/`
- `test_*_files/`
- `*.Rcheck/`
- Root-level `/*.html`
- Root-level `/*.png`

`.gitignore` did not cover root-level `/*.pdf`, so that pattern was added.

## Build Ignore Coverage

`.Rbuildignore` did not exclude local generated output roots before Phase 40. Added package-build exclusions for:

- `^test_output$`
- `^test_output/`
- `^(.*/)?test_output($|/)`
- `^test_.*_files$`
- `^(.*/)?test_.*_files($|/)`
- `^.*\\.Rcheck$`
- `^[^/]+\\.html$`
- `^[^/]+\\.png$`
- `^[^/]+\\.pdf$`
- `^AGENTS\\.md$`
- `^(.*/)?CLAUDE\\.md$`
- `^\\.claude($|/)`
- `^\\.planning($|/)`

The root-level HTML/PNG/PDF patterns avoid excluding nested installed package assets.

## Required Changes

Changed files:

- `.gitignore` - added root-level `/*.pdf`.
- `.Rbuildignore` - added local generated output exclusions, including nested `test_output/` and `test_*_files/` directories that can exist under `tests/testthat/`.
- `.Rbuildignore` - added local planning/agent guidance exclusions so source package builds do not include `.planning/`, `.claude/`, `AGENTS.md`, or `CLAUDE.md` files.
- `tests/testthat/test-date-scales.R` - replaced `../../test_output` with `.date_scale_test_output_dir()`, reusing `.test_output_dir()` when available and otherwise resolving the package root before writing `test_output/visual_test_date_scales.html`.

## Verification Evidence

Commands run after the changes:

```bash
rtk Rscript --vanilla -e 'parse("tests/testthat/test-date-scales.R"); cat("date scale test parse ok\n")'
rtk rg -n "test_output/" .gitignore
rtk rg -n "\\^test_output|Rcheck" .Rbuildignore
rtk rg -n "\\.\\./\\.\\./test_output" tests/testthat/test-date-scales.R
rtk git check-ignore test_output/browser-sf/phase40-artifact-smoke.html
rtk git check-ignore test_output/browser-sf/phase40-artifact-smoke-page-errors.log
rtk Rscript --vanilla -e 'devtools::load_all(quiet = TRUE); testthat::test_file("tests/testthat/test-date-scales.R")'
cd /private/tmp && rtk R CMD build --no-build-vignettes --no-manual /Users/davidzenz/R/gg2d3
tar -tzf /private/tmp/gg2d3_0.0.0.9000.tar.gz | rg "\\.planning|\\.claude|AGENTS\\.md|CLAUDE\\.md|test_output|Rcheck"
```

Outcomes:

- Date scale test source parsed successfully.
- `.gitignore` and `.Rbuildignore` contain the expected generated-output rules.
- No `../../test_output` references remain in `tests/testthat/test-date-scales.R`.
- `test_output/browser-sf/phase40-artifact-smoke.html` is ignored.
- `test_output/browser-sf/phase40-artifact-smoke-page-errors.log` is ignored.
- `tests/testthat/test-date-scales.R` passed with 43 assertions and 1 expected visual-test skip.
- Source package build from `/private/tmp` completed; tarball inspection returned no `.planning`, `.claude`, `AGENTS.md`, `CLAUDE.md`, `test_output`, or `Rcheck` paths.
