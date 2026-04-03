# Phase 19 Research: Custom Interactivity Handlers

## Objective
Enable users to define custom JavaScript event handlers for mark interactions (clicks, hovers) and synchronize plot state with Shiny inputs.

## Current State Analysis

### 1. Event Dispatching
- **Status:** `events.js` handles tooltips, hover effects, and legend interactions using namespaced D3 events (e.g., `mouseover.tooltip`).
- **Limitation:** There is no mechanism for users to inject their own logic without modifying the package source.

### 2. Shiny Integration
- **Status:** Basic widget rendering works in Shiny.
- **Limitation:** Interactive actions (clicking a point, selecting a legend item) do not yet notify the Shiny server of the change.

### 3. JS Function Passing
- **Status:** `d3_tooltip()` supports a `formatter` JS function string.
- **Requirement:** Need a more general R API to pass multiple handlers for different event types.

## Technical Proposals

### R API: `d3_handlers()`
Create a new pipe-able function to register handlers:
```r
gg2d3(p) |>
  d3_handlers(
    click = "function(event, d) { console.log(d); }",
    hover = "function(event, d) { ... }",
    shiny_id = "my_plot_interaction"
  )
```

### Hierarchical Event Binding
Update `events.js` with `attachHandlers(el, config)`:
1. Iterate over `INTERACTIVE_SELECTORS`.
2. Bind user JS strings using `new Function('event', 'd', config.handler)`.
3. If `shiny_id` is provided, automatically emit `Shiny.setInputValue(shiny_id, d)` on click.

### Legend-to-Shiny Sync
Automatically notify Shiny when legend state changes (toggle/solo/reset) if a `shiny_id` is present.

## Proposed Plan (19-01-PLAN.md)
1. Add R-side `d3_handlers()` function to `R/d3_handlers.R`.
2. Update `events.js` to support custom JS function execution for marks.
3. Implement automatic Shiny input synchronization for clicks and legend changes.
4. Add regression tests for handler registration and IR propagation.
5. Create a visual verification artifact (Shiny app mock) to verify event bubbling.

---
*Research completed: 2026-03-31*
