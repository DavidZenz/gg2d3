pkgdown_site_source_article_markers <- c(
  "sf family maps with",
  "geom_sf() supports polygon-family",
  "PKGDOWN_SF_OPTIONAL_SKIP",
  "Linked views with Crosstalk",
  "PKGDOWN_CROSSTALK_OPTIONAL_SKIP"
)

pkgdown_site_generated_article_text_markers <- c(
  "sf family maps with",
  "geom_sf() supports polygon-family",
  "Linked views with Crosstalk"
)

pkgdown_site_generated_widget_markers <- c(
  "gg2d3 html-widget",
  "d3.v7.min.js",
  "gg2d3-modules"
)

pkgdown_site_generated_crosstalk_asset_markers <- list(
  brush = c(
    "syncCrosstalkSelection(containerEl, panelGroup, pixelRect)",
    "collectSelectedCrosstalkKeys"
  ),
  crosstalk = c(
    "function applyLocalGroupSelection(crosstalkGroup, selectedKeys)",
    "data-gg2d3-crosstalk-group"
  ),
  binding = c(
    "window.gg2d3.crosstalk.bind(el, x.crosstalk_key, x.crosstalk_group)"
  )
)

pkgdown_site_generated_optional_sf_markers <- c(
  "PKGDOWN_SF_OPTIONAL_SKIP"
)

pkgdown_site_generated_optional_crosstalk_markers <- c(
  "PKGDOWN_CROSSTALK_OPTIONAL_SKIP"
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
    site_candidates,
    file.path(root, path),
    path,
    file.path("..", "..", path)
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

pkgdown_site_skip_if_source_docs_unavailable <- function(root = ".") {
  testthat::skip_if_not(
    pkgdown_site_has_path("vignettes/gg2d3.Rmd", root = root),
    "source docs are not available"
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

pkgdown_site_crosstalk_loadable <- function() {
  all(vapply(
    c("crosstalk", "htmltools"),
    function(package) {
      suppressWarnings(requireNamespace(package, quietly = TRUE))
    },
    logical(1)
  ))
}

pkgdown_site_script_from_marker <- function(text, marker) {
  position <- pkgdown_site_marker_position(text, marker)
  if (position <= 0) {
    return("")
  }
  rest <- substring(text, position)
  end <- regexpr("</script>", rest, fixed = TRUE)[[1]]
  if (end <= 0) {
    return(rest)
  }
  substring(rest, 1, end + nchar("</script>") - 1)
}

pkgdown_site_sf_outcome <- function(root = ".", site_root = NULL) {
  html <- pkgdown_site_read_text("docs/articles/gg2d3.html", root = root, site_root = site_root)
  md <- pkgdown_site_read_text("docs/articles/gg2d3.md", root = root, site_root = site_root)

  heading <- pkgdown_site_marker_position(html, "sf family maps with")
  if (heading <= 0) {
    return("missing")
  }

  rendered_sf_markers <- c(
    '"geom":"sf"',
    '"sf_family":"',
    '"sf_diagnostics"'
  )
  if (all(vapply(
    rendered_sf_markers,
    function(marker) grepl(marker, html, fixed = TRUE),
    logical(1)
  ))) {
    return("rendered")
  }

  if (grepl("PKGDOWN_SF_OPTIONAL_SKIP", html, fixed = TRUE) ||
      grepl("PKGDOWN_SF_OPTIONAL_SKIP", md, fixed = TRUE)) {
    return("classified_skip")
  }

  "missing"
}

pkgdown_site_sf_interactivity_outcome <- function(root = ".", site_root = NULL) {
  outcome <- pkgdown_site_sf_outcome(root = root, site_root = site_root)
  if (!identical(outcome, "rendered")) {
    return(outcome)
  }

  html <- pkgdown_site_read_text("docs/articles/gg2d3.html", root = root, site_root = site_root)
  sf_script <- pkgdown_site_script_from_marker(html, '"geom":"sf"')
  interactive_sf_markers <- c(
    '"tooltip":{"enabled":true',
    '"hover":{"enabled":true',
    '"brush":{"enabled":true'
  )
  if (all(vapply(
    interactive_sf_markers,
    function(marker) grepl(marker, sf_script, fixed = TRUE),
    logical(1)
  ))) {
    return("interactive")
  }

  "rendered_static"
}

pkgdown_site_expect_sf_outcome <- function(root = ".", require_rendered_sf = FALSE, site_root = NULL) {
  outcome <- pkgdown_site_sf_outcome(root = root, site_root = site_root)
  interactive_outcome <- pkgdown_site_sf_interactivity_outcome(root = root, site_root = site_root)

  if (isTRUE(require_rendered_sf)) {
    testthat::expect_identical(
      outcome,
      "rendered",
      info = paste0(
        "Expected docs/articles/gg2d3.html to contain a gg2d3 html-widget ",
        "with rendered sf payload evidence because rendered sf evidence is required; outcome: ",
        outcome
      )
    )
    testthat::expect_identical(
      interactive_outcome,
      "interactive",
      info = paste0(
        "Expected rendered sf widget to include tooltip, hover, and brush ",
        "interactivity config; outcome: ",
        interactive_outcome
      )
    )
    return(invisible(outcome))
  }

  testthat::expect_true(
    interactive_outcome %in% c("interactive", "classified_skip"),
    info = paste0(
      "Expected docs/articles/gg2d3.html and docs/articles/gg2d3.md to contain ",
      "PKGDOWN_SF_OPTIONAL_SKIP or rendered interactive sf payload evidence; outcome: ",
      interactive_outcome
    )
  )

  invisible(outcome)
}

pkgdown_site_crosstalk_outcome <- function(path = "docs/articles/gg2d3.html", root = ".", site_root = NULL) {
  html <- pkgdown_site_read_text(path, root = root, site_root = site_root)
  md_path <- sub("[.]html$", ".md", path)
  md <- pkgdown_site_read_text(md_path, root = root, site_root = site_root)

  heading <- pkgdown_site_marker_position(html, "Linked views with Crosstalk")
  if (heading <= 0) {
    return("missing")
  }

  crosstalk_key_positions <- gregexpr('"crosstalk_key":', html, fixed = TRUE)[[1]]
  crosstalk_widget_count <- sum(crosstalk_key_positions > 0)
  if (crosstalk_widget_count >= 2 &&
      grepl('"crosstalk_group":"pkgdown_crosstalk_iris"', html, fixed = TRUE) &&
      grepl('"brush":{"enabled":true', html, fixed = TRUE) &&
      identical(pkgdown_site_crosstalk_asset_outcome(root = root, site_root = site_root), "linked_assets")) {
    return("rendered")
  }

  if (crosstalk_widget_count >= 2 &&
      grepl('"crosstalk_group":"pkgdown_crosstalk_iris"', html, fixed = TRUE) &&
      grepl('"brush":{"enabled":true', html, fixed = TRUE)) {
    return("rendered_unlinked_assets")
  }

  if (grepl("PKGDOWN_CROSSTALK_OPTIONAL_SKIP", html, fixed = TRUE) ||
      grepl("PKGDOWN_CROSSTALK_OPTIONAL_SKIP", md, fixed = TRUE)) {
    return("classified_skip")
  }

  "missing"
}

pkgdown_site_crosstalk_asset_outcome <- function(root = ".", site_root = NULL) {
  asset_paths <- c(
    brush = "docs/articles/gg2d3_files/gg2d3-modules-0.0.1/brush.js",
    crosstalk = "docs/articles/gg2d3_files/gg2d3-modules-0.0.1/crosstalk.js",
    binding = "docs/articles/gg2d3_files/gg2d3-binding-0.0.0.9000/gg2d3.js"
  )

  texts <- lapply(asset_paths, function(path) {
    tryCatch(
      pkgdown_site_read_text(path, root = root, site_root = site_root),
      error = function(error) ""
    )
  })

  has_all_markers <- all(vapply(
    names(pkgdown_site_generated_crosstalk_asset_markers),
    function(name) {
      all(vapply(
        pkgdown_site_generated_crosstalk_asset_markers[[name]],
        function(marker) grepl(marker, texts[[name]], fixed = TRUE),
        logical(1)
      ))
    },
    logical(1)
  ))

  if (has_all_markers) {
    return("linked_assets")
  }

  "missing_linked_assets"
}

pkgdown_site_expect_crosstalk_outcome <- function(root = ".",
                                                  require_rendered_crosstalk = FALSE,
                                                  site_root = NULL) {
  paths <- c(
    "docs/articles/gg2d3.html",
    "docs/articles/gg2d3-interactivity.html"
  )
  outcomes <- vapply(
    paths,
    pkgdown_site_crosstalk_outcome,
    character(1),
    root = root,
    site_root = site_root
  )

  if (isTRUE(require_rendered_crosstalk)) {
    testthat::expect_true(
      all(outcomes == "rendered"),
      info = paste0(
        "Expected both pkgdown Crosstalk sections to render linked widgets; outcomes: ",
        paste(names(outcomes), outcomes, sep = "=", collapse = ", ")
      )
    )
    return(invisible(outcomes))
  }

  testthat::expect_true(
    all(outcomes %in% c("rendered", "classified_skip")),
    info = paste0(
      "Expected both pkgdown Crosstalk sections to render linked widgets or ",
      "contain PKGDOWN_CROSSTALK_OPTIONAL_SKIP; outcomes: ",
      paste(names(outcomes), outcomes, sep = "=", collapse = ", ")
    )
  )

  invisible(outcomes)
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
  testthat::expect_true(length(pkgdown_site_generated_crosstalk_asset_markers) > 0)
  testthat::expect_true(length(pkgdown_site_generated_optional_sf_markers) > 0)
  testthat::expect_true(length(pkgdown_site_generated_optional_crosstalk_markers) > 0)
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
  testthat::expect_identical(
    pkgdown_site_crosstalk_asset_outcome(root = root, site_root = site_root),
    "linked_assets"
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

pkgdown_site_validate_quick <- function(root = ".",
                                        require_rendered_sf = FALSE,
                                        require_rendered_crosstalk = FALSE,
                                        site_root = NULL) {
  pkgdown_site_validate_generated_article_text(root = root, site_root = site_root)
  pkgdown_site_validate_widget_dependencies(root = root, site_root = site_root)
  pkgdown_site_expect_sf_outcome(
    root = root,
    require_rendered_sf = require_rendered_sf,
    site_root = site_root
  )
  pkgdown_site_expect_crosstalk_outcome(
    root = root,
    require_rendered_crosstalk = require_rendered_crosstalk,
    site_root = site_root
  )
  pkgdown_site_validate_news_and_reference(root = root, site_root = site_root)
}

pkgdown_site_validate_publication <- function(site_root,
                                              require_rendered_sf = FALSE,
                                              require_rendered_crosstalk = FALSE,
                                              root = ".") {
  pkgdown_site_validate_quick(
    root = root,
    require_rendered_sf = require_rendered_sf,
    require_rendered_crosstalk = require_rendered_crosstalk,
    site_root = site_root
  )
}
