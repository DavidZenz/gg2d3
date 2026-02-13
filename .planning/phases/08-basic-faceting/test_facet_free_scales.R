# Test facet_wrap with free scales
library(ggplot2)

# Create faceted plot with free scales
p <- ggplot(mtcars, aes(x = wt, y = mpg)) +
  geom_point() +
  facet_wrap(~ cyl, scales = "free")

b <- ggplot_build(p)

cat("=== Free Scales Layout ===\n")
print(b$layout$layout)

cat("\n=== Number of x scales:", length(b$layout$panel_scales_x), "\n")
cat("Number of y scales:", length(b$layout$panel_scales_y), "\n")

cat("\n=== Panel 1 x range:\n")
print(b$layout$panel_params[[1]]$x.range)

cat("\n=== Panel 2 x range:\n")
print(b$layout$panel_params[[2]]$x.range)

cat("\n=== Panel 3 x range:\n")
print(b$layout$panel_params[[3]]$x.range)

cat("\n=== Facet free params:\n")
print(b$layout$facet$params$free)
