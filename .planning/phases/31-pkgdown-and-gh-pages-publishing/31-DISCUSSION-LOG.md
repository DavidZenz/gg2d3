# Phase 31: pkgdown and GH Pages publishing - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-15
**Phase:** 31-pkgdown-and-gh-pages-publishing
**Areas discussed:** Deploy + Site URL; Navbar & reference structure; Articles + homepage; Versioning + widget rendering

---

## Deploy + Site URL

### Q1: Which GHA deploy workflow?

| Option | Description | Selected |
|--------|-------------|----------|
| r-lib pkgdown.yaml (Recommended) | Standard r-lib/actions workflow → gh-pages branch via `pkgdown::deploy_to_branch()`. | ✓ |
| peaceiris/actions-gh-pages | Generic GH Pages action; non-idiomatic for R packages. | |
| Manual local deploys | `pkgdown::deploy_to_branch()` run locally; no CI. | |

### Q2: What triggers the build & deploy?

| Option | Description | Selected |
|--------|-------------|----------|
| Push to master + tagged releases (Recommended) | Every push to master + `release` events. | ✓ |
| Tags only | Deploy only on tagged releases. | |
| Manual workflow_dispatch only | Click-to-run; no automatic builds. | |

### Q3: What canonical URL?

| Option | Description | Selected |
|--------|-------------|----------|
| https://davidzenz.github.io/gg2d3/ (Recommended) | Default GH Pages URL for user.github.io/repo. | ✓ |
| Custom domain (CNAME) | e.g., gg2d3.davidzenz.com. DNS + CNAME file. | |

### Q4: Should the workflow also run R CMD check?

| Option | Description | Selected |
|--------|-------------|----------|
| pkgdown deploy only (Recommended) | Single-purpose workflow; CI check is its own phase. | |
| pkgdown + R CMD check matrix | Combined workflow with check-r-package matrix. | ✓ (initial), then **reversed** below |

### Q4-followup: Scope confirmation for R CMD check matrix

| Option | Description | Selected |
|--------|-------------|----------|
| Keep R CMD check matrix in Phase 31 | Single workflow with two jobs. | |
| Move R CMD check to its own phase | Phase 31 stays publishing-only. | ✓ |
| More questions about deploy | Keep digging on this area. | |

**Notes:** Initial answer to Q4 added R CMD check to Phase 31 scope. Follow-up question surfaced that this expands beyond the phase title and Phase 17 closed without CI check; user reversed and moved R CMD check matrix to a future phase. Recorded as Deferred Idea.

---

## Navbar & reference structure

### Q1: Reference index — curated sections or default alphabetical?

| Option | Description | Selected |
|--------|-------------|----------|
| Curated sections (Recommended) | _pkgdown.yml `reference:` with Main entry / Interactivity / Helpers groups. | ✓ |
| Default alphabetical | pkgdown auto-list, no curation. | |

### Q2: Navbar structure?

| Option | Description | Selected |
|--------|-------------|----------|
| Default + GitHub link (Recommended) | pkgdown defaults plus GitHub icon. | ✓ |
| Custom-ordered navbar | Hand-roll `navbar:` block. | |

### Q3: NEWS.md as Changelog page?

| Option | Description | Selected |
|--------|-------------|----------|
| Use existing NEWS.md (Recommended if present) | Auto-rendered Changelog. | ✓ |
| Skip Changelog page for now | Remove News link. | |

**Notes:** Verified `NEWS.md` exists at repo root (1.4K, created in Phase 17).

### Q4: Pkgdown theme?

| Option | Description | Selected |
|--------|-------------|----------|
| bootstrap 5, default (Recommended) | Matches existing stub. | ✓ |
| Bootswatch flavor | flatly/cosmo/etc. | |
| Custom CSS in pkgdown/extra.css | Most control, most maintenance. | |

---

## Articles + homepage

### Q1: Vignette ordering / labeling?

| Option | Description | Selected |
|--------|-------------|----------|
| Intro as 'Get started', Interactivity as Article (Recommended) | gg2d3-intro promoted to navbar "Get started"; interactivity under Articles. | ✓ |
| Both equal under Articles | No promotion; both in dropdown. | |

### Q2: Include diagnostics doc on public site?

| Option | Description | Selected |
|--------|-------------|----------|
| Keep dev-only — not on the site (Recommended) | Honors Phase 18 D-10. | ✓ |
| Surface it as an Article | Copy/reference into vignettes/articles. | |

### Q3: Homepage source?

| Option | Description | Selected |
|--------|-------------|----------|
| README as homepage (Recommended) | pkgdown default index.html from README.md. | ✓ |
| Separate pkgdown/index.Rmd | Decoupled landing page. | |

### Q4: Vignette chunk adjustments for pkgdown?

| Option | Description | Selected |
|--------|-------------|----------|
| Trust existing chunks; verify in build (Recommended) | Verify via local pkgdown::build_site(). | ✓ |
| Pre-emptively add pkgdown overrides | eval/echo/fig.* overrides upfront. | |

---

## Versioning + widget rendering

### Q1: Site versioning?

| Option | Description | Selected |
|--------|-------------|----------|
| Single root site (Recommended) | development: mode: release / absent. | ✓ |
| Dev/release split (mode: auto) | /dev/ for master, root for tags. | |
| Dev/release split now to prep for CRAN | Commit to split upfront. | |

### Q2: Widget rendering confidence?

| Option | Description | Selected |
|--------|-------------|----------|
| Hard requirement: at least one interactive widget must work in the published site (Recommended) | Human-checkpoint verification post-deploy. | ✓ |
| Best-effort: if build succeeds, ship it | Trust pkgdown's widget bundling. | |

### Q3: Fallback if widgets don't render?

| Option | Description | Selected |
|--------|-------------|----------|
| Investigate & fix in-phase (Recommended) | Dedicated verification wave; common-fix list in CONTEXT.md. | ✓ |
| Punt to a follow-up phase | Ship even if widgets are static. | |

### Q4: Final scope check?

| Option | Description | Selected |
|--------|-------------|----------|
| Scope feels right — ready for context | Move on. | ✓ |
| Add: gh-pages branch bootstrap details | Manual vs. usethis-managed. | |
| Add: PR previews | Per-PR preview sites. | |
| Add: pkgdown version pinning in workflow | r-lib/actions / pandoc / R version pinning. | |

**Notes:** gh-pages bootstrap was rolled into Claude's discretion in CONTEXT.md rather than a locked decision. PR previews and version pinning landed in Deferred Ideas.

---

## Claude's Discretion

- Exact YAML structure / key ordering / comments in `_pkgdown.yml`.
- Whether to patch the existing stub `_pkgdown.yml` vs. rewrite.
- Specific GHA workflow filename (`pkgdown.yaml` conventional but `pkgdown-deploy.yaml` acceptable).
- Optional `pkgdown/` subfolder (favicon, etc.).
- gh-pages branch bootstrap approach (manual `git checkout --orphan` once vs. let `usethis::use_pkgdown_github_pages()` do it).

## Deferred Ideas

- R CMD check matrix on CI (reverted from D-04; own future phase).
- Custom domain (CNAME).
- PR preview deploys.
- pkgdown version pinning in the workflow.
- Dev/release pkgdown split (`development: mode: auto`).
- Adding a Phase 31 REQ-ID (e.g., DOCS-02) to `REQUIREMENTS.md` for traceability.
- Custom pkgdown logo / hex sticker.
