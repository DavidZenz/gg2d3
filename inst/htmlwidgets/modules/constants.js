/**
 * gg2d3 Constants Module
 *
 * Provides centralized unit conversion constants and ggplot2 defaults.
 * All conversion factors are derived from W3C CSS standards:
 * - 1 inch = 96 CSS pixels (W3C standard)
 * - 1 inch = 25.4 mm
 * - 1 inch = 72 points (PostScript standard)
 *
 * @module gg2d3.constants
 */

(function() {
  // Initialize gg2d3 namespace if not exists
  if (typeof window.gg2d3 === 'undefined') {
    window.gg2d3 = {};
  }

  /**
   * W3C-standard unit conversion constants
   * Reference: https://www.w3.org/TR/css-values-3/#absolute-lengths
   */
  const DPI = 96;                    // CSS pixels per inch (W3C standard)
  const MM_PER_INCH = 25.4;          // Millimeters per inch
  const PT_PER_INCH = 72;            // Points per inch (PostScript)

  // Derived conversion factors
  const PX_PER_MM = DPI / MM_PER_INCH;    // 96 / 25.4 ≈ 3.7795275591
  const PX_PER_PT = DPI / PT_PER_INCH;    // 96 / 72 = 1.333...

  /**
   * Convert ggplot2 size (mm diameter) to SVG radius (pixels)
   * ggplot2's 'size' aesthetic represents diameter in millimeters
   * SVG circle 'r' attribute is radius in pixels
   *
   * @param {number} size_mm - Size in millimeters (diameter)
   * @returns {number} Radius in pixels
   *
   * @example
   * // ggplot2 default point size is 1.5mm diameter
   * mmToPxRadius(1.5) // ≈ 2.83 pixels radius
   */
  function mmToPxRadius(size_mm) {
    return (size_mm * PX_PER_MM) / 2;
  }

  /**
   * Convert ggplot2 linewidth (mm) to SVG stroke-width (pixels)
   * ggplot2's 'linewidth' represents width in millimeters
   * SVG stroke-width is in pixels
   *
   * @param {number} linewidth_mm - Line width in millimeters
   * @returns {number} Stroke width in pixels
   *
   * @example
   * // ggplot2 default linewidth is 0.5mm
   * mmToPxLinewidth(0.5) // ≈ 1.89 pixels
   */
  function mmToPxLinewidth(linewidth_mm) {
    return linewidth_mm * PX_PER_MM;
  }

  /**
   * Convert points to pixels
   * Used for text sizes and other typographic units
   *
   * @param {number} pt - Size in points
   * @returns {number} Size in pixels
   *
   * @example
   * // ggplot2 default axis text is 8.8pt
   * ptToPx(8.8) // ≈ 11.73 pixels
   */
  function ptToPx(pt) {
    return pt * PX_PER_PT;
  }

  /**
   * ggplot2 Default Values
   * Matching theme_gray() defaults from ggplot2
   *
   * Sources:
   * - Point size: geom_point default is 1.5mm diameter
   * - Linewidth: 0.5mm for lines, 0.25mm for grid minor
   * - Grid major: 0.5mm linewidth
   * - Text sizes: extracted from theme_gray()
   */
  const GGPLOT_DEFAULTS = {
    // Geom defaults
    point: {
      size: 1.5,              // mm (diameter)
      stroke: 0.5,            // pixels
      fill: 'black',
      colour: 'black'
    },
    line: {
      linewidth: 0.5,         // mm
      colour: 'black'
    },
    bar: {
      colour: 'NA',           // no outline by default
      fill: 'grey35'
    },

    // Theme defaults (theme_gray)
    theme: {
      panel: {
        background: '#EBEBEB',
        border: 'blank'
      },
      plot: {
        background: 'white',
        margin: {           // mm (converted from pt: 5.5pt ≈ 7.3mm)
          top: 7.3,
          right: 7.3,
          bottom: 7.3,
          left: 7.3
        }
      },
      grid: {
        major: {
          linewidth: 0.5,   // mm
          colour: 'white'
        },
        minor: {
          linewidth: 0.25,  // mm
          colour: 'white'
        }
      },
      axis: {
        line: 'blank',
        text: {
          size: 8.8,        // pt
          colour: '#4D4D4D'
        },
        title: {
          size: 11,         // pt
          colour: 'black'
        },
        ticks: {
          linewidth: 0.5,   // mm
          colour: '#333333'
        }
      },
      text: {
        title: {
          size: 13.2,       // pt
          colour: 'black'
        }
      }
    }
  };

  /**
   * Exported constants and functions
   */
  window.gg2d3.constants = {
    // Base constants
    DPI: DPI,
    MM_PER_INCH: MM_PER_INCH,
    PT_PER_INCH: PT_PER_INCH,
    PX_PER_MM: PX_PER_MM,
    PX_PER_PT: PX_PER_PT,

    // Conversion functions
    mmToPxRadius: mmToPxRadius,
    mmToPxLinewidth: mmToPxLinewidth,
    ptToPx: ptToPx,

    // ggplot2 defaults
    GGPLOT_DEFAULTS: GGPLOT_DEFAULTS
  };
})();
