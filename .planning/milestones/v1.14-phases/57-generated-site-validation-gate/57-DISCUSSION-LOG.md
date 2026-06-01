# Phase 57: Generated Site Validation Gate - Discussion Log

> Audit trail only. Binding decisions are recorded in `57-CONTEXT.md`.

**Date:** 2026-06-01T05:44:46Z
**Phase:** 57-generated-site-validation-gate
**Areas discussed:** Gate Shape, Rebuild Policy, Failure Output, Optional sf Classification

## Gate Shape

| Option | Description | Selected |
| --- | --- | --- |
| Testthat only | Keep all validation in the existing focused generated-site tests. | |
| Dedicated command only | Move the gate into a maintainer script without canonical test integration. | |
| Both | Keep `testthat` assertions canonical and add a thin maintainer-facing command/script around them. | yes |

User choice: recommendations accepted.

Notes: Canonical logic stays in tests; the command improves ergonomics for local/release use.

## Rebuild Policy

| Option | Description | Selected |
| --- | --- | --- |
| Inspect committed docs only | Fast validation of current generated files. | |
| Always rebuild | Regenerate docs and pkgdown every time the gate runs. | |
| Two modes | Quick mode inspects committed `docs/`; release mode rebuilds before inspection. | yes |

User choice: recommendations accepted.

Notes: Two modes keep ordinary validation fast while preserving a stronger release check.

## Failure Output

| Option | Description | Selected |
| --- | --- | --- |
| Marker-specific test failures | Fail with exact file/path and marker/asset messages. | yes |
| Dedicated report | Emit a separate generated report after validation. | conditional |
| CI annotations/artifacts | Push failure details into CI-specific reporting. | |

User choice: recommendations accepted.

Notes: Prefer concise `testthat` failures. A small report is allowed only if it improves diagnosis without new artifact sprawl.

## Optional sf Classification

| Option | Description | Selected |
| --- | --- | --- |
| Always allow skip | Treat `PKGDOWN_SF_OPTIONAL_SKIP` as valid in all environments. | |
| Always require rendered sf | Fail whenever sf widget evidence is absent. | |
| Local skip, CI render when dependencies load | Accept visible local skip; require rendered sf when `sf`/`geojsonsf` are loadable in CI/release mode. | yes |

User choice: recommendations accepted.

Notes: Dependency setup failures must be classified separately from stale-site or generated-content failures.

## Agent Discretion

- Planner may choose the wrapper name/location and exact implementation shape.
- Planner may refactor existing test helpers if that keeps the assertions reusable and clearer.
- Planner may add minimal report wording if it materially improves failure diagnosis.

## Deferred Ideas

- Phase 58 deploy artifact inspection.
- Public pull-request preview links.
- Screenshot, pixel, or perceptual regression gates for pkgdown pages.
- External uptime/freshness monitoring.
