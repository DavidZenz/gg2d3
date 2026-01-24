# Diagnose categorical scale issue
library(ggplot2)

cat("Reinstalling package...\n")
install.packages(".", repos = NULL, type = "source", quiet = TRUE)

source("R/as_d3_ir.R")

p <- ggplot(mtcars, aes(x=factor(cyl), y=mpg, fill=factor(cyl))) + geom_col()
ir <- as_d3_ir(p)

cat("\n=== IR Inspection ===\n\n")

cat("X Scale:\n")
cat("  Type:", ir$scales$x$type, "\n")
cat("  Domain:", paste(ir$scales$x$domain, collapse=", "), "\n\n")

cat("First 5 data points:\n")
for (i in 1:min(5, length(ir$layers[[1]]$data))) {
  pt <- ir$layers[[1]]$data[[i]]
  cat("  Point", i, ": x =", pt$x, ", y =", pt$y, ", fill =", pt$fill, "\n")
}

cat("\n=== Expected ===\n")
cat("X domain should be: 4, 6, 8\n")
cat("Data x values should be: 6, 6, 4, 6, 8, etc. (matching cyl values)\n")
