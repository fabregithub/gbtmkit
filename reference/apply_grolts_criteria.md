# Apply GRoLTS acceptance criteria to a shape table

Keeps the candidate shapes whose worst group satisfies all of the GRoLTS
adequacy thresholds and orders the survivors by the chosen criterion.
The recommended model is the top row.

## Usage

``` r
apply_grolts_criteria(
  shapes,
  pms_min = 0.05,
  appa_min = 0.7,
  occ_min = 5,
  order_by = "bic"
)
```

## Arguments

- shapes:

  A `gbtm_shapes` object or its `$table` data frame (from
  [`evaluate_shapes()`](https://fabregithub.github.io/gbtmkit/reference/evaluate_shapes.md)).

- pms_min:

  Minimum smallest-group assigned proportion (default `0.05`).

- appa_min:

  Minimum average posterior probability of assignment (default `0.70`).

- occ_min:

  Minimum odds of correct classification (default `5`).

- order_by:

  Column to sort survivors by, ascending (default `"bic"`).

## Value

A data frame of surviving shapes ordered by `order_by`, carrying an
attribute `"recommended"` (its first row, or `NULL` if none qualify) and
`"thresholds"`. Class `gbtm_criteria`.

## Examples

``` r
# \donttest{
data("sim_binary", package = "gbtmkit")
spec <- gbtm_spec(sim_binary, c("y1","y2","y3","y4"),
                  c("t1","t2","t3","t4"), id = "id", family = "binomial")
if (requireNamespace("trajeR", quietly = TRUE)) {
  sh <- evaluate_shapes(spec, n_groups = 4, method = "L", verbose = FALSE)
  apply_grolts_criteria(sh)
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
#> Starting Values
#> 0.250.250.250.25-500-0.94894612107369700.3856559360520410-50
#> 
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
#> 0.250.250.250.25-5000-0.94894612107369700.3856559360520410-50
#> 
#> 
#> Likelihood
#> initial  value 3889.644459 
#> iter   2 value 3570.547529
#> iter   3 value 3541.791468
#> iter   4 value 3497.627566
#> iter   5 value 3486.442792
#> iter   6 value 3453.135139
#> iter   7 value 3319.762316
#> iter   8 value 3244.331796
#> iter   9 value 3232.821045
#> iter  10 value 3213.847963
#> iter  11 value 3193.529748
#> iter  12 value 3187.310550
#> iter  13 value 3176.695560
#> iter  14 value 3163.914863
#> iter  15 value 3160.618868
#> iter  16 value 3157.940390
#> iter  17 value 3156.355328
#> iter  18 value 3154.764585
#> iter  19 value 3153.328694
#> iter  20 value 3152.219419
#> iter  21 value 3151.126053
#> iter  22 value 3149.879765
#> iter  23 value 3149.623310
#> iter  24 value 3149.428513
#> iter  25 value 3149.186339
#> iter  26 value 3148.845906
#> iter  27 value 3148.499734
#> iter  28 value 3148.302638
#> iter  29 value 3148.296957
#> iter  30 value 3148.283639
#> iter  31 value 3148.185901
#> iter  32 value 3148.144830
#> iter  33 value 3147.999423
#> iter  34 value 3147.976128
#> iter  35 value 3147.587584
#> iter  36 value 3147.217075
#> iter  37 value 3147.010491
#> iter  38 value 3144.983572
#> iter  39 value 3143.594947
#> iter  40 value 3142.949244
#> iter  41 value 3138.418235
#> iter  42 value 3135.801237
#> iter  43 value 3132.757124
#> iter  44 value 3130.560585
#> iter  45 value 3129.797669
#> iter  46 value 3129.166356
#> iter  47 value 3129.004516
#> iter  48 value 3128.760094
#> iter  49 value 3128.670908
#> iter  50 value 3128.603777
#> iter  51 value 3128.556219
#> iter  52 value 3128.396485
#> iter  53 value 3127.965717
#> iter  54 value 3127.930728
#> iter  55 value 3127.539617
#> iter  56 value 3127.523168
#> iter  57 value 3127.293807
#> iter  58 value 3127.279239
#> iter  59 value 3127.274313
#> iter  60 value 3127.274250
#> iter  61 value 3127.245394
#> iter  62 value 3127.230926
#> iter  63 value 3127.219832
#> iter  64 value 3127.213218
#> iter  65 value 3126.184696
#> iter  66 value 3125.748570
#> iter  67 value 3125.433821
#> iter  68 value 3125.277158
#> iter  69 value 3125.055683
#> iter  70 value 3124.982005
#> iter  71 value 3124.945053
#> iter  72 value 3124.921887
#> iter  73 value 3124.910446
#> iter  74 value 3124.906260
#> iter  75 value 3124.905646
#> iter  76 value 3124.905549
#> iter  76 value 3124.905527
#> iter  76 value 3124.905527
#> final  value 3124.905527 
#> converged
#> Starting Values
#> 0.250.250.250.25-50-0.948946121073697000.3856559360520410-50
#> 
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
#> 0.250.250.250.25-50-0.9489461210736970000.3856559360520410-50
#> 
#> 
#> Likelihood
#> initial  value 3889.644459 
#> iter   2 value 3883.292290
#> iter   3 value 3728.091493
#> iter   4 value 3584.722575
#> iter   5 value 3497.991195
#> iter   6 value 3364.026647
#> iter   7 value 3309.502322
#> iter   8 value 3303.286553
#> iter   9 value 3266.184248
#> iter  10 value 3224.505646
#> iter  11 value 3180.201830
#> iter  12 value 3167.193973
#> iter  13 value 3160.873614
#> iter  14 value 3154.564016
#> iter  15 value 3149.682203
#> iter  16 value 3146.422796
#> iter  17 value 3144.672201
#> iter  18 value 3143.896083
#> iter  19 value 3142.381526
#> iter  20 value 3141.500269
#> iter  21 value 3140.229265
#> iter  22 value 3139.567175
#> iter  23 value 3139.320805
#> iter  24 value 3138.936694
#> iter  25 value 3138.751181
#> iter  26 value 3138.493163
#> iter  27 value 3138.251916
#> iter  28 value 3137.886698
#> iter  29 value 3137.660695
#> iter  30 value 3136.695032
#> iter  31 value 3136.379799
#> iter  32 value 3135.895390
#> iter  33 value 3134.419052
#> iter  34 value 3133.698103
#> iter  35 value 3132.057789
#> iter  36 value 3131.698827
#> iter  37 value 3131.446256
#> iter  38 value 3131.287664
#> iter  39 value 3130.856372
#> iter  40 value 3130.390703
#> iter  41 value 3130.288852
#> iter  42 value 3130.239152
#> iter  43 value 3130.183650
#> iter  44 value 3130.171847
#> iter  45 value 3130.005740
#> iter  46 value 3130.004922
#> iter  47 value 3129.978793
#> iter  48 value 3129.972341
#> iter  49 value 3129.970025
#> iter  50 value 3129.954781
#> iter  51 value 3129.952800
#> iter  52 value 3129.950346
#> iter  53 value 3129.923731
#> iter  54 value 3129.864946
#> iter  55 value 3129.689231
#> iter  56 value 3129.060939
#> iter  57 value 3129.009643
#> iter  58 value 3128.534465
#> iter  59 value 3128.117690
#> iter  60 value 3127.159767
#> iter  61 value 3125.714758
#> iter  62 value 3125.316803
#> iter  63 value 3125.127594
#> iter  64 value 3125.007761
#> iter  65 value 3124.968046
#> iter  66 value 3124.950103
#> iter  67 value 3124.944822
#> iter  68 value 3124.941834
#> iter  69 value 3124.940566
#> iter  70 value 3124.939755
#> iter  71 value 3124.938102
#> iter  72 value 3124.934657
#> iter  73 value 3124.934571
#> iter  74 value 3124.934473
#> iter  75 value 3124.934264
#> iter  75 value 3124.934220
#> iter  75 value 3124.934183
#> final  value 3124.934183 
#> converged
#> Starting Values
#> 0.250.250.250.25-50-0.94894612107369700.38565593605204100-50
#> 
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
#> 0.250.250.250.25-50-0.94894612107369700.385655936052041000-50
#> 
#> 
#> Likelihood
#> initial  value 3889.644459 
#> iter   2 value 3879.314077
#> iter   3 value 3783.519296
#> iter   4 value 3573.371065
#> iter   5 value 3532.460267
#> iter   6 value 3366.035835
#> iter   7 value 3364.657255
#> iter   8 value 3322.118702
#> iter   9 value 3298.177248
#> iter  10 value 3219.570387
#> iter  11 value 3179.411893
#> iter  12 value 3177.456920
#> iter  13 value 3173.613702
#> iter  14 value 3171.986473
#> iter  15 value 3162.834773
#> iter  16 value 3143.823020
#> iter  17 value 3139.999076
#> iter  18 value 3137.879038
#> iter  19 value 3136.228246
#> iter  20 value 3135.428895
#> iter  21 value 3134.802601
#> iter  22 value 3134.286850
#> iter  23 value 3134.019843
#> iter  24 value 3133.733696
#> iter  25 value 3133.601155
#> iter  26 value 3133.338239
#> iter  27 value 3133.102299
#> iter  28 value 3132.793082
#> iter  29 value 3132.631733
#> iter  30 value 3132.458751
#> iter  31 value 3132.335585
#> iter  32 value 3132.277338
#> iter  33 value 3132.179083
#> iter  34 value 3132.147526
#> iter  35 value 3132.128589
#> iter  36 value 3132.128136
#> iter  37 value 3132.127185
#> iter  38 value 3132.123259
#> iter  39 value 3132.120961
#> iter  40 value 3132.118170
#> iter  41 value 3132.113894
#> iter  42 value 3132.088854
#> iter  43 value 3132.075239
#> iter  44 value 3131.973817
#> iter  45 value 3131.908466
#> iter  46 value 3131.871120
#> iter  47 value 3131.842348
#> iter  48 value 3131.820458
#> iter  49 value 3131.808098
#> iter  50 value 3131.801287
#> iter  51 value 3131.797558
#> iter  52 value 3131.795580
#> iter  53 value 3131.794586
#> iter  54 value 3131.794072
#> iter  55 value 3131.793814
#> iter  56 value 3131.793683
#> iter  57 value 3131.793617
#> iter  57 value 3131.793583
#> iter  57 value 3131.793583
#> final  value 3131.793583 
#> converged
#> Starting Values
#> 0.250.250.250.25-50-0.94894612107369700.3856559360520410-500
#> 
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
#> 0.250.250.250.25-50-0.94894612107369700.3856559360520410-5000
#> 
#> 
#> Likelihood
#> initial  value 3889.644459 
#> iter   2 value 3561.074195
#> iter   3 value 3531.153302
#> iter   4 value 3449.021134
#> iter   5 value 3400.849808
#> iter   6 value 3262.396439
#> iter   7 value 3245.192979
#> iter   8 value 3237.684675
#> iter   9 value 3234.999477
#> iter  10 value 3205.401290
#> iter  11 value 3204.802995
#> iter  12 value 3195.446339
#> iter  13 value 3178.637428
#> iter  14 value 3169.518024
#> iter  15 value 3154.999433
#> iter  16 value 3154.842141
#> iter  17 value 3154.457087
#> iter  18 value 3153.186092
#> iter  19 value 3151.231208
#> iter  20 value 3150.142943
#> iter  21 value 3149.320153
#> iter  22 value 3148.740972
#> iter  23 value 3148.696300
#> iter  24 value 3148.671574
#> iter  25 value 3148.589205
#> iter  26 value 3148.518325
#> iter  27 value 3148.414559
#> iter  28 value 3148.385343
#> iter  29 value 3148.378934
#> iter  30 value 3148.377458
#> iter  31 value 3148.377028
#> iter  32 value 3148.376292
#> iter  33 value 3148.370598
#> iter  34 value 3148.368398
#> iter  35 value 3148.366075
#> iter  36 value 3148.364940
#> iter  37 value 3148.363103
#> iter  37 value 3148.363102
#> final  value 3148.363102 
#> converged
#> <gbtm_criteria> PMS>0.05, APPA>0.70, OCC>=5 | 5 shape(s) pass
#>   recommended: degrees 1,2,1,1  (BIC 6337.4, entropy 0.806)
# }
```
