/**
 * gg2d3 Geom Registry Module
 *
 * Central registry for geom renderers. Provides:
 * - register() - Add new geom renderer
 * - render() - Dispatch to appropriate renderer
 * - has() - Check if geom registered
 * - list() - List all registered geoms
 * - makeColorAccessors() - Utility for creating color/fill/opacity accessors
 *
 * @module gg2d3.geomRegistry
 */

(function() {
  'use strict';

  // Initialize namespace
  if (!window.gg2d3) window.gg2d3 = {};
  if (!window.gg2d3.geomRegistry) window.gg2d3.geomRegistry = {};

  // Registry storage: geom name -> renderer function
  const renderers = {};

  /**
   * Geom Renderer Interface
   *
   * All geom renderers must implement this function signature:
   *
   * @callback GeomRenderer
   * @param {Object} layer - Layer object from IR
   * @param {Object} layer.data - Layer data (column-oriented or row array)
   * @param {Object} layer.aes - Aesthetic mappings {x, y, color, fill, size, ...}
   * @param {Object} layer.params - Static parameters (colour, fill, size, linewidth, ...)
   * @param {string} layer.geom - Geom type name
   * @param {d3.Selection} g - D3 selection of plot group (with transform applied)
   * @param {Function} xScale - D3 x scale
   * @param {Function} yScale - D3 y scale
   * @param {Object} options - Rendering options
   * @param {Function} options.colorScale - D3 color scale (if defined)
   * @returns {number} Number of marks drawn (for debugging)
   *
   * @example
   * function renderPoint(layer, g, xScale, yScale, options) {
   *   const { strokeColor, fillColor, opacity } =
   *     window.gg2d3.geomRegistry.makeColorAccessors(layer, options);
   *
   *   // ... render circles using accessors ...
   *
   *   return numPointsDrawn;
   * }
   */

  /**
   * Register a geom renderer.
   * Allows multiple names (aliases) for same renderer.
   *
   * @param {string|Array<string>} names - Geom name(s) to register
   * @param {GeomRenderer} renderer - Renderer function
   *
   * @example
   * registerGeom('point', renderPoint);
   * registerGeom(['line', 'path'], renderLine);
   */
  function registerGeom(names, renderer) {
    const nameArray = Array.isArray(names) ? names : [names];
    nameArray.forEach(name => {
      renderers[name] = renderer;
    });
  }

  /**
   * Check if geom is registered.
   *
   * @param {string} name - Geom name
   * @returns {boolean} True if registered
   */
  function hasGeom(name) {
    return !!renderers[name];
  }

  /**
   * List all registered geom names.
   *
   * @returns {Array<string>} Array of geom names
   */
  function listGeoms() {
    return Object.keys(renderers);
  }

  /**
   * Render a layer using the registered renderer.
   * Logs warning if geom not registered.
   *
   * @param {Object} layer - Layer object from IR
   * @param {d3.Selection} g - D3 plot group selection
   * @param {Function} xScale - D3 x scale
   * @param {Function} yScale - D3 y scale
   * @param {Object} options - Rendering options
   * @returns {number} Number of marks drawn (0 if not found)
   */
  function renderGeom(layer, g, xScale, yScale, options) {
    const renderer = renderers[layer.geom];
    if (!renderer) {
      console.warn(`gg2d3: Unknown geom type "${layer.geom}" - no renderer registered`);
      return 0;
    }
    return renderer(layer, g, xScale, yScale, options);
  }

  /**
   * Create color/fill/opacity accessor functions for a layer.
   * Handles aesthetic mappings, color scales, and static parameters.
   *
   * Uses gg2d3.helpers utilities and gg2d3.scales.convertColor.
   *
   * @param {Object} layer - Layer object from IR
   * @param {Object} options - Rendering options
   * @param {Function} options.colorScale - D3 color scale (if defined)
   * @returns {Object} Accessor functions {strokeColor, fillColor, opacity}
   *
   * @example
   * const { strokeColor, fillColor, opacity } = makeColorAccessors(layer, options);
   * circle.attr("fill", d => fillColor(d))
   *       .attr("stroke", d => strokeColor(d))
   *       .attr("opacity", d => opacity(d));
   */
  function makeColorAccessors(layer, options) {
    const aes = layer.aes || {};
    const params = layer.params || {};
    const colorScale = options.colorScale || (() => null);

    // Get helper functions
    const val = window.gg2d3.helpers.val;
    const isValidColor = window.gg2d3.helpers.isValidColor;
    const convertColor = window.gg2d3.scales.convertColor;

    // Helper to get column value from row
    const get = (d, k) => (k && d != null) ? d[k] : null;

    /**
     * Get stroke/border color for a data point.
     * Priority: aes.color (mapped) > params.colour (static) > 'currentColor'
     */
    const strokeColor = d => {
      if (aes.color) {
        const v = val(get(d, aes.color));
        // If it's already a valid color (hex or named like "black"), use it directly
        if (isValidColor(v)) return convertColor(v);
        // Try R color conversion (e.g., "grey50" -> "#7F7F7F")
        const converted = convertColor(v);
        if (converted !== v) return converted;
        // Otherwise map through color scale
        const mapped = colorScale(v);
        return mapped || convertColor(params.colour) || "currentColor";
      }
      return convertColor(params.colour) || "currentColor";
    };

    /**
     * Get fill color for a data point.
     * Priority: aes.fill (mapped) > params.fill (static) > 'grey35'
     */
    const fillColor = d => {
      if (aes.fill) {
        const v = val(get(d, aes.fill));
        // If it's already a valid color (hex or named), use it directly
        if (isValidColor(v)) return convertColor(v);
        // Try R color conversion (e.g., "grey70" -> "#B3B3B3")
        const converted = convertColor(v);
        if (converted !== v) return converted;
        // Otherwise map through color scale
        const mapped = colorScale(v);
        return mapped || convertColor(params.fill) || "grey35";
      }
      return convertColor(params.fill) || "grey35";
    };

    /**
     * Get opacity for a data point.
     * Priority: aes.alpha (mapped) > 1.0 (fully opaque)
     */
    const opacity = d => {
      if (aes.alpha) {
        const v = val(get(d, aes.alpha));
        return (v == null ? 1 : +v);
      }
      return 1;
    };

    return { strokeColor, fillColor, opacity };
  }

  /**
   * Update (reposition) all geom elements using new scales.
   * Centralizes element updates for zoom and transitions.
   *
   * @param {d3.Selection} container - Container holding the panels/groups
   * @param {Function} xScale - D3 x scale
   * @param {Function} yScale - D3 y scale
   * @param {Object} options - Update options (flip, transition)
   */
  function updateGeoms(container, xScale, yScale, options) {
    const flip = !!options.flip;
    const t = options.transition || d3.transition().duration(0);

    const xScaleFunc = flip ? yScale : xScale;
    const yScaleFunc = flip ? xScale : yScale;

    // geom_point
    container.selectAll('circle.geom-point')
      .transition(t)
      .attr('cx', d => xScaleFunc(d.x))
      .attr('cy', d => yScaleFunc(d.y));

    // geom_bar
    container.selectAll('rect.geom-bar')
      .transition(t)
      .each(function(d) {
        const elem = d3.select(this);
        if (flip) {
          const y0 = yScaleFunc(d.y);
          const y1 = yScaleFunc(d.yend);
          const x0 = xScaleFunc(d.xmin);
          const x1 = xScaleFunc(d.xmax);
          elem
            .attr('x', Math.min(y0, y1))
            .attr('y', Math.min(x0, x1))
            .attr('width', Math.abs(y1 - y0))
            .attr('height', Math.abs(x1 - x0));
        } else {
          const bx0 = xScaleFunc(d.xmin);
          const bx1 = xScaleFunc(d.xmax);
          const by0 = yScaleFunc(d.y);
          const by1 = yScaleFunc(d.yend);
          elem
            .attr('x', Math.min(bx0, bx1))
            .attr('y', Math.min(by0, by1))
            .attr('width', Math.abs(bx1 - bx0))
            .attr('height', Math.abs(by1 - by0));
        }
      });

    // geom_rect / geom_tile
    container.selectAll('rect.geom-rect')
      .transition(t)
      .attr('x', d => Math.min(xScaleFunc(d.xmin), xScaleFunc(d.xmax)))
      .attr('y', d => Math.min(yScaleFunc(d.ymin), yScaleFunc(d.ymax)))
      .attr('width', d => Math.abs(xScaleFunc(d.xmax) - xScaleFunc(d.xmin)))
      .attr('height', d => Math.abs(yScaleFunc(d.ymax) - yScaleFunc(d.ymin)));

    // geom_text
    container.selectAll('text.geom-text')
      .transition(t)
      .attr('x', d => xScaleFunc(d.x))
      .attr('y', d => yScaleFunc(d.y));

    // geom_segment
    container.selectAll('line.geom-segment')
      .transition(t)
      .attr('x1', d => xScaleFunc(d.x))
      .attr('y1', d => yScaleFunc(d.y))
      .attr('x2', d => xScaleFunc(d.xend))
      .attr('y2', d => yScaleFunc(d.yend));

    // geom_ribbon, geom_violin, and geom_smooth_ribbon
    const areaRibbon = d3.area()
      .x(pt => xScaleFunc(pt.x))
      .y0(pt => yScaleFunc(pt.ymin))
      .y1(pt => yScaleFunc(pt.ymax));

    container.selectAll('path.geom-ribbon, path.geom-violin, path.geom-smooth-ribbon')
      .transition(t)
      .attr('d', d => areaRibbon(d));

    // Path geoms (line, path, smooth, density-outline)
    const line = d3.line()
      .x(pt => xScaleFunc(pt.x))
      .y(pt => yScaleFunc(pt.y));

    container.selectAll('path.geom-line, path.geom-path, path.geom-smooth, path.geom-density-outline')
      .transition(t)
      .attr('d', d => line(d));

    // geom_area & geom_density
    // ggplot2 density uses ymin for stacking, else it fills to baseline (usually 0)
    // We'll use a helper that checks for ymin
    container.selectAll('path.geom-area, path.geom-density')
      .transition(t)
      .attr('d', function(d) {
        const hasYmin = d.some(p => p.ymin != null);
        const y0Func = hasYmin ? (p => yScaleFunc(p.ymin)) : (p => yScaleFunc(p.y0 !== undefined ? p.y0 : 0));
        const areaGen = d3.area()
          .x(p => xScaleFunc(p.x))
          .y0(y0Func)
          .y1(p => yScaleFunc(p.y));
        return areaGen(d);
      });

    // geom_boxplot
    container.selectAll('rect.geom-boxplot-box')
      .transition(t)
      .attr('x', d => Math.min(xScaleFunc(d.xmin), xScaleFunc(d.xmax)))
      .attr('y', d => Math.min(yScaleFunc(d.ymin), yScaleFunc(d.ymax)))
      .attr('width', d => Math.abs(xScaleFunc(d.xmax) - xScaleFunc(d.xmin)))
      .attr('height', d => Math.abs(yScaleFunc(d.ymax) - yScaleFunc(d.ymin)));

    container.selectAll('line.geom-boxplot-whisker, line.geom-boxplot-median, line.geom-boxplot-staple')
      .transition(t)
      .attr('x1', d => xScaleFunc(d.x))
      .attr('y1', d => yScaleFunc(d.y))
      .attr('x2', d => xScaleFunc(d.xend))
      .attr('y2', d => yScaleFunc(d.yend));

    container.selectAll('circle.geom-boxplot-outlier')
      .transition(t)
      .attr('cx', d => xScaleFunc(d.x))
      .attr('cy', d => yScaleFunc(d.y));

    // geom_hline
    container.selectAll('line.geom-hline')
      .transition(t)
      .attr('y1', d => yScaleFunc(d.yintercept))
      .attr('y2', d => yScaleFunc(d.yintercept));

    // geom_vline
    container.selectAll('line.geom-vline')
      .transition(t)
      .attr('x1', d => xScaleFunc(d.xintercept))
      .attr('x2', d => xScaleFunc(d.xintercept));

    // geom_dotplot
    container.selectAll('circle.geom-dotplot')
      .transition(t)
      .attr('cx', d => xScaleFunc(d.x))
      .attr('cy', d => yScaleFunc(d.y));

    // geom_rug
    container.selectAll('line.geom-rug')
      .transition(t)
      .each(function(d) {
        // Rugs are complex because of multiple sides, but we can update positions
        // if we identify which side they belong to. For now, let's just update
        // the coordinate that maps to data.
        const line = d3.select(this);
        const parent = d3.select(this.parentNode);
        const side = parent.attr('class').split('-').pop();
        if (side === 'b' || side === 't') {
          line.attr('x1', xScaleFunc(d.x)).attr('x2', xScaleFunc(d.x));
        } else {
          line.attr('y1', yScaleFunc(d.y)).attr('y2', yScaleFunc(d.y));
        }
      });

    // geom_interval: errorbar
    container.selectAll('g.geom-interval-errorbar g.interval-item')
      .each(function(d) {
        var g = d3.select(this);
        g.select('line.interval-line').transition(t)
          .attr('x1', flip ? yScaleFunc(d.ymin) : xScaleFunc(d.x))
          .attr('x2', flip ? yScaleFunc(d.ymax) : xScaleFunc(d.x))
          .attr('y1', flip ? xScaleFunc(d.x) : yScaleFunc(d.ymin))
          .attr('y2', flip ? xScaleFunc(d.x) : yScaleFunc(d.ymax));
        g.select('line.errorbar-cap-top').transition(t)
          .attr('x1', flip ? yScaleFunc(d.ymax) : xScaleFunc(d.xmin))
          .attr('x2', flip ? yScaleFunc(d.ymax) : xScaleFunc(d.xmax))
          .attr('y1', flip ? xScaleFunc(d.xmin) : yScaleFunc(d.ymax))
          .attr('y2', flip ? xScaleFunc(d.xmax) : yScaleFunc(d.ymax));
        g.select('line.errorbar-cap-bottom').transition(t)
          .attr('x1', flip ? yScaleFunc(d.ymin) : xScaleFunc(d.xmin))
          .attr('x2', flip ? yScaleFunc(d.ymin) : xScaleFunc(d.xmax))
          .attr('y1', flip ? xScaleFunc(d.xmin) : yScaleFunc(d.ymin))
          .attr('y2', flip ? xScaleFunc(d.xmax) : yScaleFunc(d.ymin));
      });

    // geom_interval: linerange
    container.selectAll('g.geom-interval-linerange g.interval-item')
      .each(function(d) {
        var g = d3.select(this);
        g.select('line.interval-line').transition(t)
          .attr('x1', flip ? yScaleFunc(d.ymin) : xScaleFunc(d.x))
          .attr('x2', flip ? yScaleFunc(d.ymax) : xScaleFunc(d.x))
          .attr('y1', flip ? xScaleFunc(d.x) : yScaleFunc(d.ymin))
          .attr('y2', flip ? xScaleFunc(d.x) : yScaleFunc(d.ymax));
      });

    // geom_interval: pointrange
    container.selectAll('g.geom-interval-pointrange g.interval-item')
      .each(function(d) {
        var g = d3.select(this);
        g.select('line.interval-line').transition(t)
          .attr('x1', flip ? yScaleFunc(d.ymin) : xScaleFunc(d.x))
          .attr('x2', flip ? yScaleFunc(d.ymax) : xScaleFunc(d.x))
          .attr('y1', flip ? xScaleFunc(d.x) : yScaleFunc(d.ymin))
          .attr('y2', flip ? xScaleFunc(d.x) : yScaleFunc(d.ymax));
        g.select('circle.pointrange-point').transition(t)
          .attr('cx', flip ? yScaleFunc(d.y) : xScaleFunc(d.x))
          .attr('cy', flip ? xScaleFunc(d.x) : yScaleFunc(d.y));
      });
  }

  // Export to window.gg2d3.geomRegistry namespace
  window.gg2d3.geomRegistry.register = registerGeom;
  window.gg2d3.geomRegistry.render = renderGeom;
  window.gg2d3.geomRegistry.has = hasGeom;
  window.gg2d3.geomRegistry.list = listGeoms;
  window.gg2d3.geomRegistry.makeColorAccessors = makeColorAccessors;
  window.gg2d3.geomRegistry.updateGeoms = updateGeoms;

})();
