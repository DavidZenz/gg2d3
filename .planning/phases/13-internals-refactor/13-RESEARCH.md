# Phase 13: Internals Refactor - Research

**Researched:** 2026-05-02
**Domain:** R package internals refactor (ggplot2 → IR extraction pipeline)
**Confidence:** HIGH

## Summary

This phase decomposes the 1,151-line `R/as_d3_ir.R` (a single ~1100-line function `as_d3_ir()` plus inline helpers) into per-concern files (`R/ir_scales.R`, `R/ir_theme.R`, `R/ir_facets.R`, `R/ir_layers.R`, `R/ir_legends.R`, plus `R/ir_utils.R`), and routes all `ggplot2:::calc_element()` call sites through a `calc_element_safe()` wrapper that falls back to public ggplot2 API on error. The refactor is purely structural — the IR contract with `inst/htmlwidgets/gg2d3.js` and the `validate_ir()` shape MUST NOT change. Existing testthat suite (12 files, 2,379 LOC) plus visual baselines in `test_output/` are the regression net.

The decisive research finding: **`ggplot2::calc_element()` is exported as of ggplot2 4.0.3** [VERIFIED: `getNamespaceExports("ggplot2")` returned `"calc_element"` — confirmed in this session]. This collapses the fallback design: `calc_element_safe()` can simply call `ggplot2::calc_element()` (public) directly when `ggplot2:::calc_element()` (private) fails, with no need for elaborate workaround. The static-default lookup in D-06 step 3 is still useful as defense-in-depth for hypothetical future API drift, but step 2 becomes trivial.

The seams in `as_d3_ir()` are clean — each block is concern-pure with no shared mutable state (only ordering dependencies on a few precomputed scalars: `xscale_obj`, `yscale_obj`, `is_flip_early`, `pp_x`, `pp_y`, `x_trans_name`, `y_trans_name`, `scales`). Refactor risk is low; the mechanical work is large but well-bounded.

**Primary recommendation:** Sequence extractions theme → utils → scales → layers → legends → facets, with one extractor per commit and full `devtools::test()` between each. Keep extractor signatures pure (`function(b, theme, ...)` returning a list); thread the small set of precomputed scalars as explicit args rather than recomputing.

## User Constraints (from CONTEXT.md)

### Locked Decisions

**Module shape:**
- **D-01:** Decompose `as_d3_ir()` into file-per-concern modules at `R/` root (R packages require flat `R/`, no nested directories).
- **D-02:** New files: `R/ir_scales.R`, `R/ir_theme.R`, `R/ir_facets.R`, `R/ir_layers.R`, `R/ir_legends.R`. Final file naming/grouping is the planner's call as long as the spirit holds — one file per concern, named `R/ir_*.R`.
- **D-03:** `R/as_d3_ir.R` becomes a thin orchestrator. Target: under ~200 lines (REFACTOR-01 success criterion). Top-level function only wires `ggplot_build()` results through the extraction helpers.
- **D-04:** Each `ir_*.R` file exports its top-level extractor (e.g. `extract_scales_ir()`, `extract_theme_ir()`). Inner helpers stay internal. All extractors are pure functions of `ggplot_build()` output + theme — no shared mutable state.

**`calc_element` fallback:**
- **D-05:** Single `calc_element_safe(element_name, theme)` helper. Every existing `ggplot2:::calc_element()` call site (5 sites: lines 75, 619, 825, 942, 1061 of current `as_d3_ir.R`) routes through it.
- **D-06:** Lookup order: (1) `ggplot2:::calc_element()` (current path); (2) on error, public-API path via `theme_get()` + exported `ggplot2::calc_element` or `ggplot_build()`-resolved theme; (3) on second failure, documented ggplot2 default for that element (small static lookup for `legend.position`, `legend.key.size`, `panel.spacing`, plus the generic theme element accessor at L75).
- **D-07:** When fallback (step 2 or 3) is used, emit a once-per-session `warning()` naming the missing element and the ggplot2 version.
- **D-08:** Helper lives in `R/ir_theme.R`.

**Behavior-change tolerance:**
- **D-09:** "Refactor done" gate is tests-pass equivalence: all v1.0 unit tests + existing visual regression checkpoints continue to pass.
- **D-10:** IR JSON output is NOT required to be byte-identical to v1.0. Trivial differences (field ordering, whitespace, list naming) are acceptable as long as the D3 renderer produces visually identical SVG.
- **D-11:** Visual equivalence judged against v1.0 visual test outputs in `test_output/` for the existing test plot corpus. Pixel-level diff is the safety net.

### Claude's Discretion

- **Test seam strategy:** Both per-helper unit tests (synthetic `ggplot_build()` slices) AND a small set of full-pipeline IR snapshot tests.
- **Refactor sequencing:** Planner decides order (default: theme first since it gates `calc_element_safe`, then scales, layers, legends, facets) and commit granularity. Default: one extractor per atomic commit.
- **Internal helper migration:** Inline helpers (`%||%`, `to_rows`, `map_discrete`, `extract_theme_element`, `validate_log_domain`, `get_scale_transform`, `get_scale_info`, `dom`) placed in concern-owning `ir_*.R` or in `R/ir_utils.R` if cross-cutting.
- **Naming conventions:** Function naming, internal data structures, roxygen2 doc style at planner's discretion as long as `devtools::document()` runs clean.

### Deferred Ideas (OUT OF SCOPE)

- IR schema cleanup (field renames, dropping unused fields) — breaks JS contract.
- Replacing `ggplot_build()` with `layer_data()` / `ggplot_gtable()` — bigger architectural shift.
- Generalizing extractor framework into a registry — v1.2+ topic.

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| REFACTOR-01 | `as_d3_ir()` is split into per-concern modules (scales, theme, facets, layers); top-level function ≤ ~200 lines | Seam Map below identifies 6 clean extractor boundaries; current top-level function does no work that can't be moved into a helper. |
| REFACTOR-02 | `ggplot2:::calc_element()` usage is wrapped in a helper with public-API fallback | `ggplot2::calc_element` IS exported in 4.0.3; fallback chain is straightforward (private → public → static default). |

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Scale domain/transform extraction | R / `ir_scales.R` | — | Operates on `ggplot_build()` panel_scales + panel_params; pure data shaping. |
| Theme element resolution | R / `ir_theme.R` | — | Owns `calc_element_safe()` and all element_rect/line/text/margin → list conversion. |
| Layer data + aesthetic mapping | R / `ir_layers.R` | — | Iterates `b$data` and `b$plot$layers`, dispatches geom name, rowizes to scalars. |
| Legend / guide IR | R / `ir_legends.R` | — | Walks `b$plot$scales`, calls `ggplot2::get_guide_data()`, builds guide specs + handles merging. |
| Facet metadata + per-panel scales | R / `ir_facets.R` | `ir_scales.R` | Reads `b$layout$facet`, `b$layout$layout`, `b$layout$panel_params`. Reuses temporal-conversion logic from scales. |
| Top-level orchestration | R / `as_d3_ir.R` | — | Calls `ggplot_build()`, runs validations (CoordTrans warning, log-domain), wires extractors, returns IR + calls `validate_ir()`. |
| IR shape validation | R / `validate_ir.R` (existing) | — | Untouched. The contract enforcer. |
| JS rendering | `inst/htmlwidgets/gg2d3.js` | — | Untouched. Consumes IR. The reason behavior change is not allowed. |

## Standard Stack

This is an internal refactor. No new dependencies are added. The relevant existing stack:

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| ggplot2 | 4.0.3 (verified in session) | Source of plot objects + theme/scale internals | The entire IR pipeline reads from `ggplot_build()` output |
| testthat | ≥ 3.0.0 (edition 3) | Test runner | Already configured in DESCRIPTION |
| devtools | (suggested, not Imports) | `load_all`, `document`, `test` | Standard R package dev loop; project also tolerates `pkgload::load_all()` (per MEMORY.md) |
| roxygen2 | 7.3.3 | Doc generation | Already configured |
| grid | (base R) | `convertUnit` for theme margin/spacing → pixels | Already used |

[VERIFIED: ggplot2 4.0.3 export list inspected in this session via `getNamespaceExports("ggplot2")` — `calc_element`, `complete_theme`, `theme_get`, `element_grob`, `get_element_tree`, `merge_element` are all exported.]

**Version verification:**
```bash
Rscript -e 'cat(as.character(packageVersion("ggplot2")))'
# 4.0.3 (verified 2026-05-02)
```

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `ggplot2:::calc_element()` (private) | `ggplot2::calc_element()` (public, exported) | Public API is now exported — fallback path is trivial. Keep private as primary because that's the v1.0 behavior; switching primary changes call semantics on plots where the two diverge (none observed, but D-09 forbids gambling). |
| File-per-concern in `R/` | `R/ir/*.R` subdirectory | NOT POSSIBLE — R CMD check requires flat `R/`. CONTEXT D-01 confirms. |

## Architecture Patterns

### System Architecture Diagram

```
                                     +---------------------+
       ggplot object  ───────────▶   |  as_d3_ir(p, ...)   |   (orchestrator, ≤200 lines)
                                     +----------+----------+
                                                │
                            ggplot2::ggplot_build(p)
                                                │
                                                ▼
                                     +---------------------+
                                     |   built object  b   |
                                     +----------+----------+
                                                │
                ┌───────────────┬───────────────┼────────────────┬────────────────┐
                ▼               ▼               ▼                ▼                ▼
        extract_scales_ir  extract_theme_ir  extract_layers_ir  extract_legends_ir  extract_facets_ir
        (ir_scales.R)      (ir_theme.R)      (ir_layers.R)      (ir_legends.R)      (ir_facets.R)
                │               │               │                │                │
                │               │               │                │                │
                │       calc_element_safe       │                │                │
                │       (private → public →     │                │                │
                │        static default;        │                │                │
                │        once-per-session       │                │                │
                │        warning on fallback)   │                │                │
                │                               │                │                │
                └───────────────┬───────────────┴────────────────┴────────────────┘
                                ▼
                       assembled ir list
                                │
                                ▼
                          validate_ir(ir)   (R/validate_ir.R, unchanged)
                                │
                                ▼
                            return ir   ──▶  inst/htmlwidgets/gg2d3.js  (renderer, unchanged)
```

Data flow: a single `ggplot_build()` produces `b`, which is passed (along with `theme = b$plot$theme`) to each extractor. Extractors return list slices that the orchestrator assembles into the final `ir` list. `calc_element_safe()` is the only point of contact with ggplot2's internal theme resolution — every other extractor is pure `ggplot_build()` output shaping.

### Recommended Project Structure

```
R/
├── as_d3_ir.R          # thin orchestrator (target ≤200 lines)
├── ir_utils.R          # %||%, to_rows, map_discrete, dom — cross-cutting
├── ir_scales.R         # extract_scales_ir + get_scale_info, get_scale_transform, validate_log_domain
├── ir_theme.R          # extract_theme_ir + calc_element_safe + extract_theme_element
├── ir_layers.R         # extract_layers_ir + geom-name dispatch + temporal column conversion
├── ir_legends.R        # extract_legends_ir + guide merging
├── ir_facets.R         # extract_facets_ir (wrap + grid + null branches) + per-panel temporal conversion
├── validate_ir.R       # UNCHANGED
├── gg2d3.R             # UNCHANGED (calls as_d3_ir)
└── d3_*.R              # UNCHANGED (interactivity API)

tests/testthat/
├── test-ir.R                # EXISTING — keep, full-pipeline tests
├── test-validate-ir.R       # EXISTING — untouched
├── test-ir-scales.R         # NEW — unit tests for extract_scales_ir
├── test-ir-theme.R          # NEW — unit tests for extract_theme_ir + calc_element_safe
├── test-ir-layers.R         # NEW — unit tests for extract_layers_ir
├── test-ir-legends.R        # NEW — unit tests for extract_legends_ir
└── test-ir-facets.R         # NEW — unit tests for extract_facets_ir
```

(File grouping is at planner's discretion per D-02 — the `R/ir_*.R` naming is the binding constraint.)

### Pattern 1: Pure Extractor Signature

**What:** Each extractor takes the built object plus pre-resolved context, returns a list slice. No closures, no `<<-`, no shared mutable state.
**When to use:** All five new extractors.
**Example:**
```r
#' @keywords internal
#' @noRd
extract_scales_ir <- function(b, pp_x, pp_y, is_flip = FALSE) {
  xscale_obj <- b$layout$panel_scales_x[[1]]
  yscale_obj <- b$layout$panel_scales_y[[1]]

  # ... existing get_scale_info / breaks / temporal logic ...

  scales <- list(
    x = c(get_scale_info(xscale_obj, pp_x, "x"), list(breaks = unname(x_breaks), ...)),
    y = c(get_scale_info(yscale_obj, pp_y, "y"), list(breaks = unname(y_breaks), ...))
  )

  # Color scale (currently lines 466-533 of as_d3_ir.R)
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

### Pattern 2: `calc_element_safe()` Implementation

**What:** Single chokepoint for theme element resolution with three-tier fallback and once-per-session warning.
**When to use:** Every site that currently calls `ggplot2:::calc_element()` (5 sites in current code).
**Example:**
```r
# In R/zzz.R or top of R/ir_theme.R — package-internal env for warning state
.gg2d3_pkgenv <- new.env(parent = emptyenv())
.gg2d3_pkgenv$calc_element_warned <- FALSE

#' @keywords internal
#' @noRd
calc_element_safe <- function(element_name, theme) {
  # Tier 1: existing private path (preserves v1.0 behavior exactly)
  result <- tryCatch(
    ggplot2:::calc_element(element_name, theme),
    error = function(e) e
  )
  if (!inherits(result, "error")) return(result)

  # Tier 2: public exported API (ggplot2 >= some version where calc_element is exported)
  result <- tryCatch({
    complete <- ggplot2::theme_get() + theme
    ggplot2::calc_element(element_name, complete)
  }, error = function(e) e)
  if (!inherits(result, "error")) {
    .gg2d3_warn_once(element_name, "public-API path")
    return(result)
  }

  # Tier 3: static default for known elements
  default <- .gg2d3_calc_element_default(element_name)
  .gg2d3_warn_once(element_name, "static default")
  default
}

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
    NULL  # generic fallback
  )
}
```

[VERIFIED: `ggplot2::calc_element` is in `getNamespaceExports("ggplot2")` for ggplot2 4.0.3 — confirmed by Rscript probe in this session. Signature: `calc_element(element, theme, verbose, skip_blank, call)`.]

[VERIFIED: `ggplot2::theme_get` and `ggplot2::complete_theme(theme, default)` are also exported — confirmed in same probe.]

### Pattern 3: Test Seam — Synthetic `ggplot_build()` Slices

**What:** Per-extractor unit tests construct a real `ggplot_build()` object, then call the extractor in isolation.
**When to use:** Each `test-ir-*.R` file.
**Example:**
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

This pattern matches the existing test conventions in `tests/testthat/test-ir.R` (per `.planning/codebase/TESTING.md`): no mocking, real `ggplot_build()`, `library(ggplot2)` inside the test, descriptive names.

### Anti-Patterns to Avoid

- **`<<-` superassign for cross-extractor state:** The current code uses `facets_ir <<-` and `panels_ir <<-` inside a `tryCatch` error handler (lines 1109–1126). When extracted, the helper must return the fallback list explicitly — do NOT preserve `<<-` semantics across the function boundary.
- **Recomputing `ggplot_build()` inside helpers:** Build once in the orchestrator, pass `b` everywhere.
- **Splitting `to_rows` per file:** It's defined twice in the current code (lines 27 and 215) — DRY into one definition in `ir_utils.R` or `ir_layers.R`. The two versions differ slightly (the inner one handles `PANEL` integer coercion and list-columns); the merged version must keep both behaviors.
- **`@export` on internal extractors:** Per D-04 each `ir_*.R` exports its top-level extractor — but "exports" in CONTEXT means file-internal API, not package-level. Use `@keywords internal` so they're available across the package without polluting the public API. Only `as_d3_ir()` and the existing `gg2d3()` / `validate_ir()` / `d3_*()` should be `@export`.
- **Reordering temporal conversion:** Temporal `* 86400000` / `* 1000` conversions appear in three places (scales, layers, facets). All three must apply consistently in the same place they do today, or domain/breaks/data go out of sync.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Theme element resolution | Custom theme walk | `calc_element_safe()` wrapping `ggplot2:::calc_element` (with `ggplot2::calc_element` public fallback) | The element tree, inheritance, `element_blank` propagation, and merging logic in ggplot2 are non-trivial and version-coupled. |
| Public theme merge | `theme_get() + theme` by hand | `ggplot2::complete_theme(theme, ggplot2::theme_get())` | Exported, handles defaults correctly. |
| Guide / legend extraction | Walk `b$plot$scales` and reimplement key generation | `ggplot2::get_guide_data(p, aesthetic = aes_name)` | Already exported and used in current code (line 667). Keep using it. |
| Unit → pixel conversion | Custom mm/inch math | `grid::convertUnit(x, "inches", valueOnly = TRUE) * 96` | Existing pattern; consistent with how plot.margin and panel.spacing already convert. |
| IR shape validation | New checks in extractors | `validate_ir(ir)` at end of orchestrator | Already exists; refactor only needs to keep producing IR that passes it. |

**Key insight:** This refactor's job is to MOVE existing code, not invent new abstractions. Anywhere the current code uses a helper, keep using it. The only new helper is `calc_element_safe()`.

## Runtime State Inventory

> Refactor phase. Auditing what besides `R/as_d3_ir.R` references the symbols being moved or wrapped.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| **Stored data** | None — gg2d3 produces JSON IR per render call; no persistent store. | None. |
| **Live service config** | None — pure R package. | None. |
| **OS-registered state** | None. | None. |
| **Secrets/env vars** | None. | None. |
| **Build artifacts / installed packages** | `man/*.Rd` files generated by roxygen2. After refactor, `devtools::document()` will regenerate man pages for new exports/keyword-internal functions. The current `as_d3_ir.Rd` (if any in `man/`) stays valid since the public function isn't moving. | Run `devtools::document()` after refactor; commit any regenerated `man/*.Rd`. NAMESPACE may gain no new exports (extractors are internal per D-04 and Anti-Pattern note). |

**Cross-file references to symbols being moved** (verified via grep): The inline helpers (`%||%`, `to_rows`, `map_discrete`, `extract_theme_element`, `validate_log_domain`, `get_scale_transform`, `get_scale_info`, `dom`) are all defined inside `as_d3_ir()` as closures — they have no external callers. Other `R/*.R` files (`d3_brush.R`, `d3_hover.R`, etc.) do NOT reference them. Safe to relocate freely.

[VERIFIED: `R/as_d3_ir.R` read in full (1,151 lines) — all listed helpers are local closures.]

## Common Pitfalls

### Pitfall 1: Closure capture broken when helpers move out of `as_d3_ir`'s scope

**What goes wrong:** Inside the current `as_d3_ir()`, `to_rows()` (inner version, line 215) captures `keep_aes` from the enclosing scope (line 203). When `to_rows` moves to `ir_utils.R`, that closure breaks.
**Why it happens:** R closures capture by lexical scope at definition time.
**How to avoid:** Pass `keep_aes` as an explicit argument: `to_rows(df, keep_aes)`. Same applies to `map_discrete` (captures `xscale_obj`/`yscale_obj` indirectly — currently it's passed `scale_obj` explicitly, so already safe).
**Warning signs:** `Error: object 'keep_aes' not found` at test time.

### Pitfall 2: `<<-` in facets fallback handler stops working

**What goes wrong:** Lines 1109–1126: the `tryCatch` error handler does `facets_ir <<- ...; panels_ir <<- ...` to escape into the parent frame. When `extract_facets_ir()` becomes its own function, `<<-` no longer reaches `as_d3_ir`'s frame; it modifies the global env, which is wrong.
**Why it happens:** `<<-` walks up the call stack searching for an existing binding.
**How to avoid:** Make the extractor return `list(facets = ..., panels = ...)` and have the orchestrator destructure. The fallback case returns the "null" facets + single-panel default explicitly.
**Warning signs:** Tests that exercise faceted plots with intentionally malformed input fail; or worse, silent global-env pollution.

### Pitfall 3: `to_rows()` defined twice with subtly different behavior

**What goes wrong:** Outer `to_rows` (line 27) drops factors → character, doesn't handle `PANEL` integer coercion or `list`-columns. Inner `to_rows` (line 215) does. They're called in different places.
**Why it happens:** Organic accretion. The outer one is dead-ish (the layer block redefines it); but verify by reading where `to_rows` is called.
**How to avoid:** Audit call sites. Lines 27 outer is only used inside the layer mapper at... actually, looking at the code: the outer `to_rows` (line 27) isn't called anywhere — the inner one (line 215) shadows it inside the `layers <- lapply(...)` block. The outer is dead code. **Drop the outer; keep the inner; move to `ir_utils.R` (or `ir_layers.R` if no other concern uses it).**
**Warning signs:** Tests that depend on `PANEL` being integer or boxplot `outliers` list-column being preserved would break if the wrong version wins.

[VERIFIED: grepped `to_rows` in `R/as_d3_ir.R` — only call site is `to_rows(df)` at line 282, inside the `layers` lapply, which uses the inner (line 215) definition due to lexical shadowing.]

### Pitfall 4: ggplot2 lazy evaluation / NSE in scale closures

**What goes wrong:** The current `get_scale_info` reaches into `environment(scale_obj$labels)$f` to extract `date_labels` and timezone (lines 416–451). This is a dance with ggplot2's internal closure structure; it's fragile but already handled with `tryCatch`.
**Why it happens:** ggplot2's date/datetime scales store format strings in a closure environment, not as a public field.
**How to avoid:** When moving this to `ir_scales.R`, keep the `tryCatch` wrappers exactly. Do NOT "clean up" the environment-walking code — it's compensating for an upstream API gap. Add a comment documenting why.
**Warning signs:** `test-date-scales.R` failures with "format" or "timezone" assertions.

### Pitfall 5: roxygen2 `@export` reintroduced accidentally

**What goes wrong:** Copying `extract_theme_element` (current name in code) into a new file with default roxygen template might add `@export`, polluting NAMESPACE.
**Why it happens:** Default `Code → Insert Roxygen Skeleton` adds `@export`.
**How to avoid:** Use `#' @keywords internal` and `#' @noRd` for all new helpers. Verify NAMESPACE diff after `devtools::document()` — should add zero new export entries.
**Warning signs:** `R CMD check` warns about undocumented exports; or NAMESPACE grows unexpectedly.

### Pitfall 6: Visual regression with no automated harness

**What goes wrong:** `test_output/` contains visual baselines but per `.planning/codebase/TESTING.md` "Widget output tested for structure/data, not visual correctness" — there is no automated pixel-diff. D-11's "pixel-level diff is the safety net" is a manual checkpoint.
**Why it happens:** R-side testthat can't easily run a headless browser.
**How to avoid:** Treat per-extractor commits as bisectable units. After each extractor lands, re-render the v1.0 corpus and eyeball; full pixel diff at end. Plan should explicitly list which test plots get re-rendered and where to save outputs (`test_output/phase13/<step>/`).
**Warning signs:** A late-phase visual regression with no obvious culprit because too many extractors moved between visual checks.

## Code Examples

### Theme extractor entry point (sketch from current code at lines 535–571, 819–856)

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
      line     = extract_theme_element("axis.line",     b$plot$theme),
      # ... etc, copied verbatim from current 552-563 ...
    ),
    text = list(
      title    = extract_theme_element("plot.title",    b$plot$theme),
      subtitle = extract_theme_element("plot.subtitle", b$plot$theme),
      caption  = extract_theme_element("plot.caption",  b$plot$theme)
    )
  )

  # Legend theme additions (lines 819-846 of current)
  legend_theme <- list(
    key.size   = .extract_legend_key_size(b$plot$theme),  # uses calc_element_safe
    text       = extract_theme_element("legend.text",       b$plot$theme),
    title      = extract_theme_element("legend.title",      b$plot$theme),
    background = extract_theme_element("legend.background", b$plot$theme),
    key        = extract_theme_element("legend.key",        b$plot$theme)
  )
  theme_ir$legend <- legend_theme

  theme_ir$strip <- list(
    text       = extract_theme_element("strip.text",       b$plot$theme),
    background = extract_theme_element("strip.background", b$plot$theme)
  )

  theme_ir
}
```

`extract_theme_element` itself is the function currently at lines 74–141; lift wholesale, replace `ggplot2:::calc_element(...)` at line 75 with `calc_element_safe(...)`.

### Top-level orchestrator after refactor (sketch)

```r
#' Build a D3-ready IR (intermediate representation) from a ggplot
#' @export
as_d3_ir <- function(p, width = 640, height = 400,
                     padding = list(top = 20, right = 20, bottom = 40, left = 50)) {
  stopifnot(inherits(p, "ggplot"))
  b <- ggplot2::ggplot_build(p)

  if (inherits(b$plot$coordinates, "CoordTrans")) {
    warning("coord_trans() is not yet supported by gg2d3. ...", call. = FALSE)
  }

  # Coord detection (currently lines 474-486, 573-589)
  is_flip   <- inherits(b$plot$coordinates, "CoordFlip")
  is_fixed  <- inherits(b$plot$coordinates, "CoordFixed")
  coord_type  <- if (is_flip) "flip" else if (is_fixed) "fixed" else "cartesian"
  coord_ratio <- if (is_fixed) (b$plot$coordinates$ratio %||% 1) else NULL

  # Un-swap panel_params for coord_flip
  if (is_flip) { pp_x <- b$layout$panel_params[[1]]$y; pp_y <- b$layout$panel_params[[1]]$x }
  else         { pp_x <- b$layout$panel_params[[1]]$x; pp_y <- b$layout$panel_params[[1]]$y }

  # Delegate to extractors
  scales   <- extract_scales_ir(b, pp_x, pp_y, is_flip = is_flip)
  layers   <- extract_layers_ir(b)
  theme_ir <- extract_theme_ir(b)
  legends  <- extract_legends_ir(b, p)  # needs `p` for get_guide_data
  fp       <- extract_facets_ir(b, pp_x, pp_y, scales, is_flip = is_flip)

  # Axis labels (swap for coord_flip)
  if (is_flip) { x_label <- b$plot$labels$y %||% ""; y_label <- b$plot$labels$x %||% "" }
  else         { x_label <- b$plot$labels$x %||% ""; y_label <- b$plot$labels$y %||% "" }

  ir <- list(
    width = width, height = height, padding = padding,
    coord = list(type = coord_type, flip = is_flip, ratio = coord_ratio),
    title = b$plot$labels$title %||% "",
    subtitle = b$plot$labels$subtitle %||% "",
    caption  = b$plot$labels$caption  %||% "",
    axes = list(
      x  = list(orientation = "bottom", label = x_label, tickLabels = .axis_ticklabels(pp_x)),
      y  = list(orientation = "left",   label = y_label, tickLabels = .axis_ticklabels(pp_y)),
      x2 = if (.has_sec_axis(b, "x")) list(enabled = TRUE) else NULL,
      y2 = if (.has_sec_axis(b, "y")) list(enabled = TRUE) else NULL
    ),
    facets = fp$facets,
    panels = fp$panels,
    scales = scales,
    layers = layers,
    guides = legends$guides,
    legend = list(enabled = TRUE, position = legends$position),
    theme  = theme_ir
  )

  validate_ir(ir)
}
```

This sketch is ~50 lines, well under the ~200 cap. `.axis_ticklabels` and `.has_sec_axis` are tiny helpers (currently lines 593–614 inline) that could live in `ir_utils.R` or `ir_layers.R`.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `ggplot2:::calc_element` private | `ggplot2::calc_element` exported | Some ggplot2 release prior to 4.0.3 (verified exported in 4.0.3) | The fallback in D-06 step 2 is now trivial — just call the exported function. The static-default lookup (step 3) becomes pure defense-in-depth. |
| Inline closures inside one giant function | File-per-concern modules | This phase | Standard R-package pattern; gg2d3 already uses it for `R/d3_*.R` interactivity API. |

**Deprecated/outdated:**
- The `to_rows` outer definition at line 27 is dead code (shadowed by inner definition at line 215). Drop on migration.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | testthat 3.0.0+ (edition 3) — verified in `DESCRIPTION` |
| Config file | `tests/testthat.R` (standard) + `Config/testthat/edition: 3` in DESCRIPTION |
| Quick run command | `Rscript -e 'testthat::test_file("tests/testthat/test-ir-<area>.R")'` |
| Full suite command | `Rscript -e 'devtools::test()'` (or `pkgload::load_all(); testthat::test_dir("tests/testthat")`) |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| REFACTOR-01 | `as_d3_ir()` ≤ ~200 lines, delegates to named helpers | structure (line count + grep) | `wc -l R/as_d3_ir.R` + grep for `extract_*_ir` calls | ❌ Add line-count check to plan verification step (not testthat) |
| REFACTOR-01 | `extract_scales_ir()` produces v1.0-equivalent scales slice | unit | `Rscript -e 'testthat::test_file("tests/testthat/test-ir-scales.R")'` | ❌ Wave 0 |
| REFACTOR-01 | `extract_theme_ir()` produces v1.0-equivalent theme slice | unit | `... test-ir-theme.R'` | ❌ Wave 0 |
| REFACTOR-01 | `extract_layers_ir()` produces v1.0-equivalent layers list | unit | `... test-ir-layers.R'` | ❌ Wave 0 |
| REFACTOR-01 | `extract_legends_ir()` produces v1.0-equivalent guides | unit | `... test-ir-legends.R'` | ❌ Wave 0 |
| REFACTOR-01 | `extract_facets_ir()` produces v1.0-equivalent facets+panels | unit | `... test-ir-facets.R'` | ❌ Wave 0 |
| REFACTOR-01 | Full-pipeline IR equivalent on representative corpus | snapshot/integration | re-use `test-ir.R` + new full-pipeline checks | ✅ `test-ir.R` exists; supplement with snapshot tests |
| REFACTOR-02 | All 5 `calc_element` sites route through `calc_element_safe` | static check | `grep -rn 'ggplot2:::calc_element' R/` should match only `R/ir_theme.R::calc_element_safe` body | ❌ Add to plan verification |
| REFACTOR-02 | `calc_element_safe` falls back on private-API failure | unit | `... test-ir-theme.R'` (mock failure) | ❌ Wave 0 |
| REFACTOR-02 | `calc_element_safe` emits exactly one warning per session on fallback | unit | `... test-ir-theme.R'` with `expect_warning` + repeat call `expect_silent` | ❌ Wave 0 |
| D-09 | All v1.0 tests pass on refactored code | regression | `Rscript -e 'devtools::test()'` | ✅ `tests/testthat/` (10 test files, 2,379 LOC) |
| D-11 | Visual regression on test_output/ corpus | manual visual diff | per plan instructions, render corpus + eyeball | ✅ `test_output/` baselines exist (per CONTEXT) |

### Sampling Rate
- **Per task commit:** Run the relevant `test-ir-<area>.R` file plus `test-ir.R` and `test-validate-ir.R` (cheap; full IR pipeline still exercised).
- **Per wave merge:** `Rscript -e 'devtools::test()'` (full testthat suite, ~10 files).
- **Phase gate:** Full suite green + visual diff on test_output/ corpus before `/gsd-verify-work`.

### Wave 0 Gaps
- [ ] `tests/testthat/test-ir-scales.R` — covers REFACTOR-01 (scales extractor)
- [ ] `tests/testthat/test-ir-theme.R` — covers REFACTOR-01 (theme extractor) AND REFACTOR-02 (`calc_element_safe` fallback + warn-once)
- [ ] `tests/testthat/test-ir-layers.R` — covers REFACTOR-01 (layers extractor)
- [ ] `tests/testthat/test-ir-legends.R` — covers REFACTOR-01 (legends extractor)
- [ ] `tests/testthat/test-ir-facets.R` — covers REFACTOR-01 (facets extractor)
- [ ] No new fixtures/conftest needed — testthat uses inline `library(ggplot2)` + built-in datasets per existing convention (TESTING.md).

## Project Constraints (from CLAUDE.md)

- **R package convention:** Use `devtools::load_all()`, `devtools::document()`, `devtools::test()`. (Project also tolerates `pkgload::load_all()` per MEMORY.md — devtools may not always be installed.)
- **D3 layer is owned by JS:** `inst/htmlwidgets/gg2d3.js` is the IR consumer. Refactor must NOT change the IR contract (D-10 allows trivial JSON-shape variation only if SVG is identical).
- **Test execution:** `devtools::test()` for full suite; `testthat::test_file("tests/testthat/test-ir.R")` for single file.
- **README rebuild:** `devtools::build_readme()` — not relevant to this phase but noted.
- **Visual test outputs go to `test_output/`** (in `.gitignore`) per MEMORY.md — DO NOT commit visual outputs.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The 5 `ggplot2:::calc_element` sites are at lines 75, 619, 825, 942, 1061 | calc_element fallback / Standard Stack | Low — CONTEXT.md D-05 asserts these line numbers; reading R/as_d3_ir.R confirms `ggplot2:::calc_element` at lines 75, 619, 825, 942, 1061 [VERIFIED via direct file read in this session]. |
| A2 | `ggplot2::calc_element` was already exported at gg2d3 v1.0 ship time (2026-02-16) | Standard Stack / D-06 | Low — if it wasn't, the fallback chain still works (it would skip to tier 3); `ggplot2::theme_get` and `ggplot2::complete_theme` are also exported [VERIFIED in session]. The minimum-version question is moot because D-06 makes it a fallback, not a primary. |
| A3 | `test_output/` contains v1.0 visual baselines suitable for pixel diff | Pitfall 6 / Validation | Medium — CONTEXT.md D-11 asserts this; not independently verified in research session (would need to inspect `test_output/` contents which are gitignored). Plan should include "verify baseline corpus exists and is current" as an explicit step. |
| A4 | The outer `to_rows` (line 27) is dead code shadowed by the inner one (line 215) | Pitfall 3 | Low — `to_rows` is only called once at line 282, lexically inside the `layers <- lapply(...)` block where the inner definition shadows the outer [VERIFIED via grep in session]. |
| A5 | `extract_theme_element`'s closure capture of `keep_aes` is the only lexical-scope hazard | Pitfall 1 | Medium — read the file but did not exhaustively trace every closure. Plan should include a "lift each helper, run tests after each lift" step to surface any others early. |

## Open Questions (RESOLVED)

1. **Is there an automated visual-regression harness in v1.0?**
   - What we know: `test_output/` exists and is gitignored; CONTEXT D-11 calls visual diff "the safety net."
   - What's unclear: Whether there's a script that renders the corpus and a way to programmatically diff against a baseline, or whether the diff is fully manual.
   - **RESOLVED:** Plan 07 Task 2 implements a manual visual-diff procedure on the `test_output/` corpus as the gate. Plan should include a "Wave 0" task that documents (or builds, if missing) the corpus-rendering script. If no harness exists, the visual check is manual-eyeball — surface this risk in the plan's verification section.

2. **What is the minimum ggplot2 version gg2d3 needs to support?**
   - What we know: DESCRIPTION has no `Imports:` block — gg2d3 currently doesn't declare a version constraint. ggplot2 4.0.3 verified in dev environment.
   - What's unclear: Whether `ggplot2::calc_element` was exported at gg2d3 v1.0 ship time or in older ggplot2 releases users might still have.
   - **RESOLVED:** Deferred to Phase 17 (CRAN packaging). This phase doesn't need to answer it — the fallback chain handles old ggplot2 (private path works) and new ggplot2 (public path works). Phase 17 (CRAN packaging) can pin a minimum.

3. **Should `calc_element_safe` warn-once state survive `devtools::load_all()` cycles?**
   - What we know: `.gg2d3_pkgenv` lives in package namespace; load_all rebuilds it.
   - What's unclear: Test interaction — if test 1 triggers fallback and warns, test 2 might silently fall back without warning.
   - **RESOLVED:** Test-only reset hook `.gg2d3_reset_calc_element_warned()` implemented in `R/zzz.R` per plan 01. Provide a test-only reset hook: `.gg2d3_pkgenv$calc_element_warned <- FALSE` callable from test setup. Keep it `@keywords internal @noRd`.

## Sources

### Primary (HIGH confidence)
- `R/as_d3_ir.R` (1,151 lines) — read in full this session.
- `R/validate_ir.R` — read this session for IR contract.
- `tests/testthat/` directory — listed and `test-ir.R` sampled.
- `DESCRIPTION` — read this session.
- `.planning/phases/13-internals-refactor/13-CONTEXT.md` — read in full.
- `.planning/codebase/TESTING.md` — read in full.
- `.planning/REQUIREMENTS.md` — REFACTOR-01/02 wording confirmed.
- `.planning/ROADMAP.md` — Phase 13 entry confirmed.
- ggplot2 package (4.0.3) — `getNamespaceExports("ggplot2")` probed via Rscript in session.

### Secondary (MEDIUM confidence)
- (none — refactor-only phase, no external research needed)

### Tertiary (LOW confidence)
- (none)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — verified ggplot2 4.0.3 export list directly.
- Architecture: HIGH — read the entire 1,151-line target file; CONTEXT.md locked most decisions.
- Pitfalls: HIGH — derived from direct code reading, not speculation.
- Validation: MEDIUM — testthat conventions verified from TESTING.md, but the visual-regression harness is unverified (Open Question 1).

**Research date:** 2026-05-02
**Valid until:** 2026-06-02 (refactor-only; no external dependencies likely to drift; ggplot2 release cadence is the main risk and 30 days is comfortable)
