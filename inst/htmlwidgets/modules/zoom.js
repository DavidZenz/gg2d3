/**
 * gg2d3 Zoom Module
 *
 * Provides zoom and pan interaction for gg2d3 plots.
 * Uses d3.zoom() behavior with scale rescaling approach.
 *
 * @module gg2d3.zoom
 */

(function() {
  'use strict';

  // Initialize gg2d3 namespace if not exists
  if (typeof window.gg2d3 === 'undefined') {
    window.gg2d3 = {};
  }

  /**
   * Attach zoom behavior to a gg2d3 widget.
   *
   * Implementation strategy:
   * - Create invisible overlay rect for zoom capture
   * - On zoom event: rescale original scales, reposition elements, redraw axes
   * - NOT using SVG transform (which would scale stroke widths)
   *
   * @param {HTMLElement} el - Widget container element
   * @param {Object} config - Zoom configuration
   * @param {Array<number>} config.scale_extent - [min, max] zoom scale factors
   * @param {string} config.direction - "both", "x", or "y"
   * @param {Object} ir - Intermediate representation (for scale info)
   */
  function attach(el, config, ir) {
    const svg = d3.select(el).select('svg');

    if (svg.empty()) {
      console.warn('gg2d3.zoom: SVG element not found');
      return;
    }

    // Determine if this is a faceted plot
    const panels = svg.selectAll('.panel');
    const isFaceted = panels.size() > 1;

    if (isFaceted) {
      // Attach synchronized zoom to all panels
      attachToFacets(svg, panels, config, ir);
    } else {
      // Single panel - simpler case
      attachToSinglePanel(svg, panels.node() ? panels : svg.select('.panel'), config, ir);
    }
  }

  /**
   * Attach zoom to a single panel plot.
   */
  function attachToSinglePanel(svg, panelSelection, config, ir) {
    if (panelSelection.empty()) {
      console.warn('gg2d3.zoom: No panel found in SVG');
      return;
    }

    const panel = panelSelection.node();
    const panelGroup = d3.select(panel);

    // Find panel dimensions from background rect or clipPath
    const bgRect = panelGroup.select('rect').node();
    if (!bgRect) {
      console.warn('gg2d3.zoom: Panel background rect not found');
      return;
    }

    const panelWidth = parseFloat(bgRect.getAttribute('width'));
    const panelHeight = parseFloat(bgRect.getAttribute('height'));

    // Create original scales from IR
    const flip = !!(ir.coord && ir.coord.flip);
    const xScaleDesc = ir.scales && ir.scales.x;
    const yScaleDesc = ir.scales && ir.scales.y;

    const xScaleOriginal = window.gg2d3.scales.createScale(
      xScaleDesc,
      flip ? [panelHeight, 0] : [0, panelWidth]
    );
    const yScaleOriginal = window.gg2d3.scales.createScale(
      yScaleDesc,
      flip ? [0, panelWidth] : [panelHeight, 0]
    );

    // Store current scales (will be updated on zoom)
    let xScaleCurrent = xScaleOriginal.copy();
    let yScaleCurrent = yScaleOriginal.copy();

    // Create zoom overlay rect (invisible, captures all pointer events)
    const overlay = panelGroup.insert('rect', ':first-child')
      .attr('class', 'zoom-overlay')
      .attr('width', panelWidth)
      .attr('height', panelHeight)
      .style('fill', 'none')
      .style('pointer-events', 'all')
      .style('cursor', 'move');

    // Create zoom behavior
    const zoom = d3.zoom()
      .scaleExtent(config.scale_extent)
      .translateExtent([[0, 0], [panelWidth, panelHeight]])
      .extent([[0, 0], [panelWidth, panelHeight]])
      .on('zoom', zoomed);

    // Apply zoom to overlay
    overlay.call(zoom);

    // Handle zoom events
    function zoomed(event) {
      const transform = event.transform;

      // Rescale based on direction setting
      if (config.direction === 'both' || config.direction === 'x') {
        xScaleCurrent = transform.rescaleX(xScaleOriginal);
      } else {
        xScaleCurrent = xScaleOriginal.copy();
      }

      if (config.direction === 'both' || config.direction === 'y') {
        yScaleCurrent = transform.rescaleY(yScaleOriginal);
      } else {
        yScaleCurrent = yScaleOriginal.copy();
      }

      // Reposition all data elements
      repositionElements(panelGroup, xScaleCurrent, yScaleCurrent, flip);

      // Redraw axes and grid
      redrawAxesAndGrid(svg, panelGroup, xScaleCurrent, yScaleCurrent, ir, flip, panelWidth, panelHeight);
    }

    // Double-click to reset
    overlay.on('dblclick.zoom', function() {
      overlay.transition()
        .duration(750)
        .call(zoom.transform, d3.zoomIdentity);
    });
  }

  /**
   * Attach synchronized zoom to all panels in a faceted plot.
   */
  function attachToFacets(svg, panels, config, ir) {
    const panelData = [];

    panels.each(function() {
      const panelGroup = d3.select(this);
      const bgRect = panelGroup.select('rect').node();

      if (!bgRect) return;

      const panelWidth = parseFloat(bgRect.getAttribute('width'));
      const panelHeight = parseFloat(bgRect.getAttribute('height'));

      panelData.push({
        group: panelGroup,
        width: panelWidth,
        height: panelHeight
      });
    });

    if (panelData.length === 0) {
      console.warn('gg2d3.zoom: No valid panels found');
      return;
    }

    // Use first panel dimensions for zoom behavior
    const firstPanel = panelData[0];
    const flip = !!(ir.coord && ir.coord.flip);
    const xScaleDesc = ir.scales && ir.scales.x;
    const yScaleDesc = ir.scales && ir.scales.y;

    const xScaleOriginal = window.gg2d3.scales.createScale(
      xScaleDesc,
      flip ? [firstPanel.height, 0] : [0, firstPanel.width]
    );
    const yScaleOriginal = window.gg2d3.scales.createScale(
      yScaleDesc,
      flip ? [0, firstPanel.width] : [firstPanel.height, 0]
    );

    let xScaleCurrent = xScaleOriginal.copy();
    let yScaleCurrent = yScaleOriginal.copy();

    // Create overlay on each panel
    panelData.forEach(pd => {
      const overlay = pd.group.insert('rect', ':first-child')
        .attr('class', 'zoom-overlay')
        .attr('width', pd.width)
        .attr('height', pd.height)
        .style('fill', 'none')
        .style('pointer-events', 'all')
        .style('cursor', 'move');

      const zoom = d3.zoom()
        .scaleExtent(config.scale_extent)
        .translateExtent([[0, 0], [pd.width, pd.height]])
        .extent([[0, 0], [pd.width, pd.height]])
        .on('zoom', zoomed);

      overlay.call(zoom);

      function zoomed(event) {
        const transform = event.transform;

        if (config.direction === 'both' || config.direction === 'x') {
          xScaleCurrent = transform.rescaleX(xScaleOriginal);
        } else {
          xScaleCurrent = xScaleOriginal.copy();
        }

        if (config.direction === 'both' || config.direction === 'y') {
          yScaleCurrent = transform.rescaleY(yScaleOriginal);
        } else {
          yScaleCurrent = yScaleOriginal.copy();
        }

        // Update all panels synchronously
        panelData.forEach(p => {
          repositionElements(p.group, xScaleCurrent, yScaleCurrent, flip);
          redrawAxesAndGrid(svg, p.group, xScaleCurrent, yScaleCurrent, ir, flip, p.width, p.height);
        });

        // Synchronize other zoom instances
        panelData.forEach(p => {
          const otherOverlay = p.group.select('.zoom-overlay');
          if (otherOverlay.node() !== overlay.node()) {
            otherOverlay.call(zoom.transform, transform);
          }
        });
      }

      // Double-click to reset
      overlay.on('dblclick.zoom', function() {
        panelData.forEach(p => {
          p.group.select('.zoom-overlay')
            .transition()
            .duration(750)
            .call(zoom.transform, d3.zoomIdentity);
        });
      });
    });
  }

  /**
   * Reposition all geom elements using new scales.
   */
  function repositionElements(panelGroup, xScale, yScale, flip) {
    const clippedGroup = panelGroup.select('g[clip-path]');
    if (clippedGroup.empty()) return;

    // Get scale functions to use (flip swaps which scale goes to which axis)
    const xScaleFunc = flip ? yScale : xScale;
    const yScaleFunc = flip ? xScale : yScale;

    // geom_point: update circle positions
    clippedGroup.selectAll('circle.geom-point').each(function(d) {
      if (!d) return;
      d3.select(this)
        .attr('cx', xScaleFunc(d.x))
        .attr('cy', yScaleFunc(d.y));
    });

    // geom_bar: update rect positions and dimensions
    clippedGroup.selectAll('rect.geom-bar').each(function(d) {
      if (!d) return;
      const elem = d3.select(this);

      // Handle both vertical and horizontal bars
      if (flip) {
        // Horizontal bars (coord_flip)
        const y0 = yScaleFunc(d.y);
        const y1 = yScaleFunc(d.yend);
        const x0 = xScaleFunc(d.xmin);
        const x1 = xScaleFunc(d.xmax);
        elem
          .attr('x', Math.min(y0, y1))
          .attr('y', Math.min(x0, x1))
          .attr('width', Math.abs(y1 - y0))
          .attr('height', Math.abs(x1 - x0));
      } else {
        // Vertical bars
        const x0 = xScaleFunc(d.xmin);
        const x1 = xScaleFunc(d.xmax);
        const y0 = yScaleFunc(d.y);
        const y1 = yScaleFunc(d.yend);
        elem
          .attr('x', Math.min(x0, x1))
          .attr('y', Math.min(y0, y1))
          .attr('width', Math.abs(x1 - x0))
          .attr('height', Math.abs(y1 - y0));
      }
    });

    // geom_rect / geom_tile: update rect positions
    clippedGroup.selectAll('rect.geom-rect').each(function(d) {
      if (!d) return;
      const x0 = xScaleFunc(d.xmin);
      const x1 = xScaleFunc(d.xmax);
      const y0 = yScaleFunc(d.ymin);
      const y1 = yScaleFunc(d.ymax);
      d3.select(this)
        .attr('x', Math.min(x0, x1))
        .attr('y', Math.min(y0, y1))
        .attr('width', Math.abs(x1 - x0))
        .attr('height', Math.abs(y1 - y0));
    });

    // geom_text: update text positions
    clippedGroup.selectAll('text.geom-text').each(function(d) {
      if (!d) return;
      d3.select(this)
        .attr('x', xScaleFunc(d.x))
        .attr('y', yScaleFunc(d.y));
    });

    // geom_segment: update line positions
    clippedGroup.selectAll('line.geom-segment').each(function(d) {
      if (!d) return;
      d3.select(this)
        .attr('x1', xScaleFunc(d.x))
        .attr('y1', yScaleFunc(d.y))
        .attr('x2', xScaleFunc(d.xend))
        .attr('y2', yScaleFunc(d.yend));
    });

    // Path-based geoms: regenerate d attribute
    repositionPathGeoms(clippedGroup, 'path.geom-line', xScaleFunc, yScaleFunc);
    repositionPathGeoms(clippedGroup, 'path.geom-area', xScaleFunc, yScaleFunc, true);
    repositionPathGeoms(clippedGroup, 'path.geom-density', xScaleFunc, yScaleFunc, true);
    repositionPathGeoms(clippedGroup, 'path.geom-smooth', xScaleFunc, yScaleFunc);

    // geom_ribbon: special case with ymin/ymax
    clippedGroup.selectAll('path.geom-ribbon').each(function(d) {
      if (!d || !Array.isArray(d)) return;
      const area = d3.area()
        .x(pt => xScaleFunc(pt.x))
        .y0(pt => yScaleFunc(pt.ymin))
        .y1(pt => yScaleFunc(pt.ymax));
      d3.select(this).attr('d', area(d));
    });

    // geom_violin: like ribbon
    clippedGroup.selectAll('path.geom-violin').each(function(d) {
      if (!d || !Array.isArray(d)) return;
      const area = d3.area()
        .x(pt => xScaleFunc(pt.x))
        .y0(pt => yScaleFunc(pt.ymin))
        .y1(pt => yScaleFunc(pt.ymax));
      d3.select(this).attr('d', area(d));
    });

    // geom_boxplot: update box, whiskers, median
    clippedGroup.selectAll('rect.geom-boxplot-box').each(function(d) {
      if (!d) return;
      const x0 = xScaleFunc(d.xmin);
      const x1 = xScaleFunc(d.xmax);
      const y0 = yScaleFunc(d.ymin);
      const y1 = yScaleFunc(d.ymax);
      d3.select(this)
        .attr('x', Math.min(x0, x1))
        .attr('y', Math.min(y0, y1))
        .attr('width', Math.abs(x1 - x0))
        .attr('height', Math.abs(y1 - y0));
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
        const area = d3.area()
          .x(pt => xScale(pt.x))
          .y0(pt => yScale(pt.y0 !== undefined ? pt.y0 : 0))
          .y1(pt => yScale(pt.y));
        d3.select(this).attr('d', area(d));
      } else {
        const line = d3.line()
          .x(pt => xScale(pt.x))
          .y(pt => yScale(pt.y));
        d3.select(this).attr('d', line(d));
      }
    });
  }

  /**
   * Redraw axes and grid lines with new scales.
   */
  function redrawAxesAndGrid(svg, panelGroup, xScale, yScale, ir, flip, panelWidth, panelHeight) {
    // Remove existing axes
    svg.selectAll('.axis-x, .axis-y').remove();

    // Remove existing grid (it's inside panel, not on svg)
    panelGroup.selectAll('line[class*="grid"]').remove();

    // Get theme for styling
    const theme = window.gg2d3.theme.createTheme(ir.theme);
    const convertColor = window.gg2d3.scales.convertColor;

    // Redraw grid
    const gridMajor = theme.get('grid.major');
    const xBreaks = ir.scales && ir.scales.x && ir.scales.x.breaks;
    const yBreaks = ir.scales && ir.scales.y && ir.scales.y.breaks;

    if (gridMajor && gridMajor.type !== 'blank') {
      window.gg2d3.theme.drawGrid(
        panelGroup,
        xScale,
        flip ? 'horizontal' : 'vertical',
        gridMajor,
        xBreaks,
        panelWidth,
        panelHeight,
        convertColor
      );
      window.gg2d3.theme.drawGrid(
        panelGroup,
        yScale,
        flip ? 'vertical' : 'horizontal',
        gridMajor,
        yBreaks,
        panelWidth,
        panelHeight,
        convertColor
      );
    }

    // Redraw axes (they're on the SVG root, not panel)
    // Find the layout g group that contains axes
    const layoutGroup = svg.select('g');
    if (layoutGroup.empty()) return;

    // Get panel position to place axes correctly
    const panelTransform = panelGroup.attr('transform');
    const match = panelTransform ? panelTransform.match(/translate\(([^,]+),([^)]+)\)/) : null;
    const panelX = match ? parseFloat(match[1]) : 0;
    const panelY = match ? parseFloat(match[2]) : 0;

    // Create new axes
    const xAxis = flip ? d3.axisLeft(xScale) : d3.axisBottom(xScale);
    const yAxis = flip ? d3.axisBottom(yScale) : d3.axisLeft(yScale);

    // Apply tick values if specified in IR
    if (xBreaks) xAxis.tickValues(xBreaks);
    if (yBreaks) yAxis.tickValues(yBreaks);

    // Append x-axis
    const xAxisGroup = layoutGroup.append('g')
      .attr('class', 'axis-x')
      .attr('transform', `translate(${panelX}, ${panelY + panelHeight})`)
      .call(xAxis);

    // Append y-axis
    const yAxisGroup = layoutGroup.append('g')
      .attr('class', 'axis-y')
      .attr('transform', `translate(${panelX}, ${panelY})`)
      .call(yAxis);

    // Apply theme styling to axes
    const axisX = theme.get('axis.line.x');
    const axisY = theme.get('axis.line.y');

    if (axisX) {
      xAxisGroup.select('.domain')
        .attr('stroke', convertColor(axisX.colour) || 'black')
        .attr('stroke-width', axisX.linewidth || 1);
    }

    if (axisY) {
      yAxisGroup.select('.domain')
        .attr('stroke', convertColor(axisY.colour) || 'black')
        .attr('stroke-width', axisY.linewidth || 1);
    }
  }

  /**
   * Export zoom module API
   */
  window.gg2d3.zoom = {
    attach: attach
  };
})();
