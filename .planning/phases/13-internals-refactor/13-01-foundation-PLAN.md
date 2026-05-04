---
phase: 13
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - tests/testthat/test-ir-scales.R
  - tests/testthat/test-ir-theme.R
  - tests/testthat/test-ir-layers.R
  - tests/testthat/test-ir-legends.R
  - tests/testthat/test-ir-facets.R
  - R/zzz.R
  - R/ir_utils.R
autonomous: true
requirements: [REFACTOR-01, REFACTOR-02]
tags: [r-package, ggplot2, refactor, testthat]

must_haves:
  truths:
    - "All 5 new test-ir-*.R files exist and run (skipped or trivially passing) without breaking the suite"
    - "R/zzz.R defines .gg2d3_pkgenv with calc_element_warned=FALSE plus a reset hook"
    - "R/ir_utils.R defines top-level %||%, to_rows(df, keep_aes), and dom() — no longer captured closures"
    - "devtools::test() (or pkgload::load_all + testthat::test_dir) is green"
  artifacts:
    - path: "tests/testthat/test-ir-scales.R"
      provides: "Wave 0 stub for extract_scales_ir"
      contains: "test_that"
    - path: "tests/testthat/test-ir-theme.R"
      provides: "Wave 0 stub for extract_theme_ir + calc_element_safe"
      contains: "test_that"
    - path: "tests/testthat/test-ir-layers.R"
      provides: "Wave 0 stub for extract_layers_ir"
      contains: "test_that"
    - path: "tests/testthat/test-ir-legends.R"
      provides: "Wave 0 stub for extract_legends_ir"
      contains: "test_that"
    - path: "tests/testthat/test-ir-facets.R"
      provides: "Wave 0 stub for extract_facets_ir"
      contains: "test_that"
    - path: "R/zzz.R"
      provides: ".gg2d3_pkgenv warn-once flag and reset hook"
      contains: ".gg2d3_pkgenv"
    - path: "R/ir_utils.R"
      provides: "%||%, to_rows, dom utilities (top-level, not closures)"
      contains: "to_rows"
  key_links:
    - from: "R/zzz.R"
      to: ".gg2d3_pkgenv"
      via: "package-namespace env created at load"
      pattern: "new\\.env\\(parent = emptyenv\\(\\)\\)"
    - from: "R/ir_utils.R"
      to: "to_rows(df, keep_aes)"
      via: "explicit keep_aes argument (no closure capture)"
      pattern: "to_rows <- function\\(df, keep_aes\\)"
---

<objective>
Lay the foundation for the Phase 13 refactor: create the 5 Wave 0 test stub files (per D-04 success criterion #2 and 13-VALIDATION.md Wave 0 list), introduce `R/zzz.R` with the package-internal warn-once env (`.gg2d3_pkgenv` per D-07/specifics), and lift the cross-cutting utilities (`%||%`, `to_rows` (inner version, with `keep_aes` lifted to an explicit argument per RESEARCH Pitfall 1), `dom`) into `R/ir_utils.R`. **No edits to `R/as_d3_ir.R` in this plan** — its inline closures still shadow the new top-level helpers, so behavior is unchanged. This plan is the safe, conflict-free foundation that all subsequent waves depend on.

Purpose: subsequent extractor plans (02–06) can `to_rows(df, keep_aes)`, `%||%`, `dom()`, and `calc_element_safe` without circular dependencies. Test stub files exist so Plan 02–06 can ADD assertions to them rather than create them.

Output: 5 new test files, `R/zzz.R`, `R/ir_utils.R`. Full test suite remains green.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/PROJECT.md
@.planning/ROADMAP.md
@.planning/STATE.md
@.planning/phases/13-internals-refactor/13-CONTEXT.md
@.planning/phases/13-internals-refactor/13-RESEARCH.md
@.planning/phases/13-internals-refactor/13-PATTERNS.md
@.planning/phases/13-internals-refactor/13-VALIDATION.md
@./CLAUDE.md
@R/as_d3_ir.R
@tests/testthat/test-ir.R

<interfaces>
<!-- Cross-extractor contracts established by this plan. Subsequent plans rely on these signatures verbatim. -->

From R/ir_utils.R (created in this plan):
```r
`%||%` <- function(x, y) if (is.null(x)) y else x

# `keep_aes` is now an EXPLICIT argument (lifted out of closure per Pitfall 1)
to_rows <- function(df, keep_aes) { ... }

dom <- function(v) { ... }
```

From R/zzz.R (created in this plan):
```r
.gg2d3_pkgenv <- new.env(parent = emptyenv())
.gg2d3_pkgenv$calc_element_warned <- FALSE

.gg2d3_reset_calc_element_warned <- function() { ... }
```
</interfaces>
</context>

<tasks>

<task type="auto" tdd="false">
  <name>Task 1: Create five Wave 0 test stub files</name>
  <files>tests/testthat/test-ir-scales.R, tests/testthat/test-ir-theme.R, tests/testthat/test-ir-layers.R, tests/testthat/test-ir-legends.R, tests/testthat/test-ir-facets.R</files>
  <read_first>
    - tests/testthat/test-ir.R (lines 1-30) — canonical testthat 3.0 style for this project: `library(ggplot2)` INSIDE each `test_that` block, no fixtures, real `ggplot_build`, built-in datasets only.
    - .planning/phases/13-internals-refactor/13-VALIDATION.md (Wave 0 Requirements section) — the 5 files listed are the exact targets.
    - .planning/phases/13-internals-refactor/13-PATTERNS.md (`Pattern F: testthat 3.0 test style` and the per-extractor `test-ir-theme.R` warn-once sketch).
    - .planning/codebase/TESTING.md (if present) — confirms `library(ggplot2)`-inside-block convention.
  </read_first>
  <action>
Create five new files. Each contains exactly one trivially-passing `test_that` block that establishes the file as a real testthat target so devtools::test() picks it up. Plans 02–06 will REPLACE these stubs with real assertions; Plan 07 verifies all five run real assertions.

Exact contents (use Write tool — do NOT use heredoc):

**tests/testthat/test-ir-scales.R**:
```r
# Wave 0 stub — assertions added by Plan 03 (R/ir_scales.R extraction)
test_that("test-ir-scales.R is wired into the testthat suite", {
  expect_true(TRUE)
})
```

**tests/testthat/test-ir-theme.R**:
```r
# Wave 0 stub — assertions added by Plan 02 (R/ir_theme.R + calc_element_safe extraction)
test_that("test-ir-theme.R is wired into the testthat suite", {
  expect_true(TRUE)
})
```

**tests/testthat/test-ir-layers.R**:
```r
# Wave 0 stub — assertions added by Plan 04 (R/ir_layers.R extraction)
test_that("test-ir-layers.R is wired into the testthat suite", {
  expect_true(TRUE)
})
```

**tests/testthat/test-ir-legends.R**:
```r
# Wave 0 stub — assertions added by Plan 05 (R/ir_legends.R extraction)
test_that("test-ir-legends.R is wired into the testthat suite", {
  expect_true(TRUE)
})
```

**tests/testthat/test-ir-facets.R**:
```r
# Wave 0 stub — assertions added by Plan 06 (R/ir_facets.R extraction)
test_that("test-ir-facets.R is wired into the testthat suite", {
  expect_true(TRUE)
})
```

Implements REFACTOR-01 success criterion #2 ("each extraction helper has its own dedicated test file in tests/testthat/") — file existence per D-04.
  </action>
  <verify>
    <automated>Rscript -e 'pkgload::load_all(); for (f in c("test-ir-scales","test-ir-theme","test-ir-layers","test-ir-legends","test-ir-facets")) testthat::test_file(file.path("tests/testthat", paste0(f, ".R")))'</automated>
  </verify>
  <acceptance_criteria>
    - `ls tests/testthat/test-ir-{scales,theme,layers,legends,facets}.R` lists all 5 files (zero "No such file").
    - `grep -l 'test_that' tests/testthat/test-ir-scales.R tests/testthat/test-ir-theme.R tests/testthat/test-ir-layers.R tests/testthat/test-ir-legends.R tests/testthat/test-ir-facets.R` prints all 5 paths.
    - The verify command exits 0 with 5 PASS lines (one per file).
  </acceptance_criteria>
  <done>All 5 stub test files exist, contain a `test_that(...)` block, and pass under testthat. The suite size grows by exactly 5 new test files; no existing test changes.</done>
</task>

<task type="auto" tdd="false">
  <name>Task 2: Create R/zzz.R with .gg2d3_pkgenv and reset hook; create R/ir_utils.R with %||%, to_rows, dom</name>
  <files>R/zzz.R, R/ir_utils.R</files>
  <read_first>
    - R/as_d3_ir.R lines 1-30 (sees `%||%` inline closure at L18, `keep_aes` defined at L20-24).
    - R/as_d3_ir.R lines 213-240 (the inner `to_rows` definition that handles `PANEL`, factor, POSIXct, Date, list-cols — this is the version to lift; the outer L27 version is dead code per RESEARCH Pitfall 3 [VERIFIED]).
    - R/as_d3_ir.R lines 467-475 (the `dom` helper).
    - .planning/phases/13-internals-refactor/13-PATTERNS.md (`R/ir_utils.R` and `R/zzz.R` sections — exact bodies to copy).
    - .planning/phases/13-internals-refactor/13-RESEARCH.md (Pitfall 1 — `keep_aes` MUST become an explicit argument; Pattern 2 — pkgenv shape).
    - R/d3_brush.R (any 1 file — to confirm flat `R/` file-per-concern conventions used elsewhere; no roxygen header needed at file scope for internal-only files).
  </read_first>
  <action>
**File 1 — Create `R/zzz.R`** (new file, top-level package state). Exact content:

```r
# Package-internal state. Created at package load.
# Tracks one-shot conditions that should not spam the user across a session.
.gg2d3_pkgenv <- new.env(parent = emptyenv())
.gg2d3_pkgenv$calc_element_warned <- FALSE

#' Reset the once-per-session warn flag for `calc_element_safe`.
#'
#' Test-only hook so `tests/testthat/test-ir-theme.R` can exercise both the
#' "first call warns" and "subsequent calls are silent" branches deterministically.
#' Not exported.
#'
#' @keywords internal
#' @noRd
.gg2d3_reset_calc_element_warned <- function() {
  .gg2d3_pkgenv$calc_element_warned <- FALSE
  invisible(NULL)
}
```

Per CONTEXT specifics ("package-internal flag e.g. `.gg2d3_pkgenv$calc_element_warned <- TRUE`") and RESEARCH Open Question 3 (test-only reset hook). The file does NOT contain `.onLoad`; the `<-` at top level runs at package install/load time which is sufficient.

**File 2 — Create `R/ir_utils.R`** (new file, cross-cutting helpers). Lift verbatim from `R/as_d3_ir.R`:
1. The `%||%` operator (currently `R/as_d3_ir.R:18`).
2. The INNER `to_rows` (currently `R/as_d3_ir.R:213-236` — the one inside the `layers <- lapply(...)` block that handles `PANEL`, factor, POSIXct, Date, list-cols). **Critical change:** add `keep_aes` as an explicit second argument (per Pitfall 1) — current code captures it from the enclosing scope; this caller-provides version must work standalone.
3. `dom` (currently `R/as_d3_ir.R:467-475`).

Exact content:

```r
# Cross-cutting utilities used by ir_scales.R, ir_theme.R, ir_layers.R,
# ir_legends.R, ir_facets.R, and as_d3_ir.R. All internal (no @export).

#' @keywords internal
#' @noRd
`%||%` <- function(x, y) if (is.null(x)) y else x

#' Row-ize a data.frame into a list of named scalar lists, applying the
#' established type coercions for downstream JSON serialization.
#'
#' `keep_aes` is an explicit argument (lifted out of the closure scope it
#' captured in v1.0 `as_d3_ir.R`). Callers MUST pass the desired aesthetic
#' vector — the orchestrator's `keep_aes` (currently `as_d3_ir.R` lines 20-24)
#' is the canonical value for layer extraction.
#'
#' @keywords internal
#' @noRd
to_rows <- function(df, keep_aes) {
  if (is.null(df) || !nrow(df)) return(list())
  df <- df[, intersect(keep_aes, names(df)), drop = FALSE]
  col_names <- names(df)
  df[] <- lapply(col_names, function(colname) {
    col <- df[[colname]]
    if (colname == "PANEL") as.integer(col)
    else if (is.factor(col)) as.character(col)
    else if (inherits(col, c("POSIXct", "POSIXt"))) as.numeric(col) * 1000
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

#' Domain helper used by scales / facets: numeric → finite range, otherwise unique.
#'
#' @keywords internal
#' @noRd
dom <- function(v) {
  if (is.null(v) || length(v) == 0) return(numeric(0))
  if (is.numeric(v)) range(v, finite = TRUE) else unique(v)
}
```

**Do NOT touch `R/as_d3_ir.R` in this plan.** The orchestrator's inline `%||%`, `to_rows`, `dom` closures still shadow these new top-level definitions — behavior is preserved. Plan 02 begins removing them as extractors take over.

After writing both files, run `Rscript -e 'devtools::document()'` (or `pkgload::load_all()` if devtools unavailable) — NAMESPACE diff MUST be empty (zero new exports per D-04 + Anti-Pattern note).
  </action>
  <verify>
    <automated>Rscript -e 'pkgload::load_all(); stopifnot(exists(".gg2d3_pkgenv"), exists("to_rows"), exists("dom")); stopifnot(isFALSE(.gg2d3_pkgenv$calc_element_warned)); .gg2d3_reset_calc_element_warned(); td <- data.frame(PANEL = 1L, x = 1, y = 2); r <- to_rows(td, c("PANEL","x","y")); stopifnot(length(r) == 1L, identical(r[[1]]$x, 1)); stopifnot(identical(dom(c(1, 2, NA, 3)), c(1, 3))); cat("OK\n")' && Rscript -e 'devtools::test()'</automated>
  </verify>
  <acceptance_criteria>
    - `test -f R/zzz.R && test -f R/ir_utils.R` exits 0.
    - `grep -c '\.gg2d3_pkgenv' R/zzz.R` ≥ 2 (env creation + reset hook reference).
    - `grep -E '^to_rows <- function\(df, keep_aes\)' R/ir_utils.R` matches exactly one line (signature with explicit `keep_aes` arg).
    - `grep -E '^`%\|\|`%' R/ir_utils.R` matches exactly one line.
    - `grep -E '^dom <- function' R/ir_utils.R` matches exactly one line.
    - `grep -c '@export' R/ir_utils.R R/zzz.R` returns 0:0 (no exports added).
    - `git diff NAMESPACE` is empty after `devtools::document()`.
    - The full `devtools::test()` run is green (no regressions, since `as_d3_ir.R` is unchanged).
  </acceptance_criteria>
  <done>R/zzz.R and R/ir_utils.R exist with the exact bodies above. .gg2d3_pkgenv is reachable from the package namespace. to_rows accepts keep_aes as an explicit argument. NAMESPACE is unchanged. devtools::test() passes.</done>
</task>

</tasks>

<verification>
1. `ls tests/testthat/test-ir-{scales,theme,layers,legends,facets}.R` — all 5 files exist.
2. `ls R/zzz.R R/ir_utils.R` — both exist.
3. `Rscript -e 'devtools::test()'` — green (zero new failures vs pre-plan baseline).
4. `git diff NAMESPACE` after `devtools::document()` — empty diff (no new exports).
5. `Rscript -e 'pkgload::load_all(); exists(".gg2d3_pkgenv")'` — TRUE.
</verification>

<success_criteria>
- 5 stub test files exist and run as testthat targets.
- R/zzz.R defines `.gg2d3_pkgenv` (an environment with `calc_element_warned = FALSE`) and `.gg2d3_reset_calc_element_warned()`.
- R/ir_utils.R defines top-level `%||%`, `to_rows(df, keep_aes)` (explicit keep_aes arg), `dom`.
- Zero new `@export` directives; NAMESPACE unchanged.
- Full `devtools::test()` is green — no regressions because R/as_d3_ir.R was not modified.
</success_criteria>

<output>
After completion, create `.planning/phases/13-internals-refactor/13-01-SUMMARY.md` per the summary template, listing the 7 files created and confirming NAMESPACE is unchanged.
</output>
