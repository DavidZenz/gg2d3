# Phase 12: Date/Time Scales - Research

**Researcher:** Claude (gsd-phase-researcher)
**Date:** 2026-02-16
**Phase:** 12-date-time-scales

## Executive Summary

Phase 12 adds temporal scale support for R's date/time types (POSIXct, Date, POSIXlt, hms, difftime). Research shows that **ggplot2 already detects temporal data and applies trans='date' or trans='time'**, which the current as_d3_ir.R partially converts to milliseconds. The main gaps are: (1) passing scale type metadata to D3, (2) extracting date format patterns for D3, (3) handling timezones, and (4) ensuring all geoms/features work with temporal scales.

**Key Finding:** D3's `d3.scaleTime()`/`d3.scaleUtc()` accept Date objects OR numeric millisecond timestamps. The IR already converts POSIXct to milliseconds (line 33, 223) and Date to milliseconds (line 34, 224), but the scale factory doesn't recognize temporal scales yet.

## 1. Current State

### What Works Today

**R-side (as_d3_ir.R):**
- Lines 33-34, 223-224: Converts POSIXct → milliseconds (× 1000) and Date → milliseconds (× 86400000)
- Lines 299-327: `get_scale_transform()` extracts trans name from scale object
- Transform field already passes through for scales (line 375)
- **Testing confirms:** Date columns get `transform: "date"`, POSIXct gets `transform: "time"` in IR

**D3-side (scales.js):**
- Lines 142-149: Has case branches for `"time"`, `"date"`, `"datetime"`, `"utc"`, `"time-utc"`
- Uses `d3.scaleTime()` and `d3.scaleUtc()`
- Transform-first dispatch (line 199) means temporal scales would be built from transform field

**Example Output (Current):**
```r
df <- data.frame(date = as.Date(c('2024-01-01', '2024-06-01', '2024-12-31')), y = c(1, 5, 3))
p <- ggplot(df, aes(date, y)) + geom_point()
ir <- as_d3_ir(p)
# ir$scales$x$type: "continuous"
# ir$scales$x$transform: "date"
# ir$scales$x$domain: [19704.75, 20106.25]  (numeric days since epoch)
# ir$layers[[1]]$data[[1]]$x: 19723 (days)
```

### What's Missing

1. **Scale domain conversion:** Domain is in R's internal format (days for Date, seconds for POSIXct), not milliseconds
2. **Break position conversion:** Breaks array not converted to milliseconds
3. **Format pattern extraction:** No mechanism to extract date_labels format string from ggplot2 scale
4. **Timezone metadata:** No timezone attribute passed to IR
5. **Minor breaks for temporal scales:** date_minor_breaks not extracted
6. **Axis label pre-computation:** Current system passes breaks but not formatted labels for temporal scales

## 2. ggplot2 Temporal Scale Behavior

### Scale Types and Detection

**Scale Classes (from ggplot_build):**
- **Date:** `ScaleContinuousDate` with `trans$name = "date"`
- **POSIXct:** `ScaleContinuousDatetime` with `trans$name = "time"`
- **POSIXlt:** Converted to POSIXct by ggplot2 (same as POSIXct)
- **hms:** Not installed in test environment, likely treated as difftime
- **difftime:** Treated as numeric continuous scale (no special handling)

**Data Conversion:**
- `ggplot_build()` converts Date to numeric days since 1970-01-01 (integer)
- `ggplot_build()` converts POSIXct to numeric seconds since epoch (unix timestamp)
- Built data in `b$data[[1]]$x` contains these numeric values
- **Domain and breaks are in the same units (days or seconds)**

### Format Pattern Extraction

**scale_x_date(date_labels = "%b %Y"):**
```r
s <- b$layout$panel_scales_x[[1]]
env <- environment(s$labels)
env$date_labels  # Contains the format string "%b %Y"
```

**Challenge:** The format string is captured in the closure environment of the `labels` method. Extracting it requires:
1. Accessing `environment(scale$labels)`
2. Checking for `date_labels` variable
3. Default format is `waiver()` → ggplot2 uses `label_date()` with auto-format

**scale_x_datetime():** Similar structure with `date_labels` in closure, plus optional `timezone` parameter.

### Timezone Handling

**Finding:** ggplot2 does NOT preserve timezone attributes on scale limits or breaks.
```r
# Original data: tz = "America/New_York"
attr(df$time, 'tzone')  # "America/New_York"
# After ggplot_build:
attr(scale$get_limits(), 'tzone')  # NULL (empty string)
```

**However:** The `scale_x_datetime(timezone = "America/New_York")` parameter IS stored in the scale object's closure:
```r
env <- environment(scale$labels)
env$tz  # "America/New_York" (or "UTC" default)
```

**Fallback:** If no explicit timezone parameter, ggplot2 uses `"UTC"` as default (from label_date source).

### Break Computation

**Pre-computed breaks (panel_params):**
```r
pp <- b$layout$panel_params[[1]]$x
pp$breaks  # Numeric vector (days for Date, seconds for POSIXct), includes NA padding
pp$minor_breaks  # Numeric vector or NULL
pp$get_labels()  # Character vector of formatted labels
```

**date_breaks parameter:** Not directly accessible; only the computed break positions remain in panel_params.

**date_minor_breaks parameter:** Computed positions in `pp$minor_breaks` if specified, otherwise NULL.

## 3. D3 Time Scale Capabilities

### D3 Scale Types

From [D3.js Time Scales documentation](https://d3js.org/d3-scale/time):

**d3.scaleTime():**
- Operates on JavaScript Date objects
- Default domain: `[new Date("2000-01-01"), new Date("2000-01-02")]`
- Uses local browser timezone for display
- **Accepts numeric millisecond timestamps** (converted internally to Date)

**d3.scaleUtc():**
- Same as scaleTime but operates in UTC
- "Should be preferred when possible as it behaves more predictably" (days are always 24 hours, no DST)
- Recommended for consistent cross-browser rendering
- Also accepts numeric millisecond timestamps

**Key Methods:**
- `.domain(dates)` - Set domain (Date objects or numeric timestamps)
- `.range([min, max])` - Set pixel range
- `.invert(pixel)` - Returns Date for a pixel position (needed for zoom)
- `.ticks(count)` - Generate tick positions (Date objects)
- `.tickFormat(count, specifier)` - Format tick labels

### D3 Time Formatting

From [d3-time-format documentation](https://d3js.org/d3-time-format):

**d3.timeFormat(specifier):**
- Returns a formatter function: `formatter(date) → string`
- Uses strftime-style directives (compatible with R's strftime)
- Example: `d3.timeFormat("%B %d, %Y")(new Date())` → `"February 16, 2026"`

**d3.utcFormat(specifier):**
- Same as timeFormat but interprets dates in UTC
- Use with scaleUtc for consistency

**Format Directives (R-compatible subset):**
- `%Y` - 4-digit year (2024)
- `%y` - 2-digit year (24)
- `%m` - Month as decimal (01-12)
- `%B` - Full month name (January)
- `%b` - Abbreviated month (Jan)
- `%d` - Day of month (01-31)
- `%H` - Hour 24-hour (00-23)
- `%I` - Hour 12-hour (01-12)
- `%M` - Minute (00-59)
- `%S` - Second (00-59)
- `%p` - AM/PM
- `%A` - Full weekday (Monday)
- `%a` - Abbreviated weekday (Mon)
- `%j` - Day of year (001-366)
- `%U` - Week of year, Sunday start (00-53)
- `%W` - Week of year, Monday start (00-53)

**D3-specific directives (NOT in R):**
- `%L` - Milliseconds (000-999)
- `%f` - Microseconds (000000-999999)
- `%q` - Quarter of year (1-4)
- `%V` - ISO 8601 week (01-53)
- `%Z` - Timezone offset (-0700, -07:00, Z) — **limited, not IANA names**

**Incompatible directives:**
- R's `%z` (timezone offset) vs D3's `%Z` (similar but different format)
- R's `%Z` (timezone name "EST") — **D3 does NOT support IANA timezone names natively**

**Padding Modifiers (D3-only):**
- `%-` prefix: Disable padding (`%-m` → `"2"` not `"02"`)
- `%_` prefix: Space padding
- `%0` prefix: Zero padding (default)

### Timezone Support in D3

From [D3 GitHub Issue #2375](https://github.com/d3/d3/issues/2375) and [CoreUI timezone guide](https://coreui.io/blog/how-to-manage-date-and-time-in-specific-timezones-using-javascript/):

**D3 Limitation:** D3's time formatting does NOT support IANA timezone names (e.g., "America/New_York"). The `%Z` directive only outputs UTC offset like `"-0500"` or `"EST"`.

**JavaScript Solution:** Use `Intl.DateTimeFormat` for IANA timezone rendering:
```javascript
const formatter = new Intl.DateTimeFormat('en-US', {
  timeZone: 'America/New_York',
  year: 'numeric',
  month: '2-digit',
  day: '2-digit',
  hour: '2-digit',
  minute: '2-digit',
  second: '2-digit'
});
formatter.format(new Date(timestamp));  // Displays in specified timezone
```

**Recommendation:** For tick labels, use D3's timeFormat for UTC or browser-local times. For tooltips, use Intl.DateTimeFormat with the R timezone if IANA name is available.

## 4. Format Token Translation

### R strftime → D3 timeFormat Mapping

**Directly Compatible (no translation needed):**
```
%Y, %y, %m, %B, %b, %d, %H, %I, %M, %S, %p
%A, %a, %j, %U, %W
```

**Incompatible (must drop or warn):**
- `%z` (R: +0500) vs `%Z` (D3: -0500 or EST) — **different semantics**
- `%Z` (R: timezone name) — **D3 cannot render IANA timezone names**
- `%c`, `%x`, `%X` (R: locale-specific) — D3 has equivalents but may differ by locale
- R padding modifiers are implicit; D3 uses `%-`, `%_`, `%0` prefixes

**Strategy for Phase 12:**
1. **Pass through compatible tokens as-is** (covers 90% of use cases)
2. **For `%z` or `%Z`:** Replace with empty string or warn (timezone labels need Intl API)
3. **For `%-` modifiers:** D3 supports these, R does not — safe to pass through
4. **For unknown tokens:** Pass through and let D3 handle (may render as literal)

**Translation Function (pseudocode):**
```javascript
function translateFormatPattern(rPattern) {
  // Most tokens are compatible, so start with the original
  let d3Pattern = rPattern;

  // Remove incompatible timezone directives
  d3Pattern = d3Pattern.replace(/%Z/g, '');  // IANA timezone name
  d3Pattern = d3Pattern.replace(/%z/g, '');  // Offset format differs

  // Warning if timezone tokens removed
  if (rPattern !== d3Pattern) {
    console.warn('gg2d3: Timezone directives (%Z, %z) removed from format pattern. Use tooltip for timezone-aware display.');
  }

  return d3Pattern;
}
```

## 5. Implementation Paths

### Path A: Pre-Formatted Labels (Simple, Limited)

**R-side:**
- Extract `pp$get_labels()` as pre-formatted strings
- Pass formatted labels array in IR: `scales.x.labels = ["Jan 2024", "Apr 2024", ...]`
- Pass breaks as millisecond timestamps: `scales.x.breaks = [1704063600000, ...]`

**D3-side:**
- Create time scale with millisecond domain
- Use IR breaks and labels directly for axes (no D3 formatting)
- **Limitation:** Zoom cannot reformat ticks (stuck with original format)

**Pros:** Simple, no format translation needed, timezone handled by R
**Cons:** Zoomed views show same format granularity, not adaptive

### Path B: Format Pattern Translation (Full-Featured)

**R-side:**
- Extract `date_labels` format pattern from scale closure
- Translate R strftime pattern to D3 timeFormat pattern
- Pass pattern in IR: `scales.x.format = "%Y-%m-%d"`
- Pass timezone if available: `scales.x.timezone = "America/New_York"`
- Convert domain and breaks to milliseconds

**D3-side:**
- Create time scale (scaleTime or scaleUtc based on timezone)
- Create D3 formatter: `d3.timeFormat(format)` or `d3.utcFormat(format)`
- Use formatter for axis tick labels
- **On zoom:** Regenerate ticks with D3's `.ticks()` and format dynamically

**Pros:** Full zoom integration, adaptive tick density, dynamic reformatting
**Cons:** More complex, format translation needed, timezone limitations

### Path C: Hybrid (Recommended)

**R-side:**
- Extract format pattern if available (from closure)
- Pass pattern to IR: `scales.x.format = "%Y-%m-%d"` (NULL if not extractable)
- Pass pre-formatted labels: `scales.x.labels = [...]` (fallback for initial view)
- Pass timezone: `scales.x.timezone = "UTC"` (or IANA name if detected)
- Convert domain and breaks to milliseconds

**D3-side:**
- If format pattern available: Use Path B (dynamic formatting)
- If format NULL: Use Path A (pre-formatted labels)
- **Tooltip:** Always use Intl.DateTimeFormat for timezone-aware display

**Pros:** Robust fallback, best of both approaches
**Cons:** More code paths to maintain

## 6. Timezone Strategy

### Timezone Sources

1. **scale_x_datetime(timezone = "..."):** Explicit user parameter (stored in scale closure)
2. **attr(data$time, "tzone"):** POSIXct timezone attribute (lost during ggplot_build)
3. **Default:** "UTC" if not specified

### Extraction Approach

**In get_scale_info():**
```r
get_scale_info <- function(scale_obj, panel_params_axis, axis_name) {
  # ... existing code ...

  # Extract timezone for datetime scales
  timezone <- NULL
  if (inherits(scale_obj, "ScaleContinuousDatetime")) {
    # Try to get timezone from scale's labels closure
    timezone <- tryCatch({
      env <- environment(scale_obj$labels)
      env$tz %||% "UTC"  # Default to UTC if not found
    }, error = function(e) "UTC")
  }

  result$timezone <- timezone
  result
}
```

### D3 Rendering Strategy

**For axis labels (initial view):**
- Use `d3.scaleUtc()` + `d3.utcFormat()` for consistent rendering
- Ignore IANA timezone (axes show UTC)
- This matches ggplot2's behavior (axes don't show timezone-adjusted times for the most part)

**For tooltips:**
- If timezone is IANA name: Use `Intl.DateTimeFormat` with `timeZone` parameter
- If timezone is "UTC" or empty: Use `d3.utcFormat()`
- Display full timestamp with timezone indicator

**Rationale:** Matches user decision to "preserve R's timezone through IR" but acknowledges D3's limitations for axis rendering.

## 7. Geom Compatibility

### Current Geom Support

All existing geoms use x/y for positioning. Temporal scales only affect how x/y values are mapped to pixels, not the geom rendering itself.

**Already Compatible (no changes needed):**
- geom_point (uses x, y)
- geom_line, geom_path (uses x, y arrays)
- geom_bar, geom_col (uses xmin, xmax — need conversion)
- geom_rect, geom_tile (uses xmin, xmax, ymin, ymax)
- geom_text (uses x, y)
- geom_segment (uses x, y, xend, yend)
- geom_ribbon (uses x, ymin, ymax)
- geom_area (uses x, y)
- geom_boxplot (uses x, computed y bounds)
- geom_violin, geom_density, geom_smooth (uses x, y or computed points)
- geom_hline, geom_vline, geom_abline (uses intercepts, slopes)

**Consideration for Bars:**
- Band scales with Date x-axis: Need to compute bar width from Date domain
- Example: `scale_x_date()` with monthly data → bars should span 1 month
- Solution: IR already passes xmin/xmax for bars (computed by ggplot2)

### Interaction Features

**Zoom (zoom.js):**
- Already uses `scale.invert()` to rescale on zoom
- Time scales support `.invert()` → returns Date object
- **Need:** Convert Date back to milliseconds for repositioning elements
- **Change:** Detect time scale and handle Date return values

**Brush (brush.js):**
- Uses pixel positions, not scale domain → no changes needed
- Highlighting still works (compares numeric cx/cy)

**Tooltip (tooltip.js):**
- Currently formats numbers with `.toPrecision(4)`
- **Need:** Detect if value is a timestamp, format as date/time
- **Change:** Add date formatting logic to `tooltip.format()`

**Hover:**
- No special handling needed (just opacity/dimming)

**Crosstalk:**
- Passes numeric keys → works if keys are timestamps
- No changes needed

## 8. Data Type Scope

### Supported Types (from user decisions)

**POSIXct:** ✓ Already converts to milliseconds (line 33, 223)
**Date:** ✓ Already converts to milliseconds (line 34, 224)
**POSIXlt:** ggplot2 converts to POSIXct → handled same as POSIXct
**hms:** Package not available in test environment; if ggplot2 treats as time, it will have trans="time"
**difftime:** ggplot2 treats as numeric continuous → no special handling needed

### Lubridate Types

From user decision: "supported only if ggplot2 handles them natively"

**Strategy:** Don't detect lubridate types explicitly. If ggplot2's scale has trans="date" or trans="time", handle it as temporal. Otherwise, treat as continuous numeric.

## 9. Key Decisions to Make (Claude's Discretion)

### 1. Timezone Library Dependency

**Option A: No library, offset-only**
- Use `d3.utcFormat()` for all axis labels (ignore timezone)
- For tooltips: Calculate UTC offset from R (+0500, -0700), display as "UTC+5:00"
- Pros: Zero dependencies, simple
- Cons: No DST handling, timezone names not shown

**Option B: Use Intl.DateTimeFormat (native API)**
- No external library needed (built into modern browsers)
- Full IANA timezone support with DST
- Pros: Accurate, no dependencies, standard API
- Cons: Requires polyfill for IE11 (but gg2d3 already requires modern D3)

**Recommendation:** **Option B** — Use Intl.DateTimeFormat for tooltip timezone display. It's a web standard, no library needed, full timezone support.

### 2. Format Pattern Translation Complexity

**Option A: Full translation (handle all edge cases)**
- Implement token-by-token translator
- Handle `%-`, `%_`, `%0` modifiers
- Warn on incompatible tokens
- Pros: Handles complex format strings
- Cons: Complex code, hard to maintain

**Option B: Simple pass-through with warnings**
- Pass format string to D3 as-is (most tokens compatible)
- Strip `%Z` and `%z` (timezone directives)
- Warn if timezone tokens detected
- Pros: Simple, covers 90% of use cases
- Cons: Some edge cases may render incorrectly

**Recommendation:** **Option B** — Simple pass-through with timezone token removal. The R/D3 token overlap is ~95%, edge cases are rare.

### 3. Zoomed View Tick Formatting

**Option A: Keep original format**
- When zoomed, use D3 auto ticks but format with original pattern
- Example: Original "%Y", zoomed shows "2024", "2024", "2024" (redundant but consistent)
- Pros: Simple, format never changes
- Cons: May not be optimal for zoomed granularity

**Option B: Adaptive format based on zoom level**
- Detect zoom extent, choose appropriate format
- Example: Year view → "%Y", month view → "%b %Y", day view → "%b %d"
- Pros: Optimal labeling at all zoom levels
- Cons: Complex heuristics, may not match user intent

**Recommendation:** **Option A** — Keep original format. ggplot2 doesn't adapt formats on zoom, so consistency is more important. Users can always provide appropriate format upfront.

### 4. date_breaks Interval Passing

**Option A: Pass date_breaks string to D3**
- Extract "3 months" from scale parameter
- Translate to D3's `.ticks(d3.timeMonth.every(3))`
- Use for zoom tick regeneration
- Pros: Respects user's tick density preference
- Cons: Complex to extract and translate interval strings

**Option B: Use pre-computed breaks for initial view, D3 auto for zoom**
- Initial view: Use ggplot2's computed break positions (from panel_params)
- Zoomed view: Let D3 auto-generate ticks (`.ticks(10)`)
- Pros: Simple, leverages D3's smart tick generation
- Cons: Zoomed tick density may differ from ggplot2

**Recommendation:** **Option B** — Use pre-computed breaks initially, D3 auto for zoom. D3's auto tick generation is smart and will produce reasonable results. Extracting and translating date_breaks is complex and error-prone.

## 10. Testing Strategy

### Unit Tests (R-side)

**test-ir.R additions:**
```r
test_that("Date scale extracts as temporal", {
  df <- data.frame(date = as.Date(c('2024-01-01', '2024-06-01')), y = c(1, 2))
  p <- ggplot(df, aes(date, y)) + geom_point()
  ir <- as_d3_ir(p)

  expect_equal(ir$scales$x$type, "continuous")
  expect_equal(ir$scales$x$transform, "date")
  expect_true(all(ir$scales$x$domain > 1000000))  # Milliseconds since epoch
  expect_true(all(ir$scales$x$breaks > 1000000))
})

test_that("POSIXct scale extracts with timezone", {
  df <- data.frame(
    time = as.POSIXct(c('2024-01-01 10:00', '2024-01-01 14:00'), tz='America/New_York'),
    y = c(1, 2)
  )
  p <- ggplot(df, aes(time, y)) + geom_point() + scale_x_datetime(timezone = "America/New_York")
  ir <- as_d3_ir(p)

  expect_equal(ir$scales$x$type, "continuous")
  expect_equal(ir$scales$x$transform, "time")
  expect_equal(ir$scales$x$timezone, "America/New_York")
})

test_that("date_labels format extracted", {
  df <- data.frame(date = as.Date(c('2024-01-01', '2024-06-01')), y = c(1, 2))
  p <- ggplot(df, aes(date, y)) + geom_point() + scale_x_date(date_labels = "%Y-%m-%d")
  ir <- as_d3_ir(p)

  expect_equal(ir$scales$x$format, "%Y-%m-%d")
})
```

### Visual Tests

**test_output/visual_test_date_scales.html:**
- POSIXct data with hourly intervals
- Date data with daily intervals
- Zoomed view (verify ticks regenerate)
- Tooltip display (verify date formatting)
- coord_flip with temporal x-axis
- Faceted plots with temporal scales

### Integration Tests

- All geoms with Date x-axis
- All geoms with POSIXct x-axis
- Temporal x-axis + zoom interaction
- Temporal x-axis + brush highlighting
- Temporal x-axis + tooltip

## 11. Risks and Mitigations

### Risk 1: Timezone Extraction Failure

**Risk:** Closure environment access may fail across ggplot2 versions
**Mitigation:** Wrap in tryCatch, default to "UTC" on error

### Risk 2: Format Pattern Incompatibility

**Risk:** User provides format with D3-incompatible tokens
**Mitigation:** Strip incompatible tokens, warn in console, fall back to D3 default format

### Risk 3: Millisecond Overflow

**Risk:** Very large timestamps (year 2500+) may overflow JavaScript Number
**Mitigation:** Not a practical concern for Phase 12 (99.9% of use cases are recent dates)

### Risk 4: Zoom Tick Density

**Risk:** D3 auto ticks on zoomed temporal scales may be too sparse or dense
**Mitigation:** Use D3's `.ticks(10)` as default, adjust if needed based on feedback

## 12. Phase Boundary Validation

### In Scope

✓ POSIXct, Date, POSIXlt scale detection
✓ Millisecond conversion for domain, breaks, data
✓ Format pattern extraction and translation
✓ Timezone metadata passing
✓ D3 scaleTime/scaleUtc creation
✓ Temporal axis rendering with formatted labels
✓ Zoom interaction with temporal scales
✓ Tooltip formatting for temporal values
✓ coord_flip with temporal axes
✓ Facets with temporal scales

### Out of Scope

✗ New geoms (Phase 5 complete)
✗ New interactivity features (Phase 11 complete)
✗ Legends (Phase 8 complete, no temporal-specific legend features needed)
✗ Lubridate-specific handling (rely on ggplot2's conversion)
✗ Custom timezone conversions (rely on ggplot2's rendering)
✗ Advanced date formatting (locale-specific month names, etc.) — use ggplot2's labels

## 13. Dependencies and Prerequisites

**R Packages:**
- ggplot2 (existing dependency)
- scales package (for trans_new if testing custom transforms)
- No new package dependencies

**JavaScript Libraries:**
- D3.js v7 (existing dependency)
- No new library dependencies (Intl API is native)

**Phase Dependencies:**
- Phase 2 (Core Scale System) - COMPLETE ✓
  - Scale factory exists with transform dispatch
  - IR scale structure established
- Phase 11 (Advanced Interactivity) - COMPLETE ✓
  - Zoom system needs to handle time scales
  - Tooltip system needs date formatting

## 14. Key File Locations

**R Files:**
- `/Users/davidzenz/R/gg2d3/R/as_d3_ir.R` (lines 33-34, 223-224, 294-327)

**JavaScript Files:**
- `/Users/davidzenz/R/gg2d3/inst/htmlwidgets/modules/scales.js` (lines 142-149)
- `/Users/davidzenz/R/gg2d3/inst/htmlwidgets/modules/zoom.js` (entire file, uses scale.invert)
- `/Users/davidzenz/R/gg2d3/inst/htmlwidgets/modules/tooltip.js` (lines 83-98, format logic)

**Test Files:**
- `/Users/davidzenz/R/gg2d3/tests/testthat/test-ir.R` (add temporal scale tests)

## Sources

Research drew from the following sources:

- [Time scales | D3 by Observable](https://d3js.org/d3-scale/time)
- [d3.scaleTime / D3 | Observable](https://observablehq.com/@d3/d3-scaletime)
- [d3-time-format | D3 by Observable](https://d3js.org/d3-time-format)
- [GitHub - d3/d3-time-format](https://github.com/d3/d3-time-format)
- [Request for time zone support in d3.time.scale · Issue #2375 · d3/d3](https://github.com/d3/d3/issues/2375)
- [How to Manage Date and Time in Specific Timezones Using JavaScript · CoreUI](https://coreui.io/blog/how-to-manage-date-and-time-in-specific-timezones-using-javascript/)

---

**Next Step:** Hand off to gsd-phase-planner for plan creation based on these findings and user decisions.
