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
spec <- gbtm_spec(sim_binary, paste0("y", 1:10),
                  paste0("t", 1:10), id = "id", family = "binomial")
if (requireNamespace("trajeR", quietly = TRUE))
  select_algorithm(spec, n_groups = 4, degrees = rep(1, 4))
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
#> 0.250.250.250.25-50-0.47756445827387600.8490727400115340-50
#> 
#> 
#> Likelihood
#> iter   1 value 10985.536114
#> iter   2 value 9104.114901
#> iter   3 value 8925.742983
#> iter   4 value 8898.032817
#> iter   5 value 8877.179941
#> iter   6 value 8860.459661
#> iter   7 value 8846.616441
#> iter   8 value 8835.073437
#> iter   9 value 8825.545853
#> iter  10 value 8817.808709
#> iter  11 value 8811.614312
#> iter  12 value 8806.700424
#> iter  13 value 8802.819327
#> iter  14 value 8799.755923
#> iter  15 value 8797.333399
#> iter  16 value 8795.411157
#> iter  17 value 8793.879465
#> iter  18 value 8792.653463
#> iter  19 value 8791.667731
#> iter  20 value 8790.871731
#> iter  21 value 8790.226353
#> iter  22 value 8789.701160
#> iter  23 value 8789.272338
#> iter  24 value 8788.921150
#> iter  25 value 8788.632765
#> iter  26 value 8788.395386
#> iter  27 value 8788.199575
#> iter  28 value 8788.037749
#> iter  29 value 8787.903785
#> iter  30 value 8787.792722
#> iter  31 value 8787.700525
#> iter  32 value 8787.623900
#> iter  33 value 8787.560152
#> iter  34 value 8787.507067
#> iter  35 value 8787.462826
#> iter  36 value 8787.433794
#> iter  37 value 8787.422019
#> iter  38 value 8787.417336
#> iter  39 value 8787.378665
#> iter  40 value 8787.369886
#> iter  41 value 8787.355942
#> iter  42 value 8787.351804
#> iter  43 value 8787.334926
#> iter  44 value 8787.322280
#> iter  45 value 8787.318759
#> iter  46 value 8787.317359
#> iter  47 value 8787.310673
#> iter  48 value 8787.308612
#> iter  49 value 8787.308416
#> iter  50 value 8787.308347
#> iter  51 value 8787.308286
#> iter  52 value 8787.308237
#> iter  53 value 8787.303529
#> iter  54 value 8787.303136
#> iter  55 value 8787.290794
#> iter  56 value 8787.287296
#> iter  57 value 8787.286996
#> iter  58 value 8787.286936
#> iter  59 value 8787.286884
#> iter  60 value 8787.286840
#> iter  61 value 8787.286788
#> iter  62 value 8787.286764
#> iter  63 value 8787.286700
#> iter  64 value 8787.284064
#> iter  65 value 8787.281932
#> iter  66 value 8787.281769
#> iter  67 value 8787.280054
#> iter  68 value 8787.279896
#> iter  69 value 8787.279855
#> iter  70 value 8787.278539
#> iter  71 value 8787.270697
#> iter  72 value 8787.268664
#> iter  73 value 8787.268487
#> iter  74 value 8787.268452
#> iter  75 value 8787.268406
#> iter  76 value 8787.266743
#> iter  77 value 8787.266618
#> iter  78 value 8787.266568
#> iter  79 value 8787.266525
#> iter  80 value 8787.266499
#> iter  81 value 8787.265877
#> iter  82 value 8787.265792
#> iter  83 value 8787.265726
#> iter  84 value 8787.265677
#> iter  85 value 8787.265656
#> iter  86 value 8787.265599
#> iter  87 value 8787.265560
#> iter  88 value 8787.265532
#> iter  89 value 8787.265476
#> iter  90 value 8787.265434
#> iter  91 value 8787.265405
#> iter  92 value 8787.265355
#> iter  93 value 8787.265339
#> iter  94 value 8787.265286
#> iter  95 value 8787.265252
#> iter  96 value 8787.265217
#> iter  97 value 8787.264920
#> iter  98 value 8787.264871
#> iter  99 value 8787.264744
#> Starting Values
#> 0.250.250.250.25-50-0.47756445827387600.8490727400115340-50
#> 
#> 
#> Likelihood
#> iter   1 value 10985.536114
#> Warning: method 'EMIRLS' did not yield a finite criterion: solve(): solution not found.
#> <gbtm_selection> stage=algorithm  by=BIC
#>  method      bic      aic    ok
#>       L 17637.33 17578.88  TRUE
#>      EM 33328.63 33270.18  TRUE
#>  EMIRLS       NA       NA FALSE
#>   best: L
# }
```
