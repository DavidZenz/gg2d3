---
phase: 02-core-scale-system
plan: 01
subsystem: scale-extraction
tags: [R-layer, IR-generation, scale-transforms, panel-params]
completed: 2026-02-08
duration_minutes: 3

dependency_graph:
  requires: [01-05]
  provides: [scale-transform-metadata, panel-params-extraction]
  affects: [inst/htmlwidgets/modules/scales.js]

tech_stack:
  added: []
  patterns: [panel-params-extraction, transform-metadata-IR]

key_files:
  created: []
  modified:
    - path: R/as_d3_ir.R
      lines_changed: +76/-23
      purpose: Rewritten scale extraction using panel_params

decisions: []

metrics:
  tasks_completed: 2
  tasks_total: 2
  tests_added: 7
  commits: 2
---

# Phase 02 Plan 01: Panel Params Scale Extraction

**One-liner:** Rewrote R-side scale extraction to use ggplot2's pre-computed panel_params for correct expansion and extract transformation metadata (log, sqrt, reverse, etc.) into IR.

## What Was Built

Eliminated hardcoded 5% expansion in scale domain calculation by extracting the already-expanded domain from ggplot2's `panel_params`. Added transformation metadata extraction (log10, log2, sqrt, reverse, symlog) with parameters (base, exponent) that flows through the IR to JavaScript.

### Key Changes

1. **Removed hardcoded expansion**
   - Deleted `range_span * 0.05` expansion calculation
   - Removed zero-clamping logic (`if (scale_range[1] >= 0 && expanded_range[1] < 0)`)
   - Now extracts from `panel_params[[1]]$x$continuous_range` which already includes ggplot2's expansion

2. **Added transformation extraction**
   - New `get_scale_transform()` helper extracts transform metadata from `scale_obj$trans`
   - Maps ggplot2 trans names to D3 equivalents (log-10 → log10, sqrt → sqrt, etc.)
   - Extracts base for log scales (10, 2, e) and exponent for power scales
   - Returns NULL for identity transform (no field in IR)

3. **Updated function signatures**
   - Changed `get_scale_info(scale_obj, data_values)` to `get_scale_info(scale_obj, panel_params_axis)`
   - Call sites now pass `b$layout$panel_params[[1]]$x` instead of collected data values
   - Removed `allx` and `ally` collection code (no longer needed)

### Code Structure

**R/as_d3_ir.R** (lines 238-308):
- `get_scale_transform()` (lines 238-269): Extracts transform name, base, exponent
- `get_scale_info()` (lines 271-308): Uses panel_params for domain, merges transform info

**tests/testthat/test-ir.R** (lines 11-111):
- 7 new test cases covering log10, log2, sqrt, reverse, identity, discrete scales
- Tests verify panel_params extraction (not hardcoded 5%)
- Tests verify transform metadata flows through IR

## Verification Results

All tests passing (27/27):
- ✓ Continuous scale extracts from panel_params
- ✓ Log10 transformation with base=10
- ✓ Sqrt transformation
- ✓ Reverse transformation
- ✓ Discrete scales unchanged
- ✓ Identity transform produces NULL
- ✓ Log2 transformation with custom trans

**Example IR output (log10 scale):**
```json
{
  "scales": {
    "x": {
      "type": "continuous",
      "domain": [0.1521149, 0.7620437],
      "transform": "log10",
      "base": 10,
      "breaks": [0.30103, 0.4771213, 0.69897]
    }
  }
}
```

**Bar chart expansion verified:**
- Panel params y continuous_range: [-0.7, 14.7]
- IR y domain: [-0.7, 14.7]
- Max count in data: 14
- ✓ Correct expansion (not touching axis edge)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical Functionality] Support both hyphenated and non-hyphenated trans names**
- **Found during:** Task 2 (log2 test failing)
- **Issue:** Custom trans objects use "log2" but built-in scales use "log-2" (with hyphen)
- **Fix:** Updated `get_scale_transform()` to check for both "log-2" and "log2", same for "log10"
- **Files modified:** R/as_d3_ir.R (line 253)
- **Commit:** e539203

## Next Phase Readiness

**Provides for Phase 2 Plan 02 (JavaScript Scale Transforms):**
- ✓ IR now includes `transform` field with D3-compatible names
- ✓ IR includes `base` parameter for log scales
- ✓ Domain values are in transformed space
- ✓ Breaks are in transformed space

**Blockers:** None

## Implementation Notes

### Panel Params Access Pattern

The panel_params structure varies slightly by ggplot2 version:
- Primary: `b$layout$panel_params[[1]]$x$continuous_range`
- Fallback: `b$layout$panel_params[[1]]$x$range`
- Last resort: Manual expansion with warning

Current implementation tries `continuous_range` first, falls back to `range`, and warns if neither works before falling back to manual 5% expansion.

### Transform Name Mapping

| ggplot2 trans | D3 name | Base/Exponent |
|--------------|---------|---------------|
| identity | (NULL) | - |
| log-10, log10 | log10 | 10 |
| log-2, log2 | log2 | 2 |
| log | log | e |
| sqrt | sqrt | - |
| reverse | reverse | - |
| pseudo_log | symlog | - |

### Discrete Scale Behavior

Discrete scales remain unchanged:
- Domain extracted from `scale_obj$get_limits()`
- No transform metadata (always NULL)
- Type remains "categorical"

## Commits

| Hash | Message | Files |
|------|---------|-------|
| ddc6787 | feat(02-core-scale-system): rewrite scale extraction to use panel_params | R/as_d3_ir.R |
| e539203 | test(02-core-scale-system): add scale transformation test cases | R/as_d3_ir.R, tests/testthat/test-ir.R |

---

## Self-Check: PASSED

**Created files:**
- ✓ /Users/davidzenz/R/gg2d3/.planning/phases/02-core-scale-system/02-01-SUMMARY.md

**Modified files exist:**
- ✓ /Users/davidzenz/R/gg2d3/R/as_d3_ir.R
- ✓ /Users/davidzenz/R/gg2d3/tests/testthat/test-ir.R

**Commits exist:**
- ✓ ddc6787 (feat: rewrite scale extraction)
- ✓ e539203 (test: add scale transformation test cases)

**Tests passing:**
- ✓ All 27 tests pass
- ✓ Bar chart expansion verified
- ✓ Log scale transform metadata verified
