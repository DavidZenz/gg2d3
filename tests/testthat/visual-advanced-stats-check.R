library(ggplot2)
library(gg2d3)

# 1. Density plot (single and stacked)
p1 <- ggplot(mtcars, aes(mpg, fill = factor(cyl))) +
  geom_density(alpha = 0.5) +
  theme_minimal() +
  labs(title = "Density Plot: Stacked (cyl)")

w1 <- gg2d3(p1) |> d3_zoom()

# 2. Smooth line (loess)
p2 <- ggplot(mtcars, aes(wt, mpg)) +
  geom_point() +
  geom_smooth(method = "loess", se = TRUE) +
  theme_light() +
  labs(title = "Smooth: LOESS with CI")

w2 <- gg2d3(p2) |> d3_zoom()

# 3. Smooth line (gam)
p3 <- ggplot(mtcars, aes(wt, mpg)) +
  geom_point() +
  geom_smooth(method = "gam", formula = y ~ s(x, bs = "cs"), se = TRUE) +
  theme_light() +
  labs(title = "Smooth: GAM with CI")

w3 <- gg2d3(p3) |> d3_zoom()

# Save for visual inspection
dir.create("test_output", showWarnings = FALSE)
htmlwidgets::saveWidget(w1, "test_output/test_stats_density.html", selfcontained = TRUE)
htmlwidgets::saveWidget(w2, "test_output/test_stats_smooth_loess.html", selfcontained = TRUE)
htmlwidgets::saveWidget(w3, "test_output/test_stats_smooth_gam.html", selfcontained = TRUE)

# Combined page
combined <- htmltools::tagList(
  htmltools::tags$h1("Phase 23 Advanced Stats Verification"),
  htmltools::tags$div(
    style = "display: flex; flex-direction: column; gap: 30px;",
    htmltools::tags$div(w1),
    htmltools::tags$div(w2),
    htmltools::tags$div(w3)
  )
)
htmltools::save_html(combined, "test_output/test_stats_combined.html")
message("Saved visual check to: test_output/test_stats_combined.html")
