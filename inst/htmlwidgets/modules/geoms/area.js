// geoms/area.js - Area geom renderer (placeholder)
(function() {
  'use strict';

  // Register area geom with no-op renderer (Wave 2 will implement)
  if (window.gg2d3 && window.gg2d3.geomRegistry) {
    window.gg2d3.geomRegistry.register(['area'], function(g, layer, scales, options) {
      // Placeholder: return 0 rendered elements
      // Wave 2 will implement actual area rendering
      return 0;
    });
  }
})();
