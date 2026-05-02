# Phase 13: Internals Refactor - Context

**Gathered:** 2026-05-02
**Status:** Ready for planning

<domain>
## Phase Boundary

Modularize `R/as_d3_ir.R` (currently 1,151 lines, single function with inline helpers) into per-concern source files, and wrap `ggplot2:::calc_element()` in a public-API-safe helper. Behavior visible to consumers does not change. No new features, no IR schema changes, no JS-side work.

Requirements covered: REFACTOR-01, REFACTOR-02.

</domain>

<decisions>
## Implementation Decisions

### Module shape

- **D-01:** Decompose `as_d3_ir()` into file-per-concern modules at `R/` root (R packages require flat `R/`, no nested directories).
- **D-02:** New files: `R/ir_scales.R`, `R/ir_theme.R`, `R/ir_facets.R`, `R/ir_layers.R`, `R/ir_legends.R`. Final file naming/grouping is the planner's call as long as the spirit holds — one file per concern, named `R/ir_*.R`.
- **D-03:** `R/as_d3_ir.R` becomes a thin orchestrator. Target: under ~200 lines (REFACTOR-01 success criterion). Top-level function only wires `ggplot_build()` results through the extraction helpers.
- **D-04:** Each `ir_*.R` file exports its top-level extractor (e.g. `extract_scales_ir()`, `extract_theme_ir()`). Inner helpers stay internal. All extractors are pure functions of `ggplot_build()` output + theme — no shared mutable state.

### `calc_element` fallback

- **D-05:** Introduce a single `calc_element_safe(element_name, theme)` helper. Every existing `ggplot2:::calc_element()` call site (5 sites: lines 75, 619, 825, 942, 1061 of current `as_d3_ir.R`) routes through it.
- **D-06:** Lookup order inside the helper:
  1. Try `ggplot2:::calc_element(element_name, theme)` (current path).
  2. On error, attempt a public-API path: resolve via `theme_get()` + `ggplot2::calc_element` if exported, or via the public `theme` resolution that `ggplot_build()` already produces.
  3. If both fail, return the documented ggplot2 default for that element (a small static lookup for the elements we actually use: `legend.position`, `legend.key.size`, `panel.spacing`, plus the generic theme element accessor at L75).
- **D-07:** When fallback (step 2 or 3) is used, emit a once-per-session `warning()` naming the missing element and the ggplot2 version, so users find out before silent visual drift accumulates.
- **D-08:** Helper lives in `R/ir_theme.R` (theme-resolution concern).

### Behavior-change tolerance

- **D-09:** "Refactor done" gate is **tests-pass equivalence**: all v1.0 unit tests (`tests/testthat/`) and the existing visual regression checkpoints continue to pass on the refactored code.
- **D-10:** IR JSON output is NOT required to be byte-identical to v1.0. Trivial differences (field ordering, whitespace, list naming) are acceptable as long as the consumer side (the D3 renderer in `inst/htmlwidgets/gg2d3.js`) produces visually identical SVG.
- **D-11:** Visual equivalence is judged against the v1.0 visual test outputs in `test_output/` for the existing test plot corpus. Pixel-level diff is the safety net.

### Claude's Discretion

- **Test seam strategy:** Both per-helper unit tests (synthetic `ggplot_build()` slices fed into each `extract_*_ir()` to verify the slice it owns) AND a small set of full-pipeline IR snapshot tests (a handful of representative plots, snapshot the resulting IR list, diff on change). Helpers caught in unit tests; integration regressions caught in snapshots.
- **Refactor sequencing:** The planner decides the order of extraction (e.g. theme first since it gates `calc_element_safe`, then scales, then layers, then legends, then facets) and how granular the commits are. Default: one extractor per atomic commit, validated against the test suite at each step, so any regression is bisectable.
- **Internal helper migration:** The dozen-plus inline helpers inside `as_d3_ir()` (`%||%`, `to_rows`, `map_discrete`, `extract_theme_element`, `validate_log_domain`, `get_scale_transform`, `get_scale_info`, `dom`, etc.) are placed in whichever `ir_*.R` file owns the concern, or in a small `R/ir_utils.R` if they're cross-cutting. Planner's call.
- **Naming conventions inside extractors:** Function naming, internal data structure shape, and roxygen2 doc style are at the planner's discretion as long as `devtools::document()` runs clean.

### Folded Todos

None — no pending todos matched this phase.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and requirements
- `.planning/PROJECT.md` — Core value, v1.1 milestone goals, key decisions table.
- `.planning/REQUIREMENTS.md` §Internals — REFACTOR-01 and REFACTOR-02 wording is the source of truth for "done."
- `.planning/ROADMAP.md` §"Phase 13: Internals Refactor" — Goal, success criteria, dependency note (Phase 13 is the v1.1 foundation; Phases 14–16 depend on it).

### Codebase context
- `.planning/codebase/STRUCTURE.md` — Where R sources live, package layout conventions.
- `.planning/codebase/CONVENTIONS.md` — Naming, documentation, and test conventions in use.
- `.planning/codebase/CONCERNS.md` — Tech debt entries; "monolithic as_d3_ir" and "ggplot2:::calc_element() fragility" are the two CONCERNS this phase pays down.
- `R/as_d3_ir.R` — The 1,151-line file being decomposed. Lines 75, 619, 825, 942, 1061 are the `calc_element` sites.
- `R/validate_ir.R` — IR validator; the refactor must keep producing IR that passes this.
- `inst/htmlwidgets/gg2d3.js` — JS-side IR consumer. The IR contract with this file MUST NOT change.

### Test surfaces
- `tests/testthat/` — All existing tests must keep passing (D-09).
- `test_output/` — Visual regression baseline (D-11).

### External
- ggplot2 documentation for `theme_get()`, `calc_element` (where exported), and `element_render` — the public-API surface the fallback in D-06 step 2 will probe.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- **`%||%` helper** (R/as_d3_ir.R:18) — Already-defined null-coalescing; goes in `ir_utils.R` or wherever first imported.
- **`to_rows()`** (R/as_d3_ir.R:27, redefined again at 215) — Same helper defined twice in the current file. Refactor should DRY this into one place. Cleanup-as-you-go.
- **`map_discrete()`** (R/as_d3_ir.R:53) — Discrete scale value mapper. Belongs in `ir_scales.R`.
- **`extract_theme_element()`** (R/as_d3_ir.R:74) — Already named like the target API. Becomes the seed of `ir_theme.R`'s public surface.
- **`validate_log_domain()`, `get_scale_transform()`, `get_scale_info()`** (R/as_d3_ir.R:289–351) — Already concern-focused; lift wholesale into `ir_scales.R`.
- **`R/validate_ir.R`** — Existing standalone IR validator. The refactored extractors should keep producing IR that passes it; planner can re-use it as a test fixture.

### Established Patterns

- Single-responsibility R files for the interactivity API (`R/d3_brush.R`, `R/d3_hover.R`, etc.) — the file-per-concern pattern is already in use elsewhere in this package, so `R/ir_*.R` fits the established style.
- `ggplot_build()` is the canonical entry point for everything in `as_d3_ir()`. Every extractor takes the built object (or a slice of it) plus the theme. Pure-function-of-build is the de facto contract.
- Test files mirror source: `tests/testthat/test-ir.R`, etc. New `R/ir_*.R` files should each get a matching `test-ir-*.R` test file.

### Integration Points

- `R/gg2d3.R::gg2d3()` — Calls `as_d3_ir(p, ...)`. Public API contract; signature MUST NOT change.
- `inst/htmlwidgets/gg2d3.js` — Consumes the IR JSON. Schema MUST NOT change. (Visual + unit tests gate this.)
- `R/validate_ir.R::validate_ir()` — Treat as the IR shape contract. The refactor passes if the validator still accepts every test-corpus IR.

</code_context>

<specifics>
## Specific Ideas

- The current file already uses `extract_theme_element` as a name — keep that flavor (`extract_*_ir`) for the new module entry points so the names tell you what they own.
- `calc_element_safe()` is the helper name — short, predictable, easy to grep across the codebase later when REFACTOR-02 audits land.
- Once-per-session warning (D-07) should use a package-internal flag (e.g. `.gg2d3_calc_element_warned <- TRUE` in `pkg.env`) so a single render doesn't spam 5 warnings if all 5 sites fall back.

</specifics>

<deferred>
## Deferred Ideas

- **IR schema cleanup** — Field renames, dropping unused fields, normalizing list-vs-named-list patterns. Tempting during a refactor but breaks the JS consumer contract; out of scope for v1.1.
- **Replacing `ggplot_build()` with the public `layer_data()` / `ggplot_gtable()` surface** — Bigger architectural shift; v1.1 only hardens the existing path.
- **Generalizing the extractor framework into a registry (so future geoms self-register their IR extraction the way they self-register their renderers)** — Possible v1.2+ topic; v1.1 stays with direct dispatch.

### Reviewed Todos (not folded)

None — no pending todos were considered.

</deferred>

---

*Phase: 13-internals-refactor*
*Context gathered: 2026-05-02*
