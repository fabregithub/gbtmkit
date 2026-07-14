# Stage 2: select the number of groups

Fits the model for each candidate number of groups and picks the one
with the lowest BIC. Each candidate uses a polynomial degree of `degree`
for every group unless a per-candidate `degrees` list is supplied. The
candidate fits are independent and run in parallel under a
[`future::plan()`](https://future.futureverse.org/reference/plan.html)
when the future.apply package is installed.

## Usage

``` r
select_n_groups(
  spec,
  engine = gbtm_engines(),
  candidates = 2:6,
  degree = 3L,
  degrees = NULL,
  method = NULL,
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

- candidates:

  Integer vector of group numbers to try (default `2:6`).

- degree:

  Single polynomial degree applied to every group (default `3`, cubic).
  Ignored when `degrees` is supplied.

- degrees:

  Optional list, one integer vector per candidate, for full control of
  the shape at each group number.

- method:

  Estimation method to use (e.g. the winner of
  [`select_algorithm()`](https://fabregithub.github.io/gbtmkit/reference/select_algorithm.md)).

- by:

  Criterion to minimise, `"bic"` (default) or `"aic"`.

- hessian, itermax, seed, ...:

  Passed to
  [`gbtm_fit()`](https://fabregithub.github.io/gbtmkit/reference/gbtm_fit.md).

## Value

A `gbtm_selection` object with `$table`, `$best` (the chosen number of
groups), and the fitted models.

## Examples

``` r
# \donttest{
data("sim_binary", package = "gbtmkit")
spec <- gbtm_spec(sim_binary, paste0("y", 1:10),
                  paste0("t", 1:10), id = "id", family = "binomial")
select_n_groups(spec, candidates = 2:5, degree = 2)
# }
```
