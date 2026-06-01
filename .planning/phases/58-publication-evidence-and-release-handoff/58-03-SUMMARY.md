# Phase 58-03 Summary - Publication Evidence And Release Handoff

## Outcome

Phase 58-03 passed and closes SITE-02/SITE-03. The pkgdown publication path now has current local generated-site evidence, a successful GitHub Actions run, a downloaded pkgdown artifact, rendered sf artifact inspection, and deploy evidence tied to the source SHA.

## Changes

- Fixed publication-root inspection so an explicit `--site-root` takes precedence over local `docs/`.
- Classified rendered sf artifact output by checking serialized sf payload markers before optional skip markers.
- Added regression coverage for downloaded artifact/site-root precedence.
- Updated Phase 58 verification, validation, requirements, roadmap, and state files to mark v1.14 ready to archive.

## Evidence

| Evidence | Result |
|----------|--------|
| `gh auth status` | Passed for `DavidZenz` when run with keyring access. |
| `pkgdown.yaml` run `26746146558` | Passed for head `d5f77c6bced901248695a0fcc1e44d373acf3950`. |
| Artifact | `pkgdown-site-26746146558`, ID `7327800756`, downloaded to ignored `test_output/github-run-26746146558/pkgdown-site-26746146558`. |
| Artifact inspector | `rtk Rscript --vanilla tools/inspect-pkgdown-publication.R --site-root test_output/github-run-26746146558/pkgdown-site-26746146558 --require-rendered-sf true` passed with `sf outcome: rendered`. |
| Local docs inspector | Passed with `sf outcome: classified_skip`. |
| Quick validator | Passed with `sf outcome: classified_skip`. |
| Focused tests | `test-pkgdown-site.R` passed with 61 expectations. |
| Deploy | `gh-pages` updated to `f19ac66` from source `d5f77c6`. |

## Residual Risks

- GitHub Actions reports a non-blocking Node.js 20 deprecation advisory for `actions/upload-artifact@v4`.
- Local sf remains a classified skip until the local GDAL/spatial dynamic-library stack is repaired.
- Browser visual smoke evidence is carried forward from Phase 55; Phase 58 focused on pkgdown publication evidence.
