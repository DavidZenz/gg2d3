# Test strip theme element defaults
library(ggplot2)

p <- ggplot(mtcars, aes(x = wt, y = mpg)) +
  geom_point() +
  facet_wrap(~ cyl)

# Get complete theme
complete_theme <- theme_gray() + p$theme

# Extract strip elements
cat("=== Strip Text ===\n")
strip_text <- ggplot2:::calc_element("strip.text", complete_theme)
print(str(strip_text))

cat("\n=== Strip Background ===\n")
strip_bg <- ggplot2:::calc_element("strip.background", complete_theme)
print(str(strip_bg))

cat("\n=== Strip Clip ===\n")
cat(complete_theme$strip.clip, "\n")

cat("\n=== Strip Placement ===\n")
cat(complete_theme$strip.placement, "\n")
