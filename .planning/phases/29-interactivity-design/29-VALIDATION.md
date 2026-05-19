---
phase: 29
slug: interactivity-design
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-19
---

# Phase 29 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Document structure checks via shell grep/test |
| **Config file** | none |
| **Quick run command** | `test -f .planning/phases/29-interactivity-design/29-INTERACTIVITY-DESIGN.md` |
| **Full suite command** | `test -f .planning/phases/29-interactivity-design/29-INTERACTIVITY-DESIGN.md && grep -F 'INTR-01' .planning/phases/29-interactivity-design/29-INTERACTIVITY-DESIGN.md && grep -F 'INTR-02' .planning/phases/29-interactivity-design/29-INTERACTIVITY-DESIGN.md && grep -F 'INTR-03' .planning/phases/29-interactivity-design/29-INTERACTIVITY-DESIGN.md && grep -F 'path.geom-sf' .planning/phases/29-interactivity-design/29-INTERACTIVITY-DESIGN.md && grep -F 'data-cx' .planning/phases/29-interactivity-design/29-INTERACTIVITY-DESIGN.md && grep -F 'data-cy' .planning/phases/29-interactivity-design/29-INTERACTIVITY-DESIGN.md && grep -F 'data-row-id' .planning/phases/29-interactivity-design/29-INTERACTIVITY-DESIGN.md && grep -F 'd3_tooltip()' .planning/phases/29-interactivity-design/29-INTERACTIVITY-DESIGN.md && grep -F 'd3_hover()' .planning/phases/29-interactivity-design/29-INTERACTIVITY-DESIGN.md && grep -F 'd3_brush()' .planning/phases/29-interactivity-design/29-INTERACTIVITY-DESIGN.md && grep -F 'd3_zoom()' .planning/phases/29-interactivity-design/29-INTERACTIVITY-DESIGN.md && grep -F 'D-01' .planning/phases/29-interactivity-design/29-INTERACTIVITY-DESIGN.md && grep -F 'D-02' .planning/phases/29-interactivity-design/29-INTERACTIVITY-DESIGN.md && grep -F 'D-03' .planning/phases/29-interactivity-design/29-INTERACTIVITY-DESIGN.md && grep -F 'D-04' .planning/phases/29-interactivity-design/29-INTERACTIVITY-DESIGN.md && grep -F 'D-05' .planning/phases/29-interactivity-design/29-INTERACTIVITY-DESIGN.md && grep -F 'D-06' .planning/phases/29-interactivity-design/29-INTERACTIVITY-DESIGN.md && grep -F 'D-07' .planning/phases/29-interactivity-design/29-INTERACTIVITY-DESIGN.md && grep -F 'D-08' .planning/phases/29-interactivity-design/29-INTERACTIVITY-DESIGN.md && grep -F 'D-09' .planning/phases/29-interactivity-design/29-INTERACTIVITY-DESIGN.md && grep -F 'D-10' .planning/phases/29-interactivity-design/29-INTERACTIVITY-DESIGN.md && grep -F 'D-11' .planning/phases/29-interactivity-design/29-INTERACTIVITY-DESIGN.md && grep -F 'D-12' .planning/phases/29-interactivity-design/29-INTERACTIVITY-DESIGN.md` |
| **Estimated runtime** | ~1 second |

---

## Sampling Rate

- **After every task commit:** Run the quick file-existence check.
- **After every plan wave:** Run the full grep coverage check.
- **Before `$gsd-verify-work`:** Full coverage check must be green.
- **Max feedback latency:** 1 second

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 29-01-01 | 01 | 1 | INTR-01 | — | N/A | docs | `test -f .planning/phases/29-interactivity-design/29-INTERACTIVITY-DESIGN.md && grep -F '# Phase 29 - Interactivity Design Contract' .planning/phases/29-interactivity-design/29-INTERACTIVITY-DESIGN.md && grep -F '## INTR-01 - Tooltip and Hover Contract' .planning/phases/29-interactivity-design/29-INTERACTIVITY-DESIGN.md && grep -F 'd3_tooltip()' .planning/phases/29-interactivity-design/29-INTERACTIVITY-DESIGN.md && grep -F 'd3_hover()' .planning/phases/29-interactivity-design/29-INTERACTIVITY-DESIGN.md && grep -F 'path.geom-sf' .planning/phases/29-interactivity-design/29-INTERACTIVITY-DESIGN.md && grep -F 'data-row-id' .planning/phases/29-interactivity-design/29-INTERACTIVITY-DESIGN.md && grep -F 'ir.aes_by_var' .planning/phases/29-interactivity-design/29-INTERACTIVITY-DESIGN.md && grep -F 'D-01' .planning/phases/29-interactivity-design/29-INTERACTIVITY-DESIGN.md && grep -F 'D-02' .planning/phases/29-interactivity-design/29-INTERACTIVITY-DESIGN.md && grep -F 'D-03' .planning/phases/29-interactivity-design/29-INTERACTIVITY-DESIGN.md && grep -F 'D-04' .planning/phases/29-interactivity-design/29-INTERACTIVITY-DESIGN.md && grep -F 'This phase produces implementation guidance only; it must not modify production R or JavaScript source files.' .planning/phases/29-interactivity-design/29-INTERACTIVITY-DESIGN.md` | ✅ W0 | ⬜ pending |
| 29-01-02 | 01 | 1 | INTR-02 | — | N/A | docs | `grep -F '## INTR-02 - Brush Selection Semantics' .planning/phases/29-interactivity-design/29-INTERACTIVITY-DESIGN.md && grep -F 'Centroid inside brush' .planning/phases/29-interactivity-design/29-INTERACTIVITY-DESIGN.md && grep -F 'Polygon overlap / hit-testing' .planning/phases/29-interactivity-design/29-INTERACTIVITY-DESIGN.md && grep -F 'Disable brush' .planning/phases/29-interactivity-design/29-INTERACTIVITY-DESIGN.md && grep -F 'Recommended' .planning/phases/29-interactivity-design/29-INTERACTIVITY-DESIGN.md && grep -F 'Rejected for first build' .planning/phases/29-interactivity-design/29-INTERACTIVITY-DESIGN.md && grep -F 'Rejected' .planning/phases/29-interactivity-design/29-INTERACTIVITY-DESIGN.md && grep -F 'A path.geom-sf region is selected when numeric data-cx and data-cy attributes fall inside the normalized brush pixel rectangle.' .planning/phases/29-interactivity-design/29-INTERACTIVITY-DESIGN.md && grep -F 'd3_brush()' .planning/phases/29-interactivity-design/29-INTERACTIVITY-DESIGN.md && grep -F 'data-cx' .planning/phases/29-interactivity-design/29-INTERACTIVITY-DESIGN.md && grep -F 'data-cy' .planning/phases/29-interactivity-design/29-INTERACTIVITY-DESIGN.md && grep -F 'isElementInPixelRect()' .planning/phases/29-interactivity-design/29-INTERACTIVITY-DESIGN.md && grep -F 'collectSelectedData()' .planning/phases/29-interactivity-design/29-INTERACTIVITY-DESIGN.md && grep -F 'D-05' .planning/phases/29-interactivity-design/29-INTERACTIVITY-DESIGN.md && grep -F 'D-06' .planning/phases/29-interactivity-design/29-INTERACTIVITY-DESIGN.md && grep -F 'D-07' .planning/phases/29-interactivity-design/29-INTERACTIVITY-DESIGN.md && grep -F 'D-08' .planning/phases/29-interactivity-design/29-INTERACTIVITY-DESIGN.md` | ✅ W0 | ⬜ pending |
| 29-01-03 | 01 | 1 | INTR-03 | — | N/A | docs | `grep -F '## INTR-03 - Zoom Architecture Decision' .planning/phases/29-interactivity-design/29-INTERACTIVITY-DESIGN.md && grep -F 'For the first sf build, d3_zoom() is suppressed for widgets containing sf layers.' .planning/phases/29-interactivity-design/29-INTERACTIVITY-DESIGN.md && grep -F 'd3_zoom() is not supported for geom_sf layers yet; zoom was not attached.' .planning/phases/29-interactivity-design/29-INTERACTIVITY-DESIGN.md && grep -F 'R/d3_zoom.R' .planning/phases/29-interactivity-design/29-INTERACTIVITY-DESIGN.md && grep -F 'SVG group transform' .planning/phases/29-interactivity-design/29-INTERACTIVITY-DESIGN.md && grep -F 'projection/path re-rendering' .planning/phases/29-interactivity-design/29-INTERACTIVITY-DESIGN.md && grep -F '## Implementation Hook Checklist' .planning/phases/29-interactivity-design/29-INTERACTIVITY-DESIGN.md && grep -F '## Decision Traceability' .planning/phases/29-interactivity-design/29-INTERACTIVITY-DESIGN.md && grep -F '## Checker Sign-Off' .planning/phases/29-interactivity-design/29-INTERACTIVITY-DESIGN.md && grep -F 'inst/htmlwidgets/modules/events.js' .planning/phases/29-interactivity-design/29-INTERACTIVITY-DESIGN.md && grep -F 'inst/htmlwidgets/modules/tooltip.js' .planning/phases/29-interactivity-design/29-INTERACTIVITY-DESIGN.md && grep -F 'inst/htmlwidgets/modules/brush.js' .planning/phases/29-interactivity-design/29-INTERACTIVITY-DESIGN.md && grep -F 'inst/htmlwidgets/modules/zoom.js' .planning/phases/29-interactivity-design/29-INTERACTIVITY-DESIGN.md && grep -F 'inst/htmlwidgets/modules/geoms/sf.js' .planning/phases/29-interactivity-design/29-INTERACTIVITY-DESIGN.md && grep -F 'D-09' .planning/phases/29-interactivity-design/29-INTERACTIVITY-DESIGN.md && grep -F 'D-10' .planning/phases/29-interactivity-design/29-INTERACTIVITY-DESIGN.md && grep -F 'D-11' .planning/phases/29-interactivity-design/29-INTERACTIVITY-DESIGN.md && grep -F 'D-12' .planning/phases/29-interactivity-design/29-INTERACTIVITY-DESIGN.md` | ✅ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing shell tools cover all phase requirements. No test framework setup is required for this documentation phase.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Design judgment is implementation-ready | INTR-01, INTR-02, INTR-03 | Automated grep can prove coverage, but not whether future agents can act without new decisions | Read `29-INTERACTIVITY-DESIGN.md` and confirm each section names exact future code hooks, chosen behavior, rejected alternatives, and rationale |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 1s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-05-19
