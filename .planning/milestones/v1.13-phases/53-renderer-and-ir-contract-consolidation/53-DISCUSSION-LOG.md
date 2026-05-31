# Phase 53: Renderer And IR Contract Consolidation - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md -- this log preserves the alternatives considered.

**Date:** 2026-05-28
**Phase:** 53-renderer-and-ir-contract-consolidation
**Areas discussed:** Geom contract source of truth, Contract strictness, `as_d3_ir()` helper boundary, Regression fixture strategy

---

## Geom Contract Source Of Truth

| Option | Description | Selected |
|--------|-------------|----------|
| Existing internal manifest | Keep `inst/htmlwidgets/modules/geom-contracts.js` as the internal source and strengthen validation around it. | yes |
| Generated/shared manifest | Introduce a generated or cross-language manifest now. | |
| Diagnostics-only gate | Document drift risks without hardening the source-level contract. | |

**User's choice:** Approved recommended option.
**Notes:** Generated renderer docs remain deferred to `FUT-04`; this phase should not create a public extension contract.

---

## Contract Strictness

| Option | Description | Selected |
|--------|-------------|----------|
| Strict drift tests with explicit exceptions | Fail for missing alias/module/render/update/interaction/private-field/public-payload coverage, but allow documented intentional gaps. | yes |
| High-risk geoms only | Enforce strict checks only for sf/polygon/interactive geoms. | |
| Soft diagnostics | Warn or document drift rather than failing tests. | |

**User's choice:** Approved recommended option.
**Notes:** Intentional gaps must carry clear reasons, such as explicit no-update behavior or known crosstalk selector omissions.

---

## `as_d3_ir()` Helper Boundary

| Option | Description | Selected |
|--------|-------------|----------|
| Focused high-risk extraction | Isolate theme extraction, layer preprocessing/dispatch, discrete/temporal mapping, geom parameter routing, and scale/axis metadata while preserving IR output. | yes |
| Full modularization | Rewrite or fully modularize `as_d3_ir()` now. | |
| Tests only | Add checks without extracting additional helpers. | |

**User's choice:** Approved recommended option.
**Notes:** Full modularization remains deferred to `FUT-03`.

---

## Regression Fixture Strategy

| Option | Description | Selected |
|--------|-------------|----------|
| Curated representative IR checks plus browser smoke | Cover non-sf, sf, facets, scales, and annotations with focused checks; use browser smoke downstream. | yes |
| Broad snapshots | Snapshot many IR outputs broadly. | |
| Browser visual only | Rely mostly on browser smoke artifacts. | |

**User's choice:** Approved recommended option.
**Notes:** Broad brittle snapshots and committed pixel goldens stay out of Phase 53.

---

## The Agent's Discretion

- Exact helper names, parser details, test organization, and small documentation placement are left to implementation as long as Phase 53 decisions and codebase style are preserved.

## Deferred Ideas

- Generated renderer documentation from contracts (`FUT-04`).
- Full `as_d3_ir()` modularization (`FUT-03`).
- Committed pixel goldens and thresholds after artifact stability is proven.
