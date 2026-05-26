read_module <- function(path) {
  installed_path <- system.file(sub("^inst/", "", path), package = "gg2d3")
  candidates <- c(path, file.path("..", "..", path), installed_path)
  resolved <- candidates[nzchar(candidates) & file.exists(candidates)][1]
  if (is.na(resolved)) {
    stop("Cannot find module: ", path, call. = FALSE)
  }
  paste(readLines(resolved, warn = FALSE), collapse = "\n")
}

extract_js_strings <- function(text) {
  matches <- gregexpr("'([^']+)'|\"([^\"]+)\"", text, perl = TRUE)[[1]]
  if (identical(matches, -1L)) {
    return(character())
  }
  raw <- regmatches(text, list(matches))[[1]]
  sub("^[\"'](.*)[\"']$", "\\1", raw)
}

extract_contract_entries <- function(contract_js) {
  lines <- strsplit(contract_js, "\n", fixed = TRUE)[[1]]
  starts <- grep("^    \\{\\s*$", lines)
  starts <- starts[vapply(starts, function(i) {
    i < length(lines) && grepl("^      geom: ", lines[[i + 1]])
  }, logical(1))]
  ends <- c(starts[-1] - 1L, grep("^  \\];\\s*$", lines)[1] - 1L)
  Map(function(start, end) paste(lines[start:end], collapse = "\n"), starts, ends)
}

contract_aliases <- function(contract_js) {
  entries <- extract_contract_entries(contract_js)
  unlist(lapply(entries, function(entry) {
    aliases_start <- regexpr("aliases:", entry, fixed = TRUE)[[1]]
    module_start <- regexpr("module:", entry, fixed = TRUE)[[1]]
    expect_true(aliases_start > 0)
    expect_true(module_start > aliases_start)
    extract_js_strings(substr(entry, aliases_start, module_start - 1L))
  }), use.names = FALSE)
}

registered_aliases <- function() {
  geom_dir <- c(
    "inst/htmlwidgets/modules/geoms",
    file.path("..", "..", "inst", "htmlwidgets", "modules", "geoms"),
    system.file("htmlwidgets/modules/geoms", package = "gg2d3")
  )
  geom_dir <- geom_dir[nzchar(geom_dir) & dir.exists(geom_dir)][1]
  if (is.na(geom_dir)) {
    stop("Cannot find geom module directory", call. = FALSE)
  }

  files <- list.files(geom_dir, pattern = "\\.js$", full.names = TRUE)
  aliases <- unlist(lapply(files, function(file) {
    src <- paste(readLines(file, warn = FALSE), collapse = "\n")
    calls <- gregexpr("geomRegistry\\.register\\([^;]+\\);", src, perl = TRUE)[[1]]
    if (identical(calls, -1L)) {
      return(character())
    }
    extract_js_strings(paste(regmatches(src, list(calls))[[1]], collapse = "\n"))
  }), use.names = FALSE)
  sort(unique(aliases))
}

contract_update_selectors <- function(contract_js) {
  entries <- extract_contract_entries(contract_js)
  selectors <- unlist(lapply(entries, function(entry) {
    update_start <- regexpr("update:", entry, fixed = TRUE)[[1]]
    interactions_start <- regexpr("interactions:", entry, fixed = TRUE)[[1]]
    expect_true(update_start > 0)
    expect_true(interactions_start > update_start)
    update_block <- substr(entry, update_start, interactions_start - 1L)
    if (grepl("type: 'explicit-none'|type: \"explicit-none\"", update_block)) {
      return(character())
    }
    setdiff(extract_js_strings(update_block), c("selectors", "explicit-none"))
  }), use.names = FALSE)
  sort(unique(selectors))
}

contract_interaction_selectors <- function(contract_js, surface) {
  entries <- extract_contract_entries(contract_js)
  selectors <- unlist(lapply(entries, function(entry) {
    lines <- strsplit(entry, "\n", fixed = TRUE)[[1]]
    start <- grep(paste0("^        ", surface, ":"), lines)
    if (length(start) == 0L) {
      return(character())
    }
    starts <- grep("^        (events|brush|crosstalk):", lines)
    private_start <- grep("^      privateFields:", lines)
    end_candidates <- c(starts[starts > start[1]], private_start[private_start > start[1]])
    end <- if (length(end_candidates)) min(end_candidates) - 1L else length(lines)
    strings <- extract_js_strings(paste(lines[start[1]:end], collapse = "\n"))
    strings[grepl("^(\\.|[a-zA-Z]+[.#])", strings)]
  }), use.names = FALSE)
  sort(unique(selectors))
}

test_that("geom contract lists every registered renderer alias", {
  contract_js <- read_module("inst/htmlwidgets/modules/geom-contracts.js")

  expect_setequal(contract_aliases(contract_js), registered_aliases())
})

test_that("registered renderer aliases are covered by geom contract", {
  contract_js <- read_module("inst/htmlwidgets/modules/geom-contracts.js")
  expected_aliases <- c(
    "point", "line", "path", "polygon", "bar", "col", "rect", "tile",
    "text", "area", "ribbon", "segment", "hline", "vline", "abline",
    "dotplot", "rug", "errorbar", "linerange", "pointrange", "boxplot",
    "violin", "density", "smooth", "sf", "sf_text", "sf_label"
  )

  aliases <- contract_aliases(contract_js)
  expect_true(all(expected_aliases %in% aliases))
  expect_true(all(registered_aliases() %in% aliases))
})

test_that("geom contract update selectors match updateGeoms source", {
  contract_js <- read_module("inst/htmlwidgets/modules/geom-contracts.js")
  registry_js <- read_module("inst/htmlwidgets/modules/geom-registry.js")

  selectors <- contract_update_selectors(contract_js)
  expect_true(length(selectors) > 0)
  for (selector in selectors) {
    expect_true(
      grepl(selector, registry_js, fixed = TRUE),
      info = paste("Missing updateGeoms selector:", selector)
    )
  }
})

test_that("geom contract exposes private renderer fields", {
  contract_js <- read_module("inst/htmlwidgets/modules/geom-contracts.js")
  private_fields <- c(
    "_polygonPoints", "_sourceIndex", "_geom", "_centroid",
    "_sfFamily", "_sfAnchor", "_pointCoord", "_pointIndex"
  )

  for (field in private_fields) {
    expect_match(contract_js, field, fixed = TRUE)
  }
})

test_that("events and brush selector contracts cover interactive geoms", {
  contract_js <- read_module("inst/htmlwidgets/modules/geom-contracts.js")
  events_js <- read_module("inst/htmlwidgets/modules/events.js")
  brush_js <- read_module("inst/htmlwidgets/modules/brush.js")
  expected <- c(
    "circle.geom-point", "rect.geom-bar", "rect.geom-rect",
    "path.geom-line", "path.geom-polygon", "path.geom-area",
    "path.geom-density", "path.geom-smooth", "path.geom-ribbon",
    "path.geom-violin", ".geom-sf", "text.geom-text",
    "line.geom-segment", "rect.geom-boxplot-box",
    "circle.geom-boxplot-outlier", "circle.geom-dotplot",
    "line.geom-rug", "line.interval-line", "line.errorbar-cap-top",
    "line.errorbar-cap-bottom", "circle.pointrange-point"
  )

  expect_true(all(expected %in% contract_interaction_selectors(contract_js, "events")))
  expect_true(all(expected %in% contract_interaction_selectors(contract_js, "brush")))
  expect_match(events_js, "selectorsFor\\('events'\\)")
  expect_match(brush_js, "selectorsFor\\('brush'\\)")
})

test_that("crosstalk selector contract preserves intentional differences", {
  contract_js <- read_module("inst/htmlwidgets/modules/geom-contracts.js")
  crosstalk_js <- read_module("inst/htmlwidgets/modules/crosstalk.js")
  expected <- c(
    "circle.geom-point", "rect.geom-bar", "rect.geom-rect",
    "path.geom-line", "path.geom-polygon", "path.geom-area",
    "path.geom-density", "path.geom-smooth", "path.geom-ribbon",
    "path.geom-violin", ".geom-sf", "text.geom-text",
    "line.geom-segment", "rect.geom-boxplot-box",
    "circle.geom-boxplot-outlier"
  )

  expect_true(all(expected %in% contract_interaction_selectors(contract_js, "crosstalk")))
  expect_match(crosstalk_js, "selectorsFor\\('crosstalk'\\)")
  expect_match(contract_js, "crosstalk.js does not currently bind dotplot marks", fixed = TRUE)
  expect_match(contract_js, "crosstalk.js does not currently bind rug marks", fixed = TRUE)
  expect_match(contract_js, "crosstalk.js does not currently bind interval component marks", fixed = TRUE)
})

test_that("public data sanitizer strips underscore-prefixed fields", {
  public_data_js <- read_module("inst/htmlwidgets/modules/public-data.js")
  yaml <- read_module("inst/htmlwidgets/gg2d3.yaml")

  expect_match(public_data_js, "window.gg2d3.publicData", fixed = TRUE)
  expect_match(public_data_js, "sanitizeDatum", fixed = TRUE)
  expect_match(public_data_js, "publicFieldNames", fixed = TRUE)
  expect_true(grepl("String\\(key\\)\\.startsWith\\('_'\\)|key\\.startsWith\\('_'\\)", public_data_js))
  expect_lt(
    regexpr("public-data\\.js", yaml)[[1]],
    regexpr("tooltip\\.js", yaml)[[1]]
  )
})

test_that("tooltip events and brush delegate to public sanitizer", {
  events_js <- read_module("inst/htmlwidgets/modules/events.js")
  brush_js <- read_module("inst/htmlwidgets/modules/brush.js")
  tooltip_js <- read_module("inst/htmlwidgets/modules/tooltip.js")

  expect_match(events_js, "sanitizeEventDatum", fixed = TRUE)
  expect_match(brush_js, "sanitizeSelectedDatum", fixed = TRUE)
  expect_match(tooltip_js, "sanitizeTooltipDatum", fixed = TRUE)

  for (js in list(events_js, brush_js, tooltip_js)) {
    expect_match(js, "publicData.sanitizeDatum", fixed = TRUE)
  }
  expect_match(tooltip_js, "config.fields.filter(k => !String(k).startsWith('_'))", fixed = TRUE)
})

test_that("polygon and sf private fields are contract-covered", {
  contract_js <- read_module("inst/htmlwidgets/modules/geom-contracts.js")
  test_sources <- paste(
    read_module("tests/testthat/test-polygon-interactivity.R"),
    read_module("tests/testthat/test-sf-interactivity.R"),
    read_module("tests/testthat/test-sf-annotations-interactivity.R"),
    sep = "\n"
  )
  private_fields <- c(
    "_polygonPoints", "_sourceIndex", "_geom", "_centroid",
    "_sfFamily", "_sfAnchor", "_pointCoord", "_pointIndex"
  )

  for (field in private_fields) {
    expect_match(contract_js, field, fixed = TRUE)
    expect_match(test_sources, field, fixed = TRUE)
  }
})
