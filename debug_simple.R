# Super simple debug test
# Works without devtools by installing package locally

library(ggplot2)
library(htmlwidgets)

cat("Installing package locally...\n")
install.packages(".", repos = NULL, type = "source", quiet = TRUE)

cat("Loading gg2d3...\n")
library(gg2d3)

cat("Creating simple scatter plot...\n")
p <- ggplot(mtcars, aes(x=wt, y=mpg)) + geom_point()

cat("Creating widget...\n")
w <- gg2d3(p)

cat("Saving HTML...\n")
f <- "debug_simple.html"
saveWidget(w, f, selfcontained = TRUE)

cat("\n========================================\n")
cat("Opening browser...\n")
cat("========================================\n\n")
cat("IMMEDIATELY press F12 (or Cmd+Option+I on Mac)\n")
cat("Go to the 'Console' tab\n")
cat("You should see messages starting with 'gg2d3:'\n\n")
cat("Tell me ALL the messages you see!\n\n")

browseURL(f)
