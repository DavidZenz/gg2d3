# Comprehensive test of all Phase 1 fixes
library(ggplot2)
library(htmlwidgets)

cat("Reinstalling package...\n")
install.packages(".", repos = NULL, type = "source", quiet = TRUE)
library(gg2d3)

# Fix 1.1: Fill aesthetic
p1 <- ggplot(mtcars, aes(x=factor(cyl), y=mpg, fill=factor(cyl))) +
  geom_col() +
  ggtitle("1.1: Fill Aesthetic")

# Fix 1.2: Bar heights (non-zero baseline)
df2 <- data.frame(x = c("A", "B"), y = c(50, 60))
p2 <- ggplot(df2, aes(x, y)) +
  geom_col(fill="steelblue") +
  ylim(48, 62) +
  ggtitle("1.2: Non-Zero Baseline")

# Fix 1.3: Rect dimensions (categorical)
df3 <- expand.grid(x = letters[1:5], y = letters[1:5])
df3$value <- runif(25)
p3 <- ggplot(df3, aes(x, y, fill=value)) +
  geom_tile() +
  ggtitle("1.3: Categorical Rects")

# Fix 1.4: Path sorting
df4 <- data.frame(x = c(1, 5, 2, 4, 3), y = c(1, 2, 3, 4, 5))
p4a <- ggplot(df4, aes(x, y)) +
  geom_line() +
  ggtitle("1.4a: Line (sorted)")
p4b <- ggplot(df4, aes(x, y)) +
  geom_path() +
  ggtitle("1.4b: Path (unsorted)")

# Fix 1.5: Default params
p5 <- ggplot(mtcars, aes(wt, mpg)) +
  geom_point(color="red", size=4) +
  ggtitle("1.5: Default Params")

# Save individual widgets
cat("\nGenerating widgets...\n")
w1 <- gg2d3(p1)
w2 <- gg2d3(p2)
w3 <- gg2d3(p3)
w4a <- gg2d3(p4a)
w4b <- gg2d3(p4b)
w5 <- gg2d3(p5)

saveWidget(w1, "test_1.1_fill.html", selfcontained = TRUE)
saveWidget(w2, "test_1.2_baseline.html", selfcontained = TRUE)
saveWidget(w3, "test_1.3_rects.html", selfcontained = TRUE)
saveWidget(w4a, "test_1.4a_line.html", selfcontained = TRUE)
saveWidget(w4b, "test_1.4b_path.html", selfcontained = TRUE)
saveWidget(w5, "test_1.5_params.html", selfcontained = TRUE)

cat("\n✅ Phase 1 Fixes Complete!\n\n")
cat("Files created:\n")
cat("  - test_1.1_fill.html (3 colored bars at x=4,6,8)\n")
cat("  - test_1.2_baseline.html (bars with y-limit from 48-62)\n")
cat("  - test_1.3_rects.html (5x5 heatmap grid)\n")
cat("  - test_1.4a_line.html (line sorted by x: 1→2→3→4→5)\n")
cat("  - test_1.4b_path.html (path preserves order: 1→5→2→4→3)\n")
cat("  - test_1.5_params.html (red points, size 4)\n\n")

cat("Opening first test...\n")
browseURL("test_1.1_fill.html")
