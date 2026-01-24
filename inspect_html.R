# Create a widget and inspect the actual HTML
library(ggplot2)
library(htmlwidgets)
source("R/as_d3_ir.R")
source("R/gg2d3.R")

p <- ggplot(mtcars, aes(x=wt, y=mpg)) + geom_point()
w <- gg2d3(p)

# Save to a known location
f <- "inspect_output.html"
saveWidget(w, f, selfcontained = FALSE)

cat("Saved to:", f, "\n")
cat("Now checking the data being passed...\n\n")

# Read the HTML to see what data is embedded
html <- readLines(f)

# Find the line with the widget data
data_line <- grep("x.*gg2d3", html, value = TRUE)
if (length(data_line) > 0) {
  cat("Found widget data line:\n")
  cat(substr(data_line[1], 1, 200), "...\n")
} else {
  cat("Could not find widget data in HTML\n")
}

cat("\nOpening in browser...\n")
browseURL(f)
