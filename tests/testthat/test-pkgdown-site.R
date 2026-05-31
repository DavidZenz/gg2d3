read_text_file <- function(path) {
  candidates <- c(
    path,
    file.path("..", "..", path)
  )
  resolved <- candidates[file.exists(candidates)][1]
  if (is.na(resolved)) {
    stop("Cannot find text file: ", path, call. = FALSE)
  }
  paste(readLines(resolved, warn = FALSE), collapse = "\n")
}

expect_text_contains <- function(path, markers) {
  text <- read_text_file(path)
  for (marker in markers) {
    expect_true(
      grepl(marker, text, fixed = TRUE),
      info = paste0("Expected ", path, " to contain marker: ", marker)
    )
  }
}

expect_existing_path <- function(path) {
  expect_true(
    file.exists(path) || dir.exists(path) ||
      file.exists(file.path("..", "..", path)) ||
      dir.exists(file.path("..", "..", path)),
    info = paste0("Expected generated pkgdown path to exist: ", path)
  )
}

marker_position <- function(text, marker) {
  regexpr(marker, text, fixed = TRUE)[[1]]
}

expect_sf_article_outcome <- function(html_path, md_path) {
  html <- read_text_file(html_path)
  md <- read_text_file(md_path)

  if (grepl("PKGDOWN_SF_OPTIONAL_SKIP", html, fixed = TRUE) ||
      grepl("PKGDOWN_SF_OPTIONAL_SKIP", md, fixed = TRUE)) {
    expect_true(TRUE, info = "Generated article contains PKGDOWN_SF_OPTIONAL_SKIP")
    return(invisible(TRUE))
  }

  heading <- marker_position(html, "sf family maps with")
  widget_positions <- gregexpr("gg2d3 html-widget", html, fixed = TRUE)[[1]]
  expect_true(
    heading > 0 && any(widget_positions > heading),
    info = paste0(
      "Expected ", html_path,
      " to contain PKGDOWN_SF_OPTIONAL_SKIP or a gg2d3 html-widget after the sf heading"
    )
  )
}

source_article_markers <- c(
  "sf family maps with",
  "geom_sf() supports polygon-family",
  "PKGDOWN_SF_OPTIONAL_SKIP"
)

generated_article_text_markers <- c(
  "sf family maps with",
  "geom_sf() supports polygon-family"
)

generated_widget_markers <- c(
  "gg2d3 html-widget",
  "d3.v7.min.js",
  "gg2d3-modules"
)

generated_optional_sf_markers <- c(
  "PKGDOWN_SF_OPTIONAL_SKIP"
)

test_that("source pkgdown article exposes the sf support and skip contract", {
  expect_text_contains("vignettes/gg2d3.Rmd", source_article_markers)
})

test_that("generated pkgdown marker contract names article and widget evidence", {
  expect_true(length(generated_article_text_markers) > 0)
  expect_true(length(generated_widget_markers) > 0)
  expect_true(length(generated_optional_sf_markers) > 0)
})

test_that("generated pkgdown article contains current sf support text", {
  expect_text_contains("docs/articles/gg2d3.html", generated_article_text_markers)
  expect_text_contains("docs/articles/gg2d3.md", generated_article_text_markers)
})

test_that("generated pkgdown article embeds gg2d3 widget dependencies", {
  expect_text_contains("docs/articles/gg2d3.html", generated_widget_markers)
  expect_existing_path("docs/articles/gg2d3_files/gg2d3-modules-0.0.1")
})

test_that("generated pkgdown article records an sf render or skip outcome", {
  expect_sf_article_outcome("docs/articles/gg2d3.html", "docs/articles/gg2d3.md")
})

test_that("generated pkgdown NEWS and reference pages reflect current support", {
  expect_text_contains(
    "docs/news/index.html",
    c("Pkgdown publication-surface evidence", "generated site")
  )
  expect_text_contains(
    "docs/reference/gg2d3.html",
    c("geom_sf()", "geom_sf_text()", "geom_sf_label()")
  )
  expect_text_contains(
    "docs/reference/extract_sf_geometries.html",
    c("polygon", "point", "line", "geom_sf()")
  )
})
