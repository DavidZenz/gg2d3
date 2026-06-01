# Phase 56: Pkgdown Content And Widget Build Contract - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md -- this log preserves the alternatives considered.

**Date:** 2026-05-31T18:29:25Z
**Phase:** 56-pkgdown-content-and-widget-build-contract
**Areas discussed:** Generated Site Freshness, Widget Rendering Evidence, sf Optional Dependency Behavior, Artifact Taxonomy

---

## Generated Site Freshness

| Option | Description | Selected |
|--------|-------------|----------|
| Source-only docs | Update source docs and rely on GitHub Pages to regenerate later | |
| Source-first plus generated site | Update source docs, regenerate pkgdown output, and treat generated `docs/` as release evidence | yes |
| Agent discretion | Let the planner decide whether generated `docs/` matters in this phase | |

**User's choice:** Recommended default selected by GSD fallback: Source-first plus generated site.
**Notes:** This matches the user's observation that source sf docs exist but the visible pkgdown site does not yet show them.

---

## Widget Rendering Evidence

| Option | Description | Selected |
|--------|-------------|----------|
| Text freshness only | Check that generated pages contain the expected documentation text | |
| Text plus widget scaffolding | Check text freshness and `gg2d3` htmlwidget containers/dependency assets | yes |
| Browser pixel checks | Add screenshot/pixel checks for pkgdown pages now | |

**User's choice:** Recommended default selected by GSD fallback: Text plus widget scaffolding.
**Notes:** Existing browser visual smoke covers rendered behavior separately; Phase 56 should prove pkgdown embeds representative widgets without introducing pixel thresholds.

---

## sf Optional Dependency Behavior

| Option | Description | Selected |
|--------|-------------|----------|
| Render sf when dependencies exist, classify otherwise | Use `sf`/`geojsonsf` when available and make skips/failures visible | yes |
| Always skip sf in pkgdown | Avoid website dependency complexity by not rendering the sf example | |
| Make sf hard-required everywhere | Promote optional spatial dependencies to mandatory package dependencies | |

**User's choice:** Recommended default selected by GSD fallback: Render sf when dependencies exist, classify otherwise.
**Notes:** This preserves optional dependency semantics while avoiding silent disappearance of the sf example from generated articles.

---

## Artifact Taxonomy

| Option | Description | Selected |
|--------|-------------|----------|
| Minimal notes | Mention only the command to build pkgdown | |
| Explicit artifact taxonomy | Document source docs, generated `docs/`, GitHub Pages output, and browser smoke artifacts separately | yes |
| No docs change | Let existing diagnostics carry the distinction implicitly | |

**User's choice:** Recommended default selected by GSD fallback: Explicit artifact taxonomy.
**Notes:** The user specifically asked whether pkgdown renders plots and whether updated sf functionality is already visible; this phase should make those answers easy to verify.

---

## the agent's Discretion

- Exact validation commands and file targets.
- Exact wording for visible optional dependency skip/failure messages.
- Whether generated `docs/` is updated before or after workflow/config fixes, as long as Phase 56 ends with generated-site evidence.

## Deferred Ideas

- Public pull-request preview links for pkgdown sites.
- Screenshot or perceptual regression coverage for selected pkgdown article pages.
- External uptime/freshness monitoring for the published GitHub Pages URL.
