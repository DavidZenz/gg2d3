# Phase 40: Package Hygiene - Context

**Gathered:** 2026-05-22
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 40 delivers package hygiene for the v1.10 release-hardening milestone. It covers dependency metadata, optional dependency skip behavior, and generated artifact paths. It does not fix renderer behavior, create the full release gate, or rewrite documentation broadly; those are Phase 41, Phase 42, and Phase 43 respectively.

</domain>

<decisions>
## Implementation Decisions

### Dependency strictness
- **D-01:** Treat every direct `pkg::fun()` use in package code, tests, helpers, examples, visual checks, vignettes, and documentation generation as requiring an explicit DESCRIPTION declaration unless it is a base/recommended package already available by policy.
- **D-02:** Keep heavy or environment-specific tooling in `Suggests`, not `Imports`, unless runtime package code requires it unconditionally.
- **D-03:** `geojsonsf` remains the runtime requirement for actual `geom_sf()` conversion and should stay declared consistently with how `sf_utils.R` errors when it is unavailable.
- **D-04:** `chromote`, `sf`, `rnaturalearth`, `pkgload`, and `rprojroot` stay optional test/development dependencies; they should be declared directly when referenced, not inherited transitively.

### Optional skip behavior
- **D-05:** Preserve the v1.9 decision to use R/testthat plus optional `chromote`; do not introduce Node, Playwright, Puppeteer, Selenium, or screenshot-diff infrastructure in Phase 40.
- **D-06:** Browser and spatial validation should skip cleanly on CRAN-like runs, missing Chrome/chromote, or missing optional spatial packages, with messages that name the missing dependency or tool.
- **D-07:** Source-level and non-browser tests should remain useful even when live browser execution skips.
- **D-08:** If a dependency is truly needed for normal package functionality rather than optional validation, prefer a clear runtime error or Imports declaration over silently skipping.

### Artifact paths and ignore policy
- **D-09:** Keep the established project-root `test_output/` convention for generated visual/browser HTML artifacts.
- **D-10:** Keep browser-specific logs and fixtures under `test_output/browser-sf/` or another clear subdirectory of `test_output/`; do not scatter generated HTML/log/check artifacts across package source directories.
- **D-11:** Ensure generated local outputs are ignored by git and do not appear in routine `git status` after package tests or smoke runs.
- **D-12:** Preserve actionable failure artifacts for local debugging rather than deleting them automatically.

### Phase 40 triage stance
- **D-13:** Fix hygiene issues when they are mechanical and low-risk in this phase.
- **D-14:** If a discovered issue is behavior-changing or belongs to renderer debt, validation-gate design, or docs/release-note sweep, record it for Phase 41, Phase 42, or Phase 43 instead of expanding Phase 40.
- **D-15:** Prefer small, reviewable commits by hygiene area: dependency metadata, optional skip behavior, and artifact/ignore handling.

### the agent's Discretion
- The planner may decide the exact audit commands and whether to use small helper scripts, `tools::package_dependencies()`, `codetools`, `R CMD check` notes, targeted `rg`, or manual DESCRIPTION comparisons.
- The planner may decide whether path/ignore cleanup belongs in `.gitignore`, `.Rbuildignore`, helper functions, or tests, as long as generated artifacts stay predictable and ignored.
- The planner may split dependency metadata fixes by runtime vs test/helper dependencies if that makes verification cleaner.

</decisions>

<specifics>
## Specific Ideas

- Conservative release-hardening defaults were selected because the interactive question UI was unavailable and project config is in `yolo` mode.
- Phase 36 already identified two advisory hygiene follow-ups: declare direct `pkgload`/`rprojroot` usage and tighten browser facet assertions so panel identity is preserved instead of only sorted count distributions. The dependency part belongs in Phase 40; the facet assertion part is likely Phase 41 unless it is needed to prove artifact or skip behavior.
- Existing v1.9 decisions intentionally avoided Node browser stacks and visual diff tooling; Phase 40 should respect that boundary.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Current milestone scope
- `.planning/ROADMAP.md` — Phase 40 goal, requirements, success criteria, and plan skeleton.
- `.planning/REQUIREMENTS.md` — HYG-01, HYG-02, and HYG-03 acceptance criteria.
- `.planning/PROJECT.md` — Release-hardening milestone intent, constraints, and current package context.

### Prior decisions and evidence
- `.planning/milestones/v1.9-phases/36-browser-sf-smoke-harness/36-CONTEXT.md` — Browser harness decisions: optional `chromote`, R/testthat runner, clean skips, and `test_output/` artifact convention.
- `.planning/milestones/v1.9-phases/36-browser-sf-smoke-harness/36-REVIEW.md` — Advisory follow-ups around direct `pkgload`/`rprojroot` declarations and facet panel identity assertions.
- `.planning/milestones/v1.9-phases/36-browser-sf-smoke-harness/36-PATTERNS.md` — Established dependency metadata and browser artifact patterns.
- `.planning/milestones/v1.9-phases/37-non-polygon-sf-ir-and-renderer/37-VERIFICATION.md` — Notes on live Chrome execution skipping in CRAN-like Rscript context.
- `.planning/milestones/v1.9-phases/38-sf-interaction-facet-and-documentation-hardening/38-VERIFICATION.md` — Notes on browser tests skipping when `chromote`/Chrome is unavailable.

### Package and helper files
- `DESCRIPTION` — Package metadata and dependency declarations.
- `.gitignore` — Ignored local outputs, including `test_output/` and `*.Rcheck/`.
- `.Rbuildignore` — Package build exclusions, if changed by artifact handling.
- `R/sf_utils.R` — Runtime `geojsonsf` and sf helper behavior.
- `tests/testthat/helper-sf-fixtures.R` — Project-root `test_output/` helper and `rprojroot` usage.
- `tests/testthat/helper-browser-sf.R` — Browser skip guards, `chromote` use, and `test_output/browser-sf` artifact handling.
- `tests/testthat/test-sf-browser.R` — Browser smoke behavior and fixture assertions.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `DESCRIPTION`: Already declares `chromote`, `pkgload`, `rprojroot`, `sf`, `geojsonsf`, and `rnaturalearth` in `Suggests`; Phase 40 should verify this is complete against current direct usage rather than assuming the prior advisory is still open.
- `tests/testthat/helper-browser-sf.R`: Centralizes browser skip behavior, `chromote` session setup, console/page-error collection, and `browser_sf_artifact_dir()`.
- `tests/testthat/helper-sf-fixtures.R`: Centralizes sf fixture creation and the project-root `test_output/` convention.
- `.gitignore`: Already ignores `test_output/`, `test_*_files/`, root generated HTML/PNG/PDF, and `*.Rcheck/`.

### Established Patterns
- R package code uses namespace-qualified package calls (`pkg::fun`) rather than broad imports.
- Optional sf/browser tests use `testthat::skip_if_not_installed()` and `skip_on_cran()` instead of hard failures.
- Visual and browser artifacts are intentionally local debugging outputs, not source artifacts.
- Browser validation is DOM/source/assertion oriented, not screenshot-diff based.

### Integration Points
- Dependency metadata changes integrate through `DESCRIPTION`.
- Artifact path changes integrate through helper functions and ignore/build-ignore files.
- Skip behavior changes integrate through `tests/testthat/helper-browser-sf.R`, `tests/testthat/helper-sf-fixtures.R`, and any tests that directly call optional packages.
- Any hygiene audit should inspect `R/`, `tests/testthat/`, `vignettes/`, `README.Rmd`, and visual-check scripts under `tests/testthat/`.

</code_context>

<deferred>
## Deferred Ideas

- Tightening browser facet assertions for panel identity may belong in Phase 41 if it changes test semantics beyond dependency/artifact hygiene.
- Stale `GeomPolygon` references and rect out-of-bounds behavior belong in Phase 41 release-blocking debt triage.
- Full release gate commands and `R CMD check` evidence belong in Phase 42.
- README/vignette/release-note language sweeps belong in Phase 43.
- Screenshot-diff or visual regression infrastructure remains future work beyond v1.10 unless a later phase explicitly scopes it.

</deferred>

---

*Phase: 40-package-hygiene*
*Context gathered: 2026-05-22*
