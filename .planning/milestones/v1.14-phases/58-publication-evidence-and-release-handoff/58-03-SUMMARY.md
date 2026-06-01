# Phase 58-03 Summary - Publication Evidence And Release Handoff

## Outcome

Phase 58-03 passed and closes SITE-02/SITE-03. The pkgdown publication path now has current local generated-site evidence, successful GitHub Actions runs, downloaded pkgdown artifacts, rendered sf and Crosstalk artifact inspection, deploy evidence tied to the source SHA, and browser-observed linked Crosstalk behavior in the generated article.

## Changes

- Fixed publication-root inspection so an explicit `--site-root` takes precedence over local `docs/`.
- Classified rendered sf artifact output by checking serialized sf payload markers before optional skip markers.
- Added regression coverage for downloaded artifact/site-root precedence.
- Published evaluated Crosstalk examples in the pkgdown articles and fixed linked brushing so one gg2d3 widget updates another widget in the same Crosstalk group.
- Preserved source sf attributes in rendered `geom_sf()` rows so the North Carolina tooltip shows `NAME` and numeric `AREA` instead of `undefined` and the fill hex code.
- Updated Phase 58 verification, validation, requirements, roadmap, and state files to mark v1.14 ready to archive.

## Evidence

| Evidence | Result |
|----------|--------|
| `gh auth status` | Passed for `DavidZenz` when run with keyring access. |
| `pkgdown.yaml` run `26750918812` | Passed for head `c4a21e0`. |
| Artifact | `pkgdown-site-26750918812`, downloaded to ignored `test_output/github-run-26750918812/pkgdown-site-26750918812`. |
| Artifact inspector | `rtk Rscript --vanilla tools/inspect-pkgdown-publication.R --site-root test_output/github-run-26750918812/pkgdown-site-26750918812 --require-rendered-sf true --require-rendered-crosstalk true` passed with `sf outcome: rendered, crosstalk outcome: rendered`. |
| Artifact sf tooltip payload | The North Carolina sf row contains `NAME = "Ashe"`, `AREA = 0.114`, and separate rendered `fill = "#A8B4DB"` for tooltip fields `NAME`, `AREA`. |
| Local browser UAT | Brushing the first pkgdown Crosstalk widget selected 41 rows and dimmed 109 rows in both linked panels. |
| Local docs inspector | Passed with `sf outcome: classified_skip`. |
| Quick validator | Passed with `sf outcome: classified_skip`. |
| Focused tests | `test-pkgdown-site.R`, `test-crosstalk.R`, `test-renderer-wiring-contracts.R`, `test-sf-utils.R`, and `test-interactivity.R` passed locally where dependencies allowed; full sf tests skip locally because `sf` cannot load its GDAL dylib. |
| Deploy | `pkgdown.yaml` run `26750918812` completed deploy to GitHub Pages. |

## Residual Risks

- GitHub Actions reports a non-blocking Node.js 20 deprecation advisory for `actions/upload-artifact@v4`.
- Local sf remains a classified skip until the local GDAL/spatial dynamic-library stack is repaired.
- Browser visual smoke evidence is carried forward from Phase 55; Phase 58 focused on pkgdown publication evidence plus targeted local browser UAT for the generated Crosstalk article.
