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
    'path.geom-polygon',         // geom_polygon
    'path.geom-area',            // geom_area
    'path.geom-density',         // geom_density
    'path.geom-smooth',          // geom_smooth
    'path.geom-ribbon',          // geom_ribbon
    'path.geom-violin',          // geom_violin
    '.geom-sf',                  // geom_sf: path.geom-sf.geom-sf-polygon, path.geom-sf.geom-sf-line, circle.geom-sf.geom-sf-point
    'text.geom-text',            // geom_text
    'line.geom-segment',         // geom_segment
    'rect.geom-boxplot-box',     // geom_boxplot (IQR box)
    'circle.geom-boxplot-outlier', // geom_boxplot (outliers)
    'circle.geom-dotplot',         // geom_dotplot (GEOM-20)
    'line.geom-rug',               // geom_rug (GEOM-21)
    'line.interval-line',          // interval central line (GEOM-22)
    'line.errorbar-cap-top',       // errorbar top cap (GEOM-22)
    'line.errorbar-cap-bottom',    // errorbar bottom cap (GEOM-22)
    'circle.pointrange-point'      // pointrange center dot (GEOM-22)
  ];

  // Per-widget legend interaction controllers.
  // WeakMap ensures cleanup when widget DOM nodes are removed.
  const LEGEND_CONTROLLERS = new WeakMap();
  const DEFAULT_CLICK_DELAY = 250;

  function normalizeLegendValue(value) {
    if (value === null || value === undefined) return '';
    return String(value).trim().toLowerCase();
  }

  function sanitizeEventDatum(d) {
    if (!d || typeof d !== 'object' || Array.isArray(d)) return d;

    const sanitized = {};
    Object.keys(d).forEach(function(key) {
      if (key.startsWith('_')) return;
      sanitized[key] = d[key];
    });
    return sanitized;
  }

  function compileEventHandler(handlerSource) {
    if (!handlerSource) return null;
    const src = String(handlerSource).trim();
    const looksLikeFnExpr = /^\s*(function\b|\(?\s*[\w\s,]*\)?\s*=>)/.test(src);
    if (looksLikeFnExpr) {
      const fn = (new Function('return (' + src + ');'))();
      if (typeof fn !== 'function') {
        throw new Error('handler did not evaluate to a function');
      }
      return fn;
    }
    return new Function('event', 'd', src);
  }

  function getLegendKeyAestheticAliases(aesthetic) {
    if (aesthetic === 'colour') return ['colour', 'color', 'fill'];
    if (aesthetic === 'color') return ['color', 'colour', 'fill'];
    if (aesthetic === 'fill') return ['fill', 'colour', 'color'];
    return [aesthetic];
  }

  function buildLegendLookup(options) {
    const ir = options && options.ir;
    const guides = (ir && ir.guides) ? ir.guides : [];
    const entries = [];

    guides.forEach(function(guide) {
      if (!guide || guide.type !== 'legend' || !guide.keys || !guide.keys.length) return;

      const aesthetics = (guide.aesthetics && guide.aesthetics.length)
        ? guide.aesthetics
        : ['legend'];
      const primaryAesthetic = aesthetics[0];

      guide.keys.forEach(function(key, idx) {
        const level = (key && key.value !== undefined && key.value !== null)
          ? key.value
          : (key && key.label !== undefined ? key.label : idx);
        const legendKey = primaryAesthetic + '::' + String(level);
        const candidates = new Set([
          normalizeLegendValue(level),
          normalizeLegendValue(key && key.label),
          normalizeLegendValue(key && key.value),
          normalizeLegendValue(key && key.colour),
          normalizeLegendValue(key && key.color),
          normalizeLegendValue(key && key.fill),
          normalizeLegendValue(key && key.shape),
          normalizeLegendValue(key && key.size)
        ]);

        entries.push({
          key: legendKey,
          aesthetic: primaryAesthetic,
          level: String(level),
          candidates: candidates
        });
      });
    });

    return entries;
  }

  function getLegendController(el) {
    return LEGEND_CONTROLLERS.get(el) || null;
  }

  function getOrCreateLegendController(el) {
    let controller = getLegendController(el);
    if (controller) return controller;

    const dispatch = d3.dispatch(
      'legend:toggle',
      'legend:solo',
      'legend:reset',
      'legend:hoverin',
      'legend:hoverout',
      'legend:changed'
    );

    controller = {
      el: el,
      dispatch: dispatch,
      options: {},
      lookup: [],
      clickDelay: DEFAULT_CLICK_DELAY,
      clickTimer: null,
      state: {
        persistent: {
          hidden: new Set(),
          solo: null
        },
        transient: {
          hover: null
        },
        linked: {
          crosstalkKeys: null
        }
      }
    };

    dispatch.on('legend:toggle.state', function(payload) {
      if (!payload || !payload.key) return;

      const key = payload.key;
      const hidden = controller.state.persistent.hidden;

      if (hidden.has(key)) {
        hidden.delete(key);
      } else {
        hidden.add(key);
      }

      if (controller.state.persistent.solo === key && hidden.has(key)) {
        controller.state.persistent.solo = null;
      }

      applyLegendState(el);

      dispatch.call('legend:changed', null, {
        source: 'toggle',
        key: key,
        state: getLegendState(el)
      });
    });

    dispatch.on('legend:solo.state', function(payload) {
      if (!payload || !payload.key) return;
      const key = payload.key;

      if (controller.state.persistent.solo === key) {
        controller.state.persistent.solo = null;
      } else {
        controller.state.persistent.solo = key;
      }

      applyLegendState(el);

      dispatch.call('legend:changed', null, {
        source: 'solo',
        key: key,
        state: getLegendState(el)
      });
    });

    dispatch.on('legend:reset.state', function() {
      controller.state.persistent.hidden.clear();
      controller.state.persistent.solo = null;
      controller.state.transient.hover = null;

      applyLegendState(el);

      dispatch.call('legend:changed', null, {
        source: 'reset',
        key: null,
        state: getLegendState(el)
      });
    });

    dispatch.on('legend:hoverin.state', function(payload) {
      controller.state.transient.hover = (payload && payload.key) ? payload.key : null;

      applyLegendState(el);

      dispatch.call('legend:changed', null, {
        source: 'hoverin',
        key: controller.state.transient.hover,
        state: getLegendState(el)
      });
    });

    dispatch.on('legend:hoverout.state', function(payload) {
      const key = payload && payload.key;
      if (!key || controller.state.transient.hover === key) {
        controller.state.transient.hover = null;
      }

      applyLegendState(el);

      dispatch.call('legend:changed', null, {
        source: 'hoverout',
        key: key || null,
        state: getLegendState(el)
      });
    });

    LEGEND_CONTROLLERS.set(el, controller);
    return controller;
  }

  function resolveLegendKeyForDatum(controller, datum) {
    if (!datum || !controller.lookup || !controller.lookup.length) {
      return null;
    }

    // Path geoms (violin, density, area, ribbon, smooth, line) bind an array
    // of points as datum via .datum(pts). Aesthetic values are uniform across
    // the array (one path per legend level), so probe the first row.
    // Some geoms also wrap each point as {x, y, d} where `d` holds the
    // original data row with the aesthetic columns; unwrap to that row.
    let probe = Array.isArray(datum) ? (datum.length > 0 ? datum[0] : null) : datum;
    if (probe && typeof probe === 'object' && probe.d && typeof probe.d === 'object' && !Array.isArray(probe.d)) {
      probe = probe.d;
    }
    if (!probe) return null;

    for (let i = 0; i < controller.lookup.length; i++) {
      const entry = controller.lookup[i];
      const aliases = getLegendKeyAestheticAliases(entry.aesthetic);

      for (let j = 0; j < aliases.length; j++) {
        const value = probe[aliases[j]];
        if (value === undefined || value === null) continue;

        if (entry.candidates.has(normalizeLegendValue(value))) {
          return entry.key;
        }
      }
    }

    return null;
  }

  function isLegendKeyVisible(state, key) {
    if (!key) return true;
    if (state.persistent.solo !== null) {
      return key === state.persistent.solo;
    }
    return !state.persistent.hidden.has(key);
  }

  function getLegendState(el) {
    const controller = getLegendController(el);
    if (!controller) {
      return {
        persistent: {
          hidden: [],
          solo: null
        },
      transient: {
        hover: null
      },
      linked: {
        crosstalk: null
      }
    };
  }

    return {
      persistent: {
        hidden: Array.from(controller.state.persistent.hidden),
        solo: controller.state.persistent.solo
      },
      transient: {
        hover: controller.state.transient.hover
      },
      linked: {
        crosstalk: controller.state.linked.crosstalkKeys
          ? Array.from(controller.state.linked.crosstalkKeys)
          : null
      }
    };
  }

  function setCrosstalkSelection(el, selectedKeys) {
    const controller = getOrCreateLegendController(el);
    const keys = Array.isArray(selectedKeys)
      ? selectedKeys.filter(k => k !== null && k !== undefined).map(String)
      : [];

    controller.state.linked.crosstalkKeys = keys.length ? new Set(keys) : null;
    applyLegendState(el);

    controller.dispatch.call('legend:changed', null, {
      source: 'crosstalk',
      key: null,
      state: getLegendState(el)
    });
  }

  function onLegendChanged(el, namespace, handler) {
    const controller = getOrCreateLegendController(el);
    const ns = (namespace && String(namespace).trim()) ? String(namespace).trim() : 'listener';
    controller.dispatch.on('legend:changed.' + ns, handler || null);
  }

  function dispatchLegend(el, type, payload) {
    const controller = getOrCreateLegendController(el);
    if (!controller || !controller.dispatch || !type) return;
    controller.dispatch.call(type, null, payload || {});
  }

  function handleLegendClick(el, payload) {
    const controller = getOrCreateLegendController(el);
    if (!controller) return;

    if (controller.clickTimer) {
      clearTimeout(controller.clickTimer);
      controller.clickTimer = null;
    }

    controller.clickTimer = setTimeout(function() {
      controller.clickTimer = null;
      dispatchLegend(el, 'legend:toggle', payload);
    }, controller.clickDelay);
  }

  function handleLegendDoubleClick(el, payload) {
    const controller = getOrCreateLegendController(el);
    if (!controller) return;

    if (controller.clickTimer) {
      clearTimeout(controller.clickTimer);
      controller.clickTimer = null;
    }

    dispatchLegend(el, 'legend:solo', payload);
  }

  /**
   * Attach legend interaction state + semantic bus to widget.
   *
   * @param {HTMLElement} el - Widget container element
   * @param {Object} options - Legend options (contains IR context)
   */
  function attachLegend(el, options) {
    const svg = d3.select(el).select('svg');
    if (svg.empty()) return null;

    const controller = getOrCreateLegendController(el);
    controller.options = options || {};
    controller.lookup = buildLegendLookup(controller.options);

    // Prevent duplicate namespaced handlers when renderValue/resize redraws.
    svg.selectAll('.legend-item').on('.legend', null);
    svg.selectAll('.legend-reset-control').on('.legend', null);

    // Rebind semantic handlers from DOM data attributes.
    svg.selectAll('.legend-item')
      .on('click.legend', function(event) {
        event.preventDefault();
        const node = d3.select(this);
        handleLegendClick(el, {
          key: node.attr('data-legend-key'),
          aesthetic: node.attr('data-aesthetic'),
          level: node.attr('data-level')
        });
      })
      .on('dblclick.legend', function(event) {
        event.preventDefault();
        event.stopPropagation();
        const node = d3.select(this);
        handleLegendDoubleClick(el, {
          key: node.attr('data-legend-key'),
          aesthetic: node.attr('data-aesthetic'),
          level: node.attr('data-level')
        });
      })
      .on('mouseover.legend', function() {
        const node = d3.select(this);
        dispatchLegend(el, 'legend:hoverin', {
          key: node.attr('data-legend-key')
        });
      })
      .on('mouseout.legend', function() {
        const node = d3.select(this);
        dispatchLegend(el, 'legend:hoverout', {
          key: node.attr('data-legend-key')
        });
      });

    svg.selectAll('.legend-reset-control')
      .on('click.legend', function(event) {
        event.preventDefault();
        event.stopPropagation();
        dispatchLegend(el, 'legend:reset', {});
      });

    applyLegendState(el);
    return controller;
  }

  /**
   * Apply the current legend state to legend controls and geom marks.
   *
   * @param {HTMLElement} el - Widget container element
   */
  function applyLegendState(el) {
    const controller = getLegendController(el);
    if (!controller) return;

    const svg = d3.select(el).select('svg');
    if (svg.empty()) return;

    const state = controller.state;
    const crosstalkKeys = state.linked && state.linked.crosstalkKeys
      ? state.linked.crosstalkKeys
      : null;
    const hasCrosstalkSelection = !!(crosstalkKeys && crosstalkKeys.size);
    const hoverKey = state.transient.hover;
    const hoverActive = hoverKey !== null;

    svg.selectAll('.legend-item').each(function() {
      const item = d3.select(this);
      const key = item.attr('data-legend-key');
      const visible = isLegendKeyVisible(state, key);
      const isHovered = hoverActive && key === hoverKey;
      const isDimmedByHover = hoverActive && key !== hoverKey;
      const isActive = visible && (!state.persistent.solo || state.persistent.solo === key);

      item
        .classed('legend-item-active', isActive)
        .classed('legend-item-hidden', !visible)
        .classed('legend-item-solo', state.persistent.solo === key)
        .classed('legend-item-hover', isHovered)
        .classed('legend-item-hover-preview', isDimmedByHover)
        .style('opacity', !visible ? 0.35 : (isDimmedByHover ? 0.65 : 1));
    });

    INTERACTIVE_SELECTORS.forEach(function(selector) {
      svg.selectAll(selector).each(function(d) {
        const elem = d3.select(this);

        if (!elem.attr('data-original-opacity')) {
          const currentOpacity = elem.style('opacity') || elem.attr('opacity') || '1';
          elem.attr('data-original-opacity', currentOpacity);
        }

        const baseOpacity = parseFloat(elem.attr('data-original-opacity') || '1');
        // Prefer controller-resolved key over the geom's data-legend-key:
        // geoms write the post-mapping aesthetic value (e.g. "colour::#00BA38"),
        // but the legend's keys use the pre-mapping factor level
        // (e.g. "colour::4"). resolveLegendKeyForDatum bridges them via
        // the controller's candidate set (which includes both the level and
        // its resolved color/shape/size). Fall back to the attribute if no
        // controller match (e.g. no guides in IR).
        const resolvedKey = resolveLegendKeyForDatum(controller, d);
        const legendKey = resolvedKey || elem.attr('data-legend-key');
        const legendLevel = elem.attr('data-legend-level') || '';
        const legendAesthetic = elem.attr('data-legend-aesthetic') || '';
        const crosstalkKey = elem.attr('data-crosstalk-key');
        const visible = isLegendKeyVisible(state, legendKey);
        const hoverMatch = hoverActive && legendKey === hoverKey;
        const hoverDim = hoverActive && !!legendKey && !hoverMatch;
        const panelNode = this.closest('.panel');
        const brushActive = !!(panelNode && panelNode.getAttribute('data-brush-active') === 'true');

        let effectiveOpacity = Number.isFinite(baseOpacity) ? baseOpacity : 1;

        elem.attr('data-legend-key', legendKey || '');
        if (legendLevel) {
          elem.attr('data-legend-level', legendLevel);
        }
        if (legendAesthetic) {
          elem.attr('data-legend-aesthetic', legendAesthetic);
        }

        if (!visible) {
          elem.style('opacity', 0.05).style('pointer-events', 'none');
          return;
        }

        if (brushActive) {
          const brushOpacity = parseFloat(elem.style('opacity'));
          if (Number.isFinite(brushOpacity)) {
            effectiveOpacity = Math.min(effectiveOpacity, brushOpacity);
          }
        }

        if (hasCrosstalkSelection) {
          const inLinkedSelection = !!(crosstalkKey && crosstalkKeys.has(String(crosstalkKey)));
          effectiveOpacity = Math.min(effectiveOpacity, inLinkedSelection ? effectiveOpacity : 0.15);
        }

        if (hoverDim) {
          effectiveOpacity = Math.min(effectiveOpacity, 0.25);
        }

        elem.style('opacity', effectiveOpacity).style('pointer-events', null);
      });
    });
  }

  /**
   * Attach tooltip event handlers to interactive elements.
   * Finds all geom elements matching INTERACTIVE_SELECTORS and adds
   * mouseover/mousemove/mouseout handlers that show/move/hide tooltip.
   *
   * @param {HTMLElement} el - Widget container element
   * @param {Object} config - Tooltip configuration
   * @param {Array<string>} config.fields - Field names to show (null = all)
   * @param {string} config.formatter - Optional JS function string
   * @param {Object} [ir] - IR object for temporal field detection
   */
  function attachTooltips(el, config, ir) {
    const svg = d3.select(el).select('svg');

    INTERACTIVE_SELECTORS.forEach(selector => {
      const selection = svg.selectAll(selector);

      // Skip if no elements match this selector
      if (selection.empty()) {
        return;
      }

      selection
        .on('mouseover.tooltip', function(event, d) {
          window.gg2d3.tooltip.show(event, d, config, ir);
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
   * Attach custom user event handlers to interactive elements.
   *
   * @param {HTMLElement} el - Widget container element
   * @param {Object} config - Handlers configuration
   * @param {string} [config.click] - JS function string for click
   * @param {string} [config.mouseover] - JS function string for mouseover
   * @param {string} [config.mouseout] - JS function string for mouseout
   * @param {string} [config.shiny_id] - Optional Shiny input ID
   */
  function attachHandlers(el, config) {
    if (!config) return;
    const svg = d3.select(el).select('svg');

    const clickHandler = compileEventHandler(config.click);
    const mouseoverHandler = compileEventHandler(config.mouseover);
    const mouseoutHandler = compileEventHandler(config.mouseout);
    const shinyId = config.shiny_id;

    INTERACTIVE_SELECTORS.forEach(selector => {
      const selection = svg.selectAll(selector);
      if (selection.empty()) return;

      if (clickHandler || shinyId) {
        selection.on('click.custom', function(event, d) {
          const publicDatum = sanitizeEventDatum(d);
          if (clickHandler) clickHandler.call(this, event, publicDatum);
          if (shinyId && window.Shiny) {
            window.Shiny.setInputValue(shinyId, publicDatum);
          }
        });
      }

      if (mouseoverHandler) {
        selection.on('mouseover.custom', function(event, d) {
          mouseoverHandler.call(this, event, sanitizeEventDatum(d));
        });
      }

      if (mouseoutHandler) {
        selection.on('mouseout.custom', function(event, d) {
          mouseoutHandler.call(this, event, sanitizeEventDatum(d));
        });
      }
    });

    // Also sync legend changes to Shiny if shiny_id is present
    if (shinyId) {
      onLegendChanged(el, 'shiny', function(payload) {
        if (window.Shiny) {
          window.Shiny.setInputValue(shinyId + '_legend', payload);
        }
      });
    }
  }

  /**
   * Export events module API
   */
  window.gg2d3.events = {
    attachTooltips: attachTooltips,
    attachHover: attachHover,
    attachHandlers: attachHandlers,
    attachLegend: attachLegend,
    getLegendState: getLegendState,
    applyLegendState: applyLegendState,
    setCrosstalkSelection: setCrosstalkSelection,
    onLegendChanged: onLegendChanged,
    dispatchLegend: dispatchLegend,
    handleLegendClick: handleLegendClick,
    handleLegendDoubleClick: handleLegendDoubleClick
  };
})();
