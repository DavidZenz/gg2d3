---
phase: 60
slug: pkgdown-visual-regression-depth
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-07-24
---

# Phase 60 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | testthat 3.x (R) |
| **Config file** | `tests/testthat.R` |
| **Quick run command** | `GG2D3_BROWSER_VISUAL_SMOKE=true Rscript -e "testthat::test_file('tests/testthat/test-pkgdown-visual.R')"` |
| **Full suite command** | `Rscript -e "devtools::test()"` |
| **Estimated runtime** | ~30–60 seconds (browser launch + page load) |

---

## Sampling Rate

- **After every task commit:** Run quick test file command
- **After every plan wave:** Run `Rscript -e "devtools::test()"`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 60 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 60-01-01 | 01 | 1 | VIS-01 | — | N/A | unit | `Rscript -e "testthat::test_file('tests/testthat/test-pkgdown-visual.R')"` | ❌ W0 | ⬜ pending |
| 60-02-01 | 02 | 2 | VIS-01, VIS-02 | — | N/A | integration | `GG2D3_BROWSER_VISUAL_SMOKE=true Rscript -e "testthat::test_file('tests/testthat/test-pkgdown-visual.R')"` | ❌ W0 | ⬜ pending |
| 60-02-02 | 02 | 2 | VIS-02 | — | N/A | integration | same as above | ❌ W0 | ⬜ pending |
| 60-03-01 | 03 | 3 | VIS-03 | — | N/A | manual | Review docs + run capture locally | N/A | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `tests/testthat/test-pkgdown-visual.R` — stub with skip guard for Phase 60 capture tests
- [ ] `tests/testthat/helper-browser-visual.R` — already exists; verify `pkgdown_visual_artifact_dir()` helper added

*Existing `helper-browser-visual.R` and `helper-pkgdown-site.R` infrastructure covers most requirements.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| CI artifact upload produces accessible artifact | VIS-03 | Requires a real GitHub Actions run | Push to PR, check pkgdown.yaml workflow run, verify artifact named `pkgdown-visual-*` is uploaded |
| PNG screenshot is visually meaningful | VIS-03 | Pixel content review | After capture, open `test_output/pkgdown-visual/*.png` and confirm chart SVG content is visible |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
