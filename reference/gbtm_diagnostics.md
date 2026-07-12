# GRoLTS classification diagnostics for a fitted model

Computes the group-based trajectory fit diagnostics used by the GRoLTS
checklist – assigned and model-implied group proportions and their
mismatch, average posterior probability of assignment (APPA), odds of
correct classification (OCC), and the normalized classification entropy
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
if (requireNamespace("trajeR", quietly = TRUE)) {
  fit <- gbtm_fit(spec, n_groups = 4, degrees = rep(3, 4), seed = 1)
  gbtm_diagnostics(fit)
}
#> Starting Values
#> 0.250.250.250.25-5000-0.4775644582738760000.849072740011534000-5000
#> 
#> 
#> Likelihood
#> initial  value 10985.536114 
#> iter   2 value 10491.023900
#> iter   3 value 10471.323454
#> iter   4 value 9823.350897
#> iter   5 value 9333.426651
#> iter   6 value 9316.718687
#> iter   7 value 9179.286071
#> iter   8 value 9137.369486
#> iter   9 value 9052.669142
#> iter  10 value 8798.250325
#> iter  11 value 8769.494247
#> iter  12 value 8750.810683
#> iter  13 value 8726.869840
#> iter  14 value 8725.947706
#> iter  15 value 8722.244141
#> iter  16 value 8667.774160
#> iter  17 value 8636.616889
#> iter  18 value 8626.618719
#> iter  19 value 8600.056315
#> iter  20 value 8582.688098
#> iter  21 value 8566.595616
#> iter  22 value 8552.985022
#> iter  23 value 8549.192827
#> iter  24 value 8540.491198
#> iter  25 value 8532.204181
#> iter  26 value 8526.663445
#> iter  27 value 8523.149421
#> iter  28 value 8512.969348
#> iter  29 value 8509.324331
#> iter  30 value 8505.655931
#> iter  31 value 8503.261298
#> iter  32 value 8502.038681
#> iter  33 value 8500.698396
#> iter  34 value 8500.069759
#> iter  35 value 8499.784763
#> iter  36 value 8499.699434
#> iter  37 value 8499.628868
#> iter  38 value 8499.573922
#> iter  39 value 8499.549704
#> iter  40 value 8499.539219
#> iter  41 value 8499.538432
#> iter  41 value 8499.538424
#> iter  41 value 8499.538416
#> final  value 8499.538416 
#> converged
#> <gbtm_diagnostics> groups=4  n=1500  entropy=0.761
#>   BIC=17138.03  AIC=17037.08  logLik=-8499.54
#>  group n_assigned prop_assigned prop_model mismatch  appa    occ
#>      1        323         0.215      0.196   -0.019 0.861 25.358
#>      2        292         0.195      0.218    0.023 0.901 32.724
#>      3        586         0.391      0.371   -0.020 0.895 14.419
#>      4        299         0.199      0.215    0.016 0.851 20.766
# }
```
