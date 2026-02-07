# Codebase Structure

**Analysis Date:** 2026-02-07

## Directory Layout

```
gg2d3/
├── R/                           # R source code
│   ├── gg2d3.R                  # Main widget entry point (20 lines)
│   └── as_d3_ir.R               # ggplot → IR converter (353 lines)
├── inst/
│   └── htmlwidgets/             # HTMLWidgets integration
│       ├── gg2d3.js             # D3 rendering engine (716 lines)
│       ├── gg2d3.yaml           # Widget configuration
│       └── lib/d3/              # D3.js library
│           └── d3.v7.min.js     # D3 v7 (vendored)
├── tests/
│   ├── testthat.R               # Test setup
│   └── testthat/
│       └── test-ir.R            # IR extraction tests (9 lines)
├── man/                         # Roxygen2 documentation (generated)
│   ├── gg2d3.Rd
│   └── as_d3_ir.Rd
├── vignettes/                   # Package vignettes
│   ├── gg2d3-intro.Rmd          # Getting started guide
│   └── d3-drawing-diagnostics.md # Known limitations & debugging
├── DESCRIPTION                  # Package metadata
├── NAMESPACE                    # Exports (gg2d3, as_d3_ir)
├── README.Rmd / README.md       # Package overview
└── _pkgdown.yml                 # Documentation site config
```

## Directory Purposes

**R/ - R Source Code:**
- Purpose: ggplot2 object extraction and IR construction
- Contains: Two main functions and internal helpers
- Key files: `gg2d3.R`, `as_d3_ir.R`
- No subdirectories (simple flat structure)

**inst/htmlwidgets/ - Widget Assets:**
- Purpose: HTMLWidgets binding and D3 rendering
- Contains: JavaScript rendering engine, widget configuration, D3 library
- Key files: `gg2d3.js` (main rendering), `gg2d3.yaml` (htmlwidgets config)
- D3 library vendored at `inst/htmlwidgets/lib/d3/d3.v7.min.js`

**tests/testthat/ - Test Suite:**
- Purpose: IR extraction and widget output verification
- Contains: Currently minimal tests (1 file, 9 test lines)
- Pattern: Single test file testing core IR functionality
- Run with: `devtools::test()` or `testthat::test_file("tests/testthat/test-ir.R")`

**man/ - Documentation:**
- Purpose: Roxygen2-generated function documentation
- Contains: Auto-generated .Rd files from `#'` comments in R source
- Regenerate with: `devtools::document()`
- Not edited directly (regenerated from source)

**vignettes/ - Package Vignettes:**
- Purpose: Long-form documentation, tutorials, known issues
- Key files:
  - `gg2d3-intro.Rmd`: Getting started (R + HTML examples)
  - `d3-drawing-diagnostics.md`: Known limitations (no legends, facets, etc.)

## Key File Locations

**Entry Points:**
- `R/gg2d3.R`: User-facing widget function, 20 lines
  - Accepts: ggplot object or pre-built IR list
  - Returns: htmlwidgets object for display
- `inst/htmlwidgets/gg2d3.js`: D3 rendering (lines 1-716)
  - Entry: `renderValue()` method receives IR
  - Main: `draw(ir, elW, elH)` constructs SVG

**Configuration:**
- `inst/htmlwidgets/gg2d3.yaml`: Widget metadata and D3 dependency declaration
- `DESCRIPTION`: Package dependencies (ggplot2, htmlwidgets, grid)
- `NAMESPACE`: Exports `gg2d3()` and `as_d3_ir()`

**Core Logic:**
- `R/as_d3_ir.R` (353 lines):
  - Lines 3-60: Helper functions (coercion, discrete mapping)
  - Lines 62-130: Theme element extraction (`extract_theme_element()`)
  - Lines 132-236: Layer processing loop (geom names, data marshalling)
  - Lines 238-269: Scale info extraction (`get_scale_info()`)
  - Lines 271-352: IR assembly and return
- `inst/htmlwidgets/gg2d3.js` (716 lines):
  - Lines 8-21: Utility functions (val, num, color checks)
  - Lines 40-175: Scale factory (`makeScale()`)
  - Lines 178-223: Color conversion and styling
  - Lines 225-399: Main draw function setup (theme, padding, backgrounds)
  - Lines 400-699: Geom rendering by type (point, line, bar, rect, text)
  - Lines 699-716: HTMLWidgets binding

**Testing:**
- `tests/testthat.R`: Test harness (minimal)
- `tests/testthat/test-ir.R`: Core IR tests, 9 lines

## Naming Conventions

**Files:**
- R functions: lowercase with underscores (`gg2d3.R`, `as_d3_ir.R`)
- Test files: `test-{name}.R` pattern (testthat convention)
- JavaScript: lowercase with underscores (`gg2d3.js`)
- Documentation: `.Rd` for R functions, `.Rmd` for vignettes, `.md` for guides

**Functions:**
- R: snake_case (`as_d3_ir`, `gg2d3`)
- Internal R helpers: lowercase (`extract_theme_element`, `get_scale_info`, `map_discrete`)
- JavaScript: camelCase (`makeScale`, `convertColor`, `isValidColor`, `applyAxisStyle`, `drawGrid`)

**Variables:**
- R: snake_case (`xscale_obj`, `b`, `ir`, `keep_aes`)
- JavaScript: camelCase (`isXBand`, `fillColor`, `linewidthVal`, `defaultTheme`)
- Constants: UPPERCASE in comments only (no formal constants)

**Types/Objects:**
- R IR components: snake_case objects (`ir$scales$x`, `ir$layers`, `ir$theme$panel$background`)
- JavaScript scale objects: camelCase (`xScale`, `yScale`, `colorScale`)

## Where to Add New Code

**New Feature:**
- Primary code: `R/as_d3_ir.R` for extraction logic, `inst/htmlwidgets/gg2d3.js` for rendering
  - Extraction: Add to layer processing loop (line 132-236) or theme extraction (line 62-130)
  - Rendering: Add to geom switch (line 398-699) or theme application section
- Tests: Add test case to `tests/testthat/test-ir.R` or create new file `test-{feature}.R`

**New Geom Support:**
- R side:
  - Add geom class → name mapping in switch statement (lines 158-184)
  - Keep geom name generic (e.g., "GeomBoxplot" → "boxplot")
  - Ensure aesthetics columns handled in `keep_aes` (line 187-191)
- D3 side:
  - Add condition in layer processing loop after line 398
  - Follow pattern: filter data, calculate positions, append SVG elements
  - Apply colors with `fillColor(d)`, `strokeColor(d)`
  - Apply opacity with `opa(d)`
  - Example: `else if (layer.geom === "boxplot") { ... }`

**New Theme Element:**
- R side:
  - Add `extract_theme_element()` call in theme IR assembly (lines 310-336)
  - Example: Add `"plot.tag" = extract_theme_element("plot.tag", b$plot$theme)`
- D3 side:
  - Add to default theme object (lines 232-254)
  - Add `getTheme()` call to retrieve element
  - Apply styling (lines 374-386 for title as example)

**Utilities/Helpers:**
- Shared helpers: Keep in respective files (R helpers in `R/as_d3_ir.R`, D3 helpers at top of `gg2d3.js`)
- Do NOT create new files for small functions—inline or add to existing files
- Internal helpers do not need export in NAMESPACE

## Special Directories

**inst/ (Installation Directory):**
- Purpose: Files installed with package (not for R code)
- Contents: htmlwidgets assets, D3 library
- Generated: No—handwritten assets
- Committed: Yes (D3 library is vendored locally)

**man/ (Documentation Directory):**
- Purpose: Roxygen2-generated function documentation
- Generated: Yes—from `#'` comments in R source
- Committed: Yes (standard practice)
- Regenerate: `devtools::document()`

**vignettes/ (Vignettes Directory):**
- Purpose: Long-form documentation built by `devtools::build_vignettes()`
- Committed: Rmd source files only (HTML generated during build)
- Update: Edit `.Rmd` files directly

**tests/testthat/ (Test Directory):**
- Purpose: Test files for testthat framework
- Pattern: `test-{module}.R`
- Run: `devtools::test()` or `testthat::test_file("path/to/test.R")`
- Coverage: Currently minimal (only IR basics tested)

---

*Structure analysis: 2026-02-07*
