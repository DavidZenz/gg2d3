# Stack Research

**Domain:** gg2d3 v1.1 stack changes for interactive legends, transitions, and advanced coord/scale parity
**Researched:** 2026-03-23
**Confidence:** HIGH

## Recommended Stack

### Core Technologies (v1.1 changes only)

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| ggplot2 compatibility target | **3.5.1+ and 4.0.x** | Stable extraction target for guides/coords/themes | v1.1 depends on modern guide + coord behavior (`position = "inside"`, `coord_cartesian(reverse, ratio)`, expanded theme tree). 4.0 introduces S7 internals, so version-aware extraction is required. |
| D3.js (vendored) | **7.9.0** | Runtime for legend interactions + animation | Keep current vendor model; D3 v7 already contains `transition`, `ease`, `dispatch`, `time-format`, `scale` needed for v1.1. No runtime library swap needed. |
| htmlwidgets | **1.6.4** | R↔JS bridge and lifecycle hooks | Current architecture already depends on it. v1.1 features map cleanly to `renderValue` + resize + widget state without introducing another bridge. |
| scales (R pkg) | **1.4.0** | Canonical R-side breaks/labels/palette semantics | Advanced parity is easier by serializing ggplot/scales outputs than reproducing every labeling edge case in JS. This is the key stack addition for parity reliability. |

### Supporting Libraries

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| d3-transition (module within d3 v7) | bundled in 7.9.0 | Enter/update/exit animations; axis/legend tweening | Required for animated legend filtering, coord zoom transitions, and scale-domain changes. |
| d3-ease (module within d3 v7) | bundled in 7.9.0 | Motion curves (`cubic`, `linear`, etc.) | Use for globally consistent transition timing tokens. |
| d3-dispatch (module within d3 v7) | bundled in 7.9.0 | Local event bus for legend ↔ layer sync | Use instead of ad-hoc DOM event wiring between modules. |
| d3-time-format (module within d3 v7) | bundled in 7.9.0 | Time scale tick/tooltip formatting in browser | Use when JS must format ticks dynamically (zoom/pan); otherwise prefer precomputed R labels. |
| crosstalk | 1.2.2 | Keep linked selection compatibility | Keep as-is; ensure legend toggle state participates in existing crosstalk filtering semantics. |
| chromote | 0.5.1 | Browser automation for interaction snapshots | Use for deterministic tests of legend clicks, transitions, and coord updates. |
| webshot2 | 0.1.2 | Screenshot capture in CI | Use for visual regression states (pre/post transition endframes). |
| shinytest2 | 0.5.1 | End-to-end interaction tests in Shiny context | Use for event-order correctness and race-condition detection in interactive flows. |

### Development Tools

| Tool | Purpose | Notes |
|------|---------|-------|
| testthat (existing) + browser-backed tests | Stateful interaction assertions | Add tests for legend state machine + transition completion callbacks. |
| vdiffr (existing) | Static fidelity regression | Keep for non-animated output; pair with chromote/webshot2 for interactive states. |
| R CMD check matrix | ggplot2 version compatibility checks | Run CI against ggplot2 3.5.x and 4.0.x to catch extractor breaks early. |

## Integration Points (explicitly with current architecture)

### R layer (`R/as_d3_ir.R` and split helpers)

1. **Add version-aware extractor shim** for ggplot2 3.5 vs 4.0 internals.
   - Keep private-API usage isolated.
2. **Serialize guide interaction metadata** into IR:
   - stable key per legend item
   - target layer groups/aesthetics
   - toggle policy (`single`, `multi`, `isolate`)
3. **Serialize transition config** into IR:
   - duration, easing token, interrupt policy
   - animation scopes (`legend`, `scales`, `coords`, `geoms`)
4. **Prefer R-side break/label computation** (via ggplot2/scales), with JS fallback only when interaction changes domains client-side.
5. **Encode coord parity fields** explicitly (`reverse`, `ratio`, side-specific expand flags) for JS layout/scale modules.

### JS layer (`inst/htmlwidgets/gg2d3.js` + `inst/htmlwidgets/modules/*`)

1. Add a **transition orchestrator module** (new file, e.g. `modules/transitions.js`) that wraps all `selection.transition()` calls.
2. Extend **legend module** to emit semantic events through `d3.dispatch` instead of directly mutating layers.
3. Update **geom registry renderers** to support keyed joins (`.data(data, key)`), enabling smooth enter/update/exit on legend filters.
4. Extend **scales/layout modules** so coord/scale updates can be animated without re-creating unrelated DOM nodes.
5. Keep `gg2d3.yaml` dependency model (vendored `d3.v7.min.js` + local modules); no bundler migration required for v1.1.

## Installation

```r
# DESCRIPTION changes (v1.1 focused)
Imports:
  ggplot2 (>= 3.5.1),
  htmlwidgets (>= 1.6.4),
  jsonlite,
  grid,
  scales (>= 1.4.0)

Suggests:
  crosstalk (>= 1.2.2),
  testthat (>= 3.0.0),
  vdiffr,
  chromote (>= 0.5.1),
  webshot2 (>= 0.1.2),
  shinytest2 (>= 0.5.1)
```

```r
# D3 remains vendored (no change in delivery model)
dir.create("inst/htmlwidgets/lib/d3", recursive = TRUE, showWarnings = FALSE)
download.file("https://d3js.org/d3.v7.min.js",
              destfile = "inst/htmlwidgets/lib/d3/d3.v7.min.js", mode = "wb")
```

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| D3 transitions + dispatch | GSAP / anime.js | Use only if gg2d3 shifts to non-D3 DOM rendering (not current architecture). |
| R-side scales labels + selective JS formatting | Full JS label engine | Use only in fully client-side plotting systems; unnecessary duplication here. |
| Keep htmlwidgets script pipeline | npm bundling migration now | Defer until a larger packaging milestone (not required for v1.1 capability). |
| Browser-driven visual tests | Pure unit tests | Unit tests alone are insufficient for transition timing and rendering parity bugs. |

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| **New animation framework (GSAP/anime.js)** | Duplicates D3 transition engine; increases payload + integration complexity | d3-transition + d3-ease already in vendored D3 v7 |
| **Moment.js/Day.js for scale ticks** | Extra runtime dependency; ggplot/scales + d3-time-format already cover required semantics | scales (R) + d3-time-format fallback |
| **State management framework (Redux/MobX)** | Overkill for widget-local state; harder htmlwidgets integration | Small module-local store + d3-dispatch |
| **Canvas/WebGL rewrite in v1.1** | Not needed for requested capabilities; risks parity regressions | Keep SVG DOM + keyed transitions |
| **Switching away from htmlwidgets** | Breaks downstream RMarkdown/Shiny embedding model | Continue current htmlwidgets architecture |
| **Relying on `ggplot2:::` everywhere** | Fragile under ggplot2 4.x internals | isolate private calls in one compatibility layer |

## Stack Patterns by Variant

**If interactive legend controls only visibility/highlight:**
- Use `d3-dispatch` + keyed joins + short (`120–200ms`) opacity/size transitions.
- Keep axis domains fixed.

**If legend interaction changes scale domains or coord limits:**
- Use transition orchestrator for axis + geom updates (`200–350ms`).
- Compute new breaks/labels from R metadata when available; fallback to d3-time-format/d3-format for client-side updates.

**If dynamic coord parity (`reverse`, `ratio`, side-specific expand`) is enabled:**
- Treat coord changes as layout+scale transitions, not full redraw.
- Animate container groups and axis positions in lockstep.

## Version Compatibility

| Package | Compatible With | Notes |
|---------|-----------------|-------|
| ggplot2 3.5.1+ | ggplot2 4.0.x | Must test both due to 4.0 internal changes. |
| htmlwidgets 1.6.4 | D3 v7 vendor pattern | Existing package model remains valid. |
| d3 7.9.0 | d3-transition/ease/dispatch/time-format | No extra JS runtime deps required. |
| scales 1.4.0 | ggplot2 3.5+/4.0+ | Recommended for parity-grade breaks/labels. |
| crosstalk 1.2.2 | htmlwidgets 1.6.4 | Keep existing linked interaction support. |
| chromote/webshot2/shinytest2 | CI and local Chrome/Chromium | Test-only stack; not runtime widget dependency. |

## Sources

- https://github.com/d3/d3/releases — verified latest D3 release (v7.9.0) **[HIGH]**
- https://d3js.org/d3-transition — transition model and API **[HIGH]**
- https://d3js.org/d3-ease — easing functions for transition policy **[HIGH]**
- https://d3js.org/d3-time-format — time formatting/parsing for dynamic scale ticks **[HIGH]**
- https://cran.r-project.org/web/packages/htmlwidgets/index.html — htmlwidgets current CRAN version (1.6.4) **[HIGH]**
- https://ggplot2.tidyverse.org/news/index.html — ggplot2 4.0.x and 3.5.x changes **[HIGH]**
- https://ggplot2.tidyverse.org/reference/coord_cartesian.html — reverse/ratio/expand behavior **[HIGH]**
- https://ggplot2.tidyverse.org/reference/guide_legend.html — legend guide semantics **[HIGH]**
- https://ggplot2.tidyverse.org/reference/guide_colourbar.html — continuous guide semantics **[HIGH]**
- https://ggplot2.tidyverse.org/reference/expansion.html — expansion defaults for parity **[HIGH]**
- https://ggplot2.tidyverse.org/reference/complete_theme.html — theme completion API for extraction **[HIGH]**
- https://cran.r-project.org/web/packages/scales/index.html — scales 1.4.0 version and scope **[HIGH]**
- https://cran.r-project.org/web/packages/crosstalk/index.html — crosstalk 1.2.2 version **[HIGH]**
- https://cran.r-project.org/web/packages/chromote/index.html — chromote 0.5.1 **[HIGH]**
- https://cran.r-project.org/web/packages/webshot2/index.html — webshot2 0.1.2 **[HIGH]**
- https://cran.r-project.org/web/packages/shinytest2/index.html — shinytest2 0.5.1 **[HIGH]**

---
*Stack research for: gg2d3 v1.1 milestone (interactive legends, transitions, advanced coord/scale parity)*
*Researched: 2026-03-23*
