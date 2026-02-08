/**
 * gg2d3 Scale Factory Module
 *
 * Creates D3 scale objects from IR scale descriptors.
 * Handles all D3 scale types with edge case handling.
 *
 * @module gg2d3.scales
 */

(function() {
  // Initialize gg2d3 namespace if not exists
  if (typeof window.gg2d3 === 'undefined') {
    window.gg2d3 = {};
  }

  /**
   * Convert R color names to CSS hex values
   * Handles R's grey0-grey100 scale and other color formats
   *
   * @param {string} color - R color string
   * @returns {string} CSS color value
   *
   * @example
   * convertColor('grey50') // '#7F7F7F'
   * convertColor('black')  // 'black'
   */
  function convertColor(color) {
    if (!color || typeof color !== 'string') return color;

    // R uses grey0-grey100 scale - convert to hex
    // grey0 = #000000 (black), grey100 = #FFFFFF (white)
    // greyN = RGB(N*2.55, N*2.55, N*2.55)
    const greyMatch = color.match(/^grey(\d+)$/);
    if (greyMatch) {
      const value = parseInt(greyMatch[1]);
      const rgb = Math.round(value * 2.55);
      const hex = rgb.toString(16).padStart(2, '0');
      return `#${hex}${hex}${hex}`;
    }

    return color;
  }

  /**
   * Create a D3 scale from an IR scale descriptor
   *
   * Handles all D3 scale types with edge cases:
   * - Missing descriptor → linear scale with [0,1] domain
   * - Empty domain → use fallback [0,1] or [new Date(0), new Date(1)]
   * - Type detection via type field or transform field
   * - Fallback to type guessing based on domain values
   *
   * @param {Object} desc - Scale descriptor from IR
   * @param {string} desc.type - Scale type (continuous, categorical, log, etc.)
   * @param {string} [desc.transform] - Transform name (alternative to type)
   * @param {string} [desc.trans] - Transform name (alternative to transform)
   * @param {Array} desc.domain - Domain values
   * @param {Array} [desc.range] - Range values (for quantize/quantile/threshold)
   * @param {number} [desc.base] - Log base (for log scales)
   * @param {number} [desc.exponent] - Exponent (for power scales)
   * @param {number} [desc.constant] - Constant (for symlog scales)
   * @param {number} [desc.padding] - Padding (for band/point scales)
   * @param {number} [desc.paddingInner] - Inner padding (for band scales)
   * @param {number} [desc.paddingOuter] - Outer padding (for band scales)
   * @param {number} [desc.align] - Alignment (for band/point scales)
   * @param {Array} range - D3 pixel range [min, max]
   * @returns {Function} D3 scale function
   *
   * Supported scale types:
   * - Continuous: linear, continuous, identity
   * - Log: log, logarithmic, log10, log2
   * - Power: sqrt, square-root, pow, power
   * - Symlog: symlog, sym-log
   * - Time: time, date, datetime, utc, time-utc
   * - Categorical: band, categorical, ordinal, discrete, point
   * - Threshold: quantize, quantile, threshold
   */
  function createScale(desc, range) {
    const rng = Array.isArray(range) ? range : [0, 1];
    if (!desc) return d3.scaleLinear().domain([0, 1]).range(rng);

    const type = typeof desc.type === "string" ? desc.type.toLowerCase() : desc.type;
    const transform = typeof desc.transform === "string"
      ? desc.transform.toLowerCase()
      : (typeof desc.trans === "string" ? desc.trans.toLowerCase() : undefined);
    const domainArr = Array.isArray(desc.domain) ? desc.domain : [];
    const numericValues = domainArr
      .map(d => (typeof d === "number" ? d : +d))
      .filter(v => Number.isFinite(v));
    const hasNumericDomain = domainArr.length && numericValues.length === domainArr.length;
    const numericDomain = numericValues.length ? numericValues : [0, 1];
    const dateDomain = (() => {
      const parsed = domainArr
        .map(d => (d instanceof Date ? d : new Date(d)))
        .filter(d => d instanceof Date && !Number.isNaN(+d));
      return parsed.length ? parsed : [new Date(0), new Date(1)];
    })();

    const buildScale = kind => {
      switch (kind) {
        case "continuous":
        case "linear":
        case "identity":
          return d3.scaleLinear().domain(numericDomain).range(rng);

        case "log":
        case "logarithmic":
        case "log10":
        case "log2": {
          const positive = numericDomain.filter(v => v > 0);
          const domain = positive.length ? positive : [1, 10];
          const scale = d3.scaleLog().domain(domain).range(rng);
          const base = desc.base || (kind === "log2" ? 2 : kind === "log10" ? 10 : null);
          if (base) scale.base(base);
          return scale;
        }

        case "sqrt":
        case "square-root":
          return d3.scaleSqrt().domain(numericDomain).range(rng);

        case "pow":
        case "power": {
          const exponent = [desc.exponent, desc.power, desc.exp]
            .map(v => (v == null ? null : +v))
            .find(v => Number.isFinite(v));
          const scale = d3.scalePow().exponent(exponent != null ? exponent : 1).domain(numericDomain).range(rng);
          return scale;
        }

        case "symlog":
        case "sym-log": {
          const scale = d3.scaleSymlog().domain(numericDomain).range(rng);
          if (desc.constant != null && Number.isFinite(+desc.constant)) scale.constant(+desc.constant);
          return scale;
        }

        case "reverse":
          // Reverse flips the domain direction; still a linear scale
          return d3.scaleLinear().domain([...numericDomain].reverse()).range(rng);

        case "time":
        case "date":
        case "datetime":
          return d3.scaleTime().domain(dateDomain).range(rng);

        case "utc":
        case "time-utc":
          return d3.scaleUtc().domain(dateDomain).range(rng);

        case "band":
        case "categorical":
        case "ordinal":
        case "discrete": {
          const band = d3.scaleBand().domain(domainArr).range(rng);
          if (desc.paddingInner != null || desc.paddingOuter != null) {
            if (desc.paddingInner != null && Number.isFinite(+desc.paddingInner)) band.paddingInner(+desc.paddingInner);
            if (desc.paddingOuter != null && Number.isFinite(+desc.paddingOuter)) band.paddingOuter(+desc.paddingOuter);
          } else if (desc.padding != null && Number.isFinite(+desc.padding)) {
            band.padding(+desc.padding);
          } else {
            band.padding(0.1);
          }
          if (desc.align != null && Number.isFinite(+desc.align)) band.align(+desc.align);
          return band;
        }

        case "point": {
          const point = d3.scalePoint().domain(domainArr).range(rng);
          if (desc.padding != null && Number.isFinite(+desc.padding)) point.padding(+desc.padding);
          if (desc.align != null && Number.isFinite(+desc.align)) point.align(+desc.align);
          return point;
        }

        case "quantize":
          if (Array.isArray(desc.range)) {
            return d3.scaleQuantize().domain(numericDomain).range(desc.range);
          }
          return null;

        case "quantile":
          if (Array.isArray(desc.range)) {
            return d3.scaleQuantile().domain(numericDomain).range(desc.range);
          }
          return null;

        case "threshold":
          if (Array.isArray(desc.range)) {
            return d3.scaleThreshold().domain(numericDomain).range(desc.range);
          }
          return null;

        default:
          return null;
      }
    };

    // Transform takes priority over type for continuous scales
    if (transform && transform !== 'identity') {
      const fromTransform = buildScale(transform);
      if (fromTransform) return fromTransform;
    }

    const fromType = buildScale(type);
    if (fromType) return fromType;

    if (!domainArr.length) return d3.scaleLinear().domain(numericDomain).range(rng);

    if (hasNumericDomain) {
      return d3.scaleLinear().domain(numericDomain).range(rng);
    }

    // Use paddingOuter for edge spacing (matches ggplot2's 0.6 units)
    // Use paddingInner for spacing between bars
    return d3.scaleBand().domain(domainArr).range(rng)
      .paddingInner(0.2)
      .paddingOuter(0.6);
  }

  /**
   * Exported scale factory
   */
  window.gg2d3.scales = {
    createScale: createScale,
    convertColor: convertColor
  };
})();
