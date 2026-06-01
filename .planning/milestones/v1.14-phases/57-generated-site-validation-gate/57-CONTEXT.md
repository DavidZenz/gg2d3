# Phase 57: Generated Site Validation Gate - Context

**Gathered:** 2026-06-01
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 57 creates a repeatable validation gate for generated pkgdown output. It must detect stale generated-site content, missing sf support text, missing htmlwidget containers, missing widget dependency assets, and ambiguous sf render/skip outcomes.

It does not add new renderer features, replace pkgdown/GitHub Pages, add screenshot or pixel comparison, or solve deploy artifact inspection. Deploy artifact inspection remains Phase 58 territory.
</domain>

<decisions>
## Implementation Decisions

### Gate Shape

- **D-01:** Keep `testthat` assertions as the canonical validation source so the gate can run inside `devtools::test()` and focused `testthat::test_file(...)`.
- **D-02:** Add a thin maintainer-facing validation command or script around the assertions so maintainers do not need to remember long R one-liners. The planner can choose the exact wrapper location/name, for example `tools/validate-pkgdown-site.R` or an R helper, as long as it calls the same assertions.

### Rebuild Policy

- **D-03:** Support two validation modes: quick mode inspects committed generated `docs/`; release mode rebuilds source-derived docs/site before inspection.
- **D-04:** Release mode should run the source-derived pipeline before checking: `devtools::document()`, `devtools::build_readme()`, and `pkgdown::build_site_github_pages(new_process = FALSE, install = FALSE)`.
- **D-05:** Quick mode should fail if committed/generated evidence is stale or missing; release mode should fail if rebuilding changes required generated evidence or required markers/assets are missing after rebuild.

### Failure Output

- **D-06:** Failure messages must name the exact file/path and marker/asset that failed, not opaque boolean failures.
- **D-07:** Keep output primarily marker-specific `testthat` failures. Add a small summary/report only if it materially improves maintainer diagnosis without creating another artifact family to manage.
- **D-08:** The gate should distinguish failure classes: stale content, missing widget scaffolding/assets, pkgdown build failure, and optional spatial dependency outcome.

### Optional sf Classification

- **D-09:** Local quick validation may pass when generated output visibly records `PKGDOWN_SF_OPTIONAL_SKIP`.
- **D-10:** CI/release validation should require rendered sf widget evidence when `sf` and `geojsonsf` are available/loadable in the website environment.
- **D-11:** If CI website dependency setup expects spatial packages but `sf`/`geojsonsf` cannot load, classify that as dependency setup failure, separate from stale-site/content failures.
- **D-12:** The sf render path should be proven as `gg2d3 html-widget` appearing after the `sf family maps with` heading when dependencies load.

### Agent Discretion

- The planner may choose the exact command/script name/location and whether to implement a small shared helper so long as `testthat` remains canonical.
- The planner may choose exact report wording if a report is added, but must avoid raw logs or large generated artifacts in planning docs.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone Scope

- `.planning/ROADMAP.md` - Phase 57 goal, requirements, and success criteria.
- `.planning/REQUIREMENTS.md` - SITE-01 and v1.14 requirement context.
- `.planning/PROJECT.md` - Current milestone constraints and publication-surface context.

### Phase 56 Inputs

- `.planning/phases/56-pkgdown-content-and-widget-build-contract/56-CONTEXT.md` - Locked source/generated/pkgdown evidence decisions.
- `.planning/phases/56-pkgdown-content-and-widget-build-contract/56-VERIFICATION.md` - Current generated-site evidence, local sf outcome, and command outcomes.
- `.planning/phases/56-pkgdown-content-and-widget-build-contract/56-03-SUMMARY.md` - Generated docs, test contract, deviations, and local environment notes.

### Existing Validation Assets

- `tests/testthat/test-pkgdown-site.R` - Current focused generated-site assertions to extend/refactor.
- `.github/workflows/pkgdown.yaml` - Pkgdown dependency setup, website dependency check, build, and deploy route.
- `DESCRIPTION` - Website/test suggests, including optional spatial dependencies.
- `_pkgdown.yml` - Site configuration and reference index.

### Source And Generated Site Surfaces

- `vignettes/gg2d3.Rmd` - Source article and sf chunk render/skip behavior.
- `README.Rmd` - Source docs with artifact taxonomy.
- `vignettes/d3-drawing-diagnostics.md` - Maintainer-facing artifact taxonomy and validation semantics.
- `docs/articles/gg2d3.html` - Generated article HTML markers/widgets.
- `docs/articles/gg2d3.md` - Generated article text snapshot.
- `docs/articles/gg2d3_files/gg2d3-modules-0.0.1` - Article-local widget module assets.
- `docs/news/index.html` - Generated NEWS evidence.
- `docs/reference/gg2d3.html` - Generated main reference evidence.
- `docs/reference/extract_sf_geometries.html` - Generated sf helper reference evidence.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `tests/testthat/test-pkgdown-site.R` already has path-resolving readers and marker assertions for generated article, NEWS, reference pages, module assets, and sf render/skip outcome.
- `.github/workflows/pkgdown.yaml` already has a website dependency verification step before the pkgdown build.
- `vignettes/gg2d3.Rmd` already emits `PKGDOWN_SF_OPTIONAL_SKIP` locally and can render a widget when spatial packages load.
- Phase 56 generated docs provide actual committed target files for quick-mode validation.

### Established Patterns

- Source-first docs: edit source docs, regenerate generated outputs, validate generated evidence.
- Optional dependency behavior must be visible and classified.
- Browser visual smoke artifacts are separate from pkgdown evidence; Phase 57 should not add pixel/screenshot thresholds.
- Test helpers should emit file/marker-specific failure messages.

### Integration Points

- Focused validation: `tests/testthat/test-pkgdown-site.R`.
- Full suite integration: `devtools::test()`.
- Maintainer/release command: likely wrapper around docs regeneration plus focused generated-site assertions.
- CI route: `.github/workflows/pkgdown.yaml` and potentially future workflow step or local command in diagnostics.
</code_context>

<specifics>
## Specific Ideas

- Pkgdown/R Markdown precomputes article examples into generated static HTML, htmlwidget JSON payloads, and dependency files. Phase 57 should validate those generated artifacts, not runtime browser compilation.
- Use quick/release validation modes so ordinary development can inspect committed `docs/`, while release validation can rebuild before inspection.
- The sf article outcome should pass locally with a visible skip, but release/CI should prefer rendered sf when dependencies are available.
</specifics>

<deferred>
## Deferred Ideas

- GitHub Pages artifact download/inspection and deployed-output evidence are Phase 58.
- Public pull-request preview links remain future/Phase 58-adjacent.
- Screenshot or perceptual regression coverage for pkgdown pages remains future work after content freshness and widget embedding gates are stable.
- External uptime/freshness monitoring remains future work.
</deferred>

---

*Phase: 57-generated-site-validation-gate*
*Context gathered: 2026-06-01*
