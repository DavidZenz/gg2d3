# Phase 26: New Geom Interactivity Wiring - Research

**Researched:** 2026-04-03
**Domain:** D3.js interactivity wiring, ggplot2 R documentation regeneration
**Confidence:** HIGH

## Summary

Phase 26 closes four partial requirements from the v1.6 milestone audit. All three
Phase 24 geoms (dotplot, rug, interval) render correctly but are invisible to every
interactivity module because their CSS classes were never added to `INTERACTIVE_SELECTORS`
in `events.js` and `brush.js`. Additionally, the `updateGeoms` handler for
`g.interval-item` in `geom-registry.js` is an empty stub, so zoom and reset do not
reposition errorbar/linerange/pointrange marks. A secondary gap is that `README.Rmd`
was updated for v1.6 but `devtools::build_readme()` was never run, leaving `README.md`
at the pre-v1.6 state.

All three JavaScript gaps are isolated changes with well-defined insertion points.
The interval `updateGeoms` stub is the most complex because it must reconstruct the
same coordinate logic used at render time (with flip awareness and per-sub-element
addressing for the three child lines/circle inside each `g.interval-item`). The
`countidx` orphaned aesthetic in `as_d3_ir.R` is tech debt from Phase 24; fixing it
is in scope as an optional cleanup since it adds no visual output and is already wired
into the IR.

**Primary recommendation:** Fix `INTERACTIVE_SELECTORS` first (two-file, one-line
addition each), then implement the interval `updateGeoms` handler, then run
`devtools::build_readme()`. Each fix is independent; they can be parallelized.

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| GEOM-20 | geom_dotplot responds to brush, hover, tooltip | Add `circle.geom-dotplot` to INTERACTIVE_SELECTORS in events.js and brush.js. updateGeoms already handles dotplot correctly (line 332-335, geom-registry.js). |
| GEOM-21 | geom_rug responds to brush, hover, tooltip | Add `line.geom-rug` to INTERACTIVE_SELECTORS in events.js and brush.js. updateGeoms already handles rug correctly (line 337-352, geom-registry.js). |
| GEOM-22 | Interval geoms reposition on zoom/reset and respond to interactivity | Add interval sub-element selectors to INTERACTIVE_SELECTORS; replace the empty `.each()` stub at line 355-361 of geom-registry.js with real update logic. |
| API-02 | README.md reflects all v1.6 features | Run `devtools::build_readme()` to regenerate README.md from the already-updated README.Rmd. |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| D3.js | v7 (vendored) | SVG rendering and interactivity | Already in use throughout project |
| R devtools | installed | `build_readme()` to regenerate docs | Standard R documentation workflow |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| pkgload | installed | `pkgload::load_all()` lighter alternative | When devtools not available |
| testthat | installed | R-side IR contract tests | Any new R-layer behavior |

**Installation:** No new dependencies required. All tools already present.

## Architecture Patterns

### INTERACTIVE_SELECTORS Pattern

`INTERACTIVE_SELECTORS` is a module-local constant array defined identically in two
files: `events.js` (line 23-37) and `brush.js` (line 29-43). Both arrays must be kept
in sync. Every geom class string follows the pattern `<svg-element>.<css-class>`.

The three additions needed:

```javascript
// Source: events.js line 37 / brush.js line 43 (append after existing entries)
'circle.geom-dotplot',           // geom_dotplot
'line.geom-rug',                 // geom_rug
'line.interval-line',            // geom_errorbar / linerange / pointrange central line
'line.errorbar-cap-top',         // geom_errorbar top cap
'line.errorbar-cap-bottom',      // geom_errorbar bottom cap
'circle.pointrange-point'        // geom_pointrange center point
```

**Design note:** `brush.js` already handles `line` elements correctly via
`isElementInPixelRect` (lines 281-296) — it checks midpoint and both endpoints.
`circle` elements are handled via cx/cy check. No new hit-testing logic is needed.

### Interval updateGeoms Pattern

The `g.interval-item` each-group contains up to three child elements, each with its
own CSS class. The update must address each child explicitly because D3 `.each()`
on the parent group cannot access the transition applied to child elements.

Pattern used by the existing boxplot update (geom-registry.js line 307-317) — select
descendants by class within the `.each()` callback using `d3.select(this)`:

```javascript
// Source: geom-registry.js updateGeoms — interval replacement for lines 355-361
container.selectAll('g.interval-item')
  .each(function(d) {
    const g = d3.select(this);
    const xSF = flip ? yScaleFunc : xScaleFunc;
    const ySF = flip ? xScaleFunc : yScaleFunc;
    const x = d[d._xKey || 'x'];

    // Central line (all three geoms share this)
    g.select('line.interval-line')
      .transition(t)
      .attr('x1', flip ? ySF(d.ymin) : xSF(x))
      .attr('x2', flip ? ySF(d.ymax) : xSF(x))
      .attr('y1', flip ? xSF(x) : ySF(d.ymin))
      .attr('y2', flip ? xSF(x) : ySF(d.ymax));

    // Errorbar caps
    g.select('line.errorbar-cap-top')
      .transition(t)
      .attr('x1', flip ? ySF(d.ymax) : xSF(d.xmin))
      .attr('x2', flip ? ySF(d.ymax) : xSF(d.xmax))
      .attr('y1', flip ? xSF(d.xmin) : ySF(d.ymax))
      .attr('y2', flip ? xSF(d.xmax) : ySF(d.ymax));

    g.select('line.errorbar-cap-bottom')
      .transition(t)
      .attr('x1', flip ? ySF(d.ymin) : xSF(d.xmin))
      .attr('x2', flip ? ySF(d.ymin) : xSF(d.xmax))
      .attr('y1', flip ? xSF(d.xmin) : ySF(d.ymin))
      .attr('y2', flip ? xSF(d.xmax) : ySF(d.ymin));

    // Pointrange center point
    g.select('circle.pointrange-point')
      .transition(t)
      .attr('cx', flip ? ySF(d[d._yKey || 'y']) : xSF(x))
      .attr('cy', flip ? xSF(x) : ySF(d[d._yKey || 'y']));
  });
```

**Critical detail:** The interval renderer stores `d.xmin`/`d.xmax` for errorbar cap
width (see interval.js lines 56-73). The datum row therefore has `x`, `y`, `ymin`,
`ymax`, `xmin`, `xmax` fields. No auxiliary data store is needed.

**Flip handling note:** The existing interval renderer already uses `flip ? yScale : xScale`
switching (interval.js lines 43-46). The `updateGeoms` pattern must mirror this exactly.

### Recommended Sub-element Selector Strategy for Hover/Brush

For hover, the `mouseover.hover` handler in `events.js` dims all INTERACTIVE_SELECTORS
elements. Adding `line.interval-line`, `line.errorbar-cap-top`, `line.errorbar-cap-bottom`,
and `circle.pointrange-point` means all sub-elements of one interval item respond
simultaneously to hover — which matches user expectation of highlighting the whole
errorbar.

For brush, `isElementInPixelRect` already handles `line` elements correctly. Circles
are handled too. No new hit-testing code needed.

### README Regeneration Pattern

```r
# Source: CLAUDE.md development commands
devtools::build_readme()
```

The README.Rmd file already contains the complete v1.6 feature list (confirmed by
file inspection — 141 lines vs README.md's 138 lines, and README.Rmd includes
`geom_dotplot`, `geom_rug`, `geom_errorbar`, interval geoms, `d3_transitions`,
`d3_handlers`, coord_polar, advanced scale configuration, and the full interactivity
API). Running `build_readme()` once regenerates README.md with no other changes needed.

### Anti-Patterns to Avoid

- **Modifying INTERACTIVE_SELECTORS in only one file:** Both `events.js` and `brush.js`
  have independent copies of the array. Missing one means half the interactions still break.
- **Using `.transition(t)` on the parent `g.interval-item`:** D3 transitions on a
  `<g>` do not propagate to child elements' positional attributes. Must select child
  elements explicitly.
- **Using `g.select(this)` outside `.each()`:** The `.each()` callback is the correct
  pattern for per-element child manipulation within a group, as used by the existing
  boxplot update code.
- **Cleaning up countidx without IR tests:** The `countidx` aes is mapped in
  `as_d3_ir.R` but unused in `dotplot.js`. It is safe to leave as-is (orphaned field
  in IR does not break anything) or remove it from the aes mapping. Removing it risks
  breaking any downstream code that might check for the field — leave for a separate
  cleanup unless tests confirm it is safe.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Hit-testing for new geoms | Custom hit-test logic | Existing `isElementInPixelRect` in brush.js | Already handles `circle`, `line`, `rect`, `path`, `text` by element tag |
| Interval child element transitions | Loop with setTimeout | D3 `.each()` + `d3.select(this).select(childClass)` | The boxplot update (lines 307-317) demonstrates the exact pattern |
| README content | Manual copy/paste | `devtools::build_readme()` | Pandoc-rendered from Rmd; manual editing would break code block formatting |

## Common Pitfalls

### Pitfall 1: INTERACTIVE_SELECTORS Divergence
**What goes wrong:** `events.js` and `brush.js` each have their own copy of
`INTERACTIVE_SELECTORS`. Adding to one but not the other means brush works but hover
doesn't (or vice versa).
**Why it happens:** The arrays are module-local constants in separate IIFEs; there is
no shared reference.
**How to avoid:** Edit both files in the same commit. The plan should treat them as a
single atomic change.
**Warning signs:** Brush selection dims dotplot dots but hover has no effect on them.

### Pitfall 2: Interval Zoom Stub — Transition Scoping
**What goes wrong:** Calling `.transition(t)` on `g.interval-item` (the parent `<g>`)
doesn't animate child lines and circles. They stay at original positions.
**Why it happens:** D3 transitions on `<g>` elements only affect the `<g>` itself
(e.g., a `transform` attribute), not child element positional attributes.
**How to avoid:** Use `.each()` to iterate items and call `.transition(t)` on each
child selection explicitly.
**Warning signs:** Interval marks don't move during zoom animation even after the stub
is replaced.

### Pitfall 3: Flip Coordinate Inversion in updateGeoms
**What goes wrong:** `updateGeoms` swaps xScaleFunc/yScaleFunc via the `flip` flag
(`const xScaleFunc = flip ? yScale : xScale`). But the interval renderer uses a
different internal convention for which axis is "x" in the drawn coordinates.
**Why it happens:** The interval renderer (interval.js line 33-46) already accounts for
flip internally, using `flip ? yScale(d.ymin) : xScale(d.x)` patterns. The
`updateGeoms` replacement must reproduce this same logic (not apply an outer flip swap
on top of it).
**How to avoid:** Use `flip ? yScaleFunc : xScaleFunc` for the data-x coordinate and
`flip ? xScaleFunc : yScaleFunc` for data-y. Compare directly against interval.js
attribute assignments.
**Warning signs:** Interval marks move to wrong positions on flipped plots after zoom.

### Pitfall 4: Missing Data Fields on Datum
**What goes wrong:** `updateGeoms` references `d.xmin`/`d.xmax` for errorbar caps but
the datum row for a linerange or pointrange doesn't have these fields (they are
errorbar-specific).
**Why it happens:** All three geom types share one `g.interval-item` class but have
different data shapes.
**How to avoid:** Guard cap updates with selector specificity (`g.interval-item` within
`.geom-interval-errorbar` group), or use `if (d.xmin != null)` guards. The parent
group has class `geom-interval-errorbar` / `geom-interval-linerange` etc. — use that
for scoped selection.
**Warning signs:** `NaN` attribute values on line elements during zoom of a linerange
or pointrange plot.

## Code Examples

### Adding to INTERACTIVE_SELECTORS (events.js)
```javascript
// Source: inst/htmlwidgets/modules/events.js, lines 23-37
// Append these entries to the INTERACTIVE_SELECTORS array:
const INTERACTIVE_SELECTORS = [
  'circle.geom-point',
  'rect.geom-bar',
  'rect.geom-rect',
  'path.geom-line',
  'path.geom-area',
  'path.geom-density',
  'path.geom-smooth',
  'path.geom-ribbon',
  'path.geom-violin',
  'text.geom-text',
  'line.geom-segment',
  'rect.geom-boxplot-box',
  'circle.geom-boxplot-outlier',
  // Phase 26 additions:
  'circle.geom-dotplot',
  'line.geom-rug',
  'line.interval-line',
  'line.errorbar-cap-top',
  'line.errorbar-cap-bottom',
  'circle.pointrange-point'
];
```

### Interval updateGeoms (scoped by parent group class)
```javascript
// Source: inst/htmlwidgets/modules/geom-registry.js, replace lines 354-361
// Use scoped selectors to avoid cross-contamination between geom sub-types:
container.selectAll('g.geom-interval-errorbar g.interval-item').each(function(d) {
  const g = d3.select(this);
  g.select('line.interval-line').transition(t)
    .attr('x1', flip ? yScaleFunc(d.ymin) : xScaleFunc(d[aes_x]))
    .attr('x2', flip ? yScaleFunc(d.ymax) : xScaleFunc(d[aes_x]))
    .attr('y1', flip ? xScaleFunc(d[aes_x]) : yScaleFunc(d.ymin))
    .attr('y2', flip ? xScaleFunc(d[aes_x]) : yScaleFunc(d.ymax));
  g.select('line.errorbar-cap-top').transition(t)
    .attr('x1', flip ? yScaleFunc(d.ymax) : xScaleFunc(d.xmin))
    .attr('x2', flip ? yScaleFunc(d.ymax) : xScaleFunc(d.xmax))
    .attr('y1', flip ? xScaleFunc(d.xmin) : yScaleFunc(d.ymax))
    .attr('y2', flip ? xScaleFunc(d.xmax) : yScaleFunc(d.ymax));
  g.select('line.errorbar-cap-bottom').transition(t)
    .attr('x1', flip ? yScaleFunc(d.ymin) : xScaleFunc(d.xmin))
    .attr('x2', flip ? yScaleFunc(d.ymin) : xScaleFunc(d.xmax))
    .attr('y1', flip ? xScaleFunc(d.xmin) : yScaleFunc(d.ymin))
    .attr('y2', flip ? xScaleFunc(d.xmax) : yScaleFunc(d.ymin));
});

container.selectAll('g.geom-interval-linerange g.interval-item').each(function(d) {
  const g = d3.select(this);
  const aes_x = 'x'; // linerange uses x directly
  g.select('line.interval-line').transition(t)
    .attr('x1', flip ? yScaleFunc(d.ymin) : xScaleFunc(d[aes_x]))
    .attr('x2', flip ? yScaleFunc(d.ymax) : xScaleFunc(d[aes_x]))
    .attr('y1', flip ? xScaleFunc(d[aes_x]) : yScaleFunc(d.ymin))
    .attr('y2', flip ? xScaleFunc(d[aes_x]) : yScaleFunc(d.ymax));
});

container.selectAll('g.geom-interval-pointrange g.interval-item').each(function(d) {
  const g = d3.select(this);
  const aes_x = 'x';
  const aes_y = 'y';
  g.select('line.interval-line').transition(t)
    .attr('x1', flip ? yScaleFunc(d.ymin) : xScaleFunc(d[aes_x]))
    .attr('x2', flip ? yScaleFunc(d.ymax) : xScaleFunc(d[aes_x]))
    .attr('y1', flip ? xScaleFunc(d[aes_x]) : yScaleFunc(d.ymin))
    .attr('y2', flip ? xScaleFunc(d[aes_x]) : yScaleFunc(d.ymax));
  g.select('circle.pointrange-point').transition(t)
    .attr('cx', flip ? yScaleFunc(d[aes_y]) : xScaleFunc(d[aes_x]))
    .attr('cy', flip ? xScaleFunc(d[aes_x]) : yScaleFunc(d[aes_y]));
});
```

**Note:** The `aes_x` key should ideally come from the layer's `aes` object. Since
`updateGeoms` does not receive the layer object, using `'x'` and `'y'` as string
literals is the pragmatic choice — consistent with how the existing dotplot (line 333-334)
and boxplot updates work.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| R / devtools | build_readme() | Yes | standard R env | pkgload::load_all() |
| D3 v7 (vendored) | JS interactivity | Yes | vendored in lib/ | — |
| Node.js | gsd-tools | Yes | runtime | — |

**Missing dependencies with no fallback:** None.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | testthat 3.x |
| Config file | tests/testthat.R |
| Quick run command | `devtools::test_file("tests/testthat/test-geoms-phase4.R")` |
| Full suite command | `devtools::test()` |

### Phase Requirements to Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| GEOM-20 | dotplot IR round-trips stackpos/binwidth | unit | `devtools::test_file("tests/testthat/test-geoms-phase4.R")` | Yes (line 316) |
| GEOM-20 | dotplot circle.geom-dotplot in INTERACTIVE_SELECTORS | unit (JS contract) | JS contract test in test-interactivity.R | No — Wave 0 gap |
| GEOM-21 | rug IR round-trips sides parameter | unit | `devtools::test_file("tests/testthat/test-geoms-phase4.R")` | Yes (line 324) |
| GEOM-21 | rug line.geom-rug in INTERACTIVE_SELECTORS | unit (JS contract) | JS contract test in test-interactivity.R | No — Wave 0 gap |
| GEOM-22 | interval IR round-trips ymin/ymax | unit | `devtools::test_file("tests/testthat/test-geoms-phase4.R")` | Yes (line 332) |
| GEOM-22 | interval updateGeoms not a stub | unit (JS contract) | JS contract test in test-zoom-brush.R | No — Wave 0 gap |
| API-02 | README.md matches README.Rmd content | manual check | diff README.md README.Rmd rendered output | N/A — regeneration task |

### Wave 0 Gaps
- [ ] `tests/testthat/test-interactivity.R` — add R-side checks that INTERACTIVE_SELECTORS values appear in rendered IR/layer data (or document that JS selector coverage is verified visually)
- [ ] `tests/testthat/test-zoom-brush.R` — add R-side check that interval geom IR has ymin/ymax/xmin/xmax fields needed by updateGeoms

**Note on JS testing:** The project has no JS test framework (no Jest/Vitest config
detected). JavaScript interactivity correctness has historically been verified visually
via `test_output/` HTML snapshots. The Wave 0 gaps above are R-layer contract tests;
the JS behavior is verified by manual visual inspection per project convention.

## Open Questions

1. **countidx cleanup scope**
   - What we know: `countidx` is mapped in `as_d3_ir.R` but never read by `dotplot.js`. It appears in the IR aes as `countidx: "countidx"` when the column is present.
   - What's unclear: Whether any downstream code or test references the countidx aes key.
   - Recommendation: Grep for `countidx` in tests before removing. If no test references it, remove the aes mapping in `as_d3_ir.R` as part of the tech debt cleanup. If tests reference it, leave it and document.

2. **interval-line selector collision risk**
   - What we know: `line.interval-line` is a sub-element inside `g.interval-item`, which is inside `g.geom-interval-errorbar` etc.
   - What's unclear: Whether `line.interval-line` is used as a class anywhere else in the codebase that would cause unintended selection.
   - Recommendation: A quick grep confirms `interval-line` is only in `interval.js`. Safe to add to INTERACTIVE_SELECTORS.

## Sources

### Primary (HIGH confidence)
- Direct source file inspection — `events.js`, `brush.js`, `geom-registry.js`, `interval.js`, `dotplot.js`, `rug.js`
- Audit document — `.planning/v1.6-MILESTONE-AUDIT.md` (authoritative gap description)
- `README.md` / `README.Rmd` — confirmed content divergence by direct inspection

### Secondary (MEDIUM confidence)
- Pattern extrapolation from existing boxplot updateGeoms (lines 299-317 in geom-registry.js) applied to interval sub-elements

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new dependencies; all changes are in already-present files
- Architecture: HIGH — exact insertion points identified by line number from direct file inspection
- Pitfalls: HIGH — derived directly from code structure (stub at line 355-361, dual-array problem confirmed in both files)

**Research date:** 2026-04-03
**Valid until:** 2026-05-03 (stable internal codebase — no external dependency drift risk)
