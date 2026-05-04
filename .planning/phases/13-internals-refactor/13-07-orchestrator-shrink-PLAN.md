---
phase: 13
plan: 07
type: execute
wave: 7
depends_on: ["13-01", "13-02", "13-03", "13-04", "13-05", "13-06"]
files_modified:
  - R/as_d3_ir.R
autonomous: false
requirements: [REFACTOR-01, REFACTOR-02]
tags: [r-package, ggplot2, refactor, orchestrator, verification]

must_haves:
  truths:
    - "as_d3_ir() function body is ≤ 210 lines (REFACTOR-01 #1; 5% slack on D-03 \"~200\")"
    - "Orchestrator delegates to extract_scales_ir, extract_theme_ir, extract_layers_ir, extract_legends_ir, extract_facets_ir"
    - "calc_element_safe is the only function in R/ that calls ggplot2:::calc_element (REFACTOR-02 success criterion)"
    - "Full devtools::test() suite is green — no v1.0 regressions (D-09)"
    - "Visual regression check on test_output/ corpus is approved by user (D-11)"
    - "as_d3_ir() retains @export and its v1.0 signature exactly"
  artifacts:
    - path: "R/as_d3_ir.R"
      provides: "Thin orchestrator ≤ 210 lines (D-03 ~200 + 5% slack), delegating to 5 ir_*.R extractors"
      max_lines: 210
    - path: ".planning/phases/13-internals-refactor/13-07-SUMMARY.md"
      provides: "Phase verification record (line count, grep audit, test summary, visual diff result)"
      contains: "REFACTOR-01"
  key_links:
    - from: "R/as_d3_ir.R::as_d3_ir"
      to: "5 extractors"
      via: "single delegating call each"
      pattern: "extract_(scales|theme|layers|legends|facets)_ir"
    - from: "All R/ files"
      to: "ggplot2:::calc_element"
      via: "ONLY through calc_element_safe in R/ir_theme.R"
      pattern: "ggplot2:::calc_element"
---

<objective>
Final shrink of the orchestrator and end-to-end phase verification. After Plans 01–06, `R/as_d3_ir.R` should already be substantially smaller, but it may still contain leftover inline helpers, dead variables, or duplicated logic that survived the per-extractor lifts. This plan does the cleanup pass and runs the phase-level verification gates: line count, `ggplot2:::calc_element` audit, full test suite, visual diff.

This plan is **non-autonomous** because the visual diff against `test_output/` baselines (D-11) requires the user to eyeball the rendered SVG corpus before final approval — there is no automated pixel-diff harness in v1.0 (RESEARCH Open Question 1).

Output: `R/as_d3_ir.R` finalized to ≤~200 lines; phase summary committed.
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
@R/ir_theme.R
@R/ir_scales.R
@R/ir_layers.R
@R/ir_legends.R
@R/ir_facets.R
@R/ir_utils.R
@R/zzz.R
</context>

<tasks>

<task type="auto" tdd="false">
  <name>Task 1: Final orchestrator shrink — clean up dead vars, inline tiny helpers, verify ≤~200 lines</name>
  <files>R/as_d3_ir.R</files>
  <read_first>
    - R/as_d3_ir.R (full current state — read it end-to-end to identify leftover inline helpers, unused locals, redundant assignments).
    - .planning/phases/13-internals-refactor/13-RESEARCH.md (§"Top-level orchestrator after refactor (sketch)" — the ~50 line target shape).
    - .planning/phases/13-internals-refactor/13-PATTERNS.md (`R/as_d3_ir.R` modified section — what stays verbatim: roxygen header, signature, stopifnot, ggplot_build, CoordTrans warning, validate_ir tail).
  </read_first>
  <action>
1. **Read** `R/as_d3_ir.R` end-to-end. The shape after Plans 01-06 should be approximately:
   - Roxygen header `#' Build a D3-ready IR ... #' @export` (KEEP).
   - Function signature `as_d3_ir <- function(p, width = 640, height = 400, padding = list(...))` (KEEP — D-04 contract).
   - `stopifnot(inherits(p, "ggplot"))` (KEEP).
   - `b <- ggplot2::ggplot_build(p)` (KEEP).
   - `CoordTrans` warning block (KEEP).
   - Coord detection: `is_flip`, `is_fixed`, `coord_type`, `coord_ratio`, `pp_x`/`pp_y` swap logic (KEEP).
   - `scales <- extract_scales_ir(b, pp_x, pp_y, is_flip)` (delegation from Plan 03).
   - `xscale_obj`/`yscale_obj` if still needed by downstream blocks (likely removable now since legends + facets were lifted).
   - `layers <- extract_layers_ir(b, xscale_obj, yscale_obj)` (Plan 04).
   - `theme_ir <- extract_theme_ir(b)` (Plan 02).
   - `legends <- extract_legends_ir(b, p)` (Plan 05); `legend_position <- legends$position`; `guides_ir <- legends$guides`.
   - Axis-label swap for coord_flip + tickLabels + sec_axis detection (these tiny helpers — `.axis_ticklabels`, `.has_sec_axis` — can stay inline OR move to ir_utils.R; pick smaller diff).
   - `fp <- extract_facets_ir(...)` (Plan 06); destructure.
   - Final `ir <- list(width, height, padding, coord, title, subtitle, caption, axes, facets, panels, scales, layers, guides, legend, theme)`.
   - `validate_ir(ir)` (KEEP, must be the last expression).

2. **Cleanup pass:**
   - Remove any local variable defined but no longer used (e.g., if `xscale_obj`/`yscale_obj` are no longer referenced after Plan 06, drop them).
   - Remove any leftover inline helpers that were missed by the per-extractor plans (e.g., `.axis_ticklabels`/`.has_sec_axis` from v1.0 lines 593-614 — if they're tiny enough, leave inline; if larger, move to `R/ir_utils.R`).
   - Remove any leftover comments referencing extracted code.
   - Ensure `legend_position` is still assigned before being consumed in the final `ir <- list(...)` block.

3. **Verify the function body line count.** Run:
   ```bash
   awk '/^as_d3_ir <- function/,/^}$/' R/as_d3_ir.R | wc -l
   ```
   Target: ≤ 210 (the "~200 line" gate from REFACTOR-01 #1 with 5% slack per CONTEXT D-03).

4. **Verify the file as a whole** is well under v1.0's 1,151 lines (expect <300 total: function body + roxygen header + any tiny inline helpers).

5. **Re-run tests:** `Rscript -e 'devtools::test()'` — green.

6. **Re-run document:** `Rscript -e 'devtools::document()'` — `git diff NAMESPACE` empty.
  </action>
  <verify>
    <automated>Rscript -e 'devtools::test()' && bash -lc 'set -e; body=$(awk "/^as_d3_ir <- function/,/^}\$/" R/as_d3_ir.R | wc -l | tr -d " "); echo "as_d3_ir body line count: $body"; test "$body" -le 210 || (echo "FAIL: as_d3_ir body $body > 210 lines"; exit 1); n=$(grep -rn "ggplot2:::calc_element" R/ | grep -v "R/ir_theme.R" | wc -l | tr -d " "); test "$n" -eq 0 || (echo "FAIL: ggplot2::: leak: $n hits"; grep -rn "ggplot2:::calc_element" R/; exit 1); echo "OK"'</automated>
  </verify>
  <acceptance_criteria>
    - `awk '/^as_d3_ir <- function/,/^}$/' R/as_d3_ir.R | wc -l` ≤ 210 (REFACTOR-01 #1, 5% slack on D-03 "~200").
    - `wc -l R/as_d3_ir.R` < 300 total.
    - `grep -c '#'\'' @export' R/as_d3_ir.R` ≥ 1 (public API preserved).
    - `grep -c 'as_d3_ir <- function(p, width = 640, height = 400' R/as_d3_ir.R` equals 1 (signature unchanged per D-04).
    - `grep -c 'extract_scales_ir(b' R/as_d3_ir.R` ≥ 1.
    - `grep -c 'extract_theme_ir(b)' R/as_d3_ir.R` ≥ 1.
    - `grep -c 'extract_layers_ir(b' R/as_d3_ir.R` ≥ 1.
    - `grep -c 'extract_legends_ir(b' R/as_d3_ir.R` ≥ 1.
    - `grep -c 'extract_facets_ir(b' R/as_d3_ir.R` ≥ 1.
    - `grep -c 'validate_ir(ir)' R/as_d3_ir.R` ≥ 1 (validator still terminates the function).
    - `grep -c '<<-' R/as_d3_ir.R` equals 0.
    - `grep -rn 'ggplot2:::calc_element' R/ | grep -v 'R/ir_theme.R' | wc -l` equals 0 (REFACTOR-02 audit).
    - `Rscript -e 'devtools::test()'` exits 0.
    - `git diff NAMESPACE` empty after `devtools::document()`.
  </acceptance_criteria>
  <done>R/as_d3_ir.R is a thin orchestrator. Function body ≤210 lines. All 5 extractors delegated to. `ggplot2:::calc_element` only appears in calc_element_safe. NAMESPACE unchanged. Full devtools::test() green.</done>
</task>

<task type="checkpoint:human-verify" gate="blocking">
  <name>Task 2: Visual regression checkpoint against test_output/ baselines (D-11)</name>
  <what-built>Phase 13 refactor is complete on the R side: `as_d3_ir()` is a thin orchestrator delegating to 5 `ir_*.R` extractor modules, and `calc_element_safe()` is the only function in `R/` that calls `ggplot2:::calc_element`. All v1.0 unit tests pass. The IR JSON contract with `inst/htmlwidgets/gg2d3.js` is preserved (D-10 allows trivial JSON-shape variation only if the rendered SVG is identical). This checkpoint verifies that visual SVG output is unchanged on the v1.0 corpus — the safety net for refactor-as-no-behavior-change (D-11).</what-built>
  <how-to-verify>
1. **Render the v1.0 corpus** with the refactored code. From the project root:
   ```r
   Rscript -e '
     pkgload::load_all()
     library(ggplot2)
     dir.create("test_output/phase13", recursive = TRUE, showWarnings = FALSE)

     # Render each plot in the v1.0 visual test corpus into HTML files in test_output/phase13/.
     # Use the same plot list and parameters as v1.0 visual tests (refer to test_output/
     # for the existing baselines and replicate exactly).

     plots <- list(
       p_point   = ggplot(mtcars, aes(wt, mpg)) + geom_point(),
       p_bar     = ggplot(mtcars, aes(factor(cyl))) + geom_bar(),
       p_box     = ggplot(mtcars, aes(factor(cyl), mpg)) + geom_boxplot(),
       p_line    = ggplot(economics, aes(date, unemploy)) + geom_line(),
       p_facet_w = ggplot(mtcars, aes(wt, mpg)) + geom_point() + facet_wrap(~cyl),
       p_facet_g = ggplot(mtcars, aes(wt, mpg)) + geom_point() + facet_grid(am ~ cyl),
       p_color   = ggplot(mtcars, aes(wt, mpg, colour = factor(cyl))) + geom_point(),
       p_flip    = ggplot(mtcars, aes(wt, mpg)) + geom_point() + coord_flip()
     )
     for (nm in names(plots)) {
       w <- gg2d3(plots[[nm]])
       htmlwidgets::saveWidget(w, file.path("test_output/phase13", paste0(nm, ".html")))
     }
     cat("Rendered ", length(plots), " plots to test_output/phase13/\n")
   '
   ```
   (If the v1.0 corpus is already documented elsewhere — e.g. a `test_output/render-corpus.R` script — use that instead.)

2. **Compare** each `test_output/phase13/*.html` against the corresponding pre-Phase-13 baseline in `test_output/`. Open both in a browser side-by-side. Confirm:
   - Identical SVG structure (same number of marks, same positions, same colors).
   - Identical axis tick positions and labels.
   - Identical facet panel layout.
   - Identical legend rendering.
   - Identical theme application (background, grid, axes).

3. **If any visible delta** is found: bisect across the per-plan commits (Plans 02-06) to identify which extractor's lift caused the regression. The single-extractor-per-commit rule (D-CONTEXT recommended sequencing) makes this tractable.

4. **Confirm no warnings** are emitted during render that weren't present in v1.0 — specifically, the `gg2d3: ggplot2:::calc_element() failed` warning from `calc_element_safe` should NOT fire on a healthy ggplot2 4.0.3 install (Tier 1 always succeeds).
  </how-to-verify>
  <acceptance_criteria>
    - All v1.0 corpus plots render without errors against the refactored code.
    - Side-by-side visual comparison against pre-Phase-13 baselines shows zero observable visual deltas.
    - No `ggplot2:::calc_element() failed` warning is emitted on a clean render (Tier 1 succeeds for ggplot2 4.0.3).
    - User signs off via "approved" or describes any visible issue for follow-up.
  </acceptance_criteria>
  <resume-signal>Type "approved" to confirm the visual diff is clean, or describe any visible issue for the executor to address.</resume-signal>
</task>

<task type="auto" tdd="false">
  <name>Task 3: Write phase-level summary documenting verification results</name>
  <files>.planning/phases/13-internals-refactor/13-07-SUMMARY.md</files>
  <read_first>
    - All earlier per-plan summaries (`13-01-SUMMARY.md` through `13-06-SUMMARY.md` if they exist).
    - $HOME/.claude/get-shit-done/templates/summary.md (canonical SUMMARY shape).
    - The verify command output from Task 1 (line count, grep audit).
  </read_first>
  <action>
Create `.planning/phases/13-internals-refactor/13-07-SUMMARY.md` per the project's summary template. Include:

1. **Final metrics:**
   - `wc -l R/as_d3_ir.R` (total).
   - `awk '/^as_d3_ir <- function/,/^}$/' R/as_d3_ir.R | wc -l` (function body).
   - Pre-phase line count (1,151) for delta.
2. **REFACTOR-01 verification:** confirm function body ≤ ~200 lines and the 5 extractors are delegated to.
3. **REFACTOR-02 verification:** paste output of `grep -rn 'ggplot2:::calc_element' R/` — confirm ONLY `R/ir_theme.R` matches.
4. **Test summary:** paste `devtools::test()` summary line (e.g., `[ FAIL 0 | WARN 0 | SKIP 0 | PASS XXX ]`).
5. **NAMESPACE diff:** confirm `git diff NAMESPACE` was empty after `devtools::document()`.
6. **Visual diff result:** record the user's "approved" sign-off from Task 2 (or any deltas found and how they were resolved).
7. **Files created:** `R/zzz.R`, `R/ir_utils.R`, `R/ir_theme.R`, `R/ir_scales.R`, `R/ir_layers.R`, `R/ir_legends.R`, `R/ir_facets.R`, `tests/testthat/test-ir-{scales,theme,layers,legends,facets}.R`.
8. **Files modified:** `R/as_d3_ir.R`.
9. **Patterns established for downstream phases:** Phase 14 (Color Fidelity) will operate on `R/ir_scales.R` for the colorbar work; Phase 15 (Secondary Axes) on `R/ir_scales.R` + axis-label block in orchestrator; Phase 16 (Robustness) on `R/ir_layers.R` for non-finite filtering.
  </action>
  <verify>
    <automated>test -f .planning/phases/13-internals-refactor/13-07-SUMMARY.md && grep -q 'REFACTOR-01' .planning/phases/13-internals-refactor/13-07-SUMMARY.md && grep -q 'REFACTOR-02' .planning/phases/13-internals-refactor/13-07-SUMMARY.md && echo OK</automated>
  </verify>
  <acceptance_criteria>
    - `.planning/phases/13-internals-refactor/13-07-SUMMARY.md` exists.
    - Contains line-count metrics for `R/as_d3_ir.R`.
    - Contains the `grep -rn 'ggplot2:::calc_element' R/` audit output.
    - Contains the `devtools::test()` summary.
    - Confirms NAMESPACE diff was empty.
    - Records the visual diff sign-off from Task 2.
    - References both REFACTOR-01 and REFACTOR-02 by ID.
  </acceptance_criteria>
  <done>Phase summary committed. All verification artifacts captured. Phase 13 ready for `/gsd-verify-work` and downstream phase planning.</done>
</task>

</tasks>

<verification>
1. `awk '/^as_d3_ir <- function/,/^}$/' R/as_d3_ir.R | wc -l` ≤ 210.
2. `grep -rn 'ggplot2:::calc_element' R/ | grep -v 'R/ir_theme.R' | wc -l` → 0.
3. `Rscript -e 'devtools::test()'` → green.
4. `git diff NAMESPACE` empty.
5. User approved visual diff against `test_output/` baselines.
6. `13-07-SUMMARY.md` exists with all metrics.
</verification>

<success_criteria>
**Phase-level (all 4 ROADMAP success criteria):**
1. ✅ Top-level `as_d3_ir()` is under ~200 lines and delegates to named helpers (`extract_scales_ir`, `extract_theme_ir`, `extract_facets_ir`, `extract_layers_ir`, `extract_legends_ir`).
2. ✅ Each extraction helper has its own dedicated test file in `tests/testthat/` (5 new files from Plans 01-06).
3. ✅ All `ggplot2:::calc_element()` call sites route through a single `calc_element_safe()` helper (`R/ir_theme.R`) with a public-API fallback path.
4. ✅ Existing v1.0 visual regression and unit tests continue to pass — no behavior change observable to consumers.
</success_criteria>

<output>
This is the terminal plan of Phase 13. After completion, the phase is ready for `/gsd-verify-work` and the v1.1 milestone proceeds to Phase 14 (Color Fidelity), which depends on the clean `R/ir_scales.R` boundary established here.
</output>
