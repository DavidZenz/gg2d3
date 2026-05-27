/**
 * gg2d3 Public Data Module
 *
 * Shared helpers for stripping renderer-private fields before exposing
 * datum payloads to tooltips, event callbacks, Shiny, or brush callbacks.
 *
 * @module gg2d3.publicData
 */

(function() {
  'use strict';

  if (typeof window.gg2d3 === 'undefined') {
    window.gg2d3 = {};
  }

  function isObjectDatum(d) {
    return !!d && typeof d === 'object' && !Array.isArray(d);
  }

  function publicFieldNames(d) {
    if (!isObjectDatum(d)) return [];
    return Object.keys(d).filter(function(key) {
      return !String(key).startsWith('_');
    });
  }

  function sanitizeDatum(d) {
    if (!isObjectDatum(d)) return d;

    var sanitized = {};
    Object.keys(d).forEach(function(key) {
      if (String(key).startsWith('_')) return;
      sanitized[key] = d[key];
    });
    return sanitized;
  }

  window.gg2d3.publicData = {
    sanitizeDatum: sanitizeDatum,
    publicFieldNames: publicFieldNames
  };
})();
