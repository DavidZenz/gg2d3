# Detect the dominant geometry type in an sf layer

Returns the summary geometry type for the sfc column in the data.frame.
When the column contains mixed types,
[`sf::st_geometry_type()`](https://r-spatial.github.io/sf/reference/st_geometry_type.html)
with `by_geometry = FALSE` returns the shared type or "GEOMETRY".

## Usage

``` r
detect_dominant_geom_type(df)
```

## Arguments

- df:

  A data.frame from `ggplot_build()$data[[i]]` containing an sfc column

## Value

Character string such as "MULTIPOLYGON", "POLYGON", "POINT",
"LINESTRING", etc.
