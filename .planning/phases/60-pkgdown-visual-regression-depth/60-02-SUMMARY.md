---
phase: 60-pkgdown-visual-regression-depth
plan: "02"
subsystem: ci-workflow
tags: [ci, github-actions, pkgdown, chromote, visual-capture, artifact-upload]
status: complete

dependency_graph:
  requires:
    - tests/testthat/test-pkgdown-visual.R (Plan 01 — the test the capture step invokes)
    - .github/workflows/pkgdown.yaml (existing workflow being modified)
  provides:
    - .github/workflows/pkgdown.yaml (modified: chromote install + 3 new steps)
    - pkgdown-visual-<run_id> CI artifact (PNG + DOM summary + browser log, uploaded on every run)
  affects:
    - pkgdown CI pipeline (adds chromote dependency and visual capture gate)

tech_stack:
  added:
    - any::chromote (added to extra-packages in setup-r-dependencies)
  patterns:
    - Non-fatal Chrome discovery (exits 0 when browser absent so test skips rather than blocking workflow)
    - Step-scoped CI escalation (GG2D3_BROWSER_VISUAL_CI only on the capture step's env block)
    - Artifact retention with if-always() guard (evidence survives step failure)

key_files:
  created: []
  modified:
    - .github/workflows/pkgdown.yaml

decisions:
  - "Locate Chrome exits 0 (non-fatal) when no browser found so a missing runner browser degrades to a test skip, not a workflow blocker (RESEARCH Pattern 5 / T-60-06)"
  - "GG2D3_BROWSER_VISUAL_CI=true is scoped to the capture step env block only — never added to job-level env (threat T-60-05 mitigated)"
  - "chromote added to extra-packages via any::chromote alongside existing any::pkgdown (RESEARCH Pitfall 6)"
  - "Three steps inserted after Validate pkgdown site and before Upload pkgdown site artifact so docs/articles/gg2d3.html exists when capture runs (RESEARCH Pitfall 1)"

metrics:
  duration: "8m"
  completed: "2026-07-24"
  tasks_completed: 1
  tasks_total: 1
  files_created: 0
  files_modified: 1
  tests_passing: 0
---

# Phase 60 Plan 02: pkgdown.yaml CI Integration Summary

**One-liner:** Added chromote install, non-fatal Chrome discovery, step-scoped CI escalation, and artifact upload to pkgdown.yaml so browser visual evidence is captured on every pkgdown CI build.

## What Was Built

Modified `.github/workflows/pkgdown.yaml` with four targeted changes:

1. **chromote installation:** Changed `extra-packages: any::pkgdown, local::.` to `extra-packages: any::pkgdown, any::chromote, local::.` so chromote is available for the capture step.

2. **Locate Chrome for chromote (pkgdown visual):** A non-fatal bash step that loops over `google-chrome google-chrome-stable chromium chromium-browser`, writes `CHROMOTE_CHROME=<path>` to `GITHUB_ENV` on the first hit, then `exit 0`. When no browser is found it echoes a message and exits 0 (unlike the analog in `browser-visual-smoke.yaml` which exits 1) — this lets the test skip via `skip_browser_visual_smoke()` rather than hard-failing the workflow.

3. **Run pkgdown visual capture:** Runs `test-pkgdown-visual.R` (Plan 01) via `pkgload::load_all()` + `testthat::test_file()` with `GG2D3_BROWSER_VISUAL_CI=true` set only on this step's `env:` block — not at the job level. Any test failure exits 1.

4. **Upload pkgdown visual artifacts:** `if: always()` so evidence is uploaded even when the capture step fails; uploads `test_output/pkgdown-visual/` (the PNG + DOM-summary + browser-log written by Plan 01's test) as `pkgdown-visual-${{ github.run_id }}`.

The three new steps are inserted between `Validate generated pkgdown site` and `Upload pkgdown site artifact`, guaranteeing `docs/articles/gg2d3.html` exists before navigation.

## Tasks

| # | Task | Status | Commit |
|---|------|--------|--------|
| 1 | Install chromote and add the three visual-capture steps to pkgdown.yaml | DONE | ff15999 |

## Verification Results

**YAML validation:** `python3 -c "import yaml; yaml.safe_load(open('.github/workflows/pkgdown.yaml'))"` — no parse errors.

**Automated assertion script (from plan `<verify>`):**
```
OK
Step ordering: validate(6) -> locate(7) -> run(8) -> upload-vis(9) -> upload-site(10)
extra-packages: any::pkgdown, any::chromote, local::.
capture step env: {'NOT_CRAN': 'true', 'GG2D3_BROWSER_VISUAL_SMOKE': 'true', 'GG2D3_BROWSER_VISUAL_CI': 'true'}
job-level env: {'GITHUB_PAT': '${{ secrets.GITHUB_TOKEN }}'}
```

## Acceptance Criteria Verification

| Criterion | Result |
|-----------|--------|
| `extra-packages` contains `any::chromote` | PASS |
| Step named `Run pkgdown visual capture` references `test-pkgdown-visual.R` | PASS |
| Step named `Upload pkgdown visual artifacts` with `path: test_output/pkgdown-visual/` | PASS |
| Capture step `env.GG2D3_BROWSER_VISUAL_CI == "true"` | PASS |
| Job-level `env` does NOT contain `GG2D3_BROWSER_VISUAL_CI` | PASS |
| Locate Chrome is non-fatal (exits 0 when browser absent) | PASS |
| Three new steps after `Validate generated pkgdown site` and before `Upload pkgdown site artifact` | PASS |
| Valid YAML | PASS |
| No new `.github/workflows/pkgdown-visual*.yaml` file created | PASS |

## Deviations from Plan

None — plan executed exactly as written. The PATTERNS.md Locate Chrome step YAML was followed precisely (including the non-fatal exit 0 variant, which differs from the browser-visual-smoke.yaml analog that exits 1).

## Known Stubs

None. All four changes are fully wired to functional steps.

## Threat Flags

None. No new external network surfaces introduced. The workflow reuses the already-vetted `actions/upload-artifact@v6` action already present in the file. chromote is an existing CRAN Suggests dependency (T-60-04 accepted). `GG2D3_BROWSER_VISUAL_CI` is step-scoped (T-60-05 mitigated). Locate Chrome exits 0 when browser absent (T-60-06 accepted).

## Self-Check: PASSED

| Item | Status |
|------|--------|
| `.github/workflows/pkgdown.yaml` exists with 3 new steps | FOUND |
| `60-02-SUMMARY.md` exists | FOUND |
| Commit `ff15999` exists | FOUND |
