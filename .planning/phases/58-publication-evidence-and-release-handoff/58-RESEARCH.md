---
phase: 58-publication-evidence-and-release-handoff
status: complete
created: 2026-06-01
---

# Phase 58 Research: Publication Evidence And Release Handoff

## Research Questions

1. How should maintainers trigger, inspect, and download pkgdown workflow output?
2. Does the current repo already publish enough deterministic pkgdown evidence?
3. What implementation surface should Phase 58 plan: workflow, helper script, docs, or evidence only?

## Findings

### GitHub CLI And Artifact Behavior

- `gh workflow run <workflow>` creates a `workflow_dispatch` event and therefore requires the workflow file to define `on.workflow_dispatch`. The existing `.github/workflows/pkgdown.yaml` already has that trigger.
- `gh run list -w pkgdown.yaml --json ...` can identify recent workflow runs and expose run IDs, status, conclusion, branch, commit SHA, URL, and timestamps.
- `gh run view <run-id> --log` can inspect run logs, but logs are not a durable evidence artifact and can have step-association limitations. Use it for diagnosis, not as the primary release ledger.
- `gh run download <run-id> --dir <path> --pattern <glob>` downloads artifacts produced by a specific run. GitHub CLI documentation warns that omitting `<run-id>` selects the latest available artifact and workflows can delete or overwrite artifacts, so Phase 58 evidence should record a concrete run ID.
- GitHub Actions artifacts are intended for files produced during a workflow run that maintainers need after the run completes. The repo already uses this pattern in `.github/workflows/browser-visual-smoke.yaml`.

Primary sources:

- <https://cli.github.com/manual/gh_workflow_run>
- <https://cli.github.com/manual/gh_run_list>
- <https://cli.github.com/manual/gh_run_view>
- <https://cli.github.com/manual/gh_run_download>
- <https://docs.github.com/en/actions/concepts/workflows-and-actions/workflow-artifacts>
- <https://docs.github.com/en/actions/how-tos/writing-workflows/choosing-what-your-workflow-does/storing-and-sharing-data-from-a-workflow>

### Local Repository State

- `.github/workflows/pkgdown.yaml` currently:
  - supports `workflow_dispatch`;
  - verifies website dependencies;
  - builds the pkgdown site;
  - runs `Rscript tools/validate-pkgdown-site.R --mode ci`;
  - deploys `docs` to `gh-pages` for non-pull-request events;
  - does **not** upload `docs/` as a workflow artifact.
- `.github/workflows/browser-visual-smoke.yaml` already uploads a workflow artifact with:
  - `uses: actions/upload-artifact@v4`;
  - `name: browser-visual-smoke-${{ github.run_id }}`;
  - `path: test_output/browser-visual-smoke/`;
  - `if-no-files-found: warn`;
  - `retention-days: 14`.
  This is the nearest local pattern for downloadable post-run evidence.
- `tools/validate-pkgdown-site.R` validates the generated site only in repository layout, where generated files live under `docs/`. It cannot directly validate an extracted artifact or `gh-pages` checkout whose root contains `articles/`, `news/`, and `reference/`.
- `tests/testthat/helper-pkgdown-site.R` contains the canonical marker contract and sf outcome logic. Phase 58 should extend it or reuse it rather than duplicating marker strings.
- `gh --version` is available locally: `gh version 2.93.0 (2026-05-27)`.
- `gh auth status` currently reports an invalid token for the default `DavidZenz` account. Phase 58 documentation and verification should classify this as an auth/setup gate and provide manual fallback, not as a generated-site failure.

### Published `gh-pages` Evidence

After `git fetch origin gh-pages`, `origin/gh-pages` points to:

```text
e8bdd42 Deploying to gh-pages from @ DavidZenz/gg2d3@29f69bade0c274126e1a60fd7638f61440f6cfe1
```

The remote deploy branch contains real pkgdown site files:

- `articles/gg2d3.html`
- `articles/gg2d3.md`
- `articles/gg2d3_files/gg2d3-modules-0.0.1/...`
- `news/index.html`
- `reference/gg2d3.html`
- `reference/extract_sf_geometries.html`

The deployed article has rendered sf evidence: `articles/gg2d3.html` contains the `sf family maps with geom_sf` section and a `gg2d3 html-widget` after that heading. The generated reference pages also contain current sf support wording.

However, `origin/gh-pages:news/index.html` does not contain the v1.14 `Pkgdown publication-surface evidence` note that exists locally in `NEWS.md` and `docs/news/index.html`. That means Phase 58 should explicitly prove currentness against the source commit or generated local docs, not merely prove that some pkgdown site exists.

### Recommended Implementation

1. Add a pkgdown site artifact upload step to `.github/workflows/pkgdown.yaml` after `Validate generated pkgdown site` and before deploy.
   - Use `actions/upload-artifact@v4`.
   - Name it `pkgdown-site-${{ github.run_id }}`.
   - Upload `docs/`.
   - Set `if-no-files-found: error`.
   - Set `retention-days: 14`.
2. Add a maintainer inspection command that validates a site root outside the repo layout.
   - Suggested entrypoint: `tools/inspect-pkgdown-publication.R`.
   - It should accept `--site-root <path>` where `<path>` contains `articles/`, `news/`, and `reference/`.
   - It should source `tests/testthat/helper-pkgdown-site.R`.
   - It should validate current article text, widget dependencies, NEWS, reference pages, and sf outcome using the same marker contract as Phase 57.
3. Extend `tests/testthat/helper-pkgdown-site.R` with site-root validation helpers rather than duplicating marker lists in the script.
4. Document the `gh` flow in `vignettes/d3-drawing-diagnostics.md`:
   - trigger: `gh workflow run pkgdown.yaml --ref master`;
   - find run: `gh run list --workflow pkgdown.yaml --branch master --limit 5 --json databaseId,status,conclusion,headSha,url`;
   - download: `gh run download <run-id> --pattern "pkgdown-site-*" --dir test_output/github-run-<run-id>`;
   - inspect downloaded artifact: `rtk Rscript --vanilla tools/inspect-pkgdown-publication.R --site-root test_output/github-run-<run-id>/pkgdown-site-<run-id>`;
   - inspect deploy branch fallback: fetch/check out `origin/gh-pages` and run the same inspector against that checkout.
5. Final verification should record run IDs, commit SHAs, commands, artifact/deploy roots, and outcomes in `58-VERIFICATION.md` without committing downloaded artifacts or raw logs.

## Validation Architecture

### Testable Behaviors

| Behavior | Requirement | Automated Evidence |
|----------|-------------|--------------------|
| Pkgdown workflow uploads downloadable site artifact after validation | SITE-02 | `rtk rg -n "Upload pkgdown site artifact|actions/upload-artifact@v4|pkgdown-site-\\$\\{\\{ github.run_id \\}\\}|path: docs|if-no-files-found: error|retention-days: 14" .github/workflows/pkgdown.yaml` |
| Downloaded or checkoutable site roots can be validated outside repository `docs/` layout | SITE-02 | `rtk Rscript --vanilla tools/inspect-pkgdown-publication.R --site-root docs` plus helper tests for site-root path validation |
| Maintainer docs describe `gh` trigger/list/download and manual fallback | SITE-02 | `rtk rg -n "gh workflow run pkgdown.yaml|gh run list --workflow pkgdown.yaml|gh run download <run-id>|inspect-pkgdown-publication|origin/gh-pages" vignettes/d3-drawing-diagnostics.md README.Rmd README.md` |
| Final release handoff maps source/build/deploy evidence and residual risks | SITE-03 | `rtk rg -n "SITE-02|SITE-03|DOCS-01|BUILD-03|workflow run|artifact|gh-pages|browser visual smoke|R CMD check|residual" .planning/phases/58-publication-evidence-and-release-handoff/58-VERIFICATION.md` |
| Release messaging does not claim new renderer support | SITE-03 | Negative `rg` scan for forbidden phrasing in `NEWS.md` and `58-VERIFICATION.md` |

### Feedback Strategy

- Quick local check after helper/script work: `rtk Rscript --vanilla tools/inspect-pkgdown-publication.R --site-root docs`.
- Focused test check: `rtk Rscript --vanilla -e 'testthat::test_file("tests/testthat/test-pkgdown-site.R")'`.
- Generated-site gate: `rtk Rscript --vanilla tools/validate-pkgdown-site.R --mode quick`.
- Release/site rebuild before final evidence: `rtk Rscript --vanilla tools/validate-pkgdown-site.R --mode release`.
- Remote/deploy evidence:
  - preferred: authenticated `gh` trigger/download path;
  - fallback: fetch and inspect `origin/gh-pages`;
  - if auth blocks `gh`, record that blocker explicitly.

## Risks

- **Auth/permissions:** Local `gh` is installed but auth is invalid. Plan and docs need fallback commands and setup classification.
- **Remote currentness:** `origin/gh-pages` can prove publication but may lag local source commits. Evidence must record the source SHA and not overclaim currentness.
- **Artifact structure drift:** `gh run download` extracts artifacts into directories based on artifact name. The inspector should validate a site root and docs should show the expected `test_output/github-run-<run-id>/pkgdown-site-<run-id>` path.
- **Raw log sprawl:** Keep logs and downloaded artifacts out of committed docs; summarize IDs and outcomes only.

## Research Complete
