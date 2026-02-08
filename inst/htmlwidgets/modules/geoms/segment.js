// geoms/segment.js - Segment geom renderer (placeholder)
(function() {
  'use strict';

  // Register segment geom with no-op renderer (Wave 2 will implement)
  if (window.gg2d3 && window.gg2d3.geomRegistry) {
    window.gg2d3.geomRegistry.register(['segment'], function(g, layer, scales, options) {
      // Placeholder: return 0 rendered elements
      // Wave 2 will implement actual segment rendering
      return 0;
    });
  }
})();
