# Get CRS information from an sf layer's geometry column

Returns a list with the EPSG code (integer or NA) and WKT string for the
coordinate reference system of the geometry column. Known CRS inputs are
normalized to WGS84 in the
[`geom_sf()`](https://ggplot2.tidyverse.org/reference/ggsf.html) IR
path; missing CRS layers warn that coordinates will be serialized as-is.

## Usage

``` r
get_layer_crs(df)
```

## Arguments

- df:

  A data.frame from `ggplot_build()$data[[i]]` containing an sfc column

## Value

A list with fields:

- `epsg`: integer EPSG code, or `NA_integer_` if not available

- `wkt`: character WKT2 string, or `NA_character_` if not available
