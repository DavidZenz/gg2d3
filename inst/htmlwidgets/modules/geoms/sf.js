/**
 * gg2d3 SF Geom Renderer
 *
 * Renders geom_sf as SVG paths using d3.geoPath + d3.geoIdentity.
 * Handles Polygon, MultiPolygon, and other GeoJSON geometry types.
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
   * Render sf geom as SVG paths.
   *
   * Per D-02: receives xScale/yScale but ignores them.
   * Uses d3.geoIdentity().reflectY(true).fitExtent() for projection.
   *
   * @param {Object} layer - Layer object from IR
   * @param {d3.Selection} g - D3 plot group selection
   * @param {Function} xScale - D3 x scale (IGNORED for sf)
   * @param {Function} yScale - D3 y scale (IGNORED for sf)
   * @param {Object} options - Rendering options
   * @returns {number} Number of paths drawn
   */
  function renderSf(layer, g, xScale, yScale, options) {
    var w = options.plotWidth;
    var h = options.plotHeight;

    var colorAccessors = window.gg2d3.geomRegistry.makeColorAccessors(layer, options);
    var strokeColor = colorAccessors.strokeColor;
    var fillColor = colorAccessors.fillColor;
    var opacityFn = colorAccessors.opacity;

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

    // Pre-compute centroids for all geometries (avoid double computation in attr calls)
    var centroids = geoms.map(function(geom) {
      if (!geom) return [NaN, NaN];
      return pathGen.centroid({ type: "Feature", geometry: geom, properties: {} });
    });

    // Build data rows with geometry attached
    // Per D-06: join by row_id but arrays are positionally parallel
    var data = layer.data || [];
    var rows = data.map(function(d, i) {
      var row = {};
      for (var k in d) { if (d.hasOwnProperty(k)) row[k] = d[k]; }
      row._geom = geoms[i] || null;
      row._centroid = centroids[i];
      return row;
    });

    // Stroke width from params or default 0.5px (UI-SPEC)
    var strokeWidth = (layer.params && layer.params.linewidth != null)
      ? layer.params.linewidth : 0.5;

    // Render paths
    var sfGroup = g.append("g").attr("class", "geom-sf-group");

    sfGroup.selectAll("path.geom-sf")
      .data(rows)
      .enter().append("path")
        .attr("class", "geom-sf")
        .attr("d", function(d) {
          if (!d._geom) return "";
          return pathGen({ type: "Feature", geometry: d._geom, properties: {} }) || "";
        })
        .attr("fill", function(d) { return fillColor(d); })
        .attr("stroke", function(d) { return strokeColor(d); })
        .attr("stroke-width", strokeWidth)
        .attr("opacity", function(d) { return opacityFn(d); })
        .attr("fill-rule", "evenodd")
        .attr("data-cx", function(d) {
          return isFiniteNumber(d._centroid[0]) ? d._centroid[0] : null;
        })
        .attr("data-cy", function(d) {
          return isFiniteNumber(d._centroid[1]) ? d._centroid[1] : null;
        })
        .attr("data-row-id", function(d) {
          return d.row_id != null ? d.row_id : null;
        });

    return rows.length;
  }

  window.gg2d3.geomRegistry.register('sf', renderSf);
})();
