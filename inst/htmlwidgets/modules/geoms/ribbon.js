// geoms/ribbon.js - Ribbon geom renderer (placeholder)
(function() {
  'use strict';

  // Register ribbon geom with no-op renderer (Wave 2 will implement)
  if (window.gg2d3 && window.gg2d3.geomRegistry) {
    window.gg2d3.geomRegistry.register(['ribbon'], function(g, layer, scales, options) {
      // Placeholder: return 0 rendered elements
      // Wave 2 will implement actual ribbon rendering
      return 0;
    });
  }
})();
