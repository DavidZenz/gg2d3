# Test simple (non-stacked) bars
library(ggplot2)
library(htmlwidgets)

cat("Reinstalling package...\n")
install.packages(".", repos = NULL, type = "source", quiet = TRUE)
library(gg2d3)

# Simple aggregated data (no stacking)
df <- data.frame(
  cyl = c("4", "6", "8"),
  avg_mpg = c(26.7, 19.7, 15.1)
)

cat("Creating simple bar chart...\n")
p <- ggplot(df, aes(x=cyl, y=avg_mpg, fill=cyl)) +
  geom_col() +
  ggtitle("Simple Bar Chart Test")

# Check if this creates ymin/ymax or not
ir <- as_d3_ir(p)
cat("\nData structure check:\n")
cat("Has ymin:", "ymin" %in% names(ir$layers[[1]]$data[[1]]), "\n")
cat("Has ymax:", "ymax" %in% names(ir$layers[[1]]$data[[1]]), "\n")
cat("Number of data points:", length(ir$layers[[1]]$data), "\n")

cat("\nGenerating widget...\n")
w <- gg2d3(p)

f <- "test_simple_bars.html"
saveWidget(w, f, selfcontained = TRUE)

cat("\n✓ Saved to:", f, "\n")
cat("\nExpected:\n")
cat("  - Three bars at positions: 4, 6, 8\n")
cat("  - Heights: ~26.7, ~19.7, ~15.1\n")
cat("  - Different colors for each bar\n\n")

browseURL(f)
