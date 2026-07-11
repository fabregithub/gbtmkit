# Run the full group-based trajectory pipeline

Executes algorithm selection (optional), group-number selection,
polynomial shape search with GRoLTS acceptance criteria, and the final
Hessian-on fit, returning all intermediate results in one object.

## Usage

``` r
run_gbtm_pipeline(
  spec,
  engine = gbtm_engines(),
  candidates = 2:6,
  degree = 3L,
  method = NULL,
  algo_n_groups = NULL,
  algo_degree = NULL,
  strategy = c("stepwise", "grid"),
  min_degree = 1L,
  max_degree = 3L,
  max_passes = 2L,
  pms_min = 0.05,
  appa_min = 0.7,
  occ_min = 5,
  itermax = 100L,
  seed = NULL,
  time_budget = Inf,
  max_fits = Inf,
  checkpoint = NULL,
  verbose = TRUE,
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

  Integer vector of group numbers to consider (stage 2).

- degree:

  Polynomial degree used during group-number selection.

- method:

  Estimation method. If `NULL` and the engine offers a choice, stage 1
  selects it; otherwise this method is used throughout.

- algo_n_groups, algo_degree:

  Group count and degree used for stage-1 algorithm selection (defaults:
  `max(candidates)`, `degree`).

- strategy, min_degree, max_degree, max_passes:

  Shape-search controls, passed to
  [`evaluate_shapes()`](https://fabregithub.github.io/gbtmkit/reference/evaluate_shapes.md).

- pms_min, appa_min, occ_min:

  GRoLTS thresholds, passed to
  [`apply_grolts_criteria()`](https://fabregithub.github.io/gbtmkit/reference/apply_grolts_criteria.md).

- itermax, seed:

  Passed to the fitting stages.

- time_budget, max_fits, checkpoint:

  Bounds for the shape search.

- verbose:

  Print progress messages.

- ...:

  Passed to the underlying fitting calls.

## Value

An object of class `gbtm_result` with elements `spec`, `engine`,
`method`, `algorithm_selection`, `group_selection`, `n_groups`,
`shapes`, `criteria`, `chosen_degrees`, `criteria_met`, `final_fit`,
`assignment`, `diagnostics`, and `call`.

## Details

If no shape meets the GRoLTS criteria, the pipeline falls back to the
lowest-BIC shape and records `criteria_met = FALSE`.

## See also

[`select_algorithm()`](https://fabregithub.github.io/gbtmkit/reference/select_algorithm.md),
[`select_n_groups()`](https://fabregithub.github.io/gbtmkit/reference/select_n_groups.md),
[`evaluate_shapes()`](https://fabregithub.github.io/gbtmkit/reference/evaluate_shapes.md),
[`apply_grolts_criteria()`](https://fabregithub.github.io/gbtmkit/reference/apply_grolts_criteria.md),
[`fit_gbtm()`](https://fabregithub.github.io/gbtmkit/reference/fit_gbtm.md)

## Examples

``` r
# \donttest{
data("sim_binary", package = "gbtmkit")
spec <- gbtm_spec(sim_binary, c("y1","y2","y3","y4"),
                  c("t1","t2","t3","t4"), id = "id", family = "binomial")
if (requireNamespace("trajeR", quietly = TRUE)) {
  res <- run_gbtm_pipeline(spec, candidates = 2:5, method = "L")
  res
}
#> Stage 2: selecting number of groups over {2, 3, 4, 5} ...
#> Starting Values
#> 0.50.5-2.169017784616020001.21830955028305000
#> 
#> 
#> Likelihood
#> initial  value 3454.147366 
#> iter   2 value 3369.083013
#> iter   3 value 3368.757462
#> iter   4 value 3293.364056
#> iter   5 value 3286.077870
#> iter   6 value 3279.330124
#> iter   7 value 3261.248932
#> iter   8 value 3245.495221
#> iter   9 value 3177.197705
#> iter  10 value 3166.818701
#> iter  11 value 3164.511488
#> iter  12 value 3164.136503
#> iter  13 value 3164.106505
#> iter  14 value 3164.096379
#> iter  15 value 3164.081382
#> iter  16 value 3164.074809
#> iter  17 value 3164.072784
#> iter  18 value 3164.072104
#> iter  19 value 3164.071533
#> iter  20 value 3164.071290
#> iter  20 value 3164.071290
#> final  value 3164.071290 
#> converged
#> Starting Values
#> 0.3333333333333330.3333333333333330.333333333333333-5000-0.2526690405186940002.40335574023852000
#> 
#> 
#> Likelihood
#> initial  value 3514.077440 
#> iter   2 value 3453.853647
#> iter   3 value 3419.945638
#> iter   4 value 3368.023846
#> iter   5 value 3293.268725
#> iter   6 value 3287.737340
#> iter   7 value 3283.828777
#> iter   8 value 3245.710157
#> iter   9 value 3200.804246
#> iter  10 value 3184.811576
#> iter  11 value 3169.180010
#> iter  12 value 3167.249098
#> iter  13 value 3159.118414
#> iter  14 value 3150.572753
#> iter  15 value 3147.923901
#> iter  16 value 3140.401999
#> iter  17 value 3137.688517
#> iter  18 value 3136.486527
#> iter  19 value 3135.384831
#> iter  20 value 3133.822964
#> iter  21 value 3132.723630
#> iter  22 value 3132.227098
#> iter  23 value 3132.020819
#> iter  24 value 3131.965653
#> iter  25 value 3131.939221
#> iter  26 value 3131.865123
#> iter  27 value 3131.816872
#> iter  28 value 3131.778063
#> iter  29 value 3131.742337
#> iter  30 value 3131.679598
#> iter  31 value 3131.584835
#> iter  32 value 3131.496676
#> iter  33 value 3131.465886
#> iter  34 value 3131.465811
#> iter  34 value 3131.465807
#> iter  34 value 3131.465797
#> final  value 3131.465797 
#> converged
#> Starting Values
#> 0.250.250.250.25-5000-0.9489461210736970000.385655936052041000-5000
#> 
#> 
#> Likelihood
#> initial  value 3889.644459 
#> iter   2 value 3824.719068
#> iter   3 value 3810.437329
#> iter   4 value 3719.130834
#> iter   5 value 3635.464072
#> iter   6 value 3629.521020
#> iter   7 value 3528.563917
#> iter   8 value 3456.694092
#> iter   9 value 3423.221580
#> iter  10 value 3385.333498
#> iter  11 value 3381.547021
#> iter  12 value 3357.686067
#> iter  13 value 3311.655810
#> iter  14 value 3268.766252
#> iter  15 value 3243.634948
#> iter  16 value 3236.722858
#> iter  17 value 3214.215020
#> iter  18 value 3188.964673
#> iter  19 value 3152.629948
#> iter  20 value 3135.610411
#> iter  21 value 3131.233583
#> iter  22 value 3128.784670
#> iter  23 value 3128.235014
#> iter  24 value 3126.963360
#> iter  25 value 3126.063494
#> iter  26 value 3124.720665
#> iter  27 value 3124.222838
#> iter  28 value 3123.725566
#> iter  29 value 3123.669653
#> iter  30 value 3123.359724
#> iter  31 value 3123.290807
#> iter  32 value 3123.241219
#> iter  33 value 3123.227224
#> iter  34 value 3123.208139
#> iter  35 value 3123.193398
#> iter  36 value 3123.178168
#> iter  37 value 3123.169787
#> iter  38 value 3123.164166
#> iter  39 value 3123.157698
#> iter  40 value 3123.147232
#> iter  41 value 3123.129534
#> iter  42 value 3123.104733
#> iter  43 value 3123.077758
#> iter  44 value 3123.076612
#> iter  45 value 3123.076489
#> iter  46 value 3123.076009
#> iter  47 value 3123.072956
#> iter  48 value 3123.071188
#> iter  49 value 3123.065777
#> iter  50 value 3123.064632
#> iter  51 value 3123.064337
#> iter  51 value 3123.064294
#> iter  52 value 3123.064166
#> iter  52 value 3123.064131
#> iter  52 value 3123.064115
#> final  value 3123.064115 
#> converged
#> Starting Values
#> 0.20.20.20.20.2-5000-1.536646406336000-0.2526690405186940000.834520970396894000-5000
#> 
#> 
#> Likelihood
#> initial  value 3710.037469 
#> iter   2 value 3662.769210
#> iter   3 value 3636.332503
#> iter   4 value 3621.437701
#> iter   5 value 3560.928651
#> iter   6 value 3543.357028
#> iter   7 value 3509.672100
#> iter   8 value 3509.019598
#> iter   9 value 3456.118043
#> iter  10 value 3397.172132
#> iter  11 value 3342.542660
#> iter  12 value 3333.370633
#> iter  13 value 3279.879744
#> iter  14 value 3244.322534
#> iter  15 value 3237.832244
#> iter  16 value 3222.349065
#> iter  17 value 3208.366117
#> iter  18 value 3185.921760
#> iter  19 value 3183.464196
#> iter  20 value 3172.553139
#> iter  21 value 3168.733610
#> iter  22 value 3156.802251
#> iter  23 value 3150.793023
#> iter  24 value 3145.753113
#> iter  25 value 3141.520213
#> iter  26 value 3136.902186
#> iter  27 value 3133.615473
#> iter  28 value 3131.958018
#> iter  29 value 3130.850785
#> iter  30 value 3129.120847
#> iter  31 value 3127.763366
#> iter  32 value 3127.236459
#> iter  33 value 3126.864164
#> iter  34 value 3126.570323
#> iter  35 value 3126.367699
#> iter  36 value 3126.038838
#> iter  37 value 3125.805077
#> iter  38 value 3125.571691
#> iter  39 value 3125.461785
#> iter  40 value 3125.320208
#> iter  41 value 3125.132105
#> iter  42 value 3124.951714
#> iter  43 value 3124.884760
#> iter  44 value 3124.847665
#> iter  45 value 3124.834169
#> iter  46 value 3124.786322
#> iter  47 value 3124.762901
#> iter  48 value 3124.739819
#> iter  49 value 3124.717407
#> iter  50 value 3124.660703
#> iter  51 value 3124.566702
#> iter  52 value 3124.400093
#> iter  53 value 3124.295703
#> iter  54 value 3124.135412
#> iter  55 value 3124.122621
#> iter  56 value 3124.115647
#> iter  57 value 3124.050770
#> iter  58 value 3124.034750
#> iter  59 value 3124.020167
#> iter  60 value 3124.005858
#> iter  61 value 3123.942869
#> iter  62 value 3123.907365
#> iter  63 value 3123.730286
#> iter  64 value 3123.673201
#> iter  65 value 3123.575186
#> iter  66 value 3123.528652
#> iter  67 value 3123.277631
#> iter  68 value 3123.225366
#> iter  69 value 3123.160932
#> iter  70 value 3123.123943
#> iter  71 value 3123.052299
#> iter  72 value 3123.017457
#> iter  73 value 3122.975753
#> iter  74 value 3122.964984
#> iter  75 value 3122.945795
#> iter  76 value 3122.935044
#> iter  77 value 3122.924019
#> iter  78 value 3122.917387
#> iter  79 value 3122.914847
#> iter  80 value 3122.913954
#> iter  81 value 3122.913797
#> iter  81 value 3122.913767
#> iter  81 value 3122.913767
#> final  value 3122.913767 
#> converged
#> Stage 3: searching shapes for ng = 3 ...
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
#> 0.3333333333333330.3333333333333330.333333333333333-500-0.25266904051869402.403355740238520
#> 
#> 
#> Likelihood
#> initial  value 3514.077440 
#> iter   2 value 3416.428267
#> iter   3 value 3406.140996
#> iter   4 value 3341.039967
#> iter   5 value 3304.208625
#> iter   6 value 3279.655793
#> iter   7 value 3247.733917
#> iter   8 value 3201.704386
#> iter   9 value 3197.794122
#> iter  10 value 3180.206354
#> iter  11 value 3163.996828
#> iter  12 value 3152.809731
#> iter  13 value 3152.298005
#> iter  14 value 3149.605288
#> iter  15 value 3149.364240
#> iter  16 value 3149.175155
#> iter  17 value 3148.932398
#> iter  18 value 3148.716368
#> iter  19 value 3148.577464
#> iter  20 value 3148.518579
#> iter  21 value 3148.517224
#> iter  22 value 3148.515166
#> iter  23 value 3148.509656
#> iter  24 value 3148.492075
#> iter  25 value 3148.478973
#> iter  26 value 3148.401834
#> iter  27 value 3148.349609
#> iter  28 value 3148.317752
#> iter  29 value 3148.313911
#> iter  30 value 3148.305993
#> iter  31 value 3148.296995
#> iter  32 value 3148.296817
#> iter  32 value 3148.296805
#> iter  32 value 3148.296805
#> final  value 3148.296805 
#> converged
#> Starting Values
#> 0.3333333333333330.3333333333333330.333333333333333-5000-0.25266904051869402.403355740238520
#> 
#> 
#> Likelihood
#> initial  value 3514.077440 
#> iter   2 value 3364.569054
#> iter   3 value 3358.812253
#> iter   4 value 3318.785224
#> iter   5 value 3252.345909
#> iter   6 value 3229.033357
#> iter   7 value 3214.558534
#> iter   8 value 3205.128386
#> iter   9 value 3203.869546
#> iter  10 value 3196.707096
#> iter  11 value 3177.311442
#> iter  12 value 3162.962590
#> iter  13 value 3157.588660
#> iter  14 value 3153.783245
#> iter  15 value 3153.111932
#> iter  16 value 3152.721156
#> iter  17 value 3152.232371
#> iter  18 value 3150.841278
#> iter  19 value 3149.964528
#> iter  20 value 3149.327895
#> iter  21 value 3148.579433
#> iter  22 value 3148.370196
#> iter  23 value 3148.348666
#> iter  24 value 3148.344655
#> iter  25 value 3148.326262
#> iter  26 value 3148.324478
#> iter  27 value 3148.323587
#> iter  28 value 3148.322482
#> iter  29 value 3148.322325
#> iter  30 value 3148.319150
#> iter  31 value 3148.318757
#> iter  32 value 3148.315579
#> iter  33 value 3148.313675
#> iter  34 value 3148.308187
#> iter  35 value 3148.307906
#> iter  36 value 3148.307833
#> iter  37 value 3148.307771
#> iter  38 value 3148.307474
#> iter  39 value 3148.306846
#> iter  40 value 3148.305195
#> iter  41 value 3148.301648
#> iter  42 value 3148.294904
#> iter  43 value 3148.284800
#> iter  44 value 3148.275454
#> iter  45 value 3148.275349
#> iter  46 value 3148.275254
#> iter  47 value 3148.275082
#> iter  48 value 3148.275021
#> iter  49 value 3148.274621
#> iter  49 value 3148.274618
#> iter  49 value 3148.274597
#> final  value 3148.274597 
#> converged
#> ~18 shapes planned, est. 225 s remaining (15.01 s/fit).
#> Starting Values
#> 0.3333333333333330.3333333333333330.333333333333333-50-0.252669040518694002.403355740238520
#> 
#> 
#> Likelihood
#> initial  value 3514.077440 
#> iter   2 value 3509.251528
#> iter   3 value 3446.039519
#> iter   4 value 3367.196789
#> iter   5 value 3322.026056
#> iter   6 value 3281.581191
#> iter   7 value 3258.845011
#> iter   8 value 3237.791080
#> iter   9 value 3178.580015
#> iter  10 value 3171.439647
#> iter  11 value 3168.510423
#> iter  12 value 3162.408254
#> iter  13 value 3161.648664
#> iter  14 value 3158.097318
#> iter  15 value 3157.360326
#> iter  16 value 3155.936875
#> iter  17 value 3155.093652
#> iter  18 value 3154.639249
#> iter  19 value 3153.112367
#> iter  20 value 3151.329902
#> iter  21 value 3151.071131
#> iter  22 value 3150.994352
#> iter  23 value 3150.778558
#> iter  24 value 3150.325865
#> iter  25 value 3150.202983
#> iter  26 value 3149.619700
#> iter  27 value 3149.374537
#> iter  28 value 3149.213252
#> iter  29 value 3148.948635
#> iter  30 value 3148.744977
#> iter  31 value 3148.618339
#> iter  32 value 3148.468045
#> iter  33 value 3148.416164
#> iter  34 value 3148.371024
#> iter  35 value 3148.350212
#> iter  36 value 3148.305661
#> iter  37 value 3148.297841
#> iter  38 value 3148.296686
#> iter  38 value 3148.296657
#> iter  38 value 3148.296657
#> final  value 3148.296657 
#> converged
#> Starting Values
#> 0.3333333333333330.3333333333333330.333333333333333-50-0.2526690405186940002.403355740238520
#> 
#> 
#> Likelihood
#> initial  value 3514.077440 
#> iter   2 value 3510.119929
#> iter   3 value 3445.620896
#> iter   4 value 3408.377800
#> iter   5 value 3362.467807
#> iter   6 value 3340.800019
#> iter   7 value 3330.593805
#> iter   8 value 3313.159828
#> iter   9 value 3264.376197
#> iter  10 value 3221.677262
#> iter  11 value 3214.313592
#> iter  12 value 3196.699867
#> iter  13 value 3173.180151
#> iter  14 value 3168.554803
#> iter  15 value 3167.327488
#> iter  16 value 3166.804677
#> iter  17 value 3166.370014
#> iter  18 value 3165.986812
#> iter  19 value 3165.250365
#> iter  20 value 3164.124443
#> iter  21 value 3162.769414
#> iter  22 value 3162.473445
#> iter  23 value 3161.109431
#> iter  24 value 3160.380263
#> iter  25 value 3159.601411
#> iter  26 value 3157.116065
#> iter  27 value 3156.425093
#> iter  28 value 3152.967556
#> iter  29 value 3152.520980
#> iter  30 value 3151.316659
#> iter  31 value 3150.510142
#> iter  32 value 3149.650802
#> iter  33 value 3149.316965
#> iter  34 value 3148.923175
#> iter  35 value 3148.779693
#> iter  36 value 3148.648931
#> iter  37 value 3148.624092
#> iter  38 value 3148.612981
#> iter  39 value 3148.611408
#> iter  40 value 3148.608044
#> iter  41 value 3148.604942
#> iter  42 value 3148.600225
#> iter  43 value 3148.596299
#> iter  43 value 3148.596288
#> final  value 3148.596288 
#> converged
#> Starting Values
#> 0.3333333333333330.3333333333333330.333333333333333-50-0.25266904051869402.4033557402385200
#> 
#> 
#> Likelihood
#> initial  value 3514.077440 
#> iter   2 value 3441.996473
#> iter   3 value 3417.899863
#> iter   4 value 3380.454965
#> iter   5 value 3303.381955
#> iter   6 value 3285.286819
#> iter   7 value 3274.434343
#> iter   8 value 3250.117971
#> iter   9 value 3243.612228
#> iter  10 value 3206.028785
#> iter  11 value 3188.262277
#> iter  12 value 3177.072001
#> iter  13 value 3163.354927
#> iter  14 value 3159.206213
#> iter  15 value 3154.799785
#> iter  16 value 3150.091673
#> iter  17 value 3148.066130
#> iter  18 value 3147.309424
#> iter  19 value 3147.187386
#> iter  20 value 3147.128542
#> iter  21 value 3147.121985
#> iter  22 value 3147.093990
#> iter  23 value 3147.085288
#> iter  24 value 3147.069479
#> iter  25 value 3147.065538
#> iter  26 value 3147.058591
#> iter  27 value 3147.030531
#> iter  28 value 3146.958565
#> iter  29 value 3146.916810
#> iter  30 value 3146.852973
#> iter  31 value 3146.827514
#> iter  32 value 3146.816450
#> iter  33 value 3146.811231
#> iter  34 value 3146.808704
#> iter  35 value 3146.808297
#> iter  36 value 3146.808235
#> iter  36 value 3146.808231
#> iter  36 value 3146.808231
#> final  value 3146.808231 
#> converged
#> Starting Values
#> 0.3333333333333330.3333333333333330.333333333333333-50-0.25266904051869402.40335574023852000
#> 
#> 
#> Likelihood
#> initial  value 3514.077440 
#> iter   2 value 3455.900606
#> iter   3 value 3411.494168
#> iter   4 value 3358.380125
#> iter   5 value 3355.108444
#> iter   6 value 3354.240809
#> iter   7 value 3339.782760
#> iter   8 value 3314.945975
#> iter   9 value 3309.154446
#> iter  10 value 3229.493398
#> iter  11 value 3208.517196
#> iter  12 value 3182.809944
#> iter  13 value 3173.130071
#> iter  14 value 3170.353225
#> iter  15 value 3169.003393
#> iter  16 value 3167.180176
#> iter  17 value 3166.651705
#> iter  18 value 3166.559033
#> iter  19 value 3166.480200
#> iter  20 value 3166.445920
#> iter  21 value 3166.421039
#> iter  22 value 3166.334405
#> iter  23 value 3166.333266
#> iter  24 value 3166.320904
#> iter  25 value 3166.313148
#> iter  26 value 3166.300380
#> iter  27 value 3166.293279
#> iter  28 value 3166.160324
#> iter  29 value 3166.082267
#> iter  30 value 3166.064475
#> iter  31 value 3165.934135
#> iter  32 value 3165.891883
#> iter  33 value 3165.871891
#> iter  34 value 3165.860569
#> iter  35 value 3165.857738
#> iter  36 value 3165.851115
#> iter  37 value 3165.849352
#> iter  38 value 3165.842964
#> iter  39 value 3165.838365
#> iter  40 value 3165.830717
#> iter  41 value 3165.823511
#> iter  42 value 3165.815725
#> iter  43 value 3165.808794
#> iter  43 value 3165.808788
#> final  value 3165.808788 
#> converged
#> evaluated 7 shapes in 114 s.
#> Stage 4: fitting final model (degrees 1,1,1, Hessian on) ...
#> Starting Values
#> 0.3333333333333330.3333333333333330.333333333333333-50-0.25266904051869402.403355740238520
#> 
#> 
#> Likelihood
#> iter   1 value 
#> 3514.077440
#> iter   2 value 
#> 3514.074231
#> iter   3 value 
#> 3514.071022
#> iter   4 value 
#> 3514.063431
#> iter   5 value 
#> 3514.055840
#> iter   6 value 
#> 3514.036988
#> iter   7 value 
#> 3514.018135
#> iter   8 value 
#> 3513.961570
#> iter   9 value 
#> 3513.904994
#> iter  10 value 
#> 3513.735211
#> iter  11 value 
#> 3513.565343
#> iter  12 value 
#> 3513.055233
#> iter  13 value 
#> 3512.544383
#> iter  14 value 
#> 3511.007617
#> iter  15 value 
#> 3509.464992
#> iter  16 value 
#> 3504.808203
#> iter  17 value 
#> 3500.121678
#> iter  18 value 
#> 3486.072715
#> iter  19 value 
#> 3449.189281
#> iter  20 value 
#> 3371.528198
#> iter  21 value 
#> 3354.835931
#> iter  22 value 
#> 3338.148695
#> iter  23 value 
#> 3322.381515
#> iter  24 value 
#> 3309.418410
#> iter  25 value 
#> 3293.805411
#> iter  26 value 
#> 3268.142820
#> iter  27 value 
#> 3254.887862
#> iter  28 value 
#> 3211.801731
#> iter  29 value 
#> 3202.677888
#> iter  30 value 
#> 3186.983751
#> iter  31 value 
#> 3172.188685
#> iter  32 value 
#> 3161.344031
#> iter  33 value 
#> 3157.273296
#> iter  34 value 
#> 3154.194838
#> iter  35 value 
#> 3152.820449
#> iter  36 value 
#> 3151.588114
#> iter  37 value 
#> 3151.030545
#> iter  38 value 
#> 3150.763060
#> iter  39 value 
#> 3150.669395
#> iter  40 value 
#> 3150.631278
#> iter  41 value 
#> 3150.615042
#> iter  42 value 
#> 3150.576997
#> iter  43 value 
#> 3150.521453
#> iter  44 value 
#> 3150.458991
#> iter  45 value 
#> 3150.427720
#> iter  46 value 
#> 3150.422607
#> iter  47 value 
#> 3150.422286
#> iter  48 value 
#> 3150.422080
#> iter  49 value 
#> 3150.421445
#> iter  50 value 
#> 3150.419874
#> iter  51 value 
#> 3150.415333
#> iter  52 value 
#> 3150.399725
#> iter  53 value 
#> 3150.302336
#> iter  54 value 
#> 3150.172700
#> iter  55 value 
#> 3150.166069
#> iter  56 value 
#> 3149.946910
#> iter  57 value 
#> 3149.748914
#> iter  58 value 
#> 3149.740011
#> iter  59 value 
#> 3149.738572
#> iter  60 value 
#> 3149.737832
#> iter  61 value 
#> 3149.735824
#> iter  62 value 
#> 3149.731217
#> iter  63 value 
#> 3149.728849
#> iter  64 value 
#> 3149.728448
#> iter  65 value 
#> 3149.728444
#> iter  66 value 
#> 3149.728444
#> iter  67 value 
#> 3149.728444
#> iter  68 value 
#> 3149.728444
#> iter  69 value 
#> 3149.728444
#> iter  70 value 
#> 3149.728444
#> iter  71 value 
#> 3149.728444
#> <gbtm_result>
#>   engine/family : trajeR / binomial
#>   method        : L
#>   groups        : 3
#>   degrees       : 1, 1, 1
#>   GRoLTS criteria met: TRUE
#>   entropy       : 0.782  BIC: 6358.0
# }
```
