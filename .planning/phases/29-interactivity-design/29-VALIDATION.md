---
phase: 29
slug: interactivity-design
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-18
---

# Phase 29 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> **Note:** Phase 29 is a design/documentation-only phase. Validation focuses on document completeness and structural correctness, not code tests.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | grep / file-existence checks (no test framework — design phase) |
| **Config file** | none |
| **Quick run command** | `test -f .planning/phases/29-interactivity-design/29-01-SF-INTERACTIVITY-DESIGN.md` |
| **Full suite command** | `bash .planning/phases/29-interactivity-design/verify-design-doc.sh` (created in Wave 0) |
| **Estimated runtime** | <5 seconds |

---

## Sampling Rate

- **After every task commit:** Run quick existence check on the design doc
- **After every plan wave:** Run the full design-doc verification script (grep for each D-01..D-11 section heading)
- **Before `/gsd-verify-work`:** Full suite must confirm every locked decision has a documented section
- **Max feedback latency:** 5 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 29-01-01 | 01 | 0 | — | — | N/A | infra | `test -x .planning/phases/29-interactivity-design/verify-design-doc.sh` | ❌ W0 | ⬜ pending |
| 29-01-02 | 01 | 1 | INTR-01 | — | N/A | doc-grep | `grep -E "^## .*(Tooltip\|Hover)" 29-01-SF-INTERACTIVITY-DESIGN.md` | ❌ W0 | ⬜ pending |
| 29-01-03 | 01 | 1 | INTR-02 | — | N/A | doc-grep | `grep -E "^## .*Brush" 29-01-SF-INTERACTIVITY-DESIGN.md` | ❌ W0 | ⬜ pending |
| 29-01-04 | 01 | 1 | INTR-03 | — | N/A | doc-grep | `grep -E "^## .*Zoom" 29-01-SF-INTERACTIVITY-DESIGN.md` | ❌ W0 | ⬜ pending |
| 29-01-05 | 01 | 2 | INTR-01..03 | — | N/A | doc-grep | `bash verify-design-doc.sh` (checks all D-01..D-11 sections) | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `.planning/phases/29-interactivity-design/verify-design-doc.sh` — grep script verifying each D-01..D-11 has a corresponding `## ` section in the design doc, plus presence of the data-attribute decision (data-centroid vs data-cx/data-cy resolution)

*This phase produces a single Markdown design document; no code framework needed.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Design doc clarity sufficient for a build phase to proceed without further decisions | INTR-01..03 | Subjective completeness check — only a human reviewer can confirm "no ambiguity remains" | Read 29-01-SF-INTERACTIVITY-DESIGN.md end-to-end and confirm a developer could implement each of the 3 capabilities without revisiting design |
| Decision rationale for `data-centroid` vs `data-cx`/`data-cy` is explicit and chosen | INTR-02 | Requires judgment that rationale matches Phase 28 reality (sf.js currently writes `data-cx`/`data-cy`) | Confirm the doc references the inconsistency surfaced in RESEARCH.md and explicitly picks one with a follow-up task noted |
| Comparison of centroid-based vs polygon hit-testing has clear recommendation + rationale | INTR-02 | Subjective sufficiency | Read the comparison section; verify both options analyzed, one recommended, other rejected with reason |
| Zoom architecture decision is concrete OR explicitly deferred with rationale | INTR-03 | Decision quality is a judgment call | Read the zoom section; confirm either a concrete approach with stroke-width tradeoff documented, or an explicit deferral statement |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 5s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
