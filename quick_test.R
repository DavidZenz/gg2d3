# Quick interactive test - auto-opens in browser
library(ggplot2)
library(htmlwidgets)
source("R/as_d3_ir.R")
source("R/gg2d3.R")

# Helper to create and open widget
view_widget <- function(widget, name = "test") {
  f <- tempfile(fileext = ".html")
  saveWidget(widget, f, selfcontained = TRUE)
  cat("Opening", name, "in browser...\n")
  browseURL(f)
  invisible(widget)
}

cat("\n=== Quick Test for gg2d3 Phase 1 Fixes ===\n\n")

# Test 1: Fill aesthetic
cat("Test 1: Fill aesthetic (should show colored bars)\n")
p1 <- ggplot(mtcars, aes(x=factor(cyl), y=mpg, fill=factor(cyl))) +
  geom_col() +
  ggtitle("Fill Aesthetic Test")
view_widget(gg2d3(p1), "Fill Aesthetic")

cat("\nPress Enter to continue to next test...")
readline()

# Test 2: Bar heights
cat("\nTest 2: Bar heights with non-zero baseline\n")
df <- data.frame(x = c("A", "B"), y = c(50, 60))
p2 <- ggplot(df, aes(x, y)) +
  geom_col() +
  ylim(48, 62) +
  ggtitle("Non-Zero Baseline Test")
view_widget(gg2d3(p2), "Bar Heights")

cat("\nPress Enter to continue to next test...")
readline()

# Test 3: Heatmap
cat("\nTest 3: Heatmap with categorical scales\n")
df <- expand.grid(x = letters[1:5], y = letters[1:5])
df$value <- runif(25)
p3 <- ggplot(df, aes(x, y, fill=value)) +
  geom_tile() +
  ggtitle("Heatmap Test")
view_widget(gg2d3(p3), "Heatmap")

cat("\nPress Enter to continue to next test...")
readline()

# Test 4: Path ordering
cat("\nTest 4: Path ordering (should zigzag, not sort)\n")
df <- data.frame(x = c(1, 5, 2, 4, 3), y = c(1, 2, 3, 4, 5))
p4 <- ggplot(df, aes(x, y)) +
  geom_path() +
  ggtitle("Path Order Test - Should Zigzag")
view_widget(gg2d3(p4), "Path Order")

cat("\nPress Enter to continue to next test...")
readline()

# Test 5: Default params
cat("\nTest 5: Default parameters (red, size 4)\n")
p5 <- ggplot(mtcars, aes(wt, mpg)) +
  geom_point(color="red", size=4) +
  ggtitle("Default Params Test")
view_widget(gg2d3(p5), "Default Params")

cat("\n=== All tests complete! ===\n")
