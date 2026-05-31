# Phase 54: Geometry Polish Closure - Research

**Researched:** 2026-05-28
**Domain:** R ggplot2 IR extraction, htmlwidgets D3 SVG renderers, geometry diagnostics
**Confidence:** HIGH for codebase seams and validation; MEDIUM for exact visual parity of label padding/justification

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
## Implementation Decisions

### `geom_label()` Box Behavior
- **D-01:** Attempt bounded ordinary `geom_label()` SVG label boxes in Phase 54 rather than diagnostics-only closure.
- **D-02:** The bounded target is rect + text rendering for ordinary `geom_label()` with useful support for fill, colour/stroke, alpha, text size, and basic padding.
- **D-03:** Keep the scope ordinary and renderer-local; do not pursue rich text, collision avoidance, path-following, or full ggrepel behavior under the label-box work.
- **D-04:** If implementation reveals that a polished label box path is not small and safe, planning may pivot to source-backed diagnostics, but it should first characterize the fixture boundary clearly.

### Polygon Subgroup And Hole Boundary
- **D-05:** Build focused fixtures for `geom_polygon(subgroup = ...)` / hole-style input and use them to decide whether a tiny ggplot-compatible subset is obvious.
- **D-06:** Default posture is explicit non-goal documentation for subgroup/hole topology unless research finds a very small, low-risk implementation path.
- **D-07:** Do not add broad GIS topology repair, ring containment inference, invalid-polygon repair, or arbitrary hole winding logic.
- **D-08:** If subgroup metadata is preserved, it should serve a concrete bounded rendering/test purpose; do not preserve extra IR metadata just as speculative future cargo.

### Transformed Rect/Tile Closure
- **D-09:** Treat the current direct transformed-bound scaling path as the likely release boundary.
- **D-10:** Strengthen fixtures and evidence around log/sqrt/reverse rect and tile behavior, including render/update consistency and shared scale/renderer seams.
- **D-11:** Fix only confirmed shared scale/render drift. Avoid a broad scale/rect refactor unless tests expose a real mismatch.
- **D-12:** If no drift is found, Phase 54 should produce narrower implementation-ready evidence and diagnostics explaining the boundary rather than reopening the full transformed-scale parity problem.

### Text Placement Triage
- **D-13:** Attempt small parity wins for ordinary text/label `hjust`, `vjust`, and `angle` where they can be implemented without destabilizing existing text rendering.
- **D-14:** Consider font family only if it falls naturally out of the same text renderer parameter path; it is secondary to justification and rotation.
- **D-15:** Explicitly defer collision avoidance, ggrepel-compatible placement, path-following text, and rich text.
- **D-16:** Documentation should separate shipped small text-placement support from deferred algorithmic placement features so users do not infer unsupported parity.

### The Agent's Discretion
- Planning may choose the exact split between characterization, implementation, browser smoke, and documentation plans as long as each GEOM requirement is traceable.
- Planner/researcher may decide whether label-box and text-placement work share one renderer plan or split into separate plans based on file blast radius.
- Browser visual smoke may be used as downstream confidence, but source/IR/DOM checks should remain the primary gates.

### Claude's Discretion
- Planning may choose the exact split between characterization, implementation, browser smoke, and documentation plans as long as each GEOM requirement is traceable.
- Planner/researcher may decide whether label-box and text-placement work share one renderer plan or split into separate plans based on file blast radius.
- Browser visual smoke may be used as downstream confidence, but source/IR/DOM checks should remain the primary gates.

### Deferred Ideas (OUT OF SCOPE)
- Full ggrepel-compatible collision avoidance remains future work (`FUT-05`).
- Path-following text, rich text, and broad label-placement algorithms remain out of Phase 54.
- Broad GIS-style polygon topology repair remains future work (`FUT-06`).
- Pixel thresholds and committed golden screenshots remain deferred until visual artifacts prove stable across environments.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| GEOM-01 | Ordinary `geom_label()` box, padding, fill, stroke, and text behavior is either implemented for the supported text renderer path or explicitly deferred with source-backed evidence and user-facing diagnostics. | `GeomLabel` currently maps to `"text"` and the ordinary text renderer emits only `text.geom-text`; ggplot2 documents label padding, border/text colour split, and fill-backed label boxes, while the existing sf label renderer already proves a bounded SVG `g + rect + text + getBBox()` pattern. [VERIFIED: R/ir_layer_helpers.R; inst/htmlwidgets/modules/geoms/text.js; inst/htmlwidgets/modules/geoms/sf.js; tests/testthat/test-text-label-polish.R; CITED: https://ggplot2.tidyverse.org/reference/geom_text.html] |
| GEOM-02 | Ordinary `geom_polygon()` subgroup/hole behavior is either supported for a bounded ggplot2-compatible subset or documented as an explicit non-goal with fixtures proving the boundary. | ggplot2 documents `subgroup` holes and `rule`, but gg2d3 currently drops `subgroup` from ordinary polygon IR and its renderer explicitly lacks `fill-rule`/topology behavior; fixtures should prove this remains a deliberate boundary unless a tiny compound-path subset is implemented. [VERIFIED: tests/testthat/test-polygon-ir.R; tests/testthat/test-polygon-renderer.R; inst/htmlwidgets/modules/geoms/polygon.js; CITED: https://ggplot2.tidyverse.org/reference/geom_polygon.html; CITED: https://developer.mozilla.org/en-US/docs/Web/SVG/Reference/Attribute/fill-rule] |
| GEOM-03 | Transformed-scale rect/tile edge parity is addressed at the shared scale/axis semantics boundary or carried forward with narrower implementation-ready evidence than the v1.12 classification. | Existing tests already compare log10/sqrt/reverse built rect/tile bounds to IR rows and source-contract the direct transformed-bound scaling path through `scales.js`, `rect.js`, and `geom-registry.js`; Phase 54 should add render/update consistency evidence rather than refactor first. [VERIFIED: tests/testthat/test-rect-tile-ir.R; tests/testthat/test-rect-tile-renderer.R; inst/htmlwidgets/modules/scales.js; inst/htmlwidgets/modules/geoms/rect.js; inst/htmlwidgets/modules/geom-registry.js; CITED: https://d3js.org/d3-scale/log; CITED: https://d3js.org/d3-scale/pow] |
| GEOM-04 | Collision avoidance, path-following text, rotation, and justification candidates are triaged into small verified improvements or future requirements without implying unsupported label-placement parity. | Built ggplot2 text/label data contains `hjust`, `vjust`, `angle`, and `family`, but ordinary gg2d3 row preservation omits these today; sf annotation helpers already implement coarse `hjust`/`vjust` and font-family mapping, while ggplot2 explicitly points automatic non-overlap to ggrepel and states `geom_label()` lacks `check_overlap`. [VERIFIED: local ggplot2 build probe; R/ir_layer_helpers.R; inst/htmlwidgets/modules/geoms/sf.js; CITED: https://ggplot2.tidyverse.org/reference/geom_text.html] |
</phase_requirements>

## Summary

Phase 54 should be planned as bounded closure, not a broad geometry parity rewrite. The strongest implementation candidate is ordinary text/label renderer work: preserve `hjust`, `vjust`, `angle`, and optional `family` in ordinary layer IR; split ordinary `GeomLabel` from ordinary `GeomText`; and reuse the existing sf-label SVG pattern to render `g.geom-label` with `rect` behind `text`. [VERIFIED: 54-CONTEXT.md; R/ir_layer_helpers.R; inst/htmlwidgets/modules/geoms/text.js; inst/htmlwidgets/modules/geoms/sf.js]

Polygon subgroup/hole support should remain fixture-led and default to an explicit non-goal. ggplot2 has first-class `subgroup` and `rule` semantics for holes, and SVG supports `fill-rule`, but gg2d3's ordinary polygon pipeline currently renders one closed path per `group` and deliberately avoids topology repair. A tiny support path exists only if the plan limits itself to preserving ggplot2-built `subgroup` and emitting compound subpaths with `fill-rule`, with no ring containment inference or invalid polygon repair. [CITED: https://ggplot2.tidyverse.org/reference/geom_polygon.html; CITED: https://developer.mozilla.org/en-US/docs/Web/SVG/Reference/Attribute/fill-rule; VERIFIED: inst/htmlwidgets/modules/geoms/polygon.js; tests/testthat/test-polygon-ir.R]

Rect/tile transformed-scale closure should strengthen evidence around the current boundary. D3 log scales require non-crossing positive/negative domains, D3 sqrt is a power scale with exponent 0.5, and gg2d3 already tests that ggplot2 built transformed bounds are passed directly to D3 scales. Fix only if focused render/update fixtures prove drift between `rect.js`, `geom-registry.js`, and `scales.js`. [CITED: https://d3js.org/d3-scale/log; CITED: https://d3js.org/d3-scale/pow; VERIFIED: tests/testthat/test-rect-tile-ir.R; tests/testthat/test-rect-tile-renderer.R]

**Primary recommendation:** Plan four workstreams: text/label bounded implementation, polygon subgroup/hole fixture decision, rect/tile transformed-bound evidence, then diagnostics/validation closure that maps shipped support versus deferrals. [VERIFIED: 54-CONTEXT.md; .planning/ROADMAP.md]

## Project Constraints (from CLAUDE.md / AGENTS.md)

- Use the established R -> IR -> D3 SVG/htmlwidgets pipeline; do not bypass `as_d3_ir()` or the module registry for geometry behavior. [VERIFIED: CLAUDE.md; AGENTS.md]
- Keep D3 v7 vendored locally under `inst/htmlwidgets/lib/d3/d3.v7.min.js` and loaded via `inst/htmlwidgets/gg2d3.yaml`. [VERIFIED: CLAUDE.md; inst/htmlwidgets/gg2d3.yaml]
- Development commands are `devtools::load_all()`, `devtools::document()`, `devtools::test()`, `testthat::test_file(...)`, and `devtools::build_readme()`. [VERIFIED: CLAUDE.md]
- Use `rtk` as the shell-command prefix in this repository. [VERIFIED: /Users/davidzenz/.codex/RTK.md]
- Do not modify untracked `.claude/` or `AGENTS.md`; current worktree shows both untracked. [VERIFIED: git status --short]
- Browser visual smoke should provide downstream confidence, while source/IR/DOM checks remain the primary gates. [VERIFIED: 54-CONTEXT.md; tests/testthat/test-browser-visual-smoke.R]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Ordinary label/text parameter extraction | R Layer | IR Layer | `ggplot_build()` supplies row columns such as `hjust`, `vjust`, `angle`, `family`, `fill`, and `linewidth`; `gg2d3_ir_layer_keep_aes()` decides what survives into JSON rows. [VERIFIED: local ggplot2 build probe; R/ir_layer_helpers.R] |
| Label box rendering | D3 Layer | IR Layer | SVG measurement and rect placement require browser-rendered text metrics; the existing sf-label renderer already uses text `getBBox()` to size a backing rect. [VERIFIED: inst/htmlwidgets/modules/geoms/sf.js; CITED: https://developer.mozilla.org/en-US/docs/Web/API/SVGGraphicsElement/getBBox] |
| Text justification and rotation | D3 Layer | R Layer | R should preserve values; SVG owns `text-anchor`, `dominant-baseline`, and `transform="rotate(...)"` on rendered text/groups. [VERIFIED: R/ir_layer_helpers.R; inst/htmlwidgets/modules/geoms/sf.js; CITED: https://developer.mozilla.org/en-US/docs/Web/SVG/Reference/Attribute/transform] |
| Polygon subgroup/hole decision | R Layer + D3 Layer | Diagnostics | R can preserve `subgroup`; D3 can render compound paths, but topology repair is explicitly out of scope. [VERIFIED: 54-CONTEXT.md; tests/testthat/test-polygon-ir.R; CITED: https://ggplot2.tidyverse.org/reference/geom_polygon.html] |
| Rect/tile transformed-bound scaling | D3 scale factory | D3 rect renderer/update | `scales.js` builds log/sqrt/reverse scales, while `rect.js` and `geom-registry.js` scale already-transformed bounds directly. [VERIFIED: inst/htmlwidgets/modules/scales.js; inst/htmlwidgets/modules/geoms/rect.js; inst/htmlwidgets/modules/geom-registry.js] |
| Diagnostics and public support language | Docs/Vignettes | README source | `vignettes/d3-drawing-diagnostics.md` carries geometry boundaries; README/Rmd mirror user-facing support claims when changed. [VERIFIED: vignettes/d3-drawing-diagnostics.md; README.Rmd] |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| R | 4.6.0 local; package requires >= 4.1.0 | Package runtime, IR generation, tests. | Existing package runtime and DESCRIPTION constraint. [VERIFIED: local Rscript; DESCRIPTION] |
| ggplot2 | 4.0.3 local | Source plot build system and geometry semantics. | `ggplot_build()` is the authoritative source for label, polygon, and rect/tile built data. [VERIFIED: local Rscript; R/as_d3_ir.R] |
| htmlwidgets | 1.6.4 local | Serialization and browser widget bridge. | Existing `gg2d3()` transport. [VERIFIED: local Rscript; R/gg2d3.R] |
| D3 | v7 vendored | SVG rendering, scales, path generation, transitions. | Existing renderer stack and documented D3 scale semantics. [VERIFIED: inst/htmlwidgets/gg2d3.yaml; CITED: https://d3js.org/d3-scale] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| testthat | 3.3.2 local | IR, source contract, and focused regression tests. | Primary automated validation gate for all GEOM requirements. [VERIFIED: local Rscript; tests/testthat] |
| pkgload | 1.5.2 local | Load package for targeted test files. | Use in all quick test commands. [VERIFIED: local Rscript; existing tests] |
| chromote | 0.5.1 local | Optional browser visual smoke and DOM artifact capture. | Use only for downstream confidence rows or final smoke; not the sole gate. [VERIFIED: local Rscript; tests/testthat/helper-browser-visual.R] |
| Chrome | `/Applications/Google Chrome.app/Contents/MacOS/Google Chrome` | Local browser for chromote. | Available for opt-in browser visual smoke. [VERIFIED: chromote::find_chrome()] |
| Node.js | v26.0.0 local | Existing graph/status tooling and optional JS utilities. | Not required by package tests, available for GSD tooling. [VERIFIED: local `node --version`] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Add a separate `label.js` module | Extend `geoms/text.js` and register a `label` alias/contract | A separate module is cleaner if label code grows; extending `text.js` keeps text/label placement helpers shared and matches D-03 renderer-local scope. [VERIFIED: 54-CONTEXT.md; inst/htmlwidgets/modules/geoms/text.js] |
| Preserve `GeomLabel` as `geom = "text"` | Emit `geom = "label"` for ordinary labels | Keeping `"text"` minimizes IR churn but hides label support from renderer contracts; `geom = "label"` gives explicit selectors and drift tests at the cost of updating `validate_ir()` and `geom-contracts.js`. [VERIFIED: R/ir_layer_helpers.R; inst/htmlwidgets/modules/geom-contracts.js; tests/testthat/test-renderer-wiring-contracts.R] |
| Implement ordinary polygon holes now | Document subgroup topology as a non-goal | A tiny compound-path subset may be viable, but broad topology inference is out of scope and risky; default plan should require strong fixture evidence before implementation. [VERIFIED: 54-CONTEXT.md; tests/testthat/test-polygon-renderer.R] |
| Add rect/tile browser pixel comparisons | Strengthen IR/source/DOM consistency evidence | Pixel thresholds are explicitly deferred; transformed rect/tile questions are source-measurable unless live DOM exposes drift. [VERIFIED: 54-CONTEXT.md; tests/testthat/test-rect-tile-renderer.R] |

**Installation:** No new dependencies should be added for Phase 54. [VERIFIED: DESCRIPTION; 54-CONTEXT.md]

**Version verification:** Local package versions were verified with `Rscript --vanilla`; D3 is locked by the vendored `gg2d3.yaml` dependency rather than npm installation. [VERIFIED: local Rscript; inst/htmlwidgets/gg2d3.yaml]

## Architecture Patterns

### System Architecture Diagram

```text
ggplot object
  |
  v
ggplot2::ggplot_build()
  |-- label/text rows: label, x/y, fill, colour, linewidth, hjust, vjust, angle, family
  |-- polygon rows: group, optional subgroup, x/y, styling
  |-- rect/tile rows: transformed xmin/xmax/ymin/ymax bounds
  v
R/as_d3_ir.R + R/ir_layer_helpers.R
  |-- preserve only supported row fields
  |-- dispatch GeomText / GeomLabel / GeomPolygon / GeomRect / GeomTile
  |-- attach bounded params such as label padding when supported
  v
JSON IR layer list
  |
  v
htmlwidgets + gg2d3.js panel rendering
  |-- build scales from scales.js
  |-- filter rows by PANEL
  |-- render into clipped panel groups
  v
geomRegistry.render()
  |-- text/label renderer: text, label box, hjust/vjust/angle
  |-- polygon renderer: grouped closed path or explicit subgroup non-goal
  |-- rect renderer/update: direct transformed-bound scaling
  v
source tests + optional browser visual smoke + diagnostics
  |-- shipped selectors and DOM nodes
  |-- non-goal diagnostics for topology/collision/path text
```

### Recommended Project Structure

```text
R/
├── ir_layer_helpers.R                 # add supported ordinary text/label fields and bounded label params
├── as_d3_ir.R                         # keep orchestration stable; only touch if dispatch requires it
└── validate_ir.R                      # add ordinary label geom only if IR emits geom = "label"
inst/htmlwidgets/modules/
├── geom-contracts.js                  # align text/label selectors and aliases
├── geom-registry.js                   # align update path for text/label transforms if needed
├── scales.js                          # touch only for proven rect/tile shared-scale drift
└── geoms/
    ├── text.js                        # likely home for ordinary text/label boxes/placement
    ├── polygon.js                     # only touch for tiny subgroup subset or explicit source guards
    └── rect.js                        # touch only for proven transformed-bound drift
tests/testthat/
├── test-text-label-polish.R           # main GEOM-01/GEOM-04 characterization and contracts
├── test-polygon-ir.R                  # subgroup/hole fixture boundary
├── test-polygon-renderer.R            # topology/non-goal or compound-path source contracts
├── test-rect-tile-ir.R                # transformed built-data evidence
├── test-rect-tile-renderer.R          # render/update/source consistency
├── test-renderer-wiring-contracts.R   # selector/load-order/contract drift
└── test-browser-visual-smoke.R        # optional downstream fixture rows only if useful
vignettes/
└── d3-drawing-diagnostics.md          # shipped support vs deferred geometry boundary
```

### Pattern 1: Explicit Ordinary Label Alias

**What:** Emit ordinary `GeomLabel` as a distinct supported renderer alias, preferably `geom = "label"` with `text.js` registering `['text', 'label']`, or a separate contract entry if planner wants stricter selector accounting. [VERIFIED: R/ir_layer_helpers.R; inst/htmlwidgets/modules/geom-contracts.js]

**When to use:** Use this if Phase 54 ships label boxes, because labels need `g + rect + text` DOM and should not be indistinguishable from `text.geom-text` in contracts. [VERIFIED: tests/testthat/test-text-label-polish.R; inst/htmlwidgets/modules/geoms/text.js]

**Example:**

```r
# Source pattern: R/ir_layer_helpers.R geom dispatch.
GeomText = "text"
GeomLabel = "label"
```

```javascript
// Source pattern: text.js renderer registration can share one module.
window.gg2d3.geomRegistry.register(['text', 'label'], renderText);
```

If this path is chosen, update `validate_ir()` known geoms, `geom-contracts.js`, and `test-renderer-wiring-contracts.R` expected aliases. [VERIFIED: R/validate_ir.R; inst/htmlwidgets/modules/geom-contracts.js; tests/testthat/test-renderer-wiring-contracts.R]

### Pattern 2: Label Box Measurement After Text Render

**What:** Render text first, call `getBBox()`, then size and position a backing rect with padding. [VERIFIED: inst/htmlwidgets/modules/geoms/sf.js; CITED: https://developer.mozilla.org/en-US/docs/Web/API/SVGGraphicsElement/getBBox]

**When to use:** Ordinary label boxes need physical text dimensions, which are available only after SVG text exists in the browser. [CITED: https://ggplot2.tidyverse.org/reference/geom_text.html; CITED: https://developer.mozilla.org/en-US/docs/Web/API/SVGGraphicsElement/getBBox]

**Example:**

```javascript
// Source: inst/htmlwidgets/modules/geoms/sf.js already uses this shape for sf labels.
labelGroups.append("rect").attr("class", "geom-label-box");
labelGroups.append("text").attr("class", "geom-label-text");

labelGroups.each(function(d) {
  const group = d3.select(this);
  const bbox = group.select("text.geom-label-text").node().getBBox();
  const pad = labelPaddingPx(d);
  group.select("rect.geom-label-box")
    .attr("x", bbox.x - pad)
    .attr("y", bbox.y - pad)
    .attr("width", bbox.width + pad * 2)
    .attr("height", bbox.height + pad * 2);
});
```

Keep rotation on the group or measure before applying rotation, because MDN documents that `getBBox()` does not account for element or parent transforms. [CITED: https://developer.mozilla.org/en-US/docs/Web/API/SVGGraphicsElement/getBBox]

### Pattern 3: Small Text Placement Mapping

**What:** Preserve `hjust`, `vjust`, `angle`, and optionally `family`; map numeric/obvious character justifications to SVG text anchor/baseline and apply `rotate(angle x y)` at the anchor. [VERIFIED: local ggplot2 build probe; inst/htmlwidgets/modules/geoms/sf.js; CITED: https://developer.mozilla.org/en-US/docs/Web/SVG/Reference/Attribute/transform]

**When to use:** Ordinary `geom_text()` and bounded `geom_label()` placement work under D-13/D-14. [VERIFIED: 54-CONTEXT.md]

**Example:**

```javascript
function rotationTransform(d, x, y) {
  const angle = Number(val(d.angle));
  return Number.isFinite(angle) && angle !== 0 ? `rotate(${angle} ${x} ${y})` : null;
}
```

Character values such as `"inward"` and `"outward"` should be tested before support is claimed; they depend on panel-relative direction rather than a static text anchor. [VERIFIED: local ggplot2 build probe; CITED: https://ggplot2.tidyverse.org/reference/geom_text.html]

### Pattern 4: Polygon Fixture-First Decision

**What:** Compare ggplot2 built data, gg2d3 IR rows, renderer source, and optional DOM for `group` + `subgroup` hole-style input before deciding support. [VERIFIED: tests/testthat/test-polygon-ir.R; tests/testthat/test-polygon-renderer.R]

**When to use:** GEOM-02 planning and execution. [VERIFIED: .planning/REQUIREMENTS.md]

**Example:**

```r
plot <- ggplot(polygon_data, aes(x, y, group = shape, subgroup = subgroup)) +
  geom_polygon(fill = "#79A7D3", colour = "#1B365D")
built <- ggplot2::ggplot_build(plot)$data[[1]]
ir <- as_d3_ir(plot)
```

Support should require a concrete rendering purpose for preserved `subgroup`; preserving it without renderer/tests contradicts D-08. [VERIFIED: 54-CONTEXT.md]

### Anti-Patterns to Avoid

- **Adding ggrepel-like placement:** ggplot2 points automatic non-overlap to ggrepel, and D-15 defers collision avoidance. [CITED: https://ggplot2.tidyverse.org/reference/geom_text.html; VERIFIED: 54-CONTEXT.md]
- **Claiming `check_overlap` parity as collision avoidance:** ggplot2 documents `check_overlap` as draw-time, row-order behavior and not supported for `geom_label()`; it should be a documented non-goal unless specifically scoped. [CITED: https://ggplot2.tidyverse.org/reference/geom_text.html]
- **Applying text rotation before measuring label boxes:** `getBBox()` ignores transforms, so measurement/rect sizing can drift if transforms are applied at the wrong level. [CITED: https://developer.mozilla.org/en-US/docs/Web/API/SVGGraphicsElement/getBBox]
- **Doing polygon ring containment inference:** D-07 forbids broad GIS topology repair. [VERIFIED: 54-CONTEXT.md]
- **Rect-only transformed-scale refactor without failing evidence:** Existing tests classify transformed rect/tile behavior at shared scale/renderer seams. [VERIFIED: tests/testthat/test-rect-tile-ir.R; tests/testthat/test-rect-tile-renderer.R]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Text box measurement | Estimated label width from character count | SVG `getBBox()` after appending text | Browser font metrics are already exposed by SVG and used by `sf.js`. [VERIFIED: inst/htmlwidgets/modules/geoms/sf.js; CITED: https://developer.mozilla.org/en-US/docs/Web/API/SVGGraphicsElement/getBBox] |
| Text rotation math | Manual trig around x/y | SVG `transform="rotate(angle x y)"` | SVG transform syntax already supports rotation around a point. [CITED: https://developer.mozilla.org/en-US/docs/Web/SVG/Reference/Attribute/transform] |
| Label collision avoidance | Custom force/overlap solver | Explicit deferral to FUT-05 / ggrepel-style future work | ggplot2 directs automatic non-overlap to ggrepel; Phase 54 defers full placement algorithms. [CITED: https://ggplot2.tidyverse.org/reference/geom_text.html; VERIFIED: 54-CONTEXT.md] |
| Polygon topology repair | Ring containment, winding correction, invalid-polygon repair | Either compound paths from ggplot2 `subgroup` or explicit non-goal docs | Phase decisions forbid GIS topology repair; SVG `fill-rule` is only a rendering primitive, not topology validation. [VERIFIED: 54-CONTEXT.md; CITED: https://developer.mozilla.org/en-US/docs/Web/SVG/Reference/Attribute/fill-rule] |
| Transformed scale inversion | Local `untransform()` logic in rect renderer | Existing D3 scale factory with direct built-bound scaling | Current tests prove ggplot2 built transformed bounds flow into D3 scales; D3 owns log/sqrt mapping. [VERIFIED: tests/testthat/test-rect-tile-renderer.R; CITED: https://d3js.org/d3-scale/log; CITED: https://d3js.org/d3-scale/pow] |
| Pixel regression thresholds | Committed golden screenshots | Source/IR/DOM tests plus optional artifact smoke | Pixel thresholds are deferred for this milestone. [VERIFIED: 54-CONTEXT.md; tests/testthat/helper-browser-visual.R] |

**Key insight:** The risky parts are contract clarity and support signaling, not raw SVG mechanics. Label boxes and basic text placement are small if their IR shape is explicit; polygon holes and collision avoidance become large as soon as the plan implies algorithmic parity. [VERIFIED: 54-CONTEXT.md; source inspection]

## Common Pitfalls

### Pitfall 1: Label Boxes Hidden Under `geom = "text"`

**What goes wrong:** Renderer contracts and browser summaries see only text support, while label DOM introduces `g/rect/text` nodes that update/interaction selectors do not cover. [VERIFIED: inst/htmlwidgets/modules/geom-contracts.js; tests/testthat/helper-browser-visual.R]

**Why it happens:** Current `GeomLabel = "text"` collapses text and label before the renderer. [VERIFIED: R/ir_layer_helpers.R]

**How to avoid:** Either emit `geom = "label"` or add explicit label metadata and contract selectors; update `validate_ir()`, `geom-contracts.js`, and source tests together. [VERIFIED: R/validate_ir.R; tests/testthat/test-renderer-wiring-contracts.R]

**Warning signs:** New `geom-label` DOM exists but no contract selector or update selector mentions it. [VERIFIED: tests/testthat/test-renderer-wiring-contracts.R]

### Pitfall 2: Padding Units Leak As Grid Objects

**What goes wrong:** `label.padding` / `label.r` serialize as opaque R unit objects or get lost, producing inconsistent JS behavior. [VERIFIED: local ggplot2 label probe]

**Why it happens:** ggplot2 stores label padding/radius in `layer$geom_params`, while `gg2d3_ir_layer_params()` currently forwards mostly `aes_params` and only special-cases rug/dotplot. [VERIFIED: R/ir_layer_helpers.R; local ggplot2 label probe]

**How to avoid:** Convert supported label units to numeric pixels or points in R before JSON serialization; source-test the serialized params. [VERIFIED: local `grid::convertUnit()` probe]

**Warning signs:** `layer$params$label.padding` is a nested list/unit object in the IR. [VERIFIED: local ggplot2 label probe]

### Pitfall 3: Text Update Path Loses Placement

**What goes wrong:** Initial render supports `hjust`/`vjust`/`angle`, but zoom/update only changes `x/y`, so transforms and label boxes drift. [VERIFIED: inst/htmlwidgets/modules/geom-registry.js; inst/htmlwidgets/modules/geoms/text.js]

**Why it happens:** `updateGeoms()` currently updates `text.geom-text` `x` and `y` only. [VERIFIED: inst/htmlwidgets/modules/geom-registry.js]

**How to avoid:** Source-test update selectors/helpers for any new text/label transform or label group geometry, or explicitly classify labels as no-update only with reason-bearing contract if that is acceptable. [VERIFIED: tests/testthat/test-renderer-wiring-contracts.R]

**Warning signs:** `text.js` contains `rotate(` or `geom-label` but `geom-registry.js` does not. [VERIFIED: inst/htmlwidgets/modules/geoms/text.js; inst/htmlwidgets/modules/geom-registry.js]

### Pitfall 4: Polygon Subgroup Metadata Without Rendering Contract

**What goes wrong:** IR preserves `subgroup`, users infer hole support, but renderer still draws one closed path per group with no compound path or `fill-rule`. [VERIFIED: tests/testthat/test-polygon-ir.R; tests/testthat/test-polygon-renderer.R]

**Why it happens:** ggplot2 built data includes `subgroup`, but gg2d3 currently filters it out. [VERIFIED: tests/testthat/test-polygon-ir.R; R/ir_layer_helpers.R]

**How to avoid:** Preserve `subgroup` only in the same plan that either renders a bounded compound-path subset or adds explicit diagnostics/tests saying it remains non-goal. [VERIFIED: 54-CONTEXT.md]

**Warning signs:** `subgroup` appears in IR without `fill-rule`/compound-path tests. [VERIFIED: tests/testthat/test-polygon-renderer.R]

### Pitfall 5: Rect/Tile Transform Work Reopens Settled Non-Issues

**What goes wrong:** The plan changes scale or rect math broadly even though current tests already mirror ggplot2 built transformed bounds. [VERIFIED: tests/testthat/test-rect-tile-ir.R]

**Why it happens:** Transformed-scale parity sounds like a rect renderer problem, but current classification points to shared scale/axis semantics. [VERIFIED: 54-CONTEXT.md; tests/testthat/test-rect-tile-renderer.R]

**How to avoid:** Add focused render/update drift fixtures first; edit `scales.js`, `rect.js`, or `geom-registry.js` only on a failing mismatch. [VERIFIED: 54-CONTEXT.md]

**Warning signs:** New `untransform` logic or custom log/sqrt math appears in `rect.js`. [VERIFIED: tests/testthat/test-rect-tile-renderer.R]

## Code Examples

### Characterize Ordinary Label Built Data

```r
# Source: local ggplot2 4.0.3 build probe; ggplot2 docs list these aesthetics/params.
plot <- ggplot(data.frame(x = 1, y = 2, label = "A"), aes(x, y, label = label)) +
  geom_label(
    size = 4,
    fill = "white",
    colour = "black",
    linewidth = 0.7,
    hjust = 0,
    vjust = 1,
    angle = 30
  )
built <- ggplot2::ggplot_build(plot)$data[[1]]
```

Built rows include `fill`, `colour`, `size`, `linewidth`, `hjust`, `vjust`, `angle`, `family`, and `alpha`; `label.padding` and `label.r` live in `layer$geom_params`. [VERIFIED: local ggplot2 build probe]

### Convert Label Padding Before JSON

```r
# Source: local grid::convertUnit() probe.
label_padding_pt <- grid::convertUnit(layer_obj$geom_params$label.padding, "pt", valueOnly = TRUE)
label_padding_px <- label_padding_pt * 96 / 72
```

This keeps JSON params numeric instead of serializing grid unit internals. [VERIFIED: local grid probe]

### Bounded Compound Polygon Path If Implemented

```javascript
// Source concept: SVG fill-rule supports evenodd/nonzero; D3 path strings can hold multiple closed subpaths.
path
  .attr("class", "geom-polygon")
  .attr("d", compoundPathForGroupAndSubgroup(rows))
  .attr("fill-rule", rule || "evenodd");
```

This is only acceptable for a fixture-proven subset and must not infer containment or repair invalid rings. [VERIFIED: 54-CONTEXT.md; CITED: https://developer.mozilla.org/en-US/docs/Web/SVG/Reference/Attribute/fill-rule]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Ordinary `geom_label()` text-only alias | Phase 54 should attempt explicit bounded label boxes or document source-backed non-goal | Pending Phase 54 | Planner should create failing-first tests around label DOM, fill/stroke, padding, and text placement. [VERIFIED: tests/testthat/test-text-label-polish.R; 54-CONTEXT.md] |
| Ordinary polygon support without topology | Grouped closed paths are shipped; subgroup/hole is still explicit boundary | Phase 44/51 | Planner should not add topology repair; decide tiny compound-path support only from fixtures. [VERIFIED: inst/htmlwidgets/modules/geoms/polygon.js; tests/testthat/test-polygon-ir.R] |
| Rect/tile transformed parity broad concern | Direct transformed-bound scaling is likely release boundary | Phase 51/54 context | Planner should strengthen evidence and avoid broad refactor. [VERIFIED: tests/testthat/test-rect-tile-ir.R; 54-CONTEXT.md] |
| Text placement anti-feature | Small hjust/vjust/angle wins are allowed; collision/path/rich text deferred | Phase 54 context | Planner should split small renderer attributes from algorithmic placement docs. [VERIFIED: 54-CONTEXT.md] |

**Deprecated/outdated:**
- `label.size` is deprecated in ggplot2 and replaced by `linewidth`; Phase 54 should prefer `linewidth` and only mention `label.size` as legacy/non-goal if tests expose it. [CITED: https://ggplot2.tidyverse.org/reference/geom_text.html]
- README currently says text justifications and rotations are supported under theming, while diagnostics says ordinary text/label placement is not translated; Phase 54 or Phase 55 must keep public support language aligned after implementation decisions. [VERIFIED: README.Rmd; vignettes/d3-drawing-diagnostics.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Numeric conversion of `label.padding`/`label.r` to px is sufficient for Phase 54 bounded label support. [ASSUMED] | Architecture Patterns / Common Pitfalls | Visual padding may differ from ggplot2 enough that diagnostics should narrow support further. |
| A2 | Emitting ordinary `GeomLabel` as `geom = "label"` is preferable to hidden metadata under `geom = "text"`. [ASSUMED] | Pattern 1 | Planner may choose a metadata branch to reduce IR churn, but must compensate with contract tests. |
| A3 | Browser visual smoke for ordinary labels is useful but not mandatory if source/DOM tests cover selectors and geometry. [ASSUMED] | Validation Architecture | Planner may decide a live DOM `getBBox()` fixture is required because label sizing depends on browser metrics. |
| A4 | Prefer explicit `geom = "label"` and update contracts; if planner chooses metadata, require explicit render/update selectors and tests. [ASSUMED] | Open Questions | Planner may prefer metadata for compatibility, changing task split and contract updates. |
| A5 | Compound subpaths from built row order may or may not match ggplot2 enough for ordinary hole fixtures without topology inference. [ASSUMED] | Open Questions | A premature implementation could overclaim polygon hole support or fail visual parity. |
| A6 | Inward/outward justification may require panel-center logic and carries drift risk. [ASSUMED] | Open Questions | Planner could over-scope text placement if these values are treated as simple anchors. |
| A7 | Ship numeric and simple character anchors first; explicitly defer inward/outward if not trivial. [ASSUMED] | Open Questions | User may expect fuller ggplot2 justification parity unless docs are precise. |

## Open Questions (RESOLVED)

1. **Should ordinary `GeomLabel` become `geom = "label"` or remain `geom = "text"` with label metadata?**
   - What we know: current aliasing hides label support from contracts, and label DOM will differ from text DOM. [VERIFIED: R/ir_layer_helpers.R; inst/htmlwidgets/modules/geom-contracts.js]
   - Resolution: Phase 54 planning selects explicit `geom = "label"` for ordinary `GeomLabel`, with `validate_ir()`, renderer contracts, update selectors, and tests updated together. This avoids hidden label behavior under the `"text"` geom while keeping stop/rollback guidance if implementation proves unsafe.

2. **Is a tiny polygon hole subset worth shipping?**
   - What we know: ggplot2 has `subgroup` and `rule`; SVG has `fill-rule`; gg2d3 currently avoids topology semantics. [CITED: https://ggplot2.tidyverse.org/reference/geom_polygon.html; CITED: https://developer.mozilla.org/en-US/docs/Web/SVG/Reference/Attribute/fill-rule; VERIFIED: tests/testthat/test-polygon-renderer.R]
   - Resolution: Phase 54 planning selects fixture-led non-goal closure for ordinary polygon subgroup/hole topology. It will not preserve `subgroup` in ordinary polygon IR without bounded renderer semantics, and it will not add topology repair, containment inference, winding repair, or invalid-polygon repair.

3. **Should character `hjust`/`vjust` values be supported beyond simple left/middle/right/top/center/bottom?**
   - What we know: ggplot2 supports numeric and character values including inward/outward. [CITED: https://ggplot2.tidyverse.org/reference/geom_text.html]
   - Resolution: Phase 54 planning selects numeric and simple character anchors only. `inward` and `outward` remain deferred unless implementation proves they are trivial within the existing renderer-local placement path.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| R | Package tests and IR probes | yes | 4.6.0 | none |
| ggplot2 | Built-data characterization | yes | 4.0.3 | none |
| testthat | Automated validation | yes | 3.3.2 | none |
| pkgload | Targeted test commands | yes | 1.5.2 | `devtools::load_all()` |
| chromote | Optional browser visual smoke | yes | 0.5.1 | Source/IR tests if smoke not needed |
| Chrome | Optional chromote browser | yes | `/Applications/Google Chrome.app/Contents/MacOS/Google Chrome` | Skip browser smoke locally; CI mode should fail unexpected browser skips |
| sf | Existing sf browser rows | no | - | Expected optional skip for sf-specific rows |
| geojsonsf | Existing sf serialization rows | yes | 2.0.5 | sf rows still skip without `sf` |
| Node.js | GSD graph/tooling only | yes | v26.0.0 | Not required for R package validation |

**Missing dependencies with no fallback:**
- None for Phase 54 ordinary label/polygon/rect/text source validation. [VERIFIED: local environment audit]

**Missing dependencies with fallback:**
- `sf` is missing; this affects existing sf visual-smoke rows only and should remain an optional skip unless planner adds sf-specific validation. [VERIFIED: local environment audit; tests/testthat/test-browser-visual-smoke.R]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | testthat 3.3.2 with pkgload 1.5.2 [VERIFIED: local Rscript] |
| Config file | DESCRIPTION `Config/testthat/edition: 3` [VERIFIED: DESCRIPTION] |
| Quick run command | `rtk Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-text-label-polish.R"); testthat::test_file("tests/testthat/test-polygon-ir.R"); testthat::test_file("tests/testthat/test-rect-tile-ir.R")'` |
| Renderer contract command | `rtk Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-polygon-renderer.R"); testthat::test_file("tests/testthat/test-rect-tile-renderer.R"); testthat::test_file("tests/testthat/test-renderer-wiring-contracts.R")'` |
| Optional browser smoke command | `rtk env NOT_CRAN=true GG2D3_BROWSER_VISUAL_SMOKE=true Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-browser-visual-smoke.R")'` |
| Full suite command | `rtk Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); devtools::test()'` |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| GEOM-01 | Ordinary `geom_label()` has bounded box/padding/fill/stroke/text support or explicit diagnostics | unit/source/optional DOM | `rtk Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-text-label-polish.R")'` | yes; update in Wave 0 |
| GEOM-02 | Polygon subgroup/hole boundary is fixture-proven as tiny support or non-goal | unit/source/optional DOM | `rtk Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-polygon-ir.R"); testthat::test_file("tests/testthat/test-polygon-renderer.R")'` | yes; extend in Wave 0 |
| GEOM-03 | Rect/tile log/sqrt/reverse transformed bounds and render/update consistency are resolved or carried forward with narrower evidence | unit/source | `rtk Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-rect-tile-ir.R"); testthat::test_file("tests/testthat/test-rect-tile-renderer.R")'` | yes; extend in Wave 0 |
| GEOM-04 | hjust/vjust/angle candidates are shipped or deferred without implying collision/path parity | unit/source/docs | `rtk Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-text-label-polish.R")'` | yes; update in Wave 0 |
| GEOM-01/04 | Label/text selectors remain contract-covered after renderer changes | source contract | `rtk Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-renderer-wiring-contracts.R")'` | yes; update if `label` alias added |
| GEOM-01/02/03/04 | Optional browser artifacts distinguish shipped DOM support from skips/failures | browser smoke | `rtk env NOT_CRAN=true GG2D3_BROWSER_VISUAL_SMOKE=true Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-browser-visual-smoke.R")'` | yes; add rows only if planner wants downstream confidence |

### Sampling Rate

- **Per task commit:** Run the relevant targeted test file(s) for touched files. [VERIFIED: existing phase summaries and test style]
- **Per wave merge:** Run quick command plus renderer contract command. [VERIFIED: local targeted commands passed]
- **Phase gate:** Run quick command, renderer contract command, diagnostics grep, and optional browser smoke if DOM label/polygon behavior was shipped. [VERIFIED: 54-CONTEXT.md; tests/testthat/helper-browser-visual.R]

### Wave 0 Gaps

- [ ] `tests/testthat/test-text-label-polish.R` — update characterization from "label maps to text without box" to failing-first shipped/non-goal expectations for GEOM-01 and GEOM-04. [VERIFIED: tests/testthat/test-text-label-polish.R]
- [ ] `tests/testthat/test-polygon-ir.R` — add focused comparison fixtures for `subgroup` + `rule` and expected boundary/support for GEOM-02. [VERIFIED: tests/testthat/test-polygon-ir.R]
- [ ] `tests/testthat/test-polygon-renderer.R` — either prove compound-path/fill-rule subset or strengthen non-goal source contract. [VERIFIED: tests/testthat/test-polygon-renderer.R]
- [ ] `tests/testthat/test-rect-tile-ir.R` and `tests/testthat/test-rect-tile-renderer.R` — add narrower transformed render/update evidence for GEOM-03. [VERIFIED: tests/testthat/test-rect-tile-ir.R; tests/testthat/test-rect-tile-renderer.R]
- [ ] `tests/testthat/test-renderer-wiring-contracts.R` — update only if label selectors/aliases change. [VERIFIED: tests/testthat/test-renderer-wiring-contracts.R]
- [ ] `vignettes/d3-drawing-diagnostics.md` — update shipped support versus future requirements after implementation decisions. [VERIFIED: vignettes/d3-drawing-diagnostics.md]

### Baseline Results

- Targeted text/polygon/rect IR baseline passed: `test-text-label-polish.R`, `test-polygon-ir.R`, and `test-rect-tile-ir.R`. [VERIFIED: local test run]
- Renderer and contract baseline passed: `test-polygon-renderer.R`, `test-rect-tile-renderer.R`, and `test-renderer-wiring-contracts.R`. [VERIFIED: local test run]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | no | No auth surface in this phase. [VERIFIED: source inspection] |
| V3 Session Management | no | No session surface in this phase. [VERIFIED: source inspection] |
| V4 Access Control | no | No access-control surface in this phase. [VERIFIED: source inspection] |
| V5 Input Validation | yes | Preserve validated IR schema via `validate_ir()` and test built-data/IR rows before renderer use. [VERIFIED: R/validate_ir.R; tests/testthat] |
| V6 Cryptography | no | No cryptography introduced. [VERIFIED: source inspection] |

### Known Threat Patterns for R/htmlwidgets SVG Rendering

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Script/HTML injection through labels | Tampering / XSS | Use SVG `.text(...)` for labels, not `.html(...)`; keep tooltip/sanitizer behavior unchanged. [VERIFIED: inst/htmlwidgets/modules/geoms/text.js; inst/htmlwidgets/modules/public-data.js] |
| Private renderer fields leaking to callbacks | Information Disclosure | Continue routing public payloads through `publicData.sanitizeDatum()` and declare private fields in `geom-contracts.js`. [VERIFIED: inst/htmlwidgets/modules/public-data.js; tests/testthat/test-renderer-wiring-contracts.R] |
| Malformed geometry values causing invalid DOM attributes | Tampering / DoS | Filter invalid/NA geometry rows as existing rect/polygon renderers do and characterize against `ggplot_build()`. [VERIFIED: inst/htmlwidgets/modules/geoms/polygon.js; inst/htmlwidgets/modules/geoms/rect.js; tests/testthat/test-polygon-ir.R] |

## Sources

### Primary (HIGH confidence)
- `.planning/phases/54-geometry-polish-closure/54-CONTEXT.md` - locked Phase 54 decisions and canonical refs.
- `.planning/REQUIREMENTS.md` - GEOM-01 through GEOM-04 requirements.
- `.planning/ROADMAP.md` and `.planning/PROJECT.md` - phase goal, milestone context, evidence-driven geometry decisions.
- `CLAUDE.md`, `AGENTS.md`, `/Users/davidzenz/.codex/RTK.md` - project and shell constraints.
- `R/ir_layer_helpers.R`, `R/as_d3_ir.R`, `R/validate_ir.R` - IR dispatch, row preservation, and validation seams.
- `inst/htmlwidgets/modules/geoms/text.js`, `sf.js`, `polygon.js`, `rect.js`, `geom-registry.js`, `scales.js`, `geom-contracts.js` - renderer and contract seams.
- `tests/testthat/test-text-label-polish.R`, `test-polygon-ir.R`, `test-polygon-renderer.R`, `test-rect-tile-ir.R`, `test-rect-tile-renderer.R`, `test-renderer-wiring-contracts.R`, `test-browser-visual-smoke.R`, `helper-browser-visual.R` - existing validation patterns.
- `.planning/milestones/v1.11-phases/44-ordinary-geom-polygon-support/44-CONTEXT.md`, `44-RESEARCH.md`, `44-PATTERNS.md` - ordinary polygon support boundary.
- `.planning/milestones/v1.11-phases/45-rect-and-tile-edge-closure/45-RECT-TILE-CLASSIFICATION.md`, `45-01-SUMMARY.md`, `45-02-SUMMARY.md` - rect/tile classification and closure evidence.

### Secondary (MEDIUM confidence)
- ggplot2 official docs for `geom_text()` / `geom_label()` - https://ggplot2.tidyverse.org/reference/geom_text.html
- ggplot2 official docs for `geom_polygon()` - https://ggplot2.tidyverse.org/reference/geom_polygon.html
- ggplot2 official docs for `geom_rect()` / `geom_tile()` - https://ggplot2.tidyverse.org/reference/geom_tile.html
- D3 official scale docs - https://d3js.org/d3-scale, https://d3js.org/d3-scale/log, https://d3js.org/d3-scale/pow
- MDN SVG docs for `getBBox()`, `transform`, and `fill-rule` - https://developer.mozilla.org/en-US/docs/Web/API/SVGGraphicsElement/getBBox, https://developer.mozilla.org/en-US/docs/Web/SVG/Reference/Attribute/transform, https://developer.mozilla.org/en-US/docs/Web/SVG/Reference/Attribute/fill-rule

### Tertiary (LOW confidence)
- None. WebSearch findings were verified against official docs or local source. [VERIFIED: source review]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - versions and dependencies were verified locally; no new dependencies recommended.
- Architecture: HIGH - implementation seams are directly visible in current R/JS modules and tests.
- Label visual parity: MEDIUM - SVG `getBBox()` gives a bounded path, but exact ggplot2 padding/radius/justification parity may require narrowing after browser fixtures.
- Polygon topology: MEDIUM - source docs show a possible `subgroup`/`fill-rule` subset, but D-06/D-07 make non-goal the default unless fixtures prove it small.
- Rect/tile transformed-scale boundary: HIGH - current tests and source contracts already establish the direct transformed-bound path.

**Research date:** 2026-05-28
**Valid until:** 2026-06-27 for local codebase findings; re-check ggplot2/D3 docs if dependencies change.
