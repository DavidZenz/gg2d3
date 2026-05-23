# Phase 42: Release Validation Gate - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md -- this log preserves the alternatives considered.

**Date:** 2026-05-23
**Phase:** 42-release-validation-gate
**Areas discussed:** release gate scope, browser smoke behavior, coverage evidence, failure artifacts, repair policy

---

## Release Gate Scope

| Option | Description | Selected |
|--------|-------------|----------|
| Two-tier gate | Define quick local smoke checks plus a full release gate with docs, tests, and package check behavior. | yes |
| Single full command | Require one command to cover every validation concern. | |
| Informal command list | Keep existing development commands without a named release gate. | |

**User's choice:** recommendations are fine
**Notes:** Existing README contributor commands already mention `devtools::document()`, `devtools::load_all()`, and `devtools::test()`, but Phase 42 needs a clearer release gate and package check path.

---

## Browser Smoke Behavior

| Option | Description | Selected |
|--------|-------------|----------|
| Optional with explicit skips | Attempt browser smoke locally when dependencies are present; accept documented skip reasons otherwise. | yes |
| Always required | Fail the release gate whenever Chrome/chromote or spatial tooling is unavailable. | |
| Manual-only | Remove browser smoke from automated release validation. | |

**User's choice:** recommendations are fine
**Notes:** Phase 40 established `skip_browser_sf_smoke()` with CRAN, chromote, sf, geojsonsf, Chrome, and session-launch checks.

---

## Coverage Evidence

| Option | Description | Selected |
|--------|-------------|----------|
| Explicit validation matrix | Map behavior areas to commands, tests, artifacts, and requirements. | yes |
| One-command inference | Let maintainers infer coverage from the full test/check output. | |
| Separate prose only | Describe coverage areas without linking exact files or commands. | |

**User's choice:** recommendations are fine
**Notes:** `test-regression-core.R` and sf/browser tests already provide strong anchors for a matrix covering the Phase 42 success criteria.

---

## Failure Artifacts

| Option | Description | Selected |
|--------|-------------|----------|
| Document ignored artifact paths | Point maintainers to `test_output/`, browser logs, and `*.Rcheck/` output. | yes |
| Standard output only | Rely on terminal output from failing commands. | |
| New artifact root | Create a separate release-output directory outside the existing conventions. | |

**User's choice:** recommendations are fine
**Notes:** Phase 40 already audited generated paths and ignore rules; Phase 42 should reuse those conventions.

---

## Repair Policy

| Option | Description | Selected |
|--------|-------------|----------|
| Fix release blockers only | Repair concrete gate failures; record optional skips and deferred non-blockers. | yes |
| Fix every observed issue | Expand Phase 42 to resolve all validation-adjacent findings. | |
| Document-only | Run the gate but avoid fixes even for release-blocking failures. | |

**User's choice:** recommendations are fine
**Notes:** Phase 41 deferred ordinary `geom_polygon()` rendering and broad rect/tile rewrites as non-blockers; Phase 42 should not reopen those without concrete failing evidence.

---

## The Agent's Discretion

- User delegated all five gray-area choices to the recommended defaults.
- Agent should choose exact command forms, documentation location, and evidence format during planning while preserving the locked decisions above.

## Deferred Ideas

- Screenshot-diff or perceptual visual regression infrastructure.
- Ordinary `geom_polygon()` renderer implementation.
- Broad rect/tile out-of-bounds renderer rewrites.
