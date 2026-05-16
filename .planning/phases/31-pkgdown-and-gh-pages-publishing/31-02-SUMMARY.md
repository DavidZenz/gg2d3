---
phase: 31
plan: 02
type: execute
wave: 1
status: complete
date: 2026-05-15
---

# Plan 31-02 Summary — Config Changes (Wave 1)

## What landed

1. **Vignette rename** — `vignettes/gg2d3-intro.Rmd` → `vignettes/gg2d3.Rmd` via `git mv` (history preserved). `VignetteIndexEntry{Getting started with gg2d3}` already matched, no in-file edit needed. Stale-reference grep returned zero hits across `*.Rmd`, `*.md`, `*.R`, `*.yml`, `*.yaml` (excluding `.planning/`, `docs/`, `.git/`).

2. **`_pkgdown.yml` rewrite** — replaced the two-line stub (`url: ~`, `template.bootstrap: 5`) with the curated config:
   - `url: https://davidzenz.github.io/gg2d3/` (D-03)
   - `template.bootstrap: 5` (D-08, preserved)
   - `development.mode: release` (D-13)
   - `reference:` with three sections — **Main entry** (`gg2d3`), **Interactivity** (`d3_tooltip`, `d3_hover`, `d3_zoom`, `d3_brush`), **Internals** (`as_d3_ir`, `validate_ir`)
   - No `navbar:` block (D-06 — defaults)
   - No `articles:` block (D-09 — filename auto-promotion handles Get-started)
   - No `news:` block (D-07 — default `NEWS.md` surfacing)
   - YAML parses cleanly; structural assertion via `yaml::read_yaml()` returned `OK`.

3. **`.Rbuildignore` patch** — appended `^\.github$` so the workflow file added in Plan 04 will not enter the CRAN source tarball (T-31-03 mitigation).

4. **`DESCRIPTION` URL field** — extended from one URL to two via `desc::desc()$set_urls()`. Now reads:
   ```
   URL: https://github.com/DavidZenz/gg2d3,
       https://davidzenz.github.io/gg2d3/
   ```
   `BugReports:` and `Authors@R:` untouched.

## Deviations from CONTEXT (applied)

- **D-05 reference list deviation:** CONTEXT listed `d3_crosstalk` as an Interactivity entry. NAMESPACE audit (2026-05-15) shows `d3_crosstalk` is **not exported** — `R/d3_crosstalk.R` defines `@name d3_crosstalk_internal`. Including it would break the pkgdown build with `no man/d3_crosstalk.Rd`. CONTEXT also omitted `as_d3_ir` and `validate_ir`, which **are** exported. Plan 02's `_pkgdown.yml` reflects the audited NAMESPACE:
  ```
  export(as_d3_ir)
  export(d3_brush)
  export(d3_hover)
  export(d3_tooltip)
  export(d3_zoom)
  export(gg2d3)
  export(validate_ir)
  ```
  Resolution: Interactivity = `d3_tooltip`, `d3_hover`, `d3_zoom`, `d3_brush` (no `d3_crosstalk`). New "Internals" section added for `as_d3_ir` + `validate_ir`.

- **D-09 promotion mechanism deviation:** CONTEXT mentioned "naming/role via the `articles:` index or a `getting-started` flag". pkgdown 2.x canonical idiom is filename auto-promotion: a vignette literally named `<pkgname>.Rmd` is promoted to the navbar Get-started slot automatically. Plan 02 uses the rename — no `articles:` block in `_pkgdown.yml`.

## Verification snapshot

| Check | Result |
|-------|--------|
| `test -f vignettes/gg2d3.Rmd` | ✓ |
| `test -e vignettes/gg2d3-intro.Rmd` | ✗ (gone, correct) |
| `grep -rn 'gg2d3-intro'` (filtered) | 0 hits |
| `yaml::read_yaml('_pkgdown.yml')` structural assertion | `OK` |
| `grep -Fx '^\.github$' .Rbuildignore` | ✓ |
| `desc::desc('DESCRIPTION')$get_urls()` length | 2 |
| `git log --follow vignettes/gg2d3.Rmd` | shows prior history (rename preserved) |

## Hand-off to Plan 03

Source tree is fully configured for pkgdown. Plan 03 can now run `pkgdown::build_site_github_pages()` and inspect the built `docs/` output.
