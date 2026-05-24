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
    const mmToPxLinewidth = window.gg2d3.constants.mmToPxLinewidth;
    const { fillColor, strokeColor, opacity } =
      window.gg2d3.geomRegistry.makeColorAccessors(layer, options);

    const aes = layer.aes || {};
    const params = layer.params || {};
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
    const flip = !!options.flip;

    function isMissingAesthetic(value) {
      const v = val(value);
      if (v === null || v === undefined) return true;
      if (typeof v === "number" && Number.isNaN(v)) return true;
      return v === "NA";
    }

    function bandValue(d, centerKey, boundKey) {
      const center = val(get(d, centerKey));
      if (center !== null && center !== undefined) return center;
      return val(get(d, boundKey));
    }

    function rectStroke(d) {
      const rowStroke = get(d, "colour");
      if (rowStroke !== null && rowStroke !== undefined) {
        return isMissingAesthetic(rowStroke) ? "none" : strokeColor(d);
      }
      if (isMissingAesthetic(params.colour)) return "none";
      return strokeColor(d);
    }

    function rectLinewidth(d) {
      const linewidth = val(get(d, "linewidth"));
      const fallback = val(params.linewidth);
      const source = linewidth !== null && linewidth !== undefined ? linewidth : fallback;
      return source !== null && source !== undefined ? mmToPxLinewidth(source) : mmToPxLinewidth(0.5);
    }

    function rectX(d) {
      if (isXBand) return xScale(bandValue(d, aes.x, aes.xmin));
      return Math.min(xScale(num(get(d, aes.xmin))), xScale(num(get(d, aes.xmax))));
    }

    function rectY(d) {
      if (isYBand) return yScale(bandValue(d, aes.y, aes.ymin));
      return Math.min(yScale(num(get(d, aes.ymin))), yScale(num(get(d, aes.ymax))));
    }

    function rectWidth(d) {
      if (isXBand) return xScale.bandwidth();
      const x1 = xScale(num(get(d, aes.xmin)));
      const x2 = xScale(num(get(d, aes.xmax)));
      return Math.abs(x2 - x1);
    }

    function rectHeight(d) {
      if (isYBand) return yScale.bandwidth();
      const y1 = yScale(num(get(d, aes.ymin)));
      const y2 = yScale(num(get(d, aes.ymax)));
      return Math.abs(y2 - y1);
    }

    function flippedRectX(d) {
      if (isYBand) return yScale(bandValue(d, aes.y, aes.ymin));
      return Math.min(yScale(num(get(d, aes.ymin))), yScale(num(get(d, aes.ymax))));
    }

    function flippedRectY(d) {
      if (isXBand) return xScale(bandValue(d, aes.x, aes.xmin));
      return Math.min(xScale(num(get(d, aes.xmin))), xScale(num(get(d, aes.xmax))));
    }

    function flippedRectWidth(d) {
      if (isYBand) return yScale.bandwidth();
      const y1 = yScale(num(get(d, aes.ymin)));
      const y2 = yScale(num(get(d, aes.ymax)));
      return Math.abs(y2 - y1);
    }

    function flippedRectHeight(d) {
      if (isXBand) return xScale.bandwidth();
      const x1 = xScale(num(get(d, aes.xmin)));
      const x2 = xScale(num(get(d, aes.xmax)));
      return Math.abs(x2 - x1);
    }

    function getLegendIdentity(datum) {
      const candidates = [
        { aesthetic: 'fill', mapping: aes.fill },
        { aesthetic: 'colour', mapping: aes.color },
        { aesthetic: 'shape', mapping: aes.shape },
        { aesthetic: 'size', mapping: aes.size }
      ];

      for (let i = 0; i < candidates.length; i++) {
        const candidate = candidates[i];
        if (!candidate.mapping) continue;

        const raw = val(get(datum, candidate.mapping));
        if (raw === null || raw === undefined) continue;
        if (typeof raw === 'number' && Number.isFinite(raw)) continue;

        const level = String(raw).trim();
        if (!level) continue;

        return {
          key: candidate.aesthetic + '::' + level,
          level: level,
          aesthetic: candidate.aesthetic
        };
      }

      return null;
    }

    // Render rectangles
    // When flip: xScale maps vertical, yScale maps horizontal
    // x-aesthetic bounds (xmin/xmax) use xScale for vertical positioning
    // y-aesthetic bounds (ymin/ymax) use yScale for horizontal positioning
    const sel = g.append("g").selectAll("rect").data(rects);
    if (flip) {
      sel.enter().append("rect")
        .attr("class", "geom-rect")
        .attr("x", d => flippedRectX(d))
        .attr("y", d => flippedRectY(d))
        .attr("width", d => flippedRectWidth(d))
        .attr("height", d => flippedRectHeight(d))
        .attr("fill", d => fillColor(d))
        .attr("stroke", d => rectStroke(d))
        .attr("stroke-width", d => rectLinewidth(d))
        .attr("opacity", d => opacity(d))
        .attr("data-legend-key", d => {
          const identity = getLegendIdentity(d);
          return identity ? identity.key : null;
        })
        .attr("data-legend-level", d => {
          const identity = getLegendIdentity(d);
          return identity ? identity.level : null;
        })
        .attr("data-legend-aesthetic", d => {
          const identity = getLegendIdentity(d);
          return identity ? identity.aesthetic : null;
        });
    } else {
      sel.enter().append("rect")
        .attr("class", "geom-rect")
        .attr("x", d => rectX(d))
        .attr("y", d => rectY(d))
        .attr("width", d => rectWidth(d))
        .attr("height", d => rectHeight(d))
      .attr("fill", d => fillColor(d))
      .attr("stroke", d => rectStroke(d))
      .attr("stroke-width", d => rectLinewidth(d))
      .attr("opacity", d => opacity(d))
      .attr("data-legend-key", d => {
        const identity = getLegendIdentity(d);
        return identity ? identity.key : null;
      })
      .attr("data-legend-level", d => {
        const identity = getLegendIdentity(d);
        return identity ? identity.level : null;
      })
      .attr("data-legend-aesthetic", d => {
        const identity = getLegendIdentity(d);
        return identity ? identity.aesthetic : null;
      });
    }

    return rects.length;
  }

  // Register with geom registry (both rect and tile use same renderer)
  window.gg2d3.geomRegistry.register(['rect', 'tile'], renderRect);

})();
