---
phase: 07-legend-system
plan: 01
subsystem: IR-extraction
tags: [guides, legends, aesthetics, ggplot2-integration]

dependency_graph:
  requires:
    - "Phase 6 layout engine (legend space reservation)"
    - "ggplot2::get_guide_data() API"
  provides:
    - "ir$guides array with complete guide specifications"
    - "Guide validation in validate_ir()"
  affects:
    - "R/as_d3_ir.R (guide extraction logic)"
    - "R/validate_ir.R (guide validation)"

tech_stack:
  added:
    - tool: "ggplot2::get_guide_data()"
      purpose: "Extract pre-computed guide keys from plot"
  patterns:
    - name: "Guide extraction via get_guide_data()"
      impl: "Leverages ggplot2's guide training mechanism"
    - name: "Legend merging detection"
      impl: "Groups guides by title, merges aesthetics"
    - name: "Colorbar gradient interpolation"
      impl: "30 evenly-spaced color stops for smooth SVG gradients"

key_files:
  created: []
  modified:
    - path: "R/as_d3_ir.R"
      lines_changed: +222
      commit: "c5de46b"
    - path: "R/validate_ir.R"
      lines_changed: +25
      commit: "c6562a6"

decisions:
  - id: "get-guide-data-extraction"
    summary: "Use ggplot2::get_guide_data() for guide extraction"
    rationale: "ggplot2 already computes all legend keys, labels, and aesthetic values through guide training; extracting pre-computed data avoids reimplementing complex guide logic"
    impact: "All guide extraction delegates to ggplot2; gg2d3 only serializes to IR"

  - id: "colorbar-30-stops"
    summary: "Generate 30 interpolated color stops for continuous colorbars"
    rationale: "get_guide_data() returns breaks (~5 values); smooth gradients need more stops to avoid banding"
    impact: "Colorbar guides include colors array with 30 hex values for SVG gradients"

  - id: "merged-guide-detection"
    summary: "Detect merged guides by matching title field"
    rationale: "ggplot2 merges guides when multiple aesthetics map to same variable with same title"
    impact: "Single guide IR entry for color+shape mapping to same variable"

  - id: "legend-theme-extraction"
    summary: "Extract legend.key.size, legend.text, legend.title theme elements"
    rationale: "D3 renderers need theme values for consistent visual parity"
    impact: "ir$theme$legend contains all necessary legend styling"

metrics:
  duration_minutes: 2
  tasks_completed: 2
  tests_added: 4
  tests_passing: 225
  files_modified: 2
  lines_added: 247
  commits: 2
  completed_at: "2026-02-09T20:02:30Z"
---

# Phase 07 Plan 01: Guide IR Extraction Summary

**Extract guide (legend) specifications from ggplot2 and serialize to IR**

## Completion

All tasks completed successfully. Guide extraction uses ggplot2's `get_guide_data()` API to extract pre-computed guide keys for all mapped aesthetics (colour, fill, size, shape, alpha). IR now contains `guides` array with complete specifications including discrete legend keys and continuous colorbar gradients.

## What Was Built

### Guide Extraction System (Task 1)

Added comprehensive guide extraction logic to `as_d3_ir()` using ggplot2's guide training mechanism:

1. **Aesthetic identification**: Scans all scales to identify which aesthetics produce legends (colour/fill/size/shape/alpha), checking for guide = "none" exclusions
2. **Guide data extraction**: Calls `get_guide_data(plot, aesthetic)` for each legend-producing aesthetic, wrapping in tryCatch for robustness
3. **Guide type detection**: Determines "legend" (discrete) vs "colorbar" (continuous) based on scale class (ScaleContinuous)
4. **Key serialization**: Converts guide_data data frame rows to JSON-serializable list structures with value, label, and aesthetic-specific fields (colour hex, size numeric, shape code)
5. **Colorbar gradient generation**: Samples scale at 30 evenly-spaced points to create smooth color array for SVG gradients
6. **Legend merging**: Detects guides with duplicate titles, merges them into single guide with multiple aesthetics array
7. **Theme extraction**: Extracts legend.key.size (with grid::convertUnit() to pixels), legend.text, legend.title, legend.background, legend.key

**Guide IR structure:**
```r
list(
  aesthetic = "colour",           # primary aesthetic
  aesthetics = list("colour"),    # all merged aesthetics
  type = "legend",                # or "colorbar"
  title = "Species",              # scale name or label
  keys = list(                    # breaks with labels and values
    list(value = "setosa", label = "setosa", colour = "#F8766D"),
    list(value = "versicolor", label = "versicolor", colour = "#00BA38"),
    list(value = "virginica", label = "virginica", colour = "#619CFF")
  ),
  colors = NULL                   # only for colorbar: 30 hex values
)
```

### Guide Validation (Task 2)

Added guide structure validation to `validate_ir()`:

- **Required fields check**: Errors if guide missing `type` field
- **Type validation**: Warns on unrecognized guide types (not "legend" or "colorbar")
- **Keys validation**: Warns if guide has no keys
- **Colorbar validation**: Warns if colorbar has insufficient colors array (< 2 stops)
- **Backward compatible**: Soft validation with warnings, not errors; older IR without guides passes unchanged

All validation tests pass, including malformed guide detection.

## Tests & Verification

**Added 4 verification tests:**

1. **Discrete color legend**: Iris plot with color=Species produces single legend guide with 3 keys containing colour hex values
2. **No legend case**: Plot without aesthetic mappings produces empty guides array
3. **Continuous colorbar**: Plot with continuous color scale produces colorbar guide with 30+ interpolated colors
4. **Merged legends**: Plot with color + shape both mapped to Species produces single merged guide with aesthetics = ["colour", "shape"]

**All 225 package tests pass**, no regressions.

## Deviations from Plan

None. Plan executed exactly as written.

## Implementation Notes

### ggplot2 get_guide_data() API

The `get_guide_data(plot, aesthetic)` function (added in ggplot2 3.5.0) returns a data frame with:
- `.value`: original data values (factor levels or numeric breaks)
- `.label`: display labels (customizable via scale labels parameter)
- `{aesthetic}`: mapped aesthetic values (hex colors for colour/fill, numeric for size, shape codes for shape)

This pre-computed structure eliminates need for gg2d3 to reimplement guide training, break computation, or aesthetic mapping logic.

### Legend Merging Logic

ggplot2 automatically merges guides when multiple aesthetics map to the same variable with the same scale name. Detection pattern:
1. Extract all guides independently
2. Group by title field
3. Guides with duplicate titles are merged: combine aesthetics array, merge key columns
4. Result: single guide IR entry with multiple aesthetic values per key

Example: `aes(color = Species, shape = Species)` → single guide with keys containing both `colour` and `shape` fields.

### Colorbar Gradient Interpolation

Discrete guides use exact breaks from `get_guide_data()`. Continuous colorbars need smooth gradients:
1. Get scale domain via `scale$get_limits()`
2. Generate 30 evenly-spaced values across domain
3. Map through scale: `scale$map(values)` → 30 hex colors
4. Store in `colors` array for D3 linearGradient rendering

30 stops provide smooth gradients without banding while keeping JSON payload reasonable.

### Theme Element Conversion

Legend theme elements require unit conversion:
- `legend.key.size`: ggplot2 default is `unit(1.2, "lines")` → convert to pixels via `grid::convertUnit(elem, "inches") * 96`
- Other elements: Use existing `extract_theme_element()` helper for text/rect/background

## Files Changed

### R/as_d3_ir.R (+222 lines)
- Added guide extraction logic (lines 512-722)
- Identifies legend-producing aesthetics from scales
- Extracts guide data via `get_guide_data()`
- Builds guide IR specifications with keys and colors
- Detects and merges guides with duplicate titles
- Extracts legend theme elements with unit conversion
- Adds `ir$guides` to IR object

### R/validate_ir.R (+25 lines)
- Added guide validation section (lines 76-100)
- Validates required type field
- Warns on unrecognized types, missing keys, insufficient colors
- Soft validation preserves backward compatibility

## Next Steps

Phase 7 plan 07-02 will implement the D3 legend rendering modules (`legend.js`) that consume this IR and render discrete legends and continuous colorbars as SVG elements.

## Self-Check: PASSED

**Created files verified:**
```bash
[ -f ".planning/phases/07-legend-system/07-01-SUMMARY.md" ] && echo "FOUND: SUMMARY.md" || echo "MISSING: SUMMARY.md"
# Output: FOUND: SUMMARY.md
```

**Commits verified:**
```bash
git log --oneline --all | grep -q "c5de46b" && echo "FOUND: c5de46b" || echo "MISSING: c5de46b"
# Output: FOUND: c5de46b

git log --oneline --all | grep -q "c6562a6" && echo "FOUND: c6562a6" || echo "MISSING: c6562a6"
# Output: FOUND: c6562a6
```

**Key files verified:**
```bash
[ -f "R/as_d3_ir.R" ] && echo "FOUND: R/as_d3_ir.R" || echo "MISSING: R/as_d3_ir.R"
# Output: FOUND: R/as_d3_ir.R

[ -f "R/validate_ir.R" ] && echo "FOUND: R/validate_ir.R" || echo "MISSING: R/validate_ir.R"
# Output: FOUND: R/validate_ir.R
```

All verification checks passed.
