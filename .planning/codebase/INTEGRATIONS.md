# External Integrations

**Analysis Date:** 2026-03-11

## APIs & External Services

**None detected** - gg2d3 does not integrate with external REST APIs or cloud services.

## Data Storage

**Databases:**
- None - gg2d3 is a pure visualization library; no database integration

**File Storage:**
- None - No persistent file storage or cloud storage integration

**Caching:**
- None - All rendering is stateless per widget instance

## Authentication & Identity

**Auth Provider:**
- None - No authentication required. gg2d3 is a client-side visualization library.

## Monitoring & Observability

**Error Tracking:**
- None configured

**Logs:**
- Browser console via `console.log()` (visible in browser dev tools)
- R console warnings via `warning()` function (e.g., coord_trans not supported warning in `R/as_d3_ir.R`)

## CI/CD & Deployment

**Hosting:**
- Not applicable - gg2d3 is an R package for local/RStudio use
- Visualizations are rendered in-browser via htmlwidgets
- Package distributed via CRAN or GitHub

**CI Pipeline:**
- None configured - No GitHub Actions or CI workflow files present
- Package testing runs locally via `devtools::test()` and testthat

## Environment Configuration

**Required env vars:**
- None - gg2d3 requires no environment variables

**Secrets location:**
- Not applicable - No secrets used

## Widget Communication

**Incoming (from JavaScript to R/Shiny):**
- Crosstalk selection messages (if SharedData detected)
  - Module: `inst/htmlwidgets/modules/crosstalk.js`
  - Sends selection via Crosstalk SelectionHandle to other widgets
  - Shiny event handlers defined in `R/d3_brush.R`, `R/d3_hover.R`

**Outgoing (from R to JavaScript):**
- IR JSON object passed to htmlwidgets JavaScript factory
  - Location: `R/gg2d3.R` creates widget with IR data
  - Serialization: htmlwidgets automatically converts R list to JSON
  - Payload includes: scales, layers, theme, coord, optional crosstalk metadata

## Browser APIs Used

**D3.js v7:**
- D3 scales (d3.scaleLinear, d3.scaleOrdinal, d3.scaleSequential, d3.scaleTime)
- D3 selections and data binding
- D3 zoom (d3.zoom)
- D3 brush (d3.brush)
- D3 color schemes (d3.schemeTableau10, d3.interpolateTurbo)
- SVG manipulation via D3

**Web Standards:**
- SVG (Scalable Vector Graphics) for rendering
- W3C CSS units and color parsing
- JavaScript ES6 modules (IIFE pattern used)
- HTML5 data attributes for interactive state

## Crosstalk Integration Details

**Package:**
- Optional dependency: `crosstalk` (Suggested in DESCRIPTION)

**When Active:**
- User creates ggplot with crosstalk::SharedData instead of data.frame
- `R/gg2d3.R` detects SharedData via `crosstalk::is.SharedData()`
- Extracts crosstalk_key and crosstalk_group
- Passes metadata to JavaScript via widget data

**JavaScript Side:**
- `inst/htmlwidgets/modules/crosstalk.js` initializes SelectionHandle
- Listens for selection changes from other Crosstalk widgets
- Broadcasts selections from gg2d3 back to Crosstalk group
- Interactive elements: circles, bars, paths, text elements

**Compatible With:**
- Shiny reactive input/output
- DT (data table) widget brushing
- plotly (via Crosstalk)
- leaflet (map brushing)

## Data Format

**Input:**
- R ggplot2 objects (from ggplot2::ggplot)
- or IR list (output from `as_d3_ir()`)

**Output:**
- HTML widget (RStudio viewer / browser)
- SVG visualization (exportable from browser)

**Intermediate Representation (IR):**
- JSON-serializable list with structure:
  - `scales` - x, y, color scale descriptions
  - `layers` - Array of geom layers with data and aesthetics
  - `theme` - Extracted ggplot2 theme elements
  - `coord` - Coordinate system info (e.g., flip status)
  - `facet_info` (optional) - Faceting structure if present

---

*Integration audit: 2026-03-11*
