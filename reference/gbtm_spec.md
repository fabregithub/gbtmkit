# Create a group-based trajectory model specification

Builds a validated `gbtm_spec` object describing the data and the model
to fit, without committing to an estimation engine. Columns are selected
*by name*, and the outcome values are checked against the declared
`family`.

## Usage

``` r
gbtm_spec(
  data,
  outcomes,
  time,
  id = NULL,
  family = gbtm_families(),
  covariates = NULL,
  tcov = NULL,
  ymin = NULL,
  ymax = NULL,
  ssigma = FALSE
)
```

## Arguments

- data:

  A data frame (or matrix with column names) in wide format: one row per
  subject, one column per outcome occasion.

- outcomes:

  Character vector of outcome column names, in time order.

- time:

  Character vector of time/occasion column names, the same length as
  `outcomes`.

- id:

  Optional name of a subject-identifier column. If `NULL`, row numbers
  are used. When supplied it must contain no duplicates.

- family:

  Outcome family; one of
  [`gbtm_families()`](https://fabregithub.github.io/gbtmkit/reference/gbtm_families.md).
  `"binomial"` for binary outcomes (LOGIT), `"gaussian"` for continuous
  (CNORM), `"poisson"` for counts, `"beta"` for proportions.

- covariates:

  Optional character vector of column names used as class-membership
  covariates (Nagin's "risk factors"): time-stable subject-level
  variables that predict *which group a subject belongs to* via a
  multinomial model, without affecting the group trajectories
  themselves. Supported by every engine (trajeR `Risk`, flexmix
  concomitant model, lcmm `classmb`). Columns may be numeric, logical,
  or factor/character (expanded via
  [`stats::model.matrix()`](https://rdrr.io/r/stats/model.matrix.html)
  where the engine needs a numeric design) and must contain no missing
  values.

- tcov:

  Optional *time-varying* (trajectory) covariates: a named list, one
  element per covariate, each a character vector of column names of the
  same length as `outcomes` (wide format, one column per occasion).
  These shift the outcome *within* a group with group-specific
  coefficients (trajeR `TCOV`; added to the component/class formula for
  flexmix and lcmm). Columns must be numeric with no missing values.
  Fitted trajectories from
  [`gbtm_predict()`](https://fabregithub.github.io/gbtmkit/reference/gbtm_predict.md)
  /
  [`plot_trajectories()`](https://fabregithub.github.io/gbtmkit/reference/plot_trajectories.md)
  are computed at `tcov = 0`, so code these covariates with a meaningful
  zero (e.g. 0/1 exposure, or centered).

- ymin, ymax:

  Optional censoring bounds for continuous (`"gaussian"`) outcomes;
  passed through to engines that support censored-normal models.

- ssigma:

  Logical; for continuous outcomes, whether the residual variance is
  shared across groups. Default `FALSE`.

## Value

An object of class `gbtm_spec`: a list with the validated `data`,
`outcomes`, `time`, `id`, `family`, `covariates`, and options.

## Examples

``` r
data("sim_binary", package = "gbtmkit")
spec <- gbtm_spec(
  sim_binary,
  outcomes = paste0("y", 1:10),
  time     = paste0("t", 1:10),
  id       = "id",
  family   = "binomial"
)
spec
```
