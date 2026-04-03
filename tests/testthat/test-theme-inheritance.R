library(ggplot2)
devtools::load_all()

test_that("element_blank is correctly captured in IR", {
  p <- ggplot(mtcars, aes(wt, mpg)) +
    geom_point() +
    theme(axis.text.x = element_blank(),
          panel.grid.major = element_blank())
  ir <- as_d3_ir(p)

  expect_equal(ir$theme$axis$text.x$type, "blank")
  expect_equal(ir$theme$grid$major$type, "blank")
})

test_that("specific theme overrides are captured", {
  p <- ggplot(mtcars, aes(wt, mpg)) +
    geom_point() +
    theme(axis.text = element_text(colour = "red"),
          axis.text.x = element_text(colour = "blue"))
  ir <- as_d3_ir(p)

  # R resolves this via calc_element
  expect_equal(ir$theme$axis$text$colour, "red")
  expect_equal(ir$theme$axis$text.x$colour, "blue")
})

test_that("legend background and margin are extracted", {
  p <- ggplot(mtcars, aes(wt, mpg, colour = factor(cyl))) +
    geom_point() +
    theme_gray() +
    theme(legend.background = element_rect(fill = "yellow", colour = "black"),
          legend.margin = margin(10, 10, 10, 10))
  ir <- as_d3_ir(p)

  str(ir$theme$legend$margin)
  expect_equal(ir$theme$legend$background$fill, "yellow")
  expect_equal(ir$theme$legend$background$colour, "black")
  # 10pt = 10 * 96/72.27 = 13.28px
  expect_equal(round(ir$theme$legend$margin$top, 2), 13.28)
})

test_that("text justifications and angles are captured", {
  p <- ggplot(mtcars, aes(wt, mpg)) +
    geom_point() +
    theme(axis.title.x = element_text(hjust = 1, angle = 45))
  ir <- as_d3_ir(p)

  expect_equal(ir$theme$axis$title.x$hjust, 1)
  expect_equal(ir$theme$axis$title.x$angle, 45)
})
