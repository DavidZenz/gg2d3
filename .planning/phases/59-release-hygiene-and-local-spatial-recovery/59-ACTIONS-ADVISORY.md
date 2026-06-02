# Phase 59 Actions Runtime Advisory Audit

**Date:** 2026-06-02
**Status:** source mitigation planned

## Runtime Context

GitHub's Node 20 deprecation path affects JavaScript-based GitHub Actions. Node 20 reached end of life in April 2026, and GitHub's changelog says hosted runners begin using Node 24 by default on June 16, 2026. The release hygiene target for this phase is to use current action versions that run on Node 24 where viable.

The current mitigation target is `actions/upload-artifact@v6`, which the upstream release notes identify as the Node 24 runtime release for artifact uploads. Its documented runner requirement is Actions Runner `2.327.1` or newer; this repository uses GitHub-hosted `ubuntu-latest` runners, so the source-level expectation is compatibility unless the workflow run proves otherwise.

## Workflow Audit

| Workflow | Action | Current source state | Advisory relevance | Decision |
|----------|--------|----------------------|--------------------|----------|
| `.github/workflows/pkgdown.yaml` | `actions/checkout@v6` | already current | Node 24-capable checkout line already present | keep |
| `.github/workflows/pkgdown.yaml` | `actions/upload-artifact@v4` | stale artifact upload action | known Node 20 advisory source | upgrade to `actions/upload-artifact@v6` |
| `.github/workflows/pkgdown.yaml` | `r-lib/actions/setup-r@v2` | R setup action | audit in workflow run for residual warnings | keep unless run evidence says otherwise |
| `.github/workflows/pkgdown.yaml` | `r-lib/actions/setup-r-dependencies@v2` | R dependency setup action | audit in workflow run for residual warnings | keep unless run evidence says otherwise |
| `.github/workflows/pkgdown.yaml` | `JamesIves/github-pages-deploy-action` | pinned deploy action SHA | possible third-party residual warning surface | keep pinned; classify run warning if present |
| `.github/workflows/browser-visual-smoke.yaml` | `actions/checkout@v6` | already current | Node 24-capable checkout line already present | keep |
| `.github/workflows/browser-visual-smoke.yaml` | `actions/upload-artifact@v4` | stale artifact upload action | known Node 20 advisory source | upgrade to `actions/upload-artifact@v6` |
| `.github/workflows/browser-visual-smoke.yaml` | `r-lib/actions/setup-r@v2` | R setup action | audit in workflow run for residual warnings | keep unless run evidence says otherwise |
| `.github/workflows/browser-visual-smoke.yaml` | `r-lib/actions/setup-r-dependencies@v2` | R dependency setup action | audit in workflow run for residual warnings | keep unless run evidence says otherwise |

## Mitigation Decision

`actions/upload-artifact@v4` will be upgraded to `actions/upload-artifact@v6` unless execution-time release verification finds a blocker.

The source-level change must preserve existing artifact names, paths, `if-no-files-found` values, and `retention-days: 14`.

source outcome: artifact upload actions upgraded to actions/upload-artifact@v6

Next Evidence: Run pkgdown.yaml and browser-visual-smoke.yaml after this commit and record run IDs in 59-VERIFICATION.md.

## Verification Plan

1. Confirm source no longer contains `actions/upload-artifact@v4` in `.github/workflows/pkgdown.yaml` or `.github/workflows/browser-visual-smoke.yaml`.
2. Confirm both workflows contain `actions/upload-artifact@v6`.
3. Run or inspect both workflows after the source commit.
4. Record run IDs, conclusions, head SHAs, and advisory state in `59-VERIFICATION.md`.

## Residual Risks

- `actions/upload-artifact@v6` requires Actions Runner `2.327.1` or newer. GitHub-hosted `ubuntu-latest` is expected to satisfy this, but the workflow run is the release evidence.
- A third-party or r-lib action may still emit advisory noise. If no newer viable action is available, record the warning as upstream-known mitigation with a tested green run.
