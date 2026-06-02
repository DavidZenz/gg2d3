---
phase: 59-release-hygiene-and-local-spatial-recovery
status: partial
created: 2026-06-02
requirements:
  - REL-01
  - REL-02
---

# Phase 59 Validation Strategy

## Validation Matrix

| ID | Requirement | Plan | Evidence | Expected Result | Status |
|----|-------------|------|----------|-----------------|--------|
| 59-VAL-01 | REL-01 | 59-01 | Workflow source audit | `rg -n "upload-artifact@v4|upload-artifact@v6|checkout@v6" .github/workflows` | `upload-artifact@v6` is present, or `upload-artifact@v4` has an explicit mitigation note. | passed |
| 59-VAL-02 | REL-01 | 59-01, 59-03 | GitHub Actions workflow evidence | `gh run list --workflow pkgdown.yaml --branch master --limit 5 --json databaseId,status,conclusion,url` and equivalent browser workflow query | Relevant runs pass or blocker is recorded. | blocked |
| 59-VAL-03 | REL-02 | 59-02 | Spatial diagnostic command | `rtk Rscript --vanilla tools/diagnose-spatial-stack.R` | Output contains `sf:`, `geojsonsf:`, `pkgdown sf outcome:`, and `recommendation:`. | passed |
| 59-VAL-04 | REL-02 | 59-02, 59-03 | Generated-site validation | `rtk Rscript --vanilla tools/validate-pkgdown-site.R --mode quick` | Exits 0 and reports rendered or classified sf outcome. | passed |
| 59-VAL-05 | REL-01, REL-02 | 59-03 | Verification ledger | `rg -n "REL-01|REL-02|Actions advisory|Spatial stack|pkgdown|browser visual|Residual" .planning/phases/59-release-hygiene-and-local-spatial-recovery/59-VERIFICATION.md` | Ledger records all evidence categories and residual risks. | partial |

## Coverage

- `REL-01` is covered by `59-01` and verified in `59-03`.
- `REL-02` is covered by `59-02` and verified in `59-03`.

## Residual Risk Rules

- A local spatial stack failure is acceptable only when diagnosed and documented as local environment repair, not a package/runtime regression.
- A GitHub Actions advisory is acceptable only when latest viable action versions have been tested or the remaining warning is documented as upstream-known with a green workflow outcome.
- Browser visual smoke may classify local browser or optional spatial skips; Phase 59 does not require screenshot-depth checks.
