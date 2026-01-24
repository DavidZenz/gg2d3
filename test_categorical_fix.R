# Test categorical scale fix
library(ggplot2)
library(htmlwidgets)

cat("Reinstalling package with categorical fix...\n")
install.packages(".", repos = NULL, type = "source", quiet = TRUE)
library(gg2d3)

cat("Creating bar chart with factor(cyl)...\n")
p <- ggplot(mtcars, aes(x=factor(cyl), y=mpg, fill=factor(cyl))) +
  geom_col() +
  ggtitle("Categorical Scale Test")

cat("Generating widget...\n")
w <- gg2d3(p)

f <- "test_categorical.html"
saveWidget(w, f, selfcontained = TRUE)

cat("\n✓ Saved to:", f, "\n")
cat("\nExpected:\n")
cat("  - X-axis labels should show: 4, 6, 8\n")
cat("  - Bars should be centered under their labels\n")
cat("  - Three different fill colors\n\n")

cat("Opening in browser...\n")
browseURL(f)
