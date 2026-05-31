# Phase 56: Pkgdown Content And Widget Build Contract - Context

**Gathered:** 2026-05-31
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 56 makes the generated pkgdown site reflect the current source documentation and support contract. It should rebuild or configure the pkgdown content path so users can see the current `geom_sf()` and widget behavior in the generated site, and so maintainers can prove representative `gg2d3` article widgets rendered during the site build. It does not add new rendering features, pixel-diff enforcement, or a replacement documentation system.

</domain>

<decisions>
## Implementation Decisions

### Generated Site Freshness
- **D-01:** Treat generated `docs/` output as part of this phase's release surface, not as a disposable byproduct. Phase 56 should bring source docs and generated pkgdown pages back into alignment.
- **D-02:** The phase should prefer source-first edits followed by regeneration over hand-editing `docs/` files. Generated pages are evidence of the build, not the authoring location.
- **D-03:** Freshness should cover the main article, reference pages, NEWS, and support-contract language, with special attention to the sf support section that exists in `vignettes/gg2d3.Rmd` but is absent from the stale generated site.

### Widget Rendering Evidence
- **D-04:** Verify representative pkgdown article output by inspecting generated HTML for real `gg2d3` htmlwidget scaffolding and dependency assets.
- **D-05:** Phase 56 should use pkgdown-generated article evidence as a distinct signal from browser visual smoke. Browser smoke proves rendering behavior; pkgdown evidence proves public documentation pages embed widgets correctly.
- **D-06:** It is enough for Phase 56 to prove widget scaffolding/assets and source-to-site alignment. Pixel comparison or screenshot thresholds belong to future work after the generated site is reliably fresh.

### sf Optional Dependency Behavior
- **D-07:** The website build should render the `geom_sf()` article example when `sf` and `geojsonsf` are available in the website environment.
- **D-08:** If optional spatial dependencies are unavailable, the outcome must be visible and classified as an optional dependency skip or setup failure. The sf section should not disappear silently from the published article.
- **D-09:** The first implementation path should inspect and harden the existing dependency route before adding new machinery: `DESCRIPTION` already lists `sf` and `geojsonsf` in `Suggests`, and `.github/workflows/pkgdown.yaml` uses `r-lib/actions/setup-r-dependencies` with `needs: website`.

### Artifact Taxonomy
- **D-10:** Documentation or diagnostics updated in this phase should clearly separate source docs (`README.Rmd`, `vignettes/`, roxygen), generated pkgdown files (`docs/`), GitHub Pages/deploy output, and browser visual smoke artifacts.
- **D-11:** The handoff should tell maintainers which artifact answers which question: source docs define intent, generated `docs/` proves local/pkgdown rendering, GitHub Pages artifacts prove publication, and browser smoke artifacts prove representative browser behavior.

### the agent's Discretion
- The planner may choose exact validation commands and file targets as long as they preserve source-first documentation and produce clear evidence for generated-site freshness and widget rendering.
- The planner may decide whether Phase 56 updates generated `docs/` immediately or first fixes build configuration and then regenerates, provided the final phase evidence includes generated site output.
- The planner may choose the exact wording for visible sf dependency skip/failure messaging.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone Scope
- `.planning/ROADMAP.md` — Phase 56 goal, requirements, and success criteria.
- `.planning/REQUIREMENTS.md` — v1.14 DOCS and BUILD requirements mapped to Phase 56.
- `.planning/PROJECT.md` — Current milestone context and decision that the published site is a release surface.

### Pkgdown Build And Publication
- `_pkgdown.yml` — pkgdown site configuration, release mode, URL, and reference index.
- `.github/workflows/pkgdown.yaml` — GitHub Actions website dependency setup, pkgdown build command, and deploy target.
- `DESCRIPTION` — package `Suggests`, including `sf`, `geojsonsf`, `rmarkdown`, `knitr`, and other website/test dependencies.

### Source Documentation
- `vignettes/gg2d3.Rmd` — Main article source, including the current sf family maps section and conditional sf example.
- `vignettes/d3-drawing-diagnostics.md` — Diagnostics, browser visual smoke semantics, optional skip language, and release validation context.
- `README.Rmd` — Source package overview and documentation pointers.
- `NEWS.md` — Release notes source that should be reflected in pkgdown NEWS output.
- `R/gg2d3.R` — Roxygen source for user-facing support contract and generated help.
- `R/sf-utils.R` — Roxygen source for sf helper reference pages and dependency behavior.

### Generated Site Evidence
- `docs/articles/gg2d3.html` — Generated main article; currently contains `gg2d3` htmlwidget divs but is stale relative to the sf source section.
- `docs/articles/gg2d3.md` — Generated markdown article snapshot useful for text freshness checks.
- `docs/news/index.html` — Generated NEWS page.
- `docs/reference/gg2d3.html` — Generated reference page for the main widget entry point.
- `docs/reference/extract_sf_geometries.html` — Generated reference evidence for sf helper documentation.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `.github/workflows/pkgdown.yaml`: Existing workflow already installs website dependencies through `r-lib/actions/setup-r-dependencies` and builds with `pkgdown::build_site_github_pages(new_process = FALSE, install = FALSE)`.
- `vignettes/gg2d3.Rmd`: Existing sf article section can be reused as the canonical example; its chunk currently depends on `requireNamespace("sf") && requireNamespace("geojsonsf")`.
- `docs/articles/gg2d3.html`: Existing generated article already contains many `gg2d3 html-widget` containers, so the issue is not that pkgdown cannot render widgets at all; the stale sf content is the sharper problem.
- `vignettes/d3-drawing-diagnostics.md`: Existing diagnostics language already distinguishes optional browser/spatial skips and can be extended for pkgdown/site validation.

### Established Patterns
- Source-first documentation is the project pattern: edit Rmd/roxygen/NEWS sources, regenerate README/help/site artifacts, and keep generated output aligned.
- Optional browser and spatial dependencies are allowed to skip only when the skip is explicit, classified, and recorded as evidence.
- Browser visual smoke artifacts are stored and inspected as downstream evidence rather than committed source artifacts.

### Integration Points
- Pkgdown build configuration: `_pkgdown.yml`, `.github/workflows/pkgdown.yaml`, and website dependency resolution through `DESCRIPTION`.
- Documentation sources: `README.Rmd`, `vignettes/gg2d3.Rmd`, `vignettes/d3-drawing-diagnostics.md`, `NEWS.md`, and roxygen comments in `R/`.
- Generated site checks: `docs/articles/`, `docs/reference/`, `docs/news/`, `docs/deps/`, and htmlwidget dependency directories under article-specific `_files/`.

</code_context>

<specifics>
## Specific Ideas

- The immediate bug to close is that `vignettes/gg2d3.Rmd` has the current sf family maps section, but `docs/articles/gg2d3.html` does not show it.
- The site should prove both text freshness and widget embedding; seeing `gg2d3 html-widget` divs alone is not enough if the article content is stale.
- The planner should preserve the distinction between pkgdown site checks and the existing browser visual smoke workflow rather than merging them into one ambiguous gate.

</specifics>

<deferred>
## Deferred Ideas

- Public pull-request preview links for pkgdown sites remain a future website-experience requirement.
- Screenshot or perceptual regression coverage for selected pkgdown article pages remains future work after content freshness and widget embedding are stable.
- External uptime/freshness monitoring for the published GitHub Pages URL remains future work after the deploy evidence path is proven.

</deferred>

---

*Phase: 56-pkgdown-content-and-widget-build-contract*
*Context gathered: 2026-05-31*
