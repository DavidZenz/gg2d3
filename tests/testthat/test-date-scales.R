library(ggplot2)

.date_scale_test_output_dir <- function() {
  if (exists(".test_output_dir", mode = "function")) {
    return(.test_output_dir())
  }

  pkg_root <- NULL
  if (requireNamespace("rprojroot", quietly = TRUE)) {
    pkg_root <- tryCatch(
      rprojroot::find_package_root_file(),
      error = function(e) NULL
    )
  }

  if (is.null(pkg_root)) {
    candidates <- normalizePath(
      c(getwd(), file.path(getwd(), "../.."), file.path(getwd(), "../../..")),
      mustWork = FALSE
    )
    is_pkg_root <- file.exists(file.path(candidates, "DESCRIPTION")) &
      dir.exists(file.path(candidates, "R"))
    pkg_root <- candidates[is_pkg_root][1]
  }

  if (is.null(pkg_root) || is.na(pkg_root)) {
    pkg_root <- normalizePath(getwd(), mustWork = FALSE)
  }

  file.path(pkg_root, "test_output")
}

# --- Date scale basics ---
test_that("Date x-axis produces temporal scale with ms domain", {
  df <- data.frame(
    date = as.Date(c("2024-01-01", "2024-06-01", "2024-12-31")),
    y = c(1, 5, 3)
  )
  p <- ggplot(df, aes(date, y)) + geom_point()
  ir <- as_d3_ir(p)

  expect_equal(ir$scales$x$type, "continuous")
  expect_equal(ir$scales$x$transform, "date")

  # Domain should be in milliseconds (Date epoch = days * 86400000)
  expect_true(all(ir$scales$x$domain > 1e12))
  # Breaks should also be in ms
  expect_gt(length(ir$scales$x$breaks), 0)
  expect_true(all(ir$scales$x$breaks > 1e12))
  # Data values should be in ms
  expect_true(ir$layers[[1]]$data[[1]]$x > 1e12)
})

# --- POSIXct scale basics ---
test_that("POSIXct x-axis produces temporal scale with ms domain", {
  df <- data.frame(
    time = as.POSIXct(c("2024-01-01 10:00", "2024-01-01 14:00"), tz = "UTC"),
    y = c(1, 2)
  )
  p <- ggplot(df, aes(time, y)) + geom_point()
  ir <- as_d3_ir(p)

  expect_equal(ir$scales$x$type, "continuous")
  expect_equal(ir$scales$x$transform, "time")
  expect_true(all(ir$scales$x$domain > 1e12))
  expect_gt(length(ir$scales$x$breaks), 0)
  expect_true(all(ir$scales$x$breaks > 1e12))
})

# --- Timezone extraction ---
test_that("timezone extracted from scale_x_datetime", {
  df <- data.frame(
    time = as.POSIXct(c("2024-01-01 10:00", "2024-01-01 14:00"), tz = "America/New_York"),
    y = c(1, 2)
  )
  p <- ggplot(df, aes(time, y)) + geom_point() +
    scale_x_datetime(timezone = "America/New_York")
  ir <- as_d3_ir(p)

  expect_equal(ir$scales$x$timezone, "America/New_York")
})

# --- Format pattern extraction ---
test_that("date_labels format pattern extracted", {
  df <- data.frame(
    date = as.Date(c("2024-01-01", "2024-06-01")),
    y = c(1, 2)
  )
  p <- ggplot(df, aes(date, y)) + geom_point() +
    scale_x_date(date_labels = "%Y-%m-%d")
  ir <- as_d3_ir(p)

  expect_equal(ir$scales$x$format, "%Y-%m-%d")
})

test_that("default date scale has NULL format (auto-format)", {
  df <- data.frame(
    date = as.Date(c("2024-01-01", "2024-06-01")),
    y = c(1, 2)
  )
  p <- ggplot(df, aes(date, y)) + geom_point()
  ir <- as_d3_ir(p)

  # Without explicit date_labels, format should be NULL
  expect_null(ir$scales$x$format)
})

# --- Date on y-axis ---
test_that("Date on y-axis works", {
  df <- data.frame(
    x = c(1, 2, 3),
    date = as.Date(c("2024-01-01", "2024-06-01", "2024-12-31"))
  )
  p <- ggplot(df, aes(x, date)) + geom_point()
  ir <- as_d3_ir(p)

  expect_equal(ir$scales$y$transform, "date")
  expect_gt(length(ir$scales$y$breaks), 0)
  expect_true(all(ir$scales$y$breaks > 1e12))
  expect_true(all(ir$scales$y$domain > 1e12))
})

# --- coord_flip with temporal axis ---
test_that("coord_flip with Date x-axis works", {
  df <- data.frame(
    date = as.Date(c("2024-01-01", "2024-06-01", "2024-12-31")),
    y = c(1, 5, 3)
  )
  p <- ggplot(df, aes(date, y)) + geom_point() + coord_flip()
  ir <- as_d3_ir(p)

  # After coord_flip, the date axis should maintain transform metadata
  # Check that one of the scales has the date transform
  has_date <- (identical(ir$scales$x$transform, "date") ||
               identical(ir$scales$y$transform, "date"))
  expect_true(has_date)
})

# --- Multiple geoms with date axis ---
test_that("geom_line with Date x-axis works", {
  set.seed(42)
  df <- data.frame(
    date = as.Date("2024-01-01") + 0:11 * 30,
    y = cumsum(rnorm(12))
  )
  p <- ggplot(df, aes(date, y)) + geom_line() + geom_point()
  ir <- as_d3_ir(p)

  expect_equal(ir$scales$x$transform, "date")
  expect_length(ir$layers, 2)
  # Both layers should have ms timestamps for x
  expect_true(ir$layers[[1]]$data[[1]]$x > 1e12)
  expect_true(ir$layers[[2]]$data[[1]]$x > 1e12)
})

test_that("geom_col with Date x-axis works", {
  df <- data.frame(
    date = as.Date(c("2024-01-01", "2024-02-01", "2024-03-01")),
    y = c(3, 5, 2)
  )
  p <- ggplot(df, aes(date, y)) + geom_col()
  ir <- as_d3_ir(p)

  expect_equal(ir$scales$x$transform, "date")
  # Bar data should have xmin/xmax in ms
  expect_true(ir$layers[[1]]$data[[1]]$xmin > 1e12)
  expect_true(ir$layers[[1]]$data[[1]]$xmax > 1e12)
})

# --- Pre-formatted labels ---
test_that("pre-formatted labels included for temporal scales", {
  df <- data.frame(
    date = as.Date(c("2024-01-01", "2024-06-01", "2024-12-31")),
    y = c(1, 5, 3)
  )
  p <- ggplot(df, aes(date, y)) + geom_point()
  ir <- as_d3_ir(p)

  # Labels should be character strings (pre-formatted by ggplot2)
  expect_true(!is.null(ir$scales$x$labels))
  expect_true(is.character(ir$scales$x$labels))
  expect_true(length(ir$scales$x$labels) > 0)
})

# --- Non-temporal regression check ---
test_that("numeric scales unchanged by temporal support", {
  df <- data.frame(x = c(1, 2, 3), y = c(4, 5, 6))
  p <- ggplot(df, aes(x, y)) + geom_point()
  ir <- as_d3_ir(p)

  expect_null(ir$scales$x$format)
  expect_null(ir$scales$x$timezone)
  expect_null(ir$scales$x$labels)
})

# --- Date scale parity (breaks and labels) ---
test_that("date_breaks correctly influences IR breaks", {
  df <- data.frame(
    date = as.Date("2024-01-01") + 0:100,
    y = 1:101
  )
  # Default breaks vs 1 month breaks
  p1 <- ggplot(df, aes(date, y)) + geom_point() + scale_x_date(date_breaks = "1 month")
  ir1 <- as_d3_ir(p1)

  p2 <- ggplot(df, aes(date, y)) + geom_point() + scale_x_date(date_breaks = "2 weeks")
  ir2 <- as_d3_ir(p2)

  # Should have different number of breaks
  expect_true(length(ir1$scales$x$breaks) != length(ir2$scales$x$breaks))
  # All breaks should be in ms
  expect_gt(length(ir1$scales$x$breaks), 0)
  expect_gt(length(ir2$scales$x$breaks), 0)
  expect_true(all(ir1$scales$x$breaks > 1e12))
  expect_true(all(ir2$scales$x$breaks > 1e12))
  expect_false(identical(ir1$scales$x$breaks, ir2$scales$x$breaks))
})

test_that("date_labels extracted for both date and datetime scales", {
  df <- data.frame(
    date = as.Date("2024-01-01") + 0:5,
    time = as.POSIXct("2024-01-01 12:00", tz = "UTC") + (0:5)*3600,
    y = 1:6
  )

  # Date scale
  p_date <- ggplot(df, aes(date, y)) + geom_point() + scale_x_date(date_labels = "%d/%m")
  ir_date <- as_d3_ir(p_date)
  expect_equal(ir_date$scales$x$format, "%d/%m")

  # Datetime scale
  p_time <- ggplot(df, aes(time, y)) + geom_point() + scale_x_datetime(date_labels = "%H:%M")
  ir_time <- as_d3_ir(p_time)
  expect_equal(ir_time$scales$x$format, "%H:%M")
})

test_that("timezone robustly extracted even without explicit scale_x_datetime", {
  # POSIXct data has its own TZ which ggplot2 uses by default
  df <- data.frame(
    time = as.POSIXct("2024-01-01 12:00", tz = "America/New_York") + (0:1)*3600,
    y = 1:2
  )
  p <- ggplot(df, aes(time, y)) + geom_point()
  ir <- as_d3_ir(p)

  # Even without scale_x_datetime(timezone=...), it should ideally pick up the data's TZ
  # if ggplot2 propagates it to the scale.
  expect_equal(ir$scales$x$timezone, "America/New_York")
})

test_that("tooltips on date axes initialize correctly", {
  library(ggplot2)
  df <- data.frame(
    date = as.Date("2024-01-01") + 0:2,
    y = 1:3
  )
  p <- ggplot(df, aes(date, y)) + geom_point()
  w <- gg2d3(p) |> d3_tooltip()

  expect_true(w$x$interactivity$tooltip$enabled)
  # Check that date transform is preserved in IR within the widget
  expect_equal(w$x$ir$scales$x$transform, "date")
})

# --- Visual test ---
test_that("visual test: date/time scales render correctly", {
  skip_on_ci()
  skip_if_not(interactive() || identical(Sys.getenv("GG2D3_VISUAL_TESTS"), "true"))

  out_dir <- .date_scale_test_output_dir()
  dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

  # Test 1: Date x-axis with points and line
  set.seed(42)
  df1 <- data.frame(
    date = as.Date("2024-01-01") + seq(0, 365, by = 30),
    value = cumsum(rnorm(13))
  )
  p1 <- ggplot(df1, aes(date, value)) + geom_line() + geom_point() +
    scale_x_date(date_labels = "%b %Y") +
    ggtitle("Date X-Axis: Points + Line")

  # Test 2: POSIXct with hourly data
  df2 <- data.frame(
    time = as.POSIXct("2024-06-15 00:00", tz = "UTC") + (0:23) * 3600,
    temp = 20 + 10 * sin(seq(0, 2 * pi, length.out = 24)) + rnorm(24, sd = 1)
  )
  p2 <- ggplot(df2, aes(time, temp)) + geom_line() + geom_point() +
    scale_x_datetime(date_labels = "%H:%M") +
    ggtitle("POSIXct X-Axis: Hourly Data")

  # Test 3: Date on y-axis
  df3 <- data.frame(
    x = c(1, 2, 3),
    date = as.Date(c("2024-01-15", "2024-06-20", "2024-11-10"))
  )
  p3 <- ggplot(df3, aes(x, date)) + geom_point(size = 3) +
    ggtitle("Date Y-Axis")

  # Test 4: coord_flip with date axis
  p4 <- ggplot(df1, aes(date, value)) + geom_point() + coord_flip() +
    ggtitle("Date X-Axis + coord_flip")

  # Test 5: Bar chart with date axis
  df5 <- data.frame(
    month = as.Date(paste0("2024-", 1:12, "-01")),
    sales = c(120, 95, 150, 130, 170, 200, 180, 160, 140, 110, 90, 135)
  )
  p5 <- ggplot(df5, aes(month, sales)) + geom_col() +
    scale_x_date(date_labels = "%b") +
    ggtitle("Date X-Axis: Bar Chart")

  plots <- list(
    date_line = p1,
    posix_hourly = p2,
    date_y = p3,
    flipped_date = p4,
    date_bar = p5
  )

  for (name in names(plots)) {
    out_file <- file.path(out_dir, paste0("visual_test_", name, ".html"))
    htmlwidgets::saveWidget(
      gg2d3(plots[[name]]) |> d3_tooltip(),
      out_file,
      selfcontained = FALSE
    )
    expect_true(file.exists(out_file), info = name)
  }
})
