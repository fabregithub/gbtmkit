# Package index

## Specification

- [`gbtm_spec()`](https://fabregithub.github.io/gbtmkit/reference/gbtm_spec.md)
  : Create a group-based trajectory model specification
- [`gbtm_families()`](https://fabregithub.github.io/gbtmkit/reference/gbtm_families.md)
  : Supported outcome families

## Fitting and engines

- [`gbtm_fit()`](https://fabregithub.github.io/gbtmkit/reference/gbtm_fit.md)
  : Fit a group-based trajectory model
- [`fit_gbtm()`](https://fabregithub.github.io/gbtmkit/reference/fit_gbtm.md)
  : Fit the final chosen trajectory model
- [`gbtm_engines()`](https://fabregithub.github.io/gbtmkit/reference/gbtm_engines.md)
  : Registered estimation engines
- [`gbtm_engine_families()`](https://fabregithub.github.io/gbtmkit/reference/gbtm_engine_families.md)
  : Outcome families supported by an engine
- [`gbtm_engine_methods()`](https://fabregithub.github.io/gbtmkit/reference/gbtm_engine_methods.md)
  : Estimation methods offered by an engine
- [`gbtm_engine_per_group_degrees()`](https://fabregithub.github.io/gbtmkit/reference/gbtm_engine_per_group_degrees.md)
  : Does an engine support per-group polynomial degrees?
- [`benchmark_engines()`](https://fabregithub.github.io/gbtmkit/reference/benchmark_engines.md)
  : Benchmark the estimation engines on a specification
- [`gbtm_bic()`](https://fabregithub.github.io/gbtmkit/reference/gbtm_accessors.md)
  [`gbtm_aic()`](https://fabregithub.github.io/gbtmkit/reference/gbtm_accessors.md)
  [`gbtm_loglik()`](https://fabregithub.github.io/gbtmkit/reference/gbtm_accessors.md)
  [`gbtm_posterior()`](https://fabregithub.github.io/gbtmkit/reference/gbtm_accessors.md)
  [`gbtm_group_sizes()`](https://fabregithub.github.io/gbtmkit/reference/gbtm_accessors.md)
  [`gbtm_n_groups()`](https://fabregithub.github.io/gbtmkit/reference/gbtm_accessors.md)
  [`gbtm_degrees()`](https://fabregithub.github.io/gbtmkit/reference/gbtm_accessors.md)
  : Engine-agnostic accessors for a fitted model
- [`gbtm_predict()`](https://fabregithub.github.io/gbtmkit/reference/gbtm_predict.md)
  : Fitted group trajectories over time

## Diagnostics

- [`gbtm_diagnostics()`](https://fabregithub.github.io/gbtmkit/reference/gbtm_diagnostics.md)
  : GRoLTS classification diagnostics for a fitted model
- [`gbtm_assign()`](https://fabregithub.github.io/gbtmkit/reference/gbtm_assign.md)
  : Hard group assignment for a fitted model

## Pipeline stages

- [`select_algorithm()`](https://fabregithub.github.io/gbtmkit/reference/select_algorithm.md)
  : Stage 1: select the estimation algorithm
- [`select_n_groups()`](https://fabregithub.github.io/gbtmkit/reference/select_n_groups.md)
  : Stage 2: select the number of groups
- [`evaluate_shapes()`](https://fabregithub.github.io/gbtmkit/reference/evaluate_shapes.md)
  : Stage 3: search polynomial shapes for a fixed number of groups
- [`apply_grolts_criteria()`](https://fabregithub.github.io/gbtmkit/reference/apply_grolts_criteria.md)
  : Apply GRoLTS acceptance criteria to a shape table
- [`grolts_recommended()`](https://fabregithub.github.io/gbtmkit/reference/grolts_recommended.md)
  : The recommended shape from GRoLTS criteria

## Orchestration, reporting, and plotting

- [`run_gbtm_pipeline()`](https://fabregithub.github.io/gbtmkit/reference/run_gbtm_pipeline.md)
  : Run the full group-based trajectory pipeline
- [`grolts_report()`](https://fabregithub.github.io/gbtmkit/reference/grolts_report.md)
  : Map a pipeline result onto the GRoLTS checklist
- [`plot_trajectories()`](https://fabregithub.github.io/gbtmkit/reference/plot_trajectories.md)
  : Plot fitted group trajectories

## Data

- [`sim_binary`](https://fabregithub.github.io/gbtmkit/reference/sim_binary.md)
  : Synthetic binary trajectory data
- [`sim_continuous`](https://fabregithub.github.io/gbtmkit/reference/sim_continuous.md)
  : Synthetic continuous trajectory data
