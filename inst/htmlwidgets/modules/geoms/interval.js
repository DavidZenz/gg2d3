/**
 * gg2d3 Interval Geoms Renderer
 *
 * Renders geom_errorbar, geom_linerange, and geom_pointrange.
 *
 * @module gg2d3.geoms.interval
 */

(function() {
  'use strict';

  /**
   * Unified renderer for interval geoms.
   *
   * @param {Object} layer - Layer object from IR
   * @param {d3.Selection} g - D3 plot group selection
   * @param {Function} xScale - D3 x scale
   * @param {Function} yScale - D3 y scale
   * @param {Object} options - Rendering options
   * @returns {number} Number of intervals drawn
   */
  function renderInterval(layer, g, xScale, yScale, options) {
    const num = window.gg2d3.helpers.num;
    const asRows = window.gg2d3.helpers.asRows;
    const { strokeColor, fillColor, opacity } =
      window.gg2d3.geomRegistry.makeColorAccessors(layer, options);

    const aes = layer.aes || {};
    const dat = asRows(layer.data);
    const params = layer.params || {};
    const geom = layer.geom;

    const flip = !!options.flip;

    const group = g.append("g").attr("class", "geom-interval-" + geom);
    const items = group.selectAll("g.interval-item").data(dat);

    const enter = items.enter().append("g").attr("class", "interval-item");

    // 1. Draw central line (all three geoms)
    enter.append("line")
      .attr("class", "interval-line")
      .attr("x1", d => flip ? yScale(num(d.ymin)) : xScale(num(d[aes.x || "x"])))
      .attr("x2", d => flip ? yScale(num(d.ymax)) : xScale(num(d[aes.x || "x"])))
      .attr("y1", d => flip ? xScale(num(d[aes.x || "x"])) : yScale(num(d.ymin)))
      .attr("y2", d => flip ? xScale(num(d[aes.x || "x"])) : yScale(num(d.ymax)))
      .attr("stroke", d => strokeColor(d))
      .attr("stroke-width", d => d.linewidth || params.linewidth || 0.5)
      .attr("opacity", d => opacity(d));

    // 2. Draw errorbar caps
    if (geom === 'errorbar') {
      // Top cap
      enter.append("line")
        .attr("class", "errorbar-cap-top")
        .attr("x1", d => flip ? yScale(num(d.ymax)) : xScale(num(d.xmin)))
        .attr("x2", d => flip ? yScale(num(d.ymax)) : xScale(num(d.xmax)))
        .attr("y1", d => flip ? xScale(num(d.xmin)) : yScale(num(d.ymax)))
        .attr("y2", d => flip ? xScale(num(d.xmax)) : yScale(num(d.ymax)))
        .attr("stroke", d => strokeColor(d))
        .attr("stroke-width", d => d.linewidth || params.linewidth || 0.5)
        .attr("opacity", d => opacity(d));

      // Bottom cap
      enter.append("line")
        .attr("class", "errorbar-cap-bottom")
        .attr("x1", d => flip ? yScale(num(d.ymin)) : xScale(num(d.xmin)))
        .attr("x2", d => flip ? yScale(num(d.ymin)) : xScale(num(d.xmax)))
        .attr("y1", d => flip ? xScale(num(d.xmin)) : yScale(num(d.ymin)))
        .attr("y2", d => flip ? xScale(num(d.xmax)) : yScale(num(d.ymin)))
        .attr("stroke", d => strokeColor(d))
        .attr("stroke-width", d => d.linewidth || params.linewidth || 0.5)
        .attr("opacity", d => opacity(d));
    }

    // 3. Draw point (pointrange)
    if (geom === 'pointrange') {
      enter.append("circle")
        .attr("class", "pointrange-point")
        .attr("cx", d => flip ? yScale(num(d[aes.y || "y"])) : xScale(num(d[aes.x || "x"])))
        .attr("cy", d => flip ? xScale(num(d[aes.x || "x"])) : yScale(num(d[aes.y || "y"])))
        .attr("r", d => (d.size || params.size || 1.5) * 2) // scale up for visibility
        .attr("fill", d => fillColor(d))
        .attr("stroke", d => strokeColor(d))
        .attr("stroke-width", 0.5)
        .attr("opacity", d => opacity(d));
    }

    return dat.length;
  }

  // Register with geom registry
  window.gg2d3.geomRegistry.register(['errorbar', 'linerange', 'pointrange'], renderInterval);

})();
