# Plot fitted group trajectories

Draws each group's fitted trajectory over time and, optionally, overlays
the observed mean outcome for the subjects assigned to that group at
each occasion. Requires the ggplot2 package.

## Usage

``` r
plot_trajectories(fit, observed = TRUE, n = 100L)
```

## Arguments

- fit:

  A
  [gbtm_fit](https://fabregithub.github.io/gbtmkit/reference/gbtm_fit.md)
  object.

- observed:

  Logical; overlay observed per-group occasion means (default `TRUE`).

- n:

  Number of time grid points for the fitted lines.

## Value

A ggplot2 object.

## Examples

``` r
# \donttest{
data("sim_binary", package = "gbtmkit")
spec <- gbtm_spec(sim_binary, c("y1","y2","y3","y4"),
                  c("t1","t2","t3","t4"), id = "id", family = "binomial")
if (requireNamespace("trajeR", quietly = TRUE) &&
    requireNamespace("ggplot2", quietly = TRUE)) {
  fit <- fit_gbtm(spec, n_groups = 4, degrees = c(1, 3, 3, 1), method = "L")
  plot_trajectories(fit)
}
#> Starting Values
#> 0.250.250.250.25-50-0.9489461210736970000.385655936052041000-50
#> 
#> 
#> Likelihood
#> iter   1 value 
#> 3889.644459
#> iter   2 value 
#> 3889.557561
#> iter   3 value 
#> 3889.470721
#> iter   4 value 
#> 3889.372368
#> iter   5 value 
#> 3889.274099
#> iter   6 value 
#> 3889.188985
#> iter   7 value 
#> 3889.103879
#> iter   8 value 
#> 3888.938577
#> iter   9 value 
#> 3888.773245
#> iter  10 value 
#> 3888.277059
#> iter  11 value 
#> 3887.780595
#> iter  12 value 
#> 3886.289556
#> iter  13 value 
#> 3884.796101
#> iter  14 value 
#> 3880.301921
#> iter  15 value 
#> 3875.788456
#> iter  16 value 
#> 3862.150939
#> iter  17 value 
#> 3848.407248
#> iter  18 value 
#> 3807.036260
#> iter  19 value 
#> 3766.463906
#> iter  20 value 
#> 3672.192981
#> iter  21 value 
#> 3618.714341
#> iter  22 value 
#> 3580.365761
#> iter  23 value 
#> 3524.316156
#> iter  24 value 
#> 3312.190203
#> iter  25 value 
#> 3310.030662
#> iter  26 value 
#> 3301.176701
#> iter  27 value 
#> 3281.334194
#> iter  28 value 
#> 3241.963918
#> iter  29 value 
#> 3237.742101
#> iter  30 value 
#> 3222.328020
#> iter  31 value 
#> 3208.216965
#> iter  32 value 
#> 3177.739609
#> iter  33 value 
#> 3156.177621
#> iter  34 value 
#> 3147.109072
#> iter  35 value 
#> 3145.613182
#> iter  36 value 
#> 3145.010857
#> iter  37 value 
#> 3144.760459
#> iter  38 value 
#> 3144.476248
#> iter  39 value 
#> 3144.257267
#> iter  40 value 
#> 3144.064009
#> iter  41 value 
#> 3143.894775
#> iter  42 value 
#> 3143.603016
#> iter  43 value 
#> 3143.454038
#> iter  44 value 
#> 3143.118756
#> iter  45 value 
#> 3142.796837
#> iter  46 value 
#> 3142.533523
#> iter  47 value 
#> 3141.917359
#> iter  48 value 
#> 3141.324462
#> iter  49 value 
#> 3140.594328
#> iter  50 value 
#> 3138.877312
#> iter  51 value 
#> 3136.795041
#> iter  52 value 
#> 3134.875283
#> iter  53 value 
#> 3131.691612
#> iter  54 value 
#> 3129.691132
#> iter  55 value 
#> 3128.725471
#> iter  56 value 
#> 3128.381415
#> iter  57 value 
#> 3128.311510
#> iter  58 value 
#> 3128.250190
#> iter  59 value 
#> 3128.206396
#> iter  60 value 
#> 3128.189609
#> iter  61 value 
#> 3128.186203
#> iter  62 value 
#> 3128.181534
#> iter  63 value 
#> 3128.179841
#> iter  64 value 
#> 3128.177379
#> iter  65 value 
#> 3128.173593
#> iter  66 value 
#> 3128.168742
#> iter  67 value 
#> 3128.165665
#> iter  68 value 
#> 3128.164542
#> iter  69 value 
#> 3128.164309
#> iter  70 value 
#> 3128.163992
#> iter  71 value 
#> 3128.163121
#> iter  72 value 
#> 3128.160739
#> iter  73 value 
#> 3128.153231
#> iter  74 value 
#> 3128.126839
#> iter  75 value 
#> 3128.118234
#> iter  76 value 
#> 3128.099194
#> iter  77 value 
#> 3128.065616
#> iter  78 value 
#> 3128.002885
#> iter  79 value 
#> 3127.879093
#> iter  80 value 
#> 3127.791432
#> iter  81 value 
#> 3127.785357
#> iter  82 value 
#> 3127.780316
#> iter  83 value 
#> 3127.779416
#> iter  84 value 
#> 3127.779040
#> iter  85 value 
#> 3127.778996
#> iter  86 value 
#> 3127.778964
#> iter  87 value 
#> 3127.778874
#> iter  88 value 
#> 3127.778655
#> iter  89 value 
#> 3127.778060
#> iter  90 value 
#> 3127.776423
#> iter  91 value 
#> 3127.774108
#> iter  92 value 
#> 3127.767356
#> iter  93 value 
#> 3127.763584
#> iter  94 value 
#> 3127.751748
#> iter  95 value 
#> 3127.723375
#> iter  96 value 
#> 3127.703045

# }
```
