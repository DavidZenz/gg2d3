/**
 * gg2d3 Legend Module
 *
 * Provides legend rendering functions for discrete legends and colorbars.
 * Estimates dimensions before rendering for layout engine integration.
 *
 * @module gg2d3.legend
 */

(function() {
  'use strict';

  // Initialize namespace
  if (!window.gg2d3) window.gg2d3 = {};

  // =========================================================================
  // Theme Extraction Helper
  // =========================================================================

  /**
   * Extract legend-specific theme values
   * @param {Object} theme - Theme accessor from createTheme()
   * @returns {Object} Legend theme defaults
   */
  function getThemeDefaults(theme) {
    const ptToPx = window.gg2d3.constants.ptToPx;
    const convertColor = window.gg2d3.scales.convertColor;

    // Extract theme elements
    const keyTheme = theme.get("legend.key") || {};
    const textTheme = theme.get("legend.text") || {};
    const titleTheme = theme.get("legend.title") || {};
    const bgTheme = theme.get("legend.background") || {};
    const legSpacing = theme.get("legend.spacing") || ptToPx(11);

    return {
      // Key size: ggplot2 default is 1.2 lines = 1.2 * 11pt = 13.2pt
      keySize: keyTheme.size ? ptToPx(keyTheme.size) : ptToPx(13.2),

      // Text sizes: ggplot2 defaults
      textSize: textTheme.size ? ptToPx(textTheme.size) : ptToPx(8.8),
      titleSize: titleTheme.size ? ptToPx(titleTheme.size) : ptToPx(11),

      // Colors
      titleColour: convertColor(titleTheme.colour || "black"),
      textColour: convertColor(textTheme.colour || "black"),

      // Spacing
      keySpacing: ptToPx(5.5),
      titleSpacing: (titleTheme.margin && titleTheme.margin.bottom) || ptToPx(5.5),
      spacing: legSpacing,

      // Backgrounds
      keyBackground: convertColor(keyTheme.fill || "white"),
      keyStroke: keyTheme.colour && keyTheme.colour !== "NA" ? convertColor(keyTheme.colour) : "none",
      legendBackground: bgTheme.type !== "blank" ? convertColor(bgTheme.fill || "white") : "transparent",
      legendStroke: bgTheme.colour && bgTheme.colour !== "NA" ? convertColor(bgTheme.colour) : "none",

      // Margin now handled by renderLegends container pass
      margin: 0
    };
  }

  // =========================================================================
  // Shape Mapping Helper
  // =========================================================================

  /**
   * Map ggplot2 shape codes to D3 symbol types
   * @param {number} shapeCode - ggplot2 shape code
   * @returns {Function} D3 symbol type generator
   */
  function getD3Symbol(shapeCode) {
    const shapeMap = {
      0: d3.symbolSquare,      // open square
      1: d3.symbolCircle,      // open circle
      2: d3.symbolTriangle,    // open triangle
      3: d3.symbolCross,       // plus
      4: d3.symbolCross,       // cross (X) - D3 v7 doesn't have symbolTimes, use cross
      5: d3.symbolDiamond,     // open diamond
      15: d3.symbolSquare,     // filled square
      16: d3.symbolCircle,     // filled circle
      17: d3.symbolTriangle,   // filled triangle
      18: d3.symbolDiamond,    // filled diamond
      19: d3.symbolCircle      // solid circle (default)
    };
    return shapeMap[shapeCode] || d3.symbolCircle;
  }

  /**
   * Check if shape is filled or open (stroke only)
   * @param {number} shapeCode - ggplot2 shape code
   * @returns {boolean} True if filled
   */
  function isFilledShape(shapeCode) {
    return shapeCode >= 15 && shapeCode <= 19;
  }

  // =========================================================================
  // Dimension Estimation
  // =========================================================================

  /**
   * Estimate legend dimensions for ALL guides before rendering.
   * Called by layout engine to reserve correct space.
   *
   * @param {Array} guides - Array of guide IR objects
   * @param {Object} theme - Theme accessor
   * @returns {Object} {width, height} in pixels
   */
  function estimateLegendDimensions(guides, theme, position) {
    if (!guides || guides.length === 0) {
      return { width: 0, height: 0 };
    }

    position = position || "right";
    const defaults = getThemeDefaults(theme);
    const estimateTextWidth = window.gg2d3.layout.estimateTextWidth;
    const estimateTextHeight = window.gg2d3.layout.estimateTextHeight;

    let totalWidth = 0;
    let totalHeight = 0;

    const isVertical = position === "right" || position === "left";

    guides.forEach((guide, idx) => {
      if (!guide || guide.position === "none") return;

      const titleHeight = guide.title ?
        estimateTextHeight(defaults.titleSize) + defaults.titleSpacing : 0;

      // Title width (no longer includes Reset — that's its own row below the keys).
      const titleWidth = guide.title ?
        estimateTextWidth(guide.title, defaults.titleSize) + defaults.margin * 2 : 0;

      // Reset is rendered as a row below the keys for discrete legends.
      // Reserve vertical space for it so the layout doesn't crop the row.
      const isDiscrete = guide.type === "legend";
      const resetRowHeight = isDiscrete
        ? estimateTextHeight(defaults.textSize) + defaults.titleSpacing
        : 0;

      if (guide.type === "legend") {
        // Discrete legend
        const nKeys = guide.keys ? guide.keys.length : 0;
        let width, height;

        if (isVertical) {
          // Vertical: keys stacked, labels to the right
          const maxLabelWidth = guide.keys ?
            Math.max(...guide.keys.map(k => estimateTextWidth(String(k.label || ""), defaults.textSize))) : 0;
          const keysWidth = defaults.keySize + defaults.keySpacing + maxLabelWidth + defaults.margin * 2;
          width = Math.max(keysWidth, titleWidth);
          height = titleHeight + (nKeys * (defaults.keySize + defaults.keySpacing)) + resetRowHeight + defaults.margin * 2;
        } else {
          // Horizontal: title left, then keys in a row, labels below keys
          const maxLabelWidth = guide.keys ?
            Math.max(...guide.keys.map(k => estimateTextWidth(String(k.label || ""), defaults.textSize))) : 0;
          const colWidth = Math.max(defaults.keySize, maxLabelWidth) + defaults.keySpacing;
          const nk = guide.keys ? guide.keys.length : 0;
          const inlineTitleWidth = guide.title ?
            estimateTextWidth(guide.title, defaults.titleSize) + defaults.keySpacing : 0;
          width = defaults.margin + inlineTitleWidth + nk * colWidth + defaults.margin;
          // Height: single row of keys + labels below + Reset row + margins
          height = defaults.keySize + defaults.textSize + resetRowHeight + defaults.margin * 2;
        }

        if (isVertical) {
          totalWidth = Math.max(totalWidth, width);
          totalHeight += height;
        } else {
          totalWidth += width;
          totalHeight = Math.max(totalHeight, height);
        }
      } else if (guide.type === "colorbar") {
        // Colorbar — only min/max labels shown
        const barWidth = defaults.keySize;
        const barHeight = 5 * defaults.keySize;
        const endLabels = guide.keys && guide.keys.length > 0 ?
          [guide.keys[0], guide.keys[guide.keys.length - 1]] : [];
        const maxLabelWidth = endLabels.length > 0 ?
          Math.max(...endLabels.map(k => estimateTextWidth(String(k.label || ""), defaults.textSize))) : 0;

        const barContentWidth = barWidth + 5 + maxLabelWidth + defaults.margin * 2;
        const width = Math.max(barContentWidth, titleWidth);
        const height = titleHeight + barHeight + defaults.margin * 2;

        if (isVertical) {
          totalWidth = Math.max(totalWidth, width);
          totalHeight += height;
        } else {
          totalWidth += width;
          totalHeight = Math.max(totalHeight, height);
        }
      }

      // Add spacing between guides (11pt in ggplot2)
      if (idx < guides.length - 1) {
        if (isVertical) {
          totalHeight += window.gg2d3.constants.ptToPx(11);
        } else {
          totalWidth += window.gg2d3.constants.ptToPx(11);
        }
      }
    });

    return { width: totalWidth, height: totalHeight };
  }

  // =========================================================================
  // Discrete Legend Renderer
  // =========================================================================

  /**
   * Render a discrete legend (guide_legend).
   *
   * @param {d3.Selection} svg - Parent SVG selection
   * @param {Object} guide - Guide IR object
   * @param {number} x - X position
   * @param {number} y - Y position
   * @param {Object} theme - Theme accessor
   * @param {string} direction - "vertical" or "horizontal" key layout
   * @returns {d3.Selection} Legend group element
   */
  function renderDiscreteLegend(svg, guide, x, y, theme, direction) {
    direction = direction || "vertical";
    const defaults = getThemeDefaults(theme);
    const convertColor = window.gg2d3.scales.convertColor;
    const mmToPxRadius = window.gg2d3.constants.mmToPxRadius;
    const estimateTextWidth = window.gg2d3.layout.estimateTextWidth;

    // Create legend group
    const g = svg.append("g")
      .attr("class", "gg2d3-legend")
      .attr("transform", `translate(${x}, ${y})`);

    let currentY = defaults.margin;

    // Determine which aesthetics this guide represents
    const hasColour = guide.aesthetics && guide.aesthetics.includes("colour");
    const hasFill = guide.aesthetics && guide.aesthetics.includes("fill");
    const hasSize = guide.aesthetics && guide.aesthetics.includes("size");
    const hasShape = guide.aesthetics && guide.aesthetics.includes("shape");
    const primaryAesthetic = guide.aesthetics && guide.aesthetics.length
      ? guide.aesthetics[0]
      : "legend";

    // Pre-compute uniform column width for horizontal layout
    let columnWidth = defaults.keySize;
    if (direction === "horizontal" && guide.keys && guide.keys.length > 0) {
      const maxLabelW = Math.max(...guide.keys.map(k =>
        estimateTextWidth(String(k.label || ""), defaults.textSize)));
      columnWidth = Math.max(defaults.keySize, maxLabelW) + defaults.keySpacing;
    }

    // Draw title
    let titleElement = null;
    let resetElement = null;
    let currentX = defaults.margin;
    if (guide.title) {
      if (direction === "horizontal") {
        // Horizontal: title to the left of keys, vertically centered with key row
        titleElement = g.append("text")
          .attr("class", "legend-title")
          .attr("x", defaults.margin)
          .attr("y", currentY + defaults.keySize / 2)
          .attr("dy", "0.35em")
          .attr("fill", defaults.titleColour)
          .style("font-size", `${defaults.titleSize}px`)
          .style("font-weight", "normal")
          .style("font-family", "sans-serif")
          .text(guide.title);
        currentX = defaults.margin + estimateTextWidth(guide.title, defaults.titleSize) + defaults.keySpacing;
      } else {
        // Vertical: title above keys (Reset control is rendered as its own
        // row below the keys after the keys loop completes, not inline next
        // to the title — keeps the title row visually clean and keeps Reset
        // out of the panel boundary).
        titleElement = g.append("text")
          .attr("class", "legend-title")
          .attr("x", defaults.margin)
          .attr("y", currentY + defaults.titleSize * 0.8)
          .attr("fill", defaults.titleColour)
          .style("font-size", `${defaults.titleSize}px`)
          .style("font-weight", "normal")
          .style("font-family", "sans-serif")
          .text(guide.title);

        currentY += defaults.titleSize + defaults.titleSpacing;
      }
    }
    if (guide.keys && guide.keys.length > 0) {
      guide.keys.forEach((key, idx) => {
        let keyX, keyY;
        if (direction === "horizontal") {
          keyX = currentX + (columnWidth - defaults.keySize) / 2; // center key in column
          keyY = currentY;
        } else {
          keyX = defaults.margin;
          keyY = currentY + idx * (defaults.keySize + defaults.keySpacing);
        }

        const level = (key.value !== undefined && key.value !== null)
          ? key.value
          : (key.label !== undefined && key.label !== null ? key.label : idx);
        const legendKey = `${primaryAesthetic}::${String(level)}`;

        // Interactive legend item wrapper with deterministic identity attrs
        const item = g.append("g")
          .attr("class", "legend-item")
          .attr("data-legend-key", legendKey)
          .attr("data-aesthetic", primaryAesthetic)
          .attr("data-level", String(level))
          .style("cursor", "pointer")
          .on("click.legend", function(event) {
            event.preventDefault();
            if (window.gg2d3 && window.gg2d3.events && window.gg2d3.events.handleLegendClick) {
              const host = this.closest('.html-widget') || this.closest('.gg2d3');
              if (host) {
                window.gg2d3.events.handleLegendClick(host, {
                  key: legendKey,
                  aesthetic: primaryAesthetic,
                  level: String(level)
                });
              }
            }
          })
          .on("dblclick.legend", function(event) {
            event.preventDefault();
            event.stopPropagation();
            if (window.gg2d3 && window.gg2d3.events && window.gg2d3.events.handleLegendDoubleClick) {
              const host = this.closest('.html-widget') || this.closest('.gg2d3');
              if (host) {
                window.gg2d3.events.handleLegendDoubleClick(host, {
                  key: legendKey,
                  aesthetic: primaryAesthetic,
                  level: String(level)
                });
              }
            }
          })
          .on("mouseover.legend", function() {
            if (window.gg2d3 && window.gg2d3.events && window.gg2d3.events.dispatchLegend) {
              const host = this.closest('.html-widget') || this.closest('.gg2d3');
              if (host) {
                window.gg2d3.events.dispatchLegend(host, 'legend:hoverin', { key: legendKey });
              }
            }
          })
          .on("mouseout.legend", function() {
            if (window.gg2d3 && window.gg2d3.events && window.gg2d3.events.dispatchLegend) {
              const host = this.closest('.html-widget') || this.closest('.gg2d3');
              if (host) {
                window.gg2d3.events.dispatchLegend(host, 'legend:hoverout', { key: legendKey });
              }
            }
          });

        // Draw key background (ggplot2 default: grey92 fill, no border)
        item.append("rect")
          .attr("class", "legend-key-bg")
          .attr("x", keyX)
          .attr("y", keyY)
          .attr("width", defaults.keySize)
          .attr("height", defaults.keySize)
          .attr("fill", defaults.keyBackground)
          .attr("stroke", defaults.keyStroke)
          .attr("stroke-width", defaults.keyStroke === "none" ? 0 : 0.5);

        // Draw key symbol
        const cX = keyX + defaults.keySize / 2;
        const cY = keyY + defaults.keySize / 2;

        if (hasShape) {
          const shapeCode = key.shape !== undefined ? key.shape : 19;
          const symbolGenerator = d3.symbol()
            .type(getD3Symbol(shapeCode))
            .size(64);

          const fillColor = hasFill ? convertColor(key.fill || "black") :
                           hasColour ? convertColor(key.colour || "black") : "black";
          const strokeColor = hasColour && !hasFill ? convertColor(key.colour || "black") : "none";

          item.append("path")
            .attr("class", "legend-key-shape")
            .attr("transform", `translate(${cX}, ${cY})`)
            .attr("d", symbolGenerator)
            .attr("fill", isFilledShape(shapeCode) ? fillColor : "none")
            .attr("stroke", isFilledShape(shapeCode) ? "none" : strokeColor)
            .attr("stroke-width", 1);

        } else if (hasSize) {
          const sizeValue = key.size !== undefined ? key.size : 1.5;
          const radius = mmToPxRadius(sizeValue);

          item.append("circle")
            .attr("class", "legend-key-size")
            .attr("cx", cX)
            .attr("cy", cY)
            .attr("r", radius)
            .attr("fill", "black")
            .attr("stroke", "none");

        } else if (hasColour || hasFill) {
          const fillValue = hasFill ? (key.fill || "#4D4D4D") :
                           hasColour ? (key.colour || "#4D4D4D") : "#4D4D4D";

          item.append("rect")
            .attr("class", "legend-key-swatch")
            .attr("x", keyX)
            .attr("y", keyY)
            .attr("width", defaults.keySize)
            .attr("height", defaults.keySize)
            .attr("fill", convertColor(fillValue))
            .attr("stroke", defaults.keyStroke)
            .attr("stroke-width", defaults.keyStroke === "none" ? 0 : 0.5);
        }

        // Draw label
        if (direction === "horizontal") {
          // Label below key, centered on column
          item.append("text")
            .attr("class", "legend-key-label")
            .attr("x", currentX + columnWidth / 2)
            .attr("y", keyY + defaults.keySize + defaults.textSize * 0.9)
            .attr("text-anchor", "middle")
            .attr("fill", defaults.textColour)
            .style("font-size", `${defaults.textSize}px`)
            .style("font-family", "sans-serif")
            .text(String(key.label || ""));

          // Advance X for next key (uniform column width)
          currentX += columnWidth;
        } else {
          // Label to right of key for vertical layout
          item.append("text")
            .attr("class", "legend-key-label")
            .attr("x", keyX + defaults.keySize + defaults.keySpacing)
            .attr("y", cY)
            .attr("dy", "0.35em")
            .attr("fill", defaults.textColour)
            .style("font-size", `${defaults.textSize}px`)
            .style("font-family", "sans-serif")
            .text(String(key.label || ""));
        }
      });
    }

    // Compute content width for background and title positioning
    const nKeys = guide.keys ? guide.keys.length : 0;
    let contentWidth;

    if (direction === "horizontal") {
      contentWidth = currentX + defaults.margin;
    } else {
      const maxLabelWidth = guide.keys ?
        Math.max(...guide.keys.map(k => estimateTextWidth(String(k.label || ""), defaults.textSize))) : 0;
      contentWidth = defaults.keySize + defaults.keySpacing + maxLabelWidth + defaults.margin * 2;
    }

    // For vertical layout, ensure at least as wide as title
    if (direction === "vertical") {
      const titleW = guide.title ?
        estimateTextWidth(guide.title, defaults.titleSize) + defaults.margin * 2 : 0;
      contentWidth = Math.max(contentWidth, titleW);
    }

    // Reset control: render BELOW the keys as its own row (for discrete
    // legends — colorbars don't have a Reset). Positioned at left margin
    // with a small gap above the keys row.
    const isDiscrete = guide.type === "legend";
    const resetRowHeight = isDiscrete
      ? defaults.textSize + defaults.titleSpacing
      : 0;
    if (isDiscrete) {
      let resetY;
      if (direction === "horizontal") {
        // Horizontal keys: label is below the swatch (keySize + textSize).
        resetY = currentY + defaults.keySize + defaults.textSize + defaults.titleSpacing;
      } else {
        // Vertical keys: stack of nKeys swatches.
        const lastKeyBottom = currentY + (nKeys > 0
          ? (nKeys - 1) * (defaults.keySize + defaults.keySpacing) + defaults.keySize
          : 0);
        resetY = lastKeyBottom + defaults.titleSpacing;
      }

      // Position: left-aligned for vertical legends (sits under the keys
      // column), horizontally centered for horizontal legends (centered
      // under the row of keys to mirror the keys' centering).
      const resetX = direction === "horizontal" ? contentWidth / 2 : defaults.margin;
      const resetAnchor = direction === "horizontal" ? "middle" : "start";

      resetElement = g.append("text")
        .attr("class", "legend-reset-control")
        .attr("x", resetX)
        .attr("y", resetY + defaults.textSize * 0.8)
        .attr("text-anchor", resetAnchor)
        .attr("fill", defaults.textColour)
        .style("font-size", `${defaults.textSize}px`)
        .style("font-family", "sans-serif")
        .style("cursor", "pointer")
        .text("Reset")
        .on("click.legend", function(event) {
          event.preventDefault();
          event.stopPropagation();
          if (window.gg2d3 && window.gg2d3.events && window.gg2d3.events.dispatchLegend) {
            const host = this.closest('.html-widget') || this.closest('.gg2d3');
            if (host) {
              window.gg2d3.events.dispatchLegend(host, 'legend:reset', {});
            }
          }
        });
    }

    // Draw legend background behind all content (insert as first child)
    if (defaults.legendBackground !== "transparent") {
      let bgHeight;
      if (direction === "horizontal") {
        bgHeight = currentY + defaults.keySize + defaults.textSize + defaults.margin + resetRowHeight;
      } else {
        const lastKeyY = currentY + (nKeys > 0 ? (nKeys - 1) * (defaults.keySize + defaults.keySpacing) : 0);
        bgHeight = lastKeyY + defaults.keySize + defaults.margin + resetRowHeight;
      }

      g.insert("rect", ":first-child")
        .attr("class", "legend-background")
        .attr("x", 0)
        .attr("y", 0)
        .attr("width", contentWidth)
        .attr("height", bgHeight)
        .attr("fill", defaults.legendBackground)
        .attr("stroke", defaults.legendStroke)
        .attr("stroke-width", defaults.legendStroke === "none" ? 0 : 0.5);
    }

    return g;
  }

  // =========================================================================
  // Colorbar Renderer
  // =========================================================================

  /**
   * Render a continuous colorbar (guide_colorbar).
   *
   * @param {d3.Selection} svg - Parent SVG selection
   * @param {Object} guide - Guide IR object
   * @param {number} x - X position
   * @param {number} y - Y position
   * @param {Object} theme - Theme accessor
   * @returns {d3.Selection} Colorbar group element
   */
  function renderColorbar(svg, guide, x, y, theme) {
    const defaults = getThemeDefaults(theme);
    const convertColor = window.gg2d3.scales.convertColor;

    // Create colorbar group
    const g = svg.append("g")
      .attr("class", "gg2d3-colorbar")
      .attr("transform", `translate(${x}, ${y})`);

    let currentY = defaults.margin;

    // Draw title if present
    if (guide.title) {
      g.append("text")
        .attr("class", "colorbar-title")
        .attr("x", defaults.margin)
        .attr("y", currentY + defaults.titleSize * 0.8)
        .attr("fill", defaults.titleColour)
        .style("font-size", `${defaults.titleSize}px`)
        .style("font-weight", "normal")
        .style("font-family", "sans-serif")
        .text(guide.title);

      currentY += defaults.titleSize + defaults.titleSpacing;
    }

    // Colorbar dimensions
    const barWidth = defaults.keySize;
    const barHeight = 5 * defaults.keySize;
    const barX = defaults.margin;
    const barY = currentY;

    // Create gradient
    const gradientId = `legend-grad-${Math.random().toString(36).substr(2, 9)}`;
    const defs = svg.append("defs");
    const gradient = defs.append("linearGradient")
      .attr("id", gradientId)
      .attr("x1", "0%")
      .attr("x2", "0%")
      .attr("y1", "100%") // Bottom
      .attr("y2", "0%");  // Top

    // Add color stops
    const colors = guide.colors || (guide.keys ? guide.keys.map(k => k.colour || k.fill || "#4D4D4D") : ["#4D4D4D"]);
    colors.forEach((color, idx) => {
      const offset = (idx / (colors.length - 1)) * 100;
      gradient.append("stop")
        .attr("offset", `${offset}%`)
        .attr("stop-color", convertColor(color));
    });

    // Draw gradient rectangle
    g.append("rect")
      .attr("class", "colorbar-gradient")
      .attr("x", barX)
      .attr("y", barY)
      .attr("width", barWidth)
      .attr("height", barHeight)
      .attr("fill", `url(#${gradientId})`)
      .attr("stroke", convertColor("grey50"))
      .attr("stroke-width", 0.5);

    // Draw tick marks and labels (only min and max)
    if (guide.keys && guide.keys.length > 0) {
      const domain = guide.keys.map(k => parseFloat(k.value || 0));
      const minVal = Math.min(...domain);
      const maxVal = Math.max(...domain);
      const range = maxVal - minVal;

      // Only show first and last key (min/max)
      const endKeys = [guide.keys[0], guide.keys[guide.keys.length - 1]];

      endKeys.forEach(key => {
        const value = parseFloat(key.value || 0);
        const proportion = range !== 0 ? (value - minVal) / range : 0;
        const tickY = barY + barHeight - (proportion * barHeight);

        g.append("line")
          .attr("class", "colorbar-tick")
          .attr("x1", barX + barWidth)
          .attr("x2", barX + barWidth + 3)
          .attr("y1", tickY)
          .attr("y2", tickY)
          .attr("stroke", defaults.textColour)
          .attr("stroke-width", 0.5);

        g.append("text")
          .attr("class", "colorbar-label")
          .attr("x", barX + barWidth + 5)
          .attr("y", tickY)
          .attr("dy", "0.35em")
          .attr("fill", defaults.textColour)
          .style("font-size", `${defaults.textSize}px`)
          .style("font-family", "sans-serif")
          .text(String(key.label || ""));
      });
    }

    return g;
  }

  // =========================================================================
  // Legend Orchestrator
  // =========================================================================

  /**
   * Render all legends at their layout positions.
   * Called from main gg2d3.js rendering pipeline.
   *
   * @param {d3.Selection} svg - Main SVG selection
   * @param {Array} guides - Array of guide IR objects
   * @param {Object} layout - Layout object from calculateLayout()
   * @param {Object} theme - Theme accessor
   */
  function renderLegends(svg, guides, layout, theme) {
    if (!guides || guides.length === 0) return;
    if (!layout || !layout.legend) return;

    const legendBox = layout.legend;
    if (legendBox.position === "none") return;

    // Get theme properties
    const legTheme = window.gg2d3.layout.getLegendTheme(theme);
    const legMargin = legTheme.margin || {};
    const convertColor = window.gg2d3.scales.convertColor;

    // Render legend background if not blank
    const bgSpec = legTheme.background || {};
    if (bgSpec && bgSpec.type !== "blank") {
      svg.append("rect")
        .attr("class", "legend-background")
        .attr("x", legendBox.x)
        .attr("y", legendBox.y)
        .attr("width", legendBox.w)
        .attr("height", legendBox.h)
        .attr("fill", convertColor(bgSpec.fill) || "none")
        .attr("stroke", convertColor(bgSpec.colour) || "none")
        .attr("stroke-width", bgSpec.linewidth || 0);
    }

    // Get theme defaults for spacing between multiple guides
    const guideSpacing = legTheme.spacing || window.gg2d3.constants.ptToPx(11);

    const isVertical = legendBox.position === "right" || legendBox.position === "left";

    // Compute total legend content size for centering (ggplot2 justification = "center")
    const totalDims = estimateLegendDimensions(guides, theme, legendBox.position);

    // Center legend within allocated box (respecting margins)
    let currentX, currentY;
    if (isVertical) {
      // Vertically center for right/left positions
      currentX = legendBox.x + (legMargin.left || 0);
      currentY = legendBox.y + (legMargin.top || 0) + Math.max(0, (legendBox.h - totalDims.height - (legMargin.top || 0) - (legMargin.bottom || 0)) / 2);
    } else {
      // Horizontally center for top/bottom positions
      currentX = legendBox.x + (legMargin.left || 0) + Math.max(0, (legendBox.w - totalDims.width - (legMargin.left || 0) - (legMargin.right || 0)) / 2);
      currentY = legendBox.y + (legMargin.top || 0);
    }

    // Key direction: vertical for right/left, horizontal for top/bottom
    const keyDirection = isVertical ? "vertical" : "horizontal";

    guides.forEach((guide, idx) => {
      if (!guide || guide.position === "none") return;

      if (guide.type === "legend") {
        renderDiscreteLegend(svg, guide, currentX, currentY, theme, keyDirection);
      } else if (guide.type === "colorbar") {
        renderColorbar(svg, guide, currentX, currentY, theme);
      }

      // Advance position for next guide
      if (idx < guides.length - 1) {
        if (isVertical) {
          const dims = estimateLegendDimensions([guide], theme, legendBox.position);
          currentY += dims.height + guideSpacing;
        } else {
          const dims = estimateLegendDimensions([guide], theme, legendBox.position);
          currentX += dims.width + guideSpacing;
        }
      }
    });
  }

  // =========================================================================
  // Export to namespace
  // =========================================================================

  window.gg2d3.legend = {
    estimateLegendDimensions: estimateLegendDimensions,
    renderDiscreteLegend: renderDiscreteLegend,
    renderColorbar: renderColorbar,
    renderLegends: renderLegends
  };
})();
