library(ggplot2)
library(gg2d3)

# 1. Pie chart (geom_bar + coord_polar theta='y')
df_pie <- data.frame(
  group = c("A", "B", "C"),
  value = c(10, 20, 30)
)
p1 <- ggplot(df_pie, aes(x = factor(1), y = value, fill = group)) +
  geom_bar(width = 1, stat = "identity") +
  coord_polar(theta = "y") +
  theme_void() +
  labs(title = "Pie Chart (coord_polar theta='y')")

w1 <- gg2d3(p1)

# 2. Coxcomb plot (geom_bar + coord_polar theta='x')
p2 <- ggplot(mtcars, aes(x = factor(cyl), fill = factor(cyl))) +
  geom_bar(width = 1) +
  coord_polar(theta = "x") +
  theme_minimal() +
  labs(title = "Coxcomb Plot (coord_polar theta='x')")

w2 <- gg2d3(p2)

# Save for visual inspection
dir.create("test_output", showWarnings = FALSE)
htmlwidgets::saveWidget(w1, "test_output/test_polar_pie.html", selfcontained = TRUE)
htmlwidgets::saveWidget(w2, "test_output/test_polar_coxcomb.html", selfcontained = TRUE)

# Combined page
combined <- htmltools::tagList(
  htmltools::tags$h1("Phase 22 Polar Coordinates Verification"),
  htmltools::tags$div(
    style = "display: flex; flex-direction: column; gap: 30px;",
    htmltools::tags$div(w1),
    htmltools::tags$div(w2)
  )
)
htmltools::save_html(combined, "test_output/test_polar_combined.html")
message("Saved visual check to: test_output/test_polar_combined.html")
