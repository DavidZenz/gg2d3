# Validate the structure of a D3 intermediate representation

Checks that an IR object has the required structure before passing it to
JavaScript. This catches malformed IR early with informative error
messages.

## Usage

``` r
validate_ir(ir)
```

## Arguments

- ir:

  A list representing the intermediate representation

## Value

The IR unchanged (invisibly) if valid, otherwise throws an error
