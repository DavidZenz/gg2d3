// geoms/reference.js - Reference line geom renderers (hline, vline, abline) (placeholder)
(function() {
  'use strict';

  // Register reference line geoms with no-op renderer (Wave 2 will implement)
  if (window.gg2d3 && window.gg2d3.geomRegistry) {
    window.gg2d3.geomRegistry.register(['hline', 'vline', 'abline'], function(g, layer, scales, options) {
      // Placeholder: return 0 rendered elements
      // Wave 2 will implement actual reference line rendering
      return 0;
    });
  }
})();
