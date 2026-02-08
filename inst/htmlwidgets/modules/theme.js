// Theme factory for gg2d3
// Provides default theme values (matching ggplot2 theme_gray), deep merge, and axis styling

(function() {
  'use strict';

  // Initialize namespace
  if (!window.gg2d3) window.gg2d3 = {};
  if (!window.gg2d3.theme) window.gg2d3.theme = {};

  // Default theme values (matching ggplot2 theme_gray)
  const DEFAULT_THEME = {
    panel: {
      background: { type: "rect", fill: "#EBEBEB", colour: null },
      border: { type: "blank" }
    },
    plot: {
      background: { type: "rect", fill: "white", colour: "white" },
      margin: { type: "margin", top: 7.3, right: 7.3, bottom: 7.3, left: 7.3 }
    },
    grid: {
      major: { type: "line", colour: "white", linewidth: 1.89 },
      minor: { type: "line", colour: "white", linewidth: 0.945 }
    },
    axis: {
      line: { type: "blank" },
      text: { type: "text", colour: "#4D4D4D", size: 8.8 },
      title: { type: "text", colour: "black", size: 11 },
      ticks: { type: "line", colour: "#333333", linewidth: 1.89 }
    },
    text: {
      title: { type: "text", colour: "black", size: 13.2 }
    }
  };

  /**
   * Create a theme with deep merge of user-provided values over defaults.
   * @param {Object} userTheme - User-provided theme object (partial or complete)
   * @returns {Object} Theme accessor with get() method
   */
  function createTheme(userTheme) {
    const theme = userTheme || {};

    /**
     * Get theme value by dot-notation path with deep merge fallback.
     * @param {string} path - Dot-notation path (e.g., "axis.text", "grid.major")
     * @returns {*} Merged value or null if not found
     */
    function get(path) {
      const parts = path.split(".");
      let val = theme;
      let def = DEFAULT_THEME;
      for (const p of parts) {
        val = val && val[p];
        def = def && def[p];
      }
      return val || def || null;
    }

    return { get };
  }

  /**
   * Apply theme styling to axis elements.
   * Styles axis text (tick labels), axis line (domain), and tick marks.
   * @param {d3.Selection} axisGroup - D3 selection of axis group
   * @param {Object} textSpec - Theme element for axis.text
   * @param {Object} lineSpec - Theme element for axis.line
   * @param {Object} tickSpec - Theme element for axis.ticks
   */
  function applyAxisStyle(axisGroup, textSpec, lineSpec, tickSpec) {
    // Get convertColor from constants module
    const convertColor = window.gg2d3.scales && window.gg2d3.scales.convertColor
      ? window.gg2d3.scales.convertColor
      : (c) => c;  // Fallback identity function

    // Style axis text (tick labels)
    if (textSpec && textSpec.type === "text") {
      axisGroup.selectAll("text")
        .style("fill", convertColor(textSpec.colour) || "#4D4D4D")
        .style("font-size", textSpec.size ? `${textSpec.size}px` : "8.8px")
        .style("font-family", textSpec.family || "sans-serif")
        .style("font-weight", textSpec.face === "bold" ? "bold" : "normal")
        .style("font-style", textSpec.face === "italic" ? "italic" : "normal");
    }

    // Hide axis line if element_blank (theme_gray default)
    if (lineSpec && lineSpec.type === "blank") {
      axisGroup.select(".domain").attr("stroke", "none");
    } else if (lineSpec && lineSpec.type === "line") {
      axisGroup.select(".domain")
        .attr("stroke", convertColor(lineSpec.colour) || "black")
        .attr("stroke-width", lineSpec.linewidth || 1.89);
    }

    // Style tick marks
    if (tickSpec && tickSpec.type === "line") {
      axisGroup.selectAll(".tick line")
        .attr("stroke", convertColor(tickSpec.colour) || "#333333")
        .attr("stroke-width", tickSpec.linewidth || 1.89);
    }
  }

  /**
   * Calculate padding from theme plot.margin with additional space for axes/labels.
   * @param {Object} themeAccessor - Theme accessor with get() method
   * @param {Object} irPadding - Fallback padding from IR object
   * @returns {Object} Padding object with top, right, bottom, left
   */
  function calculatePadding(themeAccessor, irPadding) {
    const plotMargin = themeAccessor.get("plot.margin");
    let pad;
    if (plotMargin && plotMargin.type === "margin") {
      // Use theme margin plus additional space for axes/labels
      pad = {
        top: plotMargin.top + 30,
        right: plotMargin.right + 20,
        bottom: plotMargin.bottom + 40,
        left: plotMargin.left + 50
      };
    } else {
      pad = irPadding || { top: 40, right: 20, bottom: 50, left: 60 };
    }
    return pad;
  }

  /**
   * Draw grid lines (major or minor) for a scale.
   * @param {d3.Selection} g - D3 selection of main plot group
   * @param {Function} scale - D3 scale (x or y)
   * @param {string} orientation - "vertical" or "horizontal"
   * @param {Object} gridSpec - Theme element for grid (major or minor)
   * @param {Array} breaks - Array of break positions (from ggplot2 or null for D3 default)
   * @param {number} w - Plot width
   * @param {number} h - Plot height
   * @param {Function} convertColor - Color conversion function
   */
  function drawGrid(g, scale, orientation, gridSpec, breaks, w, h, convertColor) {
    if (!gridSpec || gridSpec.type === "blank") return;

    const isBand = typeof scale.bandwidth === "function";
    // Use ggplot2's breaks if provided, otherwise fall back to D3 default
    const ticks = breaks || (isBand ? scale.domain() : scale.ticks());

    ticks.forEach(tick => {
      const pos = isBand ? scale(tick) + scale.bandwidth() / 2 : scale(tick);
      if (orientation === "vertical") {
        g.insert("line", ".axis")
          .attr("x1", pos)
          .attr("x2", pos)
          .attr("y1", 0)
          .attr("y2", h)
          .attr("stroke", convertColor(gridSpec.colour) || "white")
          .attr("stroke-width", gridSpec.linewidth || 1.89)
          .attr("opacity", 0.8);
      } else {
        g.insert("line", ".axis")
          .attr("x1", 0)
          .attr("x2", w)
          .attr("y1", pos)
          .attr("y2", pos)
          .attr("stroke", convertColor(gridSpec.colour) || "white")
          .attr("stroke-width", gridSpec.linewidth || 1.89)
          .attr("opacity", 0.8);
      }
    });
  }

  // Export to window.gg2d3.theme namespace
  window.gg2d3.theme.DEFAULT_THEME = DEFAULT_THEME;
  window.gg2d3.theme.createTheme = createTheme;
  window.gg2d3.theme.applyAxisStyle = applyAxisStyle;
  window.gg2d3.theme.calculatePadding = calculatePadding;
  window.gg2d3.theme.drawGrid = drawGrid;

})();
