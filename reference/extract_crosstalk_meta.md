# Extract crosstalk metadata from ggplot object

Checks if ggplot's data layer is a SharedData object and extracts the
crosstalk key and group name for linked brushing.

## Usage

``` r
extract_crosstalk_meta(ggplot_obj)
```

## Arguments

- ggplot_obj:

  A ggplot2 object

## Value

List with crosstalk_key and crosstalk_group, or NULL if not SharedData
