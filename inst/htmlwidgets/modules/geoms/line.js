/**
 * gg2d3 Line/Path Geom Renderer
 *
 * Renders geom_line and geom_path as SVG paths.
 * Handles:
 * - Group aesthetic for multiple lines
 * - Sorting by x for geom_line (but not geom_path)
 * - Linewidth with mm->px conversion
 * - Continuous and categorical scales
 *
 * @module gg2d3.geoms.line
 */

(function() {
  'use strict';

  /**
   * Render line/path geom as SVG paths.
   *
   * Key difference:
   * - geom_line: sorts points by x (for continuous x)
   * - geom_path: preserves data order
   *
   * Both group by 'group' aesthetic for multiple lines.
   *
   * @param {Object} layer - Layer object from IR
   * @param {d3.Selection} g - D3 plot group selection
   * @param {Function} xScale - D3 x scale
   * @param {Function} yScale - D3 y scale
   * @param {Object} options - Rendering options
   * @returns {number} Number of lines drawn
   */
  function renderLine(layer, g, xScale, yScale, options) {
    // Get utilities
    const val = window.gg2d3.helpers.val;
    const num = window.gg2d3.helpers.num;
    const asRows = window.gg2d3.helpers.asRows;
    const mmToPxLinewidth = window.gg2d3.constants.mmToPxLinewidth;
    const { strokeColor, opacity } =
      window.gg2d3.geomRegistry.makeColorAccessors(layer, options);

    const aes = layer.aes || {};
    const dat = asRows(layer.data);

    // Helper to get column value from row
    const get = (d, k) => (k && d != null) ? d[k] : null;

    const isXBand = typeof xScale.bandwidth === "function";
    const isYBand = typeof yScale.bandwidth === "function";

    // Group by 'group' aesthetic (default to single group)
    const grouped = d3.group(dat, d => val(get(d, "group")) ?? 1);

    let linesDrawn = 0;

    grouped.forEach(arr => {
      let pts = arr
        .map(d => {
          const xVal = isXBand ? val(get(d, aes.x)) : num(get(d, aes.x));
          const yVal = isYBand ? val(get(d, aes.y)) : num(get(d, aes.y));
          return { x: xVal, y: yVal, d };
        })
        .filter(p => p.x != null && p.y != null);

      // Only sort for geom_line (and only if x is numeric)
      if (layer.geom === "line" && !isXBand) {
        pts = pts.sort((a, b) => d3.ascending(a.x, b.x));
      }

      if (pts.length >= 2) {
        const line = d3.line().x(p => xScale(p.x)).y(p => yScale(p.y));
        const firstPoint = pts[0].d;
        const linewidthVal = val(get(firstPoint, "linewidth"));
        // ggplot2 default linewidth: 0.5mm = 1.89px
        const strokeWidth = linewidthVal != null ? mmToPxLinewidth(linewidthVal) : 1.89;

        g.append("path")
          .attr("d", line(pts))
          .attr("fill", "none")
          .attr("stroke", strokeColor(firstPoint))
          .attr("stroke-width", strokeWidth)
          .attr("opacity", opacity(firstPoint));

        linesDrawn += 1;
      }
    });

    return linesDrawn;
  }

  // Register with geom registry (both line and path use same renderer)
  window.gg2d3.geomRegistry.register(['line', 'path'], renderLine);

})();
