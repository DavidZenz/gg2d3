# Phase 17 Research: Advanced Scale Parity

## Objective
Achieve full parity with ggplot2 for advanced scale features: custom breaks, minor breaks, expansion, and out-of-bounds (OOB) logic.

## Current State Analysis

### 1. Breaks and Minor Breaks (`SCALE-01`)
- **Major Breaks:** Correctly extracted from `panel_params` and passed to D3.
- **Minor Breaks:**
  - Extracted at the top-level `ir$scales` but **MISSING** from the per-panel `ir$panels` metadata.
  - This causes faceted plots with free scales to lose minor grid lines or show incorrect ones.
- **Orientation:** Need to verify `minor_breaks` are correctly swapped when `is_flip` is true.

### 2. Scale Expansion (`SCALE-03`)
- **Status:** Mostly covered. `R/as_d3_ir.R` pulls `expanded_range` from `panel_params`, which already includes the effects of `expand = expansion(...)`.
- **D3 Implementation:** D3 scales use this expanded domain directly as their `domain()`.
- **Edge Case:** If `panel_params` is unavailable, `as_d3_ir` falls back to a manual 5% expansion. We should ensure this fallback is as close to ggplot2 defaults as possible.

### 3. Out-of-Bounds (OOB) Logic (`SCALE-03`)
- **Status:** Handled by R. ggplot2 processes `oob` (e.g., `scales::squish`, `scales::censor`) during the `ggplot_build` phase. The data passed to `as_d3_ir` already has these transformations applied.
- **Verification:** Confirm that interactive features (like zoom) don't accidentally "un-squish" or "un-censor" data by using original raw data instead of the built data.

### 4. Formatter Parity (`SCALE-02`)
- **Status:** Improved in Phase 14 for date/time.
- **General Scales:** For numeric scales, we currently use a hardcoded `.4~g` format in JS or fallback to pre-formatted labels from R.
- **Improvement:** Ensure numeric formatters (e.g., `scales::label_dollar()`) are consistently applied by preferring R's pre-formatted `labels` in the IR.

## Technical Proposals

### Update `panels_ir` for Minor Breaks
Modify the `panels_ir` extraction in `R/as_d3_ir.R` to include minor breaks for each panel:
```r
panel_x_minor_breaks <- unname(ppx$minor_breaks[!is.na(ppx$minor_breaks)])
# ... convert to ms if temporal ...
list(
  # ...
  x_minor_breaks = panel_x_minor_breaks,
  y_minor_breaks = panel_y_minor_breaks
)
```

### JS `renderPanel` Enhancement
Ensure `renderPanel` in `gg2d3.js` uses these per-panel minor breaks:
```javascript
const xMinorBreaks = panelData.x_minor_breaks || (ir.scales.x && ir.scales.x.minor_breaks);
```

## Proposed Plan (17-01-PLAN.md)
1. Add regression tests for custom breaks and minor breaks in faceted plots.
2. Update `R/as_d3_ir.R` to extract per-panel minor breaks.
3. Update `inst/htmlwidgets/gg2d3.js` to utilize per-panel minor breaks for grid rendering.
4. Verify that `oob` behavior is preserved during zoom/interactions.
5. Add visual verification for complex expansions and OOB squishing.

---
*Research completed: 2026-03-31*
