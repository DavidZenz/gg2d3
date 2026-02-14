/**
 * gg2d3 Crosstalk Module
 *
 * Provides Crosstalk integration for linked brushing across gg2d3 widgets
 * and other Crosstalk-compatible widgets (DT, plotly, leaflet).
 * Also provides Shiny message handlers for server-side reactivity.
 *
 * @module gg2d3.crosstalk
 */

(function() {
  'use strict';

  // Initialize gg2d3 namespace if not exists
  if (typeof window.gg2d3 === 'undefined') {
    window.gg2d3 = {};
  }

  /**
   * CSS selectors for interactive geom elements (shared with brush.js).
   */
  const INTERACTIVE_SELECTORS = [
    'circle.geom-point',
    'rect.geom-bar',
    'rect.geom-rect',
    'path.geom-line',
    'path.geom-area',
    'path.geom-density',
    'path.geom-smooth',
    'path.geom-ribbon',
    'path.geom-violin',
    'text.geom-text',
    'line.geom-segment',
    'rect.geom-boxplot-box',
    'circle.geom-boxplot-outlier'
  ];

  /**
   * Store active SelectionHandle instances by element ID.
   */
  const selectionHandles = {};

  /**
   * Initialize Crosstalk for a gg2d3 widget.
   *
   * Creates a SelectionHandle to listen for selection changes from other widgets
   * and enables broadcasting of selections from this widget.
   *
   * @param {HTMLElement} el - Widget container element
   * @param {Array} crosstalkKey - Array mapping data row indices to crosstalk keys
   * @param {string} crosstalkGroup - Crosstalk group name for linked widgets
   */
  function init(el, crosstalkKey, crosstalkGroup) {
    // Guard against missing crosstalk library
    if (typeof crosstalk === 'undefined') {
      console.warn('gg2d3.crosstalk: crosstalk library not loaded');
      return;
    }

    const svg = d3.select(el).select('svg');
    if (svg.empty()) {
      console.warn('gg2d3.crosstalk: SVG element not found');
      return;
    }

    // Create SelectionHandle for this group
    const sel = new crosstalk.SelectionHandle(crosstalkGroup);
    selectionHandles[el.id] = sel;

    // Listen for selection changes from other widgets
    sel.on("change", function(e) {
      const selectedKeys = e.value;  // null or array of keys

      if (!selectedKeys || selectedKeys.length === 0) {
        // Clear: restore all elements to full opacity
        restoreAllOpacity(svg);
        return;
      }

      // Highlight: dim non-selected, brighten selected
      highlightByKeys(svg, selectedKeys, crosstalkKey);
    });

    // Store references for later use
    el._gg2d3_crosstalk = {
      sel: sel,
      crosstalkKey: crosstalkKey,
      crosstalkGroup: crosstalkGroup
    };
  }

  /**
   * Highlight elements matching selected keys, dim others.
   *
   * @param {d3.Selection} svg - SVG element selection
   * @param {Array} selectedKeys - Array of crosstalk keys to highlight
   * @param {Array} keyArray - Array mapping data indices to crosstalk keys
   */
  function highlightByKeys(svg, selectedKeys, keyArray) {
    const keySet = new Set(selectedKeys);

    // Process each panel (handles both faceted and non-faceted plots)
    svg.selectAll('.panel').each(function() {
      const panel = d3.select(this);
      const clippedGroup = panel.select('g[clip-path]');
      if (clippedGroup.empty()) return;

      // Process each geom type
      INTERACTIVE_SELECTORS.forEach(selector => {
        clippedGroup.selectAll(selector).each(function(d, i) {
          const elem = d3.select(this);

          // Check if this data point's key is in the selected set
          // keyArray maps data row index to crosstalk key
          const dataKey = keyArray[i];
          const isSelected = keySet.has(dataKey);

          elem.style('opacity', isSelected ? 1.0 : 0.15);
        });
      });
    });
  }

  /**
   * Restore all elements to full opacity.
   *
   * @param {d3.Selection} svg - SVG element selection
   */
  function restoreAllOpacity(svg) {
    svg.selectAll('.panel').each(function() {
      const panel = d3.select(this);
      const clippedGroup = panel.select('g[clip-path]');
      if (clippedGroup.empty()) return;

      INTERACTIVE_SELECTORS.forEach(selector => {
        clippedGroup.selectAll(selector).each(function() {
          const elem = d3.select(this);
          const originalOpacity = elem.attr('data-original-opacity');
          if (originalOpacity) {
            elem.style('opacity', originalOpacity);
          } else {
            elem.style('opacity', null); // Remove inline style
          }
        });
      });
    });
  }

  /**
   * Broadcast selection to linked widgets.
   *
   * Maps data indices to crosstalk keys and broadcasts via SelectionHandle.
   *
   * @param {HTMLElement} el - Widget container element
   * @param {Array} selectedIndices - Array of data row indices that are selected
   */
  function broadcastSelection(el, selectedIndices) {
    if (!el._gg2d3_crosstalk) {
      console.warn('gg2d3.crosstalk: Crosstalk not initialized for this widget');
      return;
    }

    const { sel, crosstalkKey } = el._gg2d3_crosstalk;

    // Map indices to keys
    const selectedKeys = selectedIndices.map(i => crosstalkKey[i]).filter(k => k !== undefined);

    if (selectedKeys.length > 0) {
      sel.set(selectedKeys);
    } else {
      sel.clear();
    }
  }

  /**
   * Clear selection across all linked widgets.
   *
   * @param {HTMLElement} el - Widget container element
   */
  function clearSelection(el) {
    if (!el._gg2d3_crosstalk) return;

    const { sel } = el._gg2d3_crosstalk;
    sel.clear();
  }

  /**
   * Connect brush module to crosstalk for linked brushing.
   *
   * Hooks into brush end events to broadcast selections to linked widgets.
   *
   * @param {HTMLElement} el - Widget container element
   * @param {Object} brushModule - Reference to gg2d3.brush module
   */
  function connectBrush(el, brushModule) {
    // This would require modifying brush.js to expose events
    // For now, brush.js will directly call broadcastSelection
    // when crosstalk is detected
    console.log('gg2d3.crosstalk: Brush connection placeholder');
  }

  /**
   * Programmatically select elements by keys (for Shiny server-side control).
   *
   * @param {HTMLElement} el - Widget container element
   * @param {Array} keys - Array of crosstalk keys to select
   */
  function selectByKeys(el, keys) {
    if (!el._gg2d3_crosstalk) {
      console.warn('gg2d3.crosstalk: Crosstalk not initialized for this widget');
      return;
    }

    const { sel } = el._gg2d3_crosstalk;
    sel.set(keys);
  }

  /**
   * Initialize Shiny message handlers for a widget.
   *
   * Enables server-side control of zoom, selection, etc.
   *
   * @param {HTMLElement} el - Widget container element
   */
  function initShinyHandlers(el) {
    // Guard: only run in Shiny mode
    if (typeof HTMLWidgets === 'undefined' || !HTMLWidgets.shinyMode) {
      return;
    }

    // Guard: Shiny must be available
    if (typeof Shiny === 'undefined') {
      return;
    }

    const elementId = el.id;

    // Register custom message handler: reset zoom
    Shiny.addCustomMessageHandler("gg2d3_reset_" + elementId, function(message) {
      if (window.gg2d3.zoom) {
        window.gg2d3.zoom.reset(el);
      }
    });

    // Register custom message handler: programmatic selection
    Shiny.addCustomMessageHandler("gg2d3_select_" + elementId, function(message) {
      if (window.gg2d3.crosstalk && message.keys) {
        selectByKeys(el, message.keys);
      }
    });
  }

  /**
   * Export crosstalk module API
   */
  window.gg2d3.crosstalk = {
    init: init,
    broadcastSelection: broadcastSelection,
    clearSelection: clearSelection,
    connectBrush: connectBrush,
    selectByKeys: selectByKeys,
    initShinyHandlers: initShinyHandlers
  };
})();
