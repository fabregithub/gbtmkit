# Estimation methods offered by an engine

Engines that expose a choice of optimiser return the available method
names; engines with a single fixed optimiser return `NA_character_`,
which the algorithm-selection stage treats as a no-op.

## Usage

``` r
gbtm_engine_methods(engine = gbtm_engines())
```

## Arguments

- engine:

  Engine name; see
  [`gbtm_engines()`](https://fabregithub.github.io/gbtmkit/reference/gbtm_engines.md).

## Value

Character vector of method names, or `NA_character_`.
