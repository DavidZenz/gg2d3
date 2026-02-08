/**
 * gg2d3 Reference Line Geom Renderers
 *
 * Renders geom_hline, geom_vline, and geom_abline as SVG line elements.
 * Handles:
 * - Horizontal lines (hline) at y-intercept
 * - Vertical lines (vline) at x-intercept
 * - Diagonal lines (abline) from slope and intercept
 * - coord_flip axis swapping
 * - Linewidth, colour, linetype, and alpha styling
 *
 * @module gg2d3.geoms.reference
 */

(function() {
  'use strict';

  // Shared utilities
  const val = window.gg2d3.helpers.val;
  const num = window.gg2d3.helpers.num;
  const asRows = window.gg2d3.helpers.asRows;
  const mmToPxLinewidth = window.gg2d3.constants.mmToPxLinewidth;

  /**
   * Convert ggplot2 linetype to SVG stroke-dasharray.
   *
   * @param {string|number} lt - Linetype (name or integer code)
   * @returns {string|null} SVG dasharray or null for solid
   */
  function linetypeToStrokeDasharray(lt) {
    if (!lt || lt === "solid" || lt === 1) return null;
    if (lt === "dashed" || lt === 2) return "4,4";
    if (lt === "dotted" || lt === 3) return "1,3";
    if (lt === "dotdash" || lt === 4) return "1,3,4,3";
    if (lt === "longdash" || lt === 5) return "7,3";
    if (lt === "twodash" || lt === 6) return "2,2,6,2";
    // Hex string (e.g., "1248") -> "1,2,4,8"
    if (typeof lt === "string" && /^[0-9A-Fa-f]+$/.test(lt)) {
      return lt.split('').join(',');
    }
    return null;
  }

  // Helper to get column value from row
  const get = (d, k) => (k && d != null) ? d[k] : null;

  /**
   * Render horizontal reference line (geom_hline).
   *
   * Draws full-width horizontal lines at specified y-intercepts.
   * Position data stored in layer.data (yintercept column).
   *
   * @param {Object} layer - Layer object from IR
   * @param {d3.Selection} g - D3 plot group selection
   * @param {Function} xScale - D3 x scale
   * @param {Function} yScale - D3 y scale
   * @param {Object} options - Rendering options
   * @returns {number} Number of lines drawn
   */
  function renderHline(layer, g, xScale, yScale, options) {
    const aes = layer.aes || {};
    const dat = asRows(layer.data);
    const flip = !!options.flip;

    // Filter valid hlines
    const lines = dat.filter(d => {
      const yintercept = num(get(d, aes.yintercept || "yintercept"));
      return yintercept != null;
    });

    // Render lines
    lines.forEach(d => {
      const yintercept = num(get(d, aes.yintercept || "yintercept"));
      const colour = val(get(d, "colour")) || "black";
      const linewidth = num(get(d, "linewidth")) || 0.5;
      const linetype = val(get(d, "linetype"));
      const alpha = num(get(d, "alpha")) || 1;

      if (flip) {
        // When flipped, hline becomes vertical (spans plot height)
        const xPos = yScale(yintercept);
        g.append("line")
          .attr("x1", xPos)
          .attr("y1", 0)
          .attr("x2", xPos)
          .attr("y2", options.plotHeight)
          .attr("stroke", colour)
          .attr("stroke-width", mmToPxLinewidth(linewidth))
          .attr("stroke-dasharray", linetypeToStrokeDasharray(linetype))
          .attr("opacity", alpha);
      } else {
        // Normal: horizontal line spans plot width
        const yPos = yScale(yintercept);
        g.append("line")
          .attr("x1", 0)
          .attr("y1", yPos)
          .attr("x2", options.plotWidth)
          .attr("y2", yPos)
          .attr("stroke", colour)
          .attr("stroke-width", mmToPxLinewidth(linewidth))
          .attr("stroke-dasharray", linetypeToStrokeDasharray(linetype))
          .attr("opacity", alpha);
      }
    });

    return lines.length;
  }

  /**
   * Render vertical reference line (geom_vline).
   *
   * Draws full-height vertical lines at specified x-intercepts.
   * Position data stored in layer.data (xintercept column).
   *
   * @param {Object} layer - Layer object from IR
   * @param {d3.Selection} g - D3 plot group selection
   * @param {Function} xScale - D3 x scale
   * @param {Function} yScale - D3 y scale
   * @param {Object} options - Rendering options
   * @returns {number} Number of lines drawn
   */
  function renderVline(layer, g, xScale, yScale, options) {
    const aes = layer.aes || {};
    const dat = asRows(layer.data);
    const flip = !!options.flip;

    // Filter valid vlines
    const lines = dat.filter(d => {
      const xintercept = num(get(d, aes.xintercept || "xintercept"));
      return xintercept != null;
    });

    // Render lines
    lines.forEach(d => {
      const xintercept = num(get(d, aes.xintercept || "xintercept"));
      const colour = val(get(d, "colour")) || "black";
      const linewidth = num(get(d, "linewidth")) || 0.5;
      const linetype = val(get(d, "linetype"));
      const alpha = num(get(d, "alpha")) || 1;

      if (flip) {
        // When flipped, vline becomes horizontal (spans plot width)
        const yPos = xScale(xintercept);
        g.append("line")
          .attr("x1", 0)
          .attr("y1", yPos)
          .attr("x2", options.plotWidth)
          .attr("y2", yPos)
          .attr("stroke", colour)
          .attr("stroke-width", mmToPxLinewidth(linewidth))
          .attr("stroke-dasharray", linetypeToStrokeDasharray(linetype))
          .attr("opacity", alpha);
      } else {
        // Normal: vertical line spans plot height
        const xPos = xScale(xintercept);
        g.append("line")
          .attr("x1", xPos)
          .attr("y1", 0)
          .attr("x2", xPos)
          .attr("y2", options.plotHeight)
          .attr("stroke", colour)
          .attr("stroke-width", mmToPxLinewidth(linewidth))
          .attr("stroke-dasharray", linetypeToStrokeDasharray(linetype))
          .attr("opacity", alpha);
      }
    });

    return lines.length;
  }

  /**
   * Render diagonal reference line (geom_abline).
   *
   * Draws lines defined by slope and intercept across the plot.
   * Position data stored in layer.data (slope, intercept columns).
   *
   * @param {Object} layer - Layer object from IR
   * @param {d3.Selection} g - D3 plot group selection
   * @param {Function} xScale - D3 x scale
   * @param {Function} yScale - D3 y scale
   * @param {Object} options - Rendering options
   * @returns {number} Number of lines drawn
   */
  function renderAbline(layer, g, xScale, yScale, options) {
    const aes = layer.aes || {};
    const dat = asRows(layer.data);
    const flip = !!options.flip;

    // Filter valid ablines
    const lines = dat.filter(d => {
      const slope = num(get(d, aes.slope || "slope"));
      const intercept = num(get(d, aes.intercept || "intercept"));
      return slope != null && intercept != null;
    });

    // Render lines
    lines.forEach(d => {
      const slope = num(get(d, aes.slope || "slope"));
      const intercept = num(get(d, aes.intercept || "intercept"));
      const colour = val(get(d, "colour")) || "black";
      const linewidth = num(get(d, "linewidth")) || 0.5;
      const linetype = val(get(d, "linetype"));
      const alpha = num(get(d, "alpha")) || 1;

      // Calculate endpoints in data space
      const xDomain = xScale.domain();
      const xMin = xDomain[0];
      const xMax = xDomain[xDomain.length - 1];
      const y_at_xMin = intercept + slope * xMin;
      const y_at_xMax = intercept + slope * xMax;

      if (flip) {
        // When flipped: x uses yScale, y uses xScale
        g.append("line")
          .attr("x1", yScale(y_at_xMin))
          .attr("y1", xScale(xMin))
          .attr("x2", yScale(y_at_xMax))
          .attr("y2", xScale(xMax))
          .attr("stroke", colour)
          .attr("stroke-width", mmToPxLinewidth(linewidth))
          .attr("stroke-dasharray", linetypeToStrokeDasharray(linetype))
          .attr("opacity", alpha);
      } else {
        // Normal orientation
        g.append("line")
          .attr("x1", xScale(xMin))
          .attr("y1", yScale(y_at_xMin))
          .attr("x2", xScale(xMax))
          .attr("y2", yScale(y_at_xMax))
          .attr("stroke", colour)
          .attr("stroke-width", mmToPxLinewidth(linewidth))
          .attr("stroke-dasharray", linetypeToStrokeDasharray(linetype))
          .attr("opacity", alpha);
      }
    });

    return lines.length;
  }

  // Register with geom registry
  window.gg2d3.geomRegistry.register('hline', renderHline);
  window.gg2d3.geomRegistry.register('vline', renderVline);
  window.gg2d3.geomRegistry.register('abline', renderAbline);

})();
