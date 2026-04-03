library(ggplot2)
library(gg2d3)

# 1. Bar chart with facet_wrap and coord_flip
p1 <- ggplot(mtcars, aes(factor(cyl))) +
  geom_bar(fill = "steelblue") +
  facet_wrap(~ am) +
  coord_flip() +
  theme_minimal() +
  labs(title = "Bar Chart: facet_wrap + coord_flip",
       subtitle = "X-aesthetic (cyl) should be vertical on the left, Y (count) horizontal on the bottom")

w1 <- gg2d3(p1)

# 2. Scatter plot with facet_grid and coord_flip
p2 <- ggplot(mtcars, aes(wt, mpg)) +
  geom_point(aes(color = factor(cyl))) +
  facet_grid(am ~ vs) +
  coord_flip() +
  theme_light() +
  labs(title = "Scatter: facet_grid + coord_flip",
       subtitle = "WT (x) should be vertical, MPG (y) should be horizontal")

w2 <- gg2d3(p2)

# Save visual checks
dir.create("test_output", showWarnings = FALSE)
htmlwidgets::saveWidget(w1, "test_output/test_coord_flip_wrap.html", selfcontained = TRUE)
htmlwidgets::saveWidget(w2, "test_output/test_coord_flip_grid.html", selfcontained = TRUE)

# Combined page
combined <- htmltools::tagList(
  htmltools::tags$h1("Phase 15 coord_flip Verification"),
  htmltools::tags$div(
    style = "display: flex; flex-direction: column; gap: 30px;",
    htmltools::tags$div(w1),
    htmltools::tags$div(w2)
  )
)
htmltools::save_html(combined, "test_output/test_coord_flip_combined.html")
message("Saved visual check to: test_output/test_coord_flip_combined.html")
