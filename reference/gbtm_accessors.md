# Engine-agnostic accessors for a fitted model

Read the quantities the pipeline needs from a
[gbtm_fit](https://fabregithub.github.io/gbtmkit/reference/gbtm_fit.md)
without knowing which engine produced it.

## Usage

``` r
gbtm_bic(fit, ...)

gbtm_aic(fit, ...)

gbtm_loglik(fit, ...)

gbtm_posterior(fit, ...)

gbtm_group_sizes(fit, ...)

gbtm_n_groups(fit, ...)

gbtm_degrees(fit, ...)
```

## Arguments

- fit:

  A
  [gbtm_fit](https://fabregithub.github.io/gbtmkit/reference/gbtm_fit.md)
  object.

- ...:

  Unused.

## Value

- `gbtm_bic()`, `gbtm_aic()`, `gbtm_loglik()`: a single numeric.

- `gbtm_posterior()`: a subjects x groups matrix of posterior
  probabilities (rows sum to 1).

- `gbtm_group_sizes()`: a length-`n_groups` vector of model-implied
  group proportions (sums to 1).

- `gbtm_n_groups()`: integer number of groups.

- `gbtm_degrees()`: integer vector of polynomial degrees.
