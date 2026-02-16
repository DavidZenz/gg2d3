# Test panel spacing theme element
library(ggplot2)

p <- ggplot(mtcars, aes(x = wt, y = mpg)) +
  geom_point() +
  facet_wrap(~ cyl)

# Get complete theme
complete_theme <- theme_gray() + p$theme

# Extract panel spacing
cat("=== Panel Spacing ===\n")
panel_spacing <- complete_theme$panel.spacing
if (!is.null(panel_spacing)) {
  # Convert to pixels
  inches <- grid::convertUnit(panel_spacing, "inches", valueOnly = TRUE)
  pixels <- inches * 96
  cat("panel.spacing:", panel_spacing, "=", pixels, "px\n")
} else {
  cat("panel.spacing is NULL\n")
}

cat("\n=== Panel Spacing X ===\n")
panel_spacing_x <- complete_theme$panel.spacing.x
cat("panel.spacing.x:", if (!is.null(panel_spacing_x)) panel_spacing_x else "NULL", "\n")

cat("\n=== Panel Spacing Y ===\n")
panel_spacing_y <- complete_theme$panel.spacing.y
cat("panel.spacing.y:", if (!is.null(panel_spacing_y)) panel_spacing_y else "NULL", "\n")
