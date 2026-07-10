# Fitted group trajectories over time

Returns each group's fitted trajectory on the outcome scale (probability
for binomial, mean for gaussian, rate for poisson) over a grid of times,
computed from the model coefficients – engine-neutral, so it drives
[`plot_trajectories()`](https://fabregithub.github.io/gbtmkit/reference/plot_trajectories.md)
for any backend.

## Usage

``` r
gbtm_predict(fit, times = NULL, n = 100L, ...)
```

## Arguments

- fit:

  A
  [gbtm_fit](https://fabregithub.github.io/gbtmkit/reference/gbtm_fit.md)
  object.

- times:

  Optional numeric vector of times; defaults to a grid spanning the
  observed range.

- n:

  Number of grid points when `times` is `NULL`.

- ...:

  Unused.

## Value

A data frame with columns `group`, `time`, and `fitted`.
