if (!isNamespaceLoaded("gg2d3")) pkgload::load_all(quiet = TRUE)

read_repo_file <- function(path) {
  installed_path <- system.file(sub("^inst/", "", path), package = "gg2d3")
  candidates <- c(path, file.path("..", "..", path), installed_path)
  existing <- candidates[nzchar(candidates) & file.exists(candidates)]
  if (length(existing) == 0L) {
    stop("Could not find file: ", path, call. = FALSE)
  }
  paste(readLines(existing[[1]], warn = FALSE), collapse = "\n")
}

test_that("SFANN-02 panel renderer filters sf annotation data and geometries together", {
  gg2d3_js <- read_repo_file("inst/htmlwidgets/gg2d3.js")

  expect_match(gg2d3_js, "isSfLikeLayer")
  expect_match(gg2d3_js, '"sf_text"')
  expect_match(gg2d3_js, '"sf_label"')
  expect_match(gg2d3_js, "sfPairs")
  expect_match(gg2d3_js, "filteredPairs")
  expect_match(gg2d3_js, "geometries: filteredPairs\\.map")
  expect_match(gg2d3_js, "sfBBox:")
  expect_match(gg2d3_js, "panelData && panelData\\.sf_bbox")
})

test_that("SFANN-02 sf renderer declares annotation projection and anchor helpers", {
  sf_js <- read_repo_file("inst/htmlwidgets/modules/geoms/sf.js")

  expect_match(sf_js, "renderSfAnnotation")
  expect_match(sf_js, "renderSfText")
  expect_match(sf_js, "renderSfLabel")
  expect_match(sf_js, "pathGen\\.centroid")
  expect_match(sf_js, "projectedCoordinate")
  expect_match(sf_js, "bboxToFeatureCollection")
  expect_match(sf_js, "options\\.sfBBox")
  expect_match(sf_js, "data-cx")
  expect_match(sf_js, "data-cy")
  expect_match(sf_js, "data-row-id")
})

test_that("SFANN-02 sf renderer declares text and label DOM contracts", {
  sf_js <- read_repo_file("inst/htmlwidgets/modules/geoms/sf.js")

  expect_match(sf_js, "geom-sf-text")
  expect_match(sf_js, "geom-sf-label")
  expect_match(sf_js, "geom-sf-label-box")
  expect_match(sf_js, "geom-sf-label-text")
  expect_match(sf_js, "register\\('sf_text'")
  expect_match(sf_js, "register\\('sf_label'")
})

test_that("SFANN-02 sf renderer module remains vendored in widget yaml", {
  yaml <- read_repo_file("inst/htmlwidgets/gg2d3.yaml")

  expect_match(yaml, "geoms/sf\\.js")
})
