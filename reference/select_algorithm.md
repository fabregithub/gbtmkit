# Stage 1: select the estimation algorithm

Fits a fixed group number and shape under each candidate estimation
method and picks the one with the lowest BIC. For engines with a single
optimizer (see
[`gbtm_engine_methods()`](https://fabregithub.github.io/gbtmkit/reference/gbtm_engine_methods.md))
this is a no-op that returns that method.

## Usage

``` r
select_algorithm(
  spec,
  engine = gbtm_engines(),
  n_groups,
  degrees,
  methods = NULL,
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

- n_groups:

  Number of groups to use for the comparison.

- degrees:

  Integer vector of polynomial degrees, length `n_groups`.

- methods:

  Character vector of methods to compare; defaults to all methods the
  engine offers.

- by:

  Criterion to minimize, `"bic"` (default) or `"aic"`.

- hessian, itermax, seed, ...:

  Passed to
  [`gbtm_fit()`](https://fabregithub.github.io/gbtmkit/reference/gbtm_fit.md).
  `hessian` defaults to `FALSE` (selection does not need standard
  errors).

## Value

A `gbtm_selection` object with `$table`, `$best` (the chosen method),
and the fitted models.

## Examples

``` r
# \donttest{
data("sim_binary", package = "gbtmkit")
spec <- gbtm_spec(sim_binary, c("y1","y2","y3","y4"),
                  c("t1","t2","t3","t4"), id = "id", family = "binomial")
if (requireNamespace("trajeR", quietly = TRUE))
  select_algorithm(spec, n_groups = 4, degrees = rep(1, 4))
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
#> 0.250.250.250.25-50-0.94894612107369700.3856559360520410-50
#> 
#> 
#> Likelihood
#> iter   1 value 3889.644459
#> iter   2 value 3390.187377
#> iter   3 value 3230.936809
#> iter   4 value 3180.077398
#> iter   5 value 3173.181289
#> iter   6 value 3170.956929
#> iter   7 value 3169.756027
#> iter   8 value 3169.060187
#> iter   9 value 3168.634739
#> iter  10 value 3168.358301
#> iter  11 value 3168.167911
#> iter  12 value 3168.030212
#> iter  13 value 3167.926768
#> iter  14 value 3167.846815
#> iter  15 value 3167.785100
#> iter  16 value 3167.734101
#> iter  17 value 3167.694481
#> iter  18 value 3167.659892
#> iter  19 value 3167.633077
#> iter  20 value 3167.608808
#> iter  21 value 3167.589959
#> iter  22 value 3167.572450
#> iter  23 value 3167.558811
#> iter  24 value 3167.545915
#> iter  25 value 3167.535110
#> iter  26 value 3167.525485
#> iter  27 value 3167.517939
#> iter  28 value 3167.510581
#> iter  29 value 3167.504788
#> iter  30 value 3167.499106
#> iter  31 value 3167.494584
#> iter  32 value 3167.490744
#> iter  33 value 3167.487454
#> iter  34 value 3167.483506
#> iter  35 value 3167.480674
#> iter  36 value 3167.478253
#> iter  37 value 3167.476148
#> iter  38 value 3167.473371
#> iter  39 value 3167.471456
#> iter  40 value 3167.469798
#> iter  41 value 3167.468322
#> iter  42 value 3167.466993
#> iter  43 value 3167.465789
#> iter  44 value 3167.463700
#> iter  45 value 3167.462426
#> iter  46 value 3167.461284
#> iter  47 value 3167.460199
#> iter  48 value 3167.459149
#> iter  49 value 3167.458115
#> iter  50 value 3167.456242
#> iter  51 value 3167.454975
#> iter  52 value 3167.453708
#> iter  53 value 3167.453246
#> iter  54 value 3167.451861
#> iter  55 value 3167.449845
#> iter  56 value 3167.449197
#> iter  57 value 3167.447374
#> iter  58 value 3167.445818
#> iter  59 value 3167.444625
#> iter  60 value 3167.442857
#> iter  61 value 3167.440122
#> iter  62 value 3167.437059
#> iter  63 value 3167.433493
#> iter  64 value 3167.429296
#> iter  65 value 3167.424312
#> iter  66 value 3167.418345
#> iter  67 value 3167.411149
#> iter  68 value 3167.402406
#> iter  69 value 3167.391710
#> iter  70 value 3167.378530
#> iter  71 value 3167.360654
#> iter  72 value 3167.339263
#> iter  73 value 3167.312431
#> iter  74 value 3167.278355
#> iter  75 value 3167.234648
#> iter  76 value 3167.178055
#> iter  77 value 3167.104075
#> iter  78 value 3167.006427
#> iter  79 value 3166.876308
#> iter  80 value 3166.701348
#> iter  81 value 3166.464242
#> iter  82 value 3166.141094
#> iter  83 value 3165.699819
#> iter  84 value 3165.099600
#> iter  85 value 3164.294489
#> iter  86 value 3163.239033
#> iter  87 value 3161.912704
#> iter  88 value 3160.343507
#> iter  89 value 3158.629975
#> iter  90 value 3156.931073
#> iter  91 value 3155.415150
#> iter  92 value 3154.195695
#> iter  93 value 3153.299978
#> iter  94 value 3152.685853
#> iter  95 value 3152.281554
#> iter  96 value 3152.017906
#> iter  97 value 3151.842477
#> iter  98 value 3151.721198
#> iter  99 value 3151.631852
#> Starting Values
#> 0.250.250.250.25-50-0.94894612107369700.3856559360520410-50
#> 
#> 
#> Likelihood
#> iter   1 value 3889.644459
#> iter   2 value 3390.205253
#> iter   3 value 3230.912657
#> iter   4 value 3180.077986
#> iter   5 value 3173.183583
#> iter   6 value 3170.958519
#> iter   7 value 3169.757112
#> iter   8 value 3169.060963
#> iter   9 value 3168.635321
#> iter  10 value 3168.358756
#> iter  11 value 3168.168284
#> iter  12 value 3168.030529
#> iter  13 value 3167.927045
#> iter  14 value 3167.847067
#> iter  15 value 3167.783928
#> iter  16 value 3167.733262
#> iter  17 value 3167.692074
#> iter  18 value 3167.658231
#> iter  19 value 3167.630166
#> iter  20 value 3167.606706
#> iter  21 value 3167.586956
#> iter  22 value 3167.570221
#> iter  23 value 3167.555958
#> iter  24 value 3167.543736
#> iter  25 value 3167.533212
#> iter  26 value 3167.524109
#> iter  27 value 3167.516201
#> iter  28 value 3167.509304
#> iter  29 value 3167.503265
#> iter  30 value 3167.497961
#> iter  31 value 3167.493285
#> iter  32 value 3167.489149
#> iter  33 value 3167.485480
#> iter  34 value 3167.482215
#> iter  35 value 3167.479300
#> iter  36 value 3167.476690
#> iter  37 value 3167.474345
#> iter  38 value 3167.472231
#> iter  39 value 3167.470318
#> iter  40 value 3167.468581
#> iter  41 value 3167.466996
#> iter  42 value 3167.465543
#> iter  43 value 3167.464204
#> iter  44 value 3167.462963
#> iter  45 value 3167.461803
#> iter  46 value 3167.460711
#> iter  47 value 3167.459674
#> iter  48 value 3167.458677
#> iter  49 value 3167.457710
#> iter  50 value 3167.456757
#> iter  51 value 3167.455807
#> iter  52 value 3167.454844
#> iter  53 value 3167.453854
#> iter  54 value 3167.452819
#> iter  55 value 3167.451722
#> iter  56 value 3167.450539
#> iter  57 value 3167.449247
#> iter  58 value 3167.447815
#> iter  59 value 3167.446210
#> iter  60 value 3167.444389
#> iter  61 value 3167.442302
#> iter  62 value 3167.439888
#> iter  63 value 3167.437073
#> iter  64 value 3167.433763
#> iter  65 value 3167.429844
#> iter  66 value 3167.425172
#> iter  67 value 3167.419565
#> iter  68 value 3167.412792
#> iter  69 value 3167.404560
#> iter  70 value 3167.394488
#> iter  71 value 3167.382083
#> iter  72 value 3167.366700
#> iter  73 value 3167.347485
#> iter  74 value 3167.323304
#> iter  75 value 3167.292628
#> iter  76 value 3167.253386
#> iter  77 value 3167.202741
#> iter  78 value 3167.136777
#> iter  79 value 3167.050044
#> iter  80 value 3166.934914
#> iter  81 value 3166.780670
#> iter  82 value 3166.572283
#> iter  83 value 3166.288855
#> iter  84 value 3165.901931
#> iter  85 value 3165.374335
#> iter  86 value 3164.661105
#> iter  87 value 3163.715489
#> iter  88 value 3162.503737
#> iter  89 value 3161.029838
#> iter  90 value 3159.361664
#> iter  91 value 3157.636712
#> iter  92 value 3156.027328
#> iter  93 value 3154.676411
#> iter  94 value 3153.647768
#> iter  95 value 3152.924006
#> iter  96 value 3152.440980
#> iter  97 value 3152.125773
#> iter  98 value 3151.918350
#> iter  99 value 3151.776977
#> <gbtm_selection> stage=algorithm  by=BIC
#>  method       bic      aic   ok
#>       L  6333.016  6274.57 TRUE
#>      EM 18420.708 18362.26 TRUE
#>  EMIRLS 18496.777 18438.33 TRUE
#>   best: L
# }
```
