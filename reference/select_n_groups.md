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
spec <- gbtm_spec(sim_binary, paste0("y", 1:10),
                  paste0("t", 1:10), id = "id", family = "binomial")
if (requireNamespace("trajeR", quietly = TRUE))
  select_n_groups(spec, candidates = 2:5, degree = 2)
#> Starting Values
#> 0.50.5-1.35218614405793001.9707048996239500
#> 
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
#> <gbtm_selection> stage=n_groups  by=BIC
#>  n_groups   degrees      bic      aic   ok
#>         2       2,2 17422.92 17385.72 TRUE
#>         3     2,2,2 17452.17 17393.73 TRUE
#>         4   2,2,2,2 17168.99 17089.29 TRUE
#>         5 2,2,2,2,2 17197.93 17096.98 TRUE
#>   best: 4
# }
```
