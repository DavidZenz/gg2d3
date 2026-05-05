---
phase: 14
plan: 06
type: execute
wave: 4
depends_on: ["14-05"]
files_modified:
  - inst/htmlwidgets/modules/legend.js
  - tests/testthat/test-color-fidelity.R
autonomous: true
requirements: [COLOR-02]
tags: [js, d3, legend, colorbar, banded, horizontal]

must_haves:
  truths:
    - "renderColorbar emits one tick per element in guide.breaks (not just first/last)"
    - "Tick positions are computed against guide.domain, not against guide.keys.value"
    - "Tick labels come from guide.labels (matched index)"
    - "When guide.is_steps==TRUE, the gradient is banded (2 stops per bin) using guide.bin_colors and guide.breaks"
    - "When guide.is_steps==FALSE, the gradient retains the existing 30-stop smooth interpolation"
    - "When guide.orientation=='horizontal', the bar is wider than tall, gradient runs left-to-right, ticks below, title above (D-10)"
    - "When guide.orientation=='vertical' (default), the existing vertical layout is preserved"
    - "Smooth and banded paths share the same <linearGradient> primitive and tick rendering"
  artifacts:
    - path: "inst/htmlwidgets/modules/legend.js"
      provides: "renderColorbar honors breaks/labels/domain/orientation; branches smooth vs banded; branches vertical vs horizontal"
      contains: "is_steps"
  key_links:
    - from: "inst/htmlwidgets/modules/legend.js::renderColorbar"
      to: "guide.breaks / guide.labels / guide.domain / guide.orientation (from plan 14-05 IR)"
      via: "consume IR fields verbatim; no JS-side break or orientation derivation"
      pattern: "guide\\.breaks|guide\\.labels|guide\\.domain|guide\\.orientation"
---

<objective>
Fix Pitfalls 5 and 8 from the research, plus implement D-10 horizontal layout.

**Pitfall 5:** `inst/htmlwidgets/modules/legend.js:495-528` (`renderColorbar`) hardcodes ticks to `guide.keys[0]` and `guide.keys[last]`, dropping all intermediate ticks; tick positions are computed via `parseFloat(key.value)` which only matches the scale domain when `breaks` are domain endpoints.

**Pitfall 8:** Same renderer always emits a smooth gradient; for `is_steps=TRUE` (D-06) we need a banded gradient with hard color stops at bin boundaries.

**D-10 (horizontal layout):** Same renderer always emits a vertical bar. When `legend.position` is `"top"` or `"bottom"`, plan 14-05 sets `guide.orientation = "horizontal"` and the renderer must:
- swap gradient axes from `(x1=0%, x2=0%, y1=100%, y2=0%)` to `(x1=0%, x2=100%, y1=0%, y2=0%)`
- reorient the bar (wider than tall, e.g. `barWidth = 5*keySize`, `barHeight = keySize`)
- place ticks **below** the bar (not to the right)
- place the title **above** the bar (no change vs vertical, but visually centered)

This plan rewrites the gradient-stop generation, tick rendering, and orientation branching inside `renderColorbar`. After plan 14-05, the IR carries `breaks`, `labels`, `domain`, `is_steps`, `bin_colors`, and `orientation` — the renderer consumes them verbatim, no break logic or orientation derivation on the JS side.

Output:
- `inst/htmlwidgets/modules/legend.js::renderColorbar` rewritten (~140 lines net change inside one function).
- `tests/testthat/test-color-fidelity.R` — flip 2 skip-pending blocks (renderColorbar tick logic + renderColorbar horizontal branch). Static-grep checks per research R2.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<inputs>
@.planning/phases/14-color-fidelity/14-CONTEXT.md
@.planning/phases/14-color-fidelity/14-RESEARCH.md
@inst/htmlwidgets/modules/legend.js
@tests/testthat/test-color-fidelity.R
</inputs>

<outputs>
- `inst/htmlwidgets/modules/legend.js` — `renderColorbar` body (~lines 433-532) rewritten with smooth/banded × vertical/horizontal branches.
- `tests/testthat/test-color-fidelity.R` — 2 blocks flipped (~40 lines).
</outputs>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: TEST — RED static assertions that renderColorbar consumes guide.breaks/labels/domain, branches on is_steps, and branches on orientation</name>
  <files>tests/testthat/test-color-fidelity.R</files>
  <behavior>
    - The function body of renderColorbar references guide.breaks, guide.labels, and guide.domain.
    - The function body branches on guide.is_steps.
    - The function body branches on guide.orientation (string compare against "horizontal").
    - The horizontal branch sets gradient `x2: "100%"` and either `y1=y2=0%` or omits the vertical y-coords.
    - The endKeys-only slice (`guide.keys[0]` / `guide.keys[guide.keys.length - 1]` for tick rendering) is gone.
  </behavior>
  <action>
**Replace block 1 (`renderColorbar tick logic uses breaks`):**

```r
test_that("renderColorbar tick logic uses breaks (not first/last keys)", {
  src <- paste(readLines("../../inst/htmlwidgets/modules/legend.js", warn = FALSE), collapse = "\n")
  fn <- regmatches(src, regexpr("function renderColorbar[\\s\\S]*?\\n  \\}\\n", src, perl = TRUE))
  expect_length(fn, 1L)
  # Must consume IR fields rather than reinventing them.
  expect_match(fn, "guide\\.breaks")
  expect_match(fn, "guide\\.labels")
  expect_match(fn, "guide\\.domain")
  expect_match(fn, "guide\\.is_steps|guide\\.bin_colors")
  # The endKeys hardcode must be gone.
  expect_false(grepl("guide\\.keys\\[guide\\.keys\\.length - 1\\]", fn))
})
```

**Replace block 2 (`renderColorbar branches on guide.orientation for horizontal layout`):**

```r
test_that("renderColorbar branches on guide.orientation for horizontal layout", {
  src <- paste(readLines("../../inst/htmlwidgets/modules/legend.js", warn = FALSE), collapse = "\n")
  fn <- regmatches(src, regexpr("function renderColorbar[\\s\\S]*?\\n  \\}\\n", src, perl = TRUE))
  expect_length(fn, 1L)
  # Must consult guide.orientation.
  expect_match(fn, "guide\\.orientation")
  # Must compare against the literal "horizontal" — no other source of "horizontal" expected in renderColorbar.
  expect_match(fn, "\"horizontal\"")
  # Horizontal gradient must set x2 to "100%" (smooth) — present somewhere in the function.
  expect_match(fn, "x2\"?,?\\s*[\"']100%[\"']")
})
```

Run: both assertions fail RED.

Commit:
```
git add tests/testthat/test-color-fidelity.R
git commit -m "test(14-06): RED — renderColorbar uses breaks/labels/domain + branches is_steps + orientation"
```
  </action>
  <verify>
    <automated>Rscript -e 'pkgload::load_all(".",quiet=TRUE); res <- testthat::test_file("tests/testthat/test-color-fidelity.R", reporter="silent"); failed <- sum(vapply(res, function(r) sum(vapply(r$results, function(x) inherits(x, "expectation_failure"), logical(1))), integer(1))); stopifnot(failed >= 2)'</automated>
  </verify>
  <done>2 RED static assertions in test-color-fidelity.R; running them produces ≥2 failures.</done>
</task>

<task type="auto" tdd="true">
  <name>Task 2: IMPL — rewrite renderColorbar to honor breaks/labels/domain, branch smooth vs banded, AND branch vertical vs horizontal</name>
  <files>inst/htmlwidgets/modules/legend.js</files>
  <action>
Replace the body of `renderColorbar(svg, guide, x, y, theme)` (currently lines ~433-532). Keep the function signature and the title-rendering block (lines 444-457) as a starting point but make title placement orientation-aware.

New body skeleton (~140 lines):

```js
function renderColorbar(svg, guide, x, y, theme) {
  const defaults = getThemeDefaults(theme);
  const convertColor = window.gg2d3.scales.convertColor;

  const g = svg.append("g")
    .attr("class", "gg2d3-colorbar")
    .attr("transform", `translate(${x}, ${y})`);

  // ----- Orientation branch (D-10) -------------------------------------------
  const isHorizontal = guide.orientation === "horizontal";

  // Bar dimensions (vertical: tall+narrow; horizontal: wide+short).
  const barWidth  = isHorizontal ? 5 * defaults.keySize : defaults.keySize;
  const barHeight = isHorizontal ? defaults.keySize : 5 * defaults.keySize;

  let currentY = defaults.margin;
  const barX = defaults.margin;

  // Title (always above the bar).
  if (guide.title) {
    g.append("text")
      .attr("class", "colorbar-title")
      .attr("x", defaults.margin)
      .attr("y", currentY + defaults.titleSize * 0.8)
      .attr("fill", defaults.titleColour)
      .style("font-size", `${defaults.titleSize}px`)
      .style("font-weight", "normal")
      .style("font-family", "sans-serif")
      .text(guide.title);
    currentY += defaults.titleSize + defaults.titleSpacing;
  }
  const barY = currentY;

  // ----- Gradient axis depends on orientation --------------------------------
  // Vertical: bottom (domain[0]) -> top (domain[1]) — y goes 100% -> 0%.
  // Horizontal: left (domain[0]) -> right (domain[1]) — x goes 0% -> 100%.
  const gradientId = `legend-grad-${Math.random().toString(36).substr(2, 9)}`;
  const defs = svg.append("defs");
  const gradient = defs.append("linearGradient")
    .attr("id", gradientId)
    .attr("x1", isHorizontal ? "0%"   : "0%")
    .attr("x2", isHorizontal ? "100%" : "0%")
    .attr("y1", isHorizontal ? "0%"   : "100%")
    .attr("y2", isHorizontal ? "0%"   : "0%");

  const domain = Array.isArray(guide.domain) && guide.domain.length === 2 ? guide.domain : [0, 1];
  const [d0, d1] = domain;
  const range = (d1 - d0) || 1;

  const breaks = Array.isArray(guide.breaks) ? guide.breaks : [];
  const labels = Array.isArray(guide.labels) ? guide.labels : breaks.map(String);

  if (guide.is_steps && Array.isArray(guide.bin_colors) && breaks.length >= 2) {
    // Banded: two stops per bin sharing one color (D-06).
    // Defensive invariant — bin_colors must have exactly breaks.length - 1 entries.
    console.assert(
      guide.bin_colors.length === breaks.length - 1,
      "renderColorbar: bin_colors length must equal breaks.length - 1, got",
      guide.bin_colors.length, "vs", breaks.length - 1
    );
    for (let i = 0; i < guide.bin_colors.length; i++) {
      const lo = breaks[i];
      const hi = breaks[i + 1];
      if (lo == null || hi == null) continue;
      const colorHex = convertColor(guide.bin_colors[i]);
      const offsetLo = ((lo - d0) / range) * 100;
      const offsetHi = ((hi - d0) / range) * 100;
      gradient.append("stop").attr("offset", `${offsetLo}%`).attr("stop-color", colorHex);
      gradient.append("stop").attr("offset", `${offsetHi}%`).attr("stop-color", colorHex);
    }
  } else {
    // Smooth: existing 30-stop sample (Pitfall 4 keeps default).
    const colors = guide.colors || (guide.keys ? guide.keys.map(k => k.colour || k.fill || "#4D4D4D") : ["#4D4D4D"]);
    colors.forEach((color, idx) => {
      const offset = colors.length > 1 ? (idx / (colors.length - 1)) * 100 : 0;
      gradient.append("stop")
        .attr("offset", `${offset}%`)
        .attr("stop-color", convertColor(color));
    });
  }

  g.append("rect")
    .attr("class", "colorbar-gradient")
    .attr("x", barX)
    .attr("y", barY)
    .attr("width", barWidth)
    .attr("height", barHeight)
    .attr("fill", `url(#${gradientId})`)
    .attr("stroke", convertColor("grey50"))
    .attr("stroke-width", 0.5);

  // ----- Ticks: one per guide.breaks element (Pitfall 5 fix) -----------------
  // Vertical: domain[0] at the bottom; ticks/labels to the right.
  // Horizontal: domain[0] at the left; ticks/labels below the bar.
  breaks.forEach((b, i) => {
    if (b == null || !isFinite(b)) return;
    const proportion = (b - d0) / range;

    if (isHorizontal) {
      const tickX = barX + proportion * barWidth;
      g.append("line")
        .attr("class", "colorbar-tick")
        .attr("x1", tickX)
        .attr("x2", tickX)
        .attr("y1", barY + barHeight)
        .attr("y2", barY + barHeight + 3)
        .attr("stroke", defaults.textColour)
        .attr("stroke-width", 0.5);
      g.append("text")
        .attr("class", "colorbar-label")
        .attr("x", tickX)
        .attr("y", barY + barHeight + 5 + defaults.textSize)
        .attr("text-anchor", "middle")
        .attr("fill", defaults.textColour)
        .style("font-size", `${defaults.textSize}px`)
        .style("font-family", "sans-serif")
        .text(String(labels[i] != null ? labels[i] : b));
    } else {
      // Vertical: y inverted so domain[0] at bottom.
      const tickY = barY + barHeight - (proportion * barHeight);
      g.append("line")
        .attr("class", "colorbar-tick")
        .attr("x1", barX + barWidth)
        .attr("x2", barX + barWidth + 3)
        .attr("y1", tickY)
        .attr("y2", tickY)
        .attr("stroke", defaults.textColour)
        .attr("stroke-width", 0.5);
      g.append("text")
        .attr("class", "colorbar-label")
        .attr("x", barX + barWidth + 5)
        .attr("y", tickY)
        .attr("dy", "0.35em")
        .attr("fill", defaults.textColour)
        .style("font-size", `${defaults.textSize}px`)
        .style("font-family", "sans-serif")
        .text(String(labels[i] != null ? labels[i] : b));
    }
  });

  return g;
}
```

Key changes vs original:
- Tick loop walks `guide.breaks` instead of `[guide.keys[0], guide.keys[last]]`.
- Tick proportion uses `(break - domain[0]) / (domain[1] - domain[0])`, not `parseFloat(key.value)` math.
- Tick labels come from `guide.labels[i]` (parallel index).
- New banded branch handles `guide.is_steps && guide.bin_colors`, with a `console.assert` invariant on length.
- New horizontal branch (D-10): swapped gradient axes, swapped bar dimensions, ticks-below-bar layout, centered text-anchor.
- Smooth branch unchanged behavior; just wrapped in the else.

Run the suite: both RED tests from Task 1 must turn GREEN.

Commit:
```
git add inst/htmlwidgets/modules/legend.js
git commit -m "feat(14-06): renderColorbar honors guide.breaks/labels/domain + is_steps + orientation (Pitfalls 5+8 + D-10)"
```
  </action>
  <verify>
    <automated>Rscript -e 'pkgload::load_all(".",quiet=TRUE); testthat::test_dir("tests/testthat")'</automated>
  </verify>
  <done>renderColorbar consumes guide.breaks/labels/domain, branches on is_steps/bin_colors, branches on orientation; the endKeys hardcode is gone; static-grep tests GREEN; phase-13 baseline FAILs unchanged.</done>
</task>

</tasks>

<exit_criteria>
- `grep -E 'guide\\.breaks|guide\\.labels|guide\\.domain' inst/htmlwidgets/modules/legend.js | wc -l` ≥ 3.
- `grep 'guide.keys\[guide.keys.length - 1\]' inst/htmlwidgets/modules/legend.js` returns no match.
- `grep 'guide\\.is_steps' inst/htmlwidgets/modules/legend.js` returns ≥1 match.
- `grep 'guide\\.orientation' inst/htmlwidgets/modules/legend.js` returns ≥1 match.
- `grep '"horizontal"' inst/htmlwidgets/modules/legend.js` returns ≥1 match.
- `grep 'console\\.assert' inst/htmlwidgets/modules/legend.js` returns ≥1 match (banded invariant).
- The 2 static tests in `test-color-fidelity.R` are GREEN.
- Phase-13 baseline FAILs unchanged.
- Two atomic commits (RED then GREEN).
</exit_criteria>

<threat_model>
No threat surface — package internals only. SVG renderer rewrite consuming a deterministic IR.
</threat_model>

<output>
After completion, create `.planning/phases/14-color-fidelity/14-06-SUMMARY.md` listing the rewritten function, the new tick-loop logic, the orientation branch summary, and a one-line note that plan 14-07 will exercise both the smooth/banded and vertical/horizontal branches via the snapshot corpus + manual checkpoints.
</output>
