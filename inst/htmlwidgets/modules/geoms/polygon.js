/**
 * gg2d3 Polygon Geom Renderer
 *
 * Renders ordinary geom_polygon as one closed SVG path per group.
 * Preserves ggplot2 built row order for polygon vertex order.
 *
 * @module gg2d3.geoms.polygon
 */

(function() {
  'use strict';

  function renderPolygon(layer, g, xScale, yScale, options) {
    const val = window.gg2d3.helpers.val;
    const num = window.gg2d3.helpers.num;
    const asRows = window.gg2d3.helpers.asRows;
    const getDashArray = window.gg2d3.helpers.getDashArray;
    const mmToPxLinewidth = window.gg2d3.constants.mmToPxLinewidth;
    const { fillColor, strokeColor, opacity } =
      window.gg2d3.geomRegistry.makeColorAccessors(layer, options);

    const aes = layer.aes || {};
    const params = layer.params || {};
    const dat = asRows(layer.data);
    const get = (d, k) => (k && d != null) ? d[k] : null;

    const flip = !!options.flip;
    const isXBand = typeof xScale.bandwidth === "function";
    const isYBand = typeof yScale.bandwidth === "function";
    const xOff = isXBand ? xScale.bandwidth() / 2 : 0;
    const yOff = isYBand ? yScale.bandwidth() / 2 : 0;

    function isMissingAesthetic(value) {
      const v = val(value);
      if (v === null || v === undefined) return true;
      if (typeof v === "number" && Number.isNaN(v)) return true;
      return v === "NA";
    }

    function isValidPoint(p) {
      const xOk = isXBand ? (p.x !== null && p.x !== undefined && p.x !== "") : Number.isFinite(p.x);
      const yOk = isYBand ? (p.y !== null && p.y !== undefined && p.y !== "") : Number.isFinite(p.y);
      if (!xOk || !yOk) return false;
      const sx = flip ? yScale(p.y) + yOff : xScale(p.x) + xOff;
      const sy = flip ? xScale(p.x) + xOff : yScale(p.y) + yOff;
      return Number.isFinite(sx) && Number.isFinite(sy);
    }

    function polygonFill(d) {
      // Missing fill values (NA/null/NaN) render as none.
      const rowFill = get(d, "fill");
      if (rowFill !== null && rowFill !== undefined) {
        return isMissingAesthetic(rowFill) ? "none" : fillColor(d);
      }
      if (isMissingAesthetic(params.fill)) return "none";
      return fillColor(d);
    }

    function polygonStroke(d) {
      // Missing stroke values (NA/null/NaN) render as none.
      const rowStroke = get(d, "colour");
      if (rowStroke !== null && rowStroke !== undefined) {
        return isMissingAesthetic(rowStroke) ? "none" : strokeColor(d);
      }
      if (isMissingAesthetic(params.colour)) return "none";
      return strokeColor(d);
    }

    function polygonLinewidth(d) {
      const linewidth = val(get(d, "linewidth"));
      const fallback = val(params.linewidth);
      const source = linewidth !== null && linewidth !== undefined ? linewidth : fallback;
      return source !== null && source !== undefined ? mmToPxLinewidth(source) : mmToPxLinewidth(0.5);
    }

    function polygonDashArray(d) {
      const linetype = val(get(d, "linetype"));
      const fallback = val(params.linetype);
      const source = linetype !== null && linetype !== undefined ? linetype : fallback;
      return getDashArray(source);
    }

    const closedLine = flip
      ? d3.line().curve(d3.curveLinearClosed).x(p => yScale(p.y) + yOff).y(p => xScale(p.x) + xOff)
      : d3.line().curve(d3.curveLinearClosed).x(p => xScale(p.x) + xOff).y(p => yScale(p.y) + yOff);

    const grouped = d3.group(dat, d => val(get(d, "group")) ?? 1);
    let polygonsDrawn = 0;

    grouped.forEach(arr => {
      const pts = arr
        .map(d => {
          const xVal = isXBand ? val(get(d, aes.x)) : num(get(d, aes.x));
          const yVal = isYBand ? val(get(d, aes.y)) : num(get(d, aes.y));
          return { x: xVal, y: yVal, d };
        })
        .filter(isValidPoint);

      if (pts.length < 3) return;

      const firstPoint = pts[0].d;
      const publicRow = Object.assign({}, firstPoint);
      publicRow._polygonPoints = pts;

      g.append("path")
        .datum(publicRow)
        .attr("class", "geom-polygon")
        .attr("d", closedLine(pts))
        .attr("fill", polygonFill(firstPoint))
        .attr("stroke", polygonStroke(firstPoint))
        .attr("stroke-width", polygonLinewidth(firstPoint))
        .attr("stroke-dasharray", polygonDashArray(firstPoint))
        .attr("opacity", opacity(firstPoint));

      polygonsDrawn += 1;
    });

    return polygonsDrawn;
  }

  window.gg2d3.geomRegistry.register('polygon', renderPolygon);

})();
