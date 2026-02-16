/**
 * gg2d3 Zoom Module
 *
 * Provides zoom and pan interaction for gg2d3 plots.
 * Uses d3.zoom() with element repositioning (not SVG transform) to preserve
 * stroke widths. Axes update to reflect the zoomed data range.
 *
 * Pan behavior: Only starts from the panel background rect, not from data
 * elements. This prevents conflicts with tooltip/hover/brush on data elements.
 * Wheel zoom works everywhere within the panel.
 *
 * @module gg2d3.zoom
 */

(function() {
  'use strict';

  if (typeof window.gg2d3 === 'undefined') {
    window.gg2d3 = {};
  }

  /**
   * Attach zoom behavior to a gg2d3 widget.
   */
  function attach(el, config, ir) {
    var svg = d3.select(el).select('svg');

    if (svg.empty()) {
      console.warn('gg2d3.zoom: SVG element not found');
      return;
    }

    var panels = svg.selectAll('.panel');
    var isFaceted = panels.size() > 1;

    if (isFaceted) {
      attachToFacets(svg, panels, config, ir);
    } else {
      var panel = panels.size() >= 1 ? d3.select(panels.nodes()[0]) : svg.select('.panel');
      attachToSinglePanel(svg, panel, config, ir);
    }
  }

  /**
   * Attach zoom to a single panel plot.
   */
  function attachToSinglePanel(svg, panelGroup, config, ir) {
    if (panelGroup.empty()) {
      console.warn('gg2d3.zoom: No panel found in SVG');
      return;
    }

    var bgRect = panelGroup.select('rect').node();
    if (!bgRect) {
      console.warn('gg2d3.zoom: Panel background rect not found');
      return;
    }

    var panelWidth = parseFloat(bgRect.getAttribute('width'));
    var panelHeight = parseFloat(bgRect.getAttribute('height'));

    // Create original scales from IR (only continuous scales support zoom)
    var flip = !!(ir.coord && ir.coord.flip);
    var xScaleDesc = ir.scales && ir.scales.x;
    var yScaleDesc = ir.scales && ir.scales.y;

    var xScaleOriginal = window.gg2d3.scales.createScale(
      xScaleDesc,
      flip ? [panelHeight, 0] : [0, panelWidth]
    );
    var yScaleOriginal = window.gg2d3.scales.createScale(
      yScaleDesc,
      flip ? [0, panelWidth] : [panelHeight, 0]
    );

    // Check if scales support zoom (need .invert for rescaleX/Y)
    var canZoomX = typeof xScaleOriginal.invert === 'function';
    var canZoomY = typeof yScaleOriginal.invert === 'function';

    if (!canZoomX && !canZoomY) {
      console.warn('gg2d3.zoom: Both scales are categorical — zoom not applicable');
      return;
    }

    var xScaleCurrent = xScaleOriginal.copy();
    var yScaleCurrent = yScaleOriginal.copy();

    // Theme info for axis styling
    var theme = window.gg2d3.theme.createTheme(ir.theme);
    var axisText = theme.get('axis.text');
    var axisLine = theme.get('axis.line');
    var axisTicks = theme.get('axis.ticks');
    var axisTextX = theme.get('axis.text.x') || axisText;
    var axisTextY = theme.get('axis.text.y') || axisText;
    var axisLineX = theme.get('axis.line.x') || axisLine;
    var axisLineY = theme.get('axis.line.y') || axisLine;
    var axisTicksX = theme.get('axis.ticks.x') || axisTicks;
    var axisTicksY = theme.get('axis.ticks.y') || axisTicks;

    // Scale transforms for tick formatting
    var xTransform = xScaleDesc && xScaleDesc.transform;
    var yTransform = yScaleDesc && yScaleDesc.transform;
    var cleanFormat = d3.format('.4~g');

    // Create zoom behavior
    var zoom = d3.zoom()
      .scaleExtent(config.scale_extent)
      .extent([[0, 0], [panelWidth, panelHeight]])
      .filter(function(event) {
        // Always allow wheel zoom from anywhere in the panel
        if (event.type === 'wheel') return true;
        // Only allow drag-pan from the panel background rect
        // This prevents conflicts with tooltip/hover/brush on data elements
        return event.target === bgRect && !event.ctrlKey && !event.metaKey && event.button === 0;
      })
      .on('zoom', zoomed);

    // Apply zoom to panel group
    panelGroup
      .call(zoom)
      .on('dblclick.zoom', null);

    // Visual hint that zoom is available
    d3.select(bgRect).style('cursor', 'grab');

    function zoomed(event) {
      var transform = event.transform;

      // Clear any active brush selection when zooming
      clearBrush(panelGroup);

      // Rescale continuous axes based on direction
      if (canZoomX && (config.direction === 'both' || config.direction === 'x')) {
        xScaleCurrent = transform.rescaleX(xScaleOriginal);
      } else {
        xScaleCurrent = xScaleOriginal.copy();
      }

      if (canZoomY && (config.direction === 'both' || config.direction === 'y')) {
        yScaleCurrent = transform.rescaleY(yScaleOriginal);
      } else {
        yScaleCurrent = yScaleOriginal.copy();
      }

      // Reposition data elements (clipped by clip-path)
      repositionElements(panelGroup, xScaleCurrent, yScaleCurrent, flip);

      // Update axes to reflect zoomed range
      updateAxes(svg, xScaleCurrent, yScaleCurrent, flip,
                 axisTextX, axisTextY, axisLineX, axisLineY, axisTicksX, axisTicksY,
                 xTransform, yTransform, cleanFormat, xScaleDesc, yScaleDesc);
    }

    // Double-click to reset
    panelGroup.on('dblclick', function() {
      panelGroup.transition()
        .duration(750)
        .call(zoom.transform, d3.zoomIdentity);
    });
  }

  /**
   * Update axes to reflect zoomed scales.
   * Finds the tagged .axes-group and updates .axis-bottom / .axis-left.
   */
  function updateAxes(svg, xScaleCurrent, yScaleCurrent, flip,
                      axisTextX, axisTextY, axisLineX, axisLineY, axisTicksX, axisTicksY,
                      xTransform, yTransform, cleanFormat, xScaleDesc, yScaleDesc) {
    var axesGroup = svg.select('.axes-group');
    if (axesGroup.empty()) return;

    // Determine which scale maps to which physical axis
    var bottomScale = flip ? yScaleCurrent : xScaleCurrent;
    var leftScale = flip ? xScaleCurrent : yScaleCurrent;
    var bottomScaleDesc = flip ? yScaleDesc : xScaleDesc;
    var leftScaleDesc = flip ? xScaleDesc : yScaleDesc;

    var isTemp = window.gg2d3.scales && window.gg2d3.scales.isTemporalTransform;

    // Bottom axis
    var axisBottom = axesGroup.select('.axis-bottom');
    if (!axisBottom.empty() && typeof bottomScale.invert === 'function') {
      var bottomGen = d3.axisBottom(bottomScale);
      var bottomTransform = flip ? yTransform : xTransform;
      if (isTemp && isTemp(bottomTransform)) {
        // Apply temporal tick formatting for zoomed axis
        applyZoomTemporalFormat(bottomGen, bottomScaleDesc);
      } else if (bottomTransform && bottomTransform !== 'identity') {
        bottomGen.tickFormat(cleanFormat);
      }
      axisBottom.call(bottomGen);
      // Reapply theme styling
      var bottomTextStyle = flip ? axisTextY : axisTextX;
      var bottomLineStyle = flip ? axisLineY : axisLineX;
      var bottomTicksStyle = flip ? axisTicksY : axisTicksX;
      window.gg2d3.theme.applyAxisStyle(axisBottom, bottomTextStyle, bottomLineStyle, bottomTicksStyle);
    }

    // Left axis
    var axisLeft = axesGroup.select('.axis-left');
    if (!axisLeft.empty() && typeof leftScale.invert === 'function') {
      var leftGen = d3.axisLeft(leftScale);
      var leftTransform = flip ? xTransform : yTransform;
      if (isTemp && isTemp(leftTransform)) {
        applyZoomTemporalFormat(leftGen, leftScaleDesc);
      } else if (leftTransform && leftTransform !== 'identity') {
        leftGen.tickFormat(cleanFormat);
      }
      axisLeft.call(leftGen);
      // Reapply theme styling
      var leftTextStyle = flip ? axisTextX : axisTextY;
      var leftLineStyle = flip ? axisLineX : axisLineY;
      var leftTicksStyle = flip ? axisTicksX : axisTicksY;
      window.gg2d3.theme.applyAxisStyle(axisLeft, leftTextStyle, leftLineStyle, leftTicksStyle);
    }
  }

  /**
   * Apply temporal tick formatting to a zoom-updated axis generator.
   * Uses format pattern from scale descriptor or lets D3 auto-format.
   */
  function applyZoomTemporalFormat(axisGen, scaleDesc) {
    if (!scaleDesc) return;
    var translateFormat = window.gg2d3.scales && window.gg2d3.scales.translateFormat;
    var fmt = translateFormat ? translateFormat(scaleDesc.format) : null;
    if (fmt) {
      var useUtc = !scaleDesc.timezone || scaleDesc.timezone === 'UTC';
      axisGen.tickFormat(useUtc ? d3.utcFormat(fmt) : d3.timeFormat(fmt));
    }
    // If no explicit format, D3 time scales auto-format nicely during zoom
  }

  /**
   * Attach synchronized zoom to all panels in a faceted plot.
   */
  function attachToFacets(svg, panels, config, ir) {
    var panelData = [];

    panels.each(function() {
      var pg = d3.select(this);
      var bg = pg.select('rect').node();
      if (!bg) return;

      panelData.push({
        group: pg,
        bgRect: bg,
        width: parseFloat(bg.getAttribute('width')),
        height: parseFloat(bg.getAttribute('height'))
      });
    });

    if (panelData.length === 0) return;

    var firstPanel = panelData[0];
    var flip = !!(ir.coord && ir.coord.flip);
    var xScaleDesc = ir.scales && ir.scales.x;
    var yScaleDesc = ir.scales && ir.scales.y;

    var xScaleOriginal = window.gg2d3.scales.createScale(
      xScaleDesc,
      flip ? [firstPanel.height, 0] : [0, firstPanel.width]
    );
    var yScaleOriginal = window.gg2d3.scales.createScale(
      yScaleDesc,
      flip ? [0, firstPanel.width] : [firstPanel.height, 0]
    );

    var canZoomX = typeof xScaleOriginal.invert === 'function';
    var canZoomY = typeof yScaleOriginal.invert === 'function';

    if (!canZoomX && !canZoomY) return;

    var xScaleCurrent = xScaleOriginal.copy();
    var yScaleCurrent = yScaleOriginal.copy();

    panelData.forEach(function(pd) {
      var zoom = d3.zoom()
        .scaleExtent(config.scale_extent)
        .extent([[0, 0], [pd.width, pd.height]])
        .filter(function(event) {
          if (event.type === 'wheel') return true;
          return event.target === pd.bgRect && !event.ctrlKey && !event.metaKey && event.button === 0;
        })
        .on('zoom', function(event) {
          var transform = event.transform;

          if (canZoomX && (config.direction === 'both' || config.direction === 'x')) {
            xScaleCurrent = transform.rescaleX(xScaleOriginal);
          } else {
            xScaleCurrent = xScaleOriginal.copy();
          }

          if (canZoomY && (config.direction === 'both' || config.direction === 'y')) {
            yScaleCurrent = transform.rescaleY(yScaleOriginal);
          } else {
            yScaleCurrent = yScaleOriginal.copy();
          }

          // Clear brush and update all panels
          panelData.forEach(function(p) {
            clearBrush(p.group);
            repositionElements(p.group, xScaleCurrent, yScaleCurrent, flip);
          });
        });

      pd.group
        .call(zoom)
        .on('dblclick.zoom', null);

      d3.select(pd.bgRect).style('cursor', 'grab');

      pd.group.on('dblclick', function() {
        panelData.forEach(function(p) {
          p.group.transition()
            .duration(750)
            .call(zoom.transform, d3.zoomIdentity);
        });
      });
    });
  }

  /**
   * Clear any active brush selection on a panel.
   * Called when zoom starts so the brush rect doesn't become stale.
   */
  function clearBrush(panelGroup) {
    var brushRef = panelGroup.node().__gg2d3_brush;
    if (brushRef && panelGroup.attr('data-brush-active') === 'true') {
      // This triggers brush's end event with null selection,
      // which restores element opacities and removes data-brush-active
      brushRef.group.call(brushRef.behavior.move, null);
    }
  }

  /**
   * Reposition all geom elements using new scales.
   * Elements outside the clip rect are automatically hidden.
   */
  function repositionElements(panelGroup, xScale, yScale, flip) {
    var clippedGroup = panelGroup.select('g[clip-path]');
    if (clippedGroup.empty()) return;

    var xScaleFunc = flip ? yScale : xScale;
    var yScaleFunc = flip ? xScale : yScale;

    // geom_point
    clippedGroup.selectAll('circle.geom-point').each(function(d) {
      if (!d) return;
      d3.select(this)
        .attr('cx', xScaleFunc(d.x))
        .attr('cy', yScaleFunc(d.y));
    });

    // geom_bar
    clippedGroup.selectAll('rect.geom-bar').each(function(d) {
      if (!d) return;
      var elem = d3.select(this);
      if (flip) {
        var y0 = yScaleFunc(d.y);
        var y1 = yScaleFunc(d.yend);
        var x0 = xScaleFunc(d.xmin);
        var x1 = xScaleFunc(d.xmax);
        elem
          .attr('x', Math.min(y0, y1))
          .attr('y', Math.min(x0, x1))
          .attr('width', Math.abs(y1 - y0))
          .attr('height', Math.abs(x1 - x0));
      } else {
        var bx0 = xScaleFunc(d.xmin);
        var bx1 = xScaleFunc(d.xmax);
        var by0 = yScaleFunc(d.y);
        var by1 = yScaleFunc(d.yend);
        elem
          .attr('x', Math.min(bx0, bx1))
          .attr('y', Math.min(by0, by1))
          .attr('width', Math.abs(bx1 - bx0))
          .attr('height', Math.abs(by1 - by0));
      }
    });

    // geom_rect / geom_tile
    clippedGroup.selectAll('rect.geom-rect').each(function(d) {
      if (!d) return;
      var rx0 = xScaleFunc(d.xmin);
      var rx1 = xScaleFunc(d.xmax);
      var ry0 = yScaleFunc(d.ymin);
      var ry1 = yScaleFunc(d.ymax);
      d3.select(this)
        .attr('x', Math.min(rx0, rx1))
        .attr('y', Math.min(ry0, ry1))
        .attr('width', Math.abs(rx1 - rx0))
        .attr('height', Math.abs(ry1 - ry0));
    });

    // geom_text
    clippedGroup.selectAll('text.geom-text').each(function(d) {
      if (!d) return;
      d3.select(this)
        .attr('x', xScaleFunc(d.x))
        .attr('y', yScaleFunc(d.y));
    });

    // geom_segment
    clippedGroup.selectAll('line.geom-segment').each(function(d) {
      if (!d) return;
      d3.select(this)
        .attr('x1', xScaleFunc(d.x))
        .attr('y1', yScaleFunc(d.y))
        .attr('x2', xScaleFunc(d.xend))
        .attr('y2', yScaleFunc(d.yend));
    });

    // Path-based geoms
    repositionPathGeoms(clippedGroup, 'path.geom-line', xScaleFunc, yScaleFunc);
    repositionPathGeoms(clippedGroup, 'path.geom-area', xScaleFunc, yScaleFunc, true);
    repositionPathGeoms(clippedGroup, 'path.geom-density', xScaleFunc, yScaleFunc, true);
    repositionPathGeoms(clippedGroup, 'path.geom-smooth', xScaleFunc, yScaleFunc);

    // geom_ribbon
    clippedGroup.selectAll('path.geom-ribbon').each(function(d) {
      if (!d || !Array.isArray(d)) return;
      var area = d3.area()
        .x(function(pt) { return xScaleFunc(pt.x); })
        .y0(function(pt) { return yScaleFunc(pt.ymin); })
        .y1(function(pt) { return yScaleFunc(pt.ymax); });
      d3.select(this).attr('d', area(d));
    });

    // geom_violin
    clippedGroup.selectAll('path.geom-violin').each(function(d) {
      if (!d || !Array.isArray(d)) return;
      var area = d3.area()
        .x(function(pt) { return xScaleFunc(pt.x); })
        .y0(function(pt) { return yScaleFunc(pt.ymin); })
        .y1(function(pt) { return yScaleFunc(pt.ymax); });
      d3.select(this).attr('d', area(d));
    });

    // geom_boxplot
    clippedGroup.selectAll('rect.geom-boxplot-box').each(function(d) {
      if (!d) return;
      var bbx0 = xScaleFunc(d.xmin);
      var bbx1 = xScaleFunc(d.xmax);
      var bby0 = yScaleFunc(d.ymin);
      var bby1 = yScaleFunc(d.ymax);
      d3.select(this)
        .attr('x', Math.min(bbx0, bbx1))
        .attr('y', Math.min(bby0, bby1))
        .attr('width', Math.abs(bbx1 - bbx0))
        .attr('height', Math.abs(bby1 - bby0));
    });

    clippedGroup.selectAll('line.geom-boxplot-whisker, line.geom-boxplot-median, line.geom-boxplot-staple').each(function(d) {
      if (!d) return;
      d3.select(this)
        .attr('x1', xScaleFunc(d.x))
        .attr('y1', yScaleFunc(d.y))
        .attr('x2', xScaleFunc(d.xend))
        .attr('y2', yScaleFunc(d.yend));
    });

    clippedGroup.selectAll('circle.geom-boxplot-outlier').each(function(d) {
      if (!d) return;
      d3.select(this)
        .attr('cx', xScaleFunc(d.x))
        .attr('cy', yScaleFunc(d.y));
    });
  }

  /**
   * Reposition path-based geoms by regenerating the d attribute.
   */
  function repositionPathGeoms(container, selector, xScale, yScale, isArea) {
    container.selectAll(selector).each(function(d) {
      if (!d || !Array.isArray(d)) return;

      if (isArea) {
        var area = d3.area()
          .x(function(pt) { return xScale(pt.x); })
          .y0(function(pt) { return yScale(pt.y0 !== undefined ? pt.y0 : 0); })
          .y1(function(pt) { return yScale(pt.y); });
        d3.select(this).attr('d', area(d));
      } else {
        var line = d3.line()
          .x(function(pt) { return xScale(pt.x); })
          .y(function(pt) { return yScale(pt.y); });
        d3.select(this).attr('d', line(d));
      }
    });
  }

  window.gg2d3.zoom = {
    attach: attach
  };
})();
