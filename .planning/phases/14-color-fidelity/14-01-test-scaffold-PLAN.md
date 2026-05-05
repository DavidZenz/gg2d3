---
phase: 14
plan: 01
type: execute
wave: 0
depends_on: []
files_modified:
  - tests/testthat/test-color-fidelity.R
  - tests/testthat/helper-color.R
autonomous: true
requirements: [COLOR-01, COLOR-02]
tags: [r-package, ggplot2, color, test-scaffold, snapshot]

must_haves:
  truths:
    - "tests/testthat/test-color-fidelity.R exists and is loaded by testthat::test_dir()"
    - "tests/testthat/helper-color.R exposes helpers for ggplot_build/IR/scale extraction"
    - "Suite runs green (skip-pending tests count as skips, not failures)"
    - "_snaps/color/ directory will be auto-created on first snapshot accept"
  artifacts:
    - path: "tests/testthat/test-color-fidelity.R"
      provides: "Phase 14 snapshot harness (skip-pending placeholders for COLOR-01/COLOR-02 corpus)"
      contains: "test_that"
    - path: "tests/testthat/helper-color.R"
      provides: "Reusable extraction helpers for build colours, IR colours, guide colours"
      contains: "build_colours"
  key_links:
    - from: "tests/testthat/test-color-fidelity.R"
      to: "tests/testthat/helper-color.R"
      via: "testthat auto-sources helper-*.R before test files"
      pattern: "build_colours|ir_layer_colours|guide_colours"
---

<objective>
Stand up the Phase 14 test scaffold so all subsequent plans have a place to drop assertions and snapshots. No production code changes.

Purpose: Wave 0 per VALIDATION.md. Every later plan's `<verify>` step targets `tests/testthat/test-color-fidelity.R`; that file must exist and be runnable from task 1 onward.

Output:
- `tests/testthat/test-color-fidelity.R` — empty test_that blocks marked `skip("pending plan 14-XX")` for each requirement row in VALIDATION.md.
- `tests/testthat/helper-color.R` — extraction helpers reused by every later plan and by the snapshot corpus (plan 14-07).
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<inputs>
@.planning/phases/14-color-fidelity/14-CONTEXT.md
@.planning/phases/14-color-fidelity/14-RESEARCH.md
@.planning/phases/14-color-fidelity/14-VALIDATION.md
@./CLAUDE.md
@tests/testthat/test-ir-legends.R
@tests/testthat/test-legends.R
@R/ir_legends.R
@R/ir_layers.R
</inputs>

<outputs>
- `tests/testthat/helper-color.R` — new file, ~40-60 lines exporting `build_colours()`, `build_fills()`, `ir_layer_colours()`, `ir_layer_fills()`, `guide_by_aes()`, `scale_by_aes()`.
- `tests/testthat/test-color-fidelity.R` — new file, ~80-120 lines of skip-pending test_that blocks (one per row in VALIDATION.md per-task verification map).
</outputs>

<tasks>

<task type="auto">
  <name>Task 1: Write helper-color.R extraction utilities</name>
  <files>tests/testthat/helper-color.R</files>
  <action>
Create `tests/testthat/helper-color.R`. testthat auto-sources `helper-*.R` before any test file, so these helpers will be in scope everywhere.

Define the following functions. Keep each under 10 lines; no error-swallowing tryCatch — failures should bubble up so tests reveal real defects.

```r
# Phase 14 colour-fidelity test helpers.
# See .planning/phases/14-color-fidelity/14-RESEARCH.md "Pipeline map" for
# why these are the right extraction points.

# Resolved per-row colour column from ggplot_build (source of truth, D-04).
build_colours <- function(p, layer_index = 1L) {
  b <- ggplot2::ggplot_build(p)
  b$data[[layer_index]]$colour
}

build_fills <- function(p, layer_index = 1L) {
  b <- ggplot2::ggplot_build(p)
  b$data[[layer_index]]$fill
}

# Per-row colours/fills as carried in the IR layer data.
ir_layer_colours <- function(p, layer_index = 1L) {
  ir <- as_d3_ir(p)
  vapply(ir$layers[[layer_index]]$data, function(row) row$colour %||% NA_character_, character(1))
}

ir_layer_fills <- function(p, layer_index = 1L) {
  ir <- as_d3_ir(p)
  vapply(ir$layers[[layer_index]]$data, function(row) row$fill %||% NA_character_, character(1))
}

# Find the IR guide for a given aesthetic.
guide_by_aes <- function(p, aes_name) {
  ir <- as_d3_ir(p)
  for (g in ir$guides) {
    if (identical(g$aesthetic, aes_name)) return(g)
    if (is.list(g$aesthetics) && aes_name %in% unlist(g$aesthetics)) return(g)
  }
  NULL
}

# Extract the ggplot2 scale object for a given aesthetic from a built plot.
scale_by_aes <- function(p, aes_name) {
  b <- ggplot2::ggplot_build(p)
  b$plot$scales$get_scales(aes_name)
}

# Reference legend hex from the ggplot2 scale object — what the colorbar
# stops *should* be (D-04).
scale_reference_breaks <- function(scale_obj) {
  limits <- scale_obj$get_limits()
  scale_obj$get_breaks(limits)
}

scale_reference_labels <- function(scale_obj, breaks = NULL) {
  if (is.null(breaks)) breaks <- scale_reference_breaks(scale_obj)
  scale_obj$get_labels(breaks)
}

`%||%` <- function(a, b) if (is.null(a)) b else a
```

Notes:
- `as_d3_ir` and `%||%` are in the package namespace under `pkgload::load_all(".")`. Define a local `%||%` anyway so helpers work in fresh sessions.
- Do NOT export these via NAMESPACE — `helper-*.R` lives only in `tests/testthat/`.
  </action>
  <verify>
    <automated>Rscript -e 'pkgload::load_all(".",quiet=TRUE); testthat::test_file("tests/testthat/test-color-fidelity.R")' || true</automated>
  </verify>
  <done>helper-color.R exists with the seven functions above; sourcing it under pkgload::load_all yields no errors.</done>
</task>

<task type="auto">
  <name>Task 2: Write test-color-fidelity.R skip-pending corpus</name>
  <files>tests/testthat/test-color-fidelity.R</files>
  <action>
Create `tests/testthat/test-color-fidelity.R`. Every test_that block calls `skip("pending plan 14-XX")` as the first line so the file is harmless until later plans flesh it out. The names and structure mirror the VALIDATION.md per-task verification map exactly — later plans flip the `skip()` to real assertions.

Required block names (one test_that per row; each starts with `library(ggplot2); skip("pending plan 14-XX")`):

```
# COLOR-01 — per-row hex parity (plan 14-07 fills these in)
test_that("viridis_c per-row mark hex equals ggplot_build", { skip("pending plan 14-07") })
test_that("viridis_d per-row mark hex equals ggplot_build (8-hex RGBA)", { skip("pending plan 14-07") })
test_that("brewer (discrete fill) per-row hex parity", { skip("pending plan 14-07") })
test_that("distiller per-row hex parity", { skip("pending plan 14-07") })
test_that("scale_color_manual (named) per-row hex parity", { skip("pending plan 14-07") })
test_that("scale_color_manual (unnamed) per-row hex parity", { skip("pending plan 14-07") })
test_that("scale_fill_manual per-row hex parity", { skip("pending plan 14-07") })
test_that("scale_color_steps per-row hex parity", { skip("pending plan 14-07") })

# COLOR-02 — colorbar IR & rendering (plans 14-03..14-06 fill these in)
test_that("viridis_c emits guide.type colorbar with >=30 stops", { skip("pending plan 14-03") })
test_that("distiller emits guide.type colorbar", { skip("pending plan 14-03") })
test_that("scale_color_steps emits guide.type colorbar with is_steps TRUE", { skip("pending plan 14-03") })
test_that("colorbar IR carries breaks labels na.value domain is_continuous", { skip("pending plan 14-05") })
test_that("colorbar IR orientation defaults vertical and flips horizontal for legend.position bottom", { skip("pending plan 14-05") })
test_that("renderColorbar tick logic uses breaks (not first/last keys)", { skip("pending plan 14-06") })
test_that("renderColorbar branches on guide.orientation for horizontal layout", { skip("pending plan 14-06") })

# Edge cases (plan 14-07 corpus snapshots)
test_that("D-11 NA colour row renders as #7F7F7F (grey50)", { skip("pending plan 14-07") })
test_that("D-12 dual color+fill produces 2 guides without merge", { skip("pending plan 14-07") })
test_that("D-13 RGBA hex round-trips identically", { skip("pending plan 14-07") })
test_that("D-14 manual out-of-range factor maps to na.value", { skip("pending plan 14-07") })

# JS regex static check (plan 14-02)
test_that("isHexColor accepts 4 and 8 digit hex (constants.js regex)", { skip("pending plan 14-02") })
```

Add a leading comment block linking each test to its requirement ID and source artifact line in VALIDATION.md. End the file with no trailing test_that — the file should be ~120 lines, mostly comments + skip-pending stubs.

Do NOT add any real assertions in this plan. Later plans replace `skip(...)` with actual test bodies.
  </action>
  <verify>
    <automated>Rscript -e 'pkgload::load_all(".",quiet=TRUE); res <- testthat::test_file("tests/testthat/test-color-fidelity.R", reporter="silent"); stopifnot(sum(vapply(res, function(r) length(r$results), integer(1))) > 0)'</automated>
  </verify>
  <done>test-color-fidelity.R exists with ~20 skip-pending test_that blocks named per VALIDATION.md; running it under testthat reports skips and zero failures.</done>
</task>

<task type="auto">
  <name>Task 3: Confirm full suite green; commit scaffold</name>
  <files></files>
  <action>
Run the full suite to confirm the scaffold doesn't regress anything (the 8 pre-existing `coord_fixed`/`coord_trans` baseline FAILs from Phase 13 must remain unchanged — no new failures).

```bash
Rscript -e 'pkgload::load_all(".",quiet=TRUE); testthat::test_dir("tests/testthat")'
```

Verify the new file shows up as skipped, not failed:

```bash
Rscript -e 'pkgload::load_all(".",quiet=TRUE); res <- testthat::test_file("tests/testthat/test-color-fidelity.R", reporter="silent"); cat("skipped:", sum(vapply(res, function(r) sum(vapply(r$results, function(x) inherits(x, "expectation_skip"), logical(1))), integer(1))), "\n")'
```

Commit:
```
git add tests/testthat/test-color-fidelity.R tests/testthat/helper-color.R
git commit -m "test(14-01): scaffold color-fidelity test corpus and helpers"
```
  </action>
  <verify>
    <automated>Rscript -e 'pkgload::load_all(".",quiet=TRUE); testthat::test_dir("tests/testthat")'</automated>
  </verify>
  <done>Full suite green relative to phase-13 baseline (8 pre-existing FAILs unchanged, 0 new FAILs); scaffold committed.</done>
</task>

</tasks>

<exit_criteria>
- `tests/testthat/test-color-fidelity.R` and `tests/testthat/helper-color.R` exist and are committed.
- The new file produces ~20 skipped tests, 0 failures.
- Full suite shows no regression vs phase-13 baseline.
- Helpers `build_colours`, `build_fills`, `ir_layer_colours`, `ir_layer_fills`, `guide_by_aes`, `scale_by_aes`, `scale_reference_breaks`, `scale_reference_labels` are callable from any test file.
</exit_criteria>

<threat_model>
No threat surface — package internals only. Test scaffold; no external input, no auth, no network.
</threat_model>

<output>
After completion, create `.planning/phases/14-color-fidelity/14-01-SUMMARY.md` listing files created and confirming the suite is green.
</output>
