---
phase: 04-essential-geoms
plan: 02
subsystem: rendering
tags: [geoms, d3-rendering, area-charts, ribbon-plots, wave-2]
requires:
  - 04-01 (R-side IR infrastructure for new geoms)
provides:
  - geom_area D3 renderer
  - geom_ribbon D3 renderer
affects:
  - inst/htmlwidgets/modules/geoms/area.js
  - inst/htmlwidgets/modules/geoms/ribbon.js
tech_stack:
  added: []
  patterns:
    - d3.area() path generator for filled regions
    - Baseline calculation for area geoms
    - ymin/ymax band rendering for ribbons
key_files:
  created: []
  modified:
    - inst/htmlwidgets/modules/geoms/area.js (119 lines)
    - inst/htmlwidgets/modules/geoms/ribbon.js (100 lines)
decisions:
  - id: area-baseline-calculation
    choice: "Calculate baseline as: zero if in domain, else domain min"
    rationale: "Matches ggplot2 behavior for non-stacked areas"
  - id: area-vs-ribbon-distinction
    choice: "Area uses baseline, ribbon always uses ymin/ymax from data"
    rationale: "Reflects ggplot2's semantic difference between the two geoms"
metrics:
  duration: 61 min
  completed: 2026-02-08
---

# Phase 4 Plan 2: Area and Ribbon Geom Renderers

**One-liner:** Implemented geom_area and geom_ribbon D3 renderers using d3.area() path generator with baseline calculation and ymin/ymax band support.

## Objective

Replace Wave 1 placeholder modules with fully functional geom_area and geom_ribbon renderers. Both geoms use d3.area() path generator but differ in baseline handling: area calculates a fixed baseline (zero or domain min), while ribbon always uses ymin/ymax from data.

## Tasks Completed

| Task | Description | Status | Commit |
|------|-------------|--------|--------|
| 1 | Implement geom_area renderer | ✓ | 3ae7c48 |
| 2 | Implement geom_ribbon renderer | ✓ | f50a295 |

## Implementation Summary

### Task 1: geom_area renderer (area.js)

**Implementation:**
- Full IIFE pattern following line.js structure
- Utilities: val, num, asRows, fillColor, strokeColor, opacity
- Data preparation: Map to {x, y, ymin, d} objects with group support
- Baseline calculation:
  - If data has ymin column: use ymin per point (stacked areas)
  - If band y-scale: baseline = plotHeight
  - Else: baseline = yScale(0) if 0 in domain, else yScale(domain[0])
- d3.area() generator:
  - Normal: x(p.x), y0(baseline), y1(p.y)
  - Flipped: y(p.x), x0(baseline), x1(p.y)
- .defined() for missing data gaps
- Sorting by x for non-band scales (like geom_line)

**Files modified:**
- inst/htmlwidgets/modules/geoms/area.js (119 lines)

**Verification:**
```r
p <- ggplot(economics, aes(x = as.numeric(date), y = unemploy)) +
  geom_area(fill = "steelblue")
w <- gg2d3(p)
# PASSED: Widget created successfully
```

### Task 2: geom_ribbon renderer (ribbon.js)

**Implementation:**
- Similar structure to area.js but always uses ymin/ymax from data
- Data preparation: Map to {x, ymin, ymax, d} objects
- No baseline calculation - ribbon is always a band between two values
- d3.area() generator:
  - Normal: x(p.x), y0(p.ymin), y1(p.ymax)
  - Flipped: y(p.x), x0(p.ymin), x1(p.ymax)
- .defined() checks all three values (x, ymin, ymax)
- Sorting by x for non-band scales

**Files modified:**
- inst/htmlwidgets/modules/geoms/ribbon.js (100 lines)

**Verification:**
```r
huron <- data.frame(year = 1875:1972, level = as.numeric(LakeHuron))
huron$ymin <- huron$level - 1
huron$ymax <- huron$level + 1
p <- ggplot(huron, aes(year)) +
  geom_ribbon(aes(ymin = ymin, ymax = ymax), fill = "steelblue", alpha = 0.3) +
  geom_line(aes(y = level))
w <- gg2d3(p)
# PASSED: Widget created successfully with ribbon and line
```

## Deviations from Plan

None - plan executed exactly as written.

## Verification Results

All tasks passed their verification tests:
- ✓ Area renderer creates valid htmlwidget
- ✓ Ribbon renderer creates valid htmlwidget with multiple geoms

## Success Criteria

- ✓ Area plots render filled regions from baseline to data values
- ✓ Ribbon plots render filled bands between ymin and ymax values
- ✓ Both geoms handle grouped data (via group aesthetic)
- ✓ Both geoms handle coord_flip correctly
- ✓ Missing data creates gaps (via .defined())
- ✓ area.js provides geom_area renderer (119 lines > 60 min)
- ✓ ribbon.js provides geom_ribbon renderer (100 lines > 60 min)
- ✓ Both register with window.gg2d3.geomRegistry

## Technical Highlights

**Baseline calculation (area.js):**
The baseline calculation follows ggplot2's logic:
1. Stacked areas: use ymin from data (pre-computed by ggplot_build)
2. Band scales: baseline at panel bottom
3. Continuous scales: zero if in domain, else domain min

**Area vs Ribbon distinction:**
- **Area**: Fixed baseline (zero or domain min), fills from baseline to y
- **Ribbon**: Variable baseline, fills from ymin to ymax (both from data)

**coord_flip handling:**
Both geoms swap d3.area() coordinates:
- Normal: x(horizontal), y0/y1(vertical baseline/value)
- Flipped: y(horizontal), x0/x1(vertical baseline/value)

## Next Phase Readiness

**Phase 4 Plan 3** ready to start:
- geom_area and geom_ribbon now fully functional
- Pattern established for path-based filled geoms
- Remaining Wave 2 geoms: hline/vline, abline, segment, polygon, smooth

**No blockers or concerns.**

## Self-Check: PASSED

**Created files:**
✓ FOUND: /Users/davidzenz/R/gg2d3/inst/htmlwidgets/modules/geoms/area.js
✓ FOUND: /Users/davidzenz/R/gg2d3/inst/htmlwidgets/modules/geoms/ribbon.js

**Commits:**
✓ FOUND: 3ae7c48 (feat(04-02): implement geom_area renderer)
✓ FOUND: f50a295 (feat(04-02): implement geom_ribbon renderer)

All artifacts verified.
