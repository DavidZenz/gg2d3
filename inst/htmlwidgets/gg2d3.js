HTMLWidgets.widget({
  name: 'gg2d3',
  type: 'output',

  factory: function (el, width, height) {

    // Store IR for resize support
    let currentIR = null;

    // Calculate panel dimensions with optional coord_fixed aspect ratio constraint
    // ratio: coord_fixed ratio (y data units per x data unit in pixel space)
    // xRange/yRange: data range extents for proper unit-aware aspect ratio
    function calculatePanelSize(availW, availH, ratio, xRange, yRange) {
      if (!ratio || ratio <= 0) {
        return { w: availW, h: availH, offsetX: 0, offsetY: 0 };
      }

      // coord_fixed(ratio=N) means N data units on y per 1 data unit on x
      // should occupy equal pixel length. So the pixel aspect ratio is:
      //   panelH / panelW = ratio * (yRange / xRange)
      // This ensures 1 unit of x data and 1 unit of y data have the correct
      // relative pixel sizes.
      var dataRatio = (yRange && xRange && xRange > 0) ? (yRange / xRange) : 1;
      var targetAspect = ratio * dataRatio; // desired panelH / panelW

      var panelW, panelH;
      if (availH / availW > targetAspect) {
        // Width-limited: use full width, constrain height
        panelW = availW;
        panelH = availW * targetAspect;
      } else {
        // Height-limited: use full height, constrain width
        panelH = availH;
        panelW = availH / targetAspect;
      }

      // Center panel in available space
      var offsetX = (availW - panelW) / 2;
      var offsetY = (availH - panelH) / 2;

      return { w: panelW, h: panelH, offsetX: offsetX, offsetY: offsetY };
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

      // Calculate padding from theme
      const pad = window.gg2d3.theme.calculatePadding(theme, ir.padding);

      const availW = Math.max(10, innerW - pad.left - pad.right);
      const availH = Math.max(10, innerH - pad.top - pad.bottom);

      // Apply coord_fixed aspect ratio constraint if present
      const coordRatio = ir.coord && ir.coord.ratio;
      // Extract data ranges for proper unit-aware aspect ratio
      var xDataRange = 0, yDataRange = 0;
      if (coordRatio) {
        var xs = ir.scales && ir.scales.x;
        var ys = ir.scales && ir.scales.y;
        if (xs && xs.domain && xs.domain.length === 2) {
          xDataRange = Math.abs(xs.domain[1] - xs.domain[0]);
        }
        if (ys && ys.domain && ys.domain.length === 2) {
          yDataRange = Math.abs(ys.domain[1] - ys.domain[0]);
        }
      }
      const panel = calculatePanelSize(availW, availH, coordRatio, xDataRange, yDataRange);
      const w = panel.w;
      const h = panel.h;

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
      const clipId = "panel-clip-" + Math.random().toString(36).slice(2, 9);
      root.append("defs").append("clipPath").attr("id", clipId)
        .append("rect").attr("width", w).attr("height", h);

      const g = root.append("g").attr("transform",
        `translate(${pad.left + panel.offsetX},${pad.top + panel.offsetY})`);

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
      const flip = !!(ir.coord && ir.coord.flip);
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
      if (ir.title) {
        root.append("text")
          .attr("x", innerW / 2)
          .attr("y", Math.max(14, pad.top * 0.6))
          .attr("text-anchor", "middle")
          .style("font-size", titleSpec && titleSpec.size ? `${titleSpec.size}px` : "13.2px")
          .style("fill", convertColor(titleSpec && titleSpec.colour) || "black")
          .style("font-weight", titleSpec && titleSpec.face === "bold" ? "bold" : "normal")
          .style("font-family", titleSpec && titleSpec.family || "sans-serif")
          .text(ir.title);
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
      if (xTitle) {
        root.append("text")
          .attr("x", pad.left + panel.offsetX + w / 2)
          .attr("y", pad.top + panel.offsetY + h + pad.bottom - panel.offsetY - 5)
          .attr("text-anchor", "middle")
          .style("font-size", axisTitleSpec && axisTitleSpec.size ? `${axisTitleSpec.size}px` : "11px")
          .style("fill", convertColor(axisTitleSpec && axisTitleSpec.colour) || "black")
          .style("font-family", axisTitleSpec && axisTitleSpec.family || "sans-serif")
          .text(xTitle);
      }

      const yTitle = ir.axes && ir.axes.y && ir.axes.y.label;
      if (yTitle) {
        const yTitleX = Math.max(12, pad.left + panel.offsetX - 35);
        root.append("text")
          .attr("x", yTitleX)
          .attr("y", pad.top + panel.offsetY + h / 2)
          .attr("text-anchor", "middle")
          .attr("transform", `rotate(-90, ${yTitleX}, ${pad.top + panel.offsetY + h / 2})`)
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
