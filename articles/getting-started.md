# Getting started with gbtmkit

`gbtmkit` turns group-based trajectory modeling (GBTM) into a
reproducible pipeline that follows the GRoLTS reporting checklist.
Estimation is delegated to interchangeable backends behind one
interface, so the same workflow handles binary and continuous outcomes,
and the fit diagnostics (entropy, APPA, OCC, group proportions) are
computed the same way regardless of engine.

``` r

library(gbtmkit)
```

## The data

The package ships two entirely synthetic datasets with known
ground-truth groups. `sim_binary` has a binary outcome measured on four
occasions, with four latent trajectory shapes (stable-high, falling,
rising, stable-low):

``` r

data("sim_binary", package = "gbtmkit")
head(sim_binary)
#>   id      x1   x2 y1 y2 y3 y4 t1 t2 t3 t4 true_group
#> 1  1  0.4618 3.01  1  1  0  0  1  2  3  4          2
#> 2  2  0.0972 2.49  1  1  1  0  1  2  3  4          1
#> 3  3  0.6760 2.28  1  1  1  0  1  2  3  4          2
#> 4  4 -0.7488 2.08  1  1  1  1  1  2  3  4          1
#> 5  5  1.0256 4.63  0  0  0  1  1  2  3  4          3
#> 6  6 -0.6966 4.24  0  0  0  0  1  2  3  4          4
```

## 1. Describe the model with a spec

[`gbtm_spec()`](https://fabregithub.github.io/gbtmkit/reference/gbtm_spec.md)
records *what* to model – the outcome and time columns (by name), the
id, and the outcome family – and validates it, independent of which
engine will fit it.

``` r

spec <- gbtm_spec(
  sim_binary,
  outcomes = c("y1", "y2", "y3", "y4"),
  time     = c("t1", "t2", "t3", "t4"),
  id       = "id",
  family   = "binomial"
)
spec
#> <gbtm_spec>
#>   family     : binomial
#>   subjects   : 1500
#>   occasions  : 4
#>   outcomes   : y1, y2, y3, y4
#>   time       : t1, t2, t3, t4
#>   id         : id
```

## 2. Run the whole pipeline in one call

[`run_gbtm_pipeline()`](https://fabregithub.github.io/gbtmkit/reference/run_gbtm_pipeline.md)
performs algorithm selection (when the engine offers a choice),
group-number selection, the polynomial-shape search with GRoLTS
acceptance criteria, and the final Hessian-on fit. Here we use a small
search to keep the vignette quick.

``` r

res <- run_gbtm_pipeline(
  spec,
  candidates = 2:5,     # consider 2 to 5 groups
  degree     = 1,       # linear shapes while choosing the number of groups
  method     = "L",     # fix the algorithm (skip stage 1) for speed
  max_degree = 2,       # allow up to quadratic in the shape search
  seed       = 1,
  verbose    = FALSE
)
#> Starting Values
#> 0.50.5-2.1690177846160201.218309550283050
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
#> Starting Values
#> 0.250.250.250.25-50-0.94894612107369700.3856559360520410-50
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
#> 0.250.250.250.25-500-0.94894612107369700.3856559360520410-50
#> 
#> Likelihood
#> initial  value 3889.644459 
#> iter   2 value 3857.444972
#> iter   3 value 3783.473808
#> iter   4 value 3680.804027
#> iter   5 value 3491.084065
#> iter   6 value 3361.755992
#> iter   7 value 3344.207242
#> iter   8 value 3329.220859
#> iter   9 value 3295.486305
#> iter  10 value 3238.837914
#> iter  11 value 3220.787575
#> iter  12 value 3188.710403
#> iter  13 value 3157.044498
#> iter  14 value 3152.906952
#> iter  15 value 3149.245157
#> iter  16 value 3144.284678
#> iter  17 value 3137.140987
#> iter  18 value 3135.536958
#> iter  19 value 3133.843911
#> iter  20 value 3132.739516
#> iter  21 value 3132.366299
#> iter  22 value 3131.938793
#> iter  23 value 3131.422043
#> iter  24 value 3131.227775
#> iter  25 value 3131.033884
#> iter  26 value 3130.846740
#> iter  27 value 3130.835932
#> iter  28 value 3130.832997
#> iter  29 value 3130.825356
#> iter  30 value 3130.776818
#> iter  31 value 3130.770431
#> iter  32 value 3130.757928
#> iter  33 value 3130.755677
#> iter  34 value 3130.723737
#> iter  35 value 3130.719620
#> iter  36 value 3130.703012
#> iter  37 value 3130.676708
#> iter  38 value 3130.653518
#> iter  39 value 3130.556465
#> iter  40 value 3130.372389
#> iter  41 value 3129.228329
#> iter  42 value 3129.206947
#> iter  43 value 3129.160241
#> iter  44 value 3129.153029
#> iter  45 value 3129.123457
#> iter  46 value 3129.043810
#> iter  47 value 3128.981845
#> iter  48 value 3128.273091
#> iter  49 value 3127.608023
#> iter  50 value 3127.283104
#> iter  51 value 3126.587070
#> iter  52 value 3126.446818
#> iter  53 value 3125.744619
#> iter  54 value 3125.097099
#> iter  55 value 3125.053484
#> iter  56 value 3125.033272
#> iter  57 value 3125.014791
#> iter  58 value 3125.012071
#> iter  59 value 3125.010910
#> iter  60 value 3125.010218
#> iter  61 value 3125.009359
#> iter  62 value 3125.007972
#> iter  63 value 3125.004426
#> iter  64 value 3124.997516
#> iter  65 value 3124.984689
#> iter  66 value 3124.965173
#> iter  67 value 3124.964561
#> iter  68 value 3124.963486
#> iter  69 value 3124.962820
#> iter  70 value 3124.962124
#> iter  71 value 3124.961757
#> iter  72 value 3124.960524
#> iter  73 value 3124.958711
#> iter  74 value 3124.955265
#> iter  75 value 3124.951518
#> iter  76 value 3124.948336
#> iter  77 value 3124.946962
#> iter  78 value 3124.946710
#> iter  79 value 3124.946594
#> iter  80 value 3124.946494
#> iter  81 value 3124.945981
#> iter  82 value 3124.944925
#> iter  83 value 3124.942164
#> iter  84 value 3124.936334
#> iter  85 value 3124.925329
#> iter  86 value 3124.910781
#> iter  87 value 3124.901903
#> iter  88 value 3124.899596
#> iter  89 value 3124.898763
#> iter  90 value 3124.897944
#> iter  91 value 3124.897248
#> iter  91 value 3124.897247
#> final  value 3124.897247 
#> converged
#> Starting Values
#> 0.250.250.250.25-50-0.948946121073697000.3856559360520410-50
#> 
#> Likelihood
#> initial  value 3889.644459 
#> iter   2 value 3773.279285
#> iter   3 value 3692.053609
#> iter   4 value 3557.098354
#> iter   5 value 3260.170347
#> iter   6 value 3248.209713
#> iter   7 value 3235.659960
#> iter   8 value 3189.731324
#> iter   9 value 3180.807178
#> iter  10 value 3173.647182
#> iter  11 value 3164.546209
#> iter  12 value 3160.029796
#> iter  13 value 3152.522698
#> iter  14 value 3148.436470
#> iter  15 value 3145.715291
#> iter  16 value 3143.408634
#> iter  17 value 3142.786940
#> iter  18 value 3141.855997
#> iter  19 value 3139.733274
#> iter  20 value 3137.423009
#> iter  21 value 3133.671343
#> iter  22 value 3131.704825
#> iter  23 value 3130.997668
#> iter  24 value 3130.178136
#> iter  25 value 3130.014288
#> iter  26 value 3129.750331
#> iter  27 value 3129.681226
#> iter  28 value 3129.602476
#> iter  29 value 3129.571009
#> iter  30 value 3129.567511
#> iter  31 value 3129.469260
#> iter  32 value 3129.454885
#> iter  33 value 3129.319947
#> iter  34 value 3129.124787
#> iter  35 value 3127.629002
#> iter  36 value 3126.905517
#> iter  37 value 3126.601171
#> iter  38 value 3126.358381
#> iter  39 value 3125.825839
#> iter  40 value 3125.267036
#> iter  41 value 3124.989534
#> iter  42 value 3124.872809
#> iter  43 value 3124.846131
#> iter  44 value 3124.844817
#> iter  45 value 3124.843879
#> iter  46 value 3124.843806
#> iter  47 value 3124.843754
#> iter  47 value 3124.843750
#> iter  47 value 3124.843750
#> final  value 3124.843750 
#> converged
#> Starting Values
#> 0.250.250.250.25-50-0.94894612107369700.38565593605204100-50
#> 
#> Likelihood
#> initial  value 3889.644459 
#> iter   2 value 3861.039927
#> iter   3 value 3778.376757
#> iter   4 value 3488.070193
#> iter   5 value 3442.837200
#> iter   6 value 3425.501891
#> iter   7 value 3364.567146
#> iter   8 value 3348.142256
#> iter   9 value 3182.035109
#> iter  10 value 3179.267773
#> iter  11 value 3166.273695
#> iter  12 value 3159.272230
#> iter  13 value 3158.135361
#> iter  14 value 3151.021561
#> iter  15 value 3145.234753
#> iter  16 value 3145.080859
#> iter  17 value 3140.965783
#> iter  18 value 3139.956935
#> iter  19 value 3137.192411
#> iter  20 value 3135.775329
#> iter  21 value 3133.806424
#> iter  22 value 3132.987699
#> iter  23 value 3132.961939
#> iter  24 value 3132.581676
#> iter  25 value 3132.375564
#> iter  26 value 3132.073951
#> iter  27 value 3132.067815
#> iter  28 value 3132.002534
#> iter  29 value 3131.992782
#> iter  30 value 3131.991178
#> iter  31 value 3131.977162
#> iter  32 value 3131.942894
#> iter  33 value 3131.936572
#> iter  34 value 3131.922592
#> iter  35 value 3131.888435
#> iter  36 value 3131.862383
#> iter  37 value 3131.846223
#> iter  38 value 3131.845322
#> iter  39 value 3131.840003
#> iter  40 value 3131.832938
#> iter  41 value 3131.819543
#> iter  42 value 3131.801888
#> iter  43 value 3131.781660
#> iter  44 value 3131.771031
#> iter  45 value 3131.766248
#> iter  46 value 3131.762846
#> iter  47 value 3131.760632
#> iter  48 value 3131.759197
#> iter  49 value 3131.757635
#> iter  50 value 3131.748021
#> iter  50 value 3131.748020
#> final  value 3131.748020 
#> converged
#> Starting Values
#> 0.250.250.250.25-50-0.94894612107369700.3856559360520410-500
#> 
#> Likelihood
#> initial  value 3889.644459 
#> iter   2 value 3884.117364
#> iter   3 value 3797.634505
#> iter   4 value 3703.929099
#> iter   5 value 3668.150058
#> iter   6 value 3374.504289
#> iter   7 value 3353.687711
#> iter   8 value 3333.657231
#> iter   9 value 3279.777107
#> iter  10 value 3264.814687
#> iter  11 value 3234.123039
#> iter  12 value 3205.835396
#> iter  13 value 3185.219598
#> iter  14 value 3152.710350
#> iter  15 value 3148.365055
#> iter  16 value 3147.549183
#> iter  17 value 3146.589359
#> iter  18 value 3145.466474
#> iter  19 value 3144.646394
#> iter  20 value 3144.320136
#> iter  21 value 3144.279984
#> iter  22 value 3144.208839
#> iter  23 value 3144.171645
#> iter  24 value 3144.073809
#> iter  25 value 3143.867423
#> iter  26 value 3143.823170
#> iter  27 value 3143.812839
#> iter  28 value 3143.804994
#> iter  29 value 3143.743658
#> iter  30 value 3143.606545
#> iter  31 value 3142.518995
#> iter  32 value 3141.538984
#> iter  33 value 3140.420228
#> iter  34 value 3139.397251
#> iter  35 value 3137.675194
#> iter  36 value 3131.398946
#> iter  37 value 3129.443841
#> iter  38 value 3128.777407
#> iter  39 value 3128.098476
#> iter  40 value 3127.590502
#> iter  41 value 3126.991538
#> iter  42 value 3126.377421
#> iter  43 value 3126.075536
#> iter  44 value 3125.814087
#> iter  45 value 3125.667856
#> iter  46 value 3125.589519
#> iter  47 value 3125.458122
#> iter  48 value 3125.343389
#> iter  49 value 3125.200079
#> iter  50 value 3125.066024
#> iter  51 value 3125.055329
#> iter  52 value 3125.051065
#> iter  53 value 3125.050191
#> iter  54 value 3125.046095
#> iter  55 value 3125.027673
#> iter  56 value 3125.019620
#> iter  57 value 3125.010732
#> iter  58 value 3125.004768
#> iter  59 value 3124.994646
#> iter  60 value 3124.977179
#> iter  61 value 3124.971050
#> iter  62 value 3124.970752
#> iter  63 value 3124.970456
#> iter  64 value 3124.970284
#> iter  65 value 3124.967405
#> iter  66 value 3124.962586
#> iter  67 value 3124.951464
#> iter  68 value 3124.933795
#> iter  69 value 3124.913394
#> iter  70 value 3124.903398
#> iter  71 value 3124.900836
#> iter  72 value 3124.899494
#> iter  73 value 3124.898157
#> iter  74 value 3124.897315
#> iter  75 value 3124.897008
#> iter  75 value 3124.897008
#> final  value 3124.897008 
#> converged
#> Starting Values
#> 0.250.250.250.25-50-0.948946121073697000.3856559360520410-50
#> 
#> Likelihood
#> iter   1 value
#> 3889.644459
#> iter   2 value
#> 3889.627302
#> iter   3 value
#> 3889.610147
#> iter   4 value
#> 3889.598353
#> iter   5 value
#> 3889.586561
#> iter   6 value
#> 3889.562618
#> iter   7 value
#> 3889.538677
#> iter   8 value
#> 3889.493625
#> iter   9 value
#> 3889.448568
#> iter  10 value
#> 3889.313359
#> iter  11 value
#> 3889.178098
#> iter  12 value
#> 3888.772000
#> iter  13 value
#> 3888.365428
#> iter  14 value
#> 3887.142930
#> iter  15 value
#> 3885.916275
#> iter  16 value
#> 3882.212403
#> iter  17 value
#> 3878.474218
#> iter  18 value
#> 3867.076496
#> iter  19 value
#> 3855.455285
#> iter  20 value
#> 3819.848604
#> iter  21 value
#> 3784.366133
#> iter  22 value
#> 3687.794526
#> iter  23 value
#> 3583.509813
#> iter  24 value
#> 3486.691823
#> iter  25 value
#> 3407.709801
#> iter  26 value
#> 3329.706310
#> iter  27 value
#> 3255.812494
#> iter  28 value
#> 3226.063030
#> iter  29 value
#> 3201.802902
#> iter  30 value
#> 3172.232995
#> iter  31 value
#> 3160.447478
#> iter  32 value
#> 3152.181980
#> iter  33 value
#> 3151.001477
#> iter  34 value
#> 3150.743960
#> iter  35 value
#> 3150.552934
#> iter  36 value
#> 3150.477713
#> iter  37 value
#> 3150.323127
#> iter  38 value
#> 3150.249630
#> iter  39 value
#> 3150.213110
#> iter  40 value
#> 3150.196624
#> iter  41 value
#> 3150.174962
#> iter  42 value
#> 3150.068066
#> iter  43 value
#> 3149.988809
#> iter  44 value
#> 3149.863500
#> iter  45 value
#> 3149.708262
#> iter  46 value
#> 3149.544059
#> iter  47 value
#> 3149.404202
#> iter  48 value
#> 3149.261249
#> iter  49 value
#> 3149.174357
#> iter  50 value
#> 3149.069294
#> iter  51 value
#> 3148.804661
#> iter  52 value
#> 3148.650714
#> iter  53 value
#> 3148.502214
#> iter  54 value
#> 3148.434060
#> iter  55 value
#> 3148.376452
#> iter  56 value
#> 3148.331585
#> iter  57 value
#> 3148.310441
#> iter  58 value
#> 3148.302500
#> iter  59 value
#> 3148.300269
#> iter  60 value
#> 3148.299871
#> iter  61 value
#> 3148.299617
#> iter  62 value
#> 3148.299583
#> iter  63 value
#> 3148.299575
#> iter  64 value
#> 3148.299574
#> iter  65 value
#> 3148.299574
#> iter  66 value
#> 3148.299574
#> iter  67 value
#> 3148.299573
#> iter  68 value
#> 3148.299570
#> iter  69 value
#> 3148.299564
#> iter  70 value
#> 3148.299548
#> iter  71 value
#> 3148.299507
#> iter  72 value
#> 3148.299406
#> iter  73 value
#> 3148.299170
#> iter  74 value
#> 3148.298688
#> iter  75 value
#> 3148.297896
#> iter  76 value
#> 3148.297253
#> iter  77 value
#> 3148.296902
#> iter  78 value
#> 3148.296803
#> iter  79 value
#> 3148.296771
#> iter  80 value
#> 3148.296722
#> iter  81 value
#> 3148.296688
#> iter  82 value
#> 3148.296670
#> iter  83 value
#> 3148.296662
#> iter  84 value
#> 3148.296659
#> iter  85 value
#> 3148.296656
#> iter  86 value
#> 3148.296654
#> iter  87 value
#> 3148.296653
#> iter  88 value
#> 3148.296653
#> iter  89 value
#> 3148.296653
#> iter  90 value
#> 3148.296653
#> iter  91 value
#> 3148.296653
#> iter  92 value
#> 3148.296653
#> iter  93 value
#> 3148.296653
#> iter  94 value
#> 3148.296653
#> iter  95 value
#> 3148.296653
#> iter  96 value
#> 3148.296653
#> iter  97 value
#> 3148.296653
res
#> <gbtm_result>
#>   engine/family : trajeR / binomial
#>   method        : L
#>   groups        : 4
#>   degrees       : 1, 2, 1, 1
#>   GRoLTS criteria met: TRUE
#>   entropy       : 0.790  BIC: 6384.4
```

The pipeline recovers the four planted groups. Everything each stage
produced is kept on the result object:

``` r

res$group_selection      # BIC for each candidate number of groups
#> <gbtm_selection> stage=n_groups  by=BIC
#>  n_groups   degrees      bic      aic   ok
#>         2       1,1 6372.372 6345.806 TRUE
#>         3     1,1,1 6347.040 6304.534 TRUE
#>         4   1,1,1,1 6333.016 6274.570 TRUE
#>         5 1,1,1,1,1 6354.951 6280.566 TRUE
#>   best: 4
```

``` r

summary(res)
#> === gbtm pipeline result ===
#> <gbtm_result>
#>   engine/family : trajeR / binomial
#>   method        : L
#>   groups        : 4
#>   degrees       : 1, 2, 1, 1
#>   GRoLTS criteria met: TRUE
#>   entropy       : 0.790  BIC: 6384.4
#> 
#> Group diagnostics:
#>  group n_assigned prop_assigned prop_model mismatch  appa    occ
#>      1        525         0.350      0.334   -0.016 0.815  8.797
#>      2        319         0.213      0.234    0.021 0.798 12.987
#>      3        656         0.437      0.433   -0.004 0.981 66.306
#>      4          0         0.000      0.000    0.000    NA     NA
#> 
#> Assigned group sizes:
#> 
#>   1   2   3 
#> 525 319 656
```

## 3. Inspect and plot

[`gbtm_diagnostics()`](https://fabregithub.github.io/gbtmkit/reference/gbtm_diagnostics.md)
gives the GRoLTS classification diagnostics, and
[`plot_trajectories()`](https://fabregithub.github.io/gbtmkit/reference/plot_trajectories.md)
draws the fitted group trajectories with the observed per-group means
overlaid.

``` r

res$diagnostics$groups
#>   group n_assigned prop_assigned   prop_model      mismatch      appa      occ
#> 1     1        525     0.3500000 3.335760e-01 -1.642400e-02 0.8149233  8.79672
#> 2     2        319     0.2126667 2.335606e-01  2.089391e-02 0.7982910 12.98716
#> 3     3        656     0.4373333 4.328634e-01 -4.469911e-03 0.9806229 66.30567
#> 4     4          0     0.0000000 2.334749e-10  2.334749e-10        NA       NA
```

``` r

plot_trajectories(res$final_fit)
```

![Fitted group
trajectories](getting-started_files/figure-html/unnamed-chunk-8-1.png)

Per-subject group assignment (the analogue of exporting a group column)
is in `res$assignment`:

``` r

head(res$assignment)
#>   id group           p1           p2           p3           p4
#> 1  1     3 5.351574e-02 8.131668e-06 0.9464761282 0.000000e+00
#> 2  2     3 1.042806e-03 6.737596e-07 0.9989565202 0.000000e+00
#> 3  3     3 1.042806e-03 6.737596e-07 0.9989565202 0.000000e+00
#> 4  4     3 5.774056e-05 8.437887e-07 0.9999414157 0.000000e+00
#> 5  5     2 1.502229e-01 8.491684e-01 0.0006086841 0.000000e+00
#> 6  6     1 7.999058e-01 1.999149e-01 0.0001792851 7.669056e-10
```

## 4. Or run the stages individually

[`run_gbtm_pipeline()`](https://fabregithub.github.io/gbtmkit/reference/run_gbtm_pipeline.md)
is a convenience wrapper. For full control you can run each GRoLTS stage
yourself and inspect the result before moving on – this is exactly what
the wrapper does internally.

**Stage 1 – choose the estimation algorithm.** trajeR offers `"L"`,
`"EM"` and `"EMIRLS"`; the one with the lowest BIC is selected. (Engines
with a single optimizer skip this stage.)

``` r

algo <- select_algorithm(spec, n_groups = 2, degrees = c(1, 1))
#> Starting Values
#> 0.50.5-2.1690177846160201.218309550283050
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
#> 0.50.5-2.1690177846160201.218309550283050
#> 
#> Likelihood
#> iter   1 value 3454.147366
#> iter   2 value 3252.700921
#> iter   3 value 3182.965584
#> iter   4 value 3171.235428
#> iter   5 value 3169.021791
#> iter   6 value 3168.297519
#> iter   7 value 3168.042249
#> iter   8 value 3167.952190
#> iter   9 value 3167.920408
#> iter  10 value 3167.909183
#> iter  11 value 3167.905214
#> iter  12 value 3167.903811
#> iter  13 value 3167.903314
#> iter  14 value 3167.903284
#> iter  15 value 3167.903280
#> iter  16 value 3167.903277
#> iter  17 value 3167.903261
#> iter  18 value 3167.903255
#> iter  19 value 3167.903251
#> iter  20 value 3167.903246
#> iter  21 value 3167.903243
#> iter  22 value 3167.903239
#> iter  23 value 3167.903231
#> iter  24 value 3167.903173
#> iter  25 value 3167.903090
#> iter  26 value 3167.903088
#> iter  27 value 3167.903086
#> iter  28 value 3167.903083
#> iter  29 value 3167.903083
#> iter  30 value 3167.903080
#> iter  31 value 3167.903079
#> iter  32 value 3167.903078
#> iter  33 value 3167.903077
#> iter  34 value 3167.903074
#> iter  35 value 3167.903074
#> iter  36 value 3167.903072
#> iter  37 value 3167.903071
#> iter  38 value 3167.903070
#> iter  39 value 3167.903070
#> iter  40 value 3167.903069
#> iter  41 value 3167.903069
#> iter  42 value 3167.903068
#> iter  43 value 3167.903066
#> iter  44 value 3167.903066
#> iter  45 value 3167.903064
#> iter  46 value 3167.903063
#> iter  47 value 3167.903063
#> iter  48 value 3167.903063
#> iter  49 value 3167.903062
#> iter  50 value 3167.903061
#> iter  51 value 3167.903061
#> iter  52 value 3167.903060
#> iter  53 value 3167.903060
#> iter  54 value 3167.903059
#> iter  55 value 3167.903058
#> iter  56 value 3167.903058
#> iter  57 value 3167.903058
#> iter  58 value 3167.903057
#> iter  59 value 3167.903057
#> iter  60 value 3167.903057
#> iter  61 value 3167.903056
#> iter  62 value 3167.903056
#> iter  63 value 3167.903055
#> iter  64 value 3167.903054
#> iter  65 value 3167.903054
#> iter  66 value 3167.903054
#> iter  67 value 3167.903053
#> iter  68 value 3167.903052
#> iter  69 value 3167.903052
#> iter  70 value 3167.903052
#> iter  71 value 3167.903051
#> iter  72 value 3167.903051
#> iter  73 value 3167.903051
#> iter  74 value 3167.903051
#> iter  75 value 3167.903051
#> iter  76 value 3167.903051
#> iter  77 value 3167.903050
#> iter  78 value 3167.903050
#> iter  79 value 3167.903050
#> iter  80 value 3167.903050
#> iter  81 value 3167.903049
#> iter  82 value 3167.903049
#> iter  83 value 3167.903049
#> iter  84 value 3167.903049
#> iter  85 value 3167.903049
#> iter  86 value 3167.903049
#> iter  87 value 3167.903049
#> iter  88 value 3167.903048
#> iter  89 value 3167.903048
#> iter  90 value 3167.903048
#> iter  91 value 3167.903047
#> iter  92 value 3167.903046
#> iter  93 value 3167.903046
#> iter  94 value 3167.903046
#> iter  95 value 3167.903046
#> iter  96 value 3167.903046
#> iter  97 value 3167.903046
#> iter  98 value 3167.903046
#> iter  99 value 3167.903045
#> Starting Values
#> 0.50.5-2.1690177846160201.218309550283050
#> 
#> Likelihood
#> iter   1 value 3454.147366
#> iter   2 value 3252.696927
#> iter   3 value 3182.959030
#> iter   4 value 3171.234030
#> iter   5 value 3169.021222
#> iter   6 value 3168.297312
#> iter   7 value 3168.042176
#> iter   8 value 3167.952164
#> iter   9 value 3167.920399
#> iter  10 value 3167.909180
#> iter  11 value 3167.905213
#> iter  12 value 3167.903810
#> iter  13 value 3167.903314
#> iter  14 value 3167.903138
#> iter  15 value 3167.903076
#> iter  16 value 3167.903054
#> iter  17 value 3167.903046
#> iter  18 value 3167.903043
#> iter  19 value 3167.903042
#> iter  20 value 3167.903042
#> iter  21 value 3167.903042
#> iter  22 value 3167.903042
#> iter  23 value 3167.903042
#> iter  24 value 3167.903042
#> iter  25 value 3167.903042
#> iter  26 value 3167.903042
#> iter  27 value 3167.903042
#> iter  28 value 3167.903042
algo
#> <gbtm_selection> stage=algorithm  by=BIC
#>  method       bic       aic   ok
#>       L  6372.372  6345.806 TRUE
#>      EM 25514.385 25487.819 TRUE
#>  EMIRLS 25513.471 25486.905 TRUE
#>   best: L
```

**Stage 2 – choose the number of groups** by BIC over a set of
candidates:

``` r

groups <- select_n_groups(spec, candidates = 2:5, degree = 1, method = "L")
#> Starting Values
#> 0.50.5-2.1690177846160201.218309550283050
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
groups
#> <gbtm_selection> stage=n_groups  by=BIC
#>  n_groups   degrees      bic      aic   ok
#>         2       1,1 6372.372 6345.806 TRUE
#>         3     1,1,1 6347.040 6304.534 TRUE
#>         4   1,1,1,1 6333.016 6274.570 TRUE
#>         5 1,1,1,1,1 6354.951 6280.566 TRUE
#>   best: 4
```

**Stage 3 – search polynomial shapes** for the chosen number of groups,
then apply the GRoLTS acceptance criteria (PMS \> 0.05, APPA \> 0.70,
OCC \>= 5):

``` r

shapes <- evaluate_shapes(spec, n_groups = groups$best, method = "L",
                          max_degree = 2, verbose = FALSE)
#> Starting Values
#> 0.250.250.250.25-50-0.94894612107369700.3856559360520410-50
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
#> 0.250.250.250.25-500-0.94894612107369700.3856559360520410-50
#> 
#> Likelihood
#> initial  value 3889.644459 
#> iter   2 value 3857.444972
#> iter   3 value 3783.473808
#> iter   4 value 3680.804027
#> iter   5 value 3491.084065
#> iter   6 value 3361.755992
#> iter   7 value 3344.207242
#> iter   8 value 3329.220859
#> iter   9 value 3295.486305
#> iter  10 value 3238.837914
#> iter  11 value 3220.787575
#> iter  12 value 3188.710403
#> iter  13 value 3157.044498
#> iter  14 value 3152.906952
#> iter  15 value 3149.245157
#> iter  16 value 3144.284678
#> iter  17 value 3137.140987
#> iter  18 value 3135.536958
#> iter  19 value 3133.843911
#> iter  20 value 3132.739516
#> iter  21 value 3132.366299
#> iter  22 value 3131.938793
#> iter  23 value 3131.422043
#> iter  24 value 3131.227775
#> iter  25 value 3131.033884
#> iter  26 value 3130.846740
#> iter  27 value 3130.835932
#> iter  28 value 3130.832997
#> iter  29 value 3130.825356
#> iter  30 value 3130.776818
#> iter  31 value 3130.770431
#> iter  32 value 3130.757928
#> iter  33 value 3130.755677
#> iter  34 value 3130.723737
#> iter  35 value 3130.719620
#> iter  36 value 3130.703012
#> iter  37 value 3130.676708
#> iter  38 value 3130.653518
#> iter  39 value 3130.556465
#> iter  40 value 3130.372389
#> iter  41 value 3129.228329
#> iter  42 value 3129.206947
#> iter  43 value 3129.160241
#> iter  44 value 3129.153029
#> iter  45 value 3129.123457
#> iter  46 value 3129.043810
#> iter  47 value 3128.981845
#> iter  48 value 3128.273091
#> iter  49 value 3127.608023
#> iter  50 value 3127.283104
#> iter  51 value 3126.587070
#> iter  52 value 3126.446818
#> iter  53 value 3125.744619
#> iter  54 value 3125.097099
#> iter  55 value 3125.053484
#> iter  56 value 3125.033272
#> iter  57 value 3125.014791
#> iter  58 value 3125.012071
#> iter  59 value 3125.010910
#> iter  60 value 3125.010218
#> iter  61 value 3125.009359
#> iter  62 value 3125.007972
#> iter  63 value 3125.004426
#> iter  64 value 3124.997516
#> iter  65 value 3124.984689
#> iter  66 value 3124.965173
#> iter  67 value 3124.964561
#> iter  68 value 3124.963486
#> iter  69 value 3124.962820
#> iter  70 value 3124.962124
#> iter  71 value 3124.961757
#> iter  72 value 3124.960524
#> iter  73 value 3124.958711
#> iter  74 value 3124.955265
#> iter  75 value 3124.951518
#> iter  76 value 3124.948336
#> iter  77 value 3124.946962
#> iter  78 value 3124.946710
#> iter  79 value 3124.946594
#> iter  80 value 3124.946494
#> iter  81 value 3124.945981
#> iter  82 value 3124.944925
#> iter  83 value 3124.942164
#> iter  84 value 3124.936334
#> iter  85 value 3124.925329
#> iter  86 value 3124.910781
#> iter  87 value 3124.901903
#> iter  88 value 3124.899596
#> iter  89 value 3124.898763
#> iter  90 value 3124.897944
#> iter  91 value 3124.897248
#> iter  91 value 3124.897247
#> final  value 3124.897247 
#> converged
#> Starting Values
#> 0.250.250.250.25-50-0.948946121073697000.3856559360520410-50
#> 
#> Likelihood
#> initial  value 3889.644459 
#> iter   2 value 3773.279285
#> iter   3 value 3692.053609
#> iter   4 value 3557.098354
#> iter   5 value 3260.170347
#> iter   6 value 3248.209713
#> iter   7 value 3235.659960
#> iter   8 value 3189.731324
#> iter   9 value 3180.807178
#> iter  10 value 3173.647182
#> iter  11 value 3164.546209
#> iter  12 value 3160.029796
#> iter  13 value 3152.522698
#> iter  14 value 3148.436470
#> iter  15 value 3145.715291
#> iter  16 value 3143.408634
#> iter  17 value 3142.786940
#> iter  18 value 3141.855997
#> iter  19 value 3139.733274
#> iter  20 value 3137.423009
#> iter  21 value 3133.671343
#> iter  22 value 3131.704825
#> iter  23 value 3130.997668
#> iter  24 value 3130.178136
#> iter  25 value 3130.014288
#> iter  26 value 3129.750331
#> iter  27 value 3129.681226
#> iter  28 value 3129.602476
#> iter  29 value 3129.571009
#> iter  30 value 3129.567511
#> iter  31 value 3129.469260
#> iter  32 value 3129.454885
#> iter  33 value 3129.319947
#> iter  34 value 3129.124787
#> iter  35 value 3127.629002
#> iter  36 value 3126.905517
#> iter  37 value 3126.601171
#> iter  38 value 3126.358381
#> iter  39 value 3125.825839
#> iter  40 value 3125.267036
#> iter  41 value 3124.989534
#> iter  42 value 3124.872809
#> iter  43 value 3124.846131
#> iter  44 value 3124.844817
#> iter  45 value 3124.843879
#> iter  46 value 3124.843806
#> iter  47 value 3124.843754
#> iter  47 value 3124.843750
#> iter  47 value 3124.843750
#> final  value 3124.843750 
#> converged
#> Starting Values
#> 0.250.250.250.25-50-0.94894612107369700.38565593605204100-50
#> 
#> Likelihood
#> initial  value 3889.644459 
#> iter   2 value 3861.039927
#> iter   3 value 3778.376757
#> iter   4 value 3488.070193
#> iter   5 value 3442.837200
#> iter   6 value 3425.501891
#> iter   7 value 3364.567146
#> iter   8 value 3348.142256
#> iter   9 value 3182.035109
#> iter  10 value 3179.267773
#> iter  11 value 3166.273695
#> iter  12 value 3159.272230
#> iter  13 value 3158.135361
#> iter  14 value 3151.021561
#> iter  15 value 3145.234753
#> iter  16 value 3145.080859
#> iter  17 value 3140.965783
#> iter  18 value 3139.956935
#> iter  19 value 3137.192411
#> iter  20 value 3135.775329
#> iter  21 value 3133.806424
#> iter  22 value 3132.987699
#> iter  23 value 3132.961939
#> iter  24 value 3132.581676
#> iter  25 value 3132.375564
#> iter  26 value 3132.073951
#> iter  27 value 3132.067815
#> iter  28 value 3132.002534
#> iter  29 value 3131.992782
#> iter  30 value 3131.991178
#> iter  31 value 3131.977162
#> iter  32 value 3131.942894
#> iter  33 value 3131.936572
#> iter  34 value 3131.922592
#> iter  35 value 3131.888435
#> iter  36 value 3131.862383
#> iter  37 value 3131.846223
#> iter  38 value 3131.845322
#> iter  39 value 3131.840003
#> iter  40 value 3131.832938
#> iter  41 value 3131.819543
#> iter  42 value 3131.801888
#> iter  43 value 3131.781660
#> iter  44 value 3131.771031
#> iter  45 value 3131.766248
#> iter  46 value 3131.762846
#> iter  47 value 3131.760632
#> iter  48 value 3131.759197
#> iter  49 value 3131.757635
#> iter  50 value 3131.748021
#> iter  50 value 3131.748020
#> final  value 3131.748020 
#> converged
#> Starting Values
#> 0.250.250.250.25-50-0.94894612107369700.3856559360520410-500
#> 
#> Likelihood
#> initial  value 3889.644459 
#> iter   2 value 3884.117364
#> iter   3 value 3797.634505
#> iter   4 value 3703.929099
#> iter   5 value 3668.150058
#> iter   6 value 3374.504289
#> iter   7 value 3353.687711
#> iter   8 value 3333.657231
#> iter   9 value 3279.777107
#> iter  10 value 3264.814687
#> iter  11 value 3234.123039
#> iter  12 value 3205.835396
#> iter  13 value 3185.219598
#> iter  14 value 3152.710350
#> iter  15 value 3148.365055
#> iter  16 value 3147.549183
#> iter  17 value 3146.589359
#> iter  18 value 3145.466474
#> iter  19 value 3144.646394
#> iter  20 value 3144.320136
#> iter  21 value 3144.279984
#> iter  22 value 3144.208839
#> iter  23 value 3144.171645
#> iter  24 value 3144.073809
#> iter  25 value 3143.867423
#> iter  26 value 3143.823170
#> iter  27 value 3143.812839
#> iter  28 value 3143.804994
#> iter  29 value 3143.743658
#> iter  30 value 3143.606545
#> iter  31 value 3142.518995
#> iter  32 value 3141.538984
#> iter  33 value 3140.420228
#> iter  34 value 3139.397251
#> iter  35 value 3137.675194
#> iter  36 value 3131.398946
#> iter  37 value 3129.443841
#> iter  38 value 3128.777407
#> iter  39 value 3128.098476
#> iter  40 value 3127.590502
#> iter  41 value 3126.991538
#> iter  42 value 3126.377421
#> iter  43 value 3126.075536
#> iter  44 value 3125.814087
#> iter  45 value 3125.667856
#> iter  46 value 3125.589519
#> iter  47 value 3125.458122
#> iter  48 value 3125.343389
#> iter  49 value 3125.200079
#> iter  50 value 3125.066024
#> iter  51 value 3125.055329
#> iter  52 value 3125.051065
#> iter  53 value 3125.050191
#> iter  54 value 3125.046095
#> iter  55 value 3125.027673
#> iter  56 value 3125.019620
#> iter  57 value 3125.010732
#> iter  58 value 3125.004768
#> iter  59 value 3124.994646
#> iter  60 value 3124.977179
#> iter  61 value 3124.971050
#> iter  62 value 3124.970752
#> iter  63 value 3124.970456
#> iter  64 value 3124.970284
#> iter  65 value 3124.967405
#> iter  66 value 3124.962586
#> iter  67 value 3124.951464
#> iter  68 value 3124.933795
#> iter  69 value 3124.913394
#> iter  70 value 3124.903398
#> iter  71 value 3124.900836
#> iter  72 value 3124.899494
#> iter  73 value 3124.898157
#> iter  74 value 3124.897315
#> iter  75 value 3124.897008
#> iter  75 value 3124.897008
#> final  value 3124.897008 
#> converged
apply_grolts_criteria(shapes)
#> <gbtm_criteria> PMS>0.05, APPA>0.70, OCC>=5 | 3 shape(s) pass
#>   recommended: degrees 1,2,1,1  (BIC 6337.4, entropy 0.806)
```

**Stage 4 – fit the final model** (Hessian on, so the fit carries
standard errors) and read off the diagnostics and per-subject
assignment. Here we use the lowest-BIC shape found by the search:

``` r

fit <- fit_gbtm(spec, n_groups = groups$best, degrees = shapes$best, method = "L")
#> Starting Values
#> 0.250.250.250.25-50-0.94894612107369700.3856559360520410-50
#> 
#> Likelihood
#> iter   1 value
#> 3889.644459
#> iter   2 value
#> 3889.633166
#> iter   3 value
#> 3889.621873
#> iter   4 value
#> 3889.611566
#> iter   5 value
#> 3889.601259
#> iter   6 value
#> 3889.585806
#> iter   7 value
#> 3889.570354
#> iter   8 value
#> 3889.529110
#> iter   9 value
#> 3889.487860
#> iter  10 value
#> 3889.364081
#> iter  11 value
#> 3889.240255
#> iter  12 value
#> 3888.868502
#> iter  13 value
#> 3888.496340
#> iter  14 value
#> 3887.377489
#> iter  15 value
#> 3886.255226
#> iter  16 value
#> 3882.869980
#> iter  17 value
#> 3879.460927
#> iter  18 value
#> 3869.138026
#> iter  19 value
#> 3858.760801
#> iter  20 value
#> 3828.117032
#> iter  21 value
#> 3724.249269
#> iter  22 value
#> 3565.114446
#> iter  23 value
#> 3394.732506
#> iter  24 value
#> 3374.223409
#> iter  25 value
#> 3343.468288
#> iter  26 value
#> 3317.206729
#> iter  27 value
#> 3289.814141
#> iter  28 value
#> 3261.939178
#> iter  29 value
#> 3238.820300
#> iter  30 value
#> 3217.500601
#> iter  31 value
#> 3191.498945
#> iter  32 value
#> 3169.837040
#> iter  33 value
#> 3159.449205
#> iter  34 value
#> 3159.094689
#> iter  35 value
#> 3157.749998
#> iter  36 value
#> 3157.544648
#> iter  37 value
#> 3156.576941
#> iter  38 value
#> 3155.858946
#> iter  39 value
#> 3154.601574
#> iter  40 value
#> 3153.404186
#> iter  41 value
#> 3151.266831
#> iter  42 value
#> 3150.253175
#> iter  43 value
#> 3149.104823
#> iter  44 value
#> 3148.711778
#> iter  45 value
#> 3148.277875
#> iter  46 value
#> 3147.850841
#> iter  47 value
#> 3147.199950
#> iter  48 value
#> 3146.719191
#> iter  49 value
#> 3146.409820
#> iter  50 value
#> 3146.271854
#> iter  51 value
#> 3146.202364
#> iter  52 value
#> 3146.106805
#> iter  53 value
#> 3146.046217
#> iter  54 value
#> 3145.975919
#> iter  55 value
#> 3145.830833
#> iter  56 value
#> 3145.453512
#> iter  57 value
#> 3144.949926
#> iter  58 value
#> 3144.058806
#> iter  59 value
#> 3142.910821
#> iter  60 value
#> 3141.076606
#> iter  61 value
#> 3138.989705
#> iter  62 value
#> 3137.686072
#> iter  63 value
#> 3137.188369
#> iter  64 value
#> 3135.489476
#> iter  65 value
#> 3134.441937
#> iter  66 value
#> 3133.622302
#> iter  67 value
#> 3133.162596
#> iter  68 value
#> 3133.016805
#> iter  69 value
#> 3132.721168
#> iter  70 value
#> 3132.178075
#> iter  71 value
#> 3132.057055
#> iter  72 value
#> 3131.820937
#> iter  73 value
#> 3131.593142
#> iter  74 value
#> 3131.052244
#> iter  75 value
#> 3130.752941
#> iter  76 value
#> 3130.602331
#> iter  77 value
#> 3130.503452
#> iter  78 value
#> 3130.357993
#> iter  79 value
#> 3130.214988
#> iter  80 value
#> 3129.827575
#> iter  81 value
#> 3129.481143
#> iter  82 value
#> 3128.899682
#> iter  83 value
#> 3128.021866
#> iter  84 value
#> 3127.370953
#> iter  85 value
#> 3126.966123
#> iter  86 value
#> 3126.736058
#> iter  87 value
#> 3126.662038
#> iter  88 value
#> 3126.643400
#> iter  89 value
#> 3126.573558
#> iter  90 value
#> 3126.485352
#> iter  91 value
#> 3126.363930
#> iter  92 value
#> 3126.295243
#> iter  93 value
#> 3126.285866
#> iter  94 value
#> 3126.283706
#> iter  95 value
#> 3126.283372
#> iter  96 value
#> 3126.283252
gbtm_diagnostics(fit)
#> <gbtm_diagnostics> groups=4  n=1500  entropy=0.792
#>   BIC=6333.01  AIC=6274.57  logLik=-3126.28
#>  group n_assigned prop_assigned prop_model mismatch  appa    occ
#>      1        254         0.169      0.112   -0.057 0.663 15.542
#>      2        308         0.205      0.239    0.034 0.924 38.412
#>      3        339         0.226      0.193   -0.033 0.795 16.236
#>      4        599         0.399      0.456    0.057 0.988 97.113
head(gbtm_assign(fit))
#>   id group           p1           p2           p3           p4
#> 1  1     2 2.366581e-20 9.655368e-01 3.969569e-03 0.0304936346
#> 2  2     2 3.613713e-21 9.618273e-01 3.681724e-02 0.0013554262
#> 3  3     2 3.613713e-21 9.618273e-01 3.681724e-02 0.0013554262
#> 4  4     3 6.591062e-17 2.137844e-01 7.860759e-01 0.0001397397
#> 5  5     1 6.135728e-01 4.672433e-05 2.337530e-04 0.3861467377
#> 6  6     4 8.981039e-06 5.612112e-05 2.922847e-06 0.9999319750
```

## Continuous outcomes

The same pipeline handles continuous outcomes: switch the family to
`"gaussian"` (mapped to a censored-normal model) and point the spec at a
continuous dataset. `sim_continuous` has the same four shape types on a
continuous scale.

``` r

data("sim_continuous", package = "gbtmkit")
cspec <- gbtm_spec(
  sim_continuous,
  outcomes = c("y1", "y2", "y3", "y4"),
  time     = c("t1", "t2", "t3", "t4"),
  id       = "id",
  family   = "gaussian"
)
cfit <- fit_gbtm(cspec, n_groups = 4, degrees = rep(1, 4), method = "L")
#> Starting Values
#> 0.250.250.250.2515.5031856751151021.5258653283097026.1406055050237032.163285158218207.241321535574517.241321535574517.241321535574517.24132153557451
#> 
#> Likelihood
#> iter   1 value
#> 15970.102137
#> iter   2 value
#> 15970.101054
#> iter   3 value
#> 15970.099970
#> iter   4 value
#> 15970.097007
#> iter   5 value
#> 15970.094044
#> iter   6 value
#> 15970.085154
#> iter   7 value
#> 15970.076264
#> iter   8 value
#> 15970.049595
#> iter   9 value
#> 15970.022926
#> iter  10 value
#> 15969.942917
#> iter  11 value
#> 15969.862905
#> iter  12 value
#> 15969.622857
#> iter  13 value
#> 15969.382790
#> iter  14 value
#> 15968.662469
#> iter  15 value
#> 15967.941973
#> iter  16 value
#> 15965.779431
#> iter  17 value
#> 15963.615321
#> iter  18 value
#> 15957.113713
#> iter  19 value
#> 15950.598469
#> iter  20 value
#> 15930.974473
#> iter  21 value
#> 15911.240816
#> iter  22 value
#> 15851.481510
#> iter  23 value
#> 15791.103155
#> iter  24 value
#> 15609.039904
#> iter  25 value
#> 15431.190370
#> iter  26 value
#> 14955.099962
#> iter  27 value
#> 14771.901457
#> iter  28 value
#> 14703.226197
#> iter  29 value
#> 14594.377993
#> iter  30 value
#> 14493.432806
#> iter  31 value
#> 14475.251830
#> iter  32 value
#> 14433.318538
#> iter  33 value
#> 14387.111496
#> iter  34 value
#> 14260.791573
#> iter  35 value
#> 13901.200796
#> iter  36 value
#> 13734.753677
#> iter  37 value
#> 13562.860538
#> iter  38 value
#> 13293.417867
#> iter  39 value
#> 12967.500971
#> iter  40 value
#> 12906.725779
#> iter  41 value
#> 12490.871310
#> iter  42 value
#> 12317.496994
#> iter  43 value
#> 12173.546141
#> iter  44 value
#> 12080.016371
#> iter  45 value
#> 12044.537122
#> iter  46 value
#> 12011.225055
#> iter  47 value
#> 11986.095516
#> iter  48 value
#> 11978.004492
#> iter  49 value
#> 11974.243616
#> iter  50 value
#> 11974.022785
#> iter  51 value
#> 11973.920444
#> iter  52 value
#> 11973.544336
#> iter  53 value
#> 11973.238964
#> iter  54 value
#> 11972.952340
#> iter  55 value
#> 11972.321049
#> iter  56 value
#> 11972.004958
#> iter  57 value
#> 11971.879000
#> iter  58 value
#> 11971.818867
#> iter  59 value
#> 11971.779473
#> iter  60 value
#> 11971.754496
#> iter  61 value
#> 11971.744018
#> iter  62 value
#> 11971.739624
#> iter  63 value
#> 11971.736769
#> iter  64 value
#> 11971.735024
#> iter  65 value
#> 11971.734231
#> iter  66 value
#> 11971.733893
#> iter  67 value
#> 11971.733693
#> iter  68 value
#> 11971.733576
#> iter  69 value
#> 11971.733521
#> iter  70 value
#> 11971.733497
#> iter  71 value
#> 11971.733483
#> iter  72 value
#> 11971.733475
#> iter  73 value
#> 11971.733472
#> iter  74 value
#> 11971.733470
#> iter  75 value
#> 11971.733469
#> iter  76 value
#> 11971.733469
#> iter  77 value
#> 11971.733468
#> iter  78 value
#> 11971.733468
#> iter  79 value
#> 11971.733468
#> iter  80 value
#> 11971.733468
#> iter  81 value
#> 11971.733468
#> iter  82 value
#> 11971.733468
#> iter  83 value
#> 11971.733468
#> iter  84 value
#> 11971.733468
#> iter  85 value
#> 11971.733468
#> iter  86 value
#> 11971.733468
#> iter  87 value
#> 11971.733468
#> iter  88 value
#> 11971.733468
#> iter  89 value
#> 11971.733468
#> iter  90 value
#> 11971.733468
#> iter  91 value
#> 11971.733468
#> iter  92 value
#> 11971.733468
gbtm_diagnostics(cfit)$entropy
#> [1] 0.9999981
```

[`plot_trajectories()`](https://fabregithub.github.io/gbtmkit/reference/plot_trajectories.md)
works the same way; for a continuous outcome the fitted lines and the
observed points are on the outcome’s own scale (means, not
probabilities):

``` r

plot_trajectories(cfit)
```

![Fitted continuous group
trajectories](getting-started_files/figure-html/unnamed-chunk-15-1.png)

## Notes

- **Engine-agnostic.** The pipeline talks only to a small set of
  accessors
  ([`gbtm_bic()`](https://fabregithub.github.io/gbtmkit/reference/gbtm_accessors.md),
  [`gbtm_posterior()`](https://fabregithub.github.io/gbtmkit/reference/gbtm_accessors.md),
  [`gbtm_group_sizes()`](https://fabregithub.github.io/gbtmkit/reference/gbtm_accessors.md),
  …), so additional backends can be added without changing the workflow.
- **Built to scale.** The shape search runs the fits with the Hessian
  off (needed only for the final model’s standard errors), defaults to a
  greedy stepwise strategy, and supports a `time_budget`, `max_fits`,
  and on-disk `checkpoint`ing so large problems run unattended and
  bounded. \`\`\`
