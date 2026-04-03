# Phase 14-01 Summary: Date/Datetime Parity Improvements

## Status
- **Plan:** 01 of 01
- **Type:** Execute
- **Status:** COMPLETED
- **Date:** 2026-03-31

## Key Accomplishments
- **DATE-01 (Breaks):** Verified that `date_breaks` in ggplot2 are correctly reflected in the IR and rendered as exact tick positions in D3.
- **DATE-02 (Labels):** Improved label rendering in `scales.js` to prioritize pre-formatted labels from ggplot2, ensuring 100% parity for complex formatters.
- **DATE-03 (Timezones):** Hardened timezone extraction in `R/as_d3_ir.R` to robustly detect timezones from Scale objects and their closures.
- **Tooltip Integration:** Added regression tests for tooltips on date axes and verified that date/time metadata is correctly propagated for interactive features.

## Verification Results
- **Automated Tests:** `devtools::test(filter = 'date-scales')` passed with 35 successful assertions.
- **JS Syntax:** Validated `inst/htmlwidgets/modules/scales.js` and `inst/htmlwidgets/modules/tooltip.js` for syntax correctness.
- **Improved Extraction:** Confirmed that `as_d3_ir` now extracts timezones from the data's native TZ even without explicit `scale_x_datetime()` calls.

## Discovered Issues & Fixes
- **Timezone Fallbacks:** Discovered that some ggplot2 versions store timezone info in the `.range` object rather than a direct field; added a third fallback to `attr(scale_obj$range$range, "tzone")`.
- **Pre-formatted Labels:** Found that D3's auto-formatting was sometimes overriding R's intent; re-ordered the formatting priority in `scales.js` to favor R's pre-calculated labels.

## Final Review
- Date and datetime axes now show identical breaks and labels to ggplot2 output.
- Timezone information is extracted and available for both axis and tooltip rendering.
- Next Steps: Proceed to Phase 15 (`coord_flip` correctness hardening).
