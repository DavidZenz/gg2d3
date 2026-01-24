# Debug bar rendering issue
library(ggplot2)
library(htmlwidgets)

cat("Reinstalling package...\n")
install.packages(".", repos = NULL, type = "source", quiet = TRUE)
library(gg2d3)

# Create plot
p <- ggplot(mtcars, aes(x=factor(cyl), y=mpg, fill=factor(cyl))) + geom_col()

# Check IR
source("R/as_d3_ir.R")
ir <- as_d3_ir(p)

cat("\n=== Data Check ===\n")
cat("Number of data points:", length(ir$layers[[1]]$data), "\n\n")

cat("All data points:\n")
for (i in 1:length(ir$layers[[1]]$data)) {
  pt <- ir$layers[[1]]$data[[i]]
  cat(sprintf("  %d: x=%s, y=%.1f, fill=%s\n", i, pt$x, pt$y, pt$fill))
}

cat("\n=== Scale Check ===\n")
cat("X Scale Type:", ir$scales$x$type, "\n")
cat("X Scale Domain:", paste(ir$scales$x$domain, collapse=", "), "\n")

# Create widget with debug logging in browser
w <- gg2d3(p)
f <- "debug_bars.html"
saveWidget(w, f, selfcontained = TRUE)

cat("\n✓ Saved to:", f, "\n")
cat("\nOpen the file and check browser console (F12)\n")
cat("You should see all data points being processed\n\n")

browseURL(f)
