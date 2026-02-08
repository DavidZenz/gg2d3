/**
 * gg2d3 Area Geom Renderer
 *
 * Renders geom_area as filled SVG areas using d3.area() path generator.
 * Handles:
 * - Baseline calculation (zero or domain min)
 * - Stacked areas (uses ymin from data)
 * - Group aesthetic for multiple areas
 * - coord_flip support
 * - Missing data creates gaps (via .defined())
 *
 * @module gg2d3.geoms.area
 */

(function() {
  'use strict';

  /**
   * Render area geom as SVG paths with filled regions.
   *
   * Area fills from baseline (zero or domain min) to y values.
   * For stacked areas, uses ymin from data as baseline.
   *
   * @param {Object} layer - Layer object from IR
   * @param {d3.Selection} g - D3 plot group selection
   * @param {Function} xScale - D3 x scale
   * @param {Function} yScale - D3 y scale
   * @param {Object} options - Rendering options (flip, plotHeight)
   * @returns {number} Number of areas drawn
   */
  function renderArea(layer, g, xScale, yScale, options) {
    // Get utilities
    const val = window.gg2d3.helpers.val;
    const num = window.gg2d3.helpers.num;
    const asRows = window.gg2d3.helpers.asRows;
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

    let areasDrawn = 0;

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

      // Sort by x if not band scale (geom_area sorts like geom_line)
      if (!isXBand) {
        pts = pts.sort((a, b) => d3.ascending(a.x, b.x));
      }

      if (pts.length >= 2) {
        const xOff = isXBand ? xScale.bandwidth() / 2 : 0;

        // Calculate baseline for non-stacked areas
        let baseline;
        if (isYBand) {
          // Band scales: baseline at panel bottom
          baseline = options.plotHeight;
        } else {
          // Check if any point has ymin (stacked area)
          const hasYmin = pts.some(p => p.ymin != null);
          if (!hasYmin) {
            // Non-stacked: calculate fixed baseline
            const yDomain = yScale.domain();
            if (yDomain[0] <= 0 && yDomain[1] >= 0) {
              // Domain includes zero
              baseline = yScale(0);
            } else {
              // Domain doesn't include zero, use domain min
              baseline = yScale(yDomain[0]);
            }
          }
        }

        // Create area generator
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

        g.append("path")
          .attr("d", area(pts))
          .attr("fill", fillColor(firstPoint))
          .attr("stroke", "none")
          .attr("opacity", opacity(firstPoint));

        areasDrawn += 1;
      }
    });

    return areasDrawn;
  }

  // Register with geom registry
  window.gg2d3.geomRegistry.register(['area'], renderArea);

})();
