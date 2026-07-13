# gbtmkit

**gbtmkit** turns group-based trajectory modeling (GBTM) into a
reproducible, engine-agnostic pipeline that follows the
[GRoLTS](https://doi.org/10.1080/10705511.2016.1247646) checklist
(Guidelines for Reporting on Latent Trajectory Studies) by construction.

📖 **Documentation site:** <https://fabregithub.github.io/gbtmkit/> —
including the [Getting
started](https://fabregithub.github.io/gbtmkit/articles/getting-started.html)
walkthrough and the full function reference.

- **One workflow, any outcome.** Binary (LOGIT) and continuous (CNORM)
  outcomes run through the same specification; count and proportion
  families are mapped too.
- **Engine-agnostic.** Estimation is delegated to interchangeable
  backends ([`trajeR`](https://cran.r-project.org/package=trajeR),
  [`flexmix`](https://cran.r-project.org/package=flexmix), and
  [`lcmm`](https://cran.r-project.org/package=lcmm)) behind a small set
  of accessors, so the GRoLTS diagnostics and plotting work the same
  regardless of engine.
- **GRoLTS diagnostics and reporting built in.** Entropy, average
  posterior probability of assignment (APPA), odds of correct
  classification (OCC), and group proportions are computed once from the
  posterior matrix – and
  [`grolts_report()`](https://fabregithub.github.io/gbtmkit/reference/grolts_report.md)
  maps a pipeline result onto the GRoLTS checklist, auto-filling every
  item the pipeline can answer (with a Markdown export for supplementary
  material).
- **Built to scale.** The shape search fits with the Hessian off,
  defaults to a greedy stepwise strategy, and supports a time budget, a
  fit cap, and on-disk checkpointing so large problems run unattended
  and bounded.

## Installation

``` r

# install.packages("remotes")
remotes::install_github("fabregithub/gbtmkit")
```

The estimation engines are optional dependencies; install at least one:

``` r

install.packages("trajeR")    # per-group polynomial degrees, L/EM/EMIRLS
install.packages("flexmix")   # fast EM, one polynomial order for all groups
install.packages("lcmm")      # hlme (gaussian) / thresholds link (binary)
```

Pick the backend per fit with `engine = "trajeR"` (default),
`"flexmix"`, or `"lcmm"` in
[`gbtm_fit()`](https://fabregithub.github.io/gbtmkit/reference/gbtm_fit.md)
/
[`run_gbtm_pipeline()`](https://fabregithub.github.io/gbtmkit/reference/run_gbtm_pipeline.md)
– and let
[`benchmark_engines()`](https://fabregithub.github.io/gbtmkit/reference/benchmark_engines.md)
time them on (a subsample of) your own data when speed matters.

## Quick start

``` r

library(gbtmkit)

data("sim_binary", package = "gbtmkit")

spec <- gbtm_spec(
  sim_binary,
  outcomes = paste0("y", 1:10),
  time     = paste0("t", 1:10),
  id       = "id",
  family   = "binomial"
)

# Algorithm + group-number selection, shape search with GRoLTS criteria,
# and the final Hessian-on fit -- in one call.
res <- run_gbtm_pipeline(spec, candidates = 2:6)

summary(res)
plot_trajectories(res$final_fit)
head(res$assignment)          # per-subject group membership
```

You can also run the stages individually:
[`select_algorithm()`](https://fabregithub.github.io/gbtmkit/reference/select_algorithm.md),
[`select_n_groups()`](https://fabregithub.github.io/gbtmkit/reference/select_n_groups.md),
[`evaluate_shapes()`](https://fabregithub.github.io/gbtmkit/reference/evaluate_shapes.md) +
[`apply_grolts_criteria()`](https://fabregithub.github.io/gbtmkit/reference/apply_grolts_criteria.md),
then
[`fit_gbtm()`](https://fabregithub.github.io/gbtmkit/reference/fit_gbtm.md).
See the [Getting started
vignette](https://fabregithub.github.io/gbtmkit/articles/getting-started.html)
for a full walkthrough.

## What it does — and does not do

**In scope.** Nagin-style GBTM (latent class growth analysis): each
latent group follows its own polynomial trajectory over time, with *no*
within-group random effects. On top of that one model class, gbtmkit
standardizes the whole GRoLTS workflow: optimizer selection (for engines
that offer a choice), group-number selection by BIC, a bounded
polynomial-shape search with GRoLTS acceptance criteria (PMS, APPA,
OCC), the final fit with standard errors, and per-subject group
assignment. Binary and continuous outcomes work on all three engines;
counts (Poisson) on `trajeR`/`flexmix`; proportions (beta) on `trajeR`
only. Covariates work on every engine: class-membership covariates
(Nagin’s “risk factors”) via `gbtm_spec(covariates = ...)` and
time-varying trajectory covariates with group-specific effects via
`gbtm_spec(tcov = ...)` (fitted trajectories are reported at
`tcov = 0`). Multi-start initialization (`n_starts`) guards against
local optima.

**Out of scope (currently).** - **Not growth mixture models.** There are
no within-class random effects; if you need GMM, use
[`lcmm::hlme()`](https://cecileproust-lima.github.io/lcmm/reference/hlme.html)
with a `random =` formula (or similar tools) directly. - **Per-group
polynomial degrees are `trajeR`-only.** `flexmix` and `lcmm` fit one
polynomial order shared by all groups; the shape search adapts
automatically (see
[`gbtm_engine_per_group_degrees()`](https://fabregithub.github.io/gbtmkit/reference/gbtm_engine_per_group_degrees.md)). -
**No cross-engine BIC.** Engines define their likelihoods differently,
so compare BIC only within an engine; use the classification diagnostics
(entropy, APPA, OCC) to sanity-check fits across engines. - No
zero-inflated counts, dual/multi-trajectory models, distal outcomes, or
joint survival models.

## Data

The example datasets `sim_binary` and `sim_continuous` are **entirely
synthetic**, generated by `data-raw/simulate-data.R` with known
ground-truth group membership so the pipeline’s recovery can be
verified. No real data is included.

## License

MIT © Shoji F. Nakayama
