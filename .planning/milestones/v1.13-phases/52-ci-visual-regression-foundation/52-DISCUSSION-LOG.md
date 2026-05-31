# Phase 52: CI Visual Regression Foundation - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-27
**Phase:** 52-CI Visual Regression Foundation
**Areas discussed:** CI run shape, Artifact policy, Non-pixel gate rules, Browser and optional dependency policy

---

## CI run shape

| Option | Description | Selected |
|--------|-------------|----------|
| Dedicated GitHub Actions workflow | Separate browser visual smoke from pkgdown/site publishing | yes |
| Existing pkgdown workflow | Add browser visual smoke to `.github/workflows/pkgdown.yaml` | |
| Local CI-equivalent only | Document the command without wiring GitHub Actions yet | |

**User's choice:** Recommendations are fine.
**Notes:** The recommended defaults were accepted: a dedicated workflow runs on pull requests and `workflow_dispatch`; CI explicitly opts in with `GG2D3_BROWSER_VISUAL_SMOKE=true`; browser launch failures fail the dedicated CI workflow but remain local skips.

---

## Artifact policy

| Option | Description | Selected |
|--------|-------------|----------|
| Upload full bundle always | Upload the whole `test_output/browser-visual-smoke/` directory on every visual-smoke CI run | yes |
| Failure-only upload | Upload artifacts only when the CI check fails | |
| Failure/manual upload | Upload artifacts only for failures and manually-triggered runs | |

**User's choice:** Recommendations are fine.
**Notes:** The recommended defaults were accepted: preserve HTML, PNG screenshots, DOM summaries, browser logs, `index.html`, and `index.json`; add CI metadata; keep deterministic output under `test_output/browser-visual-smoke/`.

---

## Non-pixel gate rules

| Option | Description | Selected |
|--------|-------------|----------|
| Structural/browser-log gate | Fail on missing expected marks, missing artifacts, runtime browser errors, or malformed report rows | yes |
| Narrow gate | Fail only on runtime browser errors and missing screenshots | |
| Existing assertions only | Rely only on current testthat assertions | |

**User's choice:** Recommendations are fine.
**Notes:** The recommended defaults were accepted: use stable minimum-count selector checks; keep screenshots as evidence only; make `index.json` structured enough to catch bad links, empty rows, missing reasons, and selector drift.

---

## Browser and optional dependency policy

| Option | Description | Selected |
|--------|-------------|----------|
| CI browser must work, spatial skips allowed if explicit | Install/use Chromium for chromote; document `CHROMOTE_CHROME`; allow explicit `sf`/`geojsonsf` skips if dependency setup is not reasonable | yes |
| Require every optional dependency | Any browser or spatial skip fails CI | |
| Allow all skips | Pass CI as long as skips are recorded | |

**User's choice:** Recommendations are fine.
**Notes:** The recommended defaults were accepted: use Ubuntu GitHub Actions with Chromium/Chrome available to chromote, set `CHROMOTE_CHROME` only if needed, document that override, and distinguish browser-level CI failures from explicit optional spatial fixture skips.

## the agent's Discretion

- Exact workflow filename, artifact retention period, report metadata field names, browser version probing implementation, and helper/test split are left to planning.

## Deferred Ideas

- Pixel thresholds and committed golden screenshots.
- Hosted visual reports for pull requests.
- Renderer/IR contract consolidation and geometry support changes.
