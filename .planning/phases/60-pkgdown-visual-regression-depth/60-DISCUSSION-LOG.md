# Phase 60: Pkgdown Visual Regression Depth - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-23
**Phase:** 60-pkgdown-visual-regression-depth
**Areas discussed:** Page source, Blank detection strategy, Capture scope, Command surface

---

## Page Source

| Option | Description | Selected |
|--------|-------------|----------|
| Load docs/ HTML | Open docs/articles/gg2d3.html in chromote. Proves actual pkgdown output has rendered widgets. Requires pkgdown::build_site() first. | ✓ |
| Fresh test fixtures | Create purpose-built widget fixtures in-test like existing smoke tests. No build step needed. | |
| Both | Capture both docs/ HTML and fresh fixtures. | |

**User's choice:** Load docs/ HTML

Follow-up — CI integration:

| Option | Description | Selected |
|--------|-------------|----------|
| Inside pkgdown.yaml after build | Add capture step to existing pkgdown workflow after build. Single workflow run. | ✓ |
| Separate standalone workflow | New pkgdown-visual-regression.yaml downloading the artifact. | |
| Local-only for now | No CI integration in Phase 60. | |

**User's choice:** Inside pkgdown.yaml after build

---

## Blank Detection Strategy

| Option | Description | Selected |
|--------|-------------|----------|
| DOM-based: SVG child count | After page load + settle, count SVG children inside .html-widget-container. Assert count >= threshold. | ✓ |
| Bounding-box: widget height > 0 | Use getBoundingClientRect() to assert height/width > 0. | |
| Screenshot brightness | Pixel-sample check: >90% white/near-white = blank. | |

**User's choice:** DOM-based: SVG child count

Follow-up — screenshot alongside:

| Option | Description | Selected |
|--------|-------------|----------|
| Full-page PNG + DOM JSON | Screenshot + DOM summary with SVG child counts. Follows existing helper pattern. | ✓ |
| DOM check only | No PNG artifact. | |
| You decide | Claude picks the balance. | |

**User's choice:** Full-page PNG + DOM JSON

---

## Capture Scope

| Option | Description | Selected |
|--------|-------------|----------|
| Main article only — gg2d3.html | One page has core, sf, and Crosstalk widgets. | ✓ |
| Both articles — gg2d3.html + gg2d3-interactivity.html | Extends to zoom/brush/tooltip demos. | |
| Main article + index page | gg2d3.html + index.html (no widgets on index). | |

**User's choice:** Main article only

Follow-up — sf widget pass criteria:

| Option | Description | Selected |
|--------|-------------|----------|
| Pass if rendered OR classified skip | Mirrors existing pkgdown-site validation semantics. | ✓ |
| Require rendered — fail if skipped | Stricter: sf must have SVG children to pass. | |
| You decide | Claude picks threshold from existing helpers. | |

**User's choice:** Pass if rendered OR classified skip

---

## Command Surface

| Option | Description | Selected |
|--------|-------------|----------|
| New test file: test-pkgdown-visual.R | Testthat file alongside test-browser-visual-smoke.R, reusing helper-browser-visual.R. | ✓ |
| Standalone script: tools/capture-pkgdown-visual.R | Direct chromote calls, no testthat. | |
| You decide | Claude picks whichever fits existing patterns. | |

**User's choice:** New test file: test-pkgdown-visual.R

Follow-up — env var:

| Option | Description | Selected |
|--------|-------------|----------|
| Share existing GG2D3_BROWSER_VISUAL_SMOKE | One flag for all browser visual tests. | ✓ |
| New dedicated env var: GG2D3_PKGDOWN_VISUAL | Separate opt-in for pkgdown visual capture. | |
| You decide | Claude picks simplest CI config. | |

**User's choice:** Share existing GG2D3_BROWSER_VISUAL_SMOKE

---

## Claude's Discretion

- SVG child count threshold for "non-blank" detection (default: 3, documented in code)
- Settle interval after page load in chromote
- Chromote session setup for `file://` URL loading

## Deferred Ideas

- Interactivity article capture (gg2d3-interactivity.html) — future if needed
- Full perceptual-diff thresholds across browser matrix — FUT-01
- Pixel-brightness blank detection — considered, rejected in favor of DOM-based approach
- External uptime/freshness monitoring for public pkgdown site — FUT-04
