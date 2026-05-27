# Phase 48: Browser Visual Smoke Coverage - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md -- this log preserves the alternatives considered.

**Date:** 2026-05-25
**Phase:** 48-browser-visual-smoke-coverage
**Areas discussed:** Artifact contract, Fixture coverage set, Run and skip policy, Failure evidence

---

## Artifact Contract

| Option | Description | Selected |
|--------|-------------|----------|
| Screenshots only | Adds the missing visual artifact but leaves diagnosis to reruns or existing logs. | |
| Screenshots plus HTML/logs and index | Screenshots provide visual evidence; HTML/logs support debugging; index links artifacts together. | yes |
| Full report with richer metadata | More complete, but risks overbuilding the first local smoke layer. | |

**User's choice:** Recommendations are fine.
**Captured decision:** Produce screenshots plus HTML/logs, with a small generated local index/report.

---

## Fixture Coverage Set

| Option | Description | Selected |
|--------|-------------|----------|
| Minimal critical surfaces | Fastest path, but may miss recent geometry surfaces. | |
| Representative v1.12 matrix | Covers core Cartesian, facets, interactivity-facing marks, sf marks, ordinary polygon, and sf annotations without becoming exhaustive. | yes |
| Broad historical coverage | Highest coverage, but too much fixture maintenance for the first screenshot layer. | |

**User's choice:** Recommendations are fine.
**Captured decision:** Use a representative matrix across core rendering surfaces and recent geometry additions.

---

## Run And Skip Policy

| Option | Description | Selected |
|--------|-------------|----------|
| Explicit maintainer command plus opt-in testthat path | Keeps normal tests skip-friendly while giving maintainers a deliberate visual smoke entrypoint. | yes |
| Testthat only | Simple to discover but can blur normal tests with optional browser dependencies. | |
| Standalone script only | Clear maintainer command, but misses integration with existing test helpers. | |

**User's choice:** Recommendations are fine.
**Captured decision:** Provide an explicit maintainer command and optional testthat path gated by an environment variable.

---

## Failure Evidence

| Option | Description | Selected |
|--------|-------------|----------|
| Screenshot and browser log | Useful but may be insufficient for DOM structure issues. | |
| Screenshot, HTML copy, browser log, and DOM summary | Enough evidence to inspect visual output, runtime errors, and missing/misplaced marks. | yes |
| All artifacts plus pixel diff metadata | Better for future CI, too heavy before stable local artifacts exist. | |

**User's choice:** Recommendations are fine.
**Captured decision:** Write screenshot, copied HTML, browser log, and DOM summary on failure where feasible.

---

## the agent's Discretion

- Exact command spelling, helper names, fixture filenames, index/report format, screenshot size, and DOM summary schema.
- Whether to extend existing sf/polygon browser helpers directly or introduce shared browser visual helpers.

## Deferred Ideas

- CI-enforced screenshot diffs.
- Committed reference images or golden-image thresholds.
- Renderer refactors and geometry fixes, which belong to later v1.12 phases.
