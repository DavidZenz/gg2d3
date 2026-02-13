/**
 * gg2d3 Point Geom Renderer
 *
 * Renders geom_point as SVG circles.
 * Handles:
 * - Continuous and categorical scales
 * - Size aesthetic with mm->px conversion
 * - Color/fill aesthetics with ggplot2 fill=NA behavior
 * - Stroke width
 *
 * @module gg2d3.geoms.point
 */

(function() {
  'use strict';

  /**
   * Render point geom as SVG circles.
   *
   * ggplot2 behavior:
   * - If fill is NA, use colour for solid points (no stroke)
   * - If fill is set, use fill for interior and colour for stroke
   * - Size is in mm (diameter), converted to pixel radius
   *
   * @param {Object} layer - Layer object from IR
   * @param {d3.Selection} g - D3 plot group selection
   * @param {Function} xScale - D3 x scale
   * @param {Function} yScale - D3 y scale
   * @param {Object} options - Rendering options
   * @returns {number} Number of points drawn
   */
  function renderPoint(layer, g, xScale, yScale, options) {
    // Get utilities
    const val = window.gg2d3.helpers.val;
    const num = window.gg2d3.helpers.num;
    const asRows = window.gg2d3.helpers.asRows;
    const mmToPxRadius = window.gg2d3.constants.mmToPxRadius;
    const { strokeColor, fillColor, opacity } =
      window.gg2d3.geomRegistry.makeColorAccessors(layer, options);

    const aes = layer.aes || {};
    const params = layer.params || {};
    const dat = asRows(layer.data);

    // Helper to get column value from row
    const get = (d, k) => (k && d != null) ? d[k] : null;

    const isXBand = typeof xScale.bandwidth === "function";
    const isYBand = typeof yScale.bandwidth === "function";
    const flip = !!options.flip;

    // Filter valid points
    const pts = dat.filter(d => {
      const xVal = isXBand ? val(get(d, aes.x)) : num(get(d, aes.x));
      const yVal = isYBand ? val(get(d, aes.y)) : num(get(d, aes.y));
      return xVal != null && yVal != null;
    });

    const defaultSize = params.size || 1.5;

    // Helper: get pixel position from scale + value, centering for band scales
    function scalePos(scale, v, isBand) {
      return isBand ? scale(v) + scale.bandwidth() / 2 : scale(v);
    }

    // Render circles
    // When flip: cx uses yScale(yVal) [horizontal], cy uses xScale(xVal) [vertical]
    const sel = g.append("g").selectAll("circle").data(pts);
    sel.enter().append("circle")
      .attr("class", "geom-point")
      .attr("cx", d => {
        if (flip) {
          const yVal = isYBand ? val(get(d, aes.y)) : num(get(d, aes.y));
          return scalePos(yScale, yVal, isYBand);
        }
        const xVal = isXBand ? val(get(d, aes.x)) : num(get(d, aes.x));
        return scalePos(xScale, xVal, isXBand);
      })
      .attr("cy", d => {
        if (flip) {
          const xVal = isXBand ? val(get(d, aes.x)) : num(get(d, aes.x));
          return scalePos(xScale, xVal, isXBand);
        }
        const yVal = isYBand ? val(get(d, aes.y)) : num(get(d, aes.y));
        return scalePos(yScale, yVal, isYBand);
      })
      .attr("r", d => {
        if (aes.size) {
          const size_mm = +(val(get(d, aes.size))) || defaultSize;
          return Math.max(0.5, mmToPxRadius(size_mm));
        }
        return mmToPxRadius(defaultSize);
      })
      .attr("fill", d => {
        // ggplot2 behavior: if fill is NA, use colour for solid points
        const fillVal = val(get(d, "fill"));
        if (fillVal == null || fillVal === "NA") {
          return strokeColor(d);  // Use colour for fill
        }
        return fillColor(d);
      })
      .attr("stroke", d => {
        // For solid points (fill=NA), no visible stroke unless explicitly set
        const fillVal = val(get(d, "fill"));
        if (fillVal == null || fillVal === "NA") {
          return "none";
        }
        return strokeColor(d);
      })
      .attr("stroke-width", d => {
        const strokeVal = val(get(d, "stroke"));
        return strokeVal != null ? strokeVal : 0.5;
      })
      .attr("opacity", d => opacity(d));

    return pts.length;
  }

  // Register with geom registry
  window.gg2d3.geomRegistry.register('point', renderPoint);

})();
