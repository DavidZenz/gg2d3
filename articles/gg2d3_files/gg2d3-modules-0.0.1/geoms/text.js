/**
 * gg2d3 Text Geom Renderer
 *
 * Renders geom_text and geom_label as SVG text elements.
 * Handles:
 * - label aesthetic for text content
 * - x/y positioning with continuous and categorical scales
 * - Color and opacity aesthetics
 * - Fixed font size (10px default)
 * - Basic hjust/vjust, angle, and family placement
 *
 * @module gg2d3.geoms.text
 */

(function() {
  'use strict';

  function renderText(layer, g, xScale, yScale, options) {
    const val = window.gg2d3.helpers.val;
    const num = window.gg2d3.helpers.num;
    const asRows = window.gg2d3.helpers.asRows;
    const { strokeColor, fillColor, opacity } =
      window.gg2d3.geomRegistry.makeColorAccessors(layer, options);

    const aes = layer.aes || {};
    const dat = asRows(layer.data);
    const get = (d, k) => (k && d != null) ? d[k] : null;
    const isXBand = typeof xScale.bandwidth === "function";
    const isYBand = typeof yScale.bandwidth === "function";
    const flip = !!options.flip;
    const params = layer.params || {};
    const constants = window.gg2d3.constants || {};
    const pxPerMm = constants.PX_PER_MM || 3.7795275591;
    const mmToPxLinewidth = constants.mmToPxLinewidth || function(linewidth) {
      return linewidth || 0.5;
    };

    function textSize(d) {
      let sizeVal = val(get(d, "size"));
      if (sizeVal == null && params.size != null) sizeVal = params.size;
      if (sizeVal == null) return "10px";
      const px = +sizeVal * pxPerMm;
      return Number.isFinite(px) ? Math.max(1, px) + "px" : "10px";
    }

    function layerValue(d, key) {
      const rowVal = val(get(d, key));
      return rowVal == null ? params[key] : rowVal;
    }

    function textAnchor(d) {
      const hjust = layerValue(d, "hjust");
      if (hjust == null) return "middle";
      if (typeof hjust === "string") {
        const normalized = hjust.toLowerCase();
        if (normalized === "left") return "start";
        if (normalized === "right") return "end";
        if (normalized === "center" || normalized === "centre" || normalized === "middle") {
          return "middle";
        }
      }
      const numeric = +hjust;
      if (!Number.isFinite(numeric)) return "middle";
      if (numeric <= 0.25) return "start";
      if (numeric >= 0.75) return "end";
      return "middle";
    }

    function dominantBaseline(d) {
      const vjust = layerValue(d, "vjust");
      if (vjust == null) return "middle";
      if (typeof vjust === "string") {
        const normalized = vjust.toLowerCase();
        if (normalized === "top") return "hanging";
        if (normalized === "bottom") return "baseline";
        if (normalized === "center" || normalized === "centre" || normalized === "middle") {
          return "middle";
        }
      }
      const numeric = +vjust;
      if (!Number.isFinite(numeric)) return "middle";
      if (numeric <= 0.25) return "hanging";
      if (numeric >= 0.75) return "baseline";
      return "middle";
    }

    function fontFamily(d) {
      return layerValue(d, "family") || null;
    }

    function rotationTransform(d, x, y) {
      const angle = +layerValue(d, "angle");
      if (!Number.isFinite(angle) || angle === 0) return null;
      return "rotate(" + angle + " " + x + " " + y + ")";
    }

    function labelGroupTransform(d) {
      const x = pointX(d);
      const y = pointY(d);
      const angle = +layerValue(d, "angle");
      const rotate = Number.isFinite(angle) && angle !== 0 ? " rotate(" + angle + ")" : "";
      return "translate(" + x + "," + y + ")" + rotate;
    }

    function opacityValue(d) {
      if (aes.alpha) return opacity(d);
      const alpha = layerValue(d, "alpha");
      return alpha == null ? opacity(d) : +alpha;
    }

    function labelPadding() {
      const labelParams = params.label || {};
      const padding = +labelParams.padding;
      return Number.isFinite(padding) ? Math.max(0, padding) : 3;
    }

    function labelStrokeWidth(d) {
      const linewidth = layerValue(d, "linewidth");
      return linewidth != null ? mmToPxLinewidth(+linewidth) : mmToPxLinewidth(0.5);
    }

    function scalePos(scale, v, isBand) {
      return isBand ? scale(v) + scale.bandwidth() / 2 : scale(v);
    }

    function pointX(d) {
      if (flip) {
        const yVal = isYBand ? val(get(d, aes.y)) : num(get(d, aes.y));
        return scalePos(yScale, yVal, isYBand);
      }
      const xVal = isXBand ? val(get(d, aes.x)) : num(get(d, aes.x));
      return scalePos(xScale, xVal, isXBand);
    }

    function pointY(d) {
      if (flip) {
        const xVal = isXBand ? val(get(d, aes.x)) : num(get(d, aes.x));
        return scalePos(xScale, xVal, isXBand);
      }
      const yVal = isYBand ? val(get(d, aes.y)) : num(get(d, aes.y));
      return scalePos(yScale, yVal, isYBand);
    }

    const txt = dat.filter(d => {
      const xVal = isXBand ? val(get(d, aes.x)) : num(get(d, aes.x));
      const yVal = isYBand ? val(get(d, aes.y)) : num(get(d, aes.y));
      return xVal != null && yVal != null;
    });

    if (layer.geom === "label") {
      const labelGroups = g.append("g").selectAll("g.geom-label").data(txt);
      const enteredLabels = labelGroups.enter().append("g")
        .attr("class", "geom-label")
        .attr("transform", labelGroupTransform)
        .attr("data-cx", pointX)
        .attr("data-cy", pointY)
        .attr("opacity", opacityValue);

      enteredLabels.append("rect")
        .attr("class", "geom-label-box")
        .attr("fill", d => fillColor(d))
        .attr("stroke", d => strokeColor(d))
        .attr("stroke-width", labelStrokeWidth);

      enteredLabels.append("text")
        .attr("class", "geom-label-text")
        .attr("x", 0)
        .attr("y", 0)
        .attr("text-anchor", textAnchor)
        .attr("dominant-baseline", dominantBaseline)
        .text(d => val(get(d, aes.label)))
        .attr("fill", d => strokeColor(d))
        .style("font-size", textSize)
        .style("font-family", fontFamily);

      enteredLabels.each(function() {
        const node = d3.select(this);
        const textNode = node.select("text.geom-label-text").node();
        if (!textNode) return;
        const bbox = textNode.getBBox();
        const pad = labelPadding();
        node.select("rect.geom-label-box")
          .attr("x", bbox.x - pad)
          .attr("y", bbox.y - pad)
          .attr("width", bbox.width + pad * 2)
          .attr("height", bbox.height + pad * 2);
      });

      return txt.length;
    }

    const sel = g.append("g").selectAll("text.geom-text").data(txt);
    sel.enter().append("text")
      .attr("class", "geom-text")
      .attr("x", pointX)
      .attr("y", pointY)
      .attr("dominant-baseline", dominantBaseline)
      .attr("text-anchor", textAnchor)
      .attr("transform", d => rotationTransform(d, pointX(d), pointY(d)))
      .text(d => val(get(d, aes.label)))
      .attr("fill", d => strokeColor(d))
      .attr("opacity", opacityValue)
      .style("font-size", textSize)
      .style("font-family", fontFamily);

    return txt.length;
  }

  window.gg2d3.geomRegistry.register(['text', 'label'], renderText);

})();
