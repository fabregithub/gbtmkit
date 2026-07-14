# Stage 1: select the estimation algorithm

Fits a fixed group number and shape under each candidate estimation
method and picks the one with the lowest BIC. For engines with a single
optimiser (see
[`gbtm_engine_methods()`](https://fabregithub.github.io/gbtmkit/reference/gbtm_engine_methods.md))
this is a no-op that returns that method. The candidate fits are
independent and run in parallel under a
[`future::plan()`](https://future.futureverse.org/reference/plan.html)
when the future.apply package is installed.

## Usage

``` r
select_algorithm(
  spec,
  engine = gbtm_engines(),
  n_groups,
  degrees,
  methods = NULL,
  by = c("bic", "aic"),
  hessian = FALSE,
  itermax = 100L,
  seed = NULL,
  ...
)
```

## Arguments

- spec:

  A
  [gbtm_spec](https://fabregithub.github.io/gbtmkit/reference/gbtm_spec.md).

- engine:

  Engine name; see
  [`gbtm_engines()`](https://fabregithub.github.io/gbtmkit/reference/gbtm_engines.md).

- n_groups:

  Number of groups to use for the comparison.

- degrees:

  Integer vector of polynomial degrees, length `n_groups`.

- methods:

  Character vector of methods to compare; defaults to all methods the
  engine offers.

- by:

  Criterion to minimise, `"bic"` (default) or `"aic"`.

- hessian, itermax, seed, ...:

  Passed to
  [`gbtm_fit()`](https://fabregithub.github.io/gbtmkit/reference/gbtm_fit.md).
  `hessian` defaults to `FALSE` (selection does not need standard
  errors).

## Value

A `gbtm_selection` object with `$table`, `$best` (the chosen method),
and the fitted models.

## Examples

``` r
# \donttest{
data("sim_binary", package = "gbtmkit")
spec <- gbtm_spec(sim_binary, paste0("y", 1:10),
                  paste0("t", 1:10), id = "id", family = "binomial")
if (requireNamespace("trajeR", quietly = TRUE))
  select_algorithm(spec, engine = "trajeR", n_groups = 4,
                   degrees = rep(1, 4))
# }
```
