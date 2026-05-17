---
phase: 31
plan: 03
type: execute
wave: 2
status: in-progress
date: 2026-05-16
---

# Plan 31-03 Summary — Local pkgdown build + D-14 automated proxies

## Local Build

- Command: `Rscript -e 'pkgdown::build_site_github_pages(new_process = FALSE, install = FALSE)'`
- Prerequisite (added during plan): `R CMD INSTALL .` — pkgdown's reference building requires the package to be loadable as a library; `pkgload`-only is insufficient.
- Final exit code: 0 (after two in-phase fixes documented below).
- Build log: `/tmp/gg2d3-pkgdown-build.log`
- Warnings: none (pkgdown's `── Checking for problems ──` section produced no output).

## D-14 Automated Proxies

| # | Check | Status |
|---|-------|--------|
| 1 | `test -f docs/.nojekyll` | PASS |
| 2 | `grep -E 'src="[^"]*d3\.v7\.min\.js"' docs/articles/gg2d3.html` | PASS (1 occurrence) |
| 3 | `grep -E 'class="[^"]*html-widget' docs/articles/gg2d3.html` | PASS (45 occurrences — every chunk produces a widget) |
| 4 | `test -d docs/articles/gg2d3_files` | PASS (`d3-7`, `gg2d3-binding-0.1.0`, `gg2d3-modules-0.0.1`, `htmltools-fill-0.5.9`, `htmlwidgets-1.6.4`) |
| 5 | build exit 0 | PASS |

## Side-decision verifications

| Decision | Check | Status |
|----------|-------|--------|
| D-07 (default `news:`) | `test -f docs/news/index.html` | PASS |
| D-09 (Get started promotion) | `grep "Get started" docs/index.html` | PASS |
| D-10 (no diagnostics in published output) | `find docs -name "*diagnostic*"` returns nothing | PASS |
| D-11 (README → homepage) | `test -f docs/index.html` | PASS |
| D-13 (no /dev/ split) | `! test -d docs/dev` | PASS |

## In-phase fixes applied (D-15 caught these locally — exactly its purpose)

### Fix 1: `R CMD INSTALL .` prerequisite

**Symptom:** First build attempt failed at "Building function reference" with `there is no package called 'gg2d3'`.

**Root cause:** `pkgdown::build_site_github_pages(install = FALSE)` skips the package install step but the reference-building step internally calls `library(pkg$package)` which requires the package to be on the library path.

**Fix:** Install the source tree once: `R CMD INSTALL --no-multiarch --with-keep.source .`. Subsequent builds reuse the installed copy.

**Future implication:** The Plan 04 GitHub Actions workflow uses the canonical r-lib template, which calls `pak::pkg_install("local::.")` in a setup step — this is the CI-side equivalent. No workflow change needed.

### Fix 2: vignette `eval = FALSE` + pervasive precedence bug

**Symptom:** After moving to Plan 02's renamed `vignettes/gg2d3.Rmd`, proxies 2/3/4 (widget plumbing) failed because no chunk produced a widget.

**Root cause 1 — `eval = FALSE`:** The vignette had `knitr::opts_chunk$set(eval = FALSE)` globally. With chunks not evaluating, no `gg2d3()` call ever produces an htmlwidget, so the rendered HTML has no `html-widget` div and no `d3.v7.min.js` script tag. The decision to ship docs **with** live widgets (D-14, D-15) requires eval=TRUE.

**Root cause 2 — `+ X |> gg2d3()` precedence:** Virtually every chunk (~30 of them) used the pattern:
```r
ggplot(iris, ...) +
  geom_point() |>
  gg2d3()
```
R's `|>` binds tighter than `+`, so this parses as `ggplot(...) + (geom_point() |> gg2d3())` — calling `gg2d3()` on a bare layer, which then errors with "Provide a ggplot object or a valid IR list." The pre-existing `eval = FALSE` had been masking this defect. Worse, the original Tips section at the bottom of the vignette **documented this incorrect idiom as a feature** — author had never run it.

**Fix:**
- Set `eval = requireNamespace("gg2d3", quietly = TRUE) && requireNamespace("ggplot2", quietly = TRUE)` (guarded eval — runs locally and on CRAN-builders that have the package; safely skips on minimal CRAN check envs).
- Wrap every `ggplot(...) + ...` expression in parentheses before `|> gg2d3()` (~30 chunks).
- Rewrote the Tips section to correctly explain the precedence and recommend either parenthesisation or explicit assignment.

**Root cause 3 — crosstalk chunk fails under newer ggplot2:** The crosstalk chunk at lines 450-464 calls `ggplot(shared, ...)` where `shared` is a `crosstalk::SharedData` object. Newer ggplot2 (4.0.x) does not accept `SharedData` directly — `fortify()` errors with "data must be a data.frame". This is a separate cross-ecosystem issue and not in scope to fix in Phase 31.

**Fix:** Set `eval = FALSE` on the single crosstalk chunk only. The remaining 30+ chunks still evaluate; the crosstalk chunk renders as code-only documentation. Acceptable since crosstalk integration is verified via tests, not vignettes.

## Deviations from CONTEXT (applied)

- **Scope deviation from Plan 31-03 as written:** the plan's in-phase fix guidance covered `htmltools::tagList()` wrapping and `screenshot.force = FALSE`, but the actual fix needed was a vignette-wide chunk rewrite for an R-precedence bug that pre-dated Phase 31. User approved expanded scope (option "Fix all chunks in-phase") before the rewrite — exact dialogue captured in the orchestrator transcript. The fix is contained to `vignettes/gg2d3.Rmd`; no other source files touched.

## Files modified during Plan 31-03

- `vignettes/gg2d3.Rmd` (eval guard + parenthesise 30 chunks + crosstalk chunk eval=FALSE + Tips section rewrite)
- `docs/` build output (gitignored, not committed)
- `.planning/phases/31-pkgdown-and-gh-pages-publishing/31-03-SUMMARY.md` (this file)

## Human Preflight (Task 3.2)

### Round 1 — issues surfaced

The human inspected the locally-served `docs/` at `http://localhost:4321/` and found:

1. **`geom_path` example not visibly a circle** — the chunk used `cos(1:50)` / `sin(1:50)` without `coord_fixed()`. ggplot2 also wouldn't render as a circle without `coord_fixed()` — fix applied in-phase: rewrote the chunk to sweep a full `0..2π` and added `coord_fixed()`.
2. **`coord_flip` + `geom_boxplot` chunk** — y-axis title overlays tick labels. Real gg2d3 rendering bug. **Out of Phase 31 scope.** Spawned follow-up task "Fix coord_flip + boxplot y-axis label overlay".
3. **`facet_wrap(scales = "free")` chunk** — y-axis tick labels render inside each panel instead of on the outer left edge. Regression of a previously-fixed issue. **Out of Phase 31 scope.** Spawned follow-up task "Fix facet_wrap(scales=\"free\") y-tick labels inside panel regression".
4. **Interactivity sub-site empty** — `vignettes/gg2d3-interactivity.Rmd` still had `eval = FALSE`. Fix applied in-phase: same eval guard + `eval = FALSE` on the crosstalk chunk only (SharedData/ggplot incompatibility — same as the gg2d3.Rmd crosstalk chunk). Sub-site now shows 21 widget divs (verified `grep -c html-widget docs/articles/gg2d3-interactivity.html` = 21).
5. **"Combining features" chunk** produces many warnings. Likely a symptom of #3 (free-scale facet rendering path) plus geom_smooth SE bands. **Out of Phase 31 scope.** Spawned follow-up task "Audit pkgdown vignette rendering output for warnings".

### Round 2 — issues surfaced

Human re-inspected after Round 1 fixes. The path chunk now renders correctly as a circle. Two new gg2d3 bugs surfaced in the interactivity sections (now visible because Round 1 enabled eval on the interactivity vignette):

6. **`d3_tooltip(fields = c("wt", "mpg"))` shows "undefined"** — field-filtering tooltip path is broken; default `d3_tooltip()` (no args) works. Likely cause: tooltip JS looks up original variable names but IR stores aesthetic names. **Out of Phase 31 scope.** Spawned follow-up task "Fix d3_tooltip(fields = ...) showing undefined instead of values".
7. **`d3_zoom()` on `geom_line()` plot** — axes zoom/pan correctly but the line itself stays static. Affects default zoom, `direction = "x"`, `direction = "y"`, and `scale_extent` variants. Zoom transform not propagated to line/path geom rendering. **Out of Phase 31 scope.** Spawned follow-up task "Fix d3_zoom not transforming line/path geoms".

### Round 3 — rebuild on master with all 5 fixes merged, new issue surfaced

After porting Phase 19 → Phase 31 on master and confirming all 5 spawned gg2d3 fixes were merged (commits 96dedc1, 1f78131, 2bb8d92, d178f8e/fd01f1c, fee31ae), rebuilt locally on branch `claude/phase-29-pkgdown`:

- `R CMD INSTALL .` → DONE
- `pkgdown::build_site_github_pages(new_process = FALSE, install = FALSE)` → exit 0, **0 build warnings**, all 45 widget divs serialized correctly in `docs/articles/gg2d3.html`.
- All 10 D-14 automated proxies still pass.
- All 5 fixes confirmed wired in (source-level grep).

**However:** browser inspection at `http://localhost:4321/articles/gg2d3.html` shows only the first **12 of 45 widgets render**. From "Statistical geoms" onwards (widgets 13–45), the div is present and the JSON IR data block is present, but the div stays empty.

Diagnostics:
- `binding.find(document)` returns 45 widgets → htmlwidgets sees them all.
- `binding.renderValue()` works on every widget when manually invoked → gg2d3's renderer is sound.
- Calling `HTMLWidgets.staticRender()` a SECOND time after page load renders all remaining 33 widgets cleanly (12 → 45).
- 0 console errors throughout.

Conclusion: the bug is in HTMLWidgets' first staticRender pass silently aborting after the 12th widget. **Not a gg2d3 bug per se** — but blocks Phase 31 publishing because the published site would show empty divs for two-thirds of the Get-started article.

**Spawned follow-up task:** "Fix HTMLWidgets.staticRender halting partway through pkgdown article" — bisect the 5 recent fixes, inspect htmlwidgets-1.6.4 staticRender source, and resolve.

### Rounds 4–7 — successive polish passes on top of the merged fixes

After all 5 follow-up fixes landed on master and were composed with each other on `claude/phase-29-pkgdown`, the local pkgdown build surfaced (and we resolved) several more visual / interaction issues. Each was found by re-inspecting the served `docs/` and triaged against the documented behavior or D-14 expectation:

| Round | Symptom | Root cause | Fix |
|---|---|---|---|
| 4 | `geom_line` non-finite gap vanished | `line.js` filtered NA before `d3.line()` | Keep all points, install `.defined()` predicate, skip x-sort when any point is non-defined so the null breaks the sub-path at the right visual position |
| 4 | Legend "Reset" overflowed to "Re"; legend touched panel | `estimateLegendDimensions` under-reserved width; slice order in `layout.js` put gap on the wrong side | Include Reset width in title estimate; slice legend first then carve the spacing gap from the panel-adjacent side |
| 4 | Legend click highlighted legend but didn't dim plot marks | Geoms wrote `data-legend-key` as the resolved aesthetic value (`colour::#00BA38`); legend items used the factor level (`colour::4`) | `applyLegendState` resolves keys through the controller's candidate set first; geom attribute used as fallback only |
| 5 | Violin/density legend toggle didn't dim paths | `.datum(pts)` binds an array of `{x, y, d}` wrappers; `resolveLegendKeyForDatum` probed the wrapper instead of the row at `.d` | `resolveLegendKeyForDatum` now unwraps `Array → first → .d` |
| 5 | Tooltip showed `[object Object]` on smooth/line/area | `format()` iterated `Object.keys(array)` | Same unwrap pattern in `format()` |
| 5 | Reset rendered inline next to title, overlapped panel | Title-row Reset broke at long titles | Moved to its own row below the keys (vertical + horizontal); reserved `resetRowHeight` in both `renderGuide` bg height and `estimateLegendDimensions` |
| 6 | No visible gap between panel and legend | Slice order subtle — sliced spacing carved gap on the **far** side of the legend, not between panel and legend | Re-ordered: slice legend first, then carve spacing from the panel side of remaining box. Verified gap = 15px (matches `theme.legend.spacing` ≈ 14.61px) |
| 6 | Footer said "Developed by First Last." | `DESCRIPTION` carried the `create_package()` skeleton author | `desc::desc()$set_authors(person("David", "Zenz", , "office@davidzenz.com", role = c("aut","cre")))` |
| 6 | Interactivity sub-page empty | `vignettes/gg2d3-interactivity.Rmd` wasn't ported from stupefied-austin | Copied it across; now 21/21 widget divs |
| 6 | Custom tooltip `formatter = "function(d) {…}"` ignored | Old per-field API only; my fix accepted only `(d)`; both APIs are documented | Dual-arity support: `customFn.length <= 1` → whole-row early return; `>= 2` → per-field iteration |
| 7 | Tooltips stopped showing entirely | I introduced a duplicate `const aesByVar` in the same function scope → silent `SyntaxError` killing `format()` | Removed the duplicate |
| 7 | `Species: #F8766D` instead of `Species: setosa` | IR row only carries post-mapping aesthetic values | Build a reverse `{resolvedValue → factor label}` lookup from `ir.guides[i].keys` and apply during both enrichment and per-field rendering. Covers colour/color/fill/shape/size/alpha/linetype |
| 7 | `d3_hover` default opacity 0.7 not distinctive | Subjective polish | `R/d3_hover.R` default 0.7 → 0.3; updated roxygen + both vignettes |
| 7 | Reset for `position = "bottom"` left-aligned | Was using `x = defaults.margin` regardless | Center for horizontal direction: `x = contentWidth/2`, `text-anchor = "middle"` |
| 7 | Bottom-position legend had no Reset | Reset rendering was vertical-only | Reset row now rendered for both directions |

Also: ran `devtools::document()` which exposed previously-undocumented sf functions (`detect_dominant_geom_type`, `extract_sf_geometries`, `get_layer_crs`, `normalize_to_wgs84`) and `d3_handlers` / `d3_transitions` in `NAMESPACE`. Added them to `_pkgdown.yml` reference index to keep the build clean.

### Sign-off

**Approved by user 2026-05-17 after multi-round live inspection.**

All 10 D-14 automated proxies still pass. Both vignettes render fully (`gg2d3.html` 45/45 widgets, `gg2d3-interactivity.html` 21/21 widgets). Interactivity verified: tooltips show factor labels, legend toggles dim correct marks across point/violin/density/smooth/line geoms, zoom transforms lines, hover dims with reasonable contrast, custom formatters work with both `(d)` and `(field, value)` shapes, legend gap is 15px from panel, Reset positioned below keys (centered for horizontal legends).

One acknowledged-not-fixed observation: facet_wrap/grid with `scales = "free"` produces panel-specific grid spacing — this is intentional ggplot2 behavior (each panel's `breaks_extended()` picks nice ticks for its own range), not a gg2d3 bug.

Plan 31-03 complete. Plans 31-04 (workflow + gh-pages bootstrap) and 31-05 (D-14 published-site verification) are now unblocked.
