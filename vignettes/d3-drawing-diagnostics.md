# Known limitations

This document lists current limitations of gg2d3's D3 renderer compared to
native ggplot2 output. These are areas where the D3 rendering may differ
from what ggplot2 produces.

## Geom coverage

gg2d3 supports core Cartesian geoms (point, line, path, bar, col, rect, tile,
text, label, polygon, area, ribbon, segment, hline/vline/abline, boxplot, violin,
density, smooth) plus polygon-family, point-family, and line-family `geom_sf`
and projected-anchor `geom_sf_text()` / `geom_sf_label()` annotations.

Geoms outside this set (for example `geom_contour`) log a warning and do not
render.

## v1.13 release validation overview

The v1.13 release documentation, validation, and geometry contract is built from
source docs, source tests, generated help, and summarized validation evidence.
The primary release validation commands are:

```bash
Rscript --vanilla -e 'devtools::document(); devtools::build_readme()'
Rscript --vanilla -e 'devtools::test()'
R CMD build --no-manual /path/to/gg2d3
R CMD check --as-cran gg2d3_0.0.0.9000.tar.gz
```

Focused v1.13 gates cover:

- browser visual smoke behavior and artifacts from Phase 52, including the
  dedicated `.github/workflows/browser-visual-smoke.yaml` workflow and
  `GG2D3_BROWSER_VISUAL_CI` mode;
- renderer contracts from Phase 53 through
  `inst/htmlwidgets/modules/geom-contracts.js` and
  `tests/testthat/test-renderer-wiring-contracts.R`;
- selected IR helper-boundary coverage from Phase 53 through
  `tests/testthat/test-ir-helper-boundaries.R`;
- bounded Phase 54 geometry support for ordinary `geom_label()`,
  `geom_polygon()`, `geom_rect()`, and `geom_tile()`.

Release evidence should summarize command outcomes and artifact paths, not
paste browser logs, `00check.log` contents, or raw generated artifacts into
public documentation.

## Pkgdown site evidence

Pkgdown evidence answers a different release-readiness question than browser
visual smoke. Use these artifact classes consistently:

- source docs (`README.Rmd`, `vignettes/`, roxygen comments, and `NEWS.md`)
  define the intended public support contract;
- generated `docs/` proves the local/pkgdown rendering path and is the
  committed publication surface for articles, reference pages, and NEWS;
- GitHub Pages or deploy output proves that the generated site was published
  from the workflow target; and
- browser visual smoke artifacts under `test_output/browser-visual-smoke/`
  prove representative browser behavior for selected rendered fixtures.

The generated pkgdown site should show current support text and real
htmlwidget scaffolding before release claims rely on it. Browser visual smoke
remains downstream inspection evidence for rendered behavior, not a substitute
for source-to-site freshness.

### Generated-site validation gate

Use the generated-site gate whenever source documentation, widget dependencies,
or pkgdown workflow behavior changes.

Quick local validation inspects the committed generated `docs/` output without
rebuilding:

```sh
rtk Rscript --vanilla tools/validate-pkgdown-site.R --mode quick
```

Release validation rebuilds source-derived README/help/pkgdown output before
checking the same generated-site markers:

```sh
rtk Rscript --vanilla tools/validate-pkgdown-site.R --mode release
```

The focused `testthat` entrypoint uses the same validation helper and remains
the canonical test-suite integration:

```sh
rtk Rscript --vanilla -e 'testthat::test_file("tests/testthat/test-pkgdown-site.R")'
```

CI mode is run by the pkgdown workflow after `Build site` and before deploy:

```sh
Rscript tools/validate-pkgdown-site.R --mode ci
```

Failure classes are intentionally narrow:

- stale generated content: source markers exist but generated article/reference
  pages no longer contain the current support contract;
- missing widget scaffolding/assets: generated article HTML lacks
  `gg2d3 html-widget`, `d3.v7.min.js`, `gg2d3-modules`, or the
  `docs/articles/gg2d3_files/gg2d3-modules-0.0.1` asset path;
- pkgdown build failure: release mode cannot regenerate source-derived docs or
  site output; and
- optional spatial dependency classification: local quick mode may pass with
  `PKGDOWN_SF_OPTIONAL_SKIP` when `sf` or `geojsonsf` cannot load, while
  release and CI mode require rendered sf evidence when both packages are
  loadable.

Repair stale generated-site evidence by editing the source docs first, running
release validation or the documented rebuild commands, inspecting the generated
`docs/` diff, rerunning quick validation, and committing the required
source/generated evidence together. Downloaded GitHub Pages artifact inspection
is a Phase 58 release-evidence step, not part of this Phase 57 local generated
site gate.

### Local sf/GDAL diagnostics

When local generated-site validation reports `classified_skip` for the sf
article example, first check whether the local spatial stack can load:

```sh
rtk Rscript --vanilla tools/diagnose-spatial-stack.R
```

To inspect a specific generated or downloaded site root, pass `--site-root`:

```sh
rtk Rscript --vanilla tools/diagnose-spatial-stack.R --site-root docs
```

The diagnostic output includes stable markers:

- `sf:` reports whether the `sf` namespace is loadable and includes the load
  error when a dynamic library such as GDAL is missing;
- `geojsonsf:` reports whether the GeoJSON serializer dependency is loadable;
- `pkgdown sf outcome:` reports `rendered`, `classified_skip`, `missing`, or
  `site_root_unavailable`; and
- `recommendation:` names the next action.

A local `classified_skip` is acceptable in quick validation only when the
diagnostic reports `sf` or `geojsonsf` as not loadable. In that case this is
local environment repair, not a gg2d3 regression. Repair or reinstall the local
spatial stack through the maintainer's package manager and R library setup, then
rerun release validation to convert local evidence from `classified_skip` to
rendered sf output:

```sh
rtk Rscript --vanilla tools/validate-pkgdown-site.R --mode release
```

### Publication artifact inspection

The generated-site validation gate proves the local `docs/` contents. The
publication inspection step proves that a workflow artifact or deployed site root
exposes the same current sf/widget evidence outside the repository layout.

Trigger the pkgdown workflow when remote evidence is needed:

```sh
gh workflow run pkgdown.yaml --ref master
```

Find the run ID, status, source commit, and run URL:

```sh
gh run list --workflow pkgdown.yaml --branch master --limit 5 --json databaseId,status,conclusion,headSha,url
```

Download the validation-backed pkgdown site artifact for a concrete run:

```sh
gh run download <run-id> --pattern "pkgdown-site-*" --dir test_output/github-run-<run-id>
```

Inspect the downloaded publication root:

```sh
rtk Rscript --vanilla tools/inspect-pkgdown-publication.R --site-root test_output/github-run-<run-id>/pkgdown-site-<run-id>
```

If `gh auth status` reports an authentication problem, use the GitHub Actions UI
to download `pkgdown-site-<run-id>` from the run artifacts, or inspect a fetched
`origin/gh-pages` checkout with the same `--site-root` command:

```sh
git fetch origin gh-pages
rtk Rscript --vanilla tools/inspect-pkgdown-publication.R --site-root <gh-pages-checkout>
```

Downloaded artifacts under `test_output/github-run-*` are local inspection
artifacts. Do not commit them; record only the run ID, source SHA, inspected
site root, and command outcome in release evidence.

## Ordinary `geom_polygon()` support

Ordinary `geom_polygon()` renders grouped closed SVG paths from ggplot2 built
data. Row order is preserved inside each group, core fill/stroke/alpha/
linewidth/linetype styling is carried through, and facets plus existing
tooltip, hover, brush, handler, and linked-view hooks are supported at the path
mark level.

Residual risks remain explicit: topology and hole behavior beyond clean grouped
closed paths is not shipped by Phase 54. Focused fixtures prove that ggplot2
built data may include `subgroup` and `rule` values for hole-style polygon
input, but gg2d3's ordinary polygon IR does not currently preserve `subgroup`
or render compound paths. The ordinary polygon renderer does not infer GIS
topology, ring containment, hole winding, self-intersection handling, or
invalid-polygon repair; users should provide groups that ggplot2 already builds
into the intended path order.

## `geom_sf` support

`geom_sf()` support exists for polygon-family (`POLYGON`, `MULTIPOLYGON`),
point-family (`POINT`, `MULTIPOINT`), and line-family (`LINESTRING`,
`MULTILINESTRING`) layers. Polygon and line families render as SVG paths; point
families render as SVG circle marks. Known CRS inputs are normalized to WGS84 in
R before serialization. If a layer has no CRS, gg2d3 warns that coordinates
will be serialized as-is.

Unsupported, empty, invalid, or missing sf geometries are skipped with a
warning while accepted rows remain renderable. `GEOMETRYCOLLECTION` expansion is
not supported.

`geom_sf_text()` and `geom_sf_label()` are supported for the accepted sf
families above. They render text and label groups at projected anchors aligned
with the same panel projection used by polygon, point, and line sf marks.
Tooltip, hover, handler, and brush behavior reuse the existing `.geom-sf`
interaction path with sanitized public payloads.

Interactivity targets `.geom-sf` polygon, point, and line marks. Tooltip,
hover, custom handler, and Shiny-style callback payloads are sanitized
source-row objects. Brush selection uses representative-anchor brushing from
rendered `data-cx` and `data-cy` anchors rather than geometric intersection.
Optional browser validation is R/testthat/chromote based and may skip cleanly;
when available, it covers sf family interactivity, stacked overlays, faceted and
empty panels, skipped rows, and zoom suppression.

## Browser visual smoke artifacts

Maintainers can generate local browser-rendered visual smoke artifacts with the
opt-in test runner. The skip-friendly command is:

```bash
Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-browser-visual-smoke.R")'
```

The full artifact command is:

```bash
NOT_CRAN=true GG2D3_BROWSER_VISUAL_SMOKE=true Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-browser-visual-smoke.R")'
```

The CI-equivalent local command is:

```bash
NOT_CRAN=true GG2D3_BROWSER_VISUAL_SMOKE=true GG2D3_BROWSER_VISUAL_CI=true Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); res <- testthat::test_file("tests/testthat/test-browser-visual-smoke.R"); df <- as.data.frame(res); if (any(df$failed > 0 | df$error)) quit(status = 1)'
```

In CI, the dedicated workflow is `.github/workflows/browser-visual-smoke.yaml`.
It runs on pull requests and `workflow_dispatch`, sets
`GG2D3_BROWSER_VISUAL_SMOKE=true` and `GG2D3_BROWSER_VISUAL_CI=true`, and
uploads the full `test_output/browser-visual-smoke/` directory as a workflow
artifact on every run.

Generated files live under `test_output/browser-visual-smoke/`, which is ignored
by git and excluded from package builds. The report files are `index.html` and
`index.json`. `index.html` is the human-readable report, while `index.json`
contains structured row and run metadata. Each executable fixture can also
produce `<fixture>.html`, `<fixture>.png`, `<fixture>-dom-summary.json`, and
`<fixture>-browser-log.json`.

Coverage includes Cartesian geoms, facets, interactivity-facing marks, ordinary
`geom_polygon()`, sf geometry marks, and `geom_sf_text()` /
`geom_sf_label()` annotations. The run may skip explicitly when
`GG2D3_BROWSER_VISUAL_SMOKE` is not true, when Chrome/Chromium or chromote
launch is unavailable, or for sf-dependent rows when `sf` or `geojsonsf` is
unavailable.

Local skip behavior and CI behavior differ intentionally. Local maintainers can
run the skip-friendly command to confirm the harness loads without requiring a
browser. In `GG2D3_BROWSER_VISUAL_CI=true` mode, browser-level unavailability
is a failure so workflow artifacts either prove a browser-rendered run or expose
the failure clearly.

If `chromote::find_chrome()` does not find the intended local browser, set
`CHROMOTE_CHROME=/path/to/chrome` as a troubleshooting override. In the
dedicated CI workflow, browser-level skips are failures; optional `sf` or
`geojsonsf` row skips may pass only when the generated report records them
explicitly. Screenshots are inspection evidence only. Committed baseline image
comparisons and automated image-difference tolerances are deferred until CI
artifacts prove stable across environments.

Map anti-features are explicit: no tile basemaps, no slippy map controls, no
JavaScript-side CRS reprojection, no true geometry-overlap brushing, no
`GEOMETRYCOLLECTION` expansion, and no large-map performance guarantees.

Annotation anti-features are also explicit: repelled label placement, rich text,
and path-following annotation placement are not shipped.
Ordinary text and label layers have bounded `angle` support; sf annotation
rotation parity remains outside the current projected-anchor contract.

## Pkgdown visual regression

Pkgdown visual regression adds browser-rendered widget evidence for the
generated pkgdown article, complementing the text/marker-based validation
from `tools/validate-pkgdown-site.R`. Where the existing gate checks that
source markers are present in generated HTML, this step loads the article
in a real browser and asserts that gg2d3 widgets are not blank or stale.

The test lives in `tests/testthat/test-pkgdown-visual.R` and reuses the
same `helper-browser-visual.R` opt-in infrastructure as the browser visual
smoke tests.

### Prerequisite

`pkgdown::build_site()` (or `build_site_github_pages()`) must have run to
populate `docs/` so `docs/articles/gg2d3.html` exists. The test skips with
"generated docs site is not available" when this file is absent. Build the
site locally before running the capture:

```sh
Rscript --vanilla -e 'pkgdown::build_site(new_process = FALSE, preview = FALSE)'
```

### Local run

The test uses the same `GG2D3_BROWSER_VISUAL_SMOKE=true` opt-in env var as
the browser visual smoke tests — no new env var (D-10). The skip-friendly
command loads the package without the browser:

```bash
Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-pkgdown-visual.R")'
```

The full opt-in command that runs the capture and writes artifacts:

```bash
NOT_CRAN=true GG2D3_BROWSER_VISUAL_SMOKE=true Rscript --vanilla -e \
  'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-pkgdown-visual.R")'
```

Expect `[ FAIL 0 | WARN 0 | SKIP 0 | PASS 7 ]` when Chrome is available
and the site is built. The test skips cleanly when `GG2D3_BROWSER_VISUAL_SMOKE`
is not `true`, when Chrome is unavailable, or when `docs/articles/gg2d3.html`
does not exist.

### Blank/stale detection mechanism

After navigating to `docs/articles/gg2d3.html` in a headless 1280×900
Chromote session and waiting for the page to settle, the test evaluates a
JavaScript IIFE that counts SVG child elements (`path`, `circle`, `rect`,
`line`, `g`) inside each `.gg2d3.html-widget svg`. A widget is considered
rendered when it has **at least 3 SVG child elements** (`.PKGDOWN_VISUAL_SVG_CHILD_THRESHOLD`).
The threshold is documented in `test-pkgdown-visual.R` and is intentionally
adjustable without breaking the interface.

The test then asserts:

1. The page renders **at least 10** gg2d3 SVG widgets
   (`renderedSvgCount >= 10`).
2. **Zero** widgets fall below the SVG child count threshold
   (`blankWidgetCount == 0`).

This detection is **DOM-based and deterministic** — it counts SVG children,
not pixel brightness, brightness histograms, or perceptual difference scores.
Committed baseline images and pixel-threshold comparisons are future work
(FUT-01) and are not part of this mechanism.

### sf and Crosstalk outcome classification

The sf widget region passes in one of two branches (D-06):

- **`rendered`** — `pkgdown_site_sf_outcome()` returned `"rendered"` (sf
  loaded, the polygon example in the article has `.geom-sf` elements). The
  test requires `geomSfCount >= 1` in the DOM summary.
- **`classified_skip`** — the article body carries the
  `PKGDOWN_SF_OPTIONAL_SKIP` notice (sf or geojsonsf is unavailable locally
  or the article example was skipped). The test verifies this notice is
  present in the page text; no `.geom-sf` assertion is made.

Any other outcome (e.g., `"missing"`) causes the test to fail with an
informative message. The same pass-or-classified-skip semantics apply to the
Crosstalk section: `ct_outcome %in% c("rendered", "rendered_unlinked_assets")`
requires at least one `[data-gg2d3-crosstalk-group]` element; `classified_skip`
is accepted without a DOM assertion.

### Artifacts

Written to `test_output/pkgdown-visual/` (gitignored, excluded from package
builds via `.Rbuildignore`):

- `pkgdown-main-article.png` — viewport screenshot (1280×900) of the
  rendered article for human review.
- `pkgdown-main-article-dom-summary.json` — programmatic widget counts:
  `renderedSvgCount`, `blankWidgetCount`, `geomSfCount`,
  `crosstalkGroupCount`, and per-widget SVG child counts. Use this JSON
  for CI gating; check `renderedSvgCount >= 10` and `blankWidgetCount == 0`
  to confirm a passing run.
- `pkgdown-main-article-browser-log.json` — session metadata and browser
  console log entries for debugging.

### CI behavior

Three steps are inserted in `.github/workflows/pkgdown.yaml` **after**
`Build site` and `Validate generated pkgdown site` and **before**
`Upload pkgdown site artifact`:

1. **Locate Chrome for chromote (pkgdown visual)** — a non-fatal step that
   discovers `google-chrome`, `chromium`, or similar and writes
   `CHROMOTE_CHROME=<path>` to `GITHUB_ENV`. When no browser is found it
   exits 0 (non-fatal), so a missing runner Chrome degrades to a test skip
   rather than a workflow failure.
2. **Run pkgdown visual capture** — runs `test-pkgdown-visual.R` with
   `NOT_CRAN=true GG2D3_BROWSER_VISUAL_SMOKE=true GG2D3_BROWSER_VISUAL_CI=true`
   scoped to this step's `env:` block only (not at the job level). A test
   failure exits 1 and fails the workflow. In CI, a test skip escalates to
   a failure when `GG2D3_BROWSER_VISUAL_CI=true` is active.
3. **Upload pkgdown visual artifacts** — uploads `test_output/pkgdown-visual/`
   as `pkgdown-visual-${{ github.run_id }}` with `if: always()` so the PNG
   and JSON evidence is preserved even when the capture step fails.

### Capture scope

Only `docs/articles/gg2d3.html` (the main gg2d3 article) is captured.
The interactivity article is out of scope for this phase (D-07, D-08) and
is not captured.

## Text options

`geom_text()` supports position, size, color, alpha, `hjust`, `vjust`, `angle`,
and `family` for ordinary Cartesian text layers. Ordinary `geom_label()` is a
distinct renderer path that emits SVG label groups with `rect.geom-label-box`
and `text.geom-label-text`; bounded label boxes carry text content, fill,
stroke/colour, alpha, size, numeric padding, `hjust`, `vjust`, `angle`, and
`family`.

These label and text improvements are deliberately bounded. Collision
avoidance, repelled label placement, path-following text, and rich text are
future work rather than hidden behavior in the renderer. Label text is inserted
with SVG text APIs, not HTML insertion.

## Linetype

Dashed and dotted linetypes (`linetype = "dashed"`, `"dotted"`, etc.) are
translated to SVG `stroke-dasharray` patterns. Custom numeric linetype
specifications may not match ggplot2 exactly.

## Theme translation

Most theme elements are translated, but some edge cases are not covered:

- `element_blank()` is handled, but `element_line(arrow = ...)` is not
- `strip.text` rotation is not supported
- `plot.margin` is partially supported (outer margins only)

## Renderer and IR contract boundaries

The internal renderer contract manifest is
`inst/htmlwidgets/modules/geom-contracts.js`. Source-level drift is checked by
`tests/testthat/test-renderer-wiring-contracts.R`, including renderer module
paths, htmlwidgets load order, declared render selectors, update selectors,
interaction selectors, and public payload expectations. Unsupported update or
interaction surfaces should use explicit exceptions with reason strings rather
than bare empty arrays.

Public tooltip, event, brush, and linked-view payload paths are expected to pass
through `window.gg2d3.publicData.sanitizeDatum()` / `publicData.sanitizeDatum`
so renderer-private underscore fields stay out of public row payloads.

On the R side, `as_d3_ir()` remains the orchestrator for plot building, sf
payload routing, coordinate metadata, guides, facets, final IR assembly, and
validation. Focused helpers cover selected scale, layer, facet, theme, and geom
parameter seams, but full `as_d3_ir()` modularization remains deferred to
FUT-03. The generated renderer documentation remains deferred to FUT-04; the
source contract and focused tests are the maintained boundary for now.

These diagnostics do not add committed baseline images or image-difference
gates. Browser visual smoke artifacts remain downstream inspection evidence,
with baseline image comparisons and automated image-difference tolerances still
deferred until CI artifacts prove stable across environments.

## Rect/tile edge cases

Phase 45 closed the deferred `geom_rect` and `geom_tile` out-of-bounds item.
Focused fixtures distinguish scale-limit censoring from `coord_cartesian()` and
SVG clipping: scale limits can produce `NA` bounds before gg2d3 sees the rows,
while coordinate limits preserve finite bounds and rely on the panel clip path.

Confirmed renderer/update mismatches were fixed at the D3 boundary. Categorical
tile positioning now uses band-scale center values with `bandwidth()` dimensions,
rect borders use the registry stroke/linewidth accessors, and the
`rect.geom-rect` update path mirrors band-scale and `coord_flip()` geometry.
Phase 54 added mixed log10/sqrt/reverse transformed-bound evidence and kept the
release boundary at direct scaling of ggplot2-built transformed bounds. The
initial rect/tile renderer now filters non-finite scaled SVG bounds before
emitting `x`, `y`, `width`, or `height`; no inverse-transform math, custom
log/sqrt rect math, or broad scale factory rewrite is shipped.

## Phase 54 residual-risk list

The v1.13 geometry polish contract is deliberately bounded. The following items
are deferred and not shipped by Phase 54:

- Ordinary polygon topology and hole repair beyond grouped closed paths.
- Ordinary polygon `subgroup` / `rule` compound-path rendering.
- Tile basemaps and slippy map controls.
- JavaScript-side CRS reprojection.
- Repelled label placement and collision avoidance.
- Rich text for text and label annotations.
- Path-following annotation placement.

## v1.13 future-work IDs

- **FUT-01:** committed golden screenshots and pixel-diff thresholds after
  local and CI artifacts are stable across operating systems.
- **FUT-02:** public hosted visual reports for pull requests if workflow
  artifacts are not ergonomic enough for maintainers.
- **FUT-03:** full `as_d3_ir()` modularization after the high-risk helper
  boundaries are stable.
- **FUT-04:** generated renderer documentation from declarative geom contracts
  if the contract table becomes the long-term source of truth.
- **FUT-05:** full repelled label placement if demand justifies the dependency
  and algorithmic complexity.
- **FUT-06:** broad GIS-style polygon topology repair only if gg2d3 expands
  beyond ggplot2 rendering parity.

## Private API dependency

The package uses `ggplot2:::calc_element()` to resolve inherited theme
elements. This private API could change in future ggplot2 releases. If theme
translation breaks after a ggplot2 update, this is the likely cause.

## Extension packages

Geoms from ggplot2 extension packages (ggridges, ggrepel, ggforce, etc.) are
not supported. Only geoms from core ggplot2 are recognized by the renderer.
