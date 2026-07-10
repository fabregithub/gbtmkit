# GBTM Pipeline — Design Document

**Status:** Draft for review
**Goal:** Turn a one-off group-based-trajectory analysis script into a generic,
engine-agnostic R package for group-based trajectory modeling (GBTM) that follows the GRoLTS
reporting checklist by construction.

**Resolved decisions (2026-07-07):**
- Package name: **`gbtmkit`** — confirmed free on CRAN (404), GitHub, Bioconductor. Folder
  renamed `gbtm-pipeline/` → `gbtmkit/` (done); git initialized on `main`.
- Scope: **engine-agnostic** (trajeR → flexmix → lcmm behind one interface).
- Outcome types: binary (LOGIT) **and continuous (CNORM)** first-class in v0.1.
- Data: **entirely synthetic and domain-neutral.** No real cohort data and no external
  published dataset are used anywhere. Two generated datasets ship as package data —
  `sim_binary` and `sim_continuous` (built by `data-raw/simulate-data.R`, known ground-truth
  groups) — and drive the tests, examples, and vignette. The original private data stays out
  of the repo entirely.
- Tests assert recovery of the **synthetic** ground truth; the original paper's result is
  **not** reproduced in the suite (its data cannot ship).
- Performance is a first-class requirement: the shape search must scale to ~80k rows. See §11.
- License: **MIT**.

---

## 1. Objectives

- **Generic:** any dataset, any outcome column layout, configurable time/covariate columns.
- **Multiple outcome types:** binary (LOGIT) **and continuous (CNORM)** from v0.1, plus
  count (POIS/ZIP) and proportion (BETA) via the same spec.
- **Engine-agnostic:** one interface, multiple estimation backends (`trajeR` first, then
  `lcmm`, `flexmix`). Swapping engines should not change the calling code.
- **GRoLTS-aligned:** the diagnostics the script computes by hand (BIC/AIC, entropy, APPA,
  OCC, PMS, mismatch) become first-class, tested outputs, with the standard thresholds as
  documented defaults.
- **Reproducible:** the synthetic datasets have *known* ground-truth groups, so regression
  tests can assert the pipeline recovers them and refactoring cannot silently change output.
- **Maintainable:** small pure functions, tidy return types, unit tests, roxygen docs, and a
  vignette that walks through a full analysis on the synthetic data.

---

## 2. What we are migrating from

The original script runs four stages, all hard-coded to one dataset:

| Stage | Script lines | What it does | To become |
|-------|-------------|--------------|-----------|
| 1. Algorithm selection | 11–50 | Fit `ng=4` under `L`/`EM`/`EMIRLS`, min-BIC | `select_algorithm()` |
| 2. Group-number selection | 52–89 | Sweep `ng = 2…6`, min-BIC | `select_n_groups()` |
| 3. Shape selection | 93–299 | Brute-force degree permutations, GRoLTS diagnostics, threshold filter, min-BIC | `evaluate_shapes()` + `apply_grolts_criteria()` |
| 4. Final fit & outputs | 303–386 | Refit optimum, plot, assign groups | `fit_gbtm()`, `assign_groups()`, `plot_trajectories()` |

Known defects in the source to fix during migration (do **not** port verbatim):

- Lines 273–275 vs 278–280: two different PMS filters; the first is dead/inconsistent.
- Line 49: `test_algo[1:2]` drops the third algorithm from the BIC table (off-by-one vs the
  three fitted methods).
- Line 69: `test_algo[i]` indexed by the group loop `i = 2:6`, reads out of bounds.
- Mixed parallel backends (`doFuture` in stages 1–2, `doParallel` + `type='FORK'` in stage 3);
  `FORK` breaks on Windows. Standardize on one backend.
- Monolithic dated `save.image()` snapshots → replace with explicit, typed return objects.
- `plyr` loaded alongside `dplyr` (masking hazards) → drop `plyr`.

---

## 3. Package layout

```
gbtmkit/                      # proposed package name (see §9)
├── DESCRIPTION               # Imports: stats, cli, future.apply; Suggests: trajeR, lcmm, flexmix, testthat, knitr
├── NAMESPACE                 # roxygen-generated
├── R/
│   ├── engine-interface.R    # the adapter contract (S3 generics)
│   ├── engine-trajer.R       # trajeR adapter (first, ships v0.1)
│   ├── engine-lcmm.R         # lcmm adapter (later)
│   ├── engine-flexmix.R      # flexmix adapter (later)
│   ├── spec.R                # gbtm_spec(): dataset + column mapping + model family
│   ├── select-algorithm.R    # stage 1
│   ├── select-groups.R       # stage 2
│   ├── evaluate-shapes.R     # stage 3 (the refactored trajectory())
│   ├── grolts-criteria.R     # thresholds + filtering
│   ├── diagnostics.R         # entropy/APPA/OCC/PMS/mismatch, engine-neutral where possible
│   ├── fit.R                 # final fit + group assignment
│   ├── plot.R                # trajectory plotting
│   ├── pipeline.R            # run_gbtm_pipeline() orchestrator
│   └── parallel.R            # backend setup helper
├── man/                      # generated
├── tests/testthat/
│   ├── fixtures/             # cached synthetic datasets for tests
│   ├── test-spec.R
│   ├── test-trajer-adapter.R
│   ├── test-diagnostics.R
│   ├── test-grolts-criteria.R
│   └── test-recovery.R       # asserts recovery of synthetic ground truth
├── vignettes/
│   └── getting-started.Rmd  # full analysis walkthrough on synthetic data
├── data/                     # lazy-loaded package data (below)
│   ├── sim_binary.rda
│   └── sim_continuous.rda
└── data-raw/
    └── simulate-data.R      # generates sim_binary + sim_continuous (ground truth known)
```

---

## 4. The engine-agnostic core (the key decision)

Everything hinges on one abstraction: a **fitted trajectory model** and the operations the
pipeline needs from it. Backends differ wildly in call signature and return shape, so we
define a thin S3 adapter. The pipeline only ever talks to this interface.

### 4.1 The specification object

`gbtm_spec()` captures *what* to model, independent of *how*:

```r
spec <- gbtm_spec(
  sim_binary,
  outcomes  = c("y1", "y2", "y3", "y4"),   # by NAME, not index
  time      = c("t1", "t2", "t3", "t4"),
  id        = "id",
  family    = "binomial",   # binomial | gaussian | poisson | beta  (mapped per-engine)
  covariates = NULL
)
```

This removes every hard-coded column index from the workflow. Column selection is by name
with validation (types, missingness, equal lengths of outcomes vs time).

### 4.2 The adapter contract

A backend is registered by implementing a small set of S3 methods on a fit object. Draft:

```r
# Construct + fit. Returns an object of class c("gbtm_fit_<engine>", "gbtm_fit").
gbtm_engine_fit(spec, engine, n_groups, degrees, method = NULL, ...)

# Accessors the pipeline relies on — every engine MUST provide these:
gbtm_bic(fit)              -> numeric(1)
gbtm_aic(fit)              -> numeric(1)
gbtm_posterior(fit)        -> matrix [n_subjects x n_groups]  (posterior probs)
gbtm_group_sizes(fit)      -> numeric(n_groups)               (model-implied proportions)
gbtm_coef(fit)             -> tidy tibble of trajectory parameters
gbtm_predict(fit, time)    -> fitted trajectory per group (for plotting)
gbtm_supported_families(engine) -> character
gbtm_supported_methods(engine)  -> character   (e.g. trajeR: L/EM/EMIRLS; others: NA)
```

All GRoLTS diagnostics (entropy, APPA, OCC, PMS, mismatch) are then computed **once** in
`diagnostics.R` from `gbtm_posterior()` + `gbtm_group_sizes()`, rather than re-derived per
engine. This is the payoff of the abstraction: the original script's bespoke `AvePP`/`OCC`/
`GroupProb` calls (trajeR-specific) get replaced by engine-neutral math on the posterior
matrix. Where an engine ships its own diagnostic, the adapter may override.

### 4.3 Family / method mapping

| neutral `family` | trajeR `Model` | lcmm | flexmix |
|---------|--------|------|---------|
| `binomial` (binary) | `LOGIT` | `hlme`/`lcmm` link | `FLXMRglm(family="binomial")` |
| `gaussian` (continuous) | `CNORM` | `hlme` | `FLXMRglm(family="gaussian")` |
| `poisson` / zero-inflated count | `POIS` / `ZIP` | — | `FLXMRglm(family="poisson")` |
| `beta` (proportions) | `BETA` | — | — |
| algorithm choice | `L`/`EM`/`EMIRLS` | fixed | fixed (EM) |
| polynomial degree | `degre=` vector | `mixture=` formula | formula |

**Continuous outcomes are first-class in v0.1, not deferred.** trajeR's `CNORM`
(censored-normal) model is confirmed working (smoke-tested on `dataNORM01` and on the
synthetic continuous fixture, which recovers its ground truth exactly). Continuous-specific
knobs surface through `gbtm_spec()`:
- `ymin` / `ymax` — censoring bounds (for outcomes with a floor/ceiling; CNORM handles
  censoring that a plain Gaussian mixture ignores).
- `ssigma` — whether variance is shared across groups (trajeR `ssigma=`).

So the same pipeline runs a binary outcome (`family="binomial"` → LOGIT) and a continuous
outcome (`family="gaussian"` → CNORM) with only the spec changing. The diagnostics layer
(§4.2) is already family-neutral because it operates on the posterior matrix, not the outcome
scale.

The adapter translates the neutral `family`/`degrees` into each engine's idiom and advertises
which methods it supports (so stage 1 no-ops for engines without algorithm choice).

---

## 5. Pipeline stages as functions

Each returns a tidy object; none writes files as a side effect (the orchestrator decides
persistence).

```r
select_algorithm(spec, engine, n_groups, degrees, methods = engine_default)
  -> tibble(method, bic, aic); attr best method
     # trajeR: compares L/EM/EMIRLS. Other engines: returns single row, no-op.

select_n_groups(spec, engine, method, candidates = 2:6, degrees = default_per_ng)
  -> tibble(n_groups, bic, aic); attr best n

evaluate_shapes(spec, engine, method, n_groups, max_degree = 4, parallel = TRUE)
  -> tibble: one row per degree combination x [deg1..degG, AIC, BIC, Entropy,
             PMS1..G, APPA1..G, OCC1..G, mismatch1..G]
     # replaces trajectory(); this is the compute-heavy brute force.

apply_grolts_criteria(shapes,
                      pms_min = 0.05, appa_min = 0.70, occ_min = 5,
                      order_by = "BIC")
  -> filtered/ranked tibble; top row = recommended shape.

fit_gbtm(spec, engine, n_groups, degrees, method)   -> gbtm_fit
assign_groups(fit, spec)                             -> tibble(id, group, posterior...)
plot_trajectories(fit, spec, colors = NULL)          -> ggplot
```

Orchestrator:

```r
run_gbtm_pipeline(spec, engine = "trajeR", ...) ->
  gbtm_result {
    algorithm_selection, group_selection, shape_evaluation, criteria,
    final_fit, group_assignment, plot, call, sessioninfo
  }
# with print()/summary()/plot() methods and a GRoLTS-checklist reporter.
```

A `grolts_report(result)` helper emits the checklist items the analysis satisfies (item
numbers from the GRoLTS paper) as a table — this is the feature that most differentiates the
package and directly serves your reporting goal.

---

## 6. Cross-cutting concerns

- **Parallelism:** single backend via `future`/`future.apply` (works on Windows and Unix,
  no `FORK`). `plan()` set by the caller; the package never calls `detectCores()` implicitly.
- **Reproducibility:** seed is a pipeline argument (default documented), threaded to every
  stochastic call; `future` RNG via `future.apply(..., future.seed = TRUE)`.
- **Error handling:** replace `.errorhandling='remove'` (silent) with explicit capture so a
  failed fit is recorded as `NA` diagnostics with a warning, not dropped invisibly.
- **No global state / no save.image:** results are returned; the vignette shows optional
  `saveRDS`.

---

## 7. Testing strategy

1. **Unit tests** for `gbtm_spec()` validation, diagnostics math (against hand-computed toy
   posteriors), and criteria filtering (including the two-filter bug — assert the corrected
   behavior).
2. **Adapter conformance test:** a shared test that any registered engine must pass
   (returns finite BIC, posterior rows sum to 1, group sizes sum to 1).
3. **Recovery test (`test-recovery.R`):** run the pipeline on `sim_binary` and
   `sim_continuous` and assert it recovers the planted `n_groups = 4` and the correct shape
   ordering. Ground truth is known by construction, so no historical reference is needed.
   (Verified during data design: binary recovers `ng=4` by BIC; continuous recovers `ng=4`
   with ~100% classification.)
4. **CI:** GitHub Actions `R CMD check` on macOS/Windows/Linux; `trajeR`/`lcmm`/`flexmix` in
   Suggests so check passes without all engines installed.

---

## 8. Milestones

- **v0.1 — trajeR feature parity.** Package skeleton, `gbtm_spec()`, trajeR adapter, all four
  stages, diagnostics, criteria, plotting, synthetic recovery tests + vignette, for both
  binary (LOGIT) and continuous (CNORM) outcomes. *This is the first shippable, publishable
  repo.*
- **v0.2 — GRoLTS reporter.** `grolts_report()` mapping outputs to checklist items.
- **v0.3 — second engine.** `flexmix` adapter (already installed here) to prove the interface
  generalizes; adjust the contract where trajeR assumptions leaked.
- **v0.4 — lcmm adapter** + continuous/count outcome examples.

---

## 9. Data — synthetic and domain-neutral only

No real data and no external published dataset are used anywhere. Two synthetic datasets are
generated by `data-raw/simulate-data.R` (fixed seed) and ship as lazy-loaded package data:

- **`sim_binary`** (n = 1500) — binary outcomes, four occasions, four planted groups
  (stable-high / falling / rising / stable-low). Recovers `ng = 4` by BIC.
- **`sim_continuous`** (n = 1200) — continuous outcomes, same four shape types, wider
  separation so the single-start CNORM fit avoids local optima. Recovers `ng = 4` with ~100%
  classification.

Both use neutral columns: `id`, covariates `x1`/`x2`, outcomes `y1..y4`, times `t1..t4`, and
a `true_group` label the pipeline never sees. They drive the tests, the examples, and the
vignette. Because ground truth is known, tests assert the pipeline recovers the planted groups
and shapes — no real cohort data, and nothing that hints at the original study's domain. The
original private data stays out of the repo entirely (`.gitignore`).

## 9b. Remaining housekeeping

1. **`to-be-deleted-before-commit/`** (script, manuscript PDF, checklist PDF) → `.gitignore`
   from the first commit so it never enters git history.
2. **License** — MIT (permissive) unless we later link GPL code into `Imports`, in which case
   GPL-3. trajeR/flexmix are only in `Suggests`, so MIT is compatible.

---

## 11. Performance — scaling the shape search to ~80k rows

The dominant cost is stage 3: a full grid of `5^g` fits (625 at g=4, 3,125 at g=5, 15,625 at
g=6), each on ~80k rows with `hessian=TRUE`, `itermax=300`, `Method='L'`. Strategies in
descending order of expected payoff:

1. **Hessian only on the final model, not during search — empirically verified.** In trajeR
   `hessian=TRUE` computes standard errors (Fisher information); the SAS-Traj/GRoLTS workflow
   needs those SEs to report coefficient CIs and judge term significance on the **final**
   model. But model *selection* does not: in a quick `ng=2` LOGIT benchmark the fit gave
   **identical** results either way — BIC 6893.918 (TRUE) vs 6893.919 (FALSE), same converged
   log-likelihood, and `AvePP`/posterior diagnostics work under `FALSE` — while `hessian=FALSE`
   ran in **2.62 s vs 6.78 s (~2.6× faster)**. So the pipeline runs the whole search with
   `hessian=FALSE`, then refits the single chosen model with `hessian=TRUE` to recover the SEs
   the report needs. (`hessian_during_search=FALSE` is the default but is exposed as an
   argument in case a future engine/family behaves differently.)
2. **Prune the search space.** Cap degree at cubic (`4^g` not `5^g`) and replace the full
   Cartesian product with **greedy/stepwise per-group degree selection** (fit max degree, drop
   non-significant top terms) — exponential → ~linear in `g`. Largest structural win. Keep the
   existing two-stage design (pick `ng` with fixed cubic, then search shapes for that `ng`).
3. **Subsample-then-confirm.** Rank degree combinations on a 10–20k random subsample, refit
   only the finalists on the full 80k. Group structure is typically stable to subsampling.
4. **Loose search, tight finalist.** Lower `itermax` / looser tolerance to *rank*; converge
   fully only for the winner.
5. **Right parallel backend.** `plan(multicore)` on macOS/Linux (shared memory, no
   per-task re-serialization of the 80k matrix) with `multisession` as the Windows fallback.
   Load-balanced scheduling (`future.scheduling`) so heterogeneous fits keep all cores busy.
   **Pin BLAS threads to 1** while parallel workers run, to avoid oversubscription.
6. **Optimized BLAS.** Link R to Apple Accelerate (macOS) / OpenBLAS — multiplies the linear
   algebra inside each fit. Use single-threaded BLAS when running many R workers.
7. **Engine as a performance lever.** `Method='L'` (Newton–Raphson, numerical Hessian each
   iteration) is typically slowest/least stable; benchmark `EM`/`EMIRLS`. Across engines,
   `flexmix` (C) and `lcmm::hlme` (Fortran) are often much faster than trajeR at large N —
   the adapter design lets us pick the fastest engine per problem. Ship a small **benchmark
   harness** (`bench::mark`) over an 80k-scale simulated dataset to measure trajeR vs flexmix
   vs lcmm and the effect of each optimization above.

Expected combined effect of (1)+(2)+(3): shape-search wall time down by ~1 order of magnitude
before parallelism/engine choice is even considered. These optimizations live in
`evaluate-shapes.R` and are exposed as pipeline arguments (`hessian_during_search`,
`max_degree`, `search_strategy = c("stepwise","grid")`, `subsample`).

### 11.1 Stage 3 must run unattended and bounded ("not days, no babysitting")

The requirement is a search that (a) never runs for days, and (b) needs no interaction while
it runs. The design achieves both without forcing you to choose grid-vs-stepwise up front:

- **Estimate before committing.** `evaluate_shapes()` first times a handful of representative
  fits, extrapolates total cost from the planned number of fits, and prints an **up-front ETA**
  ("≈ 240 fits, est. 18 min on 10 cores"). If the estimate exceeds `time_budget` (default e.g.
  2 h), it automatically switches from `grid` to the cheaper `stepwise` strategy and/or turns
  on `subsample` — so it self-limits instead of running away.
- **Stepwise is the default strategy** (greedy per-group degree, ~linear in `g`), which is
  what keeps a `g=5`/`g=6` problem from exploding to thousands of fits. `grid` remains
  available for small `g` or final confirmation.
- **Hard budget.** A `time_budget` / `max_fits` cap stops the search cleanly and returns the
  best model found so far, flagged as budget-limited — never an open-ended run.
- **Checkpointing.** Each completed fit's diagnostics are appended to an on-disk store
  (`checkpoint_dir`). A crash or manual stop loses nothing; re-running resumes from the
  checkpoint. You can also open the partial results while it's still going.
- **Non-interactive progress.** Instead of a live progress bar that needs watching, progress
  (with running ETA) is written to a log file via `progressr` file handler. Run it in the
  background and walk away.
- **Notify on completion, not on a timer.** Optionally fire a desktop/email notification when
  the search finishes — so you check back once, at the end, rather than every 5–10 min.

Net: you kick off `run_gbtm_pipeline(spec, time_budget = "2h")`, get an ETA immediately, and
either let it finish or accept the best-within-budget answer. No day-long runs, no polling.

---

## 10. Build sequence (step by step, confirmed at each stage)

1. ✅ Rename folder → `gbtmkit/`, `git init`, `.gitignore` (excludes `to-be-deleted-before-commit/`,
   `*.RData`, `.DS_Store`, private `*.rds`).
2. ✅ Synthetic data generator + `sim_binary` / `sim_continuous` fixtures, recovery verified.
3. Scaffold the package (`DESCRIPTION`, `NAMESPACE`, `R/`, `tests/`, MIT `LICENSE`,
   `usethis`-style metadata); wire the fixtures in as lazy-loaded package data.
4. Implement `gbtm_spec()` + trajeR adapter + diagnostics with tests (the riskiest core).
5. Port stages 1–4 on top of the adapter; delete the buggy duplicated logic.
6. Vignette + `R CMD check` + CI, then create the GitHub repo.
