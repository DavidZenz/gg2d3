/**
 * gg2d3 Brush Module
 *
 * Provides brush selection interaction for gg2d3 plots.
 * Uses d3.brush() behavior to enable rectangular selection with data highlighting.
 *
 * Key design decisions:
 * - Brush group inserted BEFORE clipped data group so data elements remain on top
 *   and can still receive tooltip/hover events from events.js
 * - Highlighting uses pixel-position checking (not data-domain comparison) so it
 *   works for all scale types (continuous, categorical, band)
 * - Selection format normalized: brushX returns [x0,x1], brushY returns [y0,y1],
 *   brush returns [[x0,y0],[x1,y1]] — all converted to {px0,py0,px1,py1}
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
   * CSS selectors for interactive geom elements.
   */
  var INTERACTIVE_SELECTORS = [
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
   * @param {HTMLElement} el - Widget container element
   * @param {Object} config - Brush configuration
   * @param {string} config.direction - "xy", "x", or "y"
   * @param {string} config.fill - Brush overlay fill color
   * @param {number} config.opacity - Opacity for non-selected elements
   * @param {string} config.on_brush - Optional JavaScript callback
   * @param {Object} ir - Intermediate representation (for scale info)
   */
  function attach(el, config, ir) {
    var svg = d3.select(el).select('svg');

    if (svg.empty()) {
      console.warn('gg2d3.brush: SVG element not found');
      return;
    }

    // Determine if this is a faceted plot
    var panels = svg.selectAll('.panel');
    var isFaceted = panels.size() > 1;

    if (isFaceted) {
      panels.each(function() {
        attachToPanel(d3.select(this), el, config, ir);
      });
    } else {
      var panel = panels.size() >= 1 ? d3.select(panels.nodes()[0]) : svg.select('.panel');
      attachToPanel(panel, el, config, ir);
    }
  }

  /**
   * Attach brush to a single panel.
   */
  function attachToPanel(panelGroup, containerEl, config, ir) {
    if (panelGroup.empty()) {
      console.warn('gg2d3.brush: No panel found');
      return;
    }

    // Find panel dimensions from background rect
    var bgRect = panelGroup.select('rect').node();
    if (!bgRect) {
      console.warn('gg2d3.brush: Panel background rect not found');
      return;
    }

    var panelWidth = parseFloat(bgRect.getAttribute('width'));
    var panelHeight = parseFloat(bgRect.getAttribute('height'));

    // Build scales for Shiny data-domain output only
    var flip = !!(ir.coord && ir.coord.flip);
    var xScaleDesc = ir.scales && ir.scales.x;
    var yScaleDesc = ir.scales && ir.scales.y;

    var xScale = window.gg2d3.scales.createScale(
      xScaleDesc,
      flip ? [panelHeight, 0] : [0, panelWidth]
    );
    var yScale = window.gg2d3.scales.createScale(
      yScaleDesc,
      flip ? [0, panelWidth] : [panelHeight, 0]
    );

    // Determine brush type based on direction
    var brushType;
    if (config.direction === 'x') {
      brushType = d3.brushX();
    } else if (config.direction === 'y') {
      brushType = d3.brushY();
    } else {
      brushType = d3.brush();
    }

    // Configure brush extent to match panel dimensions
    brushType.extent([[0, 0], [panelWidth, panelHeight]]);

    // Insert brush group BEFORE the clipped data group so data elements
    // remain on top and can still receive tooltip/hover events.
    // Once a brush gesture starts (mousedown on overlay), D3 captures the
    // pointer via window-level events, so dragging over data elements works.
    var clippedGroup = panelGroup.select('g[clip-path]');
    var brushGroup;
    if (!clippedGroup.empty()) {
      brushGroup = panelGroup.insert('g', function() { return clippedGroup.node(); })
        .attr('class', 'brush-overlay')
        .call(brushType);
    } else {
      brushGroup = panelGroup.append('g')
        .attr('class', 'brush-overlay')
        .call(brushType);
    }

    // Style the brush overlay
    brushGroup.select('.overlay')
      .style('cursor', 'crosshair');

    brushGroup.select('.selection')
      .style('fill', config.fill)
      .style('fill-opacity', 0.2)
      .style('stroke', config.fill)
      .style('stroke-width', 1);

    // Handle brush end event
    brushType.on('end.brush', function(event) {
      var selection = event.selection;

      // If no selection (brush cleared), restore all elements
      if (!selection) {
        restoreAllElements(panelGroup);
        panelGroup.attr('data-brush-active', null);

        if (typeof HTMLWidgets !== 'undefined' && HTMLWidgets.shinyMode) {
          Shiny.onInputChange(containerEl.id + '_brush', null);
        }

        return;
      }

      // Mark panel as having active brush (used by hover to skip dimming)
      panelGroup.attr('data-brush-active', 'true');

      // Normalize selection to pixel rect regardless of brush direction
      // brushX returns [x0, x1], brushY returns [y0, y1], brush returns [[x0,y0],[x1,y1]]
      var pixelRect = normalizeSelection(selection, config.direction, panelWidth, panelHeight);

      // Highlight elements within selection using pixel positions
      highlightSelection(panelGroup, pixelRect, config.opacity);

      // Invert to data domain for Shiny/callback output
      if ((typeof HTMLWidgets !== 'undefined' && HTMLWidgets.shinyMode) || config.on_brush) {
        var bounds = invertSelection(pixelRect, xScale, yScale, xScaleDesc, yScaleDesc, config.direction);

        if (typeof HTMLWidgets !== 'undefined' && HTMLWidgets.shinyMode) {
          Shiny.onInputChange(containerEl.id + '_brush', {
            xmin: bounds.xmin,
            xmax: bounds.xmax,
            ymin: bounds.ymin,
            ymax: bounds.ymax
          });
        }

        if (config.on_brush) {
          try {
            var callback = new Function('selectedData', config.on_brush);
            var selectedData = collectSelectedData(panelGroup, pixelRect);
            callback(selectedData);
          } catch (e) {
            console.error('gg2d3.brush: Error in on_brush callback:', e);
          }
        }
      }
    });

    // Expose brush reference for external clearing (e.g., by zoom module)
    panelGroup.node().__gg2d3_brush = {
      behavior: brushType,
      group: brushGroup
    };

    // Double-click to clear brush
    brushGroup.on('dblclick.brush', function() {
      brushGroup.call(brushType.move, null);
    });
  }

  /**
   * Normalize brush selection to a pixel rect.
   * d3.brush() returns [[x0,y0],[x1,y1]]
   * d3.brushX() returns [x0, x1]
   * d3.brushY() returns [y0, y1]
   */
  function normalizeSelection(selection, direction, panelWidth, panelHeight) {
    if (direction === 'x') {
      // brushX: selection = [x0, x1]
      return { px0: selection[0], py0: 0, px1: selection[1], py1: panelHeight };
    } else if (direction === 'y') {
      // brushY: selection = [y0, y1]
      return { px0: 0, py0: selection[0], px1: panelWidth, py1: selection[1] };
    } else {
      // brush: selection = [[x0,y0],[x1,y1]]
      return { px0: selection[0][0], py0: selection[0][1], px1: selection[1][0], py1: selection[1][1] };
    }
  }

  /**
   * Highlight elements within selection using pixel-position checking.
   * Works for all scale types (continuous, categorical, band).
   */
  function highlightSelection(panelGroup, pixelRect, dimOpacity) {
    var clippedGroup = panelGroup.select('g[clip-path]');
    if (clippedGroup.empty()) return;

    INTERACTIVE_SELECTORS.forEach(function(selector) {
      clippedGroup.selectAll(selector).each(function() {
        var elem = d3.select(this);
        var isSelected = isElementInPixelRect(this, pixelRect);
        elem.style('opacity', isSelected ? 1.0 : dimOpacity);
      });
    });
  }

  /**
   * Check if an SVG element's position falls within the pixel rectangle.
   * Uses element attributes directly — no data-domain conversion needed.
   */
  function isElementInPixelRect(node, rect) {
    var tagName = node.tagName.toLowerCase();

    if (tagName === 'circle') {
      // Point-in-rect check for circles (use center)
      var cx = parseFloat(node.getAttribute('cx'));
      var cy = parseFloat(node.getAttribute('cy'));
      return cx >= rect.px0 && cx <= rect.px1 &&
             cy >= rect.py0 && cy <= rect.py1;
    }

    if (tagName === 'rect') {
      // Overlap check for rectangles (selected if any part overlaps)
      var x = parseFloat(node.getAttribute('x'));
      var y = parseFloat(node.getAttribute('y'));
      var w = parseFloat(node.getAttribute('width'));
      var h = parseFloat(node.getAttribute('height'));
      return (x + w) > rect.px0 && x < rect.px1 &&
             (y + h) > rect.py0 && y < rect.py1;
    }

    if (tagName === 'text') {
      // Point-in-rect check for text (use anchor position)
      var tx = parseFloat(node.getAttribute('x'));
      var ty = parseFloat(node.getAttribute('y'));
      return tx >= rect.px0 && tx <= rect.px1 &&
             ty >= rect.py0 && ty <= rect.py1;
    }

    if (tagName === 'line') {
      // Check if midpoint or either endpoint is in selection
      var x1 = parseFloat(node.getAttribute('x1'));
      var y1 = parseFloat(node.getAttribute('y1'));
      var x2 = parseFloat(node.getAttribute('x2'));
      var y2 = parseFloat(node.getAttribute('y2'));
      var midX = (x1 + x2) / 2;
      var midY = (y1 + y2) / 2;
      var midIn = midX >= rect.px0 && midX <= rect.px1 &&
                  midY >= rect.py0 && midY <= rect.py1;
      var p1In = x1 >= rect.px0 && x1 <= rect.px1 &&
                 y1 >= rect.py0 && y1 <= rect.py1;
      var p2In = x2 >= rect.px0 && x2 <= rect.px1 &&
                 y2 >= rect.py0 && y2 <= rect.py1;
      return midIn || p1In || p2In;
    }

    if (tagName === 'path') {
      // Use bounding box center for path elements
      try {
        var bbox = node.getBBox();
        var centerX = bbox.x + bbox.width / 2;
        var centerY = bbox.y + bbox.height / 2;
        return centerX >= rect.px0 && centerX <= rect.px1 &&
               centerY >= rect.py0 && centerY <= rect.py1;
      } catch (e) {
        return false;
      }
    }

    return false;
  }

  /**
   * Invert pixel rectangle to data domain (for Shiny output and callbacks).
   */
  function invertSelection(pixelRect, xScale, yScale, xScaleDesc, yScaleDesc, direction) {
    var bounds = {};

    // Handle x dimension
    if (direction === 'xy' || direction === 'x') {
      if (xScaleDesc && xScaleDesc.type === 'band') {
        var domainX = xScale.domain();
        var bandwidthX = xScale.bandwidth();
        var selectedX = domainX.filter(function(d) {
          var center = xScale(d) + bandwidthX / 2;
          return center >= pixelRect.px0 && center <= pixelRect.px1;
        });
        bounds.xmin = selectedX[0];
        bounds.xmax = selectedX[selectedX.length - 1];
        bounds.xCategories = selectedX;
      } else if (xScale.invert) {
        bounds.xmin = xScale.invert(pixelRect.px0);
        bounds.xmax = xScale.invert(pixelRect.px1);
      }
    }

    // Handle y dimension
    if (direction === 'xy' || direction === 'y') {
      if (yScaleDesc && yScaleDesc.type === 'band') {
        var domainY = yScale.domain();
        var bandwidthY = yScale.bandwidth();
        var selectedY = domainY.filter(function(d) {
          var center = yScale(d) + bandwidthY / 2;
          return center >= pixelRect.py0 && center <= pixelRect.py1;
        });
        bounds.ymin = selectedY[0];
        bounds.ymax = selectedY[selectedY.length - 1];
        bounds.yCategories = selectedY;
      } else if (yScale.invert) {
        bounds.ymin = yScale.invert(pixelRect.py0);
        bounds.ymax = yScale.invert(pixelRect.py1);
      }
    }

    return bounds;
  }

  /**
   * Restore all elements to original opacity.
   */
  function restoreAllElements(panelGroup) {
    var clippedGroup = panelGroup.select('g[clip-path]');
    if (clippedGroup.empty()) return;

    INTERACTIVE_SELECTORS.forEach(function(selector) {
      clippedGroup.selectAll(selector).each(function() {
        var elem = d3.select(this);
        var originalOpacity = elem.attr('data-original-opacity');
        if (originalOpacity) {
          elem.style('opacity', originalOpacity);
        } else {
          elem.style('opacity', null);
        }
      });
    });
  }

  /**
   * Collect data from selected elements (for on_brush callback).
   */
  function collectSelectedData(panelGroup, pixelRect) {
    var clippedGroup = panelGroup.select('g[clip-path]');
    if (clippedGroup.empty()) return [];

    var selectedData = [];

    INTERACTIVE_SELECTORS.forEach(function(selector) {
      clippedGroup.selectAll(selector).each(function(d) {
        if (!d) return;
        if (isElementInPixelRect(this, pixelRect)) {
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
