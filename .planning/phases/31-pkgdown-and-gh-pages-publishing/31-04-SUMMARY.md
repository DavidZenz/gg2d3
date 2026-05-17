---
phase: 31
plan: 04
type: execute
wave: 3
status: complete
date: 2026-05-17
---

# Plan 31-04 Summary — Workflow + gh-pages bootstrap + first CI deploy

## What landed

### Task 4.1 — `.github/workflows/pkgdown.yaml`

Committed verbatim from the live r-lib v2-branch template:
- Source: https://github.com/r-lib/actions/blob/v2-branch/examples/pkgdown.yaml
- Triggers: `push: [main, master]`, `pull_request` (build only), `release.published`, `workflow_dispatch`
- Build: `pkgdown::build_site_github_pages(new_process = FALSE, install = FALSE)`
- Deploy: `JamesIves/github-pages-deploy-action@d92aa235d04922e8f08b40ce78cc5442fcfbfa2f` (v4.8.0, SHA-pinned per T-31-07)
- Permissions: workflow scope `read-all`, pkgdown job `contents: write` (T-31-08)
- Deploy guard: `if: github.event_name != 'pull_request'` — PRs build but never deploy

Acceptance criteria all passed:
- `^\.github$` pre-existed in `.Rbuildignore` (Plan 31-02)
- YAML parses; single job named `pkgdown`
- SHA pin present; both permission blocks present
- `build_site_github_pages` (not `build_site`)

### Task 4.2 — Manual-orphan bootstrap (executed by orchestrator, not human)

Per the manual-orphan decision locked in Plan 31-01, the 7-step bootstrap was executed:

1. `git stash push -u -m "phase 31-04 workflow + .claude pre-bootstrap"` (safety)
2. `git checkout --orphan gh-pages`
3. `git rm -rf .`
4. `echo "<!doctype html><html><body>gg2d3 site bootstrapping…</body></html>" > index.html && git add index.html`
5. `git commit -m "Initial gh-pages branch"` → bootstrap SHA `e0bc960...`
6. `git push origin gh-pages` (succeeded)
7. `git checkout claude/phase-29-pkgdown && git stash pop`

GitHub Pages settings:

- Plan called for a UI toggle at github.com/DavidZenz/gg2d3/settings/pages.
- Found that Pages was already enabled with `build_type: workflow` (default for new repos). Switched to `build_type: legacy` + source `gh-pages / (root)` via `gh api -X PUT /repos/DavidZenz/gg2d3/pages -f build_type=legacy -f source[branch]=gh-pages -f source[path]=/`.
- Required PAT scope: `pages:write` (user refreshed token mid-task).

Result: `gh api /repos/DavidZenz/gg2d3/pages` returns `{build_type: "legacy", source: {branch: "gh-pages", path: "/"}, html_url: "https://davidzenz.github.io/gg2d3/", https_enforced: true}`.

### Task 4.3 — Commit + push + first CI deploy

- Committed `.github/workflows/pkgdown.yaml` to `claude/phase-29-pkgdown`.
- Fast-forwarded `master` to include all 13 commits of Phase 31 work (port + 5 fix branches' cherry-picks + getDashArray unblock + 7 rounds of polish + workflow file).
- Pushed master → triggered first CI run.

## First CI Deploy

- **Commit on master**: `625dddf` (workflow + all Phase 31 polish)
- **Run URL**: https://github.com/DavidZenz/gg2d3/actions/runs/25996275369
- **Status**: completed
- **Conclusion**: success
- **Duration**: 3m 31s
- **Steps**: 8/8 ✓ (checkout, setup-pandoc, setup-r, setup-r-dependencies, Build site, Deploy to GitHub pages 🚀, post-deps, post-checkout)
- **gh-pages SHA after deploy**: `5532bb4f95376ba25c7cef55cb3b842c8ef8531d` (replaced the `e0bc960...` placeholder)

## Live site

- URL: https://davidzenz.github.io/gg2d3/
- `curl -L https://davidzenz.github.io/gg2d3/` → `HTTP 200`
- HTTPS enforced
- Plan 31-05 will perform the D-14 interactive verification (widget renders, tooltip, zoom/pan/brush, DevTools console clean, d3.v7.min.js 200 OK)

## Threat-model dispositions exercised

| Threat | Status |
|---|---|
| T-31-07 (third-party action tag-rewrite) | mitigated — SHA pin grep-verified |
| T-31-08 (overly broad token) | mitigated — read-all workflow scope, contents:write job scope only, PRs cannot deploy |
| T-31-09 (gh-pages overwrite) | accepted — documented as intentional deploy mechanism |
| T-31-10 (build log env leak) | accepted — current chunks don't `Sys.getenv()`; future risk only |

## Deviations from plan

- **Task 4.2 was originally a human checkpoint**; user delegated execution back to orchestrator. Bootstrap + Pages API toggle done programmatically; no functional difference vs. the human-doing-it-themselves path.
- **Task 4.3 expected to push directly to master**; in our port we worked on `claude/phase-29-pkgdown` first and then fast-forward-merged. End state identical: master contains the full Phase 31 commit chain.

Plan 31-04 complete. Plan 31-05 (D-14 published-site verification, DOCS-02, ROADMAP update) is unblocked.
