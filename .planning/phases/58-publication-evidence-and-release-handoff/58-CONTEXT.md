# Phase 58: Publication Evidence And Release Handoff - Context

**Gathered:** 2026-06-01
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 58 proves that the pkgdown/GitHub Pages publication surface can be inspected as release evidence. It should make the workflow output, downloadable or checkoutable generated site, deployed GitHub Pages output, and release-readiness handoff line up with the source/generated-site validation established in Phases 56 and 57.

This phase does not add new renderer support, replace pkgdown or GitHub Pages, introduce public PR previews, add screenshot or perceptual regression gates, or add external uptime monitoring.

</domain>

<decisions>
## Implementation Decisions

### Artifact Target

- **D-01:** Inspect both workflow/build evidence and deployed publication output when available.
- **D-02:** Prefer deterministic evidence that can be downloaded or checked out, such as a workflow artifact, run output, or `gh-pages` branch contents, over only eyeballing the GitHub UI.
- **D-03:** Treat the deployed GitHub Pages URL or deploy branch as publication proof. If network access, GitHub auth, or deployment timing prevents inspection, record the exact blocker and the fallback evidence that was used.

### Trigger And Retrieval Flow

- **D-04:** Use the `gh` CLI as the primary maintainer path for triggering, inspecting, polling, and downloading pkgdown workflow output.
- **D-05:** Document a manual GitHub Actions UI and deployed-site fallback for maintainers who do not have an authenticated `gh` session.
- **D-06:** Classify `gh` auth or permission failures as setup/manual-action gates, not generated-site validation failures.

### Evidence Bundle

- **D-07:** Commit concise release-readiness evidence in Phase 58 verification and handoff documentation. Record commands, run IDs, artifact/deploy paths, validation outcomes, and residual risks.
- **D-08:** Do not commit bulky downloaded artifacts, raw workflow logs, browser logs, DOM dumps, screenshot bundles, or generated artifact directories. Local downloaded artifacts may live under ignored inspection paths such as `test_output/github-run-*`.
- **D-09:** Final validation must map the v1.14 documentation/build/site requirements to source docs, generated `docs/`, workflow/artifact evidence, deployed output when available, browser visual smoke evidence, optional-skip classifications, and package-check outcomes.

### Release Messaging

- **D-10:** NEWS or release handoff wording should describe publication-surface validation and release-handoff hardening only.
- **D-11:** Do not imply new `geom_sf()`, annotation, widget, or renderer support. Claim rendered sf publication evidence only when a workflow artifact or deployed output proves it.
- **D-12:** If local or CI spatial dependencies are unavailable, report the visible skip or setup classification separately from stale-site/content failures.

### Agent Discretion

- The planner may choose exact script names, documentation locations, and command flags as long as they reuse the Phase 57 generated-site validation contract where practical.
- The planner may decide whether artifact inspection is implemented as a small helper script, a documented `gh` command sequence, or both, provided the release handoff remains repeatable.
- The planner may choose how to summarize requirement mapping, but raw logs and bulky artifacts should stay out of committed documentation.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone Scope

- `.planning/ROADMAP.md` - Phase 58 goal, success criteria, and dependency on Phase 57.
- `.planning/REQUIREMENTS.md` - SITE-02 and SITE-03 requirements plus future boundaries for PR previews, screenshot/perceptual regression, and uptime monitoring.
- `.planning/PROJECT.md` - Current milestone context for pkgdown/GitHub Pages as release surfaces.
- `.planning/STATE.md` - Current focus, accumulated decisions, and Phase 56/57 completion notes.

### Prior Phase Decisions

- `.planning/phases/56-pkgdown-content-and-widget-build-contract/56-CONTEXT.md` - Source/generated/GitHub Pages/browser visual smoke artifact taxonomy.
- `.planning/phases/56-pkgdown-content-and-widget-build-contract/56-VERIFICATION.md` - Generated-site evidence, local sf outcome, and Phase 56 validation notes.
- `.planning/phases/57-generated-site-validation-gate/57-CONTEXT.md` - Generated-site gate decisions and explicit Phase 58 boundary for deploy artifact inspection.
- `.planning/phases/57-generated-site-validation-gate/57-VERIFICATION.md` - Commands and outcomes for the quick/release/CI generated-site validation gate.
- `.planning/phases/57-generated-site-validation-gate/57-03-SUMMARY.md` - Final Phase 57 handoff and residual GitHub Pages artifact scope.

### Workflow And Validation Assets

- `.github/workflows/pkgdown.yaml` - `workflow_dispatch`, website dependency evidence, pkgdown build, CI validation, and `gh-pages` deploy route.
- `tools/validate-pkgdown-site.R` - Quick/release/CI generated-site validation command to reuse for publication evidence where practical.
- `tests/testthat/helper-pkgdown-site.R` - Shared marker, asset, and sf outcome validation helpers.
- `tests/testthat/test-pkgdown-site.R` - Canonical testthat coverage for generated pkgdown site evidence.
- `_pkgdown.yml` - pkgdown site configuration, URL, and reference index.

### Documentation And Release Surfaces

- `README.Rmd` - Source documentation pointer for artifact taxonomy and release validation.
- `README.md` - Generated README evidence.
- `vignettes/d3-drawing-diagnostics.md` - Maintainer-facing validation commands, artifact taxonomy, failure classes, and Phase 58 boundary.
- `vignettes/gg2d3.Rmd` - Source article with current sf support and optional dependency behavior.
- `NEWS.md` - Release-note wording that must avoid claiming new rendering support.
- `docs/articles/gg2d3.html` - Generated article HTML markers/widgets.
- `docs/articles/gg2d3.md` - Generated article text snapshot.
- `docs/articles/gg2d3_files/gg2d3-modules-0.0.1` - Article-local widget dependency evidence.
- `docs/news/index.html` - Generated NEWS evidence.
- `docs/reference/gg2d3.html` - Generated main reference evidence.
- `docs/reference/extract_sf_geometries.html` - Generated sf helper reference evidence.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `.github/workflows/pkgdown.yaml` already supports `workflow_dispatch`, builds the pkgdown site, validates generated output before deploy, and deploys `docs` to `gh-pages` for non-pull-request events.
- `tools/validate-pkgdown-site.R` already provides quick, release, and CI modes with a concise final outcome line.
- `tests/testthat/helper-pkgdown-site.R` can validate current support text, widget containers, dependency assets, NEWS/reference pages, and rendered-or-classified sf outcomes.
- `vignettes/d3-drawing-diagnostics.md` already explains quick/release/CI validation and can be extended with artifact/deploy inspection and handoff guidance.
- `NEWS.md` already frames the v1.14 work as publication-surface evidence without implying new rendering support.

### Established Patterns

- Source-first docs remain the authoring model; generated `docs/` and GitHub Pages output are evidence surfaces.
- Optional spatial dependency skips are acceptable only when visible and classified.
- Browser visual smoke artifacts and pkgdown artifacts answer different release-readiness questions and should stay distinct.
- Planning/verification docs should summarize evidence, not embed raw logs or bulky artifacts.

### Integration Points

- GitHub Actions inspection: `gh workflow run pkgdown.yaml`, `gh run list`, `gh run view`, and `gh run download` are the likely command family for triggering and retrieving workflow evidence.
- Deploy inspection: `gh-pages` branch contents or the configured GitHub Pages URL should be checked for the same current sf/widget markers as the generated-site gate.
- Release handoff: Phase 58 verification should tie pkgdown source/build/deploy evidence to package tests, generated help, browser visual smoke, optional skip classifications, and package-check outcomes.

</code_context>

<specifics>
## Specific Ideas

- If a downloaded workflow artifact has a nested site root, the implementation may need a small locator that finds the generated `docs` root before applying marker checks.
- If the workflow does not upload a separate artifact, `gh run view --log` plus `gh-pages` branch inspection may be the practical proof path, but the handoff should make that explicit.
- A useful maintainer flow is: trigger or locate latest `pkgdown.yaml` run, confirm dependency and validation steps, download or inspect output, validate the site evidence, then record run/deploy identifiers in the release handoff.

</specifics>

<deferred>
## Deferred Ideas

- Public pull-request preview links for pkgdown sites remain future work.
- Screenshot or perceptual regression coverage for pkgdown article pages remains future work.
- External uptime or freshness monitoring for the published GitHub Pages URL remains future work.
- New renderer, `geom_sf()`, annotation, or widget behavior remains out of scope for this publication evidence phase.

</deferred>

---

*Phase: 58-publication-evidence-and-release-handoff*
*Context gathered: 2026-06-01*
