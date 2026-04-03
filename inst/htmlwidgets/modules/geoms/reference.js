/**
 * Reference Geoms module for gg2d3
 * Provides renderers for geom_hline, geom_vline, and geom_abline.
 */

(function() {
  'use strict';

  /**
   * Render geom_hline (horizontal lines across full panel)
   */
  function renderHline(layer, g, xScale, yScale, options) {
    const { strokeColor, opacity } = window.gg2d3.geomRegistry.makeColorAccessors(layer, options);
    const params = layer.params || {};
    const aes = layer.aes || {};
    const data = layer.data || [];

    const xRange = xScale.range();
    const x0 = Math.min(xRange[0], xRange[1]);
    const x1 = Math.max(xRange[0], xRange[1]);

    const lines = g.selectAll("line.geom-hline")
      .data(data)
      .enter()
      .append("line")
      .attr("class", "geom-hline")
      .attr("x1", x0)
      .attr("x2", x1)
      .attr("y1", d => yScale(d[aes.yintercept || "yintercept"]))
      .attr("y2", d => yScale(d[aes.yintercept || "yintercept"]))
      .attr("stroke", d => strokeColor(d))
      .attr("stroke-width", d => d.linewidth || params.linewidth || 0.5)
      .attr("stroke-dasharray", d => window.gg2d3.helpers.getDashArray(d.linetype || params.linetype))
      .attr("opacity", d => opacity(d));

    return lines.size();
  }

  /**
   * Render geom_vline (vertical lines across full panel)
   */
  function renderVline(layer, g, xScale, yScale, options) {
    const { strokeColor, opacity } = window.gg2d3.geomRegistry.makeColorAccessors(layer, options);
    const params = layer.params || {};
    const aes = layer.aes || {};
    const data = layer.data || [];

    const yRange = yScale.range();
    const y0 = Math.min(yRange[0], yRange[1]);
    const y1 = Math.max(yRange[0], yRange[1]);

    const lines = g.selectAll("line.geom-vline")
      .data(data)
      .enter()
      .append("line")
      .attr("class", "geom-vline")
      .attr("x1", d => xScale(d[aes.xintercept || "xintercept"]))
      .attr("x2", d => xScale(d[aes.xintercept || "xintercept"]))
      .attr("y1", y0)
      .attr("y2", y1)
      .attr("stroke", d => strokeColor(d))
      .attr("stroke-width", d => d.linewidth || params.linewidth || 0.5)
      .attr("stroke-dasharray", d => window.gg2d3.helpers.getDashArray(d.linetype || params.linetype))
      .attr("opacity", d => opacity(d));

    return lines.size();
  }

  /**
   * Render geom_abline (diagonal lines defined by slope/intercept)
   */
  function renderAbline(layer, g, xScale, yScale, options) {
    const { strokeColor, opacity } = window.gg2d3.geomRegistry.makeColorAccessors(layer, options);
    const params = layer.params || {};
    const aes = layer.aes || {};
    const data = layer.data || [];

    const xDomain = xScale.domain();
    const yDomain = yScale.domain();

    // Helper to calculate line coordinates clipped to panel box
    function getAblineCoords(d) {
      const slope = d[aes.slope || "slope"];
      const intercept = d[aes.intercept || "intercept"];

      // Line equation: y = slope * x + intercept
      // Panel boundaries (data space)
      const xMin = xDomain[0], xMax = xDomain[1];
      const yMin = yDomain[0], yMax = yDomain[1];

      let points = [];

      // 1. Intersection with xMin
      const yAtXMin = slope * xMin + intercept;
      if (yAtXMin >= Math.min(yMin, yMax) && yAtXMin <= Math.max(yMin, yMax)) {
        points.push({ x: xMin, y: yAtXMin });
      }

      // 2. Intersection with xMax
      const yAtXMax = slope * xMax + intercept;
      if (yAtXMax >= Math.min(yMin, yMax) && yAtXMax <= Math.max(yMin, yMax)) {
        points.push({ x: xMax, y: yAtXMax });
      }

      // 3. Intersection with yMin
      if (slope !== 0) {
        const xAtYMin = (yMin - intercept) / slope;
        if (xAtYMin >= Math.min(xMin, xMax) && xAtYMin <= Math.max(xMin, xMax)) {
          points.push({ x: xAtYMin, y: yMin });
        }
      }

      // 4. Intersection with yMax
      if (slope !== 0) {
        const xAtYMax = (yMax - intercept) / slope;
        if (xAtYMax >= Math.min(xMin, xMax) && xAtYMax <= Math.max(xMin, xMax)) {
          points.push({ x: xAtYMax, y: yMax });
        }
      }

      // Remove duplicates and sort to get two distinct endpoints
      // (Simple way: just take first 2 unique ones)
      const uniquePoints = [];
      const seen = new Set();
      points.forEach(p => {
        const key = `${p.x.toFixed(6)},${p.y.toFixed(6)}`;
        if (!seen.has(key)) {
          seen.add(key);
          uniquePoints.push(p);
        }
      });

      if (uniquePoints.length < 2) return null;

      return {
        x1: xScale(uniquePoints[0].x),
        y1: yScale(uniquePoints[0].y),
        x2: xScale(uniquePoints[1].x),
        y2: yScale(uniquePoints[1].y)
      };
    }

    const lines = g.selectAll("line.geom-abline")
      .data(data)
      .enter()
      .append("line")
      .attr("class", "geom-abline")
      .each(function(d) {
        const coords = getAblineCoords(d);
        if (coords) {
          d3.select(this)
            .attr("x1", coords.x1)
            .attr("y1", coords.y1)
            .attr("x2", coords.x2)
            .attr("y2", coords.y2);
        } else {
          d3.select(this).remove();
        }
      })
      .attr("stroke", d => strokeColor(d))
      .attr("stroke-width", d => d.linewidth || params.linewidth || 0.5)
      .attr("stroke-dasharray", d => window.gg2d3.helpers.getDashArray(d.linetype || params.linetype))
      .attr("opacity", d => opacity(d));

    return lines.size();
  }

  // Register renderers
  window.gg2d3.geomRegistry.register("hline", renderHline);
  window.gg2d3.geomRegistry.register("vline", renderVline);
  window.gg2d3.geomRegistry.register("abline", renderAbline);

})();
