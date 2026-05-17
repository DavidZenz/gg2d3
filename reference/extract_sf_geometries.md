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
