/**
 * gg2d3 Density Geom Renderer
 *
 * Renders geom_density as filled SVG areas with outline using d3.area() path generator.
 * Handles:
 * - Density curves with fill and stroke (outline)
 * - Baseline calculation (zero or domain min)
 * - Stacked densities (uses ymin from data)
 * - Group aesthetic for multiple density curves
 * - coord_flip support
 * - Missing data creates gaps (via .defined())
 *
 * GeomDensity extends GeomArea in ggplot2, rendering as filled area under the density curve
 * with a visible outline.
 *
 * @module gg2d3.geoms.density
 */

(function() {
  'use strict';

  /**
   * Render density geom as SVG paths with filled area and outline stroke.
   *
   * Density fills from baseline (zero or domain min) to density values.
   * For stacked densities, uses ymin from data as baseline.
   *
   * @param {Object} layer - Layer object from IR
   * @param {d3.Selection} g - D3 plot group selection
   * @param {Function} xScale - D3 x scale
   * @param {Function} yScale - D3 y scale
   * @param {Object} options - Rendering options (flip, plotHeight)
   * @returns {number} Number of density curves drawn
   */
  function renderDensity(layer, g, xScale, yScale, options) {
    // Get utilities
    const val = window.gg2d3.helpers.val;
    const num = window.gg2d3.helpers.num;
    const asRows = window.gg2d3.helpers.asRows;
    const mmToPxLinewidth = window.gg2d3.constants.mmToPxLinewidth;
    const { fillColor, strokeColor, opacity } =
      window.gg2d3.geomRegistry.makeColorAccessors(layer, options);

    const aes = layer.aes || {};
    const dat = asRows(layer.data);

    // Helper to get column value from row
    const get = (d, k) => (k && d != null) ? d[k] : null;

    const flip = !!options.flip;
    const isXBand = typeof xScale.bandwidth === "function";
    const isYBand = typeof yScale.bandwidth === "function";

    // Group by 'group' aesthetic (default to single group)
    const grouped = d3.group(dat, d => val(get(d, "group")) ?? 1);

    let densitiesDrawn = 0;

    grouped.forEach(arr => {
      // Map to {x, y, ymin, d} objects
      let pts = arr
        .map(d => {
          const xVal = isXBand ? val(get(d, aes.x)) : num(get(d, aes.x));
          const yVal = isYBand ? val(get(d, aes.y)) : num(get(d, aes.y));
          const yminVal = num(get(d, "ymin")); // May be null for non-stacked
          return { x: xVal, y: yVal, ymin: yminVal, d };
        })
        .filter(p => p.x != null && p.y != null);

      // Sort by x (density data should already be sorted, but ensure it)
      if (!isXBand) {
        pts = pts.sort((a, b) => d3.ascending(a.x, b.x));
      }

      if (pts.length >= 2) {
        const xOff = isXBand ? xScale.bandwidth() / 2 : 0;

        // Calculate baseline for non-stacked densities
        let baseline;
        if (isYBand) {
          // Band scales: baseline at panel bottom
          baseline = options.plotHeight;
        } else {
          // Check if any point has ymin (stacked density)
          const hasYmin = pts.some(p => p.ymin != null);
          if (!hasYmin) {
            // Non-stacked: calculate fixed baseline
            const yDomain = yScale.domain();
            if (yDomain[0] <= 0 && yDomain[1] >= 0) {
              // Domain includes zero (typical for density)
              baseline = yScale(0);
            } else {
              // Domain doesn't include zero, use domain min
              baseline = yScale(yDomain[0]);
            }
          }
        }

        // Create area generator for filled density
        const area = flip
          ? d3.area()
              .y(p => xScale(p.x) + xOff)
              .x0(p => p.ymin != null ? yScale(p.ymin) : baseline)
              .x1(p => yScale(p.y))
              .defined(p => p.x != null && p.y != null)
          : d3.area()
              .x(p => xScale(p.x) + xOff)
              .y0(p => p.ymin != null ? yScale(p.ymin) : baseline)
              .y1(p => yScale(p.y))
              .defined(p => p.x != null && p.y != null);

        const firstPoint = pts[0].d;

        // Draw filled area
        g.append("path")
          .attr("d", area(pts))
          .attr("fill", fillColor(firstPoint))
          .attr("stroke", "none")
          .attr("opacity", opacity(firstPoint));

        // Draw outline stroke (density has visible outline unlike basic area)
        const line = flip
          ? d3.line()
              .x(p => yScale(p.y))
              .y(p => xScale(p.x) + xOff)
              .defined(p => p.x != null && p.y != null)
          : d3.line()
              .x(p => xScale(p.x) + xOff)
              .y(p => yScale(p.y))
              .defined(p => p.x != null && p.y != null);

        const linewidthVal = val(get(firstPoint, "linewidth"));
        // ggplot2 default linewidth for density: 0.5mm = 1.89px
        const strokeWidth = linewidthVal != null ? mmToPxLinewidth(linewidthVal) : 1.89;

        g.append("path")
          .attr("d", line(pts))
          .attr("fill", "none")
          .attr("stroke", strokeColor(firstPoint))
          .attr("stroke-width", strokeWidth)
          .attr("opacity", opacity(firstPoint));

        densitiesDrawn += 1;
      }
    });

    return densitiesDrawn;
  }

  // Register with geom registry
  window.gg2d3.geomRegistry.register(['density'], renderDensity);

})();
