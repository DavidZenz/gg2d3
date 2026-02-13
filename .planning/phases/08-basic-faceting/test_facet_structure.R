# Test script to understand ggplot_build() structure with facet_wrap
library(ggplot2)

# Create a simple faceted plot
p <- ggplot(mtcars, aes(x = wt, y = mpg)) +
  geom_point() +
  facet_wrap(~ cyl, nrow = 2) +
  labs(title = "MPG by Weight", subtitle = "Faceted by Cylinder")

# Build the plot
b <- ggplot_build(p)

# Investigate structure
cat("=== Layout Structure ===\n")
print(str(b$layout, max.level = 2))

cat("\n=== Layout$layout dataframe ===\n")
print(b$layout$layout)

cat("\n=== Panel Params Length ===\n")
cat("Number of panel_params:", length(b$layout$panel_params), "\n")

cat("\n=== First Panel Params ===\n")
print(str(b$layout$panel_params[[1]], max.level = 1))

cat("\n=== Panel Scales X ===\n")
cat("Number of x scales:", length(b$layout$panel_scales_x), "\n")

cat("\n=== Panel Scales Y ===\n")
cat("Number of y scales:", length(b$layout$panel_scales_y), "\n")

cat("\n=== Layer Data (first layer) ===\n")
cat("Columns in first layer data:\n")
print(names(b$data[[1]]))
cat("\nFirst 5 rows with PANEL column:\n")
print(head(b$data[[1]][, c("PANEL", "x", "y", "group")], 10))

cat("\n=== Facet Object ===\n")
print(str(b$layout$facet, max.level = 2))

cat("\n=== Facet Params ===\n")
print(b$layout$facet$params)
