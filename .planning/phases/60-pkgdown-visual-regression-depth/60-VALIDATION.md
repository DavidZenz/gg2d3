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
| **Quick run command** | `GG2D3_BROWSER_VISUAL_SMOKE=true rtk Rscript -e "testthat::test_file('tests/testthat/test-pkgdown-visual.R')"` |
| **Full suite command** | `rtk Rscript -e "devtools::test()"` |
| **Estimated runtime** | ~30–60 seconds (browser launch + page load) |

---

## Sampling Rate

- **After every task commit:** Run quick test file command
- **After every plan wave:** Run `rtk Rscript -e "devtools::test()"`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 60 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 60-01-01 | 01 | 1 | VIS-01 | — | N/A | unit | `rtk Rscript -e "testthat::test_file('tests/testthat/test-pkgdown-visual.R')"` | ✅ present | ⬜ pending |
| 60-02-01 | 02 | 2 | VIS-01, VIS-02 | — | N/A | integration | `GG2D3_BROWSER_VISUAL_SMOKE=true rtk Rscript -e "testthat::test_file('tests/testthat/test-pkgdown-visual.R')"` | ✅ present | ⬜ pending |
| 60-03-01 | 03 | 3 | VIS-03 | — | N/A | manual | Review docs + run capture locally | ✅ present | ⬜ pending |
| 60-03-02 | 03 | 3 | VIS-03 | T-60-07 | Human validation of capture/docs/CI evidence | checkpoint | `rtk Rscript --vanilla -e "...test_file('tests/testthat/test-pkgdown-site.R')..."` plus human full-page PNG/skip review | ✅ present | ⬜ pending |
| 60-04-01 | 04 | 2 | VIS-01, VIS-02, VIS-03 | T-60-04-GAP-01 | Named region, marker, payload, and blank-widget checks | integration | `NOT_CRAN=true GG2D3_BROWSER_VISUAL_SMOKE=true rtk Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); res <- testthat::test_file("tests/testthat/test-pkgdown-visual.R"); df <- as.data.frame(res); if (any(df$failed > 0) || any(df$error)) quit(status = 1)'` | ✅ present | ⬜ pending |
| 60-05-01 | 05 | 3 | VIS-03 | T-60-05-GAP-01 | Four-candidate Chrome discovery and scoped CI escalation | workflow | `rtk python3 -c 'import yaml; yaml.safe_load(open(".github/workflows/pkgdown.yaml")); print("YAML_OK")'` | ✅ present | ⬜ pending |
| 60-05-02 | 05 | 3 | VIS-03 | T-60-05-GAP-03 | Local/CI runbook and bounded evidence claims | docs | `rtk python3 -c 'from pathlib import Path; text=Path("vignettes/d3-drawing-diagnostics.md").read_text(); assert "google-chrome-stable" in text and "google-chrome" in text and "chromium-browser" in text and "chromium" in text; print("DOC_CANDIDATES_OK")'` | ✅ present | ⬜ pending |
| 60-06-01 | 06 | 4 | VIS-03 | T-60-06-GAP-01 | Source-first README pointer and generated output | docs | `rtk python3 -c 'from pathlib import Path; s=Path("README.Rmd").read_text(); o=Path("README.md").read_text(); required=["pkgdown visual regression","test_output/pkgdown-visual","d3-drawing-diagnostics.md"]; assert all(x in s and x in o for x in required); print("README_POINTER_OK")'` | ✅ present | ⬜ pending |
| 60-06-02 | 06 | 4 | VIS-01, VIS-03 | T-60-06-GAP-02 | Browser/CI/public-site evidence checkpoint with static guard | checkpoint | `rtk Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); res <- testthat::test_file("tests/testthat/test-pkgdown-site.R"); df <- as.data.frame(res); if (any(df$failed > 0) || any(df$error)) quit(status = 1)'` | ✅ present | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `tests/testthat/test-pkgdown-visual.R` — existing capture test from completed Plans 01–04; gap closure extends its assertions
- [x] `tests/testthat/helper-browser-visual.R` — existing shared helper remains the source of opt-in/Chrome behavior

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

The validation strategy remains `status: draft` and `nyquist_compliant: false` until the gap-closure plans execute and `/gsd-validate-phase` records the resulting evidence.
