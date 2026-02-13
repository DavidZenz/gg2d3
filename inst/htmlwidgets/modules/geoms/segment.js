/**
 * gg2d3 Segment Geom Renderer
 *
 * Renders geom_segment as SVG line elements.
 * Handles:
 * - Arbitrary point pairs (x,y) to (xend,yend)
 * - Continuous and categorical scales
 * - Linewidth, colour, linetype, and alpha styling
 * - coord_flip axis swapping
 *
 * @module gg2d3.geoms.segment
 */

(function() {
  'use strict';

  /**
   * Render segment geom as SVG line elements.
   *
   * Each segment connects two arbitrary points:
   * - Start: (x, y)
   * - End: (xend, yend)
   *
   * @param {Object} layer - Layer object from IR
   * @param {d3.Selection} g - D3 plot group selection
   * @param {Function} xScale - D3 x scale
   * @param {Function} yScale - D3 y scale
   * @param {Object} options - Rendering options
   * @returns {number} Number of segments drawn
   */
  function renderSegment(layer, g, xScale, yScale, options) {
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
    const flip = !!options.flip;

    // Filter valid segments (require all 4 coordinates)
    const segs = dat.filter(d => {
      const xVal = isXBand ? val(get(d, aes.x)) : num(get(d, aes.x));
      const yVal = isYBand ? val(get(d, aes.y)) : num(get(d, aes.y));
      const xendVal = isXBand ? val(get(d, aes.xend)) : num(get(d, aes.xend));
      const yendVal = isYBand ? val(get(d, aes.yend)) : num(get(d, aes.yend));
      return xVal != null && yVal != null && xendVal != null && yendVal != null;
    });

    // Helper: get pixel position from scale + value, centering for band scales
    function scalePos(scale, v, isBand) {
      return isBand ? scale(v) + scale.bandwidth() / 2 : scale(v);
    }

    // Render segments as line elements
    // When flip: x uses yScale, y uses xScale
    const sel = g.append("g").selectAll("line").data(segs);
    sel.enter().append("line")
      .attr("class", "geom-segment")
      .attr("x1", d => {
        if (flip) {
          const yVal = isYBand ? val(get(d, aes.y)) : num(get(d, aes.y));
          return scalePos(yScale, yVal, isYBand);
        }
        const xVal = isXBand ? val(get(d, aes.x)) : num(get(d, aes.x));
        return scalePos(xScale, xVal, isXBand);
      })
      .attr("y1", d => {
        if (flip) {
          const xVal = isXBand ? val(get(d, aes.x)) : num(get(d, aes.x));
          return scalePos(xScale, xVal, isXBand);
        }
        const yVal = isYBand ? val(get(d, aes.y)) : num(get(d, aes.y));
        return scalePos(yScale, yVal, isYBand);
      })
      .attr("x2", d => {
        if (flip) {
          const yendVal = isYBand ? val(get(d, aes.yend)) : num(get(d, aes.yend));
          return scalePos(yScale, yendVal, isYBand);
        }
        const xendVal = isXBand ? val(get(d, aes.xend)) : num(get(d, aes.xend));
        return scalePos(xScale, xendVal, isXBand);
      })
      .attr("y2", d => {
        if (flip) {
          const xendVal = isXBand ? val(get(d, aes.xend)) : num(get(d, aes.xend));
          return scalePos(xScale, xendVal, isXBand);
        }
        const yendVal = isYBand ? val(get(d, aes.yend)) : num(get(d, aes.yend));
        return scalePos(yScale, yendVal, isYBand);
      })
      .attr("stroke", d => strokeColor(d))
      .attr("stroke-width", d => {
        const linewidthVal = val(get(d, "linewidth"));
        return linewidthVal != null ? mmToPxLinewidth(linewidthVal) : 1.42;
      })
      .attr("opacity", d => opacity(d));

    return segs.length;
  }

  // Register with geom registry
  window.gg2d3.geomRegistry.register(['segment'], renderSegment);

})();
