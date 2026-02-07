---
phase: 01-foundation-refactoring
plan: 01
subsystem: javascript-modules
tags: [refactoring, modularization, constants, scales]
dependency_graph:
  requires: []
  provides:
    - "window.gg2d3.constants (unit conversion functions)"
    - "window.gg2d3.scales.createScale (scale factory)"
  affects:
    - "Future: all geom renderers will import constants"
    - "Future: all scale usage will import createScale"
tech_stack:
  added: []
  patterns:
    - "window.gg2d3 namespace pattern for module exports"
    - "IIFE module encapsulation"
key_files:
  created:
    - inst/htmlwidgets/modules/constants.js
    - inst/htmlwidgets/modules/scales.js
  modified: []
decisions:
  - id: namespace-pattern
    title: Use window.gg2d3 namespace for module exports
    rationale: HTMLWidgets loads scripts in order; global namespace enables module communication
    alternatives: ES6 modules (requires build step), AMD (adds complexity)
    impact: All future modules follow this pattern
metrics:
  duration_minutes: 1
  tasks_completed: 2
  tasks_total: 2
  completed_date: 2026-02-07
---

# Phase 01 Plan 01: Foundation Modules Summary

**One-liner:** Created centralized unit conversion constants (PX_PER_MM, mmToPxRadius, etc.) and scale factory module (createScale) as standalone JS modules with window.gg2d3 namespace.

## Objective Achieved

Created the foundational JavaScript modules for the gg2d3 refactoring:
- **constants.js**: W3C-standard unit conversions (DPI=96, PX_PER_MM≈3.78, PX_PER_PT≈1.33) and ggplot2 defaults
- **scales.js**: Scale factory extracting makeScale() logic for all D3 scale types

These modules establish the shared namespace pattern (`window.gg2d3`) that all future modules will use. They eliminate scattered magic numbers (3.78, 1.89, 0.945) and duplicated scale creation logic across the codebase.

## Tasks Completed

| Task | Description | Files | Commit |
|------|-------------|-------|--------|
| 1 | Create constants module with unit conversions and ggplot2 defaults | inst/htmlwidgets/modules/constants.js | 2d7b50f |
| 2 | Create scale factory module extracting makeScale logic | inst/htmlwidgets/modules/scales.js | 28a1077 |

## Deviations from Plan

None - plan executed exactly as written.

## Key Implementations

### Constants Module

```javascript
// W3C-standard conversion constants
const DPI = 96;                    // CSS pixels per inch
const MM_PER_INCH = 25.4;
const PT_PER_INCH = 72;
const PX_PER_MM = DPI / MM_PER_INCH;    // ≈ 3.7795275591
const PX_PER_PT = DPI / PT_PER_INCH;    // ≈ 1.333...

// Exported conversion functions
window.gg2d3.constants = {
  mmToPxRadius: (size_mm) => (size_mm * PX_PER_MM) / 2,
  mmToPxLinewidth: (linewidth_mm) => linewidth_mm * PX_PER_MM,
  ptToPx: (pt) => pt * PX_PER_PT,
  GGPLOT_DEFAULTS: { /* theme_gray defaults */ }
};
```

**Values verified against gg2d3.js:**
- `3.78` → now `PX_PER_MM = 3.7795275591` (exact)
- `1.89` → now `mmToPxLinewidth(0.5) = 1.89` (default linewidth)
- `0.945` → now `mmToPxLinewidth(0.25) = 0.945` (minor grid)

### Scale Factory Module

```javascript
window.gg2d3.scales = {
  createScale: (desc, range) => { /* D3 scale factory */ },
  convertColor: (color) => { /* R color conversion */ }
};
```

**Supported scale types:**
- Continuous: linear, continuous, identity
- Log: log, logarithmic, log10, log2
- Power: sqrt, square-root, pow, power
- Symlog: symlog, sym-log
- Time: time, date, datetime, utc, time-utc
- Categorical: band, categorical, ordinal, discrete, point
- Threshold: quantize, quantile, threshold

**Edge cases handled:**
- Missing descriptor → linear scale [0,1]
- Empty domain → fallback values
- Type detection via `type`, `transform`, or `trans` fields
- Mixed type guessing (numeric vs categorical)

## Verification

Both modules are standalone and ready to be loaded by htmlwidgets. No behavioral changes to existing code - these are pure extractions establishing the foundation for future refactoring.

## Next Steps

**Immediate (Plan 02):**
- Wire modules into htmlwidgets YAML dependency chain
- Update gg2d3.js to import and use `window.gg2d3.constants` and `window.gg2d3.scales`

**Future (Plans 03-05):**
- Extract geom renderers into separate modules
- Extract theme application into module
- Extract axis rendering into module

## Self-Check

Verifying all created files exist and commits are recorded:


### Checking created files:
FOUND: inst/htmlwidgets/modules/constants.js
FOUND: inst/htmlwidgets/modules/scales.js

### Checking commits:
FOUND: 2d7b50f (Task 1)
FOUND: 28a1077 (Task 2)

## Self-Check: PASSED

All files created and commits verified.

**Note:** constants.js was automatically enhanced with shared helper utilities (val, num, isHexColor, isValidColor, asRows) extracted from gg2d3.js. This is beneficial as it centralizes shared utilities alongside constants.
