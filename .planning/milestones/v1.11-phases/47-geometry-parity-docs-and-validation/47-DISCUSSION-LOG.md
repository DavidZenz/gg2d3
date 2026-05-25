# Phase 47: Geometry Parity Docs And Validation - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-25T10:10:14+02:00
**Phase:** 47-Geometry Parity Docs And Validation
**Areas discussed:** Public support wording, Validation evidence shape, Deferred scope placement, Generated docs policy

---

## Public Support Wording

| Option | Description | Selected |
|--------|-------------|----------|
| Balanced support table | Mark features as supported with explicit limitations and diagnostics links. | yes |
| Conservative wording | Mostly diagnostic/release-note wording, minimizing public support claims. | |
| Strong parity wording | Emphasize "geometry parity shipped" with limitations secondary. | |

**User's choice:** Balanced support table.
**Notes:** User selected `1a`.

---

## Validation Evidence Shape

| Option | Description | Selected |
|--------|-------------|----------|
| Feature matrix | Map polygon / rect-tile / sf annotations to test files, commands, browser smoke, and skip semantics. | yes |
| Short summary | Brief narrative validation summary only. | |
| Exhaustive appendix | List every related test. | |

**User's choice:** Feature matrix.
**Notes:** User selected `2a`.

---

## Deferred Scope Placement

| Option | Description | Selected |
|--------|-------------|----------|
| Concise public notes plus detailed diagnostics | Surface short limitation notes in README/vignettes/help and put detailed caveats in diagnostics. | yes |
| Diagnostics only | Keep limitations only in diagnostics docs. | |
| Repeat details everywhere | Repeat detailed limitations across all public docs. | |

**User's choice:** Concise public notes plus detailed diagnostics.
**Notes:** User selected `3a`.

---

## Generated Docs Policy

| Option | Description | Selected |
|--------|-------------|----------|
| Source-first regeneration | Update roxygen/README sources and regenerate `README.md` plus `man/*.Rd`. | yes |
| Sources only | Update sources only; leave generated artifacts for release prep. | |
| Manual generated edits | Update generated docs manually where needed. | |

**User's choice:** Source-first regeneration.
**Notes:** User selected `4a`.

---

## the agent's Discretion

- Exact support table and validation matrix layout may be chosen during planning/execution.
- Exact validation notes location may be chosen during planning/execution as long as Phase 47 success criteria are satisfied.

## Deferred Ideas

None.
