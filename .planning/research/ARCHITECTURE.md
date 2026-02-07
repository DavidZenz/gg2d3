# Architecture Research

**Domain:** ggplot2-to-D3.js translation
**Researched:** 2026-02-07
**Confidence:** HIGH

## Recommended Architecture

The architecture should evolve from the current three-layer pipeline to a **modular component system** with clear boundaries between extraction, representation, and rendering layers. This follows proven patterns from Vega-Lite, Plotly, and Observable Plot while respecting gg2d3's htmlwidgets foundation.

### System Overview

```
┌──────────────────────────────────────────────────────────────────┐
│                         R LAYER (ggplot2 → IR)                    │
├──────────────────────────────────────────────────────────────────┤
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐           │
│  │  Extractor   │  │   Builder    │  │  Validator   │           │
│  │  Modules     │→ │   Modules    │→ │  Modules     │           │
│  └──────────────┘  └──────────────┘  └──────────────┘           │
│      ↓ scales          ↓ IR assembly      ↓ IR validation       │
│      ↓ themes          ↓ unit conversion  ↓ schema checks       │
│      ↓ geoms           ↓ defaults         ↓ integrity           │
│      ↓ facets                                                     │
│      ↓ legends                                                    │
├──────────────────────────────────────────────────────────────────┤
│                    IR LAYER (JSON Schema)                         │
├──────────────────────────────────────────────────────────────────┤
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  {                                                        │   │
│  │    version: "2.0",                                        │   │
│  │    scales: { x, y, color, size, ... },                   │   │
│  │    layers: [{ geom, data, aes, params, stat }, ...],     │   │
│  │    guides: { legends: [...], axes: {...} },               │   │
│  │    facets: { type, rows, cols, layout, scales },         │   │
│  │    theme: { panel, plot, grid, axis, legend, text },     │   │
│  │    coord: { type, flip, expand, ... }                     │   │
│  │  }                                                        │   │
│  └──────────────────────────────────────────────────────────┘   │
├──────────────────────────────────────────────────────────────────┤
│                      D3 LAYER (Rendering)                         │
├──────────────────────────────────────────────────────────────────┤
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐         │
│  │  Scale   │  │  Layout  │  │  Render  │  │  Event   │         │
│  │  Factory │→ │  Engine  │→ │  Engine  │→ │  System  │         │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘         │
│      ↓             ↓              ↓              ↓                │
│  makeScale()   calculate     draw geoms    attach handlers       │
│  makeGuide()   positions     draw guides   pipe API              │
│                                                                   │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │              Geom Registry                              │    │
│  │  point, line, bar, area, ribbon, boxplot, ...          │    │
│  └─────────────────────────────────────────────────────────┘    │
└──────────────────────────────────────────────────────────────────┘
```

### Component Responsibilities

| Component | Responsibility | Typical Implementation |
|-----------|----------------|------------------------|
| **Extractor Modules** | Extract specific ggplot2 components | `extract_scales()`, `extract_theme()`, `extract_facets()`, `extract_guides()` |
| **Builder Modules** | Assemble IR with conversions | `build_scale_ir()`, `build_layer_ir()`, `build_guide_ir()` |
| **Validator Modules** | Verify IR integrity | `validate_scale_domain()`, `validate_geom_data()`, `check_ir_schema()` |
| **Scale Factory** | Create D3 scales from IR | `makeScale(desc)` returns d3.scale* instance |
| **Layout Engine** | Calculate positions, spacing | Panel layout, facet grid, legend placement calculations |
| **Render Engine** | Draw SVG elements | `renderGeom(layer)`, `renderGuides()`, `renderFacets()` |
| **Geom Registry** | Pluggable geom renderers | Each geom has `render(data, scales, aes, params)` function |
| **Event System** | Interactive behavior | Tooltip handlers, brush/zoom, linked views via pipe API |

## Recommended Project Structure

```
R/
├── gg2d3.R                    # Main widget entry point
├── as_d3_ir.R                 # Top-level IR builder (orchestrator)
├── extract/                   # Extractor modules
│   ├── extract-scales.R       # Scale extraction
│   ├── extract-theme.R        # Theme element extraction
│   ├── extract-geoms.R        # Layer/geom data extraction
│   ├── extract-facets.R       # Facet layout extraction
│   └── extract-guides.R       # Legend/axis guide extraction
├── build/                     # Builder modules
│   ├── build-scale-ir.R       # Scale IR construction
│   ├── build-layer-ir.R       # Layer IR with unit conversions
│   ├── build-guide-ir.R       # Guide IR (legends, axes)
│   └── build-facet-ir.R       # Facet IR with panel layout
├── validate/                  # Validator modules
│   ├── validate-ir.R          # IR schema validation
│   └── validate-components.R  # Component integrity checks
├── utils/                     # Shared utilities
│   ├── unit-conversions.R     # Centralized mm→px conversions
│   ├── color-utils.R          # Color translation helpers
│   └── discrete-mapping.R     # Categorical value mapping
└── interactivity.R            # Pipe API: d3_tooltip(), d3_brush(), etc.

inst/htmlwidgets/
├── gg2d3.js                   # Main widget (orchestrator)
├── lib/
│   └── d3/d3.v7.min.js        # D3 dependency
├── modules/                   # D3 modules
│   ├── scale-factory.js       # makeScale() and helpers
│   ├── layout-engine.js       # Position/spacing calculations
│   ├── render-engine.js       # Core rendering orchestration
│   ├── theme-system.js        # Theme application
│   └── event-system.js        # Event handlers and pipe API
├── geoms/                     # Geom renderers (registry)
│   ├── geom-point.js          # renderPoint(layer, scales, g)
│   ├── geom-line.js           # renderLine(layer, scales, g)
│   ├── geom-bar.js            # renderBar(layer, scales, g)
│   ├── geom-area.js           # renderArea(layer, scales, g)
│   ├── geom-boxplot.js        # renderBoxplot(layer, scales, g)
│   └── registry.js            # Geom lookup and dispatch
├── guides/                    # Guide renderers
│   ├── render-legend.js       # Legend layout and rendering
│   ├── render-axis.js         # Axis rendering
│   └── render-facet.js        # Facet panel layout
└── utils/                     # JavaScript utilities
    ├── color-utils.js         # convertColor(), isValidColor()
    ├── data-utils.js          # asRows(), val(), num()
    └── geometry-utils.js      # Path generation helpers
```

### Structure Rationale

- **R extract/build/validate**: Separates concerns—extraction uses ggplot2 APIs, building assembles IR with conversions, validation ensures correctness before serialization
- **D3 modules/geoms/guides**: Modular D3 code allows independent development and testing of components, enables tree-shaking for bundle size optimization
- **Geom registry pattern**: Each geom is a standalone function `render(layer, scales, g)` that knows how to draw itself—extensible, testable, maintainable
- **Pipe API in R/interactivity.R**: Composable interactivity like `gg2d3(p) |> d3_tooltip() |> d3_zoom()` following tidyverse conventions

## Architectural Patterns

### Pattern 1: Extractor-Builder-Validator Pipeline

**What:** Separation of ggplot2 extraction (uses private APIs), IR building (applies conversions), and validation (checks integrity)

**When to use:** Always—this is the core R-side architecture

**Trade-offs:**
- **Pros:** Isolates ggplot2 API fragility to extractors, builders can be tested independently, validators catch issues before JSON serialization
- **Cons:** More files/functions than monolithic approach, requires coordination between modules

**Example:**
```r
# Orchestrator in as_d3_ir.R
as_d3_ir <- function(p, width = 640, height = 400) {
  b <- ggplot2::ggplot_build(p)

  # Extract (uses ggplot2 internals)
  scales_raw <- extract_scales(b)
  theme_raw <- extract_theme(b)
  layers_raw <- extract_geoms(b)
  facets_raw <- extract_facets(b)
  guides_raw <- extract_guides(b)

  # Build (assembles IR with conversions)
  ir <- list(
    version = "2.0",
    scales = build_scale_ir(scales_raw),
    layers = build_layer_ir(layers_raw, scales_raw),
    guides = build_guide_ir(guides_raw),
    facets = build_facet_ir(facets_raw),
    theme = build_theme_ir(theme_raw),
    coord = build_coord_ir(b$plot$coordinates)
  )

  # Validate (checks before serialization)
  validate_ir(ir)

  ir
}
```

### Pattern 2: Geom Registry with Renderer Functions

**What:** Each geom is a standalone JavaScript function registered in a lookup table, dispatched by `geom` name from IR

**When to use:** Always for geom rendering—enables extensibility and testing

**Trade-offs:**
- **Pros:** Easy to add new geoms without modifying core, each geom is independently testable, clear separation of concerns
- **Cons:** Slight dispatch overhead (negligible), requires consistent interface across all geoms

**Example:**
```javascript
// geoms/registry.js
import { renderPoint } from './geom-point.js';
import { renderLine } from './geom-line.js';
import { renderBar } from './geom-bar.js';
// ... import all geoms

export const geomRegistry = {
  point: renderPoint,
  line: renderLine,
  path: renderLine,  // Same renderer
  bar: renderBar,
  col: renderBar,
  area: renderArea,
  // ... all 30+ geoms
};

export function renderLayer(layer, scales, g, theme) {
  const renderer = geomRegistry[layer.geom];
  if (!renderer) {
    console.warn(`Unsupported geom: ${layer.geom}`);
    return;
  }
  renderer(layer, scales, g, theme);
}

// geoms/geom-point.js
export function renderPoint(layer, scales, g, theme) {
  const data = asRows(layer.data);
  const aes = layer.aes || {};

  g.selectAll("circle")
    .data(data)
    .enter().append("circle")
    .attr("cx", d => scales.x(d[aes.x]))
    .attr("cy", d => scales.y(d[aes.y]))
    .attr("r", d => calculateRadius(d, aes, layer.params))
    .attr("fill", d => getFillColor(d, aes, layer.params))
    // ... more attributes
}
```

### Pattern 3: Layout Engine for Positioning

**What:** Centralized calculation of all spatial positions (panel layout, facet grids, legend placement, axis positioning)

**When to use:** Required for facets and legends—avoids hardcoded positions scattered across renderers

**Trade-offs:**
- **Pros:** Single source of truth for layout math, easier to debug positioning issues, cleaner geom renderers
- **Cons:** Additional abstraction layer, must pass layout results to renderers

**Example:**
```javascript
// modules/layout-engine.js
export function calculateLayout(ir, width, height) {
  const theme = mergeTheme(ir.theme);
  const plotMargin = calculatePlotMargin(theme);

  // Calculate facet panel layout if present
  const panelLayout = ir.facets.type !== "none"
    ? calculateFacetLayout(ir.facets, width, height, plotMargin)
    : { panels: [{ x: plotMargin.left, y: plotMargin.top,
                   width: width - plotMargin.left - plotMargin.right,
                   height: height - plotMargin.top - plotMargin.bottom }] };

  // Calculate legend positions
  const legendLayout = calculateLegendLayout(ir.guides.legends, theme, width, height);

  return {
    plot: { width, height, margin: plotMargin },
    panels: panelLayout.panels,
    legends: legendLayout,
    axes: calculateAxisPositions(panelLayout.panels)
  };
}
```

### Pattern 4: Pipe-Based Interactivity API

**What:** R functions that augment gg2d3 widgets with interactive behavior via htmlwidgets message passing

**When to use:** For all interactivity—tooltips, brushing, zooming, linked views

**Trade-offs:**
- **Pros:** Familiar tidyverse syntax, composable (`p |> f() |> g()`), lazy evaluation until render
- **Cons:** Requires htmlwidgets message protocol, more complex than direct JavaScript

**Example:**
```r
# R/interactivity.R
d3_tooltip <- function(widget, fields = NULL, format = NULL) {
  widget$x$tooltip <- list(
    enabled = TRUE,
    fields = fields,
    format = format
  )
  widget
}

d3_brush <- function(widget, on_brush = NULL) {
  widget$x$brush <- list(
    enabled = TRUE,
    callback = on_brush  # Shiny output ID or JS function
  )
  widget
}

# Usage
gg2d3(p) |>
  d3_tooltip(fields = c("x", "y", "Species")) |>
  d3_brush(on_brush = "brush_output")
```

### Pattern 5: IR Versioning and Schema Validation

**What:** Explicit IR version field and schema validation to catch breaking changes early

**When to use:** Always—prevents silent failures when IR format evolves

**Trade-offs:**
- **Pros:** Clear contract between R and D3 layers, easier to migrate formats, catches errors before rendering
- **Cons:** Requires maintenance of schema definitions, validation overhead

**Example:**
```r
# R/validate/validate-ir.R
validate_ir <- function(ir) {
  # Check version
  if (is.null(ir$version) || ir$version < "2.0") {
    stop("IR version 2.0+ required")
  }

  # Check required top-level fields
  required_fields <- c("scales", "layers", "guides", "theme", "coord")
  missing <- setdiff(required_fields, names(ir))
  if (length(missing) > 0) {
    stop("Missing required IR fields: ", paste(missing, collapse = ", "))
  }

  # Validate scales
  validate_scales(ir$scales)

  # Validate layers
  for (i in seq_along(ir$layers)) {
    validate_layer(ir$layers[[i]], i)
  }

  # ... more validation

  ir
}
```

## Data Flow

### Request Flow

```
User creates ggplot object (p)
    ↓
gg2d3(p)
    ↓
as_d3_ir(p) orchestrator
    ↓
┌───────────────── R EXTRACTION PHASE ─────────────────┐
│                                                       │
│  ggplot_build(p) → build object (b)                  │
│         ↓                                             │
│  ┌──────────────┐  ┌──────────────┐                 │
│  │ extract_     │  │ extract_     │  ...             │
│  │ scales()     │  │ theme()      │                  │
│  └──────────────┘  └──────────────┘                 │
│         ↓                  ↓                          │
│     scales_raw        theme_raw     ...              │
│                                                       │
└───────────────────────────────────────────────────────┘
    ↓
┌───────────────── R BUILDING PHASE ───────────────────┐
│                                                       │
│  ┌──────────────┐  ┌──────────────┐                 │
│  │ build_       │  │ build_       │  ...             │
│  │ scale_ir()   │  │ theme_ir()   │                  │
│  └──────────────┘  └──────────────┘                 │
│         ↓                  ↓                          │
│    Apply unit conversions, defaults, mappings        │
│         ↓                  ↓                          │
│  ir$scales = {...}, ir$theme = {...}, ...            │
│                                                       │
└───────────────────────────────────────────────────────┘
    ↓
validate_ir(ir) — schema checks, integrity validation
    ↓
htmlwidgets::createWidget() — JSON serialization
    ↓
┌─────────────── BROWSER RENDERING PHASE ──────────────┐
│                                                       │
│  JavaScript factory receives IR                      │
│         ↓                                             │
│  renderValue(ir)                                      │
│         ↓                                             │
│  layout = calculateLayout(ir, width, height)         │
│         ↓                                             │
│  ┌──────────────────────────────────────┐            │
│  │  Create SVG container                │            │
│  │  Apply plot/panel backgrounds        │            │
│  │  Create scales with makeScale()      │            │
│  │  Draw grid lines                     │            │
│  └──────────────────────────────────────┘            │
│         ↓                                             │
│  For each panel in layout.panels:                    │
│      Create panel <g> element                        │
│      Apply clip path                                 │
│      For each layer:                                 │
│          renderLayer(layer, scales, g, theme)        │
│              ↓                                        │
│          geomRegistry[layer.geom](...)               │
│         ↓                                             │
│  Draw axes with renderAxis()                         │
│  Draw legends with renderLegend()                    │
│  Apply theme styles                                  │
│         ↓                                             │
│  Attach event handlers (if pipe API used)            │
│         ↓                                             │
│  Display complete SVG                                │
│                                                       │
└───────────────────────────────────────────────────────┘
```

### State Management

**R Layer:**
- No persistent state—pure functions from ggplot to IR
- Each `gg2d3()` call rebuilds IR from scratch

**IR Layer:**
- Immutable—once serialized, never modified
- Version tracked for format migrations

**D3 Layer:**
- Minimal state—scales and layout computed per render
- Event state (brush selection, zoom transform) stored in widget instance
- Pipe API augments widget data structure with interaction configs

**Key Data Flows:**

1. **Scale Construction:** IR scale descriptor → `makeScale()` → D3 scale object → used by geom renderers
2. **Theme Application:** IR theme elements → merge with defaults → applied during rendering (backgrounds, axes, legends)
3. **Geom Rendering:** IR layer → `renderLayer()` → dispatch to geom renderer → draw SVG elements
4. **Facet Layout:** IR facets → `calculateFacetLayout()` → panel positions → each panel renders layers
5. **Legend Construction:** IR guides.legends → extract unique values → `renderLegend()` → positioned legend elements

## Scaling Considerations

| Scale | Architecture Adjustments |
|-------|--------------------------|
| **5-10 geoms** | Current monolithic approach acceptable, registry pattern optional |
| **15-30 geoms** | **Geom registry required**—monolithic code becomes unmaintainable; modular geoms enable parallel development |
| **Facets + Legends** | **Layout engine required**—hardcoded positions break; centralized layout math essential |
| **Complex interactions** | **Pipe API + event system required**—direct JavaScript coupling too rigid; composable API needed |

### Scaling Priorities

1. **First bottleneck: Geom coverage**
   - Current: 8 geoms in monolithic renderer (300+ lines of switch/if-else)
   - Fix: Implement geom registry pattern (Pattern 2) before adding more geoms
   - Impact: Each new geom is ~50-100 lines in separate file vs. growing monolith

2. **Second bottleneck: Layout complexity**
   - Current: Hardcoded single-panel layout with fixed padding
   - Fix: Implement layout engine (Pattern 3) when adding facets or legends
   - Impact: Layout math centralized, easier to debug positioning, supports multiple panels

3. **Third bottleneck: Maintainability**
   - Current: 353-line `as_d3_ir()` function, duplicated helpers, no validation
   - Fix: Refactor to extractor-builder-validator pipeline (Pattern 1)
   - Impact: Isolated changes, better testability, clearer ggplot2 API boundaries

## Anti-Patterns

### Anti-Pattern 1: Monolithic IR Builder

**What people do:** Keep all extraction and building in single 500+ line function

**Why it's wrong:**
- Mixes ggplot2 API usage with unit conversions and defaults
- Hard to test individual components
- Difficult to isolate ggplot2 version-specific changes
- Duplicates code across extraction logic

**Do this instead:** Extract-Build-Validate pipeline (Pattern 1)
- Separate `extract_*()` functions that use ggplot2 internals
- Separate `build_*()` functions that assemble IR with conversions
- Separate validation before serialization

### Anti-Pattern 2: Geom Switch Statement

**What people do:** Single giant `switch(layer.geom)` or `if-else` chain for all geoms

**Why it's wrong:**
- File grows to 1000+ lines with 30 geoms
- Merge conflicts when multiple people add geoms
- Can't test geoms in isolation
- Hard to find specific geom logic

**Do this instead:** Geom registry (Pattern 2)
- Each geom in separate file: `geoms/geom-point.js`
- Registry maps names to renderers: `geomRegistry[layer.geom]`
- Each geom function has consistent signature
- Easy to add/test/modify individual geoms

### Anti-Pattern 3: Hardcoded Positions

**What people do:** Calculate positions inline during rendering (e.g., `x: 50 + ...`)

**Why it's wrong:**
- Breaks when adding facets (multiple panels need different offsets)
- Breaks when adding legends (legend takes space from plot area)
- Impossible to debug layout issues—math scattered everywhere
- Can't support dynamic positioning based on content

**Do this instead:** Layout engine (Pattern 3)
- Calculate all positions upfront in `calculateLayout()`
- Pass layout results to renderers
- Single source of truth for all spatial math
- Easy to debug and adjust

### Anti-Pattern 4: Direct JavaScript for Interactivity

**What people do:** Require users to write custom JavaScript to add tooltips/interactions

**Why it's wrong:**
- R users expect R API
- Doesn't compose with ggplot2 workflow
- Hard to maintain (JavaScript scattered in R code)
- No consistency across plots

**Do this instead:** Pipe API (Pattern 4)
- R functions like `d3_tooltip()`, `d3_brush()`
- Compose with `|>` operator: `gg2d3(p) |> d3_tooltip()`
- Consistent with tidyverse conventions
- Works in Rmarkdown without custom JavaScript

### Anti-Pattern 5: Silent IR Format Changes

**What people do:** Modify IR structure without versioning or validation

**Why it's wrong:**
- Old plots break silently when IR format changes
- Hard to migrate between versions
- Errors happen in D3 layer (far from source)
- No clear contract between R and JavaScript

**Do this instead:** IR versioning + validation (Pattern 5)
- Explicit `version` field in IR
- Schema validation before serialization
- Fail fast in R layer with clear error messages
- Migration path for IR format changes

## Integration Points

### External Services

| Service | Integration Pattern | Notes |
|---------|---------------------|-------|
| **ggplot2** | Direct R API calls in extractors | Use public APIs where possible; isolate private API usage (`:::calc_element`) to extractor modules for easy updates |
| **grid** | Unit conversion via `grid::convertUnit()` | Used for theme margin conversion (mm/inches → pixels) |
| **htmlwidgets** | Standard widget creation + message passing | Core integration—widget creation, JSON serialization, JavaScript binding |
| **D3 v7** | ES6 module imports | Vendored at `inst/htmlwidgets/lib/d3/d3.v7.min.js`; use ES6 `import` for tree-shaking if bundling |
| **Shiny (future)** | htmlwidgets message protocol | Pipe API callbacks can target Shiny outputs; no special Shiny code in core package |

### Internal Boundaries

| Boundary | Communication | Notes |
|----------|---------------|-------|
| **Extractors ↔ Builders** | Raw data structures (lists) | Extractors return unprocessed ggplot2 objects; builders normalize to IR format |
| **Builders ↔ Validators** | Complete IR object | Builders create IR; validators check schema/integrity before JSON serialization |
| **R ↔ JavaScript** | JSON-serialized IR via htmlwidgets | One-way data flow; no callbacks from D3 to R (except Shiny messages) |
| **Render Engine ↔ Geoms** | Function calls with scales, data, SVG group | Render engine dispatches to geom registry; geoms draw into provided `<g>` element |
| **Layout Engine ↔ Renderers** | Layout descriptor object | Layout engine calculates positions; renderers use layout.panels, layout.legends, etc. |

## Component Build Order

The right build order minimizes rework and allows incremental validation. Components have natural dependencies—scales must exist before geoms can render, legends need scales to be complete, facets need layout engine.

### Phase 1: Modularize Core (Foundation)
**Goal:** Extract existing functionality into modular components without adding features

**Components:**
1. **Geom registry** — Extract 8 existing geoms into separate files
2. **Scale factory** — Extract `makeScale()` into module
3. **Theme system** — Extract theme merging and application
4. **Unit conversion utilities** — Centralize mm→px conversions

**Rationale:** Refactoring first makes subsequent additions cleaner. Current code is monolithic (353-line `as_d3_ir()`, 716-line `gg2d3.js`). Modularizing before adding 30 geoms prevents 2000+ line files.

**Validation:** Existing plots render identically after refactor (regression tests)

---

### Phase 2: Scale System (Prerequisite for Everything)
**Goal:** Full scale coverage—all ggplot2 scale types supported

**Components:**
1. **R scale extractors** — `extract_scales()` handles all scale types (date/time, color palettes, transformations)
2. **R scale IR builders** — `build_scale_ir()` for each scale type with proper domain/range handling
3. **D3 scale factory** — Extend `makeScale()` for color scales, date scales, diverging scales, etc.
4. **Color scale system** — Full color/fill palette support (viridis, brewer, manual)

**Rationale:** Scales are used by geoms, legends, and axes. Incomplete scale support blocks everything downstream. Better to have robust scales early than patch them repeatedly while building geoms/legends.

**Validation:** All ggplot2 scale types render correctly in isolation

---

### Phase 3: Geom Coverage (User Value)
**Goal:** Support all 30+ common ggplot2 geoms

**Components (in dependency order):**
1. **Statistical geoms** — boxplot, violin, density, histogram, bin2d (need stat computation in R)
2. **Area/ribbon geoms** — area, ribbon, polygon (need path generation helpers)
3. **Annotation geoms** — segment, curve, spoke, errorbar, crossbar, linerange, pointrange
4. **Specialized geoms** — contour, hex, raster, quantile, rug, step

**Rationale:** Each geom is independent once registry exists (Phase 1). Statistical geoms first because they're most requested. Area/ribbon share path logic. Annotations have similar structure.

**Validation:** Each geom renders identically to ggplot2 output; test suite with visual comparisons

---

### Phase 4: Layout Engine (Required for Guides)
**Goal:** Centralized position calculation supporting guides and facets

**Components:**
1. **Layout engine core** — `calculateLayout()` for spatial math
2. **Legend positioning** — Calculate legend placement based on size and position (`"right"`, `"bottom"`, etc.)
3. **Axis positioning** — Handle secondary axes, positioning based on data range
4. **Panel calculations** — Prepare for facets (single panel initially)

**Rationale:** Legends need space carved out of plot area—can't hardcode. Layout engine enables legends in Phase 5 and facets in Phase 6. Building layout engine before legends avoids rewriting legend code when facets arrive.

**Validation:** Single-panel layouts match current behavior; layout math is unit-tested

---

### Phase 5: Legend System (Visibility into Aesthetics)
**Goal:** Automatic legends for all aesthetic mappings

**Components:**
1. **R guide extraction** — `extract_guides()` gets legend specs from ggplot2 build
2. **R guide IR builder** — `build_guide_ir()` with key-value pairs, colors, shapes, sizes
3. **D3 legend renderer** — `renderLegend()` for color, fill, size, shape, alpha legends
4. **Legend layout** — Use layout engine to position legends around plot

**Rationale:** Legends require complete scale system (Phase 2), layout engine (Phase 4), and geom glyphs. Building legends validates that scales work correctly and makes debugging geoms easier (can see what data maps to what aesthetics).

**Validation:** Legends match ggplot2 appearance; all aesthetic types supported

---

### Phase 6: Facet System (Small Multiples)
**Goal:** facet_wrap and facet_grid support

**Components:**
1. **R facet extraction** — `extract_facets()` gets facet layout from ggplot2
2. **R facet IR builder** — `build_facet_ir()` with panel layout, scale sharing, strip labels
3. **Layout engine extension** — Multi-panel calculations with spacing
4. **D3 facet renderer** — `renderFacet()` creates panel grid with strip labels
5. **Per-panel rendering** — Loop over panels, render layers with panel-specific scales

**Rationale:** Facets are the most complex feature—require layout engine, complete geom coverage, and proper scale handling. Building facets last allows all earlier components to be battle-tested. Facets also benefit from legends being complete (facets + legends = complex layout).

**Validation:** Faceted plots match ggplot2 layout; scale sharing works correctly

---

### Phase 7: Interactivity (User Engagement)
**Goal:** Pipe-based API for tooltips, brushing, zooming, linked views

**Components:**
1. **Event system** — D3 event handlers for hover, click, brush, zoom
2. **Tooltip module** — `d3_tooltip()` pipe function and D3 tooltip renderer
3. **Brush/zoom module** — `d3_brush()`, `d3_zoom()` with scale updates
4. **Linked views** — `d3_link()` for cross-widget communication
5. **Shiny integration** — Message passing to Shiny outputs

**Rationale:** Interactivity is value-add on top of complete rendering. Users can create static plots with full coverage (Phases 1-6) before interactivity arrives. Building interactivity last allows API design informed by real usage patterns.

**Validation:** Interactive behaviors work smoothly; Shiny integration doesn't break static rendering

---

### Dependency Diagram

```
Phase 1: Modularize Core (foundation)
    ↓
Phase 2: Scale System (prerequisite for all rendering)
    ↓
    ├─→ Phase 3: Geom Coverage (independent geoms)
    │
    ↓
Phase 4: Layout Engine (required for guides)
    ↓
Phase 5: Legend System (uses scales + layout)
    ↓
Phase 6: Facet System (uses all prior components)
    ↓
Phase 7: Interactivity (augments complete renderer)
```

### Why This Order Works

1. **Foundation first** — Modularizing (Phase 1) prevents rework when adding features
2. **Scales early** — Everything depends on scales; getting them right upfront saves iteration
3. **Geoms next** — High user value, parallelizable once registry exists, validates scale system
4. **Layout before guides** — Avoids rewriting legends/facets when adding the other
5. **Legends before facets** — Legends are simpler, debug patterns apply to facets
6. **Facets late** — Most complex, benefits from stable foundation
7. **Interactivity last** — Pure enhancement, doesn't block core functionality

### Anti-Pattern: Wrong Build Order

**❌ Don't build facets before legends** — You'll rewrite facet layout when legends need space

**❌ Don't build geoms before modularizing** — You'll have a 2000-line file that's unmaintainable

**❌ Don't build legends before layout engine** — You'll hardcode positions that break with facets

**❌ Don't build interactivity before complete rendering** — You'll design APIs around incomplete features

## Sources

### High Confidence (Official Documentation & Tools)

- [Vega-Lite: A High-Level Grammar of Interactive Graphics](https://vega.github.io/vega-lite/) — Declarative visualization architecture with automatic legend/axis generation
- [D3.js Modular Architecture (Medium)](https://medium.com/@christopheviau/d3-js-modularity-d5eed78ba06e) — ES6 modules, component patterns
- [ggplot2 Faceting Chapter](https://ggplot2-book.org/facet.html) — Official guide to facet implementation
- [D3.js Getting Started with Data-Driven Documents (2026)](https://thelinuxcode.com/d3js-getting-started-with-data-driven-documents-for-real-world-visualization-2026/) — Current D3 best practices

### Medium Confidence (Community & Research)

- [Plotly's ggplotly Converter](https://moderndata.plotly.com/ggplot2-docs-completely-remade-in-d3-js/) — ggplot2 to D3 translation via Plotly API
- [Grammar of Graphics Guide (Cornell)](https://info5940.infosci.cornell.edu/notes/dataviz/grammar-of-graphics/) — Grammar of graphics theory
- [Combining R and D3.js](https://www.ae.be/blog/combining-the-power-of-r-and-d3-js/) — Integration patterns
- [Interactive Data Visualization with D3.js](https://www.usdsi.org/data-science-insights/how-to-build-interactive-data-visualization-with-d3-js) — Event handling architecture

### Project-Specific (Analyzed Codebase)

- `/Users/davidzenz/R/gg2d3/R/as_d3_ir.R` — Current 353-line monolithic IR builder
- `/Users/davidzenv/R/gg2d3/inst/htmlwidgets/gg2d3.js` — Current 716-line D3 renderer
- `/Users/davidzenz/R/gg2d3/vignettes/d3-drawing-diagnostics.md` — Known issues document
- `/Users/davidzenz/R/gg2d3/.planning/codebase/ARCHITECTURE.md` — Current architecture analysis
- `/Users/davidzenz/R/gg2d3/.planning/PROJECT.md` — Project requirements and constraints

---

*Architecture research for: ggplot2-to-D3.js translation system*
*Researched: 2026-02-07*
