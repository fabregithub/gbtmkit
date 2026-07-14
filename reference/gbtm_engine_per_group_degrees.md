# Does an engine support per-group polynomial degrees?

trajeR and the native gbtmkit engine fit a separate polynomial order per
group. flexmix and lcmm fit one model formula shared by all
components/classes, so the degree is uniform across groups;
[`evaluate_shapes()`](https://fabregithub.github.io/gbtmkit/reference/evaluate_shapes.md)
then sweeps uniform shapes instead of per-group combinations.

## Usage

``` r
gbtm_engine_per_group_degrees(engine = gbtm_engines())
```

## Arguments

- engine:

  Engine name; see
  [`gbtm_engines()`](https://fabregithub.github.io/gbtmkit/reference/gbtm_engines.md).

## Value

`TRUE` if `degrees` may differ across groups, `FALSE` otherwise.
