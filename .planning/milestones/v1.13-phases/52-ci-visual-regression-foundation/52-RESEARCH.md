# Phase 52: CI Visual Regression Foundation - Research

**Researched:** 2026-05-27
**Status:** Complete

## Research Goal

Plan how to turn Phase 48's local, opt-in browser visual smoke harness into a CI-safe regression gate without introducing pixel thresholds, committed golden screenshots, or a new browser stack.

## Source Findings

### Existing Harness

- `tests/testthat/helper-browser-visual.R` already owns deterministic paths under `test_output/browser-visual-smoke/`, sanitized fixture ids, HTML/PNG/DOM/browser-log artifact paths, chromote launch probing, static DOM summary JS, screenshot capture, browser error collection, and index writing.
- `tests/testthat/test-browser-visual-smoke.R` already owns the representative fixture matrix and stable minimum-count selector checks through each fixture's `expected` map.
- `vignettes/d3-drawing-diagnostics.md` already documents the quick skip-friendly command and full opt-in command, artifact shapes, fixture categories, and skip semantics.
- `.gitignore` and `.Rbuildignore` already exclude `test_output/`, so CI artifacts can reuse the existing output root without changing package/source boundaries.

### CI Shape

- Existing `.github/workflows/pkgdown.yaml` is site publishing. Phase 52 should add a dedicated workflow rather than mixing visual smoke into publishing.
- The dedicated workflow should run on `pull_request` and `workflow_dispatch`, set `NOT_CRAN=true`, `GG2D3_BROWSER_VISUAL_SMOKE=true`, and a new explicit CI-mode env var such as `GG2D3_BROWSER_VISUAL_CI=true`.
- The existing helper currently uses `testthat::skip_*` paths for browser/chromote failures. That is correct locally but not enough for CI, because skips can let the dedicated gate pass without proving the browser path works. A CI-mode helper should fail on browser-level unavailable conditions while preserving ordinary local skips.
- Optional spatial fixture skips are different from browser-level skips. Phase 52 decisions allow explicit `sf`/`geojsonsf` row skips when dependency setup is not reasonable, so row/report validation should distinguish browser gate failures from explicit spatial row skips.

### Report and Metadata

- `write_browser_visual_index()` currently writes `generated_at`, `artifact_dir`, and `rows`. It should accept/report metadata including CI flag, GitHub event, SHA, run id, runner OS, browser path/version when available, and relevant env flags.
- A small row validator will make CI failures more actionable than relying on scattered assertions. It should verify stable row fields, statuses, artifact paths for passed/failed rows, skip/failure reasons where applicable, and no silent empty rows.
- Screenshots should remain inspection evidence. Phase 52 should not add pixel comparison or committed image baselines.

### GitHub Actions Notes

- The current repo already uses `actions/checkout@v6` and `r-lib/actions/setup-r@v2` / `setup-r-dependencies@v2`; the new workflow should stay close to that style.
- The official `r-lib/actions` README says the current R actions are used through the `v2` tag, including `setup-r` and `setup-r-dependencies` ([r-lib/actions](https://github.com/r-lib/actions)).
- The official `actions/upload-artifact` action supports uploading paths from the workspace and exposes retention/overwrite/no-files behavior; use it to upload `test_output/browser-visual-smoke/` on every run ([actions/upload-artifact](https://github.com/actions/upload-artifact)).

## Validation Architecture

### Test Layers

1. **Default skip path:** Run `Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-browser-visual-smoke.R")'` without opt-in. It should pass by skipping at the opt-in gate.
2. **Source/helper assertions:** Source `helper-browser-visual.R` and verify new helper functions, metadata fields, report validation behavior, and no forbidden browser stack/pixel-diff strings.
3. **CI-equivalent browser path:** Run `NOT_CRAN=true GG2D3_BROWSER_VISUAL_SMOKE=true GG2D3_BROWSER_VISUAL_CI=true Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-browser-visual-smoke.R")'` when Chrome/chromote are available. In a browser-limited sandbox, this may fail by design and should be recorded as a CI-mode browser requirement.
4. **Workflow source validation:** Check `.github/workflows/browser-visual-smoke.yaml` for `pull_request`, `workflow_dispatch`, opt-in env vars, `actions/upload-artifact`, and the full artifact directory path.
5. **Docs validation:** Check `vignettes/d3-drawing-diagnostics.md` for CI command, artifact inspection guidance, `CHROMOTE_CHROME` troubleshooting, and the explicit pixel-threshold deferral.

### Risks to Guard

- CI workflow passes because browser unavailable became a skip rather than a failure.
- Spatial dependency skips accidentally mask non-sf fixture failures.
- Report rows omit artifact links or reasons, making CI failures hard to inspect.
- Workflow uploads only partial artifacts or uploads from a second output root.
- Docs imply screenshot/pixel regression support before it exists.

## Planning Recommendation

Create three plans:

1. **Report Contract And CI Mode:** Add CI metadata, report row validation, and CI-mode browser fail behavior to the helper/test contract.
2. **Dedicated GitHub Actions Workflow:** Add a separate workflow that runs the full visual smoke command and uploads `test_output/browser-visual-smoke/` on every run.
3. **Docs And Final Validation:** Document CI/local inspection, `CHROMOTE_CHROME` troubleshooting, and run final source/workflow coverage checks.

## RESEARCH COMPLETE
