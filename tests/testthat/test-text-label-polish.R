if (!isNamespaceLoaded("gg2d3")) pkgload::load_all(quiet = TRUE)

library(ggplot2)

read_repo_file <- function(path) {
  candidates <- c(path, file.path("..", "..", path))
  existing <- candidates[file.exists(candidates)]
  if (length(existing) == 0L) {
    stop("Could not find file: ", path, call. = FALSE)
  }
  paste(readLines(existing[[1]], warn = FALSE), collapse = "\n")
}

test_that("GEOM-03 ordinary geom_text keeps basic label aesthetics in IR", {
  plot <- ggplot(
    data.frame(x = 1, y = 2, label = "A"),
    aes(x, y, label = label)
  ) +
    geom_text(size = 5, colour = "red", alpha = 0.5)

  ir <- as_d3_ir(plot)
  layer <- ir$layers[[1]]
  row <- layer$data[[1]]

  expect_equal(layer$geom, "text")
  expect_equal(row$label, "A")
  expect_equal(row$size, 5)
  expect_equal(row$colour, "red")
  expect_equal(row$alpha, 0.5)
  expect_no_warning(validate_ir(ir))
})

test_that("GEOM-03 ordinary geom_label currently maps to text IR without label box renderer", {
  plot <- ggplot(
    data.frame(x = 1, y = 2, label = "A"),
    aes(x, y, label = label)
  ) +
    geom_label(size = 4, fill = "white", colour = "black")

  ir <- as_d3_ir(plot)
  layer <- ir$layers[[1]]
  text_js <- read_repo_file("inst/htmlwidgets/modules/geoms/text.js")

  expect_equal(layer$geom, "text")
  expect_true("fill" %in% names(layer$data[[1]]))
  expect_match(text_js, "geomRegistry\\.register\\('text'")
  expect_false(grepl("geom-label", text_js, fixed = TRUE))
  expect_false(grepl("label-box", text_js, fixed = TRUE))
})

test_that("GEOM-03 ordinary text renderer is centered SVG text with mapped size support", {
  text_js <- read_repo_file("inst/htmlwidgets/modules/geoms/text.js")

  expect_match(text_js, "text\\.geom-text|geom-text")
  expect_match(text_js, "dominant-baseline\", \"middle\"")
  expect_match(text_js, "text-anchor\", \"middle\"")
  expect_match(text_js, "function textSize")
  expect_match(text_js, "PX_PER_MM")
  expect_match(text_js, "val\\(get\\(d, \"size\"\\)\\)")
  expect_match(text_js, "font-size\", d => textSize\\(d\\)")
})

test_that("GEOM-03 ordinary text renderer does not implement collision or path-following placement", {
  text_js <- read_repo_file("inst/htmlwidgets/modules/geoms/text.js")

  expect_false(grepl("ggrepel", text_js, fixed = TRUE))
  expect_false(grepl("collision", text_js, fixed = TRUE))
  expect_false(grepl("path-follow", text_js, fixed = TRUE))
  expect_false(grepl("textPath", text_js, fixed = TRUE))
})
