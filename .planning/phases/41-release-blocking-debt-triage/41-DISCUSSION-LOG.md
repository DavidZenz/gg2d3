# Phase 41: Release-Blocking Debt Triage - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md -- this log preserves the alternatives considered.

**Date:** 2026-05-23
**Phase:** 41-release-blocking-debt-triage
**Areas discussed:** advisory follow-ups, ordinary geom_polygon debt, rect/tile out-of-bounds behavior, debt audit artifact

---

## Advisory Follow-ups

| Option | Description | Selected |
|--------|-------------|----------|
| Verify and classify resolved | Treat Phase 40 dependency declarations and current facet panel identity assertions as resolved if verification passes. | yes |
| Add more behavior work | Add new tests or implementation changes even if current evidence already satisfies the advisory. | |
| Defer without verification | Document as non-blocking without re-checking current repo state. | |

**User's choice:** recommendations are fine
**Notes:** Current scout found no Phase 41 todos. `tests/testthat/test-sf-browser.R` compares facet panel counts in panel order for wrap and grid fixtures.

---

## Ordinary geom_polygon Debt

| Option | Description | Selected |
|--------|-------------|----------|
| Implement ordinary polygon renderer | Expand Phase 41 into new ordinary `geom_polygon()` support. | |
| Clarify/defer support contract | Avoid new feature scope; reconcile stale references and document ordinary polygon support as deferred if still unsupported. | yes |
| Ignore until later | Leave support-table and unsupported-vignette contradiction unresolved. | |

**User's choice:** recommendations are fine
**Notes:** Phase 41 should distinguish ordinary `geom_polygon()` from already-supported `geom_sf()` polygon-family rendering.

---

## Rect/Tile Out-of-Bounds Behavior

| Option | Description | Selected |
|--------|-------------|----------|
| Fix only if low-risk | Characterize first; fix only if clearly small and release-blocking. | yes |
| Force a renderer rewrite | Treat out-of-bounds rect/tile behavior as mandatory implementation work. | |
| Docs-only defer | Document the issue without checking whether a small fix is available. | |

**User's choice:** recommendations are fine
**Notes:** Existing diagnostics already mention the edge case. Planning should decide whether a targeted characterization or low-risk fix is appropriate.

---

## Debt Audit Artifact

| Option | Description | Selected |
|--------|-------------|----------|
| Create dedicated audit artifact | Record each debt item with evidence, status, rationale, and next step. | yes |
| Rely on commits/tests only | Let implementation history carry the rationale. | |
| Split by item only | Store rationale only inside individual plan outputs. | |

**User's choice:** recommendations are fine
**Notes:** A single release-reviewable artifact best satisfies the Phase 41 requirement that deferred debt has explicit rationale.

---

## The Agent's Discretion

- User delegated all four gray-area choices to the recommended defaults.
- Agent should choose narrow verification and documentation-first actions during planning unless code evidence proves a release blocker.

## Deferred Ideas

- New ordinary `geom_polygon()` renderer implementation.
- Broad rect/tile clipping or scale-bound renderer rewrites.
