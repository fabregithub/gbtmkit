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
spec <- gbtm_spec(sim_binary, paste0("y", 1:10),
                  paste0("t", 1:10), id = "id", family = "binomial")
sh <- evaluate_shapes(spec, n_groups = 4, verbose = FALSE)
apply_grolts_criteria(sh)
# }
```
