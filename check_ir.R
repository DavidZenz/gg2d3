# Check IR structure directly
library(ggplot2)
source("R/as_d3_ir.R")

# Create simple plot
p <- ggplot(mtcars, aes(x=factor(cyl), y=mpg, fill=factor(cyl))) + geom_col()

# Get IR
ir <- as_d3_ir(p)

# Print JSON to see what JavaScript will receive
cat("=== IR as JSON (what JavaScript sees) ===\n\n")
json <- jsonlite::toJSON(ir, auto_unbox = TRUE, pretty = TRUE)
cat(json)

cat("\n\n=== Quick checks ===\n")
cat("Has scales?", !is.null(ir$scales), "\n")
cat("Has layers?", length(ir$layers) > 0, "\n")
if (length(ir$layers) > 0) {
  cat("Layer 1 geom:", ir$layers[[1]]$geom, "\n")
  cat("Layer 1 data length:", length(ir$layers[[1]]$data), "\n")
  if (length(ir$layers[[1]]$data) > 0) {
    cat("First data point:\n")
    print(ir$layers[[1]]$data[[1]])
  }
}
