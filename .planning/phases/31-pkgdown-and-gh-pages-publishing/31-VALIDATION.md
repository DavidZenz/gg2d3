---
phase: 31
slug: pkgdown-and-gh-pages-publishing
status: planned
nyquist_compliant: true
wave_0_complete: false
created: 2026-05-15
updated: 2026-05-15
---

# Phase 31 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | R / testthat 3.x (existing) + local pkgdown build + automated HTML grep proxies |
| **Config file** | `tests/testthat.R` (existing); no new framework |
| **Quick run command** | `Rscript -e 'pkgload::load_all(); cat("OK\n")'` |
| **Full suite command** | `Rscript -e 'pkgdown::build_site_github_pages(install = FALSE, new_process = FALSE)'` |
| **Estimated runtime** | ~30–90 seconds (pkgdown local build) |

---

## Sampling Rate

- **After every task commit:** Quick sanity (`pkgload::load_all()` or `yaml::read_yaml('_pkgdown.yml')`).
- **After every plan wave:** Run the local pkgdown build for waves that touch `_pkgdown.yml`, vignettes, or `.Rbuildignore`.
- **Before `/gsd-verify-work`:** Full local pkgdown build green AND all five automated D-14 proxy greps pass on `docs/articles/gg2d3.html` AND the human D-14 interactivity checkpoint on the LIVE URL is recorded.
- **Max feedback latency:** ~90 seconds for local build; published-site verification is human-gated post-deploy.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | D-NN | Threat Ref | Behavior | Test Type | Automated Command | Status |
|---------|------|------|------|------------|----------|-----------|-------------------|--------|
| 1.1 | 31-01 | 0 | preflight | T-31-01 | pkgdown >= 2.2.0 and usethis >= 3.0.0 installed | static | `Rscript -e 'stopifnot(packageVersion("pkgdown") >= "2.2.0"); stopifnot(packageVersion("usethis") >= "3.0.0")'` | ⬜ pending |
| 1.2 | 31-01 | 0 | bootstrap-decision | T-31-02 | Manual-orphan strategy recorded in SUMMARY | static | `grep -q "Strategy:.*manual-orphan" .planning/phases/31-pkgdown-and-gh-pages-publishing/31-01-SUMMARY.md` | ⬜ pending |
| 1.3 | 31-01 | 0 | — | — | Human signs off on preflight | HUMAN | (checkpoint:human-verify) | ⬜ pending |
| 2.1 | 31-02 | 1 | D-09 | T-31-04 | Vignette renamed; no stale cross-refs | static | `test -f vignettes/gg2d3.Rmd && ! test -e vignettes/gg2d3-intro.Rmd` + grep audit | ⬜ pending |
| 2.2 | 31-02 | 1 | D-03,D-05,D-06,D-08,D-13 | — | Curated _pkgdown.yml parses + has expected structure | static | `Rscript -e 'y <- yaml::read_yaml("_pkgdown.yml"); stopifnot(y$url, y$template$bootstrap == 5, y$development$mode == "release", length(y$reference) == 3)'` | ⬜ pending |
| 2.3 | 31-02 | 1 | D-03 | T-31-03 | .Rbuildignore has ^\\.github$; DESCRIPTION URL has both endpoints | static | `grep -Fx '^\\.github$' .Rbuildignore && grep -F "davidzenz.github.io/gg2d3" DESCRIPTION` | ⬜ pending |
| 3.1 | 31-03 | 2 | D-07,D-09,D-10,D-11,D-13 + D-14-proxy | T-31-05 | Build succeeds; 5 automated proxies pass | build | `pkgdown::build_site_github_pages()` exit 0 + 5 grep proxies | ⬜ pending |
| 3.2 | 31-03 | 2 | D-14 (preflight) | T-31-05 | Local widget verified interactive in browser | HUMAN | (checkpoint:human-verify) | ⬜ pending |
| 4.1 | 31-04 | 3 | D-01,D-02,D-04 | T-31-07,T-31-08 | Workflow file matches r-lib template with SHA pin | static | `grep -F 'JamesIves/github-pages-deploy-action@d92aa235' .github/workflows/pkgdown.yaml` + YAML parse | ⬜ pending |
| 4.2 | 31-04 | 3 | bootstrap | T-31-09 | gh-pages branch on origin + Pages settings configured | HUMAN | (checkpoint:human-action) | ⬜ pending |
| 4.3 | 31-04 | 3 | D-01,D-02 | — | First CI run completes successfully | gh-cli | `gh run list --workflow=pkgdown.yaml --limit 1 --json status,conclusion --jq '.[0].conclusion'` returns `success` | ⬜ pending |
| 5.1 | 31-05 | 4 | **D-14** | T-31-05 | Published widget interactive in real browser | HUMAN | (checkpoint:human-verify) — THE phase gate | ⬜ pending |
| 5.2 | 31-05 | 4 | polish | — | Repo About sidebar carries pkgdown URL | gh-cli | `gh repo view DavidZenz/gg2d3 --json homepageUrl --jq .homepageUrl` returns the URL | ⬜ pending |
| 5.3 | 31-05 | 4 | traceability | T-19-11 | DOCS-02 in REQUIREMENTS.md; ROADMAP Phase 31 finalized | static | `grep -q "DOCS-02" .planning/REQUIREMENTS.md && ! grep -A2 "### Phase 31" .planning/ROADMAP.md | grep -q "\\[To be planned\\]"` | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] Confirm `pkgdown` (≥ 2.2.0) and `usethis` are installed locally — Plan 31-01 Task 1.1
- [x] Confirm `GITHUB_PAT` presence is recorded (informational only — manual bootstrap doesn't require it) — Plan 31-01 Task 1.2
- [x] Confirm `gh-pages` branch bootstrap decision is recorded in plan: **manual-orphan** — Plan 31-01 Task 1.2
- [x] D-14 proxy checks are encoded inline in Plan 31-03 Task 3.1's `<verify><automated>` block — no separate script file needed (single point of use; adding `scripts/verify-pkgdown-build.sh` would be over-engineering for a phase this size)

---

## Manual-Only Verifications

| Behavior | D-NN | Why Manual | Test Instructions |
|----------|------|------------|-------------------|
| **Local widget interactivity (D-15 preflight for D-14)** | D-14 + D-15 | Real browser DOM events fire only in a live browser | Plan 31-03 Task 3.2 — `python3 -m http.server -d docs 4321`, open `http://localhost:4321/articles/gg2d3.html`, run 5 D-14 checks |
| **Pages settings toggle** | bootstrap | GitHub Pages source selection is a UI click; `gh api` route is fiddly | Plan 31-04 Task 4.2 step 7 — github.com/DavidZenz/gg2d3/settings/pages |
| **Published widget interactivity** | **D-14** | Real browser, real URL, real users would hit this | Plan 31-05 Task 5.1 — `https://davidzenz.github.io/gg2d3/articles/gg2d3.html`, run 5 D-14 checks on the live page |
| **Repo About sidebar URL (polish)** | code_context recommendation | One-click UI or `gh repo edit` — both fine | Plan 31-05 Task 5.2 |

**Automated proxy checks (per RESEARCH.md §Validation Architecture) — necessary but NOT sufficient for D-14:**

1. `test -f docs/.nojekyll`
2. `grep -q 'src=".*d3.v7.min.js"' docs/articles/gg2d3.html`
3. `grep -q 'class="html-widget"' docs/articles/gg2d3.html`
4. `test -d docs/articles/gg2d3_files`
5. `pkgdown::build_site_github_pages()` exits 0

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify (build/grep/yamllint/gh-cli) or are explicit human checkpoints
- [x] Sampling continuity: no 3 consecutive autonomous tasks without an automated verify (every auto task has one; human checkpoints are gated)
- [x] Wave 0 covers all MISSING references (pkgdown install, GITHUB_PAT, bootstrap decision)
- [x] No watch-mode flags
- [x] Feedback latency < 90s for build; D-14 human checkpoint logged in 31-05-SUMMARY before phase closes
- [x] `nyquist_compliant: true` set in frontmatter (this commit)

**Approval:** planned 2026-05-15
