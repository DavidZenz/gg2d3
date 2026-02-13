/**
 * gg2d3 Tooltip Module
 *
 * Provides singleton tooltip div with viewport-aware positioning and
 * configurable content formatting for interactive D3 visualizations.
 *
 * @module gg2d3.tooltip
 */

(function() {
  'use strict';

  // Initialize gg2d3 namespace if not exists
  if (typeof window.gg2d3 === 'undefined') {
    window.gg2d3 = {};
  }

  /**
   * Get or create singleton tooltip div.
   * Creates a single shared tooltip element in document.body on first call.
   *
   * @returns {d3.selection} D3 selection of tooltip div
   */
  function getOrCreate() {
    let tooltip = d3.select('body').select('.gg2d3-tooltip');

    if (tooltip.empty()) {
      tooltip = d3.select('body').append('div')
        .attr('class', 'gg2d3-tooltip')
        .style('position', 'absolute')
        .style('display', 'none')
        .style('pointer-events', 'none')  // Critical: prevents tooltip from intercepting mouse events
        .style('background', 'white')
        .style('border', '1px solid #ccc')
        .style('border-radius', '4px')
        .style('padding', '6px 10px')
        .style('font-family', 'sans-serif')
        .style('font-size', '12px')
        .style('color', '#333')
        .style('box-shadow', '0 2px 4px rgba(0,0,0,0.15)')
        .style('z-index', '9999')
        .style('max-width', '300px')
        .style('line-height', '1.4');
    }

    return tooltip;
  }

  /**
   * Format tooltip content from data row.
   * Generates HTML string with field names and formatted values.
   *
   * @param {Object} d - Data row bound to SVG element
   * @param {Object} config - Tooltip configuration
   * @param {Array<string>} config.fields - Field names to show (null = all except internals)
   * @param {string} config.formatter - Optional JS function string for custom formatting
   * @returns {string} HTML string for tooltip content
   */
  function format(d, config) {
    // Determine which fields to show
    let fields;
    if (config.fields) {
      fields = config.fields;
    } else {
      // Show all fields except internals (underscore prefix, PANEL, group, SCALE_X, SCALE_Y)
      const internalKeys = ['PANEL', 'group', 'SCALE_X', 'SCALE_Y'];
      fields = Object.keys(d).filter(k =>
        !k.startsWith('_') && !internalKeys.includes(k)
      );
    }

    // Custom formatter if provided
    let formatter = null;
    if (config.formatter) {
      try {
        formatter = new Function('field', 'value', config.formatter);
      } catch (e) {
        console.warn('gg2d3: Invalid tooltip formatter function:', e);
      }
    }

    // Generate HTML for each field
    const lines = fields.map(field => {
      const value = d[field];

      // Format value
      let formatted;
      if (formatter) {
        formatted = formatter(field, value);
      } else {
        // Default formatting
        let displayValue = value;
        if (typeof value === 'number') {
          // Format numbers with up to 4 significant digits
          displayValue = parseFloat(value.toPrecision(4));
        }
        formatted = `<strong>${field}:</strong> ${displayValue}`;
      }

      return `<div style="margin:1px 0">${formatted}</div>`;
    });

    return lines.join('');
  }

  /**
   * Show tooltip at cursor position with data content.
   *
   * @param {Event} event - Mouse event
   * @param {Object} d - Data row to display
   * @param {Object} config - Tooltip configuration
   */
  function show(event, d, config) {
    const tooltip = getOrCreate();
    tooltip.style('display', 'block');
    tooltip.html(format(d, config));
    position(event, tooltip);
  }

  /**
   * Update tooltip position on mouse move.
   *
   * @param {Event} event - Mouse event
   */
  function move(event) {
    const tooltip = getOrCreate();
    position(event, tooltip);
  }

  /**
   * Hide tooltip.
   */
  function hide() {
    const tooltip = getOrCreate();
    tooltip.style('display', 'none');
  }

  /**
   * Position tooltip with viewport-aware edge detection.
   * Adjusts position to keep tooltip visible when near viewport edges.
   *
   * @param {Event} event - Mouse event with pageX/pageY coordinates
   * @param {d3.selection} tooltipDiv - D3 selection of tooltip div
   */
  function position(event, tooltipDiv) {
    const tooltip = tooltipDiv.node();
    const bounds = tooltip.getBoundingClientRect();
    const offset = 12;  // px from cursor

    let x = event.pageX + offset;
    let y = event.pageY + offset;

    // Check right edge - flip to left of cursor if too close
    if (x + bounds.width > window.innerWidth) {
      x = event.pageX - bounds.width - offset;
    }

    // Check bottom edge - flip above cursor if too close
    if (y + bounds.height > window.innerHeight + window.scrollY) {
      y = event.pageY - bounds.height - offset;
    }

    // Fallback: clamp to prevent going off-screen left or top
    if (x < 0) {
      x = offset;
    }
    if (y < window.scrollY) {
      y = window.scrollY + offset;
    }

    tooltipDiv
      .style('left', x + 'px')
      .style('top', y + 'px');
  }

  /**
   * Export tooltip module API
   */
  window.gg2d3.tooltip = {
    getOrCreate: getOrCreate,
    format: format,
    show: show,
    move: move,
    hide: hide,
    position: position
  };
})();
