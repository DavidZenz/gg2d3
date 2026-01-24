# Debug script to diagnose blank page issues
library(ggplot2)
library(htmlwidgets)
source("R/as_d3_ir.R")
source("R/gg2d3.R")

cat("=== Debugging gg2d3 ===\n\n")

# Step 1: Check IR creation
cat("Step 1: Creating plot and IR...\n")
p1 <- ggplot(mtcars, aes(x=factor(cyl), y=mpg, fill=factor(cyl))) + geom_col()
ir <- as_d3_ir(p1)

cat("IR structure:\n")
cat("  Layers:", length(ir$layers), "\n")
cat("  Layer 1 geom:", ir$layers[[1]]$geom, "\n")
cat("  Layer 1 data rows:", length(ir$layers[[1]]$data), "\n")
cat("  Scales x type:", ir$scales$x$type, "\n")
cat("  Scales y type:", ir$scales$y$type, "\n")
cat("  Has color scale:", !is.null(ir$scales$color), "\n")

# Step 2: Print first data row to check structure
cat("\nFirst data row:\n")
print(str(ir$layers[[1]]$data[[1]]))

# Step 3: Check if D3 library exists
cat("\nStep 3: Checking D3 library...\n")
d3_path <- "inst/htmlwidgets/lib/d3/d3.v7.min.js"
if (file.exists(d3_path)) {
  cat("  ✓ D3 library found at", d3_path, "\n")
  cat("  Size:", file.size(d3_path), "bytes\n")
} else {
  cat("  ✗ D3 library NOT FOUND at", d3_path, "\n")
  cat("  This is the problem! Download D3 with:\n")
  cat("    dir.create('inst/htmlwidgets/lib/d3', recursive=TRUE)\n")
  cat("    download.file('https://d3js.org/d3.v7.min.js',\n")
  cat("                  'inst/htmlwidgets/lib/d3/d3.v7.min.js', mode='wb')\n")
}

# Step 4: Check widget YAML
cat("\nStep 4: Checking widget YAML...\n")
yaml_path <- "inst/htmlwidgets/gg2d3.yaml"
if (file.exists(yaml_path)) {
  cat("  ✓ Widget YAML found\n")
  cat("  Contents:\n")
  yaml_content <- readLines(yaml_path)
  cat(paste("   ", yaml_content), sep="\n")
} else {
  cat("  ✗ Widget YAML NOT FOUND\n")
}

# Step 5: Create widget and save with debug info
cat("\nStep 5: Creating widget...\n")
w1 <- gg2d3(p1)

cat("\nStep 6: Saving to HTML with console instructions...\n")
f <- "debug_output.html"
saveWidget(w1, f, selfcontained = TRUE)

cat("\n=== Instructions ===\n")
cat("1. Open", f, "in your browser\n")
cat("2. Open browser console (F12 or Cmd+Option+I)\n")
cat("3. Look for JavaScript errors (in red)\n")
cat("4. Check if you see 'gg2d3: no marks drawn' warning\n")
cat("5. Run this in console to inspect IR:\n")
cat("   HTMLWidgets.widgets[0].instance.x\n\n")

cat("Opening in browser now...\n")
browseURL(f)
