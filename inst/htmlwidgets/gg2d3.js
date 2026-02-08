HTMLWidgets.widget({
  name: 'gg2d3',
  type: 'output',

  factory: function (el, width, height) {

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

      const w = Math.max(10, innerW - pad.left - pad.right);
      const h = Math.max(10, innerH - pad.top - pad.bottom);

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

      const g = root.append("g").attr("transform", `translate(${pad.left},${pad.top})`);

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

      // Render data layers using geom registry
      let drawn = 0;
      (ir.layers || []).forEach(layer => {
        const count = window.gg2d3.geomRegistry.render(
          layer,
          g,
          xScale,
          yScale,
          { colorScale, plotWidth: w, plotHeight: h }
        );
        drawn += count;
      });

      // Axes - render AFTER data so they appear on top
      const axisText = theme.get("axis.text");
      const axisLine = theme.get("axis.line");
      const axisTicks = theme.get("axis.ticks");

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
        window.gg2d3.theme.applyAxisStyle(leftAxis, axisText, axisLine, axisTicks);
        window.gg2d3.theme.applyAxisStyle(bottomAxis, axisText, axisLine, axisTicks);
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
        window.gg2d3.theme.applyAxisStyle(xAxis, axisText, axisLine, axisTicks);
        window.gg2d3.theme.applyAxisStyle(yAxis, axisText, axisLine, axisTicks);
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
        draw(ir, width, height);
      },
      resize: function () { /* store & redraw if needed */ }
    };
  }
});
