if (!isNamespaceLoaded("gg2d3")) pkgload::load_all(quiet = TRUE)

library(ggplot2)

read_repo_file <- function(path) {
  installed_path <- system.file(sub("^inst/", "", path), package = "gg2d3")
  candidates <- c(path, file.path("..", "..", path), installed_path)
  existing <- candidates[file.exists(candidates)]
  if (length(existing) == 0L) {
    stop("Could not find file: ", path, call. = FALSE)
  }
  paste(readLines(existing[[1]], warn = FALSE), collapse = "\n")
}

test_that("GEOM-01 ordinary labels declare bounded box IR and renderer support", {
  plot <- ggplot(
    data.frame(x = 1, y = 2, label = "A"),
    aes(x, y, label = label)
  ) +
    geom_label(
      fill = "white",
      colour = "black",
      alpha = 0.7,
      size = 4,
      linewidth = 0.4,
      label.padding = grid::unit(0.2, "lines"),
      hjust = 0,
      vjust = 1,
      angle = 30,
      family = "serif"
    )

  ir <- as_d3_ir(plot)
  layer <- ir$layers[[1]]
  row <- layer$data[[1]]
  text_js <- read_repo_file("inst/htmlwidgets/modules/geoms/text.js")

  expect_equal(layer$geom, "label")
  expect_equal(row$label, "A")
  expect_equal(row$fill, "white")
  expect_equal(row$colour, "black")
  expect_equal(row$alpha, 0.7)
  expect_equal(row$size, 4)
  expect_equal(row$linewidth, 0.4)
  expect_equal(row$hjust, 0)
  expect_equal(row$vjust, 1)
  expect_equal(row$angle, 30)
  expect_equal(row$family, "serif")
  expect_true(is.list(layer$params$label))
  expect_true(is.numeric(layer$params$label$padding))
  expect_gt(layer$params$label$padding, 0)
  expect_no_warning(validate_ir(ir))

  expect_match(text_js, "geomRegistry\\.register\\(\\['text', 'label'\\]")
  expect_match(text_js, "g\\.geom-label")
  expect_match(text_js, "rect\\.geom-label-box")
  expect_match(text_js, "text\\.geom-label-text")
  expect_match(text_js, "getBBox\\(")
  expect_match(text_js, "\\.text\\(")
})

test_that("GEOM-04 ordinary text and label preserve small placement fields", {
  text_plot <- ggplot(
    data.frame(x = 1, y = 2, label = "A"),
    aes(x, y, label = label)
  ) +
    geom_text(hjust = 0.25, vjust = 0.75, angle = 15, family = "mono")

  label_plot <- ggplot(
    data.frame(x = 1, y = 2, label = "B"),
    aes(x, y, label = label)
  ) +
    geom_label(hjust = 1, vjust = 0, angle = -30, family = "serif")

  text_row <- as_d3_ir(text_plot)$layers[[1]]$data[[1]]
  label_row <- as_d3_ir(label_plot)$layers[[1]]$data[[1]]
  text_js <- read_repo_file("inst/htmlwidgets/modules/geoms/text.js")

  expect_equal(text_row$hjust, 0.25)
  expect_equal(text_row$vjust, 0.75)
  expect_equal(text_row$angle, 15)
  expect_equal(text_row$family, "mono")
  expect_equal(label_row$hjust, 1)
  expect_equal(label_row$vjust, 0)
  expect_equal(label_row$angle, -30)
  expect_equal(label_row$family, "serif")

  expect_match(text_js, "function textAnchor")
  expect_match(text_js, "function dominantBaseline")
  expect_match(text_js, "function rotationTransform")
  expect_match(text_js, "font-family")
  expect_match(text_js, "text-anchor")
  expect_match(text_js, "dominant-baseline")
  expect_match(text_js, "rotate\\(")
})

test_that("GEOM-04 algorithmic label placement remains an explicit non-goal", {
  text_js <- read_repo_file("inst/htmlwidgets/modules/geoms/text.js")

  expect_match(text_js, "geom-text")
  expect_match(text_js, "geom-label")
  expect_false(grepl(".html(", text_js, fixed = TRUE))
  expect_false(grepl("innerHTML", text_js, fixed = TRUE))
  expect_false(grepl("foreignObject", text_js, fixed = TRUE))
  expect_false(grepl("ggrepel", text_js, fixed = TRUE))
  expect_false(grepl("collision", text_js, fixed = TRUE))
  expect_false(grepl("path-following", text_js, fixed = TRUE))
  expect_false(grepl("rich text", text_js, fixed = TRUE))
  expect_false(grepl("textPath", text_js, fixed = TRUE))
})
