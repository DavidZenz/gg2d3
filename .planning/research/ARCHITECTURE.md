# Architecture Research

**Domain:** gg2d3 v1.1 integration architecture (interactive legends, transitions, advanced coord/scale parity)
**Researched:** 2026-03-23
**Confidence:** HIGH

## Standard Architecture

### System Overview

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                    R Extraction + IR Assembly Layer                         │
├──────────────────────────────────────────────────────────────────────────────┤
│  as_d3_ir() orchestration                                                   │
│   ├─ scale/coord extract + panel metadata                                   │
│   ├─ layer rows + stable row keys                                           │
│   ├─ guide extraction via get_guide_data()                                  │
│   ├─ transition spec + interaction config pass-through                       │
│   └─ validate_ir() contract checks                                           │
├──────────────────────────────────────────────────────────────────────────────┤
│                          IR Contract Layer                                   │
├──────────────────────────────────────────────────────────────────────────────┤
│ ir = {                                                                       │
│   scales, panels, facets, coord, layers, guides, theme,                     │
│   interactivity, transitions, key_index                                      │
│ }                                                                            │
├──────────────────────────────────────────────────────────────────────────────┤
│                   D3 Rendering + Interaction Layer                           │
├──────────────────────────────────────────────────────────────────────────────┤
│  gg2d3.js orchestration                                                      │
│   ├─ layout.calculateLayout()                                                │
│   ├─ scales.createScale()                                                    │
│   ├─ geomRegistry.render(...) by panel                                       │
│   ├─ legend.renderLegends(...)                                               │
│   ├─ transitions.reconcileAndAnimate(...)    [NEW]                           │
│   └─ events/tooltip/zoom/brush/crosstalk attach                              │
└──────────────────────────────────────────────────────────────────────────────┘
```

### Component Responsibilities

| Component | Responsibility | Typical Implementation |
|-----------|----------------|------------------------|
| `R/as_d3_ir.R` | Canonical IR producer; owns R→IR mapping and defaults | Extend existing orchestration, avoid splitting again before v1.1 ships |
| `R/validate_ir.R` | Hard contract checks for new IR fields | Add validation for `layers[].key`, `transitions`, guide merge metadata |
| `inst/htmlwidgets/gg2d3.js` | Render orchestration and module sequencing | Keep as coordinator; delegate animation diffing to new transitions module |
| `modules/legend.js` | Legend sizing and drawing from guide IR | Extend to expose legend item identity + state classes for interaction |
| `modules/layout.js` | Spatial allocation for panel/legend/axes/strips | Reuse; add no new layout system for v1.1 |
| `modules/scales.js` | Scale construction + temporal formatting helpers | Extend transform parity and axis formatting consistency |
| `modules/transitions.js` **(NEW)** | Data join + enter/update/exit animation policy | Use `selection.data(data, key).join(...)` + d3-transition |
| `modules/coords.js` **(NEW optional shim)** | Coordinate transform helpers shared by geoms | Start as small helper for coord_transform-compatible mapping |

## Recommended Project Structure

```
R/
├── as_d3_ir.R                 # MODIFY: add transition+key metadata, advanced coord IR
├── validate_ir.R              # MODIFY: enforce new IR contract
├── d3_tooltip.R               # existing
├── d3_hover.R                 # existing
├── d3_zoom.R                  # existing
├── d3_brush.R                 # existing
└── d3_crosstalk.R             # MODIFY: key mapping compatibility for legend/selection sync

inst/htmlwidgets/
├── gg2d3.js                   # MODIFY: route through transition reconciler
├── gg2d3.yaml                 # MODIFY: register transitions.js (+coords.js if added)
└── modules/
    ├── scales.js              # MODIFY: advanced transform parity behavior
    ├── layout.js              # MINOR MODIFY: animation-safe layout outputs
    ├── legend.js              # MODIFY: interactive legend semantics
    ├── events.js              # MODIFY: legend-item events + namespaced handlers
    ├── zoom.js                # MINOR MODIFY: transition interrupt coordination
    ├── brush.js               # MINOR MODIFY: transition interrupt coordination
    ├── crosstalk.js           # MODIFY: stable key-indexed highlight path
    ├── transitions.js         # NEW: central enter/update/exit animation engine
    ├── coords.js              # NEW (recommended): coord transform helpers
    ├── geom-registry.js       # MODIFY: enforce geom render contract for keyed joins
    └── geoms/*.js             # MODIFY subset: return/update selections with stable keys
```

### Structure Rationale

- **Keep one orchestrator on each side** (`as_d3_ir.R`, `gg2d3.js`) and add focused modules; this minimizes regression risk in a mature-but-fragile pipeline.
- **Add transitions as a dedicated module** rather than sprinkling `.transition()` calls across geom files. This keeps timing policy, interrupt behavior, and keying in one place.
- **Treat advanced coord/scale parity as contract work first** (IR + scale helpers), then renderer work. Parity bugs come from inconsistent semantics, not missing drawing primitives.

## Architectural Patterns

### Pattern 1: Keyed Mark Identity as First-Class Contract

**What:** Every renderable row gets a stable key (`layers[].data[].key`) generated in R and preserved in JS.
**When to use:** Always for animated updates, interactive legend filtering, brush/zoom persistence, crosstalk syncing.
**Trade-offs:**
- Pro: Enables correct D3 join semantics and object constancy.
- Con: Slightly larger IR payload and stricter validation burden.

**Example:**
```javascript
// transitions.js (core idea)
const marks = g.selectAll("circle.geom-point")
  .data(rows, d => d.key);   // stable key from R

marks.join(
  enter => enter.append("circle").attr("opacity", 0),
  update => update,
  exit => exit.transition(t).attr("opacity", 0).remove()
);
```

### Pattern 2: Transition Reconciler Between Layout and Geom Render

**What:** A single reconciler computes `prevIR -> nextIR` intent and invokes geom-specific enter/update/exit animation paths.
**When to use:** Any update beyond initial draw (resizes, data changes, legend toggles, axis/scale changes).
**Trade-offs:**
- Pro: Consistent timing/easing/interrupt policy across all geoms.
- Con: Requires geom API standardization (some geoms currently imperative-only).

**Example:**
```javascript
// gg2d3.js
if (previousState && ir.transitions?.enabled) {
  window.gg2d3.transitions.reconcileAndAnimate({
    root, previousState, nextIR: ir, layout, registry: window.gg2d3.geomRegistry
  });
} else {
  drawStatic(ir, layout);
}
```

### Pattern 3: Guides as Interaction Controllers (Not Decoration)

**What:** Legend entries emit semantic events (`legend:toggle`, `legend:hover`) keyed by aesthetic/value and drive mark state updates.
**When to use:** Interactive legends in v1.1.
**Trade-offs:**
- Pro: Unified interaction semantics across point/bar/line/etc.
- Con: Requires legend items and marks to share identity space (aesthetic + key/value mapping).

### Pattern 4: Coord/Scale Parity via Canonical Mapping Functions

**What:** Central helpers map data-space → panel-space for transformed coords and scales; geoms call helpers rather than ad hoc math.
**When to use:** coord_transform parity and any non-identity transform.
**Trade-offs:**
- Pro: Prevents per-geom divergence and flip/transform edge-case drift.
- Con: Requires careful testing for each coord/scale combination.

## Data Flow

### Request Flow

```
ggplot object
   ↓
as_d3_ir()
   ├─ ggplot_build()
   ├─ extract scales/panels/guides/coord
   ├─ assign stable row keys
   ├─ assemble transitions + interactivity config
   └─ validate_ir()
   ↓
htmlwidgets JSON payload
   ↓
gg2d3.js renderValue(x)
   ├─ layout.calculateLayout(...)
   ├─ scales.createScale(...)
   ├─ if first render → static draw path
   └─ else → transitions.reconcileAndAnimate(prev,next)
         ├─ keyed join per geom
         ├─ axis/grid/legend transition pass
         └─ interaction rebind/refresh
```

### State Management

```
Widget instance state
  ├─ previousIR                (for diff/animation)
  ├─ rendered mark index       (key → node refs, optional)
  ├─ active interaction state  (legend filters, brush ranges, zoom transform)
  └─ transition locks/interrupt flags
```

### Key Data Flows

1. **Legend → Mark state flow:** `guides[key/value]` → legend event → mark filter/highlight → optional transition.
2. **Scale/coord update flow:** IR transform/domain change → recompute scales → transition reconciler updates marks + axes.
3. **Interaction persistence flow:** brush/zoom/hover state carried across redraw via key-index and interrupted/replayed transitions.

## Integration Points

### External Services

| Service | Integration Pattern | Notes |
|---------|---------------------|-------|
| ggplot2 `get_guide_data()` | R-side guide extraction contract | Official API supports merged guides and panel-specific extraction (HIGH confidence) |
| ggplot2 `coord_transform()` semantics | R-side coord metadata + JS mapping consistency | Must preserve “coord transform occurs after stat” behavior (HIGH confidence) |
| D3 selection join | Keyed `selection.data(..., key).join(...)` in transitions module | Canonical pattern for object constancy and animated enter/update/exit (HIGH confidence) |
| D3 transition | Centralized transition orchestration (`d3-transition`) | Must not use transition for element creation/data binding steps (HIGH confidence) |

### Internal Boundaries

| Boundary | Communication | Notes |
|----------|---------------|-------|
| `as_d3_ir.R` ↔ `validate_ir.R` | Full IR object | Validation becomes release gate for new fields |
| `gg2d3.js` ↔ `transitions.js` | `previousState`, `nextIR`, `layout`, registry hooks | Keep orchestration thin in gg2d3.js |
| `legend.js` ↔ `events.js` | DOM classes + custom events | Legend interaction should not directly mutate geoms |
| `scales.js`/`coords.js` ↔ geoms | Pure mapping functions | Geoms stop embedding transform-specific math |
| `brush.js`/`zoom.js` ↔ `transitions.js` | interrupt + state handoff hooks | Avoid fighting transitions during active gestures |

## New vs Modified Components (Explicit)

### New Components

1. **`inst/htmlwidgets/modules/transitions.js`**
   - Owns diff classification (enter/update/exit, scale-only change, layout-only change).
   - Owns timing/easing defaults and interrupt policy.
   - Owns keyed join wrappers used by geom modules.

2. **`inst/htmlwidgets/modules/coords.js`** *(recommended, can start minimal)*
   - Encapsulates coord mapping helpers for transformed coordinates.
   - Shared by geoms to reduce duplication and parity drift.

### Modified Components

1. **`R/as_d3_ir.R` (major)**
   - Add stable mark keys and transition config block.
   - Emit richer coord metadata for parity (transform names/options).
   - Preserve guide merge metadata explicitly.

2. **`R/validate_ir.R` (major)**
   - Enforce key uniqueness per layer/panel.
   - Validate transitions schema and supported coord transform descriptors.

3. **`inst/htmlwidgets/gg2d3.js` (major)**
   - Maintain previous render state.
   - Route updates through transition reconciler.

4. **`modules/legend.js` + `modules/events.js` (major)**
   - Add interactive legend event emission and handling.
   - Standardize legend item classes/data attrs (`data-aesthetic`, `data-level`).

5. **`modules/scales.js` (major)**
   - Ensure advanced transform parity and unified formatting for static + zoomed axes.

6. **`modules/zoom.js`, `modules/brush.js`, `modules/crosstalk.js` (medium)**
   - Integrate with transition interrupt/state handoff.
   - Use stable key-index for reliable selection/highlight persistence.

7. **`modules/geoms/*.js` + `geom-registry.js` (medium-major)**
   - Conform to keyed join/update contract (at least for geoms targeted in v1.1).

## Build Order (Dependency + Risk Driven)

1. **IR Contract Upgrade (R first)**
   - Add stable keys, transition block, coord metadata, and validator rules.
   - Why first: every downstream feature depends on identity and contract correctness.

2. **Transition Infrastructure (JS core)**
   - Add `transitions.js`, wire `gg2d3.js` stateful render path, no feature toggles yet.
   - Why second: provides safe primitive used by legends and coord/scale updates.

3. **Geom Contract Migration (targeted set)**
   - Upgrade high-usage geoms (point, line, bar, rect, text) to keyed join paths.
   - Why third: proves end-to-end animation architecture before broad rollout.

4. **Interactive Legends Integration**
   - Extend `legend.js` + `events.js`; link legend state to keyed mark updates.
   - Why fourth: now identity + transition primitives exist, avoiding ad hoc toggles.

5. **Advanced Scale/Coord Parity Integration**
   - Centralize mapping in `scales.js`/`coords.js`; apply across migrated geoms.
   - Why fifth: parity changes are easier/safer once render/update mechanics are stable.

6. **Interactivity Reconciliation Pass (zoom/brush/crosstalk)**
   - Add interrupt/persistence hooks so gestures and transitions coexist.
   - Why last: polishing integration risk after core behavior is deterministic.

### Ordering Rationale

- **Identity before animation**, **animation before interaction controls**, **controls before parity edge-cases**.
- This sequence minimizes rewrite churn: each phase builds on stable primitives from the prior phase.

## Scaling Considerations

| Scale | Architecture Adjustments |
|-------|--------------------------|
| 0–1k marks | Full SVG transitions acceptable; keep defaults simple |
| 1k–20k marks | Disable/shorten transitions by default for heavy geoms; animate axes/legend only |
| 20k+ marks | Keep keyed joins but switch to selective/no mark transitions, preserve interaction correctness |

### Scaling Priorities

1. **First bottleneck:** transition cost on large mark counts; mitigate with per-geom animation policies.
2. **Second bottleneck:** interaction-vs-transition conflicts; mitigate with explicit interrupt/state handoff API.

## Anti-Patterns

### Anti-Pattern 1: Per-Geom Ad Hoc Animation Logic

**What people do:** Add `.transition()` directly in each geom renderer without shared policy.
**Why it's wrong:** Inconsistent timing, hard-to-reason interrupts, brittle behavior under zoom/brush.
**Do this instead:** Central transition reconciler + small geom hooks.

### Anti-Pattern 2: Legend State by CSS-Only Filtering

**What people do:** Toggle `.hidden` classes on DOM nodes without key/index model.
**Why it's wrong:** Breaks on redraw/resize/facets and cannot sync with crosstalk/brush.
**Do this instead:** Keyed state model in widget instance; render from state each update.

### Anti-Pattern 3: Declaring Coord Parity Without Contract Tests

**What people do:** Add partial transform math in JS and call feature “supported”.
**Why it's wrong:** Silent mismatch vs ggplot semantics, especially stat/coord ordering.
**Do this instead:** Encode coord semantics in IR + validator + golden tests per coord/geom pair.

## Sources

- D3 transition API (v7.9.0 docs): https://d3js.org/d3-transition
- D3 data join / `selection.join` (official docs): https://d3js.org/d3-selection/joining
- ggplot2 `get_guide_data()` reference (v4.0.2): https://ggplot2.tidyverse.org/reference/get_guide_data.html
- ggplot2 `coord_transform()` reference (v4.0.2): https://ggplot2.tidyverse.org/reference/coord_transform.html
- Codebase evidence (current architecture):
  - `R/as_d3_ir.R`
  - `R/validate_ir.R`
  - `inst/htmlwidgets/gg2d3.js`
  - `inst/htmlwidgets/modules/{layout.js,legend.js,scales.js,events.js,zoom.js,brush.js,crosstalk.js}`

---
*Architecture research for: gg2d3 v1.1 integration architecture*
*Researched: 2026-03-23*
