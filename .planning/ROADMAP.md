# Roadmap: gg2d3

## Milestones

- ✅ **v1.12 Quality & Architecture Hardening** — Phases 48-51 (shipped 2026-05-27)
- ✅ **v1.11 Geometry Parity** — Phases 44-47 (shipped 2026-05-25)
- ✅ **v1.10 Release Hardening** — Phases 40-43 (shipped 2026-05-23)
- ✅ **v1.9 sf Robustness and Expansion** — Phases 36-39 (shipped 2026-05-22)
- ✅ **v1.8 Production geom_sf Polygon MVP** — Phases 32-35 (shipped 2026-05-20)
- ✅ **v1.7 Choropleth Map Research** — Phases 27-30 (shipped 2026-05-20)
- ✅ **Distribution: pkgdown and GH Pages Publishing** — Phase 31 (shipped 2026-05-17)
- ✅ **v1.6 Advanced Geoms & API Polish** — Phases 24-26 (shipped 2026-04-04)
- ✅ **v1.5 Non-Cartesian Systems & Advanced Stats** — Phases 22-23 (shipped 2026-03-31)
- ✅ **v1.4 Comprehensive Theme Parity & Reference Geoms** — Phases 20-21 (shipped 2026-03-31)
- ✅ **v1.3 Advanced Facets & Custom Interactivity** — Phases 18-19 (shipped 2026-03-31)
- ✅ **v1.2 Smooth Transitions & Scale Parity** — Phases 16-17 (shipped 2026-03-31)
- ✅ **v1.1 Interactive Exploration** — Phases 13-15 (shipped 2026-03-31)
- ✅ **v1.0 MVP** — Phases 1-12 (shipped 2026-02-16)

## Current Status

v1.12 is shipped and archived. Start the next milestone with `$gsd-new-milestone`.

## Archived Milestones

<details>
<summary>✅ v1.12 Quality & Architecture Hardening (Phases 48-51) — SHIPPED 2026-05-27</summary>

See `.planning/milestones/v1.12-ROADMAP.md` and `.planning/milestones/v1.12-REQUIREMENTS.md` for full details.

Delivered deterministic opt-in browser visual smoke coverage, high-risk IR helper boundaries, renderer/update/interactivity contract coverage, public payload sanitization coverage, and evidence-driven geometry polish for transformed rect/tile behavior, ordinary polygon topology boundaries, and ordinary text sizing.

- [x] Phase 48: Browser Visual Smoke Coverage (3/3 plans) — completed 2026-05-26
- [x] Phase 49: IR Helper Boundary Hardening (3/3 plans) — completed 2026-05-26
- [x] Phase 50: Renderer Wiring And Interaction Contracts (3/3 plans) — completed 2026-05-26
- [x] Phase 51: Geometry Edge-Case Classification And Polish (4/4 plans) — completed 2026-05-27

</details>

<details>
<summary>✅ v1.11 Geometry Parity (Phases 44-47) — SHIPPED 2026-05-25</summary>

See `.planning/milestones/v1.11-ROADMAP.md`, `.planning/milestones/v1.11-REQUIREMENTS.md`, and `.planning/milestones/v1.11-phases/` for full details.

Delivered ordinary `geom_polygon()` IR/rendering/interactivity, rect/tile edge closure with source-backed renderer fixes and classification evidence, `geom_sf_text()` / `geom_sf_label()` projected-anchor rendering with sanitized interaction contracts, and public docs/generated help/validation evidence for the v1.11 geometry support contract.

</details>

<details>
<summary>✅ v1.10 Release Hardening (Phases 40-43) — SHIPPED 2026-05-23</summary>

See `.planning/milestones/v1.10-ROADMAP.md`, `.planning/milestones/v1.10-REQUIREMENTS.md`, and `.planning/milestones/v1.10-phases/` for full details.

Delivered package dependency and artifact hygiene, optional browser/spatial skip hardening, release-blocking debt triage, repeatable release-gate evidence, release-facing documentation polish, and v1.10 release notes with residual-risk handoff.

</details>

<details>
<summary>✅ v1.9 sf Robustness and Expansion (Phases 36-39) — SHIPPED 2026-05-22</summary>

See `.planning/milestones/v1.9-ROADMAP.md`, `.planning/milestones/v1.9-REQUIREMENTS.md`, and `.planning/milestones/v1.9-phases/` for full details.

Delivered automated browser sf smoke harnessing, point-family and line-family `geom_sf()` IR/rendering/interactivity, hardened sf facet/documentation coverage, and package internals hardening around sf helper boundaries, ggplot2 compatibility wrappers, and regression gates.

</details>

<details>
<summary>✅ v1.8 Production geom_sf Polygon MVP (Phases 32-35) — SHIPPED 2026-05-20</summary>

See `.planning/milestones/v1.8-ROADMAP.md`, `.planning/milestones/v1.8-REQUIREMENTS.md`, and `.planning/milestones/v1.8-phases/` for full details.

Delivered production-safe polygon-family `geom_sf()` support: R-side sf extraction, WGS84 normalization, skipped-row diagnostics, D3 `path.geom-sf` rendering, tooltip/hover/handler interactivity, centroid brushing, sf zoom suppression, shared stacked-layer projection, faceted panel projection, and documentation/browser validation hardening.

</details>

<details>
<summary>✅ v1.7 Choropleth Map Research (Phases 27-30) — SHIPPED 2026-05-20</summary>

See `.planning/milestones/v1.7-ROADMAP.md` and `.planning/milestones/v1.7-MILESTONE-AUDIT.md` for full details.

Delivered the `geom_sf` research handoff: R extraction feasibility, D3 polygon rendering prototype, interactivity design, and future implementation blueprint.

</details>

<details>
<summary>✅ Distribution: pkgdown and GH Pages Publishing (Phase 31) — SHIPPED 2026-05-17</summary>

Phase 31 was orthogonal to the v1.7 choropleth stream. It ported the pkgdown/GitHub Pages publishing work from the v1.1 `stupefied-austin` branch.

</details>

<details>
<summary>✅ v1.0-v1.6 Previous Milestones — SHIPPED 2026-02-16 to 2026-04-04</summary>

See `.planning/milestones/` and archived roadmap files for full details on the MVP, interactive exploration, transitions, facets, theme parity, non-Cartesian systems, and advanced geom milestones.

</details>

---
*Roadmap updated: 2026-05-27 after archiving v1.12 Quality & Architecture Hardening*
