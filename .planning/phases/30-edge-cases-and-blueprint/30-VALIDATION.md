---
phase: 30
slug: edge-cases-and-blueprint
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-20
---

# Phase 30 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Shell grep checks for docs-only deliverable |
| **Config file** | none |
| **Quick run command** | `rtk rg -F 'BLPR-01' .planning/phases/30-edge-cases-and-blueprint/30-EDGE-CASE-BLUEPRINT.md` |
| **Full suite command** | `rtk rg -F 'Mixed geometry types' .planning/phases/30-edge-cases-and-blueprint/30-EDGE-CASE-BLUEPRINT.md && rtk rg -F 'tile basemaps' .planning/phases/30-edge-cases-and-blueprint/30-EDGE-CASE-BLUEPRINT.md && rtk rg -F 'Future Build Roadmap' .planning/phases/30-edge-cases-and-blueprint/30-EDGE-CASE-BLUEPRINT.md` |
| **Estimated runtime** | ~1 second |

---

## Sampling Rate

- **After every task commit:** Run the task-specific grep checks in `30-01-PLAN.md`
- **After every plan wave:** Run the full suite command above
- **Before `$gsd-verify-work`:** Full document coverage checks must be green
- **Max feedback latency:** 5 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 30-01-01 | 01 | 1 | BLPR-01 | T-30-01 | Edge-case handling is explicit and non-polygon behavior is not silently implied | docs-grep | `rtk rg -F 'Mixed geometry types' .planning/phases/30-edge-cases-and-blueprint/30-EDGE-CASE-BLUEPRINT.md` | yes | pending |
| 30-01-02 | 01 | 1 | BLPR-02 | T-30-02 | Anti-features include rationale and revisit conditions | docs-grep | `rtk rg -F 'tile basemaps' .planning/phases/30-edge-cases-and-blueprint/30-EDGE-CASE-BLUEPRINT.md && rtk rg -F 'Revisit condition' .planning/phases/30-edge-cases-and-blueprint/30-EDGE-CASE-BLUEPRINT.md` | yes | pending |
| 30-01-03 | 01 | 1 | BLPR-03 | T-30-03 | Future build work names file targets and validation gates | docs-grep | `rtk rg -F 'Future Build Roadmap' .planning/phases/30-edge-cases-and-blueprint/30-EDGE-CASE-BLUEPRINT.md && rtk rg -F 'R/as_d3_ir.R' .planning/phases/30-edge-cases-and-blueprint/30-EDGE-CASE-BLUEPRINT.md` | yes | pending |

*Status: pending until execution creates the blueprint.*

---

## Wave 0 Requirements

Existing documentation checks cover this phase. No test framework setup is required.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Future visual gates are sufficiently concrete | BLPR-03 | Future visual/browser comparisons cannot run before production sf implementation exists | Read the `Future Build Roadmap` section and confirm each future build phase includes at least one visual/manual validation gate where visual fidelity matters. |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 5s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending execution
