/**
 * gg2d3 Layout Engine Module
 *
 * Provides calculateLayout() pure function that computes pixel positions
 * for all chart components using subtraction-based allocation.
 *
 * @module gg2d3.layout
 */

(function() {
  'use strict';

  // Initialize namespace
  if (!window.gg2d3) window.gg2d3 = {};

  // =========================================================================
  // Box Manipulation Utilities (Pure Functions)
  // =========================================================================

  /**
   * Shrink a box by margin amounts on all sides
   * @param {Object} box - {x, y, w, h}
   * @param {Object} margin - {top, right, bottom, left}
   * @returns {Object} New box {x, y, w, h}
   */
  function shrinkBox(box, margin) {
    return {
      x: box.x + margin.left,
      y: box.y + margin.top,
      w: box.w - margin.left - margin.right,
      h: box.h - margin.top - margin.bottom
    };
  }

  /**
   * Slice off the top portion of a box
   * @param {Object} box - {x, y, w, h}
   * @param {number} amount - Height to slice off
   * @returns {Object} {sliced: {x,y,w,h}, remaining: {x,y,w,h}}
   */
  function sliceTop(box, amount) {
    return {
      sliced: { x: box.x, y: box.y, w: box.w, h: amount },
      remaining: { x: box.x, y: box.y + amount, w: box.w, h: box.h - amount }
    };
  }

  /**
   * Slice off the bottom portion of a box
   * @param {Object} box - {x, y, w, h}
   * @param {number} amount - Height to slice off
   * @returns {Object} {sliced: {x,y,w,h}, remaining: {x,y,w,h}}
   */
  function sliceBottom(box, amount) {
    return {
      sliced: { x: box.x, y: box.y + box.h - amount, w: box.w, h: amount },
      remaining: { x: box.x, y: box.y, w: box.w, h: box.h - amount }
    };
  }

  /**
   * Slice off the left portion of a box
   * @param {Object} box - {x, y, w, h}
   * @param {number} amount - Width to slice off
   * @returns {Object} {sliced: {x,y,w,h}, remaining: {x,y,w,h}}
   */
  function sliceLeft(box, amount) {
    return {
      sliced: { x: box.x, y: box.y, w: amount, h: box.h },
      remaining: { x: box.x + amount, y: box.y, w: box.w - amount, h: box.h }
    };
  }

  /**
   * Slice off the right portion of a box
   * @param {Object} box - {x, y, w, h}
   * @param {number} amount - Width to slice off
   * @returns {Object} {sliced: {x,y,w,h}, remaining: {x,y,w,h}}
   */
  function sliceRight(box, amount) {
    return {
      sliced: { x: box.x + box.w - amount, y: box.y, w: amount, h: box.h },
      remaining: { x: box.x, y: box.y, w: box.w - amount, h: box.h }
    };
  }

  /**
   * Slice a box from a given side
   * @param {Object} box - {x, y, w, h}
   * @param {string} position - "right"|"left"|"top"|"bottom"
   * @param {number} width - Width for left/right slices
   * @param {number} height - Height for top/bottom slices
   * @returns {Object} {sliced: {x,y,w,h}, remaining: {x,y,w,h}}
   */
  function sliceSide(box, position, width, height) {
    switch (position) {
      case "right": return sliceRight(box, width);
      case "left": return sliceLeft(box, width);
      case "top": return sliceTop(box, height);
      case "bottom": return sliceBottom(box, height);
      default: return { sliced: {x: 0, y: 0, w: 0, h: 0}, remaining: box };
    }
  }

  // =========================================================================
  // Text Dimension Estimation (Pure Functions - No DOM)
  // =========================================================================

  /**
   * Estimate text height from font size
   * @param {number} fontSizePx - Font size in pixels
   * @returns {number} Estimated height in pixels (includes line height)
   */
  function estimateTextHeight(fontSizePx) {
    // Text height is approximately 1.2x font size (accounting for line height)
    return fontSizePx * 1.2;
  }

  /**
   * Estimate text width from string and font size
   * @param {string} text - Text to measure
   * @param {number} fontSizePx - Font size in pixels
   * @returns {number} Estimated width in pixels
   */
  function estimateTextWidth(text, fontSizePx) {
    if (!text || typeof text !== 'string') return 0;
    // Average character width is ~0.6x font size for sans-serif
    return text.length * fontSizePx * 0.6;
  }

  /**
   * Estimate maximum text width from array of labels
   * @param {Array<string>} labels - Array of label strings
   * @param {number} fontSizePx - Font size in pixels
   * @returns {number} Maximum estimated width in pixels
   */
  function estimateMaxTextWidth(labels, fontSizePx) {
    if (!labels || !Array.isArray(labels) || labels.length === 0) return 0;
    let maxWidth = 0;
    for (let i = 0; i < labels.length; i++) {
      const w = estimateTextWidth(String(labels[i]), fontSizePx);
      if (w > maxWidth) maxWidth = w;
    }
    return maxWidth;
  }

  // =========================================================================
  // Theme Extraction Helpers
  // =========================================================================

  /**
   * Get plot margin from theme
   * @param {Object} theme - Theme accessor from createTheme()
   * @returns {Object} {top, right, bottom, left} in pixels
   */
  function getPlotMargin(theme) {
    const margin = theme.get("plot.margin");
    if (margin && margin.type === "margin") {
      return {
        top: margin.top || 7.3,
        right: margin.right || 7.3,
        bottom: margin.bottom || 7.3,
        left: margin.left || 7.3
      };
    }
    // Default: 5.5pt = 7.3px
    return { top: 7.3, right: 7.3, bottom: 7.3, left: 7.3 };
  }

  /**
   * Get title/subtitle/caption font sizes from theme
   * @param {Object} theme - Theme accessor
   * @returns {Object} {title, subtitle, caption} sizes in pixels
   */
  function getTitleSize(theme) {
    const ptToPx = window.gg2d3.constants.ptToPx;
    const titleTheme = theme.get("text.title");
    const subtitleTheme = theme.get("text.subtitle");
    const captionTheme = theme.get("text.caption");

    return {
      title: titleTheme && titleTheme.size ? ptToPx(titleTheme.size) : ptToPx(13.2),
      subtitle: subtitleTheme && subtitleTheme.size ? ptToPx(subtitleTheme.size) : ptToPx(11),
      caption: captionTheme && captionTheme.size ? ptToPx(captionTheme.size) : ptToPx(8.8)
    };
  }

  /**
   * Get axis text font sizes from theme
   * @param {Object} theme - Theme accessor
   * @returns {Object} {x, y} sizes in pixels
   */
  function getAxisTextSize(theme) {
    const ptToPx = window.gg2d3.constants.ptToPx;
    const textX = theme.get("axis.text.x") || theme.get("axis.text");
    const textY = theme.get("axis.text.y") || theme.get("axis.text");

    return {
      x: textX && textX.size ? ptToPx(textX.size) : ptToPx(8.8),
      y: textY && textY.size ? ptToPx(textY.size) : ptToPx(8.8)
    };
  }

  /**
   * Get axis title font sizes from theme
   * @param {Object} theme - Theme accessor
   * @returns {Object} {x, y} sizes in pixels
   */
  function getAxisTitleSize(theme) {
    const ptToPx = window.gg2d3.constants.ptToPx;
    const titleX = theme.get("axis.title.x") || theme.get("axis.title");
    const titleY = theme.get("axis.title.y") || theme.get("axis.title");

    return {
      x: titleX && titleX.size ? ptToPx(titleX.size) : ptToPx(11),
      y: titleY && titleY.size ? ptToPx(titleY.size) : ptToPx(11)
    };
  }

  /**
   * Get tick length from theme
   * @param {Object} theme - Theme accessor
   * @returns {number} Tick length in pixels
   */
  function getTickLength(theme) {
    const ptToPx = window.gg2d3.constants.ptToPx;
    // ggplot2 default: axis.ticks.length = 2.75pt = 3.67px
    return ptToPx(2.75);
  }

  /**
   * Get legend box spacing (gap between panel and legend)
   * @param {Object} theme - Theme accessor
   * @returns {number} Spacing in pixels
   */
  function getLegendBoxSpacing(theme) {
    const ptToPx = window.gg2d3.constants.ptToPx;
    // ggplot2 default: legend.box.spacing = 11pt = 14.7px
    return ptToPx(11);
  }

  /**
   * Get strip text font size from theme
   * @param {Object} theme - Theme accessor
   * @returns {number} Font size in pixels
   */
  function getStripTextSize(theme) {
    var ptToPx = window.gg2d3.constants.ptToPx;
    var stripText = theme.get("strip.text");
    return stripText && stripText.size ? ptToPx(stripText.size) : ptToPx(8.8);
  }

  /**
   * Get strip visual styling from theme
   * @param {Object} theme - Theme accessor
   * @returns {Object} Strip theme values for rendering
   */
  function getStripTheme(theme) {
    var ptToPx = window.gg2d3.constants.ptToPx;
    var convertColor = window.gg2d3.scales.convertColor;
    var stripText = theme.get("strip.text") || {};
    var stripBg = theme.get("strip.background") || {};

    return {
      fontSize: stripText.size ? ptToPx(stripText.size) : ptToPx(8.8),
      fontColour: convertColor(stripText.colour || "black"),
      fontFace: stripText.face || "normal",
      fontFamily: stripText.family || "sans-serif",
      bgFill: stripBg.fill ? convertColor(stripBg.fill) : convertColor("grey85"),
      bgColour: stripBg.colour ? convertColor(stripBg.colour) : null,
      bgLinewidth: stripBg.linewidth || 0
    };
  }

  // =========================================================================
  // Main Layout Calculation Function
  // =========================================================================

  /**
   * Calculate complete layout for all chart components.
   * Pure function - no DOM access, uses estimation heuristics.
   *
   * @param {Object} config - Layout configuration
   * @param {number} config.width - Total widget width in pixels
   * @param {number} config.height - Total widget height in pixels
   * @param {Object} config.theme - Theme accessor (from createTheme)
   * @param {Object} config.titles - {title, subtitle, caption} strings
   * @param {Object} config.axes - Axis metadata with labels and tick label strings
   * @param {Object} config.legend - Legend position and estimated dimensions
   * @param {Object} config.coord - Coordinate system (flip, ratio, xRange, yRange)
   * @returns {LayoutResult} Complete position data for all components
   */
  function calculateLayout(config) {
    const { width, height, theme, titles, axes, legend, coord, facets } = config;

    // --- Determine if faceted ---
    const isFaceted = facets && (facets.type === "wrap" || facets.type === "grid") &&
                      facets.layout && facets.layout.length > 1;
    const isFacetGrid = facets && facets.type === "grid";

    // --- Get theme values ---
    const plotMargin = getPlotMargin(theme);
    const axisTextSize = getAxisTextSize(theme);
    const axisTitleSize = getAxisTitleSize(theme);
    const tickLength = getTickLength(theme);
    const titleSize = getTitleSize(theme);
    const legendSpacing = getLegendBoxSpacing(theme);

    // Strip dimensions (for faceted plots)
    let stripHeight = 0;
    if (isFaceted) {
      const stripTextSize = getStripTextSize(theme);
      // Strip height = text height + top/bottom margin (4.4pt each = ~5.9px each)
      const stripMargin = window.gg2d3.constants.ptToPx(4.4);
      stripHeight = estimateTextHeight(stripTextSize) + stripMargin * 2;
    }

    // --- Compute component sizes ---
    const titleHeight = titles.title ?
      estimateTextHeight(titleSize.title) + 4 : 0;
    const subtitleHeight = titles.subtitle ?
      estimateTextHeight(titleSize.subtitle) + 2 : 0;
    const captionHeight = titles.caption ?
      estimateTextHeight(titleSize.caption) + 4 : 0;

    // Axis tick labels: estimate from label strings
    const yTickMaxWidth = axes.y.tickLabels && axes.y.tickLabels.length > 0 ?
      estimateMaxTextWidth(axes.y.tickLabels, axisTextSize.y) : 0;
    const xTickHeight = axes.x.tickLabels && axes.x.tickLabels.length > 0 ?
      estimateTextHeight(axisTextSize.x) : 0;

    // Axis titles (y-axis title is rotated, so use height as width)
    const xTitleHeight = axes.x.label ?
      estimateTextHeight(axisTitleSize.x) + 4 : 0;
    const yTitleWidth = axes.y.label ?
      estimateTextHeight(axisTitleSize.y) + 4 : 0;

    // Secondary axes (same size as primary)
    const yTickMaxWidthSecondary = (axes.y2 && axes.y2.enabled) ? yTickMaxWidth : 0;
    const xTickHeightSecondary = (axes.x2 && axes.x2.enabled) ? xTickHeight : 0;
    const xTitleHeightSecondary = (axes.x2 && axes.x2.enabled && axes.x2.label) ? xTitleHeight : 0;
    const yTitleWidthSecondary = (axes.y2 && axes.y2.enabled && axes.y2.label) ? yTitleWidth : 0;

    // --- Allocate space (outside-in subtraction) ---
    let box = { x: 0, y: 0, w: width, h: height };

    // 1. Plot margins
    box = shrinkBox(box, plotMargin);

    // 2. Title area (top)
    const titleAreaHeight = titleHeight + subtitleHeight;
    const titleResult = sliceTop(box, titleAreaHeight);
    const titleArea = titleResult.sliced;
    box = titleResult.remaining;

    // 3. Caption area (bottom)
    const captionResult = sliceBottom(box, captionHeight);
    const captionArea = captionResult.sliced;
    box = captionResult.remaining;

    // 4. Legend area (based on position)
    let legendBox = { x: 0, y: 0, w: 0, h: 0 };
    if (legend && legend.position !== "none" && legend.position !== "inside") {
      const legendWidth = legend.width || 0;
      const legendHeight = legend.height || 0;

      // Only reserve space if legend has non-zero dimensions
      if (legendWidth > 0 || legendHeight > 0) {
        let legendAmount;
        if (legend.position === "right" || legend.position === "left") {
          legendAmount = legendWidth + legendSpacing;
        } else {
          legendAmount = legendHeight + legendSpacing;
        }

        const legendResult = sliceSide(box, legend.position, legendAmount, legendAmount);
        legendBox = legendResult.sliced;
        box = legendResult.remaining;
      }
    }

    // 5. Axis space
    const bottomSpace = xTickHeight + tickLength + xTitleHeight + 8;
    const leftSpace = yTickMaxWidth + tickLength + yTitleWidth + 8;
    const topSpace = (axes.x2 && axes.x2.enabled) ?
      xTickHeightSecondary + tickLength + xTitleHeightSecondary + 8 : 0;
    const rightSpace = (axes.y2 && axes.y2.enabled) ?
      yTickMaxWidthSecondary + tickLength + yTitleWidthSecondary + 8 : 0;

    // 6. Panel = remaining space after axis allocation
    let panel = {
      x: box.x + leftSpace,
      y: box.y + topSpace,
      w: Math.max(50, box.w - leftSpace - rightSpace),
      h: Math.max(50, box.h - bottomSpace - topSpace)
    };

    // Panel offset for coord_fixed centering (default 0)
    let panelOffsetX = 0;
    let panelOffsetY = 0;

    // 7. Apply coord_fixed aspect ratio constraint (not supported with facets)
    if (!isFaceted && coord && coord.ratio && coord.xRange && coord.yRange) {
      const availW = panel.w;
      const availH = panel.h;
      const dataRatio = coord.yRange / coord.xRange;
      const targetAspect = coord.ratio * dataRatio;

      // Calculate constrained dimensions
      let constrainedW, constrainedH;
      if (availW / availH > 1 / targetAspect) {
        // Width-limited: constrain width
        constrainedH = availH;
        constrainedW = availH / targetAspect;
      } else {
        // Height-limited: constrain height
        constrainedW = availW;
        constrainedH = availW * targetAspect;
      }

      // Center the constrained panel in available space
      panelOffsetX = (availW - constrainedW) / 2;
      panelOffsetY = (availH - constrainedH) / 2;

      panel = {
        x: panel.x + panelOffsetX,
        y: panel.y + panelOffsetY,
        w: constrainedW,
        h: constrainedH
      };
    }

    // 8. Multi-panel grid calculation for faceted plots
    let panelsArr = null;
    let stripsArr = null;
    let colStripsArr = null;
    let rowStripsArr = null;

    if (isFaceted && !isFacetGrid) {
      // facet_wrap layout calculation
      const nrow = facets.nrow;
      const ncol = facets.ncol;
      const spacing = facets.spacing || 7.3;

      // Available space is the computed single-panel area
      const availX = panel.x;
      const availY = panel.y;
      const availW = panel.w;
      const availH = panel.h;

      // Total spacing between panels
      const totalSpacingX = (ncol - 1) * spacing;
      const totalSpacingY = (nrow - 1) * spacing;

      // Total strip height (one strip row per panel row)
      const totalStripHeight = nrow * stripHeight;

      // Panel dimensions after accounting for spacing and strips
      const panelW = (availW - totalSpacingX) / ncol;
      const panelH = (availH - totalSpacingY - totalStripHeight) / nrow;

      // Build panels array from layout data
      panelsArr = facets.layout.map(function(item) {
        const col = item.COL - 1;  // 0-indexed
        const row = item.ROW - 1;

        // Each row occupies: stripHeight + panelH + spacing
        const rowBlockH = stripHeight + panelH;

        return {
          PANEL: item.PANEL,
          x: availX + col * (panelW + spacing),
          y: availY + row * (rowBlockH + spacing) + stripHeight,
          w: panelW,
          h: panelH,
          clipId: "panel-" + item.PANEL + "-clip-" + Math.random().toString(36).substr(2, 6)
        };
      });

      // Build strips array
      stripsArr = facets.strips.map(function(strip) {
        // Find corresponding panel layout entry
        var panelLayout = panelsArr.find(function(p) { return p.PANEL === strip.PANEL; });
        if (!panelLayout) return null;

        return {
          PANEL: strip.PANEL,
          x: panelLayout.x,
          y: panelLayout.y - stripHeight,  // strip is above its panel
          w: panelLayout.w,
          h: stripHeight,
          label: strip.label
        };
      }).filter(Boolean);

      // Update panel bounding box to span the full grid (for axis label centering)
      if (panelsArr.length > 0) {
        const minX = Math.min.apply(Math, panelsArr.map(function(p) { return p.x; }));
        const maxRight = Math.max.apply(Math, panelsArr.map(function(p) { return p.x + p.w; }));
        const minY = Math.min.apply(Math, panelsArr.map(function(p) { return p.y; }));
        const maxBottom = Math.max.apply(Math, panelsArr.map(function(p) { return p.y + p.h; }));
        panel = {
          x: minX,
          y: minY,
          w: maxRight - minX,
          h: maxBottom - minY
        };
      }
    } else if (isFacetGrid) {
      // facet_grid layout calculation (2D grid with row and column strips)
      const nrow = facets.nrow;
      const ncol = facets.ncol;
      const spacing = facets.spacing || 7.3;

      // Available space is the computed single-panel area
      const availX = panel.x;
      const availY = panel.y;
      const availW = panel.w;
      const availH = panel.h;

      // Strip dimensions for facet_grid:
      // - stripHeight: column strip height (already computed above, text height + 2*margin)
      // - stripWidth: row strip width (rotated text, so width = text height)
      const stripWidth = stripHeight;  // rotated text width equals text height

      // Reserve space for row strips (right side) and column strips (top)
      const panelAreaW = availW - stripWidth;    // reserve right for row strips
      const panelAreaH = availH - stripHeight;   // reserve top for column strips

      // Total spacing between panels
      const totalSpacingX = (ncol - 1) * spacing;
      const totalSpacingY = (nrow - 1) * spacing;

      // Panel dimensions after accounting for spacing
      const panelW = (panelAreaW - totalSpacingX) / ncol;
      const panelH = (panelAreaH - totalSpacingY) / nrow;

      // Build panels array from layout data
      panelsArr = facets.layout.map(function(item) {
        const col = item.COL - 1;  // 0-indexed
        const row = item.ROW - 1;

        return {
          PANEL: item.PANEL,
          x: availX + col * (panelW + spacing),
          y: availY + stripHeight + row * (panelH + spacing),
          w: panelW,
          h: panelH,
          clipId: "panel-" + item.PANEL + "-clip-" + Math.random().toString(36).substr(2, 6)
        };
      });

      // Build column strips array (positioned at top of each column)
      if (facets.col_strips) {
        colStripsArr = facets.col_strips.map(function(strip) {
          const col = strip.COL - 1;
          return {
            COL: strip.COL,
            x: availX + col * (panelW + spacing),
            y: availY,
            w: panelW,
            h: stripHeight,
            label: strip.label,
            orientation: "top"
          };
        });
      }

      // Build row strips array (positioned to the right of each row)
      if (facets.row_strips) {
        rowStripsArr = facets.row_strips.map(function(strip) {
          const rowIdx = strip.ROW - 1;
          return {
            ROW: strip.ROW,
            x: availX + panelAreaW,
            y: availY + stripHeight + rowIdx * (panelH + spacing),
            w: stripWidth,
            h: panelH,
            label: strip.label,
            orientation: "right"
          };
        });
      }

      // Update panel bounding box to span the full grid (for axis label centering)
      if (panelsArr.length > 0) {
        const minX = Math.min.apply(Math, panelsArr.map(function(p) { return p.x; }));
        const maxRight = Math.max.apply(Math, panelsArr.map(function(p) { return p.x + p.w; }));
        const minY = Math.min.apply(Math, panelsArr.map(function(p) { return p.y; }));
        const maxBottom = Math.max.apply(Math, panelsArr.map(function(p) { return p.y + p.h; }));
        panel = {
          x: minX,
          y: minY,
          w: maxRight - minX,
          h: maxBottom - minY
        };
      }
    }

    // Generate unique clip ID (for single-panel case)
    const clipId = "panel-clip-" + Math.random().toString(36).substr(2, 9);

    // --- Compute derived positions ---
    return {
      total: { w: width, h: height },
      plotMargin: plotMargin,
      title: {
        x: panel.x + panel.w / 2,
        y: titleArea.y + titleHeight * 0.8,
        visible: !!titles.title
      },
      subtitle: {
        x: panel.x + panel.w / 2,
        y: titleArea.y + titleHeight + subtitleHeight * 0.8,
        visible: !!titles.subtitle
      },
      caption: {
        x: panel.x + panel.w / 2,
        y: captionArea.y + captionHeight * 0.8,
        visible: !!titles.caption
      },
      panel: {
        x: panel.x,
        y: panel.y,
        w: panel.w,
        h: panel.h,
        offsetX: panelOffsetX,
        offsetY: panelOffsetY
      },
      clipId: clipId,
      axes: {
        bottom: { x: panel.x, y: panel.y + panel.h, w: panel.w },
        left: { x: panel.x, y: panel.y, h: panel.h },
        top: topSpace > 0 ? { x: panel.x, y: panel.y, w: panel.w } : null,
        right: rightSpace > 0 ? { x: panel.x + panel.w, y: panel.y, h: panel.h } : null
      },
      axisLabels: {
        x: {
          x: panel.x + panel.w / 2,
          y: panel.y + panel.h + xTickHeight + tickLength + xTitleHeight * 0.8,
          visible: !!axes.x.label
        },
        y: {
          x: panel.x - yTickMaxWidth - tickLength - yTitleWidth / 2,
          y: panel.y + panel.h / 2,
          rotation: -90,
          visible: !!axes.y.label
        }
      },
      legend: {
        x: legendBox.x,
        y: legendBox.y,
        w: legendBox.w,
        h: legendBox.h,
        position: legend ? legend.position : "none"
      },
      // Multi-panel faceting (Phase 8 & 9):
      panels: panelsArr,       // [{PANEL, x, y, w, h, clipId}, ...] or null
      strips: stripsArr,       // [{PANEL, x, y, w, h, label}, ...] or null (facet_wrap only)
      colStrips: colStripsArr, // [{COL, x, y, w, h, label, orientation}, ...] or null (facet_grid only)
      rowStrips: rowStripsArr, // [{ROW, x, y, w, h, label, orientation}, ...] or null (facet_grid only)
      stripHeight: stripHeight,  // Height of strip in pixels (0 for non-faceted)
      secondaryAxes: {
        top: topSpace > 0,
        right: rightSpace > 0
      }
    };
  }

  // =========================================================================
  // Export to namespace
  // =========================================================================

  window.gg2d3.layout = {
    calculateLayout: calculateLayout,
    getStripTheme: getStripTheme,
    // Export utilities for testing
    estimateTextWidth: estimateTextWidth,
    estimateTextHeight: estimateTextHeight,
    estimateMaxTextWidth: estimateMaxTextWidth,
    shrinkBox: shrinkBox,
    sliceTop: sliceTop,
    sliceBottom: sliceBottom,
    sliceLeft: sliceLeft,
    sliceRight: sliceRight,
    sliceSide: sliceSide
  };
})();
