---
phase: 57-generated-site-validation-gate
status: complete
created: 2026-06-01
---

# Phase 57 Pattern Map

## Files To Modify Or Create

| Target | Role | Closest Existing Analog | Notes |
| --- | --- | --- | --- |
| `tests/testthat/helper-pkgdown-site.R` | Shared validation helper | `tests/testthat/helper-browser-visual.R` | Test helper sourced automatically by testthat; should contain reusable functions, not tests. |
| `tests/testthat/test-pkgdown-site.R` | Canonical focused assertions | Current `tests/testthat/test-pkgdown-site.R` | Keep testthat as source of truth and call helper functions. |
| `tools/validate-pkgdown-site.R` | Maintainer/CI command wrapper | Existing `tools/` scripts if present; otherwise R package scripts use direct `rtk Rscript` entrypoints | Source helper and expose `--mode quick`, `--mode release`, and `--mode ci`. |
| `.github/workflows/pkgdown.yaml` | CI validation route | Existing `Verify website dependencies` and `Build site` steps | Add validation after build and before deploy. |
| `vignettes/d3-drawing-diagnostics.md` | Maintainer diagnostics | Existing pkgdown artifact taxonomy section | Add command, mode, failure-class, and repair documentation. |
| `README.Rmd` and `README.md` | Short public pointer | Existing validation/taxonomy pointer | Add concise pointer to generated-site validation gate. |
| `.planning/phases/57-generated-site-validation-gate/57-VERIFICATION.md` | Final evidence ledger | `56-VERIFICATION.md` | Map SITE-01 to files and commands. |

## Existing Code Patterns

### Text File Resolution

`tests/testthat/test-pkgdown-site.R` currently resolves both repo-root and package-test working directories:

```r
candidates <- c(path, file.path("..", "..", path))
resolved <- candidates[file.exists(candidates)][1]
```

Phase 57 should preserve this pattern, but centralize it in a helper.

### Marker-Specific Failure Messages

Current generated-site checks use:

```r
info = paste0("Expected ", path, " to contain marker: ", marker)
```

Phase 57 should keep this style and extend it to mode/script failures.

### Optional Dependency Classification

Phase 56 established `PKGDOWN_SF_OPTIONAL_SKIP` as a visible generated-site outcome. Phase 57 should classify it by environment:

- pass in local quick mode;
- fail when rendered sf is required and spatial packages are loadable;
- fail when neither skip nor rendered evidence exists.

### Workflow Step Placement

`.github/workflows/pkgdown.yaml` currently has:

1. verify website dependencies;
2. build site;
3. deploy.

Phase 57 should add validation between build and deploy.

## Constraints

- Do not introduce browser screenshot or pixel comparison checks.
- Do not replace pkgdown or GitHub Pages.
- Do not duplicate validation logic between `testthat` and `tools/`.
- Do not require rendered sf in a local environment where `sf`/`geojsonsf` cannot load.
- Keep raw logs out of planning verification docs.
