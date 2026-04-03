# Phase 7 Legend IR Extraction Tests
# Tests for guide (legend) structure in IR: discrete color/fill, size, shape, merged legends, colorbars

test_that("Discrete colour legend structure", {
  library(ggplot2)

  p <- ggplot(iris, aes(Sepal.Length, Sepal.Width, color = Species)) + geom_point()
  ir <- as_d3_ir(p)

  # Should have exactly one guide
  expect_equal(length(ir$guides), 1)

  # Guide should be type "legend" (discrete)
  expect_equal(ir$guides[[1]]$type, "legend")

  # Should have 3 keys (setosa, versicolor, virginica)
  expect_equal(length(ir$guides[[1]]$keys), 3)

  # Each key should have label and colour fields
  expect_true(all(sapply(ir$guides[[1]]$keys, function(k) "label" %in% names(k))))
  expect_true(all(sapply(ir$guides[[1]]$keys, function(k) "colour" %in% names(k))))

  # Colors should be valid hex strings (start with "#")
  colors <- sapply(ir$guides[[1]]$keys, function(k) k$colour)
  expect_true(all(grepl("^#", colors)))
})

test_that("Discrete fill legend structure", {
  library(ggplot2)

  p <- ggplot(mtcars, aes(factor(cyl), fill = factor(cyl))) + geom_bar()
  ir <- as_d3_ir(p)

  # Should have guide with fill values
  expect_true(length(ir$guides) >= 1)

  # Find the fill guide
  fill_guide <- ir$guides[[1]]
  expect_equal(fill_guide$type, "legend")

  # Keys should have fill field with hex colors
  expect_true(all(sapply(fill_guide$keys, function(k) "fill" %in% names(k))))

  # Fill values should be hex strings
  fills <- sapply(fill_guide$keys, function(k) k$fill)
  expect_true(all(grepl("^#", fills)))
})

test_that("Continuous colour legend (colorbar)", {
  library(ggplot2)

  p <- ggplot(iris, aes(Sepal.Length, Sepal.Width, color = Petal.Length)) + geom_point()
  ir <- as_d3_ir(p)

  # Should have colorbar guide
  expect_equal(length(ir$guides), 1)
  expect_equal(ir$guides[[1]]$type, "colorbar")

  # Should have colors array with many stops (>= 20)
  expect_true(is.character(ir$guides[[1]]$colors))
  expect_true(length(ir$guides[[1]]$colors) >= 20)

  # All colors should be hex strings
  expect_true(all(grepl("^#", ir$guides[[1]]$colors)))
})

test_that("Size legend", {
  library(ggplot2)

  p <- ggplot(iris, aes(Sepal.Length, Sepal.Width, size = Petal.Length)) + geom_point()
  ir <- as_d3_ir(p)

  # Should have guide
  expect_true(length(ir$guides) >= 1)

  # Guide type depends on whether continuous size produces legend or colorbar
  # Typically it's a legend with discrete size breaks
  size_guide <- ir$guides[[1]]

  # Keys should have size field with numeric values
  if (length(size_guide$keys) > 0) {
    expect_true(all(sapply(size_guide$keys, function(k) "size" %in% names(k))))
    sizes <- sapply(size_guide$keys, function(k) k$size)
    expect_true(is.numeric(sizes))
  }
})

test_that("Shape legend", {
  library(ggplot2)

  p <- ggplot(iris, aes(Sepal.Length, Sepal.Width, shape = Species)) + geom_point()
  ir <- as_d3_ir(p)

  # Should have guide with shape keys
  expect_equal(length(ir$guides), 1)

  shape_guide <- ir$guides[[1]]
  expect_equal(shape_guide$type, "legend")

  # Keys should have shape field
  expect_true(all(sapply(shape_guide$keys, function(k) "shape" %in% names(k))))
})

test_that("Legend merging (colour + shape same variable)", {
  library(ggplot2)

  p <- ggplot(iris, aes(Sepal.Length, Sepal.Width, color = Species, shape = Species)) +
    geom_point()
  ir <- as_d3_ir(p)

  # Should have exactly 1 merged guide (not 2 separate guides)
  expect_equal(length(ir$guides), 1)

  # Guide should have aesthetics containing both "colour" and "shape"
  aesthetics <- ir$guides[[1]]$aesthetics
  expect_true("colour" %in% aesthetics)
  expect_true("shape" %in% aesthetics)

  # Keys should have both colour and shape fields
  expect_true(all(sapply(ir$guides[[1]]$keys, function(k) "colour" %in% names(k))))
  expect_true(all(sapply(ir$guides[[1]]$keys, function(k) "shape" %in% names(k))))
})

test_that("No legend when no mapped aesthetics", {
  library(ggplot2)

  p <- ggplot(iris, aes(Sepal.Length, Sepal.Width)) + geom_point()
  ir <- as_d3_ir(p)

  # Should have no guides
  expect_equal(length(ir$guides), 0)
})

test_that("No legend when legend.position = none", {
  library(ggplot2)

  p <- ggplot(iris, aes(Sepal.Length, Sepal.Width, color = Species)) +
    geom_point() +
    theme(legend.position = "none")
  ir <- as_d3_ir(p)

  # Should have no guides
  expect_equal(length(ir$guides), 0)
})

test_that("Guide title from scale name", {
  library(ggplot2)

  p <- ggplot(iris, aes(Sepal.Length, Sepal.Width, color = Species)) +
    geom_point() +
    scale_color_discrete(name = "Flower Species")
  ir <- as_d3_ir(p)

  # Guide title should match scale name
  expect_equal(ir$guides[[1]]$title, "Flower Species")
})

test_that("Multiple separate legends (different variables)", {
  library(ggplot2)

  p <- ggplot(iris, aes(Sepal.Length, Sepal.Width, color = Species, size = Petal.Length)) +
    geom_point()
  ir <- as_d3_ir(p)

  # Should have 2 separate guides (color and size for different variables)
  expect_equal(length(ir$guides), 2)
})

test_that("Legend position extraction", {
  library(ggplot2)

  p <- ggplot(iris, aes(Sepal.Length, Sepal.Width, color = Species)) +
    geom_point() +
    theme(legend.position = "bottom")
  ir <- as_d3_ir(p)

  # Legend position should be extracted
  expect_equal(ir$legend$position, "bottom")
})

test_that("Alpha aesthetic legend", {
  library(ggplot2)

  p <- ggplot(iris, aes(Sepal.Length, Sepal.Width, alpha = Petal.Length)) + geom_point()
  ir <- as_d3_ir(p)

  # Alpha may or may not produce a guide depending on ggplot2 defaults
  # This test just ensures IR extraction doesn't crash
  expect_true(is.list(ir$guides))

  # If alpha guide exists, verify structure
  if (length(ir$guides) > 0) {
    alpha_guide <- ir$guides[[1]]
    expect_true(alpha_guide$type %in% c("legend", "colorbar"))
  }
})

test_that("interactive legend contract: discrete guides expose stable identity fields", {
  library(ggplot2)

  p <- ggplot(iris, aes(Sepal.Length, Sepal.Width, colour = Species)) +
    geom_point()
  ir <- as_d3_ir(p)

  expect_equal(length(ir$guides), 1)
  guide <- ir$guides[[1]]

  expect_equal(guide$type, "legend")
  expect_true("colour" %in% unlist(guide$aesthetics))
  expect_true(length(guide$keys) >= 3)

  expect_true(all(sapply(guide$keys, function(k) "label" %in% names(k))))
  expect_true(all(sapply(guide$keys, function(k) "value" %in% names(k))))
  expect_true(all(sapply(guide$keys, function(k) !is.null(k$value) && !is.na(k$value))))
})

test_that("interactive legend contract: merged discrete guides preserve identity values", {
  library(ggplot2)

  p <- ggplot(iris, aes(Sepal.Length, Sepal.Width, colour = Species, shape = Species)) +
    geom_point()
  ir <- as_d3_ir(p)

  expect_equal(length(ir$guides), 1)
  guide <- ir$guides[[1]]

  expect_equal(guide$type, "legend")
  expect_true(all(c("colour", "shape") %in% unlist(guide$aesthetics)))
  expect_true(all(sapply(guide$keys, function(k) all(c("value", "label", "colour", "shape") %in% names(k)))))
})

test_that("interactive legend contract: colorbar guides stay non-discrete", {
  library(ggplot2)

  p <- ggplot(iris, aes(Sepal.Length, Sepal.Width, colour = Petal.Length)) +
    geom_point()
  ir <- as_d3_ir(p)

  expect_equal(length(ir$guides), 1)
  guide <- ir$guides[[1]]

  expect_equal(guide$type, "colorbar")
  expect_true(is.null(guide$aesthetics) || !any(unlist(guide$aesthetics) %in% c("shape", "linetype")))
  expect_true(length(guide$colors) >= 20)
})

test_that("interactive legend contract: discrete legends carry reset-capable title semantics", {
  library(ggplot2)

  p <- ggplot(iris, aes(Sepal.Length, Sepal.Width, colour = Species)) +
    geom_point()
  ir <- as_d3_ir(p)

  expect_equal(length(ir$guides), 1)
  guide <- ir$guides[[1]]

  expect_equal(guide$type, "legend")
  expect_true("title" %in% names(guide))
  expect_true(is.character(guide$title))
  expect_true(nzchar(guide$title))
})

test_that("interactive legend contract: handles NA values in discrete scales", {
  library(ggplot2)
  df <- data.frame(x = 1:4, y = 1:4, g = c("A", "B", "A", NA))
  p <- ggplot(df, aes(x, y, colour = g)) + geom_point()
  ir <- as_d3_ir(p)

  expect_equal(length(ir$guides), 1)
  guide <- ir$guides[[1]]

  # ggplot2 usually includes (NA) in the legend if present in data
  # The interaction contract should still provide a stable 'value' for it
  labels <- sapply(guide$keys, function(k) k$label)
  values <- sapply(guide$keys, function(k) k$value)

  expect_true(any(is.na(labels)) || any(labels == "NA"))
  # Even for NA labels, we want a usable value or at least no crash
  expect_equal(length(values), length(labels))
})

test_that("interactive legend contract: multiple separate legends have distinct identities", {
  library(ggplot2)
  p <- ggplot(mtcars, aes(wt, mpg, colour = factor(cyl), shape = factor(am))) +
    geom_point()
  ir <- as_d3_ir(p)

  expect_equal(length(ir$guides), 2)

  # Both should be interactive legends
  expect_true(all(sapply(ir$guides, function(g) g$type == "legend")))

  # Each should have its own aesthetics
  aes_list <- lapply(ir$guides, function(g) unlist(g$aesthetics))
  expect_true(any(sapply(aes_list, function(a) "colour" %in% a)))
  expect_true(any(sapply(aes_list, function(a) "shape" %in% a)))

  # Each should have its own set of keys and values
  for (guide in ir$guides) {
    expect_true(all(sapply(guide$keys, function(k) "value" %in% names(k))))
  }
})
