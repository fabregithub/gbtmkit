# Stage 3: search polynomial shapes for a fixed number of groups

Fits candidate per-group polynomial degrees and records the GRoLTS
diagnostics for each, returning one row per evaluated shape. The search
runs unattended and bounded: a greedy `"stepwise"` strategy by default,
an optional hard `time_budget`/`max_fits`, on-disk `checkpoint`ing with
resume, and an up-front run-time estimate.

## Usage

``` r
evaluate_shapes(
  spec,
  n_groups,
  engine = gbtm_engines(),
  method = NULL,
  strategy = c("stepwise", "grid"),
  min_degree = 1L,
  max_degree = 3L,
  max_passes = 2L,
  hessian = FALSE,
  itermax = 100L,
  seed = NULL,
  time_budget = Inf,
  max_fits = Inf,
  checkpoint = NULL,
  verbose = TRUE
)
```

## Arguments

- spec:

  A
  [gbtm_spec](https://fabregithub.github.io/gbtmkit/reference/gbtm_spec.md).

- n_groups:

  Number of groups.

- engine:

  Engine name; see
  [`gbtm_engines()`](https://fabregithub.github.io/gbtmkit/reference/gbtm_engines.md).

- method:

  Estimation method (e.g. the winner of
  [`select_algorithm()`](https://fabregithub.github.io/gbtmkit/reference/select_algorithm.md)).

- strategy:

  `"stepwise"` (default, greedy coordinate descent) or `"grid"` (full
  Cartesian product of degrees).

- min_degree, max_degree:

  Per-group polynomial degree bounds.

- max_passes:

  Maximum coordinate-descent passes for `"stepwise"`.

- hessian:

  Logical; keep `FALSE` during search (default).

- itermax, seed:

  Passed to
  [`gbtm_fit()`](https://fabregithub.github.io/gbtmkit/reference/gbtm_fit.md).

- time_budget:

  Wall-clock limit: seconds, or a string like `"2h"`. `Inf` for no
  limit.

- max_fits:

  Maximum number of model fits. `Inf` for no limit.

- checkpoint:

  Optional file path; results are appended here and a rerun resumes,
  skipping shapes already evaluated.

- verbose:

  Print the run-time estimate and progress messages.

## Value

An object of class `gbtm_shapes`: `$table` (one row per shape), `$best`
(degrees with the lowest BIC), `$best_fit`, `$n_fits`, `$budget_hit`,
and `$strategy`.

## See also

[`apply_grolts_criteria()`](https://fabregithub.github.io/gbtmkit/reference/apply_grolts_criteria.md)
