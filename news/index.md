# Changelog

## gbtmkit 0.0.0.9000

- Third estimation engine: `lcmm` (`engine = "lcmm"`). Gaussian outcomes
  map to
  [`lcmm::hlme()`](https://cecileproust-lima.github.io/lcmm/reference/hlme.html)
  and binary outcomes to `lcmm::lcmm(link = "thresholds")`, both as
  latent class growth models (`random = ~ -1`) with the canonical
  1-class-fit initialization. Single optimizer; uniform polynomial order
  across groups (like flexmix).

- Second estimation engine: `flexmix` (`engine = "flexmix"`), proving
  the adapter interface generalizes. Supports binomial, gaussian, and
  poisson families with a single EM optimizer; the polynomial order is
  shared by all groups
  ([`gbtm_engine_per_group_degrees()`](https://fabregithub.github.io/gbtmkit/reference/gbtm_engine_per_group_degrees.md)),
  and
  [`evaluate_shapes()`](https://fabregithub.github.io/gbtmkit/reference/evaluate_shapes.md)
  sweeps uniform shapes for such engines.

- First working version: an engine-agnostic pipeline for group-based
  trajectory modeling (GBTM) that follows the GRoLTS reporting
  checklist.

- [`gbtm_spec()`](https://fabregithub.github.io/gbtmkit/reference/gbtm_spec.md)
  describes the data and model (columns by name, outcome family) with
  validation.

- An engine interface
  ([`gbtm_fit()`](https://fabregithub.github.io/gbtmkit/reference/gbtm_fit.md)
  and accessors) with a `trajeR` adapter supporting binary (LOGIT) and
  continuous (CNORM) outcomes; the design allows further backends
  without changing the pipeline.

- Engine-neutral GRoLTS diagnostics: entropy, APPA, OCC, group
  proportions and mismatch
  ([`gbtm_diagnostics()`](https://fabregithub.github.io/gbtmkit/reference/gbtm_diagnostics.md)),
  plus
  [`gbtm_assign()`](https://fabregithub.github.io/gbtmkit/reference/gbtm_assign.md).

- Pipeline stages:
  [`select_algorithm()`](https://fabregithub.github.io/gbtmkit/reference/select_algorithm.md),
  [`select_n_groups()`](https://fabregithub.github.io/gbtmkit/reference/select_n_groups.md),
  [`evaluate_shapes()`](https://fabregithub.github.io/gbtmkit/reference/evaluate_shapes.md)
  (bounded, checkpointing shape search) with
  [`apply_grolts_criteria()`](https://fabregithub.github.io/gbtmkit/reference/apply_grolts_criteria.md),
  and
  [`fit_gbtm()`](https://fabregithub.github.io/gbtmkit/reference/fit_gbtm.md).

- [`run_gbtm_pipeline()`](https://fabregithub.github.io/gbtmkit/reference/run_gbtm_pipeline.md)
  runs the whole workflow in one call and returns a `gbtm_result`;
  [`plot_trajectories()`](https://fabregithub.github.io/gbtmkit/reference/plot_trajectories.md)
  draws fitted trajectories.

- Two synthetic example datasets, `sim_binary` and `sim_continuous`: ten
  occasions, four planted groups of mixed polynomial order (two linear,
  two cubic).
