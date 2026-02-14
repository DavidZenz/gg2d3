/**
 * gg2d3 Brush Module
 *
 * Provides brush selection interaction for gg2d3 plots.
 * Uses d3.brush() behavior to enable rectangular selection with data highlighting.
 *
 * @module gg2d3.brush
 */

(function() {
  'use strict';

  // Initialize gg2d3 namespace if not exists
  if (typeof window.gg2d3 === 'undefined') {
    window.gg2d3 = {};
  }

  /**
   * CSS selectors for interactive geom elements (reuse from events.js pattern).
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
   * Attach brush behavior to a gg2d3 widget.
   *
   * Implementation strategy:
   * - Append brush overlay to panel
   * - On brush end: invert selection to data domain, highlight selected elements
   * - Use scale.invert() for continuous, band center filtering for categorical
   * - Send brush coordinates to Shiny if in Shiny mode
   *
   * @param {HTMLElement} el - Widget container element
   * @param {Object} config - Brush configuration
   * @param {string} config.direction - "xy", "x", or "y"
   * @param {string} config.fill - Brush overlay fill color
   * @param {number} config.opacity - Opacity for non-selected elements
   * @param {string} config.on_brush - Optional JavaScript callback
   * @param {Object} ir - Intermediate representation (for scale info)
   */
  function attach(el, config, ir) {
    const svg = d3.select(el).select('svg');

    if (svg.empty()) {
      console.warn('gg2d3.brush: SVG element not found');
      return;
    }

    // Determine if this is a faceted plot
    const panels = svg.selectAll('.panel');
    const isFaceted = panels.size() > 1;

    if (isFaceted) {
      // Attach brush to each panel independently
      panels.each(function() {
        attachToPanel(d3.select(this), el, config, ir);
      });
    } else {
      // Single panel
      const panel = panels.node() ? panels : svg.select('.panel');
      attachToPanel(panel, el, config, ir);
    }
  }

  /**
   * Attach brush to a single panel.
   */
  function attachToPanel(panelSelection, containerEl, config, ir) {
    if (panelSelection.empty()) {
      console.warn('gg2d3.brush: No panel found');
      return;
    }

    const panelGroup = panelSelection;

    // Find panel dimensions from background rect
    const bgRect = panelGroup.select('rect').node();
    if (!bgRect) {
      console.warn('gg2d3.brush: Panel background rect not found');
      return;
    }

    const panelWidth = parseFloat(bgRect.getAttribute('width'));
    const panelHeight = parseFloat(bgRect.getAttribute('height'));

    // Create original scales from IR
    const flip = !!(ir.coord && ir.coord.flip);
    const xScaleDesc = ir.scales && ir.scales.x;
    const yScaleDesc = ir.scales && ir.scales.y;

    const xScale = window.gg2d3.scales.createScale(
      xScaleDesc,
      flip ? [panelHeight, 0] : [0, panelWidth]
    );
    const yScale = window.gg2d3.scales.createScale(
      yScaleDesc,
      flip ? [0, panelWidth] : [panelHeight, 0]
    );

    // Determine brush type based on direction
    let brushType;
    if (config.direction === 'x') {
      brushType = d3.brushX();
    } else if (config.direction === 'y') {
      brushType = d3.brushY();
    } else {
      brushType = d3.brush();
    }

    // Configure brush extent to match panel dimensions
    brushType.extent([[0, 0], [panelWidth, panelHeight]]);

    // Append brush group to panel (after data so overlay is on top)
    const brushGroup = panelGroup.append('g')
      .attr('class', 'brush-overlay')
      .call(brushType);

    // Style the brush overlay
    brushGroup.select('.overlay')
      .style('cursor', 'crosshair');

    brushGroup.select('.selection')
      .style('fill', config.fill)
      .style('fill-opacity', 0.2)
      .style('stroke', config.fill)
      .style('stroke-width', 1);

    // Handle brush end event (fire only on completion, not during drag)
    brushType.on('end.brush', function(event) {
      const selection = event.selection;

      // If no selection (brush cleared), restore all elements
      if (!selection) {
        restoreAllElements(panelGroup);

        // Send null to Shiny if in Shiny mode
        if (typeof HTMLWidgets !== 'undefined' && HTMLWidgets.shinyMode) {
          Shiny.onInputChange(containerEl.id + '_brush', null);
        }

        return;
      }

      // Invert selection to data domain
      const bounds = invertSelection(selection, xScale, yScale, xScaleDesc, yScaleDesc, config.direction);

      // Highlight elements within selection
      highlightSelection(panelGroup, bounds, flip, config.opacity);

      // Send brush coordinates to Shiny if in Shiny mode
      if (typeof HTMLWidgets !== 'undefined' && HTMLWidgets.shinyMode) {
        Shiny.onInputChange(containerEl.id + '_brush', {
          xmin: bounds.xmin,
          xmax: bounds.xmax,
          ymin: bounds.ymin,
          ymax: bounds.ymax
        });
      }

      // Call user callback if provided
      if (config.on_brush) {
        try {
          const callback = new Function('selectedData', config.on_brush);
          // Collect selected data
          const selectedData = collectSelectedData(panelGroup, bounds, flip);
          callback(selectedData);
        } catch (e) {
          console.error('gg2d3.brush: Error in on_brush callback:', e);
        }
      }
    });

    // Double-click to clear brush
    brushGroup.on('dblclick.brush', function() {
      brushGroup.call(brushType.move, null);
    });
  }

  /**
   * Invert pixel selection to data domain.
   * Handles both continuous (scale.invert) and categorical (band center) scales.
   */
  function invertSelection(selection, xScale, yScale, xScaleDesc, yScaleDesc, direction) {
    const bounds = {};

    // Handle x dimension
    if (direction === 'xy' || direction === 'x') {
      const x0 = selection[0][0];
      const x1 = selection[1][0];

      if (xScaleDesc && xScaleDesc.type === 'band') {
        // Categorical scale: filter domain values whose band center falls within selection
        const domain = xScale.domain();
        const bandwidth = xScale.bandwidth();
        const selected = domain.filter(d => {
          const center = xScale(d) + bandwidth / 2;
          return center >= x0 && center <= x1;
        });
        bounds.xmin = selected[0];
        bounds.xmax = selected[selected.length - 1];
        bounds.xCategories = selected;
      } else {
        // Continuous scale: use invert
        bounds.xmin = xScale.invert(x0);
        bounds.xmax = xScale.invert(x1);
      }
    }

    // Handle y dimension
    if (direction === 'xy' || direction === 'y') {
      const y0 = selection[0][1];
      const y1 = selection[1][1];

      if (yScaleDesc && yScaleDesc.type === 'band') {
        // Categorical scale
        const domain = yScale.domain();
        const bandwidth = yScale.bandwidth();
        const selected = domain.filter(d => {
          const center = yScale(d) + bandwidth / 2;
          return center >= y0 && center <= y1;
        });
        bounds.ymin = selected[0];
        bounds.ymax = selected[selected.length - 1];
        bounds.yCategories = selected;
      } else {
        // Continuous scale: use invert
        bounds.ymin = yScale.invert(y0);
        bounds.ymax = yScale.invert(y1);
      }
    }

    return bounds;
  }

  /**
   * Highlight elements within selection, dim elements outside.
   */
  function highlightSelection(panelGroup, bounds, flip, dimOpacity) {
    const clippedGroup = panelGroup.select('g[clip-path]');
    if (clippedGroup.empty()) return;

    // Get scale functions to use (flip swaps which scale goes to which axis)
    const xField = flip ? 'y' : 'x';
    const yField = flip ? 'x' : 'y';

    // Process each geom type
    INTERACTIVE_SELECTORS.forEach(selector => {
      clippedGroup.selectAll(selector).each(function(d) {
        if (!d) return;

        const elem = d3.select(this);
        const isSelected = isElementInSelection(d, bounds, xField, yField);

        elem.style('opacity', isSelected ? 1.0 : dimOpacity);
      });
    });
  }

  /**
   * Check if an element's data falls within the brush selection.
   */
  function isElementInSelection(d, bounds, xField, yField) {
    let xInside = true;
    let yInside = true;

    // Check x dimension
    if (bounds.xCategories !== undefined) {
      // Categorical x scale
      xInside = bounds.xCategories.includes(d[xField]);
    } else if (bounds.xmin !== undefined && bounds.xmax !== undefined) {
      // Continuous x scale
      const xVal = d[xField];
      xInside = xVal >= Math.min(bounds.xmin, bounds.xmax) &&
                xVal <= Math.max(bounds.xmin, bounds.xmax);
    }

    // Check y dimension
    if (bounds.yCategories !== undefined) {
      // Categorical y scale
      yInside = bounds.yCategories.includes(d[yField]);
    } else if (bounds.ymin !== undefined && bounds.ymax !== undefined) {
      // Continuous y scale
      const yVal = d[yField];
      yInside = yVal >= Math.min(bounds.ymin, bounds.ymax) &&
                yVal <= Math.max(bounds.ymin, bounds.ymax);
    }

    return xInside && yInside;
  }

  /**
   * Restore all elements to original opacity.
   */
  function restoreAllElements(panelGroup) {
    const clippedGroup = panelGroup.select('g[clip-path]');
    if (clippedGroup.empty()) return;

    INTERACTIVE_SELECTORS.forEach(selector => {
      clippedGroup.selectAll(selector).each(function() {
        const elem = d3.select(this);
        const originalOpacity = elem.attr('data-original-opacity');
        if (originalOpacity) {
          elem.style('opacity', originalOpacity);
        } else {
          elem.style('opacity', null); // Remove inline style, fall back to CSS/attribute
        }
      });
    });
  }

  /**
   * Collect data from selected elements (for on_brush callback).
   */
  function collectSelectedData(panelGroup, bounds, flip) {
    const clippedGroup = panelGroup.select('g[clip-path]');
    if (clippedGroup.empty()) return [];

    const selectedData = [];
    const xField = flip ? 'y' : 'x';
    const yField = flip ? 'x' : 'y';

    INTERACTIVE_SELECTORS.forEach(selector => {
      clippedGroup.selectAll(selector).each(function(d) {
        if (!d) return;
        if (isElementInSelection(d, bounds, xField, yField)) {
          selectedData.push(d);
        }
      });
    });

    return selectedData;
  }

  /**
   * Export brush module API
   */
  window.gg2d3.brush = {
    attach: attach
  };
})();
