---
phase: 31
plan: 01
type: execute
wave: 0
status: complete
date: 2026-05-15
---

# Plan 31-01 Summary — Preflight + Bootstrap Decision

## Preflight

pkgdown: 2.2.0
usethis: 3.2.1
R: R version 4.6.0 (2026-04-24)

Floors satisfied: `pkgdown >= 2.2.0` ✓, `usethis >= 3.0.0` ✓. Filename-based "Get started" promotion in Plan 02 will fire (pkgdown 2.2.0 meets the minimum).

Automated assertion (`stopifnot(packageVersion("pkgdown") >= "2.2.0"); stopifnot(packageVersion("usethis") >= "3.0.0")`) returned `OK`.

## Bootstrap Decision

**Strategy:** manual-orphan (git checkout --orphan gh-pages + manual GitHub Pages settings toggle)

**Rationale:**
- Transparent — every git operation is visible in the commit log
- No dependency on GITHUB_PAT being correctly scoped
- No risk of `usethis::use_pkgdown_github_pages()` overwriting the curated `_pkgdown.yml` produced in Plan 02
- Idempotent: orphan branch is created once, never again

**GITHUB_PAT status (informational):** PAT_PRESENT=false

The manual-orphan strategy does not require a PAT — the local `git push origin gh-pages` uses whatever credentials the developer has configured (SSH key or HTTPS credential helper). PAT only matters for `usethis::use_pkgdown_github_pages()`, which we are deliberately not using.

**Concrete steps that will be executed in Plan 04 Task 4.2 (recorded here for traceability):**
1. `git checkout --orphan gh-pages`
2. `git rm -rf .`
3. `echo "placeholder" > index.html && git add index.html`
4. `git commit -m "Initial gh-pages branch"`
5. `git push origin gh-pages`
6. `git checkout master`
7. **Manual UI step (cannot be automated):** github.com/DavidZenz/gg2d3/settings/pages → Source: "Deploy from a branch" → Branch: `gh-pages / (root)` → Save

## Deviations

- **D-01 deploy mechanism:** 31-CONTEXT.md references `pkgdown::deploy_to_branch()`. The canonical r-lib `pkgdown.yaml` workflow installed by `usethis::use_pkgdown_github_pages()` actually uses `pkgdown::build_site_github_pages()` followed by `JamesIves/github-pages-deploy-action@v4.8.0` (SHA-pinned `d92aa235...`). Plans 02–04 follow the live r-lib template verbatim — this honors the spirit of D-01 ("standard r-lib path") since the template is the artifact `usethis` would have installed. Plan 04 records the exact diff in its own SUMMARY.
- **D-15 (Claude's-discretion bootstrap):** Resolved to `manual-orphan` (see above). The alternative `usethis::use_pkgdown_github_pages()` was rejected because it would clobber the curated `_pkgdown.yml` and the PAT-scoping failure mode is opaque to the user (Pitfall 3 in 31-RESEARCH.md).
