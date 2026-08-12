---
schema_version: 1
open_count: 1
waived_count: 0
fixed_count: 0
total_count: 1
last_updated: 2026-08-12T10:22:13.778Z
---

# Broken Windows Ledger

> Cross-phase defect register. `/gsd-ship` blocks while `open_count > 0`.
> Waive with `gsd-tools windows waive <id> "<reason>"` (reason required).
> Mark fixed with `gsd-tools windows fixed <id>`.

| id | phase | kind | file | line | description | status | reason | recorded_at | resolved_at |
|----|-------|------|------|------|-------------|--------|--------|-------------|-------------|
| 1 | 60 | unrun-verify | tests/testthat/test-pkgdown-visual.R | 250 | Rendered browser capture and PNG/JSON artifact verification were not run because local Chrome/chromote was unavailable; opt-in test skipped before artifact read. | open |  | 2026-08-12T10:22:13.778Z |  |

````json
[
  {
    "id": 1,
    "kind": "unrun-verify",
    "phase": "60",
    "file": "tests/testthat/test-pkgdown-visual.R",
    "line": 250,
    "description": "Rendered browser capture and PNG/JSON artifact verification were not run because local Chrome/chromote was unavailable; opt-in test skipped before artifact read.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-12T10:22:13.778Z",
    "resolved_at": null
  }
]
````
