# Fit the final chosen trajectory model

A thin wrapper over
[`gbtm_fit()`](https://fabregithub.github.io/gbtmkit/reference/gbtm_fit.md)
intended for the final model, once the number of groups and the
polynomial shape have been chosen. It differs only in defaulting
`hessian = TRUE`, so the result includes standard errors.

## Usage

``` r
fit_gbtm(
  spec,
  n_groups,
  degrees,
  method = NULL,
  engine = gbtm_engines(),
  hessian = TRUE,
  itermax = 100L,
  seed = NULL,
  ...
)
```

## Arguments

- spec:

  A
  [gbtm_spec](https://fabregithub.github.io/gbtmkit/reference/gbtm_spec.md).

- n_groups:

  Number of latent groups.

- degrees:

  Integer vector of polynomial degrees, length `n_groups`.

- method:

  Estimation method; must be one of
  [`gbtm_engine_methods()`](https://fabregithub.github.io/gbtmkit/reference/gbtm_engine_methods.md)
  for the chosen engine (ignored by engines with a single optimiser).

- engine:

  Engine name; see
  [`gbtm_engines()`](https://fabregithub.github.io/gbtmkit/reference/gbtm_engines.md).

- hessian:

  Logical; compute the Hessian (standard errors). Default `TRUE`.

- itermax:

  Maximum optimiser iterations.

- seed:

  Optional integer seed for reproducibility.

- ...:

  Passed on to the underlying engine call.

## Value

A
[gbtm_fit](https://fabregithub.github.io/gbtmkit/reference/gbtm_fit.md)
object.

## See also

[`gbtm_fit()`](https://fabregithub.github.io/gbtmkit/reference/gbtm_fit.md),
[`gbtm_diagnostics()`](https://fabregithub.github.io/gbtmkit/reference/gbtm_diagnostics.md),
[`gbtm_assign()`](https://fabregithub.github.io/gbtmkit/reference/gbtm_assign.md),
[`plot_trajectories()`](https://fabregithub.github.io/gbtmkit/reference/plot_trajectories.md)

## Examples

``` r
# \donttest{
data("sim_binary", package = "gbtmkit")
spec <- gbtm_spec(sim_binary, paste0("y", 1:10),
                  paste0("t", 1:10), id = "id", family = "binomial")
fit_gbtm(spec, n_groups = 4, degrees = rep(3, 4))
# }
```
