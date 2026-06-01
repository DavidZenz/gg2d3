pkgdown_site_source_article_markers <- c(
  "sf family maps with",
  "geom_sf() supports polygon-family",
  "PKGDOWN_SF_OPTIONAL_SKIP"
)

pkgdown_site_generated_article_text_markers <- c(
  "sf family maps with",
  "geom_sf() supports polygon-family"
)

pkgdown_site_generated_widget_markers <- c(
  "gg2d3 html-widget",
  "d3.v7.min.js",
  "gg2d3-modules"
)

pkgdown_site_generated_optional_sf_markers <- c(
  "PKGDOWN_SF_OPTIONAL_SKIP"
)

pkgdown_site_publication_path <- function(path, site_root = NULL) {
  if (is.null(site_root)) {
    return(path)
  }
  sub("^docs/", "", path)
}

pkgdown_site_resolve_path <- function(path, root = ".", site_root = NULL) {
  publication_path <- pkgdown_site_publication_path(path, site_root = site_root)
  site_candidates <- character()
  if (!is.null(site_root)) {
    site_candidates <- c(
      file.path(site_root, publication_path),
      file.path(root, site_root, publication_path),
      file.path("..", "..", site_root, publication_path)
    )
  }
  candidates <- c(
    file.path(root, path),
    path,
    file.path("..", "..", path),
    site_candidates
  )
  resolved <- candidates[file.exists(candidates) | dir.exists(candidates)][1]
  if (is.na(resolved)) {
    stop("Cannot find generated pkgdown path: ", path, call. = FALSE)
  }
  resolved
}

pkgdown_site_has_path <- function(path, root = ".", site_root = NULL) {
  !is.na(tryCatch(
    pkgdown_site_resolve_path(path, root = root, site_root = site_root),
    error = function(error) NA_character_
  ))
}

pkgdown_site_skip_if_generated_docs_unavailable <- function(root = ".") {
  testthat::skip_if_not(
    pkgdown_site_has_path("docs/articles/gg2d3.html", root = root),
    "generated docs site is not available"
  )
}

pkgdown_site_read_text <- function(path, root = ".", site_root = NULL) {
  resolved <- pkgdown_site_resolve_path(path, root = root, site_root = site_root)
  paste(readLines(resolved, warn = FALSE), collapse = "\n")
}

pkgdown_site_expect_text_contains <- function(path, markers, root = ".", site_root = NULL) {
  text <- pkgdown_site_read_text(path, root = root, site_root = site_root)
  for (marker in markers) {
    testthat::expect_true(
      grepl(marker, text, fixed = TRUE),
      info = paste0("Expected ", path, " to contain marker: ", marker)
    )
  }
}

pkgdown_site_expect_existing_path <- function(path, root = ".", site_root = NULL) {
  resolved <- tryCatch(
    pkgdown_site_resolve_path(path, root = root, site_root = site_root),
    error = function(error) NA_character_
  )
  testthat::expect_true(
    !is.na(resolved),
    info = paste0("Expected generated pkgdown path to exist: ", path)
  )
}

pkgdown_site_marker_position <- function(text, marker) {
  regexpr(marker, text, fixed = TRUE)[[1]]
}

pkgdown_site_spatial_loadable <- function() {
  all(vapply(
    c("sf", "geojsonsf"),
    function(package) {
      suppressWarnings(requireNamespace(package, quietly = TRUE))
    },
    logical(1)
  ))
}

pkgdown_site_sf_outcome <- function(root = ".", site_root = NULL) {
  html <- pkgdown_site_read_text("docs/articles/gg2d3.html", root = root, site_root = site_root)
  md <- pkgdown_site_read_text("docs/articles/gg2d3.md", root = root, site_root = site_root)

  if (grepl("PKGDOWN_SF_OPTIONAL_SKIP", html, fixed = TRUE) ||
      grepl("PKGDOWN_SF_OPTIONAL_SKIP", md, fixed = TRUE)) {
    return("classified_skip")
  }

  heading <- pkgdown_site_marker_position(html, "sf family maps with")
  if (heading <= 0) {
    return("missing")
  }

  next_heading <- regexpr("<h3", substring(html, heading + 1), fixed = TRUE)[[1]]
  sf_section <- if (next_heading > 0) {
    substring(html, heading, heading + next_heading - 1)
  } else {
    substring(html, heading)
  }

  widget_positions <- gregexpr("gg2d3 html-widget", sf_section, fixed = TRUE)[[1]]
  if (any(widget_positions > 0)) {
    return("rendered")
  }

  "missing"
}

pkgdown_site_expect_sf_outcome <- function(root = ".", require_rendered_sf = FALSE, site_root = NULL) {
  outcome <- pkgdown_site_sf_outcome(root = root, site_root = site_root)

  if (isTRUE(require_rendered_sf)) {
    testthat::expect_identical(
      outcome,
      "rendered",
      info = paste0(
        "Expected docs/articles/gg2d3.html to contain a gg2d3 html-widget ",
        "inside the sf section because rendered sf evidence is required; outcome: ",
        outcome
      )
    )
    return(invisible(outcome))
  }

  testthat::expect_true(
    outcome %in% c("rendered", "classified_skip"),
    info = paste0(
      "Expected docs/articles/gg2d3.html and docs/articles/gg2d3.md to contain ",
      "PKGDOWN_SF_OPTIONAL_SKIP or a gg2d3 html-widget inside the sf section; outcome: ",
      outcome
    )
  )

  invisible(outcome)
}

pkgdown_site_validate_source_contract <- function(root = ".") {
  pkgdown_site_expect_text_contains(
    "vignettes/gg2d3.Rmd",
    pkgdown_site_source_article_markers,
    root = root
  )
}

pkgdown_site_validate_marker_contract <- function() {
  testthat::expect_true(length(pkgdown_site_generated_article_text_markers) > 0)
  testthat::expect_true(length(pkgdown_site_generated_widget_markers) > 0)
  testthat::expect_true(length(pkgdown_site_generated_optional_sf_markers) > 0)
}

pkgdown_site_validate_generated_article_text <- function(root = ".", site_root = NULL) {
  pkgdown_site_expect_text_contains(
    "docs/articles/gg2d3.html",
    pkgdown_site_generated_article_text_markers,
    root = root,
    site_root = site_root
  )
  pkgdown_site_expect_text_contains(
    "docs/articles/gg2d3.md",
    pkgdown_site_generated_article_text_markers,
    root = root,
    site_root = site_root
  )
}

pkgdown_site_validate_widget_dependencies <- function(root = ".", site_root = NULL) {
  pkgdown_site_expect_text_contains(
    "docs/articles/gg2d3.html",
    pkgdown_site_generated_widget_markers,
    root = root,
    site_root = site_root
  )
  pkgdown_site_expect_existing_path(
    "docs/articles/gg2d3_files/gg2d3-modules-0.0.1",
    root = root,
    site_root = site_root
  )
}

pkgdown_site_validate_news_and_reference <- function(root = ".", site_root = NULL) {
  pkgdown_site_expect_text_contains(
    "docs/news/index.html",
    c("Pkgdown publication-surface evidence", "generated site"),
    root = root,
    site_root = site_root
  )
  pkgdown_site_expect_text_contains(
    "docs/reference/gg2d3.html",
    c("geom_sf()", "geom_sf_text()", "geom_sf_label()"),
    root = root,
    site_root = site_root
  )
  pkgdown_site_expect_text_contains(
    "docs/reference/extract_sf_geometries.html",
    c("polygon", "point", "line", "geom_sf()"),
    root = root,
    site_root = site_root
  )
}

pkgdown_site_validate_quick <- function(root = ".", require_rendered_sf = FALSE, site_root = NULL) {
  pkgdown_site_validate_generated_article_text(root = root, site_root = site_root)
  pkgdown_site_validate_widget_dependencies(root = root, site_root = site_root)
  pkgdown_site_expect_sf_outcome(
    root = root,
    require_rendered_sf = require_rendered_sf,
    site_root = site_root
  )
  pkgdown_site_validate_news_and_reference(root = root, site_root = site_root)
}

pkgdown_site_validate_publication <- function(site_root, require_rendered_sf = FALSE, root = ".") {
  pkgdown_site_validate_quick(
    root = root,
    require_rendered_sf = require_rendered_sf,
    site_root = site_root
  )
}
