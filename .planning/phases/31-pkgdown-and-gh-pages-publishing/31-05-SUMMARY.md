---
phase: 31
plan: 05
type: execute
wave: 4
status: complete
date: 2026-05-17
---

# Plan 31-05 Summary — Phase 31 close-out

## Task 5.1 — D-14 published-site human verification

**Approved by user 2026-05-17** on the LIVE URL `https://davidzenz.github.io/gg2d3/articles/gg2d3.html`.

Three CI runs were needed before the deployed site contained renderable widgets:

| Run | Result | What it surfaced |
|---|---|---|
| [25996275369](https://github.com/DavidZenz/gg2d3/actions/runs/25996275369) | success but empty | Vignette `eval` guard `requireNamespace(...)` returned FALSE in pkgdown's article subprocess despite `local::.` install; HTML was 64 KB with 0 widgets |
| [25996914582](https://github.com/DavidZenz/gg2d3/actions/runs/25996914582) | failure | Set `eval = TRUE`, then chunks ran but `library(ggplot2)` failed — `DESCRIPTION` had no `Imports:` block at all |
| [25997189317](https://github.com/DavidZenz/gg2d3/actions/runs/25997189317) | success with widgets | Added `Imports: ggplot2, htmlwidgets, jsonlite, grid, rlang` + guarded the `map_data("state")` chunk on `maps` package; deploy now produces a 13.1 MB article with 44 widget divs |

Final state verified by `curl`:
- `https://davidzenz.github.io/gg2d3/articles/gg2d3.html` → HTTP 200, 13.1 MB, 44 `html-widget` divs
- `https://davidzenz.github.io/gg2d3/articles/gg2d3_files/d3-7/d3.v7.min.js` → HTTP 200

Human-verified D-14 five-check pass on live URL (user `approve` response).

## Task 5.2 — Repo About sidebar

Set via `gh repo edit DavidZenz/gg2d3 --homepage "https://davidzenz.github.io/gg2d3/"`.

Verified: `gh repo view DavidZenz/gg2d3 --json homepageUrl --jq .homepageUrl` → `https://davidzenz.github.io/gg2d3/`.

## Task 5.3 — REQUIREMENTS.md + ROADMAP.md finalize

- `REQUIREMENTS.md`: added a "Distribution" cross-milestone section with `DOCS-02` (status: complete, met by Phase 31). Added the corresponding traceability row.
- `ROADMAP.md`: Phase 31 row updated to `5/5 | Complete | 2026-05-17`. Replaced the inline "in-progress" note with the final goal, requirements pointer, and the 5-plan checklist.

## D-NN decision → satisfying plan map

| Decision | Where landed |
|---|---|
| D-01 (r-lib standard publishing path) | 31-04 workflow file (verbatim r-lib template) |
| D-02 (push to master + release) | 31-04 workflow triggers |
| D-03 (canonical site URL) | 31-02 `_pkgdown.yml` `url:`, DESCRIPTION URL field |
| D-04 (single Actions job) | 31-04 workflow `jobs.pkgdown` only |
| D-05 (reference structure) | 31-02 `_pkgdown.yml` 3-section reference: (Main entry / Interactivity / Internals); deviated to use audited NAMESPACE |
| D-06 (default navbar) | 31-02 no custom `navbar:` block |
| D-07 (default NEWS surface) | 31-02 no `news:` block; verified via `docs/news/index.html` |
| D-08 (Bootstrap 5 template) | 31-02 `_pkgdown.yml` `template.bootstrap: 5` |
| D-09 (Get-started auto-promotion) | 31-02 vignette renamed to `gg2d3.Rmd` |
| D-10 (no diagnostics in published output) | 31-03 verified by `find docs -name "*diagnostic*"` → empty |
| D-11 (README → homepage) | default pkgdown behavior; verified `docs/index.html` |
| D-13 (single-mode docs, no /dev/ split) | 31-02 `_pkgdown.yml` `development.mode: release` |
| D-14 (published-site human interactivity check) | 31-05 Task 5.1 |
| D-15 (local-build preflight before workflow commit) | 31-03 Task 3.2 plus 7 rounds of polish |

## Deviations from the original CONTEXT recorded across the phase

1. CONTEXT D-01 described the deploy mechanism as `pkgdown::deploy_to_branch()`; the actual r-lib template uses `pkgdown::build_site_github_pages()` + `JamesIves/github-pages-deploy-action@d92aa235...`. Honors the spirit of "standard r-lib path." (Logged in 31-01-SUMMARY and 31-04-SUMMARY.)
2. CONTEXT D-05 listed `d3_crosstalk` as exported; NAMESPACE audit found it is internal. `_pkgdown.yml` reflects the audited NAMESPACE. (Logged in 31-02-SUMMARY.)
3. Plan 31-04 Task 4.2 was a human checkpoint; user delegated execution back to orchestrator. Bootstrap + Pages settings done via git + `gh api`. (Logged in 31-04-SUMMARY.)
4. Plan 31-05 added Imports to DESCRIPTION (ggplot2, htmlwidgets, jsonlite, grid, rlang). The package had been shipping with no `Imports:` block at all, which only became visible because CI's clean install couldn't find ggplot2 during vignette rendering. Side-effect fix that was strictly necessary to satisfy D-14 on the public URL.

## Phase 31 goal

> A pkgdown site at https://davidzenz.github.io/gg2d3/ is rebuilt and redeployed on every push to master (and on releases), and at least one `gg2d3()` widget in the published "Get started" article is verifiably interactive in a user's browser.

**Met.** Site live, workflow active, widgets verified interactive by user on 2026-05-17.

## Final commit chain on master

From `c9dc23e` (last pre-Phase-31 master) through `<this commit>`:
- 13 cherry-picked / port commits (Phase 31 plan artifacts + 6 gg2d3 fix commits)
- 12 polish commits (rounds 1–7)
- workflow + DESCRIPTION + vignette eval fixes (Plan 31-04/05)
- this SUMMARY

Plan 31-05 complete. Phase 31 complete. DOCS-02 met.
