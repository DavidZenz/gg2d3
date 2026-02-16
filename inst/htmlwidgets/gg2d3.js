HTMLWidgets.widget({
  name: 'gg2d3',
  type: 'output',

  factory: function (el, width, height) {

    // Store IR for resize support
    let currentIR = null;

    // ---------- renderPanel helper ----------
    function renderPanel(root, parentGroup, panelBox, panelData, ir, theme, convertColor, flip, panelNum, isFaceted) {
      const w = panelBox.w;
      const h = panelBox.h;
      const clipId = panelBox.clipId;

      // Create panel group translated to panel position
      const g = parentGroup.append("g")
        .attr("class", "panel panel-" + panelNum)
        .attr("transform", "translate(" + panelBox.x + "," + panelBox.y + ")");

      // Clip path definition
      root.select("defs").append("clipPath").attr("id", clipId)
        .append("rect").attr("width", w).attr("height", h);

      // Panel background
      const panelBg = theme.get("panel.background");
      if (panelBg && panelBg.type === "rect" && panelBg.fill) {
        g.append("rect")
          .attr("x", 0).attr("y", 0)
          .attr("width", w).attr("height", h)
          .attr("fill", convertColor(panelBg.fill))
          .attr("stroke", convertColor(panelBg.colour) || "none")
          .attr("stroke-width", panelBg.linewidth || 0);
      }

      // Create scales for this panel using panel-specific ranges
      // Only override domain for continuous scales; categorical scales keep their label domain
      const xDesc = ir.scales && ir.scales.x;
      const yDesc = ir.scales && ir.scales.y;
      const xScaleDesc = Object.assign({}, xDesc);
      const yScaleDesc = Object.assign({}, yDesc);
      if (xDesc && xDesc.type === "continuous" && panelData.x_range) {
        xScaleDesc.domain = panelData.x_range;
      }
      if (yDesc && yDesc.type === "continuous" && panelData.y_range) {
        yScaleDesc.domain = panelData.y_range;
      }

      const xScale = window.gg2d3.scales.createScale(xScaleDesc, flip ? [h, 0] : [0, w]);
      const yScale = window.gg2d3.scales.createScale(yScaleDesc, flip ? [0, w] : [h, 0]);

      // Grid - use panel-specific breaks
      const gridMajor = theme.get("grid.major");
      const gridMinor = theme.get("grid.minor");

      const xBreaks = panelData.x_breaks || (ir.scales && ir.scales.x && ir.scales.x.breaks);
      const yBreaks = panelData.y_breaks || (ir.scales && ir.scales.y && ir.scales.y.breaks);
      const xMinorBreaks = ir.scales && ir.scales.x && ir.scales.x.minor_breaks;
      const yMinorBreaks = ir.scales && ir.scales.y && ir.scales.y.minor_breaks;

      // Minor grid
      if (gridMinor && gridMinor.type !== "blank") {
        if (xMinorBreaks || yMinorBreaks) {
          window.gg2d3.theme.drawGrid(g, xScale, flip ? "horizontal" : "vertical", gridMinor, xMinorBreaks, w, h, convertColor);
          window.gg2d3.theme.drawGrid(g, yScale, flip ? "vertical" : "horizontal", gridMinor, yMinorBreaks, w, h, convertColor);
        }
      }

      // Major grid
      if (gridMajor && gridMajor.type !== "blank") {
        window.gg2d3.theme.drawGrid(g, xScale, flip ? "horizontal" : "vertical", gridMajor, xBreaks, w, h, convertColor);
        window.gg2d3.theme.drawGrid(g, yScale, flip ? "vertical" : "horizontal", gridMajor, yBreaks, w, h, convertColor);
      }

      // Clipped group for data
      const gClipped = g.append("g").attr("clip-path", "url(#" + clipId + ")");

      // Color scale (same for all panels)
      const cdesc = ir.scales && ir.scales.color;
      const colorScale = cdesc
        ? (cdesc.type === "continuous"
            ? d3.scaleSequential(d3.interpolateTurbo).domain(d3.extent(cdesc.domain || [0, 1]))
            : d3.scaleOrdinal(d3.schemeTableau10).domain(cdesc.domain || []))
        : function() { return null; };

      // Render layers - filter by PANEL
      let drawn = 0;
      (ir.layers || []).forEach(function(layer) {
        // Create a copy of the layer with filtered data for this panel
        const filteredData = isFaceted
          ? layer.data.filter(function(d) { return d.PANEL === panelNum; })
          : layer.data;  // non-faceted: use all data

        const filteredLayer = Object.assign({}, layer, { data: filteredData });

        const count = window.gg2d3.geomRegistry.render(
          filteredLayer,
          gClipped,
          xScale,
          yScale,
          { colorScale: colorScale, plotWidth: w, plotHeight: h, flip: flip }
        );
        drawn += count;
      });

      // Panel border (on top of geom layers)
      const panelBorder = theme.get("panel.border");
      if (panelBorder && panelBorder.type === "rect" && panelBorder.colour) {
        g.append("rect")
          .attr("x", 0).attr("y", 0)
          .attr("width", w).attr("height", h)
          .attr("fill", "none")
          .attr("stroke", convertColor(panelBorder.colour))
          .attr("stroke-width", panelBorder.linewidth || 1);
      }

      return drawn;
    }

    // ---------- draw ----------
    function draw(ir, elW, elH) {
      d3.select(el).selectAll("*").remove();

      const innerW = ir.width || elW || 640;
      const innerH = ir.height || elH || 400;

      // Get helpers and converters from modules
      const convertColor = window.gg2d3.scales.convertColor;

      // Create theme accessor with deep merge
      const theme = window.gg2d3.theme.createTheme(ir.theme);
      const flip = !!(ir.coord && ir.coord.flip);

      // Estimate legend dimensions from IR guides
      const legendPosition = (ir.legend && ir.legend.position) || "none";
      const legendDims = (ir.guides && ir.guides.length > 0 && legendPosition !== "none")
        ? window.gg2d3.legend.estimateLegendDimensions(ir.guides, theme, legendPosition)
        : { width: 0, height: 0 };

      // Extract data ranges for coord_fixed
      var xDataRange = 0, yDataRange = 0;
      if (ir.coord && ir.coord.ratio) {
        var xs = ir.scales && ir.scales.x;
        var ys = ir.scales && ir.scales.y;
        if (xs && xs.domain && xs.domain.length === 2) {
          xDataRange = Math.abs(xs.domain[1] - xs.domain[0]);
        }
        if (ys && ys.domain && ys.domain.length === 2) {
          yDataRange = Math.abs(ys.domain[1] - ys.domain[0]);
        }
      }

      // Build layout configuration from IR
      const layoutConfig = {
        width: innerW,
        height: innerH,
        theme: theme,
        titles: {
          title: ir.title || null,
          subtitle: ir.subtitle || null,
          caption: ir.caption || null
        },
        axes: {
          x: {
            label: (ir.axes && ir.axes.x && ir.axes.x.label) || null,
            tickLabels: (ir.axes && ir.axes.x && ir.axes.x.tickLabels) || []
          },
          y: {
            label: (ir.axes && ir.axes.y && ir.axes.y.label) || null,
            tickLabels: (ir.axes && ir.axes.y && ir.axes.y.tickLabels) || []
          },
          x2: (ir.axes && ir.axes.x2) || null,
          y2: (ir.axes && ir.axes.y2) || null
        },
        legend: {
          position: (ir.legend && ir.legend.position) || "none",
          width: legendDims.width,
          height: legendDims.height
        },
        coord: {
          type: (ir.coord && ir.coord.type) || "cartesian",
          flip: flip,
          ratio: (ir.coord && ir.coord.ratio) || null,
          xRange: xDataRange,
          yRange: yDataRange
        },
        facets: ir.facets && (ir.facets.type === "wrap" || ir.facets.type === "grid") ? {
          type: ir.facets.type,
          nrow: ir.facets.nrow,
          ncol: ir.facets.ncol,
          layout: ir.facets.layout,
          strips: ir.facets.strips || null,            // facet_wrap
          row_strips: ir.facets.row_strips || null,    // facet_grid
          col_strips: ir.facets.col_strips || null,    // facet_grid
          scales: ir.facets.scales || "fixed",
          spacing: ir.facets.spacing || 7.3
        } : null
      };

      const layout = window.gg2d3.layout.calculateLayout(layoutConfig);
      const isFaceted = layout.panels && layout.panels.length > 1;
      const isFacetGrid = ir.facets && ir.facets.type === "grid";

      const root = d3.select(el).append("svg").attr("width", innerW).attr("height", innerH);

      // Plot background (full SVG area)
      const plotBg = theme.get("plot.background");
      if (plotBg && plotBg.type === "rect" && plotBg.fill) {
        root.insert("rect", ":first-child")
          .attr("x", 0)
          .attr("y", 0)
          .attr("width", innerW)
          .attr("height", innerH)
          .attr("fill", convertColor(plotBg.fill))
          .attr("stroke", "none");
      }

      // Create defs group for clip paths
      root.append("defs");

      let totalDrawn = 0;

      if (isFaceted) {
        // Multi-panel rendering
        const panelsGroup = root.append("g").attr("class", "panels");

        layout.panels.forEach(function(panelBox) {
          // Find panel data from IR
          const panelData = (ir.panels || []).find(function(p) {
            return p.PANEL === panelBox.PANEL;
          }) || {};

          totalDrawn += renderPanel(
            root, panelsGroup, panelBox, panelData,
            ir, theme, convertColor, flip, panelBox.PANEL, true
          );
        });
      } else {
        // Single-panel rendering (existing behavior)
        const panelBox = {
          x: layout.panel.x,
          y: layout.panel.y,
          w: layout.panel.w,
          h: layout.panel.h,
          clipId: layout.clipId
        };
        const panelData = ir.panels && ir.panels[0] ? ir.panels[0] : {
          x_range: ir.scales && ir.scales.x && ir.scales.x.domain,
          y_range: ir.scales && ir.scales.y && ir.scales.y.domain,
          x_breaks: ir.scales && ir.scales.x && ir.scales.x.breaks,
          y_breaks: ir.scales && ir.scales.y && ir.scales.y.breaks
        };

        totalDrawn = renderPanel(
          root, root, panelBox, panelData,
          ir, theme, convertColor, flip, 1, false
        );
      }

      // Render strip labels (faceted plots only)
      // facet_wrap strips (one per panel, positioned above each panel)
      if (!isFacetGrid && isFaceted && layout.strips && layout.strips.length > 0) {
        const stripTheme = window.gg2d3.layout.getStripTheme(theme);

        layout.strips.forEach(function(strip) {
          const stripGroup = root.append("g")
            .attr("class", "strip strip-" + strip.PANEL);

          // Strip background rectangle
          stripGroup.append("rect")
            .attr("x", strip.x)
            .attr("y", strip.y)
            .attr("width", strip.w)
            .attr("height", strip.h)
            .attr("fill", stripTheme.bgFill)
            .attr("stroke", stripTheme.bgColour || "none")
            .attr("stroke-width", stripTheme.bgLinewidth);

          // Strip label text (centered in strip box)
          stripGroup.append("text")
            .attr("x", strip.x + strip.w / 2)
            .attr("y", strip.y + strip.h / 2)
            .attr("text-anchor", "middle")
            .attr("dominant-baseline", "central")
            .style("font-size", stripTheme.fontSize + "px")
            .style("fill", stripTheme.fontColour)
            .style("font-weight", stripTheme.fontFace === "bold" ? "bold" : "normal")
            .style("font-family", stripTheme.fontFamily)
            .text(strip.label);
        });
      }

      // facet_grid column strips (top of each column, horizontal text)
      if (isFacetGrid && layout.colStrips && layout.colStrips.length > 0) {
        const stripTheme = window.gg2d3.layout.getStripTheme(theme);
        layout.colStrips.forEach(function(strip) {
          const stripGroup = root.append("g").attr("class", "strip strip-col-" + strip.COL);
          // Background rect
          stripGroup.append("rect")
            .attr("x", strip.x).attr("y", strip.y)
            .attr("width", strip.w).attr("height", strip.h)
            .attr("fill", stripTheme.bgFill)
            .attr("stroke", stripTheme.bgColour || "none")
            .attr("stroke-width", stripTheme.bgLinewidth);
          // Label text (horizontal, centered)
          stripGroup.append("text")
            .attr("x", strip.x + strip.w / 2)
            .attr("y", strip.y + strip.h / 2)
            .attr("text-anchor", "middle")
            .attr("dominant-baseline", "central")
            .style("font-size", stripTheme.fontSize + "px")
            .style("fill", stripTheme.fontColour)
            .style("font-weight", stripTheme.fontFace === "bold" ? "bold" : "normal")
            .style("font-family", stripTheme.fontFamily)
            .text(strip.label);
        });
      }

      // facet_grid row strips (right of each row, rotated text)
      if (isFacetGrid && layout.rowStrips && layout.rowStrips.length > 0) {
        const stripTheme = window.gg2d3.layout.getStripTheme(theme);
        layout.rowStrips.forEach(function(strip) {
          const stripGroup = root.append("g").attr("class", "strip strip-row-" + strip.ROW);
          // Background rect
          stripGroup.append("rect")
            .attr("x", strip.x).attr("y", strip.y)
            .attr("width", strip.w).attr("height", strip.h)
            .attr("fill", stripTheme.bgFill)
            .attr("stroke", stripTheme.bgColour || "none")
            .attr("stroke-width", stripTheme.bgLinewidth);
          // Label text (rotated -90 degrees, centered in strip area)
          var cx = strip.x + strip.w / 2;
          var cy = strip.y + strip.h / 2;
          stripGroup.append("text")
            .attr("x", cx).attr("y", cy)
            .attr("text-anchor", "middle")
            .attr("dominant-baseline", "central")
            .attr("transform", "rotate(-90," + cx + "," + cy + ")")
            .style("font-size", stripTheme.fontSize + "px")
            .style("fill", stripTheme.fontColour)
            .style("font-weight", stripTheme.fontFace === "bold" ? "bold" : "normal")
            .style("font-family", stripTheme.fontFamily)
            .text(strip.label);
        });
      }

      // Title
      const titleSpec = theme.get("text.title");
      if (ir.title && layout.title.visible) {
        root.append("text")
          .attr("x", layout.title.x)
          .attr("y", layout.title.y)
          .attr("text-anchor", "middle")
          .style("font-size", titleSpec && titleSpec.size ? `${titleSpec.size}px` : "13.2px")
          .style("fill", convertColor(titleSpec && titleSpec.colour) || "black")
          .style("font-weight", titleSpec && titleSpec.face === "bold" ? "bold" : "normal")
          .style("font-family", titleSpec && titleSpec.family || "sans-serif")
          .text(ir.title);
      }

      // Subtitle
      const subtitleSpec = theme.get("text.subtitle");
      if (ir.subtitle && layout.subtitle.visible) {
        root.append("text")
          .attr("x", layout.subtitle.x)
          .attr("y", layout.subtitle.y)
          .attr("text-anchor", "middle")
          .style("font-size", subtitleSpec && subtitleSpec.size ? `${subtitleSpec.size}px` : "11px")
          .style("fill", convertColor(subtitleSpec && subtitleSpec.colour) || "#4D4D4D")
          .style("font-family", subtitleSpec && subtitleSpec.family || "sans-serif")
          .text(ir.subtitle);
      }

      // Caption
      const captionSpec = theme.get("text.caption");
      if (ir.caption && layout.caption.visible) {
        root.append("text")
          .attr("x", layout.caption.x)
          .attr("y", layout.caption.y)
          .attr("text-anchor", "middle")
          .style("font-size", captionSpec && captionSpec.size ? `${captionSpec.size}px` : "8.8px")
          .style("fill", convertColor(captionSpec && captionSpec.colour) || "#4D4D4D")
          .style("font-family", captionSpec && captionSpec.family || "sans-serif")
          .text(ir.caption);
      }

      // Axes - render AFTER data so they appear on top
      // Generic axis theme elements (fallback)
      const axisText = theme.get("axis.text");
      const axisLine = theme.get("axis.line");
      const axisTicks = theme.get("axis.ticks");

      // x/y-specific theme elements with fallback to generic
      const axisTextX = theme.get("axis.text.x") || axisText;
      const axisTextY = theme.get("axis.text.y") || axisText;
      const axisLineX = theme.get("axis.line.x") || axisLine;
      const axisLineY = theme.get("axis.line.y") || axisLine;
      const axisTicksX = theme.get("axis.ticks.x") || axisTicks;
      const axisTicksY = theme.get("axis.ticks.y") || axisTicks;

      // Axis title theme
      const axisTitleSpec = theme.get("axis.title");

      // Extract breaks and transforms for axis tick positioning
      const xBreaks = ir.scales && ir.scales.x && ir.scales.x.breaks;
      const yBreaks = ir.scales && ir.scales.y && ir.scales.y.breaks;
      const xTransform = ir.scales && ir.scales.x && ir.scales.x.transform;
      const yTransform = ir.scales && ir.scales.y && ir.scales.y.transform;

      // Create tick format for transformed scales
      const cleanFormat = d3.format(".4~g");

      if (isFaceted) {
        // Determine free scale mode
        const scalesMode = (ir.facets && ir.facets.scales) || "fixed";
        const isFreeX = scalesMode === "free" || scalesMode === "free_x";
        const isFreeY = scalesMode === "free" || scalesMode === "free_y";

        const maxRow = Math.max.apply(Math, ir.facets.layout.map(function(l) { return l.ROW; }));
        const panelW = layout.panels[0].w;
        const panelH = layout.panels[0].h;

        // Render axes for each panel based on free scale mode
        layout.panels.forEach(function(panelBox) {
          const layoutEntry = ir.facets.layout.find(function(l) { return l.PANEL === panelBox.PANEL; });
          const panelData = (ir.panels || []).find(function(p) { return p.PANEL === panelBox.PANEL; }) || {};
          const isBottomRow = layoutEntry.ROW === maxRow;
          const isLeftCol = layoutEntry.COL === 1;

          // Render x-axis if bottom row OR free_x/free
          if (isBottomRow || isFreeX) {
            // Create per-panel x scale using this panel's domain
            const xScaleDesc = Object.assign({}, ir.scales.x);
            if (isFreeX && xScaleDesc.type === "continuous" && panelData.x_range) {
              xScaleDesc.domain = panelData.x_range;
            }
            const panelXScale = window.gg2d3.scales.createScale(xScaleDesc, flip ? [panelH, 0] : [0, panelW]);

            const ag = root.append("g").attr("transform", "translate(" + panelBox.x + "," + (panelBox.y + panelH) + ")");
            const xAxisGen = d3.axisBottom(panelXScale);

            // Use panel-specific breaks for free scales
            const panelXBreaks = (isFreeX && panelData.x_breaks) ? panelData.x_breaks :
                                 (ir.scales.x && ir.scales.x.breaks);
            if (panelXBreaks && typeof panelXScale.bandwidth !== "function") {
              xAxisGen.tickValues(panelXBreaks);
            }
            if (xTransform && xTransform !== "identity" && typeof panelXScale.bandwidth !== "function") {
              xAxisGen.tickFormat(cleanFormat);
            }

            const xAxis = ag.append("g").attr("class", "axis").call(xAxisGen);
            window.gg2d3.theme.applyAxisStyle(xAxis, axisTextX, axisLineX, axisTicksX);
          }

          // Render y-axis if left column OR free_y/free
          if (isLeftCol || isFreeY) {
            const yScaleDesc = Object.assign({}, ir.scales.y);
            if (isFreeY && yScaleDesc.type === "continuous" && panelData.y_range) {
              yScaleDesc.domain = panelData.y_range;
            }
            const panelYScale = window.gg2d3.scales.createScale(yScaleDesc, flip ? [0, panelW] : [panelH, 0]);

            const ag = root.append("g").attr("transform", "translate(" + panelBox.x + "," + panelBox.y + ")");
            const yAxisGen = d3.axisLeft(panelYScale);

            const panelYBreaks = (isFreeY && panelData.y_breaks) ? panelData.y_breaks :
                                 (ir.scales.y && ir.scales.y.breaks);
            if (panelYBreaks && typeof panelYScale.bandwidth !== "function") {
              yAxisGen.tickValues(panelYBreaks);
            }
            if (yTransform && yTransform !== "identity" && typeof panelYScale.bandwidth !== "function") {
              yAxisGen.tickFormat(cleanFormat);
            }

            const yAxis = ag.append("g").attr("class", "axis").call(yAxisGen);
            window.gg2d3.theme.applyAxisStyle(yAxis, axisTextY, axisLineY, axisTicksY);
          }
        });
      } else {
        // Single-panel axis rendering
        const w = layout.panel.w;
        const h = layout.panel.h;

        // Create scales for axes
        const axisXScale = window.gg2d3.scales.createScale(ir.scales && ir.scales.x, flip ? [h, 0] : [0, w]);
        const axisYScale = window.gg2d3.scales.createScale(ir.scales && ir.scales.y, flip ? [0, w] : [h, 0]);

        // Axes group positioned at panel location
        const axesGroup = root.append("g")
          .attr("class", "axes-group")
          .attr("transform", "translate(" + layout.panel.x + "," + layout.panel.y + ")");

        if (flip) {
          // For flip: xScale is the x-aesthetic mapped to vertical range [h,0] -> LEFT axis
          //           yScale is the y-aesthetic mapped to horizontal range [0,w] -> BOTTOM axis
          const leftAxisGen = d3.axisLeft(axisXScale);
          const bottomAxisGen = d3.axisBottom(axisYScale);

          if (xBreaks && typeof axisXScale.bandwidth !== "function") {
            leftAxisGen.tickValues(xBreaks);
          }
          if (yBreaks && typeof axisYScale.bandwidth !== "function") {
            bottomAxisGen.tickValues(yBreaks);
          }

          if (xTransform && xTransform !== "identity" && typeof axisXScale.bandwidth !== "function") {
            leftAxisGen.tickFormat(cleanFormat);
          }
          if (yTransform && yTransform !== "identity" && typeof axisYScale.bandwidth !== "function") {
            bottomAxisGen.tickFormat(cleanFormat);
          }

          const leftAxis = axesGroup.append("g").attr("class", "axis axis-left").call(leftAxisGen);
          const bottomAxis = axesGroup.append("g").attr("class", "axis axis-bottom").attr("transform", "translate(0," + h + ")").call(bottomAxisGen);
          window.gg2d3.theme.applyAxisStyle(leftAxis, axisTextX, axisLineX, axisTicksX);
          window.gg2d3.theme.applyAxisStyle(bottomAxis, axisTextY, axisLineY, axisTicksY);
        } else {
          const xAxisGen = d3.axisBottom(axisXScale);
          const yAxisGen = d3.axisLeft(axisYScale);

          if (xBreaks && typeof axisXScale.bandwidth !== "function") {
            xAxisGen.tickValues(xBreaks);
          }
          if (yBreaks && typeof axisYScale.bandwidth !== "function") {
            yAxisGen.tickValues(yBreaks);
          }

          if (xTransform && xTransform !== "identity" && typeof axisXScale.bandwidth !== "function") {
            xAxisGen.tickFormat(cleanFormat);
          }
          if (yTransform && yTransform !== "identity" && typeof axisYScale.bandwidth !== "function") {
            yAxisGen.tickFormat(cleanFormat);
          }

          const xAxis = axesGroup.append("g").attr("class", "axis axis-bottom").attr("transform", "translate(0," + h + ")").call(xAxisGen);
          const yAxis = axesGroup.append("g").attr("class", "axis axis-left").call(yAxisGen);
          window.gg2d3.theme.applyAxisStyle(xAxis, axisTextX, axisLineX, axisTicksX);
          window.gg2d3.theme.applyAxisStyle(yAxis, axisTextY, axisLineY, axisTicksY);
        }
      }

      // Axis titles
      // ir.axes.x.label and ir.axes.y.label are already swapped for coord_flip in R
      // x label always goes below the bottom axis, y label always goes left of the left axis
      const xTitle = ir.axes && ir.axes.x && ir.axes.x.label;
      if (xTitle && layout.axisLabels.x.visible) {
        root.append("text")
          .attr("x", layout.axisLabels.x.x)
          .attr("y", layout.axisLabels.x.y)
          .attr("text-anchor", "middle")
          .style("font-size", axisTitleSpec && axisTitleSpec.size ? `${axisTitleSpec.size}px` : "11px")
          .style("fill", convertColor(axisTitleSpec && axisTitleSpec.colour) || "black")
          .style("font-family", axisTitleSpec && axisTitleSpec.family || "sans-serif")
          .text(xTitle);
      }

      const yTitle = ir.axes && ir.axes.y && ir.axes.y.label;
      if (yTitle && layout.axisLabels.y.visible) {
        root.append("text")
          .attr("x", layout.axisLabels.y.x)
          .attr("y", layout.axisLabels.y.y)
          .attr("text-anchor", "middle")
          .attr("transform", `rotate(${layout.axisLabels.y.rotation}, ${layout.axisLabels.y.x}, ${layout.axisLabels.y.y})`)
          .style("font-size", axisTitleSpec && axisTitleSpec.size ? `${axisTitleSpec.size}px` : "11px")
          .style("fill", convertColor(axisTitleSpec && axisTitleSpec.colour) || "black")
          .style("font-family", axisTitleSpec && axisTitleSpec.family || "sans-serif")
          .text(yTitle);
      }

      // Render legends (after panel content, using layout-computed positions)
      if (ir.guides && ir.guides.length > 0 && layout.legend.position !== "none") {
        window.gg2d3.legend.renderLegends(root, ir.guides, layout, theme);
      }

      // Fallback indicator if no marks drawn
      if (!totalDrawn) {
        console.warn("gg2d3: no marks drawn — check aes names and data types", ir);
        root.append("circle").attr("cx", innerW/2).attr("cy", innerH/2).attr("r", 6).attr("fill", "tomato");
      }
    }

    // ---------- widget API ----------
    return {
      renderValue: function (x) {
        let ir = (x && x.ir !== undefined) ? x.ir : x;
        if (typeof ir === "string") {
          try { ir = JSON.parse(ir); } catch (e) { console.error("gg2d3: JSON parse failed:", e, ir); return; }
        }
        if (!ir || !ir.scales) {
          console.warn("gg2d3: invalid IR payload", ir);
          d3.select(el).selectAll("*").remove();
          d3.select(el).append("svg").attr("width", width).attr("height", height)
            .append("rect").attr("x", 20).attr("y", 20).attr("width", 200).attr("height", 100).attr("fill", "tomato");
          return;
        }
        currentIR = ir;
        draw(ir, width, height);

        // Initialize crosstalk if metadata present
        if (typeof crosstalk !== 'undefined' && x.crosstalk_key && x.crosstalk_group) {
          if (window.gg2d3.crosstalk) {
            window.gg2d3.crosstalk.init(el, x.crosstalk_key, x.crosstalk_group);
          }
        }

        // Initialize Shiny message handlers if in Shiny mode
        if (window.gg2d3.crosstalk) {
          window.gg2d3.crosstalk.initShinyHandlers(el);
        }
      },
      resize: function (newWidth, newHeight) {
        width = newWidth;
        height = newHeight;
        if (currentIR) {
          draw(currentIR, newWidth, newHeight);
        }
      }
    };
  }
});
