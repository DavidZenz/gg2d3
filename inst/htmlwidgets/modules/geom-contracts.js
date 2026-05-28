/**
 * gg2d3 Geom Contracts Module
 *
 * Internal metadata for renderer/update/interaction wiring. This is not a
 * public extension API; it exists so source-level tests and small runtime
 * helpers can share the same supported-geom contract.
 *
 * @module gg2d3.geomContracts
 */

(function() {
  'use strict';

  if (!window.gg2d3) window.gg2d3 = {};

  const contracts = [
    {
      geom: 'point',
      aliases: ['point'],
      module: 'geoms/point.js',
      renderSelectors: ['circle.geom-point'],
      update: { type: 'selectors', selectors: ['circle.geom-point'] },
      interactions: {
        events: ['circle.geom-point'],
        brush: ['circle.geom-point'],
        crosstalk: ['circle.geom-point']
      },
      privateFields: [],
      publicPayload: true
    },
    {
      geom: 'line',
      aliases: ['line', 'path'],
      module: 'geoms/line.js',
      renderSelectors: ['path.geom-line'],
      update: { type: 'selectors', selectors: ['path.geom-line', 'path.geom-path'] },
      interactions: {
        events: ['path.geom-line'],
        brush: ['path.geom-line'],
        crosstalk: ['path.geom-line']
      },
      privateFields: [],
      publicPayload: true
    },
    {
      geom: 'polygon',
      aliases: ['polygon'],
      module: 'geoms/polygon.js',
      renderSelectors: ['path.geom-polygon'],
      update: { type: 'selectors', selectors: ['path.geom-polygon'] },
      interactions: {
        events: ['path.geom-polygon'],
        brush: ['path.geom-polygon'],
        crosstalk: ['path.geom-polygon']
      },
      privateFields: ['_polygonPoints', '_sourceIndex'],
      publicPayload: true
    },
    {
      geom: 'bar',
      aliases: ['bar', 'col'],
      module: 'geoms/bar.js',
      renderSelectors: ['rect.geom-bar', 'path.geom-bar.geom-polar'],
      update: { type: 'selectors', selectors: ['rect.geom-bar'] },
      interactions: {
        events: ['rect.geom-bar'],
        brush: ['rect.geom-bar'],
        crosstalk: ['rect.geom-bar']
      },
      privateFields: [],
      publicPayload: true
    },
    {
      geom: 'rect',
      aliases: ['rect', 'tile'],
      module: 'geoms/rect.js',
      renderSelectors: ['rect.geom-rect'],
      update: { type: 'selectors', selectors: ['rect.geom-rect'] },
      interactions: {
        events: ['rect.geom-rect'],
        brush: ['rect.geom-rect'],
        crosstalk: ['rect.geom-rect']
      },
      privateFields: [],
      publicPayload: true
    },
    {
      geom: 'text',
      aliases: ['text'],
      module: 'geoms/text.js',
      renderSelectors: ['text.geom-text'],
      update: { type: 'selectors', selectors: ['text.geom-text'] },
      interactions: {
        events: ['text.geom-text'],
        brush: ['text.geom-text'],
        crosstalk: ['text.geom-text']
      },
      privateFields: [],
      publicPayload: true
    },
    {
      geom: 'area',
      aliases: ['area'],
      module: 'geoms/area.js',
      renderSelectors: ['path.geom-area'],
      update: { type: 'selectors', selectors: ['path.geom-area'] },
      interactions: {
        events: ['path.geom-area'],
        brush: ['path.geom-area'],
        crosstalk: ['path.geom-area']
      },
      privateFields: [],
      publicPayload: true
    },
    {
      geom: 'ribbon',
      aliases: ['ribbon'],
      module: 'geoms/ribbon.js',
      renderSelectors: ['path.geom-ribbon'],
      update: { type: 'selectors', selectors: ['path.geom-ribbon'] },
      interactions: {
        events: ['path.geom-ribbon'],
        brush: ['path.geom-ribbon'],
        crosstalk: ['path.geom-ribbon']
      },
      privateFields: [],
      publicPayload: true
    },
    {
      geom: 'segment',
      aliases: ['segment'],
      module: 'geoms/segment.js',
      renderSelectors: ['line.geom-segment'],
      update: { type: 'selectors', selectors: ['line.geom-segment'] },
      interactions: {
        events: ['line.geom-segment'],
        brush: ['line.geom-segment'],
        crosstalk: ['line.geom-segment']
      },
      privateFields: [],
      publicPayload: true
    },
    {
      geom: 'hline',
      aliases: ['hline'],
      module: 'geoms/reference.js',
      renderSelectors: ['line.geom-hline'],
      update: { type: 'selectors', selectors: ['line.geom-hline'] },
      interactions: { events: [], brush: [], crosstalk: [] },
      privateFields: [],
      publicPayload: true
    },
    {
      geom: 'vline',
      aliases: ['vline'],
      module: 'geoms/reference.js',
      renderSelectors: ['line.geom-vline'],
      update: { type: 'selectors', selectors: ['line.geom-vline'] },
      interactions: { events: [], brush: [], crosstalk: [] },
      privateFields: [],
      publicPayload: true
    },
    {
      geom: 'abline',
      aliases: ['abline'],
      module: 'geoms/reference.js',
      renderSelectors: ['line.geom-abline'],
      update: {
        type: 'explicit-none',
        selectors: [],
        reason: 'geom_abline is rendered from scale domains and currently has no updateGeoms branch.'
      },
      interactions: { events: [], brush: [], crosstalk: [] },
      privateFields: [],
      publicPayload: true
    },
    {
      geom: 'dotplot',
      aliases: ['dotplot'],
      module: 'geoms/dotplot.js',
      renderSelectors: ['circle.geom-dotplot'],
      update: { type: 'selectors', selectors: ['circle.geom-dotplot'] },
      interactions: {
        events: ['circle.geom-dotplot'],
        brush: ['circle.geom-dotplot'],
        crosstalk: {
          selectors: [],
          reason: 'crosstalk.js does not currently bind dotplot marks.'
        }
      },
      privateFields: [],
      publicPayload: true
    },
    {
      geom: 'rug',
      aliases: ['rug'],
      module: 'geoms/rug.js',
      renderSelectors: ['line.geom-rug'],
      update: { type: 'selectors', selectors: ['line.geom-rug'] },
      interactions: {
        events: ['line.geom-rug'],
        brush: ['line.geom-rug'],
        crosstalk: {
          selectors: [],
          reason: 'crosstalk.js does not currently bind rug marks.'
        }
      },
      privateFields: [],
      publicPayload: true
    },
    {
      geom: 'interval',
      aliases: ['errorbar', 'linerange', 'pointrange'],
      module: 'geoms/interval.js',
      renderSelectors: [
        'g.geom-interval-errorbar g.interval-item',
        'g.geom-interval-linerange g.interval-item',
        'g.geom-interval-pointrange g.interval-item',
        'line.interval-line',
        'line.errorbar-cap-top',
        'line.errorbar-cap-bottom',
        'circle.pointrange-point'
      ],
      update: {
        type: 'selectors',
        selectors: [
          'g.geom-interval-errorbar g.interval-item',
          'g.geom-interval-linerange g.interval-item',
          'g.geom-interval-pointrange g.interval-item'
        ]
      },
      interactions: {
        events: [
          'line.interval-line',
          'line.errorbar-cap-top',
          'line.errorbar-cap-bottom',
          'circle.pointrange-point'
        ],
        brush: [
          'line.interval-line',
          'line.errorbar-cap-top',
          'line.errorbar-cap-bottom',
          'circle.pointrange-point'
        ],
        crosstalk: {
          selectors: [],
          reason: 'crosstalk.js does not currently bind interval component marks.'
        }
      },
      privateFields: [],
      publicPayload: true
    },
    {
      geom: 'boxplot',
      aliases: ['boxplot'],
      module: 'geoms/boxplot.js',
      renderSelectors: [
        'rect.geom-boxplot-box',
        'line.geom-boxplot-whisker',
        'line.geom-boxplot-median',
        'circle.geom-boxplot-outlier'
      ],
      update: {
        type: 'selectors',
        selectors: [
          'rect.geom-boxplot-box',
          'line.geom-boxplot-whisker, line.geom-boxplot-median, line.geom-boxplot-staple',
          'circle.geom-boxplot-outlier'
        ]
      },
      interactions: {
        events: ['rect.geom-boxplot-box', 'circle.geom-boxplot-outlier'],
        brush: ['rect.geom-boxplot-box', 'circle.geom-boxplot-outlier'],
        crosstalk: ['rect.geom-boxplot-box', 'circle.geom-boxplot-outlier']
      },
      privateFields: [],
      publicPayload: true
    },
    {
      geom: 'violin',
      aliases: ['violin'],
      module: 'geoms/violin.js',
      renderSelectors: ['path.geom-violin'],
      update: { type: 'selectors', selectors: ['path.geom-violin'] },
      interactions: {
        events: ['path.geom-violin'],
        brush: ['path.geom-violin'],
        crosstalk: ['path.geom-violin']
      },
      privateFields: [],
      publicPayload: true
    },
    {
      geom: 'density',
      aliases: ['density'],
      module: 'geoms/density.js',
      renderSelectors: ['path.geom-density', 'path.geom-density-outline'],
      update: { type: 'selectors', selectors: ['path.geom-density', 'path.geom-density-outline'] },
      interactions: {
        events: ['path.geom-density'],
        brush: ['path.geom-density'],
        crosstalk: ['path.geom-density']
      },
      privateFields: [],
      publicPayload: true
    },
    {
      geom: 'smooth',
      aliases: ['smooth'],
      module: 'geoms/smooth.js',
      renderSelectors: ['path.geom-smooth', 'path.geom-smooth-ribbon'],
      update: { type: 'selectors', selectors: ['path.geom-smooth', 'path.geom-smooth-ribbon'] },
      interactions: {
        events: ['path.geom-smooth'],
        brush: ['path.geom-smooth'],
        crosstalk: ['path.geom-smooth']
      },
      privateFields: [],
      publicPayload: true
    },
    {
      geom: 'sf',
      aliases: ['sf'],
      module: 'geoms/sf.js',
      renderSelectors: [
        'path.geom-sf.geom-sf-polygon',
        'path.geom-sf.geom-sf-line',
        'circle.geom-sf.geom-sf-point'
      ],
      update: {
        type: 'explicit-none',
        selectors: [],
        reason: 'geom_sf uses projection-space coordinates and currently has no updateGeoms branch.'
      },
      interactions: {
        events: ['.geom-sf'],
        brush: ['.geom-sf'],
        crosstalk: ['.geom-sf']
      },
      privateFields: ['_geom', '_centroid', '_sfFamily', '_pointCoord', '_pointIndex'],
      publicPayload: true
    },
    {
      geom: 'sf_text',
      aliases: ['sf_text'],
      module: 'geoms/sf.js',
      renderSelectors: ['text.geom-sf.geom-sf-text'],
      update: {
        type: 'explicit-none',
        selectors: [],
        reason: 'geom_sf_text uses projection-space coordinates and currently has no updateGeoms branch.'
      },
      interactions: {
        events: ['.geom-sf'],
        brush: ['.geom-sf'],
        crosstalk: ['.geom-sf']
      },
      privateFields: ['_geom', '_centroid', '_sfFamily', '_sfAnchor'],
      publicPayload: true
    },
    {
      geom: 'sf_label',
      aliases: ['sf_label'],
      module: 'geoms/sf.js',
      renderSelectors: ['g.geom-sf.geom-sf-label'],
      update: {
        type: 'explicit-none',
        selectors: [],
        reason: 'geom_sf_label uses projection-space coordinates and currently has no updateGeoms branch.'
      },
      interactions: {
        events: ['.geom-sf'],
        brush: ['.geom-sf'],
        crosstalk: ['.geom-sf']
      },
      privateFields: ['_geom', '_centroid', '_sfFamily', '_sfAnchor'],
      publicPayload: true
    }
  ];

  function unique(values) {
    const seen = {};
    const out = [];
    values.forEach(function(value) {
      if (!value || seen[value]) return;
      seen[value] = true;
      out.push(value);
    });
    return out;
  }

  function interactionSelectors(entry, surface) {
    const value = entry && entry.interactions ? entry.interactions[surface] : null;
    if (!value) return [];
    if (Array.isArray(value)) return value.slice();
    if (Array.isArray(value.selectors)) return value.selectors.slice();
    return [];
  }

  function all() {
    return contracts.slice();
  }

  function names() {
    const out = [];
    contracts.forEach(function(entry) {
      out.push(entry.geom);
      (entry.aliases || []).forEach(function(alias) {
        out.push(alias);
      });
    });
    return unique(out);
  }

  function find(name) {
    return contracts.find(function(entry) {
      return entry.geom === name || (entry.aliases || []).indexOf(name) !== -1;
    }) || null;
  }

  function selectorsFor(surface) {
    const selectors = [];
    contracts.forEach(function(entry) {
      interactionSelectors(entry, surface).forEach(function(selector) {
        selectors.push(selector);
      });
    });
    return unique(selectors);
  }

  function privateFields() {
    const fields = [];
    contracts.forEach(function(entry) {
      (entry.privateFields || []).forEach(function(field) {
        fields.push(field);
      });
    });
    return unique(fields);
  }

  window.gg2d3.geomContracts = {
    all: all,
    names: names,
    find: find,
    selectorsFor: selectorsFor,
    privateFields: privateFields
  };

})();
