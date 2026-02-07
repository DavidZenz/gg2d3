# External Integrations

**Analysis Date:** 2026-02-07

## APIs & External Services

**Graphics/Visualization:**
- D3.js v7 - JavaScript visualization library
  - SDK/Client: Vendored in `inst/htmlwidgets/lib/d3/d3.v7.min.js`
  - Auth: None (open source)
  - Integration: Declaratively specified in `inst/htmlwidgets/gg2d3.yaml` dependencies

## Data Storage

**Databases:**
- None - Package is stateless; no persistent storage

**File Storage:**
- None - Widget renders in-browser

**Caching:**
- None detected

## Authentication & Identity

**Auth Provider:**
- None - Not applicable for visualization package

## Monitoring & Observability

**Error Tracking:**
- None

**Logs:**
- Console logging available in D3 rendering layer (`inst/htmlwidgets/gg2d3.js`) via browser console

## CI/CD & Deployment

**Hosting:**
- Not applicable - R package distributed via GitHub/CRAN

**CI Pipeline:**
- Not detected (commented-out badge in README suggests GitHub Actions workflow exists but not active)

**Package Distribution:**
- GitHub: `https://github.com/<you>/gg2d3` (placeholder in DESCRIPTION)
- Installation: `devtools::install_github("DavidZenz/gg2d3")`

## Environment Configuration

**Required env vars:**
- None

**Secrets location:**
- Not applicable

## Webhooks & Callbacks

**Incoming:**
- None

**Outgoing:**
- None

## R Ecosystem Integrations

**Tight coupling to:**
- ggplot2 objects as input (parses via `ggplot2::ggplot_build()`)
- htmlwidgets as rendering bridge (output via `htmlwidgets::createWidget()`)

**Integration Flow:**
1. User creates ggplot2 object in R
2. Pass to `gg2d3()` function in `R/gg2d3.R`
3. Internally calls `as_d3_ir()` in `R/as_d3_ir.R` to extract intermediate representation
4. htmlwidgets serializes IR to JSON and passes to browser
5. `inst/htmlwidgets/gg2d3.js` receives IR and renders with D3.js

## Browser Environment

**Client-side:**
- D3.js v7 provides DOM manipulation, scales, selections, axes
- No external API calls from D3 rendering code (fully client-side)
- SVG output only (no canvas, no WebGL)

---

*Integration audit: 2026-02-07*
