/**
 * gg2d3 Dotplot Geom Renderer
 *
 * Renders geom_dotplot as SVG circles.
 * Handles dot stacking based on binwidth and stackpos.
 *
 * @module gg2d3.geoms.dotplot
 */

(function() {
  'use strict';

  /**
   * Render dotplot geom as SVG circles.
   *
   * @param {Object} layer - Layer object from IR
   * @param {d3.Selection} g - D3 plot group selection
   * @param {Function} xScale - D3 x scale
   * @param {Function} yScale - D3 y scale
   * @param {Object} options - Rendering options
   * @returns {number} Number of dots drawn
   */
  function renderDotplot(layer, g, xScale, yScale, options) {
    const val = window.gg2d3.helpers.val;
    const num = window.gg2d3.helpers.num;
    const asRows = window.gg2d3.helpers.asRows;
    const { strokeColor, fillColor, opacity } =
      window.gg2d3.geomRegistry.makeColorAccessors(layer, options);

    const aes = layer.aes || {};
    const dat = asRows(layer.data);
    const params = layer.params || {};

    // Helper to get column value from row
    const get = (d, k) => (k && d != null) ? d[k] : null;

    const flip = !!options.flip;
    const binaxis = params.binaxis || 'x';
    const stackdir = params.stackdir || 'up';

    // Dots are typically circles
    const dots = dat.filter(d => {
      const xVal = num(get(d, aes.x));
      const yVal = num(get(d, aes.y));
      return xVal != null && yVal != null;
    });

    const sel = g.append("g").selectAll("circle").data(dots);

    sel.enter().append("circle")
      .attr("class", "geom-dotplot")
      .attr("cx", d => {
        const xBase = xScale(num(get(d, aes.x)));
        if (binaxis === 'y') {
          // If binning on y, x is the stacking axis
          const stackpos = num(get(d, aes.stackpos)) || 0;
          const binwidth = num(get(d, aes.binwidth)) || 1;
          // stackdir affects which way they stack
          const offset = stackdir === 'down' ? -stackpos : stackpos;
          return xBase + offset * binwidth * options.plotWidth; // crude approximation
        }
        return xBase;
      })
      .attr("cy", d => {
        const yBase = yScale(num(get(d, aes.y)));
        if (binaxis === 'x') {
          // If binning on x, y is the stacking axis
          const stackpos = num(get(d, aes.stackpos)) || 0;
          const binwidth = num(get(d, aes.binwidth)) || 1;
          // In D3, Y increases downwards, so 'up' stack means decreasing Y
          const offset = stackdir === 'down' ? stackpos : -stackpos;
          // binwidth in IR is in data units. We need pixels.
          const yRange = yScale.range();
          const yDomain = yScale.domain();
          const pixelsPerUnit = Math.abs(yRange[1] - yRange[0]) / Math.abs(yDomain[1] - yDomain[0]);
          return yBase + offset * binwidth * pixelsPerUnit;
        }
        return yBase;
      })
      .attr("r", d => {
        const binwidth = num(get(d, aes.binwidth)) || 1;
        const yRange = yScale.range();
        const yDomain = yScale.domain();
        const pixelsPerUnit = Math.abs(yRange[1] - yRange[0]) / Math.abs(yDomain[1] - yDomain[0]);
        return (binwidth * pixelsPerUnit) / 2;
      })
      .attr("fill", d => fillColor(d))
      .attr("stroke", d => strokeColor(d))
      .attr("stroke-width", d => d.stroke || 1)
      .attr("opacity", d => opacity(d));

    return dots.length;
  }

  // Register with geom registry
  window.gg2d3.geomRegistry.register('dotplot', renderDotplot);

})();
