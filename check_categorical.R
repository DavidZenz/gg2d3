# Check what's happening with categorical scales
library(ggplot2)
install.packages(".", repos = NULL, type = "source", quiet = TRUE)
library(gg2d3)

p <- ggplot(mtcars, aes(x=factor(cyl), y=mpg, fill=factor(cyl))) + geom_col()

# Get IR
ir <- as_d3_ir(p)

cat("X Scale Info:\n")
cat("  Type:", ir$scales$x$type, "\n")
cat("  Domain:", paste(ir$scales$x$domain, collapse=", "), "\n\n")

cat("First few data points:\n")
for (i in 1:min(3, length(ir$layers[[1]]$data))) {
  cat("  Point", i, ": x =", ir$layers[[1]]$data[[i]]$x, "\n")
}
