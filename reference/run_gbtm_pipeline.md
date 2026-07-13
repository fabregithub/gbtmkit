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
spec <- gbtm_spec(sim_binary, paste0("y", 1:10),
                  paste0("t", 1:10), id = "id", family = "binomial")
if (requireNamespace("trajeR", quietly = TRUE)) {
  res <- run_gbtm_pipeline(spec, candidates = 2:5, method = "L")
  res
}
#> Stage 2: selecting number of groups over {2, 3, 4, 5} ...
#> Starting Values
#> 0.50.5-1.352186144057930001.97070489962395000
#> 
#> 
#> Likelihood
#> initial  value 11144.862797 
#> iter   2 value 8783.321420
#> iter   3 value 8783.248063
#> iter   4 value 8749.588699
#> iter   5 value 8748.937795
#> iter   6 value 8726.649046
#> iter   7 value 8724.183615
#> iter   8 value 8717.618012
#> iter   9 value 8713.212993
#> iter  10 value 8686.201989
#> iter  11 value 8686.133419
#> iter  12 value 8685.877893
#> iter  13 value 8685.857798
#> iter  13 value 8685.857755
#> iter  13 value 8685.857754
#> final  value 8685.857754 
#> converged
#> Starting Values
#> 0.3333333333333330.3333333333333330.333333333333333-2.759537960690260000.166785556197535000-5000
#> 
#> 
#> Likelihood
#> initial  value 11486.525318 
#> iter   2 value 11342.193112
#> iter   3 value 10796.938537
#> iter   4 value 10490.126060
#> iter   5 value 10339.771142
#> iter   6 value 9918.011218
#> iter   7 value 9870.338312
#> iter   8 value 9677.206813
#> iter   9 value 9667.428624
#> iter  10 value 9623.856490
#> iter  11 value 9518.370881
#> iter  12 value 9496.692720
#> iter  13 value 9329.487860
#> iter  14 value 9286.914722
#> iter  15 value 9149.756987
#> iter  16 value 9149.489901
#> iter  17 value 8970.328812
#> iter  18 value 8919.516175
#> iter  19 value 8895.641704
#> iter  20 value 8875.228296
#> iter  21 value 8866.227640
#> iter  22 value 8848.049445
#> iter  23 value 8805.933069
#> iter  24 value 8754.348530
#> iter  25 value 8740.688015
#> iter  26 value 8696.479368
#> iter  27 value 8690.757879
#> iter  28 value 8686.165684
#> iter  29 value 8685.906228
#> iter  30 value 8685.868984
#> iter  31 value 8685.847910
#> iter  32 value 8685.823293
#> iter  33 value 8685.791981
#> iter  34 value 8685.728608
#> iter  35 value 8685.509273
#> iter  36 value 8685.503847
#> iter  37 value 8685.503693
#> iter  38 value 8685.502548
#> iter  38 value 8685.502517
#> iter  38 value 8685.502446
#> final  value 8685.502446 
#> converged
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
#> Starting Values
#> 0.20.20.20.20.2-5000-0.9429734252739980000.1667855561975350001.40451822596028000-5000
#> 
#> 
#> Likelihood
#> initial  value 10812.940044 
#> iter   2 value 10023.569034
#> iter   3 value 10002.207236
#> iter   4 value 9992.916638
#> iter   5 value 9473.807763
#> iter   6 value 9320.937935
#> iter   7 value 9264.142816
#> iter   8 value 9258.734820
#> iter   9 value 9157.046271
#> iter  10 value 9134.635693
#> iter  11 value 9007.669394
#> iter  12 value 8823.429599
#> iter  13 value 8748.374684
#> iter  14 value 8722.907408
#> iter  15 value 8704.962399
#> iter  16 value 8691.561148
#> iter  17 value 8687.854503
#> iter  18 value 8653.686131
#> iter  19 value 8647.292450
#> iter  20 value 8645.211670
#> iter  21 value 8624.314695
#> iter  22 value 8619.637497
#> iter  23 value 8604.640818
#> iter  24 value 8600.269964
#> iter  25 value 8590.163485
#> iter  26 value 8579.874779
#> iter  27 value 8564.623712
#> iter  28 value 8553.076609
#> iter  29 value 8550.004623
#> iter  30 value 8539.930902
#> iter  31 value 8526.062607
#> iter  32 value 8521.804416
#> iter  33 value 8515.352807
#> iter  34 value 8507.298600
#> iter  35 value 8504.117853
#> iter  36 value 8503.968324
#> iter  37 value 8502.719743
#> iter  38 value 8501.109723
#> iter  39 value 8500.776755
#> iter  40 value 8500.226131
#> iter  41 value 8499.966356
#> iter  42 value 8499.859086
#> iter  43 value 8499.780903
#> iter  44 value 8499.690374
#> iter  45 value 8499.558520
#> iter  46 value 8499.520809
#> iter  47 value 8499.503853
#> iter  48 value 8499.492348
#> iter  49 value 8499.481478
#> iter  50 value 8499.474375
#> iter  51 value 8499.473972
#> iter  51 value 8499.473920
#> iter  51 value 8499.473912
#> final  value 8499.473912 
#> converged
#> Stage 3: searching shapes for ng = 4 ...
#> Starting Values
#> 0.250.250.250.25-50-0.47756445827387600.8490727400115340-50
#> 
#> 
#> Likelihood
#> initial  value 10985.536114 
#> iter   2 value 10858.137188
#> iter   3 value 9950.868337
#> iter   4 value 9604.010268
#> iter   5 value 9523.410887
#> iter   6 value 9424.342436
#> iter   7 value 9352.321409
#> iter   8 value 9286.441113
#> iter   9 value 9210.792735
#> iter  10 value 9175.171325
#> iter  11 value 9140.418239
#> iter  12 value 8942.384509
#> iter  13 value 8890.026663
#> iter  14 value 8856.759064
#> iter  15 value 8827.460274
#> iter  16 value 8807.414078
#> iter  17 value 8801.288694
#> iter  18 value 8792.357282
#> iter  19 value 8788.725740
#> iter  20 value 8787.870797
#> iter  21 value 8786.613241
#> iter  22 value 8785.812000
#> iter  23 value 8785.542198
#> iter  24 value 8785.498141
#> iter  25 value 8785.497116
#> iter  26 value 8785.496879
#> iter  27 value 8785.496464
#> iter  28 value 8785.466852
#> iter  29 value 8785.454730
#> iter  30 value 8785.401997
#> iter  31 value 8785.337041
#> iter  32 value 8785.325229
#> iter  33 value 8785.187009
#> iter  34 value 8785.146106
#> iter  35 value 8785.082182
#> iter  36 value 8785.025301
#> iter  37 value 8784.991490
#> iter  38 value 8784.876299
#> iter  39 value 8784.686230
#> iter  40 value 8784.482840
#> iter  41 value 8784.378795
#> iter  42 value 8784.081436
#> iter  43 value 8784.042734
#> iter  44 value 8783.552654
#> iter  45 value 8783.445591
#> iter  46 value 8782.872342
#> iter  47 value 8782.448203
#> iter  48 value 8782.171581
#> iter  49 value 8782.074688
#> iter  50 value 8782.042333
#> iter  51 value 8782.038646
#> iter  52 value 8781.951582
#> iter  53 value 8781.890176
#> iter  54 value 8781.853451
#> iter  55 value 8781.588346
#> iter  56 value 8781.516054
#> iter  57 value 8780.682039
#> iter  58 value 8780.337291
#> iter  59 value 8779.850009
#> iter  60 value 8779.651352
#> iter  61 value 8779.544711
#> iter  62 value 8779.364064
#> iter  63 value 8779.179306
#> iter  64 value 8778.852676
#> iter  65 value 8778.770623
#> iter  66 value 8778.672801
#> iter  67 value 8778.578332
#> iter  68 value 8778.539880
#> iter  69 value 8778.486867
#> iter  70 value 8778.447743
#> iter  71 value 8778.447384
#> iter  72 value 8778.446945
#> iter  73 value 8778.443635
#> iter  74 value 8778.442132
#> iter  74 value 8778.442011
#> iter  75 value 8778.441777
#> iter  75 value 8778.441729
#> iter  75 value 8778.441724
#> final  value 8778.441724 
#> converged
#> Starting Values
#> 0.250.250.250.25-500-0.47756445827387600.8490727400115340-50
#> 
#> 
#> Likelihood
#> initial  value 10985.536114 
#> iter   2 value 10800.352734
#> iter   3 value 10710.056216
#> iter   4 value 10696.539619
#> iter   5 value 10410.628040
#> iter   6 value 9573.297464
#> iter   7 value 9351.651148
#> iter   8 value 9329.344541
#> iter   9 value 9302.416025
#> iter  10 value 9265.668463
#> iter  11 value 9068.342808
#> iter  12 value 9037.543327
#> iter  13 value 8952.913024
#> iter  14 value 8926.152513
#> iter  15 value 8882.675206
#> iter  16 value 8869.904385
#> iter  17 value 8854.504370
#> iter  18 value 8829.269294
#> iter  19 value 8814.535096
#> iter  20 value 8794.155209
#> iter  21 value 8773.611200
#> iter  22 value 8739.848514
#> iter  23 value 8727.306187
#> iter  24 value 8715.940614
#> iter  25 value 8714.820453
#> iter  26 value 8706.647409
#> iter  27 value 8703.676076
#> iter  28 value 8698.952844
#> iter  29 value 8698.567056
#> iter  30 value 8698.201645
#> iter  31 value 8693.360213
#> iter  32 value 8688.138022
#> iter  33 value 8681.607925
#> iter  34 value 8680.921116
#> iter  35 value 8677.333737
#> iter  36 value 8674.251396
#> iter  37 value 8671.868378
#> iter  38 value 8669.386158
#> iter  39 value 8667.460252
#> iter  40 value 8665.912307
#> iter  41 value 8665.132798
#> iter  42 value 8665.116599
#> iter  43 value 8665.109115
#> iter  43 value 8665.109003
#> iter  43 value 8665.109003
#> final  value 8665.109003 
#> converged
#> Starting Values
#> 0.250.250.250.25-5000-0.47756445827387600.8490727400115340-50
#> 
#> 
#> Likelihood
#> initial  value 10985.536114 
#> iter   2 value 10886.600543
#> iter   3 value 10862.909766
#> iter   4 value 10671.259390
#> iter   5 value 9887.299676
#> iter   6 value 9814.061667
#> iter   7 value 9725.736135
#> iter   8 value 9431.956405
#> iter   9 value 9309.089085
#> iter  10 value 9157.673614
#> iter  11 value 9022.109546
#> iter  12 value 8969.446538
#> iter  13 value 8926.403004
#> iter  14 value 8902.358809
#> iter  15 value 8866.480236
#> iter  16 value 8828.857807
#> iter  17 value 8817.894795
#> iter  18 value 8806.176516
#> iter  19 value 8795.825224
#> iter  20 value 8793.029682
#> iter  21 value 8790.652786
#> iter  22 value 8788.726102
#> iter  23 value 8787.480071
#> iter  24 value 8787.285331
#> iter  25 value 8787.245374
#> iter  26 value 8787.241036
#> iter  27 value 8787.240185
#> iter  28 value 8787.239227
#> iter  28 value 8787.239140
#> final  value 8787.239140 
#> converged
#> ~24 shapes planned, est. 1135 s remaining (54.07 s/fit).
#> Starting Values
#> 0.250.250.250.25-500-0.477564458273876000.8490727400115340-50
#> 
#> 
#> Likelihood
#> initial  value 10985.536114 
#> iter   2 value 10957.973806
#> iter   3 value 10684.012113
#> iter   4 value 10524.257499
#> iter   5 value 10418.379817
#> iter   6 value 10399.123681
#> iter   7 value 9173.627233
#> iter   8 value 9113.693718
#> iter   9 value 9060.884048
#> iter  10 value 9060.139110
#> iter  11 value 9037.755567
#> iter  12 value 8984.740975
#> iter  13 value 8938.517252
#> iter  14 value 8926.904910
#> iter  15 value 8922.819343
#> iter  16 value 8904.439601
#> iter  17 value 8802.626488
#> iter  18 value 8790.554991
#> iter  19 value 8708.935300
#> iter  20 value 8653.373669
#> iter  21 value 8630.630284
#> iter  22 value 8605.581995
#> iter  23 value 8572.170409
#> iter  24 value 8560.618326
#> iter  25 value 8548.068724
#> iter  26 value 8540.968468
#> iter  27 value 8539.620827
#> iter  28 value 8535.293466
#> iter  29 value 8533.776331
#> iter  30 value 8532.680792
#> iter  31 value 8532.660401
#> iter  32 value 8532.655304
#> iter  33 value 8532.597926
#> iter  34 value 8532.583905
#> iter  35 value 8532.533671
#> iter  36 value 8532.339763
#> iter  37 value 8532.172075
#> iter  38 value 8531.746983
#> iter  39 value 8531.713991
#> iter  40 value 8531.482780
#> iter  41 value 8531.472328
#> iter  42 value 8531.419744
#> iter  43 value 8531.335160
#> iter  44 value 8531.295980
#> iter  45 value 8531.281881
#> iter  45 value 8531.281875
#> iter  45 value 8531.281875
#> final  value 8531.281875 
#> converged
#> Starting Values
#> 0.250.250.250.25-500-0.4775644582738760000.8490727400115340-50
#> 
#> 
#> Likelihood
#> initial  value 10985.536114 
#> iter   2 value 10903.202993
#> iter   3 value 10523.248501
#> iter   4 value 10096.543272
#> iter   5 value 10059.423897
#> iter   6 value 9800.386286
#> iter   7 value 9569.033193
#> iter   8 value 9401.795170
#> iter   9 value 9207.231580
#> iter  10 value 9197.067121
#> iter  11 value 9134.620754
#> iter  12 value 9118.995916
#> iter  13 value 9104.042147
#> iter  14 value 8859.160932
#> iter  15 value 8787.061083
#> iter  16 value 8756.607556
#> iter  17 value 8744.315956
#> iter  18 value 8733.969020
#> iter  19 value 8703.008906
#> iter  20 value 8690.071862
#> iter  21 value 8647.681478
#> iter  22 value 8641.425019
#> iter  23 value 8612.364494
#> iter  24 value 8602.502790
#> iter  25 value 8600.487925
#> iter  26 value 8599.255314
#> iter  27 value 8598.614612
#> iter  28 value 8593.250901
#> iter  29 value 8592.940106
#> iter  30 value 8592.352495
#> iter  31 value 8591.564393
#> iter  32 value 8591.434956
#> iter  33 value 8588.795133
#> iter  34 value 8588.677443
#> iter  35 value 8586.653640
#> iter  36 value 8584.393213
#> iter  37 value 8580.583653
#> iter  38 value 8580.000935
#> iter  39 value 8578.052719
#> iter  40 value 8576.976528
#> iter  41 value 8572.849952
#> iter  42 value 8570.537196
#> iter  43 value 8564.946989
#> iter  44 value 8558.572809
#> iter  45 value 8549.861904
#> iter  46 value 8543.418428
#> iter  47 value 8535.178714
#> iter  48 value 8528.051810
#> iter  49 value 8522.776074
#> iter  50 value 8522.519247
#> iter  51 value 8521.954646
#> iter  52 value 8521.858536
#> iter  53 value 8521.843159
#> iter  54 value 8521.841467
#> iter  55 value 8521.841334
#> iter  55 value 8521.841318
#> iter  55 value 8521.841318
#> final  value 8521.841318 
#> converged
#> Starting Values
#> 0.250.250.250.25-500-0.4775644582738760000.84907274001153400-50
#> 
#> 
#> Likelihood
#> initial  value 10985.536114 
#> iter   2 value 10894.920780
#> iter   3 value 10696.548987
#> iter   4 value 10625.893529
#> iter   5 value 10460.785562
#> iter   6 value 10126.311356
#> iter   7 value 10095.755969
#> iter   8 value 9970.881358
#> iter   9 value 9386.829406
#> iter  10 value 9352.750584
#> iter  11 value 9327.690998
#> iter  12 value 9228.272669
#> iter  13 value 9209.046142
#> iter  14 value 8999.788115
#> iter  15 value 8995.053010
#> iter  16 value 8938.998427
#> iter  17 value 8807.807357
#> iter  18 value 8784.185119
#> iter  19 value 8767.215806
#> iter  20 value 8731.994941
#> iter  21 value 8719.882165
#> iter  22 value 8705.148727
#> iter  23 value 8694.541892
#> iter  24 value 8693.179121
#> iter  25 value 8690.049150
#> iter  26 value 8686.992049
#> iter  27 value 8684.439139
#> iter  28 value 8683.923651
#> iter  29 value 8683.573953
#> iter  30 value 8682.917824
#> iter  31 value 8681.275275
#> iter  32 value 8677.591734
#> iter  33 value 8675.908456
#> iter  34 value 8674.439723
#> iter  35 value 8670.262015
#> iter  36 value 8657.767932
#> iter  37 value 8657.731319
#> iter  38 value 8657.374260
#> iter  39 value 8655.246413
#> iter  40 value 8652.031482
#> iter  41 value 8651.735015
#> iter  42 value 8650.933439
#> iter  43 value 8648.435972
#> iter  44 value 8648.232069
#> iter  45 value 8645.345089
#> iter  46 value 8644.237940
#> iter  47 value 8631.215833
#> iter  48 value 8628.798799
#> iter  49 value 8621.654199
#> iter  50 value 8615.484050
#> iter  51 value 8614.806257
#> iter  52 value 8608.542258
#> iter  53 value 8605.870936
#> iter  54 value 8602.512289
#> iter  55 value 8600.249355
#> iter  56 value 8599.287750
#> iter  57 value 8597.990051
#> iter  58 value 8597.665676
#> iter  59 value 8597.579938
#> iter  60 value 8597.566094
#> iter  61 value 8597.563913
#> iter  62 value 8597.563551
#> iter  63 value 8597.563394
#> iter  64 value 8597.563054
#> iter  65 value 8597.562723
#> iter  66 value 8597.562279
#> iter  67 value 8597.562011
#> iter  67 value 8597.562011
#> final  value 8597.562011 
#> converged
#> Starting Values
#> 0.250.250.250.25-500-0.4775644582738760000.849072740011534000-50
#> 
#> 
#> Likelihood
#> initial  value 10985.536114 
#> iter   2 value 10493.221942
#> iter   3 value 10476.329952
#> iter   4 value 9749.925159
#> iter   5 value 9543.811841
#> iter   6 value 9512.623046
#> iter   7 value 9266.555334
#> iter   8 value 9104.059806
#> iter   9 value 9069.275349
#> iter  10 value 8999.821966
#> iter  11 value 8989.185673
#> iter  12 value 8978.204094
#> iter  13 value 8905.661286
#> iter  14 value 8717.839479
#> iter  15 value 8668.828519
#> iter  16 value 8648.328414
#> iter  17 value 8619.170634
#> iter  18 value 8615.688248
#> iter  19 value 8610.887970
#> iter  20 value 8605.339898
#> iter  21 value 8604.981820
#> iter  22 value 8601.579607
#> iter  23 value 8600.052070
#> iter  24 value 8598.807457
#> iter  25 value 8597.883500
#> iter  26 value 8597.565850
#> iter  27 value 8597.422541
#> iter  28 value 8597.397731
#> iter  29 value 8597.383705
#> iter  30 value 8597.373113
#> iter  31 value 8597.349701
#> iter  32 value 8597.312657
#> iter  33 value 8597.243054
#> iter  34 value 8597.136576
#> iter  35 value 8597.094378
#> iter  35 value 8597.094337
#> iter  36 value 8597.093752
#> iter  36 value 8597.093720
#> iter  36 value 8597.093719
#> final  value 8597.093719 
#> converged
#> Starting Values
#> 0.250.250.250.25-500-0.4775644582738760000.8490727400115340-500
#> 
#> 
#> Likelihood
#> initial  value 10985.536114 
#> iter   2 value 10903.190446
#> iter   3 value 10484.708005
#> iter   4 value 9946.010551
#> iter   5 value 9915.070028
#> iter   6 value 9475.347085
#> iter   7 value 9116.419141
#> iter   8 value 9012.127987
#> iter   9 value 8990.208459
#> iter  10 value 8988.919502
#> iter  11 value 8976.930620
#> iter  12 value 8956.070754
#> iter  13 value 8950.970559
#> iter  14 value 8917.158697
#> iter  15 value 8885.039726
#> iter  16 value 8870.729779
#> iter  17 value 8867.911762
#> iter  18 value 8852.590369
#> iter  19 value 8792.219012
#> iter  20 value 8770.043281
#> iter  21 value 8756.835588
#> iter  22 value 8749.097257
#> iter  23 value 8716.665579
#> iter  24 value 8703.587805
#> iter  25 value 8694.387576
#> iter  26 value 8592.599625
#> iter  27 value 8590.558835
#> iter  28 value 8572.380435
#> iter  29 value 8563.765427
#> iter  30 value 8553.065639
#> iter  31 value 8545.685772
#> iter  32 value 8536.591798
#> iter  33 value 8531.553867
#> iter  34 value 8525.824210
#> iter  35 value 8522.970926
#> iter  36 value 8522.263468
#> iter  37 value 8521.763445
#> iter  38 value 8521.668802
#> iter  39 value 8521.611659
#> iter  40 value 8521.587376
#> iter  41 value 8521.575049
#> iter  42 value 8521.572869
#> iter  43 value 8521.572607
#> iter  43 value 8521.572605
#> final  value 8521.572605 
#> converged
#> Starting Values
#> 0.250.250.250.25-500-0.4775644582738760000.8490727400115340-5000
#> 
#> 
#> Likelihood
#> initial  value 10985.536114 
#> iter   2 value 10902.080940
#> iter   3 value 10764.962197
#> iter   4 value 10422.657365
#> iter   5 value 10282.172930
#> iter   6 value 10147.016932
#> iter   7 value 10121.432859
#> iter   8 value 9904.789307
#> iter   9 value 9105.134841
#> iter  10 value 9067.117350
#> iter  11 value 9050.950846
#> iter  12 value 9047.996286
#> iter  13 value 9034.168233
#> iter  14 value 9033.687040
#> iter  15 value 9022.986662
#> iter  16 value 9016.130619
#> iter  17 value 9013.987010
#> iter  18 value 9008.761960
#> iter  19 value 8917.080226
#> iter  20 value 8848.742699
#> iter  21 value 8829.852262
#> iter  22 value 8820.712796
#> iter  23 value 8800.763895
#> iter  24 value 8797.079127
#> iter  25 value 8785.792634
#> iter  26 value 8770.502733
#> iter  27 value 8766.876521
#> iter  28 value 8739.830577
#> iter  29 value 8682.457210
#> iter  30 value 8634.605450
#> iter  31 value 8612.929081
#> iter  32 value 8602.114770
#> iter  33 value 8598.162994
#> iter  34 value 8579.050684
#> iter  35 value 8577.943215
#> iter  36 value 8577.372223
#> iter  37 value 8566.195480
#> iter  38 value 8563.421679
#> iter  39 value 8558.056343
#> iter  40 value 8551.598901
#> iter  41 value 8543.217293
#> iter  42 value 8539.525442
#> iter  43 value 8534.332934
#> iter  44 value 8534.250547
#> iter  45 value 8527.629518
#> iter  46 value 8524.745522
#> iter  47 value 8524.531474
#> iter  48 value 8524.468096
#> iter  49 value 8524.400709
#> iter  50 value 8523.690609
#> iter  51 value 8523.394490
#> iter  52 value 8523.356865
#> iter  53 value 8520.595548
#> iter  54 value 8520.186156
#> iter  55 value 8518.951195
#> iter  56 value 8515.959840
#> iter  57 value 8514.198797
#> iter  58 value 8512.773975
#> iter  59 value 8511.948440
#> iter  60 value 8509.720991
#> iter  61 value 8507.309753
#> iter  62 value 8506.048681
#> iter  63 value 8505.278744
#> iter  64 value 8504.560417
#> iter  65 value 8502.664200
#> iter  66 value 8501.949284
#> iter  67 value 8501.226008
#> iter  68 value 8500.279566
#> iter  69 value 8500.105160
#> iter  70 value 8499.869669
#> iter  71 value 8499.856039
#> iter  72 value 8499.847626
#> iter  73 value 8499.847083
#> iter  73 value 8499.847030
#> iter  73 value 8499.847030
#> final  value 8499.847030 
#> converged
#> Starting Values
#> 0.250.250.250.25-50-0.4775644582738760000.8490727400115340-5000
#> 
#> 
#> Likelihood
#> initial  value 10985.536114 
#> iter   2 value 10902.093260
#> iter   3 value 10896.822549
#> iter   4 value 10671.904263
#> iter   5 value 10633.629699
#> iter   6 value 9323.546874
#> iter   7 value 9125.721334
#> iter   8 value 9070.468171
#> iter   9 value 8984.905434
#> iter  10 value 8961.952831
#> iter  11 value 8950.088916
#> iter  12 value 8943.047508
#> iter  13 value 8917.209439
#> iter  14 value 8905.582836
#> iter  15 value 8893.823800
#> iter  16 value 8887.958316
#> iter  17 value 8878.059168
#> iter  18 value 8872.002043
#> iter  19 value 8867.735986
#> iter  20 value 8855.092129
#> iter  21 value 8840.064859
#> iter  22 value 8836.029766
#> iter  23 value 8809.418375
#> iter  24 value 8787.478953
#> iter  25 value 8765.855292
#> iter  26 value 8758.417920
#> iter  27 value 8736.808567
#> iter  28 value 8725.117095
#> iter  29 value 8717.801721
#> iter  30 value 8716.547827
#> iter  31 value 8715.574697
#> iter  32 value 8715.131206
#> iter  33 value 8715.130958
#> iter  34 value 8715.111079
#> iter  35 value 8715.020827
#> iter  36 value 8714.991554
#> iter  37 value 8714.989950
#> iter  38 value 8714.111201
#> iter  39 value 8713.695099
#> iter  40 value 8713.635022
#> iter  41 value 8713.353488
#> iter  42 value 8712.956557
#> iter  43 value 8712.689081
#> iter  44 value 8712.530475
#> iter  45 value 8712.470662
#> iter  46 value 8712.419412
#> iter  47 value 8712.385639
#> iter  48 value 8712.369803
#> iter  49 value 8712.362198
#> iter  50 value 8712.358106
#> iter  51 value 8712.356074
#> iter  52 value 8712.355072
#> iter  53 value 8712.354564
#> iter  54 value 8712.354310
#> iter  54 value 8712.354183
#> iter  54 value 8712.354183
#> final  value 8712.354183 
#> converged
#> Starting Values
#> 0.250.250.250.25-5000-0.4775644582738760000.8490727400115340-5000
#> 
#> 
#> Likelihood
#> initial  value 10985.536114 
#> iter   2 value 10922.981063
#> iter   3 value 10918.315871
#> iter   4 value 10603.712778
#> iter   5 value 10551.866165
#> iter   6 value 10417.850659
#> iter   7 value 9525.459861
#> iter   8 value 9501.635589
#> iter   9 value 9322.322839
#> iter  10 value 9273.062650
#> iter  11 value 9249.396601
#> iter  12 value 9220.061067
#> iter  13 value 9208.873542
#> iter  14 value 9185.815175
#> iter  15 value 9177.254917
#> iter  16 value 8986.321112
#> iter  17 value 8963.109050
#> iter  18 value 8821.413936
#> iter  19 value 8771.160784
#> iter  20 value 8635.076922
#> iter  21 value 8616.519869
#> iter  22 value 8604.254121
#> iter  23 value 8594.431725
#> iter  24 value 8588.610296
#> iter  25 value 8586.227456
#> iter  26 value 8583.108747
#> iter  27 value 8581.343811
#> iter  28 value 8580.784124
#> iter  29 value 8580.647478
#> iter  30 value 8580.624795
#> iter  31 value 8580.608314
#> iter  32 value 8580.586991
#> iter  33 value 8580.542298
#> iter  34 value 8580.464084
#> iter  35 value 8580.351226
#> iter  36 value 8580.250919
#> iter  37 value 8580.250480
#> iter  38 value 8580.249188
#> iter  39 value 8580.242927
#> iter  39 value 8580.242860
#> iter  40 value 8580.237573
#> iter  41 value 8580.236846
#> iter  42 value 8580.234966
#> iter  42 value 8580.234925
#> iter  43 value 8580.234289
#> iter  43 value 8580.234214
#> iter  43 value 8580.234213
#> final  value 8580.234213 
#> converged
#> Starting Values
#> 0.250.250.250.25-500-0.47756445827387600.8490727400115340-5000
#> 
#> 
#> Likelihood
#> initial  value 10985.536114 
#> iter   2 value 10876.757002
#> iter   3 value 10579.018173
#> iter   4 value 10184.372325
#> iter   5 value 10113.379067
#> iter   6 value 9810.911544
#> iter   7 value 9339.527204
#> iter   8 value 9304.571345
#> iter   9 value 9297.244783
#> iter  10 value 9287.584750
#> iter  11 value 9251.051138
#> iter  12 value 9185.924581
#> iter  13 value 9104.742687
#> iter  14 value 8878.321374
#> iter  15 value 8855.845529
#> iter  16 value 8818.898739
#> iter  17 value 8803.829067
#> iter  18 value 8772.058962
#> iter  19 value 8749.902330
#> iter  20 value 8732.872733
#> iter  21 value 8721.478965
#> iter  22 value 8717.921662
#> iter  23 value 8716.276766
#> iter  24 value 8715.976049
#> iter  25 value 8715.573902
#> iter  26 value 8715.443391
#> iter  27 value 8715.375233
#> iter  28 value 8715.337561
#> iter  29 value 8715.318177
#> iter  30 value 8715.296310
#> iter  31 value 8715.295893
#> iter  32 value 8715.290311
#> iter  33 value 8715.290155
#> iter  34 value 8715.285282
#> iter  35 value 8715.279588
#> iter  36 value 8715.274064
#> iter  37 value 8715.244158
#> iter  38 value 8714.975199
#> iter  39 value 8714.905610
#> iter  40 value 8714.887921
#> iter  41 value 8714.869824
#> iter  42 value 8714.682506
#> iter  43 value 8714.672728
#> iter  44 value 8714.666907
#> iter  45 value 8714.660105
#> iter  46 value 8714.655386
#> iter  47 value 8714.653128
#> iter  48 value 8714.652134
#> iter  49 value 8714.651572
#> iter  50 value 8714.651282
#> iter  51 value 8714.651145
#> iter  51 value 8714.651075
#> iter  51 value 8714.651075
#> final  value 8714.651075 
#> converged
#> Starting Values
#> 0.250.250.250.25-500-0.477564458273876000.8490727400115340-5000
#> 
#> 
#> Likelihood
#> initial  value 10985.536114 
#> iter   2 value 10301.253371
#> iter   3 value 10298.958097
#> iter   4 value 10133.952800
#> iter   5 value 10052.794441
#> iter   6 value 9364.546437
#> iter   7 value 9042.645842
#> iter   8 value 8918.088763
#> iter   9 value 8875.365326
#> iter  10 value 8809.495376
#> iter  11 value 8771.672340
#> iter  12 value 8764.580220
#> iter  13 value 8726.803364
#> iter  14 value 8686.128017
#> iter  15 value 8669.959131
#> iter  16 value 8613.274276
#> iter  17 value 8598.863857
#> iter  18 value 8588.389283
#> iter  19 value 8576.633235
#> iter  20 value 8555.485216
#> iter  21 value 8543.895559
#> iter  22 value 8531.086038
#> iter  23 value 8526.693419
#> iter  24 value 8523.124366
#> iter  25 value 8519.525618
#> iter  26 value 8514.540396
#> iter  27 value 8513.638223
#> iter  28 value 8513.273157
#> iter  29 value 8512.651475
#> iter  30 value 8512.521358
#> iter  31 value 8512.407481
#> iter  32 value 8512.378359
#> iter  33 value 8512.377501
#> iter  34 value 8512.371858
#> iter  35 value 8512.371536
#> iter  36 value 8512.368703
#> iter  37 value 8512.367638
#> iter  37 value 8512.367517
#> iter  37 value 8512.367445
#> final  value 8512.367445 
#> converged
#> Starting Values
#> 0.250.250.250.25-500-0.4775644582738760000.84907274001153400-5000
#> 
#> 
#> Likelihood
#> initial  value 10985.536114 
#> iter   2 value 10913.904114
#> iter   3 value 10780.162063
#> iter   4 value 10659.887732
#> iter   5 value 10165.387906
#> iter   6 value 10155.068661
#> iter   7 value 9634.338835
#> iter   8 value 9568.078112
#> iter   9 value 9452.580976
#> iter  10 value 9067.276329
#> iter  11 value 8928.809186
#> iter  12 value 8871.481552
#> iter  13 value 8837.439322
#> iter  14 value 8787.368075
#> iter  15 value 8745.373859
#> iter  16 value 8730.688207
#> iter  17 value 8686.119222
#> iter  18 value 8684.414245
#> iter  19 value 8683.583366
#> iter  20 value 8683.306122
#> iter  21 value 8683.162909
#> iter  22 value 8682.917995
#> iter  23 value 8682.861196
#> iter  24 value 8682.839435
#> iter  25 value 8682.802567
#> iter  26 value 8682.760861
#> iter  27 value 8682.692467
#> iter  28 value 8682.596237
#> iter  29 value 8682.520445
#> iter  30 value 8682.455593
#> iter  31 value 8682.181845
#> iter  32 value 8681.923946
#> iter  33 value 8681.507374
#> iter  34 value 8681.214395
#> iter  35 value 8681.108862
#> iter  36 value 8681.080587
#> iter  36 value 8681.080521
#> final  value 8681.080521 
#> converged
#> Starting Values
#> 0.250.250.250.25-500-0.4775644582738760000.849072740011534000-5000
#> 
#> 
#> Likelihood
#> initial  value 10985.536114 
#> iter   2 value 10492.106524
#> iter   3 value 10473.741762
#> iter   4 value 10346.383807
#> iter   5 value 9516.446853
#> iter   6 value 9514.397647
#> iter   7 value 9476.919990
#> iter   8 value 9326.278416
#> iter   9 value 9199.800122
#> iter  10 value 9109.146168
#> iter  11 value 9015.930723
#> iter  12 value 8992.250864
#> iter  13 value 8937.407045
#> iter  14 value 8836.515139
#> iter  15 value 8765.120484
#> iter  16 value 8698.673948
#> iter  17 value 8663.033573
#> iter  18 value 8635.086593
#> iter  19 value 8626.461535
#> iter  20 value 8612.518493
#> iter  21 value 8603.389023
#> iter  22 value 8600.889391
#> iter  23 value 8599.572389
#> iter  24 value 8598.309716
#> iter  25 value 8598.044639
#> iter  26 value 8597.925382
#> iter  27 value 8597.808600
#> iter  28 value 8597.658926
#> iter  29 value 8597.591821
#> iter  30 value 8597.579348
#> iter  31 value 8597.577679
#> iter  32 value 8597.575699
#> iter  33 value 8597.570532
#> iter  34 value 8597.559824
#> iter  35 value 8597.539412
#> iter  36 value 8597.507650
#> iter  37 value 8597.472331
#> iter  38 value 8597.435193
#> iter  39 value 8597.434865
#> iter  39 value 8597.434865
#> iter  39 value 8597.434861
#> final  value 8597.434861 
#> converged
#> evaluated 15 shapes in 1123 s.
#> Stage 4: fitting final model (degrees 2,3,1,3, Hessian on) ...
#> Starting Values
#> 0.250.250.250.25-500-0.4775644582738760000.8490727400115340-5000
#> 
#> 
#> Likelihood
#> iter   1 value 
#> 10985.536114
#> iter   2 value 
#> 10983.421303
#> iter   3 value 
#> 10982.886391
#> iter   4 value 
#> 10982.343290
#> iter   5 value 
#> 10980.663149
#> iter   6 value 
#> 10978.903854
#> iter   7 value 
#> 10973.099912
#> iter   8 value 
#> 10966.406472
#> iter   9 value 
#> 10938.838000
#> iter  10 value 
#> 10893.588544
#> iter  11 value 
#> 10592.931941
#> iter  12 value 
#> 10305.612657
#> iter  13 value 
#> 10267.382811
#> iter  14 value 
#> 10243.098105
#> iter  15 value 
#> 10175.893638
#> iter  16 value 
#> 10077.380766
#> iter  17 value 
#> 10021.082931
#> iter  18 value 
#> 9964.691625
#> iter  19 value 
#> 9907.291321
#> iter  20 value 
#> 9737.967233
#> iter  21 value 
#> 9450.880057
#> iter  22 value 
#> 9423.595048
#> iter  23 value 
#> 9387.822703
#> iter  24 value 
#> 9332.064480
#> iter  25 value 
#> 9312.111647
#> iter  26 value 
#> 9276.586499
#> iter  27 value 
#> 9207.760389
#> iter  28 value 
#> 9074.046268
#> iter  29 value 
#> 8968.887386
#> iter  30 value 
#> 8887.576562
#> iter  31 value 
#> 8838.300432
#> iter  32 value 
#> 8781.684488
#> iter  33 value 
#> 8699.169355
#> iter  34 value 
#> 8663.141079
#> iter  35 value 
#> 8627.562676
#> iter  36 value 
#> 8599.693407
#> iter  37 value 
#> 8570.428929
#> iter  38 value 
#> 8567.619255
#> iter  39 value 
#> 8556.558931
#> iter  40 value 
#> 8550.959847
#> iter  41 value 
#> 8544.410027
#> iter  42 value 
#> 8537.127010
#> iter  43 value 
#> 8531.766685
#> iter  44 value 
#> 8522.436848
#> iter  45 value 
#> 8518.857270
#> iter  46 value 
#> 8513.603762
#> iter  47 value 
#> 8510.856755
#> iter  48 value 
#> 8507.667951
#> iter  49 value 
#> 8505.487591
#> iter  50 value 
#> 8504.044847
#> iter  51 value 
#> 8501.992450
#> iter  52 value 
#> 8500.763873
#> iter  53 value 
#> 8500.152909
#> iter  54 value 
#> 8499.953692
#> iter  55 value 
#> 8499.917248
#> iter  56 value 
#> 8499.895927
#> iter  57 value 
#> 8499.868716
#> iter  58 value 
#> 8499.853855
#> iter  59 value 
#> 8499.848237
#> iter  60 value 
#> 8499.847370
#> iter  61 value 
#> 8499.847154
#> iter  62 value 
#> 8499.847049
#> iter  63 value 
#> 8499.847027
#> iter  64 value 
#> 8499.847026
#> iter  65 value 
#> 8499.847026
#> iter  66 value 
#> 8499.847026
#> iter  67 value 
#> 8499.847026
#> <gbtm_result>
#>   engine/family : trajeR / binomial
#>   method        : L
#>   groups        : 4
#>   degrees       : 2, 3, 1, 3
#>   GRoLTS criteria met: TRUE
#>   entropy       : 0.762  BIC: 17116.7
# }
```
