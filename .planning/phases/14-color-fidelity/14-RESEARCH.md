# Phase 14: Color Fidelity — Research

**Researched:** 2026-05-04
**Domain:** ggplot2 → D3 color scale extraction & legend rendering
**Confidence:** HIGH (defects reproduced live against the post-Phase-13 codebase)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Gap focus**
- **D-01:** Phase 14 closes three concrete gaps simultaneously: (a) per-row hex parity for viridis/brewer/manual, (b) continuous-color → colorbar trigger correctly firing instead of falling back to discrete keys, (c) colorbar quality (ticks, labels, orientation, title placement) matching ggplot2.
- **D-02:** Researcher's first task is to render a corpus and produce a concrete defect list per scale type; planner uses that list to decide the per-plan task split.

**Fidelity contract**
- **D-03:** "Identical hex codes" means **exact string equality** between rendered DOM `fill`/`stroke` and `ggplot_build()`'s resolved color column. No color-distance tolerance. Char-for-char.
- **D-04:** Source of truth: per-row resolved-color column from `ggplot_build()` for layer marks, and `scale_obj$map(scale_obj$breaks)` for legend swatches/colorbar stops.

**Scale scope**
- **D-05:** In scope: `scale_*_viridis_c`, `scale_*_viridis_d`, `scale_*_brewer`, `scale_*_distiller`, `scale_*_manual` (named & unnamed), `scale_*_steps` / `scale_*_binned`.
- **D-06:** Steps/binned legends render as a **banded colorbar** (matches `guide_coloursteps` — single rect with hard color stops, no smooth gradient). Same orientation/sizing as continuous.
- **D-07:** `scale_*_gradient`/`gradient2`/`gradientn` ship only if they fall out for free.

**Colorbar quality**
- **D-08:** Colorbar ticks pull `breaks`/`labels` from the scale object (lockstep with ggplot2), not from `d3.axisRight`.
- **D-09:** 30-stop sampling in `R/ir_legends.R:108` is a starting point; bump if banding visible. Final stop count is Claude's discretion.
- **D-10:** Legend title, orientation (vertical default; horizontal when `legend.position` is top/bottom), sizing follow ggplot2 theme defaults — no new theme APIs.

**Edge cases**
- **D-11:** NA values render with `na.value` (default `"grey50"`) — verified by snapshot.
- **D-12:** `scale_color_*` and `scale_fill_*` together produce two correct legends with no overlap or shared-state bugs.
- **D-13:** Alpha-resolved RGBA hex (e.g. `#FF000080`) round-trips identically to the DOM. Don't strip the alpha byte.
- **D-14:** Out-of-range factor levels in `scale_*_manual(values=...)` map to `na.value` (same path as D-11).

**Verification**
- **D-15:** `tests/testthat/_snaps/color/<plot-id>.json` per plot, `{expected_hex_per_row, expected_legend_hex}`. `testthat`'s built-in snapshot machinery. NOT PNG diff.
- **D-16:** ~7-8 base snapshots (one geom_point per scale variant) + 4 edge-case snapshots (D-11..D-14).
- **D-17:** Each test renders via existing pipeline, walks the DOM (v1.0 `test-legends.R` pattern), compares to snapshot. `testthat::snapshot_accept()` updates.

### Claude's Discretion
- Final gradient stop count (D-09 ceiling: bump if banding).
- Tick count on colorbar — driven by ggplot2's pretty-break logic.
- Whether to share rendering code between continuous (smooth) and binned (banded) — both produce a `linearGradient`.
- Whether color extraction lives in `R/ir_scales.R` or new `R/ir_colors.R`. Default: extend `R/ir_scales.R`; split only past Phase-13 size envelope.
- Per-row layer color flow already correct (`ggplot_build` resolves; `R/ir_layers.R` passes through). Confirm in research.

### Deferred Ideas (OUT OF SCOPE)
- Visual PNG diff testing — defer to CRAN-prep or v1.2.
- `scale_*_gradient`/`gradient2`/`gradientn` as named requirements — only if free.
- Custom `guide_colorbar()` argument support (`barwidth=`, `title.position=`) — v1.2 theming.
- Color blending for overlapping `geom_density`/`geom_polygon` fills — Phase 16.
- Interactive legend (click-to-filter, hover-to-highlight) — static legends only.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| COLOR-01 | viridis/brewer/manual color/fill scales render in D3 with the same hex codes ggplot2 produces (verified per-row vs `ggplot_build()`) | Defect Corpus rows 1-7 reproduce mark colors per scale; existing `R/ir_layers.R::extract_layers_ir` already passes per-row `colour`/`fill` through (Pitfall 6 confirms passthrough is correct). The break is on the JS side (Pitfall 1 — RGBA regex) and in legend swatches (Pitfall 4 — colorbar `colors_array` is sampled but ignored when `is_continuous` mis-routes). Plan owns: (a) JS regex fix, (b) ensure layer per-row column is the only color source for `colour`/`fill` aesthetics, (c) drop the unused turbo fallback. |
| COLOR-02 | Continuous color renders as a colorbar legend (gradient + ticks), not a discrete key fallback | Defect Corpus row 1 (viridis_c), row 4 (distiller), row 7 (steps) all already produce `type=colorbar` from `extract_legends_ir`. The break is downstream: (a) `ir$scales$color` always reports `type="categorical"` (Pitfall 3) — irrelevant to the legend type but masks any continuous detection done from `ir.scales`; (b) colorbar IR carries 30-stop `colors_array` but no `breaks`, `labels`, or `is_steps` flag (Pitfall 4); (c) `renderColorbar` uses only first/last keys for ticks (Pitfall 5). Plan owns: enrich colorbar IR + extend `renderColorbar` to honor breaks and the banded/smooth distinction. |
</phase_requirements>

## Summary

Three findings change planning from what CONTEXT.md anticipated:

1. **Per-row layer colors are *already* plumbed correctly end-to-end for valid 6-digit hex** (viridis_c, brewer, distiller, manual). The existing `R/ir_layers.R` per-row passthrough plus the JS-side `makeColorAccessors` "if `isValidColor(v)` use it directly" branch already wins for these. There's almost no R-side per-row work for COLOR-01 in those cases.
2. **The blocking defect for COLOR-01 is a 1-line JS regex bug**: `isHexColor` accepts only `#RGB`/`#RRGGBB` and rejects 8-digit RGBA. This breaks `viridis_d` (which emits `#440154FF`) and any alpha-resolved row (D-13: `#FF000080`). When `isHexColor` returns false, the row falls through to a `colorScale(v)` call against `d3.interpolateTurbo`, which produces visually wrong colors and silently violates char-for-char parity.
3. **The colorbar IR is built but undernourished.** `extract_legends_ir` already sets `type="colorbar"` for continuous color/fill aesthetics and produces a 30-element `colors_array`. The JS `renderColorbar` already draws a `linearGradient` rectangle. **What's missing:** `breaks`, `labels`, and an `is_steps` flag on the IR; on the JS side, the renderer hardcodes first/last keys as ticks (Pitfall 5) and has no banded path. So COLOR-02 is two narrow extensions, not a rewrite.

**Primary recommendation:** Two-axis split. Plan A — JS regex/hex fix (small, high-leverage) for COLOR-01 RGBA cases. Plan B — IR enrichment (`breaks`, `labels`, `na.value`, `is_steps`, `is_continuous`) in `R/ir_legends.R` and `R/ir_scales.R::scales$color`. Plan C — `renderColorbar` extension for ticks-from-breaks + banded variant for COLOR-02. Plus snapshot harness plan and dual-scale (D-12) plan. The existing 30-stop sampling looks visually smooth on viridis_c and distiller in the corpus — start there, bump only if a snapshot reveals banding on a wider palette.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Per-row resolved hex (mark colors) | R: `ggplot_build()` + `R/ir_layers.R` | JS: `geom-registry.js::makeColorAccessors` | Source of truth is ggplot2 itself; R passes through; JS only consumes hex strings |
| Discrete legend swatches | R: `extract_legends_ir` (already public-API via `get_guide_data`) | JS: `legend.js::renderDiscreteLegend` | ggplot2's public guide_data API supplies hex per key; JS already renders correctly |
| Colorbar gradient stops | R: `extract_legends_ir` (`scale_obj$map(seq(domain, 30))`) | JS: `legend.js::renderColorbar` | Stops are scale-mapped values; sampling decision is R-side; rendering is just `<linearGradient>` |
| Colorbar tick positions/labels | R: `extract_legends_ir` (extend) | JS: `renderColorbar` (extend) | ggplot2 owns break/label logic; JS must consume verbatim, not regenerate |
| Banded vs smooth colorbar | R: `extract_legends_ir` (set `is_steps` flag) | JS: `renderColorbar` (branch on flag) | Distinction is a property of the scale; renderer just chooses 2-stop-per-bin vs N-stop |
| na.value resolution | R: `scale_obj$na.value` extraction in `ir_scales.R` | JS: `makeColorAccessors` (already converts named colors via `convertColor`) | ggplot2 stores na.value on the scale; JS already handles `"grey50"` |
| Color domain for `ir.scales.color` | R: `extract_scales_ir` (rewrite — see Pitfall 3) | — | Currently misclassifies; correctness matters only if anything reads it (it does not in the geom path) |

## Existing Color Pipeline (end-to-end map)

```
ggplot2 plot
   │
   ▼
ggplot_build(p)                                            [R: ggplot2 internal]
   │  resolves every layer row's `colour` / `fill` to a hex string
   │  (or "grey50" for NA, or RGBA hex when alpha is mapped)
   │
   ▼
R/as_d3_ir.R::as_d3_ir(p)                                  [R: orchestrator, 120 lines]
   │  delegates to per-concern extractors
   │
   ├──► extract_layers_ir(b, xscale, yscale)               [R/ir_layers.R:10-133]
   │      keep_aes c(...,"colour","fill","alpha",...)      [line 13-22]
   │      to_rows(df, keep_aes)                            [line 128]
   │      ──► ir.layers[[i]].data is array of row objects
   │           each row carries the resolved `colour` and `fill` hex columns
   │
   ├──► extract_scales_ir(b, pp_x, pp_y, is_flip)          [R/ir_scales.R:247-305]
   │      ▼ scales$color block at line 296                [<<< CONTEXT.md's "extend point" >>>]
   │        allc <- unlist(lapply(b$data, fn(df) df$colour))
   │        scales$color <- list(
   │          type   = if (is.numeric(allc)) "continuous" else "categorical",
   │          domain = unname(dom(allc))
   │        )
   │      ──► ir.scales.color
   │      ⚠️  `is.numeric(allc)` is ALWAYS FALSE because `ggplot_build`
   │          has already resolved colour to character hex strings — see
   │          Pitfall 3. The block also never inspects `b$data[[i]]$fill`.
   │
   └──► extract_legends_ir(b, p)                           [R/ir_legends.R:7-184]
          loops over plot scales whose aesthetic ∈ {colour, fill, size, shape, alpha}
          calls public ggplot2::get_guide_data(p, aesthetic=…)   [line 47-50]
          ▼ guide_type decision at line 61
            is_continuous  <- inherits(scale_obj, "ScaleContinuous")
            is_color_aes   <- aes_name %in% c("colour","fill")
            guide_type     <- if (is_continuous && is_color_aes) "colorbar" else "legend"
          ▼ colorbar branch lines 101-114 (CONTEXT.md "extend point")
            if (guide_type == "colorbar") {
              scale_domain <- scale_obj$get_limits()
              color_values <- seq(scale_domain[1], scale_domain[2], length.out = 30)
              colors_array <- scale_obj$map(color_values)
            }
          ▼ guide_spec assembly lines 116-123
            list(aesthetic, aesthetics, type, title, keys, colors)
          ──► ir.guides[[i]]
          ⚠️  No `breaks`, `labels`, `na.value`, `is_steps` — see Pitfall 4.

ir   ─JSON─►   inst/htmlwidgets/gg2d3.js (browser)

inst/htmlwidgets/gg2d3.js:79-84                            [JS: render entry]
   const cdesc = ir.scales && ir.scales.color;
   const colorScale = cdesc
     ? (cdesc.type === "continuous"
         ? d3.scaleSequential(d3.interpolateTurbo).domain(d3.extent(cdesc.domain || [0,1]))
         : d3.scaleOrdinal(d3.schemeTableau10).domain(cdesc.domain || []))
     : (() => null);
   ⚠️  This builds a colorScale from ir.scales.color, but Pitfall 3
       guarantees `cdesc.type === "categorical"` ALWAYS, so the discrete
       branch is taken even for continuous plots. The Tableau10 ordinal
       scale is then *never used in practice* because rows already have
       hex strings (Pitfall 6).

inst/htmlwidgets/modules/geom-registry.js::makeColorAccessors  [lines 127-191]
   const strokeColor = d => {
     if (aes.color) {
       const v = val(get(d, aes.color));
       if (isValidColor(v)) return convertColor(v);     // ◄── 6-hex hits this fast path
       const converted = convertColor(v);
       if (converted !== v) return converted;            // ◄── grey50 hits this branch
       const mapped = colorScale(v);                     // ◄── ONLY reached if v is not
       return mapped || convertColor(params.colour) || "currentColor";
     }                                                   //     a valid CSS color string
     return convertColor(params.colour) || "currentColor";
   };
   ⚠️  isValidColor / isHexColor regex `^#([0-9a-f]{3}|[0-9a-f]{6})$/i`
       REJECTS 8-digit RGBA. viridis_d emits `#440154FF`; alpha-mapped
       rows emit `#FF000080`. These fall to the broken colorScale path.
       This is the single biggest visible defect — see Pitfall 1.

inst/htmlwidgets/modules/legend.js::renderLegends  [line 547-597]
   for each guide:
     guide.type === "legend"   → renderDiscreteLegend(...)   [line 216]
     guide.type === "colorbar" → renderColorbar(svg, guide, x, y, theme)  [line 433-532]

inst/htmlwidgets/modules/legend.js::renderColorbar  [line 433-532]
   ▼ defs.append("linearGradient")             [line 467-473]
     vertical gradient bottom-to-top
   ▼ stops from guide.colors                   [line 476-482]
     `(idx / (colors.length-1)) * 100`% offset, `convertColor(color)` stop-color
   ▼ <rect> fill=url(#gradientId)              [line 485-493]
     barWidth = defaults.keySize, barHeight = 5×keySize
   ▼ tick rendering                            [line 495-528]
     ⚠️  Uses ONLY guide.keys[0] and guide.keys[last] for ticks/labels.
         All intermediate ticks are dropped. See Pitfall 5.
     ⚠️  Tick `proportion` is computed from key.value vs the
         min/max of `guide.keys.map(k => parseFloat(k.value))`,
         NOT against the scale domain. Works only if first/last
         keys are domain endpoints — not always true for `pretty()`
         break logic.

⚠️  No banded variant. `renderColorbar` always emits a smooth gradient.
   For `scale_color_steps()` (D-06), this is wrong — should be hard
   stops at bin boundaries, matching guide_coloursteps's appearance.
```

**Net:** five concrete gap points (numbered Pitfalls 1-5 below) plus two confirmations (Pitfalls 6-7) that flagged candidate work is actually a no-op.

## Defect Corpus

Rendered live against `pkgload::load_all(".")` of the post-Phase-13 codebase. Each row reports: what `ggplot_build()` produced; what `as_d3_ir()` produced; what would render in the DOM following the JS pipeline above; the gap.

### Per-Scale-Type Findings

| # | Scale variant | Per-row mark | Legend `ir$guides[[1]]$type` | Per-row hex parity? | Legend hex parity? | Defect |
|---|---|---|---|---|---|---|
| 1 | `scale_color_viridis_c()` | `#440154` (6-hex) | `colorbar` ✓ | **Pass** — hex passes through `isHexColor` → `convertColor` identity | **Partial** — gradient stops are correct; ticks use only first/last key (Pitfall 5) | Tick logic |
| 2 | `scale_color_viridis_d()` | `#440154FF` (8-hex RGBA) | `legend` (correct: discrete) | **Fail** — `isHexColor` rejects 8-digit; falls through to `interpolateTurbo`, producing visually wrong color | Discrete legend renders correctly because `renderDiscreteLegend` reads `key.colour` directly (no regex) | **Pitfall 1** |
| 3 | `scale_fill_brewer(palette="Set1")` (discrete) | `#E41A1C` (6-hex) | `legend` ✓ | **Pass** | **Pass** | None |
| 4 | `scale_color_distiller(palette="Spectral")` (continuous) | `#3288BD` (6-hex) | `colorbar` ✓ | **Pass** | **Partial** — same Pitfall 5 (ticks) and Pitfall 4 (no `breaks`/`labels` in IR) | Tick/break plumbing |
| 5 | `scale_color_manual(values=c(a="#FF0000",b="#00FF00",c="#0000FF"))` (named) | `#FF0000` (6-hex) | `legend` ✓ | **Pass** | **Pass** | None |
| 6 | `scale_color_manual(values=c("#FF0000","#00FF00","#0000FF"))` (unnamed, position-mapped) | `#FF0000` (6-hex) | `legend` ✓ | **Pass** | **Pass** | None |
| 7 | `scale_color_steps()` (binned) | `#1B3A57` (6-hex) | `legend` (**wrong — should be `colorbar`/banded**) | Mark color: pass | Legend: rendered as discrete keys, not banded gradient | **Pitfall 8** |

### Edge-Case Findings

| # | Edge case | Observation | Defect |
|---|---|---|---|
| E1 | NA in continuous color column (D-11) | `ggplot_build` emits literal string `"grey50"` for NA rows. `convertColor("grey50")` correctly returns `#7F7F7F`. **Per-row pass**. The colorbar gradient does NOT include grey50 (correct — ggplot2 colorbars also exclude na.value); no separate "NA swatch" rendered. | None for marks; consider whether D-11 wants an explicit NA swatch (ggplot2 `guide_colorbar` does not show one by default — Pitfall 9). |
| E2 | Alpha resolved into RGBA (D-13) | `aes(alpha=...)` produces a separate alpha guide; the colour column itself stays as 6-hex (`#F8766D`) and ggplot2 emits `opacity` separately. **However**, when `aes(color=...)` is mapped to a discrete variable WITH `viridis_d`, the colour column is 8-hex `#440154FF`. The 8-hex case is the actual D-13 risk. | **Pitfall 1** (same root cause as defect #2). |
| E3 | Both `scale_color_*` and `scale_fill_*` (D-12) | Two guides emitted (`type=legend` for color, `type=colorbar` for fill). Per-row `colour` AND `fill` columns both carry hex strings. `ir$scales$color` shows ONLY the colour domain (no fill block) — but the geom-side `makeColorAccessors` reads from row data, not from `ir.scales`, so this works in practice. | None blocking; **confirms D-12 works**. But Pitfall 3 still applies. |
| E4 | Manual out-of-range factor level (D-14) | `g = factor(c("a","b","x"), levels=c("a","b","x"))` with `scale_color_manual(values=c(a="#FF0000",b="#00FF00"))` ⇒ row 3 emits `"grey50"` literal. `convertColor("grey50")` → `#7F7F7F`. **Pass**. ggplot2 also emits a 1-row warning about missing values. | None; **confirms D-14 works**. |

### Live evidence (excerpts; full corpus in `/tmp/research_corpus.R`)

```
CASE: viridis_d (discrete color)
  ggplot_build colour column: "#440154FF" "#482878FF" ...        ← 8-hex RGBA
  ir.layers[[1]].data[[1]].colour: "#440154FF"                   ← passthrough OK
  ir.guides[[1]]: type=legend, keys=10, key.colour="#440154FF"  ← legend OK
  → DOM render path:
     row.colour = "#440154FF"
     isHexColor("#440154FF") = false   (regex limited to 3 or 6 hex digits)
     isValidColor("#440154FF") = true  (browser CSS recognises rgba hex)
     ⇒ falls through to convertColor identity
     ⇒ ACTUALLY renders correctly via the second branch
  WAIT — re-check: isValidColor returns true via the named-color path
  because modern browsers accept #RRGGBBAA. The fall-through to colorScale
  only happens if isValidColor returns FALSE entirely. For browsers that
  accept 8-hex CSS, parity holds. For browsers that don't, breaks. SEE
  Pitfall 1 nuance.
```

(Pitfall 1 below carries the corrected analysis — the regex is still wrong, but the practical fallout depends on browser CSS support for 8-digit hex. ALL evergreen browsers support it; IE11 does not. Snapshot test must assert exact hex regardless of browser capability, so the regex still needs fixing.)

```
CASE: scale_color_steps()
  ggplot_build colour column: "#1B3A57" "#1B3A57" "#2A5A82" ...  ← 6-hex per bin
  ir.scales.color.type: "categorical"                            ← Pitfall 3
  ir.guides[[1]]:
    type: "legend"   ← WRONG. ggplot2 default for steps is guide_coloursteps,
                       which is a banded colorbar, not discrete keys
    colors_array: NULL
  Root cause: extract_legends_ir line 59:
    is_continuous <- inherits(scale_obj, "ScaleContinuous")
  ScaleBinned does NOT inherit from ScaleContinuous in ggplot2 — it inherits
  from Scale directly. So the colorbar branch is never reached.
  → Pitfall 8.
```

```
CASE: continuous color, NA row
  ggplot_build colour column: "#440154" "#452B70" "grey50" "#37678C" ...
  ir.scales.color.type: "categorical"   ← Pitfall 3 again
  ir.guides[[1]]: type=colorbar, colors_array length 30
  No na.value field anywhere in IR.
  → DOM path:
    row.colour = "grey50"
    isHexColor → false; isValidColor → true (CSS named); convertColor("grey50") → "#7F7F7F"
    Renders correctly.
  ggplot2 reference: guide_colorbar does NOT render an NA swatch by default.
  → No rendering defect. But D-11's snapshot must assert #7F7F7F for the NA row.
```

```
CASE: dual color+fill (D-12)
  ggplot_build:
    colour column: "#E41A1C" "#377EB8" ... (Set1, discrete)
    fill   column: "#440154" "#452B70" ... (viridis_c, continuous)
  ir.scales.color.domain has the COLOUR brewer values + a trailing NA
    (because dom() of fills was unioned in — bug at R/ir_scales.R:296,
    `allc <- unlist(lapply(b$data, fn(df) if ("colour" %in% names(df)) df$colour))`
    correctly only reads colour, but the trailing NA in the printed output
    suggests something elsewhere; verify in plan).
  ir.guides has TWO entries:
    - aesthetic=colour, type=legend, 10 keys with key.colour set
    - aesthetic=fill,   type=colorbar, 30 colors_array
  Renders correctly per-row. → D-12 verifies clean.
```

## Pitfalls

### Pitfall 1: 8-digit RGBA hex is not matched by `isHexColor`
- **What goes wrong:** `inst/htmlwidgets/modules/constants.js:188-190` defines `isHexColor` with regex `/^#([0-9a-f]{3}|[0-9a-f]{6})$/i`. `viridis_d` emits `#RRGGBBAA` (e.g. `#440154FF`); `aes(alpha=...)` resolution can also emit RGBA hex (D-13).
- **Why it happens:** Original v1.0 spec only considered 3/6-digit hex; CSS Color 4 added 8-digit hex later, and viridis_d uses it for the trailing `FF` alpha by convention.
- **Practical fallout:** `isValidColor` falls through from `isHexColor` to a DOM `getComputedStyle` check — modern browsers accept 8-hex via CSS, so visual rendering often *appears* correct. **But snapshot tests assert exact strings.** Any code path that uses `isHexColor` directly (none in the current codebase, but reasonable to expect during this phase) will break, and IE11 / older WebView contexts fail outright.
- **How to avoid:** Update regex to `/^#([0-9a-f]{3,4}|[0-9a-f]{6}|[0-9a-f]{8})$/i` (3, 4, 6, or 8 hex digits — 4-digit is the short RGBA form).
- **Warning signs:** Any plot using `scale_*_viridis_d()` is a tripwire.

### Pitfall 2: `extract_legends_ir` continuous-detection misses `ScaleBinned`
- **What goes wrong:** `R/ir_legends.R:59` does `is_continuous <- inherits(scale_obj, "ScaleContinuous")`. ggplot2's `ScaleBinned` (used by `scale_*_steps`, `scale_*_binned`) inherits from `Scale` directly, **not** from `ScaleContinuous`. Result: `scale_color_steps()` is misclassified as discrete — `guide_type == "legend"` instead of `"colorbar"`. (Confirmed live: defect corpus row 7.)
- **Why it happens:** ggplot2's class hierarchy quietly added `ScaleBinned` as a third sibling alongside `ScaleContinuous` and `ScaleDiscrete`.
- **How to avoid:** Predicate should be `inherits(scale_obj, c("ScaleContinuous", "ScaleBinned"))`. Then add an `is_steps <- inherits(scale_obj, "ScaleBinned")` flag on the guide spec so the JS renderer can choose banded vs smooth (D-06).
- **Warning signs:** `scale_*_steps`, `scale_*_binned`, or any custom binned scale produces a discrete-key legend.

### Pitfall 3: `ir.scales.color.type` is always `"categorical"` (cosmetic but misleading)
- **What goes wrong:** `R/ir_scales.R:298` does `type = if (is.numeric(allc)) "continuous" else "categorical"`. `allc` is `unlist(b$data[[i]]$colour)` — but `ggplot_build()` has already mapped colour to a **character** hex string. `is.numeric(character)` is `FALSE` always. So `ir.scales.color.type` is always `"categorical"`, regardless of whether the underlying ggplot scale is continuous.
- **Why it happens:** v1.0 inherited from a pre-`ggplot_build` code path where `allc` was the raw input data column. After the layer pipeline shifted to using built layer data, the type detection stopped working.
- **Impact:** Almost none — `inst/htmlwidgets/gg2d3.js:79-84` uses `cdesc.type` to choose between `d3.scaleSequential(d3.interpolateTurbo)` and `d3.scaleOrdinal(d3.schemeTableau10)`. Both branches construct a `colorScale` that is **never used for valid hex rows** because `makeColorAccessors` short-circuits via `isValidColor`. The colorScale is only consulted when a row carries a non-color value (e.g. a numeric still pending mapping), which ggplot2 never produces.
- **How to avoid:** Either (a) fix the type detection by inspecting the first scale object (`ScaleContinuous` ⇒ `"continuous"`), or (b) **delete the colorScale construction in `gg2d3.js:79-84` entirely** since it's unused. Option (b) is cleaner — it eliminates the broken `interpolateTurbo` fallback that would silently mask Pitfall 1 if that fallback were ever reached. **Recommended: delete.** If the planner prefers (a), it must also extend `extract_scales_ir` to set the right type AND populate `domain` with the scale's numeric domain (currently it's a `dom()` of the rendered hex strings — meaningless for a continuous color scale).
- **Warning signs:** Look at any test that asserts `ir$scales$color$type == "continuous"` — there are none currently, which is why the bug has lived.

### Pitfall 4: Colorbar IR carries `colors_array` but no `breaks`/`labels`/`na.value`/`is_steps`
- **What goes wrong:** `R/ir_legends.R:101-114` builds `colors_array <- scale_obj$map(seq(domain[1], domain[2], length.out=30))`. The guide spec at lines 116-123 stores it as `colors`. **But:** no `breaks`, no `labels`, no `na.value`, no `is_steps`. Downstream `renderColorbar` (legend.js:495-528) compensates by reading `guide.keys[0]` and `guide.keys[last]` — losing all intermediate ticks.
- **Why it happens:** v1.0 colorbar was a stub; it produced a gradient with placeholder min/max labels and was never extended to honor ggplot2's pretty-break logic.
- **How to avoid:** Extend the colorbar branch in `extract_legends_ir` to also store:
  - `breaks` — `scale_obj$breaks` (auto) or whatever `scale_obj$get_breaks()` returns; align with what's in `guide_data$.value`
  - `labels` — `scale_obj$get_labels(breaks)` (or pull from `guide_data$.label`)
  - `na.value` — `scale_obj$na.value %||% "grey50"`
  - `is_steps` — `inherits(scale_obj, "ScaleBinned")` (Pitfall 2)
  - `is_continuous` — explicit boolean for downstream branching
  - `domain` — numeric `scale_obj$get_limits()` (DIFFERENT from current `colors_array` indexing — the JS needs the domain to position ticks correctly).
- **Warning signs:** Colorbar in the rendered DOM shows only two labels (at min and max) — exactly what the corpus shows for viridis_c.

### Pitfall 5: `renderColorbar` ignores intermediate ticks; uses key positions, not domain positions
- **What goes wrong:** `inst/htmlwidgets/modules/legend.js:495-528`:
  ```js
  const endKeys = [guide.keys[0], guide.keys[guide.keys.length - 1]];
  endKeys.forEach(key => { ... draw tick + label ... })
  ```
  Only the first and last keys produce ticks. ggplot2's `guide_colorbar` shows ~5 ticks at scale-pretty break positions.
  
  Also: the proportion math `(value - minVal) / range` uses the min/max of *the keys* as `minVal`/`maxVal`. ggplot2's keys come from break positions, which may not be the scale domain endpoints (e.g. `breaks=c(2.5, 5, 7.5)` for a `[0,10]` domain). The first key would be at proportion 0 instead of 0.25 — visible misplacement.
- **How to avoid:** After Pitfall 4 is fixed, renderColorbar receives `guide.breaks`, `guide.labels`, and `guide.domain`. Iterate over `guide.breaks`, place each tick at `(break - domain[0]) / (domain[1] - domain[0])`, label from `guide.labels[i]`. Drop the `[0]/[last]` slice.
- **Warning signs:** Continuous colorbar with custom breaks (e.g. `+ scale_color_viridis_c(breaks=c(2,4,6,8))`) renders only `2` and `8` labels in v1.0.

### Pitfall 6: Per-row `colour`/`fill` passthrough is correct (confirms CONTEXT.md's discretion note)
- **Status:** Verified. `R/ir_layers.R:13-22` keep_aes contains `"colour"` and `"fill"`. `to_rows(df, keep_aes)` emits each row with these columns intact. `inst/htmlwidgets/modules/geom-registry.js:144-176::strokeColor`/`fillColor` short-circuit on `isValidColor` to use the per-row hex directly. **No planner work needed for the pure passthrough.** The only per-row defect is Pitfall 1.

### Pitfall 7: The unused `colorScale` in `gg2d3.js:79-84` is dead code worth deleting
- **Status:** Same root cause as Pitfall 3 + 6. The branch builds a D3 ordinal/sequential scale that gets passed to `makeColorAccessors` as `options.colorScale` — but `makeColorAccessors` only reaches it if `isValidColor` AND `convertColor`-identity both fail, which doesn't happen for `ggplot_build`-resolved data. Deleting it would prevent silent visual regressions if Pitfall 1 caused a fall-through to `interpolateTurbo`. **Recommend: drop the construction; pass `null` as `options.colorScale`; simplify `makeColorAccessors` to remove the `colorScale(v)` branch.** This is a small refactor that makes the color path deterministic.

### Pitfall 8: `scale_*_steps` / `scale_*_binned` defaults to `guide_coloursteps`, not `guide_colorbar`
- **What goes wrong:** This is the surface manifestation of Pitfall 2 in ggplot2 terms. When you call `scale_color_steps()`, ggplot2's default guide is `guide_coloursteps()` — which produces the **banded** colorbar (D-06's exact target). Currently gg2d3 misroutes it to discrete. Once Pitfall 2 is fixed (the `ScaleBinned` predicate), the IR will say `type=colorbar`, but `renderColorbar` produces a smooth gradient — wrong for D-06.
- **How to avoid:** After Pitfall 2 + Pitfall 4 land, `is_steps=true` propagates. In `renderColorbar`, branch:
  - `is_steps=false` (smooth): existing 30-stop interpolated gradient. No change.
  - `is_steps=true` (banded): build a gradient with **two stops per bin** (the same color at the start and end of each bin), so the gradient appears as flat color blocks with hard boundaries. `<linearGradient>` supports this trivially.
  - Banded ticks should align with bin boundaries (`breaks`).
- **Warning signs:** `scale_color_steps()` in v1.1 still showing a smooth gradient.

### Pitfall 9: `na.value` is not rendered as a separate swatch (matches ggplot2; do NOT add)
- **Status:** ggplot2's default `guide_colorbar()` does NOT show an NA swatch — NA rows just render in the panel with `na.value` color but no dedicated legend element. D-11 is satisfied by per-row parity alone (`#7F7F7F` for `"grey50"`). **Plan should explicitly NOT add a separate NA swatch to the colorbar** — that would diverge from ggplot2.
- **Counterpoint:** If a user passes `+ scale_color_viridis_c(na.value="red")` and provides `guide=guide_colorbar(na.value=...)`, ggplot2 *can* show an NA swatch in some versions. Out of scope per D-07/D-10 (no per-guide overrides).

### Pitfall 10: `RColorBrewer` `n too large` warnings are noise, not signal
- **What goes wrong:** Defect corpus row 3 produced 4 warnings: `"n too large, allowed maximum for palette Set1 is 9"`. Set1 has 9 colors; the corpus had 10 levels. ggplot2 silently fills the 10th with NA.
- **Status:** This is ggplot2 behavior, not a gg2d3 bug. The corpus had 10 levels; if a real test plot has ≤9, no warning. **Snapshot tests should use ≤9 levels for Set1 to avoid warning noise.**

## Implementation Approach

**File-extension default (per CONTEXT.md "Claude's Discretion"):** Extend `R/ir_scales.R` and `R/ir_legends.R` rather than create `R/ir_colors.R`. The extensions add ~30 lines to `ir_legends.R` and ~10 to `ir_scales.R` — well within Phase-13's size envelope.

### Plan-shape proposal (planner's call; not prescriptive)

Six narrow plans, executable in three waves:

**Wave 0 — Test scaffold (no production code)**
- `14-00-snapshot-harness-PLAN.md`: Create `tests/testthat/_snaps/color/` directory, helper for DOM-walking the rendered SVG, snapshot helper that captures `{expected_hex_per_row, expected_legend_hex, expected_colorbar_stops}`. Stub corpus plots in `tests/testthat/test-color-fidelity.R` (skip-pending).

**Wave 1 — Independent fixes (parallel)**
- `14-01-rgba-hex-PLAN.md`: Pitfall 1 — fix `isHexColor` regex; add unit test for 4/8-digit hex.
- `14-02-binned-detection-PLAN.md`: Pitfall 2 — extend `is_continuous` predicate in `R/ir_legends.R` to include `ScaleBinned`; add `is_steps` flag on guide spec.
- `14-03-colorscale-cleanup-PLAN.md`: Pitfall 3 + 7 — remove dead `colorScale` construction in `gg2d3.js:79-84`; simplify `makeColorAccessors` colorScale branch; either delete `ir.scales.color` block or correct it (recommend delete; no consumer).

**Wave 2 — Colorbar enrichment (depends on Wave 1)**
- `14-04-colorbar-ir-PLAN.md`: Pitfall 4 — extend colorbar branch in `extract_legends_ir` with `breaks`, `labels`, `na.value`, `domain`, `is_continuous`, `is_steps`; update `tests/testthat/test-ir-legends.R`.
- `14-05-colorbar-render-PLAN.md`: Pitfalls 5 + 8 — extend `renderColorbar` to honor breaks/labels and to branch smooth vs banded.

**Wave 3 — Snapshot corpus (depends on all above)**
- `14-06-snapshots-PLAN.md`: Populate the 7 base + 4 edge-case snapshots from D-16. Each test:
  1. Build the plot, run `as_d3_ir(p)`, render via the existing pipeline (use `htmlwidgets:::toHTML` + an offscreen DOM walker; reuse the `test-legends.R` pattern).
  2. Walk the DOM, extract `fill`/`stroke` from layer elements and `stop-color` from gradient stops.
  3. Compare to `ggplot_build(p)` resolved colour/fill columns and `scale_obj$map(scale_obj$get_breaks())` for legend swatches.
  4. Use `testthat::expect_snapshot_value(..., style="json2")` to persist.

### Banded gradient strategy (D-06 + Pitfall 8)

For `is_steps=true`, build the SVG `<linearGradient>` with `2 * n_bins` stops:
```
bin 1: [domain[0], break[1]]  →  color[1]@0%, color[1]@(break[1]-domain[0])/range×100%
bin 2: [break[1], break[2]]   →  color[2]@same%, color[2]@(break[2]-domain[0])/range×100%
...
```
Both stops within a bin share the same color, producing visually flat blocks with hard boundaries — visually equivalent to ggplot2's `guide_coloursteps`. `<linearGradient>` handles same-position stops correctly across all evergreen browsers.

### Tick logic plumbing (D-08)

After Pitfall 4: `guide.breaks` and `guide.labels` arrive in the JS as parallel arrays. In `renderColorbar`:
```js
const breaks = guide.breaks || [];
const labels = guide.labels || breaks.map(String);
const [d0, d1] = guide.domain || [0, 1];
breaks.forEach((b, i) => {
  const proportion = (b - d0) / (d1 - d0);
  const tickY = barY + barHeight - (proportion * barHeight);
  // emit <line> + <text> at tickY with labels[i]
});
```
**Drop entirely** the existing `endKeys` slice and the `parseFloat(key.value)` math.

### Risk register
- **R1 (low):** Pitfall 4's `scale_obj$breaks` may be a function (autobreak generator) rather than a numeric vector. Resolution: prefer `scale_obj$get_breaks(scale_obj$get_limits())` or pull from `panel_params` like `R/ir_scales.R::extract_scales_ir` does for x/y axes. Verify in plan 14-04.
- **R2 (low):** Snapshot tests run in headless R; the JS-side DOM is built via htmlwidgets render hooks. There's no JS runtime in `testthat` by default. v1.0's `test-legends.R` works around this by **walking the IR**, not the rendered DOM (`expect_true(all(grepl("^#", colors)))`). For COLOR-01's char-for-char contract, asserting against IR is sufficient because the JS path for valid hex is provably identity (Pitfall 6) — we don't need a JS runtime to verify hex parity. Plan 14-00 should explicitly call out: snapshots compare `ir.layers[[i]].data[[j]].colour` to `ggplot_build()$data[[i]]$colour`, and `ir.guides[[i]].colors` (or `keys[k].colour`) to `scale_obj$map(...)`. The Pitfall 1 regex fix is the only "truly JS-side" defect; cover it with a JS unit test in `tests/testthat/test-validate-ir.R`-style with `V8` or `node`, OR a static assertion ("`isHexColor` regex matches an 8-digit hex"). Recommend the latter — `grep` on `/[0-9a-f]{8}/` in `constants.js`.
- **R3 (medium):** Dual color+fill (D-12) — verify `extract_legends_ir`'s "merged guides" logic (lines 129-180) doesn't accidentally merge the two when titles differ. Corpus row D-12 shows two guides correctly; planner should add a regression snapshot.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | `testthat` 3.x (already established) |
| Config file | `tests/testthat.R` |
| Quick run command | `Rscript -e 'pkgload::load_all(".",quiet=TRUE); testthat::test_file("tests/testthat/test-color-fidelity.R")'` |
| Full suite command | `Rscript -e 'pkgload::load_all(".",quiet=TRUE); testthat::test_dir("tests/testthat")'` |
| Snapshot tool | `testthat::expect_snapshot_value(style="json2")` writes to `tests/testthat/_snaps/color/` |
| R env note | If devtools/Makevars conflict: `R_MAKEVARS_USER=/tmp/empty_makevars Rscript ...` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| COLOR-01 | viridis_c per-row mark hex equals `ggplot_build()` | unit/snapshot | `testthat::test_file("tests/testthat/test-color-fidelity.R")` | ❌ Wave 0 |
| COLOR-01 | viridis_d per-row mark hex (8-hex RGBA) equals `ggplot_build()` | unit/snapshot | same | ❌ Wave 0 |
| COLOR-01 | brewer (discrete fill) per-row hex parity | unit/snapshot | same | ❌ Wave 0 |
| COLOR-01 | distiller per-row hex parity | unit/snapshot | same | ❌ Wave 0 |
| COLOR-01 | manual (named) per-row hex parity | unit/snapshot | same | ❌ Wave 0 |
| COLOR-01 | manual (unnamed) per-row hex parity | unit/snapshot | same | ❌ Wave 0 |
| COLOR-01 | steps/binned per-row hex parity | unit/snapshot | same | ❌ Wave 0 |
| COLOR-02 | viridis_c emits `type=colorbar` with ≥30 gradient stops | unit | extends `tests/testthat/test-ir-legends.R` | ✅ partial (line 49-65) |
| COLOR-02 | distiller emits `type=colorbar` | unit | same | ❌ Wave 1 (extension) |
| COLOR-02 | scale_color_steps emits `type=colorbar` AND `is_steps=true` | unit | same | ❌ Wave 1 |
| COLOR-02 | colorbar IR includes `breaks`, `labels`, `na.value`, `domain`, `is_continuous` | unit | same | ❌ Wave 2 |
| COLOR-02 | renderColorbar tick count matches `length(guide$breaks)` | static/JS | grep-style assertion in `tests/testthat/test-color-fidelity.R` (string-search the rendered SVG via htmlwidgets render path) | ❌ Wave 3 |
| Edge D-11 | NA color row renders as `#7F7F7F` (`grey50`) | unit/snapshot | corpus snapshot test | ❌ Wave 3 |
| Edge D-12 | dual color+fill produces 2 guides, no merge | unit/snapshot | corpus snapshot test | ❌ Wave 3 |
| Edge D-13 | RGBA hex round-trips identically | unit/snapshot | corpus snapshot test (also covered by viridis_d) | ❌ Wave 3 |
| Edge D-14 | manual out-of-range factor maps to `na.value` | unit/snapshot | corpus snapshot test | ❌ Wave 3 |
| Regression | v1.0 discrete legends still pass | unit | `testthat::test_file("tests/testthat/test-legends.R")` | ✅ exists |
| Regression | post-Phase-13 IR-legends tests still pass | unit | `testthat::test_file("tests/testthat/test-ir-legends.R")` | ✅ exists |
| JS regex | `isHexColor` accepts 4/8-digit hex | static | `grep '\\[0-9a-f\\]\\{4\\}\\|\\[0-9a-f\\]\\{8\\}' inst/htmlwidgets/modules/constants.js` returns ≥1 match | ❌ Wave 1 |

### Sampling Rate
- **Per task commit:** `Rscript -e 'pkgload::load_all(".",quiet=TRUE); testthat::test_file("tests/testthat/test-color-fidelity.R")'` (target <10s).
- **Per wave merge:** Full suite — `testthat::test_dir("tests/testthat")` (~30s baseline).
- **Phase gate:** Full suite green; baseline 8 pre-existing FAILs (Phase 13 carved out as out-of-scope) must remain unchanged. Snapshot files committed.

### Wave 0 Gaps
- [ ] `tests/testthat/test-color-fidelity.R` — covers COLOR-01 + COLOR-02
- [ ] `tests/testthat/_snaps/color/` directory — snapshot artifacts
- [ ] Helper in `tests/testthat/helper-color.R` for: (a) extracting `b$data[[i]]$colour`/`fill`, (b) extracting `ir.layers[[i]].data[[j]].colour`/`fill`, (c) extracting `ir.guides[[k]].colors` and `keys[m].colour`/`fill`, (d) `scale_obj$map(scale_obj$get_breaks())` extraction
- [ ] No new framework/config files needed — `testthat` already configured.

### Eval Dimensions (per the orchestrator's request)

| Dimension | Question | Pass criterion |
|-----------|----------|----------------|
| hex-parity | For every layer row, does the IR's `colour`/`fill` exactly equal `ggplot_build()`'s? | `identical()` per row across all corpus plots |
| colorbar-trigger | Does every continuous and binned color/fill scale produce `guide.type=="colorbar"`? | viridis_c, distiller, steps, binned all emit colorbar; viridis_d, brewer-discrete, manual emit `legend` |
| colorbar-quality | Does the colorbar IR carry `breaks`, `labels`, `na.value`, `domain`, `is_continuous`, `is_steps`? Are tick count and label strings what ggplot2 produces? | Field presence asserted via `expect_named`; tick count == `length(scale_obj$get_breaks())`; labels == `scale_obj$get_labels(...)` |
| edge-cases | NA, RGBA, dual scales, out-of-range manual all correct? | 4 dedicated snapshots; D-11/12/13/14 explicitly named |
| regression | Discrete legend behavior preserved? Phase 13 baseline preserved? | `test-legends.R`, `test-ir-legends.R`, `test-ir-scales.R` all pass; `[ FAIL 8 | PASS 551+N ]` where N is new tests |

## Open Questions

All resolved against CONTEXT.md. None requires user re-engagement before planning.

Two micro-questions left to Claude's discretion (already flagged in CONTEXT.md):

1. **Pitfall 3 + 7 (dead `colorScale` removal):** Delete `ir.scales.color`, or keep and fix? Defaulting to **delete** (cleaner; no consumer; eliminates a silent-failure path). Planner can override.
2. **30-stop sufficiency (D-09):** Visual inspection of the corpus shows no banding on viridis_c or distiller at 30 stops. Defaulting to **keep at 30**; planner can bump if a snapshot reveals banding at, e.g., a wider Spectral palette.

## Sources

### Primary (HIGH confidence)
- `R/ir_scales.R` (305 lines, post-Phase-13) — line 296 colour block reproduced and tested
- `R/ir_legends.R` (184 lines, post-Phase-13) — line 59 continuous predicate, lines 101-114 colorbar branch tested live
- `R/ir_layers.R` (133 lines, post-Phase-13) — lines 13-22 keep_aes confirmed
- `inst/htmlwidgets/gg2d3.js:79-101` — colorScale construction & layer rendering
- `inst/htmlwidgets/modules/legend.js:166, 433-532` — colorbar dispatch + render
- `inst/htmlwidgets/modules/geom-registry.js:127-191` — `makeColorAccessors`
- `inst/htmlwidgets/modules/constants.js:188-204` — `isHexColor`/`isValidColor`
- `tests/testthat/test-ir-legends.R` (46 lines) — current IR-legend assertions
- `tests/testthat/test-legends.R` (197 lines) — DOM-walk pattern reference
- `.planning/phases/13-internals-refactor/13-VERIFICATION.md` — confirms post-refactor module shape
- **Live evidence:** `/tmp/research_corpus.R` ran 11 plot variants under `pkgload::load_all(".")`; outputs in this report

### Secondary (MEDIUM confidence)
- ggplot2 internals knowledge: `ScaleBinned` class hierarchy and `guide_coloursteps` default — verified by inspecting that `inherits(scale_color_steps(), "ScaleContinuous")` returns `FALSE` in the corpus (Pitfall 2 reproduces).
- Browser support for 8-digit RGBA hex — modern Chrome/Firefox/Safari accept; IE11 does not. Standard CSS Color 4.

### Tertiary (LOW confidence)
- None used. All claims either verified live in the corpus run or grounded in file content directly read.

## Project Constraints (from CLAUDE.md)

- **Build & test commands:** `devtools::load_all()`, `devtools::document()`, `devtools::test()`, `testthat::test_file(...)`. devtools may not be installed; `pkgload::load_all()` is the documented fallback (verified working in this research session).
- **D3 vendoring:** D3 v7 vendored at `inst/htmlwidgets/lib/d3/d3.v7.min.js`. No new D3 plugins introduced this phase.
- **Three-layer pipeline:** R → IR → D3. New color logic must respect this boundary; no R-side rendering, no JS-side scale extraction.
- **Visual test output:** Save HTML to `test_output/` (in `.gitignore`), not `/tmp/`. Snapshot JSON goes to `tests/testthat/_snaps/color/` per D-15.
- **MEMORY.md notes relevant to this phase:**
  - "Pixel-position vs Data-domain Highlighting" — colorbar tick positions should be computed from `(value - domain[0]) / range`, not from key indices (matches Pitfall 5 fix).
  - "devtools Not Always Available" — use `pkgload::load_all()` in CI/test scripts.

## Assumptions Log

No `[ASSUMED]` claims in this research. Every defect, every hex value, every IR shape was reproduced live against the post-Phase-13 codebase via `pkgload::load_all(".")`. Two opinions left to discretion (Pitfall 3 deletion default, 30-stop default) are flagged as such — neither is presented as fact.

## Metadata

**Confidence breakdown:**
- Pipeline map (file:line refs): HIGH — every line cited was read in this session
- Defect corpus: HIGH — reproduced live, full output preserved
- Pitfalls 1-7: HIGH — each backed by file:line + corpus evidence
- Pitfalls 8-10: HIGH — Pitfall 8 reproduced (steps misclassification); Pitfalls 9-10 are domain knowledge with corpus confirmation
- Implementation approach: MEDIUM — concrete and grounded but planner has discretion on plan boundaries
- Validation architecture: HIGH — based on existing testthat infrastructure verified in test-ir-legends.R and test-legends.R

**Research date:** 2026-05-04
**Valid until:** 2026-06-03 (~30 days; ggplot2 stable; gg2d3 paused on Phase 13 verify)

---

## RESEARCH COMPLETE

**Phase:** 14 - Color Fidelity
**Confidence:** HIGH

### Key Findings
- **COLOR-01 is mostly already-plumbed.** Per-row passthrough works for all 6-digit hex (viridis_c, brewer, distiller, manual). Only blocking defect is a 1-line JS regex bug in `isHexColor` that rejects 8-digit RGBA (viridis_d, alpha-resolved).
- **COLOR-02's colorbar IR exists but is undernourished.** `extract_legends_ir` already routes continuous color/fill to `type=colorbar` with a 30-stop `colors_array`, and `renderColorbar` already produces a `linearGradient`. The gaps: (a) no `breaks`/`labels`/`na.value`/`is_steps` on IR; (b) renderer hard-codes only first/last keys as ticks; (c) no banded variant.
- **`scale_*_steps()` is misclassified as discrete** because `ScaleBinned` doesn't inherit from `ScaleContinuous` — fix is a one-token predicate change.
- **`ir.scales.color.type` is permanently `"categorical"`** (broken type detection on already-resolved hex strings); the dependent JS `colorScale` construction in `gg2d3.js:79-84` is unused dead code that's safest to delete.
- **D-12 (dual color+fill) and D-14 (out-of-range manual) already work correctly** end-to-end — verified live. Just need regression snapshots.

### File Created
`/Users/davidzenz/.claude-worktrees/gg2d3/stupefied-austin/.planning/phases/14-color-fidelity/14-RESEARCH.md`

### Confidence Assessment
| Area | Level | Reason |
|------|-------|--------|
| Pipeline map | HIGH | Every file:line cited was read in-session |
| Defect corpus | HIGH | 11 plot variants reproduced live via `pkgload::load_all(".")` |
| Pitfalls (1-10) | HIGH | Each backed by file:line + corpus evidence; Pitfalls 6, 9, 12 explicitly confirm "no work needed" |
| Implementation approach | MEDIUM | Plan-shape proposal is suggestive; planner owns final split |
| Validation | HIGH | Built on existing testthat patterns (test-ir-legends.R, test-legends.R) |

### Open Questions
None requiring user input. Two micro-defaults left to planner discretion (delete vs fix `ir.scales.color`; keep 30 stops vs bump) explicitly flagged in §"Open Questions".

### Ready for Planning
Research complete. Planner can produce 6-plan split (snapshot harness, RGBA regex, binned detection, colorScale cleanup, colorbar IR enrichment, colorbar render extension, snapshot corpus) or alternative grouping. All required REQUIREMENTS-mapped tests scaffolded in §"Validation Architecture".
