# Phase 45: Rect And Tile Edge Closure - Research

**Researched:** 2026-05-24 [VERIFIED: system date]
**Domain:** ggplot2 rect/tile IR extraction, D3 SVG rectangle rendering, and regression closure evidence [VERIFIED: .planning/ROADMAP.md; R/as_d3_ir.R; inst/htmlwidgets/modules/geoms/rect.js]
**Confidence:** HIGH for codebase surfaces and local ggplot2 behavior; MEDIUM for optional browser execution availability [VERIFIED: source inspection; local R probes]

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

## Implementation Decisions

### Fixture Matrix
- **D-01:** Cover continuous scale limits, `coord_cartesian()` limits, discrete `geom_tile()` grids, reversed scales, `coord_flip()`, and facets.
- **D-02:** Treat scale limits and coordinate limits as distinct behaviors to classify, because ggplot2 drops/clips data differently across those paths.
- **D-03:** Skip transformed scales by default unless research/planning finds an existing high-risk fixture or source-level evidence that they are part of the deferred mismatch.

### Fix vs Non-Issue Threshold
- **D-04:** Fix only behavior that is visibly or DOM-measurably mismatched against ggplot2's expected rect/tile behavior.
- **D-05:** If a suspected issue is compatible with ggplot2 behavior, or is intentionally handled by SVG panel clipping, close it as a non-issue with tests and documented rationale.
- **D-06:** Keep fixes at the renderer or IR boundary implied by the evidence; avoid broad scale or coordinate refactors unless the matrix proves they are necessary.

### Validation Shape
- **D-07:** Use focused IR tests, JavaScript/source contract tests, and optional browser DOM smoke coverage for representative rect/tile cases.
- **D-08:** Do not introduce screenshot or perceptual-diff validation for this phase.
- **D-09:** Browser smoke, if used, should remain CRAN-compatible and optional in the same spirit as prior chromote/browser coverage.

### Closure Documentation
- **D-10:** Update `vignettes/d3-drawing-diagnostics.md` and Phase 45 verification notes so the v1.10 deferred item is closed cleanly.
- **D-11:** Leave broader README/vignette/public documentation updates to Phase 47 unless Phase 45 changes the user-facing support contract.

### Claude's Discretion

- Exact fixture names, helper split, and test-file placement are left to research/planning.
- Planner may decide whether browser DOM smoke is part of plan 45-01, plan 45-02, or a later verification step.
- Planner may choose the precise documentation wording as long as it records whether the issue was fixed or verified as non-reproducible/non-issue.

### Deferred Ideas (OUT OF SCOPE)

- Transformed-scale fixture expansion, unless Phase 45 research finds existing evidence that it belongs in the core matrix.
- Broad public docs, README, roxygen, and vignette updates, covered by Phase 47 unless Phase 45 changes the user-facing support contract.
- Tile basemaps, slippy-map semantics, GIS topology, and non-ggplot map-engine behavior.
- Screenshot or perceptual visual regression infrastructure.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| RECT-01 | Maintainers have a focused regression fixture that reproduces the deferred rect/tile out-of-bounds behavior across relevant scale-limit and coordinate-limit cases, or proves the suspected mismatch is no longer present. [VERIFIED: .planning/REQUIREMENTS.md] | Plan a matrix that probes `ggplot_build()` data, gg2d3 IR rows, and optional rendered DOM geometry for scale limits, coordinate limits, discrete tiles, reverse scales, coord flip, and facets. [VERIFIED: .planning/phases/45-rect-and-tile-edge-closure/45-CONTEXT.md; local R probe] |
| RECT-02 | Confirmed rect/tile out-of-bounds mismatches are fixed in the renderer or IR boundary, while non-issues are locked with tests and documented rationale. [VERIFIED: .planning/REQUIREMENTS.md] | Primary code boundaries are `R/as_d3_ir.R`, `inst/htmlwidgets/modules/geoms/rect.js`, and `inst/htmlwidgets/modules/geom-registry.js`; diagnostics closure belongs in `vignettes/d3-drawing-diagnostics.md`. [VERIFIED: .planning/phases/45-rect-and-tile-edge-closure/45-CONTEXT.md; source inspection] |
</phase_requirements>

## Summary

Phase 45 should be planned as an evidence-first closure phase, not as a speculative rect renderer rewrite. [VERIFIED: .planning/phases/45-rect-and-tile-edge-closure/45-CONTEXT.md] The current deferred note says rect/tile marks are panel-clipped, while bounds beyond scale limits and transformed/reversed interactions are deferred renderer debt pending focused regression evidence. [VERIFIED: vignettes/d3-drawing-diagnostics.md:60-65]

The most important technical split is scale limits versus coordinate limits. A local `ggplot2` 4.0.3 probe showed continuous scale limits convert an out-of-limits rect's four bounds to `NA` in `ggplot_build()` data, while `coord_cartesian()` limits preserve the original bounds and narrow the panel scale domain. [VERIFIED: local R probe using ggplot2 4.0.3] The gg2d3 rect renderer already filters rows whose four bounds are `null`/missing and otherwise relies on SVG panel clipping. [VERIFIED: inst/htmlwidgets/modules/geoms/rect.js:44-48; inst/htmlwidgets/gg2d3.js:22-24,76-77]

**Primary recommendation:** Plan `45-01` to build and classify a focused fixture matrix, then plan `45-02` to either patch `rect.js`/`geom-registry.js` or close the diagnostic note as a verified non-issue with regression tests and Phase 45 verification notes. [VERIFIED: .planning/ROADMAP.md; source inspection]

## Project Constraints (from CLAUDE.md / AGENTS.md)

- Use the package development commands `devtools::load_all()`, `devtools::document()`, `devtools::test()`, `testthat::test_file(...)`, and `devtools::build_readme()` when relevant. [VERIFIED: AGENTS.md; CLAUDE.md]
- D3 v7 is vendored locally under `inst/htmlwidgets/lib/d3/d3.v7.min.js`. [VERIFIED: AGENTS.md; inst/htmlwidgets/gg2d3.yaml]
- The package pipeline is R extraction, JSON-serializable IR, and D3 SVG rendering. [VERIFIED: AGENTS.md; CLAUDE.md]
- Rect/tile support currently flows through `R/as_d3_ir.R` and `inst/htmlwidgets/modules/geoms/rect.js`. [VERIFIED: AGENTS.md; source inspection]
- Shell commands in this repository should be prefixed with `rtk`. [VERIFIED: /Users/davidzenz/.codex/RTK.md]
- Nested CLAUDE files for `R/`, `inst/htmlwidgets/modules/`, `inst/htmlwidgets/modules/geoms/`, `tests/testthat/`, and `vignettes/` contain only memory-context notes and no additional actionable coding directives for this phase. [VERIFIED: local file inspection]
- No `.agents/skills` directory exists, and `.claude/` has local settings/launch files but no project skill directory discovered for this phase. [VERIFIED: `rg --files -uu .planning .claude .agents`]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| ggplot2 rect/tile classification | R Layer / IR | Test layer | `as_d3_ir()` consumes `ggplot_build()` output and serializes `xmin`, `xmax`, `ymin`, and `ymax`; tests should compare ggplot-built rows and IR rows before renderer changes. [VERIFIED: R/as_d3_ir.R:172-193,208-209] |
| Panel clipping behavior | D3 Layer | Browser DOM smoke | The widget defines SVG clip paths per panel and renders data inside a clipped group. [VERIFIED: inst/htmlwidgets/gg2d3.js:22-24,76-77] |
| Rect/tile SVG geometry | D3 Layer | R Layer / IR | `rect.js` computes `x`, `y`, `width`, and `height` from serialized bounds for initial render. [VERIFIED: inst/htmlwidgets/modules/geoms/rect.js:83-164] |
| Zoom/update parity | D3 Layer | Source contract tests | `geom-registry.js` separately updates existing `rect.geom-rect` marks; any geometry fix that affects scale math must keep this update path aligned. [VERIFIED: inst/htmlwidgets/modules/geom-registry.js:202-249] |
| Closure documentation | Documentation | Verification notes | The active deferred note lives in diagnostics, and Phase 45 success criteria require recording the outcome. [VERIFIED: vignettes/d3-drawing-diagnostics.md:60-65; .planning/ROADMAP.md] |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| R | 4.6.0 local; package requires >= 4.1.0 | Runs package code and tests. [VERIFIED: local Rscript; DESCRIPTION] | Existing project runtime. [VERIFIED: DESCRIPTION] |
| ggplot2 | 4.0.3 local | Builds plots into layer data and scale/panel metadata. [VERIFIED: local Rscript; R/as_d3_ir.R:9] | `as_d3_ir()` delegates plot construction to `ggplot2::ggplot_build()`. [VERIFIED: R/as_d3_ir.R:9] |
| htmlwidgets | 1.6.4 local | Transports IR to the browser widget. [VERIFIED: local Rscript; DESCRIPTION] | Existing widget framework. [VERIFIED: R/gg2d3.R; DESCRIPTION] |
| D3 | vendored v7 dependency; minified file reports 7.9.0 | Renders SVG scales and rectangles in browser. [VERIFIED: inst/htmlwidgets/gg2d3.yaml; inst/htmlwidgets/lib/d3/d3.v7.min.js] | Existing renderer stack; no new JS rendering library is needed. [VERIFIED: inst/htmlwidgets/gg2d3.yaml] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| testthat | 3.3.2 local; package suggests >= 3.0.0 | R IR tests and source-contract tests. [VERIFIED: local Rscript; DESCRIPTION] | Required for RECT-01/RECT-02 regression coverage. [VERIFIED: .planning/codebase/TESTING.md; tests/testthat] |
| pkgload | 1.5.2 local | Loads package code for targeted command-line tests. [VERIFIED: local Rscript] | Use in quick Rscript test commands. [VERIFIED: tests/testthat/test-regression-core.R:1] |
| V8 | 8.2.0 local | Optional JS/source execution checks. [VERIFIED: local Rscript; DESCRIPTION] | Use only if source contract tests need JS evaluation without a browser. [VERIFIED: tests/testthat/test-layout-facet-free.R] |
| chromote | 0.5.1 local | Optional browser DOM smoke tests. [VERIFIED: local Rscript; DESCRIPTION] | Use for representative rendered `rect.geom-rect` DOM checks with clean skips. [VERIFIED: tests/testthat/helper-browser-polygon.R] |
| rprojroot | 2.1.1 local | Locates package root for browser artifact output. [VERIFIED: local Rscript; tests/testthat/helper-browser-polygon.R] | Reuse helper pattern if creating a rect browser helper. [VERIFIED: tests/testthat/helper-browser-polygon.R] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| DOM/source assertions | Screenshot/perceptual diffs | Explicitly out of scope for this phase. [VERIFIED: .planning/phases/45-rect-and-tile-edge-closure/45-CONTEXT.md] |
| Existing `rect.js` renderer | New rect/tile rendering engine | A rewrite is not justified unless the fixture matrix proves renderer math is wrong. [VERIFIED: .planning/phases/45-rect-and-tile-edge-closure/45-CONTEXT.md] |
| Existing optional chromote pattern | Mandatory browser gate | Browser smoke must remain optional and CRAN-compatible. [VERIFIED: .planning/phases/45-rect-and-tile-edge-closure/45-CONTEXT.md; tests/testthat/helper-browser-polygon.R] |

**Installation:** No new dependency installation is recommended for Phase 45; required packages are already declared or suggested in `DESCRIPTION`. [VERIFIED: DESCRIPTION; local Rscript]

**Version verification:** R package versions were verified locally with `rtk Rscript --vanilla -e 'packageVersion(...)'`, not with `npm view`, because this is an R package phase. [VERIFIED: local Rscript; DESCRIPTION]

## Architecture Patterns

### System Architecture Diagram

```text
ggplot object
  -> ggplot2::ggplot_build()
     -> built layer rows: xmin/xmax/ymin/ymax, PANEL, transformed scale values
        -> as_d3_ir()
           -> layer geom "rect" and row-wise serialized bounds
           -> scales/panels domains and facet metadata
              -> htmlwidgets JSON transport
                 -> gg2d3 renderPanel()
                    -> per-panel x/y D3 scales
                    -> clipped SVG data group
                    -> rect.js initial render
                       -> rect.geom-rect DOM attributes
                    -> geom-registry.js update path for zoom/transition
```

All arrows and components above are present in the current implementation. [VERIFIED: R/as_d3_ir.R; inst/htmlwidgets/gg2d3.js; inst/htmlwidgets/modules/geoms/rect.js; inst/htmlwidgets/modules/geom-registry.js]

### Recommended Project Structure

```text
tests/testthat/
├── test-rect-tile-ir.R          # RECT-01 ggplot_build/as_d3_ir fixture matrix
├── test-rect-tile-renderer.R    # RECT-02 source contract for rect.js/update path
└── test-rect-tile-browser.R     # optional chromote DOM smoke, if planner includes it

vignettes/
└── d3-drawing-diagnostics.md    # closure note for deferred item
```

This structure follows existing test placement and naming conventions. [VERIFIED: .planning/codebase/TESTING.md; tests/testthat/test-polygon-renderer.R; tests/testthat/test-polygon-browser.R]

### Pattern 1: Fixture Matrix Before Fix

**What:** Build small plot fixtures and assert both `ggplot_build()` row state and gg2d3 IR state before changing renderer code. [VERIFIED: local R probe; tests/testthat/test-regression-core.R]

**When to use:** Use for every matrix row in `45-01` so planner can classify expected dropped rows versus expected clipped rows. [VERIFIED: .planning/phases/45-rect-and-tile-edge-closure/45-CONTEXT.md]

**Example:**

```r
# Source: local ggplot2 4.0.3 probe and existing testthat patterns.
test_that("scale limits censor out-of-limit geom_rect bounds before rendering", {
  library(ggplot2)

  p <- ggplot(data.frame(xmin = -1, xmax = 2, ymin = -1, ymax = 2),
              aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax)) +
    geom_rect() +
    scale_x_continuous(limits = c(0, 1)) +
    scale_y_continuous(limits = c(0, 1))

  built <- ggplot_build(p)$data[[1]]
  ir <- as_d3_ir(p)

  expect_true(all(is.na(built[, c("xmin", "xmax", "ymin", "ymax")])))
  expect_equal(ir$layers[[1]]$geom, "rect")
  expect_true(all(is.na(unlist(ir$layers[[1]]$data[[1]][c("xmin", "xmax", "ymin", "ymax")]))))
})
```

### Pattern 2: DOM Attributes, Not Screenshots

**What:** Optional browser smoke should assert node counts, `rect.geom-rect` attributes, clip-path ancestry, and absence of browser exceptions. [VERIFIED: tests/testthat/test-polygon-browser.R; tests/testthat/helper-browser-polygon.R]

**When to use:** Use for representative coordinate-limit and facet cases when source/IR tests cannot prove visible clipping. [VERIFIED: .planning/phases/45-rect-and-tile-edge-closure/45-CONTEXT.md]

**Example:**

```r
# Source: tests/testthat/test-polygon-browser.R pattern.
rects <- eval_js_value(session, "
  Array.from(document.querySelectorAll('rect.geom-rect')).map(r => ({
    x: Number(r.getAttribute('x')),
    y: Number(r.getAttribute('y')),
    width: Number(r.getAttribute('width')),
    height: Number(r.getAttribute('height')),
    clipped: !!r.closest('g[clip-path]')
  }))
")
expect_true(all(vapply(rects, `[[`, logical(1), "clipped")))
```

### Anti-Patterns to Avoid

- **Conflating scale limits and coordinate limits:** Scale limits can censor built data to `NA`, while coordinate limits can preserve data and narrow panel domains. [VERIFIED: local R probe using ggplot2 4.0.3]
- **Treating off-panel SVG coordinates as a bug by default:** Large or negative pixel positions can be correct when the mark is intentionally clipped by the panel clip path. [VERIFIED: inst/htmlwidgets/gg2d3.js:22-24,76-77; .planning/phases/45-rect-and-tile-edge-closure/45-CONTEXT.md]
- **Fixing only initial render:** `geom-registry.js` has a separate update path for `rect.geom-rect`, so geometry math changes must be mirrored or explicitly proven irrelevant. [VERIFIED: inst/htmlwidgets/modules/geom-registry.js:243-249]
- **Adding transformed-scale work by default:** Transformed scales are deferred unless source evidence pulls them into the core matrix. [VERIFIED: .planning/phases/45-rect-and-tile-edge-closure/45-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Expected ggplot2 data dropping/clipping semantics | Custom R-side OOB classifier | `ggplot2::ggplot_build()` probes in test fixtures | The project already treats built ggplot2 output as the IR source of truth. [VERIFIED: R/as_d3_ir.R:9; local R probe] |
| Visual regression comparison | Screenshot diff harness | DOM/source assertions plus optional chromote smoke | Screenshot/perceptual diff is out of scope. [VERIFIED: .planning/phases/45-rect-and-tile-edge-closure/45-CONTEXT.md] |
| Rect scale math | Custom scale implementation | Existing `window.gg2d3.scales.createScale()` and D3 scales | The renderer already centralizes continuous, reverse, temporal, and band scale creation. [VERIFIED: inst/htmlwidgets/modules/scales.js:136-225] |
| Browser launching and skip handling | New ad hoc browser runner | Existing chromote helper pattern | Existing helpers already skip on CRAN, missing chromote, missing Chrome, and failed session launch. [VERIFIED: tests/testthat/helper-browser-polygon.R:19-47] |

**Key insight:** The safest plan is to preserve ggplot2-built data semantics and only adjust the renderer/update boundary if the rendered DOM measurably contradicts that built-data contract. [VERIFIED: .planning/phases/45-rect-and-tile-edge-closure/45-CONTEXT.md; R/as_d3_ir.R; inst/htmlwidgets/modules/geoms/rect.js]

## Common Pitfalls

### Pitfall 1: `NA` Rows Look Like Missing Renderer Output

**What goes wrong:** A test expects a visible rect after scale limits, but ggplot2 has already censored the row bounds to `NA`. [VERIFIED: local R probe]
**Why it happens:** Scale limits apply before coordinate clipping in the built data path. [VERIFIED: local R probe]
**How to avoid:** Classify `ggplot_build()` rows before inspecting DOM output. [VERIFIED: local R probe; R/as_d3_ir.R:9]
**Warning signs:** `ir$layers[[1]]$data[[i]]` has `NA` for one or more of `xmin`, `xmax`, `ymin`, or `ymax`. [VERIFIED: local R probe]

### Pitfall 2: Discrete `geom_tile()` Uses Numeric Bounds With Categorical Domains

**What goes wrong:** `geom_tile()` built rows include numeric `xmin`/`xmax`/`ymin`/`ymax` around discrete positions, while gg2d3 maps only center `x`/`y` values to labels in the current IR path. [VERIFIED: local R probe; R/as_d3_ir.R:175-193]
**Why it happens:** `map_discrete()` only maps whole-number indices safely; half-step tile bounds remain numeric. [VERIFIED: R/as_d3_ir.R:175-193; local R probe]
**How to avoid:** Include discrete tile DOM smoke or source tests that verify band-scale branches use `bandwidth()` and row filtering excludes out-of-domain limited tiles. [VERIFIED: inst/htmlwidgets/modules/geoms/rect.js:50-51,138-148; local R probe]
**Warning signs:** Rendered `rect.geom-rect` count differs from rows with non-`NA` tile bounds after discrete limits. [VERIFIED: local R probe]

### Pitfall 3: Reversed Scales Double-Reverse Geometry

**What goes wrong:** ggplot2-built rect bounds on a reversed axis can already be transformed to reversed-space values, while `scales.js` also reverses the scale domain. [VERIFIED: local R probe; inst/htmlwidgets/modules/scales.js:196-198]
**Why it happens:** The IR stores transformed values and transform metadata together. [VERIFIED: R/as_d3_ir.R:414-436; local R probe]
**How to avoid:** Add a reversed-scale fixture that checks DOM `x`/`width` rather than assuming original data-space bounds. [VERIFIED: local R probe; inst/htmlwidgets/modules/geoms/rect.js:130-148]
**Warning signs:** DOM rects appear mirrored or shifted relative to axis tick order. [ASSUMED]

### Pitfall 4: Update Path Diverges From Initial Render

**What goes wrong:** Initial render handles flip or band scales, but zoom/update uses simpler `Math.min(scale(d.xmin), scale(d.xmax))` math. [VERIFIED: inst/htmlwidgets/modules/geoms/rect.js:88-164; inst/htmlwidgets/modules/geom-registry.js:243-249]
**Why it happens:** Rect initial rendering lives in `rect.js`, while update rendering lives in `geom-registry.js`. [VERIFIED: source inspection]
**How to avoid:** Add source-contract tests that compare intended handling across both files whenever `rect.js` changes. [VERIFIED: tests/testthat/test-polygon-renderer.R]
**Warning signs:** Browser smoke passes initial render but fails after zoom/pan or transition. [ASSUMED]

## Code Examples

### Matrix Classification Helper

```r
# Source: existing testthat style and local ggplot2 probe.
classify_rect_case <- function(plot) {
  built <- ggplot2::ggplot_build(plot)$data[[1]]
  ir <- as_d3_ir(plot)
  bounds <- c("xmin", "xmax", "ymin", "ymax")
  list(
    built_non_na = stats::complete.cases(built[, bounds, drop = FALSE]),
    ir_non_na = vapply(ir$layers[[1]]$data, function(row) {
      all(!is.na(unlist(row[bounds])))
    }, logical(1)),
    scales = ir$scales,
    panels = ir$panels
  )
}
```

### Source Contract For Rect Update Parity

```r
# Source: tests/testthat/test-polygon-renderer.R pattern.
read_repo_file <- function(path) {
  candidates <- c(path, file.path("..", "..", path))
  existing <- candidates[file.exists(candidates)]
  paste(readLines(existing[[1]], warn = FALSE), collapse = "\n")
}

test_that("rect renderer and update path both handle rect.geom-rect", {
  rect_js <- read_repo_file("inst/htmlwidgets/modules/geoms/rect.js")
  registry_js <- read_repo_file("inst/htmlwidgets/modules/geom-registry.js")

  expect_match(rect_js, "geomRegistry\\.register\\(\\['rect', 'tile'\\]")
  expect_match(rect_js, "rect\\.geom-rect|geom-rect")
  expect_match(registry_js, "rect\\.geom-rect")
})
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Treat rect/tile OOB behavior as deferred renderer debt | Close by focused matrix, fix only proven mismatches, or document non-issue | Phase 45, v1.11 roadmap | Prevents carrying a vague v1.10 deferred item forward. [VERIFIED: .planning/ROADMAP.md; vignettes/d3-drawing-diagnostics.md:60-65] |
| Broad visual confidence through manual observation | IR/source assertions plus optional chromote DOM smoke | Established by prior sf/polygon phases | Keeps validation fast and CRAN-compatible. [VERIFIED: tests/testthat/helper-browser-polygon.R; .planning/phases/44-ordinary-geom-polygon-support/44-VERIFICATION.md] |
| Single regression file with broad smoke coverage | Focused test files per behavior family | Existing tests use `test-polygon-ir.R`, `test-polygon-renderer.R`, and `test-polygon-browser.R` | Phase 45 should mirror this split for clear planning. [VERIFIED: tests/testthat listing] |

**Deprecated/outdated:**
- The old diagnostics wording that leaves rect/tile edge behavior as open deferred debt should be replaced or narrowed after Phase 45 evidence exists. [VERIFIED: vignettes/d3-drawing-diagnostics.md:60-65; .planning/ROADMAP.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | A reversed-scale DOM mismatch would appear as mirrored or shifted rects relative to tick order. [ASSUMED] | Common Pitfalls | Tests might need a different oracle, such as comparing ggplot2 grob coordinates or a browser-measured coordinate table. |
| A2 | Update-path divergence would likely surface after zoom/pan or transition. [ASSUMED] | Common Pitfalls | If no rect update interaction exists in the phase, source-contract parity may be enough and browser zoom smoke may be unnecessary. |

## Open Questions (RESOLVED)

1. **RESOLVED: Optional browser DOM smoke belongs in `45-02`, only if needed.** [VERIFIED: .planning/phases/45-rect-and-tile-edge-closure/45-CONTEXT.md; .planning/phases/45-rect-and-tile-edge-closure/45-02-PLAN.md]
   - What we know: Browser smoke is allowed but optional and must skip cleanly. [VERIFIED: 45-CONTEXT.md; tests/testthat/helper-browser-polygon.R]
   - Resolution: `45-01` performs IR/source classification only. `45-02` adds optional browser DOM smoke only when a visible clipping, facet placement, reversed-scale DOM geometry, coord_flip DOM geometry, or update-path question remains after IR/source tests. [VERIFIED: .planning/phases/45-rect-and-tile-edge-closure/45-01-PLAN.md; .planning/phases/45-rect-and-tile-edge-closure/45-02-PLAN.md]

2. **RESOLVED: Reversed scale behavior gets characterized first and fixed only with DOM/source evidence.** [VERIFIED: local R probe; .planning/phases/45-rect-and-tile-edge-closure/45-01-PLAN.md; .planning/phases/45-rect-and-tile-edge-closure/45-02-PLAN.md]
   - What we know: Local `ggplot_build()` changed `xmin=0,xmax=1` into `xmin=0,xmax=-1` under `scale_x_reverse()`, and gg2d3 also emits `transform = "reverse"`. [VERIFIED: local R probe]
   - Resolution: `45-01` includes a reversed continuous rect fixture and classification. `45-02` patches only if the classification marks reversed-scale behavior as a visible or DOM-measurable mismatch; otherwise it is closed as a tested non-issue. [VERIFIED: .planning/phases/45-rect-and-tile-edge-closure/45-CONTEXT.md; .planning/phases/45-rect-and-tile-edge-closure/45-02-PLAN.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Rscript | Test execution | yes | R 4.6.0 | None needed. [VERIFIED: local command] |
| ggplot2 | Fixture oracle and IR input | yes | 4.0.3 | None needed. [VERIFIED: local Rscript] |
| testthat | Unit/source tests | yes | 3.3.2 | None needed. [VERIFIED: local Rscript] |
| pkgload | Targeted test loading | yes | 1.5.2 | `devtools::load_all()` is available by project convention. [VERIFIED: local Rscript; AGENTS.md] |
| V8 | Optional JS source execution | yes | 8.2.0 | Use plain source-string assertions if V8 is unnecessary. [VERIFIED: local Rscript; tests/testthat/test-layout-facet-free.R] |
| chromote | Optional browser DOM smoke | yes | 0.5.1 | Skip cleanly and rely on IR/source tests. [VERIFIED: local Rscript; tests/testthat/helper-browser-polygon.R] |
| Google Chrome | Optional chromote runtime | yes via `/Applications/Google Chrome.app/Contents/MacOS/Google Chrome` | not probed | Skip cleanly and rely on IR/source tests. [VERIFIED: `chromote::find_chrome()` local probe] |
| Node | Graph tooling / optional local inspection | yes | not probed | Not required for Phase 45 execution. [VERIFIED: local command] |

**Missing dependencies with no fallback:** None found for the recommended Phase 45 plan. [VERIFIED: local environment audit]

**Missing dependencies with fallback:** Browser execution can skip cleanly if chromote launch fails despite Chrome being discoverable. [VERIFIED: tests/testthat/helper-browser-polygon.R]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | testthat 3.3.2 local; package config uses edition 3. [VERIFIED: local Rscript; DESCRIPTION] |
| Config file | DESCRIPTION `Config/testthat/edition: 3`; runner `tests/testthat.R`. [VERIFIED: DESCRIPTION; tests/testthat.R] |
| Quick run command | `rtk Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-rect-tile-ir.R")'` [VERIFIED: existing targeted test pattern] |
| Full suite command | `rtk Rscript --vanilla -e 'devtools::test()'` [VERIFIED: AGENTS.md] |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| RECT-01 | Fixture matrix classifies rect/tile behavior under scale limits, coord limits, discrete tiles, reverse scales, coord flip, and facets. [VERIFIED: 45-CONTEXT.md] | unit / characterization | `rtk Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-rect-tile-ir.R")'` | No - Wave 0 gap [VERIFIED: tests/testthat listing] |
| RECT-02 | Confirmed mismatches are patched at renderer/IR boundary or non-issues are locked with tests and rationale. [VERIFIED: .planning/REQUIREMENTS.md] | source contract plus optional browser DOM | `rtk Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-rect-tile-renderer.R")'` | No - Wave 0 gap [VERIFIED: tests/testthat listing] |
| RECT-02 | Representative visible clipping/update behavior is DOM-measured when source/IR evidence is insufficient. [VERIFIED: 45-CONTEXT.md] | optional browser smoke | `rtk env NOT_CRAN=true Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-rect-tile-browser.R")'` | No - optional Wave 0 gap [VERIFIED: tests/testthat listing] |

### Sampling Rate

- **Per task commit:** Run the relevant new `test-rect-tile-*.R` file plus any touched existing regression file. [VERIFIED: existing phase verification patterns in .planning/phases/44-ordinary-geom-polygon-support/44-VERIFICATION.md]
- **Per wave merge:** Run all new Phase 45 tests and `tests/testthat/test-regression-core.R`. [VERIFIED: tests/testthat/test-regression-core.R]
- **Phase gate:** Run `rtk Rscript --vanilla -e 'devtools::test()'` before `/gsd-verify-work`. [VERIFIED: AGENTS.md; .planning/config.json]

### Wave 0 Gaps

- [ ] `tests/testthat/test-rect-tile-ir.R` - covers RECT-01 fixture matrix. [VERIFIED: tests/testthat listing]
- [ ] `tests/testthat/test-rect-tile-renderer.R` - covers RECT-02 source contract for `rect.js` and update path. [VERIFIED: tests/testthat listing]
- [ ] `tests/testthat/test-rect-tile-browser.R` - optional DOM smoke if planner decides browser coverage is needed. [VERIFIED: tests/testthat listing; 45-CONTEXT.md]
- [ ] Optional helper reuse or creation for rect/tile browser artifacts under `test_output/`. [VERIFIED: tests/testthat/helper-browser-polygon.R]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | no | Phase 45 does not add authentication. [VERIFIED: .planning/ROADMAP.md] |
| V3 Session Management | no | Phase 45 does not add session state. [VERIFIED: .planning/ROADMAP.md] |
| V4 Access Control | no | Phase 45 does not add authorization boundaries. [VERIFIED: .planning/ROADMAP.md] |
| V5 Input Validation | yes | Preserve defensive row filtering for finite/non-null rect bounds and validate IR with existing `validate_ir()`. [VERIFIED: inst/htmlwidgets/modules/geoms/rect.js:44-48; R/as_d3_ir.R:943] |
| V6 Cryptography | no | Phase 45 does not add cryptographic behavior. [VERIFIED: .planning/ROADMAP.md] |

### Known Threat Patterns for gg2d3 Rect/Tile Rendering

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Malformed or missing rect bounds produce invalid SVG attributes | Tampering / Denial of Service | Keep or strengthen renderer filtering before attribute writes. [VERIFIED: inst/htmlwidgets/modules/geoms/rect.js:44-48] |
| Excessive rect/tile counts can create large DOMs | Denial of Service | Do not add unbounded browser-side expansion; keep Phase 45 fixtures small. [VERIFIED: .planning/codebase/CONCERNS.md] |
| User text injection | Tampering | Not directly affected by rect/tile geometry; existing concern remains about text APIs, not rect attributes. [VERIFIED: .planning/codebase/CONCERNS.md] |

## Sources

### Primary (HIGH confidence)

- `.planning/phases/45-rect-and-tile-edge-closure/45-CONTEXT.md` - locked fixture, validation, fix threshold, and documentation decisions. [VERIFIED: file read]
- `.planning/REQUIREMENTS.md` - RECT-01 and RECT-02. [VERIFIED: file read]
- `.planning/ROADMAP.md` - Phase 45 scope, success criteria, and expected plans. [VERIFIED: file read]
- `R/as_d3_ir.R` - rect/tile IR mapping, discrete mapping, scale extraction, panel metadata, and validation call. [VERIFIED: source inspection]
- `inst/htmlwidgets/modules/geoms/rect.js` - initial rect/tile renderer. [VERIFIED: source inspection]
- `inst/htmlwidgets/modules/geom-registry.js` - rect/tile update path. [VERIFIED: source inspection]
- `inst/htmlwidgets/gg2d3.js` - panel clip path and per-panel scale/render flow. [VERIFIED: source inspection]
- `vignettes/d3-drawing-diagnostics.md` - current deferred rect/tile edge note. [VERIFIED: source inspection]
- Local R probe with ggplot2 4.0.3 - scale-limit, coord-limit, discrete tile, reverse, and flip built-data behavior. [VERIFIED: local Rscript]

### Secondary (MEDIUM confidence)

- `.planning/codebase/CONCERNS.md` - older but still relevant rect/tile and scale/domain concerns. [VERIFIED: file read]
- `.planning/codebase/TESTING.md` - older test pattern survey, superseded in places by current tests. [VERIFIED: file read]
- `.planning/phases/44-ordinary-geom-polygon-support/44-VERIFICATION.md` - current phase verification precedent for optional browser smoke and targeted commands. [VERIFIED: file read]

### Tertiary (LOW confidence)

- None. [VERIFIED: source list]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - versions and declarations were verified locally. [VERIFIED: local Rscript; DESCRIPTION]
- Architecture: HIGH - implementation surfaces were inspected directly. [VERIFIED: R/as_d3_ir.R; inst/htmlwidgets/gg2d3.js; inst/htmlwidgets/modules/geoms/rect.js; inst/htmlwidgets/modules/geom-registry.js]
- Pitfalls: MEDIUM - scale/coord/discrete behavior was locally probed, while visible reversed-scale mismatch risk still needs DOM evidence. [VERIFIED: local R probe; ASSUMED where noted]

**Research date:** 2026-05-24 [VERIFIED: system date]
**Valid until:** 2026-06-23 for local architecture; revalidate sooner if ggplot2, D3, or htmlwidgets versions change. [ASSUMED]
