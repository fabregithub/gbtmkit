# gbtmkit 0.4.0

* The native engine gains an **EM optimiser**:
  `gbtm_fit(engine = "gbtmkit", method = "EM")` runs
  expectation-maximisation (monotone likelihood ascent; weighted-GLM
  M-steps -- closed-form WLS for gaussian, IRLS for binomial/poisson; a
  closed-form or weighted-multinomial membership step) as an alternative to
  the default BFGS. Both maximise the same likelihood and converge to the
  same MLE (verified on the fixtures); EM is more robust near degenerate
  components, BFGS is faster. `gbtm_engine_methods("gbtmkit")` now returns
  `c("BFGS", "EM")`, so `select_algorithm()` and the pipeline's stage-1
  algorithm selection now work for the native engine -- the default
  `run_gbtm_pipeline()` picks BFGS vs EM by BIC. EM covers
  binomial/gaussian/poisson with membership and time-varying covariates;
  censored-normal outcomes stay BFGS-only.

# gbtmkit 0.3.0

* **The native engine is now the default** (`gbtm_engines()` lists it first).
  Existing code that relied on the old default with trajeR-specific arguments
  (e.g. `method = "L"`) must now pass `engine = "trajeR"` explicitly; code
  without engine-specific arguments keeps working and gets much faster.

* New built-in estimation engine: `engine = "gbtmkit"` -- a clean-room,
  fully vectorised maximum-likelihood implementation of Nagin-style GBTM
  (BFGS with analytic gradients validated against numDeriv; the likelihood
  reproduces trajeR's convention exactly). Typically 10-100x faster than
  trajeR at matching or better optima, with per-group degrees, both covariate
  kinds, shared or per-group residual variance, NA-tolerant outcomes (masked,
  not dropped), exposed convergence tolerance (`reltol`), native k-means
  multi-start, standard errors via `hessian = TRUE` (`fit$vcov`), and
  censored-normal (Tobit) outcomes via the spec's `ymin`/`ymax` bounds --
  validated against trajeR's CNORM (identical log-likelihood at the same
  parameters) and shown to recover latent trajectory parameters through ~13%
  censoring. The three established packages (trajeR, flexmix, lcmm) remain
  available as citable instruments.
* Multi-start seeding now pins the RNG kind (Mersenne-Twister) inside each
  start, so seeded results are identical whether or not a `future::plan()` is
  active (`future.apply` uses L'Ecuyer-CMRG streams, which otherwise changed
  the native engine's k-means partitions).

# gbtmkit 0.2.0

* Parallel execution of independent fits: multi-start initialisations
  (`n_starts`) and the candidate fits in `select_n_groups()` /
  `select_algorithm()` run via future.apply when it is installed -- set
  `future::plan(multisession)` (or `multicore`) to use several cores. With a
  `seed`, results are identical under any plan (each start/candidate seeds
  itself); measured ~2-2.6x wall-clock on 4-5 way parallelism, bounded by the
  slowest fit.
* Time-varying (trajectory) covariates: `gbtm_spec(tcov = list(w = c("w1",
  ...)))` -- occasion-level variables that shift the outcome within a group,
  with group-specific coefficients on every engine (trajeR `TCOV`; added to
  the component/class formula for flexmix and lcmm). Fitted trajectories from
  `gbtm_predict()` / `plot_trajectories()` are computed at `tcov = 0`.
  `gbtm_posterior()` for trajeR now passes `TCOV`/`Risk` through to
  `GroupProb()` (required with `tcov`; a no-op numerically for membership
  covariates).
* New `grolts_report()`: maps a `run_gbtm_pipeline()` result onto the GRoLTS
  checklist (van de Schoot et al. 2017). Items the pipeline can answer --
  time metric, software and engine versions, shape search, starting values
  and iterations, selection tools, models fitted, class sizes, entropy --
  are auto-filled; items only the analyst can know (missing-data mechanism,
  manuscript plots, syntax availability) are flagged with context. Pass
  `file =` to also write a Markdown appendix. Fits now record `itermax` to
  support it.
* New `benchmark_engines()`: fits the same model with each installed engine
  and reports wall-clock time alongside the engine-neutral classification
  diagnostics, so the fastest adequate backend can be picked per problem
  (fit a subsample, then commit). Skips -- with a recorded note -- engines
  that are missing, don't support the family, or need uniform degrees.
  `data-raw/benchmark-scale.R` runs it at increasing data scale.
* Class-membership covariates ("risk factors"): `gbtm_spec(covariates = ...)`
  now feeds a multinomial membership model on every engine (trajeR `Risk`,
  flexmix concomitant `FLXPmultinom`, lcmm `classmb`). Columns may be numeric,
  logical, or factor/character; trajectories themselves are unaffected. With
  covariates, `gbtm_group_sizes()` reports the average model-implied
  proportions (equal to mean posterior).
* New `n_starts` argument on `gbtm_fit()` (and, via `...`, on `fit_gbtm()`,
  the stage functions, and `run_gbtm_pipeline()`): multi-start initialisation
  that keeps the best fit by BIC. Engine-specific starts: trajeR uses k-means
  partition starting values (its default initialisation is deterministic),
  flexmix re-runs its random EM initialisation, and lcmm delegates to
  `lcmm::gridsearch()`. On the shipped fixtures this escapes the known
  single-start local optima (empty/merged groups) and makes mixed per-group
  degrees usable on trajeR.

# gbtmkit 0.1.0

* Third estimation engine: `lcmm` (`engine = "lcmm"`). Gaussian outcomes map
  to `lcmm::hlme()` and binary outcomes to `lcmm::lcmm(link = "thresholds")`,
  both as latent class growth models (`random = ~ -1`) with the canonical
  1-class-fit initialisation. Single optimiser; uniform polynomial order
  across groups (like flexmix).
* Second estimation engine: `flexmix` (`engine = "flexmix"`), proving the
  adapter interface generalises. Supports binomial, gaussian, and poisson
  families with a single EM optimiser; the polynomial order is shared by all
  groups (`gbtm_engine_per_group_degrees()`), and `evaluate_shapes()` sweeps
  uniform shapes for such engines.

* First working version: an engine-agnostic pipeline for group-based trajectory
  modelling (GBTM) that follows the GRoLTS reporting checklist.
* `gbtm_spec()` describes the data and model (columns by name, outcome family)
  with validation.
* An engine interface (`gbtm_fit()` and accessors) with a `trajeR` adapter
  supporting binary (LOGIT) and continuous (CNORM) outcomes; the design allows
  further backends without changing the pipeline.
* Engine-neutral GRoLTS diagnostics: entropy, APPA, OCC, group proportions and
  mismatch (`gbtm_diagnostics()`), plus `gbtm_assign()`.
* Pipeline stages: `select_algorithm()`, `select_n_groups()`,
  `evaluate_shapes()` (bounded, checkpointing shape search) with
  `apply_grolts_criteria()`, and `fit_gbtm()`.
* `run_gbtm_pipeline()` runs the whole workflow in one call and returns a
  `gbtm_result`; `plot_trajectories()` draws fitted trajectories.
* Two synthetic example datasets, `sim_binary` and `sim_continuous`: ten
  occasions, four planted groups of mixed polynomial order (two linear, two
  cubic).
