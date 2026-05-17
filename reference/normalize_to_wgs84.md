# Normalize an sfc column to WGS84 (EPSG:4326)

Transforms any projected or geographic CRS to EPSG:4326. Returns the
input unchanged if it is not an sfc object. If the CRS is already
EPSG:4326, no transformation is performed.

## Usage

``` r
normalize_to_wgs84(geom_col)
```

## Arguments

- geom_col:

  An sfc geometry column, or any other R object

## Value

The sfc column transformed to EPSG:4326, or the input unchanged if not
an sfc object
