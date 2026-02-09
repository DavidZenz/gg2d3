/**
 * gg2d3 Boxplot Geom Renderer
 *
 * Renders geom_boxplot as SVG elements showing five-number summary.
 * Handles:
 * - IQR box (rectangle from Q1 to Q3)
 * - Median line
 * - Whiskers (from box edges to ymin/ymax)
 * - Whisker endcaps (staples)
 * - Outliers as circles
 * - coord_flip support
 * - Color/fill/alpha aesthetics
 *
 * @module gg2d3.geoms.boxplot
 */

(function() {
  'use strict';

  /**
   * Render boxplot geom as SVG primitives.
   *
   * ggplot2 pre-computes all statistics:
   * - ymin: lower whisker endpoint
   * - lower: Q1 (25th percentile)
   * - middle: median (50th percentile)
   * - upper: Q3 (75th percentile)
   * - ymax: upper whisker endpoint
   * - outliers: array of outlier y-values
   *
   * @param {Object} layer - Layer object from IR
   * @param {d3.Selection} g - D3 plot group selection
   * @param {Function} xScale - D3 x scale
   * @param {Function} yScale - D3 y scale
   * @param {Object} options - Rendering options (flip, plotWidth, plotHeight)
   * @returns {number} Number of boxplots drawn
   */
  function renderBoxplot(layer, g, xScale, yScale, options) {
    // Get utilities
    const val = window.gg2d3.helpers.val;
    const num = window.gg2d3.helpers.num;
    const asRows = window.gg2d3.helpers.asRows;
    const mmToPxRadius = window.gg2d3.constants.mmToPxRadius;
    const mmToPxLinewidth = window.gg2d3.constants.mmToPxLinewidth;
    const { strokeColor, fillColor, opacity } =
      window.gg2d3.geomRegistry.makeColorAccessors(layer, options);

    const aes = layer.aes || {};
    const params = layer.params || {};
    const dat = asRows(layer.data);

    // Helper to get column value from row
    const get = (d, k) => (k && d != null) ? d[k] : null;

    const flip = !!options.flip;
    const isXBand = typeof xScale.bandwidth === "function";

    // Filter valid boxplot data (must have x and required stat columns)
    const boxes = dat.filter(d => {
      const xVal = val(get(d, aes.x));
      const hasStats = d.lower != null && d.middle != null && d.upper != null;
      return xVal != null && hasStats;
    });

    // Default linewidth (0.5mm in ggplot2)
    const defaultLinewidth = params.linewidth || 0.5;

    boxes.forEach(d => {
      // Get x position (categorical or numeric)
      const xVal = val(get(d, aes.x));

      // Calculate center position and box width from xmin/xmax
      // ggplot2 pre-computes xmin/xmax in ggplot_build() based on the width parameter
      let centerPos, boxWidth;
      const xmin = num(d.xmin);
      const xmax = num(d.xmax);
      if (isXBand) {
        centerPos = xScale(xVal) + xScale.bandwidth() / 2;
        // xmin/xmax are in continuous position space (1,2,3,...); scale proportionally to bandwidth
        boxWidth = (xmax != null && xmin != null)
          ? xScale.bandwidth() * (xmax - xmin)
          : xScale.bandwidth() * 0.75;
      } else {
        centerPos = xScale(num(xVal));
        // For continuous x, use xmin/xmax directly in pixel space
        boxWidth = (xmax != null && xmin != null)
          ? Math.abs(xScale(xmax) - xScale(xmin))
          : (options.plotWidth / boxes.length) * 0.5;
      }

      // Get stat values
      const ymin = num(d.ymin);
      const lower = num(d.lower);
      const middle = num(d.middle);
      const upper = num(d.upper);
      const ymax = num(d.ymax);

      // Get linewidth from data or defaults
      const linewidthMm = d.linewidth != null ? num(d.linewidth) : defaultLinewidth;
      const linewidthPx = mmToPxLinewidth(linewidthMm);

      // Helper: create attributes for normal or flipped orientation
      const boxAttrs = flip
        ? {
            x: yScale(lower),
            y: centerPos - boxWidth / 2,
            width: yScale(upper) - yScale(lower),
            height: boxWidth
          }
        : {
            x: centerPos - boxWidth / 2,
            y: yScale(upper),
            width: boxWidth,
            height: yScale(lower) - yScale(upper)
          };

      // 1. Draw IQR box (rectangle from lower to upper)
      g.append('rect')
        .attr('x', boxAttrs.x)
        .attr('y', boxAttrs.y)
        .attr('width', boxAttrs.width)
        .attr('height', boxAttrs.height)
        .attr('fill', fillColor(d))
        .attr('stroke', strokeColor(d))
        .attr('stroke-width', linewidthPx)
        .attr('opacity', opacity(d));

      // 2. Draw median line (same linewidth as box border, matching ggplot2)
      const medianLinewidth = linewidthPx;
      if (flip) {
        g.append('line')
          .attr('x1', yScale(middle))
          .attr('x2', yScale(middle))
          .attr('y1', centerPos - boxWidth / 2)
          .attr('y2', centerPos + boxWidth / 2)
          .attr('stroke', strokeColor(d))
          .attr('stroke-width', medianLinewidth);
      } else {
        g.append('line')
          .attr('x1', centerPos - boxWidth / 2)
          .attr('x2', centerPos + boxWidth / 2)
          .attr('y1', yScale(middle))
          .attr('y2', yScale(middle))
          .attr('stroke', strokeColor(d))
          .attr('stroke-width', medianLinewidth);
      }

      // 3. Draw upper whisker (from box top to ymax)
      if (ymax != null) {
        if (flip) {
          g.append('line')
            .attr('x1', yScale(upper))
            .attr('x2', yScale(ymax))
            .attr('y1', centerPos)
            .attr('y2', centerPos)
            .attr('stroke', strokeColor(d))
            .attr('stroke-width', linewidthPx);
        } else {
          g.append('line')
            .attr('x1', centerPos)
            .attr('x2', centerPos)
            .attr('y1', yScale(upper))
            .attr('y2', yScale(ymax))
            .attr('stroke', strokeColor(d))
            .attr('stroke-width', linewidthPx);
        }

        // ggplot2 default staple.width = 0 (no endcaps on whiskers)
      }

      // 4. Draw lower whisker (from box bottom to ymin)
      if (ymin != null) {
        if (flip) {
          g.append('line')
            .attr('x1', yScale(lower))
            .attr('x2', yScale(ymin))
            .attr('y1', centerPos)
            .attr('y2', centerPos)
            .attr('stroke', strokeColor(d))
            .attr('stroke-width', linewidthPx);
        } else {
          g.append('line')
            .attr('x1', centerPos)
            .attr('x2', centerPos)
            .attr('y1', yScale(lower))
            .attr('y2', yScale(ymin))
            .attr('stroke', strokeColor(d))
            .attr('stroke-width', linewidthPx);
        }

        // ggplot2 default staple.width = 0 (no endcaps on whiskers)
      }

      // 5. Draw outliers as circles
      // ggplot2 default outlier size is 1.5mm diameter
      const outlierRadius = mmToPxRadius(1.5);
      if (d.outliers && Array.isArray(d.outliers) && d.outliers.length > 0) {
        d.outliers.forEach(outlierVal => {
          const outlierY = num(outlierVal);
          if (outlierY != null) {
            if (flip) {
              g.append('circle')
                .attr('cx', yScale(outlierY))
                .attr('cy', centerPos)
                .attr('r', outlierRadius)
                .attr('fill', strokeColor(d))  // Outliers use colour, not fill
                .attr('stroke', 'none');
            } else {
              g.append('circle')
                .attr('cx', centerPos)
                .attr('cy', yScale(outlierY))
                .attr('r', outlierRadius)
                .attr('fill', strokeColor(d))  // Outliers use colour, not fill
                .attr('stroke', 'none');
            }
          }
        });
      }
    });

    return boxes.length;
  }

  // Register with geom registry
  window.gg2d3.geomRegistry.register('boxplot', renderBoxplot);

})();
