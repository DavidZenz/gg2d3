# Phase 14 colour-fidelity snapshot harness.
#
# Wave 0 scaffold — all tests are skip-pending stubs that later plans flip to
# real assertions. The names and groupings mirror VALIDATION.md's per-task
# verification map exactly. Helpers in tests/testthat/helper-color.R are
# auto-sourced by testthat before this file runs.
#
# Requirement IDs:
#   COLOR-01 — per-row hex parity vs ggplot_build (D-03/D-04)
#   COLOR-02 — continuous color renders as colorbar (not discrete fallback)
#
# Each test_that block calls skip("pending plan 14-XX") as the first line so
# the file is harmless until the named plan replaces it. Do NOT add real
# assertions here; that's the downstream plans' job.

# ---------------------------------------------------------------------------
# COLOR-01 — per-row mark hex parity (filled in by plan 14-07 corpus)
# ---------------------------------------------------------------------------

test_that("viridis_c per-row mark hex equals ggplot_build", {
  library(ggplot2)
  skip("pending plan 14-07")
})

test_that("viridis_d per-row mark hex equals ggplot_build (8-hex RGBA)", {
  library(ggplot2)
  skip("pending plan 14-07")
})

test_that("brewer (discrete fill) per-row hex parity", {
  library(ggplot2)
  skip("pending plan 14-07")
})

test_that("distiller per-row hex parity", {
  library(ggplot2)
  skip("pending plan 14-07")
})

test_that("scale_color_manual (named) per-row hex parity", {
  library(ggplot2)
  skip("pending plan 14-07")
})

test_that("scale_color_manual (unnamed) per-row hex parity", {
  library(ggplot2)
  skip("pending plan 14-07")
})

test_that("scale_fill_manual per-row hex parity", {
  library(ggplot2)
  skip("pending plan 14-07")
})

test_that("scale_color_steps per-row hex parity", {
  library(ggplot2)
  skip("pending plan 14-07")
})

# ---------------------------------------------------------------------------
# COLOR-02 — colorbar IR & rendering (plans 14-03..14-06)
# ---------------------------------------------------------------------------

test_that("viridis_c emits guide.type colorbar with >=30 stops", {
  library(ggplot2)
  skip("pending plan 14-03")
})

test_that("distiller emits guide.type colorbar", {
  library(ggplot2)
  skip("pending plan 14-03")
})

test_that("scale_color_steps emits guide.type colorbar with is_steps TRUE", {
  library(ggplot2)
  skip("pending plan 14-03")
})

test_that("colorbar IR carries breaks labels na.value domain is_continuous", {
  library(ggplot2)
  skip("pending plan 14-05")
})

test_that("colorbar IR orientation defaults vertical and flips horizontal for legend.position bottom", {
  library(ggplot2)
  skip("pending plan 14-05")
})

test_that("renderColorbar tick logic uses breaks (not first/last keys)", {
  library(ggplot2)
  skip("pending plan 14-06")
})

test_that("renderColorbar branches on guide.orientation for horizontal layout", {
  library(ggplot2)
  skip("pending plan 14-06")
})

# ---------------------------------------------------------------------------
# Edge cases (plan 14-07 corpus snapshots) — D-11..D-14
# ---------------------------------------------------------------------------

test_that("D-11 NA colour row renders as #7F7F7F (grey50)", {
  library(ggplot2)
  skip("pending plan 14-07")
})

test_that("D-12 dual color+fill produces 2 guides without merge", {
  library(ggplot2)
  skip("pending plan 14-07")
})

test_that("D-13 RGBA hex round-trips identically", {
  library(ggplot2)
  skip("pending plan 14-07")
})

test_that("D-14 manual out-of-range factor maps to na.value", {
  library(ggplot2)
  skip("pending plan 14-07")
})

# ---------------------------------------------------------------------------
# JS regex static check (plan 14-02)
# ---------------------------------------------------------------------------

test_that("isHexColor accepts 4 and 8 digit hex (constants.js regex)", {
  src <- readLines("../../inst/htmlwidgets/modules/constants.js", warn = FALSE)
  joined <- paste(src, collapse = "\n")
  # Find the isHexColor function body.
  # Match through the line-leading closing brace (function body ends with a `}` at line start,
  # not the inner `{3,4}` quantifier braces). Lazy match up to first newline-anchored `}`.
  fn_match <- regmatches(joined, regexpr("function isHexColor[\\s\\S]*?\\n  \\}", joined, perl = TRUE))
  expect_length(fn_match, 1L)
  # Regex must accept 8-digit hex (full RGBA: #RRGGBBAA) and 4-digit (short RGBA: #RGBA).
  expect_match(fn_match, "\\[0-9a-f\\]\\{8\\}|\\[0-9a-f\\]\\{6,8\\}|\\[0-9a-f\\]\\{3,8\\}")
  expect_match(fn_match, "\\[0-9a-f\\]\\{4\\}|\\[0-9a-f\\]\\{3,4\\}|\\[0-9a-f\\]\\{3,8\\}")
})
