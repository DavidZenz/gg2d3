# Phase 41 Debt Audit

## Audit Schema

Each item is tracked with these fields: `Item`, `Requirement`, `Evidence`, `Status`, `Release-blocking judgment`, `Action`, `Rationale`, and `Next step`.

## DEBT-01 Advisory Follow-ups

| Item | Requirement | Evidence | Status | Release-blocking judgment | Action | Rationale | Next step |
|------|-------------|----------|--------|---------------------------|--------|-----------|-----------|
| pkgload direct declaration | DEBT-01 | `DESCRIPTION` Suggests contains `pkgload`; `dependency advisory resolved` command passed | Resolved | Not blocking | No code change required | DESCRIPTION Suggests declares the direct helper dependency. | Keep covered by Phase 42 package checks. |
| rprojroot direct declaration | DEBT-01 | `DESCRIPTION` Suggests contains `rprojroot`; `dependency advisory resolved` command passed | Resolved | Not blocking | No code change required | DESCRIPTION Suggests declares the direct helper dependency. | Keep covered by Phase 42 package checks. |
| facet panel identity assertions | DEBT-01 | `test-sf-browser.R` keeps ordered facet vectors `c(1L, 1L)` and `c(1L, 0L, 0L, 1L)` and compares `panel_counts` directly; `facet identity assertion ok` command passed | Resolved | Not blocking | No code change required | BRSF-02 preserves panel-order identity rather than sorted count distribution. | Keep covered by browser smoke source checks. |

## DEBT-02 Renderer and Documentation Debt

Pending Phase 41 plan 02.

## Verification Evidence

Pending verification.
