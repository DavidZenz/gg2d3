---
phase: 58-publication-evidence-and-release-handoff
status: complete
created: 2026-06-01
---

# Phase 58 Pattern Map

## Files To Modify Or Create

| Target | Role | Closest Existing Analog | Notes |
| --- | --- | --- | --- |
| `.github/workflows/pkgdown.yaml` | Upload downloadable pkgdown site artifact after validation and before deploy | `.github/workflows/browser-visual-smoke.yaml` | Reuse `actions/upload-artifact@v4`, run-id artifact naming, and 14-day retention pattern. |
| `tests/testthat/helper-pkgdown-site.R` | Shared validation contract for repo-layout and site-root layouts | Existing Phase 57 helper | Extend the helper so marker lists and sf outcome logic remain canonical. |
| `tests/testthat/test-pkgdown-site.R` | Focused tests for publication/site-root validation helpers | Existing pkgdown focused tests | Add a small site-root validation test against `docs/`, not a new artifact family. |
| `tools/inspect-pkgdown-publication.R` | Maintainer command for downloaded artifacts or `gh-pages` checkout | `tools/validate-pkgdown-site.R` | Source the helper, parse CLI flags, print concise pass/fail outcome. |
| `vignettes/d3-drawing-diagnostics.md` | Maintainer runbook for `gh` trigger/download/deploy inspection | Existing generated-site validation and browser artifact sections | Add publication artifact inspection after the generated-site gate section. |
| `README.Rmd` and `README.md` | Short public pointer to publication inspection runbook | Existing pkgdown validation pointer | Keep concise; rebuild README from source. |
| `NEWS.md` and `docs/news/index.html` | Release messaging/current generated NEWS evidence | Existing v1.14 NEWS bullet | Refine only if needed; avoid implying new rendering support. |
| `.planning/phases/58-publication-evidence-and-release-handoff/58-VERIFICATION.md` | Final release-readiness evidence ledger | `57-VERIFICATION.md` and Phase 55 release evidence | Summarize commands, run IDs, artifact/deploy checks, requirement coverage, and residual risks. |

## Existing Code Patterns

### Workflow Artifact Upload

`browser-visual-smoke.yaml` uses:

```yaml
- name: Upload browser visual smoke artifacts
  if: always()
  uses: actions/upload-artifact@v4
  with:
    name: browser-visual-smoke-${{ github.run_id }}
    path: test_output/browser-visual-smoke/
    if-no-files-found: warn
    retention-days: 14
```

Phase 58 should use the same artifact family but stricter missing-file behavior for pkgdown site output:

```yaml
- name: Upload pkgdown site artifact
  uses: actions/upload-artifact@v4
  with:
    name: pkgdown-site-${{ github.run_id }}
    path: docs/
    if-no-files-found: error
    retention-days: 14
```

Place this after `Validate generated pkgdown site` and before `Deploy to GitHub pages`.

### Existing Pkgdown Validation Helper

`tests/testthat/helper-pkgdown-site.R` has canonical marker vectors:

- `pkgdown_site_generated_article_text_markers`
- `pkgdown_site_generated_widget_markers`
- `pkgdown_site_generated_optional_sf_markers`

It also has `pkgdown_site_sf_outcome(root = ".")`, which currently expects `docs/articles/gg2d3.html` and `docs/articles/gg2d3.md`.

Apply by adding site-root variants or a path-prefix abstraction so both of these layouts work:

- repository layout: `docs/articles/gg2d3.html`;
- downloaded/deploy layout: `articles/gg2d3.html`.

### Maintainer Script Pattern

`tools/validate-pkgdown-site.R` patterns to reuse:

- parse simple `--flag value` arguments;
- locate project root from current working directory;
- `source(file.path(root, "tests", "testthat", "helper-pkgdown-site.R"))`;
- stop with `call. = FALSE`;
- print one final line with mode and sf outcome.

Phase 58 script should print a line shaped like:

```text
Pkgdown publication inspection passed (site root: <site-root>, sf outcome: <rendered|classified_skip>)
```

### Documentation Evidence Pattern

`vignettes/d3-drawing-diagnostics.md` already separates:

- source docs;
- generated `docs/`;
- GitHub Pages/deploy output;
- browser visual smoke artifacts.

Add publication artifact inspection under the pkgdown evidence section, before browser visual smoke artifacts, so the flow reads source -> generated -> workflow artifact/deploy -> browser smoke.

### Verification Ledger Pattern

`57-VERIFICATION.md` is concise and avoids raw logs. Reuse that pattern:

- frontmatter with status/date/outcome;
- command table;
- requirement coverage table;
- threat mitigation table;
- notes/residual risks.

Do not paste raw `gh run view --log`, browser logs, DOM summaries, or `00check.log`.

## Constraints

- Do not replace pkgdown or GitHub Pages.
- Do not add screenshot/perceptual regression checks.
- Do not claim new rendering support.
- Do not commit `test_output/github-run-*` artifacts.
- Classify invalid `gh` auth as setup/manual fallback, not generated-site failure.
