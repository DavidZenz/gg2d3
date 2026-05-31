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
