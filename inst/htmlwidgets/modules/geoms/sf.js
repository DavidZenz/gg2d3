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
    var w = options.plotWidth;
    var h = options.plotHeight;
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

    // Parse all geometry JSON strings once (Pitfall 4: guard against null/empty)
    var geoms = (layer.geometries || []).map(function(s) {
      try { return s ? JSON.parse(s) : null; } catch(e) { return null; }
    });

    // Build FeatureCollection from non-null geometries for fitExtent bounds
    // (Pitfall 1: must include ALL features, not a subset)
    var validFeatures = [];
    geoms.forEach(function(geom, i) {
      if (geom != null) {
        validFeatures.push({ type: "Feature", geometry: geom, properties: { _idx: i } });
      }
    });

    if (validFeatures.length === 0) return 0;

    var fc = { type: "FeatureCollection", features: validFeatures };
    var fitSource = bboxToFeatureCollection(options.sfBBox) || fc;

    // Build projection: geoIdentity + reflectY (Pitfall 2: required for SVG y-axis)
    // UI-SPEC: 4px padding on all sides
    var padding = 4;
    var proj = d3.geoIdentity()
      .reflectY(true)
      .fitExtent([[padding, padding], [w - padding, h - padding]], fitSource);

    var pathGen = d3.geoPath().projection(proj);

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
      for (var k in d) { if (d.hasOwnProperty(k)) row[k] = d[k]; }
      return row;
    }

    // Pre-compute centroids for all geometries (avoid double computation in attr calls)
    var centroids = geoms.map(function(geom) {
      if (!geom) return [NaN, NaN];
      return pathGen.centroid(asFeature(geom));
    });

    // Build data rows with geometry attached
    // Per D-06: join by row_id but arrays are positionally parallel
    var data = layer.data || [];
    var rows = data.map(function(d, i) {
      var row = copyRow(d);
      row._geom = geoms[i] || null;
      row._centroid = centroids[i];
      row._sfFamily = geometryFamily(row._geom);
      return row;
    });

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

    function projectedCoordinate(coord) {
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

    function expandPointRows(rows) {
      var pointRows = [];
      rows.forEach(function(row) {
        pointCoordinates(row._geom).forEach(function(coord, index) {
          var pointRow = copyRow(row);
          pointRow._pointCoord = coord;
          pointRow._pointIndex = index;
          pointRow._centroid = projectedCoordinate(coord);
          pointRows.push(pointRow);
        });
      });
      return pointRows;
    }

    var sfGroup = g.append("g").attr("class", "geom-sf-group");
    var polygonRows = rows.filter(function(d) { return d._sfFamily === "polygon"; });
    var lineRows = rows.filter(function(d) { return d._sfFamily === "line"; });
    var pointRows = expandPointRows(rows.filter(function(d) { return d._sfFamily === "point"; }));

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

  window.gg2d3.geomRegistry.register('sf', renderSf);
})();
