test_that("source pkgdown article exposes the sf support and skip contract", {
  pkgdown_site_validate_source_contract()
})

test_that("generated pkgdown marker contract names article and widget evidence", {
  pkgdown_site_validate_marker_contract()
})

test_that("generated pkgdown article contains current sf support text", {
  pkgdown_site_validate_generated_article_text()
})

test_that("generated pkgdown article embeds gg2d3 widget dependencies", {
  pkgdown_site_validate_widget_dependencies()
})

test_that("generated pkgdown article records an sf render or skip outcome", {
  pkgdown_site_expect_sf_outcome(require_rendered_sf = FALSE)
})

test_that("generated pkgdown NEWS and reference pages reflect current support", {
  pkgdown_site_validate_news_and_reference()
})

test_that("generated pkgdown quick gate validates current site evidence", {
  pkgdown_site_validate_quick(require_rendered_sf = FALSE)
})
