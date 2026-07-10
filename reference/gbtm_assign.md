# Hard group assignment for a fitted model

Assigns each subject to the group with the highest posterior
probability.

## Usage

``` r
gbtm_assign(fit)
```

## Arguments

- fit:

  A
  [gbtm_fit](https://fabregithub.github.io/gbtmkit/reference/gbtm_fit.md)
  object.

## Value

A data frame with `id`, the assigned `group`, and one posterior
probability column per group.

## Examples

``` r
data("sim_binary", package = "gbtmkit")
# (fit a model first, then:)  gbtm_assign(fit)
```
