# Extract sf geometries from ggplot_build layer data as GeoJSON strings

Extracts the sfc geometry column from a data.frame produced by
`ggplot_build()$data[[i]]`, normalizes CRS to WGS84 unconditionally (per
D-11), and serializes each geometry as a GeoJSON geometry string via
[`geojsonsf::sfc_geojson()`](https://rdrr.io/pkg/geojsonsf/man/sfc_geojson.html)
(per D-10).

## Usage

``` r
extract_sf_geometries(df)
```

## Arguments

- df:

  A data.frame from `ggplot_build()$data[[i]]` containing an sfc column

## Value

Character vector of GeoJSON geometry strings, one per row

## Details

gg2d3's public sf renderer accepts polygon, point, and line geometry
families for
[`geom_sf()`](https://ggplot2.tidyverse.org/reference/ggsf.html) and
projected-anchor annotation support for
[`geom_sf_text()`](https://ggplot2.tidyverse.org/reference/ggsf.html)
and
[`geom_sf_label()`](https://ggplot2.tidyverse.org/reference/ggsf.html).
Missing CRS emits "geom_sf layer has missing CRS; coordinates will be
serialized as-is". Unsupported, empty, invalid, or missing geometries
emit "geom_sf layer skipped %d unsupported, empty, invalid, or missing
geometries" and are skipped before rendering.
