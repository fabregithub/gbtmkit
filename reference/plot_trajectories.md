# Plot fitted group trajectories

Draws each group's fitted trajectory over time and, optionally, overlays
the observed mean outcome for the subjects assigned to that group at
each occasion. Requires the ggplot2 package.

## Usage

``` r
plot_trajectories(fit, observed = TRUE, n = 100L)
```

## Arguments

- fit:

  A
  [gbtm_fit](https://fabregithub.github.io/gbtmkit/reference/gbtm_fit.md)
  object.

- observed:

  Logical; overlay observed per-group occasion means (default `TRUE`).

- n:

  Number of time grid points for the fitted lines.

## Value

A ggplot2 object.

## Examples

``` r
# \donttest{
data("sim_binary", package = "gbtmkit")
spec <- gbtm_spec(sim_binary, paste0("y", 1:10),
                  paste0("t", 1:10), id = "id", family = "binomial")
if (requireNamespace("ggplot2", quietly = TRUE)) {
  fit <- fit_gbtm(spec, n_groups = 4, degrees = rep(3, 4))
  plot_trajectories(fit)
}
# }
```
