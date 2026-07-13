# Map a pipeline result onto the GRoLTS checklist

Produces a per-item reporting aid for the GRoLTS checklist (Guidelines
for Reporting on Latent Trajectory Studies; van de Schoot et al. 2017,
[doi:10.1080/10705511.2016.1247646](https://doi.org/10.1080/10705511.2016.1247646)
) from a
[`run_gbtm_pipeline()`](https://fabregithub.github.io/gbtmkit/reference/run_gbtm_pipeline.md)
result. Items the pipeline can answer – time metric, software, shape
search, starts and iterations, selection tools, class sizes, entropy –
are filled in automatically; items that require knowledge the pipeline
cannot have (missing-data mechanism, what appears in the manuscript,
syntax availability) are flagged for the analyst, with whatever context
the result can contribute.

## Usage

``` r
grolts_report(result, file = NULL)
```

## Arguments

- result:

  A `gbtm_result` from
  [`run_gbtm_pipeline()`](https://fabregithub.github.io/gbtmkit/reference/run_gbtm_pipeline.md).

- file:

  Optional path; when supplied, the report is also written there as
  Markdown (for a supplementary-material appendix).

## Value

An object of class `gbtm_grolts_report`: a data frame with columns
`item`, `topic`, `status` (`"auto"`, `"partial"`, `"analyst"`), and
`detail`.

## Details

Item wording is paraphrased; see the paper for the authoritative
checklist.

## See also

[`apply_grolts_criteria()`](https://fabregithub.github.io/gbtmkit/reference/apply_grolts_criteria.md),
[`gbtm_diagnostics()`](https://fabregithub.github.io/gbtmkit/reference/gbtm_diagnostics.md)

## Examples

``` r
# \donttest{
data("sim_binary", package = "gbtmkit")
spec <- gbtm_spec(sim_binary, paste0("y", 1:10),
                  paste0("t", 1:10), id = "id", family = "binomial")
if (requireNamespace("trajeR", quietly = TRUE)) {
  res <- run_gbtm_pipeline(spec, candidates = 2:5, method = "L",
                           seed = 1, verbose = FALSE)
  grolts_report(res)
}
# }
```
