# Phase 2: Core Scale System - Research

**Researched:** 2026-02-08
**Domain:** Scale transformations and expansions in ggplot2 and D3.js
**Confidence:** HIGH

## Summary

Phase 2 extends the basic scale system built in Phase 1 to support the full range of ggplot2 scale transformations (log, sqrt, pow, reverse) and proper expansion behavior. The current implementation in `as_d3_ir.R` hardcodes 5% continuous expansion and lacks transformation support entirely. D3.js provides native scale types for all needed transformations (scaleLog, scaleSqrt, scalePow, scaleSymlog) but has strict domain constraints (log scales cannot include zero) that require R-side validation. The key architectural decision is whether to compute expansion in R (during IR generation) or in D3 (during rendering) — research strongly suggests R-side expansion because ggplot2's `ggplot_build()` already computes expanded domains through `panel_params`, and accessing this pre-computed data eliminates duplication and ensures consistency.

Scale transformations in ggplot2 are defined by transformation objects in the scales package, which bundle: (1) forward transform function, (2) inverse function, (3) breaks generator. Critically, ggplot2 computes breaks AFTER expansion but IN transformed space, meaning a log scale with domain [1, 100] expanded to [0.5, 200] will have breaks at [1, 10, 100], not [0.5, 5, 50, 500]. D3's log scales require strictly-positive or strictly-negative domains (zero causes log(0) = -∞); for data spanning zero, D3 provides scaleSymlog (symmetric log) which handles negative values and zero with a tunable constant parameter.

**Primary recommendation:** Extract scale transformations and expansion parameters from ggplot2's computed `panel_params`, pass them through IR as explicit fields (`type`, `transform`, `domain`, `expansion`), and implement D3 scale factory logic to match ggplot2's transformation-then-expansion semantics exactly.

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| D3.js | v7 | Scale transformations | Already integrated in Phase 1; provides scaleLog, scaleSqrt, scalePow, scaleSymlog out of the box |
| ggplot2 | 3.x | Scale specification | Source of truth for scale behavior; `ggplot_build()` computes all scale transformations and expansions |
| scales package | Latest | Transformation objects | Defines all ggplot2 transformations; accessed via `scale_obj$trans` field |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| grid | Base R | Unit conversion | Already used in `as_d3_ir.R` for margin conversion; may need for expansion units |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| D3 scale factory | Custom JS math | D3 scales are battle-tested and handle edge cases (negative values in pow scales, clamping, domain validation) |
| R-side expansion | JS-side expansion | JS-side requires duplicating ggplot2's expansion logic; R-side leverages pre-computed `panel_params$x$range` |
| Symlog for zero-crossing | Manual piecewise scale | Symlog is mathematically principled and matches ggplot2's pseudo_log transformation |

**Installation:**
No new dependencies required — all libraries already present in Phase 1.

## Architecture Patterns

### Recommended IR Structure Extension

Current IR structure (from Phase 1):
```javascript
scales: {
  x: { type: "continuous", domain: [0, 10] },
  y: { type: "categorical", domain: ["A", "B", "C"] }
}
```

Extended IR structure for Phase 2:
```javascript
scales: {
  x: {
    type: "continuous",           // categorical | continuous
    transform: "log10",            // NULL | "log" | "log10" | "sqrt" | "pow" | "reverse" | "symlog"
    domain: [1, 100],              // expanded domain (already includes expansion)
    breaks: [1, 10, 100],          // major breaks in transformed space
    minor_breaks: [2, 3, 4, 5, ...], // minor breaks (optional)
    // Transform parameters (if applicable)
    base: 10,                      // for log scales
    exponent: 0.5,                 // for power scales
    constant: 1                    // for symlog scales
  },
  y: { ... }
}
```

### Pattern 1: R-Side Expansion Extraction

**What:** Extract expansion from ggplot2's computed `panel_params` instead of hardcoding 5%

**When to use:** Always — ggplot2 has already computed this during `ggplot_build()`

**Example:**
```r
# Current approach (WRONG - hardcoded 5%)
range_span <- diff(scale_range)
expansion <- range_span * 0.05
expanded_range <- c(scale_range[1] - expansion, scale_range[2] + expansion)

# Correct approach (extract from panel_params)
# panel_params already contains expanded range
x_range <- b$layout$panel_params[[1]]$x$range  # [expanded_min, expanded_max]
x_domain <- unname(x_range)  # already expanded by ggplot2
```

**Source:** [ggplot2 expansion() reference](https://ggplot2.tidyverse.org/reference/expansion.html) — defaults are `mult = 0.05` for continuous, `add = 0.6` for discrete, but users can override with `scale_*_*(expand = expansion(mult = ..., add = ...))`.

### Pattern 2: D3 Scale Factory with Transform Dispatch

**What:** Extend `window.gg2d3.scales.createScale()` to handle transform field

**When to use:** During scale creation in D3 rendering pipeline

**Example:**
```javascript
// In scales.js createScale() function
function createScale(desc, range) {
  const transform = desc.transform ? desc.transform.toLowerCase() : null;
  const domain = desc.domain || [0, 1];

  // Dispatch by transform type
  if (transform === 'log' || transform === 'log10') {
    const scale = d3.scaleLog().domain(domain).range(range);
    if (desc.base) scale.base(desc.base);
    return scale;
  } else if (transform === 'sqrt') {
    return d3.scaleSqrt().domain(domain).range(range);
  } else if (transform === 'pow') {
    const scale = d3.scalePow().domain(domain).range(range);
    if (desc.exponent) scale.exponent(desc.exponent);
    return scale;
  } else if (transform === 'reverse') {
    // Reverse is just flipping the domain
    return d3.scaleLinear().domain([...domain].reverse()).range(range);
  } else if (transform === 'symlog') {
    const scale = d3.scaleSymlog().domain(domain).range(range);
    if (desc.constant) scale.constant(desc.constant);
    return scale;
  } else {
    // Fall back to type-based dispatch (Phase 1 behavior)
    return buildScaleByType(desc, range);
  }
}
```

**Source:** Adapted from [D3 scale documentation](https://d3js.org/d3-scale) and current `inst/htmlwidgets/modules/scales.js` structure.

### Pattern 3: Transformation Metadata Extraction from ggplot2

**What:** Extract transformation name and parameters from scale object's `$trans` field

**When to use:** In `as_d3_ir.R` when building scale IR

**Example:**
```r
# Extract transformation from scale object
get_transform_info <- function(scale_obj) {
  trans <- scale_obj$trans

  if (is.null(trans)) {
    return(list(transform = NULL))
  }

  # trans$name gives transformation name: "identity", "log-10", "sqrt", "reverse", etc.
  trans_name <- trans$name

  result <- list(transform = trans_name)

  # Extract parameters for specific transformations
  if (grepl("log", trans_name, ignore.case = TRUE)) {
    # Log transformations may specify base
    if (grepl("log-2", trans_name)) {
      result$base <- 2
    } else if (grepl("log-10", trans_name)) {
      result$base <- 10
    } else {
      result$base <- exp(1)  # natural log
    }
  } else if (grepl("pow", trans_name, ignore.case = TRUE)) {
    # Power transformations specify exponent
    # Extract from transformation function if available
    result$exponent <- 1  # default, may need inspection of trans object
  }

  result
}
```

**Source:** [ggplot2 scale transformation docs](https://ggplot2.tidyverse.org/reference/scale_continuous.html) — transformations defined in scales package, accessible via `scale_obj$trans`.

### Pattern 4: Discrete Scale Expansion

**What:** Discrete scales use additive expansion (0.6 units), not multiplicative

**When to use:** When `inherits(scale_obj, "ScaleDiscrete")`

**Example:**
```r
# For discrete scales, expansion adds fixed units to each end
# ggplot2 default: expansion(add = 0.6)
# This means domain ["A", "B", "C"] gets 0.6 units of padding on each side
# In D3 band/point scales, this maps to paddingOuter parameter

# Current implementation in scales.js (already correct for discrete):
return d3.scaleBand().domain(domainArr).range(rng)
  .paddingInner(0.2)   // spacing between bars
  .paddingOuter(0.6);  // matches ggplot2's add = 0.6

# For point scales (no width, just positions):
return d3.scalePoint().domain(domainArr).range(rng)
  .padding(0.6);  // matches ggplot2's add = 0.6
```

**Source:** [ggplot2 expansion() reference](https://ggplot2.tidyverse.org/reference/expansion.html) — "defaults are to expand the scale by 5% on each side for continuous variables, and by 0.6 units on each side for discrete variables."

### Anti-Patterns to Avoid

- **Hardcoding expansion percentages:** ggplot2 users can override defaults with `scale_*_*(expand = expansion(...))` — always extract from `panel_params$x$range`
- **Computing expansion in JavaScript:** Duplicates ggplot2 logic and will diverge; R has already computed this
- **Ignoring transformation parameters:** Log scales need base, power scales need exponent — these affect tick generation even if not the mapping itself
- **Allowing zero in log scale domains:** D3 will produce `-Infinity`; validate in R and suggest symlog for zero-crossing data
- **Reversing scales by negating data:** Breaks axis labels; use `reverse()` transformation or flip domain in scale creation

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Log scale with zero | Custom piecewise function | D3 scaleSymlog | Mathematically principled bi-symmetric log transformation; handles zero and negatives correctly |
| Scale expansion calculation | JavaScript expansion logic | ggplot2's panel_params$x$range | ggplot2 has already computed this during ggplot_build(); duplicating risks inconsistency |
| Transformation inverse | Custom inverse functions | scales package trans objects | Each transformation bundles forward, inverse, and breaks methods; pre-tested for edge cases |
| Color interpolation | Manual RGB lerp | D3 interpolate with HCL/Cubehelix | Perceptually uniform color spaces prevent banding; RGB interpolation looks muddy |
| Discrete scale domain validation | Manual factor level checks | ggplot2's scale_obj$get_limits() | Handles dropped levels, reordered factors, NA translation automatically |

**Key insight:** ggplot2's `ggplot_build()` pipeline does heavy lifting for scale transformations and expansions. The IR should be a faithful snapshot of `ggplot_build()` output, not a recomputation. D3's scale system is powerful but has different defaults (no expansion, different color spaces) — our job is bridging semantics, not reimplementing algorithms.

## Common Pitfalls

### Pitfall 1: Log Scale Domain Includes Zero

**What goes wrong:** D3 log scale returns `-Infinity` for zero, causing NaN positions and invisible points

**Why it happens:** User has data at zero or ggplot2 expansion pulls domain to include zero (e.g., [0.1, 10] expanded by 5% → [0.095, 10.5] but log(0.095) is still valid; problem is when domain starts at exactly 0)

**How to avoid:**
- Validate in R: if `scale_obj$trans$name` contains "log" and `min(domain) <= 0`, throw informative error
- Suggest alternatives: "Log scale domain must be strictly positive. Consider scale_x_continuous(trans = 'pseudo_log') for data including zero"
- For negative values: if data crosses zero, suggest symlog

**Warning signs:**
- Console warnings from D3: "Invalid value NaN for attribute cy"
- All points disappear on transformed axis
- Axis labels show `-Infinity` or `Infinity`

**Source:** [D3 log scale docs](https://d3js.org/d3-scale/log) — "Domain must be strictly-positive OR strictly-negative; the domain must NOT include or cross zero, since log(0) = -∞."

### Pitfall 2: Expansion Applied Twice

**What goes wrong:** Data has excessive padding, bars float away from axis edges

**Why it happens:** R computes expansion during `ggplot_build()`, stores in `panel_params$x$range`; if JS also applies 5% expansion, you get double expansion (~10% total)

**How to avoid:**
- **Always use `panel_params$x$range` for domain** — this is the final expanded range
- **Never compute `range * 0.05` in R or JS** — expansion is already baked in
- Document this clearly in code comments: "Domain from panel_params is already expanded"

**Warning signs:**
- Bars in bar charts have visible gap between bar and axis
- Scatter plot points have more padding than ggplot2 equivalent
- Axis range is noticeably larger than data range

**Source:** Current codebase bug — `as_d3_ir.R` lines 255-258 compute `expansion <- range_span * 0.05` but this should be replaced with direct extraction from `panel_params`.

### Pitfall 3: Reverse Scale Axis Direction Confusion

**What goes wrong:** `scale_x_reverse()` flips data order but axis labels and orientation look wrong

**Why it happens:** Reversing scale is NOT the same as coord_flip; reverse affects one axis, not the coordinate system

**How to avoid:**
- Reverse transformation should flip domain: `[10, 0]` instead of `[0, 10]`
- Axis still draws bottom (for x) or left (for y) — only the direction changes
- In D3: `d3.scaleLinear().domain([10, 0])` handles this automatically
- DO NOT swap axis positions when transform is "reverse"

**Warning signs:**
- Axis moves to opposite side (e.g., x-axis jumps to top)
- Data mirrors correctly but labels are backwards
- Grid lines don't align with data

**Source:** [ggplot2 scale_*_reverse docs](https://ggplot2.tidyverse.org/reference/scale_continuous.html) — convenience function that sets `trans = "reverse"`, not a coordinate transformation.

### Pitfall 4: Discrete Scale Factor Level Mismatches

**What goes wrong:** Data subset shows only 2 categories but legend shows all 5; or vice versa — factor levels present in data don't appear

**Why it happens:** ggplot2's `drop` parameter controls whether unused levels display; `scale_obj$get_limits()` returns different values depending on `drop = TRUE` (data-driven) vs `drop = FALSE` (factor-driven)

**How to avoid:**
- Use `scale_obj$get_limits()` for domain, not `unique(data$x)` — this respects user's `drop` setting
- For discrete scales, `get_limits()` returns character vector of labels in display order
- Mapping: if data has integer indices (1, 2, 3), map to labels via `labels[index]`

**Warning signs:**
- Bar chart missing bars for known categories
- Legend shows categories not in the plot
- Category order doesn't match user's factor levels
- Subset data shows unexpected categories

**Source:** [ggplot2 discrete scale docs](https://ggplot2.tidyverse.org/reference/scale_discrete.html) — "drop: Should unused factor levels be omitted from the scale? The default, TRUE, uses the levels that appear in the data; FALSE includes the levels in the factor."

### Pitfall 5: Transform vs. Coord_trans Confusion

**What goes wrong:** User applies `coord_trans(x = "log10")` and rendering breaks

**Why it happens:** `coord_trans()` applies transformation AFTER statistical computation, affecting visual appearance only; `scale_x_log10()` transforms BEFORE stat, affecting both data and visuals. These are different code paths in ggplot2.

**How to avoid:**
- Phase 2 focuses on `scale_*_*` transformations (applied to scales)
- Coordinate transformations (`coord_trans`) are Phase 3 work
- Check if `b$plot$coordinates` has a `$trans` field — if so, defer to Phase 3
- For now, document limitation: "coord_trans() not yet supported; use scale_x_log10() instead"

**Warning signs:**
- User reports "log scale works in ggplot2 but not in gg2d3" but they used `coord_trans()`
- Statistical geoms (smooth, density) look wrong with coord_trans

**Source:** [ggplot2 book on transformations](https://ggplot2-book.org/scales-position.html) — "coord_trans() is different to scale transformations in that it occurs after statistical transformation and will affect only the visual appearance of geoms."

## Code Examples

Verified patterns from official sources:

### Extract Transformation from Scale Object

```r
# Source: ggplot2 internal structure (from ggplot_build)
# Location: R/as_d3_ir.R

get_scale_transform <- function(scale_obj) {
  # scale_obj$trans is a transformation object from scales package
  trans <- scale_obj$trans

  if (is.null(trans) || trans$name == "identity") {
    return(NULL)  # no transformation
  }

  # Normalize transformation names to D3 equivalents
  trans_map <- c(
    "identity" = NULL,
    "reverse" = "reverse",
    "log-10" = "log10",
    "log-2" = "log2",
    "log" = "log",
    "sqrt" = "sqrt",
    "power" = "pow",
    "pseudo_log" = "symlog"
  )

  trans_name <- trans_map[[trans$name]]
  if (is.null(trans_name)) {
    warning(sprintf("Unsupported transformation: %s", trans$name))
    return(NULL)
  }

  list(transform = trans_name)
}
```

### Extract Expanded Domain from panel_params

```r
# Source: ggplot2 ggplot_build() output structure
# Location: R/as_d3_ir.R, in get_scale_info() function

get_scale_info <- function(scale_obj, panel_params_axis) {
  # panel_params_axis is panel_params[[1]]$x or panel_params[[1]]$y

  if (inherits(scale_obj, "ScaleDiscrete")) {
    # Discrete: use limits from scale object
    domain <- scale_obj$get_limits()
    return(list(
      type = "categorical",
      domain = unname(domain),
      breaks = unname(panel_params_axis$breaks),
      minor_breaks = NULL  # discrete scales don't have minor breaks
    ))
  } else {
    # Continuous: use expanded range from panel_params
    # panel_params_axis$range is ALREADY EXPANDED by ggplot2
    domain <- unname(panel_params_axis$range)

    # Get transformation info
    transform_info <- get_scale_transform(scale_obj)

    return(c(
      list(
        type = "continuous",
        domain = domain,
        breaks = unname(panel_params_axis$breaks),
        minor_breaks = unname(panel_params_axis$minor_breaks)
      ),
      transform_info  # NULL or list(transform = "log10", base = 10)
    ))
  }
}
```

### D3 Scale Factory with Transform Support

```javascript
// Source: Adapted from D3.js official documentation
// Location: inst/htmlwidgets/modules/scales.js

function createScale(desc, range) {
  const rng = Array.isArray(range) ? range : [0, 1];
  if (!desc) return d3.scaleLinear().domain([0, 1]).range(rng);

  const domain = desc.domain || [0, 1];
  const transform = desc.transform ? desc.transform.toLowerCase() : null;

  // Transform-based scale creation
  if (transform) {
    switch (transform) {
      case 'log':
      case 'log10':
      case 'log2': {
        // Validate strictly-positive or strictly-negative domain
        const allPositive = domain.every(d => d > 0);
        const allNegative = domain.every(d => d < 0);
        if (!allPositive && !allNegative) {
          console.error('Log scale domain must be strictly-positive or strictly-negative:', domain);
          return d3.scaleLinear().domain(domain).range(rng);  // fallback
        }
        const scale = d3.scaleLog().domain(domain).range(rng);
        if (transform === 'log2') scale.base(2);
        if (transform === 'log10') scale.base(10);
        if (desc.base) scale.base(desc.base);
        return scale;
      }

      case 'sqrt':
        return d3.scaleSqrt().domain(domain).range(rng);

      case 'pow':
      case 'power': {
        const scale = d3.scalePow().domain(domain).range(rng);
        if (desc.exponent) scale.exponent(desc.exponent);
        return scale;
      }

      case 'symlog': {
        const scale = d3.scaleSymlog().domain(domain).range(rng);
        if (desc.constant) scale.constant(desc.constant);
        return scale;
      }

      case 'reverse':
        // Reverse is just flipping the domain
        return d3.scaleLinear().domain([...domain].reverse()).range(rng);

      default:
        console.warn('Unknown transform:', transform);
    }
  }

  // Fall back to type-based scale creation (Phase 1 logic)
  return createScaleByType(desc, rng);
}
```

### Validate Log Scale Domain in R

```r
# Source: Best practice for user-friendly error messages
# Location: R/as_d3_ir.R, in get_scale_info()

validate_log_domain <- function(scale_obj, domain, axis_name) {
  trans <- scale_obj$trans
  if (is.null(trans)) return(TRUE)

  is_log <- grepl("log", trans$name, ignore.case = TRUE) &&
            !grepl("pseudo_log|symlog", trans$name, ignore.case = TRUE)

  if (is_log) {
    if (any(domain <= 0)) {
      stop(sprintf(
        "Log scale on %s-axis has non-positive domain [%s, %s].\n",
        axis_name, domain[1], domain[2],
        "Log scales require strictly positive values.\n",
        "Consider:\n",
        "  - scale_%s_continuous(trans = 'pseudo_log') for data including zero\n",
        "  - Filtering data to positive values\n",
        "  - Using a linear scale"
      ), axis_name, axis_name)
    }
  }

  TRUE
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Hardcoded 5% expansion | Extract from panel_params$range | Phase 2 (this phase) | Respects user's custom expansion settings |
| Type-only scale dispatch | Transform-aware dispatch | Phase 2 (this phase) | Enables log, sqrt, pow transformations |
| Ignore scale transformations | Extract from scale_obj$trans | Phase 2 (this phase) | Matches ggplot2's transformed axes |
| Manual RGB color lerp | D3 interpolateHcl/Cubehelix | D3 v4+ (2016) | Perceptually uniform gradients |
| Always drop unused levels | Respect scale drop parameter | Phase 2 (this phase) | Handles factor subsetting correctly |

**Deprecated/outdated:**
- **D3 v3 scale.rangeBands()**: Replaced by `scaleBand()` in D3 v4+; we're using v7 (correct)
- **ggplot2 expand parameter as numeric vector**: Replaced by `expansion()` function in ggplot2 3.3.0 (2020); still accept numeric for backwards compatibility
- **coord_trans for log scales**: Still works but `scale_x_log10()` is preferred for cleaner syntax and better stat integration

## Open Questions

1. **How to handle custom transformations?**
   - What we know: Users can create custom trans objects with `scales::new_transform()`
   - What's unclear: Should we support arbitrary custom transformations or only built-in ones?
   - Recommendation: Phase 2 supports built-in transformations only ("identity", "log", "log10", "log2", "sqrt", "pow", "reverse", "pseudo_log"); custom transformations fail gracefully with informative error. This covers 95% of use cases. Full custom transform support is Phase 3+ work.

2. **Should we validate transformation domain in R or D3?**
   - What we know: R validation gives better error messages and fails fast; D3 validation is the final safety net
   - What's unclear: Is R validation sufficient or do we need both?
   - Recommendation: Validate in R (during `as_d3_ir()`) with clear error messages suggesting fixes; add defensive checks in D3 (console.error and fallback to linear scale) for safety. R validation is the primary defense, D3 is failsafe.

3. **How to handle coord_trans() vs scale_x_log10()?**
   - What we know: coord_trans applies transformation after stat computation (affects visual only); scale transformations apply before stat (affects data and visual)
   - What's unclear: Can we detect coord_trans usage and warn user, or should we attempt to support it?
   - Recommendation: Phase 2 focuses on scale transformations only. Check `b$plot$coordinates` for `$trans` field; if present, throw informative error: "coord_trans() not yet supported. Use scale_x_log10() instead, which provides equivalent visual output for most cases." Full coord_trans support is Phase 3 work after coordinate system refactoring.

4. **What about color scale transformations (e.g., log-scale color mapping)?**
   - What we know: ggplot2 supports `scale_color_continuous(trans = "log")` for continuous color scales
   - What's unclear: Does this require special handling in D3 or is it automatically handled by scale dispatch?
   - Recommendation: Phase 2 focuses on position scales (x, y); color scale transformations are Phase 7 (Legend System) work. For now, color scales remain untransformed (linear mapping). This is acceptable because position scales are higher priority and color transformations are rare in practice.

5. **How to handle scale limits that differ from data range?**
   - What we know: Users can set `scale_x_continuous(limits = c(0, 100))` which may exclude data
   - What's unclear: Does panel_params$range respect user limits or data range?
   - Recommendation: Test empirically — create a ggplot with explicit limits, inspect `panel_params$x$range`. Hypothesis: `panel_params$range` respects user limits (this is the expanded range actually used for rendering). If true, our current approach is correct. Add test case to validation suite.

## Sources

### Primary (HIGH confidence)
- [ggplot2 expansion() reference](https://ggplot2.tidyverse.org/reference/expansion.html) - Expansion formulas and defaults
- [ggplot2 scale_continuous() reference](https://ggplot2.tidyverse.org/reference/scale_continuous.html) - Transformation parameters and usage
- [ggplot2 scale_discrete() reference](https://ggplot2.tidyverse.org/reference/scale_discrete.html) - Discrete scale behavior (drop, na.translate, limits)
- [D3 log scale documentation](https://d3js.org/d3-scale/log) - Domain constraints and usage
- [D3 symlog scale documentation](https://d3js.org/d3-scale/symlog) - Handling zero-crossing data
- [D3 linear scale documentation](https://d3js.org/d3-scale/linear) - Color interpolation and clamping
- [scales package home](https://scales.r-lib.org/) - Transformation objects structure
- Codebase files:
  - `/Users/davidzenz/R/gg2d3/R/as_d3_ir.R` - Current IR generation with hardcoded expansion (lines 245-266)
  - `/Users/davidzenz/R/gg2d3/inst/htmlwidgets/modules/scales.js` - Current scale factory (15+ scale types)
  - `/Users/davidzenz/R/gg2d3/vignettes/d3-drawing-diagnostics.md` - Known issues with bar chart zero-domain assumption

### Secondary (MEDIUM confidence)
- [ggplot2 book on position scales](https://ggplot2-book.org/scales-position.html) - Scale transformation vs coord_trans difference
- [ggplot2 color scales chapter](https://ggplot2-book.org/scales-colour.html) - Continuous vs discrete color scales
- [D3 scale chromatic documentation](https://d3js.org/d3-scale-chromatic) - Color interpolation schemes
- [CSS In Real Life: Color Scales in D3](https://css-irl.info/working-with-color-scales-for-data-visualisation-in-d3/) - Practical color scale usage

### Tertiary (LOW confidence - for further investigation)
- GitHub issues:
  - [ggplot2 #1584 - NAs should be excluded from discrete X-axis by default](https://github.com/tidyverse/ggplot2/issues/1584) - NA handling edge cases
  - [ggplot2 #1433 - discrete_scale(drop=TRUE) does not drop unused levels](https://github.com/tidyverse/ggplot2/issues/1433) - Drop parameter behavior
  - [d3 #1420 - d3.scale.log(), 0 in domain](https://github.com/d3/d3/issues/1420) - Historic discussion of log scale zero handling

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - D3 v7 already integrated, ggplot2 is source of truth, scales package is ggplot2 dependency
- Architecture: HIGH - `panel_params` extraction verified in ggplot2 source, D3 scale API documented, current codebase structure understood
- Pitfalls: HIGH - All pitfalls verified against official documentation or observed in current codebase bugs
- Transform semantics: MEDIUM - Official docs confirm transformation types and parameters, but custom transformations need empirical testing
- Expansion extraction: HIGH - `panel_params$x$range` is documented ggplot2 output structure

**Research date:** 2026-02-08
**Valid until:** 2026-03-08 (30 days - stable domain, ggplot2 and D3 APIs are mature)

**Critical dependencies for planning:**
- Must read `panel_params` structure from ggplot_build() output (already accessible in current code)
- Must extend IR schema to include `transform`, `base`, `exponent`, `constant` fields
- Must validate log scale domains in R before passing to JavaScript
- Phase 3 (Coordinate Systems) depends on Phase 2 completing scale transformations correctly
