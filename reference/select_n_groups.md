# Stage 2: select the number of groups

Fits the model for each candidate number of groups and picks the one
with the lowest BIC. Each candidate uses a polynomial degree of `degree`
for every group unless a per-candidate `degrees` list is supplied.

## Usage

``` r
select_n_groups(
  spec,
  engine = gbtm_engines(),
  candidates = 2:6,
  degree = 3L,
  degrees = NULL,
  method = NULL,
  by = c("bic", "aic"),
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

- engine:

  Engine name; see
  [`gbtm_engines()`](https://fabregithub.github.io/gbtmkit/reference/gbtm_engines.md).

- candidates:

  Integer vector of group numbers to try (default `2:6`).

- degree:

  Single polynomial degree applied to every group (default `3`, cubic).
  Ignored when `degrees` is supplied.

- degrees:

  Optional list, one integer vector per candidate, for full control of
  the shape at each group number.

- method:

  Estimation method to use (e.g. the winner of
  [`select_algorithm()`](https://fabregithub.github.io/gbtmkit/reference/select_algorithm.md)).

- by:

  Criterion to minimize, `"bic"` (default) or `"aic"`.

- hessian, itermax, seed, ...:

  Passed to
  [`gbtm_fit()`](https://fabregithub.github.io/gbtmkit/reference/gbtm_fit.md).

## Value

A `gbtm_selection` object with `$table`, `$best` (the chosen number of
groups), and the fitted models.

## Examples

``` r
# \donttest{
data("sim_binary", package = "gbtmkit")
spec <- gbtm_spec(sim_binary, c("y1","y2","y3","y4"),
                  c("t1","t2","t3","t4"), id = "id", family = "binomial")
if (requireNamespace("trajeR", quietly = TRUE))
  select_n_groups(spec, candidates = 2:5, degree = 1)
#> Starting Values
#> 0.50.5-2.1690177846160201.218309550283050
#> 
#> 
#> Likelihood
#> initial  value 3454.147366 
#> iter   2 value 3423.436500
#> iter   3 value 3414.748985
#> iter   4 value 3311.191835
#> iter   5 value 3213.160855
#> iter   6 value 3194.629948
#> iter   7 value 3179.043480
#> iter   8 value 3168.399518
#> iter   9 value 3167.928377
#> iter  10 value 3167.904775
#> iter  11 value 3167.903287
#> iter  12 value 3167.903044
#> iter  12 value 3167.903042
#> final  value 3167.903042 
#> converged
#> Starting Values
#> 0.3333333333333330.3333333333333330.333333333333333-50-0.25266904051869402.403355740238520
#> 
#> 
#> Likelihood
#> initial  value 3514.077440 
#> iter   2 value 3498.032931
#> iter   3 value 3483.431806
#> iter   4 value 3452.370402
#> iter   5 value 3337.074062
#> iter   6 value 3326.914372
#> iter   7 value 3314.743700
#> iter   8 value 3257.081854
#> iter   9 value 3216.237605
#> iter  10 value 3172.366973
#> iter  11 value 3164.067564
#> iter  12 value 3156.954434
#> iter  13 value 3149.228867
#> iter  14 value 3146.831016
#> iter  15 value 3145.406683
#> iter  16 value 3144.595225
#> iter  17 value 3144.458136
#> iter  18 value 3144.338854
#> iter  19 value 3144.330193
#> iter  20 value 3144.327448
#> iter  21 value 3144.326541
#> iter  22 value 3144.315487
#> iter  23 value 3144.312589
#> iter  24 value 3144.286041
#> iter  25 value 3144.275312
#> iter  26 value 3144.271232
#> iter  27 value 3144.267692
#> iter  28 value 3144.267226
#> iter  28 value 3144.267224
#> iter  28 value 3144.267224
#> final  value 3144.267224 
#> converged
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
#> Starting Values
#> 0.20.20.20.20.2-50-1.5366464063360-0.25266904051869400.8345209703968940-50
#> 
#> 
#> Likelihood
#> initial  value 3710.037469 
#> iter   2 value 3653.877604
#> iter   3 value 3567.357785
#> iter   4 value 3483.142775
#> iter   5 value 3408.235168
#> iter   6 value 3312.009110
#> iter   7 value 3282.391489
#> iter   8 value 3196.075878
#> iter   9 value 3189.452391
#> iter  10 value 3158.815297
#> iter  11 value 3155.408531
#> iter  12 value 3152.593123
#> iter  13 value 3148.837846
#> iter  14 value 3145.930017
#> iter  15 value 3142.984898
#> iter  16 value 3142.412722
#> iter  17 value 3141.198055
#> iter  18 value 3140.259026
#> iter  19 value 3135.105403
#> iter  20 value 3133.458945
#> iter  21 value 3132.088997
#> iter  22 value 3129.277930
#> iter  23 value 3128.741015
#> iter  24 value 3128.524933
#> iter  25 value 3128.193462
#> iter  26 value 3127.674085
#> iter  27 value 3127.319808
#> iter  28 value 3126.613633
#> iter  29 value 3126.425846
#> iter  30 value 3126.367821
#> iter  31 value 3126.355244
#> iter  32 value 3126.349579
#> iter  33 value 3126.348451
#> iter  34 value 3126.347878
#> iter  35 value 3126.347217
#> iter  36 value 3126.345909
#> iter  37 value 3126.345152
#> iter  38 value 3126.337580
#> iter  39 value 3126.333188
#> iter  40 value 3126.330920
#> iter  41 value 3126.329960
#> iter  42 value 3126.329700
#> iter  43 value 3126.319780
#> iter  44 value 3126.310961
#> iter  45 value 3126.298279
#> iter  46 value 3126.290493
#> iter  47 value 3126.287332
#> iter  48 value 3126.285590
#> iter  49 value 3126.284341
#> iter  50 value 3126.283680
#> iter  51 value 3126.283395
#> iter  52 value 3126.283246
#> iter  53 value 3126.283158
#> iter  53 value 3126.283114
#> iter  53 value 3126.283114
#> final  value 3126.283114 
#> converged
#> <gbtm_selection> stage=n_groups  by=BIC
#>  n_groups   degrees      bic      aic   ok
#>         2       1,1 6372.372 6345.806 TRUE
#>         3     1,1,1 6347.040 6304.534 TRUE
#>         4   1,1,1,1 6333.016 6274.570 TRUE
#>         5 1,1,1,1,1 6354.951 6280.566 TRUE
#>   best: 4
# }
```
