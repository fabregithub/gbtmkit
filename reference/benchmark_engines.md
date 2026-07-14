# Benchmark the estimation engines on a specification

Fits the same model with each requested engine and reports wall-clock
time alongside the engine-neutral diagnostics (entropy, minimum APPA,
effective number of groups). Use it to pick a backend for a large
problem: fit a subsample first, then commit to the fastest engine whose
classification quality is adequate.

## Usage

``` r
benchmark_engines(
  spec,
  n_groups,
  degrees,
  engines = gbtm_engines(),
  method = NULL,
  hessian = FALSE,
  itermax = 100L,
  seed = NULL,
  ...
)
```

## Arguments

- spec:

  A
  [gbtm_spec](https://fabregithub.github.io/gbtmkit/reference/gbtm_spec.md).

- n_groups:

  Number of latent groups.

- degrees:

  Integer vector of polynomial degrees, length `n_groups`. Engines
  without per-group degrees (see
  [`gbtm_engine_per_group_degrees()`](https://fabregithub.github.io/gbtmkit/reference/gbtm_engine_per_group_degrees.md))
  are skipped – with a note – unless the degrees are uniform.

- engines:

  Engines to benchmark; defaults to all registered engines. Engines
  whose package is not installed or whose families do not include
  `spec$family` are recorded as skipped.

- method:

  Estimation method for engines that offer a choice (trajeR); ignored by
  single-optimiser engines.

- hessian, itermax, seed, ...:

  Passed to
  [`gbtm_fit()`](https://fabregithub.github.io/gbtmkit/reference/gbtm_fit.md)
  (e.g. `n_starts`).

## Value

An object of class `gbtm_benchmark`: a data frame with one row per
engine (`engine`, `ok`, `seconds`, `bic`, `loglik`, `entropy`,
`min_appa`, `groups_effective`, `note`).

## Details

BIC and log-likelihood are reported for completeness but are comparable
only *within* an engine – each backend defines its likelihood
differently. Compare engines on time and on the classification
diagnostics.

## Examples

``` r
# \donttest{
data("sim_binary", package = "gbtmkit")
spec <- gbtm_spec(sim_binary, paste0("y", 1:10),
                  paste0("t", 1:10), id = "id", family = "binomial")
benchmark_engines(spec, n_groups = 4, degrees = rep(2, 4), seed = 1)
# }
```
