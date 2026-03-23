# Pitfalls Research

**Domain:** gg2d3 v1.1 interactive exploration (interactive legends, transitions/animation, advanced coords/scales)
**Researched:** 2026-03-23
**Confidence:** HIGH

## Critical Pitfalls

### Pitfall 1: Legend semantics drift from ggplot2 guide semantics

**What goes wrong:**
Legend output looks plausible but is behaviorally wrong versus ggplot2: wrong key inclusion, wrong merged/split guides, wrong ordering, wrong placement, or wrong styling precedence.

**Why it happens:**
Teams implement “draw a legend from unique values” instead of reproducing ggplot2 guide semantics (`guide_legend()`, `guide_colourbar()`, guide integration/ordering, per-guide `position`, theme interaction). ggplot2 3.5+ and 4.x also shifted guide behavior and styling conventions.

**How to avoid:**
- Treat guides as first-class IR objects, not post-hoc D3 decorations.
- Extract guide metadata from built plot/scale objects (type, breaks, labels, order, reverse, per-guide position).
- Reproduce ggplot2 distinction between discrete legend keys and continuous colour bar semantics.
- Build golden test fixtures for: merged guides, separate guides, inside legend placement, reversed guides, `show.legend` edge cases.
- Lock minimum ggplot2 version and run compatibility matrix tests.

**Warning signs:**
- Legend keys include aesthetics from layers that ggplot2 suppresses.
- Continuous color legends render as discrete keys (or vice versa).
- `guides(order=...)` appears ignored.
- `legend.position = "inside"` plots mismatch ggplot2 screenshots.

**Phase to address:**
Phase 1 (Guide/legend IR contract + extraction tests) and Phase 3 (full legend rendering parity).

---

### Pitfall 2: Broken object constancy in transitions (index-based joins)

**What goes wrong:**
Animations “jump,” morph the wrong marks, or flicker when data order changes, filtering occurs, or faceting/scales update.

**Why it happens:**
D3 data joins default to index-based matching unless a key is provided. In a ggplot2 parity engine, row order can change across stats, scales, and panel operations; index joins break identity continuity.

**How to avoid:**
- Require stable per-mark keys in IR (panel id + layer id + row/group key).
- Use keyed joins everywhere (`selection.data(data, keyFn)`), never implicit index joins for animated layers.
- Define transition contracts per geom (which attrs interpolate vs snap).
- Add regression tests where data reorder is intentional (factor reorder, filtered subsets, faceting).

**Warning signs:**
- On update, marks animate from unrelated positions.
- Exit/enter counts spike despite small data changes.
- Same data values produce different animation paths between renders.

**Phase to address:**
Phase 2 (transition infrastructure + keyed join policy) before any user-facing animation API.

---

### Pitfall 3: Coordinated updates are not atomic (marks/axes/legends desynchronize)

**What goes wrong:**
During zoom/filter/update, marks animate on new scales while axes/legends still show old domains (or vice versa), creating temporary semantic lies and parity failures.

**Why it happens:**
Rendering pipeline updates components independently without a unified transition transaction. ggplot2 semantics are static snapshot-based; interactive runtime must emulate coherent state transitions explicitly.

**How to avoid:**
- Implement a render transaction model: compute next scene graph first, then commit marks + axes + legends in one transition timeline.
- Centralize scale-domain updates and propagate to all dependent components before starting animations.
- Use transition orchestration (shared duration/ease, interrupt policy, and completion callbacks).
- Add tests for rapid consecutive updates (double zoom, repeated filter toggles).

**Warning signs:**
- Axis ticks lag behind moving marks.
- Legend labels/colors update one frame late.
- Rapid interactions leave chart in mixed old/new state.

**Phase to address:**
Phase 2 (render transaction architecture), verified again in Phase 4 (advanced coord/scale interactions).

---

### Pitfall 4: Confusing scale limits with coord zoom semantics

**What goes wrong:**
Interactive “zoom” accidentally drops data (scale limits behavior) instead of visual zooming (coord behavior), causing changed stats and mismatched trend lines versus ggplot2 expectations.

**Why it happens:**
`scale_*` limits and `coord_cartesian()` limits are not equivalent in ggplot2. Scale limits censor/remove OOB data; coordinate limits zoom the view while preserving underlying data/stat computations.

**How to avoid:**
- Encode and enforce two distinct operations in API/runtime: data-domain filtering vs viewport zooming.
- For coord-style zoom, keep full data/stat state and only alter view transform/domain projection.
- Write explicit parity tests reproducing ggplot2 examples where smoothing differs under scale limits vs coord zoom.

**Warning signs:**
- Smoothers/hist bins change when user performs “zoom.”
- Point count drops unexpectedly after pan/zoom.
- Warnings equivalent to ggplot2 “removed rows outside scale range” appear in zoom flows.

**Phase to address:**
Phase 1 (semantic contract in IR/API) and Phase 4 (advanced coords/scales implementation).

---

### Pitfall 5: coord_flip and axis/theme directionality handled as simple x↔y swap

**What goes wrong:**
Flipped plots render with seemingly correct geometry but wrong axis ownership, theme application, and legend/guide orientation.

**Why it happens:**
ggplot2 `coord_flip()` semantics affect axis/theme direction mapping and coordinate interpretation beyond numeric swap. Also, `coord_flip()` is superseded and many layers now prefer explicit orientation, increasing edge-case complexity.

**How to avoid:**
- Implement coord semantics as full layout transform, not just scale swap.
- Preserve axis/theme mapping rules from ggplot2 docs (x settings apply horizontal direction, y settings vertical under flip).
- Add compatibility suite for both explicit orientation and `coord_flip()` legacy behavior.
- Keep `coord_flip` support but steer new API/features toward orientation-aware geoms.

**Warning signs:**
- Axis text/theme rules appear mirrored incorrectly.
- Flipped geoms look right but axis positions/titles do not match ggplot2.
- Mixed behavior between geoms with/without orientation argument.

**Phase to address:**
Phase 4 (advanced coord parity) with prerequisite baseline tests in Phase 1.

---

### Pitfall 6: Transitioning non-interpolable attributes without policy

**What goes wrong:**
Paths self-intersect, ribbons/areas fold, text rotates unpredictably, or transitions degrade performance badly when trying to tween attributes that should snap.

**Why it happens:**
D3 can interpolate many values, but not every ggplot-rendered attribute should be tweened. Complex path topology or categorical changes often require enter/exit/snap policies rather than interpolation.

**How to avoid:**
- Define per-geom transition policy matrix: interpolable attrs, discrete attrs, and “rebuild required” conditions.
- For path-like geoms, enforce compatible point ordering/topology before tweening, else fall back to fade/snap.
- Use `attrTween/styleTween` only where mathematically valid.
- Add performance budgets and disable heavy tweens beyond thresholds.

**Warning signs:**
- Area/line animations create loops or spikes.
- Frame rate collapses on medium datasets.
- Visual artifacts disappear when transitions are disabled.

**Phase to address:**
Phase 2 (transition policy foundation) and Phase 5 (polish/performance hardening).

---

### Pitfall 7: Legend interactivity mutates visual state but not semantic state

**What goes wrong:**
Clicking legend keys hides/fades layers visually, but scales, guide state, aria labeling, and linked interactions remain stale or contradictory.

**Why it happens:**
Legend is treated as a UI toggle disconnected from the plot’s canonical state model.

**How to avoid:**
- Introduce a single canonical interaction state (visibility/filter selections) that drives both marks and guides.
- Recompute dependent guide extents/labels when legend-driven filters are active (or explicitly freeze semantics and document behavior).
- Keep accessibility/aria descriptions synchronized with current visible state.
- Test legend interactions with multi-aesthetic guides and faceted plots.

**Warning signs:**
- Hidden series still appear in tooltip/brush interactions.
- Legend indicates disabled state but axis/scale domain still includes hidden series unexpectedly.
- Screen reader text mismatches visible chart.

**Phase to address:**
Phase 3 (interactive legends) with verification in Phase 5 (accessibility + QA).

---

### Pitfall 8: Clip-path and off-panel drawing regressions under animation

**What goes wrong:**
Animated marks bleed into margins, overlap legends/titles, or disappear prematurely near panel edges.

**Why it happens:**
`coord_cartesian(clip=...)` semantics and panel clipping are not consistently applied through enter/update/exit transitions. Animating transforms can temporarily bypass expected clip boundaries.

**How to avoid:**
- Make clip-path assignment part of core layer lifecycle (enter/update/exit).
- Bind transitions inside clipped groups, not outside panel containers.
- Add dedicated tests for `clip="on"` vs `clip="off"`, including zoom/pan and exiting marks.

**Warning signs:**
- Marks appear in axis/title/legend regions during transitions.
- Pan/zoom leaves “ghost” marks outside panel.
- Behavior differs between first render and update render.

**Phase to address:**
Phase 2 (render pipeline/transition architecture) and Phase 4 (coord behavior validation).

---

### Pitfall 9: Unbounded transition/event queues in htmlwidgets + Shiny updates

**What goes wrong:**
Rapid reactive updates create backlog: old transitions keep running, interactions lag, memory/CPU climb, and final state becomes nondeterministic.

**Why it happens:**
htmlwidgets `renderValue` updates can arrive faster than transitions complete; without interrupt/cancel strategy, D3 timers queue work indefinitely.

**How to avoid:**
- Define explicit interrupt strategy (`selection.interrupt`) on new renders.
- Debounce/throttle high-frequency updates from Shiny where appropriate.
- Adopt “last-write-wins” state token to discard stale updates.
- Instrument transition counts/timing in dev mode and fail tests on queue growth.

**Warning signs:**
- CPU remains high after interactions stop.
- Chart visibly lags behind controls.
- Same input sequence yields different end states.

**Phase to address:**
Phase 2 (runtime control-plane) before enabling transition-heavy user features.

---

### Pitfall 10: Compatibility blindness across ggplot2 versions for guides/coords

**What goes wrong:**
Features pass locally but fail for users on different ggplot2 minor/major versions due to guide API shifts, deprecations, or internal structure changes.

**Why it happens:**
Implementation assumes one ggplot2 structure snapshot; milestone adds functionality in volatile areas (guides, coords, orientation, legend theming).

**How to avoid:**
- Establish supported ggplot2 version range explicitly (e.g., >=3.5 with tested 4.x).
- Add CI matrix for at least: min-supported, current CRAN, devel.
- Isolate ggplot2 extraction in adapter layer with feature flags/capability detection.
- Maintain snapshot corpus of representative plots for each supported version.

**Warning signs:**
- User issues reproducible only on specific ggplot2 versions.
- Legend/theme behavior drifts after dependency update.
- Frequent hotfixes around extractor code.

**Phase to address:**
Phase 1 (compatibility policy + adapter boundary) and ongoing verification each phase gate.

---

## Technical Debt Patterns

Shortcuts that seem reasonable but create long-term problems.

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Build legends from rendered layer colors/sizes only | Fast prototype | Can’t match guide merging/order/theme semantics | Never for parity milestone |
| Use index-based joins for transitions | Minimal code | Broken object constancy, flicker | Never |
| Animate every attribute by default | Quick “wow” demos | Artifacts + poor performance + nondeterminism | Never |
| Recompute scales per layer independently | Local simplicity | Desync between marks/axes/legends | Never |
| Handle zoom by rewriting scale limits | Easy implementation | Changes data semantics vs coord zoom | Never |
| Ignore transition interrupt handling | Fewer state controls | Queue growth, lag, race conditions | Never in Shiny/htmlwidgets context |

## Integration Gotchas

Common mistakes when connecting interactive behavior in an R/htmlwidgets/D3 stack.

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| htmlwidgets `renderValue` updates | Start new transitions without cancelling old ones | Interrupt prior transitions, apply version/token guard |
| Shiny reactivity | Treat every input tick as full animated render | Coalesce/debounce high-frequency events, render atomically |
| Crosstalk-like linked state | Use unstable row indices as linkage keys | Use stable public-safe keys; enforce key uniqueness |
| ggplot2 guide extraction | Infer legend content from layer data only | Extract from scales/guides metadata + layer participation |
| coord + clipping | Clip only on initial render | Reapply clip-path policy across enter/update/exit |
| Theme-driven legend placement | Position legends in raw SVG coordinates only | Respect guide `position`, theme justifications, inside placement |

## Performance Traps

Patterns that work at small scale but fail as usage grows.

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Full DOM rebuild per reactive update | Flicker, high CPU, no smooth animation | Keyed join + incremental update strategy | ~1k+ marks with frequent updates |
| Animating path `d` for large multi-series lines | Stutter, browser jank | Simplify/fallback transitions, topology checks | ~5k+ vertices or many concurrent series |
| Recomputing legend layout every frame | Interaction lag | Precompute legend layout; update only changed guides | 5+ guides with frequent state toggles |
| Axis tick regeneration on every minor interaction | Tick popping, layout jitter | Cache ticks when domain unchanged; atomic updates | High-frequency pan/brush scenarios |
| Unbounded queued transitions | Memory growth, delayed final state | Interrupt policy + capped durations + stale update discard | Any rapid Shiny/reactive stream |

## Security Mistakes

Domain-specific security issues beyond general web security.

| Mistake | Risk | Prevention |
|---------|------|------------|
| Rendering legend/tooltip labels with HTML injection paths | XSS in notebooks/apps | Use text nodes by default; sanitize any opt-in HTML |
| Using raw data keys that include sensitive IDs for interactivity | Identifier leakage in client HTML/JS | Use non-sensitive surrogate keys for client state |
| Allowing arbitrary JS callback strings in interaction API by default | Code injection surface | Keep callback registration explicit/trusted; document trust model |

## UX Pitfalls

Common user experience mistakes in this domain.

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| Fancy transitions that alter perceived data values | Users misread trends | Keep duration short, prioritize semantic clarity over spectacle |
| Legend toggles with unclear active state | Confusion about what is shown | Explicit active/inactive styling + accessible labels |
| Zoom behavior inconsistent with ggplot2 mental model | Trust erosion for parity-focused users | Separate “zoom view” vs “filter data” controls and labels |
| Inside legends overlapping marks after interactions | Lost readability | Collision-aware legend placement or fallback to side placement |

## "Looks Done But Isn't" Checklist

Things that appear complete but are missing critical pieces.

- [ ] **Interactive legends:** Keys toggle visibility, but merged guide semantics still mismatch ggplot2.
- [ ] **Transitions:** Demo looks smooth on static ordering, but fails with reordered/filter-updated data.
- [ ] **Coord zoom:** Visual zoom works, but stats/axes semantics match scale-limit censoring (wrong).
- [ ] **Advanced coords:** `coord_flip` looks right for one geom, but axis/theme direction rules fail broadly.
- [ ] **Update pipeline:** Marks animate, but axes/legends are not synchronized transactionally.
- [ ] **Shiny/reactive stress:** Works with slow updates, but queues/race conditions appear under rapid updates.
- [ ] **Clip behavior:** First render clips correctly; animated enter/exit leaks outside panel.

## Recovery Strategies

When pitfalls occur despite prevention, how to recover.

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Guide semantics drift | HIGH | Freeze feature work; build guide IR contract + golden corpus; refactor legend renderer to consume guide IR only |
| Broken transition identity | MEDIUM | Introduce stable keys in IR, migrate all joins to keyed joins, re-baseline animation tests |
| Desynchronized updates | HIGH | Implement render transaction boundary and shared transition orchestration |
| Zoom semantics conflated | MEDIUM | Split API/engine paths for coord zoom vs scale filtering; add explicit tests from ggplot2 examples |
| coord_flip partial implementation | MEDIUM | Rework as layout transform stage; add axis/theme direction regression suite |
| Transition queue backlog | MEDIUM | Add interrupts + stale-token discard + input throttling in reactive integrations |

## Pitfall-to-Phase Mapping

How roadmap phases should address these pitfalls.

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| Legend semantics drift | Phase 1 + Phase 3 | Snapshot compare of legend structure/placement/order vs ggplot2 reference corpus |
| Broken object constancy | Phase 2 | Reorder/filter animation tests confirm stable mark identity paths |
| Non-atomic coordinated updates | Phase 2 (+ Phase 4 validation) | Transaction tests: marks/axes/legends move on synchronized timeline |
| Scale-vs-coord semantic confusion | Phase 1 + Phase 4 | Parity tests for `coord_cartesian()` zoom vs scale-limit censor behavior |
| coord_flip oversimplification | Phase 4 | Regression suite across geoms + axis/theme direction checks |
| Unsafe interpolation policy | Phase 2 + Phase 5 | Geom transition matrix tests + perf budget checks under medium datasets |
| Legend UI/state divergence | Phase 3 + Phase 5 | Interaction tests for visibility/filter/accessibility consistency |
| Clip-path animation regressions | Phase 2 + Phase 4 | Visual regression for enter/update/exit with `clip` on/off |
| Reactive transition queue growth | Phase 2 | Stress tests with rapid updates show bounded timers and deterministic end state |
| ggplot2 version compatibility blindness | Phase 1 + ongoing | CI matrix (min/current/devel ggplot2) + snapshot corpus per version |

## Sources

### Primary (HIGH confidence)
- ggplot2 guide_legend reference (v4.0.2): https://ggplot2.tidyverse.org/reference/guide_legend.html
- ggplot2 guide_colourbar reference (v4.0.2): https://ggplot2.tidyverse.org/reference/guide_colourbar.html
- ggplot2 guides reference (v4.0.2): https://ggplot2.tidyverse.org/reference/guides.html
- ggplot2 coord_cartesian reference (v4.0.2): https://ggplot2.tidyverse.org/reference/coord_cartesian.html
- ggplot2 coord_flip reference (v4.0.2): https://ggplot2.tidyverse.org/reference/coord_flip.html
- ggplot2 expansion reference (v4.0.2): https://ggplot2.tidyverse.org/reference/expansion.html
- ggplot2 scale_continuous reference (v4.0.2): https://ggplot2.tidyverse.org/reference/scale_continuous.html
- ggplot2 3.5.0 legends blog: https://tidyverse.org/blog/2024/02/ggplot2-3-5-0-legends/
- D3 joining data docs (v7.9.0): https://d3js.org/d3-selection/joining
- D3 transition docs (v7.9.0): https://d3js.org/d3-transition
- htmlwidgets advanced topics vignette (CRAN, 2023-12-05): https://cran.r-project.org/web/packages/htmlwidgets/vignettes/develop_advanced.html

### Secondary (MEDIUM confidence)
- Crosstalk usage docs (official, integration patterns): https://rstudio.github.io/crosstalk/using.html

### Project-specific context
- Repository guidance and architecture notes: `/Users/davidzenz/R/gg2d3/CLAUDE.md`
- Existing research baseline and known limitations: `.planning/research/SUMMARY.md`, `.planning/research/ARCHITECTURE.md`

---
*Pitfalls research for: gg2d3 v1.1 interactive exploration milestone*
*Researched: 2026-03-23*
