# Phase 35: geom_sf Docs and Validation Hardening - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-20T14:40:02Z
**Phase:** 35-geom_sf Docs and Validation Hardening
**Areas discussed:** Public Support Story, Truthful Boundaries, Validation Fixture Set, Browser Verification Depth

---

## Public Support Story

| Option | Description | Selected |
|--------|-------------|----------|
| Concise README plus detailed docs | README gets a brief support statement and example/link; vignette/diagnostics/help carry details. Recommended because it keeps the front page confident without hiding caveats. | ✓ |
| Full README treatment | Put the detailed sf story directly in README. Clear but risks overloading the README. | |
| Docs-only treatment | Keep README mostly unchanged and document sf only in vignette/help. Lower churn but less discoverable. | |

**User's choice:** Recommendations are fine.
**Notes:** Accepted recommended default. Documentation should be discoverable but not overstate general map support.

---

## Truthful Boundaries

| Option | Description | Selected |
|--------|-------------|----------|
| Blunt support contract | Explicitly list supported polygon behavior, warning/skip behavior, missing CRS behavior, zoom suppression, and anti-features. Recommended because incorrect map expectations are costly. | ✓ |
| Softer limitations language | Mention only major caveats in prose. Easier reading but less protective against overpromising. | |
| Minimal caveats | Keep caveats sparse and rely on warnings/tests. Too easy for users to infer full sf support. | |

**User's choice:** Recommendations are fine.
**Notes:** Accepted recommended default. Docs should correct stale statements that `geom_sf` is entirely unsupported.

---

## Validation Fixture Set

| Option | Description | Selected |
|--------|-------------|----------|
| Canonical v1.8 fixture matrix | Cover single choropleth, stacked overlay, facet wrap/grid, unsupported/invalid rows, CRS warning, interactivity smoke, and zoom suppression. Recommended because it maps directly to SFDOC-02. | ✓ |
| Visual fixtures only | Generate human-inspectable HTML examples without expanding automated assertions. Lighter but leaves warning/interactivity contracts under-guarded. | |
| Automated contracts only | Focus on R/source tests and skip new visual fixture breadth. Good for CI but weaker for renderer confidence. | |

**User's choice:** Recommendations are fine.
**Notes:** Accepted recommended default. Tests should prove skipped/invalid sf rows do not become misleading selectable paths.

---

## Browser Verification Depth

| Option | Description | Selected |
|--------|-------------|----------|
| Lightweight manual/browser smoke | Generate HTML fixtures plus structural assertions and optional cheap path existence checks. Recommended because it hardens confidence without adding heavy infrastructure. | ✓ |
| Full visual regression | Add screenshot/pixel diff infrastructure. Stronger but too large for this phase. | |
| Manual-only artifacts | Save HTML files and rely entirely on humans. Simple but weaker as a phase completion gate. | |

**User's choice:** Recommendations are fine.
**Notes:** Accepted recommended default. Full screenshot diffing is deferred.

---

## the agent's Discretion

- Exact documentation structure and headings.
- Exact fixture names and grouping.
- Exact wording of docs, as long as it matches actual warnings and behavior.

## Deferred Ideas

- Full screenshot/pixel visual regression infrastructure.
- Global-comparison facet projection mode.
- Non-polygon sf rendering.
- Polygon-overlap brushing.
- Large-map simplification/performance budgets.
- Tile basemaps, slippy map controls, and JavaScript-side CRS reprojection.
