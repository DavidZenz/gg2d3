# Phase 56: Pkgdown Content And Widget Build Contract - Research

**Researched:** 2026-05-31 [VERIFIED: local date/context]
**Domain:** R pkgdown source-to-generated-site alignment, htmlwidgets article embedding, optional sf dependency classification [VERIFIED: .planning/ROADMAP.md; .planning/phases/56-pkgdown-content-and-widget-build-contract/56-CONTEXT.md]
**Confidence:** HIGH [VERIFIED: local repository inspection; CITED: https://pkgdown.r-lib.org/reference/build_site.html; CITED: https://www.htmlwidgets.org/develop_intro.html]

<user_constraints>
## User Constraints (from CONTEXT.md)

Verbatim phase constraints copied from `.planning/phases/56-pkgdown-content-and-widget-build-contract/56-CONTEXT.md`. [VERIFIED: local file]

```markdown
## Phase Boundary

Phase 56 makes the generated pkgdown site reflect the current source documentation and support contract. It should rebuild or configure the pkgdown content path so users can see the current `geom_sf()` and widget behavior in the generated site, and so maintainers can prove representative `gg2d3` article widgets rendered during the site build. It does not add new rendering features, pixel-diff enforcement, or a replacement documentation system.

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

## Deferred Ideas

- Public pull-request preview links for pkgdown sites remain a future website-experience requirement.
- Screenshot or perceptual regression coverage for selected pkgdown article pages remains future work after content freshness and widget embedding are stable.
- External uptime/freshness monitoring for the published GitHub Pages URL remains future work after the deploy evidence path is proven.
```
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DOCS-01 | Maintainers can build a generated pkgdown site whose articles, reference pages, NEWS, and support-contract text reflect the current v1.13/v1.14 source documentation. [VERIFIED: .planning/REQUIREMENTS.md] | Use source-first updates plus `pkgdown::build_site_github_pages()` regeneration; pkgdown builds articles, reference, news, and related sections as part of a complete site. [VERIFIED: local workflow; CITED: https://pkgdown.r-lib.org/reference/build_site.html] |
| DOCS-02 | Users can find the current `geom_sf()` polygon, point, line, and sf annotation support contract in the generated pkgdown site, not only in source files. [VERIFIED: .planning/REQUIREMENTS.md] | `vignettes/gg2d3.Rmd` contains the sf family maps section, while `docs/articles/gg2d3.md` and `docs/articles/gg2d3.html` do not contain that marker today. [VERIFIED: local R grep probe] |
| DOCS-03 | Maintainers can distinguish source documentation, generated `docs/`, GitHub Pages output, and browser visual smoke artifacts when checking release readiness. [VERIFIED: .planning/REQUIREMENTS.md] | Extend diagnostics/README language around artifact taxonomy; existing diagnostics already distinguish source docs, generated help, validation evidence, browser smoke artifacts, and ignored raw artifacts. [VERIFIED: vignettes/d3-drawing-diagnostics.md; README.Rmd] |
| BUILD-01 | Maintainers can run the pkgdown build locally and in GitHub Actions with website dependencies configured so representative `gg2d3` article chunks render consistently. [VERIFIED: .planning/REQUIREMENTS.md] | Local R has `pkgdown 2.2.0`, `rmarkdown 2.31`, `knitr 1.51`, `htmlwidgets 1.6.4`, `geojsonsf 2.0.5`, and no installed `sf`; the workflow already installs `any::pkgdown, local::.` with `needs: website`. [VERIFIED: local R probes; .github/workflows/pkgdown.yaml] |
| BUILD-02 | Pkgdown articles include rendered `gg2d3` htmlwidget scaffolding, dependencies, and assets for representative examples rather than static or missing placeholders. [VERIFIED: .planning/REQUIREMENTS.md] | Current stale `docs/articles/gg2d3.html` still has 45 `gg2d3 html-widget` divs and article-local dependency folders `d3-7`, `htmlwidgets-1.6.4`, `gg2d3-modules-0.0.1`, and `gg2d3-binding-0.0.0.9000`. [VERIFIED: local R probe; docs/articles/gg2d3.html; docs/articles/gg2d3_files/] |
| BUILD-03 | The `geom_sf()` pkgdown example renders when `sf` and `geojsonsf` are available, and any dependency-based non-rendering is surfaced as an explicit classified outcome. [VERIFIED: .planning/REQUIREMENTS.md] | Current vignette chunk uses `eval = requireNamespace("sf", quietly = TRUE) && requireNamespace("geojsonsf", quietly = TRUE)`, which silently omits execution output when a dependency is missing; replace or supplement this with visible classified text. [VERIFIED: vignettes/gg2d3.Rmd] |
</phase_requirements>

## Project Constraints (from AGENTS.md)

- Use the `rtk` prefix for shell commands. [VERIFIED: /Users/davidzenz/.codex/RTK.md loaded via AGENTS.md]
- Keep D3 v7 vendored locally at `inst/htmlwidgets/lib/d3/d3.v7.min.js`. [VERIFIED: AGENTS.md; inst/htmlwidgets/gg2d3.yaml]
- Use the established R package commands for docs/tests: `devtools::document()`, `devtools::test()`, `testthat::test_file(...)`, and `devtools::build_readme()`. [VERIFIED: AGENTS.md]
- Preserve the three-layer pipeline: R extraction in `R/as_d3_ir.R`, JSON-serializable IR, and D3/htmlwidgets rendering in `inst/htmlwidgets/`. [VERIFIED: AGENTS.md; local files]
- No root `CLAUDE.md` exists; project skill directories `.claude/skills` and `.agents/skills` do not exist. [VERIFIED: local filesystem probe]

## Summary

Phase 56 should be planned as a source-first documentation and build-evidence repair, not as a rendering feature phase. [VERIFIED: 56-CONTEXT.md] The current source support contract is present in `vignettes/gg2d3.Rmd`, `README.Rmd`, `R/gg2d3.R`, `R/sf_utils.R`, generated `man/*.Rd`, and diagnostics language, but the generated main pkgdown article is stale because `docs/articles/gg2d3.md` and `docs/articles/gg2d3.html` do not contain the `sf family maps` marker. [VERIFIED: local grep/R probes]

The package's pkgdown/htmlwidget machinery is already fundamentally capable of embedding widgets: stale `docs/articles/gg2d3.html` contains 45 `gg2d3 html-widget` containers and article-local htmlwidget/D3/gg2d3 dependency directories. [VERIFIED: local R probe] The planner should therefore focus on regenerating and proving current content, hardening the optional sf chunk so dependency skips are visible, and documenting artifact taxonomy. [VERIFIED: 56-CONTEXT.md]

**Primary recommendation:** Update source docs and the sf vignette chunk for visible optional-dependency classification, run `devtools::document()`, `devtools::build_readme()`, and `pkgdown::build_site_github_pages(new_process = FALSE, install = FALSE)`, then inspect generated `docs/` for sf contract text plus htmlwidget scaffolding/assets. [VERIFIED: local tooling; CITED: https://pkgdown.r-lib.org/reference/build_site.html]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Source support-contract wording | R package source/docs | Generated site | Authoring lives in `README.Rmd`, `vignettes/`, roxygen in `R/`, and `NEWS.md`; generated pages should be regenerated evidence. [VERIFIED: 56-CONTEXT.md; local files] |
| Pkgdown build orchestration | Build/CI | R package source/docs | `_pkgdown.yml` configures site shape and `.github/workflows/pkgdown.yaml` runs the site build/deploy path. [VERIFIED: local files] |
| Article widget embedding | Browser / Client | R htmlwidgets | `gg2d3()` returns `htmlwidgets::createWidget(...)`, and htmlwidgets widgets are designed to print into HTML contexts. [VERIFIED: R/gg2d3.R; CITED: https://www.htmlwidgets.org/develop_intro.html] |
| Optional sf example execution | R vignette/build process | Generated site | The `geom_sf()` example depends on R packages `sf` and `geojsonsf` during vignette rendering, before generated HTML is emitted. [VERIFIED: vignettes/gg2d3.Rmd; R/sf_utils.R] |
| Artifact taxonomy | Documentation | Build/CI evidence | Maintainers need source, generated `docs/`, GitHub Pages/deploy output, and browser smoke artifacts separated by purpose. [VERIFIED: 56-CONTEXT.md; .planning/REQUIREMENTS.md] |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| pkgdown | 2.2.0 local/docs version | Build package website into `docs/` and generate article/reference/news pages. [VERIFIED: local R probe; CITED: https://pkgdown.r-lib.org/reference/build_site.html] | Existing project site is pkgdown and workflow already uses `pkgdown::build_site_github_pages(...)`. [VERIFIED: _pkgdown.yml; .github/workflows/pkgdown.yaml] |
| rmarkdown | 2.31 local | Render `vignettes/gg2d3.Rmd` through `rmarkdown::html_vignette`. [VERIFIED: local R probe; vignettes/gg2d3.Rmd] | Existing vignette YAML declares `output: rmarkdown::html_vignette`. [VERIFIED: vignettes/gg2d3.Rmd] |
| knitr | 1.51 local | Evaluate R chunks and chunk options for vignette/article generation. [VERIFIED: local R probe; vignettes/gg2d3.Rmd] | Existing vignette uses knitr chunk options and `eval = ...` for the sf chunk. [VERIFIED: vignettes/gg2d3.Rmd; CITED: https://yihui.org/knitr/options/] |
| htmlwidgets | 1.6.4 local | Serialize `gg2d3` widget payloads and dependencies into article HTML. [VERIFIED: local R probe; R/gg2d3.R] | `gg2d3()` calls `htmlwidgets::createWidget(...)`; htmlwidgets package widgets include source code for dependencies for reproducible HTML output. [VERIFIED: R/gg2d3.R; CITED: https://www.htmlwidgets.org/develop_intro.html] |

### Supporting

| Library/Tool | Version | Purpose | When to Use |
|--------------|---------|---------|-------------|
| sf | not installed locally; `DESCRIPTION` requires `sf (>= 1.0.0)` in Suggests | Execute the article `geom_sf()` example and sf helper behavior. [VERIFIED: local R probe; DESCRIPTION; vignettes/gg2d3.Rmd] | Required for a rendered sf example; missing locally should produce a visible classified skip/failure. [VERIFIED: 56-CONTEXT.md] |
| geojsonsf | 2.0.5 local; `DESCRIPTION` requires `geojsonsf (>= 2.0.0)` in Suggests | Serialize sf geometries to GeoJSON for the IR. [VERIFIED: local R probe; R/sf_utils.R; DESCRIPTION] | Required with `sf` for the article sf example and sf helper execution. [VERIFIED: vignettes/gg2d3.Rmd; R/sf_utils.R] |
| roxygen2 | 8.0.0 local/config | Regenerate `man/*.Rd` from roxygen source comments. [VERIFIED: local R probe; DESCRIPTION] | Run before pkgdown when roxygen support-contract text changes. [VERIFIED: AGENTS.md; R/gg2d3.R; R/sf_utils.R] |
| devtools | 2.5.2 local | Project commands for `document()`, `test()`, and `build_readme()`. [VERIFIED: local R probe; AGENTS.md] | Use for established project documentation/test workflows. [VERIFIED: AGENTS.md] |
| Python http.server | available via local `.claude/launch.json` contract only | Serve generated `docs/` locally on port 4321 for manual inspection. [VERIFIED: .claude/launch.json] | Optional manual preview, not the phase's validation source of truth. [VERIFIED: 56-CONTEXT.md] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `pkgdown::build_site_github_pages(new_process = FALSE, install = FALSE)` | `pkgdown::build_site(devel = FALSE)` | Existing CI already uses `build_site_github_pages(...)`; switching commands is unnecessary unless the planner proves the current wrapper blocks required evidence. [VERIFIED: .github/workflows/pkgdown.yaml; CITED: https://pkgdown.r-lib.org/reference/build_site.html] |
| Source-first regeneration | Hand-edit `docs/articles/gg2d3.html` | Hand edits contradict D-02 and would be overwritten by pkgdown regeneration. [VERIFIED: 56-CONTEXT.md] |
| Visible chunk output for missing `sf` | Silent `eval = requireNamespace(...)` only | Silent `eval = FALSE` behavior hides the missing dependency outcome from generated article readers. [VERIFIED: vignettes/gg2d3.Rmd; 56-CONTEXT.md] |

**Installation / build preparation:**
```r
# Source docs and generated help
devtools::document()
devtools::build_readme()

# Full generated site evidence
pkgdown::build_site_github_pages(new_process = FALSE, install = FALSE)
```
[VERIFIED: AGENTS.md; .github/workflows/pkgdown.yaml; local R `args(pkgdown::build_site_github_pages)`]

**Version verification:** Use `rtk Rscript -e 'installed.packages()[, c("Package", "Version")]'` for local versions and confirm pkgdown behavior against the official 2.2.0 reference before planning command semantics. [VERIFIED: local R probe; CITED: https://pkgdown.r-lib.org/reference/build_site.html]

## Architecture Patterns

### System Architecture Diagram

```text
Source docs and code
  README.Rmd + vignettes/*.Rmd + NEWS.md + R roxygen
        |
        | devtools::document(); devtools::build_readme()
        v
Generated source artifacts
  README.md + man/*.Rd
        |
        | pkgdown::build_site_github_pages(new_process = FALSE, install = FALSE)
        v
Generated pkgdown docs/
  articles/*.html + reference/*.html + news/index.html + deps/
        |
        | inspect text markers + widget divs + script/dependency assets
        v
Phase 56 evidence
  source/site support-contract alignment + htmlwidget embedding + visible sf render/skip class
```
[VERIFIED: local files; .github/workflows/pkgdown.yaml; CITED: https://pkgdown.r-lib.org/reference/build_site.html]

### Recommended Project Structure

```text
README.Rmd                  # source overview and artifact taxonomy [VERIFIED: local file]
NEWS.md                     # release note source reflected in docs/news/index.html [VERIFIED: local files]
R/gg2d3.R                   # main widget roxygen support contract [VERIFIED: local file]
R/sf_utils.R                # sf helper roxygen and optional dependency messages [VERIFIED: local file]
vignettes/gg2d3.Rmd         # canonical generated article source and sf example [VERIFIED: local file]
vignettes/d3-drawing-diagnostics.md  # diagnostics and artifact taxonomy [VERIFIED: local file]
_pkgdown.yml                # site URL, release mode, reference index [VERIFIED: local file]
.github/workflows/pkgdown.yaml       # CI website dependency/build/deploy route [VERIFIED: local file]
docs/                       # generated pkgdown release surface [VERIFIED: local filesystem]
```

### Pattern 1: Source-First Contract Alignment

**What:** Edit source docs/roxygen/NEWS first, regenerate `README.md`, `man/*.Rd`, and `docs/`, then inspect generated outputs. [VERIFIED: 56-CONTEXT.md; AGENTS.md]

**When to use:** Use for every DOCS-01/DOCS-02/DOCS-03 change in this phase. [VERIFIED: .planning/REQUIREMENTS.md]

**Example:**
```r
# Source: AGENTS.md project commands and local pkgdown workflow
devtools::document()
devtools::build_readme()
pkgdown::build_site_github_pages(new_process = FALSE, install = FALSE)
```
[VERIFIED: AGENTS.md; .github/workflows/pkgdown.yaml]

### Pattern 2: Visible Optional sf Outcome

**What:** Keep the sf example code in the article, but add visible article output that classifies whether the example rendered, skipped for optional dependencies, or failed setup. [VERIFIED: 56-CONTEXT.md]

**When to use:** Use for BUILD-03 because the current `eval = requireNamespace(...) && requireNamespace(...)` can omit execution output without an explicit reader-facing result. [VERIFIED: vignettes/gg2d3.Rmd]

**Example:**
```r
# Source: current vignettes/gg2d3.Rmd pattern, adapted for visible classification
has_sf <- requireNamespace("sf", quietly = TRUE)
has_geojsonsf <- requireNamespace("geojsonsf", quietly = TRUE)

if (!has_sf || !has_geojsonsf) {
  cat("PKGDOWN_SF_OPTIONAL_SKIP: sf example not rendered; missing ",
      paste(c(if (!has_sf) "sf", if (!has_geojsonsf) "geojsonsf"), collapse = ", "),
      ".\n", sep = "")
} else {
  nc <- sf::st_read(system.file("shape/nc.shp", package = "sf"), quiet = TRUE)
  (ggplot(nc, aes(fill = AREA)) +
    geom_sf(color = "white", linewidth = 0.2) +
    scale_fill_gradient(low = "#eff3ff", high = "#08519c") +
    labs(fill = "Area")) |>
    gg2d3()
}
```
[VERIFIED: vignettes/gg2d3.Rmd; R/sf_utils.R; 56-CONTEXT.md]

### Pattern 3: Generated HTML Widget Evidence

**What:** Inspect generated article HTML for both `gg2d3 html-widget` divs and dependency scripts/assets such as `htmlwidgets.js`, `d3.v7.min.js`, `gg2d3.js`, and `gg2d3-modules`. [VERIFIED: local R probe; docs/articles/gg2d3.html; docs/articles/gg2d3_files/]

**When to use:** Use after pkgdown regeneration to prove BUILD-02 without introducing pixel-diff scope. [VERIFIED: 56-CONTEXT.md]

**Example:**
```r
html <- paste(readLines("docs/articles/gg2d3.html", warn = FALSE), collapse = "\n")
stopifnot(grepl("gg2d3 html-widget", html, fixed = TRUE))
stopifnot(grepl("d3.v7.min.js", html, fixed = TRUE))
stopifnot(dir.exists("docs/articles/gg2d3_files/gg2d3-modules-0.0.1"))
```
[VERIFIED: local R probe]

### Anti-Patterns to Avoid

- **Hand-editing `docs/`:** Generated pages are evidence, not source, and hand edits violate D-02. [VERIFIED: 56-CONTEXT.md]
- **Treating widget div count as freshness proof:** Current stale article has 45 widget containers while missing the sf section marker. [VERIFIED: local R probe]
- **Letting optional sf dependencies disappear silently:** BUILD-03 requires visible classification for non-rendering. [VERIFIED: .planning/REQUIREMENTS.md; 56-CONTEXT.md]
- **Merging pkgdown evidence with browser visual smoke:** Pkgdown evidence proves public documentation embedding; browser smoke proves rendering behavior. [VERIFIED: 56-CONTEXT.md]
- **Adding pixel thresholds in Phase 56:** Pixel comparison is explicitly deferred. [VERIFIED: 56-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Static site generation | Custom R Markdown copier or HTML patcher | pkgdown | Existing site config and CI use pkgdown, and pkgdown's complete build covers home/articles/reference/news. [VERIFIED: _pkgdown.yml; .github/workflows/pkgdown.yaml; CITED: https://pkgdown.r-lib.org/reference/build_site.html] |
| Widget dependency embedding | Manual `<script>` and asset copying into `docs/` | htmlwidgets/pkgdown output | `gg2d3()` already declares htmlwidgets dependencies through `createWidget()` and `inst/htmlwidgets/gg2d3.yaml`. [VERIFIED: R/gg2d3.R; inst/htmlwidgets/gg2d3.yaml; CITED: https://www.htmlwidgets.org/develop_intro.html] |
| Website dependency solving in CI | Bespoke `install.packages()` matrix | `r-lib/actions/setup-r-dependencies@v2` with `needs: website` | Existing workflow already uses this route, and r-lib/actions documents setup-r-dependencies as installing packages declared in `DESCRIPTION`. [VERIFIED: .github/workflows/pkgdown.yaml; CITED: https://github.com/r-lib/actions] |
| Visual proof for this phase | New screenshot or pixel-diff harness | Generated HTML/text/asset inspection | Phase 56 scope only requires scaffolding/assets and source-to-site alignment. [VERIFIED: 56-CONTEXT.md] |

**Key insight:** The hard part is not inventing rendering infrastructure; it is keeping source docs, generated site output, and optional dependency outcomes synchronized and visible. [VERIFIED: local repository state; 56-CONTEXT.md]

## Common Pitfalls

### Pitfall 1: Stale Generated Site Looks Healthy

**What goes wrong:** `docs/articles/gg2d3.html` can contain many widget containers while still omitting current sf support text. [VERIFIED: local R probe]

**Why it happens:** Widget embedding and source-text freshness are independent signals. [VERIFIED: local R probe; 56-CONTEXT.md]

**How to avoid:** Check both support-contract markers and htmlwidget scaffolding/assets after regeneration. [VERIFIED: .planning/REQUIREMENTS.md]

**Warning signs:** `docs/articles/gg2d3.html` has `gg2d3 html-widget` but lacks `sf family maps`. [VERIFIED: local R probe]

### Pitfall 2: Silent `eval = FALSE` sf Chunk

**What goes wrong:** Missing `sf` makes the current sf chunk not execute, with no visible generated-site classification. [VERIFIED: vignettes/gg2d3.Rmd; local R probe showing `sf` unavailable]

**Why it happens:** The current chunk-level `eval` expression is dependency-gated. [VERIFIED: vignettes/gg2d3.Rmd]

**How to avoid:** Move the dependency check inside an evaluated chunk that prints a classified skip/failure message or returns the widget. [VERIFIED: 56-CONTEXT.md]

**Warning signs:** Generated article contains the sf section text but no sf widget JSON and no `PKGDOWN_SF_OPTIONAL_SKIP` or equivalent visible marker. [VERIFIED: .planning/REQUIREMENTS.md]

### Pitfall 3: CI Dependency Route Is Assumed Rather Than Proven

**What goes wrong:** Website CI may not install optional spatial dependencies even though `DESCRIPTION` lists them in `Suggests`. [ASSUMED]

**Why it happens:** `needs: website` dependency scope is an r-lib/actions feature and should be verified in workflow output or by a local build environment before treating sf rendering as guaranteed. [VERIFIED: .github/workflows/pkgdown.yaml; CITED: https://github.com/r-lib/actions]

**How to avoid:** Plan a workflow/build log check or add a visible dependency availability diagnostic in the pkgdown article/build output. [VERIFIED: 56-CONTEXT.md]

**Warning signs:** Local build emits the optional skip because `sf` is missing while CI is expected to render it. [VERIFIED: local R probe; 56-CONTEXT.md]

### Pitfall 4: Generated Reference Pages Lag Roxygen

**What goes wrong:** Updating `R/gg2d3.R` or `R/sf_utils.R` without `devtools::document()` leaves `man/*.Rd` and pkgdown reference pages stale. [VERIFIED: AGENTS.md; local roxygen/man files]

**Why it happens:** Pkgdown reference pages consume generated package documentation, not unprocessed roxygen comments alone. [VERIFIED: local R package structure]

**How to avoid:** Run `devtools::document()` before the pkgdown site build whenever roxygen text changes. [VERIFIED: AGENTS.md]

**Warning signs:** `R/gg2d3.R` contains sf support language that `man/gg2d3.Rd` or `docs/reference/gg2d3.html` lacks. [VERIFIED: local files]

## Code Examples

### Local Build Command

```r
# Source: existing GitHub Actions workflow
pkgdown::build_site_github_pages(new_process = FALSE, install = FALSE)
```
[VERIFIED: .github/workflows/pkgdown.yaml; local R `args()`]

### Generated Site Freshness Probe

```r
checks <- c(
  article_md = "docs/articles/gg2d3.md",
  article_html = "docs/articles/gg2d3.html",
  reference = "docs/reference/gg2d3.html",
  sf_reference = "docs/reference/extract_sf_geometries.html",
  news = "docs/news/index.html"
)

for (path in checks) {
  text <- paste(readLines(path, warn = FALSE), collapse = "\n")
  message(path, ": sf marker = ", grepl("sf family maps", text, fixed = TRUE))
}
```
[VERIFIED: local R probe]

### Widget Scaffolding Probe

```r
html <- paste(readLines("docs/articles/gg2d3.html", warn = FALSE), collapse = "\n")
widget_count <- length(gregexpr("gg2d3 html-widget", html, fixed = TRUE)[[1]])
stopifnot(widget_count > 0)
stopifnot(grepl("gg2d3_files/d3-7/d3.v7.min.js", html, fixed = TRUE))
stopifnot(dir.exists("docs/articles/gg2d3_files/htmlwidgets-1.6.4"))
stopifnot(dir.exists("docs/articles/gg2d3_files/gg2d3-modules-0.0.1"))
```
[VERIFIED: local R probe]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Treat source docs and generated site as loosely coupled | Treat generated `docs/` as release surface and regenerate from source | v1.14 Phase 56 decision | Plans must update source and verify generated output. [VERIFIED: 56-CONTEXT.md; .planning/PROJECT.md] |
| Browser visual smoke as the main public-rendering evidence | Separate browser smoke from pkgdown article embedding evidence | v1.14 Phase 56 decision | Plans must prove widget scaffolding/assets in generated articles without pixel-diff scope. [VERIFIED: 56-CONTEXT.md] |
| Silent optional sf chunk skip | Visible classified sf render/skip/failure outcome | v1.14 requirement BUILD-03 | The generated article should tell maintainers why sf did or did not render. [VERIFIED: .planning/REQUIREMENTS.md; 56-CONTEXT.md] |

**Deprecated/outdated:**
- Silent dependency-gated article chunks for release-surface examples are no longer sufficient for sf documentation. [VERIFIED: .planning/REQUIREMENTS.md; 56-CONTEXT.md]
- `docs/` freshness inferred from any widget presence is no longer sufficient. [VERIFIED: local R probe; 56-CONTEXT.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Website CI may not install optional spatial dependencies even though `DESCRIPTION` lists them in `Suggests`. | Common Pitfalls | Planner may over-invest in dependency diagnostics if CI already reliably installs `sf`; still low-risk because visible classification is required either way. |

## Open Questions (RESOLVED)

1. **Should local Phase 56 execution install `sf` or accept a classified local skip?** [VERIFIED: local R probe; 56-CONTEXT.md]
   - What we know: `geojsonsf` is installed locally and `sf` is not installed locally. [VERIFIED: local R probe]
   - RESOLVED: Do not require installing `sf` locally during Phase 56 execution. Accept a visible classified local skip only when generated article output contains `PKGDOWN_SF_OPTIONAL_SKIP`; rendered sf widget evidence remains available in any environment where both `sf` and `geojsonsf` are installed. [VERIFIED: .planning/REQUIREMENTS.md; 56-CONTEXT.md; 56-01-PLAN.md; 56-03-PLAN.md]

2. **Will Phase 56 commit regenerated `docs/` immediately?** [VERIFIED: 56-CONTEXT.md]
   - What we know: D-01 treats generated `docs/` as release surface, and D-02 requires source-first regeneration. [VERIFIED: 56-CONTEXT.md]
   - RESOLVED: Commit source-derived generated `docs/`, generated README, and generated help during Phase 56 after source docs and build behavior are correct. Do not hand-edit generated files; Plan 56-03 owns regeneration and final evidence. [VERIFIED: 56-CONTEXT.md; 56-03-PLAN.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| R | All package/doc commands | yes | 4.6.0 | none [VERIFIED: local R probe] |
| pandoc | R Markdown/pkgdown rendering | yes | 3.9.0.2 | none [VERIFIED: local R probe] |
| pkgdown | Site build | yes | 2.2.0 | none [VERIFIED: local R probe] |
| rmarkdown | Vignette rendering | yes | 2.31 | none [VERIFIED: local R probe] |
| knitr | Chunk evaluation | yes | 1.51 | none [VERIFIED: local R probe] |
| htmlwidgets | Widget serialization | yes | 1.6.4 | none [VERIFIED: local R probe] |
| devtools | Project doc/test commands | yes | 2.5.2 | direct `roxygen2`/`pkgdown` calls if needed [VERIFIED: local R probe; AGENTS.md] |
| roxygen2 | Generated help | yes | 8.0.0 | none [VERIFIED: local R probe; DESCRIPTION] |
| sf | sf article example | no | - | visible optional skip locally, or install/request environment with `sf` [VERIFIED: local R probe; 56-CONTEXT.md] |
| geojsonsf | sf article example and serialization | yes | 2.0.5 | visible optional skip if missing [VERIFIED: local R probe; R/sf_utils.R] |

**Missing dependencies with no fallback:**
- None for non-sf generated-site freshness and widget scaffolding evidence. [VERIFIED: local R probe; 56-CONTEXT.md]

**Missing dependencies with fallback:**
- `sf` is missing locally; fallback is a visible classified optional skip, but rendered sf widget evidence requires installing `sf` or using CI/another environment where `sf` is available. [VERIFIED: local R probe; .planning/REQUIREMENTS.md]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | testthat 3.3.2, edition 3 [VERIFIED: local R probe; DESCRIPTION] |
| Config file | `DESCRIPTION` (`Config/testthat/edition: 3`) [VERIFIED: DESCRIPTION] |
| Quick run command | `rtk Rscript -e 'testthat::test_file("tests/testthat/test-pkgdown-site.R")'` after adding the Phase 56 focused test, or source-only probes if no test file is added. [VERIFIED: local test infrastructure; ASSUMED test filename] |
| Full suite command | `rtk Rscript -e 'devtools::test()'` [VERIFIED: AGENTS.md] |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| DOCS-01 | Generated article/reference/news pages reflect source support text | generated-file smoke | `rtk Rscript -e 'source("tests/testthat/test-pkgdown-site.R")'` or `testthat::test_file(...)` | no, Wave 0 [VERIFIED: no pkgdown/site test file found] |
| DOCS-02 | Generated article exposes sf family support contract | generated-file smoke | `rtk Rscript -e 'testthat::test_file("tests/testthat/test-pkgdown-site.R")'` | no, Wave 0 [VERIFIED: no pkgdown/site test file found] |
| DOCS-03 | Docs explain artifact taxonomy | text grep / documentation smoke | `rtk Rscript -e 'testthat::test_file("tests/testthat/test-pkgdown-site.R")'` | no, Wave 0 [VERIFIED: no pkgdown/site test file found] |
| BUILD-01 | Local/pkgdown build command completes or emits classified optional dependency outcome | integration/manual plus generated-file smoke | `rtk Rscript -e 'pkgdown::build_site_github_pages(new_process = FALSE, install = FALSE)'` | command exists [VERIFIED: local R probe] |
| BUILD-02 | Article contains htmlwidget scaffolding and assets | generated HTML smoke | `rtk Rscript -e 'testthat::test_file("tests/testthat/test-pkgdown-site.R")'` | no, Wave 0 [VERIFIED: no pkgdown/site test file found] |
| BUILD-03 | sf example renders or visible classified skip/failure appears | generated article smoke | `rtk Rscript -e 'testthat::test_file("tests/testthat/test-pkgdown-site.R")'` | no, Wave 0 [VERIFIED: no pkgdown/site test file found] |

### Sampling Rate

- **Per task commit:** Run focused text/HTML probes or `testthat::test_file("tests/testthat/test-pkgdown-site.R")` once added. [VERIFIED: local test infrastructure]
- **Per wave merge:** Run `devtools::test()` plus the pkgdown build command if source docs or build config changed. [VERIFIED: AGENTS.md; .github/workflows/pkgdown.yaml]
- **Phase gate:** Regenerate docs/site and verify generated text markers, widget divs, dependency assets, and visible sf render/skip/failure classification. [VERIFIED: .planning/REQUIREMENTS.md; 56-CONTEXT.md]

### Wave 0 Gaps

- [ ] `tests/testthat/test-pkgdown-site.R` or equivalent script-level smoke checks for DOCS-01/DOCS-02/BUILD-02/BUILD-03 generated artifacts. [VERIFIED: no existing pkgdown/site test file found]
- [ ] A visible sf optional-dependency marker in `vignettes/gg2d3.Rmd` generated output. [VERIFIED: current chunk silently uses `eval = ...`]
- [ ] Decide whether focused generated-site checks belong in Phase 56 or wait for Phase 57; Phase 56 still needs manual/evidence inspection if automated gate is deferred. [VERIFIED: ROADMAP.md; 56-CONTEXT.md]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | no | Static docs/site build has no authentication surface. [VERIFIED: phase scope; _pkgdown.yml] |
| V3 Session Management | no | Static docs/site build has no session state. [VERIFIED: phase scope; _pkgdown.yml] |
| V4 Access Control | no | Generated docs are public release artifacts. [VERIFIED: .planning/PROJECT.md; _pkgdown.yml URL] |
| V5 Input Validation | yes | Treat generated-site probes as file/content checks; do not execute untrusted generated HTML. [ASSUMED] |
| V6 Cryptography | no | Phase does not add cryptography. [VERIFIED: phase scope] |

### Known Threat Patterns for pkgdown/htmlwidgets Docs

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Publishing stale or misleading support claims | Tampering/Repudiation | Source-first regeneration plus generated-page marker checks. [VERIFIED: .planning/REQUIREMENTS.md; 56-CONTEXT.md] |
| Raw browser logs or large artifacts committed into docs | Information Disclosure | Keep browser visual smoke artifacts under ignored paths and summarize evidence in docs. [VERIFIED: NEWS.md; vignettes/d3-drawing-diagnostics.md] |
| Manual generated HTML edits | Tampering | Regenerate via pkgdown and inspect output rather than editing `docs/` by hand. [VERIFIED: 56-CONTEXT.md] |

## Sources

### Primary (HIGH confidence)

- `.planning/phases/56-pkgdown-content-and-widget-build-contract/56-CONTEXT.md` - phase boundary, decisions, deferred scope. [VERIFIED: local file]
- `.planning/REQUIREMENTS.md` - DOCS/BUILD requirements and traceability. [VERIFIED: local file]
- `.planning/ROADMAP.md` - phase goal and success criteria. [VERIFIED: local file]
- `.planning/STATE.md` and `.planning/PROJECT.md` - milestone state and generated-site release-surface decision. [VERIFIED: local files]
- `AGENTS.md` and `/Users/davidzenz/.codex/RTK.md` - project commands, architecture, and `rtk` shell rule. [VERIFIED: local files]
- `_pkgdown.yml`, `.github/workflows/pkgdown.yaml`, `DESCRIPTION`, `vignettes/gg2d3.Rmd`, `README.Rmd`, `NEWS.md`, `R/gg2d3.R`, `R/sf_utils.R`, `inst/htmlwidgets/gg2d3.yaml`, `docs/articles/gg2d3.html`, `docs/articles/gg2d3.md`, `docs/reference/*.html`, `docs/news/index.html` - local implementation state. [VERIFIED: local files]
- pkgdown 2.2.0 reference for `build_site()` behavior and site destination/development process: https://pkgdown.r-lib.org/reference/build_site.html [CITED: official docs]
- htmlwidgets creating widgets guide: https://www.htmlwidgets.org/develop_intro.html [CITED: official docs]
- knitr options reference: https://yihui.org/knitr/options/ [CITED: official docs]
- r-lib/actions README: https://github.com/r-lib/actions [CITED: official GitHub]

### Secondary (MEDIUM confidence)

- Local R package/version probes for installed tools and dependency availability. [VERIFIED: local R probes]

### Tertiary (LOW confidence)

- None beyond the assumptions listed in the Assumptions Log. [VERIFIED: this document]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - existing project stack and local installed versions are verified; pkgdown/htmlwidgets behavior is checked against official docs. [VERIFIED: local R probes; CITED: official docs]
- Architecture: HIGH - phase is local source/build/docs alignment with clear existing files and workflow. [VERIFIED: local files; 56-CONTEXT.md]
- Pitfalls: HIGH for stale site and silent chunk behavior; MEDIUM for CI dependency route until a live workflow log confirms `needs: website` installs `sf`. [VERIFIED: local probes; ASSUMED for CI route uncertainty]

**Research date:** 2026-05-31 [VERIFIED: local context]
**Valid until:** 2026-06-30 for local project architecture; re-check official pkgdown/r-lib/actions docs before changing CI semantics. [ASSUMED]
