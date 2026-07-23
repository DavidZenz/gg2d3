#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)

value_after <- function(flag, default = NULL) {
  index <- match(flag, args)
  if (is.na(index) || length(args) < index + 1L || grepl("^--", args[[index + 1L]])) {
    return(default)
  }
  args[[index + 1L]]
}

find_project_root <- function(path = getwd()) {
  current <- normalizePath(path, mustWork = TRUE)
  repeat {
    if (file.exists(file.path(current, "DESCRIPTION")) &&
        file.exists(file.path(current, "tests", "testthat", "helper-pkgdown-site.R"))) {
      return(current)
    }
    parent <- dirname(current)
    if (identical(parent, current)) {
      stop("Cannot locate gg2d3 project root from: ", path, call. = FALSE)
    }
    current <- parent
  }
}

load_package_status <- function(package) {
  namespace <- tryCatch(
    suppressWarnings(loadNamespace(package)),
    error = function(error) error
  )
  if (inherits(namespace, "error")) {
    return(list(
      loadable = FALSE,
      version = NA_character_,
      message = conditionMessage(namespace)
    ))
  }
  list(
    loadable = TRUE,
    version = as.character(utils::packageVersion(package)),
    message = ""
  )
}

format_status <- function(package, status) {
  if (isTRUE(status$loadable)) {
    return(paste0(package, ": loadable version ", status$version))
  }
  paste0(package, ": not_loadable: ", status$message)
}

format_sf_external_libraries <- function() {
  versions <- tryCatch(
    sf::sf_extSoftVersion(),
    error = function(error) NULL
  )
  if (is.null(versions)) {
    return("sf external libraries: unavailable")
  }
  pairs <- paste(names(versions), as.character(versions), sep = "=")
  paste0("sf external libraries: ", paste(pairs, collapse = ", "))
}

root <- find_project_root()

# Standalone sf-outcome probe — no dependency on the testthat helper.
# Reads the built pkgdown HTML and MD articles and returns one of:
#   "rendered"         – gg2d3 widget with rendered sf payload found
#   "classified_skip"  – PKGDOWN_SF_OPTIONAL_SKIP marker found
#   "missing"          – sf heading found but payload absent
#   "error: <msg>"     – file not found or read error
pkgdown_site_sf_outcome <- function(root = ".", site_root = NULL) {
  read_article <- function(rel_path) {
    candidates <- character()
    if (!is.null(site_root)) {
      pub_path <- sub("^docs/", "", rel_path)
      candidates <- c(
        file.path(site_root, pub_path),
        file.path(root, site_root, pub_path)
      )
    }
    candidates <- c(candidates, file.path(root, rel_path), rel_path)
    hit <- candidates[file.exists(candidates)][1]
    if (is.na(hit)) {
      stop("Cannot find: ", rel_path, call. = FALSE)
    }
    paste(readLines(hit, warn = FALSE), collapse = "\n")
  }

  html <- tryCatch(read_article("docs/articles/gg2d3.html"), error = function(e) stop(conditionMessage(e)))
  md   <- tryCatch(read_article("docs/articles/gg2d3.md"),   error = function(e) stop(conditionMessage(e)))

  if (regexpr("sf family maps with", html, fixed = TRUE)[[1]] <= 0) {
    return("missing")
  }

  rendered_markers <- c('"geom":"sf"', '"sf_family":"', '"sf_diagnostics"')
  if (all(vapply(rendered_markers, function(m) grepl(m, html, fixed = TRUE), logical(1)))) {
    return("rendered")
  }

  if (grepl("PKGDOWN_SF_OPTIONAL_SKIP", html, fixed = TRUE) ||
      grepl("PKGDOWN_SF_OPTIONAL_SKIP", md,   fixed = TRUE)) {
    return("classified_skip")
  }

  "missing"
}

site_root_input <- value_after("--site-root", "docs")
site_root <- if (dir.exists(site_root_input)) {
  normalizePath(site_root_input, mustWork = TRUE)
} else if (dir.exists(file.path(root, site_root_input))) {
  normalizePath(file.path(root, site_root_input), mustWork = TRUE)
} else {
  NULL
}

sf_status <- load_package_status("sf")
geojsonsf_status <- load_package_status("geojsonsf")

cat("Spatial stack diagnostic\n")
cat(format_status("sf", sf_status), "\n", sep = "")
cat(format_status("geojsonsf", geojsonsf_status), "\n", sep = "")

if (isTRUE(sf_status$loadable)) {
  cat(format_sf_external_libraries(), "\n", sep = "")
}

if (is.null(site_root)) {
  sf_outcome <- "site_root_unavailable"
} else {
  sf_outcome <- tryCatch(
    pkgdown_site_sf_outcome(root = root, site_root = site_root),
    error = function(error) paste0("error: ", conditionMessage(error))
  )
}
cat("pkgdown sf outcome: ", sf_outcome, "\n", sep = "")

if (isTRUE(sf_status$loadable) && isTRUE(geojsonsf_status$loadable)) {
  recommendation <- "spatial stack loadable; rerun pkgdown release validation for rendered sf evidence"
} else {
  recommendation <- "repair local sf/GDAL dynamic-library stack before expecting rendered local sf evidence"
}
cat("recommendation: ", recommendation, "\n", sep = "")
