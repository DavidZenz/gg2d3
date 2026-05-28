/**
 * gg2d3 SF Geom Renderer
 *
 * Renders geom_sf using d3.geoPath + d3.geoIdentity.
 * Handles Polygon, MultiPolygon, Point, MultiPoint, LineString, and
 * MultiLineString GeoJSON geometry types.
 * Uses fill-rule="evenodd" for correct multipolygon hole rendering.
 *
 * @module gg2d3.geoms.sf
 */
(function() {
  'use strict';

  function isFiniteNumber(value) {
    return typeof value === 'number' && Number.isFinite(value);
  }

  function bboxToFeatureCollection(bbox) {
    if (!Array.isArray(bbox) || bbox.length !== 4) return null;

    var xmin = bbox[0];
    var ymin = bbox[1];
    var xmax = bbox[2];
    var ymax = bbox[3];
    if (![xmin, ymin, xmax, ymax].every(isFiniteNumber)) return null;

    return {
      type: "FeatureCollection",
      features: [{
        type: "Feature",
        geometry: {
          type: "Polygon",
          coordinates: [[
            [xmin, ymin],
            [xmax, ymin],
            [xmax, ymax],
            [xmin, ymax],
            [xmin, ymin]
          ]]
        },
        properties: {}
      }]
    };
  }

  function geometryFamily(geom) {
    if (!geom || !geom.type) return "unsupported";
    if (geom.type === "Polygon" || geom.type === "MultiPolygon") return "polygon";
    if (geom.type === "Point" || geom.type === "MultiPoint") return "point";
    if (geom.type === "LineString" || geom.type === "MultiLineString") return "line";
    return "unsupported";
  }

  function asFeature(geom) {
    return { type: "Feature", geometry: geom, properties: {} };
  }

  function copyRow(d) {
    var row = {};
    for (var k in d) {
      if (Object.prototype.hasOwnProperty.call(d, k)) row[k] = d[k];
    }
    return row;
  }

  function normalizeGeometries(geometries) {
    if (geometries == null) return [];
    return Array.isArray(geometries) ? geometries : [geometries];
  }

  function parseGeometries(layer) {
    return normalizeGeometries(layer.geometries).map(function(s) {
      try { return s ? JSON.parse(s) : null; } catch(e) { return null; }
    });
  }

  function buildProjection(layer, options) {
    var w = options.plotWidth;
    var h = options.plotHeight;
    var geoms = parseGeometries(layer);
    var validFeatures = [];

    geoms.forEach(function(geom, i) {
      if (geom != null) {
        validFeatures.push({ type: "Feature", geometry: geom, properties: { _idx: i } });
      }
    });

    if (validFeatures.length === 0) return null;

    var fc = { type: "FeatureCollection", features: validFeatures };
    var fitSource = bboxToFeatureCollection(options.sfBBox) || fc;
    var padding = 4;
    var proj = d3.geoIdentity()
      .reflectY(true)
      .fitExtent([[padding, padding], [w - padding, h - padding]], fitSource);
    var pathGen = d3.geoPath().projection(proj);

    return {
      geoms: geoms,
      proj: proj,
      pathGen: pathGen
    };
  }

  function finiteAttr(value) {
    return isFiniteNumber(value) ? value : null;
  }

  function attrCx(d) {
    return d._centroid ? finiteAttr(d._centroid[0]) : null;
  }

  function attrCy(d) {
    return d._centroid ? finiteAttr(d._centroid[1]) : null;
  }

  function rowId(d) {
    return d.row_id != null ? d.row_id : null;
  }

  function projectedCoordinate(proj, coord) {
    if (!Array.isArray(coord) || coord.length < 2) return [NaN, NaN];
    var x = +coord[0];
    var y = +coord[1];
    if (!isFiniteNumber(x) || !isFiniteNumber(y)) return [NaN, NaN];
    return proj([x, y]);
  }

  function pointCoordinates(geom) {
    if (!geom || !geom.coordinates) return [];
    if (geom.type === "Point") return [geom.coordinates];
    if (geom.type === "MultiPoint") return geom.coordinates;
    return [];
  }

  function expandPointRows(rows, proj) {
    var pointRows = [];
    rows.forEach(function(row) {
      pointCoordinates(row._geom).forEach(function(coord, index) {
        var pointRow = copyRow(row);
        pointRow._pointCoord = coord;
        pointRow._pointIndex = index;
        pointRow._centroid = projectedCoordinate(proj, coord);
        pointRows.push(pointRow);
      });
    });
    return pointRows;
  }

  function buildSfRows(layer, geoms, pathGen) {
    var data = layer.data || [];
    var centroids = geoms.map(function(geom) {
      if (!geom) return [NaN, NaN];
      return pathGen.centroid(asFeature(geom));
    });

    return data.map(function(d, i) {
      var row = copyRow(d);
      row._geom = geoms[i] || null;
      row._centroid = centroids[i];
      row._sfFamily = geometryFamily(row._geom);
      return row;
    });
  }

  function annotationAnchor(geom, pathGen, proj) {
    var family = geometryFamily(geom);
    var coords;
    if (family === "point") {
      coords = pointCoordinates(geom);
      if (coords.length > 0) return projectedCoordinate(proj, coords[0]);
    }
    if (!geom) return [NaN, NaN];
    return pathGen.centroid(asFeature(geom));
  }

  function scaledAnnotationAnchor(row, xScale, yScale) {
    var x = +row.x;
    var y = +row.y;
    if (!isFiniteNumber(x) || !isFiniteNumber(y)) return null;
    var sx = xScale(x);
    var sy = yScale(y);
    if (!isFiniteNumber(sx) || !isFiniteNumber(sy)) return null;
    return [sx, sy];
  }

  function buildAnnotationRows(layer, geoms, pathGen, proj, val, xScale, yScale) {
    var data = layer.data || [];
    return data.map(function(d, i) {
      var row = copyRow(d);
      row._geom = geoms[i] || null;
      row._centroid = scaledAnnotationAnchor(row, xScale, yScale) || annotationAnchor(row._geom, pathGen, proj);
      row._sfAnchor = row._centroid;
      row._sfFamily = geometryFamily(row._geom);
      return row;
    }).filter(function(row) {
      var label = labelValue(row, layer, val);
      return label != null && label !== "" && isFiniteNumber(attrCx(row)) && isFiniteNumber(attrCy(row));
    });
  }

  function labelValue(d, layer, val) {
    var aes = layer.aes || {};
    var key = aes.label || "label";
    return val(d[key]);
  }

  function staticOrMappedSize(d, layer, val) {
    var constants = window.gg2d3.constants || {};
    var pxPerMm = constants.PX_PER_MM || 3.7795275591;
    var params = layer.params || {};
    var sizeVal = val(d.size);
    if (sizeVal == null && params.size != null) sizeVal = params.size;
    if (sizeVal == null) return "10px";
    return Math.max(1, +sizeVal * pxPerMm) + "px";
  }

  function opacityValue(d, layer, opacityFn, val) {
    var aes = layer.aes || {};
    var params = layer.params || {};
    if (aes.alpha) return opacityFn(d);
    var alpha = val(d.alpha);
    if (alpha == null && params.alpha != null) alpha = params.alpha;
    return alpha == null ? opacityFn(d) : +alpha;
  }

  function textAnchor(d, layer, val) {
    var params = layer.params || {};
    var hjust = val(d.hjust);
    if (hjust == null && params.hjust != null) hjust = params.hjust;
    if (hjust == null) return "middle";
    hjust = +hjust;
    if (hjust <= 0.25) return "start";
    if (hjust >= 0.75) return "end";
    return "middle";
  }

  function dominantBaseline(d, layer, val) {
    var params = layer.params || {};
    var vjust = val(d.vjust);
    if (vjust == null && params.vjust != null) vjust = params.vjust;
    if (vjust == null) return "middle";
    vjust = +vjust;
    if (vjust <= 0.25) return "hanging";
    if (vjust >= 0.75) return "baseline";
    return "middle";
  }

  function fontFamily(d, layer, val) {
    var params = layer.params || {};
    return val(d.family) || params.family || null;
  }

  function fontWeight(d, layer, val) {
    var params = layer.params || {};
    var face = val(d.fontface) || params.fontface || "";
    return /bold/.test(String(face)) ? "bold" : "normal";
  }

  function fontStyle(d, layer, val) {
    var params = layer.params || {};
    var face = val(d.fontface) || params.fontface || "";
    return /italic/.test(String(face)) ? "italic" : "normal";
  }

  /**
   * Render sf geom as SVG marks.
   *
   * Per D-02: receives xScale/yScale but ignores them.
   * Uses d3.geoIdentity().reflectY(true).fitExtent() for projection.
   *
   * @param {Object} layer - Layer object from IR
   * @param {d3.Selection} g - D3 plot group selection
   * @param {Function} xScale - D3 x scale (IGNORED for sf)
   * @param {Function} yScale - D3 y scale (IGNORED for sf)
   * @param {Object} options - Rendering options
   * @returns {number} Number of marks drawn
   */
  function renderSf(layer, g, xScale, yScale, options) {
    var helpers = window.gg2d3.helpers || {};
    var constants = window.gg2d3.constants || {};
    var val = helpers.val || function(value) {
      if (value == null) return null;
      if (typeof value === "number" && Number.isNaN(value)) return null;
      return value;
    };
    var mmToPxRadius = constants.mmToPxRadius || function(size) { return size || 1.5; };
    var mmToPxLinewidth = constants.mmToPxLinewidth || function(linewidth) { return linewidth || 0.5; };
    var getDashArray = helpers.getDashArray || function() { return null; };

    var colorAccessors = window.gg2d3.geomRegistry.makeColorAccessors(layer, options);
    var strokeColor = colorAccessors.strokeColor;
    var fillColor = colorAccessors.fillColor;
    var opacityFn = colorAccessors.opacity;
    var params = layer.params || {};
    var projection = buildProjection(layer, options);
    if (!projection) return 0;

    var pathGen = projection.pathGen;
    var rows = buildSfRows(layer, projection.geoms, pathGen);

    function pathD(d) {
      if (!d._geom) return "";
      return pathGen(asFeature(d._geom)) || "";
    }

    function polygonStrokeWidth() {
      return params.linewidth != null ? params.linewidth : 0.5;
    }

    function lineStrokeWidth(d) {
      var linewidthVal = val(d.linewidth);
      if (linewidthVal == null && params.linewidth != null) linewidthVal = params.linewidth;
      return linewidthVal != null ? mmToPxLinewidth(+linewidthVal) : 1.42;
    }

    function pointRadius(d) {
      var sizeVal = val(d.size);
      if (sizeVal == null && params.size != null) sizeVal = params.size;
      if (sizeVal == null) sizeVal = 1.5;
      return Math.max(0.5, mmToPxRadius(+sizeVal));
    }

    function pointFill(d) {
      var fillVal = val(d.fill);
      if (fillVal == null || fillVal === "NA") return strokeColor(d);
      return fillColor(d);
    }

    function pointStroke(d) {
      var fillVal = val(d.fill);
      if (fillVal == null || fillVal === "NA") return "none";
      return strokeColor(d);
    }

    var sfGroup = g.append("g").attr("class", "geom-sf-group");
    var polygonRows = rows.filter(function(d) { return d._sfFamily === "polygon"; });
    var lineRows = rows.filter(function(d) { return d._sfFamily === "line"; });
    var pointRows = expandPointRows(rows.filter(function(d) { return d._sfFamily === "point"; }), projection.proj);

    // Keep polygon compatibility with existing path.geom-sf browser tests.
    sfGroup.selectAll("path.geom-sf.geom-sf-polygon")
      .data(polygonRows)
      .enter().append("path")
        .attr("class", "geom-sf geom-sf-polygon")
        .attr("d", pathD)
        .attr("fill", function(d) { return fillColor(d); })
        .attr("stroke", function(d) { return strokeColor(d); })
        .attr("stroke-width", polygonStrokeWidth())
        .attr("opacity", function(d) { return opacityFn(d); })
        .attr("fill-rule", "evenodd")
        .attr("data-cx", attrCx)
        .attr("data-cy", attrCy)
        .attr("data-row-id", rowId);

    sfGroup.selectAll("path.geom-sf.geom-sf-line")
      .data(lineRows)
      .enter().append("path")
        .attr("class", "geom-sf geom-sf-line")
        .attr("d", pathD)
        .attr("fill", "none")
        .attr("stroke", function(d) { return strokeColor(d); })
        .attr("stroke-width", lineStrokeWidth)
        .attr("stroke-dasharray", function(d) {
          return getDashArray(val(d.linetype) || params.linetype);
        })
        .attr("opacity", function(d) { return opacityFn(d); })
        .attr("data-cx", attrCx)
        .attr("data-cy", attrCy)
        .attr("data-row-id", rowId);

    sfGroup.selectAll("circle.geom-sf.geom-sf-point")
      .data(pointRows)
      .enter().append("circle")
        .attr("class", "geom-sf geom-sf-point")
        .attr("cx", attrCx)
        .attr("cy", attrCy)
        .attr("r", pointRadius)
        .attr("fill", pointFill)
        .attr("stroke", pointStroke)
        .attr("stroke-width", function(d) {
          var strokeVal = val(d.stroke);
          return strokeVal != null ? strokeVal : 0.5;
        })
        .attr("opacity", function(d) { return opacityFn(d); })
        .attr("data-cx", attrCx)
        .attr("data-cy", attrCy)
        .attr("data-row-id", rowId);

    return polygonRows.length + lineRows.length + pointRows.length;
  }

  function renderSfAnnotation(layer, g, xScale, yScale, options, annotationType) {
    var helpers = window.gg2d3.helpers || {};
    var val = helpers.val || function(value) {
      if (value == null) return null;
      if (typeof value === "number" && Number.isNaN(value)) return null;
      return value;
    };
    var colorAccessors = window.gg2d3.geomRegistry.makeColorAccessors(layer, options);
    var projection = buildProjection(layer, options);
    if (!projection) return 0;

    var rows = buildAnnotationRows(layer, projection.geoms, projection.pathGen, projection.proj, val, xScale, yScale);
    var group = g.append("g").attr("class", "geom-sf-annotation-group geom-sf-" + annotationType + "-group");

    if (annotationType === "text") {
      group.selectAll("text.geom-sf.geom-sf-text")
        .data(rows)
        .enter().append("text")
          .attr("class", "geom-sf geom-sf-text")
          .attr("x", attrCx)
          .attr("y", attrCy)
          .attr("data-cx", attrCx)
          .attr("data-cy", attrCy)
          .attr("data-row-id", rowId)
          .attr("text-anchor", function(d) { return textAnchor(d, layer, val); })
          .attr("dominant-baseline", function(d) { return dominantBaseline(d, layer, val); })
          .text(function(d) { return labelValue(d, layer, val); })
          .attr("fill", function(d) { return colorAccessors.strokeColor(d); })
          .attr("opacity", function(d) { return opacityValue(d, layer, colorAccessors.opacity, val); })
          .style("font-size", function(d) { return staticOrMappedSize(d, layer, val); })
          .style("font-family", function(d) { return fontFamily(d, layer, val); })
          .style("font-weight", function(d) { return fontWeight(d, layer, val); })
          .style("font-style", function(d) { return fontStyle(d, layer, val); });
      return rows.length;
    }

    var labelGroups = group.selectAll("g.geom-sf.geom-sf-label")
      .data(rows)
      .enter().append("g")
        .attr("class", "geom-sf geom-sf-label")
        .attr("transform", function(d) { return "translate(" + attrCx(d) + "," + attrCy(d) + ")"; })
        .attr("data-cx", attrCx)
        .attr("data-cy", attrCy)
        .attr("data-row-id", rowId)
        .attr("opacity", function(d) { return opacityValue(d, layer, colorAccessors.opacity, val); });

    labelGroups.append("rect")
      .attr("class", "geom-sf-label-box")
      .attr("fill", function(d) { return colorAccessors.fillColor(d); })
      .attr("stroke", function(d) { return colorAccessors.strokeColor(d); })
      .attr("stroke-width", 0.5);

    labelGroups.append("text")
      .attr("class", "geom-sf-label-text")
      .attr("x", 0)
      .attr("y", 0)
      .attr("text-anchor", function(d) { return textAnchor(d, layer, val); })
      .attr("dominant-baseline", function(d) { return dominantBaseline(d, layer, val); })
      .text(function(d) { return labelValue(d, layer, val); })
      .attr("fill", function(d) { return colorAccessors.strokeColor(d); })
      .style("font-size", function(d) { return staticOrMappedSize(d, layer, val); })
      .style("font-family", function(d) { return fontFamily(d, layer, val); })
      .style("font-weight", function(d) { return fontWeight(d, layer, val); })
      .style("font-style", function(d) { return fontStyle(d, layer, val); });

    labelGroups.each(function() {
      var node = d3.select(this);
      var textNode = node.select("text.geom-sf-label-text").node();
      if (!textNode) return;
      var bbox = textNode.getBBox();
      var pad = 3;
      node.select("rect.geom-sf-label-box")
        .attr("x", bbox.x - pad)
        .attr("y", bbox.y - pad)
        .attr("width", bbox.width + pad * 2)
        .attr("height", bbox.height + pad * 2);
    });

    return rows.length;
  }

  function renderSfText(layer, g, xScale, yScale, options) {
    return renderSfAnnotation(layer, g, xScale, yScale, options, "text");
  }

  function renderSfLabel(layer, g, xScale, yScale, options) {
    return renderSfAnnotation(layer, g, xScale, yScale, options, "label");
  }

  window.gg2d3.geomRegistry.register('sf', renderSf);
  window.gg2d3.geomRegistry.register('sf_text', renderSfText);
  window.gg2d3.geomRegistry.register('sf_label', renderSfLabel);
})();
