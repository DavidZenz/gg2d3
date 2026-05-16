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
   * Estimate text height from font size and margin
   * @param {number} fontSizePx - Font size in pixels
   * @param {Object} [margin] - Optional margin object {top, bottom}
   * @returns {number} Estimated total height in pixels
   */
  function estimateTextHeight(fontSizePx, margin) {
    const h = fontSizePx * 1.2;
    const m = margin || { top: 0, bottom: 0 };
    return h + (m.top || 0) + (m.bottom || 0);
  }

  /**
   * Estimate total text width including margins
   */
  function estimateTextWidth(text, fontSizePx, margin) {
    if (!text || typeof text !== 'string') return 0;
    const w = text.length * fontSizePx * 0.6;
    const m = margin || { left: 0, right: 0 };
    return w + (m.left || 0) + (m.right || 0);
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
   * Get title specs including margins
   */
  function getTitleSpecs(theme) {
    const ptToPx = window.gg2d3.constants.ptToPx;
    const title = theme.get("plot.title") || {};
    const subtitle = theme.get("plot.subtitle") || {};
    const caption = theme.get("plot.caption") || {};

    return {
      title: { size: title.size ? ptToPx(title.size) : ptToPx(13.2), margin: title.margin },
      subtitle: { size: subtitle.size ? ptToPx(subtitle.size) : ptToPx(11), margin: subtitle.margin },
      caption: { size: caption.size ? ptToPx(caption.size) : ptToPx(8.8), margin: caption.margin }
    };
  }

  /**
   * Get axis title font sizes from theme
   * @param {Object} theme - Theme accessor
   * @returns {Object} {x, y} sizes and margins
   */
  function getAxisTitleSpecs(theme) {
    const ptToPx = window.gg2d3.constants.ptToPx;
    const titleX = theme.get("axis.title.x") || theme.get("axis.title") || {};
    const titleY = theme.get("axis.title.y") || theme.get("axis.title") || {};

    return {
      x: { size: titleX.size ? ptToPx(titleX.size) : ptToPx(11), margin: titleX.margin },
      y: { size: titleY.size ? ptToPx(titleY.size) : ptToPx(11), margin: titleY.margin }
    };
  }

  /**
   * Get legend margin and spacing from theme
   */
  function getLegendTheme(theme) {
    const ptToPx = window.gg2d3.constants.ptToPx;
    const margin = theme.get("legend.margin") || { top: 0, right: 0, bottom: 0, left: 0 };
    const spacing = theme.get("legend.spacing") || ptToPx(11);
    const bg = theme.get("legend.background") || {};

    return { margin, spacing, background: bg };
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
    const { width, height, theme, titles, axes, legend, coord, facets, panels: panelsIR } = config;

    // --- Determine if faceted ---
    const isFaceted = facets && (facets.type === "wrap" || facets.type === "grid") &&
                      facets.layout && facets.layout.length > 1;
    const isFacetGrid = facets && facets.type === "grid";

    // --- Get theme values ---
    const plotMargin = getPlotMargin(theme);
    const axisTextSize = getAxisTextSize(theme);
    const axisTitleSpecs = getAxisTitleSpecs(theme);
    const tickLength = getTickLength(theme);
    const titleSpecs = getTitleSpecs(theme);
    const legendTheme = getLegendTheme(theme);

    // Strip dimensions (for faceted plots)
    let stripHeight = 0;
    let numColVars = 1;
    let numRowVars = 1;

    if (isFaceted) {
      const stripTextSize = getStripTextSize(theme);
      // Strip height = text height + top/bottom margin (4.4pt each = ~5.9px each)
      const stripMargin = window.gg2d3.constants.ptToPx(4.4);
      stripHeight = estimateTextHeight(stripTextSize) + stripMargin * 2;

      if (!isFacetGrid && facets.strips) {
        numColVars = facets.strips.length || 1;
      } else if (isFacetGrid) {
        numColVars = (facets.col_strips && facets.col_strips.length) || 0;
        numRowVars = (facets.row_strips && facets.row_strips.length) || 0;
      }
    }

    // --- Compute component sizes ---
    const titleHeight = titles.title ?
      estimateTextHeight(titleSpecs.title.size, titleSpecs.title.margin) : 0;
    const subtitleHeight = titles.subtitle ?
      estimateTextHeight(titleSpecs.subtitle.size, titleSpecs.subtitle.margin) : 0;
    const captionHeight = titles.caption ?
      estimateTextHeight(titleSpecs.caption.size, titleSpecs.caption.margin) : 0;

    // Axis tick labels: estimate from label strings
    const yTickMaxWidth = axes.y.tickLabels && axes.y.tickLabels.length > 0 ?
      estimateMaxTextWidth(axes.y.tickLabels, axisTextSize.y) : 0;
    const xTickHeight = axes.x.tickLabels && axes.x.tickLabels.length > 0 ?
      estimateTextHeight(axisTextSize.x) : 0;

    // Axis titles (y-axis title is rotated, so use height as width)
    const xTitleHeight = axes.x.label ?
      estimateTextHeight(axisTitleSpecs.x.size, axisTitleSpecs.x.margin) : 0;
    const yTitleWidth = axes.y.label ?
      estimateTextHeight(axisTitleSpecs.y.size, axisTitleSpecs.y.margin) : 0;

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
      const legMargin = legendTheme.margin || {};
      const legendW = (legend.width || 0) + (legMargin.left || 0) + (legMargin.right || 0);
      const legendH = (legend.height || 0) + (legMargin.top || 0) + (legMargin.bottom || 0);
      const legendSpacing = legendTheme.spacing || 0;

      // Only reserve space if legend has non-zero dimensions
      if (legendW > 0 || legendH > 0) {
        let legendAmount;
        if (legend.position === "right" || legend.position === "left") {
          legendAmount = legendW + legendSpacing;
        } else {
          legendAmount = legendH + legendSpacing;
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

    // Per-axis gap extras for free scales: when scales="free"/"free_y",
    // each non-leftmost panel renders its own primary y-axis whose labels
    // extend LEFTWARD from the panel's left edge into the inter-column gap.
    // Same for free_x and per-panel x-axes extending UPWARD into the row gap.
    // Without this reservation the labels overlap the previous panel's data.
    function computeFreeAxisExtras() {
      const scalesMode = (facets && facets.scales) || "fixed";
      const isFreeY = scalesMode === "free" || scalesMode === "free_y";
      const isFreeX = scalesMode === "free" || scalesMode === "free_x";
      let colExtra = 0;
      let rowExtra = 0;
      if (isFreeY) {
        let maxYWidth = estimateMaxTextWidth(axes.y.tickLabels || [], axisTextSize.y);
        if (panelsIR && Array.isArray(panelsIR)) {
          for (let i = 0; i < panelsIR.length; i++) {
            const p = panelsIR[i];
            let labs = p && p.y_tickLabels;
            if ((!labs || !labs.length) && p && p.y_breaks && p.y_breaks.length) {
              labs = p.y_breaks.map(function(v) { return String(v); });
            }
            if (labs && labs.length) {
              const w = estimateMaxTextWidth(labs, axisTextSize.y);
              if (w > maxYWidth) maxYWidth = w;
            }
          }
        }
        colExtra = tickLength + maxYWidth + 4;
      }
      if (isFreeX) {
        rowExtra = tickLength + estimateTextHeight(axisTextSize.x) + 4;
      }
      return { colExtra: colExtra, rowExtra: rowExtra };
    }
    const freeExtras = computeFreeAxisExtras();

    if (isFaceted && !isFacetGrid) {
      // facet_wrap layout calculation
      const nrow = facets.nrow;
      const ncol = facets.ncol;
      const baseSpacing = facets.spacing || 7.3;
      const colSpacing = baseSpacing + freeExtras.colExtra;
      const rowSpacing = baseSpacing + freeExtras.rowExtra;

      // Available space is the computed single-panel area
      const availX = panel.x;
      const availY = panel.y;
      const availW = panel.w;
      const availH = panel.h;

      // Total spacing between panels
      const totalSpacingX = (ncol - 1) * colSpacing;
      const totalSpacingY = (nrow - 1) * rowSpacing;

      // Total strip height (hierarchical rows of headers)
      const totalStripHeightPerRow = numColVars * stripHeight;
      const totalStripHeightAcrossAllRows = nrow * totalStripHeightPerRow;

      // Panel dimensions after accounting for spacing and strips
      const panelW = (availW - totalSpacingX) / ncol;
      const panelH = (availH - totalSpacingY - totalStripHeightAcrossAllRows) / nrow;

      // Build panels array from layout data
      panelsArr = facets.layout.map(function(item) {
        const col = item.COL - 1;  // 0-indexed
        const row = item.ROW - 1;

        // Each row occupies: totalStripHeightPerRow + panelH + rowSpacing
        const rowBlockH = totalStripHeightPerRow + panelH;

        return {
          PANEL: item.PANEL,
          x: availX + col * (panelW + colSpacing),
          y: availY + row * (rowBlockH + rowSpacing) + totalStripHeightPerRow,
          w: panelW,
          h: panelH,
          clipId: "panel-" + item.PANEL + "-clip-" + Math.random().toString(36).substr(2, 6)
        };
      });

      // Build strips array (flattened hierarchical levels)
      stripsArr = [];
      facets.strips.forEach(function(levelObj) {
        const level = levelObj.level; // 1-indexed
        levelObj.labels.forEach(function(strip) {
          var panelLayout = panelsArr.find(function(p) { return p.PANEL === strip.PANEL; });
          if (!panelLayout) return;

          stripsArr.push({
            PANEL: strip.PANEL,
            level: level,
            x: panelLayout.x,
            // Position based on level: level 1 is highest (furthest from panel)
            y: panelLayout.y - (numColVars - level + 1) * stripHeight,
            w: panelLayout.w,
            h: stripHeight,
            label: strip.label
          });
        });
      });

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
      const baseSpacing = facets.spacing || 7.3;
      const colSpacing = baseSpacing + freeExtras.colExtra;
      const rowSpacing = baseSpacing + freeExtras.rowExtra;

      // Available space is the computed single-panel area
      const availX = panel.x;
      const availY = panel.y;
      const availW = panel.w;
      const availH = panel.h;

      // Hierarchical strip totals
      const totalColStripHeight = numColVars * stripHeight;
      const totalRowStripWidth = numRowVars * stripHeight; // Width of side strip = text height * levels

      // Reserve space for row strips (right side) and column strips (top)
      const panelAreaW = availW - totalRowStripWidth;
      const panelAreaH = availH - totalColStripHeight;

      // Total spacing between panels
      const totalSpacingX = (ncol - 1) * colSpacing;
      const totalSpacingY = (nrow - 1) * rowSpacing;

      // Panel dimensions after accounting for spacing
      const panelW = (panelAreaW - totalSpacingX) / ncol;
      const panelH = (panelAreaH - totalSpacingY) / nrow;

      // Build panels array from layout data
      panelsArr = facets.layout.map(function(item) {
        const col = item.COL - 1;  // 0-indexed
        const row = item.ROW - 1;

        return {
          PANEL: item.PANEL,
          x: availX + col * (panelW + colSpacing),
          y: availY + totalColStripHeight + row * (panelH + rowSpacing),
          w: panelW,
          h: panelH,
          clipId: "panel-" + item.PANEL + "-clip-" + Math.random().toString(36).substr(2, 6)
        };
      });

      // Build column strips array (positioned at top of each column)
      colStripsArr = [];
      if (facets.col_strips) {
        facets.col_strips.forEach(function(levelObj) {
          const level = levelObj.level;
          levelObj.labels.forEach(function(strip) {
            const col = strip.COL - 1;
            colStripsArr.push({
              COL: strip.COL,
              level: level,
              x: availX + col * (panelW + colSpacing),
              y: availY + (level - 1) * stripHeight,
              w: panelW,
              h: stripHeight,
              label: strip.label,
              orientation: "top"
            });
          });
        });
      }

      // Build row strips array (positioned to the right of each row)
      rowStripsArr = [];
      if (facets.row_strips) {
        facets.row_strips.forEach(function(levelObj) {
          const level = levelObj.level;
          levelObj.labels.forEach(function(strip) {
            const rowIdx = strip.ROW - 1;
            rowStripsArr.push({
              ROW: strip.ROW,
              level: level,
              x: availX + panelAreaW + (level - 1) * stripHeight,
              y: availY + totalColStripHeight + rowIdx * (panelH + rowSpacing),
              w: stripHeight,
              h: panelH,
              label: strip.label,
              orientation: "right"
            });
          });
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
      scalesMode: facets ? (facets.scales || "fixed") : "fixed",  // "fixed", "free", "free_x", or "free_y"
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
