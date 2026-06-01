#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)

value_after <- function(flag, default = NULL) {
  index <- match(flag, args)
  if (is.na(index) || length(args) < index + 1L || grepl("^--", args[[index + 1L]])) {
    return(default)
  }
  args[[index + 1L]]
}

as_bool <- function(value, flag) {
  if (identical(value, "true")) {
    return(TRUE)
  }
  if (identical(value, "false")) {
    return(FALSE)
  }
  stop(
    "Unknown ",
    flag,
    " value: ",
    value,
    ". Expected one of: true, false, auto",
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

site_root_input <- value_after("--site-root")
if (is.null(site_root_input)) {
  stop("--site-root is required", call. = FALSE)
}

require_rendered_sf_input <- value_after("--require-rendered-sf", "false")
valid_require_rendered_sf <- c("true", "false", "auto")
if (!require_rendered_sf_input %in% valid_require_rendered_sf) {
  stop(
    "Unknown --require-rendered-sf value: ",
    require_rendered_sf_input,
    ". Expected one of: ",
    paste(valid_require_rendered_sf, collapse = ", "),
    call. = FALSE
  )
}

require_rendered_crosstalk_input <- value_after("--require-rendered-crosstalk", "false")
valid_require_rendered_crosstalk <- c("true", "false", "auto")
if (!require_rendered_crosstalk_input %in% valid_require_rendered_crosstalk) {
  stop(
    "Unknown --require-rendered-crosstalk value: ",
    require_rendered_crosstalk_input,
    ". Expected one of: ",
    paste(valid_require_rendered_crosstalk, collapse = ", "),
    call. = FALSE
  )
}

root <- find_project_root()
setwd(root)

source(file.path(root, "tests", "testthat", "helper-pkgdown-site.R"))

site_root <- normalizePath(site_root_input, mustWork = TRUE)
require_rendered_sf <- if (identical(require_rendered_sf_input, "auto")) {
  pkgdown_site_spatial_loadable()
} else {
  as_bool(require_rendered_sf_input, "--require-rendered-sf")
}
require_rendered_crosstalk <- if (identical(require_rendered_crosstalk_input, "auto")) {
  pkgdown_site_crosstalk_loadable()
} else {
  as_bool(require_rendered_crosstalk_input, "--require-rendered-crosstalk")
}

pkgdown_site_validate_publication(
  site_root = site_root,
  require_rendered_sf = require_rendered_sf,
  require_rendered_crosstalk = require_rendered_crosstalk,
  root = root
)
sf_outcome <- pkgdown_site_sf_outcome(root = root, site_root = site_root)
crosstalk_outcome <- pkgdown_site_crosstalk_outcome(root = root, site_root = site_root)

cat(
  "Pkgdown publication inspection passed (site root: ",
  site_root_input,
  ", sf outcome: ",
  sf_outcome,
  ", crosstalk outcome: ",
  crosstalk_outcome,
  ")\n",
  sep = ""
)
