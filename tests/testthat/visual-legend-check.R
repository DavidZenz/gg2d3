library(ggplot2)
library(crosstalk)
library(gg2d3)
library(htmltools)

# Helper to save widget for visual inspection
save_visual_check <- function(widget, name) {
  dir.create("test_output", showWarnings = FALSE)
  path <- file.path("test_output", paste0(name, ".html"))
  htmlwidgets::saveWidget(widget, path, selfcontained = TRUE)
  message("Saved visual check to: ", path)
}

# 1. Discrete legend scatter with 3 groups and crosstalk SharedData
iris_sd <- SharedData$new(iris, group = "shared_group")
p1 <- ggplot(iris, aes(Sepal.Length, Sepal.Width, colour = Species)) +
  geom_point(size = 3) +
  theme_minimal() +
  labs(title = "Interactive Legend + Crosstalk",
       subtitle = "Click to toggle, Dbl-click to solo, Hover to preview")
p1$data <- iris_sd

w1 <- gg2d3(p1)

# 2. Continuous colorbar plot (should NOT be interactive)
p2 <- ggplot(iris, aes(Sepal.Length, Sepal.Width, colour = Petal.Length)) +
  geom_point(size = 3) +
  theme_minimal() +
  labs(title = "Continuous Colorbar (Non-interactive)",
       subtitle = "Legend should not respond to clicks/hovers")

w2 <- gg2d3(p2)

# Save both
save_visual_check(w1, "test_legend_interactive")
save_visual_check(w2, "test_legend_colorbar")

# Generate a combined page for easier viewing
combined_page <- tagList(
  tags$h1("Phase 13 Legend Verification"),
  tags$div(
    style = "display: flex; flex-wrap: wrap; gap: 20px;",
    tags$div(
      style = "border: 1px solid #ccc; padding: 10px;",
      tags$h2("Discrete + Crosstalk"),
      w1
    ),
    tags$div(
      style = "border: 1px solid #ccc; padding: 10px;",
      tags$h2("Continuous Colorbar"),
      w2
    )
  )
)

htmltools::save_html(combined_page, "test_output/test_legend_combined.html")
message("Saved visual check to: test_output/test_legend_combined.html")
