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
spec <- gbtm_spec(sim_binary, c("y1", "y2", "y3", "y4"),
                  c("t1", "t2", "t3", "t4"), id = "id", family = "binomial")
if (requireNamespace("trajeR", quietly = TRUE)) {
  fit <- gbtm_fit(spec, n_groups = 4, degrees = rep(1, 4), seed = 1)
  gbtm_diagnostics(fit)
}
#> Starting Values
#> 0.250.250.250.25-50-0.94894612107369700.3856559360520410-50
#> 
#> 
#> Likelihood
#> initial  value 3889.644459 
#> iter   2 value 3686.500786
#> iter   3 value 3605.669041
#> iter   4 value 3476.798584
#> iter   5 value 3463.604944
#> iter   6 value 3364.300839
#> iter   7 value 3293.207267
#> iter   8 value 3288.003410
#> iter   9 value 3255.318374
#> iter  10 value 3238.305472
#> iter  11 value 3207.819092
#> iter  12 value 3172.603149
#> iter  13 value 3164.655958
#> iter  14 value 3158.339294
#> iter  15 value 3154.316268
#> iter  16 value 3147.480475
#> iter  17 value 3141.047569
#> iter  18 value 3138.714029
#> iter  19 value 3137.704408
#> iter  20 value 3137.256644
#> iter  21 value 3137.058930
#> iter  22 value 3136.895103
#> iter  23 value 3136.715689
#> iter  24 value 3136.474564
#> iter  25 value 3136.406977
#> iter  26 value 3136.349818
#> iter  27 value 3136.246247
#> iter  28 value 3136.225298
#> iter  29 value 3136.090264
#> iter  30 value 3135.675899
#> iter  31 value 3135.426328
#> iter  32 value 3135.033194
#> iter  33 value 3134.684070
#> iter  34 value 3134.288829
#> iter  35 value 3134.058545
#> iter  36 value 3133.787293
#> iter  37 value 3133.313530
#> iter  38 value 3132.792135
#> iter  39 value 3132.585801
#> iter  40 value 3132.464281
#> iter  41 value 3132.182210
#> iter  42 value 3131.961313
#> iter  43 value 3130.705631
#> iter  44 value 3130.625574
#> iter  45 value 3130.470530
#> iter  46 value 3130.414801
#> iter  47 value 3130.334164
#> iter  48 value 3130.309852
#> iter  49 value 3130.077779
#> iter  50 value 3129.571736
#> iter  51 value 3128.687810
#> iter  52 value 3128.611177
#> iter  53 value 3128.262066
#> iter  54 value 3128.211748
#> iter  55 value 3128.202360
#> iter  56 value 3128.037359
#> iter  57 value 3127.911980
#> iter  58 value 3127.817608
#> iter  59 value 3127.581595
#> iter  60 value 3126.770200
#> iter  61 value 3126.624897
#> iter  62 value 3126.510753
#> iter  63 value 3126.468151
#> iter  64 value 3126.435579
#> iter  65 value 3126.430714
#> iter  66 value 3126.427093
#> iter  67 value 3126.393073
#> iter  68 value 3126.368812
#> iter  69 value 3126.331335
#> iter  70 value 3126.306524
#> iter  71 value 3126.296714
#> iter  72 value 3126.291394
#> iter  73 value 3126.287285
#> iter  74 value 3126.285094
#> iter  74 value 3126.285093
#> final  value 3126.285093 
#> converged
#> <gbtm_diagnostics> groups=4  n=1500  entropy=0.791
#>   BIC=6333.02  AIC=6274.57  logLik=-3126.29
#>  group n_assigned prop_assigned prop_model mismatch  appa    occ
#>      1        339         0.226      0.193   -0.033 0.795 16.216
#>      2        254         0.169      0.112   -0.057 0.663 15.534
#>      3        308         0.205      0.239    0.034 0.924 38.463
#>      4        599         0.399      0.456    0.057 0.988 96.231
# }
```
