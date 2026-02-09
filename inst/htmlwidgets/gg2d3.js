HTMLWidgets.widget({
  name: 'gg2d3',
  type: 'output',

  factory: function (el, width, height) {

    // Store IR for resize support
    let currentIR = null;

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
          width: 0,   // Phase 7 will provide actual dimensions
          height: 0
        },
        coord: {
          type: (ir.coord && ir.coord.type) || "cartesian",
          flip: flip,
          ratio: (ir.coord && ir.coord.ratio) || null,
          xRange: xDataRange,
          yRange: yDataRange
        }
      };

      const layout = window.gg2d3.layout.calculateLayout(layoutConfig);
      const w = layout.panel.w;
      const h = layout.panel.h;

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

      // Create clip-path for panel area (prevents geoms like abline from exceeding panel bounds)
      const clipId = layout.clipId;
      root.append("defs").append("clipPath").attr("id", clipId)
        .append("rect").attr("width", w).attr("height", h);

      const g = root.append("g").attr("transform",
        `translate(${layout.panel.x},${layout.panel.y})`);

      // Panel background (plot area)
      const panelBg = theme.get("panel.background");
      if (panelBg && panelBg.type === "rect" && panelBg.fill) {
        g.insert("rect", ":first-child")
          .attr("x", 0)
          .attr("y", 0)
          .attr("width", w)
          .attr("height", h)
          .attr("fill", convertColor(panelBg.fill))
          .attr("stroke", convertColor(panelBg.colour) || "none")
          .attr("stroke-width", panelBg.linewidth || 0);
      }

      // Create scales using module
      let xScale = window.gg2d3.scales.createScale(ir.scales && ir.scales.x, flip ? [h, 0] : [0, w]);
      let yScale = window.gg2d3.scales.createScale(ir.scales && ir.scales.y, flip ? [0, w] : [h, 0]);

      // Draw grid using theme module
      const gridMajor = theme.get("grid.major");
      const gridMinor = theme.get("grid.minor");

      // Draw minor grid first (so major grid draws over it)
      // When flipped: xScale maps vertical, so x-breaks draw horizontal lines;
      //               yScale maps horizontal, so y-breaks draw vertical lines
      if (gridMinor && gridMinor.type !== "blank") {
        const xMinorBreaks = ir.scales && ir.scales.x && ir.scales.x.minor_breaks;
        const yMinorBreaks = ir.scales && ir.scales.y && ir.scales.y.minor_breaks;
        if (xMinorBreaks || yMinorBreaks) {
          window.gg2d3.theme.drawGrid(g, xScale, flip ? "horizontal" : "vertical", gridMinor, xMinorBreaks, w, h, convertColor);
          window.gg2d3.theme.drawGrid(g, yScale, flip ? "vertical" : "horizontal", gridMinor, yMinorBreaks, w, h, convertColor);
        }
      }

      // Draw major grid using ggplot2's break positions
      if (gridMajor && gridMajor.type !== "blank") {
        const xBreaks = ir.scales && ir.scales.x && ir.scales.x.breaks;
        const yBreaks = ir.scales && ir.scales.y && ir.scales.y.breaks;
        window.gg2d3.theme.drawGrid(g, xScale, flip ? "horizontal" : "vertical", gridMajor, xBreaks, w, h, convertColor);
        window.gg2d3.theme.drawGrid(g, yScale, flip ? "vertical" : "horizontal", gridMajor, yBreaks, w, h, convertColor);
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

      // Color scale setup
      const cdesc = ir.scales && ir.scales.color;
      const colorScale = cdesc
        ? (cdesc.type === "continuous"
            ? d3.scaleSequential(d3.interpolateTurbo).domain(d3.extent(cdesc.domain || [0, 1]))
            : d3.scaleOrdinal(d3.schemeTableau10).domain(cdesc.domain || []))
        : () => null;

      // Create a clipped sub-group for data layers (after grid, so geoms render on top of grid)
      const gClipped = g.append("g").attr("clip-path", `url(#${clipId})`);

      // Render data layers using geom registry (inside clipped group)
      let drawn = 0;
      (ir.layers || []).forEach(layer => {
        const count = window.gg2d3.geomRegistry.render(
          layer,
          gClipped,
          xScale,
          yScale,
          { colorScale, plotWidth: w, plotHeight: h, flip }
        );
        drawn += count;
      });

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

      // Extract breaks and transforms for axis tick positioning (reuse from grid section above)
      const xBreaks = ir.scales && ir.scales.x && ir.scales.x.breaks;
      const yBreaks = ir.scales && ir.scales.y && ir.scales.y.breaks;
      const xTransform = ir.scales && ir.scales.x && ir.scales.x.transform;
      const yTransform = ir.scales && ir.scales.y && ir.scales.y.transform;

      // Create tick format for transformed scales
      const cleanFormat = d3.format(".4~g");

      if (flip) {
        // For flip: xScale is the x-aesthetic mapped to vertical range [h,0] -> LEFT axis
        //           yScale is the y-aesthetic mapped to horizontal range [0,w] -> BOTTOM axis
        // x-breaks go to left axis (xScale), y-breaks go to bottom axis (yScale)
        const leftAxisGen = d3.axisLeft(xScale);
        const bottomAxisGen = d3.axisBottom(yScale);

        // Set tick values: xBreaks for left axis (x-aesthetic), yBreaks for bottom axis (y-aesthetic)
        if (xBreaks && typeof xScale.bandwidth !== "function") {
          leftAxisGen.tickValues(xBreaks);
        }
        if (yBreaks && typeof yScale.bandwidth !== "function") {
          bottomAxisGen.tickValues(yBreaks);
        }

        // Set tick format for transformed scales
        if (xTransform && xTransform !== "identity" && typeof xScale.bandwidth !== "function") {
          leftAxisGen.tickFormat(cleanFormat);
        }
        if (yTransform && yTransform !== "identity" && typeof yScale.bandwidth !== "function") {
          bottomAxisGen.tickFormat(cleanFormat);
        }

        const leftAxis = g.append("g").attr("class", "axis").call(leftAxisGen);
        const bottomAxis = g.append("g").attr("class", "axis").attr("transform", `translate(0,${h})`).call(bottomAxisGen);
        // In flip: x-aesthetic themes apply to left axis, y-aesthetic themes to bottom axis
        window.gg2d3.theme.applyAxisStyle(leftAxis, axisTextX, axisLineX, axisTicksX);
        window.gg2d3.theme.applyAxisStyle(bottomAxis, axisTextY, axisLineY, axisTicksY);
      } else {
        // ggplot2 always places x-axis at the bottom of the panel
        const xAxisY = h;

        const xAxisGen = d3.axisBottom(xScale);
        const yAxisGen = d3.axisLeft(yScale);

        // Set tick values if breaks available and scale is continuous
        if (xBreaks && typeof xScale.bandwidth !== "function") {
          xAxisGen.tickValues(xBreaks);
        }
        if (yBreaks && typeof yScale.bandwidth !== "function") {
          yAxisGen.tickValues(yBreaks);
        }

        // Set tick format for transformed scales
        if (xTransform && xTransform !== "identity" && typeof xScale.bandwidth !== "function") {
          xAxisGen.tickFormat(cleanFormat);
        }
        if (yTransform && yTransform !== "identity" && typeof yScale.bandwidth !== "function") {
          yAxisGen.tickFormat(cleanFormat);
        }

        const xAxis = g.append("g").attr("class", "axis").attr("transform", `translate(0,${xAxisY})`).call(xAxisGen);
        const yAxis = g.append("g").attr("class", "axis").call(yAxisGen);
        // In normal: x-aesthetic themes apply to bottom axis, y-aesthetic themes to left axis
        window.gg2d3.theme.applyAxisStyle(xAxis, axisTextX, axisLineX, axisTicksX);
        window.gg2d3.theme.applyAxisStyle(yAxis, axisTextY, axisLineY, axisTicksY);
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

      // Fallback indicator if no marks drawn
      if (!drawn) {
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
