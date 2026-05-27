# Phase 50: Renderer Wiring And Interaction Contracts - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-26T13:02:25Z
**Phase:** 50-renderer-wiring-and-interaction-contracts
**Areas discussed:** Renderer wiring source of truth, Zoom/update handler contract, Interaction selector ownership, Public payload sanitization rules

---

## Renderer Wiring Source Of Truth

| Option | Description | Selected |
|--------|-------------|----------|
| Internal declarative geom descriptor | Capture supported geom names, selectors/classes, renderer registration, interaction participation, update expectations, and private-field behavior in a small internal contract. Recommended because it reduces duplicated knowledge without creating a public API. | ✓ |
| Validation around existing calls only | Keep all runtime wiring as-is and add tests around existing `registerGeom()` and selector lists. Lower risk but leaves more duplicated source knowledge. | |
| Broad renderer rewrite | Replace current registry/update structure with a new architecture. Too much churn for this phase. | |

**User's choice:** Recommendations are fine.
**Notes:** Lock recommended internal descriptor/contract, with planner discretion on runtime use versus test-only validation.

---

## Zoom/Update Handler Contract

| Option | Description | Selected |
|--------|-------------|----------|
| Descriptor-backed update coverage tests | Require every supported geom to have expected update plumbing or an explicit exclusion. Recommended because `updateGeoms()` is procedural and high-risk. | ✓ |
| Full update handler map refactor | Split all update branches into per-geom update handlers immediately. Useful but riskier. | |
| Leave updates procedural with spot checks | Minimal churn, but weaker protection against missing supported geoms. | |

**User's choice:** Recommendations are fine.
**Notes:** Lock incremental update contract tests first; small update metadata extraction is allowed when low risk.

---

## Interaction Selector Ownership

| Option | Description | Selected |
|--------|-------------|----------|
| Canonical descriptor with module-specific selector derivation/validation | Keep module-specific responsibilities while deriving or testing selector lists from one source. Recommended because `events.js`, `brush.js`, and `crosstalk.js` overlap but are not identical. | ✓ |
| One identical selector list shared everywhere | Reduces duplication but may overfit modules with different semantics. | |
| Keep lists separate and manually tested | Lowest runtime change but leaves ongoing drift risk. | |

**User's choice:** Recommendations are fine.
**Notes:** Lock canonical descriptor/contract with module-specific selector coverage, not a blind single list for all modules.

---

## Public Payload Sanitization Rules

| Option | Description | Selected |
|--------|-------------|----------|
| Centralize or contract-test sanitizer behavior | Ensure tooltip, events/handlers, and brush callbacks consistently strip underscore-prefixed renderer-private fields. Recommended because similar sanitizer code exists in multiple modules. | ✓ |
| Leave local sanitizers with narrow tests | Lower churn but risks future drift between tooltip, brush, and handler payloads. | |
| Expose private fields for advanced callbacks | Rejected; contradicts existing polygon and sf privacy contracts. | |

**User's choice:** Recommendations are fine.
**Notes:** Lock public payload rule: underscore-prefixed renderer-private fields stay out of user-facing tooltip, event, handler, and brush payloads. Crosstalk can use `_sourceIndex` internally before sanitization.

---

## the agent's Discretion

- Exact descriptor filename and schema shape.
- Whether descriptor is runtime-consumed, test-only, or both.
- Exact plan split and test file placement.

## Deferred Ideas

- Public JS plugin/extension API.
- Geometry behavior changes scheduled for Phase 51.
- CI-hosted visual diffs and golden screenshots.
