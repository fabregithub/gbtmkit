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

  Optional character vector of covariate column names (reserved for
  group-membership models; not used by the basic pipeline).

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
#> <gbtm_spec>
#>   family     : binomial
#>   subjects   : 1500
#>   occasions  : 10
#>   outcomes   : y1, y2, y3, y4, y5, y6, y7, y8, y9, y10
#>   time       : t1, t2, t3, t4, t5, t6, t7, t8, t9, t10
#>   id         : id
```
