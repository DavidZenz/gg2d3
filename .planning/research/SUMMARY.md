# Project Research Summary

**Project:** gg2d3 v1.1 Interactive Exploration
**Domain:** Interactive analytical plotting parity (ggplot2 semantics rendered via D3/htmlwidgets)
**Researched:** 2026-03-23
**Confidence:** HIGH

## Executive Summary

gg2d3 v1.1 is an **interaction-and-parity milestone**, not a net-new rendering stack. The research converges on a clear approach: keep the existing htmlwidgets + vendored D3 v7 architecture, then add missing interaction primitives (interactive discrete legends + synchronized transitions) while hardening semantic parity for advanced scales/coords. Experts build this type of product by treating guides, transitions, and coord/scale behavior as contract-driven system behavior—not ad hoc UI effects.

The strongest recommendation is to sequence work by dependency: establish a robust IR/compatibility contract first (stable keys, guide metadata, coord semantics), then build centralized transition infrastructure, then wire legend interactivity, and only then push advanced coord/scale parity and downstream integrations (zoom/brush/crosstalk). This order is repeatedly validated across architecture and pitfalls research: identity before animation, animation before controls, controls before parity edge-cases.

Primary risk is semantic drift: charts may look “interactive” while violating ggplot2 mental models (guide semantics, scale-vs-coord behavior, coord_flip directionality, and non-atomic updates). Mitigation is explicit: contract validation in R, keyed joins everywhere in JS, one transition orchestrator, and parity regression suites (including ggplot2 3.5.x/4.0.x matrix and browser-backed interaction tests).

## Key Findings

### Recommended Stack

v1.1 should retain the current delivery model and add only targeted capabilities for parity and interaction reliability. The stack decision is conservative by design: no runtime framework swaps, no bundler migration, no animation-library additions.

**Core technologies:**
- **ggplot2 (target 3.5.1+ and 4.0.x):** extraction source and behavior baseline — needed for modern guide/coord behavior and version-aware compatibility shims.
- **D3.js (vendored 7.9.0):** rendering + transitions/events — already contains transition/ease/dispatch/time-format modules required for v1.1.
- **htmlwidgets (>= 1.6.4):** R↔JS lifecycle bridge — matches existing architecture and supports stateful render/update flows.
- **scales (>= 1.4.0):** canonical breaks/labels/palette semantics — critical for parity-grade axis/label behavior.

Critical supporting choices: `d3-transition`, `d3-dispatch`, and browser-backed testing stack (`chromote`, `webshot2`, `shinytest2`).

### Expected Features

v1.1 scope is tightly focused on interactive exploration workflows used by analysts, with strict semantics for what legends and zoom-like operations mean.

**Must have (table stakes):**
- Discrete legend click toggle with persisted state.
- Legend solo mode (double-click) and reset behavior.
- Legend state synchronized with linked-view interaction state.
- Object-constant enter/update/exit transitions (with reduced-motion compliance).
- Synchronized axis + mark transitions when domains change.
- Scale parity hardening (`breaks`, `minor breaks`, `labels`, `expand`, `oob`, limits semantics).
- Date/datetime parity (including timezone display behavior).
- `coord_flip` correctness (axis side mapping, faceted contexts).

**Should have (differentiators):**
- Legend hover pre-highlight (non-committal emphasis).
- Interaction-type transition presets.
- Simple R transition API presets (`none/fast/smooth`) once defaults are validated.

**Defer (v1.2+):**
- Broad `coord_transform` parity beyond targeted support.
- Advanced legend query UX (search/hierarchy).
- Presentation-heavy storytelling animation modes.

### Architecture Approach

Architecture research strongly favors **contract-first extension of the current pipeline**: keep `as_d3_ir.R` and `gg2d3.js` as orchestrators, add stable-key and transition metadata to IR, and centralize animation behavior in a new `modules/transitions.js` reconciler.

**Major components:**
1. **R IR contract layer (`as_d3_ir.R` + `validate_ir.R`)** — emits stable row keys, guide interaction metadata, transition schema, and coord parity fields; enforces uniqueness/schema invariants.
2. **JS transition reconciler (`modules/transitions.js`)** — unified keyed join + timing/interrupt policy across geoms, axes, and legends.
3. **Legend/event integration (`modules/legend.js` + `modules/events.js`)** — semantic legend events (`toggle`, `hover`, `solo`) that update canonical interaction state rather than mutating DOM directly.
4. **Scale/coord mapping helpers (`modules/scales.js` + optional `modules/coords.js`)** — canonical mapping functions to prevent per-geom parity drift.

### Critical Pitfalls

1. **Guide semantics drift** — avoid by extracting/serializing guides as first-class IR and validating merged/split/order/position parity against ggplot2 references.
2. **Broken object constancy (index joins)** — avoid by requiring stable keys in IR and keyed joins in every animated layer.
3. **Desynchronized updates (marks/axes/legends)** — avoid with atomic render transactions and a single transition timeline.
4. **Scale-limit vs coord-zoom confusion** — avoid with two explicit semantics in API/runtime and parity tests mirroring ggplot2 behavior.
5. **Transition/event queue backlog under Shiny updates** — avoid with interrupts, last-write-wins tokens, and stress tests for deterministic final state.

## Implications for Roadmap

Based on combined research, suggested phase structure:

### Phase 1: IR Contract + Compatibility Baseline
**Rationale:** Every v1.1 capability depends on correct identity and semantics at the IR boundary.
**Delivers:** Stable mark keys, transition schema, guide interaction metadata, coord parity fields, validator upgrades, ggplot2 3.5.x/4.0.x adapter boundary.
**Addresses:** Legend sync prerequisites, scale/coord semantic correctness.
**Avoids:** Compatibility blindness and semantic drift from source ggplot2 behavior.

### Phase 2: Transition Infrastructure + Geom Join Migration
**Rationale:** Interactive updates are unsafe until keyed joins and orchestration are centralized.
**Delivers:** `transitions.js`, stateful `prevIR -> nextIR` path in `gg2d3.js`, keyed join migration for core geoms (point/line/bar/rect/text), shared timing/interrupt policy, reduced-motion branch.
**Uses:** D3 transition/ease/dispatch modules in current vendored stack.
**Implements:** Architecture Pattern 1 + 2 (identity + reconciler).
**Avoids:** Flicker, wrong morphs, and non-atomic updates.

### Phase 3: Interactive Legend Semantics
**Rationale:** User-visible v1.1 value lands after identity and transition primitives are reliable.
**Delivers:** Click toggle, solo/reset, linked-state synchronization, discrete-vs-continuous guide behavior correctness, optional hover highlight as controlled extension.
**Addresses:** P1 feature expectations for analyst workflows.
**Avoids:** “Visual-only toggles” that leave semantic state stale.

### Phase 4: Advanced Scale/Coord Parity Hardening
**Rationale:** Parity work is safest after interaction paths are deterministic.
**Delivers:** Break/label/oob/expand parity hardening, date/datetime fidelity, `coord_flip` axis/theme direction correctness, scale-domain change transition sync.
**Addresses:** Core trust requirement: ggplot2-consistent semantics during interaction.
**Avoids:** False zoom semantics, axis-side mismatches, and faceted parity regressions.

### Phase 5: Interactivity Reconciliation, Performance, and QA Gates
**Rationale:** Final stabilization phase reduces production risk in Shiny/htmlwidgets environments.
**Delivers:** zoom/brush/crosstalk interrupt handoff, clip-path lifecycle correctness, stress/perf budgets, browser-backed visual + event-order regression suite.
**Addresses:** Runtime determinism and enterprise-readiness.
**Avoids:** Queue growth, race conditions, and clipping artifacts.

### Phase Ordering Rationale

- **Identity before animation:** stable keys are the non-negotiable base for object constancy.
- **Animation before legend controls:** UI controls without reconciled transitions produce inconsistent state.
- **Parity hardening after core interaction:** advanced coord/scale bugs are easier to isolate once update mechanics are stable.
- **Stabilization at the end:** Shiny/reactive stress and clip/perf regressions require end-to-end behavior to already exist.

### Research Flags

Phases likely needing deeper research during planning:
- **Phase 3:** merged guide edge-cases and panel-specific guide behavior under legend interactivity.
- **Phase 4:** nuanced date/time timezone formatting and coord semantics across faceting/orientation combinations.
- **Phase 5:** reactive backpressure strategies in high-frequency Shiny update streams.

Phases with standard patterns (skip research-phase):
- **Phase 1:** IR schema/validation and compatibility adapter patterns are well-understood.
- **Phase 2:** keyed joins + centralized transition orchestration are established D3 patterns.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Strong official sources (CRAN + ggplot2 + D3 docs); recommendations are incremental and low-risk. |
| Features | HIGH | Table-stakes and MVP are concrete; only competitor-behavior references introduce minor uncertainty. |
| Architecture | HIGH | Clear alignment with existing code boundaries and proven D3/htmlwidgets patterns. |
| Pitfalls | HIGH | Risks are specific, reproducible, and mapped to prevention phases with test strategies. |

**Overall confidence:** HIGH

### Gaps to Address

- **Legend behavior policy under filtering:** decide whether scale/guide extents recompute or freeze under legend-driven hides; document one semantic model and test it.
- **Geom transition policy matrix completeness:** define per-geom interpolable vs snap attributes before broad animation enablement.
- **Large-mark performance thresholds:** set concrete cutoffs for disabling mark animations while preserving axis/legend transition quality.
- **Accessibility verification depth:** ensure legend state and filtered visibility are reflected in ARIA text and assistive behavior tests.

## Sources

### Primary (HIGH confidence)
- https://d3js.org/d3-transition — transition model and constraints.
- https://d3js.org/d3-selection/joining — keyed join semantics for object constancy.
- https://ggplot2.tidyverse.org/reference/get_guide_data.html — guide extraction contract.
- https://ggplot2.tidyverse.org/reference/guide_legend.html — discrete guide behavior.
- https://ggplot2.tidyverse.org/reference/guide_colourbar.html — continuous guide behavior.
- https://ggplot2.tidyverse.org/reference/coord_cartesian.html — coord zoom semantics.
- https://ggplot2.tidyverse.org/reference/coord_flip.html — flip directionality and axis mapping.
- https://ggplot2.tidyverse.org/reference/scale_continuous.html — limits/oob/expand semantics.
- https://ggplot2.tidyverse.org/reference/scale_date.html — date/datetime scale semantics.
- https://cran.r-project.org/web/packages/htmlwidgets/index.html — widget runtime baseline.
- https://cran.r-project.org/web/packages/scales/index.html — parity-grade label/break tooling.

### Secondary (MEDIUM confidence)
- https://plotly.com/r/legend/ — comparative legend interaction expectations.
- https://rstudio.github.io/crosstalk/using.html — linked-state integration patterns.

### Project-specific context
- `.planning/research/STACK.md`
- `.planning/research/FEATURES.md`
- `.planning/research/ARCHITECTURE.md`
- `.planning/research/PITFALLS.md`

---
*Research completed: 2026-03-23*
*Ready for roadmap: YES*
