/**
 * gg2d3 Violin Geom Renderer
 *
 * Renders geom_violin as symmetric density curves using d3.area().
 * Handles:
 * - Symmetric mirrored density shapes
 * - Grouping (multiple violins)
 * - violinwidth from ggplot2's pre-computed stat_ydensity
 * - coord_flip support
 * - Color/fill/alpha aesthetics
 * - Smooth curve interpolation
 *
 * @module gg2d3.geoms.violin
 */

(function() {
  'use strict';

  /**
   * Render violin geom as symmetric SVG area paths.
   *
   * ggplot2's stat_ydensity pre-computes density curves with many points (typically 512).
   * Each group has many rows with:
   * - x: categorical position (same for all points in group)
   * - y: data value along continuous axis
   * - violinwidth: density width (0 to 1 scale)
   * - group: group identifier
   *
   * Violin is rendered as single closed path with symmetric left/right sides.
   *
   * @param {Object} layer - Layer object from IR
   * @param {d3.Selection} g - D3 plot group selection
   * @param {Function} xScale - D3 x scale
   * @param {Function} yScale - D3 y scale
   * @param {Object} options - Rendering options (flip, plotWidth, plotHeight)
   * @returns {number} Number of violins drawn
   */
  function renderViolin(layer, g, xScale, yScale, options) {
    // Get utilities
    const d3 = window.d3;
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

    const flip = !!options.flip;
    const isXBand = typeof xScale.bandwidth === "function";

    // Filter valid points (must have x, y, and violinwidth)
    const pts = dat.filter(d => {
      const xVal = val(get(d, aes.x));
      const yVal = num(get(d, aes.y));
      return xVal != null && yVal != null && d.violinwidth != null;
    });

    if (pts.length === 0) return 0;

    // Group by x value (each x position = one violin)
    // Note: group aesthetic might also be used, but primary grouping is by x
    const grouped = d3.group(pts, d => val(get(d, aes.x)));

    // Default linewidth (0.5mm in ggplot2)
    const defaultLinewidth = params.linewidth || 0.5;

    let violinsDrawn = 0;

    grouped.forEach((points, xVal) => {
      // Get first point for aesthetic lookups
      const firstPoint = points[0];

      // Calculate center position and max width
      let centerPos, maxWidth;
      if (isXBand) {
        centerPos = xScale(xVal) + xScale.bandwidth() / 2;
        maxWidth = xScale.bandwidth() * (firstPoint.width || 0.9);
      } else {
        centerPos = xScale(num(xVal));
        const spacing = options.plotWidth / grouped.size;
        maxWidth = spacing * (firstPoint.width || 0.9);
      }

      const halfWidth = maxWidth / 2;

      // Sort points by y value (ascending) for proper path tracing
      const sortedPoints = points.slice().sort((a, b) => {
        return d3.ascending(num(get(a, aes.y)), num(get(b, aes.y)));
      });

      // Get linewidth from data or defaults
      const linewidthMm = firstPoint.linewidth != null ? num(firstPoint.linewidth) : defaultLinewidth;
      const linewidthPx = mmToPxLinewidth(linewidthMm);

      // Create symmetric area generator
      if (flip) {
        // Horizontal violins (coord_flip)
        // y position from x value (categorical), x position from y value (continuous)
        const area = d3.area()
          .x(p => yScale(num(get(p, aes.y))))                    // horizontal position from data value
          .y0(p => centerPos - num(p.violinwidth) * halfWidth)   // top edge (mirror)
          .y1(p => centerPos + num(p.violinwidth) * halfWidth)   // bottom edge (mirror)
          .curve(d3.curveCardinal.tension(0.9))                  // smooth curve
          .defined(p => {
            const yv = num(get(p, aes.y));
            return yv != null && p.violinwidth != null;
          });

        g.append('path')
          .datum(sortedPoints)
          .attr('class', 'geom-violin')
          .attr('d', area)
          .attr('fill', fillColor(firstPoint))
          .attr('stroke', strokeColor(firstPoint))
          .attr('stroke-width', linewidthPx)
          .attr('opacity', opacity(firstPoint));

      } else {
        // Vertical violins (normal orientation)
        // x position from x value (categorical), y position from y value (continuous)
        const area = d3.area()
          .y(p => yScale(num(get(p, aes.y))))                    // vertical position from data value
          .x0(p => centerPos - num(p.violinwidth) * halfWidth)   // left edge
          .x1(p => centerPos + num(p.violinwidth) * halfWidth)   // right edge (mirror)
          .curve(d3.curveCardinal.tension(0.9))                  // smooth curve
          .defined(p => {
            const yv = num(get(p, aes.y));
            return yv != null && p.violinwidth != null;
          });

        g.append('path')
          .datum(sortedPoints)
          .attr('class', 'geom-violin')
          .attr('d', area)
          .attr('fill', fillColor(firstPoint))
          .attr('stroke', strokeColor(firstPoint))
          .attr('stroke-width', linewidthPx)
          .attr('opacity', opacity(firstPoint));
      }

      violinsDrawn += 1;
    });

    return violinsDrawn;
  }

  // Register with geom registry
  window.gg2d3.geomRegistry.register('violin', renderViolin);

})();
