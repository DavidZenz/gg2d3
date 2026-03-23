# Feature Research

**Domain:** Interactive analytical plotting for R analysts (gg2d3 v1.1 milestone)
**Researched:** 2026-03-23
**Confidence:** HIGH

## Feature Landscape

### Table Stakes (Users Expect These)

Features users assume exist in an interactive ggplot-like workflow. Missing these = "looks interactive, but not analyst-usable".

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| **Legend click-to-toggle series visibility** | Analysts routinely isolate one category, then restore context | MEDIUM | Must support single click hide/show without recalculating scales unless explicitly requested. Expected behavior from Plotly and web charts. |
| **Legend state reflected in plot + linked views** | In analyst workflows, legend is a filter control, not decoration | HIGH | Existing linked-view plumbing is a dependency; legend events should emit the same filter state model as brush/click interactions. |
| **Continuous legends stay non-clickable (colorbar semantics)** | Users expect colorbars to explain numeric mapping, not toggle arbitrary bins | LOW | Match ggplot2 guide split: discrete uses `guide_legend`, continuous uses `guide_colourbar`. |
| **Object-constant transitions on filter/legend changes** | Smooth updates help users track what changed | HIGH | Use stable keys per mark. Enter/update/exit with short defaults (150–300ms). Avoid re-sorting during transition. |
| **Animated axis updates when scale domain changes** | Analysts zoom/filter and expect axis + marks to move together | HIGH | Axis and marks must share one transition clock; otherwise chart appears broken. |
| **Respect reduced-motion preference** | Accessibility and enterprise expectations | MEDIUM | If `prefers-reduced-motion` is set, switch transitions to near-instant while preserving end state. |
| **Correct scale limit semantics (`scale_*` drops data, `coord_*` zooms view)** | Core ggplot2 mental model for reproducibility | HIGH | Must preserve behavior documented by ggplot2: scale limits can censor data; coordinate limits should zoom visual window. |
| **Parity for common advanced scale controls (breaks, minor breaks, labels, expand, oob)** | Analysts heavily customize ticks/labels for publication and QA | MEDIUM-HIGH | Existing scale types are present; v1.1 parity is behavior fidelity and edge-case correctness. |
| **Date/datetime axis formatting parity (`date_breaks`, `date_labels`, timezone display)** | Time-series is central in analyst work | MEDIUM | Must handle Date vs POSIXct semantics and timezone display predictably. |
| **Reliable `coord_flip` / orientation behavior** | Horizontal bars/boxplots are standard analyst plots | MEDIUM | ggplot2 now prefers orientation swap, but `coord_flip` still needed for geoms/stats without orientation support. |

### Differentiators (Competitive Advantage)

Features that create real analyst productivity advantage beyond baseline parity.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| **Legend hover highlights (without committing filter)** | Fast visual scan before filtering; reduces click churn | MEDIUM | Hover = temporary emphasis/de-emphasis; click = persistent toggle. Important distinction for analyst speed. |
| **Legend group controls (solo, multi-select, reset)** | Common analysis pattern: compare 1 vs all, then a few vs few | MEDIUM-HIGH | Suggested UX: click toggle, double-click solo, modifier-click multi-select, explicit reset affordance. |
| **Transition presets by interaction type** | Better defaults: filter transitions should differ from zoom transitions | MEDIUM | Opinionated presets (e.g., filter=200ms fade, zoom=250ms transform) outperform one-size-fits-all animation settings. |
| **Semantic transition API in R (`transition = "none"|"fast"|"smooth"`)** | Analysts want simple controls, not D3 internals | LOW-MEDIUM | Keep advanced hook in JS, but expose minimal stable presets in R. |
| **Guide-level synchronization across facets/panels** | Multi-panel consistency improves interpretation confidence | HIGH | When one legend item is hidden, all relevant panels update coherently with preserved panel scales/options. |

### Anti-Features (Commonly Requested, Often Problematic)

Features that sound powerful but typically harm analyst workflows, maintainability, or correctness.

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| **Auto-play animations by default** | Looks impressive in demos | Hurts analytical reading, obscures exact values, adds motion noise | Default to static + user-triggered transitions on interaction only |
| **Dozens of easing curves exposed in R API** | Perceived flexibility | Bloated API; inconsistent charts across teams; support burden | Offer 2–3 presets (`linear`, `ease`, `none`) with sensible defaults |
| **Legend as full query builder (search, regex, hierarchy) in v1.1** | Users ask for BI-like controls | Scope explosion; duplicates linked-filter UI concerns | Keep legends for visibility/filter toggles only; do advanced filtering in linked-controls layer |
| **Attempting full `coord_transform()` + arbitrary custom transform parity now** | "Parity" pressure | High correctness risk (post-stat transform behavior is subtle) and hard-to-debug outputs | Support common transforms in scales first; defer arbitrary coord transforms to later research phase |
| **Clickable colorbar bin toggling for continuous scales** | Appears interactive | Semantically misleading; continuous encodings are not categories | Keep colorbar informative; provide brush/range filter UI separately |
| **Animating every redraw (including resize/theme changes)** | "Feels alive" | Performance cost and visual fatigue | Animate only state changes meaningful to analysis (filter, zoom, domain change) |

## Feature Dependencies

```
Interactive Legend Toggling
    └──requires──> Stable mark identity keys
    └──requires──> Legend event model (click, dblclick, modifier)
    └──requires──> Shared filter state with linked views

Meaningful Transitions
    └──requires──> D3 enter/update/exit join discipline
    └──requires──> Transition scheduler (axis + marks synchronized)
    └──requires──> Reduced-motion compliance branch

Advanced Scale Parity
    └──requires──> Tick/break generator parity with scale type
    └──requires──> Label formatter parity (numeric + date/time)
    └──requires──> Correct oob/expand/limits semantics

Advanced Coord Parity
    └──requires──> Axis-side/orientation mapping correctness
    └──requires──> Facet-aware coordinate application
    └──enhances──> Legend and transition coherence

Legend Hover Highlight
    └──enhances──> Interactive legend toggling
    └──conflicts──> Aggressive tooltip handlers (event priority issues)
```

### Dependency Notes

- **Legend interactivity depends on stable identity keys:** without key functions, toggles trigger full rebinds and destroy object constancy.
- **Transitions depend on synchronized axes:** marks moving without axis transition is perceived as a bug.
- **Scale parity is mostly correctness work, not new primitives:** since major scale types already exist, v1.1 risk is edge-case mismatch.
- **Coord parity interacts with facets and guides:** coordinate bugs are amplified in faceted views and can invalidate legend interpretation.
- **Hover highlight must not steal click semantics:** pointer-event ordering must be explicit to avoid flaky toggles.

## MVP Definition

### Launch With (v1.1 scope)

Minimum viable set for this milestone’s interactive exploration goals.

- [ ] **Discrete legend click toggle (show/hide) with persisted state** — baseline analyst workflow
- [ ] **Legend solo mode (double-click) + reset** — common comparison pattern
- [ ] **Legend interactions synchronized with linked views** — avoids fragmented interaction model
- [ ] **Default transitions for data/legend/filter updates (fast + stable)** — preserves mental model
- [ ] **Axis + mark transition sync when domains change** — prevents confusing movement
- [ ] **Reduced-motion support** — accessibility and enterprise readiness
- [ ] **Scale behavior parity hardening:** breaks/minor breaks/labels/expand/oob/limits semantics
- [ ] **Date/datetime label + break fidelity (including timezone display behavior)**
- [ ] **`coord_flip` correctness in axis side mapping and faceted contexts**

### Add After Validation (v1.1.x)

Features to add after baseline behavior is trusted by users.

- [ ] **Legend hover pre-highlight** — add once click behavior is stable
- [ ] **R-side transition presets API (`none/fast/smooth`)** — after default transition telemetry/feedback
- [ ] **Optional animated zoom programmatic controls** — only once domain/axis sync is robust
- [ ] **Guide styling transitions (legend reorder, gentle fades)** — polish, not core behavior

### Future Consideration (v1.2+)

Defer until core parity + interaction stability are proven.

- [ ] **Broader coordinate family parity (`coord_fixed`, selective `coord_transform`)** — requires targeted feasibility study
- [ ] **Advanced legend UX (search/group trees)** — only with clear user demand and design validation
- [ ] **High-dimensional animated storytelling modes** — presentation-oriented, low analyst ROI

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Discrete legend click toggle | HIGH | MEDIUM | P1 |
| Legend solo + reset | HIGH | MEDIUM | P1 |
| Legend ↔ linked-view state sync | HIGH | HIGH | P1 |
| Stable enter/update/exit transitions | HIGH | HIGH | P1 |
| Axis-mark synchronized transitions | HIGH | HIGH | P1 |
| Reduced-motion compliance | MEDIUM-HIGH | MEDIUM | P1 |
| Scale parity hardening (breaks/labels/oob/limits) | HIGH | MEDIUM-HIGH | P1 |
| Date/datetime formatting parity | HIGH | MEDIUM | P1 |
| `coord_flip` correctness hardening | MEDIUM-HIGH | MEDIUM | P1 |
| Legend hover highlight | MEDIUM-HIGH | MEDIUM | P2 |
| R transition preset API | MEDIUM | LOW-MEDIUM | P2 |
| Animated zoom programmatic controls | MEDIUM | MEDIUM-HIGH | P2 |
| Advanced legend search/hierarchy | LOW-MEDIUM | HIGH | P3 |
| Arbitrary coord transforms parity | LOW-MEDIUM | HIGH | P3 |

**Priority key:**
- P1: Must have for v1.1 milestone success
- P2: Strong follow-up after baseline stability
- P3: Defer unless explicit demand appears

## Competitor Feature Analysis

| Workflow Behavior | ggplot2 | Plotly (R) | Typical D3 custom apps | gg2d3 v1.1 recommendation |
|-------------------|---------|------------|-------------------------|----------------------------|
| Legend toggles visibility | Static legends only | Standard interactive toggle behavior | Common, custom | **Adopt Plotly-like baseline toggle semantics** |
| Continuous color guide behavior | Informational colourbar | Informational; not category toggle | Usually informational | **Keep non-toggle colorbar semantics** |
| Transition model | Mostly static render | Built-in animated frames/transitions | Flexible but manual | **Use constrained, analyst-first transitions** |
| Axis/domain interaction | Strong semantic rules | Interactive axis updates | Depends on implementation | **Preserve ggplot2 semantics + interactive updates** |
| Coord nuance (`coord_flip` etc.) | Well-defined semantics | Variable via conversion | Manual correctness burden | **Prioritize correctness over breadth** |

## Sources

### High Confidence (Official docs)
- ggplot2 `guide_legend` (v4.0.2): https://ggplot2.tidyverse.org/reference/guide_legend.html
- ggplot2 `guide_colourbar` (v4.0.2): https://ggplot2.tidyverse.org/reference/guide_colourbar.html
- ggplot2 continuous scales semantics (v4.0.2): https://ggplot2.tidyverse.org/reference/scale_continuous.html
- ggplot2 date/datetime scales semantics (v4.0.2): https://ggplot2.tidyverse.org/reference/scale_date.html
- ggplot2 coord transform semantics (v4.0.2): https://ggplot2.tidyverse.org/reference/coord_transform.html
- ggplot2 `coord_flip` behavior notes (v4.0.2): https://ggplot2.tidyverse.org/reference/coord_flip.html
- D3 transitions (v7.9.0 docs): https://d3js.org/d3-transition
- D3 zoom behavior (v7.9.0 docs): https://d3js.org/d3-zoom

### Medium Confidence (Ecosystem expectations)
- Plotly R legends (interactive behavior patterns): https://plotly.com/r/legend/
- Plotly R animations (interaction/frame patterns): https://plotly.com/r/animations/
  - Note: Plotly indicates retirement of some non-Python docs; behavior references remain useful but should not be sole authority.

---
*Feature research for: gg2d3 v1.1 Interactive Exploration*
*Researched: 2026-03-23*
*Confidence: HIGH overall (ggplot2 + D3 docs), MEDIUM for competitive behavior expectations*
