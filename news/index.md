# Changelog

## gbtmkit (development version)

- Time-varying (trajectory) covariates:
  `gbtm_spec(tcov = list(w = c("w1", ...)))` – occasion-level variables
  that shift the outcome within a group, with group-specific
  coefficients on every engine (trajeR `TCOV`; added to the
  component/class formula for flexmix and lcmm). Fitted trajectories
  from
  [`gbtm_predict()`](https://fabregithub.github.io/gbtmkit/reference/gbtm_predict.md)
  /
  [`plot_trajectories()`](https://fabregithub.github.io/gbtmkit/reference/plot_trajectories.md)
  are computed at `tcov = 0`.
  [`gbtm_posterior()`](https://fabregithub.github.io/gbtmkit/reference/gbtm_accessors.md)
  for trajeR now passes `TCOV`/`Risk` through to `GroupProb()` (required
  with `tcov`; a no-op numerically for membership covariates).
- New
  [`grolts_report()`](https://fabregithub.github.io/gbtmkit/reference/grolts_report.md):
  maps a
  [`run_gbtm_pipeline()`](https://fabregithub.github.io/gbtmkit/reference/run_gbtm_pipeline.md)
  result onto the GRoLTS checklist (van de Schoot et al. 2017). Items
  the pipeline can answer – time metric, software and engine versions,
  shape search, starting values and iterations, selection tools, models
  fitted, class sizes, entropy – are auto-filled; items only the analyst
  can know (missing-data mechanism, manuscript plots, syntax
  availability) are flagged with context. Pass `file =` to also write a
  Markdown appendix. Fits now record `itermax` to support it.
- New
  [`benchmark_engines()`](https://fabregithub.github.io/gbtmkit/reference/benchmark_engines.md):
  fits the same model with each installed engine and reports wall-clock
  time alongside the engine-neutral classification diagnostics, so the
  fastest adequate backend can be picked per problem (fit a subsample,
  then commit). Skips – with a recorded note – engines that are missing,
  don’t support the family, or need uniform degrees.
  `data-raw/benchmark-scale.R` runs it at increasing data scale.
- Class-membership covariates (“risk factors”):
  `gbtm_spec(covariates = ...)` now feeds a multinomial membership model
  on every engine (trajeR `Risk`, flexmix concomitant `FLXPmultinom`,
  lcmm `classmb`). Columns may be numeric, logical, or factor/character;
  trajectories themselves are unaffected. With covariates,
  [`gbtm_group_sizes()`](https://fabregithub.github.io/gbtmkit/reference/gbtm_accessors.md)
  reports the average model-implied proportions (equal to mean
  posterior).
- New `n_starts` argument on
  [`gbtm_fit()`](https://fabregithub.github.io/gbtmkit/reference/gbtm_fit.md)
  (and, via `...`, on
  [`fit_gbtm()`](https://fabregithub.github.io/gbtmkit/reference/fit_gbtm.md),
  the stage functions, and
  [`run_gbtm_pipeline()`](https://fabregithub.github.io/gbtmkit/reference/run_gbtm_pipeline.md)):
  multi-start initialization that keeps the best fit by BIC.
  Engine-specific starts: trajeR uses k-means partition starting values
  (its default initialization is deterministic), flexmix re-runs its
  random EM initialization, and lcmm delegates to
  [`lcmm::gridsearch()`](https://cecileproust-lima.github.io/lcmm/reference/gridsearch.html).
  On the shipped fixtures this escapes the known single-start local
  optima (empty/merged groups) and makes mixed per-group degrees usable
  on trajeR.

## gbtmkit 0.1.0

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
