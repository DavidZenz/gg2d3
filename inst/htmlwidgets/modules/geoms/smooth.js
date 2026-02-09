/**
 * gg2d3 Smooth Geom Renderer
 *
 * Renders geom_smooth as fitted line + confidence ribbon using d3.line() and d3.area().
 * Handles:
 * - Fitted line (solid curve through predicted values)
 * - Confidence interval ribbon (semi-transparent band from ymin to ymax)
 * - se = FALSE mode (line only, no ribbon)
 * - Group aesthetic for multiple smooth curves
 * - coord_flip support
 * - Missing data creates gaps (via .defined())
 *
 * GeomSmooth draws TWO visual elements: ribbon (behind) + line (in front).
 * Previously mapped to "path" (line only), now has dedicated renderer for both.
 *
 * @module gg2d3.geoms.smooth
 */

(function() {
  'use strict';

  /**
   * Render smooth geom as SVG paths with confidence ribbon and fitted line.
   *
   * Draws confidence ribbon first (if ymin/ymax present), then fitted line on top.
   * Ribbon is semi-transparent (default: grey60, alpha 0.4).
   * Line is fully opaque (default: blue #3366FF).
   *
   * @param {Object} layer - Layer object from IR
   * @param {d3.Selection} g - D3 plot group selection
   * @param {Function} xScale - D3 x scale
   * @param {Function} yScale - D3 y scale
   * @param {Object} options - Rendering options (flip, plotHeight)
   * @returns {number} Number of smooth curves drawn
   */
  function renderSmooth(layer, g, xScale, yScale, options) {
    // Get utilities
    const val = window.gg2d3.helpers.val;
    const num = window.gg2d3.helpers.num;
    const asRows = window.gg2d3.helpers.asRows;
    const mmToPxLinewidth = window.gg2d3.constants.mmToPxLinewidth;
    const { fillColor, strokeColor, opacity } =
      window.gg2d3.geomRegistry.makeColorAccessors(layer, options);

    const aes = layer.aes || {};
    const dat = asRows(layer.data);

    // Helper to get column value from row
    const get = (d, k) => (k && d != null) ? d[k] : null;

    const flip = !!options.flip;
    const isXBand = typeof xScale.bandwidth === "function";
    const isYBand = typeof yScale.bandwidth === "function";

    // Group by 'group' aesthetic (default to single group)
    const grouped = d3.group(dat, d => val(get(d, "group")) ?? 1);

    let smoothsDrawn = 0;

    grouped.forEach(arr => {
      // Map to {x, y, ymin, ymax, d} objects
      let pts = arr
        .map(d => {
          const xVal = isXBand ? val(get(d, aes.x)) : num(get(d, aes.x));
          const yVal = isYBand ? val(get(d, aes.y)) : num(get(d, aes.y));
          const yminVal = num(get(d, "ymin")); // May be null if se = FALSE
          const ymaxVal = num(get(d, "ymax")); // May be null if se = FALSE
          return { x: xVal, y: yVal, ymin: yminVal, ymax: ymaxVal, d };
        })
        .filter(p => p.x != null && p.y != null);

      // Sort by x (smooth data should already be sorted, but ensure it)
      if (!isXBand) {
        pts = pts.sort((a, b) => d3.ascending(a.x, b.x));
      }

      if (pts.length >= 2) {
        const xOff = isXBand ? xScale.bandwidth() / 2 : 0;
        const firstPoint = pts[0].d;

        // Check if confidence band data exists (se = FALSE disables CI)
        const hasCIData = pts.some(p => p.ymin != null && p.ymax != null);

        // Step A: Render confidence ribbon (if present)
        if (hasCIData) {
          const ribbonArea = flip
            ? d3.area()
                .y(p => xScale(p.x) + xOff)
                .x0(p => yScale(p.ymin))
                .x1(p => yScale(p.ymax))
                .defined(p => p.x != null && p.ymin != null && p.ymax != null)
            : d3.area()
                .x(p => xScale(p.x) + xOff)
                .y0(p => yScale(p.ymin))
                .y1(p => yScale(p.ymax))
                .defined(p => p.x != null && p.ymin != null && p.ymax != null);

          // Ribbon styling: use fillColor, default grey60 with alpha 0.4
          g.append("path")
            .attr("d", ribbonArea(pts))
            .attr("fill", fillColor(firstPoint))
            .attr("stroke", "none")
            .attr("opacity", opacity(firstPoint));
        }

        // Step B: Render fitted line (always)
        const line = flip
          ? d3.line()
              .x(p => yScale(p.y))
              .y(p => xScale(p.x) + xOff)
              .defined(p => p.x != null && p.y != null)
          : d3.line()
              .x(p => xScale(p.x) + xOff)
              .y(p => yScale(p.y))
              .defined(p => p.x != null && p.y != null);

        const linewidthVal = val(get(firstPoint, "linewidth"));
        // ggplot2 default linewidth for smooth: 1mm = 3.78px (thicker than regular lines)
        const strokeWidth = linewidthVal != null ? mmToPxLinewidth(linewidthVal) : 3.78;

        // Line styling: use strokeColor, default blue #3366FF, fully opaque
        g.append("path")
          .attr("d", line(pts))
          .attr("fill", "none")
          .attr("stroke", strokeColor(firstPoint))
          .attr("stroke-width", strokeWidth)
          .attr("opacity", 1.0); // Line is always fully opaque

        smoothsDrawn += 1;
      }
    });

    return smoothsDrawn;
  }

  // Register with geom registry
  window.gg2d3.geomRegistry.register(['smooth'], renderSmooth);

})();
