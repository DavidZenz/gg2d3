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
   * Check if a data field maps to a temporal scale.
   *
   * @param {string} field - Data field name (e.g., 'x', 'y', 'xmin')
   * @param {Object} ir - IR object with scales
   * @returns {Object|false} Scale descriptor if temporal, false otherwise
   */
  function getTemporalScale(field, ir) {
    if (!ir || !ir.scales) return false;
    var isTemp = window.gg2d3.scales && window.gg2d3.scales.isTemporalTransform;
    if (!isTemp) return false;

    if ((field === 'x' || field === 'xmin' || field === 'xmax') &&
        ir.scales.x && isTemp(ir.scales.x.transform)) {
      return ir.scales.x;
    }
    if ((field === 'y' || field === 'ymin' || field === 'ymax') &&
        ir.scales.y && isTemp(ir.scales.y.transform)) {
      return ir.scales.y;
    }
    return false;
  }

  /**
   * Format a temporal (millisecond timestamp) value for tooltip display.
   *
   * @param {number} value - Milliseconds since epoch
   * @param {Object} scaleInfo - IR scale descriptor with format/timezone/transform
   * @returns {string} Formatted date/time string
   */
  function formatTemporalValue(value, scaleInfo) {
    var date = new Date(value);
    if (isNaN(date.getTime())) return String(value);

    // Use timezone-aware Intl formatting if timezone provided
    if (scaleInfo.timezone && scaleInfo.timezone !== 'UTC') {
      try {
        var opts = {
          timeZone: scaleInfo.timezone,
          year: 'numeric', month: 'short', day: 'numeric'
        };
        if (scaleInfo.transform === 'time') {
          opts.hour = '2-digit';
          opts.minute = '2-digit';
        }
        return new Intl.DateTimeFormat('en-US', opts).format(date);
      } catch (e) { /* fall through to D3 format */ }
    }

    // Use D3 UTC format with pattern from R, or default
    var translateFormat = window.gg2d3.scales && window.gg2d3.scales.translateFormat;
    var fmt = translateFormat ? translateFormat(scaleInfo.format) : null;
    if (fmt) {
      return d3.utcFormat(fmt)(date);
    }

    // Sensible default: date-only for "date", datetime for "time"
    return scaleInfo.transform === 'time'
      ? d3.utcFormat('%Y-%m-%d %H:%M')(date)
      : d3.utcFormat('%Y-%m-%d')(date);
  }

  /**
   * Format tooltip content from data row.
   * Generates HTML string with field names and formatted values.
   *
   * @param {Object} d - Data row bound to SVG element
   * @param {Object} config - Tooltip configuration
   * @param {Array<string>} config.fields - Field names to show (null = all except internals)
   * @param {string} config.formatter - Optional JS function string for custom formatting
   * @param {Object} [ir] - IR object for temporal field detection
   * @returns {string} HTML string for tooltip content
   */
  function format(d, config, ir) {
    // Path geoms (line, area, density, ribbon, smooth, violin) bind an
    // array of points as datum via .datum(pts). Hovering anywhere on the
    // path produces a single tooltip for the path; show the first point's
    // values as representative. Without this, Object.keys(array) returns
    // numeric indices "0","1",… and each d[i] stringifies as "[object Object]".
    //
    // Some geoms wrap each point as {x, y, d} where `d` is the original
    // data row. Unwrap to that row when present so the tooltip shows the
    // ggplot aesthetic columns (colour, fill, group, …) rather than the
    // wrapper's plotting coordinates.
    if (Array.isArray(d)) {
      d = d.length > 0 ? d[0] : {};
    }
    if (d && typeof d === 'object' && d.d && typeof d.d === 'object' && !Array.isArray(d.d)) {
      d = d.d;
    }

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

    // Custom formatter if provided. Per the documented API
    // (vignettes/gg2d3.Rmd: `formatter = "function(d) { return d.mpg + ' mpg'; }"`)
    // the formatter receives the entire row and returns the whole tooltip
    // content as a string. The string can be either a full function
    // expression ("function(d) {...}" or "(d) => ...") or a raw body
    // ("return d.mpg + ' mpg';"). Detect and compile appropriately.
    if (config.formatter) {
      try {
        const src = String(config.formatter).trim();
        const looksLikeFnExpr = /^\s*(function\b|\(?\s*\w*\s*\)?\s*=>)/.test(src);
        const customFn = looksLikeFnExpr
          ? (new Function('return (' + src + ');'))()
          : new Function('d', src);
        if (typeof customFn !== 'function') {
          throw new Error('formatter did not evaluate to a function');
        }
        // Enrich the row so user formatters can refer to ORIGINAL variable
        // names (d.mpg, d.cyl, ...) as well as aesthetic names (d.x, d.y,
        // d.colour). The IR stores data under aesthetic keys; aes_by_var
        // bridges them. Without this, the documented example
        // `function(d) { return d.mpg + ' mpg'; }` returns "undefined mpg".
        const aesByVar = (ir && ir.aes_by_var) || {};
        const enriched = Object.assign({}, d);
        Object.keys(aesByVar).forEach(function(varName) {
          if (!Object.prototype.hasOwnProperty.call(enriched, varName)) {
            const aesKey = aesByVar[varName];
            if (aesKey && Object.prototype.hasOwnProperty.call(d, aesKey)) {
              enriched[varName] = d[aesKey];
            }
          }
        });
        const out = customFn(enriched);
        return out == null ? '' : String(out);
      } catch (e) {
        console.warn('gg2d3: Invalid tooltip formatter function:', e);
      }
    }

    // Build variable-name -> aesthetic-key reverse map for lookup fallback.
    // gg2d3 stores row data under aesthetic keys (x, y, colour, ...) but users
    // pass original variable names (wt, mpg, cyl) in `fields`. Translate misses.
    const aesByVar = (ir && ir.aes_by_var) || {};

    // Generate HTML for each field
    const lines = fields.map(field => {
      let aesField = field;
      let value = d[field];
      if (value === undefined && Object.prototype.hasOwnProperty.call(aesByVar, field)) {
        aesField = aesByVar[field];
        value = d[aesField];
      }

      // Default formatting (custom formatter is handled above with an
      // early return — see the config.formatter block).
      let formatted;
      {
        let displayValue = value;
        const temporalScale = getTemporalScale(aesField, ir);
        if (temporalScale && typeof value === 'number') {
          // Format temporal values as dates, not raw milliseconds
          displayValue = formatTemporalValue(value, temporalScale);
        } else if (typeof value === 'number') {
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
  function show(event, d, config, ir) {
    const tooltip = getOrCreate();
    tooltip.style('display', 'block');
    tooltip.html(format(d, config, ir));
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
