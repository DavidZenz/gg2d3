---
phase: 33-single-panel-renderer-and-interactivity
status: passed
threats_open: 0
audited: 2026-05-20
---

# Phase 33 Security Audit

## Verdict

All Phase 33 threat-model items are mitigated. The main security/privacy concern was accidental exposure of renderer-private sf payloads through user-facing interactivity callbacks.

## Threat Review

| Threat | Status | Evidence |
|--------|--------|----------|
| Rendered sf paths lose row identity or centroid attributes needed by interactivity | Mitigated | `sf.js` keeps `data-row-id`, `data-cx`, and `data-cy`; `test-sf-interactivity.R` guards the source contract. |
| Tooltip output or formatter input exposes private renderer fields | Mitigated | `tooltip.js` sanitizes underscore-prefixed fields before field selection and formatter calls. |
| Custom handlers or Shiny payloads expose private renderer fields | Mitigated | `events.js` sanitizes event data before click, mouseover, mouseout, and Shiny payload delivery. Added after code review warning WR-01. |
| Sf brush selection uses polygon bbox center instead of centroid | Mitigated | `brush.js` handles `path.geom-sf` before generic path handling and reads only `data-cx`/`data-cy`. |
| Brush callbacks leak private renderer fields | Mitigated | `brush.js` sanitizes selected rows before returning callback data. |
| Cartesian zoom transforms sf widgets into misleading maps | Mitigated | `d3_zoom()` warns and returns before storing zoom config or attaching zoom JS when sf layers are present. |

## Verification

Passed:

- `Rscript --vanilla -e 'pkgload::load_all(quiet = TRUE); testthat::test_file("tests/testthat/test-sf-renderer.R"); testthat::test_file("tests/testthat/test-sf-interactivity.R"); testthat::test_file("tests/testthat/test-zoom-brush.R")'`

## Open Threats

None.

---
*Audited: 2026-05-20*
