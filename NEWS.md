# gbtmkit 0.1.0

* Third estimation engine: `lcmm` (`engine = "lcmm"`). Gaussian outcomes map
  to `lcmm::hlme()` and binary outcomes to `lcmm::lcmm(link = "thresholds")`,
  both as latent class growth models (`random = ~ -1`) with the canonical
  1-class-fit initialization. Single optimizer; uniform polynomial order
  across groups (like flexmix).
* Second estimation engine: `flexmix` (`engine = "flexmix"`), proving the
  adapter interface generalizes. Supports binomial, gaussian, and poisson
  families with a single EM optimizer; the polynomial order is shared by all
  groups (`gbtm_engine_per_group_degrees()`), and `evaluate_shapes()` sweeps
  uniform shapes for such engines.

* First working version: an engine-agnostic pipeline for group-based trajectory
  modeling (GBTM) that follows the GRoLTS reporting checklist.
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
