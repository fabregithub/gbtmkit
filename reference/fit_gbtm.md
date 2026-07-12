# Fit the final chosen trajectory model

A thin wrapper over
[`gbtm_fit()`](https://fabregithub.github.io/gbtmkit/reference/gbtm_fit.md)
intended for the final model, once the number of groups and the
polynomial shape have been chosen. It differs only in defaulting
`hessian = TRUE`, so the result includes standard errors.

## Usage

``` r
fit_gbtm(
  spec,
  n_groups,
  degrees,
  method = NULL,
  engine = gbtm_engines(),
  hessian = TRUE,
  itermax = 100L,
  seed = NULL,
  ...
)
```

## Arguments

- spec:

  A
  [gbtm_spec](https://fabregithub.github.io/gbtmkit/reference/gbtm_spec.md).

- n_groups:

  Number of latent groups.

- degrees:

  Integer vector of polynomial degrees, length `n_groups`.

- method:

  Estimation method; must be one of
  [`gbtm_engine_methods()`](https://fabregithub.github.io/gbtmkit/reference/gbtm_engine_methods.md)
  for the chosen engine (ignored by engines with a single optimizer).

- engine:

  Engine name; see
  [`gbtm_engines()`](https://fabregithub.github.io/gbtmkit/reference/gbtm_engines.md).

- hessian:

  Logical; compute the Hessian (standard errors). Default `TRUE`.

- itermax:

  Maximum optimizer iterations.

- seed:

  Optional integer seed for reproducibility.

- ...:

  Passed on to the underlying engine call.

## Value

A
[gbtm_fit](https://fabregithub.github.io/gbtmkit/reference/gbtm_fit.md)
object.

## See also

[`gbtm_fit()`](https://fabregithub.github.io/gbtmkit/reference/gbtm_fit.md),
[`gbtm_diagnostics()`](https://fabregithub.github.io/gbtmkit/reference/gbtm_diagnostics.md),
[`gbtm_assign()`](https://fabregithub.github.io/gbtmkit/reference/gbtm_assign.md),
[`plot_trajectories()`](https://fabregithub.github.io/gbtmkit/reference/plot_trajectories.md)

## Examples

``` r
# \donttest{
data("sim_binary", package = "gbtmkit")
spec <- gbtm_spec(sim_binary, paste0("y", 1:10),
                  paste0("t", 1:10), id = "id", family = "binomial")
if (requireNamespace("trajeR", quietly = TRUE))
  fit_gbtm(spec, n_groups = 4, degrees = rep(3, 4), method = "L")
#> Starting Values
#> 0.250.250.250.25-5000-0.4775644582738760000.849072740011534000-5000
#> 
#> 
#> Likelihood
#> iter   1 value 
#> 10985.536114
#> iter   2 value 
#> 10980.527072
#> iter   3 value 
#> 10975.535925
#> iter   4 value 
#> 10974.685937
#> iter   5 value 
#> 10973.839813
#> iter   6 value 
#> 10971.285301
#> iter   7 value 
#> 10968.711717
#> iter   8 value 
#> 10960.863450
#> iter   9 value 
#> 10952.791121
#> iter  10 value 
#> 10926.639168
#> iter  11 value 
#> 10895.732083
#> iter  12 value 
#> 10744.184012
#> iter  13 value 
#> 10471.217711
#> iter  14 value 
#> 9934.991509
#> iter  15 value 
#> 9864.112200
#> iter  16 value 
#> 9763.004280
#> iter  17 value 
#> 9737.361300
#> iter  18 value 
#> 9726.034911
#> iter  19 value 
#> 9690.027590
#> iter  20 value 
#> 9646.339922
#> iter  21 value 
#> 9544.534552
#> iter  22 value 
#> 9419.809567
#> iter  23 value 
#> 9381.028379
#> iter  24 value 
#> 9313.397906
#> iter  25 value 
#> 9252.675150
#> iter  26 value 
#> 9189.781789
#> iter  27 value 
#> 9136.567943
#> iter  28 value 
#> 9045.820360
#> iter  29 value 
#> 8977.811943
#> iter  30 value 
#> 8874.187057
#> iter  31 value 
#> 8771.316424
#> iter  32 value 
#> 8742.279697
#> iter  33 value 
#> 8673.319080
#> iter  34 value 
#> 8659.350499
#> iter  35 value 
#> 8652.300622
#> iter  36 value 
#> 8643.956171
#> iter  37 value 
#> 8636.124256
#> iter  38 value 
#> 8629.061600
#> iter  39 value 
#> 8626.065296
#> iter  40 value 
#> 8625.272830
#> iter  41 value 
#> 8624.510845
#> iter  42 value 
#> 8623.880797
#> iter  43 value 
#> 8623.106647
#> iter  44 value 
#> 8622.680867
#> iter  45 value 
#> 8622.200578
#> iter  46 value 
#> 8621.512124
#> iter  47 value 
#> 8620.887735
#> iter  48 value 
#> 8619.534632
#> iter  49 value 
#> 8619.374822
#> iter  50 value 
#> 8619.061395
#> iter  51 value 
#> 8618.492287
#> iter  52 value 
#> 8618.156606
#> iter  53 value 
#> 8617.829518
#> iter  54 value 
#> 8617.825741
#> iter  55 value 
#> 8617.730425
#> iter  56 value 
#> 8617.663594
#> iter  57 value 
#> 8617.635611
#> iter  58 value 
#> 8617.632786
#> iter  59 value 
#> 8617.631976
#> iter  60 value 
#> 8617.631625
#> iter  61 value 
#> 8617.631172
#> iter  62 value 
#> 8617.630370
#> iter  63 value 
#> 8617.628977
#> iter  64 value 
#> 8617.626777
#> iter  65 value 
#> 8617.623496
#> iter  66 value 
#> 8617.618015
#> iter  67 value 
#> 8617.611577
#> iter  68 value 
#> 8617.596177
#> iter  69 value 
#> 8617.584435
#> iter  70 value 
#> 8617.561387
#> iter  71 value 
#> 8617.556829
#> iter  72 value 
#> 8617.555703
#> iter  73 value 
#> 8617.555452
#> iter  74 value 
#> 8617.555449
#> iter  75 value 
#> 8617.555448
#> iter  76 value 
#> 8617.555448
#> iter  77 value 
#> 8617.555446
#> iter  78 value 
#> 8617.555443
#> iter  79 value 
#> 8617.555433
#> iter  80 value 
#> 8617.555410
#> iter  81 value 
#> 8617.555350
#> iter  82 value 
#> 8617.555206
#> iter  83 value 
#> 8617.554876
#> iter  84 value 
#> 8617.554192
#> iter  85 value 
#> 8617.552924
#> iter  86 value 
#> 8617.551530
#> iter  87 value 
#> 8617.545324
#> iter  88 value 
#> 8617.518411
#> iter  89 value 
#> 8616.683934
#> iter  90 value 
#> 8616.596245
#> iter  91 value 
#> 8616.436956
#> iter  92 value 
#> 8616.096503
#> <gbtm_fit> engine=trajeR family=binomial
#>   groups  : 4
#>   degrees : 3, 3, 3, 3
#>   method  : L
#>   BIC     : 17371.14
# }
```
