# gbtmkit 0.0.0.9000

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
* Two synthetic example datasets, `sim_binary` and `sim_continuous`.
