---
phase: 14
plan: 07
type: execute
wave: 5
depends_on: ["14-02", "14-03", "14-04", "14-05", "14-06"]
files_modified:
  - tests/testthat/test-color-fidelity.R
  - tests/testthat/_snaps/color/
autonomous: false
requirements: [COLOR-01, COLOR-02]
tags: [r-package, ggplot2, color, snapshot-corpus, edge-cases]

must_haves:
  truths:
    - "8 base snapshots exist for geom_point × {viridis_c, viridis_d, brewer, distiller, manual_named, manual_unnamed, fill_manual, steps}"
    - "4 edge-case snapshots cover D-11 (NA), D-12 (dual color+fill), D-13 (RGBA), D-14 (out-of-range manual)"
    - "Each snapshot asserts per-row hex equals ggplot_build()'s resolved column (D-04)"
    - "Each colorbar snapshot asserts legend_hex equals scale_obj$map(scale_obj$get_breaks())"
    - "Discrete legend regression: tests/testthat/test-legends.R remains green"
    - "Snapshot files committed under tests/testthat/_snaps/color/"
    - "Manual checkpoint covers horizontal colorbar via theme(legend.position='bottom') (D-10)"
  artifacts:
    - path: "tests/testthat/test-color-fidelity.R"
      provides: "12 real assertions replacing skip-pending stubs"
      contains: "expect_snapshot_value"
    - path: "tests/testthat/_snaps/color/"
      provides: "JSON snapshots per corpus plot"
      contains: ".json"
  key_links:
    - from: "tests/testthat/test-color-fidelity.R"
      to: "tests/testthat/helper-color.R"
      via: "build_colours / ir_layer_colours / guide_by_aes / scale_by_aes"
      pattern: "build_colours|ir_layer_colours|guide_by_aes"
    - from: "tests/testthat/test-color-fidelity.R"
      to: "ggplot_build()"
      via: "source-of-truth comparison per D-04"
      pattern: "ggplot_build"
---

<objective>
Populate the snapshot corpus that closes COLOR-01 and COLOR-02. By the time this plan runs, plans 14-02..14-06 have all R/JS production-code changes in. This plan only writes tests and accepts snapshot baselines.

Per D-15/D-16/D-17: snapshots live at `tests/testthat/_snaps/color/<plot-id>.json` and contain `{expected_hex_per_row, expected_legend_hex}`. Comparisons are char-for-char (D-03). The harness walks the IR (not the rendered DOM) per research R2 — JS path for valid hex is provably identity (Pitfall 6), so IR-vs-`ggplot_build` is sufficient for the per-row contract.

ROADMAP success criterion 2 explicitly names `scale_fill_manual` as well as `scale_color_manual`; the base corpus therefore includes a dedicated `scale_fill_manual` snapshot in addition to the named/unnamed `scale_color_manual` snapshots — covering the literal text of the requirement.

Three checkpoints in this plan:
- **Checkpoint A (after writing tests, before snapshot accept):** human reviews the snapshot diff to confirm the captured hex strings look right (e.g., that `#440154FF` is what viridis_d should produce, not a regression).
- **Checkpoint B (manual visual verification of vertical colorbar):** human renders `test_output/phase14/colorbar-smooth.html` and `test_output/phase14/steps-bar.html` and confirms no banding on smooth and clean band edges on banded.
- **Checkpoint C (manual visual verification of horizontal colorbar — D-10):** human renders `test_output/phase14/colorbar-horizontal.html` (viridis_c with `theme(legend.position="bottom")`) and confirms a horizontal gradient bar with ticks below and the title above.

This plan is `autonomous: false` because of those checkpoints.

Output:
- 12 test_that blocks in `tests/testthat/test-color-fidelity.R` flipped from skip-pending to real assertions (8 base + 4 edge-case).
- Snapshot files in `tests/testthat/_snaps/color/`.
- 3 manual verification HTML artifacts in `test_output/phase14/` (gitignored).
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<inputs>
@.planning/phases/14-color-fidelity/14-CONTEXT.md
@.planning/phases/14-color-fidelity/14-RESEARCH.md
@.planning/phases/14-color-fidelity/14-VALIDATION.md
@tests/testthat/helper-color.R
@tests/testthat/test-color-fidelity.R
@tests/testthat/test-legends.R
@R/ir_legends.R
@R/ir_layers.R
</inputs>

<outputs>
- `tests/testthat/test-color-fidelity.R` — replace 12 skip-pending blocks with real assertions (~280 lines net).
- `tests/testthat/_snaps/color/*.json` — 12 snapshot files (auto-created by `testthat::expect_snapshot_value`).
- `test_output/phase14/colorbar-smooth.html`, `test_output/phase14/steps-bar.html`, `test_output/phase14/colorbar-horizontal.html` — generated for manual visual checkpoints.
</outputs>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: Replace 8 base-corpus skip-pending blocks with real assertions</name>
  <files>tests/testthat/test-color-fidelity.R</files>
  <behavior>
    For each scale variant in {viridis_c, viridis_d, brewer-discrete, distiller, manual_named, manual_unnamed, fill_manual, steps}:
    - Build a fixed-seed geom_point plot with mtcars (or a small reproducible data frame).
    - Assert IR per-row colours/fills `identical()` to `ggplot_build()$data[[1]]$colour|fill`.
    - For colorbar guides: assert `g$colors` length, plus `expect_snapshot_value(list(per_row = ..., legend = ...), style = "json2")`.
    - For discrete legends: assert key colours match `scale_obj$map(scale_obj$get_breaks())`.
  </behavior>
  <action>
For each of the 8 base-corpus blocks in `tests/testthat/test-color-fidelity.R`, replace the body. Pattern (showing viridis_c; replicate for each):

```r
test_that("viridis_c per-row mark hex equals ggplot_build", {
  library(ggplot2)
  set.seed(14)
  df <- data.frame(x = 1:10, y = 1:10, v = seq(1, 100, length.out = 10))
  p <- ggplot(df, aes(x, y, colour = v)) + geom_point() + scale_color_viridis_c()

  build_col <- build_colours(p)
  ir_col    <- ir_layer_colours(p)
  expect_identical(ir_col, build_col)  # D-03 char-for-char, D-04 source of truth

  g <- guide_by_aes(p, "colour")
  expect_equal(g$type, "colorbar")
  expect_gte(length(g$colors), 30L)

  scale_obj <- scale_by_aes(p, "colour")
  ref_legend <- scale_obj$map(scale_obj$get_breaks(scale_obj$get_limits()))
  snap <- list(
    per_row     = ir_col,
    legend_hex  = unname(ref_legend),
    breaks      = unname(g$breaks),
    labels      = g$labels,
    is_steps    = g$is_steps
  )
  expect_snapshot_value(snap, style = "json2")
})
```

Repeat the pattern, varying the scale call:

| Block | Scale | Aesthetic | Notes |
|---|---|---|---|
| `viridis_c per-row mark hex` | `scale_color_viridis_c()` | colour | smooth colorbar |
| `viridis_d per-row mark hex (8-hex RGBA)` | `scale_color_viridis_d()` with `colour = factor(...)` | colour | discrete legend; assert hex strings include `#......FF` 8-hex |
| `brewer (discrete fill) per-row hex parity` | `scale_fill_brewer(palette="Set1")`, `colour = factor(g)` ≤9 levels | fill | discrete legend (research Pitfall 10) |
| `distiller per-row hex parity` | `scale_color_distiller(palette="Spectral")`, continuous v | colour | continuous colorbar |
| `scale_color_manual (named) per-row hex parity` | `scale_color_manual(values=c(a="#FF0000",b="#00FF00",c="#0000FF"))` | colour | discrete |
| `scale_color_manual (unnamed) per-row hex parity` | `scale_color_manual(values=c("#FF0000","#00FF00","#0000FF"))` | colour | discrete |
| `scale_fill_manual per-row hex parity` | `scale_fill_manual(values=c(a="#1f77b4",b="#ff7f0e",c="#2ca02c"))` with `geom_point(shape=21)` and `aes(fill=g)` | fill | discrete; covers ROADMAP literal `scale_fill_manual` |
| `scale_color_steps per-row hex parity` | `scale_color_steps()`, continuous v | colour | banded colorbar; assert `g$is_steps == TRUE` and `length(g$bin_colors) >= 1` |

For the **`scale_fill_manual`** block specifically (uses fill helpers):

```r
test_that("scale_fill_manual per-row hex parity", {
  library(ggplot2)
  set.seed(14)
  df <- data.frame(x = 1:9, y = 1:9, g = factor(rep(c("a","b","c"), each = 3)))
  p <- ggplot(df, aes(x, y, fill = g)) + geom_point(shape = 21, size = 4) +
    scale_fill_manual(values = c(a = "#1f77b4", b = "#ff7f0e", c = "#2ca02c"))

  build_fill <- build_fills(p)
  ir_fill    <- ir_layer_fills(p)
  expect_identical(ir_fill, build_fill)

  g <- guide_by_aes(p, "fill")
  expect_false(is.null(g))
  expect_equal(g$type, "legend")  # discrete

  scale_obj <- scale_by_aes(p, "fill")
  ref_legend <- scale_obj$map(scale_obj$get_breaks(scale_obj$get_limits()))
  snap <- list(
    per_row    = ir_fill,
    legend_hex = unname(ref_legend),
    is_steps   = g$is_steps
  )
  expect_snapshot_value(snap, style = "json2")
})
```

Each block does the same three things:
1. Build plot with deterministic data.
2. Compare `ir_layer_colours(p)` (or `ir_layer_fills(p)` for fill aesthetic) to `build_colours(p)` (or `build_fills(p)`) via `expect_identical` (D-03).
3. `expect_snapshot_value(snap, style = "json2")` capturing the canonical fields.

Run the suite. Snapshots will be created on first run and reported as "new snapshot — accept manually".

After all 8 blocks pass per-row identity (the snapshot accept happens in Task 4), commit:
```
git add tests/testthat/test-color-fidelity.R
git commit -m "test(14-07): base-corpus per-row hex parity for 8 scale variants"
```
  </action>
  <verify>
    <automated>Rscript -e 'pkgload::load_all(".",quiet=TRUE); testthat::test_file("tests/testthat/test-color-fidelity.R")'</automated>
  </verify>
  <done>8 base-corpus blocks contain real per-row identity assertions plus snapshot calls; per-row identity passes for all 8 (including scale_fill_manual); snapshots are pending acceptance (new).</done>
</task>

<task type="auto" tdd="true">
  <name>Task 2: Replace 4 edge-case skip-pending blocks (D-11/D-12/D-13/D-14)</name>
  <files>tests/testthat/test-color-fidelity.R</files>
  <behavior>
    - D-11: NA in colour column → IR carries `"grey50"` literal; `convertColor("grey50")` reference is "#7F7F7F" (asserted after a JS-equivalent helper or via the snapshot).
    - D-12: aes(colour=, fill=) with both scales mapped → IR has 2 distinct guides, no merge.
    - D-13: aes(alpha=) with viridis_d → 8-hex RGBA round-trips identically through IR.
    - D-14: scale_color_manual with an out-of-range factor level → row maps to `"grey50"` literal.
  </behavior>
  <action>
Replace each of the 4 skip-pending blocks. Templates:

**D-11 (NA):**
```r
test_that("D-11 NA colour row renders as #7F7F7F (grey50)", {
  library(ggplot2)
  df <- data.frame(x = 1:5, y = 1:5, v = c(1, 2, NA, 4, 5))
  p <- ggplot(df, aes(x, y, colour = v)) + geom_point() + scale_color_viridis_c()
  build_col <- build_colours(p)
  ir_col    <- ir_layer_colours(p)
  expect_identical(ir_col, build_col)
  expect_true("grey50" %in% ir_col || any(grepl("^#7F7F7F$", ir_col, ignore.case = TRUE)))
  expect_snapshot_value(list(per_row = ir_col), style = "json2")
})
```

**D-12 (dual color+fill):**
```r
test_that("D-12 dual color+fill produces 2 guides without merge", {
  library(ggplot2)
  df <- data.frame(x = 1:9, y = 1:9, c = factor(rep(c("a","b","c"), each=3)), f = 1:9)
  p <- ggplot(df, aes(x, y, colour = c, fill = f)) + geom_point(shape = 21) +
    scale_color_brewer(palette = "Set1") + scale_fill_viridis_c()
  ir <- as_d3_ir(p)
  aes_seen <- vapply(ir$guides, function(g) g$aesthetic, character(1))
  expect_true("colour" %in% aes_seen)
  expect_true("fill"   %in% aes_seen)
  # No merge: 2 distinct guide entries.
  expect_gte(sum(aes_seen %in% c("colour","fill")), 2L)
  expect_snapshot_value(list(
    per_row_colour = ir_layer_colours(p),
    per_row_fill   = ir_layer_fills(p),
    aes_seen       = aes_seen
  ), style = "json2")
})
```

**D-13 (RGBA round-trip):**
```r
test_that("D-13 RGBA hex round-trips identically", {
  library(ggplot2)
  df <- data.frame(x = 1:5, y = 1:5, v = factor(letters[1:5]))
  p <- ggplot(df, aes(x, y, colour = v)) + geom_point() + scale_color_viridis_d()
  build_col <- build_colours(p)
  ir_col    <- ir_layer_colours(p)
  # ggplot2 emits 8-hex RGBA for viridis_d; round-trip must be char-for-char.
  expect_identical(ir_col, build_col)
  expect_true(all(grepl("^#[0-9A-Fa-f]{8}$", build_col)))
  expect_snapshot_value(list(per_row = ir_col), style = "json2")
})
```

**D-14 (out-of-range manual):**
```r
test_that("D-14 manual out-of-range factor maps to na.value", {
  library(ggplot2)
  df <- data.frame(x = 1:3, y = 1:3, g = factor(c("a","b","x"), levels = c("a","b","x")))
  p <- suppressWarnings(
    ggplot(df, aes(x, y, colour = g)) + geom_point() +
      scale_color_manual(values = c(a = "#FF0000", b = "#00FF00"))
  )
  build_col <- build_colours(p)
  ir_col    <- ir_layer_colours(p)
  expect_identical(ir_col, build_col)
  # The "x" level has no value → ggplot2 emits NA → resolves to grey50 / NA literal.
  expect_true(any(is.na(build_col) | grepl("grey50|^#7F7F7F$", build_col, ignore.case = TRUE)))
  expect_snapshot_value(list(per_row = ir_col), style = "json2")
})
```

Run the suite. All 4 edge-case blocks should pass per-row identity. Snapshots queued for accept.

Commit:
```
git add tests/testthat/test-color-fidelity.R
git commit -m "test(14-07): edge-case corpus D-11/D-12/D-13/D-14"
```
  </action>
  <verify>
    <automated>Rscript -e 'pkgload::load_all(".",quiet=TRUE); testthat::test_file("tests/testthat/test-color-fidelity.R")'</automated>
  </verify>
  <done>4 edge-case blocks contain real assertions; per-row identity passes for all 4; snapshots pending accept.</done>
</task>

<task type="checkpoint:human-verify" gate="blocking">
  <name>Task 3: Checkpoint A — review snapshot diff before accepting</name>
  <what-built>
    12 new snapshot files staged at `tests/testthat/_snaps/color/*.json`. Per-row hex strings come from `ggplot_build()` which is the source of truth (D-04). Reviewer is asked to confirm the captured strings are sane: 6-hex for viridis_c/brewer/distiller/manual; 8-hex (`#......FF`) for viridis_d; `grey50` or `#7F7F7F` for NA / out-of-range manual; and that `scale_fill_manual` snapshot has the three named hex values from the test (`#1f77b4`, `#ff7f0e`, `#2ca02c`) verbatim.
  </what-built>
  <how-to-verify>
    1. `Rscript -e 'pkgload::load_all(".",quiet=TRUE); testthat::test_file("tests/testthat/test-color-fidelity.R")'` — observe the "new snapshot" reports.
    2. `ls tests/testthat/_snaps/color/` — confirm 12 JSON files.
    3. `cat` a couple of them (e.g., `viridis-c-per-row-mark-hex-equals-ggplot-build.json`, `scale-fill-manual-per-row-hex-parity.json`, and `d-13-rgba-hex-round-trips-identically.json`).
    4. Confirm:
       - viridis_c snapshot has 10 entries of the form `#XXXXXX` (lowercase 6-hex).
       - viridis_d snapshot has 5 entries of the form `#XXXXXXFF` (8-hex with trailing `FF`).
       - D-11 snapshot has at least one `grey50` or `#7F7F7F`.
       - D-12 snapshot has both `aes_seen` containing both `colour` and `fill`.
       - scale_fill_manual snapshot contains `#1f77b4`, `#ff7f0e`, `#2ca02c` (or their resolved canonical forms).
    5. If anything looks wrong, do NOT accept — report back and the planner will add a regression task. If correct, proceed.
  </how-to-verify>
  <resume-signal>Type "approved" to proceed to snapshot accept, or describe any anomalies found.</resume-signal>
</task>

<task type="auto">
  <name>Task 4: Accept snapshots and commit baseline</name>
  <files>tests/testthat/_snaps/color/</files>
  <action>
After Checkpoint A is approved:

```bash
Rscript -e 'pkgload::load_all(".",quiet=TRUE); testthat::snapshot_accept("color-fidelity")'
```

Or, if `snapshot_accept` argument matching is unreliable, accept all phase-14 snapshots:
```bash
Rscript -e 'pkgload::load_all(".",quiet=TRUE); testthat::snapshot_accept()'
```

Verify:
```bash
ls tests/testthat/_snaps/color/ | wc -l   # → 12 (or however many distinct snapshot files were generated)
```

Re-run the suite — all 12 corpus tests now PASS (no longer "new snapshot" notices):
```bash
Rscript -e 'pkgload::load_all(".",quiet=TRUE); testthat::test_dir("tests/testthat")'
```

Confirm phase-13 baseline FAILs unchanged.

Commit:
```
git add tests/testthat/_snaps/color/
git commit -m "test(14-07): accept color-fidelity snapshot baseline"
```
  </action>
  <verify>
    <automated>Rscript -e 'pkgload::load_all(".",quiet=TRUE); testthat::test_dir("tests/testthat")'</automated>
  </verify>
  <done>12 snapshot JSONs committed under tests/testthat/_snaps/color/; full suite green vs phase-13 baseline.</done>
</task>

<task type="auto">
  <name>Task 5: Render manual-verification HTML artifacts (vertical + horizontal + steps)</name>
  <files>test_output/phase14/colorbar-smooth.html, test_output/phase14/steps-bar.html, test_output/phase14/colorbar-horizontal.html</files>
  <action>
Per VALIDATION.md "Manual-Only Verifications" and D-10 horizontal coverage: render three HTML files for visual confirmation that gradients look right (snapshot tests can't judge perceptual banding or layout correctness).

```r
dir.create("test_output/phase14", recursive = TRUE, showWarnings = FALSE)

library(gg2d3)
library(ggplot2)

p_smooth <- ggplot(mtcars, aes(wt, mpg, colour = hp)) + geom_point() +
  scale_color_viridis_c() + ggtitle("smooth colorbar (viridis_c, vertical)")
htmlwidgets::saveWidget(gg2d3(p_smooth), "test_output/phase14/colorbar-smooth.html", selfcontained = TRUE)

p_steps <- ggplot(mtcars, aes(wt, mpg, colour = hp)) + geom_point() +
  scale_color_steps() + ggtitle("banded colorbar (scale_color_steps, vertical)")
htmlwidgets::saveWidget(gg2d3(p_steps), "test_output/phase14/steps-bar.html", selfcontained = TRUE)

p_horiz <- ggplot(mtcars, aes(wt, mpg, colour = hp)) + geom_point() +
  scale_color_viridis_c() +
  theme(legend.position = "bottom") +
  ggtitle("horizontal colorbar (viridis_c, legend.position='bottom') — D-10")
htmlwidgets::saveWidget(gg2d3(p_horiz), "test_output/phase14/colorbar-horizontal.html", selfcontained = TRUE)
```

`test_output/` is gitignored — these are not committed; they're for the human checkpoints below.
  </action>
  <verify>
    <automated>test -f test_output/phase14/colorbar-smooth.html && test -f test_output/phase14/steps-bar.html && test -f test_output/phase14/colorbar-horizontal.html</automated>
  </verify>
  <done>All three HTML files exist in test_output/phase14/.</done>
</task>

<task type="checkpoint:human-verify" gate="blocking">
  <name>Task 6: Checkpoint B — manual visual confirmation of vertical colorbar quality</name>
  <what-built>
    Two HTML widgets at `test_output/phase14/colorbar-smooth.html` and `test_output/phase14/steps-bar.html`. Snapshot tests assert that the IR carries the right hex strings; this checkpoint confirms the IR turns into a visually correct colorbar (no banding on the smooth one, clean band edges on the banded one).
  </what-built>
  <how-to-verify>
    1. Open `test_output/phase14/colorbar-smooth.html` in a browser. Confirm:
       - A vertical gradient legend on the right of the panel.
       - No visible banding (smooth color transition top-to-bottom).
       - At least 3 ticks (not just min/max).
       - Tick labels are numbers from `pretty()` on `mtcars$hp` (50, 100, 150, 200, 250 or similar).
    2. Open `test_output/phase14/steps-bar.html`. Confirm:
       - A vertical legend with hard color bands (no smooth gradient).
       - Band boundaries align with tick marks.
       - At least 3 distinct color blocks visible.
    3. If banding is visible in the smooth one: report back, planner will bump the stop count from 30 (D-09 ceiling).
    4. If band edges look misaligned in the steps one: report back; the bin_colors / breaks pairing logic in plan 14-06 needs revisiting.
  </how-to-verify>
  <resume-signal>Type "approved" to proceed to the horizontal colorbar checkpoint, or describe banding/alignment issues observed.</resume-signal>
</task>

<task type="checkpoint:human-verify" gate="blocking">
  <name>Task 7: Checkpoint C — manual visual confirmation of horizontal colorbar (D-10)</name>
  <what-built>
    HTML widget at `test_output/phase14/colorbar-horizontal.html`. The plot uses `theme(legend.position = "bottom")` which per D-10 must trigger a horizontal colorbar layout: gradient runs left-to-right, ticks placed below the bar, title above.
  </what-built>
  <how-to-verify>
    1. Open `test_output/phase14/colorbar-horizontal.html` in a browser. Confirm:
       - Legend appears at the bottom of the plot (not on the right).
       - The gradient bar is wider than tall (oriented horizontally).
       - Color transitions left-to-right (low values on the left, high on the right) — for viridis_c that's purple → yellow.
       - Tick marks appear below the bar (not beside it).
       - Tick labels appear below the ticks, centered under each tick mark (text-anchor: middle).
       - The legend title (`hp`) appears above the bar.
    2. If the bar is still vertical or oriented incorrectly: report back. The R-side `orientation` field (plan 14-05) or the JS-side branching (plan 14-06) needs revisiting.
    3. If the gradient direction is reversed (yellow on the left): the linearGradient `x1`/`x2` swap in renderColorbar is wrong.
    4. If ticks are still on the right side of the bar: the orientation branch in renderColorbar didn't fire — check `guide.orientation` is reaching the function.
  </how-to-verify>
  <resume-signal>Type "approved" to mark the phase complete, or describe horizontal-layout issues observed.</resume-signal>
</task>

</tasks>

<exit_criteria>
- 12 test_that blocks in `test-color-fidelity.R` are real (no `skip()`).
- 12 snapshot files exist under `tests/testthat/_snaps/color/` and are committed.
- Per-row identity (`expect_identical(ir_col, build_col)`) passes for every corpus plot, including the `scale_fill_manual` block.
- `test-legends.R` and `test-ir-legends.R` remain green (regression).
- Phase-13 baseline FAILs unchanged.
- All three manual checkpoints (A snapshot review, B vertical visual, C horizontal visual) approved.
</exit_criteria>

<threat_model>
No threat surface — package internals only. Snapshot tests serialize hex strings to disk; no external input, no auth, no network.
</threat_model>

<output>
After completion, create `.planning/phases/14-color-fidelity/14-07-SUMMARY.md` listing:
- Final test count (~20 active in test-color-fidelity.R; 12 with snapshots).
- Snapshot file list (`ls tests/testthat/_snaps/color/`).
- Phase-13 baseline status (FAIL count unchanged).
- Resolutions of all three checkpoints (A, B, C).
- Confirmation that ROADMAP success criterion 2 is satisfied including the literal `scale_fill_manual` coverage.
- Confirmation that D-10 horizontal colorbar is verified end-to-end (R IR + JS render + visual checkpoint).
</output>
