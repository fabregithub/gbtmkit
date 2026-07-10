# Supported outcome families

The neutral family names understood by
[`gbtm_spec()`](https://fabregithub.github.io/gbtmkit/reference/gbtm_spec.md).
Each engine adapter maps these to its own idiom (e.g. trajeR maps
`"binomial"` to `LOGIT`, `"gaussian"` to `CNORM`).

## Usage

``` r
gbtm_families()
```

## Value

A character vector of supported family names.
