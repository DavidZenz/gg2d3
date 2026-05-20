# Roadmap: gg2d3

## Milestones

- ✅ **v1.0 MVP** — Phases 1-12 (shipped 2026-02-16)
- ✅ **v1.1 Interactive Exploration** — Phases 13-15 (shipped 2026-03-31)
- ✅ **v1.2 Smooth Transitions & Scale Parity** — Phases 16-17 (shipped 2026-03-31)
- ✅ **v1.3 Advanced Facets & Custom Interactivity** — Phases 18-19 (shipped 2026-03-31)
- ✅ **v1.4 Comprehensive Theme Parity & Reference Geoms** — Phases 20-21 (shipped 2026-03-31)
- ✅ **v1.5 Non-Cartesian Systems & Advanced Stats** — Phases 22-23 (shipped 2026-03-31)
- ✅ **v1.6 Advanced Geoms & API Polish** — Phases 24-26 (shipped 2026-04-04)
- ✅ **v1.7 Choropleth Map Research** — Phases 27-30 (shipped 2026-05-20)
- ✅ **Distribution: pkgdown and GH Pages Publishing** — Phase 31 (shipped 2026-05-17)

## Phases

<details>
<summary>✅ v1.0 MVP (Phases 1-12) — SHIPPED 2026-02-16</summary>

See `.planning/milestones/v1.0-ROADMAP.md` for full details.

</details>

<details>
<summary>✅ v1.1 Interactive Exploration (Phases 13-15) — SHIPPED 2026-03-31</summary>

See `.planning/milestones/v1.1-ROADMAP.md` for full details.

</details>

<details>
<summary>✅ v1.2 Smooth Transitions & Scale Parity (Phases 16-17) — SHIPPED 2026-03-31</summary>

See `.planning/milestones/v1.2-ROADMAP.md` for full details.

</details>

<details>
<summary>✅ v1.3 Advanced Facets & Custom Interactivity (Phases 18-19) — SHIPPED 2026-03-31</summary>

See `.planning/milestones/v1.3-ROADMAP.md` for full details.

</details>

<details>
<summary>✅ v1.4 Comprehensive Theme Parity & Reference Geoms (Phases 20-21) — SHIPPED 2026-03-31</summary>

See `.planning/milestones/v1.4-ROADMAP.md` for full details.

</details>

<details>
<summary>✅ v1.5 Non-Cartesian Systems & Advanced Stats (Phases 22-23) — SHIPPED 2026-03-31</summary>

See `.planning/milestones/v1.5-ROADMAP.md` for full details.

</details>

<details>
<summary>✅ v1.6 Advanced Geoms & API Polish (Phases 24-26) — SHIPPED 2026-04-04</summary>

See `.planning/milestones/v1.6-ROADMAP.md` for full details.

</details>

<details>
<summary>✅ v1.7 Choropleth Map Research (Phases 27-30) — SHIPPED 2026-05-20</summary>

See `.planning/milestones/v1.7-ROADMAP.md` for full details.

Delivered the `geom_sf` research handoff: R extraction feasibility, D3 polygon rendering prototype, interactivity design, and future implementation blueprint.

</details>

<details>
<summary>✅ Distribution: pkgdown and GH Pages Publishing (Phase 31) — SHIPPED 2026-05-17</summary>

Phase 31 was orthogonal to the v1.7 choropleth stream. It ported the pkgdown/GitHub Pages publishing work from the v1.1 `stupefied-austin` branch.

**Goal:** A pkgdown site at <https://davidzenz.github.io/gg2d3/> is rebuilt and redeployed on every push to master and releases, with at least one verifiably interactive `gg2d3()` widget in the published "Get started" article.

**Requirements:** DOCS-02

**Plans:** 5/5 complete

- [x] 31-01 — preflight (pkgdown/usethis versions, PAT presence, manual-orphan bootstrap decision)
- [x] 31-02 — config edits (rename vignette to gg2d3.Rmd, rewrite `_pkgdown.yml`, patch `.Rbuildignore`, extend DESCRIPTION URL)
- [x] 31-03 — local build + D-15 preflight human interactivity check
- [x] 31-04 — `.github/workflows/pkgdown.yaml`, orphan `gh-pages` branch, GitHub Pages settings, and first CI deploy
- [x] 31-05 — D-14 published-site human checkpoint, repo About URL, and planning finalization

</details>

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 27. R IR Extraction Feasibility | v1.7 | 2/2 | Complete | 2026-04-04 |
| 28. D3 Renderer Prototyping | v1.7 | 2/2 | Complete | 2026-04-04 |
| 29. Interactivity Design | v1.7 | 1/1 | Complete | 2026-05-19 |
| 30. Edge Cases and Blueprint | v1.7 | 1/1 | Complete | 2026-05-20 |
| 31. pkgdown and GH Pages Publishing | distribution | 5/5 | Complete | 2026-05-17 |

---
*Roadmap updated: 2026-05-20 after v1.7 milestone archive*
