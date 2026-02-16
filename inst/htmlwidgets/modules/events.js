/**
 * gg2d3 Events Module
 *
 * Provides event attachment system for interactive features (tooltips, hover effects).
 * Attaches D3 event handlers to geom elements using CSS selectors.
 *
 * @module gg2d3.events
 */

(function() {
  'use strict';

  // Initialize gg2d3 namespace if not exists
  if (typeof window.gg2d3 === 'undefined') {
    window.gg2d3 = {};
  }

  /**
   * CSS selectors for interactive geom elements.
   * Uses class selectors for paths to distinguish geom types.
   * Excludes non-interactive elements like panel backgrounds.
   */
  const INTERACTIVE_SELECTORS = [
    'circle.geom-point',         // geom_point
    'rect.geom-bar',             // geom_bar
    'rect.geom-rect',            // geom_rect / geom_tile
    'path.geom-line',            // geom_line
    'path.geom-area',            // geom_area
    'path.geom-density',         // geom_density
    'path.geom-smooth',          // geom_smooth
    'path.geom-ribbon',          // geom_ribbon
    'path.geom-violin',          // geom_violin
    'text.geom-text',            // geom_text
    'line.geom-segment',         // geom_segment
    'rect.geom-boxplot-box',     // geom_boxplot (IQR box)
    'circle.geom-boxplot-outlier' // geom_boxplot (outliers)
  ];

  /**
   * Attach tooltip event handlers to interactive elements.
   * Finds all geom elements matching INTERACTIVE_SELECTORS and adds
   * mouseover/mousemove/mouseout handlers that show/move/hide tooltip.
   *
   * @param {HTMLElement} el - Widget container element
   * @param {Object} config - Tooltip configuration
   * @param {Array<string>} config.fields - Field names to show (null = all)
   * @param {string} config.formatter - Optional JS function string
   */
  function attachTooltips(el, config) {
    const svg = d3.select(el).select('svg');

    INTERACTIVE_SELECTORS.forEach(selector => {
      const selection = svg.selectAll(selector);

      // Skip if no elements match this selector
      if (selection.empty()) {
        return;
      }

      selection
        .on('mouseover.tooltip', function(event, d) {
          window.gg2d3.tooltip.show(event, d, config);
        })
        .on('mousemove.tooltip', function(event) {
          window.gg2d3.tooltip.move(event);
        })
        .on('mouseout.tooltip', function() {
          window.gg2d3.tooltip.hide();
        });
    });
  }

  /**
   * Attach hover effect handlers to interactive elements.
   * On hover: dims all sibling elements, highlights hovered element.
   * On mouseout: restores original opacity.
   *
   * @param {HTMLElement} el - Widget container element
   * @param {Object} config - Hover configuration
   * @param {number} config.opacity - Opacity for non-hovered elements (0-1)
   * @param {string} config.stroke - Optional stroke color for hovered element
   * @param {number} config.stroke_width - Optional stroke width for hovered element
   */
  function attachHover(el, config) {
    const svg = d3.select(el).select('svg');

    INTERACTIVE_SELECTORS.forEach(selector => {
      const selection = svg.selectAll(selector);

      // Skip if no elements match this selector
      if (selection.empty()) {
        return;
      }

      // Store original opacity values on first setup
      selection.each(function() {
        const elem = d3.select(this);
        if (!elem.attr('data-original-opacity')) {
          const currentOpacity = elem.style('opacity') || elem.attr('opacity') || '1';
          elem.attr('data-original-opacity', currentOpacity);
        }
      });

      selection
        .on('mouseover.hover', function(event, d) {
          // When brush selection is active, skip hover dimming to avoid
          // overriding the brush's opacity state
          var panelNode = this.closest('.panel');
          if (panelNode && panelNode.getAttribute('data-brush-active') === 'true') {
            return;
          }

          // Dim all interactive elements
          INTERACTIVE_SELECTORS.forEach(sel => {
            svg.selectAll(sel)
              .style('opacity', config.opacity);
          });

          // Highlight this element
          const elem = d3.select(this);
          elem.style('opacity', 1.0);

          // Add stroke if configured
          if (config.stroke) {
            elem.attr('data-hover-stroke', '1');
            elem.style('stroke', config.stroke);
            if (config.stroke_width) {
              elem.style('stroke-width', config.stroke_width);
            }
          }
        })
        .on('mouseout.hover', function() {
          // When brush is active, skip hover restore
          var panelNode = this.closest('.panel');
          if (panelNode && panelNode.getAttribute('data-brush-active') === 'true') {
            return;
          }

          // Restore original opacity for all elements
          INTERACTIVE_SELECTORS.forEach(sel => {
            svg.selectAll(sel).each(function() {
              const elem = d3.select(this);
              const originalOpacity = elem.attr('data-original-opacity') || '1';
              elem.style('opacity', originalOpacity);
            });
          });

          // Remove hover stroke if it was added
          const elem = d3.select(this);
          if (elem.attr('data-hover-stroke')) {
            elem.attr('data-hover-stroke', null);
            elem.style('stroke', null);
            elem.style('stroke-width', null);
          }
        });
    });
  }

  /**
   * Export events module API
   */
  window.gg2d3.events = {
    attachTooltips: attachTooltips,
    attachHover: attachHover
  };
})();
