# gbtmkit

<!-- badges: start -->
[![R-CMD-check](https://github.com/fabregithub/gbtmkit/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/fabregithub/gbtmkit/actions/workflows/R-CMD-check.yaml)
[![pkgdown](https://github.com/fabregithub/gbtmkit/actions/workflows/pkgdown.yaml/badge.svg)](https://github.com/fabregithub/gbtmkit/actions/workflows/pkgdown.yaml)
<!-- badges: end -->

**gbtmkit** turns group-based trajectory modeling (GBTM) into a reproducible,
engine-agnostic pipeline that follows the
[GRoLTS](https://doi.org/10.1080/10705511.2016.1247646) checklist (Guidelines
for Reporting on Latent Trajectory Studies) by construction.

📖 **Documentation site:** <https://fabregithub.github.io/gbtmkit/> — including the
[Getting started](https://fabregithub.github.io/gbtmkit/articles/getting-started.html)
walkthrough and the full function reference.

- **One workflow, any outcome.** Binary (LOGIT) and continuous (CNORM) outcomes
  run through the same specification; count and proportion families are mapped
  too.
- **Engine-agnostic.** Estimation is delegated to interchangeable backends
  ([`trajeR`](https://cran.r-project.org/package=trajeR),
  [`flexmix`](https://cran.r-project.org/package=flexmix), and
  [`lcmm`](https://cran.r-project.org/package=lcmm)) behind a small set
  of accessors, so the GRoLTS diagnostics and plotting work the same
  regardless of engine.
- **GRoLTS diagnostics built in.** Entropy, average posterior probability of
  assignment (APPA), odds of correct classification (OCC), and group
  proportions are computed once from the posterior matrix.
- **Built to scale.** The shape search fits with the Hessian off, defaults to a
  greedy stepwise strategy, and supports a time budget, a fit cap, and on-disk
  checkpointing so large problems run unattended and bounded.

## Installation

```r
# install.packages("remotes")
remotes::install_github("fabregithub/gbtmkit")
```

The estimation engines are optional dependencies; install at least one:

```r
install.packages("trajeR")    # per-group polynomial degrees, L/EM/EMIRLS
install.packages("flexmix")   # fast EM, one polynomial order for all groups
install.packages("lcmm")      # hlme (gaussian) / thresholds link (binary)
```

Pick the backend per fit with `engine = "trajeR"` (default), `"flexmix"`, or
`"lcmm"` in `gbtm_fit()` / `run_gbtm_pipeline()`.

## Quick start

```r
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

You can also run the stages individually: `select_algorithm()`,
`select_n_groups()`, `evaluate_shapes()` + `apply_grolts_criteria()`, then
`fit_gbtm()`. See the
[Getting started vignette](https://fabregithub.github.io/gbtmkit/articles/getting-started.html)
for a full walkthrough.

## What it does — and does not do

**In scope.** Nagin-style GBTM (latent class growth analysis): each latent
group follows its own polynomial trajectory over time, with *no* within-group
random effects. On top of that one model class, gbtmkit standardizes the whole
GRoLTS workflow: optimizer selection (for engines that offer a choice),
group-number selection by BIC, a bounded polynomial-shape search with GRoLTS
acceptance criteria (PMS, APPA, OCC), the final fit with standard errors, and
per-subject group assignment. Binary and continuous outcomes work on all three
engines; counts (Poisson) on `trajeR`/`flexmix`; proportions (beta) on
`trajeR` only. Class-membership covariates (Nagin's "risk factors") are
supported on every engine via `gbtm_spec(covariates = ...)`, and multi-start
initialization (`n_starts`) guards against local optima.

**Out of scope (currently).**

- **No trajectory covariates.** Group trajectories are functions of time
  only; time-varying covariates on the outcome are not yet exposed.
  (Covariates on *class membership* are supported -- see above. The `x1`/`x2`
  columns in the demo data are deliberately inert.)
- **Not growth mixture models.** There are no within-class random effects; if
  you need GMM, use `lcmm::hlme()` with a `random =` formula (or similar
  tools) directly.
- **Per-group polynomial degrees are `trajeR`-only.** `flexmix` and `lcmm`
  fit one polynomial order shared by all groups; the shape search adapts
  automatically (see `gbtm_engine_per_group_degrees()`).
- **No cross-engine BIC.** Engines define their likelihoods differently, so
  compare BIC only within an engine; use the classification diagnostics
  (entropy, APPA, OCC) to sanity-check fits across engines.
- No zero-inflated counts, dual/multi-trajectory models, distal outcomes, or
  joint survival models.

## Data

The example datasets `sim_binary` and `sim_continuous` are **entirely
synthetic**, generated by `data-raw/simulate-data.R` with known ground-truth
group membership so the pipeline's recovery can be verified. No real data is
included.

## License

MIT © Shoji F. Nakayama
