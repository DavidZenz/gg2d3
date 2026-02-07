# Phase 1: Foundation Refactoring - Research

**Researched:** 2026-02-07
**Domain:** JavaScript/D3.js modular architecture, R package design patterns, unit conversion standards
**Confidence:** HIGH

## Summary

Phase 1 refactors the existing monolithic gg2d3.js renderer (~1000 lines) into modular components using proven JavaScript design patterns while maintaining identical visual output. The research reveals that the current codebase has three critical refactoring opportunities: (1) geom rendering logic dispersed throughout a single draw() function can be extracted using the Registry + Strategy patterns, (2) unit conversion constants are hardcoded with inconsistent precision across 10+ locations, and (3) scale creation and theme handling involve duplicated logic that can be centralized.

The R layer (as_d3_ir.R) already follows S3 patterns appropriately, but lacks IR validation before JSON serialization. JavaScript module organization should use ES6 module syntax (supported in htmlwidgets) with factory functions for scale creation and a geom registry for extensibility. Visual regression testing is essential to verify pixel-perfect output preservation but presents challenges for D3/SVG rendering.

**Primary recommendation:** Use ES6 modules with a Registry pattern for geoms, centralize unit conversions in a constants module with documented DPI standards, implement scale/theme factories, and add JSON Schema validation in R before serialization. Test with manual visual comparison (automated SVG comparison has limited reliability for dynamic D3 content).

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| D3.js | v7 | SVG rendering, scales, axes | Already vendored, modular architecture, factory-based API |
| htmlwidgets | Latest | R-JavaScript bridge | Standard for R packages with JS visualizations |
| testthat | Latest | R unit testing | Standard R package testing framework |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| jsonlite | Latest | IR serialization (already used) | Automatic in htmlwidgets pipeline |
| Ajv | Latest | JSON Schema validation | If IR validation complexity increases beyond basic checks |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| ES6 modules | IIFE module pattern | ES6 is cleaner, better tooling support, htmlwidgets supports it |
| Manual validation | Ajv JSON Schema | Ajv adds dependency, overkill for simple IR structure |
| R6 classes | S3 functions | S3 is R standard, adequate for functional IR transformation |

**Installation:**
```r
# R dependencies already in DESCRIPTION
# D3.js already vendored in inst/htmlwidgets/lib/d3/
```

## Architecture Patterns

### Recommended Project Structure
```
inst/htmlwidgets/
├── gg2d3.js              # Main entry point, coordinates modules
├── modules/
│   ├── constants.js      # Unit conversion constants (mm→px, pt→px)
│   ├── scales.js         # Scale factory (makeScale + helpers)
│   ├── theme.js          # Theme factory (getTheme, applyAxisStyle)
│   ├── geom-registry.js  # Geom registry + base renderer interface
│   └── geoms/
│       ├── point.js      # Point geom renderer
│       ├── line.js       # Line/path geom renderer
│       ├── bar.js        # Bar/col geom renderer
│       ├── rect.js       # Rect/tile geom renderer
│       └── text.js       # Text geom renderer

R/
├── gg2d3.R               # Main widget function (unchanged)
├── as_d3_ir.R            # IR generator (add validation)
└── validate_ir.R         # NEW: IR validation before serialization
```

### Pattern 1: Geom Registry (Strategy + Registry)
**What:** Central registry maps geom names to renderer functions, allowing dynamic dispatch without giant if/else chains.

**When to use:** When you have multiple "kinds" of things that share a common interface but have different implementations. Perfect for geoms.

**Example:**
```javascript
// modules/geom-registry.js
const geomRegistry = new Map();

export function registerGeom(name, renderFn) {
  geomRegistry.set(name, renderFn);
}

export function renderGeom(geomName, layer, g, xScale, yScale, options) {
  const renderer = geomRegistry.get(geomName);
  if (!renderer) {
    console.warn(`gg2d3: unknown geom '${geomName}'`);
    return 0;
  }
  return renderer(layer, g, xScale, yScale, options);
}

// Register at module load
import { renderPoint } from './geoms/point.js';
import { renderLine } from './geoms/line.js';
// etc.

registerGeom('point', renderPoint);
registerGeom('line', renderLine);
registerGeom('path', renderLine); // same renderer
```

### Pattern 2: Scale Factory
**What:** Centralized function that creates D3 scale objects from IR descriptors, with consistent fallback logic.

**When to use:** When creating objects of different types based on runtime data. Already partially implemented in makeScale().

**Example:**
```javascript
// modules/scales.js
export function createScale(descriptor, range) {
  const type = normalizeType(descriptor?.type);
  const builder = scaleBuilders[type] || scaleBuilders.default;
  return builder(descriptor, range);
}

const scaleBuilders = {
  continuous: (desc, range) => d3.scaleLinear().domain(desc.domain).range(range),
  categorical: (desc, range) => d3.scaleBand().domain(desc.domain).range(range).padding(0.1),
  // ... etc
  default: (desc, range) => d3.scaleLinear().domain([0, 1]).range(range)
};
```

### Pattern 3: Constants Module
**What:** Single source of truth for unit conversions with documented standards.

**When to use:** Always, for magic numbers that appear in multiple places.

**Example:**
```javascript
// modules/constants.js
// Web standard: 96 DPI (W3C CSS specification)
// Source: https://www.w3.org/TR/css-values-3/#absolute-lengths
export const DPI = 96;
export const MM_PER_INCH = 25.4;
export const PT_PER_INCH = 72;

// Derived conversions
export const PX_PER_MM = DPI / MM_PER_INCH;  // 3.7795275591
export const PX_PER_PT = DPI / PT_PER_INCH;  // 1.3333...

// ggplot2-specific: size aesthetic is in mm, represents diameter
export function mmToPxRadius(sizeMm) {
  return (sizeMm * PX_PER_MM) / 2;
}

export function mmToPxLinewidth(linewidthMm) {
  return linewidthMm * PX_PER_MM;
}
```

### Pattern 4: Theme Factory with Defaults
**What:** Merge user theme with default theme using object destructuring/spreading, avoiding hardcoded fallbacks scattered throughout code.

**When to use:** Configuration objects that have defaults plus user overrides.

**Example:**
```javascript
// modules/theme.js
import { PX_PER_MM } from './constants.js';

const DEFAULT_THEME = {
  panel: {
    background: { type: "rect", fill: "#EBEBEB", colour: null },
    border: { type: "blank" }
  },
  grid: {
    major: { type: "line", colour: "white", linewidth: 1.89 },
    minor: { type: "line", colour: "white", linewidth: 0.945 }
  },
  // ... etc
};

export function createTheme(userTheme) {
  // Deep merge user theme over defaults
  return deepMerge(DEFAULT_THEME, userTheme || {});
}

export function getThemeElement(theme, path) {
  const parts = path.split(".");
  return parts.reduce((obj, key) => obj?.[key], theme);
}
```

### Anti-Patterns to Avoid
- **Magic numbers scattered in code:** All unit conversions, padding defaults, opacity values should be named constants
- **Geom logic in monolithic function:** Breaks Open/Closed Principle, makes testing individual geoms impossible
- **Inline theme fallbacks:** `|| "black"` scattered throughout loses single source of truth
- **No validation before serialization:** Invalid IR causes silent failures or cryptic JS errors

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| JSON Schema validation | Custom validator with if/else checks | Ajv or R-side validation functions | Schema validation has edge cases (nested objects, optional fields, type coercion) that are error-prone |
| Module bundling | Custom concatenation script | ES6 modules (native in modern browsers) | htmlwidgets supports ES6, browser handles loading, easier debugging |
| Visual regression testing | Pixel-by-pixel PNG comparison | Manual visual inspection + structural tests | D3/SVG rendering has sub-pixel variations, dynamic content, font rendering differences across environments |
| Deep object merging | Recursive function for theme merging | Lodash merge or small utility | Edge cases: arrays, null vs undefined, circular references |

**Key insight:** D3.js already provides factory patterns (scale constructors), so align with D3's conventions rather than inventing new patterns. Similarly, htmlwidgets handles serialization/deserialization automatically—add validation as a pre-serialization step in R, not post-deserialization in JS.

## Common Pitfalls

### Pitfall 1: Hardcoded DPI/Conversion Constants
**What goes wrong:** Current code uses `3.78` in some places, `3.7795275591` in others. Leads to subtle rendering inconsistencies and makes changing standards (e.g., high-DPI displays) require hunting down all instances.

**Why it happens:** Constants were calculated inline during development without central definition.

**How to avoid:**
- Create `constants.js` module with documented source (W3C spec: 96 DPI)
- Export conversion functions (`mmToPx`, `ptToPx`) instead of raw multipliers
- Reference constants by name everywhere: `sizeMm * PX_PER_MM`

**Warning signs:** Search for literal numbers like `96`, `3.78`, `1.89`, `0.945` in renderer code.

### Pitfall 2: Registry Without Clear Interface
**What goes wrong:** If geom renderers have inconsistent signatures or return values, registry becomes brittle. Some renderers might modify `g` directly, others return elements, some count drawn items, others don't.

**Why it happens:** No explicit contract/interface definition for what a geom renderer must do.

**How to avoid:**
- Document expected signature: `function renderGeom(layer, g, xScale, yScale, options) => number`
- Return value: count of drawn elements (for debugging)
- Options object: `{ colorScale, getTheme, constants }`
- All renderers append to `g`, never replace it

**Warning signs:** Different geoms using different parameter orders or missing error handling.

### Pitfall 3: Breaking Visual Output During Refactor
**What goes wrong:** Refactoring changes rendering logic accidentally—different scale padding, altered color resolution, shifted positioning. Tests pass but visuals differ.

**Why it happens:** No automated visual regression tests, only structural tests (IR shape, data presence).

**How to avoid:**
- Before refactoring: generate reference HTML outputs for all 8 geoms
- After each refactor step: regenerate outputs and manually compare side-by-side
- Test matrix: each geom × (continuous scales, categorical scales, flipped coords, custom theme)
- Document specific values to check: stroke-width, radius, position coords

**Warning signs:** Subtle differences in test outputs that aren't caught by unit tests.

### Pitfall 4: ES6 Modules in htmlwidgets
**What goes wrong:** Assuming htmlwidgets automatically bundles ES6 modules or transforms import/export. It doesn't—browser must support modules natively or you need explicit bundling.

**Why it happens:** htmlwidgets is designed for single-file JS, multi-file support requires explicit config.

**How to avoid:**
- Modern browsers support ES6 modules natively (2026 standard)
- Use `type="module"` in script tag (htmlwidgets may need wrapper)
- Alternative: manually concatenate modules during build (use `//@ sourceURL` for debuggability)
- Test in browser console for module loading errors

**Warning signs:** "Uncaught SyntaxError: Unexpected token 'export'" or modules not found.

### Pitfall 5: Over-Engineering Validation
**What goes wrong:** Adding heavyweight JSON Schema validation (Ajv library) increases bundle size and adds dependency for simple IR structure that rarely changes.

**Why it happens:** Premature optimization or fear of invalid data.

**How to avoid:**
- Start with R-side validation: check required fields (scales, layers), valid types
- Use simple checks: `stopifnot()`, `is.list()`, `inherits()`
- Only add JSON Schema if IR structure becomes complex (nested optionals, union types)
- Document IR schema in comments, not formal schema file

**Warning signs:** Large validation library for small IR, validation code longer than transformation code.

## Code Examples

Verified patterns from existing code and D3 conventions:

### Geom Renderer Interface
```javascript
// Source: current gg2d3.js pattern adapted for modularity
// Each geom renderer follows this interface:

/**
 * Render a geom layer to SVG
 * @param {Object} layer - Layer from IR (data, aes, params, geom)
 * @param {d3.Selection} g - D3 selection to append elements to
 * @param {d3.Scale} xScale - X scale function
 * @param {d3.Scale} yScale - Y scale function
 * @param {Object} options - Shared options (colorScale, getTheme, constants)
 * @returns {number} - Count of elements drawn (for debugging)
 */
export function renderPoint(layer, g, xScale, yScale, options) {
  const { asRows, val, num, constants } = options;
  const dat = asRows(layer.data);
  const aes = layer.aes || {};

  const pts = dat.filter(d => {
    const xVal = num(d[aes.x]);
    const yVal = num(d[aes.y]);
    return xVal != null && yVal != null;
  });

  g.selectAll("circle")
    .data(pts)
    .enter()
    .append("circle")
    .attr("cx", d => xScale(num(d[aes.x])))
    .attr("cy", d => yScale(num(d[aes.y])))
    .attr("r", d => {
      const sizeMm = num(d[aes.size]) || layer.params?.size || 1.5;
      return constants.mmToPxRadius(sizeMm);
    })
    .attr("fill", d => options.getFill(d, layer))
    .attr("stroke", d => options.getStroke(d, layer))
    .attr("opacity", d => options.getAlpha(d, layer));

  return pts.length;
}
```

### R-side IR Validation
```r
# R/validate_ir.R - Add before JSON serialization
validate_ir <- function(ir) {
  stopifnot(
    is.list(ir),
    !is.null(ir$scales),
    !is.null(ir$layers),
    is.list(ir$scales$x),
    is.list(ir$scales$y)
  )

  # Validate each layer
  for (i in seq_along(ir$layers)) {
    layer <- ir$layers[[i]]
    if (is.null(layer$geom) || !is.character(layer$geom)) {
      stop(sprintf("Layer %d missing valid 'geom' field", i))
    }
    if (is.null(layer$data)) {
      warning(sprintf("Layer %d has no data", i))
    }
  }

  # Validate scale types
  valid_types <- c("continuous", "categorical", "linear", "band",
                   "time", "log", "sqrt", "pow", "symlog")
  if (!ir$scales$x$type %in% valid_types) {
    warning(sprintf("Unrecognized x scale type: %s", ir$scales$x$type))
  }

  invisible(ir)
}

# Usage in as_d3_ir.R (before returning):
# ir <- list(...)
# validate_ir(ir)
# return(ir)
```

### Constants Module Implementation
```javascript
// modules/constants.js
// W3C CSS Values spec: https://www.w3.org/TR/css-values-3/#absolute-lengths
// "The reference pixel is the visual angle of one pixel on a device
// with a pixel density of 96dpi and a distance from the reader of an arm's length."

export const DPI = 96;
export const MM_PER_INCH = 25.4;
export const PT_PER_INCH = 72;

// Conversion factors (read-only)
export const PX_PER_MM = DPI / MM_PER_INCH;  // 3.7795275591
export const PX_PER_PT = DPI / PT_PER_INCH;  // 1.3333333333

// ggplot2 size conversions (documented in R source)
// ggplot2 size aesthetic: diameter in mm
// SVG radius: pixels
export function mmToPxRadius(sizeMm) {
  return (sizeMm * PX_PER_MM) / 2;
}

// ggplot2 linewidth: mm (ggplot2 default: 0.5mm)
// SVG stroke-width: pixels
export function mmToPxLinewidth(linewidthMm) {
  return linewidthMm * PX_PER_MM;
}

// ggplot2 text size: points (theme_gray default: 11pt for axis titles)
// SVG font-size: pixels
export function ptToPx(sizePt) {
  return sizePt * PX_PER_PT;
}

// Common ggplot2 defaults (from theme_gray)
export const GGPLOT_DEFAULTS = {
  linewidth: 0.5,              // mm
  pointSize: 1.5,              // mm (diameter)
  textSize: 11,                // pt (axis title)
  textSizeSmall: 8.8,          // pt (axis text)
  gridMajorLinewidth: 0.5,     // mm (becomes 1.89px)
  gridMinorLinewidth: 0.25,    // mm (becomes 0.945px)
  panelBackground: "#EBEBEB",
  gridColor: "white"
};
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| IIFE module pattern | ES6 modules | 2015+ (widespread 2020+) | Cleaner syntax, native browser support, better tooling |
| d3.scale.linear() | d3.scaleLinear() | D3 v4 (2016) | Modular architecture, tree-shakeable |
| Single-file htmlwidgets | Multi-file with modules | htmlwidgets always supported multi-file | Enables modular refactoring |
| R S4 classes | R S3 functions (or R6 for stateful) | Hadley's Advanced R recommendation | S3 is simpler, adequate for functional transformations |
| Manual JSON validation | JSON Schema + Ajv | Modern approach, but overkill here | Only needed if IR becomes complex |

**Deprecated/outdated:**
- D3 v3 scale syntax (`d3.scale.linear()`): Use v7 syntax (`d3.scaleLinear()`)
- Factor pattern with `new` keyword: Use factory functions (return plain objects)
- Global namespace pollution: Use ES6 modules with explicit imports

## Open Questions

1. **ES6 Module Loading in htmlwidgets**
   - What we know: htmlwidgets generates HTML that loads JS from `inst/htmlwidgets/`
   - What's unclear: Whether `type="module"` can be added to script tag without modifying htmlwidgets internals
   - Recommendation: Test with simple multi-file example. Fallback: concatenate modules manually in package build step (use `usethis::use_build_ignore()` for source modules).

2. **Visual Regression Test Strategy**
   - What we know: Automated SVG comparison has high false-positive rate (font rendering, sub-pixel differences)
   - What's unclear: Best workflow for manual comparison during refactor (diffing HTML files? side-by-side screenshots?)
   - Recommendation: Generate reference HTML for each geom type, use browser dev tools to compare specific SVG attributes (stroke-width, positions, colors) rather than visual appearance.

3. **Performance Impact of Modular Code**
   - What we know: Splitting into modules might increase load time (more HTTP requests) but improves maintainability
   - What's unclear: Whether htmlwidgets/browser caching mitigates this, whether bundling is necessary
   - Recommendation: Start modular, measure load times with browser dev tools. If problematic, add build step to concatenate (preserve readability in source).

4. **R6 vs S3 for Future Extensions**
   - What we know: Current codebase uses S3 (functional), appropriate for stateless IR transformation
   - What's unclear: Whether future interactivity (Phase 5) will require stateful objects (event handlers, animation state)
   - Recommendation: Keep S3 for now. Revisit in Phase 5 if stateful patterns emerge (R6 better for JavaScript API wrappers).

## Sources

### Primary (HIGH confidence)
- [D3.js Official Documentation](https://d3js.org/getting-started) - D3 v7 scale factories and modular architecture
- [htmlwidgets for R](https://www.htmlwidgets.org/) - Official htmlwidgets documentation
- [W3C CSS Values Specification](https://www.w3.org/TR/css-values-3/#absolute-lengths) - 96 DPI standard for web
- [Advanced R by Hadley Wickham](https://adv-r.hadley.nz/oo-tradeoffs.html) - R6 vs S3 tradeoffs

### Secondary (MEDIUM confidence)
- [Factory Functions and the Module Pattern | The Odin Project](https://www.theodinproject.com/lessons/node-path-javascript-factory-functions-and-the-module-pattern) - JS module patterns
- [Registry Pattern - GeeksforGeeks](https://www.geeksforgeeks.org/system-design/registry-pattern/) - Registry pattern explanation
- [Building a team of internal R packages | Emily Riederer](https://www.emilyriederer.com/post/team-of-packages/) - R package modular design
- [PX to MM Converter - CSS Tool 2026](https://cssunitconvert.com/convert/px-to-mm) - Unit conversion verification
- [Visual Testing: A Step-by-Step Guide for Pixel-Perfect UI](https://testgrid.io/blog/visual-testing/) - Visual regression testing practices

### Tertiary (LOW confidence - requires verification)
- Medium articles on module patterns: General patterns but no gg2d3-specific validation
- Visual regression tool comparisons: Many tools listed but none specifically tested for D3/SVG rendering
- JSON Schema validators: Ajv is standard but overhead needs measurement for this use case

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - D3 v7, htmlwidgets, testthat are established and verified in codebase
- Architecture patterns: HIGH - Registry, factory, constants modules are proven patterns, directly applicable
- Unit conversions: HIGH - W3C spec and ggplot2 source provide exact values
- Pitfalls: MEDIUM-HIGH - Based on existing code analysis and documented issues, but some refactoring-specific pitfalls are projections
- Visual testing: MEDIUM - Strategy is sound but specific tooling recommendations need validation

**Research date:** 2026-02-07
**Valid until:** 2026-03-07 (30 days - stable domain, D3 v7 and htmlwidgets are mature)

**Next steps for planner:**
1. Create tasks for each module (constants, scales, theme, geom-registry, individual geoms)
2. Add validation task (R-side IR validation before serialization)
3. Include visual regression testing checkpoints (generate references, compare after each module)
4. Consider phased approach: constants first (low risk), then scales/theme (medium risk), then geom registry (high complexity)
