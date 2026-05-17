# Changelog

## gg2d3 (development version)

### gg2d3 0.6.0 (2026-03-31)

- **Specialized Geoms**: Added support for `geom_dotplot`, `geom_rug`,
  `geom_errorbar`, `geom_linerange`, and `geom_pointrange`.
- **API Polish**: Standardized interactivity attachment and optimized
  rendering performance for state updates.

### gg2d3 0.5.0 (2026-03-31)

- **Non-Cartesian Systems**: Full support for `coord_polar`, including
  specialized radial/circular axes and pie/coxcomb charts.
- **Advanced Stats**: High-fidelity rendering for `geom_density` and
  complex `geom_smooth` (loess, gam).

### gg2d3 0.4.0 (2026-03-31)

- **Theme Parity**: Implemented deep theme inheritance and support for
  complex element styling (margins, justifications, rotation).
- **Reference Geoms**: Added `geom_hline`, `geom_vline`, and
  `geom_abline` with robust clipping.

### gg2d3 0.3.0 (2026-03-31)

- **Advanced Facets**: Support for hierarchical facet headers and
  multiple nesting variables.
- **Custom Interactivity**: New R API `d3_handlers` for injecting custom
  JS logic and Shiny synchronization.

### gg2d3 0.2.0 (2026-03-31)

- **Smooth Transitions**: Object-constant enter/update/exit animations
  for marks and axes.
- **Scale Parity**: Enhanced support for custom breaks, minor breaks,
  expansion, and OOB logic.

### gg2d3 0.1.0 (2026-02-16)

- **MVP Release**: Core support for 15 basic geoms, faceting, and
  pipe-based interactivity API (tooltip, zoom, brush, crosstalk).
