# Phase 53: Renderer And IR Contract Consolidation - Research

**Researched:** 2026-05-28
**Domain:** R package IR helper boundaries, htmlwidgets/D3 renderer contracts, source-level drift tests
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
## Implementation Decisions

### Geom Contract Source Of Truth
- **D-01:** Treat `inst/htmlwidgets/modules/geom-contracts.js` as the internal renderer contract manifest for Phase 53.
- **D-02:** Strengthen validation around the existing manifest instead of introducing generated/shared contracts or public extension semantics in this phase.
- **D-03:** Keep generated renderer documentation deferred to `FUT-04` unless planning finds a tiny source-first note is needed to satisfy the diagnostics requirement.

### Contract Strictness
- **D-04:** Contract drift tests should be strict for every supported/registered geom alias.
- **D-05:** Required contract coverage includes module path/loading expectations, render selectors, update handling, interaction selectors, private renderer fields, and public payload sanitization expectations.
- **D-06:** Intentional gaps are allowed only when explicitly documented in the contract with a clear reason, such as `update.type = "explicit-none"` or a selector-surface rationale for unsupported crosstalk behavior.
- **D-07:** Test failures should name the missing geom alias, selector, module, or sanitizer surface clearly enough that maintainers know which contract entry or renderer module drifted.

### `as_d3_ir()` Helper Boundary
- **D-08:** Extract only high-risk responsibilities from `as_d3_ir()` now; do not attempt a full modularization or rewrite.
- **D-09:** Priority helper seams are theme extraction, layer preprocessing/dispatch, discrete and temporal mapping, geom parameter routing, and scale/axis metadata.
- **D-10:** Representative IR output for non-sf, sf, facet, scale, and annotation fixtures must remain unchanged except for intentional no-op structural cleanup that tests prove is equivalent.
- **D-11:** Full `as_d3_ir()` modularization remains deferred to `FUT-03`.

### Regression Fixture Strategy
- **D-12:** Use curated representative IR fixtures/checks as the primary unchanged-output contract for this phase.
- **D-13:** Fixture coverage should include non-sf layers, sf layers, facets, scale/date/time transforms, and annotations.
- **D-14:** Avoid broad brittle snapshots and committed pixel goldens in Phase 53.
- **D-15:** Continue using browser visual smoke as downstream validation, not the primary contract gate.

### Claude's Discretion
- Planning and implementation may choose exact helper names, test organization, and source-level parser details as long as the decisions above and existing project style are preserved.
- Small diagnostic documentation placement is flexible, but the likely target is `vignettes/d3-drawing-diagnostics.md` because it already carries architecture and residual-risk notes.

### Deferred Ideas (OUT OF SCOPE)
## Deferred Ideas

- Generated renderer documentation from contracts remains `FUT-04`.
- Full `as_d3_ir()` modularization remains `FUT-03`.
- Committed pixel goldens and thresholds remain deferred until visual artifacts are stable enough across environments.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| ARCH-01 | Renderer registration, update selectors, interaction selectors, and public payload sanitization expectations are driven by a single declarative geom contract or a source-of-truth validation gate. [VERIFIED: .planning/REQUIREMENTS.md] | Use `geom-contracts.js` as the manifest and extend `test-renderer-wiring-contracts.R` to validate aliases, modules, load order, selectors, exceptions, and sanitizer surfaces. [VERIFIED: .planning/phases/53-renderer-and-ir-contract-consolidation/53-CONTEXT.md; tests/testthat/test-renderer-wiring-contracts.R] |
| ARCH-02 | Additional high-risk `as_d3_ir()` responsibilities are isolated behind focused helpers without changing representative non-sf, sf, facet, scale, and annotation IR output. [VERIFIED: .planning/REQUIREMENTS.md] | Extract remaining high-risk seams from `R/as_d3_ir.R`, especially theme extraction and geom parameter routing, while preserving existing helper files and focused characterization tests. [VERIFIED: R/as_d3_ir.R; R/ir_layer_helpers.R; R/ir_scale_helpers.R; R/ir_facet_helpers.R; tests/testthat/test-ir-helper-boundaries.R] |
| ARCH-03 | Contract tests fail with actionable messages when renderer metadata, module loading, update handling, or interaction payload behavior drifts. [VERIFIED: .planning/REQUIREMENTS.md] | Prefer helper-driven source parsers and `info = paste(...)` messages that name the missing alias, module, selector, field, or sanitizer surface. [VERIFIED: tests/testthat/test-renderer-wiring-contracts.R] |
</phase_requirements>

## Summary

Phase 53 should consolidate what Phase 49 and Phase 50 already introduced, not replace it. [VERIFIED: .planning/milestones/v1.12-phases/49-ir-helper-boundary-hardening/49-RESEARCH.md; .planning/milestones/v1.12-phases/50-renderer-wiring-and-interaction-contracts/50-RESEARCH.md] The source-of-truth for renderer behavior is already `inst/htmlwidgets/modules/geom-contracts.js`, and the current source tests already compare aliases, update selectors, interaction selectors, private fields, and sanitizer delegation. [VERIFIED: inst/htmlwidgets/modules/geom-contracts.js; tests/testthat/test-renderer-wiring-contracts.R]

The main planning risk is a second, weaker source of truth. [VERIFIED: .planning/phases/53-renderer-and-ir-contract-consolidation/53-CONTEXT.md] Plans should harden the existing manifest and tests around module loading, render selector production, explicit exception shape, and public payload expectations, while keeping runtime behavior stable. [VERIFIED: inst/htmlwidgets/modules/geom-contracts.js; inst/htmlwidgets/gg2d3.yaml; inst/htmlwidgets/modules/public-data.js; tests/testthat/test-renderer-wiring-contracts.R]

On the R side, `as_d3_ir()` still owns theme extraction, top-level guide extraction, coord metadata, axis labels, and final IR assembly, while scale, layer, and facet responsibilities already have helper files. [VERIFIED: R/as_d3_ir.R; R/ir_scale_helpers.R; R/ir_layer_helpers.R; R/ir_facet_helpers.R] The best Phase 53 cut is to extract only the remaining high-risk seams named by context, then prove representative IR behavior with focused checks rather than broad snapshots. [VERIFIED: .planning/phases/53-renderer-and-ir-contract-consolidation/53-CONTEXT.md; tests/testthat/test-ir-helper-boundaries.R]

**Primary recommendation:** plan two implementation tracks: one JS contract-hardening track around `geom-contracts.js` and `test-renderer-wiring-contracts.R`, and one R helper-boundary track around `as_d3_ir()` theme/parameter/top-level assembly seams with curated IR checks. [VERIFIED: .planning/ROADMAP.md; .planning/phases/53-renderer-and-ir-contract-consolidation/53-CONTEXT.md]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Renderer geom metadata contract | Browser / D3 layer | R test layer | `geom-contracts.js` exports renderer metadata, and R source tests parse the JS to catch drift without launching a browser. [VERIFIED: inst/htmlwidgets/modules/geom-contracts.js; tests/testthat/test-renderer-wiring-contracts.R] |
| Renderer module load-order contract | htmlwidgets static dependency config | Browser / D3 layer | `gg2d3.yaml` orders `geom-contracts.js` and `public-data.js` before tooltip/events/brush/crosstalk/registry and geom modules. [VERIFIED: inst/htmlwidgets/gg2d3.yaml] |
| Interaction selector contract | Browser / D3 layer | R test layer | `events.js`, `brush.js`, and `crosstalk.js` consume `window.gg2d3.geomContracts.selectorsFor(surface)` when available. [VERIFIED: inst/htmlwidgets/modules/events.js; inst/htmlwidgets/modules/brush.js; inst/htmlwidgets/modules/crosstalk.js] |
| Public payload sanitization | Browser / D3 layer | R test layer | `public-data.js` strips underscore-prefixed fields, and tooltip/events/brush delegate to `publicData.sanitizeDatum()`. [VERIFIED: inst/htmlwidgets/modules/public-data.js; inst/htmlwidgets/modules/tooltip.js; inst/htmlwidgets/modules/events.js; inst/htmlwidgets/modules/brush.js; tests/testthat/test-renderer-wiring-contracts.R] |
| IR helper extraction | R layer | IR contract tests | `as_d3_ir()` builds ggplot objects into IR, and helper-boundary tests characterize scale, layer, facet, sf, and annotation output. [VERIFIED: R/as_d3_ir.R; tests/testthat/test-ir-helper-boundaries.R] |
| Browser visual smoke | Browser runtime validation | R test harness | Browser smoke is opt-in and produces inspectable artifacts, but Phase 53 context says it is downstream validation rather than the primary contract gate. [VERIFIED: tests/testthat/helper-browser-visual.R; tests/testthat/test-browser-visual-smoke.R; .planning/phases/53-renderer-and-ir-contract-consolidation/53-CONTEXT.md] |

## Project Constraints (from CLAUDE.md)

- This repository is an R package that converts ggplot objects into IR and renders them with D3 via htmlwidgets. [VERIFIED: CLAUDE.md]
- Development commands are `devtools::load_all()`, `devtools::document()`, `devtools::test()`, `testthat::test_file(...)`, and `devtools::build_readme()`. [VERIFIED: CLAUDE.md]
- D3 v7 is vendored locally under `inst/htmlwidgets/lib/d3/d3.v7.min.js`. [VERIFIED: CLAUDE.md; inst/htmlwidgets/gg2d3.yaml; inst/htmlwidgets/lib/d3/d3.v7.min.js]
- The architecture is a three-layer R -> IR -> D3/htmlwidgets pipeline. [VERIFIED: CLAUDE.md; R/as_d3_ir.R; inst/htmlwidgets/gg2d3.js]
- `R/as_d3_ir.R`, `R/gg2d3.R`, `inst/htmlwidgets/gg2d3.js`, and `inst/htmlwidgets/gg2d3.yaml` are key package files. [VERIFIED: CLAUDE.md]
- Current known limitations include no legends/facets in the old AGENTS/CLAUDE summary, but current code and diagnostics show legends and facets now exist; planners should trust current source and vignettes over stale summary text when they conflict. [VERIFIED: CLAUDE.md; R/as_d3_ir.R; tests/testthat/test-facets.R; tests/testthat/test-legends.R; vignettes/d3-drawing-diagnostics.md]
- Shell commands should be prefixed with `rtk` under the repository's referenced RTK instruction. [VERIFIED: AGENTS.md; /Users/davidzenz/.codex/RTK.md]

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| R | 4.6.0 local runtime | Runs package code and test commands. [VERIFIED: `rtk Rscript --version`] | The package `DESCRIPTION` requires R >= 4.1.0. [VERIFIED: DESCRIPTION] |
| ggplot2 | 4.0.3 local install | Builds plot data and layout consumed by `as_d3_ir()`. [VERIFIED: `rtk Rscript ... packageVersion`; R/as_d3_ir.R] | `as_d3_ir()` calls `ggplot2::ggplot_build()` and compatibility wrappers quarantine private ggplot2 theme APIs. [VERIFIED: R/as_d3_ir.R; R/ggplot2_compat.R] |
| htmlwidgets | 1.6.4 local install | Creates and serializes the browser widget. [VERIFIED: `rtk Rscript ... packageVersion`; R/gg2d3.R] | `gg2d3()` calls `htmlwidgets::createWidget()` and htmlwidgets loads scripts from `gg2d3.yaml`. [VERIFIED: R/gg2d3.R; inst/htmlwidgets/gg2d3.yaml] |
| D3.js | v7 vendored | Browser SVG rendering and interaction primitives. [VERIFIED: inst/htmlwidgets/gg2d3.yaml; inst/htmlwidgets/lib/d3/d3.v7.min.js] | The renderer modules are D3 modules loaded through htmlwidgets. [VERIFIED: inst/htmlwidgets/gg2d3.yaml; inst/htmlwidgets/modules/geom-registry.js] |
| testthat | 3.3.2 local install; edition 3 configured | Source-level and IR behavior tests. [VERIFIED: `rtk Rscript ... packageVersion`; DESCRIPTION] | Existing contract and helper-boundary tests use testthat expectations and skip helpers. [VERIFIED: tests/testthat/test-renderer-wiring-contracts.R; tests/testthat/test-ir-helper-boundaries.R] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| pkgload | 1.5.2 local install | Load package code for focused test-file commands. [VERIFIED: `rtk Rscript ... packageVersion`; tests/testthat/test-browser-visual-smoke.R] | Use in validation commands that run `testthat::test_file()` outside `devtools::test()`. [VERIFIED: tests/testthat/test-browser-visual-smoke.R; tests/testthat/helper-browser-visual.R] |
| chromote | 0.5.1 local install | Optional browser visual smoke execution. [VERIFIED: `rtk Rscript ... packageVersion`; tests/testthat/helper-browser-visual.R] | Use only for opt-in browser smoke; source contract tests should not depend on Chrome. [VERIFIED: tests/testthat/helper-browser-visual.R; .planning/phases/53-renderer-and-ir-contract-consolidation/53-CONTEXT.md] |
| sf | Missing locally | Optional spatial IR/helper tests. [VERIFIED: `rtk Rscript ... requireNamespace`] | sf-dependent tests should skip cleanly when `sf` is absent. [VERIFIED: tests/testthat/test-ir-helper-boundaries.R; test run 2026-05-28] |
| geojsonsf | 2.0.5 local install | Optional sf serialization dependency. [VERIFIED: `rtk Rscript ... packageVersion`; DESCRIPTION] | Only useful when `sf` is also available for sf fixtures. [VERIFIED: DESCRIPTION; tests/testthat/test-ir-helper-boundaries.R] |
| V8 | 8.2.0 local install | Existing suggested JS evaluation support. [VERIFIED: `rtk Rscript ... packageVersion`; DESCRIPTION] | Do not introduce V8-based contract parsing unless source parsing becomes too brittle, because current tests already parse source strings. [VERIFIED: tests/testthat/test-renderer-wiring-contracts.R] |
| crosstalk | 1.2.2 local install | Linked selection support. [VERIFIED: `rtk Rscript ... packageVersion`; R/gg2d3.R] | Validate crosstalk selector exceptions separately because its selector surface is intentionally shorter than events/brush. [VERIFIED: inst/htmlwidgets/modules/crosstalk.js; inst/htmlwidgets/modules/geom-contracts.js; tests/testthat/test-renderer-wiring-contracts.R] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Existing `geom-contracts.js` manifest | Generated shared R/JS contract | Deferred by user decision `FUT-04`, and adding generation now would create tooling scope outside Phase 53. [VERIFIED: .planning/phases/53-renderer-and-ir-contract-consolidation/53-CONTEXT.md] |
| Source-level contract tests | Browser-only smoke tests | Browser smoke is opt-in and may skip, while source tests are already fast and deterministic. [VERIFIED: tests/testthat/test-browser-visual-smoke.R; tests/testthat/test-renderer-wiring-contracts.R] |
| Curated IR checks | Broad snapshot files or pixel goldens | Broad snapshots and committed pixel goldens are out of scope for this phase. [VERIFIED: .planning/phases/53-renderer-and-ir-contract-consolidation/53-CONTEXT.md] |
| Focused helper extraction | Full `as_d3_ir()` modularization | Full modularization is explicitly deferred to `FUT-03`. [VERIFIED: .planning/phases/53-renderer-and-ir-contract-consolidation/53-CONTEXT.md] |

**Installation:**

No new package installation is recommended for Phase 53. [VERIFIED: DESCRIPTION; .planning/phases/53-renderer-and-ir-contract-consolidation/53-CONTEXT.md]

**Version verification:** Local package versions were verified with `rtk Rscript --vanilla -e 'packageVersion(...)'`; registry publish dates were not queried because this phase should not add or upgrade dependencies. [VERIFIED: command run 2026-05-28; DESCRIPTION]

## Architecture Patterns

### System Architecture Diagram

```text
ggplot object
  |
  v
R/as_d3_ir.R
  |-- scale/layer/facet helpers
  |-- theme/coord/guide/top-level assembly seams
  v
JSON-serializable IR
  |
  v
htmlwidgets gg2d3.yaml load order
  |-- geom-contracts.js
  |-- public-data.js
  |-- tooltip/events/brush/crosstalk
  |-- geom-registry.js
  |-- geoms/*.js
  v
D3 SVG renderer + interaction modules
  |
  v
Source tests and optional browser visual smoke validate drift
```

The diagram reflects the project pipeline and script load order in the current source. [VERIFIED: CLAUDE.md; R/as_d3_ir.R; R/gg2d3.R; inst/htmlwidgets/gg2d3.yaml; tests/testthat/test-renderer-wiring-contracts.R]

### Recommended Project Structure

```text
R/
├── as_d3_ir.R              # top-level orchestration and remaining extraction targets
├── ir_layer_helpers.R      # existing layer rows, geom naming, aes, temporal columns, non-sf layer payload
├── ir_scale_helpers.R      # existing scale transform, domain, temporal metadata, axis breaks
├── ir_facet_helpers.R      # existing facet and panel metadata helpers
└── ggplot2_compat.R        # quarantined private ggplot2 compatibility wrappers

inst/htmlwidgets/modules/
├── geom-contracts.js       # internal renderer contract manifest
├── public-data.js          # shared public payload sanitizer
├── geom-registry.js        # renderer registry and updateGeoms
├── events.js / brush.js / crosstalk.js / tooltip.js
└── geoms/*.js              # renderer modules that self-register aliases

tests/testthat/
├── test-renderer-wiring-contracts.R
├── test-ir-helper-boundaries.R
├── test-browser-visual-smoke.R
└── helper-browser-visual.R
```

This structure already exists except for any new helper files or helper functions Phase 53 may add. [VERIFIED: `rtk rg --files`; R/as_d3_ir.R; tests/testthat/test-renderer-wiring-contracts.R]

### Pattern 1: Manifest-First Renderer Contract

**What:** Keep renderer metadata in `geom-contracts.js` entries with `geom`, `aliases`, `module`, `renderSelectors`, `update`, `interactions`, `privateFields`, and `publicPayload`. [VERIFIED: inst/htmlwidgets/modules/geom-contracts.js]

**When to use:** Use this for every supported or registered geom alias, including explicit exceptions such as `update.type = 'explicit-none'` or crosstalk selector exclusions with reasons. [VERIFIED: inst/htmlwidgets/modules/geom-contracts.js; .planning/phases/53-renderer-and-ir-contract-consolidation/53-CONTEXT.md]

**Example:**

```javascript
// Source: inst/htmlwidgets/modules/geom-contracts.js
{
  geom: 'sf',
  aliases: ['sf'],
  module: 'geoms/sf.js',
  renderSelectors: [
    'path.geom-sf.geom-sf-polygon',
    'path.geom-sf.geom-sf-line',
    'circle.geom-sf.geom-sf-point'
  ],
  update: {
    type: 'explicit-none',
    selectors: [],
    reason: 'geom_sf uses projection-space coordinates and currently has no updateGeoms branch.'
  },
  interactions: {
    events: ['.geom-sf'],
    brush: ['.geom-sf'],
    crosstalk: ['.geom-sf']
  },
  privateFields: ['_geom', '_centroid', '_sfFamily', '_pointCoord', '_pointIndex'],
  publicPayload: true
}
```

### Pattern 2: Contract-Derived Selector Consumers

**What:** Interaction modules should call `window.gg2d3.geomContracts.selectorsFor(surface)` and retain fallback selector arrays for load-order or older-widget resilience. [VERIFIED: inst/htmlwidgets/modules/events.js; inst/htmlwidgets/modules/brush.js; inst/htmlwidgets/modules/crosstalk.js]

**When to use:** Use this for events, brush, and crosstalk selector lists instead of duplicating manually maintained selector arrays as the primary path. [VERIFIED: inst/htmlwidgets/modules/events.js; inst/htmlwidgets/modules/brush.js; inst/htmlwidgets/modules/crosstalk.js]

**Example:**

```javascript
// Source: inst/htmlwidgets/modules/events.js
const contractEventSelectors = window.gg2d3.geomContracts &&
  typeof window.gg2d3.geomContracts.selectorsFor === 'function'
    ? window.gg2d3.geomContracts.selectorsFor('events')
    : [];
const INTERACTIVE_SELECTORS = contractEventSelectors.length
  ? contractEventSelectors
  : FALLBACK_INTERACTIVE_SELECTORS;
```

### Pattern 3: Shared Public Payload Sanitizer

**What:** Public tooltip/event/brush payloads should route through `window.gg2d3.publicData.sanitizeDatum()` so underscore-prefixed renderer fields stay internal. [VERIFIED: inst/htmlwidgets/modules/public-data.js; inst/htmlwidgets/modules/tooltip.js; inst/htmlwidgets/modules/events.js; inst/htmlwidgets/modules/brush.js]

**When to use:** Use it whenever a datum is exposed to user callbacks, Shiny-style inputs, tooltip content, or brush-selected data. [VERIFIED: inst/htmlwidgets/modules/tooltip.js; inst/htmlwidgets/modules/events.js; inst/htmlwidgets/modules/brush.js]

**Example:**

```javascript
// Source: inst/htmlwidgets/modules/public-data.js
function sanitizeDatum(d) {
  if (!isObjectDatum(d)) return d;

  var sanitized = {};
  Object.keys(d).forEach(function(key) {
    if (String(key).startsWith('_')) return;
    sanitized[key] = d[key];
  });
  return sanitized;
}
```

### Pattern 4: Focused R Helper Boundary Extraction

**What:** Move narrow responsibilities from `as_d3_ir()` into internal helpers with explicit inputs, then characterize their observable IR output. [VERIFIED: R/as_d3_ir.R; R/ir_layer_helpers.R; R/ir_scale_helpers.R; R/ir_facet_helpers.R; tests/testthat/test-ir-helper-boundaries.R]

**When to use:** Use this for theme extraction, geom parameter routing, discrete/temporal mapping, scale/axis metadata, and layer dispatch, but do not rewrite the whole IR function. [VERIFIED: .planning/phases/53-renderer-and-ir-contract-consolidation/53-CONTEXT.md; R/as_d3_ir.R]

**Example:**

```r
# Source: R/ir_layer_helpers.R
gg2d3_ir_non_sf_layer <- function(gname, df, aes, params, var_names) {
  list(
    geom = gname,
    data = gg2d3_ir_layer_rows(df),
    aes = aes,
    params = params,
    var_names = var_names
  )
}
```

### Anti-Patterns to Avoid

- **Generated contract tooling in Phase 53:** It contradicts the locked deferral of `FUT-04`. [VERIFIED: .planning/phases/53-renderer-and-ir-contract-consolidation/53-CONTEXT.md]
- **Browser smoke as the primary gate:** The smoke test skips unless `GG2D3_BROWSER_VISUAL_SMOKE=true`, so it cannot replace deterministic source contracts. [VERIFIED: tests/testthat/test-browser-visual-smoke.R; test run 2026-05-28]
- **Silent exception fields:** Empty update or interaction selector surfaces need explicit reasons in `geom-contracts.js`. [VERIFIED: inst/htmlwidgets/modules/geom-contracts.js; .planning/phases/53-renderer-and-ir-contract-consolidation/53-CONTEXT.md]
- **Broad IR snapshots:** Phase 53 context rejects broad brittle snapshots and prefers curated representative checks. [VERIFIED: .planning/phases/53-renderer-and-ir-contract-consolidation/53-CONTEXT.md]
- **Direct new `ggplot2:::` calls:** Private ggplot2 API access is already quarantined in `R/ggplot2_compat.R`. [VERIFIED: R/ggplot2_compat.R; .planning/PROJECT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Runtime renderer discovery | A browser-time scanner that infers registered geoms from loaded modules | Source tests parsing `geomRegistry.register(...)` and `geom-contracts.js` | Current tests already detect alias drift deterministically without launching a browser. [VERIFIED: tests/testthat/test-renderer-wiring-contracts.R] |
| Public payload sanitization | Separate sanitizer functions in tooltip/events/brush | `window.gg2d3.publicData.sanitizeDatum()` | The shared helper already strips underscore fields and consumers already delegate to it. [VERIFIED: inst/htmlwidgets/modules/public-data.js; inst/htmlwidgets/modules/tooltip.js; inst/htmlwidgets/modules/events.js; inst/htmlwidgets/modules/brush.js] |
| Visual regression thresholding | Pixel diff thresholds or committed golden screenshots | Existing source contracts plus optional browser visual smoke artifacts | Pixel goldens and thresholds are deferred, and browser smoke artifacts are inspection evidence. [VERIFIED: .planning/phases/53-renderer-and-ir-contract-consolidation/53-CONTEXT.md; vignettes/d3-drawing-diagnostics.md] |
| Full IR schema snapshotting | One huge serialized expected IR file | Curated assertions in `test-ir-helper-boundaries.R` plus existing focused IR tests | Existing tests name scale, layer, facet, sf, and annotation boundaries with localized expectation messages. [VERIFIED: tests/testthat/test-ir-helper-boundaries.R] |
| ggplot2 theme resolution | New private API calls scattered through helper files | `gg2d3_plot_theme()` and `gg2d3_calc_element()` | The compatibility wrappers already isolate `ggplot2:::` usage. [VERIFIED: R/ggplot2_compat.R] |

**Key insight:** Phase 53 is a consolidation phase, so the highest-value work is making existing sources stricter and more actionable rather than adding new runtime machinery. [VERIFIED: .planning/ROADMAP.md; .planning/phases/53-renderer-and-ir-contract-consolidation/53-CONTEXT.md]

## Runtime State Inventory

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None found; Phase 53 changes source contracts and internal helper code, and no database/datastore is referenced by the canonical phase files. [VERIFIED: .planning/phases/53-renderer-and-ir-contract-consolidation/53-CONTEXT.md; `rtk rg` canonical refs] | No data migration. [VERIFIED: .planning/phases/53-renderer-and-ir-contract-consolidation/53-CONTEXT.md] |
| Live service config | None found; htmlwidgets dependency order lives in `inst/htmlwidgets/gg2d3.yaml`, not an external UI or service database. [VERIFIED: inst/htmlwidgets/gg2d3.yaml] | Code edit only if load order changes. [VERIFIED: inst/htmlwidgets/gg2d3.yaml] |
| OS-registered state | None found; no launchd/systemd/pm2/task registration is part of this package phase. [VERIFIED: .planning/ROADMAP.md; DESCRIPTION] | None. [VERIFIED: .planning/ROADMAP.md] |
| Secrets/env vars | `GG2D3_BROWSER_VISUAL_SMOKE`, `GG2D3_BROWSER_VISUAL_CI`, `CHROMOTE_CHROME`, and GitHub Actions metadata env vars affect optional browser validation only. [VERIFIED: tests/testthat/helper-browser-visual.R; vignettes/d3-drawing-diagnostics.md] | Preserve names and skip semantics; do not rename env vars. [VERIFIED: tests/testthat/helper-browser-visual.R] |
| Build artifacts | Browser visual artifacts are generated under ignored `test_output/browser-visual-smoke/` only when opt-in smoke runs. [VERIFIED: tests/testthat/helper-browser-visual.R; vignettes/d3-drawing-diagnostics.md] | No artifact migration; source tests should not depend on generated artifacts. [VERIFIED: tests/testthat/test-browser-visual-smoke.R] |

## Common Pitfalls

### Pitfall 1: Contract Exists But Is Not Strict Enough

**What goes wrong:** A new registered geom alias or selector drifts without a useful failure naming the missing surface. [VERIFIED: tests/testthat/test-renderer-wiring-contracts.R; .planning/phases/53-renderer-and-ir-contract-consolidation/53-CONTEXT.md]

**Why it happens:** The current tests parse aliases and selectors, but module path/load-order and render-selector production can be tightened further. [VERIFIED: tests/testthat/test-renderer-wiring-contracts.R; inst/htmlwidgets/gg2d3.yaml; inst/htmlwidgets/modules/geom-contracts.js]

**How to avoid:** Add tests that compare `module` entries to `gg2d3.yaml`, verify each module file exists and is loaded after dependencies, verify render selectors appear in the declared renderer module, and include `info` messages naming the alias/module/selector. [VERIFIED: inst/htmlwidgets/gg2d3.yaml; inst/htmlwidgets/modules/geoms; tests/testthat/test-renderer-wiring-contracts.R]

**Warning signs:** Test failures say only `expect_true(...) is not TRUE` or use a bulk `all(...)` assertion without naming the missing alias or selector. [VERIFIED: tests/testthat/test-renderer-wiring-contracts.R]

### Pitfall 2: Treating All Interaction Surfaces As Identical

**What goes wrong:** Crosstalk gets forced to bind marks that it intentionally excludes, or events/brush lose interval/dotplot/rug coverage. [VERIFIED: inst/htmlwidgets/modules/geom-contracts.js; inst/htmlwidgets/modules/crosstalk.js]

**Why it happens:** `events`, `brush`, and `crosstalk` have different selector surfaces, and the contract encodes crosstalk exceptions with reasons. [VERIFIED: inst/htmlwidgets/modules/geom-contracts.js; tests/testthat/test-renderer-wiring-contracts.R]

**How to avoid:** Validate each surface separately through `selectorsFor(surface)` and require reasons for empty selector objects. [VERIFIED: inst/htmlwidgets/modules/geom-contracts.js]

**Warning signs:** A test compares one shared selector list to all three modules without allowing explicit exceptions. [VERIFIED: tests/testthat/test-renderer-wiring-contracts.R]

### Pitfall 3: Sanitizer Coverage Without Payload Behavior Checks

**What goes wrong:** Tests prove the sanitizer exists but not that every public consumer uses it. [VERIFIED: inst/htmlwidgets/modules/public-data.js; tests/testthat/test-renderer-wiring-contracts.R]

**Why it happens:** Tooltip/events/brush have wrapper sanitizers, and crosstalk legitimately reads `_sourceIndex` internally before public payload exposure. [VERIFIED: inst/htmlwidgets/modules/tooltip.js; inst/htmlwidgets/modules/events.js; inst/htmlwidgets/modules/brush.js; inst/htmlwidgets/modules/crosstalk.js]

**How to avoid:** Keep tests that assert consumer delegation to `publicData.sanitizeDatum()` and add contract-driven checks for every `privateFields` entry. [VERIFIED: tests/testthat/test-renderer-wiring-contracts.R; inst/htmlwidgets/modules/geom-contracts.js]

**Warning signs:** A private field such as `_polygonPoints`, `_sourceIndex`, `_geom`, or `_sfAnchor` appears in a public callback fixture. [VERIFIED: tests/testthat/test-polygon-interactivity.R; tests/testthat/test-sf-interactivity.R; tests/testthat/test-sf-annotations-interactivity.R]

### Pitfall 4: Extracting Too Much From `as_d3_ir()`

**What goes wrong:** A broad refactor changes representative IR output while chasing modularity. [VERIFIED: .planning/phases/53-renderer-and-ir-contract-consolidation/53-CONTEXT.md]

**Why it happens:** `as_d3_ir()` still coordinates build orchestration, theme extraction, coord metadata, guide extraction, and final IR assembly, so large moves have high blast radius. [VERIFIED: R/as_d3_ir.R]

**How to avoid:** Extract only high-risk seams named by the context, one seam at a time, and run `test-ir-helper-boundaries.R` after each seam. [VERIFIED: .planning/phases/53-renderer-and-ir-contract-consolidation/53-CONTEXT.md; tests/testthat/test-ir-helper-boundaries.R]

**Warning signs:** Plans propose a full file split, exported helper API, or a generated schema before focused tests pass. [VERIFIED: .planning/phases/53-renderer-and-ir-contract-consolidation/53-CONTEXT.md]

### Pitfall 5: Optional Dependency Confusion

**What goes wrong:** sf or browser visual tests look like failures when they are expected skips in the local environment. [VERIFIED: tests/testthat/test-ir-helper-boundaries.R; tests/testthat/helper-browser-visual.R; test runs 2026-05-28]

**Why it happens:** `sf` is missing locally, browser visual smoke requires `GG2D3_BROWSER_VISUAL_SMOKE=true`, and Chrome/chromote are optional validation infrastructure. [VERIFIED: `rtk Rscript ... requireNamespace`; tests/testthat/helper-browser-visual.R]

**How to avoid:** Keep source contract tests as the main gate and document skip expectations in validation tasks. [VERIFIED: .planning/phases/53-renderer-and-ir-contract-consolidation/53-CONTEXT.md; tests/testthat/test-browser-visual-smoke.R]

**Warning signs:** A planner makes browser smoke mandatory for each small source edit or requires sf fixtures without installing `sf`. [VERIFIED: tests/testthat/helper-browser-visual.R; test run 2026-05-28]

## Code Examples

### Actionable Missing Selector Message

```r
# Source: tests/testthat/test-renderer-wiring-contracts.R
for (selector in selectors) {
  expect_true(
    grepl(selector, registry_js, fixed = TRUE),
    info = paste("Missing updateGeoms selector:", selector)
  )
}
```

This pattern should be extended to module paths, render selectors, private fields, and sanitizer surfaces. [VERIFIED: tests/testthat/test-renderer-wiring-contracts.R]

### Contract Alias Parsing

```r
# Source: tests/testthat/test-renderer-wiring-contracts.R
test_that("geom contract lists every registered renderer alias", {
  contract_js <- read_module("inst/htmlwidgets/modules/geom-contracts.js")

  expect_setequal(contract_aliases(contract_js), registered_aliases())
})
```

This pattern is the right source-level drift gate for renderer aliases. [VERIFIED: tests/testthat/test-renderer-wiring-contracts.R]

### Temporal Helper Boundary

```r
# Source: R/ir_layer_helpers.R
gg2d3_ir_apply_temporal_layer_columns <- function(df, x_trans_name, y_trans_name) {
  x_cols <- intersect(c("x", "xmin", "xmax", "xend", "xintercept"), names(df))
  y_cols <- intersect(c("y", "ymin", "ymax", "yend", "yintercept"), names(df))
  # ...
  df
}
```

This is an existing helper seam that Phase 53 should preserve when extracting adjacent layer preprocessing logic. [VERIFIED: R/ir_layer_helpers.R; tests/testthat/test-ir-helper-boundaries.R]

### Theme Extraction Candidate

```r
# Source: R/as_d3_ir.R
extract_theme_element <- function(element_name, theme) {
  calc <- gg2d3_calc_element(element_name, theme)
  # element_blank, element_rect, element_line, element_text, margin, and unit handling
}
```

This nested helper is a high-value extraction candidate because context names theme extraction as a priority seam and the helper currently lives inside `as_d3_ir()`. [VERIFIED: R/as_d3_ir.R; .planning/phases/53-renderer-and-ir-contract-consolidation/53-CONTEXT.md]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Manual duplicated interaction selector arrays | `geomContracts.selectorsFor(surface)` with fallbacks in events/brush/crosstalk | Phase 50, v1.12 [VERIFIED: .planning/milestones/v1.12-phases/50-renderer-wiring-and-interaction-contracts/50-RESEARCH.md; inst/htmlwidgets/modules/events.js] | Phase 53 should test the contract more strictly instead of replacing the pattern. [VERIFIED: .planning/phases/53-renderer-and-ir-contract-consolidation/53-CONTEXT.md] |
| Duplicated underscore-field sanitizer logic | Shared `public-data.js` sanitizer with consumer delegation | Phase 50, v1.12 [VERIFIED: .planning/milestones/v1.12-phases/50-renderer-wiring-and-interaction-contracts/50-RESEARCH.md; inst/htmlwidgets/modules/public-data.js] | Phase 53 should make sanitizer expectations contract-driven and failure-local. [VERIFIED: tests/testthat/test-renderer-wiring-contracts.R] |
| Monolithic `as_d3_ir()` owns scale/layer/facet logic | Existing internal helper files for scale, layer, and facet boundaries | Phase 49, v1.12 [VERIFIED: .planning/milestones/v1.12-phases/49-ir-helper-boundary-hardening/49-RESEARCH.md; R/ir_scale_helpers.R; R/ir_layer_helpers.R; R/ir_facet_helpers.R] | Phase 53 should extract only remaining high-risk seams. [VERIFIED: .planning/phases/53-renderer-and-ir-contract-consolidation/53-CONTEXT.md] |
| Browser smoke as local optional evidence only | CI/browser visual smoke foundation with deterministic artifacts | Phase 52, v1.13 [VERIFIED: .planning/ROADMAP.md; tests/testthat/helper-browser-visual.R; vignettes/d3-drawing-diagnostics.md] | Phase 53 can use browser smoke downstream but should not make it the primary drift gate. [VERIFIED: .planning/phases/53-renderer-and-ir-contract-consolidation/53-CONTEXT.md] |

**Deprecated/outdated:**

- Generated renderer documentation is not part of Phase 53 because it remains `FUT-04`. [VERIFIED: .planning/phases/53-renderer-and-ir-contract-consolidation/53-CONTEXT.md]
- Full `as_d3_ir()` modularization is not part of Phase 53 because it remains `FUT-03`. [VERIFIED: .planning/phases/53-renderer-and-ir-contract-consolidation/53-CONTEXT.md]
- Committed pixel goldens and thresholds are not part of Phase 53 because they are deferred until artifacts are stable across environments. [VERIFIED: .planning/phases/53-renderer-and-ir-contract-consolidation/53-CONTEXT.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| - | None. All planning-relevant claims are tied to project files, local command output, or phase context. [VERIFIED: sources listed below] | - | - |

## Open Questions

1. **How much diagnostics text is enough?**
   - What we know: Phase 53 success criteria require diagnostics or architecture notes describing the remaining modularization boundary and future migration path. [VERIFIED: .planning/ROADMAP.md]
   - What's unclear: The exact amount of new text is left to implementation discretion. [VERIFIED: .planning/phases/53-renderer-and-ir-contract-consolidation/53-CONTEXT.md]
   - Recommendation: Add a short source-first section to `vignettes/d3-drawing-diagnostics.md` only if code/test changes create a new maintainership boundary that is not already described. [VERIFIED: vignettes/d3-drawing-diagnostics.md; .planning/phases/53-renderer-and-ir-contract-consolidation/53-CONTEXT.md]

2. **Should render selectors be verified by source text or runtime DOM?**
   - What we know: Current contract tests are source-level, and browser smoke validates representative rendered structure downstream. [VERIFIED: tests/testthat/test-renderer-wiring-contracts.R; tests/testthat/test-browser-visual-smoke.R]
   - What's unclear: Some selectors may be produced dynamically enough that a pure source grep is weaker than DOM smoke. [VERIFIED: inst/htmlwidgets/modules/geoms]
   - Recommendation: Use source tests for mandatory contract drift and browser smoke only as an optional confidence check. [VERIFIED: .planning/phases/53-renderer-and-ir-contract-consolidation/53-CONTEXT.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Rscript | All focused test commands | Yes | 4.6.0 | None needed. [VERIFIED: `rtk Rscript --version`] |
| ggplot2 | IR generation tests | Yes | 4.0.3 | None needed. [VERIFIED: `rtk Rscript ... packageVersion`] |
| testthat | Contract and helper-boundary tests | Yes | 3.3.2 | None needed. [VERIFIED: `rtk Rscript ... packageVersion`; DESCRIPTION] |
| pkgload | Focused test-file loading | Yes | 1.5.2 | `devtools::load_all()` for interactive development. [VERIFIED: `rtk Rscript ... packageVersion`; AGENTS.md] |
| chromote | Browser visual smoke | Yes | 0.5.1 | Source-level contract tests when browser smoke is not opted in. [VERIFIED: `rtk Rscript ... packageVersion`; tests/testthat/helper-browser-visual.R] |
| Chrome/Chromium | Browser visual smoke | Yes | `/Applications/Google Chrome.app/Contents/MacOS/Google Chrome` | Browser smoke skips/fails depending on CI mode. [VERIFIED: `chromote::find_chrome()` run 2026-05-28; tests/testthat/helper-browser-visual.R] |
| sf | sf IR helper-boundary fixtures | No | - | sf-dependent tests skip locally; install `sf` for full spatial coverage. [VERIFIED: `rtk Rscript ... requireNamespace`; test run 2026-05-28] |
| geojsonsf | sf serialization fixtures | Yes | 2.0.5 | Not useful for sf fixtures unless `sf` is installed. [VERIFIED: `rtk Rscript ... packageVersion`; tests/testthat/test-ir-helper-boundaries.R] |
| D3 v7 vendored file | Browser renderer | Yes | v7 in yaml | Re-vendor with AGENTS command if missing. [VERIFIED: inst/htmlwidgets/gg2d3.yaml; AGENTS.md] |

**Missing dependencies with no fallback:**
- None for source-level Phase 53 planning and primary contract tests. [VERIFIED: test runs 2026-05-28]

**Missing dependencies with fallback:**
- `sf` is missing locally; sf-dependent helper-boundary tests skip and full spatial confidence requires installing `sf`. [VERIFIED: `rtk Rscript ... requireNamespace`; test run 2026-05-28]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | testthat 3.3.2, edition 3. [VERIFIED: `rtk Rscript ... packageVersion`; DESCRIPTION] |
| Config file | `DESCRIPTION` has `Config/testthat/edition: 3`. [VERIFIED: DESCRIPTION] |
| Quick run command | `rtk Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-renderer-wiring-contracts.R"); testthat::test_file("tests/testthat/test-ir-helper-boundaries.R")'` [VERIFIED: individual test runs 2026-05-28] |
| Full suite command | `rtk Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_dir("tests/testthat")'` [VERIFIED: tests/testthat directory exists] |
| Browser smoke command | `rtk Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-browser-visual-smoke.R")'` [VERIFIED: test run 2026-05-28] |
| Full browser artifact command | `NOT_CRAN=true GG2D3_BROWSER_VISUAL_SMOKE=true rtk Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-browser-visual-smoke.R")'` [VERIFIED: tests/testthat/test-browser-visual-smoke.R; vignettes/d3-drawing-diagnostics.md] |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| ARCH-01 | Geom aliases, module paths, update selectors, interaction selectors, and sanitizer expectations are validated against `geom-contracts.js`. [VERIFIED: .planning/REQUIREMENTS.md; inst/htmlwidgets/modules/geom-contracts.js] | source/unit | `rtk Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-renderer-wiring-contracts.R")'` | Yes; 206 passing assertions on 2026-05-28. [VERIFIED: test run 2026-05-28] |
| ARCH-02 | Extracted helper seams preserve representative non-sf, sf, facet, scale, and annotation IR output. [VERIFIED: .planning/REQUIREMENTS.md; tests/testthat/test-ir-helper-boundaries.R] | unit/characterization | `rtk Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-ir-helper-boundaries.R")'` | Yes; 47 passing assertions and 2 sf skips on 2026-05-28. [VERIFIED: test run 2026-05-28] |
| ARCH-03 | Drift failures name missing alias, selector, module, private field, or sanitizer surface. [VERIFIED: .planning/REQUIREMENTS.md; .planning/phases/53-renderer-and-ir-contract-consolidation/53-CONTEXT.md] | source/unit | Same renderer contract command plus added focused failure-message checks. [VERIFIED: tests/testthat/test-renderer-wiring-contracts.R] | Yes, but Phase 53 should add stricter module/render-selector/actionable-message checks. [VERIFIED: tests/testthat/test-renderer-wiring-contracts.R; .planning/phases/53-renderer-and-ir-contract-consolidation/53-CONTEXT.md] |
| ARCH-01/03 downstream | Browser-rendered structure and runtime console remain healthy after contract changes. [VERIFIED: tests/testthat/test-browser-visual-smoke.R] | optional smoke | `rtk Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-browser-visual-smoke.R")'` | Yes; skipped locally without opt-in on 2026-05-28. [VERIFIED: test run 2026-05-28] |

### Sampling Rate

- **Per task commit:** Run the focused quick command for renderer or IR track files changed. [VERIFIED: tests/testthat/test-renderer-wiring-contracts.R; tests/testthat/test-ir-helper-boundaries.R]
- **Per wave merge:** Run the quick command plus affected adjacent tests such as `test-polygon-interactivity.R`, `test-sf-interactivity.R`, `test-sf-annotations-interactivity.R`, `test-facets.R`, and `test-date-scales.R` when those surfaces change. [VERIFIED: tests/testthat directory; .planning/milestones/v1.12-phases/49-ir-helper-boundary-hardening/49-RESEARCH.md; .planning/milestones/v1.12-phases/50-renderer-wiring-and-interaction-contracts/50-RESEARCH.md]
- **Phase gate:** Focused contract/helper tests must pass; browser visual smoke should run or skip with the documented opt-in message unless CI-equivalent artifact validation is explicitly requested. [VERIFIED: test runs 2026-05-28; tests/testthat/helper-browser-visual.R]

### Wave 0 Gaps

- [ ] Extend `tests/testthat/test-renderer-wiring-contracts.R` to verify every `module` path exists under `inst/htmlwidgets/modules/`, appears in `gg2d3.yaml`, and loads after `geom-contracts.js` plus `public-data.js` where needed. [VERIFIED: inst/htmlwidgets/modules/geom-contracts.js; inst/htmlwidgets/gg2d3.yaml]
- [ ] Extend `tests/testthat/test-renderer-wiring-contracts.R` to verify `renderSelectors` appear in the declared renderer module source or are explicitly justified. [VERIFIED: inst/htmlwidgets/modules/geom-contracts.js; inst/htmlwidgets/modules/geoms]
- [ ] Add focused IR helper-boundary checks for theme extraction and geom parameter routing before or immediately after extraction. [VERIFIED: R/as_d3_ir.R; tests/testthat/test-ir-helper-boundaries.R]
- [ ] Decide whether the diagnostics note is a small addition to `vignettes/d3-drawing-diagnostics.md`; no generated docs should be introduced. [VERIFIED: vignettes/d3-drawing-diagnostics.md; .planning/phases/53-renderer-and-ir-contract-consolidation/53-CONTEXT.md]

## Security Domain

Security enforcement is treated as enabled because `.planning/config.json` does not set `security_enforcement` to `false`. [VERIFIED: .planning/config.json]

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | No | Phase 53 does not add authentication behavior. [VERIFIED: .planning/ROADMAP.md; canonical source refs] |
| V3 Session Management | No | Phase 53 does not add session management behavior. [VERIFIED: .planning/ROADMAP.md; canonical source refs] |
| V4 Access Control | No | Phase 53 does not add authorization behavior. [VERIFIED: .planning/ROADMAP.md; canonical source refs] |
| V5 Input Validation | Yes | Validate internal contract shape and IR boundaries with testthat source/characterization tests. [VERIFIED: tests/testthat/test-renderer-wiring-contracts.R; tests/testthat/test-ir-helper-boundaries.R] |
| V6 Cryptography | No | Phase 53 does not add cryptography or secret handling. [VERIFIED: .planning/ROADMAP.md; canonical source refs] |

### Known Threat Patterns for R/htmlwidgets/D3 Contract Work

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Renderer-private data leaks through callbacks or tooltips | Information Disclosure | Shared `publicData.sanitizeDatum()` plus tests covering private fields. [VERIFIED: inst/htmlwidgets/modules/public-data.js; tests/testthat/test-renderer-wiring-contracts.R] |
| Contract drift silently disables interaction or zoom update behavior | Tampering / Integrity | Source-level tests compare aliases, update selectors, interaction selectors, module load order, and explicit exceptions. [VERIFIED: tests/testthat/test-renderer-wiring-contracts.R; inst/htmlwidgets/modules/geom-contracts.js] |
| Dynamic user-supplied JS callbacks throw at runtime | Denial of Service at widget level | Existing modules wrap formatter/handler compilation and callback execution with guarded error handling; Phase 53 should not widen this surface. [VERIFIED: inst/htmlwidgets/modules/tooltip.js; inst/htmlwidgets/modules/events.js; inst/htmlwidgets/modules/brush.js] |

## Sources

### Primary (HIGH confidence)

- `.planning/phases/53-renderer-and-ir-contract-consolidation/53-CONTEXT.md` - locked phase decisions, discretion, deferred scope, canonical refs. [VERIFIED: file read 2026-05-28]
- `.planning/REQUIREMENTS.md` - ARCH-01, ARCH-02, ARCH-03 requirement text. [VERIFIED: file read 2026-05-28]
- `.planning/ROADMAP.md` - Phase 53 goal and success criteria. [VERIFIED: file read 2026-05-28]
- `.planning/PROJECT.md` and `.planning/STATE.md` - milestone decisions and history. [VERIFIED: file read 2026-05-28]
- `CLAUDE.md`, `AGENTS.md`, `/Users/davidzenz/.codex/RTK.md` - project instructions and RTK shell rule. [VERIFIED: files read 2026-05-28]
- `inst/htmlwidgets/modules/geom-contracts.js` - renderer contract manifest. [VERIFIED: file read 2026-05-28]
- `inst/htmlwidgets/modules/geom-registry.js` - registration and `updateGeoms()` source. [VERIFIED: file read 2026-05-28]
- `inst/htmlwidgets/gg2d3.yaml` - htmlwidgets dependency load order. [VERIFIED: file read 2026-05-28]
- `inst/htmlwidgets/modules/public-data.js`, `events.js`, `brush.js`, `crosstalk.js`, `tooltip.js` - public payload and interaction surfaces. [VERIFIED: files read 2026-05-28]
- `R/as_d3_ir.R`, `R/ir_layer_helpers.R`, `R/ir_scale_helpers.R`, `R/ir_facet_helpers.R`, `R/ggplot2_compat.R` - IR helper boundaries and remaining extraction targets. [VERIFIED: files read 2026-05-28]
- `tests/testthat/test-renderer-wiring-contracts.R`, `tests/testthat/test-ir-helper-boundaries.R`, `tests/testthat/test-browser-visual-smoke.R`, `tests/testthat/helper-browser-visual.R` - current validation architecture. [VERIFIED: files read and tests run 2026-05-28]

### Secondary (MEDIUM confidence)

- `.planning/milestones/v1.12-phases/49-ir-helper-boundary-hardening/49-RESEARCH.md` - prior IR helper research. [VERIFIED: file read 2026-05-28]
- `.planning/milestones/v1.12-phases/50-renderer-wiring-and-interaction-contracts/50-RESEARCH.md` - prior renderer contract research. [VERIFIED: file read 2026-05-28]
- `vignettes/d3-drawing-diagnostics.md` - current diagnostics location and residual-risk notes. [VERIFIED: file read 2026-05-28]

### Tertiary (LOW confidence)

- None. [VERIFIED: no web-only claims used]

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH - versions and dependency roles were verified from `DESCRIPTION`, local package versions, and source usage. [VERIFIED: DESCRIPTION; command output 2026-05-28]
- Architecture: HIGH - source files and prior phase research agree on the R -> IR -> D3/htmlwidgets contract and helper/manifest boundaries. [VERIFIED: CLAUDE.md; R/as_d3_ir.R; inst/htmlwidgets/gg2d3.yaml; prior research files]
- Pitfalls: HIGH - pitfalls map directly to existing tests, phase decisions, and observed local skip behavior. [VERIFIED: tests/testthat/test-renderer-wiring-contracts.R; tests/testthat/test-ir-helper-boundaries.R; tests/testthat/test-browser-visual-smoke.R; test runs 2026-05-28]

**Research date:** 2026-05-28
**Valid until:** 2026-06-27 for codebase architecture; re-check local package versions and optional dependency availability before execution. [VERIFIED: command output 2026-05-28]
