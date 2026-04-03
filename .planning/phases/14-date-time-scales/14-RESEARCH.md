# Phase 14 Research: Date/Datetime Parity Behavior

## Objective
Ensure date and datetime axes in `gg2d3` behave identically to `ggplot2` regarding breaks, labels, and timezones.

## Current State Analysis

### 1. Date/Datetime Breaks (`DATE-01`)
- **Extraction:** `R/as_d3_ir.R` extracts breaks from `ggplot_build(p)$panel$ranges`. This should naturally include the effects of `date_breaks` since ggplot2 pre-calculates them.
- **Rendering:** `inst/htmlwidgets/modules/scales.js` uses `axisGen.tickValues(breaks.map(d => new Date(d)))`.
- **Potential Gap:** If `date_breaks` results in many minor breaks or specific alignments, we need to ensure they are all passed and rendered correctly. Current implementation filters NA breaks but doesn't explicitly distinguish between major and minor breaks in the final axis generation (only major breaks are currently used for `tickValues`).

### 2. Date/Datetime Labels (`DATE-02`)
- **Extraction:** `R/as_d3_ir.R` extracts `date_labels` pattern from the scale's label function closure and stores it in `ir$scales$x$format`.
- **Rendering:** `scales.js` uses `d3.utcFormat(fmt)` or `d3.timeFormat(fmt)` if a pattern exists.
- **Fallback:** If no pattern exists, it falls back to `scaleDesc.labels` (pre-formatted by ggplot2).
- **Potential Gap:** The translation from R `strftime` patterns to D3 patterns is currently a simple regex: `rFormat.replace(/%[Zz]/g, '').trim()`. While mostly compatible, we should verify if more complex R patterns (like `%q` for quarter) need mapping.

### 3. Timezone Behavior (`DATE-03`)
- **Extraction:** `R/as_d3_ir.R` attempts to extract `timezone` from the scale object.
- **Rendering:** `scales.js` switches between `d3.scaleUtc()` and `d3.scaleTime()` based on whether `timezone === 'UTC'`.
- **CRITICAL GAP:** `d3.scaleTime()` uses the **browser's local timezone**, which may differ from the `timezone` specified in `scale_x_datetime(tz = "...")`. To achieve true parity, we must ensure the display matches the requested timezone regardless of the browser's locale.

## Technical Proposals

### Timezone Correctness
To support arbitrary timezones without external libraries like `moment-timezone` (keeping dependencies low):
1. **Option A (Timestamp Offset):** Adjust the millisecond timestamps in the IR by the timezone offset relative to UTC, then use `d3.scaleUtc()`. This is risky for DST transitions if we don't know the exact offsets for every date.
2. **Option B (D3-Time-Format UTC with Offset):** Use `d3.utcFormat` but manually adjust the `Date` object before formatting.
3. **Option C (Simple Parity):** If we cannot perfectly replicate arbitrary timezones in D3 without a heavy library, we should at least ensure "UTC" and "Local" are handled correctly, and warn for others, OR find a lightweight way to handle the offset.
*Decision:* We should check if `ggplot2` provides the UTC-offset timestamps or if we can extract them.

### Formatting Parity
- Verify `d3.timeFormat` tokens against `base::strptime`.
- tokens like `%e` (space-padded day) might need attention.

## Proposed Plan (14-01-PLAN.md)
1. Add comprehensive tests for `date_breaks` and `date_labels`.
2. Investigate timezone offset extraction from R.
3. Update `scales.js` to handle non-UTC timezones more accurately (possibly via offset-based UTC rendering).
4. Add regression tests for different timezones.

---
*Research completed: 2026-03-31*
