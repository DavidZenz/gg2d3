# Requirements: gg2d3

**Defined:** 2026-03-23
**Milestone:** v1.1 Interactive Exploration
**Core Value:** Any ggplot2 plot should render identically in D3 - same visual output, but now interactive and web-native.

## v1 Requirements

Requirements committed for milestone v1.1.

### Interactive Legends

- [ ] **LEG-01**: User can click a discrete legend item to toggle that series visibility on/off.
- [ ] **LEG-02**: User can double-click a discrete legend item to solo that series and use reset to restore all series.
- [ ] **LEG-03**: User sees legend-driven visibility state stay synchronized with linked-view interaction state.
- [ ] **LEG-04**: User can hover a legend item to preview emphasis/de-emphasis without changing persistent filter state.

### Date/Time Parity

- [ ] **DATE-01**: User sees date axes honor configured `date_breaks` values.
- [ ] **DATE-02**: User sees date/datetime labels honor configured `date_labels` formatting.
- [ ] **DATE-03**: User sees datetime displays apply timezone behavior consistently with ggplot2 expectations.

### coord_flip Hardening

- [ ] **COORD-01**: User sees `coord_flip` place x/y axes on correct sides after flipping.
- [ ] **COORD-02**: User sees `coord_flip` preserve correct orientation behavior in faceted plots.

## v2 Requirements

Deferred from v1.1 scope.

### Transitions

- **TRAN-01**: User sees object-constant enter/update/exit transitions during interactive state changes.
- **TRAN-02**: User sees marks and axes transition on a synchronized timeline when domains change.
- **TRAN-03**: User can use gg2d3 with reduced-motion preference and receive low-motion updates.
- **TRAN-04**: User can configure simple transition presets from R (`none`, `fast`, `smooth`).

### Scale Parity

- **SCALE-01**: User sees continuous/discrete scales honor configured `breaks` and `minor_breaks` semantics.
- **SCALE-02**: User sees axis labels honor configured formatter semantics across supported scale types.
- **SCALE-03**: User sees `expand`, `oob`, and limits behavior match ggplot2 semantics.

## Out of Scope

Explicit exclusions for v1.1.

| Feature | Reason |
|---------|--------|
| Broad `coord_transform` parity expansion | High complexity and correctness risk relative to v1.1 goals |
| Advanced legend query UX (search/hierarchy) | Scope expansion beyond analyst-core legend interactions |
| Auto-play storytelling animations | Presentation-focused behavior, low value for analyst exploration baseline |

## Traceability

Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| LEG-01 | TBD | Pending |
| LEG-02 | TBD | Pending |
| LEG-03 | TBD | Pending |
| LEG-04 | TBD | Pending |
| DATE-01 | TBD | Pending |
| DATE-02 | TBD | Pending |
| DATE-03 | TBD | Pending |
| COORD-01 | TBD | Pending |
| COORD-02 | TBD | Pending |

**Coverage:**
- v1 requirements: 9 total
- Mapped to phases: 0
- Unmapped: 9 ⚠

---
*Requirements defined: 2026-03-23*
*Last updated: 2026-03-23 after milestone v1.1 requirement scoping*
