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
  const FALLBACK_INTERACTIVE_SELECTORS = [
    'circle.geom-point',
    'rect.geom-bar',
    'rect.geom-rect',
    'path.geom-line',
    'path.geom-polygon',
    'path.geom-area',
    'path.geom-density',
    'path.geom-smooth',
    'path.geom-ribbon',
    'path.geom-violin',
    '.geom-sf',                  // geom_sf and sf annotations: path/circle/text/g marks
    'text.geom-text',
    'line.geom-segment',
    'rect.geom-boxplot-box',
    'circle.geom-boxplot-outlier'
  ];
  const contractCrosstalkSelectors = window.gg2d3.geomContracts &&
    typeof window.gg2d3.geomContracts.selectorsFor === 'function'
      ? window.gg2d3.geomContracts.selectorsFor('crosstalk')
      : [];
  const INTERACTIVE_SELECTORS = contractCrosstalkSelectors.length
    ? contractCrosstalkSelectors
    : FALLBACK_INTERACTIVE_SELECTORS;

  /**
   * Store active SelectionHandle instances by element ID.
   */
  const selectionHandles = {};

  function getCrosstalkLib() {
    if (typeof window !== 'undefined' && window.crosstalk) {
      return window.crosstalk;
    }
    if (typeof globalThis !== 'undefined' && globalThis.crosstalk) {
      return globalThis.crosstalk;
    }
    if (typeof self !== 'undefined' && self.crosstalk) {
      return self.crosstalk;
    }
    if (typeof global !== 'undefined' && global.crosstalk) {
      return global.crosstalk;
    }
    if (typeof crosstalk !== 'undefined') {
      return crosstalk;
    }
    return null;
  }

  function isAvailable() {
    const crosstalkLib = getCrosstalkLib();
    return !!(crosstalkLib && crosstalkLib.SelectionHandle);
  }

  function bind(el, crosstalkKey, crosstalkGroup) {
    const svg = d3.select(el).select('svg');
    if (svg.empty()) {
      console.warn('gg2d3.crosstalk: SVG element not found');
      return false;
    }

    el.setAttribute('data-gg2d3-crosstalk-group', crosstalkGroup);
    el._gg2d3_crosstalk = Object.assign(el._gg2d3_crosstalk || {}, {
      crosstalkKey: crosstalkKey,
      crosstalkGroup: crosstalkGroup,
      syncLock: false
    });

    bindCrosstalkKeys(svg, crosstalkKey);
    return true;
  }

  function isLegendKeyVisible(state, key) {
    if (!key) return true;
    if (state && state.persistent && state.persistent.solo !== null) {
      return key === state.persistent.solo;
    }
    const hidden = (state && state.persistent && state.persistent.hidden) || [];
    return hidden.indexOf(key) === -1;
  }

  function applyCrosstalkSelection(el, selectedKeys) {
    if (window.gg2d3.events && window.gg2d3.events.setCrosstalkSelection) {
      window.gg2d3.events.setCrosstalkSelection(el, selectedKeys || []);
      return;
    }

    const svg = d3.select(el).select('svg');
    if (svg.empty()) return;

    if (!selectedKeys || selectedKeys.length === 0) {
      restoreAllOpacity(svg);
    } else {
      highlightByKeys(svg, selectedKeys);
    }
  }

  function syncLegendToCrosstalk(el, legendState) {
    if (!el._gg2d3_crosstalk || !legendState) return;
    const meta = el._gg2d3_crosstalk;
    if (meta.syncLock) return;

    const svg = d3.select(el).select('svg');
    if (svg.empty()) return;

    const visibleKeys = new Set();
    const allKeys = new Set();

    svg.selectAll('.panel').each(function() {
      const panel = d3.select(this);
      const clippedGroup = panel.select('g[clip-path]');
      if (clippedGroup.empty()) return;

      INTERACTIVE_SELECTORS.forEach(function(selector) {
        clippedGroup.selectAll(selector).each(function() {
          const elem = d3.select(this);
          const crosstalkKey = elem.attr('data-crosstalk-key');
          if (!crosstalkKey) return;

          const legendKey = elem.attr('data-legend-key');
          allKeys.add(crosstalkKey);
          if (isLegendKeyVisible(legendState, legendKey)) {
            visibleKeys.add(crosstalkKey);
          }
        });
      });
    });

    // Sync contract:
    // - legend persistent states (toggle/solo/reset) publish visible crosstalk keys
    //   through SelectionHandle so linked widgets receive identical filtering.
    // - if legend allows all keys, clear selection to avoid imposing redundant filters.
    const visible = Array.from(visibleKeys);
    const total = allKeys.size;

    meta.syncLock = true;
    try {
      if (!visible.length || visible.length === total) {
        meta.sel.clear();
      } else {
        meta.sel.set(visible);
      }
    } finally {
      meta.syncLock = false;
    }
  }

  function crosstalkKeyIndex(d, fallbackIndex) {
    if (d && d._sourceIndex !== null && d._sourceIndex !== undefined) {
      const sourceIndex = Number(d._sourceIndex);
      if (Number.isFinite(sourceIndex) && sourceIndex >= 0) return sourceIndex;
    }
    return fallbackIndex;
  }

  function bindCrosstalkKeys(svg, keyArray) {
    svg.selectAll('.panel').each(function() {
      const panel = d3.select(this);
      const clippedGroup = panel.select('g[clip-path]');
      if (clippedGroup.empty()) return;

      INTERACTIVE_SELECTORS.forEach(function(selector) {
        clippedGroup.selectAll(selector).each(function(d, i) {
          const rowIndex = crosstalkKeyIndex(d, i);
          const key = keyArray && keyArray[rowIndex] !== undefined ? keyArray[rowIndex] : null;
          d3.select(this).attr('data-crosstalk-key', key == null ? null : String(key));
        });
      });
    });
  }

  function applyLocalGroupSelection(crosstalkGroup, selectedKeys) {
    if (!crosstalkGroup || typeof document === 'undefined') return;

    const keys = Array.isArray(selectedKeys)
      ? selectedKeys.filter(k => k !== null && k !== undefined).map(String)
      : [];

    document.querySelectorAll('.gg2d3.html-widget').forEach(function(widgetEl) {
      if (widgetEl.getAttribute('data-gg2d3-crosstalk-group') !== crosstalkGroup) return;
      applyCrosstalkSelection(widgetEl, keys);
    });
  }

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
    if (!bind(el, crosstalkKey, crosstalkGroup)) {
      return;
    }

    // Guard against missing crosstalk library
    const crosstalkLib = getCrosstalkLib();
    if (!crosstalkLib || !crosstalkLib.SelectionHandle) {
      return;
    }

    if (el._gg2d3_crosstalk.sel && typeof el._gg2d3_crosstalk.sel.close === 'function') {
      el._gg2d3_crosstalk.sel.close();
    }

    // Create SelectionHandle for this group
    const sel = new crosstalkLib.SelectionHandle(crosstalkGroup);
    selectionHandles[el.id] = sel;

    // Listen for selection changes from other widgets.
    // Synchronization contract with legend interactions:
    // 1) Crosstalk SelectionHandle change events are treated as linked persistent state
    //    and routed through events.setCrosstalkSelection() so legend + mark visuals are
    //    recomputed by one shared pipeline (events.applyLegendState).
    // 2) Legend persistent changes (toggle/solo/reset) publish back through this same
    //    SelectionHandle using existing sel.set()/sel.clear() transport.
    // 3) Hover preview never propagates to crosstalk (transient-only by design).
    sel.on("change", function(e) {
      const selectedKeys = e.value;  // null or array of keys

      if (el._gg2d3_crosstalk && el._gg2d3_crosstalk.syncLock) {
        return;
      }

      applyCrosstalkSelection(el, selectedKeys);
    });

    // Store references for later use
    el._gg2d3_crosstalk = Object.assign(el._gg2d3_crosstalk || {}, {
      sel: sel,
      crosstalkKey: crosstalkKey,
      crosstalkGroup: crosstalkGroup,
      syncLock: false
    });

    if (window.gg2d3.events && window.gg2d3.events.applyLegendState) {
      window.gg2d3.events.applyLegendState(el);
    }

    if (window.gg2d3.events && window.gg2d3.events.onLegendChanged) {
      window.gg2d3.events.onLegendChanged(el, 'crosstalk-sync', function(payload) {
        if (!payload || !payload.state) return;
        if (payload.source === 'hoverin' || payload.source === 'hoverout' || payload.source === 'crosstalk') {
          return;
        }
        syncLegendToCrosstalk(el, payload.state);
      });
    }
  }

  /**
   * Highlight elements matching selected keys, dim others.
   *
   * @param {d3.Selection} svg - SVG element selection
   * @param {Array} selectedKeys - Array of crosstalk keys to highlight
   * @param {Array} keyArray - Array mapping data indices to crosstalk keys
   */
  function highlightByKeys(svg, selectedKeys) {
    const keySet = new Set(selectedKeys);

    // Process each panel (handles both faceted and non-faceted plots)
    svg.selectAll('.panel').each(function() {
      const panel = d3.select(this);
      const clippedGroup = panel.select('g[clip-path]');
      if (clippedGroup.empty()) return;

      // Process each geom type
      INTERACTIVE_SELECTORS.forEach(selector => {
        clippedGroup.selectAll(selector).each(function() {
          const elem = d3.select(this);

          const dataKey = elem.attr('data-crosstalk-key');
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

    const { sel, crosstalkKey, crosstalkGroup } = el._gg2d3_crosstalk;

    // Map indices to keys
    const selectedKeys = selectedIndices.map(i => crosstalkKey[i]).filter(k => k !== undefined);

    if (sel) {
      if (selectedKeys.length > 0) {
        sel.set(selectedKeys);
      } else {
        sel.clear();
      }
    }
    applyLocalGroupSelection(crosstalkGroup, selectedKeys);
  }

  /**
   * Clear selection across all linked widgets.
   *
   * @param {HTMLElement} el - Widget container element
   */
  function clearSelection(el) {
    if (!el._gg2d3_crosstalk) return;

    const { sel, crosstalkGroup } = el._gg2d3_crosstalk;
    if (sel) {
      sel.clear();
    }
    applyLocalGroupSelection(crosstalkGroup, []);
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

    const selectedKeys = Array.isArray(keys)
      ? keys.filter(k => k !== null && k !== undefined).map(String)
      : [];
    const { sel, crosstalkGroup } = el._gg2d3_crosstalk;
    if (sel) {
      sel.set(selectedKeys);
    }
    applyLocalGroupSelection(crosstalkGroup, selectedKeys);
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
    isAvailable: isAvailable,
    bind: bind,
    init: init,
    broadcastSelection: broadcastSelection,
    clearSelection: clearSelection,
    connectBrush: connectBrush,
    selectByKeys: selectByKeys,
    initShinyHandlers: initShinyHandlers
  };
})();
