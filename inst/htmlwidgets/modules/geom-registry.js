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

  // Export to window.gg2d3.geomRegistry namespace
  window.gg2d3.geomRegistry.register = registerGeom;
  window.gg2d3.geomRegistry.render = renderGeom;
  window.gg2d3.geomRegistry.has = hasGeom;
  window.gg2d3.geomRegistry.list = listGeoms;
  window.gg2d3.geomRegistry.makeColorAccessors = makeColorAccessors;

})();
