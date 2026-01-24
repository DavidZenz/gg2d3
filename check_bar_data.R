# Check bar data being sent to D3
library(ggplot2)
install.packages(".", repos = NULL, type = "source", quiet = TRUE)
library(gg2d3)

p <- ggplot(mtcars, aes(x=factor(cyl), y=mpg, fill=factor(cyl))) + geom_col()
ir <- as_d3_ir(p)

cat("=== X Scale ===\n")
cat("Type:", ir$scales$x$type, "\n")
cat("Domain:", paste(ir$scales$x$domain, collapse=", "), "\n\n")

cat("=== Layer Data ===\n")
cat("Total data points:", length(ir$layers[[1]]$data), "\n\n")

cat("Unique x values and counts:\n")
x_vals <- sapply(ir$layers[[1]]$data, function(d) d$x)
table(x_vals)

cat("\n\nFirst 5 data points:\n")
for (i in 1:min(5, length(ir$layers[[1]]$data))) {
  d <- ir$layers[[1]]$data[[i]]
  cat(sprintf("  %d: x=%s, ymin=%.1f, ymax=%.1f, fill=%s\n",
              i, d$x, d$ymin, d$ymax, d$fill))
}

cat("\n=== Expected ===\n")
cat("Should have data points for all three x values: 4, 6, 8\n")
cat("Each should have multiple segments (stacked by fill)\n")
