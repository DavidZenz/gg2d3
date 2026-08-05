---
phase: 59-release-hygiene-and-local-spatial-recovery
status: verified
threats_open: 0
asvs_level: 1
created: 2026-08-05
---

# Phase 59 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Workflow source -> GitHub-hosted runner | Action versions and runner selection determine whether release workflows execute. | YAML workflow instructions |
| Workflow artifact upload -> release evidence | Artifact names and paths must remain stable for inspection and publication. | Generated site, visual artifacts, metadata |
| Local R library -> package validation | Optional spatial packages may fail before gg2d3 code runs. | Package load status and external library diagnostics |
| Diagnostic output -> maintainer decision | Stable markers must distinguish local repair from a package regression. | Load errors, site outcome, recommendation |
| Evidence ledger -> release-readiness claim | Remote workflow state and local command results must be represented accurately. | Commands, run IDs, SHAs, conclusions, classifications |

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-59-01 | Denial of Service | `actions/upload-artifact@v6` runner requirement | high | mitigate | Both workflows use `ubuntu-latest`, `actions/checkout@v6`, and `actions/upload-artifact@v6`; official tag verification is recorded in `59-ACTIONS-ADVISORY.md`. | closed |
| T-59-02 | Repudiation | advisory classification | medium | mitigate | Advisory records the current source outcome and next remote evidence step. | closed |
| T-59-03 | Tampering/Repudiation | artifact upload paths | medium | mitigate | Artifact names, paths, retention, and `if-no-files-found` behavior are preserved in both workflows. | closed |
| T-59-04 | Repudiation | local spatial classification | medium | mitigate | Diagnostic markers and classification semantics are implemented in the script and diagnostics vignette. | closed |
| T-59-05 | Denial of Service | broken local `sf` load | medium | mitigate | Quiet namespace loading and `tryCatch()` guards prevent a dynamic-library error from aborting diagnostics. | closed |
| T-59-06 | Tampering/Repudiation | stale README pointer | low | mitigate | Both `README.Rmd` and `README.md` point to the diagnostic command and vignette. | closed |
| T-59-07 | Repudiation | final verification ledger | high | mitigate | Ledger records exact commands, run IDs, head SHAs, conclusions, classifications, and residual risks. | closed |
| T-59-08 | Information Disclosure | raw workflow/browser logs | medium | mitigate | Evidence is summarized and the raw-log leakage scan passed. | closed |
| T-59-09 | Repudiation | remote workflow blocker | high | mitigate | The ahead-of-origin state and pre-correction remote runs are explicitly recorded as partial/blocked, never as current-SHA passed evidence. | closed |

*Status: open · closed · open — below high threshold (non-blocking)*
*Severity: critical > high > medium > low — only open threats at or above workflow.security_block_on count toward threats_open*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

## Accepted Risks Log

No accepted risks.

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-08-05 | 9 | 5 | 4 | gsd-security-auditor (initial audit) |
| 2026-08-05 | 9 | 9 | 0 | gsd-security-auditor (re-audit) |

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-08-05
