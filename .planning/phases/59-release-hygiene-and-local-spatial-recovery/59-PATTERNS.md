# Phase 59 Pattern Map

**Mapped:** 2026-06-02
**Status:** Complete

## File Roles

| Target | Role | Closest Existing Pattern |
|--------|------|--------------------------|
| `.github/workflows/pkgdown.yaml` | Pkgdown CI/build/deploy workflow | Existing post-build validation and artifact upload step ordering |
| `.github/workflows/browser-visual-smoke.yaml` | Browser visual CI workflow | Existing Chrome location, test execution, and artifact upload pattern |
| `tools/diagnose-spatial-stack.R` | New maintainer diagnostic command | `tools/validate-pkgdown-site.R` and `tools/inspect-pkgdown-publication.R` CLI argument parsing/root detection |
| `vignettes/d3-drawing-diagnostics.md` | Maintainer diagnostics documentation | Existing generated-site validation and browser visual smoke diagnostics sections |
| `.planning/phases/59-release-hygiene-and-local-spatial-recovery/59-VERIFICATION.md` | Phase evidence ledger | Prior `57-VERIFICATION.md` and `58-VERIFICATION.md` concise evidence tables |

## Existing Patterns To Reuse

### Rscript Tool Entrypoints

`tools/validate-pkgdown-site.R` and `tools/inspect-pkgdown-publication.R` both:

- Parse `commandArgs(trailingOnly = TRUE)`.
- Define a small `value_after()` helper.
- Locate the project root by walking upward until `DESCRIPTION` and expected test helpers exist.
- Source `tests/testthat/helper-pkgdown-site.R`.
- Print a concise final status line.

Use the same shape for `tools/diagnose-spatial-stack.R`.

### Pkgdown Outcome Classification

`tests/testthat/helper-pkgdown-site.R` owns the canonical generated-site classification:

- `pkgdown_site_spatial_loadable()`
- `pkgdown_site_sf_outcome()`
- `pkgdown_site_sf_interactivity_outcome()`
- `pkgdown_site_expect_sf_outcome()`

The diagnostic command should reuse these helpers when reporting pkgdown article outcome, not duplicate HTML parsing.

### Workflow Artifact Upload

Both workflows upload artifacts with:

```yaml
uses: actions/upload-artifact@v4
with:
  name: ...
  path: ...
  retention-days: 14
```

The Phase 59 workflow update should preserve artifact names, paths, `if-no-files-found`, and retention behavior while changing only the action version if the audit confirms compatibility.

### Verification Ledgers

Prior verification files avoid raw log dumps. They record:

- Frontmatter status and key outcomes.
- Commands run as concise rows.
- Requirement coverage.
- Threat mitigation.
- Residual risks.

Use this style for `59-VERIFICATION.md`.

## Data Flow

1. Workflows generate `docs/` and `test_output/browser-visual-smoke/`.
2. Artifact upload publishes those directories for GitHub Actions inspection.
3. Pkgdown helpers classify generated or downloaded site roots.
4. The new spatial diagnostic command reports local package loadability and site outcome.
5. The Phase 59 verification ledger ties local and remote evidence back to `REL-01` and `REL-02`.

## Landmines

- Do not convert optional `sf`/`geojsonsf` dependencies into hard local requirements.
- Do not treat local `classified_skip` as a package regression when `sf` itself cannot load.
- Do not add broad screenshot or visual diff assertions in Phase 59; Phase 60 owns that.
- Do not commit downloaded GitHub Actions artifacts from `test_output/`.
- Do not paste raw workflow logs or large browser artifacts into planning evidence.
