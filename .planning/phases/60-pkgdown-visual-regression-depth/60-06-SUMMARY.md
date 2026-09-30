---
phase: 60-pkgdown-visual-regression-depth
plan: "06"
subsystem: documentation/testing
tags: [pkgdown, browser-visual, chromote, sf, crosstalk, README, UAT]

# Dependency graph
requires:
  - phase: 60-pkgdown-visual-regression-depth
    provides: Named pkgdown visual regions, live-payload checks, CI capture wiring, and maintainer runbook
  - phase: 60-pkgdown-visual-regression-depth
    provides: Source-first README evidence pointer
provides:
  - Approved browser, CI, screenshot, DOM, and generated-public-site evidence for the Phase 60 gap closure
  - Completed UAT record for the pkgdown visual regression checkpoint
affects: [VIS-01, VIS-02, VIS-03, Phase 61]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Human browser evidence is recorded with the exact cache-busted URL and observed tooltip values.
    - Historical or unavailable local capture artifacts are separated from current CI and browser evidence.
    - Generated-site assertions remain the publication boundary for keeping maintainer diagnostics internal.

key-files:
  created:
    - .planning/phases/60-pkgdown-visual-regression-depth/60-06-SUMMARY.md
  modified:
    - README.Rmd
    - README.md
    - .planning/phases/60-pkgdown-visual-regression-depth/60-UAT.md

key-decisions:
  - "Accept the approved cache-busted in-app browser review as the current visual sign-off: all representative plots/checks passed and the sf tooltip showed NAME: Ashe and AREA: 0.114."
  - "Treat the local Chromote unavailable-browser result as an environment classification, not a product failure; do not use the retained July local artifacts as fresh proof."
  - "Use CI run 30992820343 for the successful DOM/artifact evidence and retain the workflow conclusion that Chrome discovery is non-fatal while the capture step owns CI escalation."
  - "Keep d3-drawing-diagnostics maintainer-only: the generated public site and navbar must omit the diagnostics article while the README pointer remains source documentation."

patterns-established:
  - "Evidence records distinguish manual visual approval, generated-site assertions, CI DOM summaries, and artifact freshness caveats."

requirements-completed: [VIS-01, VIS-02, VIS-03]

coverage:
  - id: D1
    description: "README source/output pointer and public documentation boundary are synchronized."
    requirement: VIS-03
    verification:
      - kind: other
        ref: "README_PUBLIC_SCOPE_OK plus README.Rmd/README.md marker checks"
        status: pass
    human_judgment: false
  - id: D2
    description: "The generated pkgdown site validates current sf, Crosstalk, tooltip payload, and diagnostics-publication behavior."
    requirement: VIS-01
    verification:
      - kind: integration
        ref: "tests/testthat/test-pkgdown-site.R: 80 passing assertions"
        status: pass
      - kind: other
        ref: "SF_OUTCOME=rendered; SF_INTERACTIVITY=interactive; CROSSTALK_OUTCOME=rendered; DIAGNOSTICS_ARTICLE_PRESENT=FALSE"
        status: pass
    human_judgment: false
  - id: D3
    description: "Browser and CI evidence confirms rendered core, sf, and Crosstalk regions and records the approved visual review."
    requirement: VIS-02
    verification:
      - kind: e2e
        ref: "GitHub Actions run 30992820343 DOM summary and uploaded visual artifacts"
        status: pass
      - kind: automated_ui
        ref: "http://127.0.0.1:8765/articles/gg2d3.html?nocache=20260930-2005#sf-family-maps-with-geom_sf"
        status: pass
    human_judgment: true
    rationale: "Screenshot appearance, tooltip content, and interaction checks require a human browser review; the user explicitly approved this checkpoint."

# Metrics
duration: 15m
completed: 2026-09-30
status: complete
---

# Phase 60 Plan 06: README Pointer and Browser/Public-Site Closure Summary

**The Phase 60 README gap is closed and the browser, CI, generated-site, and public diagnostics-scope checkpoint is approved with exact evidence and environment caveats recorded.**

## Performance

- **Duration:** 15 min
- **Started:** 2026-09-30T18:05:00Z (continuation after the human checkpoint)
- **Completed:** 2026-09-30
- **Tasks:** 2 completed across the plan; Task 2 resumed and closed in this continuation
- **Files modified by this continuation:** 1 UAT record, 1 summary, plus GSD state metadata below

## Accomplishments

- Preserved the source-first README pointer from Task 1 (`7c411b6`) and verified its scoped markers in both `README.Rmd` and generated `README.md` without adding a public diagnostics article or navbar entry.
- Re-ran the focused generated-site test: `test-pkgdown-site.R` finished with `[ FAIL 0 | WARN 0 | SKIP 0 | PASS 80 ] Done!`.
- Closed the human checkpoint after the cache-busted in-app browser review. The user replied `perfect, pass`; all other plots/checks were approved, and the sf tooltip visibly read `NAME: Ashe` and `AREA: 0.114`.
- Recorded successful CI DOM/artifact evidence, workflow semantics, generated-site outcomes, public-site diagnostics exclusion, and local environment limitations in the UAT and this summary.

## Validation Evidence

### Local focused generated-site validation

Command:

```text
rtk Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE); res <- testthat::test_file("tests/testthat/test-pkgdown-site.R"); df <- as.data.frame(res); if (any(df$failed > 0) || any(df$error)) quit(status=1)'
```

Result: **80 passing assertions, 0 failures, 0 warnings, 0 skips**.

The generated-site helper classifications were:

```text
SF_OUTCOME=rendered
SF_INTERACTIVITY=interactive
CROSSTALK_OUTCOME=rendered
DIAGNOSTICS_ARTICLE_PRESENT=FALSE
ARTICLE_PRESENT=TRUE
```

The README/public-scope check printed `README_PUBLIC_SCOPE_OK`. It confirmed the README source/output marker set, the current SF and Crosstalk headings, the source payload fields `NAME=Ashe` and `AREA=0.114`, and the absence of `d3-drawing-diagnostics` in generated/public pkgdown configuration and article paths. The workflow structure check printed `PKGDOWN_WORKFLOW_SCOPE_OK`.

### Human browser review

The approved cache-busted in-app browser URL was:

```text
http://127.0.0.1:8765/articles/gg2d3.html?nocache=20260930-2005#sf-family-maps-with-geom_sf
```

The human review found the article rendered rather than blank, approved the other plots and checks, and hovered the SF map successfully. The visible tooltip values were exactly:

```text
NAME: Ashe
AREA: 0.114
```

The user response was `perfect, pass`, which closes the blocking human-verify checkpoint. This was a visual/browser review in the in-app browser; it was not fabricated from a stale local PNG.

### CI visual and workflow evidence

The successful pkgdown workflow run `30992820343` completed visual capture, artifact upload, and Pages deployment. Its downloaded DOM summary is:

```text
test_output/github-run-30992820343/pkgdown-visual/pkgdown-main-article-dom-summary.json
```

Recorded values:

```text
widgetCount: 49
renderedSvgCount: 49
blankWidgetCount: 0
geomSfCount: 100
crosstalkGroupCount: 2
```

The paired browser log reported `status: "passed"` and `logs: []`. The artifact contained the expected PNG, DOM-summary JSON, and browser-log JSON under `pkgdown-visual/`.

The workflow conclusion remains explicit and scoped: Chrome discovery succeeds non-fatally when no executable is found; `GG2D3_BROWSER_VISUAL_CI=true` is set only on the visual capture step, where an unavailable browser escalates the shared helper skip; and the visual artifact upload uses `if: always()`. The cleanup deployment run `30999489653` also passed through Pages deployment.

### Screenshot and artifact caveat

The current local opt-in browser command was attempted with the generated article present, but Chromote could not launch Chrome and reported `Cannot find an available port`. It exited through the documented local skip path. No current local capture was claimed from that run.

The retained `test_output/pkgdown-visual/` files are older local evidence (`widgetCount: 48`, `renderedSvgCount: 48`, `blankWidgetCount: 0`, `geomSfCount: 0`, `crosstalkGroupCount: 2`, dated 2026-07-24) and were not used as current proof. The downloaded CI PNG from run `30992820343` is `1265 x 885`; its DOM summary predates the later freshness/full-page artifact fields, so it is recorded as successful historical CI evidence rather than claimed as the current D-05 full-page dimension check. The approved cache-busted browser review supplies the current visual sign-off. The existing broken-windows entry for the unavailable rendered-capture environment remains the ledger record; no duplicate entry was added.

## Task Commits

Each task was committed atomically:

1. **Task 1: Restore the source-first README pkgdown visual evidence pointer** - `7c411b6` (`docs`)
2. **Task 2: Validate browser evidence, CI missing-Chrome behavior, and public-site diagnostics scope** - `8a6c1d7` (`docs`)

**Plan metadata:** finalized by the executor's GSD metadata commit after the summary self-check.

## Files Created/Modified

- `README.Rmd` - Authoritative source for the scoped pkgdown visual evidence pointer, committed by Task 1.
- `README.md` - Regenerated output containing the matching pointer and artifact directory, committed by Task 1.
- `.planning/phases/60-pkgdown-visual-regression-depth/60-UAT.md` - Closed the stale partial/blocked UAT record with the approved 5/5 evidence.
- `.planning/phases/60-pkgdown-visual-regression-depth/60-06-SUMMARY.md` - This gap-closure summary.

## Decisions Made

- The explicit human approval closes the browser checkpoint even though the current local Chromote runtime cannot launch Chrome; the local skip remains an environment classification.
- CI run `30992820343` is the retained successful DOM/artifact evidence source, while the current cache-busted browser URL is the source of the human visual and tooltip approval.
- The maintainer diagnostics document remains internal. Generated-site tests and the deployed cleanup conclusion keep its article path and navbar entry absent.
- The current phase claim remains bounded to named DOM/live-payload and browser evidence. It does not imply broad perceptual-diff or pixel-threshold coverage.

## Deviations from Plan

None - plan executed as written. The only continuation change was recording the already-approved checkpoint in the UAT and summary artifacts.

## Issues Encountered

- The first sandboxed staging attempt could not create `.git/index.lock`; the scoped UAT commit succeeded after requesting repository-write permission. No unrelated file was staged.
- Local Chromote/Chrome is unavailable (`Cannot find an available port`), so the local opt-in path is a documented skip. The approved in-app browser review and prior successful CI artifact provide the current runtime evidence.

## Known Stubs

None. No implementation stub or placeholder was introduced, and the internal diagnostics/public-site boundary is intentional.

## Authentication Gates

None encountered during this continuation.

## Threat Flags

None. This plan changes/records documentation and validation evidence only; it introduces no new network endpoint, auth path, file-access boundary, or schema surface.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 60-06 is complete and VIS-01, VIS-02, and VIS-03 are ready to be marked complete in GSD state. Phase 61 may proceed. Local Chrome/chromote availability and the older viewport-sized CI artifact remain documented environment/history caveats for any future fresh D-05 capture; they do not block this approved checkpoint closure.

## Self-Check: PASSED

| Item | Status |
|------|--------|
| Summary file exists | FOUND |
| UAT file exists and records 5/5 passed | FOUND |
| README.Rmd and README.md exist with the scoped pointer | FOUND |
| Task 1 commit `7c411b6` exists | FOUND |
| Task 2 commit `8a6c1d7` exists | FOUND |
| Summary/UAT whitespace checks | PASS |
| Focused generated-site test | PASS: 80 assertions |
| Human browser checkpoint | APPROVED: `perfect, pass` |

---
*Phase: 60-pkgdown-visual-regression-depth*
*Plan: 06*
*Completed: 2026-09-30*
