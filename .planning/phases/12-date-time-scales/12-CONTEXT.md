# Phase 12: Date/Time Scales - Context

**Gathered:** 2026-02-16
**Status:** Ready for planning

<domain>
## Phase Boundary

Add date/time scale support so POSIXct, Date, and other temporal R types render correctly with properly formatted time axes in D3. This extends the existing scale system (Phase 2) with temporal scale types. No new geoms or interactivity features.

</domain>

<decisions>
## Implementation Decisions

### Date formats
- Match ggplot2's formatting exactly for the initial view
- Extract the date_labels format pattern from the ggplot2 scale and translate to D3's d3.timeFormat equivalent (not just pre-formatted strings)
- This enables dynamic reformatting when zoomed (format pattern lives in JS, not just static label text)

### Data type scope
- Support all temporal types: POSIXct, Date, POSIXlt, hms, difftime
- Lubridate types (periods, intervals, durations) supported only if ggplot2 handles them natively (no special handling)
- Use ggplot2's scale type detection (from ggplot_build) rather than detecting original R class
- Date/time must work on both x and y axes (including with coord_flip)

### Timezone handling
- Preserve R's timezone (tzone attribute) through the IR to D3
- When R data has no explicit timezone (empty tzone), assume UTC for consistent cross-browser rendering
- Tooltip values must display in the same timezone as axis labels (not browser-local)

### Axis tick density
- Use ggplot2's pre-computed break positions for the initial (non-zoomed) view
- Match ggplot2's minor tick/grid behavior (show minor grid only if ggplot2 provides date_minor_breaks)
- Match ggplot2's label overlap behavior (only rotate/thin if ggplot2 does)

### Claude's Discretion
- Whether to accept a timezone library dependency or use an offset-based approach for timezone display
- Whether to translate R strftime format tokens to D3 format tokens, or fall back to pre-formatted strings if translation is too complex
- Whether zoomed views should show adaptive tick granularity (years -> months -> days) or keep original format
- Whether to pass date_breaks interval to D3 for zoom recalculation, or just use pre-computed positions with D3 auto ticks for zoom

</decisions>

<specifics>
## Specific Ideas

- The existing scale system uses ggplot2 breaks as ticks (ir-breaks-as-ticks decision from Phase 2) — date/time should follow the same pattern
- The existing zoom.js already handles scale rescaling — date/time zoom should integrate with this existing system
- R's strftime and D3's d3.timeFormat share many tokens (%Y, %m, %d, %H, %M, %S) — translation may be straightforward for common formats

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 12-date-time-scales*
*Context gathered: 2026-02-16*
