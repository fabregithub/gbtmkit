# Run the full group-based trajectory pipeline

Executes algorithm selection (optional), group-number selection,
polynomial shape search with GRoLTS acceptance criteria, and the final
Hessian-on fit, returning all intermediate results in one object.

## Usage

``` r
run_gbtm_pipeline(
  spec,
  engine = gbtm_engines(),
  candidates = 2:6,
  degree = 3L,
  method = NULL,
  algo_n_groups = NULL,
  algo_degree = NULL,
  strategy = c("stepwise", "grid"),
  min_degree = 1L,
  max_degree = 3L,
  max_passes = 2L,
  pms_min = 0.05,
  appa_min = 0.7,
  occ_min = 5,
  itermax = 100L,
  seed = NULL,
  time_budget = Inf,
  max_fits = Inf,
  checkpoint = NULL,
  verbose = TRUE,
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

  Integer vector of group numbers to consider (stage 2).

- degree:

  Polynomial degree used during group-number selection.

- method:

  Estimation method. If `NULL` and the engine offers a choice, stage 1
  selects it; otherwise this method is used throughout.

- algo_n_groups, algo_degree:

  Group count and degree used for stage-1 algorithm selection (defaults:
  `max(candidates)`, `degree`).

- strategy, min_degree, max_degree, max_passes:

  Shape-search controls, passed to
  [`evaluate_shapes()`](https://fabregithub.github.io/gbtmkit/reference/evaluate_shapes.md).

- pms_min, appa_min, occ_min:

  GRoLTS thresholds, passed to
  [`apply_grolts_criteria()`](https://fabregithub.github.io/gbtmkit/reference/apply_grolts_criteria.md).

- itermax, seed:

  Passed to the fitting stages.

- time_budget, max_fits, checkpoint:

  Bounds for the shape search.

- verbose:

  Print progress messages.

- ...:

  Passed to the underlying fitting calls in every stage. In particular
  `n_starts` (see
  [`gbtm_fit()`](https://fabregithub.github.io/gbtmkit/reference/gbtm_fit.md))
  applies multi-start initialization throughout; note it multiplies the
  cost of the shape search, which `max_fits`/`time_budget` still bound.

## Value

An object of class `gbtm_result` with elements `spec`, `engine`,
`method`, `algorithm_selection`, `group_selection`, `n_groups`,
`shapes`, `criteria`, `chosen_degrees`, `criteria_met`, `final_fit`,
`assignment`, `diagnostics`, and `call`.

## Details

If no shape meets the GRoLTS criteria, the pipeline falls back to the
lowest-BIC shape and records `criteria_met = FALSE`.

## See also

[`select_algorithm()`](https://fabregithub.github.io/gbtmkit/reference/select_algorithm.md),
[`select_n_groups()`](https://fabregithub.github.io/gbtmkit/reference/select_n_groups.md),
[`evaluate_shapes()`](https://fabregithub.github.io/gbtmkit/reference/evaluate_shapes.md),
[`apply_grolts_criteria()`](https://fabregithub.github.io/gbtmkit/reference/apply_grolts_criteria.md),
[`fit_gbtm()`](https://fabregithub.github.io/gbtmkit/reference/fit_gbtm.md)

## Examples

``` r
# \donttest{
data("sim_binary", package = "gbtmkit")
spec <- gbtm_spec(sim_binary, paste0("y", 1:10),
                  paste0("t", 1:10), id = "id", family = "binomial")
if (requireNamespace("trajeR", quietly = TRUE)) {
  res <- run_gbtm_pipeline(spec, candidates = 2:5, method = "L")
  res
}
# }
```
