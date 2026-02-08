/**
 * gg2d3 Bar/Col Geom Renderer
 *
 * Renders geom_bar and geom_col as SVG rectangles.
 * Handles:
 * - Categorical and continuous x scales
 * - Stacked bars (ymin/ymax in data)
 * - Baseline calculation (0 if in domain, else domain min)
 * - Color/fill aesthetics with ggplot2 colour=NA default
 * - Linewidth with mm->px conversion
 *
 * @module gg2d3.geoms.bar
 */

(function() {
  'use strict';

  /**
   * Render bar/col geom as SVG rectangles.
   *
   * ggplot2 behavior:
   * - colour=NA by default (no outline)
   * - Baseline at 0 if in domain, else domain min
   * - Stacked bars use ymin/ymax from data
   * - Bandwidth from scale or calculated from data length
   *
   * @param {Object} layer - Layer object from IR
   * @param {d3.Selection} g - D3 plot group selection
   * @param {Function} xScale - D3 x scale
   * @param {Function} yScale - D3 y scale
   * @param {Object} options - Rendering options
   * @returns {number} Number of bars drawn
   */
  function renderBar(layer, g, xScale, yScale, options) {
    // Get utilities
    const val = window.gg2d3.helpers.val;
    const num = window.gg2d3.helpers.num;
    const asRows = window.gg2d3.helpers.asRows;
    const mmToPxLinewidth = window.gg2d3.constants.mmToPxLinewidth;
    const { strokeColor, fillColor, opacity } =
      window.gg2d3.geomRegistry.makeColorAccessors(layer, options);

    const aes = layer.aes || {};
    const dat = asRows(layer.data);

    // Helper to get column value from row
    const get = (d, k) => (k && d != null) ? d[k] : null;

    const flip = !!options.flip;
    const isBand = typeof xScale.bandwidth === "function";
    const bw = isBand
      ? xScale.bandwidth()
      : Math.max(4, options.plotWidth / Math.max(1, dat.length));

    // For categorical x, use val(); for continuous, use num()
    const bars = dat.filter(d => {
      const xVal = isBand ? val(get(d, aes.x)) : num(get(d, aes.x));
      const yVal = num(get(d, aes.y));
      return xVal != null && yVal != null;
    });

    // Check if data has ymin/ymax (for stacked bars)
    const hasStack = bars.length > 0 && get(bars[0], "ymin") != null && get(bars[0], "ymax") != null;

    // Calculate baseline: use 0 if in domain, else use domain min
    // When flip: the value axis is yScale (horizontal), baseline is horizontal
    const valScale = flip ? yScale : yScale;
    let baseline;
    if (!hasStack) {
      const yDomain = yScale.domain();
      if (typeof yScale.bandwidth === "function") {
        baseline = flip ? 0 : options.plotHeight;
      } else {
        const [yMin, yMax] = d3.extent(yDomain);
        if (yMin <= 0 && yMax >= 0) {
          baseline = yScale(0);
        } else {
          baseline = yScale(yMin);
        }
      }
    }

    // Render rectangles
    const sel = g.append("g").selectAll("rect").data(bars);

    if (flip) {
      // Horizontal bars: xScale=category (vertical), yScale=value (horizontal)
      sel.enter().append("rect")
        .attr("y", d => (isBand ? xScale(val(get(d, aes.x))) : xScale(num(get(d, aes.x))) - bw / 2))
        .attr("x", d => {
          if (hasStack) {
            const yMinPos = yScale(num(get(d, "ymin")));
            const yMaxPos = yScale(num(get(d, "ymax")));
            return Math.min(yMinPos, yMaxPos);
          } else {
            const yPos = yScale(num(get(d, aes.y)));
            return Math.min(yPos, baseline);
          }
        })
        .attr("height", bw)
        .attr("width", d => {
          if (hasStack) {
            const yMinPos = yScale(num(get(d, "ymin")));
            const yMaxPos = yScale(num(get(d, "ymax")));
            return Math.abs(yMaxPos - yMinPos);
          } else {
            return Math.abs(yScale(num(get(d, aes.y))) - baseline);
          }
        })
        .attr("fill", d => fillColor(d))
        .attr("stroke", d => {
          const colourVal = val(get(d, "colour"));
          if (colourVal == null || colourVal === "NA") { return "none"; }
          return strokeColor(d);
        })
        .attr("stroke-width", d => {
          const linewidthVal = val(get(d, "linewidth"));
          return linewidthVal != null ? mmToPxLinewidth(linewidthVal) : 1.89;
        })
        .attr("opacity", d => opacity(d));
    } else {
      // Normal vertical bars
      sel.enter().append("rect")
        .attr("x", d => (isBand ? xScale(val(get(d, aes.x))) : xScale(num(get(d, aes.x))) - bw / 2))
        .attr("y", d => {
          if (hasStack) {
            return yScale(num(get(d, "ymax")));
          } else {
            const yPos = yScale(num(get(d, aes.y)));
            return Math.min(yPos, baseline);
          }
        })
        .attr("width", bw)
        .attr("height", d => {
          if (hasStack) {
            const yMinPos = yScale(num(get(d, "ymin")));
            const yMaxPos = yScale(num(get(d, "ymax")));
            return Math.abs(yMaxPos - yMinPos);
          } else {
            return Math.abs(yScale(num(get(d, aes.y))) - baseline);
          }
        })
      .attr("fill", d => fillColor(d))
      .attr("stroke", d => {
        // ggplot2 bar default: colour=NA (no outline)
        const colourVal = val(get(d, "colour"));
        if (colourVal == null || colourVal === "NA") {
          return "none";
        }
        return strokeColor(d);
      })
      .attr("stroke-width", d => {
        const linewidthVal = val(get(d, "linewidth"));
        // Convert mm to pixels: 0.5mm = 1.89px
        return linewidthVal != null ? mmToPxLinewidth(linewidthVal) : 1.89;
      })
      .attr("opacity", d => opacity(d));
    }

    return bars.length;
  }

  // Register with geom registry (both bar and col use same renderer)
  window.gg2d3.geomRegistry.register(['bar', 'col'], renderBar);

})();
