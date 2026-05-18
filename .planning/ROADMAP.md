# Roadmap: gg2d3

## Milestones

- ✅ **v1.0 MVP** — Phases 1-12 (shipped 2026-02-16)
- ✅ **v1.1 Interactive Exploration** — Phases 13-15 (shipped 2026-03-31)
- ✅ **v1.2 Smooth Transitions & Scale Parity** — Phases 16-17 (shipped 2026-03-31)
- ✅ **v1.3 Advanced Facets & Custom Interactivity** — Phases 18-19 (shipped 2026-03-31)
- ✅ **v1.4 Comprehensive Theme Parity & Reference Geoms** — Phases 20-21 (shipped 2026-03-31)
- ✅ **v1.5 Non-Cartesian Systems & Advanced Stats** — Phases 22-23 (shipped 2026-03-31)
- ✅ **v1.6 Advanced Geoms & API Polish** — Phases 24-26 (shipped 2026-04-04)
- ✅ **v1.7 Choropleth Map Research** — Phases 27-30 (shipped 2026-05-18)
- 📦 **Distribution** — Phase 31 pkgdown + GH Pages (shipped 2026-05-17, cross-milestone — DOCS-02)
- 📋 **Next milestone** — TBD (run `/gsd-new-milestone`)

## Phases

<details>
<summary>✅ v1.0 MVP (Phases 1-12) — SHIPPED 2026-02-16</summary>

See .planning/milestones/v1.0-ROADMAP.md for full details.

</details>

<details>
<summary>✅ v1.1 Interactive Exploration (Phases 13-15) — SHIPPED 2026-03-31</summary>

See .planning/milestones/v1.1-ROADMAP.md for full details.

</details>

<details>
<summary>✅ v1.2 Smooth Transitions & Scale Parity (Phases 16-17) — SHIPPED 2026-03-31</summary>

See .planning/milestones/v1.2-ROADMAP.md for full details.

</details>

<details>
<summary>✅ v1.3 Advanced Facets & Custom Interactivity (Phases 18-19) — SHIPPED 2026-03-31</summary>

See .planning/milestones/v1.3-ROADMAP.md for full details.

</details>

<details>
<summary>✅ v1.4 Comprehensive Theme Parity & Reference Geoms (Phases 20-21) — SHIPPED 2026-03-31</summary>

See .planning/milestones/v1.4-ROADMAP.md for full details.

</details>

<details>
<summary>✅ v1.5 Non-Cartesian Systems & Advanced Stats (Phases 22-23) — SHIPPED 2026-03-31</summary>

See .planning/milestones/v1.5-ROADMAP.md for full details.

</details>

<details>
<summary>✅ v1.6 Advanced Geoms & API Polish (Phases 24-26) — SHIPPED 2026-04-04</summary>

See .planning/milestones/v1.6-ROADMAP.md for full details.

</details>

<details>
<summary>✅ v1.7 Choropleth Map Research (Phases 27-30) — SHIPPED 2026-05-18</summary>

See .planning/milestones/v1.7-ROADMAP.md for full details.

Audit: .planning/milestones/v1.7-MILESTONE-AUDIT.md (status: tech_debt — see Phase 29 human-UAT pending; non-blocking)

</details>

<details>
<summary>📦 Distribution: Phase 31 pkgdown + GH Pages — SHIPPED 2026-05-17</summary>

Cross-milestone publishing work; satisfies DOCS-02. Site live at https://davidzenz.github.io/gg2d3/ — rebuilds on every push to master via `.github/workflows/pkgdown.yaml`.

- [x] 31-01 — preflight (versions, PAT, manual-orphan bootstrap decision)
- [x] 31-02 — config edits (`_pkgdown.yml`, `.Rbuildignore`, DESCRIPTION URL, vignette rename)
- [x] 31-03 — local build + D-15 interactivity preflight
- [x] 31-04 — `.github/workflows/pkgdown.yaml` + orphan gh-pages branch + Pages settings
- [x] 31-05 — D-14 published-site human checkpoint + repo About URL + finalize

</details>

### 📋 Next Milestone (TBD)

No active phases. Run `/gsd-new-milestone` to plan the next cycle. Likely candidate from v1.7 blueprint: **IMPL-04 sf build milestone** (implement R/sf_utils.R + as_d3_ir.R GeomSf + sf.js renderer + interactivity per .planning/milestones/v1.7-phases/.../30-01-BLUEPRINT.md Build Phases A/B/C).

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1-12 | v1.0 | 48/48 | Complete | 2026-02-16 |
| 13-15 | v1.1 | — | Complete | 2026-03-31 |
| 16-17 | v1.2 | — | Complete | 2026-03-31 |
| 18-19 | v1.3 | — | Complete | 2026-03-31 |
| 20-21 | v1.4 | — | Complete | 2026-03-31 |
| 22-23 | v1.5 | — | Complete | 2026-03-31 |
| 24-26 | v1.6 | — | Complete | 2026-04-04 |
| 27-30 | v1.7 | 6/6 | Complete | 2026-05-18 |
| 31 | distribution | 5/5 | Complete | 2026-05-17 |

---
*Roadmap updated: 2026-05-18 — v1.7 archived*
