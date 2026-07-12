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
ground-truth groups. `sim_binary` has a binary outcome measured on ten
occasions, with four latent trajectory shapes of mixed polynomial order:
a linear rising group, a cubic rise-peak-decline group, a cubic
decline-trough-recovery group, and a linear falling group:

``` r

data("sim_binary", package = "gbtmkit")
head(sim_binary)
#>   id      x1   x2 y1 y2 y3 y4 y5 y6 y7 y8 y9 y10 t1 t2 t3 t4 t5 t6 t7 t8 t9 t10
#> 1  1  0.4618 3.01  1  1  1  1  1  1  1  1  0   1  1  2  3  4  5  6  7  8  9  10
#> 2  2  0.0972 2.49  0  0  0  0  0  1  1  1  1   1  1  2  3  4  5  6  7  8  9  10
#> 3  3  0.6760 2.28  1  1  1  1  1  1  1  0  0   0  1  2  3  4  5  6  7  8  9  10
#> 4  4 -0.7488 2.08  0  0  0  0  0  0  1  1  1   0  1  2  3  4  5  6  7  8  9  10
#> 5  5  1.0256 4.63  0  1  1  0  0  0  0  0  1   1  1  2  3  4  5  6  7  8  9  10
#> 6  6 -0.6966 4.24  1  1  1  1  1  1  1  0  1   0  1  2  3  4  5  6  7  8  9  10
#>   true_group
#> 1          2
#> 2          1
#> 3          2
#> 4          1
#> 5          3
#> 6          4
```

## 1. Describe the model with a spec

[`gbtm_spec()`](https://fabregithub.github.io/gbtmkit/reference/gbtm_spec.md)
records *what* to model – the outcome and time columns (by name), the
id, and the outcome family – and validates it, independent of which
engine will fit it.

``` r

spec <- gbtm_spec(
  sim_binary,
  outcomes = paste0("y", 1:10),
  time     = paste0("t", 1:10),
  id       = "id",
  family   = "binomial"
)
spec
#> <gbtm_spec>
#>   family     : binomial
#>   subjects   : 1500
#>   occasions  : 10
#>   outcomes   : y1, y2, y3, y4, y5, y6, y7, y8, y9, y10
#>   time       : t1, t2, t3, t4, t5, t6, t7, t8, t9, t10
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
  degree     = 2,       # quadratic while choosing the number of groups --
                        # with curved shapes, linear-only selection under-selects
  method     = "L",     # fix the algorithm (skip stage 1) for speed
  max_degree = 3,       # allow up to cubic in the shape search
  seed       = 1,
  verbose    = FALSE
)
#> Starting Values
#> 0.50.5-1.35218614405793001.9707048996239500
#> 
#> Likelihood
#> initial  value 11144.862797 
#> iter   2 value 9949.344846
#> iter   3 value 9948.517726
#> iter   4 value 9887.968577
#> iter   5 value 9852.794629
#> iter   6 value 9802.178974
#> iter   7 value 9756.011520
#> iter   8 value 9750.721957
#> iter   9 value 9419.958041
#> iter  10 value 9161.731928
#> iter  11 value 8914.045923
#> iter  12 value 8782.663552
#> iter  13 value 8720.369955
#> iter  14 value 8689.124054
#> iter  15 value 8686.580176
#> iter  16 value 8685.887592
#> iter  17 value 8685.880238
#> iter  17 value 8685.880137
#> iter  18 value 8685.877664
#> iter  19 value 8685.877129
#> iter  20 value 8685.868228
#> iter  21 value 8685.867828
#> iter  22 value 8685.864742
#> iter  23 value 8685.864540
#> iter  24 value 8685.862595
#> iter  25 value 8685.862448
#> iter  25 value 8685.862321
#> iter  25 value 8685.862318
#> final  value 8685.862318 
#> converged
#> Starting Values
#> 0.3333333333333330.3333333333333330.333333333333333-2.75953796069026000.16678555619753500-500
#> 
#> Likelihood
#> initial  value 11486.525318 
#> iter   2 value 11267.702756
#> iter   3 value 11046.140091
#> iter   4 value 10424.392736
#> iter   5 value 9803.587104
#> iter   6 value 9737.171147
#> iter   7 value 9731.611043
#> iter   8 value 9703.989854
#> iter   9 value 9695.292237
#> iter  10 value 9512.244560
#> iter  11 value 9351.003029
#> iter  12 value 9185.579216
#> iter  13 value 8972.709663
#> iter  14 value 8944.442491
#> iter  15 value 8938.613980
#> iter  16 value 8890.720136
#> iter  17 value 8865.243610
#> iter  18 value 8848.058840
#> iter  19 value 8800.173650
#> iter  20 value 8797.454865
#> iter  21 value 8771.525950
#> iter  22 value 8697.804331
#> iter  23 value 8688.651526
#> iter  24 value 8687.396370
#> iter  25 value 8687.082615
#> iter  26 value 8686.508758
#> iter  27 value 8686.205263
#> iter  28 value 8686.041080
#> iter  29 value 8685.960229
#> iter  30 value 8685.912017
#> iter  31 value 8685.887332
#> iter  32 value 8685.875141
#> iter  33 value 8685.868812
#> iter  34 value 8685.865561
#> iter  35 value 8685.863946
#> iter  36 value 8685.863134
#> iter  36 value 8685.863134
#> final  value 8685.863134 
#> converged
#> Starting Values
#> 0.250.250.250.25-500-0.477564458273876000.84907274001153400-500
#> 
#> Likelihood
#> initial  value 10985.536114 
#> iter   2 value 10832.062710
#> iter   3 value 10820.357392
#> iter   4 value 10676.738270
#> iter   5 value 9789.253631
#> iter   6 value 9510.472294
#> iter   7 value 9147.675265
#> iter   8 value 9101.075214
#> iter   9 value 9039.654187
#> iter  10 value 9000.295827
#> iter  11 value 8979.413113
#> iter  12 value 8931.417694
#> iter  13 value 8891.762505
#> iter  14 value 8884.444598
#> iter  15 value 8861.054776
#> iter  16 value 8860.535407
#> iter  17 value 8856.284035
#> iter  18 value 8841.861792
#> iter  19 value 8802.427472
#> iter  20 value 8787.058697
#> iter  21 value 8749.511283
#> iter  22 value 8689.112051
#> iter  23 value 8682.724958
#> iter  24 value 8676.175820
#> iter  25 value 8670.648359
#> iter  26 value 8644.729215
#> iter  27 value 8622.755948
#> iter  28 value 8612.789550
#> iter  29 value 8602.489948
#> iter  30 value 8583.983131
#> iter  31 value 8581.801208
#> iter  32 value 8563.945825
#> iter  33 value 8548.627139
#> iter  34 value 8540.672875
#> iter  35 value 8538.162604
#> iter  36 value 8535.027188
#> iter  37 value 8533.760348
#> iter  38 value 8531.406171
#> iter  39 value 8531.257026
#> iter  40 value 8530.394562
#> iter  41 value 8530.082376
#> iter  42 value 8529.800045
#> iter  43 value 8529.677807
#> iter  44 value 8529.653000
#> iter  45 value 8529.648380
#> iter  46 value 8529.647935
#> iter  46 value 8529.647883
#> iter  47 value 8529.647173
#> iter  48 value 8529.646934
#> iter  48 value 8529.646924
#> iter  48 value 8529.646917
#> final  value 8529.646917 
#> converged
#> Starting Values
#> 0.20.20.20.20.2-500-0.942973425273998000.166785556197535001.4045182259602800-500
#> 
#> Likelihood
#> initial  value 10812.940044 
#> iter   2 value 10068.443848
#> iter   3 value 10058.144107
#> iter   4 value 10036.187036
#> iter   5 value 9834.899792
#> iter   6 value 9182.395578
#> iter   7 value 9086.542650
#> iter   8 value 8960.369949
#> iter   9 value 8957.421335
#> iter  10 value 8955.314342
#> iter  11 value 8945.711717
#> iter  12 value 8942.562532
#> iter  13 value 8786.165828
#> iter  14 value 8743.270149
#> iter  15 value 8702.895117
#> iter  16 value 8696.866127
#> iter  17 value 8630.095693
#> iter  18 value 8629.254238
#> iter  19 value 8606.937714
#> iter  20 value 8593.852582
#> iter  21 value 8593.102524
#> iter  22 value 8584.368738
#> iter  23 value 8553.667352
#> iter  24 value 8547.219857
#> iter  25 value 8540.141701
#> iter  26 value 8538.576846
#> iter  27 value 8533.078268
#> iter  28 value 8531.144563
#> iter  29 value 8530.119368
#> iter  30 value 8529.692493
#> iter  31 value 8529.633005
#> iter  32 value 8529.613447
#> iter  33 value 8529.607527
#> iter  34 value 8529.605189
#> iter  35 value 8529.604122
#> iter  36 value 8529.602856
#> iter  37 value 8529.599269
#> iter  38 value 8529.586038
#> iter  39 value 8529.578910
#> iter  40 value 8529.570747
#> iter  41 value 8529.560051
#> iter  42 value 8529.549428
#> iter  43 value 8529.511282
#> iter  44 value 8529.498679
#> iter  45 value 8529.490258
#> iter  46 value 8529.488627
#> iter  46 value 8529.488511
#> final  value 8529.488511 
#> converged
#> Starting Values
#> 0.250.250.250.25-50-0.47756445827387600.8490727400115340-50
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
#> Starting Values
#> 0.250.250.250.25-500-0.477564458273876000.8490727400115340-50
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
#> Starting Values
#> 0.250.250.250.25-500-0.4775644582738760000.8490727400115340-5000
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
res
#> <gbtm_result>
#>   engine/family : trajeR / binomial
#>   method        : L
#>   groups        : 4
#>   degrees       : 2, 3, 1, 3
#>   GRoLTS criteria met: TRUE
#>   entropy       : 0.762  BIC: 17116.7
```

The pipeline recovers the four planted groups. Everything each stage
produced is kept on the result object:

``` r

res$group_selection      # BIC for each candidate number of groups
#> <gbtm_selection> stage=n_groups  by=BIC
#>  n_groups   degrees      bic      aic   ok
#>         2       2,2 17422.92 17385.72 TRUE
#>         3     2,2,2 17452.17 17393.73 TRUE
#>         4   2,2,2,2 17168.99 17089.29 TRUE
#>         5 2,2,2,2,2 17197.93 17096.98 TRUE
#>   best: 4
```

``` r

summary(res)
#> === gbtm pipeline result ===
#> <gbtm_result>
#>   engine/family : trajeR / binomial
#>   method        : L
#>   groups        : 4
#>   degrees       : 2, 3, 1, 3
#>   GRoLTS criteria met: TRUE
#>   entropy       : 0.762  BIC: 17116.7
#> 
#> Group diagnostics:
#>  group n_assigned prop_assigned prop_model mismatch  appa    occ
#>      1        325         0.217      0.197   -0.019 0.862 25.333
#>      2        290         0.193      0.217    0.023 0.902 33.189
#>      3        572         0.381      0.358   -0.023 0.891 14.634
#>      4        313         0.209      0.228    0.019 0.866 21.945
#> 
#> Assigned group sizes:
#> 
#>   1   2   3   4 
#> 325 290 572 313
```

## 3. Inspect and plot

[`gbtm_diagnostics()`](https://fabregithub.github.io/gbtmkit/reference/gbtm_diagnostics.md)
gives the GRoLTS classification diagnostics, and
[`plot_trajectories()`](https://fabregithub.github.io/gbtmkit/reference/plot_trajectories.md)
draws the fitted group trajectories with the observed per-group means
overlaid.

``` r

res$diagnostics$groups
#>   group n_assigned prop_assigned prop_model    mismatch      appa      occ
#> 1     1        325     0.2166667  0.1973879 -0.01927876 0.8616925 25.33329
#> 2     2        290     0.1933333  0.2166825  0.02334920 0.9017755 33.18889
#> 3     3        572     0.3813333  0.3583779 -0.02295544 0.8909961 14.63429
#> 4     4        313     0.2086667  0.2275517  0.01888500 0.8660335 21.94462
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
#> 1  1     3 7.128253e-10 4.486503e-04 9.472586e-01 0.0522927836
#> 2  2     1 9.470205e-01 4.553914e-02 3.593663e-08 0.0074403597
#> 3  3     3 6.537871e-11 5.160593e-05 9.423786e-01 0.0575698258
#> 4  4     1 9.602393e-01 2.927954e-02 2.435747e-08 0.0104811684
#> 5  5     2 3.073100e-03 9.962652e-01 1.342337e-05 0.0006482664
#> 6  6     3 2.151267e-10 1.157310e-04 9.264874e-01 0.0733968257
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
#> 0.50.5-1.3521861440579301.970704899623950
#> 
#> Likelihood
#> initial  value 11144.862797 
#> iter   2 value 9527.864549
#> iter   3 value 9454.817848
#> iter   4 value 9312.734417
#> iter   5 value 9303.984714
#> iter   6 value 9271.598762
#> iter   7 value 9049.609517
#> iter   8 value 9007.559499
#> iter   9 value 8982.329873
#> iter  10 value 8979.854567
#> iter  11 value 8972.757583
#> iter  12 value 8971.983206
#> iter  13 value 8971.977860
#> iter  14 value 8971.887242
#> iter  15 value 8971.860098
#> iter  16 value 8971.765228
#> iter  17 value 8971.743130
#> iter  18 value 8971.721612
#> iter  18 value 8971.721604
#> iter  18 value 8971.721604
#> final  value 8971.721604 
#> converged
#> Starting Values
#> 0.50.5-1.3521861440579301.970704899623950
#> 
#> Likelihood
#> iter   1 value 11144.862797
#> iter   2 value 9032.839186
#> iter   3 value 8973.329390
#> iter   4 value 8972.290757
#> iter   5 value 8972.113062
#> iter   6 value 8971.995610
#> iter   7 value 8971.913742
#> iter   8 value 8971.856499
#> iter   9 value 8971.816402
#> iter  10 value 8971.788276
#> iter  11 value 8971.765023
#> iter  12 value 8971.749926
#> iter  13 value 8971.746860
#> iter  14 value 8971.746654
#> iter  15 value 8971.746553
#> iter  16 value 8971.737532
#> iter  17 value 8971.735601
#> iter  18 value 8971.735472
#> iter  19 value 8971.735438
#> iter  20 value 8971.730471
#> iter  21 value 8971.730142
#> iter  22 value 8971.730114
#> iter  23 value 8971.730085
#> iter  24 value 8971.730064
#> iter  25 value 8971.729201
#> iter  26 value 8971.729157
#> iter  27 value 8971.729102
#> iter  28 value 8971.726530
#> iter  29 value 8971.726380
#> iter  30 value 8971.726365
#> iter  31 value 8971.726348
#> iter  32 value 8971.726338
#> iter  33 value 8971.726320
#> iter  34 value 8971.726277
#> iter  35 value 8971.726261
#> iter  36 value 8971.726242
#> iter  37 value 8971.726183
#> iter  38 value 8971.725540
#> iter  39 value 8971.725500
#> iter  40 value 8971.725479
#> iter  41 value 8971.725467
#> iter  42 value 8971.725445
#> iter  43 value 8971.724415
#> iter  44 value 8971.724364
#> iter  45 value 8971.724355
#> iter  46 value 8971.724348
#> iter  47 value 8971.724337
#> iter  48 value 8971.724304
#> iter  49 value 8971.724298
#> iter  50 value 8971.724267
#> iter  51 value 8971.724255
#> iter  52 value 8971.724234
#> iter  53 value 8971.724200
#> iter  54 value 8971.724186
#> iter  55 value 8971.724150
#> iter  56 value 8971.724141
#> iter  57 value 8971.724131
#> iter  58 value 8971.724127
#> iter  59 value 8971.724097
#> iter  60 value 8971.724085
#> iter  61 value 8971.724078
#> iter  62 value 8971.724072
#> iter  63 value 8971.724053
#> iter  64 value 8971.724034
#> iter  65 value 8971.724029
#> iter  66 value 8971.724021
#> iter  67 value 8971.724014
#> iter  68 value 8971.724008
#> iter  69 value 8971.723981
#> iter  70 value 8971.723972
#> iter  71 value 8971.723965
#> iter  72 value 8971.723959
#> iter  73 value 8971.723937
#> iter  74 value 8971.723924
#> iter  75 value 8971.723918
#> iter  76 value 8971.723912
#> iter  77 value 8971.723900
#> iter  78 value 8971.723879
#> iter  79 value 8971.723874
#> iter  80 value 8971.723866
#> iter  81 value 8971.723859
#> iter  82 value 8971.723854
#> iter  83 value 8971.723830
#> iter  84 value 8971.723820
#> iter  85 value 8971.723814
#> iter  86 value 8971.723808
#> iter  87 value 8971.723794
#> iter  88 value 8971.723776
#> iter  89 value 8971.723772
#> iter  90 value 8971.723764
#> iter  91 value 8971.723758
#> iter  92 value 8971.723753
#> iter  93 value 8971.723732
#> iter  94 value 8971.723722
#> iter  95 value 8971.723717
#> iter  96 value 8971.723711
#> iter  97 value 8971.723695
#> iter  98 value 8971.723682
#> iter  99 value 8971.723677
#> Starting Values
#> 0.50.5-1.3521861440579301.970704899623950
#> 
#> Likelihood
#> iter   1 value 11144.862797
#> iter   2 value 9032.839223
#> iter   3 value 8973.329376
#> iter   4 value 8972.290740
#> iter   5 value 8972.113050
#> iter   6 value 8971.995602
#> iter   7 value 8971.913737
#> iter   8 value 8971.856495
#> iter   9 value 8971.816399
#> iter  10 value 8971.788274
#> iter  11 value 8971.768524
#> iter  12 value 8971.754641
#> iter  13 value 8971.744876
#> iter  14 value 8971.738003
#> iter  15 value 8971.733163
#> iter  16 value 8971.729754
#> iter  17 value 8971.727351
#> iter  18 value 8971.725658
#> iter  19 value 8971.724463
#> iter  20 value 8971.723621
#> iter  21 value 8971.723027
#> iter  22 value 8971.722608
#> iter  23 value 8971.722313
#> iter  24 value 8971.722104
#> iter  25 value 8971.721957
#> iter  26 value 8971.721853
#> iter  27 value 8971.721780
#> iter  28 value 8971.721728
#> iter  29 value 8971.721692
#> iter  30 value 8971.721666
#> iter  31 value 8971.721648
#> iter  32 value 8971.721635
#> iter  33 value 8971.721626
#> iter  34 value 8971.721619
#> iter  35 value 8971.721615
#> iter  36 value 8971.721612
#> iter  37 value 8971.721609
#> iter  38 value 8971.721608
#> iter  39 value 8971.721607
#> iter  40 value 8971.721606
#> iter  41 value 8971.721605
#> iter  42 value 8971.721605
#> iter  43 value 8971.721605
#> iter  44 value 8971.721605
#> iter  45 value 8971.721604
#> iter  46 value 8971.721604
#> iter  47 value 8971.721604
#> iter  48 value 8971.721604
#> iter  49 value 8971.721604
#> iter  50 value 8971.721604
#> iter  51 value 8971.721604
#> iter  52 value 8971.721604
#> iter  53 value 8971.721604
#> iter  54 value 8971.721604
#> iter  55 value 8971.721604
#> iter  56 value 8971.721604
#> iter  57 value 8971.721604
#> iter  58 value 8971.721604
#> iter  59 value 8971.721604
#> iter  60 value 8971.721604
#> iter  61 value 8971.721604
#> iter  62 value 8971.721604
algo
#> <gbtm_selection> stage=algorithm  by=BIC
#>  method       bic       aic   ok
#>       L  17980.01  17953.44 TRUE
#>      EM 145507.84 145481.28 TRUE
#>  EMIRLS 145739.37 145712.80 TRUE
#>   best: L
```

**Stage 2 – choose the number of groups** by BIC over a set of
candidates. Quadratic shapes are used while sweeping: with curved
trajectories like these, linear-only selection under-selects the number
of groups:

``` r

groups <- select_n_groups(spec, candidates = 2:5, degree = 2, method = "L")
#> Starting Values
#> 0.50.5-1.35218614405793001.9707048996239500
#> 
#> Likelihood
#> initial  value 11144.862797 
#> iter   2 value 9949.344846
#> iter   3 value 9948.517726
#> iter   4 value 9887.968577
#> iter   5 value 9852.794629
#> iter   6 value 9802.178974
#> iter   7 value 9756.011520
#> iter   8 value 9750.721957
#> iter   9 value 9419.958041
#> iter  10 value 9161.731928
#> iter  11 value 8914.045923
#> iter  12 value 8782.663552
#> iter  13 value 8720.369955
#> iter  14 value 8689.124054
#> iter  15 value 8686.580176
#> iter  16 value 8685.887592
#> iter  17 value 8685.880238
#> iter  17 value 8685.880137
#> iter  18 value 8685.877664
#> iter  19 value 8685.877129
#> iter  20 value 8685.868228
#> iter  21 value 8685.867828
#> iter  22 value 8685.864742
#> iter  23 value 8685.864540
#> iter  24 value 8685.862595
#> iter  25 value 8685.862448
#> iter  25 value 8685.862321
#> iter  25 value 8685.862318
#> final  value 8685.862318 
#> converged
#> Starting Values
#> 0.3333333333333330.3333333333333330.333333333333333-2.75953796069026000.16678555619753500-500
#> 
#> Likelihood
#> initial  value 11486.525318 
#> iter   2 value 11267.702756
#> iter   3 value 11046.140091
#> iter   4 value 10424.392736
#> iter   5 value 9803.587104
#> iter   6 value 9737.171147
#> iter   7 value 9731.611043
#> iter   8 value 9703.989854
#> iter   9 value 9695.292237
#> iter  10 value 9512.244560
#> iter  11 value 9351.003029
#> iter  12 value 9185.579216
#> iter  13 value 8972.709663
#> iter  14 value 8944.442491
#> iter  15 value 8938.613980
#> iter  16 value 8890.720136
#> iter  17 value 8865.243610
#> iter  18 value 8848.058840
#> iter  19 value 8800.173650
#> iter  20 value 8797.454865
#> iter  21 value 8771.525950
#> iter  22 value 8697.804331
#> iter  23 value 8688.651526
#> iter  24 value 8687.396370
#> iter  25 value 8687.082615
#> iter  26 value 8686.508758
#> iter  27 value 8686.205263
#> iter  28 value 8686.041080
#> iter  29 value 8685.960229
#> iter  30 value 8685.912017
#> iter  31 value 8685.887332
#> iter  32 value 8685.875141
#> iter  33 value 8685.868812
#> iter  34 value 8685.865561
#> iter  35 value 8685.863946
#> iter  36 value 8685.863134
#> iter  36 value 8685.863134
#> final  value 8685.863134 
#> converged
#> Starting Values
#> 0.250.250.250.25-500-0.477564458273876000.84907274001153400-500
#> 
#> Likelihood
#> initial  value 10985.536114 
#> iter   2 value 10832.062710
#> iter   3 value 10820.357392
#> iter   4 value 10676.738270
#> iter   5 value 9789.253631
#> iter   6 value 9510.472294
#> iter   7 value 9147.675265
#> iter   8 value 9101.075214
#> iter   9 value 9039.654187
#> iter  10 value 9000.295827
#> iter  11 value 8979.413113
#> iter  12 value 8931.417694
#> iter  13 value 8891.762505
#> iter  14 value 8884.444598
#> iter  15 value 8861.054776
#> iter  16 value 8860.535407
#> iter  17 value 8856.284035
#> iter  18 value 8841.861792
#> iter  19 value 8802.427472
#> iter  20 value 8787.058697
#> iter  21 value 8749.511283
#> iter  22 value 8689.112051
#> iter  23 value 8682.724958
#> iter  24 value 8676.175820
#> iter  25 value 8670.648359
#> iter  26 value 8644.729215
#> iter  27 value 8622.755948
#> iter  28 value 8612.789550
#> iter  29 value 8602.489948
#> iter  30 value 8583.983131
#> iter  31 value 8581.801208
#> iter  32 value 8563.945825
#> iter  33 value 8548.627139
#> iter  34 value 8540.672875
#> iter  35 value 8538.162604
#> iter  36 value 8535.027188
#> iter  37 value 8533.760348
#> iter  38 value 8531.406171
#> iter  39 value 8531.257026
#> iter  40 value 8530.394562
#> iter  41 value 8530.082376
#> iter  42 value 8529.800045
#> iter  43 value 8529.677807
#> iter  44 value 8529.653000
#> iter  45 value 8529.648380
#> iter  46 value 8529.647935
#> iter  46 value 8529.647883
#> iter  47 value 8529.647173
#> iter  48 value 8529.646934
#> iter  48 value 8529.646924
#> iter  48 value 8529.646917
#> final  value 8529.646917 
#> converged
#> Starting Values
#> 0.20.20.20.20.2-500-0.942973425273998000.166785556197535001.4045182259602800-500
#> 
#> Likelihood
#> initial  value 10812.940044 
#> iter   2 value 10068.443848
#> iter   3 value 10058.144107
#> iter   4 value 10036.187036
#> iter   5 value 9834.899792
#> iter   6 value 9182.395578
#> iter   7 value 9086.542650
#> iter   8 value 8960.369949
#> iter   9 value 8957.421335
#> iter  10 value 8955.314342
#> iter  11 value 8945.711717
#> iter  12 value 8942.562532
#> iter  13 value 8786.165828
#> iter  14 value 8743.270149
#> iter  15 value 8702.895117
#> iter  16 value 8696.866127
#> iter  17 value 8630.095693
#> iter  18 value 8629.254238
#> iter  19 value 8606.937714
#> iter  20 value 8593.852582
#> iter  21 value 8593.102524
#> iter  22 value 8584.368738
#> iter  23 value 8553.667352
#> iter  24 value 8547.219857
#> iter  25 value 8540.141701
#> iter  26 value 8538.576846
#> iter  27 value 8533.078268
#> iter  28 value 8531.144563
#> iter  29 value 8530.119368
#> iter  30 value 8529.692493
#> iter  31 value 8529.633005
#> iter  32 value 8529.613447
#> iter  33 value 8529.607527
#> iter  34 value 8529.605189
#> iter  35 value 8529.604122
#> iter  36 value 8529.602856
#> iter  37 value 8529.599269
#> iter  38 value 8529.586038
#> iter  39 value 8529.578910
#> iter  40 value 8529.570747
#> iter  41 value 8529.560051
#> iter  42 value 8529.549428
#> iter  43 value 8529.511282
#> iter  44 value 8529.498679
#> iter  45 value 8529.490258
#> iter  46 value 8529.488627
#> iter  46 value 8529.488511
#> final  value 8529.488511 
#> converged
groups
#> <gbtm_selection> stage=n_groups  by=BIC
#>  n_groups   degrees      bic      aic   ok
#>         2       2,2 17422.92 17385.72 TRUE
#>         3     2,2,2 17452.17 17393.73 TRUE
#>         4   2,2,2,2 17168.99 17089.29 TRUE
#>         5 2,2,2,2,2 17197.93 17096.98 TRUE
#>   best: 4
```

**Stage 3 – search polynomial shapes** for the chosen number of groups,
then apply the GRoLTS acceptance criteria (PMS \> 0.05, APPA \> 0.70,
OCC \>= 5). (The one-call pipeline above searched up to cubic; here we
cap the search at quadratic to keep the vignette quick.)

``` r

shapes <- evaluate_shapes(spec, n_groups = groups$best, method = "L",
                          max_degree = 2, verbose = FALSE)
#> Starting Values
#> 0.250.250.250.25-50-0.47756445827387600.8490727400115340-50
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
#> 0.250.250.250.25-500-0.477564458273876000.8490727400115340-50
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
#> 0.250.250.250.25-500-0.477564458273876000.84907274001153400-50
#> 
#> Likelihood
#> initial  value 10985.536114 
#> iter   2 value 10833.776650
#> iter   3 value 10824.139570
#> iter   4 value 10521.839475
#> iter   5 value 10053.305042
#> iter   6 value 9800.174219
#> iter   7 value 9798.461093
#> iter   8 value 9781.453435
#> iter   9 value 9188.989839
#> iter  10 value 9140.049751
#> iter  11 value 9117.459484
#> iter  12 value 9086.191293
#> iter  13 value 8868.460923
#> iter  14 value 8837.344627
#> iter  15 value 8810.409589
#> iter  16 value 8779.402555
#> iter  17 value 8770.457965
#> iter  18 value 8741.932222
#> iter  19 value 8729.370372
#> iter  20 value 8684.595205
#> iter  21 value 8655.459553
#> iter  22 value 8647.638693
#> iter  23 value 8642.606056
#> iter  24 value 8637.403816
#> iter  25 value 8635.558391
#> iter  26 value 8630.693943
#> iter  27 value 8628.935969
#> iter  28 value 8628.480809
#> iter  29 value 8628.359949
#> iter  30 value 8628.316385
#> iter  31 value 8628.314970
#> iter  32 value 8628.314608
#> iter  33 value 8628.310037
#> iter  34 value 8628.295521
#> iter  35 value 8628.287984
#> iter  36 value 8628.257315
#> iter  37 value 8628.204349
#> iter  38 value 8628.200008
#> iter  39 value 8628.183555
#> iter  40 value 8628.172342
#> iter  41 value 8628.157236
#> iter  42 value 8628.120122
#> iter  43 value 8628.113845
#> iter  44 value 8628.112862
#> iter  45 value 8628.111329
#> iter  46 value 8628.110266
#> iter  47 value 8628.109724
#> iter  47 value 8628.109620
#> iter  47 value 8628.109620
#> final  value 8628.109620 
#> converged
#> Starting Values
#> 0.250.250.250.25-500-0.477564458273876000.8490727400115340-500
#> 
#> Likelihood
#> initial  value 10985.536114 
#> iter   2 value 10956.218621
#> iter   3 value 10615.926047
#> iter   4 value 10552.099337
#> iter   5 value 10256.006422
#> iter   6 value 10238.254834
#> iter   7 value 9267.864512
#> iter   8 value 9239.162535
#> iter   9 value 9069.569418
#> iter  10 value 9032.262218
#> iter  11 value 9029.245870
#> iter  12 value 9026.987132
#> iter  13 value 8967.858934
#> iter  14 value 8908.531675
#> iter  15 value 8893.048120
#> iter  16 value 8884.042394
#> iter  17 value 8873.824874
#> iter  18 value 8853.897104
#> iter  19 value 8825.697659
#> iter  20 value 8817.343019
#> iter  21 value 8811.947874
#> iter  22 value 8792.570568
#> iter  23 value 8770.362343
#> iter  24 value 8763.588853
#> iter  25 value 8743.107085
#> iter  26 value 8730.296589
#> iter  27 value 8700.578684
#> iter  28 value 8684.184187
#> iter  29 value 8673.697615
#> iter  30 value 8665.857168
#> iter  31 value 8647.339320
#> iter  32 value 8637.595495
#> iter  33 value 8637.409696
#> iter  34 value 8625.705673
#> iter  35 value 8621.643536
#> iter  36 value 8620.016425
#> iter  37 value 8618.980137
#> iter  38 value 8618.948213
#> iter  39 value 8618.944062
#> iter  40 value 8618.942055
#> iter  41 value 8618.729292
#> iter  42 value 8617.598338
#> iter  43 value 8615.571133
#> iter  44 value 8577.911824
#> iter  45 value 8576.406909
#> iter  46 value 8575.445144
#> iter  47 value 8574.470061
#> iter  48 value 8573.145907
#> iter  49 value 8567.400465
#> iter  50 value 8563.619895
#> iter  51 value 8553.574206
#> iter  52 value 8546.107880
#> iter  53 value 8541.995831
#> iter  54 value 8539.555889
#> iter  55 value 8535.220214
#> iter  56 value 8532.198911
#> iter  57 value 8531.638471
#> iter  58 value 8531.365941
#> iter  59 value 8531.306440
#> iter  60 value 8531.298674
#> iter  61 value 8531.293315
#> iter  62 value 8531.282124
#> iter  63 value 8531.278064
#> iter  64 value 8531.277062
#> iter  64 value 8531.276957
#> iter  64 value 8531.276957
#> final  value 8531.276957 
#> converged
#> Starting Values
#> 0.250.250.250.25-50-0.477564458273876000.8490727400115340-50
#> 
#> Likelihood
#> initial  value 10985.536114 
#> iter   2 value 10959.776864
#> iter   3 value 10822.929312
#> iter   4 value 9762.271128
#> iter   5 value 9579.681515
#> iter   6 value 9452.778477
#> iter   7 value 9374.129412
#> iter   8 value 9161.051055
#> iter   9 value 9114.493988
#> iter  10 value 9079.048039
#> iter  11 value 9024.025736
#> iter  12 value 9010.412424
#> iter  13 value 8912.310321
#> iter  14 value 8888.052978
#> iter  15 value 8868.002225
#> iter  16 value 8859.162609
#> iter  17 value 8851.187751
#> iter  18 value 8839.257703
#> iter  19 value 8825.386596
#> iter  20 value 8807.991260
#> iter  21 value 8799.212239
#> iter  22 value 8772.405277
#> iter  23 value 8761.232794
#> iter  24 value 8738.352530
#> iter  25 value 8723.094879
#> iter  26 value 8716.685771
#> iter  27 value 8716.372936
#> iter  28 value 8716.294494
#> iter  29 value 8716.229709
#> iter  30 value 8715.953320
#> iter  31 value 8715.794081
#> iter  32 value 8715.164509
#> iter  33 value 8714.080622
#> iter  34 value 8713.872458
#> iter  35 value 8713.164358
#> iter  36 value 8713.011582
#> iter  37 value 8711.432174
#> iter  38 value 8711.074658
#> iter  39 value 8709.304721
#> iter  40 value 8707.738641
#> iter  41 value 8707.505187
#> iter  42 value 8707.408390
#> iter  43 value 8707.290487
#> iter  44 value 8707.049550
#> iter  45 value 8706.539836
#> iter  46 value 8705.960598
#> iter  47 value 8705.586958
#> iter  48 value 8699.981182
#> iter  49 value 8699.957505
#> iter  50 value 8699.928620
#> iter  51 value 8699.855753
#> iter  52 value 8699.783651
#> iter  53 value 8699.663529
#> iter  54 value 8698.881372
#> iter  55 value 8696.696575
#> iter  56 value 8691.718450
#> iter  57 value 8690.917968
#> iter  58 value 8688.894478
#> iter  59 value 8688.813670
#> iter  60 value 8684.556440
#> iter  61 value 8681.153057
#> iter  62 value 8680.587189
#> iter  63 value 8678.921854
#> iter  64 value 8678.065392
#> iter  65 value 8677.523549
#> iter  66 value 8677.380177
#> iter  67 value 8677.356672
#> iter  68 value 8677.353509
#> iter  69 value 8677.352032
#> iter  69 value 8677.352019
#> iter  69 value 8677.352019
#> final  value 8677.352019 
#> converged
apply_grolts_criteria(shapes)
#> <gbtm_criteria> PMS>0.05, APPA>0.70, OCC>=5 | 5 shape(s) pass
#>   recommended: degrees 2,2,1,1  (BIC 17157.6, entropy 0.751)
```

**Stage 4 – fit the final model** (Hessian on, so the fit carries
standard errors) and read off the diagnostics and per-subject
assignment. Here we use the lowest-BIC shape found by the search:

``` r

fit <- fit_gbtm(spec, n_groups = groups$best, degrees = shapes$best, method = "L")
#> Starting Values
#> 0.250.250.250.25-500-0.477564458273876000.8490727400115340-50
#> 
#> Likelihood
#> iter   1 value
#> 10985.536114
#> iter   2 value
#> 10985.331734
#> iter   3 value
#> 10985.127668
#> iter   4 value
#> 10985.010505
#> iter   5 value
#> 10984.893344
#> iter   6 value
#> 10984.542069
#> iter   7 value
#> 10984.190774
#> iter   8 value
#> 10983.136769
#> iter   9 value
#> 10982.082572
#> iter  10 value
#> 10978.918710
#> iter  11 value
#> 10975.752690
#> iter  12 value
#> 10966.238216
#> iter  13 value
#> 10956.691113
#> iter  14 value
#> 10927.727166
#> iter  15 value
#> 10897.908543
#> iter  16 value
#> 10794.666099
#> iter  17 value
#> 10647.516391
#> iter  18 value
#> 10179.636614
#> iter  19 value
#> 10123.476062
#> iter  20 value
#> 10002.827146
#> iter  21 value
#> 9597.290712
#> iter  22 value
#> 9443.173886
#> iter  23 value
#> 9378.745654
#> iter  24 value
#> 9308.930144
#> iter  25 value
#> 9219.750637
#> iter  26 value
#> 9211.882660
#> iter  27 value
#> 9091.445003
#> iter  28 value
#> 9053.909678
#> iter  29 value
#> 9024.762552
#> iter  30 value
#> 9009.793130
#> iter  31 value
#> 8976.123521
#> iter  32 value
#> 8875.119552
#> iter  33 value
#> 8814.319512
#> iter  34 value
#> 8797.009834
#> iter  35 value
#> 8773.170208
#> iter  36 value
#> 8742.915098
#> iter  37 value
#> 8723.504277
#> iter  38 value
#> 8691.647235
#> iter  39 value
#> 8660.101668
#> iter  40 value
#> 8627.112143
#> iter  41 value
#> 8598.905637
#> iter  42 value
#> 8579.870250
#> iter  43 value
#> 8563.957831
#> iter  44 value
#> 8557.453427
#> iter  45 value
#> 8550.614674
#> iter  46 value
#> 8547.488226
#> iter  47 value
#> 8544.636619
#> iter  48 value
#> 8541.916709
#> iter  49 value
#> 8536.955007
#> iter  50 value
#> 8532.916919
#> iter  51 value
#> 8531.937623
#> iter  52 value
#> 8531.498429
#> iter  53 value
#> 8531.332062
#> iter  54 value
#> 8531.292911
#> iter  55 value
#> 8531.288307
#> iter  56 value
#> 8531.284901
#> iter  57 value
#> 8531.282957
#> iter  58 value
#> 8531.282111
#> iter  59 value
#> 8531.281920
#> iter  60 value
#> 8531.281882
#> iter  61 value
#> 8531.281876
#> iter  62 value
#> 8531.281875
#> iter  63 value
#> 8531.281875
#> iter  64 value
#> 8531.281875
#> iter  65 value
#> 8531.281875
gbtm_diagnostics(fit)
#> <gbtm_diagnostics> groups=4  n=1500  entropy=0.751
#>   BIC=17157.64  AIC=17088.56  logLik=-8531.28
#>  group n_assigned prop_assigned prop_model mismatch  appa    occ
#>      1        292         0.195      0.220    0.026 0.872 24.154
#>      2        290         0.193      0.207    0.014 0.867 24.913
#>      3        582         0.388      0.366   -0.022 0.894 14.680
#>      4        336         0.224      0.207   -0.017 0.869 25.385
head(gbtm_assign(fit))
#>   id group          p1           p2           p3           p4
#> 1  1     3 0.068521671 4.383471e-04 9.310400e-01 3.874438e-09
#> 2  2     4 0.006976608 5.761475e-02 4.597203e-08 9.354086e-01
#> 3  3     3 0.055095186 6.591159e-05 9.448389e-01 3.652011e-10
#> 4  4     4 0.006236484 5.497547e-02 3.255112e-08 9.387880e-01
#> 5  5     2 0.003693902 9.832119e-01 2.924786e-05 1.306498e-02
#> 6  6     3 0.068865465 1.503809e-04 9.309842e-01 1.180727e-09
```

## Continuous outcomes

The same pipeline handles continuous outcomes: switch the family to
`"gaussian"` (mapped to a censored-normal model) and point the spec at a
continuous dataset. `sim_continuous` has the same four shape types on a
continuous scale.

We fit cubic shapes in all four groups (in a real analysis the shape
search refines the per-group degrees, as above). Shape misspecification
can push a fit into a degenerate local optimum where a group ends up
empty – on this data, forcing *linear* shapes (`degrees = rep(1, 4)`)
with the `"L"` optimizer does exactly that. If it happens,
[`plot_trajectories()`](https://fabregithub.github.io/gbtmkit/reference/plot_trajectories.md)
/
[`gbtm_predict()`](https://fabregithub.github.io/gbtmkit/reference/gbtm_predict.md)
warn you; switching the method (`"EM"` recovers all four groups here) or
revisiting the shapes fixes it.

``` r

data("sim_continuous", package = "gbtmkit")
cspec <- gbtm_spec(
  sim_continuous,
  outcomes = paste0("y", 1:10),
  time     = paste0("t", 1:10),
  id       = "id",
  family   = "gaussian"
)
cfit <- fit_gbtm(cspec, n_groups = 4, degrees = rep(3, 4), method = "L")
#> Starting Values
#> 0.250.250.250.2518.949347908300400022.606815498125400025.409266168541200029.06673375836620004.397527404569394.397527404569394.397527404569394.39752740456939
#> 
#> Likelihood
#> iter   1 value
#> 34136.544152
#> iter   2 value
#> 34136.264353
#> iter   3 value
#> 34135.984555
#> iter   4 value
#> 34135.146767
#> iter   5 value
#> 34134.308962
#> iter   6 value
#> 34131.795440
#> iter   7 value
#> 34129.281764
#> iter   8 value
#> 34121.739860
#> iter   9 value
#> 34114.196756
#> iter  10 value
#> 34091.561667
#> iter  11 value
#> 34068.920914
#> iter  12 value
#> 34001.003238
#> iter  13 value
#> 33933.173057
#> iter  14 value
#> 33882.319885
#> iter  15 value
#> 33825.105811
#> iter  16 value
#> 33640.758820
#> iter  17 value
#> 33477.005851
#> iter  18 value
#> 33393.543450
#> iter  19 value
#> 33369.186613
#> iter  20 value
#> 33330.969986
#> iter  21 value
#> 33292.905433
#> iter  22 value
#> 33192.394216
#> iter  23 value
#> 33091.545802
#> iter  24 value
#> 32787.750212
#> iter  25 value
#> 32484.377826
#> iter  26 value
#> 31622.718648
#> iter  27 value
#> 31206.410252
#> iter  28 value
#> 30881.189330
#> iter  29 value
#> 30788.271576
#> iter  30 value
#> 30720.656534
#> iter  31 value
#> 30639.747902
#> iter  32 value
#> 30617.407328
#> iter  33 value
#> 30535.627841
#> iter  34 value
#> 30490.318552
#> iter  35 value
#> 30418.445707
#> iter  36 value
#> 30166.956203
#> iter  37 value
#> 30029.206088
#> iter  38 value
#> 29894.368301
#> iter  39 value
#> 29699.687125
#> iter  40 value
#> 29561.983215
#> iter  41 value
#> 29368.354416
#> iter  42 value
#> 29254.717398
#> iter  43 value
#> 29059.991407
#> iter  44 value
#> 28989.907560
#> iter  45 value
#> 28817.422391
#> iter  46 value
#> 28772.722331
#> iter  47 value
#> 28656.495997
#> iter  48 value
#> 28507.779426
#> iter  49 value
#> 28316.996142
#> iter  50 value
#> 28090.097269
#> iter  51 value
#> 27908.204802
#> iter  52 value
#> 27719.015073
#> iter  53 value
#> 27542.603382
#> iter  54 value
#> 27396.576916
#> iter  55 value
#> 27325.652118
#> iter  56 value
#> 27119.737988
#> iter  57 value
#> 26964.143435
#> iter  58 value
#> 26838.015868
#> iter  59 value
#> 26555.532371
#> iter  60 value
#> 26305.050124
#> iter  61 value
#> 26176.696080
#> iter  62 value
#> 25919.504147
#> iter  63 value
#> 25681.857705
#> iter  64 value
#> 25472.867990
#> iter  65 value
#> 25274.695508
#> iter  66 value
#> 25056.844315
#> iter  67 value
#> 24907.421714
#> iter  68 value
#> 24689.146913
#> iter  69 value
#> 24442.026940
#> iter  70 value
#> 24209.063884
#> iter  71 value
#> 24099.740359
#> iter  72 value
#> 24079.729813
#> iter  73 value
#> 23946.222389
#> iter  74 value
#> 23892.442519
#> iter  75 value
#> 23748.814414
#> iter  76 value
#> 23643.805534
#> iter  77 value
#> 23562.461836
#> iter  78 value
#> 23541.639722
#> iter  79 value
#> 23525.619610
#> iter  80 value
#> 23522.790468
#> iter  81 value
#> 23521.458110
#> iter  82 value
#> 23521.222756
#> iter  83 value
#> 23521.159523
#> iter  84 value
#> 23521.143017
#> iter  85 value
#> 23521.137376
#> iter  86 value
#> 23521.136350
#> iter  87 value
#> 23521.136272
#> iter  88 value
#> 23521.136269
#> iter  89 value
#> 23521.136269
#> iter  90 value
#> 23521.136269
#> iter  91 value
#> 23521.136269
gbtm_diagnostics(cfit)$entropy
#> [1] 1
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
