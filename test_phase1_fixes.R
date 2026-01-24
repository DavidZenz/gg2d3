# Test script for Phase 1 fixes
# Installs package locally so htmlwidgets can find JavaScript files

library(ggplot2)
library(htmlwidgets)

# Install package locally (required for htmlwidgets to find JS files)
cat("Installing gg2d3 package locally...\n")
install.packages(".", repos = NULL, type = "source", quiet = TRUE)
library(gg2d3)

# Create output directory
if (!dir.exists("test_output")) dir.create("test_output")

cat("Testing Phase 1 Fixes...\n")
cat("Saving HTML files to test_output/ directory\n\n")

# Fix 1.1: Fill aesthetic support
cat("Test 1.1: Fill aesthetic\n")
p1 <- ggplot(mtcars, aes(x=factor(cyl), y=mpg, fill=factor(cyl))) +
  geom_col() +
  ggtitle("Test 1.1: Fill Aesthetic")
w1 <- gg2d3(p1)
saveWidget(w1, "test_output/test_1.1_fill_aesthetic.html", selfcontained = TRUE)
cat("  Saved: test_output/test_1.1_fill_aesthetic.html\n")
cat("  Expected: Bars should show different fill colors (not all grey)\n\n")

# Fix 1.2: Bar heights with non-zero baseline
cat("Test 1.2: Bar heights with non-zero baseline\n")
df <- data.frame(x = c("A", "B"), y = c(50, 60))
p2 <- ggplot(df, aes(x, y)) +
  geom_col() +
  ylim(48, 62) +
  ggtitle("Test 1.2: Non-Zero Baseline")
w2 <- gg2d3(p2)
saveWidget(w2, "test_output/test_1.2_bar_heights.html", selfcontained = TRUE)
cat("  Saved: test_output/test_1.2_bar_heights.html\n")
cat("  Expected: Bars should extend from bottom (not clipped or negative height)\n\n")

# Fix 1.3: Rectangle dimensions with categorical scales
cat("Test 1.3: Rectangle dimensions\n")
df <- expand.grid(x = letters[1:5], y = letters[1:5])
df$value <- runif(25)
p3 <- ggplot(df, aes(x, y, fill=value)) +
  geom_tile() +
  ggtitle("Test 1.3: Categorical Scales")
w3 <- gg2d3(p3)
saveWidget(w3, "test_output/test_1.3_rect_dimensions.html", selfcontained = TRUE)
cat("  Saved: test_output/test_1.3_rect_dimensions.html\n")
cat("  Expected: Proper 5x5 heatmap grid (no missing/collapsed tiles)\n\n")

# Fix 1.4: Path sorting
cat("Test 1.4a: Line sorting\n")
df <- data.frame(x = c(1, 5, 2, 4, 3), y = c(1, 2, 3, 4, 5))
p4a <- ggplot(df, aes(x, y)) +
  geom_line() +
  ggtitle("Test 1.4a: geom_line (sorted)")
w4a <- gg2d3(p4a)
saveWidget(w4a, "test_output/test_1.4a_line_sorted.html", selfcontained = TRUE)
cat("  Saved: test_output/test_1.4a_line_sorted.html\n")
cat("  Expected: Line connects points in x-order (1,2,3,4,5) going up-right\n\n")

cat("Test 1.4b: Path ordering\n")
p4b <- ggplot(df, aes(x, y)) +
  geom_path() +
  ggtitle("Test 1.4b: geom_path (preserve order)")
w4b <- gg2d3(p4b)
saveWidget(w4b, "test_output/test_1.4b_path_order.html", selfcontained = TRUE)
cat("  Saved: test_output/test_1.4b_path_order.html\n")
cat("  Expected: Path follows data order creating zigzag (1->5->2->4->3)\n\n")

# Fix 1.5: Default parameters
cat("Test 1.5: Default parameters\n")
p5 <- ggplot(mtcars, aes(wt, mpg)) +
  geom_point(color="red", size=4) +
  ggtitle("Test 1.5: Default Parameters")
w5 <- gg2d3(p5)
saveWidget(w5, "test_output/test_1.5_default_params.html", selfcontained = TRUE)
cat("  Saved: test_output/test_1.5_default_params.html\n")
cat("  Expected: All points should be red and larger (size 4)\n\n")

# Combined test
cat("Test Combined: Fill aesthetic + bar heights\n")
p6 <- ggplot(mtcars, aes(x=factor(cyl), y=mpg, fill=factor(gear))) +
  geom_col() +
  ggtitle("Combined: Fill + Bar Heights")
w6 <- gg2d3(p6)
saveWidget(w6, "test_output/test_combined.html", selfcontained = TRUE)
cat("  Saved: test_output/test_combined.html\n")
cat("  Expected: Bars with different colors and proper heights\n\n")

cat("========================================\n")
cat("All tests completed!\n")
cat("HTML files saved to test_output/\n")
cat("========================================\n\n")

# Option to open first test in browser
cat("To view test 1.1 in your browser, run:\n")
cat("  browseURL('test_output/test_1.1_fill_aesthetic.html')\n\n")

cat("Or if in RStudio, just run: gg2d3(p1) to view in Viewer pane\n")
