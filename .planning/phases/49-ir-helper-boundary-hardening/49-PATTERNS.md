# Phase 49: IR Helper Boundary Hardening - Pattern Map

**Mapped:** 2026-05-26
**Status:** Complete

## PATTERN MAPPING COMPLETE

## Files To Modify

| File | Role | Closest Existing Pattern | Notes |
|------|------|--------------------------|-------|
| `R/as_d3_ir.R` | Orchestrator to shrink | `R/gg2d3.R` delegates to `as_d3_ir()`; `R/sf_utils.R` helpers are used from `as_d3_ir()` | Keep public `as_d3_ir()` signature unchanged. |
| `R/ir_scale_helpers.R` | New internal helpers | `R/ggplot2_compat.R` small internal wrappers | Helper names should start `gg2d3_ir_` to avoid public-sounding exports. |
| `R/ir_layer_helpers.R` | New internal helpers | `R/sf_utils.R` payload helpers | Return plain lists/data frames matching current IR. |
| `R/ir_facet_helpers.R` | New internal helpers | existing facet block in `R/as_d3_ir.R`; sf bbox helpers in `R/sf_utils.R` | Isolate panel metadata and reuse `attach_sf_panel_bboxes()`. |
| `tests/testthat/test-ir-helper-boundaries.R` | New characterization tests | `tests/testthat/test-sf-ir.R`, `tests/testthat/test-date-scales.R` | Test names should identify the helper boundary. |

## Existing Patterns To Reuse

### Compatibility Wrapper Pattern

`R/ggplot2_compat.R` wraps ggplot2 internals behind small functions:

```r
gg2d3_calc_element <- function(element_name, theme, default = NULL) {
  if (is.null(theme)) {
    return(default)
  }

  element <- tryCatch(
    ggplot2:::calc_element(element_name, theme),
    error = function(e) NULL
  )

  if (is.null(element)) default else element
}
```

New helpers should call wrappers like `gg2d3_panel_axis()` and `gg2d3_continuous_range()` instead of using private ggplot2 internals directly.

### Payload Helper Pattern

`R/sf_utils.R` returns structured payloads:

```r
sf_layer_ir_payload <- function(df, aes, params, var_names) {
  sf_prepared <- prepare_sf_geometry_ir(df)

  list(
    layer = list(...),
    coord_geometry = sf_prepared$geometry,
    panel_geometries = sf_panel_geometries(sf_prepared)
  )
}
```

Layer and facet helpers should follow this pattern: explicit inputs, plain-list output, no hidden mutation except where `as_d3_ir()` deliberately accumulates sf panel geometries.

### Test Pattern

Existing tests use small ggplot fixtures and direct IR assertions:

```r
p <- ggplot(mtcars, aes(wt, mpg)) + geom_point() + scale_x_log10()
ir <- as_d3_ir(p)
expect_equal(ir$scales$x$transform, "log10")
```

New boundary tests should use the same style, but with test names and helper assertions that identify scale, layer, or facet boundaries.

## Data Flow

```text
ggplot object
  -> ggplot2::ggplot_build()
  -> as_d3_ir() orchestration
     -> scale helpers
     -> layer helpers
        -> sf helper payloads where applicable
     -> facet/panel helpers
     -> validate_ir()
  -> htmlwidget renderer
```

## Landmines

- `ggplot_build()` output shape changes across ggplot2 versions. Keep compatibility access behind `R/ggplot2_compat.R`.
- Full IR snapshots may be brittle. Prefer structural assertions on stable fields.
- sf dependencies are optional. Tests must skip cleanly when `sf` or `geojsonsf` is unavailable.
- Date/POSIXct conversion currently happens in both layer data and scale/panel metadata. Extracting only one side can cause drift.
- `as_d3_ir()` uses accumulated sf coord/panel geometry state. Refactors must preserve stacked and faceted sf bbox behavior.

