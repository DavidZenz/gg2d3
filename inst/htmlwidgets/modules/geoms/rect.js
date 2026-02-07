/**
 * gg2d3 Rect/Tile Geom Renderer
 *
 * Renders geom_rect and geom_tile as SVG rectangles.
 * Handles:
 * - xmin/xmax, ymin/ymax aesthetics
 * - Continuous and categorical scales
 * - Bandwidth for categorical scales
 * - Fill and opacity aesthetics
 *
 * @module gg2d3.geoms.rect
 */

(function() {
  'use strict';

  /**
   * Render rect/tile geom as SVG rectangles.
   *
   * Uses xmin/xmax/ymin/ymax aesthetics to define rectangle bounds.
   * For band scales, uses bandwidth() for dimension.
   *
   * @param {Object} layer - Layer object from IR
   * @param {d3.Selection} g - D3 plot group selection
   * @param {Function} xScale - D3 x scale
   * @param {Function} yScale - D3 y scale
   * @param {Object} options - Rendering options
   * @returns {number} Number of rectangles drawn
   */
  function renderRect(layer, g, xScale, yScale, options) {
    // Get utilities
    const val = window.gg2d3.helpers.val;
    const num = window.gg2d3.helpers.num;
    const asRows = window.gg2d3.helpers.asRows;
    const { fillColor, opacity } =
      window.gg2d3.geomRegistry.makeColorAccessors(layer, options);

    const aes = layer.aes || {};
    const dat = asRows(layer.data);

    // Helper to get column value from row
    const get = (d, k) => (k && d != null) ? d[k] : null;

    // Filter valid rectangles (must have all 4 bounds)
    const rects = dat.filter(d =>
      get(d, aes.xmin) != null && get(d, aes.xmax) != null &&
      get(d, aes.ymin) != null && get(d, aes.ymax) != null
    );

    const isXBand = typeof xScale.bandwidth === "function";
    const isYBand = typeof yScale.bandwidth === "function";

    // Render rectangles
    const sel = g.append("g").selectAll("rect").data(rects);
    sel.enter().append("rect")
      .attr("x", d => {
        const xmin = isXBand ? val(get(d, aes.xmin)) : num(get(d, aes.xmin));
        return xScale(xmin);
      })
      .attr("y", d => {
        const ymax = isYBand ? val(get(d, aes.ymax)) : num(get(d, aes.ymax));
        return yScale(ymax);
      })
      .attr("width", d => {
        if (isXBand) return xScale.bandwidth();
        const x1 = xScale(num(get(d, aes.xmin)));
        const x2 = xScale(num(get(d, aes.xmax)));
        return Math.abs(x2 - x1);
      })
      .attr("height", d => {
        if (isYBand) return yScale.bandwidth();
        const y1 = yScale(num(get(d, aes.ymin)));
        const y2 = yScale(num(get(d, aes.ymax)));
        return Math.abs(y2 - y1);
      })
      .attr("fill", d => fillColor(d))
      .attr("opacity", d => opacity(d));

    return rects.length;
  }

  // Register with geom registry (both rect and tile use same renderer)
  window.gg2d3.geomRegistry.register(['rect', 'tile'], renderRect);

})();
