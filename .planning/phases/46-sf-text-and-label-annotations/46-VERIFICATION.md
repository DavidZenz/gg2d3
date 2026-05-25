# Phase 46 Verification

## Goal Achievement

Phase 46 added `geom_sf_text()` and `geom_sf_label()` support across the gg2d3 IR, D3 renderer, and interactivity contracts. The implementation uses `sf_text` and `sf_label` IR layers, preserves sf geometry diagnostics and panel-local `sf_bbox`, renders text/label marks from projected anchors, and reuses `.geom-sf` interaction plumbing.

## Requirements Coverage

| Requirement | Status | Evidence |
|-------------|--------|----------|
| SFANN-01 | Covered by tests; skipped locally because `sf` cannot load GDAL | `tests/testthat/test-sf-annotations-ir.R`, `tests/testthat/test-regression-core.R` |
| SFANN-02 | Covered | `tests/testthat/test-sf-annotations-renderer.R`, `tests/testthat/test-sf-annotations-ir.R` |
| SFANN-03 | Covered | `tests/testthat/test-sf-annotations-interactivity.R`, `tests/testthat/test-sf-annotations-browser.R` |

## Commands Run

```bash
rtk Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-sf-annotations-ir.R")'
```

Result: exit 0. The IR file skipped explicitly because `{sf}` cannot be loaded in the local environment.

```bash
rtk Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-sf-annotations-ir.R"); testthat::test_file("tests/testthat/test-regression-core.R")'
```

Result: exit 0. sf-specific tests skipped explicitly because `{sf}` cannot be loaded; non-sf regression tests passed.

```bash
node --check inst/htmlwidgets/modules/geoms/sf.js
```

Result: exit 0.

```bash
rtk Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-sf-annotations-renderer.R")'
```

Result: exit 0, 30 passing assertions.

```bash
rtk Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-sf-annotations-interactivity.R")'
```

Result: exit 0, 29 passing assertions.

```bash
rtk env NOT_CRAN=true Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-sf-annotations-browser.R")'
```

Result: exit 0. Browser smoke skipped explicitly because `{sf}` cannot be loaded.

```bash
rtk Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-sf-annotations-ir.R"); testthat::test_file("tests/testthat/test-sf-annotations-renderer.R"); testthat::test_file("tests/testthat/test-sf-annotations-interactivity.R")'
```

Result: exit 0. `test-sf-annotations-ir.R` skipped explicitly because `{sf}` cannot be loaded; renderer and interactivity source tests passed.

## Browser Smoke

`tests/testthat/test-sf-annotations-browser.R` is optional and CRAN-compatible. It calls `skip_browser_sf_smoke()` before constructing sf fixtures, so missing spatial packages, missing `chromote`, or unavailable Chrome/Chromium skip the browser DOM checks explicitly.

When dependencies are available, it checks polygon text, point label, line text, stacked annotations, faceted annotations, skipped unsupported rows, live `data-cx` / `data-cy` anchors, label box/text DOM structure, brush selection around an annotation anchor, and sanitized callback/tooltip/brush payloads.

## Residual Risks

- Local `sf` cannot load because the installed package references a missing GDAL dylib. This means sf-dependent IR and browser behavior was verified as explicit skips in this environment, not as live spatial assertions.
- Source tests verify renderer and interactivity contracts, but live browser validation depends on an environment with working `sf`, `geojsonsf`, `chromote`, and Chrome/Chromium.
- Exact ggplot2 label padding/radius parity and rotation parity are not implemented.

## Deferred Scope

- No screenshot or perceptual diffing was introduced.
- `ggrepel` collision avoidance remains deferred.
- Path-following labels remain deferred.
- Rich text, advanced rotation handling, tiled maps, JavaScript CRS reprojection, and new sf-specific interactivity APIs remain deferred.
- Broad README, roxygen, generated help, and vignette updates remain deferred to Phase 47.

