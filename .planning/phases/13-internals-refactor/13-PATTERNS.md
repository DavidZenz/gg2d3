# Phase 13: Internals Refactor - Pattern Map

**Mapped:** 2026-05-02
**Files analyzed:** 14 (7 new R sources, 5 new test files, 1 modified R source, 1 modified `NAMESPACE`/docs side-effect)
**Analogs found:** 14 / 14 (refactor: every new file's analog is a slice of the file being decomposed)

## Scope Note (refactor-only)

This is a structural refactor: code is **moved**, not invented. The closest analog for every new `R/ir_*.R` file is the corresponding line range of `R/as_d3_ir.R` (1,151 lines). The closest analog for every new `tests/testthat/test-ir-*.R` file is `tests/testthat/test-ir.R`. The "patterns" below are the concrete excerpts each new file should lift, plus the shared style conventions enforced across all `R/*.R` files in this package (file-per-concern, roxygen header, `%||%` idiom, `tryCatch` fallback wrapping, `library(ggplot2)` inside each test).

Per CONTEXT D-04 + RESEARCH Anti-Pattern: new helpers use `#' @keywords internal` + `#' @noRd` (NOT `@export`). Only `as_d3_ir()` keeps its existing `@export`.

## File Classification

| New / Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `R/ir_utils.R` (new) | utility | transform | `R/as_d3_ir.R` lines 18, 215–236, 469–472 (`%||%`, `to_rows`, `dom`) | exact (lift) |
| `R/ir_theme.R` (new) | extractor + fallback helper | transform | `R/as_d3_ir.R` lines 73–141, 535–571, 819–856 + new `calc_element_safe` | exact (lift + new wrapper) |
| `R/ir_scales.R` (new) | extractor | transform | `R/as_d3_ir.R` lines 49–71, 263–278, 289–464, 488–533 | exact (lift) |
| `R/ir_layers.R` (new) | extractor | transform | `R/as_d3_ir.R` lines 143–286 | exact (lift) |
| `R/ir_legends.R` (new) | extractor | transform | `R/as_d3_ir.R` lines 616–817 | exact (lift) |
| `R/ir_facets.R` (new) | extractor | transform | `R/as_d3_ir.R` lines 863–1126 | exact (lift, `<<-` removed) |
| `R/zzz.R` (new, optional) | config (pkgenv state) | n/a | none — new file for `.gg2d3_pkgenv` warn-once flag | new |
| `R/as_d3_ir.R` (modified) | orchestrator | request-response (R → IR) | itself, post-extraction (≤200 lines target) | self |
| `tests/testthat/test-ir-scales.R` (new) | test | unit | `tests/testthat/test-ir.R` lines 1–110 | exact |
| `tests/testthat/test-ir-theme.R` (new) | test | unit | `tests/testthat/test-ir.R` + `tests/testthat/test-validate-ir.R` lines 1–26 | exact + warn-once additions |
| `tests/testthat/test-ir-layers.R` (new) | test | unit | `tests/testthat/test-ir.R` | exact |
| `tests/testthat/test-ir-legends.R` (new) | test | unit | `tests/testthat/test-legends.R` | exact |
| `tests/testthat/test-ir-facets.R` (new) | test | unit | `tests/testthat/test-facets.R` lines 1–50 | exact |
| `NAMESPACE` / `man/*.Rd` (regenerated) | doc artifact | n/a | existing — `devtools::document()` regenerates | exact (no new exports) |

## Pattern Assignments

### `R/ir_utils.R` (utility, transform)

**Analog:** `R/as_d3_ir.R` lines 18, 215–236, 469–472. The outer `to_rows` at line 27 is dead code (RESEARCH Pitfall 3, `[VERIFIED]`); use the inner version (line 215) only.

**File header pattern (copy from any `R/d3_*.R`):** plain comment header is fine for an internal-only file. No roxygen at file scope.

**`%||%` excerpt** (`R/as_d3_ir.R:18`):
```r
`%||%` <- function(x, y) if (is.null(x)) y else x
```
Lift to `R/ir_utils.R` at top level (not as a closure).

**`to_rows` excerpt** (`R/as_d3_ir.R:215-236`, the inner version that handles `PANEL` and list-cols):
```r
to_rows <- function(df, keep_aes) {
  if (is.null(df) || !nrow(df)) return(list())
  df <- df[, intersect(keep_aes, names(df)), drop = FALSE]
  col_names <- names(df)
  df[] <- lapply(col_names, function(colname) {
    col <- df[[colname]]
    if (colname == "PANEL") as.integer(col)
    else if (is.factor(col)) as.character(col)
    else if (inherits(col, c("POSIXct","POSIXt"))) as.numeric(col) * 1000
    else if (inherits(col, "Date")) as.numeric(col) * 86400000
    else if (is.list(col)) I(col)
    else col
  })
  names(df) <- col_names
  rows <- vector("list", nrow(df))
  for (ii in seq_len(nrow(df))) {
    r <- lapply(df[ii, , drop = FALSE], function(v) v[[1]])
    names(r) <- names(df)
    rows[[ii]] <- r
  }
  rows
}
```
**Key change vs original:** `keep_aes` is now an **explicit argument**, not a captured closure variable (RESEARCH Pitfall 1). Caller passes the desired vector.

**`dom` excerpt** (`R/as_d3_ir.R:469-472`):
```r
dom <- function(v) {
  if (is.null(v) || length(v) == 0) return(numeric(0))
  if (is.numeric(v)) range(v, finite = TRUE) else unique(v)
}
```

**Roxygen pattern for every helper in this file:**
```r
#' @keywords internal
#' @noRd
```

---

### `R/ir_theme.R` (extractor + `calc_element_safe`, transform)

**Analog:** `R/as_d3_ir.R:73-141` (`extract_theme_element`), `R/as_d3_ir.R:535-571` (theme assembly), `R/as_d3_ir.R:819-856` (legend + strip theme). Plus the **new** `calc_element_safe` helper, which has no analog — it's the central change for REFACTOR-02.

**Imports pattern:** None for R packages — use namespaced calls (`ggplot2::`, `grid::convertUnit`) like the current code does.

**Lift: `extract_theme_element` core dispatch** (`R/as_d3_ir.R:74-141`) — the only edit is replacing the line-75 private call:
```r
# BEFORE (R/as_d3_ir.R:75):
calc <- ggplot2:::calc_element(element_name, theme)

# AFTER (in R/ir_theme.R):
calc <- calc_element_safe(element_name, theme)
```
The rest of the function (element_blank / element_rect / element_line / element_text / margin branches at lines 81–140) lifts verbatim. Linewidth conversion `* 3.7795275591` stays as-is (note: MEMORY.md flags this constant for `element_line`/`element_rect`; do NOT change in this phase).

**Lift: theme assembly** (`R/as_d3_ir.R:535-571` + 819–856). Wrap in `extract_theme_ir(b)`:
```r
#' @keywords internal
#' @noRd
extract_theme_ir <- function(b) {
  if (is.null(b$plot$theme)) return(NULL)
  theme_ir <- list(
    panel = list(
      background = extract_theme_element("panel.background", b$plot$theme),
      border     = extract_theme_element("panel.border",     b$plot$theme)
    ),
    plot = list(
      background = extract_theme_element("plot.background", b$plot$theme),
      margin     = extract_theme_element("plot.margin",     b$plot$theme)
    ),
    grid = list(
      major = extract_theme_element("panel.grid.major", b$plot$theme),
      minor = extract_theme_element("panel.grid.minor", b$plot$theme)
    ),
    axis = list(
      line    = extract_theme_element("axis.line",    b$plot$theme),
      line.x  = extract_theme_element("axis.line.x",  b$plot$theme),
      line.y  = extract_theme_element("axis.line.y",  b$plot$theme),
      text    = extract_theme_element("axis.text",    b$plot$theme),
      text.x  = extract_theme_element("axis.text.x",  b$plot$theme),
      text.y  = extract_theme_element("axis.text.y",  b$plot$theme),
      title   = extract_theme_element("axis.title",   b$plot$theme),
      title.x = extract_theme_element("axis.title.x", b$plot$theme)
      # ... continue verbatim from R/as_d3_ir.R:559-571
    )
    # ... text / legend / strip blocks lifted from 819-856
  )
  theme_ir
}
```
Internal helpers like `.extract_legend_key_size` (currently lines 822–833 inline `tryCatch`) become small private helpers in this file.

**NEW: `calc_element_safe` pattern.** No analog in current code. Pattern source: RESEARCH §"Pattern 2" (the canonical sketch) and CONTEXT D-05 through D-08. The shape:
```r
#' @keywords internal
#' @noRd
calc_element_safe <- function(element_name, theme) {
  # Tier 1: existing private path (preserves v1.0 behavior exactly)
  result <- tryCatch(
    ggplot2:::calc_element(element_name, theme),
    error = function(e) e
  )
  if (!inherits(result, "error")) return(result)

  # Tier 2: public exported API
  result <- tryCatch({
    complete <- ggplot2::theme_get() + theme
    ggplot2::calc_element(element_name, complete)
  }, error = function(e) e)
  if (!inherits(result, "error")) {
    .gg2d3_warn_once(element_name, "public-API path")
    return(result)
  }

  # Tier 3: static default
  default <- .gg2d3_calc_element_default(element_name)
  .gg2d3_warn_once(element_name, "static default")
  default
}
```
[VERIFIED in RESEARCH: `ggplot2::calc_element` is exported in 4.0.3.]

**NEW: warn-once + static-default helpers.** Sketch (per CONTEXT specifics: `.gg2d3_pkgenv$calc_element_warned`):
```r
.gg2d3_warn_once <- function(element_name, path) {
  if (isTRUE(.gg2d3_pkgenv$calc_element_warned)) return(invisible())
  .gg2d3_pkgenv$calc_element_warned <- TRUE
  warning(sprintf(
    "gg2d3: ggplot2:::calc_element() failed for '%s'; using %s. ggplot2 version: %s. Further occurrences this session will be silent.",
    element_name, path, as.character(utils::packageVersion("ggplot2"))
  ), call. = FALSE)
}

.gg2d3_calc_element_default <- function(element_name) {
  switch(element_name,
    legend.position = "right",
    legend.key.size = grid::unit(1.2, "lines"),
    panel.spacing  = grid::unit(5.5, "pt"),
    NULL
  )
}
```

**Replace all 5 sites** — the orchestrator's existing inline `tryCatch({ complete_theme <- ggplot2::theme_get() + b$plot$theme; ggplot2:::calc_element(...) }, ...)` patterns (`R/as_d3_ir.R:617-621, 823-833, 940-949, 1059-1068`, plus the call at L75 inside `extract_theme_element`) all collapse to one-line `calc_element_safe("name", b$plot$theme)` calls. The unit-to-pixel conversion (`grid::convertUnit(...) * 96`) stays inline at the call site that needs pixels.

---

### `R/zzz.R` (new, optional — pkgenv state)

**Analog:** standard R-package `zzz.R` convention; no current analog in this codebase (gg2d3 has no `zzz.R` today). Could equally live at the top of `R/ir_theme.R` (CONTEXT specifics says "package-internal flag e.g. `.gg2d3_pkgenv`"). Planner's call where this lives.

**Pattern:**
```r
.gg2d3_pkgenv <- new.env(parent = emptyenv())
.gg2d3_pkgenv$calc_element_warned <- FALSE

# Test-only reset hook (RESEARCH Open Question 3)
#' @keywords internal
#' @noRd
.gg2d3_reset_calc_element_warned <- function() {
  .gg2d3_pkgenv$calc_element_warned <- FALSE
  invisible(NULL)
}
```

---

### `R/ir_scales.R` (extractor, transform)

**Analog:** `R/as_d3_ir.R:49-71` (`map_discrete`), `R/as_d3_ir.R:289-464` (`validate_log_domain`, `get_scale_transform`, `get_scale_info`), `R/as_d3_ir.R:488-533` (breaks + scales-list assembly), `R/as_d3_ir.R:466-472` (color domain — `dom` is in `ir_utils.R` but `allc` lives here).

**Lift: `validate_log_domain`** (`R/as_d3_ir.R:289-311`) — verbatim, top-level function, `#' @keywords internal @noRd`.

**Lift: `get_scale_transform`** (`R/as_d3_ir.R:314-348`) — verbatim.

**Lift: `get_scale_info`** (`R/as_d3_ir.R:351-464`) — verbatim, including the fragile `tryCatch` block at 416–451 that walks `scale_obj$labels` closure environments. **DO NOT CLEAN UP** that `tryCatch` (RESEARCH Pitfall 4); add a `# Compensates for ggplot2 lacking a public field for date_labels / timezone` comment.

**Lift: `map_discrete`** (`R/as_d3_ir.R:53-71`) — verbatim. Already takes `scale_obj` as an explicit arg, so no closure rewrite needed.

**Top-level entry point — assemble per RESEARCH §"Pattern 1":**
```r
#' @keywords internal
#' @noRd
extract_scales_ir <- function(b, pp_x, pp_y, is_flip = FALSE) {
  xscale_obj <- b$layout$panel_scales_x[[1]]
  yscale_obj <- b$layout$panel_scales_y[[1]]

  # Breaks block — lifted from R/as_d3_ir.R:488-516 verbatim
  x_breaks <- pp_x$breaks; y_breaks <- pp_y$breaks
  x_breaks <- x_breaks[!is.na(x_breaks)]; y_breaks <- y_breaks[!is.na(y_breaks)]
  # ... temporal *86400000 / *1000 conversions, verbatim ...

  scales <- list(
    x = c(get_scale_info(xscale_obj, pp_x, "x"), list(breaks = unname(x_breaks), ...)),
    y = c(get_scale_info(yscale_obj, pp_y, "y"), list(breaks = unname(y_breaks), ...))
  )

  # Color scale — lifted from R/as_d3_ir.R:466-472, 528-533
  allc <- unlist(lapply(b$data, function(df) if ("colour" %in% names(df)) df$colour))
  if (length(allc)) {
    scales$color <- list(
      type = if (is.numeric(allc)) "continuous" else "categorical",
      domain = unname(dom(allc))
    )
  }
  scales
}
```

**Critical:** temporal `* 86400000` / `* 1000` conversions appear in scales (487–516), layers (269–278), and facets (905–928, 1034–1047). RESEARCH Anti-Pattern says all three must continue to apply consistently in their current places. Do not consolidate.

---

### `R/ir_layers.R` (extractor, transform)

**Analog:** `R/as_d3_ir.R:143-286` (the `layers <- lapply(seq_along(b$data), ...)` block).

**Lift signature:**
```r
#' @keywords internal
#' @noRd
extract_layers_ir <- function(b, xscale_obj, yscale_obj) {
  lapply(seq_along(b$data), function(i) {
    df <- b$data[[i]]
    # map_discrete calls — lifted verbatim from R/as_d3_ir.R:147-188
    if ("x" %in% names(df) && !all(is.na(df$x))) df$x <- map_discrete(df$x, xscale_obj)
    # ... rest of mapping block ...

    # geom-name dispatch — lifted from R/as_d3_ir.R:190-201 (the existing block)
    # keep_aes vector lifted from 203-212
    # to_rows(df, keep_aes) called explicitly with keep_aes arg
    # temporal conversion 263-278 lifted verbatim
    list(geom = gname, data = to_rows(df, keep_aes), aes = aes,
         params = b$plot$layers[[i]]$aes_params)
  })
}
```

**Critical change vs original:** `to_rows` is no longer a local closure — it's imported from `ir_utils.R`, and `keep_aes` is passed explicitly (RESEARCH Pitfall 1).

---

### `R/ir_legends.R` (extractor, transform)

**Analog:** `R/as_d3_ir.R:616-817` (legend_position detection + guides_ir construction + merge logic).

**Lift signature:**
```r
#' @keywords internal
#' @noRd
extract_legends_ir <- function(b, p) {  # `p` needed for ggplot2::get_guide_data(p, ...)
  legend_position <- tryCatch(
    if (is.character(pos <- calc_element_safe("legend.position", b$plot$theme))) pos else "right",
    error = function(e) "right"
  )

  guides_ir <- list()
  if (legend_position != "none") {
    # entire block lifted from R/as_d3_ir.R:632-817 verbatim
    # including the merge-by-title pass at 760-816
  }

  list(position = legend_position, guides = guides_ir)
}
```
Critical: `ggplot2::get_guide_data(p, aesthetic = aes_name)` (line 667) is the public API; keep using it (RESEARCH "Don't Hand-Roll" table).

---

### `R/ir_facets.R` (extractor, transform)

**Analog:** `R/as_d3_ir.R:863-1126` (the `tryCatch`-wrapped facet wrap/grid/null branches).

**Lift with critical structural change:** The current code uses `<<-` to escape `tryCatch`'s error handler (`R/as_d3_ir.R:1109-1126`). When this becomes its own function, `<<-` reaches the global env (RESEARCH Pitfall 2). Replace with explicit return:

```r
#' @keywords internal
#' @noRd
extract_facets_ir <- function(b, pp_x, pp_y, scales,
                              x_breaks, y_breaks,
                              x_trans_name, y_trans_name,
                              is_flip = FALSE) {
  fallback <- list(
    facets = list(
      type = "null", vars = list(), nrow = 1L, ncol = 1L,
      layout = list(list(PANEL = 1L, ROW = 1L, COL = 1L, SCALE_X = 1L, SCALE_Y = 1L)),
      strips = list()
    ),
    panels = list(list(
      PANEL = 1L,
      x_range = unname(scales$x$domain), y_range = unname(scales$y$domain),
      x_breaks = unname(x_breaks),       y_breaks = unname(y_breaks)
    ))
  )

  tryCatch({
    is_facet_wrap <- inherits(b$layout$facet, "FacetWrap")
    is_facet_grid <- inherits(b$layout$facet, "FacetGrid")

    if (is_facet_wrap) {
      # ... lifted verbatim from R/as_d3_ir.R:871-969 ...
      # panel.spacing call site at 940-949 becomes:
      panel_spacing <- tryCatch({
        spacing <- calc_element_safe("panel.spacing", b$plot$theme)
        if (!is.null(spacing)) grid::convertUnit(spacing, "inches", valueOnly = TRUE) * 96
        else 7.3
      }, error = function(e) 7.3)
      list(facets = facets_ir, panels = panels_ir)
    } else if (is_facet_grid) {
      # ... lifted verbatim from R/as_d3_ir.R:970-1090 ...
      list(facets = facets_ir, panels = panels_ir)
    } else {
      # null-facet branch lifted from R/as_d3_ir.R:1091-1107
      fallback
    }
  }, error = function(e) fallback)
}
```
Orchestrator destructures `fp <- extract_facets_ir(...); ir$facets <- fp$facets; ir$panels <- fp$panels`.

---

### `R/as_d3_ir.R` (modified — orchestrator, ≤200 lines)

**Analog:** itself, refactored. Sketch in RESEARCH §"Top-level orchestrator after refactor (sketch)" (~50 lines).

**Keeps verbatim:**
- `#' @export` roxygen header (line 1) — public API contract.
- Function signature `as_d3_ir <- function(p, width = 640, height = 400, padding = list(...))` (lines 3-4) — MUST NOT change per CONTEXT canonical refs.
- `stopifnot(inherits(p, "ggplot"))` + `b <- ggplot2::ggplot_build(p)` (lines 5-6).
- `CoordTrans` warning (lines 9-16) — kept in orchestrator.
- `validate_ir(ir)` call as last line (line 1150).

**Removes:** All inline closures (lines 18, 27, 53, 74, 215, 289, 314, 351, 469). All extractor blocks.

**Adds:** Calls to the 5 new `extract_*_ir()` functions, plus `coord` detection (lines 474–486), plus the small inline `tickLabels` / `secondary axis` helpers at 593–614 (these are tiny enough to stay inline OR move to `ir_utils.R` — planner's call).

**Line-count gate:** `wc -l R/as_d3_ir.R` should report ≤200 (REFACTOR-01 success criterion, CONTEXT D-03).

---

### Test files (`tests/testthat/test-ir-*.R`)

**Analog:** `tests/testthat/test-ir.R` (existing, 262 lines). All five new test files mirror its style.

**Imports pattern** (`tests/testthat/test-ir.R:1-3`):
```r
test_that("descriptive name of behavior", {
  library(ggplot2)
  p <- ggplot(mtcars, aes(wt, mpg)) + geom_point()
  ir <- as_d3_ir(p)
  expect_true(length(ir$layers) >= 1)
  ...
})
```
Pattern conventions (per `.planning/codebase/TESTING.md` + verified in test-ir.R):
- `library(ggplot2)` **inside each `test_that` block**, not at file top.
- No mocking. Real `ggplot_build()`. Built-in datasets (`mtcars`, `iris`, etc.).
- Descriptive `test_that` names ("continuous scale extracts domain from panel_params").
- `expect_equal` for exact, `expect_true` with comparison ops for ranges, `expect_null` for absent fields.

**Per-extractor unit pattern** (RESEARCH §"Pattern 3"):
```r
test_that("extract_scales_ir extracts continuous x domain from panel_params", {
  library(ggplot2)
  p <- ggplot(mtcars, aes(wt, mpg)) + geom_point()
  b <- ggplot_build(p)
  pp_x <- b$layout$panel_params[[1]]$x
  pp_y <- b$layout$panel_params[[1]]$y
  scales <- extract_scales_ir(b, pp_x, pp_y, is_flip = FALSE)
  expect_equal(scales$x$type, "continuous")
  expect_true(scales$x$domain[1] <= min(mtcars$wt))
})
```

**`test-ir-theme.R` adds warn-once tests** (REFACTOR-02 verification, CONTEXT D-07):
```r
test_that("calc_element_safe falls back to public API on private failure", {
  .gg2d3_reset_calc_element_warned()
  # construct theme that breaks the private path, or stub via with_mocked_bindings
  expect_warning(
    calc_element_safe("legend.position", broken_theme),
    "ggplot2:::calc_element\\(\\) failed.*public-API path"
  )
})

test_that("calc_element_safe warns at most once per session", {
  .gg2d3_reset_calc_element_warned()
  expect_warning(calc_element_safe("legend.position", broken_theme))
  expect_silent(calc_element_safe("legend.position", broken_theme))
})
```

**`test-ir-facets.R` analog also pulls from `tests/testthat/test-facets.R`** (existing — facet IR shape assertions at lines 4–50).

---

### `NAMESPACE` / `man/*.Rd`

**Analog:** existing — `devtools::document()` regenerates from roxygen. Per RESEARCH Runtime State Inventory + CONTEXT Anti-Pattern: **zero new exports** should appear. All new helpers use `#' @keywords internal @noRd`. Run `devtools::document()` after refactor; `git diff NAMESPACE` should be empty.

Verification (RESEARCH §"Phase Requirements → Test Map"):
```bash
grep -rn 'ggplot2:::calc_element' R/
# After refactor: should match only the body of calc_element_safe in R/ir_theme.R
```

## Shared Patterns

### Pattern A: File-per-concern in flat `R/`
**Source:** `R/d3_brush.R`, `R/d3_hover.R`, `R/d3_tooltip.R`, `R/d3_zoom.R`, `R/d3_crosstalk.R` (existing interactivity API). Each is a single-purpose 40–85 line file at `R/` root.
**Apply to:** All new `R/ir_*.R` files. Do NOT create subdirectories (CONTEXT D-01 — R CMD check rejects `R/ir/`).

### Pattern B: Roxygen header for internal helpers
**Source:** `R/validate_ir.R:1-10` is the closest existing roxygen pattern (note that one is `@export` — internal helpers omit `@export`).
**Apply to:** Every function in every new `R/ir_*.R` file.
```r
#' @keywords internal
#' @noRd
```
For the package-public function being preserved (`as_d3_ir`), keep the existing header at `R/as_d3_ir.R:1-2`:
```r
#' Build a D3-ready IR (intermediate representation) from a ggplot
#' @export
```

### Pattern C: `tryCatch` with documented fallback
**Source:** `R/as_d3_ir.R:417-429` (date_labels closure walk), `R/as_d3_ir.R:606-614` (secondary axis detection), `R/as_d3_ir.R:617-621` (legend_position).
**Apply to:** Every site that probes ggplot2 internals. Do not strip these wrappers when lifting.
```r
result <- tryCatch({ ... fragile probe ... }, error = function(e) safe_default)
```
The new `calc_element_safe` is itself this pattern, formalized.

### Pattern D: Namespaced ggplot2 calls
**Source:** Throughout `R/as_d3_ir.R` — uses `ggplot2::ggplot_build`, `ggplot2::theme_get`, `ggplot2::get_guide_data`. Private calls use `ggplot2:::calc_element`.
**Apply to:** All extractors. Add new public path `ggplot2::calc_element` (verified exported).

### Pattern E: Pure-function-of-build extractor signature
**Source:** No analog — the current code accumulates in scope. RESEARCH §"Pattern 1" defines the new contract.
**Apply to:** All five `extract_*_ir(b, ...)` functions. Pass precomputed scalars (`pp_x`, `pp_y`, `xscale_obj`, `yscale_obj`, `x_trans_name`, `y_trans_name`, `is_flip`, `scales`, `x_breaks`, `y_breaks`) as explicit args. No `<<-`, no closures over orchestrator-scope variables.

### Pattern F: testthat 3.0 test style
**Source:** `tests/testthat/test-ir.R:1-9`, `tests/testthat/test-facets.R:4-15`, `tests/testthat/test-validate-ir.R:17-26`.
**Apply to:** All new `test-ir-*.R` files.
- One concern per `test_that` block.
- `library(ggplot2)` inside each block.
- Built-in datasets only (no fixtures, per RESEARCH Wave 0 Gaps).
- `expect_equal` / `expect_true` / `expect_null` / `expect_silent` / `expect_error` / `expect_warning`.

### Pattern G: IR shape contract via `validate_ir`
**Source:** `R/validate_ir.R` (172 lines, untouched).
**Apply to:** Orchestrator's last line stays `validate_ir(ir)`. Refactored extractors are correct iff their assembled IR still passes this validator. Use it as a regression fixture in full-pipeline tests (RESEARCH §Test Map: REFACTOR-01 full-pipeline row).

## No Analog Found

| File | Role | Reason |
|---|---|---|
| `calc_element_safe` body in `R/ir_theme.R` | fallback helper | New code — no current analog. Pattern from RESEARCH §"Pattern 2" (which is itself sourced from CONTEXT D-05 to D-08). |
| `.gg2d3_pkgenv` warn-once state | config | New code — gg2d3 has no `zzz.R` or `pkgenv` today. Standard R-package pattern but not previously used here. |
| `.gg2d3_reset_calc_element_warned` test hook | utility | New code — exists only to support `test-ir-theme.R` warn-once test (RESEARCH Open Question 3). |
| Static-default lookup (`.gg2d3_calc_element_default`) | utility | New code — small `switch` with three known-element defaults. |

## Metadata

**Analog search scope:** `R/` (all 8 source files), `tests/testthat/` (all 10 test files).
**Files scanned:** 18.
**Pattern extraction date:** 2026-05-02.
**Source-of-truth file:** `R/as_d3_ir.R` (1,151 lines, read in full this and prior session per RESEARCH Sources).

## PATTERN MAPPING COMPLETE
