# Roadmap: gg2d3

## Overview

This roadmap defines milestone **v1.1 Interactive Exploration** using only v1.1 active v1 requirements. The phase structure starts at **Phase 13** (continuing from v1.0 Phase 12) and groups work into coherent user-visible capabilities: interactive legend workflows, date/time parity behavior, and coord_flip correctness in faceted contexts.

Depth setting is **comprehensive**, so requirement categories are kept as separate delivery boundaries rather than compressed.

## Milestones

- ✅ **v1.0 MVP** — Phases 1-12 (shipped 2026-02-16)
- 🟡 **v1.1 Interactive Exploration** — Phases 13-15 (planned)

## Phases

### Phase 13 - Interactive Legend Controls

**Goal:** Analysts can control visibility and emphasis directly through discrete legends without losing interaction-state consistency.

**Dependencies:** Existing v1.0 legend rendering + linked-view state foundation.

**Requirements:** LEG-01, LEG-02, LEG-03, LEG-04

**Success Criteria (observable):**
1. User can click a discrete legend item to hide/show its corresponding series.
2. User can double-click a discrete legend item to solo that series and can reset to restore all series.
3. User sees legend-driven visibility state remain synchronized with linked-view interaction state.
4. User can hover a legend item to preview emphasis/de-emphasis without changing persistent filter state.

### Phase 14 - Date/Datetime Parity Behavior

**Goal:** Users see date and datetime axes behave like ggplot2 for breaks, labels, and timezone display semantics.

**Dependencies:** Phase 13 complete; existing scale/axis infrastructure from v1.0.

**Requirements:** DATE-01, DATE-02, DATE-03

**Success Criteria (observable):**
1. User sees date axes respect configured `date_breaks` values.
2. User sees date/datetime axis labels follow configured `date_labels` formatting.
3. User sees datetime display behavior apply timezone semantics consistently with ggplot2 expectations.

### Phase 15 - coord_flip Correctness Hardening

**Goal:** Users can rely on `coord_flip` to preserve correct axis-side and facet orientation behavior.

**Dependencies:** Phase 14 complete; existing facet + coord systems from v1.0.

**Requirements:** COORD-01, COORD-02

**Success Criteria (observable):**
1. User sees `coord_flip` place x/y axes on the correct sides after flipping.
2. User sees `coord_flip` maintain correct orientation behavior in faceted plots.

## Progress

| Phase | Milestone | Goal | Requirements | Status |
|-------|-----------|------|--------------|--------|
| 13. Interactive Legend Controls | v1.1 | Legend-based toggle/solo/hover workflows with synchronized state | LEG-01, LEG-02, LEG-03, LEG-04 | Planned |
| 14. Date/Datetime Parity Behavior | v1.1 | ggplot2-consistent date/datetime breaks, labels, timezone behavior | DATE-01, DATE-02, DATE-03 | Planned |
| 15. coord_flip Correctness Hardening | v1.1 | Correct flipped axis-side and faceted orientation behavior | COORD-01, COORD-02 | Planned |

---
*Roadmap updated: 2026-03-23*
*Milestone in planning: v1.1 Interactive Exploration*
*v1.1 phases: 3 (13-15)*
*v1.1 requirement coverage: 9/9 mapped*
