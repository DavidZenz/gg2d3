# Minimal test to check basic rendering
library(ggplot2)
library(htmlwidgets)
source("R/as_d3_ir.R")
source("R/gg2d3.R")

# Simplest possible plot
p <- ggplot(mtcars, aes(x=wt, y=mpg)) + geom_point()

# Create widget
w <- gg2d3(p)

# Save and open
f <- tempfile(fileext = ".html")
saveWidget(w, f, selfcontained = TRUE)
cat("Saved to:", f, "\n")
cat("Opening in browser...\n")
cat("\nIMPORTANT: Open browser console (F12 or Cmd+Option+I)\n")
cat("Look for errors in red text\n\n")

browseURL(f)

# Also print the IR to check structure
cat("\n=== IR Structure ===\n")
ir <- as_d3_ir(p)
cat("Width:", ir$width, "\n")
cat("Height:", ir$height, "\n")
cat("Layers:", length(ir$layers), "\n")
if (length(ir$layers) > 0) {
  cat("Geom:", ir$layers[[1]]$geom, "\n")
  cat("Data points:", length(ir$layers[[1]]$data), "\n")
  cat("X aesthetic:", ir$layers[[1]]$aes$x, "\n")
  cat("Y aesthetic:", ir$layers[[1]]$aes$y, "\n")
}
