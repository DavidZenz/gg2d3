---
phase: 14
plan: 02
type: execute
wave: 1
depends_on: ["14-01"]
files_modified:
  - inst/htmlwidgets/modules/constants.js
  - tests/testthat/test-color-fidelity.R
autonomous: true
requirements: [COLOR-01]
tags: [js, regex, hex, rgba, color-fidelity]

must_haves:
  truths:
    - "isHexColor accepts 3, 4, 6, and 8 digit hex strings"
    - "Static grep against constants.js confirms the widened regex"
    - "viridis_d 8-hex RGBA strings (e.g. #440154FF) no longer fall through to colorScale"
    - "Alpha-resolved RGBA hex (D-13, e.g. #FF000080) round-trips identically"
  artifacts:
    - path: "inst/htmlwidgets/modules/constants.js"
      provides: "Widened isHexColor regex covering 3/4/6/8 hex digits"
      contains: "[0-9a-f]{8}"
  key_links:
    - from: "inst/htmlwidgets/modules/constants.js::isHexColor"
      to: "inst/htmlwidgets/modules/geom-registry.js::makeColorAccessors"
      via: "fast-path branch for valid hex (Pitfall 1)"
      pattern: "isHexColor"
---

<objective>
Fix Pitfall 1 from the research: `isHexColor` in `inst/htmlwidgets/modules/constants.js:188-190` rejects 8-digit RGBA hex (`#440154FF`, `#FF000080`). Widen the regex to accept 3, 4, 6, or 8 hex digits — covering CSS Color 4 short-RGBA (`#RGBA`) and full-RGBA (`#RRGGBBAA`).

Purpose: COLOR-01 progress for viridis_d (D-05) and alpha-resolved fills (D-13). One-line fix; high leverage.

Output:
- `inst/htmlwidgets/modules/constants.js` — regex widened.
- `tests/testthat/test-color-fidelity.R` — flip the `isHexColor accepts 4 and 8 digit hex` skip-pending into a real static-grep assertion.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<inputs>
@.planning/phases/14-color-fidelity/14-RESEARCH.md
@.planning/phases/14-color-fidelity/14-VALIDATION.md
@inst/htmlwidgets/modules/constants.js
@tests/testthat/test-color-fidelity.R
@tests/testthat/helper-color.R
</inputs>

<outputs>
- `inst/htmlwidgets/modules/constants.js` — 1-line change at the `isHexColor` regex.
- `tests/testthat/test-color-fidelity.R` — replace one `skip("pending plan 14-02")` block with a real static-grep assertion (~10 lines).
</outputs>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: TEST — flip isHexColor regex check from skip to RED</name>
  <files>tests/testthat/test-color-fidelity.R</files>
  <behavior>
    - Test 1: Read `inst/htmlwidgets/modules/constants.js`; the file contents must contain a regex literal that matches 8 hex digits (`[0-9a-f]{8}`).
    - Test 2: Same file must also accept 4 hex digits (`[0-9a-f]{4}` or a `{3,4}` quantifier covering it).
    - Test currently RED: file ships with `^#([0-9a-f]{3}|[0-9a-f]{6})$/i` only.
  </behavior>
  <action>
Replace the existing block:

```r
test_that("isHexColor accepts 4 and 8 digit hex (constants.js regex)", { skip("pending plan 14-02") })
```

with:

```r
test_that("isHexColor accepts 4 and 8 digit hex (constants.js regex)", {
  src <- readLines("../../inst/htmlwidgets/modules/constants.js", warn = FALSE)
  joined <- paste(src, collapse = "\n")
  # Find the isHexColor function body.
  fn_match <- regmatches(joined, regexpr("function isHexColor[\\s\\S]*?\\}", joined, perl = TRUE))
  expect_length(fn_match, 1L)
  # Regex must accept 8-digit hex (full RGBA: #RRGGBBAA) and 4-digit (short RGBA: #RGBA).
  expect_match(fn_match, "\\[0-9a-f\\]\\{8\\}|\\[0-9a-f\\]\\{6,8\\}|\\[0-9a-f\\]\\{3,8\\}")
  expect_match(fn_match, "\\[0-9a-f\\]\\{4\\}|\\[0-9a-f\\]\\{3,4\\}|\\[0-9a-f\\]\\{3,8\\}")
})
```

The path `../../inst/htmlwidgets/modules/constants.js` is correct — `testthat::test_file` runs with cwd at `tests/testthat/`.

Run the test — it should FAIL (RED) since the source still has only `{3}|{6}`.

Commit:
```
git add tests/testthat/test-color-fidelity.R
git commit -m "test(14-02): RED — assert isHexColor accepts 4/8-digit hex"
```
  </action>
  <verify>
    <automated>Rscript -e 'pkgload::load_all(".",quiet=TRUE); res <- testthat::test_file("tests/testthat/test-color-fidelity.R", reporter="silent"); failed <- sum(vapply(res, function(r) sum(vapply(r$results, function(x) inherits(x, "expectation_failure"), logical(1))), integer(1))); stopifnot(failed >= 1)'</automated>
  </verify>
  <done>RED test asserts presence of 4-digit and 8-digit branches in isHexColor; running test-color-fidelity.R produces at least 1 failure.</done>
</task>

<task type="auto" tdd="true">
  <name>Task 2: IMPL — widen isHexColor regex; verify GREEN</name>
  <files>inst/htmlwidgets/modules/constants.js</files>
  <action>
Edit `inst/htmlwidgets/modules/constants.js:189`. Replace:

```js
return typeof s === "string" && /^#([0-9a-f]{3}|[0-9a-f]{6})$/i.test(s);
```

with:

```js
// Accept #RGB, #RGBA (CSS Color 4 short), #RRGGBB, #RRGGBBAA (full RGBA).
return typeof s === "string" && /^#([0-9a-f]{3,4}|[0-9a-f]{6}|[0-9a-f]{8})$/i.test(s);
```

Update the JSDoc one line above to reflect the new accepted forms:

```js
/**
 * Check if string is a valid hex color.
 * @param {string} s - String to check
 * @returns {boolean} True if valid hex color (#RGB, #RGBA, #RRGGBB, or #RRGGBBAA)
 */
```

Re-run the suite — the RED test from Task 1 should now PASS, and nothing else should regress (this is JS source; R tests don't load it, but the static-grep test now reads the new content).

Commit:
```
git add inst/htmlwidgets/modules/constants.js
git commit -m "fix(14-02): isHexColor accepts 4/8-digit RGBA hex (Pitfall 1)"
```
  </action>
  <verify>
    <automated>Rscript -e 'pkgload::load_all(".",quiet=TRUE); testthat::test_file("tests/testthat/test-color-fidelity.R")'</automated>
  </verify>
  <done>isHexColor regex covers `{3,4}|{6}|{8}` digit hex; the RED test from Task 1 is now GREEN; full suite shows no new failures vs baseline.</done>
</task>

</tasks>

<exit_criteria>
- `grep -E "\[0-9a-f\]\{8\}" inst/htmlwidgets/modules/constants.js` returns ≥1 match.
- `tests/testthat/test-color-fidelity.R` test "isHexColor accepts 4 and 8 digit hex (constants.js regex)" passes (no longer skipped).
- Phase-13 baseline (`[ FAIL 8 | PASS ... ]`) unchanged in count and identity of failures.
- Two atomic commits: RED test, then GREEN impl.
</exit_criteria>

<threat_model>
No threat surface — package internals only. Regex widening on a client-side validation helper.
</threat_model>

<output>
After completion, create `.planning/phases/14-color-fidelity/14-02-SUMMARY.md` listing the regex change and confirming the static test is green.
</output>
