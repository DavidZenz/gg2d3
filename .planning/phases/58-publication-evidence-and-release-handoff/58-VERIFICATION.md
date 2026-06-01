---
phase: 58-publication-evidence-and-release-handoff
status: partial
verified: 2026-06-01
local_head: 79d675dd35c0a19432f5c3ff9a88445b6374f1dc
sf_outcome: classified_skip
---

# Phase 58 Verification

Phase 58 has complete local source/generated-site/package evidence and complete maintainer documentation for publication inspection. It is **partial** overall because authenticated `gh` artifact evidence is blocked by an invalid local GitHub CLI token, and the fallback `origin/gh-pages` deploy checkout is structurally valid but stale relative to the current local v1.14 commits.

## Commands Run

| Command | Outcome |
|---------|---------|
| `rtk Rscript --vanilla tools/inspect-pkgdown-publication.R --site-root docs` | Passed; local publication-root inspection reported `sf outcome: classified_skip`. |
| `rtk Rscript --vanilla tools/validate-pkgdown-site.R --mode quick` | Passed; generated-site validation reported `sf outcome: classified_skip`. |
| `rtk Rscript --vanilla tools/validate-pkgdown-site.R --mode release` | Passed; rebuilt README/help/pkgdown output and left no tracked `README.md`, `docs/`, or `man/` drift. |
| `rtk Rscript --vanilla -e 'testthat::test_file("tests/testthat/test-pkgdown-site.R")'` | Passed with 60 expectations after package-check-aware skip guards were added. |
| `rtk Rscript --vanilla -e 'devtools::test()'` | Passed with `[ FAIL 0 | WARN 6 | SKIP 47 | PASS 2169 ]`; skips are expected local browser/sf/interactive classifications. |
| `rtk R CMD build --no-manual .` | Passed; built `gg2d3_0.0.0.9000.tar.gz` for package check and removed the local tarball afterward. |
| `rtk R CMD check --as-cran --output=/tmp/gg2d3-phase58-check gg2d3_0.0.0.9000.tar.gz` | Passed with 0 ERRORs, 0 WARNINGs, and 4 NOTEs. |
| `gh auth status` | Blocked: the default `DavidZenz` token is invalid. |
| `git fetch origin gh-pages` | Passed. |
| `git worktree add /tmp/gg2d3-gh-pages-phase58 origin/gh-pages` | Passed; temporary checkout removed after inspection. |
| `rtk Rscript --vanilla tools/inspect-pkgdown-publication.R --site-root /tmp/gg2d3-gh-pages-phase58` | Passed structurally with `sf outcome: classified_skip`, but currentness is stale. |

## Publication Evidence

| Surface | Evidence | Status |
|---------|----------|--------|
| Source docs | `README.Rmd`, `vignettes/d3-drawing-diagnostics.md`, and `NEWS.md` describe source/generated/deploy/browser roles and publication inspection. | Current locally. |
| Generated `docs/` | `tools/validate-pkgdown-site.R --mode quick` and `--mode release` passed; `tools/inspect-pkgdown-publication.R --site-root docs` passed. | Current locally. |
| Workflow artifact | `.github/workflows/pkgdown.yaml` uploads `pkgdown-site-${{ github.run_id }}` after `Validate generated pkgdown site`. | Configured, but not proven by a current downloaded run because `gh auth status` is blocked. |
| Deployed `gh-pages` output | `origin/gh-pages` at `e8bdd423bd550586365e7e7773cf6547f6d3197f`, deployed from source `29f69bade0c274126e1a60fd7638f61440f6cfe1`, passes the publication inspector structurally. | Stale relative to local `79d675dd35c0a19432f5c3ff9a88445b6374f1dc`; it does not contain the Phase 58 publication-surface/news inspection wording. |
| Browser visual smoke | Phase 55 evidence records the dedicated browser visual smoke workflow/artifact path and CI fallback evidence; current local `devtools::test()` keeps the default browser-smoke skip classification. | Carried forward; not rerun as a remote artifact in Phase 58. |
| Optional sf classification | Local generated site and publication inspector report `classified_skip` because `sf` cannot load locally; CI/release validation requires rendered sf automatically when `sf` and `geojsonsf` are loadable. | Classified, not hidden. |
| Package tests | Current `devtools::test()` passed with 2169 expectations, 6 warnings, and 47 expected skips. | Passed. |
| Generated help | `tools/validate-pkgdown-site.R --mode release` regenerated source-derived README/help/pkgdown outputs with no tracked drift. | Passed. |
| Package check | Current tarball `R CMD check --as-cran` passed with 4 NOTEs and no ERROR/WARNING. | Passed with notes. |

## Requirement Coverage

| Requirement | Status | Evidence |
|-------------|--------|----------|
| SITE-02 | Partial | Local artifact/deploy inspector exists, workflow artifact upload is configured, documentation contains trigger/download/fallback commands, and `origin/gh-pages` can be inspected structurally. Current downloaded workflow artifact evidence remains blocked by invalid `gh` auth, and fallback deploy output is stale. |
| SITE-03 | Partial | Release-readiness evidence now includes local pkgdown source/build validation, package tests, generated help, browser visual smoke classification, optional sf classification, and package-check outcome. It cannot yet close the deploy/currentness portion until current workflow artifact or deploy evidence is obtained. |

## v1.14 Requirement Map

| Requirement | Evidence Path | Status |
|-------------|---------------|--------|
| DOCS-01 | Phase 56 verification; current `tools/validate-pkgdown-site.R --mode release`; `README.Rmd`, `vignettes/`, `NEWS.md`, `docs/` | Passed. |
| DOCS-02 | `docs/articles/gg2d3.html`, `docs/articles/gg2d3.md`, `docs/reference/gg2d3.html`, `docs/reference/extract_sf_geometries.html` | Passed locally. |
| DOCS-03 | `README.Rmd`, `README.md`, `vignettes/d3-drawing-diagnostics.md`, Phase 58 publication inspection runbook | Passed locally. |
| BUILD-01 | `.github/workflows/pkgdown.yaml`, `tools/validate-pkgdown-site.R --mode release`, Phase 56 workflow dependency evidence | Passed locally/configured. |
| BUILD-02 | `docs/articles/gg2d3.html`, widget dependency markers, `docs/articles/gg2d3_files/gg2d3-modules-0.0.1` | Passed locally. |
| BUILD-03 | Local `classified_skip`; Phase 56/57 validation notes; release/CI mode requires rendered sf when optional packages are loadable | Passed as classified local skip. |
| SITE-01 | Phase 57 verification; `tools/validate-pkgdown-site.R`; CI gate before deploy | Passed. |
| SITE-02 | `tools/inspect-pkgdown-publication.R`, workflow artifact upload config, diagnostics `gh` runbook, fallback `gh-pages` structural inspection | Partial until current artifact/deploy evidence is obtained. |
| SITE-03 | This verification ledger; package tests; generated help; browser visual smoke and package-check outcomes | Partial until current publication output is proven. |

## Release Messaging

`NEWS.md` says v1.14 repairs pkgdown publication-surface evidence and explicitly avoids implying new rendering support. The negative scan for `new (geom_sf|geom_sf_text|geom_sf_label|renderer|htmlwidget) support` across `NEWS.md`, diagnostics, and README files passed.

## Threat Mitigation

| Threat | Status | Mitigation Evidence |
|--------|--------|---------------------|
| T-58-05 | Partial | Local commands, SHAs, paths, and outcomes are recorded without raw logs. Current remote workflow run ID/artifact path is blocked by `gh` auth. |
| T-58-06 | Partial | Fallback deploy SHA and source SHA are recorded; stale output is classified rather than treated as current. |
| T-58-07 | Mitigated | Verification summarizes outcomes only; raw logs, browser JSON, screenshots, tarballs, `.Rcheck` directories, and downloaded artifacts are not committed. |
| T-58-08 | Accepted with blocker | Invalid `gh` auth is recorded as setup/manual blocker. |

## Residual Risks

- `gh auth status` must be repaired with `gh auth login -h github.com` or a maintainer must provide a downloaded `pkgdown-site-<run-id>` artifact path from the GitHub Actions UI.
- Current local commits have not been proven in a downloaded `pkgdown-site-*` workflow artifact.
- `origin/gh-pages` currently points to deploy source `29f69bade0c274126e1a60fd7638f61440f6cfe1`, which predates the Phase 58 publication inspection documentation and workflow-artifact additions.
- Local sf remains `classified_skip`; rendered sf publication evidence still depends on a CI/website environment where `sf` and `geojsonsf` load.

## Next Step

After `gh` auth is repaired or a current artifact is provided, run the documented publication flow:

```sh
gh workflow run pkgdown.yaml --ref master
gh run list --workflow pkgdown.yaml --branch master --limit 5 --json databaseId,status,conclusion,headSha,url
gh run download <run-id> --pattern "pkgdown-site-*" --dir test_output/github-run-<run-id>
rtk Rscript --vanilla tools/inspect-pkgdown-publication.R --site-root test_output/github-run-<run-id>/pkgdown-site-<run-id>
```

Then update this file to `status: passed` and mark SITE-02/SITE-03 complete only if the artifact or deploy output is current for the source SHA under review.
