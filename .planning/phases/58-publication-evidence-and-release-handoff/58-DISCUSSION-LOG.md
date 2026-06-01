# Phase 58: Publication Evidence And Release Handoff - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md - this log preserves the alternatives considered.

**Date:** 2026-06-01
**Phase:** 58-Publication Evidence And Release Handoff
**Areas discussed:** Artifact target, Trigger and retrieval flow, Evidence bundle, Release messaging

---

## Artifact Target

| Option | Description | Selected |
|--------|-------------|----------|
| Both workflow/build evidence and deployed output | Downloadable or checkoutable CI/build evidence is deterministic; deployed GitHub Pages or `gh-pages` output proves publication. | yes |
| Artifact only | Focus on workflow output and skip deployed-site publication proof. | |
| Deployed site only | Inspect the published site but skip deterministic workflow/build evidence. | |

**User's choice:** Recommendations are fine.
**Notes:** The selected path inspects both artifact/build evidence and deployed output when available.

---

## Trigger And Retrieval Flow

| Option | Description | Selected |
|--------|-------------|----------|
| Primary `gh` CLI plus manual fallback | Use `gh` for trigger/list/view/download flows and document UI fallback for auth or maintainer setup differences. | yes |
| CLI only | Require an authenticated `gh` session for the evidence path. | |
| UI/manual only | Document GitHub Actions UI inspection without a repeatable CLI path. | |

**User's choice:** Recommendations are fine.
**Notes:** Auth or permission failures should be classified as setup/manual-action gates, not as generated-site failures.

---

## Evidence Bundle

| Option | Description | Selected |
|--------|-------------|----------|
| Concise committed evidence; no bulky artifacts | Commit commands, run IDs, paths, outcomes, and residual risks in verification/handoff docs; keep raw artifacts/logs ignored. | yes |
| Commit a small machine-readable summary too | Add a generated JSON/summary artifact in git. | |
| Commit selected artifact extracts | Store selected downloaded artifact snippets or copied files in the repository. | |

**User's choice:** Recommendations are fine.
**Notes:** Downloaded artifacts may be inspected locally under ignored paths such as `test_output/github-run-*`, but final release evidence should be compact.

---

## Release Messaging

| Option | Description | Selected |
|--------|-------------|----------|
| Publication-surface validation/handoff hardening | Describe the v1.14 work as evidence and publication validation, without implying new rendering support. | yes |
| No NEWS change | Keep publication evidence only in planning/handoff docs. | |
| More prominent release note wording | Emphasize the release note more strongly, with higher risk of implying new support. | |

**User's choice:** Recommendations are fine.
**Notes:** NEWS and handoff wording must not claim new `geom_sf()`, annotation, widget, or renderer support.

---

## Agent Discretion

- Choose exact script names, documentation locations, and command flags.
- Decide whether artifact inspection is implemented as a helper script, documented `gh` command sequence, or both.
- Choose final evidence table shape, as long as raw logs and bulky artifacts stay out of committed docs.

## Deferred Ideas

- Public pull-request preview links.
- Screenshot or perceptual regression gates for pkgdown pages.
- External uptime or freshness monitoring.
- New renderer, `geom_sf()`, annotation, or widget behavior.
