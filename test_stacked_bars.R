# Test stacked bar fix
library(ggplot2)
library(htmlwidgets)

cat("Reinstalling package with stacked bar fix...\n")
install.packages(".", repos = NULL, type = "source", quiet = TRUE)
library(gg2d3)

cat("Creating bar chart with factor(cyl)...\n")
p <- ggplot(mtcars, aes(x=factor(cyl), y=mpg, fill=factor(cyl))) +
  geom_col() +
  ggtitle("Bar Chart Test - Should show 3 bars")

cat("Generating widget...\n")
w <- gg2d3(p)

f <- "test_stacked_bars.html"
saveWidget(w, f, selfcontained = TRUE)

cat("\n✓ Saved to:", f, "\n")
cat("\nExpected:\n")
cat("  - Three bars at x positions: 4, 6, 8\n")
cat("  - Each bar should be a different color\n")
cat("  - Heights should match ggplot2 output\n\n")

cat("Opening in browser...\n")
browseURL(f)
