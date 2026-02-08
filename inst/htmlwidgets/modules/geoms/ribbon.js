/**
 * gg2d3 Ribbon Geom Renderer
 *
 * Renders geom_ribbon as filled SVG areas using d3.area() path generator.
 * Handles:
 * - ymin/ymax bands from data
 * - Group aesthetic for multiple ribbons
 * - coord_flip support
 * - Missing data creates gaps (via .defined())
 *
 * Key difference from area: Ribbon always uses ymin/ymax from data,
 * never a fixed baseline.
 *
 * @module gg2d3.geoms.ribbon
 */

(function() {
  'use strict';

  /**
   * Render ribbon geom as SVG paths with filled bands.
   *
   * Ribbon fills between ymin and ymax values from data.
   * Common use case: confidence bands, ranges.
   *
   * @param {Object} layer - Layer object from IR
   * @param {d3.Selection} g - D3 plot group selection
   * @param {Function} xScale - D3 x scale
   * @param {Function} yScale - D3 y scale
   * @param {Object} options - Rendering options (flip, plotHeight)
   * @returns {number} Number of ribbons drawn
   */
  function renderRibbon(layer, g, xScale, yScale, options) {
    // Get utilities
    const val = window.gg2d3.helpers.val;
    const num = window.gg2d3.helpers.num;
    const asRows = window.gg2d3.helpers.asRows;
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

    let ribbonsDrawn = 0;

    grouped.forEach(arr => {
      // Map to {x, ymin, ymax, d} objects
      let pts = arr
        .map(d => {
          const xVal = isXBand ? val(get(d, aes.x)) : num(get(d, aes.x));
          const yminVal = isYBand ? val(get(d, "ymin")) : num(get(d, "ymin"));
          const ymaxVal = isYBand ? val(get(d, "ymax")) : num(get(d, "ymax"));
          return { x: xVal, ymin: yminVal, ymax: ymaxVal, d };
        })
        .filter(p => p.x != null && p.ymin != null && p.ymax != null);

      // Sort by x if not band scale
      if (!isXBand) {
        pts = pts.sort((a, b) => d3.ascending(a.x, b.x));
      }

      if (pts.length >= 2) {
        const xOff = isXBand ? xScale.bandwidth() / 2 : 0;

        // Create area generator
        const area = flip
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

        const firstPoint = pts[0].d;

        g.append("path")
          .attr("d", area(pts))
          .attr("fill", fillColor(firstPoint))
          .attr("stroke", "none")
          .attr("opacity", opacity(firstPoint));

        ribbonsDrawn += 1;
      }
    });

    return ribbonsDrawn;
  }

  // Register with geom registry
  window.gg2d3.geomRegistry.register(['ribbon'], renderRibbon);

})();
