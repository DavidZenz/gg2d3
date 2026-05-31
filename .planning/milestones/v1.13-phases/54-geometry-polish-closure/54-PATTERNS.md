# Phase 54: Geometry Polish Closure - Pattern Map

**Mapped:** 2026-05-28
**Files analyzed:** 22
**Analogs found:** 18 / 18 proposed work areas

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `R/ir_layer_helpers.R` | utility | transform | existing layer keep/geom/params helpers | exact |
| `R/as_d3_ir.R` | service/orchestrator | transform | existing layer dispatch path | exact |
| `R/validate_ir.R` | validation/config | transform | existing `known_geoms` / sf validation | exact |
| `inst/htmlwidgets/modules/geoms/text.js` | renderer | SVG render | `inst/htmlwidgets/modules/geoms/sf.js` sf text/label annotation path | role-match |
| `inst/htmlwidgets/modules/geoms/polygon.js` | renderer | SVG render/update | existing ordinary polygon renderer plus sf `fill-rule` path | exact/partial |
| `inst/htmlwidgets/modules/geoms/rect.js` | renderer | SVG render/update | existing rect/tile renderer | exact |
| `inst/htmlwidgets/modules/scales.js` | utility | transform | existing log/sqrt/reverse scale factory | exact |
| `inst/htmlwidgets/modules/geom-registry.js` | registry/update service | event-driven/update | existing register/update/color accessor paths | exact |
| `inst/htmlwidgets/modules/geom-contracts.js` | contract config | event-driven/source-validation | existing geom contract entries | exact |
| `tests/testthat/test-text-label-polish.R` | test | transform/source | existing text/label characterization tests | exact |
| `tests/testthat/test-polygon-ir.R` | test | transform/source | existing polygon subgroup classification tests | exact |
| `tests/testthat/test-polygon-renderer.R` | test | source-contract | existing polygon renderer contract tests | exact |
| `tests/testthat/test-rect-tile-ir.R` | test | transform/source | existing transformed-bound IR fixtures | exact |
| `tests/testthat/test-rect-tile-renderer.R` | test | source-contract | existing rect render/update contract tests | exact |
| `tests/testthat/test-renderer-wiring-contracts.R` | test | source-contract | existing Phase 53 contract tests | exact |
| `tests/testthat/test-browser-visual-smoke.R` | test | browser artifact/DOM | existing optional fixture matrix | role-match |
| `vignettes/d3-drawing-diagnostics.md` | docs | documentation | existing geometry limitations sections | exact |
| `README.Rmd` / `README.md` | docs | generated documentation | existing scoped support claims | role-match |

## Pattern Assignments

### Label/Text Boxes And Placement

**Apply to:** `R/ir_layer_helpers.R`, `R/as_d3_ir.R`, `R/validate_ir.R`, `inst/htmlwidgets/modules/geoms/text.js`, contract/tests/docs.

**R-side analogs:**

```r
# R/ir_layer_helpers.R lines 16-26
c(
  "PANEL", "x", "y", "xend", "yend", "xmin", "xmax", "ymin", "ymax",
  "colour", "fill", "size", "alpha", "group", "label",
  "stroke", "shape", "linewidth", "linetype", "lineend",
  ...
)

# R/ir_layer_helpers.R lines 65-78
GeomText = "text",
GeomLabel = "text",
```

Guidance:
- Preserve ordinary text/label built-row fields only when Phase 54 uses them: likely `hjust`, `vjust`, `angle`, `family`; consider `fontface` only if it falls out naturally.
- If ordinary labels become `geom = "label"`, update `R/validate_ir.R` lines 12-20 to include `label`. If they remain `geom = "text"`, add explicit label metadata/tests so contracts still observe selector changes.
- Put bounded label params in `gg2d3_ir_layer_params()` (`R/ir_layer_helpers.R` lines 204-221), converting grid units such as `label.padding` before JSON rather than serializing unit internals.
- Keep `as_d3_ir()` as orchestration only; its layer branch at `R/as_d3_ir.R` lines 58-105 should stay a dispatch seam, not become renderer logic.

**Renderer analogs:**

```javascript
// inst/htmlwidgets/modules/geoms/text.js lines 30-37
function renderText(layer, g, xScale, yScale, options) {
  const val = window.gg2d3.helpers.val;
  const num = window.gg2d3.helpers.num;
  const asRows = window.gg2d3.helpers.asRows;
  const { strokeColor, opacity } =
    window.gg2d3.geomRegistry.makeColorAccessors(layer, options);

// inst/htmlwidgets/modules/geoms/text.js lines 92-97
.attr("dominant-baseline", "middle")
.attr("text-anchor", "middle")
.text(d => val(get(d, aes.label)))
.attr("fill", d => strokeColor(d))
.attr("opacity", d => opacity(d))
.style("font-size", d => textSize(d));
```

```javascript
// inst/htmlwidgets/modules/geoms/sf.js lines 236-260
function textAnchor(d, layer, val) { ... }
function dominantBaseline(d, layer, val) { ... }
function fontFamily(d, layer, val) { ... }

// inst/htmlwidgets/modules/geoms/sf.js lines 438-478
var labelGroups = group.selectAll("g.geom-sf.geom-sf-label")
  .data(rows)
  .enter().append("g")
    .attr("class", "geom-sf geom-sf-label")
...
labelGroups.append("rect").attr("class", "geom-sf-label-box")
labelGroups.append("text").attr("class", "geom-sf-label-text")
...
var bbox = textNode.getBBox();
var pad = 3;
node.select("rect.geom-sf-label-box")
  .attr("x", bbox.x - pad)
  .attr("width", bbox.width + pad * 2)
```

Guidance:
- Reuse SVG `.text(...)`, never `.html(...)`; this is the T-54-01 mitigation.
- Ordinary label boxes should be renderer-local `g + rect + text` with `getBBox()` sizing, modeled after sf labels.
- Text placement wins should be small: anchor/baseline/rotation/font-family. Do not implement collision avoidance, rich text, ggrepel parity, or `textPath`.
- If labels use `g.geom-label`, update update selectors, event/brush/crosstalk selectors, and public payload contracts.

**Validation hooks:** `tests/testthat/test-text-label-polish.R` lines 14-70, `54-VALIDATION.md` lines 43 and 46, plus optional browser fixture only after source/DOM contracts exist.

### Polygon Subgroup/Hole Boundary

**Apply to:** `R/ir_layer_helpers.R`, `R/as_d3_ir.R`, `inst/htmlwidgets/modules/geoms/polygon.js`, polygon tests/docs.

**Current boundary analogs:**

```r
# tests/testthat/test-polygon-ir.R lines 171-189
expect_true("subgroup" %in% names(built))
expect_equal(as.character(built$subgroup), polygon_data$subgroup)
expect_false(any(row_has_field(layer$data, "subgroup")))
expect_equal(as.numeric(row_values(layer$data, "x")), built$x)
expect_equal(as.numeric(row_values(layer$data, "y")), built$y)
```

```javascript
// inst/htmlwidgets/modules/geoms/polygon.js lines 83-121
const closedLine = ... d3.line().curve(d3.curveLinearClosed) ...
const grouped = d3.group(indexedRows, row => val(get(row.d, "group")) ?? 1);
...
publicRow._polygonPoints = pts;
publicRow._sourceIndex = pts[0].sourceIndex;
g.append("path")
  .datum(publicRow)
  .attr("class", "geom-polygon")
  .attr("d", closedLine(pts))
```

**Partial analog if tiny support ships:**

```javascript
// inst/htmlwidgets/modules/geoms/sf.js lines 350-360
sfGroup.selectAll("path.geom-sf.geom-sf-polygon")
  ...
  .attr("fill-rule", "evenodd")
```

Guidance:
- Fixture first. Preserve `subgroup` only if it drives a concrete bounded compound-path contract; do not keep extra IR metadata speculatively.
- Acceptable tiny implementation, if proven: built-row-order compound subpaths within one ggplot2 `group`, explicit `fill-rule`, no containment inference.
- Default acceptable closure: stronger non-goal diagnostics and source tests proving built data has `subgroup` while ordinary gg2d3 does not claim topology support.
- Anti-patterns: GIS topology repair, ring containment inference, arbitrary hole winding repair, invalid polygon repair, self-intersection logic.

**Validation hooks:** `tests/testthat/test-polygon-ir.R` lines 171-252, `tests/testthat/test-polygon-renderer.R` lines 67-86, `54-VALIDATION.md` lines 44 and 57-58.

### Rect/Tile Transformed-Scale Evidence

**Apply to:** `inst/htmlwidgets/modules/geoms/rect.js`, `inst/htmlwidgets/modules/geom-registry.js`, `inst/htmlwidgets/modules/scales.js`, rect/tile tests/docs.

**Renderer analog:**

```javascript
// inst/htmlwidgets/modules/geoms/rect.js lines 85-107
function rectX(d) {
  if (isXBand) return xScale(bandValue(d, aes.x, aes.xmin));
  return Math.min(xScale(num(get(d, aes.xmin))), xScale(num(get(d, aes.xmax))));
}
...
function rectWidth(d) {
  if (isXBand) return xScale.bandwidth();
  const x1 = xScale(num(get(d, aes.xmin)));
  const x2 = xScale(num(get(d, aes.xmax)));
  return Math.abs(x2 - x1);
}
```

**Update-path analog:**

```javascript
// inst/htmlwidgets/modules/geom-registry.js lines 219-257, 293-311
function rectX(d) {
  if (isXBand) return xScale(bandValue(d, 'x', 'xmin'));
  return Math.min(xScale(num(d.xmin)), xScale(num(d.xmax)));
}
...
container.selectAll('rect.geom-rect')
  .transition(t)
  .attr('x', d => { if (flip) return flippedRectX(d); return rectX(d); })
```

**Scale factory analog:**

```javascript
// inst/htmlwidgets/modules/scales.js lines 164-198
case "log":
case "log10":
  const scale = d3.scaleLog().domain(domain).range(rng);
...
case "sqrt":
  return d3.scaleSqrt().domain(numericDomain).range(rng);
case "reverse":
  return d3.scaleLinear().domain([...numericDomain].reverse()).range(rng);
```

Guidance:
- Current release boundary is direct scaling of ggplot2-built transformed bounds. Strengthen evidence before changing math.
- Fix only proven drift between `rect.js`, `geom-registry.js`, and `scales.js`.
- Anti-patterns: adding `untransform`, custom log/sqrt math in `rect.js`, broad scale refactor without failing fixtures, pixel-threshold validation.

**Validation hooks:** `tests/testthat/test-rect-tile-ir.R` lines 156-237, `tests/testthat/test-rect-tile-renderer.R` lines 141-178, `54-VALIDATION.md` lines 45 and 59.

### Renderer Wiring Contracts

**Apply to:** `geom-contracts.js`, `geom-registry.js`, `gg2d3.yaml`, public payload tests.

**Contract analogs:**

```javascript
// inst/htmlwidgets/modules/geom-contracts.js lines 73-100
{
  geom: 'rect',
  aliases: ['rect', 'tile'],
  module: 'geoms/rect.js',
  renderSelectors: ['rect.geom-rect'],
  update: { type: 'selectors', selectors: ['rect.geom-rect'] },
  interactions: { events: ['rect.geom-rect'], brush: ['rect.geom-rect'], crosstalk: ['rect.geom-rect'] },
  privateFields: [],
  publicPayload: true
},
{
  geom: 'text',
  aliases: ['text'],
  module: 'geoms/text.js',
  renderSelectors: ['text.geom-text'],
  ...
}
```

```javascript
// inst/htmlwidgets/modules/geom-registry.js lines 64-68
function registerGeom(names, renderer) {
  const nameArray = Array.isArray(names) ? names : [names];
  nameArray.forEach(name => { renderers[name] = renderer; });
}

// inst/htmlwidgets/gg2d3.yaml lines 21-35
- geom-contracts.js
- public-data.js
...
- geom-registry.js
- geoms/polygon.js
- geoms/rect.js
- geoms/text.js
```

Guidance:
- If `label` becomes a renderer alias, contract aliases must equal registered aliases, and `validate_ir()` must know the geom.
- If a new `label.js` module is added, add it to `gg2d3.yaml` after `geom-registry.js` and add a contract entry. If label remains in `text.js`, do not add YAML churn.
- Any label group private fields must be underscore-prefixed and listed in `privateFields`; public payloads rely on `public-data.js` lines 21-36.
- Empty update/interaction surfaces must use explicit `reason` objects, not bare empty arrays.

**Validation hooks:** `tests/testthat/test-renderer-wiring-contracts.R` lines 237-328 and 330-448, `54-VALIDATION.md` line 46.

### Diagnostics Docs

**Apply to:** `vignettes/d3-drawing-diagnostics.md`, `README.Rmd`, generated `README.md`.

**Existing doc analogs:**

```markdown
<!-- vignettes/d3-drawing-diagnostics.md lines 117-123 -->
`geom_text` supports position, size, color, and alpha. Ordinary `geom_label()`
currently maps to the text renderer, so label boxes, padding, and label-specific
background styling are not yet translated. Rotation (`angle`), justification
(`hjust`/`vjust`), font family, collision avoidance, and path-following text are
not yet translated.
```

```markdown
<!-- vignettes/d3-drawing-diagnostics.md lines 25-31 -->
Residual risks remain explicit: topology/hole repair beyond clean grouped
closed paths is not shipped ...
```

```markdown
<!-- vignettes/d3-drawing-diagnostics.md lines 165-179 -->
## Rect/tile edge cases
...
Full rect/tile transformed-scale edge parity remains out of scope ...
```

Guidance:
- Diagnostics is the primary closure doc. Update it after implementation decisions to distinguish shipped bounded support from explicit future requirements.
- README support claims are generated from `README.Rmd`; edit `README.Rmd` first and rebuild only in implementation/release phase.
- Watch existing README mismatch: `README.Rmd` lines 108-113 mention theme text justifications/rotations, while diagnostics lines 117-123 say ordinary text/label placement is not translated. Phase 54/55 must align this after decisions.

**Validation hook:** `54-VALIDATION.md` line 47:

```bash
rg -n "geom_label|geom_polygon|subgroup|hole|hjust|vjust|angle|collision|path-following|rect|tile" vignettes/d3-drawing-diagnostics.md README.Rmd README.md
```

## Shared Anti-Patterns

- Do not add new dependencies for Phase 54.
- Do not implement `.html(...)` label content or bypass SVG `.text(...)`.
- Do not build a ggrepel clone, collision solver, path-following text, rich text, or broad label-placement algorithm.
- Do not implement GIS topology repair, containment inference, winding repair, or invalid polygon repair.
- Do not add custom rect/tile transform inversion or refactor shared scales without failing source evidence.
- Do not rely on committed golden screenshots or pixel thresholds; browser smoke is downstream inspection evidence only.
- Do not modify untracked `.claude/` or `AGENTS.md`.

## Validation Commands

From `54-VALIDATION.md` lines 22-25:

```bash
rtk Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-text-label-polish.R"); testthat::test_file("tests/testthat/test-polygon-ir.R"); testthat::test_file("tests/testthat/test-rect-tile-ir.R")'
rtk Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-polygon-renderer.R"); testthat::test_file("tests/testthat/test-rect-tile-renderer.R"); testthat::test_file("tests/testthat/test-renderer-wiring-contracts.R")'
rtk env NOT_CRAN=true GG2D3_BROWSER_VISUAL_SMOKE=true Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-browser-visual-smoke.R")'
rtk Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); devtools::test()'
```

## No Analog Found

None. Every Phase 54 work area has an existing analog. The only partial analog is ordinary polygon hole support: sf polygons prove `fill-rule="evenodd"`, but ordinary polygon topology is currently a documented non-goal unless fixtures prove a tiny compound-path subset.

## Metadata

**Analog search scope:** `R/`, `inst/htmlwidgets/modules/`, `tests/testthat/`, `vignettes/`, `README.Rmd`, `README.md`, Phase 54 planning artifacts.
**Pattern extraction date:** 2026-05-28
