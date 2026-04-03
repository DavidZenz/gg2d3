library(ggplot2)
library(gg2d3)

# Create a plot with all three reference line types
p <- ggplot(mtcars, aes(wt, mpg)) +
  geom_point() +
  geom_hline(yintercept = 20, colour = "red", linetype = "dashed", linewidth = 1) +
  geom_vline(xintercept = 3.5, colour = "blue", linetype = "dotted", linewidth = 1) +
  geom_abline(slope = -5, intercept = 35, colour = "darkgreen", linewidth = 1.5) +
  theme_minimal() +
  labs(title = "Reference Geoms: hline, vline, abline",
       subtitle = "Red dashed hline at 20, Blue dotted vline at 3.5, Green abline")

w <- gg2d3(p)

# Save for visual inspection
dir.create("test_output", showWarnings = FALSE)
htmlwidgets::saveWidget(w, "test_output/test_reference_geoms.html", selfcontained = TRUE)
message("Saved visual check to: test_output/test_reference_geoms.html")
