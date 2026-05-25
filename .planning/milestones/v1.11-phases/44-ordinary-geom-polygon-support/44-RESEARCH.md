# Phase 44: Ordinary geom_polygon Support - Research

**Researched:** 2026-05-24
**Domain:** R ggplot2 IR extraction + htmlwidgets D3 SVG renderer + interaction selectors [VERIFIED: .planning/ROADMAP.md; AGENTS.md]
**Confidence:** HIGH for codebase integration, MEDIUM for browser fixture execution risk [VERIFIED: source inspection; local environment audit]

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
## Implementation Decisions

### Polygon Group Semantics
- **D-01:** Render ordinary `geom_polygon()` as one SVG path per `group`, preserving row order from ggplot2 built data.
- **D-02:** Support multiple groups/polygons in one layer when ggplot2 built data provides distinct groups.
- **D-03:** Defer explicit hole/subgroup/topology semantics unless ggplot2 built data already represents them cleanly without special topology work.
- **D-04:** Treat row-order preservation as part of the public rendering contract; planners should avoid automatic sorting that would reorder intentional polygon paths.

### Styling Contract
- **D-05:** Lock core visible polygon styling in Phase 44: `fill`, `colour`/stroke, `alpha`, `linewidth`, and `linetype`.
- **D-06:** `fill = NA` should render as no fill, and `colour = NA` should render as no stroke.
- **D-07:** Broader styling edge cases beyond the core polygon contract are not Phase 44 scope unless they fall out naturally from existing helpers.

### Interactivity Behavior
- **D-08:** Ordinary polygon marks are interactive at the group/path level.
- **D-09:** Tooltip, hover, custom handler, and Shiny-style handler payloads should use a sanitized representative source row for the polygon group.
- **D-10:** Brush selection should use SVG path bounds for ordinary Cartesian polygons rather than sf-style centroid/anchor semantics.
- **D-11:** Do not create a new polygon-specific interactivity API; reuse existing tooltip, hover, brush, and handler plumbing.

### Validation Matrix
- **D-12:** Phase 44 should include IR tests, JavaScript source/contract tests, and browser DOM smoke coverage.
- **D-13:** Representative validation cases must include: single polygon, multiple groups, facets, mapped styling, `NA` fill/stroke behavior, and interactivity selectors/payload sanitization.
- **D-14:** Do not add screenshot or perceptual comparison infrastructure in Phase 44; DOM/source assertions are the expected automated gate.

### the agent's Discretion
- Exact helper names, file split, and fixture names are left to research/planning.
- Planner may decide whether to implement polygon rendering in a new `inst/htmlwidgets/modules/geoms/polygon.js` file or another established renderer location, provided registry and bundle conventions are followed.
- Planner may choose the exact representative source row for group-level payloads, as long as the choice is deterministic, sanitized, and documented in tests.

### Claude's Discretion
- Exact helper names, file split, and fixture names are left to research/planning.
- Planner may decide whether to implement polygon rendering in a new `inst/htmlwidgets/modules/geoms/polygon.js` file or another established renderer location, provided registry and bundle conventions are followed.
- Planner may choose the exact representative source row for group-level payloads, as long as the choice is deterministic, sanitized, and documented in tests.

### Deferred Ideas (OUT OF SCOPE)
- Explicit polygon hole/subgroup/topology support beyond clean ggplot2 built-data grouping.
- Screenshot or perceptual visual regression infrastructure.
- sf text/label annotations, covered by Phase 46.
- Rect/tile out-of-bounds behavior, covered by Phase 45.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| POLY-01 | `as_d3_ir()` recognizes ordinary `geom_polygon()` layers and preserves grouped polygon row order, x/y coordinates, and mapped fill, stroke, alpha, linewidth, and linetype aesthetics. [VERIFIED: .planning/REQUIREMENTS.md] | `R/as_d3_ir.R` already maps `GeomPolygon` to `"polygon"` and keeps `PANEL`, `x`, `y`, `colour`, `fill`, `alpha`, `group`, `linewidth`, and `linetype`; plan targeted characterization tests rather than broad extractor refactor. [VERIFIED: R/as_d3_ir.R:224, R/as_d3_ir.R:238-252, local R fixture] |
| POLY-02 | The D3 renderer draws ordinary `geom_polygon()` groups as closed SVG paths that match ggplot2 positioning, fill/stroke styling, clipping, and facet panel placement for representative Cartesian plots. [VERIFIED: .planning/REQUIREMENTS.md] | Add and register an ordinary `polygon` renderer loaded by `gg2d3.yaml`; rely on existing panel filtering/clipping in `gg2d3.js`; use D3 closed path generation and existing style helpers with polygon-specific `NA` fill/stroke handling. [VERIFIED: inst/htmlwidgets/gg2d3.yaml:26-43, inst/htmlwidgets/gg2d3.js:76-131; CITED: https://d3js.org/d3-shape/curve] |
| POLY-03 | Existing tooltip, hover, brush, and custom handler APIs can target ordinary polygon marks with stable classes, row identity, and sanitized callback payloads. [VERIFIED: .planning/REQUIREMENTS.md] | Add `path.geom-polygon` to `events.js`, `brush.js`, and likely `crosstalk.js`; bind a representative sanitized row to each path so current tooltip/handler sanitizers receive an object, not an array. [VERIFIED: inst/htmlwidgets/modules/events.js:23-44, inst/htmlwidgets/modules/brush.js:29-50, inst/htmlwidgets/modules/crosstalk.js:22-36, inst/htmlwidgets/modules/tooltip.js:117-156] |
</phase_requirements>

## Summary

Phase 44 should be planned as a narrow ordinary-geom extension across the existing R -> IR -> D3 pipeline, not as a spatial/topology feature. [VERIFIED: .planning/phases/44-ordinary-geom-polygon-support/44-CONTEXT.md; AGENTS.md] The R side already recognizes `GeomPolygon` and emits the required row-level aesthetics, so the highest-value R work is characterization coverage for row-order preservation, group splits, facets, mapped styling, and `NA` styling cases. [VERIFIED: R/as_d3_ir.R:224, R/as_d3_ir.R:238-252, local R fixture]

The implementation should add a dedicated ordinary polygon renderer that creates one `path.geom-polygon` per built-data group, preserves the group row order, uses a closed path, applies fill/stroke/alpha/linewidth/linetype from the group representative row, and registers the renderer in the module registry and yaml bundle. [VERIFIED: inst/htmlwidgets/modules/geom-registry.js:64-108, inst/htmlwidgets/gg2d3.yaml:26-43; CITED: https://d3js.org/d3-shape/curve] Facet placement and clipping should remain owned by `gg2d3.js`, which already filters non-sf layer rows by `PANEL` and renders into a clipped panel group. [VERIFIED: inst/htmlwidgets/gg2d3.js:76-131]

Interactivity should be a selector/data-binding change, not a new API. [VERIFIED: .planning/phases/44-ordinary-geom-polygon-support/44-CONTEXT.md] The existing tooltip, hover, custom handler, Shiny handler, and brush modules are selector-driven and already sanitize underscore-prefixed renderer-private fields. [VERIFIED: inst/htmlwidgets/modules/events.js:56-65, inst/htmlwidgets/modules/events.js:666-700, inst/htmlwidgets/modules/tooltip.js:117-156, inst/htmlwidgets/modules/brush.js:397-440] Browser smoke coverage should reuse the established optional R/testthat/chromote pattern and assert DOM state/payloads, not screenshots. [VERIFIED: tests/testthat/helper-browser-sf.R:21-47, tests/testthat/test-sf-browser.R:1-24; .planning/phases/44-ordinary-geom-polygon-support/44-CONTEXT.md]

**Primary recommendation:** Plan three small waves: first lock R IR fixtures, second add `geoms/polygon.js` plus bundle/source guards, third add selector/payload/brush/browser coverage for `path.geom-polygon`. [VERIFIED: .planning/ROADMAP.md; source inspection]

## Project Constraints (from AGENTS.md)

- Use `rtk` as the shell-command prefix while working in this repository. [VERIFIED: /Users/davidzenz/.codex/RTK.md]
- The package architecture is a three-layer pipeline: R extraction in `R/as_d3_ir.R`, JSON-serializable IR, and D3 SVG rendering in `inst/htmlwidgets/gg2d3.js` plus modules. [VERIFIED: AGENTS.md]
- Development commands are `devtools::load_all()`, `devtools::document()`, `devtools::test()`, `testthat::test_file(...)`, and `devtools::build_readme()`. [VERIFIED: AGENTS.md]
- D3 v7 is vendored locally under `inst/htmlwidgets/lib/d3/d3.v7.min.js` and configured through `inst/htmlwidgets/gg2d3.yaml`. [VERIFIED: AGENTS.md; inst/htmlwidgets/gg2d3.yaml:7-11]
- Known current limitations include ordinary `geom_polygon()` not rendering because no renderer is registered; Phase 44 is the planned closure for that gap. [VERIFIED: vignettes/gg2d3.Rmd:561-568; .planning/ROADMAP.md]
- Do not expand Phase 44 into legends/facets beyond existing panel support, GIS topology repair, sf annotations, rect/tile behavior, screenshot diffs, or new interactivity APIs. [VERIFIED: .planning/phases/44-ordinary-geom-polygon-support/44-CONTEXT.md]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Recognize `GeomPolygon` and preserve built rows | R Layer | IR Layer | `as_d3_ir()` owns ggplot2 build extraction and already maps `GeomPolygon` to `"polygon"` while rowizing built data. [VERIFIED: R/as_d3_ir.R:172-377] |
| Group polygon vertices into one mark per group | D3 Layer | IR Layer | The IR should preserve rows; the renderer should group rows by `group` at render time, matching existing area/ribbon/line patterns. [VERIFIED: inst/htmlwidgets/modules/geoms/area.js:49-56, inst/htmlwidgets/modules/geoms/line.js:52-87] |
| Closed path creation | D3 Layer | — | D3 path/shape utilities create SVG path data; D3 documents closed linear curves and `closePath` semantics. [CITED: https://d3js.org/d3-shape/curve; CITED: https://d3js.org/d3-path] |
| Facet filtering and clipping | D3 widget shell | D3 geom renderer | `gg2d3.js` filters ordinary layer data by `PANEL` and renders into `g[clip-path]`; polygon renderer should not duplicate this. [VERIFIED: inst/htmlwidgets/gg2d3.js:76-131] |
| Polygon styling | D3 Layer | IR Layer | The renderer consumes row/param aesthetics and helper conversions; R side supplies built aesthetic columns. [VERIFIED: R/as_d3_ir.R:238-252, inst/htmlwidgets/modules/geom-registry.js:127-190] |
| Tooltip, hover, handlers | Interactivity modules | D3 geom renderer | `events.js` attaches handlers by selector and exposes sanitized data; polygon must emit a matching selector and useful bound datum. [VERIFIED: inst/htmlwidgets/modules/events.js:23-44, inst/htmlwidgets/modules/events.js:546-700] |
| Brush selection | Brush module | D3 geom renderer | `brush.js` selects elements by selector and uses generic `path.getBBox()` for non-sf paths; polygon must use ordinary path behavior, not sf centroid attributes. [VERIFIED: inst/htmlwidgets/modules/brush.js:266-327] |
| Optional browser smoke validation | R test layer | Browser runtime | Existing browser validation uses testthat + chromote with clean skips and DOM assertions. [VERIFIED: tests/testthat/helper-browser-sf.R:21-47, tests/testthat/test-sf-browser.R:1-24] |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| R | 4.6.0 local; package requires >= 4.1.0 | Package runtime and test execution. [VERIFIED: local `Rscript`; DESCRIPTION] | Existing package target and local runtime. [VERIFIED: DESCRIPTION] |
| ggplot2 | 4.0.3 local; imported without pinned version | Source plot build system and `GeomPolygon` semantics. [VERIFIED: local `Rscript`; DESCRIPTION] | Official `geom_polygon()` docs define grouping, closure, fill/stroke aesthetics, and subgroup holes; Phase 44 explicitly excludes new topology work. [CITED: https://ggplot2.tidyverse.org/reference/geom_polygon.html; VERIFIED: 44-CONTEXT.md] |
| htmlwidgets | 1.6.4 local; imported | Widget serialization and dependency loading. [VERIFIED: local `Rscript`; DESCRIPTION] | Existing package transport for IR into the browser. [VERIFIED: R/gg2d3.R:44-55] |
| D3 | v7 vendored; docs site currently identifies D3 7.9.0 | SVG path generation and DOM rendering. [VERIFIED: inst/htmlwidgets/gg2d3.yaml:7-11; CITED: https://d3js.org/d3-shape/curve] | Existing renderer stack and module registry are D3-based. [VERIFIED: inst/htmlwidgets/modules/geom-registry.js:1-12] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| testthat | 3.3.2 local; package suggests >= 3.0.0 | Unit/source tests for IR, renderer source contracts, and interactivity selectors. [VERIFIED: local `Rscript`; DESCRIPTION] | Required for POLY-01/02/03 automated gates. [VERIFIED: tests/testthat directory] |
| chromote | 0.5.1 local; package suggests >= 0.5.1 | Optional browser DOM smoke validation. [VERIFIED: local `Rscript`; DESCRIPTION] | Use for D-12 browser smoke coverage with skip behavior matching sf tests. [VERIFIED: tests/testthat/helper-browser-sf.R:21-47] |
| V8 | 8.2.0 local; package suggests V8 | Optional JS parsing/execution checks if planner wants non-browser JS validation. [VERIFIED: local `Rscript`; DESCRIPTION] | Useful for source-level JS guards, but browser DOM tests remain necessary for SVG path/brush behavior. [VERIFIED: DESCRIPTION; tests/testthat/test-sf-browser.R] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Dedicated `geoms/polygon.js` | Reuse `geoms/line.js` with a `polygon` branch | A branch in `line.js` risks accidental `geom_line` sorting/line defaults; a dedicated module keeps Phase 44 scoped and mirrors other one-geom files. [VERIFIED: inst/htmlwidgets/modules/geoms/line.js:102-126; 44-CONTEXT.md] |
| D3 `line().curve(d3.curveLinearClosed)` | Append `"Z"` to an ordinary `d3.line()` path | Both are documented D3 closure strategies; `curveLinearClosed` expresses the intended closed polyline in the generator and avoids string manipulation. [CITED: https://d3js.org/d3-shape/curve; CITED: https://d3js.org/d3-path] |
| New polygon brush algorithm | Existing generic path bounding-box hit-test | Locked decision requires path bounds; `brush.js` already uses `getBBox()` for non-sf paths. [VERIFIED: 44-CONTEXT.md; inst/htmlwidgets/modules/brush.js:316-327] |
| New polygon interactivity API | Existing selector-based tooltip/hover/brush/handler API | Locked decision forbids a polygon-specific API; existing modules are selector-driven. [VERIFIED: 44-CONTEXT.md; inst/htmlwidgets/modules/events.js:23-44] |

**Installation:** No new package installation is required for the implementation path. [VERIFIED: DESCRIPTION; source inspection]

**Version verification:** Local versions were verified with `Rscript --vanilla`; package registry lookups are not required because Phase 44 uses existing declared dependencies. [VERIFIED: local environment audit]

## Architecture Patterns

### System Architecture Diagram

```text
ggplot object
  |
  v
ggplot2::ggplot_build()
  |
  v
R/as_d3_ir.R
  |-- detect GeomPolygon -> layer$geom = "polygon"
  |-- preserve built rows: PANEL, x/y, group, fill, colour, alpha, linewidth, linetype
  v
IR layer list
  |
  v
htmlwidgets serialization
  |
  v
inst/htmlwidgets/gg2d3.js renderPanel()
  |-- choose panel scales
  |-- create clipPath + clipped data group
  |-- filter non-sf rows by PANEL
  v
geomRegistry.render(layer = "polygon")
  |
  v
geoms/polygon.js
  |-- group rows by group
  |-- preserve row order within each group
  |-- create closed SVG path per group
  |-- bind representative public row
  |-- set class path.geom-polygon and styling
  v
events.js / brush.js / crosstalk.js selectors
  |-- tooltip, hover, handlers, Shiny payload
  |-- brush uses path getBBox bounds
```

Diagram reflects existing data flow and proposed polygon hook points. [VERIFIED: AGENTS.md; R/as_d3_ir.R; inst/htmlwidgets/gg2d3.js; inst/htmlwidgets/modules]

### Recommended Project Structure

```text
R/
├── as_d3_ir.R                         # existing GeomPolygon extraction
└── validate_ir.R                      # polygon already recognized
inst/htmlwidgets/
├── gg2d3.yaml                         # add geoms/polygon.js after line/path or before sf
└── modules/
    ├── geom-registry.js               # add polygon zoom/update path if needed
    ├── events.js                      # add path.geom-polygon selector
    ├── brush.js                       # add path.geom-polygon selector
    ├── crosstalk.js                   # add path.geom-polygon selector if crosstalk row binding is in scope
    └── geoms/polygon.js               # new ordinary polygon renderer
tests/testthat/
├── test-polygon-ir.R                  # POLY-01 fixtures
├── test-polygon-renderer.R            # POLY-02 source contracts
├── test-polygon-interactivity.R       # POLY-03 selector/payload source contracts
└── test-polygon-browser.R             # optional chromote DOM smoke coverage
```

Structure follows existing module/test patterns. [VERIFIED: inst/htmlwidgets/gg2d3.yaml:26-43; tests/testthat/test-sf-renderer.R; tests/testthat/test-sf-interactivity.R; tests/testthat/test-sf-browser.R]

### Pattern 1: Preserve Built Row Order

**What:** Use ggplot2 built row order as the polygon vertex order, grouping by `group` without sorting. [VERIFIED: 44-CONTEXT.md; local R fixture]

**When to use:** Always for ordinary `geom_polygon()`, because ggplot2 polygon/path semantics depend on vertex order. [CITED: https://ggplot2.tidyverse.org/reference/geom_polygon.html]

**Example:**

```javascript
// Source pattern: area.js and line.js group by row data, but polygon must not sort.
const grouped = d3.group(dat, d => val(get(d, "group")) ?? 1);
grouped.forEach(arr => {
  const pts = arr.map(d => ({ x: num(get(d, aes.x)), y: num(get(d, aes.y)), d }));
  // No sort here: polygon row order is the rendering contract.
});
```

Source basis: `area.js` groups by `group`, `line.js` preserves order for `geom_path`, and Phase 44 locks no sorting. [VERIFIED: inst/htmlwidgets/modules/geoms/area.js:49-56; inst/htmlwidgets/modules/geoms/line.js:102-109; 44-CONTEXT.md]

### Pattern 2: One Bound Public Row Per Group Path

**What:** Bind the representative row object, not the full point array, to each `path.geom-polygon`; keep the point array local for path generation or store only renderer-private fields with underscore prefixes if unavoidable. [VERIFIED: inst/htmlwidgets/modules/events.js:56-65; inst/htmlwidgets/modules/tooltip.js:117-156]

**When to use:** For tooltip/handler/brush payloads that need one stable group-level payload. [VERIFIED: 44-CONTEXT.md]

**Example:**

```javascript
// Source pattern: events.js and tooltip.js sanitize object data by dropping underscore keys.
const representative = Object.assign({}, pts[0].d);
representative._polygonPoints = pts;

g.append("path")
  .datum(representative)
  .attr("class", "geom-polygon")
  .attr("d", polygonPath(pts));
```

If this pattern is used, tests must prove `_polygonPoints` never appears in tooltip/handler/brush payloads. [VERIFIED: inst/htmlwidgets/modules/events.js:56-65; inst/htmlwidgets/modules/tooltip.js:117-156; inst/htmlwidgets/modules/brush.js:397-440]

### Pattern 3: Closed Path Generation With D3

**What:** Use D3 closed line generation for polygon paths, or call a D3 path serializer and `closePath()`. [CITED: https://d3js.org/d3-shape/curve; CITED: https://d3js.org/d3-path]

**When to use:** Ordinary Cartesian polygons represented by x/y vertices. [VERIFIED: 44-CONTEXT.md]

**Example:**

```javascript
// Source: D3 curve docs describe curveLinearClosed as a closed polyline.
const line = d3.line()
  .curve(d3.curveLinearClosed)
  .x(p => xScale(p.x) + xOff)
  .y(p => yScale(p.y) + yOff);
```

### Pattern 4: Style From Representative Row With Explicit NA Handling

**What:** Use built row aesthetics first, then params/defaults, but convert `NA`/`null` fill to `"none"` and `NA`/`null` stroke to `"none"` only when the user explicitly set or ggplot built row supplies missing values. [VERIFIED: local R fixture; 44-CONTEXT.md]

**When to use:** Polygon fill/stroke because Phase 44 locks `fill = NA` and `colour = NA` semantics. [VERIFIED: 44-CONTEXT.md]

**Example:**

```javascript
// Source pattern: sf.js uses getDashArray and mmToPxLinewidth; polygon must add NA handling.
function isMissingAesthetic(value) {
  return value === null || value === undefined || value === "NA" ||
    (typeof value === "number" && Number.isNaN(value));
}

path
  .attr("fill", d => isMissingAesthetic(d.fill) ? "none" : fillColor(d))
  .attr("stroke", d => isMissingAesthetic(d.colour) ? "none" : strokeColor(d))
  .attr("stroke-width", d => mmToPxLinewidth(val(d.linewidth) ?? params.linewidth ?? 0.5))
  .attr("stroke-dasharray", d => getDashArray(val(d.linetype) || params.linetype));
```

Existing `makeColorAccessors()` defaults missing fill to `grey35` and missing stroke to `currentColor`, so polygon needs explicit `NA` handling to satisfy D-06. [VERIFIED: inst/htmlwidgets/modules/geom-registry.js:144-176; local R fixture; 44-CONTEXT.md]

### Anti-Patterns to Avoid

- **Sorting polygon points:** Sorting by x breaks intentional polygon vertex order. [VERIFIED: 44-CONTEXT.md; inst/htmlwidgets/modules/geoms/line.js:102-109]
- **Using sf renderer/projection for ordinary polygons:** Ordinary polygons are Cartesian x/y marks and should use current scales, panel clipping, and generic path brushing. [VERIFIED: 44-CONTEXT.md; inst/htmlwidgets/modules/geoms/sf.js:46-105]
- **Binding full point arrays to public interactivity:** Existing tooltip can unwrap arrays, but D-09 asks for a representative source row and brush sanitizer only treats arrays as arrays, not representative rows. [VERIFIED: inst/htmlwidgets/modules/tooltip.js:139-156; inst/htmlwidgets/modules/brush.js:400-408; 44-CONTEXT.md]
- **Adding selector in only one interaction module:** `events.js`, `brush.js`, and `crosstalk.js` each maintain local selector arrays. [VERIFIED: inst/htmlwidgets/modules/events.js:23-44; inst/htmlwidgets/modules/brush.js:29-50; inst/htmlwidgets/modules/crosstalk.js:22-36]
- **Treating holes/subgroup as Phase 44:** ggplot2 supports `subgroup` holes, but Phase 44 defers explicit hole/topology semantics unless clean built data falls out naturally. [CITED: https://ggplot2.tidyverse.org/reference/geom_polygon.html; VERIFIED: 44-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| SVG path serialization | Custom string concatenation for `M/L/Z` commands | `d3.line().curve(d3.curveLinearClosed)` or D3 path serializer | D3 already implements closed polyline/path semantics. [CITED: https://d3js.org/d3-shape/curve; CITED: https://d3js.org/d3-path] |
| Facet placement | Custom facet routing in `polygon.js` | Existing `gg2d3.js` panel filtering and clipped groups | Non-sf layers are already filtered by `PANEL` and passed to renderer inside the panel clip path. [VERIFIED: inst/htmlwidgets/gg2d3.js:76-131] |
| Interactivity API | New `d3_polygon_*` options | Existing selector-based tooltip/hover/brush/handler modules | Phase 44 locks reuse of existing APIs. [VERIFIED: 44-CONTEXT.md] |
| Brush geometry overlap | Point-in-polygon or computational geometry | Existing path bounding box center hit-test | Phase 44 locks SVG path bounds; `brush.js` already uses `getBBox()` for paths. [VERIFIED: 44-CONTEXT.md; inst/htmlwidgets/modules/brush.js:316-327] |
| Unit conversion | New linewidth conversion constants | `window.gg2d3.constants.mmToPxLinewidth` | Existing renderers use the shared ggplot linewidth conversion helper. [VERIFIED: inst/htmlwidgets/modules/constants.js:52-68; inst/htmlwidgets/modules/geoms/line.js:38-121] |
| Linetype mapping | New dash parser | `window.gg2d3.helpers.getDashArray` | Existing constants module maps ggplot linetype names/codes to SVG dash arrays. [VERIFIED: inst/htmlwidgets/modules/constants.js:252-297] |

**Key insight:** The hard part is not polygon geometry; it is preserving ggplot row semantics while making one group-level SVG mark participate in selector-driven interactivity without exposing renderer-private helper data. [VERIFIED: 44-CONTEXT.md; source inspection]

## Common Pitfalls

### Pitfall 1: Reusing `geom_line` Sorting Semantics

**What goes wrong:** Polygon vertices get sorted by x and self-cross or reshape incorrectly. [VERIFIED: 44-CONTEXT.md]

**Why it happens:** Existing `line.js` intentionally sorts `geom_line` by x but preserves order for `geom_path`. [VERIFIED: inst/htmlwidgets/modules/geoms/line.js:102-109]

**How to avoid:** Dedicated polygon renderer must never sort points; add a test where x order is intentionally non-monotone. [VERIFIED: local R fixture]

**Warning signs:** Source contains `pts.sort` or `d3.ascending` in polygon renderer. [VERIFIED: inst/htmlwidgets/modules/geoms/line.js:107-108]

### Pitfall 2: `fill = NA` and `colour = NA` Default Back to Visible Colors

**What goes wrong:** No-fill polygons render grey, or no-stroke polygons render with current color. [VERIFIED: inst/htmlwidgets/modules/geom-registry.js:144-176; local R fixture]

**Why it happens:** `makeColorAccessors()` currently supplies defaults for missing `params.fill` and `params.colour`. [VERIFIED: inst/htmlwidgets/modules/geom-registry.js:144-176]

**How to avoid:** Add polygon-local missing-aesthetic checks before calling default color fallback. [VERIFIED: 44-CONTEXT.md]

**Warning signs:** Renderer directly uses `.attr("fill", fillColor(firstPoint))` and `.attr("stroke", strokeColor(firstPoint))` without checking `NA`/`null`. [VERIFIED: inst/htmlwidgets/modules/geoms/area.js:109-115; inst/htmlwidgets/modules/geoms/line.js:123-130]

### Pitfall 3: Binding an Array Datum Breaks Group-Level Payload Expectations

**What goes wrong:** Brush callbacks receive arrays or wrapper objects instead of a deterministic source row. [VERIFIED: inst/htmlwidgets/modules/brush.js:400-440; 44-CONTEXT.md]

**Why it happens:** Path renderers often use `.datum(pts)` so zoom can recompute paths, and tooltip has special array unwrapping, but brush sanitizer does not transform arrays into representative rows. [VERIFIED: tests/testthat/test-zoom-path-datum.R:1-18; inst/htmlwidgets/modules/tooltip.js:139-156; inst/htmlwidgets/modules/brush.js:400-440]

**How to avoid:** For polygon, bind a representative public row and store renderer-private point data under `_polygonPoints`, then update zoom/brush code accordingly if needed. [VERIFIED: inst/htmlwidgets/modules/events.js:56-65]

**Warning signs:** Browser brush payload serializes numeric array indices or `_polygonPoints`. [VERIFIED: inst/htmlwidgets/modules/brush.js:397-440]

### Pitfall 4: Missing Zoom/Update Coverage for Polygon Paths

**What goes wrong:** Polygon paths render initially but fail to update on zoom/pan or resize transitions. [VERIFIED: tests/testthat/test-zoom-path-datum.R:1-8; inst/htmlwidgets/modules/geom-registry.js:275-283]

**Why it happens:** `updateGeoms()` only recomputes path selectors listed in the path update block. [VERIFIED: inst/htmlwidgets/modules/geom-registry.js:275-283]

**How to avoid:** Add `path.geom-polygon` to the update path block and make the bound datum provide points to the generator. [VERIFIED: inst/htmlwidgets/modules/geom-registry.js:275-283]

**Warning signs:** `test-zoom-path-datum.R` does not include `polygon.js`, or `geom-registry.js` update selectors omit `path.geom-polygon`. [VERIFIED: tests/testthat/test-zoom-path-datum.R:10-18]

### Pitfall 5: Selector Drift Across Modules

**What goes wrong:** Tooltips work while brush/crosstalk does not, or brush works while hover does not. [VERIFIED: inst/htmlwidgets/modules/events.js:23-44; inst/htmlwidgets/modules/brush.js:29-50; inst/htmlwidgets/modules/crosstalk.js:22-36]

**Why it happens:** Selector arrays are copied in multiple modules rather than imported from a shared constant. [VERIFIED: source inspection]

**How to avoid:** Add source-contract tests that assert `path.geom-polygon` appears in all intended modules. [VERIFIED: tests/testthat/test-sf-interactivity.R:23-73]

**Warning signs:** A grep finds `path.geom-polygon` in only one of `events.js`, `brush.js`, or `crosstalk.js`. [VERIFIED: source inspection]

## Code Examples

### Polygon Renderer Skeleton

```javascript
// Source basis: geoms/line.js, geoms/area.js, constants.js, D3 curve docs.
(function() {
  'use strict';

  function renderPolygon(layer, g, xScale, yScale, options) {
    const val = window.gg2d3.helpers.val;
    const num = window.gg2d3.helpers.num;
    const asRows = window.gg2d3.helpers.asRows;
    const getDashArray = window.gg2d3.helpers.getDashArray;
    const mmToPxLinewidth = window.gg2d3.constants.mmToPxLinewidth;
    const { strokeColor, fillColor, opacity } =
      window.gg2d3.geomRegistry.makeColorAccessors(layer, options);

    const aes = layer.aes || {};
    const params = layer.params || {};
    const dat = asRows(layer.data);
    const get = (d, k) => (k && d != null) ? d[k] : null;
    const flip = !!options.flip;
    const isXBand = typeof xScale.bandwidth === "function";
    const isYBand = typeof yScale.bandwidth === "function";
    const xOff = isXBand ? xScale.bandwidth() / 2 : 0;
    const yOff = isYBand ? yScale.bandwidth() / 2 : 0;

    const grouped = d3.group(dat, d => val(get(d, "group")) ?? 1);
    let drawn = 0;

    grouped.forEach(arr => {
      const pts = arr.map(d => ({
        x: isXBand ? val(get(d, aes.x)) : num(get(d, aes.x)),
        y: isYBand ? val(get(d, aes.y)) : num(get(d, aes.y)),
        d
      })).filter(p => p.x != null && p.y != null);
      if (pts.length < 3) return;

      const line = flip
        ? d3.line().curve(d3.curveLinearClosed).x(p => yScale(p.y) + yOff).y(p => xScale(p.x) + xOff)
        : d3.line().curve(d3.curveLinearClosed).x(p => xScale(p.x) + xOff).y(p => yScale(p.y) + yOff);

      const first = pts[0].d;
      const publicRow = Object.assign({}, first);
      publicRow._polygonPoints = pts;

      g.append("path")
        .datum(publicRow)
        .attr("class", "geom-polygon")
        .attr("d", line(pts))
        .attr("fill", polygonFill(first, fillColor))
        .attr("stroke", polygonStroke(first, strokeColor))
        .attr("stroke-width", polygonLinewidth(first, params, val, mmToPxLinewidth))
        .attr("stroke-dasharray", getDashArray(val(first.linetype) || params.linetype))
        .attr("opacity", opacity(first));

      drawn += 1;
    });

    return drawn;
  }

  window.gg2d3.geomRegistry.register('polygon', renderPolygon);
})();
```

This is a planning skeleton, not final code; tests should drive exact helper names and `NA` checks. [VERIFIED: source inspection]

### Selector Additions

```javascript
// Source basis: events.js / brush.js selector arrays.
'path.geom-polygon', // ordinary geom_polygon
```

Add to `events.js` and `brush.js`; add to `crosstalk.js` if polygon crosstalk participation is expected through existing linked-view behavior. [VERIFIED: inst/htmlwidgets/modules/events.js:23-44; inst/htmlwidgets/modules/brush.js:29-50; inst/htmlwidgets/modules/crosstalk.js:22-36]

### Browser DOM Smoke Shape

```r
# Source basis: test-sf-browser.R and helper-browser-sf.R.
test_that("POLY-02/03 DOM: polygon paths render and expose public payloads", {
  skip_polygon_browser_smoke()
  widget <- gg2d3(polygon_fixture()) |>
    d3_brush(on_brush = "window.__gg2d3_polygon_brush = selectedData;") |>
    d3_tooltip() |>
    d3_hover() |>
    d3_handlers(click = "window.__gg2d3_polygon_click = d;")

  path <- save_browser_polygon_widget(widget, "phase44-polygon-interactivity.html")
  # chromote: assert path.geom-polygon count, closed d path, fill/stroke attrs,
  # clip-path ancestor, no console errors, and no _polygonPoints in payloads.
})
```

Pattern follows optional sf browser tests with DOM assertions and clean skips. [VERIFIED: tests/testthat/helper-browser-sf.R:21-64; tests/testthat/test-sf-browser.R:150-240]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `GeomPolygon` recognized in IR but no JS renderer | Add registered ordinary polygon renderer and source/browser gates | Phase 44 active milestone, 2026-05-24 [VERIFIED: .planning/ROADMAP.md] | Removes documented unsupported ordinary polygon warning path. [VERIFIED: vignettes/gg2d3.Rmd:561-568] |
| Screenshot/perceptual checks for geometry confidence | DOM/source assertions and optional chromote smoke coverage | Established by v1.9/v1.10 sf validation [VERIFIED: .planning/STATE.md; tests/testthat/test-sf-browser.R] | Keeps Phase 44 validation fast and CRAN-compatible. [VERIFIED: tests/testthat/helper-browser-sf.R:21-47] |
| sf centroid/anchor brushing for polygon-family maps | Ordinary polygon path-bounds brushing via generic path branch | Phase 44 locked decision [VERIFIED: 44-CONTEXT.md] | Avoids adding computational geometry or map-specific semantics. [VERIFIED: 44-CONTEXT.md; inst/htmlwidgets/modules/brush.js:316-327] |

**Deprecated/outdated:**
- Documentation saying ordinary polygon marks are not rendered becomes stale after Phase 44 implementation and should be updated later in Phase 47, not inside Phase 44 unless tests require fixture notes. [VERIFIED: vignettes/gg2d3.Rmd:561-568; .planning/ROADMAP.md Phase 47]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `crosstalk.js` should be updated for `path.geom-polygon` if POLY-03 "row identity" is interpreted to include linked-view key binding, even though POLY-03 names tooltip/hover/brush/custom handler APIs and the phase focus names "existing interactivity hooks." [ASSUMED] | Phase Requirements, Architecture Patterns | If wrong, planner might include one extra source/test edit; low blast radius. |

## Open Questions (RESOLVED)

Resolved during Phase 44 planning on 2026-05-24:

- Include `path.geom-polygon` in `inst/htmlwidgets/modules/crosstalk.js` selector coverage as part of POLY-03, reusing the existing crosstalk behavior with no new API.
- Include polygon zoom/update handling in Phase 44 via `inst/htmlwidgets/modules/geom-registry.js` and `tests/testthat/test-zoom-path-datum.R`.
- Do not add `subgroup`, hole preservation, or explicit topology semantics in Phase 44; grouped ordinary polygons use ggplot2 built row order and defer topology semantics.

1. **Should ordinary polygon crosstalk be included in POLY-03?**
   - What we know: `crosstalk.js` has its own selector list and binds keys to marks by selector. [VERIFIED: inst/htmlwidgets/modules/crosstalk.js:22-36, inst/htmlwidgets/modules/crosstalk.js:118-130]
   - What's unclear: POLY-03 names tooltip, hover, brush, and custom handlers, while broader project docs include linked views as existing interactivity. [VERIFIED: .planning/REQUIREMENTS.md; .planning/PROJECT.md]
   - Resolution: Include `path.geom-polygon` in `crosstalk.js` source guards because the plan already touches selector plumbing, but do not add new crosstalk behavior.

2. **Should polygon zoom/update be required in Phase 44?**
   - What we know: `updateGeoms()` handles path geoms for zoom/reset, but the success criteria do not explicitly name zoom. [VERIFIED: inst/htmlwidgets/modules/geom-registry.js:275-283; .planning/ROADMAP.md]
   - What's unclear: Existing interactivity hooks may imply zoom compatibility for non-sf Cartesian geoms. [VERIFIED: .planning/PROJECT.md]
   - Resolution: Add `path.geom-polygon` to `updateGeoms()` and extend `test-zoom-path-datum.R`; this is small and prevents an obvious regression. [VERIFIED: tests/testthat/test-zoom-path-datum.R:1-18]

3. **Should subgroup/hole source columns be preserved for future work?**
   - What we know: ggplot2 documents `subgroup` and hole support, but Phase 44 defers explicit hole/topology behavior. [CITED: https://ggplot2.tidyverse.org/reference/geom_polygon.html; VERIFIED: 44-CONTEXT.md]
   - What's unclear: `R/as_d3_ir.R` currently does not keep `subgroup`. [VERIFIED: R/as_d3_ir.R:238-252]
   - Resolution: Do not add subgroup support in Phase 44. Subgroup/hole preservation and topology semantics remain explicitly deferred. [VERIFIED: 44-CONTEXT.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| R | All R package tests | yes [VERIFIED: `command -v R`] | 4.6.0 [VERIFIED: local `Rscript`] | None |
| Rscript | Local probes and automated test commands | yes [VERIFIED: `command -v Rscript`] | 4.6.0 runtime [VERIFIED: local `Rscript`] | Use R console commands manually |
| ggplot2 | POLY-01 fixtures | yes [VERIFIED: local `Rscript`] | 4.0.3 [VERIFIED: local `Rscript`] | None |
| testthat | Unit/source gates | yes [VERIFIED: local `Rscript`] | 3.3.2 [VERIFIED: local `Rscript`] | None |
| chromote | Optional browser DOM smoke | yes [VERIFIED: local `Rscript`] | 0.5.1 [VERIFIED: local `Rscript`] | Skip cleanly using existing helper pattern |
| Chrome/Chromium | Optional chromote execution | yes via `/Applications/Google Chrome.app/Contents/MacOS/Google Chrome` [VERIFIED: `chromote::find_chrome()`] | Browser version not probed [VERIFIED: local environment audit] | Source/IR tests still run if browser unavailable |
| D3 v7 vendored file | Browser renderer | expected by yaml [VERIFIED: inst/htmlwidgets/gg2d3.yaml:7-11] | v7 dependency declaration [VERIFIED: inst/htmlwidgets/gg2d3.yaml:7-11] | Vendor command in AGENTS.md if file missing |

**Missing dependencies with no fallback:** None found for planning. [VERIFIED: local environment audit]

**Missing dependencies with fallback:** Browser version was not probed, but chromote found a Chrome executable; browser tests already have skip patterns for unavailable launch. [VERIFIED: tests/testthat/helper-browser-sf.R:21-47; local environment audit]

## Validation Architecture

Nyquist validation is enabled by default because `.planning/config.json` has no `workflow.nyquist_validation: false` key. [VERIFIED: .planning/config.json]

### Test Framework

| Property | Value |
|----------|-------|
| Framework | testthat 3.3.2 local; package config uses edition 3. [VERIFIED: local `Rscript`; DESCRIPTION] |
| Config file | DESCRIPTION `Config/testthat/edition: 3`. [VERIFIED: DESCRIPTION] |
| Quick run command | `rtk Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-polygon-ir.R")'` [VERIFIED: existing testthat pattern] |
| Full suite command | `rtk Rscript --vanilla -e 'devtools::test()'` [VERIFIED: AGENTS.md] |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| POLY-01 | `GeomPolygon` IR rows preserve `group`, row order, `PANEL`, x/y, fill, colour, alpha, linewidth, linetype, and `NA` styling source values. [VERIFIED: .planning/REQUIREMENTS.md] | unit | `rtk Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-polygon-ir.R")'` | No - Wave 0 gap [VERIFIED: tests/testthat listing] |
| POLY-02 | Renderer source registers `polygon`, yaml loads `geoms/polygon.js`, renderer emits `path.geom-polygon`, closed path generator, fill/stroke/linewidth/linetype/opacity, and clipping/facet path uses existing panel shell. [VERIFIED: .planning/REQUIREMENTS.md] | source/unit | `rtk Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-polygon-renderer.R")'` | No - Wave 0 gap [VERIFIED: tests/testthat listing] |
| POLY-02 | Browser DOM smoke renders single/grouped/faceted polygon paths with non-empty closed `d`, expected counts per panel, clip-path ancestry, and style attributes. [VERIFIED: 44-CONTEXT.md] | optional browser smoke | `rtk Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-polygon-browser.R")'` | No - Wave 0 gap [VERIFIED: tests/testthat listing] |
| POLY-03 | `path.geom-polygon` participates in tooltip, hover, brush, handlers, Shiny-style payloads, and sanitized representative payloads. [VERIFIED: .planning/REQUIREMENTS.md] | source + optional browser smoke | `rtk Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-polygon-interactivity.R")'` | No - Wave 0 gap [VERIFIED: tests/testthat listing] |

### Sampling Rate

- **Per task commit:** Run the smallest new test file for the touched layer: `test-polygon-ir.R`, `test-polygon-renderer.R`, or `test-polygon-interactivity.R`. [VERIFIED: AGENTS.md test patterns]
- **Per wave merge:** Run all Phase 44 tests plus existing regression guard: `test-regression-core.R`, `test-zoom-path-datum.R`, and optional `test-polygon-browser.R`. [VERIFIED: tests/testthat listing]
- **Phase gate:** `rtk Rscript --vanilla -e 'devtools::test()'` plus explicit note if optional browser smoke skips. [VERIFIED: AGENTS.md; tests/testthat/helper-browser-sf.R:21-47]

### Wave 0 Gaps

- [ ] `tests/testthat/test-polygon-ir.R` - covers POLY-01. [VERIFIED: tests/testthat listing]
- [ ] `tests/testthat/test-polygon-renderer.R` - covers POLY-02 source contracts. [VERIFIED: tests/testthat listing]
- [ ] `tests/testthat/test-polygon-interactivity.R` - covers POLY-03 selector and sanitizer source contracts. [VERIFIED: tests/testthat listing]
- [ ] `tests/testthat/test-polygon-browser.R` and optionally `tests/testthat/helper-browser-polygon.R` - covers DOM smoke without screenshot infrastructure. [VERIFIED: tests/testthat/test-sf-browser.R; tests/testthat/helper-browser-sf.R]
- [ ] Extend `tests/testthat/test-zoom-path-datum.R` if polygon paths are added to zoom/update. [VERIFIED: tests/testthat/test-zoom-path-datum.R:10-18]

## Security Domain

Security enforcement is treated as enabled because `.planning/config.json` does not explicitly set `security_enforcement: false`. [VERIFIED: .planning/config.json]

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | no | No authentication surface in Phase 44. [VERIFIED: phase scope/source inspection] |
| V3 Session Management | no | No session management surface in Phase 44. [VERIFIED: phase scope/source inspection] |
| V4 Access Control | no | No authorization surface in Phase 44. [VERIFIED: phase scope/source inspection] |
| V5 Input Validation | yes | Keep IR validation and sanitize event/tooltip/brush payloads before user callbacks. [VERIFIED: R/validate_ir.R; inst/htmlwidgets/modules/events.js:56-65; inst/htmlwidgets/modules/tooltip.js:117-156; inst/htmlwidgets/modules/brush.js:397-440] |
| V6 Cryptography | no | No cryptography surface in Phase 44. [VERIFIED: phase scope/source inspection] |

### Known Threat Patterns for R/htmlwidgets Callback Surface

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Renderer-private data exposure through callbacks | Information Disclosure | Bind representative rows and keep private helper data underscore-prefixed so existing sanitizers drop it. [VERIFIED: inst/htmlwidgets/modules/events.js:56-65; inst/htmlwidgets/modules/tooltip.js:117-156; inst/htmlwidgets/modules/brush.js:397-440] |
| Broken selector coverage causing invisible/uncontrolled marks | Tampering/Integrity | Source tests assert selector arrays include `path.geom-polygon` where APIs depend on them. [VERIFIED: tests/testthat/test-sf-interactivity.R:23-73] |
| Unsafe custom callback strings | Execution | Existing API already accepts user-supplied JS callback strings; Phase 44 should not expand this surface. [VERIFIED: inst/htmlwidgets/modules/events.js:666-700; R/d3_handlers.R if present not inspected] |

## Sources

### Primary (HIGH confidence)

- `.planning/phases/44-ordinary-geom-polygon-support/44-CONTEXT.md` - locked decisions, validation matrix, deferred scope. [VERIFIED: file read]
- `.planning/REQUIREMENTS.md` - POLY-01, POLY-02, POLY-03. [VERIFIED: file read]
- `.planning/ROADMAP.md` - phase goal, success criteria, plan split. [VERIFIED: file read]
- `.planning/PROJECT.md` and `.planning/STATE.md` - architecture, prior decisions, validation history. [VERIFIED: file read]
- `AGENTS.md` and `/Users/davidzenz/.codex/RTK.md` - project commands, architecture, command prefix. [VERIFIED: file read]
- `R/as_d3_ir.R`, `R/validate_ir.R`, `inst/htmlwidgets/gg2d3.js`, `inst/htmlwidgets/gg2d3.yaml`, `inst/htmlwidgets/modules/*`, `tests/testthat/*` - current implementation and test patterns. [VERIFIED: source inspection]
- Local R probes for installed versions and `geom_polygon()` built IR values. [VERIFIED: local `Rscript`]

### Primary Documentation (HIGH confidence)

- https://ggplot2.tidyverse.org/reference/geom_polygon.html - official ggplot2 4.0.3 `geom_polygon()` semantics and aesthetics. [CITED: official docs]
- https://d3js.org/d3-shape/curve - official D3 curve docs for closed linear paths. [CITED: official docs]
- https://d3js.org/d3-path - official D3 path docs for `closePath()` semantics. [CITED: official docs]

### Secondary (MEDIUM confidence)

- None used. [VERIFIED: research source log]

### Tertiary (LOW confidence)

- None used. [VERIFIED: research source log]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - package stack is declared locally and versions were probed. [VERIFIED: DESCRIPTION; local `Rscript`]
- Architecture: HIGH - extension points are visible in current source files and prior sf tests. [VERIFIED: source inspection]
- Pitfalls: HIGH - pitfalls come from locked decisions plus concrete current code paths. [VERIFIED: 44-CONTEXT.md; source inspection]
- Browser validation: MEDIUM - chromote and Chrome are available locally, but browser tests should still skip cleanly in CRAN-like environments. [VERIFIED: local environment audit; tests/testthat/helper-browser-sf.R:21-47]

**Research date:** 2026-05-24
**Valid until:** 2026-06-23 for local codebase architecture; re-check official docs and package versions if planning happens after that date. [ASSUMED]
