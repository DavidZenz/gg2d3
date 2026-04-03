/**
 * gg2d3 Rug Geom Renderer
 *
 * Renders geom_rug as small segments along the panel edges.
 *
 * @module gg2d3.geoms.rug
 */

(function() {
  'use strict';

  /**
   * Render rug geom as SVG segments.
   *
   * @param {Object} layer - Layer object from IR
   * @param {d3.Selection} g - D3 plot group selection
   * @param {Function} xScale - D3 x scale
   * @param {Function} yScale - D3 y scale
   * @param {Object} options - Rendering options
   * @returns {number} Number of rug segments drawn
   */
  function renderRug(layer, g, xScale, yScale, options) {
    const asRows = window.gg2d3.helpers.asRows;
    const num = window.gg2d3.helpers.num;
    const { strokeColor, opacity } =
      window.gg2d3.geomRegistry.makeColorAccessors(layer, options);

    const aes = layer.aes || {};
    const dat = asRows(layer.data);
    const params = layer.params || {};
    const sides = params.sides || 'bl';

    const w = options.plotWidth;
    const h = options.plotHeight;
    const rugLen = Math.min(w, h) * 0.03; // Rug marks are 3% of panel size

    let totalDrawn = 0;

    // We may need to draw multiple segments per data point if multiple sides are specified
    sides.split('').forEach(side => {
      const sel = g.append("g").attr("class", "rug-side-" + side).selectAll("line").data(dat);

      sel.enter().append("line")
        .attr("class", "geom-rug")
        .attr("x1", d => {
          if (side === 'b' || side === 't') return xScale(num(d[aes.x || "x"]));
          if (side === 'l') return 0;
          if (side === 'r') return w;
          return 0;
        })
        .attr("x2", d => {
          if (side === 'b' || side === 't') return xScale(num(d[aes.x || "x"]));
          if (side === 'l') return rugLen;
          if (side === 'r') return w - rugLen;
          return 0;
        })
        .attr("y1", d => {
          if (side === 'l' || side === 'r') return yScale(num(d[aes.y || "y"]));
          if (side === 'b') return h;
          if (side === 't') return 0;
          return 0;
        })
        .attr("y2", d => {
          if (side === 'l' || side === 'r') return yScale(num(d[aes.y || "y"]));
          if (side === 'b') return h - rugLen;
          if (side === 't') return rugLen;
          return 0;
        })
        .attr("stroke", d => strokeColor(d))
        .attr("stroke-width", d => d.linewidth || params.linewidth || 0.5)
        .attr("opacity", d => opacity(d));
      
      totalDrawn += dat.length;
    });

    return totalDrawn;
  }

  // Register with geom registry
  window.gg2d3.geomRegistry.register('rug', renderRug);

})();
