#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)

value_after <- function(flag, default = NULL) {
  index <- match(flag, args)
  if (is.na(index) || length(args) < index + 1L || grepl("^--", args[[index + 1L]])) {
    return(default)
  }
  args[[index + 1L]]
}

mode <- value_after("--mode", "quick")
valid_modes <- c("quick", "release", "ci")
if (!mode %in% valid_modes) {
  stop(
    "Unknown pkgdown site validation mode: ", mode,
    ". Expected one of: ", paste(valid_modes, collapse = ", "),
    call. = FALSE
  )
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

root <- find_project_root()
setwd(root)

source(file.path(root, "tests", "testthat", "helper-pkgdown-site.R"))

if (identical(mode, "release")) {
  devtools::document()
  devtools::build_readme()
  pkgdown::build_site_github_pages(new_process = FALSE, install = FALSE)
}

require_rendered_sf <- identical(mode, "ci") || identical(mode, "release")
require_rendered_sf <- require_rendered_sf && pkgdown_site_spatial_loadable()
require_rendered_crosstalk <- identical(mode, "ci") || identical(mode, "release")
require_rendered_crosstalk <- require_rendered_crosstalk && pkgdown_site_crosstalk_loadable()

pkgdown_site_validate_source_contract(root = root)
pkgdown_site_validate_quick(
  root = root,
  require_rendered_sf = require_rendered_sf,
  require_rendered_crosstalk = require_rendered_crosstalk
)

sf_outcome <- pkgdown_site_sf_outcome(root = root)
crosstalk_outcome <- pkgdown_site_crosstalk_outcome(root = root)
cat(
  "Generated pkgdown site validation passed (mode: ",
  mode,
  ", sf outcome: ",
  sf_outcome,
  ", crosstalk outcome: ",
  crosstalk_outcome,
  ")\n",
  sep = ""
)
