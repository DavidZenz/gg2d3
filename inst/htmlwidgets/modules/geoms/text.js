/**
 * gg2d3 Text Geom Renderer
 *
 * Renders geom_text as SVG text elements.
 * Handles:
 * - label aesthetic for text content
 * - x/y positioning with continuous and categorical scales
 * - Color and opacity aesthetics
 * - Fixed font size (10px default)
 *
 * @module gg2d3.geoms.text
 */

(function() {
  'use strict';

  /**
   * Render text geom as SVG text elements.
   *
   * Uses label aesthetic for text content.
   * Positioning with dominant-baseline and text-anchor (centered).
   *
   * @param {Object} layer - Layer object from IR
   * @param {d3.Selection} g - D3 plot group selection
   * @param {Function} xScale - D3 x scale
   * @param {Function} yScale - D3 y scale
   * @param {Object} options - Rendering options
   * @returns {number} Number of text elements drawn
   */
  function renderText(layer, g, xScale, yScale, options) {
    // Get utilities
    const val = window.gg2d3.helpers.val;
    const num = window.gg2d3.helpers.num;
    const asRows = window.gg2d3.helpers.asRows;
    const { strokeColor, opacity } =
      window.gg2d3.geomRegistry.makeColorAccessors(layer, options);

    const aes = layer.aes || {};
    const dat = asRows(layer.data);

    // Helper to get column value from row
    const get = (d, k) => (k && d != null) ? d[k] : null;

    const isXBand = typeof xScale.bandwidth === "function";
    const isYBand = typeof yScale.bandwidth === "function";

    // Filter valid text elements
    const txt = dat.filter(d => {
      const xVal = isXBand ? val(get(d, aes.x)) : num(get(d, aes.x));
      const yVal = isYBand ? val(get(d, aes.y)) : num(get(d, aes.y));
      return xVal != null && yVal != null;
    });

    // Render text elements
    const sel = g.append("g").selectAll("text").data(txt);
    sel.enter().append("text")
      .attr("x", d => {
        const xVal = isXBand ? val(get(d, aes.x)) : num(get(d, aes.x));
        return xScale(xVal);
      })
      .attr("y", d => {
        const yVal = isYBand ? val(get(d, aes.y)) : num(get(d, aes.y));
        return yScale(yVal);
      })
      .attr("dominant-baseline", "middle")
      .attr("text-anchor", "middle")
      .text(d => val(get(d, aes.label)))
      .attr("fill", d => strokeColor(d))
      .attr("opacity", d => opacity(d))
      .style("font-size", "10px");

    return txt.length;
  }

  // Register with geom registry
  window.gg2d3.geomRegistry.register('text', renderText);

})();
