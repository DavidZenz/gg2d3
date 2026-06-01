---
phase: 58-publication-evidence-and-release-handoff
status: passed
verified: 2026-06-01
publication_head: d5f77c6bced901248695a0fcc1e44d373acf3950
workflow_run: 26746146558
artifact: pkgdown-site-26746146558
sf_outcome_local: classified_skip
sf_outcome_artifact: rendered
---

# Phase 58 Verification

Phase 58 passed. The generated pkgdown site, the GitHub Actions pkgdown artifact, and the deployed `gh-pages` output are current for publication-affecting head `d5f77c6bced901248695a0fcc1e44d373acf3950`. `gh` authentication is healthy when Codex runs auth-dependent commands with keyring access; the earlier auth blocker was a sandbox/keyring visibility issue, not a project or maintainer setup failure.

## Commands Run

| Command | Outcome |
|---------|---------|
| `gh auth status` | Passed for account `DavidZenz`; token scopes include `repo` and `workflow`. |
| `gh run watch 26746146558 --interval 10 --exit-status` | Passed; `pkgdown.yaml` completed successfully in 3m44s. |
| `gh run download 26746146558 --pattern 'pkgdown-site-*' --dir test_output/github-run-26746146558` | Passed; downloaded `pkgdown-site-26746146558`. |
| `rtk Rscript --vanilla tools/inspect-pkgdown-publication.R --site-root test_output/github-run-26746146558/pkgdown-site-26746146558 --require-rendered-sf true` | Passed; artifact inspection reported `sf outcome: rendered`. |
| `rtk Rscript --vanilla tools/inspect-pkgdown-publication.R --site-root docs` | Passed; local generated-site inspection reported `sf outcome: classified_skip`. |
| `rtk Rscript --vanilla tools/validate-pkgdown-site.R --mode quick` | Passed; local validation reported `sf outcome: classified_skip`. |
| `rtk Rscript --vanilla -e 'testthat::test_file("tests/testthat/test-pkgdown-site.R")'` | Passed with 61 expectations, including downloaded-site-root precedence coverage. |
| `rtk Rscript --vanilla -e 'devtools::test()'` | Passed earlier in Phase 58 with `[ FAIL 0 | WARN 6 | SKIP 47 | PASS 2169 ]`; skips are expected local browser/sf/interactive classifications. |
| `rtk R CMD check --as-cran --output=/tmp/gg2d3-phase58-check gg2d3_0.0.0.9000.tar.gz` | Passed earlier in Phase 58 with 0 ERRORs, 0 WARNINGs, and 4 NOTEs. |

## Publication Evidence

| Surface | Evidence | Status |
|---------|----------|--------|
| Source docs | `README.Rmd`, `vignettes/d3-drawing-diagnostics.md`, `NEWS.md`, and generated help describe publication inspection and the sf/widget support contract without claiming new renderer support. | Passed. |
| Generated `docs/` | `tools/inspect-pkgdown-publication.R --site-root docs` and `tools/validate-pkgdown-site.R --mode quick` pass locally. | Passed with local `classified_skip`. |
| Workflow run | [`pkgdown.yaml` run 26746146558](https://github.com/DavidZenz/gg2d3/actions/runs/26746146558) completed successfully for head `d5f77c6bced901248695a0fcc1e44d373acf3950`. | Passed. |
| Workflow validation | CI log reports `Generated pkgdown site validation passed (mode: ci, sf outcome: rendered)`. | Passed. |
| Workflow artifact | Artifact `pkgdown-site-26746146558`, ID `7327800756`, size `2430347` bytes, download URL `https://github.com/DavidZenz/gg2d3/actions/runs/26746146558/artifacts/7327800756`. Downloaded copy at `test_output/github-run-26746146558/pkgdown-site-26746146558`. | Passed; artifact is ignored and uncommitted. |
| Deployed `gh-pages` output | Deploy step force-pushed `gh-pages` from `b249c85` to `f19ac66` with commit message source `DavidZenz/gg2d3@d5f77c6bced901248695a0fcc1e44d373acf3950`. | Passed. |
| Browser visual smoke | Phase 55 evidence records the dedicated browser visual smoke workflow/artifact path and CI fallback evidence; Phase 58 package tests preserve the expected local browser-smoke skip classification. | Carried forward. |
| Optional sf classification | Local generated docs classify sf as `classified_skip` because the local spatial stack cannot load; the workflow artifact renders sf and passes `--require-rendered-sf true`. | Passed. |
| Package tests | Phase 58 `devtools::test()` passed with no failures; focused pkgdown tests now include 61 expectations. | Passed. |
| Generated help | Release validation earlier in Phase 58 regenerated README/help/pkgdown output without tracked drift beyond intentional generated-site marker work. | Passed. |
| Package check | `R CMD check --as-cran` passed with 4 NOTEs and no ERROR/WARNING. | Passed with notes. |

## Requirement Coverage

| Requirement | Status | Evidence |
|-------------|--------|----------|
| SITE-02 | Complete | Current artifact `pkgdown-site-26746146558` was downloaded and inspected with `--require-rendered-sf true`; deploy step updated `gh-pages` to `f19ac66` from source `d5f77c6`. |
| SITE-03 | Complete | Release-readiness evidence now includes source docs, generated `docs/`, workflow artifact/deploy validation, browser visual smoke carry-forward, optional sf classification, package tests, generated help, and package-check outcomes. |

## v1.14 Requirement Map

| Requirement | Evidence Path | Status |
|-------------|---------------|--------|
| DOCS-01 | Phase 56 verification; `README.Rmd`, `vignettes/d3-drawing-diagnostics.md`, `NEWS.md`, generated `docs/` | Passed. |
| DOCS-02 | `docs/articles/gg2d3.html`, `docs/articles/gg2d3.md`, `docs/reference/gg2d3.html`, artifact `pkgdown-site-26746146558` | Passed. |
| DOCS-03 | Artifact taxonomy and publication inspection docs in `README.Rmd`, `README.md`, and `vignettes/d3-drawing-diagnostics.md` | Passed. |
| BUILD-01 | `.github/workflows/pkgdown.yaml`, run `26746146558`, `tools/validate-pkgdown-site.R --mode quick` | Passed. |
| BUILD-02 | Local and artifact `articles/gg2d3.html` include widget containers, D3 dependency markers, and `gg2d3-modules` assets | Passed. |
| BUILD-03 | Local `classified_skip`; CI/artifact `rendered` sf outcome with `--require-rendered-sf true` | Passed. |
| SITE-01 | Phase 57 generated-site validation gate and Phase 58 CI validation line | Passed. |
| SITE-02 | Downloaded artifact path, artifact ID `7327800756`, run `26746146558`, deploy commit `f19ac66` | Passed. |
| SITE-03 | This verification ledger plus package tests, generated help, browser visual smoke evidence, and package-check outcome | Passed. |

## Release Messaging

`NEWS.md` frames v1.14 as a publication-surface and release-readiness fix. It does not imply new `geom_sf`, renderer, or htmlwidget capabilities beyond the support already delivered in prior milestones.

## Threat Mitigation

| Threat | Status | Mitigation Evidence |
|--------|--------|---------------------|
| T-58-05 | Mitigated | Commands, run ID, artifact ID, source SHA, deploy SHA, paths, and outcomes are recorded without raw logs. |
| T-58-06 | Mitigated | Artifact and deploy output are tied to source `d5f77c6`; downloaded artifact inspection requires rendered sf evidence. |
| T-58-07 | Mitigated | Downloaded artifacts remain under ignored `test_output/`; verification contains summaries only. |
| T-58-08 | Mitigated | `gh auth status` works with keyring access; Codex sandbox keyring visibility is documented as the prior confusion. |

## Residual Risks

- GitHub warns that Node.js 20 actions are deprecated for `actions/upload-artifact@v4`; the current workflow passes, but the warning should be revisited before GitHub forces Node 24 defaults.
- Local sf remains `classified_skip` until the local GDAL/spatial dynamic-library stack is repaired; CI provides the rendered sf publication evidence.
- Browser visual smoke was carried forward from Phase 55 rather than rerun as part of Phase 58, because this milestone targeted pkgdown publication evidence.

## Next Step

v1.14 requirements are complete. The next GSD action is `$gsd-complete-milestone`.
