# Phase 38: sf Interaction, Facet, And Documentation Hardening - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md - this log preserves the alternatives considered.

**Date:** 2026-05-22
**Phase:** 38-sf Interaction, Facet, And Documentation Hardening
**Areas discussed:** Interaction Proof Depth, Facet Validation Matrix, Documentation Surface, Public Contract Wording

---

## Area Selection

The user selected all four proposed gray areas with `1-4`.

---

## Interaction Proof Depth

| Option | Description | Selected |
|--------|-------------|----------|
| Full sf interaction gate | Use chromote DOM/callback checks across all accepted sf families for tooltip, hover/custom handlers, Shiny-style handlers, brush callbacks, and zoom suppression. | yes |
| Source/unit-only gate | Rely mostly on JS source assertions plus existing browser smoke. | |
| Visual/manual gate | Keep generated HTML fixtures and inspect manually. | |

**User's choice:** recommendations are fine.
**Notes:** The recommended option was locked. This extends existing source-level interactivity assertions into live browser proof.

---

## Facet Validation Matrix

| Option | Description | Selected |
|--------|-------------|----------|
| Full wrap/grid sf matrix | Cover `facet_wrap()` and `facet_grid()` with point, line, polygon, mixed-family, and empty-panel cases using panel-local counts and bbox isolation. | yes |
| Minimal mixed fixture | Only wrap/grid smoke for one small mixed fixture. | |
| Historical failures only | Only cases that failed historically. | |

**User's choice:** recommendations are fine.
**Notes:** The recommended option was locked. Direct DOM/IR assertions are preferred over screenshot diffs.

---

## Documentation Surface

| Option | Description | Selected |
|--------|-------------|----------|
| Full public docs refresh | Update README/Rmd, main vignette, diagnostics doc, roxygen help, and generated Rd/README. | yes |
| README plus diagnostics | Update only README and diagnostics. | |
| Help/vignette only | Update package help and vignette while leaving README compact. | |

**User's choice:** recommendations are fine.
**Notes:** The recommended option was locked. README should remain compact but no longer claim polygon-only sf support.

---

## Public Contract Wording

| Option | Description | Selected |
|--------|-------------|----------|
| Conservative and explicit | Document supported families, skipped unsupported geometries, source-row payloads, representative-anchor brushing, zoom suppression, and map anti-features. | yes |
| Friendlier and shorter | Put most details in diagnostics only. | |
| More ambitious map wording | Frame point/line sf as general map support. | |

**User's choice:** recommendations are fine.
**Notes:** The recommended option was locked. The phase should avoid implying basemaps, slippy maps, JS CRS reprojection, true geometry-overlap brushing, or large-map guarantees.

---

## Codex Discretion

- Use the existing chromote/browser-sf harness and fixture helpers where possible.
- Keep automated validation focused on live DOM/IR/callback behavior.
- Keep the documentation contract consistent across surfaces, with diagnostics carrying the longest explanation.

## Deferred Ideas

- `GEOMETRYCOLLECTION` rendering.
- `geom_sf_text()` / `geom_sf_label()` support.
- Basemaps, slippy-map controls, and JavaScript CRS reprojection.
- True geometry-overlap brushing.
- Large-map performance guarantees.
- Screenshot-diff visual regression as the primary sf browser gate.
