---
phase: 29
slug: interactivity-design
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-19
---

# Phase 29 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Document structure checks via shell grep/test |
| **Config file** | none |
| **Quick run command** | `test -f .planning/phases/29-interactivity-design/29-INTERACTIVITY-DESIGN.md` |
| **Full suite command** | `grep -E "INTR-01|INTR-02|INTR-03|path\\.geom-sf|data-cx|data-cy|data-row-id|d3_zoom\\(\\)" .planning/phases/29-interactivity-design/29-INTERACTIVITY-DESIGN.md` |
| **Estimated runtime** | ~1 second |

---

## Sampling Rate

- **After every task commit:** Run the quick file-existence check.
- **After every plan wave:** Run the full grep coverage check.
- **Before `$gsd-verify-work`:** Full coverage check must be green.
- **Max feedback latency:** 1 second

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 29-01-01 | 01 | 1 | INTR-01 | — | N/A | docs | `grep -E "INTR-01|d3_tooltip\\(\\)|d3_hover\\(\\)|path\\.geom-sf|data-row-id" .planning/phases/29-interactivity-design/29-INTERACTIVITY-DESIGN.md` | ✅ W0 | ⬜ pending |
| 29-01-02 | 01 | 1 | INTR-02 | — | N/A | docs | `grep -E "INTR-02|centroid|polygon|data-cx|data-cy" .planning/phases/29-interactivity-design/29-INTERACTIVITY-DESIGN.md` | ✅ W0 | ⬜ pending |
| 29-01-03 | 01 | 1 | INTR-03 | — | N/A | docs | `grep -E "INTR-03|d3_zoom\\(\\)|R/d3_zoom\\.R|projection|re-render|SVG group transform" .planning/phases/29-interactivity-design/29-INTERACTIVITY-DESIGN.md` | ✅ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing shell tools cover all phase requirements. No test framework setup is required for this documentation phase.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Design judgment is implementation-ready | INTR-01, INTR-02, INTR-03 | Automated grep can prove coverage, but not whether future agents can act without new decisions | Read `29-INTERACTIVITY-DESIGN.md` and confirm each section names exact future code hooks, chosen behavior, rejected alternatives, and rationale |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 1s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-05-19
