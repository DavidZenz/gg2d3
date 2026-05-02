# Phase 13: Internals Refactor - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-02
**Phase:** 13-internals-refactor
**Areas discussed:** Module shape, calc_element fallback, Behavior-change tolerance

---

## Area Selection

| Area | Description | Selected |
|------|-------------|----------|
| Module shape | File-per-concern vs R/ir/ subdir vs single file | ✓ |
| calc_element fallback | What the wrapper does when private API fails | ✓ |
| Behavior-change tolerance | Byte-identical IR vs tests-pass equivalence vs visual-only | ✓ |
| Test seam strategy | Per-helper unit tests vs IR snapshots vs both | (Claude's discretion) |

---

## Module shape

| Option | Description | Selected |
|--------|-------------|----------|
| File-per-concern (Recommended) | New files: R/ir_scales.R, R/ir_theme.R, R/ir_facets.R, R/ir_layers.R, R/ir_legends.R. as_d3_ir.R becomes a thin orchestrator (<200 lines). Standard R package pattern, reviewer-friendly. | ✓ |
| ir_helpers.R single file | One R/ir_helpers.R with all extract_* helpers, sectioned by comment headers. as_d3_ir.R orchestrates. Smaller diff, less file churn, but a single 800-line helper file. | |
| Group by aesthetic stage | R/ir_extract.R (data → IR), R/ir_decorate.R (theme/legend overlays), R/ir_finalize.R (validation + serialization). Pipeline-oriented split rather than concern-oriented. | |

**User's choice:** File-per-concern (Recommended)
**Notes:** Aligns with the existing `R/d3_*.R` per-concern pattern. R packages keep all source in flat `R/` (no nested directories), so `R/ir_*.R` is the practical shape.

---

## calc_element fallback

| Option | Description | Selected |
|--------|-------------|----------|
| Try public path, fall back to ggplot2 defaults (Recommended) | calc_element_safe() first attempts the private API; on error, resolves the element via theme_get() + element resolution against the complete theme. If even that fails, returns the documented ggplot2 default for that element with a once-per-session warning. | ✓ |
| Hardcoded defaults only | On private-API failure, use a small lookup table of v1.0-validated defaults (legend.position='right', panel.spacing=5.5pt, etc.). Simpler, no second API surface to break, but drifts from any user-customized theme. | |
| Warn and return NULL | Wrapper returns NULL on failure; each call site decides what to do. Most explicit, but pushes the policy to 5 different sites. | |
| Error with install guidance | Hard fail with 'gg2d3 needs ggplot2 ≥ X.Y.Z, you have Z.Y.X. Pin or upgrade.' Loud and safe, but breaks at runtime instead of degrading. | |

**User's choice:** Try public path, fall back to ggplot2 defaults
**Notes:** Three-tier degradation: private API → public theme resolution → static ggplot2 default. Once-per-session warning so users find out about drift without being spammed.

---

## Behavior-change tolerance

| Option | Description | Selected |
|--------|-------------|----------|
| Tests-pass equivalence (Recommended) | All 515+ tests still pass and visual outputs are pixel-equivalent. Trivial differences in IR JSON (field ordering, whitespace, named vs unnamed list slots) are acceptable. Lets the refactor actually clean things up. | ✓ |
| Byte-identical IR | JSON output of as_d3_ir() must match v1.0 byte-for-byte for a fixed corpus of test plots. Strongest safety net, but may force ugly compatibility shims if ggplot2 internals shift between R versions. | |
| Visual-only equivalence | Don't gate on IR shape at all — only require the rendered SVG to look identical to v1.0 on a corpus of test plots. Lightest gate, gives most refactor freedom. | |

**User's choice:** Tests-pass equivalence
**Notes:** Test suite (515+) + visual regression in `test_output/` form the gate. IR JSON is allowed to vary in trivial ways as long as the consumer (gg2d3.js) renders identical SVG.

---

## Claude's Discretion

- **Test seam strategy** — Both per-helper unit tests AND IR snapshot tests on a small corpus.
- **Refactor sequencing** — Theme first (gates `calc_element_safe`), then scales/layers/legends/facets. One extractor per atomic commit.
- **Inline-helper migration** — Helpers like `to_rows`, `map_discrete`, `%||%` placed by concern, or in `ir_utils.R` if cross-cutting.
- **Internal naming** — Function naming and roxygen2 doc style at planner's discretion as long as `devtools::document()` is clean.

## Deferred Ideas

- IR schema cleanup (field renames, normalization) — breaks JS consumer; out of scope for v1.1.
- Replacing `ggplot_build()` with public `layer_data()` / `ggplot_gtable()` surface — too large; v1.1 only hardens the current path.
- Generalizing extractors into a registry like the geom-renderer registry — possible v1.2+ topic.
