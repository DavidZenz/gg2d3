# Phase 59: Release Hygiene And Local Spatial Recovery - Context

**Gathered:** 2026-06-02
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 59 resolves or explicitly mitigates release-readiness advisories and makes local spatial validation repairable. The phase covers GitHub Actions runtime advisory handling, local `sf`/GDAL diagnostics and recovery guidance, and Phase 59 release-gate evidence. It must keep pkgdown and browser visual workflows passing or explicitly classified after hygiene changes.

This phase does not deepen pkgdown screenshot/widget-region visual regression coverage; that remains Phase 60.

</domain>

<decisions>
## Implementation Decisions

### Actions Advisory Handling
- **D-01:** Audit both workflow files for runtime advisory sources and update stale actions where a newer stable version exists.
- **D-02:** If a GitHub Actions advisory persists while the workflow uses the latest stable viable action, document it as upstream-known advisory noise with a tested green workflow outcome instead of blocking indefinitely.
- **D-03:** Keep workflow changes narrow. Do not redesign the pkgdown or browser visual workflows just to chase an advisory.

### Local `sf`/GDAL Recovery
- **D-04:** Add maintainer-facing diagnostics and repair guidance for local `sf`/GDAL dynamic-library failures.
- **D-05:** Include a small maintainer command or script that reports whether `sf` and `geojsonsf` are loadable, so maintainers can distinguish local spatial stack breakage from package/runtime regressions.
- **D-06:** Do not attempt to repair this machine's Homebrew/R spatial environment as part of the phase unless the user explicitly asks later. The deliverable is repeatable diagnosis and guidance.

### Release Gate Evidence
- **D-07:** Preserve the existing focused validation commands instead of adding one combined release-hygiene gate command.
- **D-08:** Add a concise Phase 59 verification ledger tying together workflow advisory outcome, local spatial diagnostic outcome, pkgdown validation, browser visual smoke behavior, and residual risks.
- **D-09:** Evidence should classify local `sf` as `rendered`, `classified_skip`, or a diagnosed local environment failure using the existing generated-site semantics.

### Phase 59 / Phase 60 Boundary
- **D-10:** Phase 59 should only prove the existing pkgdown and browser visual workflows still pass or classify skips explicitly after release-hygiene changes.
- **D-11:** Representative screenshots, blank/stale widget-region detection, and deeper pkgdown visual evidence are deferred to Phase 60.

### the agent's Discretion
- The agent may choose the exact shape of the `sf`/GDAL diagnostic command or script, provided it is lightweight, maintainer-friendly, and reuses existing package/site helper patterns where practical.
- The agent may decide whether advisory mitigation belongs in workflow YAML, maintainer documentation, verification evidence, or a combination, as long as the outcome is testable and clearly recorded.
- The agent may choose the verification ledger filename and format, matching existing phase verification conventions.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Scope And Release Constraints
- `.planning/ROADMAP.md` - Phase 59 goal, requirements, success criteria, and planned plan breakdown.
- `.planning/REQUIREMENTS.md` - `REL-01` and `REL-02` requirements for advisory mitigation and local spatial recovery.
- `.planning/PROJECT.md` - Current milestone context, known local `sf`/GDAL issue, and GitHub Actions advisory carry-forward.
- `.planning/STATE.md` - Current blocker/concern notes and v1.14 handoff evidence.
- `.planning/MILESTONES.md` - v1.14 closeout risks, including local `sf`/GDAL skip and upload-artifact advisory.

### Workflow Surfaces
- `.github/workflows/pkgdown.yaml` - Pkgdown build, dependency verification, artifact upload, and GitHub Pages deploy workflow.
- `.github/workflows/browser-visual-smoke.yaml` - Dedicated browser visual smoke workflow and artifact upload.

### Pkgdown And Publication Validation
- `tools/validate-pkgdown-site.R` - Local/release/CI generated-site validation entrypoint.
- `tools/inspect-pkgdown-publication.R` - Downloaded/generated publication artifact inspection entrypoint.
- `tests/testthat/helper-pkgdown-site.R` - Shared helper functions for `sf`/Crosstalk outcome classification and publication validation.
- `tests/testthat/test-pkgdown-site.R` - Focused pkgdown/site validation tests.
- `vignettes/d3-drawing-diagnostics.md` - Existing diagnostics documentation for generated-site validation and optional dependency outcomes.
- `vignettes/gg2d3.Rmd` - Source article that emits rendered `geom_sf()` examples or visible optional spatial skips.

### Prior Evidence
- `.planning/milestones/v1.14-phases/56-pkgdown-content-and-widget-build-contract/56-VERIFICATION.md` - Initial local classified-skip evidence and package/site build behavior.
- `.planning/milestones/v1.14-phases/57-generated-site-validation-gate/57-VERIFICATION.md` - Generated-site validation evidence and local `sf` classified skip.
- `.planning/milestones/v1.14-phases/58-publication-evidence-and-release-handoff/58-VERIFICATION.md` - Final v1.14 local/artifact outcomes, including rendered CI sf evidence and residual local spatial risk.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `pkgdown_site_spatial_loadable()` in `tests/testthat/helper-pkgdown-site.R` already checks whether `sf` and `geojsonsf` can load.
- `pkgdown_site_sf_outcome()` and `pkgdown_site_expect_sf_outcome()` already classify site output as `rendered`, `classified_skip`, or `missing`.
- `tools/validate-pkgdown-site.R` already exposes quick/release/CI modes and can be extended or referenced for release-hygiene evidence.
- `tools/inspect-pkgdown-publication.R` already supports `--require-rendered-sf true|false|auto` for downloaded artifacts or generated site roots.

### Established Patterns
- Optional spatial dependencies remain optional; failures must be visible and classified rather than silently disappearing.
- Local validation may accept `classified_skip` when the local spatial stack is unavailable; CI or an environment with loadable spatial packages can provide rendered sf evidence.
- Browser visual smoke is an opt-in local path and a dedicated CI workflow path; browser-level unavailability should be explicit rather than silently skipped in CI mode.
- Phase verification ledgers summarize command outcomes and residual risks without pasting raw logs.

### Integration Points
- Workflow advisory mitigation touches `.github/workflows/pkgdown.yaml` and `.github/workflows/browser-visual-smoke.yaml`.
- Spatial diagnostics should reuse or align with `tests/testthat/helper-pkgdown-site.R` and the `tools/` entrypoint style.
- Maintainer guidance belongs in `vignettes/d3-drawing-diagnostics.md` and any generated docs that flow from it, with source-first documentation preserved.
- Phase evidence should connect to existing validation commands and the Phase 59 planning directory.

</code_context>

<specifics>
## Specific Ideas

- Prefer narrow workflow updates plus documented mitigation over broad CI redesign.
- Prefer a diagnostic/status command for local spatial loadability rather than attempting to mutate the developer machine.
- Keep Phase 59 focused on release hygiene; leave deeper screenshot and widget-region regression checks to Phase 60.

</specifics>

<deferred>
## Deferred Ideas

- Pkgdown page screenshots, blank widget detection, stale widget-region checks, and broader visual artifact depth are deferred to Phase 60.
- External uptime/freshness monitoring for the public pkgdown site remains future work beyond v1.15 unless later promoted.

</deferred>

---

*Phase: 59-release-hygiene-and-local-spatial-recovery*
*Context gathered: 2026-06-02*
