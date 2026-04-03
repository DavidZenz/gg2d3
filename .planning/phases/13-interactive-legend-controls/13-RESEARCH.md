# Phase 13: Interactive Legend Controls - Research

**Researched:** 2026-03-23  
**Domain:** Interactive discrete legend state management in gg2d3 (R htmlwidgets + D3 v7)  
**Confidence:** MEDIUM-HIGH

## User Constraints

No `*-CONTEXT.md` exists for Phase 13, so there are no locked decisions to copy verbatim.

Constraints from roadmap/requirements and user-provided phase context:
- Scope is strictly **Phase 13** and only **LEG-01..LEG-04**.
- Keep phase independent and comprehensive.
- Focus on **discrete legend interaction** as a state controller.
- Preserve linked-view consistency (legend state must synchronize with existing interaction state).
- Keep continuous colorbars non-interactive for this phase.

## Summary

Phase 13 is primarily a **state architecture** phase, not a drawing phase. The codebase already renders discrete legends (`legend.js`), has interaction modules (`events.js`, `brush.js`, `zoom.js`), and has linked selection plumbing (`crosstalk.js`), but there is currently no shared interaction-state model and no legend event pipeline. If implemented ad hoc (mutating DOM directly from legend clicks), LEG-03 will likely fail.

The reliable approach is to introduce a canonical legend interaction state in JS (active/hidden/solo + transient hover preview), expose semantic legend events (`toggle`, `solo`, `reset`, `hover-in`, `hover-out`) via `d3-dispatch`, and make marks + legend visuals subscribe to that state. This should be integrated with existing opacity flows (`data-original-opacity`, brush-active guardrails) so hover preview remains temporary and does not overwrite persistent filter state.

**Primary recommendation:** Implement a centralized legend state store + `d3.dispatch` event bus, then adapt `legend.js`, `events.js`, and `crosstalk.js` to read/write the same state contract.

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| D3 (vendored) | 7.9.0 | Legend DOM events, dispatch bus, selections, transitions | Already shipped in repo (`d3.v7.min.js`), includes needed modules (`selection`, `dispatch`, `transition`) |
| htmlwidgets | Existing project runtime | R→JS payload and post-render hooks | Existing integration model for all interactivity (`onRender`) |
| ggplot2 guide extraction (`as_d3_ir`) | Current code path | Distinguish discrete `legend` vs continuous `colorbar` | Required for LEG scope split and parity with ggplot2 guide semantics |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| crosstalk | Current package integration | Linked-view synchronization channel | For LEG-03 when legend visibility should reflect across linked widgets |
| testthat | Current | Unit tests for R-side config/state wiring | Validate API payload/state contract |
| browser-based interaction checks (existing/manual harness; chromote optional) | N/A | Verify click/dblclick/hover sequencing and UI state | Use for integration-level acceptance of LEG-01..04 |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `d3.dispatch` semantic bus | DOM CustomEvent-only wiring | Harder lifecycle cleanup and namespacing across modules |
| centralized state map | direct `.style('opacity', ...)` in legend handlers | Fast to code but breaks synchronization and causes state drift |
| keeping colorbars passive | making all guides clickable | Violates ggplot guide semantics and user expectations |

**Installation:**
```bash
# No new runtime dependency required for Phase 13 baseline.
```

## Architecture Patterns

### Recommended Project Structure
```text
inst/htmlwidgets/
├── gg2d3.js                  # draw pipeline entrypoint
└── modules/
    ├── legend.js             # render discrete/colorbar guides; add item identity attrs + handlers
    ├── events.js             # host shared interaction state + legend event binding helpers
    ├── crosstalk.js          # legend state ↔ linked-view sync
    ├── brush.js              # preserve brush-active semantics during legend hover preview
    └── zoom.js               # preserve dblclick reset separation from legend interactions
```

### Pattern 1: Canonical Legend Interaction State
**What:** Maintain one per-widget state object keyed by guide identity (e.g., aesthetic + level), with separate persistent and transient fields.

Suggested shape:
- `persistent.hidden: Set<key>`
- `persistent.solo: key | null`
- `transient.hover: key | null`

**When to use:** Always for LEG-01/02/03/04.

**Example:**
```typescript
// Source: d3-dispatch docs + repo module architecture
const bus = d3.dispatch("legend:toggle", "legend:solo", "legend:reset", "legend:hoverin", "legend:hoverout", "legend:changed");

const legendState = {
  hidden: new Set(),
  solo: null,
  hover: null
};

function effectiveVisibility(key) {
  if (legendState.solo !== null) return key === legendState.solo;
  return !legendState.hidden.has(key);
}
```

### Pattern 2: Event Semantics, Not DOM Semantics
**What:** Legend item click/dblclick/hover handlers emit semantic events and do not directly mutate geom DOM in-place.

**When to use:** Any legend input path.

**Example:**
```typescript
// Source: d3-selection .on namespacing + MDN click/dblclick ordering
legendItem
  .on("click.legend", (event, d) => {
    // gate against dblclick race: defer toggle slightly
    scheduleSingleClickToggle(d.key);
  })
  .on("dblclick.legend", (event, d) => {
    cancelScheduledToggle(d.key);
    bus.call("legend:solo", null, { key: d.key });
  })
  .on("mouseover.legend", (event, d) => bus.call("legend:hoverin", null, { key: d.key }))
  .on("mouseout.legend", () => bus.call("legend:hoverout", null, {}));
```

### Pattern 3: Two-Phase Visual Application
**What:** Compute effective mark state from persistent + transient state, then apply styles in one pass to marks and legend keys.

**When to use:** After every legend and linked-view state change.

**Example:**
```typescript
// Source: existing opacity conventions in events.js/crosstalk.js
function applyLegendState(svg, state) {
  // persistent visibility (display/opacity) first
  // transient hover emphasis second
  // never overwrite data-original-opacity baseline
}
```

### Anti-Patterns to Avoid
- **Direct style toggling in `legend.js` click handlers:** causes LEG-03 desync with crosstalk/brush states.
- **Single shared “opacity” without layering:** hover preview (LEG-04) will accidentally persist.
- **Unscoped listeners (`.on('click', ...)` without namespace):** breaks cleanup/rebind on redraw.
- **Applying click behavior to colorbars:** violates discrete/continuous guide contract.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Event bus between modules | ad hoc global callbacks | `d3.dispatch` | Named channels, replace/remove semantics, stable D3 pattern |
| Click vs dblclick arbitration | fragile timestamp hacks everywhere | single helper leveraging DOM event ordering (`click` before `dblclick`) | Prevent duplicate toggle+solo races |
| Full guide semantics engine rewrite | custom guide model from scratch | existing `as_d3_ir` guide extraction + incremental metadata extension | Already handles legend/colorbar split + merged guides |
| Linked-view sync transport | custom postMessage/store | existing crosstalk SelectionHandle integration | Already supported in widget payload/runtime |

**Key insight:** In this phase, custom rendering is cheap; custom state semantics are expensive. Reuse D3/ggplot2/crosstalk primitives and centralize state logic.

## Common Pitfalls

### Pitfall 1: Click and double-click conflict (LEG-01 vs LEG-02)
**What goes wrong:** Single-click toggle fires, then dblclick solo fires, leaving wrong final state.
**Why it happens:** Browser event order emits two click events before dblclick.
**How to avoid:** Defer click action briefly and cancel on dblclick.
**Warning signs:** Intermittent failure where solo leaves an extra series hidden.

### Pitfall 2: Hover preview mutates persistent filter (LEG-04 failure)
**What goes wrong:** Hover leaves marks dimmed/hidden after mouseout.
**Why it happens:** No separation between transient and persistent state.
**How to avoid:** Keep `hover` in separate transient channel and recompute effective styles each frame.
**Warning signs:** Mouseout does not fully restore prior toggle/solo state.

### Pitfall 3: Linked-view desynchronization (LEG-03 failure)
**What goes wrong:** Legend indicates hidden/solo, but linked widgets (crosstalk) show contradictory selection.
**Why it happens:** Legend updates only local DOM; no crosstalk bridge.
**How to avoid:** Translate legend visibility into same shared state updates used by linked-view handlers.
**Warning signs:** Interactions work in single widget but not across shared group.

### Pitfall 4: Overlapping opacity systems (hover/brush/crosstalk/legend)
**What goes wrong:** Last interaction wins and erases previous state.
**Why it happens:** Modules all write inline opacity independently.
**How to avoid:** Define precedence (e.g., hidden > solo filter > brush/crosstalk selection > hover preview accent) and enforce one apply pipeline.
**Warning signs:** Brush active state randomly clears after legend hover.

### Pitfall 5: Identity mismatch between legend keys and marks
**What goes wrong:** Clicking one legend item affects wrong marks or only one panel.
**Why it happens:** Missing stable key mapping (aesthetic + level) across merged guides/facets.
**How to avoid:** Add explicit `data-aesthetic`, `data-level`, and shared key construction in legend + mark rendering.
**Warning signs:** Works for simple color legend; fails for merged color+shape legends.

## Code Examples

Verified patterns from official/current sources and repo:

### Namespaced D3 handlers for rebind safety
```typescript
// Source: https://d3js.org/d3-selection/events
selection
  .on("click.legend", onClick)
  .on("dblclick.legend", onDoubleClick)
  .on("mouseover.legend", onHoverIn)
  .on("mouseout.legend", onHoverOut);

// cleanup
selection.on(".legend", null);
```

### Dispatch-based semantic event routing
```typescript
// Source: https://d3js.org/d3-dispatch
const bus = d3.dispatch("legend:toggle", "legend:solo", "legend:reset", "legend:hoverin", "legend:hoverout");

bus.on("legend:toggle.apply", ({ key }) => {
  // mutate canonical state, then apply visuals
});
```

### Transition interruption for rapid toggles
```typescript
// Source: https://d3js.org/d3-transition/control-flow
marks.interrupt("legend");
marks.transition("legend").duration(150).style("opacity", targetOpacity);
```

### htmlwidgets interactivity configuration extension pattern
```r
# Source: existing d3_hover/d3_brush/d3_zoom patterns in R/
widget$x$interactivity$legend <- list(
  enabled = TRUE,
  double_click = "solo",
  hover_preview = TRUE
)

widget <- htmlwidgets::onRender(widget, "
  function(el, x) {
    setTimeout(function() {
      if (x.interactivity && x.interactivity.legend) {
        window.gg2d3.events.attachLegend(el, x.interactivity.legend, x.ir);
      }
    }, 0);
  }
")
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Static legend as annotation only | Legend as interaction controller (toggle/solo patterns) | Established across modern interactive plotting tools | Users expect legend to drive visibility directly |
| Direct DOM mutation per interaction source | Central interaction state + event bus | Modern D3 app architecture practice | Prevents semantic drift/race conditions |
| One opacity channel for all interactions | Layered state (persistent vs transient) | Needed as interactions compose (hover+filter+linked views) | Critical for LEG-04 correctness |

**Deprecated/outdated for this phase:**
- Treating continuous colorbars as equivalent to discrete clickable legends.
- Using unnamespaced event listeners in redraw-heavy widgets.

## Open Questions

1. **Reset-all UX for LEG-02**
   - What we know: Requirement explicitly includes reset-all behavior.
   - What's unclear: Trigger location (legend title click, external control, double-click empty area).
   - Recommendation: Decide explicit reset gesture in plan and test contract.

2. **Legend-state mapping into Crosstalk payload**
   - What we know: Current crosstalk module handles key-based selection only.
   - What's unclear: Whether legend visibility should publish as selection, filter, or local-only state.
   - Recommendation: Define one synchronization contract before implementation tasks.

3. **Merged-guide interaction identity**
   - What we know: IR merges guides sharing title; keys can include multiple aesthetics.
   - What's unclear: Exact key construction for robust matching across geoms/layers/panels.
   - Recommendation: Lock a deterministic key schema in Phase 13 plan early.

4. **Accessibility semantics for legend state**
   - What we know: Click event is device-independent; keyboard parity expected for controls.
   - What's unclear: Whether Phase 13 includes keyboard/ARIA acceptance criteria.
   - Recommendation: At minimum, track as explicit non-goal or add minimal a11y task.

## Sources

### Primary (HIGH confidence)
- Repository source code (current):
  - `inst/htmlwidgets/modules/legend.js` (discrete vs colorbar rendering)
  - `inst/htmlwidgets/modules/events.js` (hover/tooltip conventions)
  - `inst/htmlwidgets/modules/crosstalk.js` (linked-view selection plumbing)
  - `inst/htmlwidgets/modules/brush.js`, `zoom.js` (dblclick behavior, opacity/state interactions)
  - `R/as_d3_ir.R` (guide extraction, merged guides, legend/colorbar typing)
- D3 official docs:
  - https://d3js.org/d3-selection/events
  - https://d3js.org/d3-dispatch
  - https://d3js.org/d3-transition/control-flow
- ggplot2 official docs (guide semantics):
  - https://ggplot2.tidyverse.org/reference/guide_legend.html

### Secondary (MEDIUM confidence)
- Plotly figure reference and legend docs (interaction semantics benchmark):
  - https://plotly.com/javascript/reference/layout/#layout-legend-itemclick
  - https://plotly.com/javascript/legend/

### Tertiary (LOW confidence)
- None used for critical claims.

## Metadata

**Confidence breakdown:**
- Standard stack: **HIGH** — verified in repo + official D3/ggplot2 docs.
- Architecture: **MEDIUM-HIGH** — strongly supported by current module boundaries; some contract choices remain open.
- Pitfalls: **MEDIUM-HIGH** — validated by browser event ordering docs + observed current opacity/state overlap patterns.

**Research date:** 2026-03-23  
**Valid until:** 2026-04-22 (30 days; moderate ecosystem churn, but architecture assumptions should be revalidated after major module changes)
