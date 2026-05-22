# Phase 36: Browser sf Smoke Harness - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md. This log preserves the alternatives considered.

**Date:** 2026-05-20T19:39:35Z
**Phase:** 36-browser-sf-smoke-harness
**Areas discussed:** Browser runner contract, fixture matrix, assertion depth, failure artifacts

---

## Browser Runner Contract

| Option | Description | Selected |
|--------|-------------|----------|
| `chromote` only | Optional `Suggests`, skip CRAN/missing Chrome. Recommended. | yes |
| Broader browser stack | Add Playwright/Node or similar now. | |
| Manual checks only | Keep generated HTML validation manual. | |

**User's choice:** recommendations are fine.
**Notes:** Locks `chromote` as the first-choice optional browser runner.

---

## Fixture Matrix

| Option | Description | Selected |
|--------|-------------|----------|
| Full v1.8 polygon regression set | Choropleth, stacked overlay, facet wrap/grid, skipped rows, interactivity, zoom suppression. Recommended. | yes |
| Minimal first pass | Choropleth plus skipped rows only. | |
| Include future sf families now | Add point/line fixtures before Phase 37 support exists. | |

**User's choice:** recommendations are fine.
**Notes:** Phase 36 protects existing polygon sf behavior before non-polygon expansion.

---

## Assertion Depth

| Option | Description | Selected |
|--------|-------------|----------|
| DOM plus minimal interaction smoke | Assert live DOM and simulate brush/callback behavior where reliable. Recommended. | yes |
| Static DOM only | Assert rendered paths and attributes but no interactions. | |
| Visual assertions | Add screenshot or visual-diff assertions. | |

**User's choice:** recommendations are fine.
**Notes:** DOM behavior should include `path.geom-sf`, non-empty `d`, row ids, finite anchors, console/page errors, and minimal interaction smoke.

---

## Failure Artifacts

| Option | Description | Selected |
|--------|-------------|----------|
| HTML plus logs, optional screenshot | Always leave generated HTML and console/page-error logs; screenshots only as optional diagnostics. Recommended. | yes |
| HTML only | Leave generated HTML as the only artifact. | |
| Required full bundle | Require screenshots as part of the artifact bundle. | |

**User's choice:** recommendations are fine.
**Notes:** Screenshots are allowed for debugging but are not a pass/fail gate.

---

## Agent Discretion

- Exact helper names, test helper file layout, render polling mechanics, and artifact filenames are left to the planning/execution agents.

## Deferred Ideas

- Node/browser-runner alternatives unless `chromote` proves insufficient.
- Screenshot or pixel-diff regression gates.
- Point and line sf browser fixtures before Phase 37.
