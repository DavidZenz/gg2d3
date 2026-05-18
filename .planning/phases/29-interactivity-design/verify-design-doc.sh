#!/usr/bin/env bash
# Phase 29 design-doc verifier — checks every locked decision D-01..D-11 from
# CONTEXT.md has a dedicated section in the design doc, plus that the
# data-centroid vs data-cx/data-cy inconsistency is explicitly resolved.
set -u

DOC=".planning/phases/29-interactivity-design/29-01-SF-INTERACTIVITY-DESIGN.md"
fail=0

check() {
  local pattern="$1"
  local label="$2"
  if grep -qE "$pattern" "$DOC"; then
    echo "OK   $label"
  else
    echo "MISS $label  (pattern: $pattern)"
    fail=1
  fi
}

if [ ! -f "$DOC" ]; then
  echo "FATAL: $DOC not found"
  exit 2
fi

# Each D-NN must have a dedicated section heading.
check '^### D-01[^0-9]' 'D-01 section (default tooltip label rule)'
check '^### D-02[^0-9]' 'D-02 section (path data attributes spec)'
check '^### D-03[^0-9]' 'D-03 section (registry-entry integration)'
check '^### D-04[^0-9]' 'D-04 section (no JSON attribute embedding)'
check '^### D-05[^0-9]' 'D-05 section (centroid-only brush algorithm)'
check '^### D-06[^0-9]' 'D-06 section (polygon hit-test rejection)'
check '^### D-07[^0-9]' 'D-07 section (centroid limitation)'
check '^### D-08[^0-9]' 'D-08 section (SVG group transform zoom)'
check '^### D-09[^0-9]' 'D-09 section (vector-effect non-scaling-stroke)'
check '^### D-10[^0-9]' 'D-10 section (divergence from zoom.js pattern)'
check '^### D-11[^0-9]' 'D-11 section (zoom event integration)'

# Top-level requirement sections.
check '^## .*INTR-01' 'INTR-01 (Tooltip/Hover) top-level section'
check '^## .*INTR-02' 'INTR-02 (Brush) top-level section'
check '^## .*INTR-03' 'INTR-03 (Zoom) top-level section'

# Critical Inconsistency resolution must be present and pick one option.
check 'Critical Inconsistency|data-centroid vs data-cx' 'Critical Inconsistency resolution section'
check 'data-centroid' 'data-centroid attribute mentioned'
check 'data-cx' 'data-cx attribute mentioned (acknowledged)'

# INTR-02 must contain the comparison matrix dimensions.
check '[Cc]entroid.*[Pp]olygon|[Pp]olygon.*[Cc]entroid' 'Centroid vs polygon comparison'
check '[Mm]emory' 'Comparison includes memory dimension'
check '[Cc]ompute|[Pp]erformance|60fps' 'Comparison includes compute/perf dimension'

# INTR-03 must spec vector-effect as presentation attribute (per pitfall 3).
check 'vector-effect="non-scaling-stroke"|vector-effect.*non-scaling-stroke' 'vector-effect non-scaling-stroke specified'
check '[Pp]resentation attribute' 'vector-effect described as presentation attribute (not CSS)'
check 'sf-zoom-layer' 'sf-zoom-layer group class specified'

# Build-phase migration task named.
check 'IMPL-04|build phase' 'Build-phase implementation referenced'

if [ "$fail" -ne 0 ]; then
  echo ""
  echo "FAIL: design doc is missing required sections."
  exit 1
fi

echo ""
echo "PASS: all D-01..D-11 and structural requirements present."
exit 0
