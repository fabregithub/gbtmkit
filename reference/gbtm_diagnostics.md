# GRoLTS classification diagnostics for a fitted model

Computes the group-based trajectory fit diagnostics used by the GRoLTS
checklist – assigned and model-implied group proportions and their
mismatch, average posterior probability of assignment (APPA), odds of
correct classification (OCC), and the normalised classification entropy
– entirely from the posterior matrix and model group sizes, so the
result is identical regardless of estimation engine.

## Usage

``` r
gbtm_diagnostics(fit, ...)
```

## Arguments

- fit:

  A
  [gbtm_fit](https://fabregithub.github.io/gbtmkit/reference/gbtm_fit.md)
  object.

- ...:

  Unused.

## Value

An object of class `gbtm_diagnostics`: a list with `groups` (a per-group
data frame), scalar `entropy`, `n`, and `n_groups`. When called on a fit
it also carries `bic`, `aic`, `loglik`, and `degrees`.

## Examples

``` r
# \donttest{
data("sim_binary", package = "gbtmkit")
spec <- gbtm_spec(sim_binary, paste0("y", 1:10),
                  paste0("t", 1:10), id = "id", family = "binomial")
fit <- gbtm_fit(spec, n_groups = 4, degrees = rep(3, 4), seed = 1)
gbtm_diagnostics(fit)
# }
```
