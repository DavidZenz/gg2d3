# Phase 52: CI Visual Regression Foundation - Context

**Gathered:** 2026-05-27
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 52 turns the v1.12 opt-in browser visual smoke harness into CI-safe regression confidence. It should add a dedicated CI path for browser visual smoke, preserve local opt-in and skip semantics, upload inspectable artifacts, and gate on stable DOM/report/browser-log invariants before any pixel-diff or committed-golden workflow exists.

This phase does not introduce mandatory pixel thresholds, committed screenshots, renderer architecture refactors, or new geometry support. Later v1.13 phases cover renderer/IR contracts, geometry polish, and release documentation.

</domain>

<decisions>
## Implementation Decisions

### CI Run Shape
- **D-01:** Add a dedicated GitHub Actions workflow for browser visual smoke rather than folding it into the existing pkgdown workflow.
- **D-02:** Run the workflow on pull requests and `workflow_dispatch`.
- **D-03:** Preserve opt-in semantics for normal local/package test runs. The dedicated CI workflow should explicitly set `GG2D3_BROWSER_VISUAL_SMOKE=true`.
- **D-04:** Treat Chromium/chromote launch failure as a failure in the dedicated CI workflow, while preserving skip behavior for local/default runs.

### Artifact Policy
- **D-05:** Upload the browser visual artifact bundle on every visual-smoke CI run while the workflow stabilizes.
- **D-06:** Use the whole `test_output/browser-visual-smoke/` directory as the canonical artifact bundle, including fixture HTML, PNG screenshots, DOM summaries, browser logs, `index.html`, and `index.json`.
- **D-07:** Enrich the report/index with CI metadata such as run type, commit SHA, browser path/version if available, and environment flags that affect skip/run behavior.
- **D-08:** Keep deterministic paths under `test_output/browser-visual-smoke/`; let CI upload that directory unchanged instead of introducing a second output root.

### Non-Pixel Gate Rules
- **D-09:** Fail the visual-smoke CI gate for missing expected DOM marks, missing artifact files, runtime browser errors, or malformed report rows.
- **D-10:** Keep fixture DOM assertions as stable minimum-count checks using the existing fixture `expected` selector contract. Do not require exact full-DOM counts.
- **D-11:** Do not compare screenshots automatically in Phase 52. Screenshots are inspection evidence only.
- **D-12:** Require `index.json` rows to have stable id/category/status fields, expected artifact links, skip/failure reasons when applicable, and no silent empty fixture rows.

### Browser and Optional Dependency Policy
- **D-13:** CI should use an Ubuntu GitHub Actions runner with installed Chromium/Chrome exposed to `chromote`; set `CHROMOTE_CHROME` only if needed.
- **D-14:** Document `CHROMOTE_CHROME` as a troubleshooting override for local and CI diagnosis, not as the default path.
- **D-15:** Try to make `sf` and `geojsonsf` available through normal R dependency setup if the package Suggests/system dependency path is reasonable. If not, explicit spatial fixture skip rows are acceptable.
- **D-16:** Browser-level skips should fail in the dedicated CI workflow. Optional spatial fixture skips may pass only when they are explicit in the generated report.

### the agent's Discretion
- Exact workflow filename, artifact retention period, report metadata field names, browser version probing implementation, and whether CI-specific assertions live in the test file or helper functions are left to planning and implementation.
- The planner may add a small helper/report validator if that keeps the CI assertions clearer than embedding all checks in the main fixture loop.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and phase scope
- `.planning/ROADMAP.md` — Phase 52 goal, dependency, requirements, and success criteria.
- `.planning/REQUIREMENTS.md` — CI-01, CI-02, and CI-03 acceptance scope.
- `.planning/PROJECT.md` — v1.13 milestone context, validation priorities, constraints, and prior decisions.
- `.planning/STATE.md` — Current project position and milestone continuity.

### Prior browser visual foundation
- `.planning/milestones/v1.12-phases/48-browser-visual-smoke-coverage/48-CONTEXT.md` — Locked v1.12 decisions for artifact contract, fixture coverage, opt-in behavior, and failure evidence.
- `.planning/milestones/v1.12-phases/48-browser-visual-smoke-coverage/48-VERIFICATION.md` — Verified Phase 48 outcomes, browser-available command evidence, artifact contract, and known local skip behavior.
- `.planning/milestones/v1.12-phases/48-browser-visual-smoke-coverage/48-VALIDATION.md` — Phase 48 validation commands and feedback cadence.

### Existing browser visual implementation
- `tests/testthat/helper-browser-visual.R` — Current artifact paths, dependency gates, chromote launch probing, DOM summaries, browser logs, screenshots, and index writer.
- `tests/testthat/test-browser-visual-smoke.R` — Current fixture matrix, expected selector contract, opt-in runner, and generated report assertions.
- `vignettes/d3-drawing-diagnostics.md` — Maintainer-facing browser visual smoke commands, artifact locations, coverage, and skip semantics.
- `.github/workflows/pkgdown.yaml` — Existing GitHub Actions style and separation point; Phase 52 should add a dedicated workflow rather than overloading this one.
- `.gitignore` — Generated `test_output/` artifact boundary.
- `.Rbuildignore` — Package-build exclusion for generated browser visual artifacts.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `browser_visual_artifact_dir()` already writes deterministic output under `test_output/browser-visual-smoke/`.
- `browser_visual_paths()` already defines per-fixture HTML, PNG, DOM summary, and browser-log artifact names from sanitized fixture ids.
- `skip_browser_visual_smoke()` already captures local opt-in, CRAN, `chromote`, Chrome/Chromium discovery, and chromote launch skip semantics.
- `browser_visual_optional_dependencies()` already supports explicit `sf` and `geojsonsf` availability checks and skip messages.
- `capture_browser_visual_fixture()` already saves the widget, opens it in chromote, waits for SVG, evaluates DOM summary, checks expected selectors, records browser errors, writes artifacts, and returns report rows.
- `write_browser_visual_index()` already writes `index.json` and `index.html`, which can be extended with CI metadata and stronger row validation.

### Established Patterns
- Browser validation is optional in ordinary local/package test flows and becomes active only with `GG2D3_BROWSER_VISUAL_SMOKE=true`.
- Generated artifacts stay ignored under `test_output/` and are excluded from package builds.
- Browser visual fixtures use stable minimum expected selector counts rather than exact DOM snapshots.
- Screenshots and HTML are inspection evidence; they are not golden references.
- Existing GitHub Actions configuration is limited to pkgdown/site publishing, so a separate visual-smoke workflow keeps release documentation publishing independent from browser regression checks.

### Integration Points
- Add or extend helper behavior in `tests/testthat/helper-browser-visual.R` for CI metadata, stricter report row validation, and CI/browser skip handling.
- Extend `tests/testthat/test-browser-visual-smoke.R` to assert the Phase 52 report/index guarantees without weakening local skip behavior.
- Add a dedicated workflow under `.github/workflows/` for PR and manual browser visual smoke runs.
- Update `vignettes/d3-drawing-diagnostics.md` with CI artifact inspection guidance and `CHROMOTE_CHROME` troubleshooting notes.

</code_context>

<specifics>
## Specific Ideas

- Keep the CI artifact shape boring and inspectable: upload `test_output/browser-visual-smoke/` unchanged.
- CI should prove the browser path actually works; local environments can still skip explicitly.
- The first CI regression gate should be structural and log-based. Pixel thresholds remain deferred until artifacts prove stable across CI runs.

</specifics>

<deferred>
## Deferred Ideas

- Committed golden screenshots and pixel-diff thresholds remain future work after CI artifact stability is proven.
- Hosted public visual reports for pull requests remain a future requirement if GitHub Actions artifacts are not ergonomic enough.
- Broad renderer/IR source-of-truth work belongs to Phase 53.
- Geometry support changes belong to Phase 54.

</deferred>

---

*Phase: 52-ci-visual-regression-foundation*
*Context gathered: 2026-05-27*
