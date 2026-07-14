# Fit a group-based trajectory model

Dispatches to the adapter for `engine`, returning a `gbtm_fit` object
that the rest of the pipeline reads through the engine-agnostic
accessors
([`gbtm_bic()`](https://fabregithub.github.io/gbtmkit/reference/gbtm_accessors.md),
[`gbtm_posterior()`](https://fabregithub.github.io/gbtmkit/reference/gbtm_accessors.md),
[`gbtm_group_sizes()`](https://fabregithub.github.io/gbtmkit/reference/gbtm_accessors.md),
...).

## Usage

``` r
gbtm_fit(
  spec,
  engine = gbtm_engines(),
  n_groups,
  degrees,
  method = NULL,
  hessian = FALSE,
  itermax = 100L,
  seed = NULL,
  n_starts = 1L,
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

  Number of latent groups.

- degrees:

  Integer vector of polynomial degrees, length `n_groups`.

- method:

  Estimation method; must be one of
  [`gbtm_engine_methods()`](https://fabregithub.github.io/gbtmkit/reference/gbtm_engine_methods.md)
  for the chosen engine (ignored by engines with a single optimizer).

- hessian:

  Logical; compute the Hessian (standard errors). Default `FALSE` for
  speed during model search – set `TRUE` for the final model.

- itermax:

  Maximum optimizer iterations.

- seed:

  Optional integer seed for reproducibility.

- n_starts:

  Number of initializations to try; the best fit by BIC is kept. The
  first start is the engine's default initialization; additional starts
  are engine-specific (trajeR and the native gbtmkit engine: k-means
  partition starting values; flexmix: fresh random EM initializations;
  lcmm:
  [`lcmm::gridsearch()`](https://cecileproust-lima.github.io/lcmm/reference/gridsearch.html)).
  Mixture fits can land in local optima – empty or merged groups are the
  telltale sign – and `n_starts` greater than 1 is the standard defense.
  Independent starts run in parallel under a
  [`future::plan()`](https://future.futureverse.org/reference/plan.html)
  when the future.apply package is installed; with a `seed`, results are
  identical under any plan.

- ...:

  Passed on to the underlying engine call.

## Value

A `gbtm_fit` object (subclassed per engine).
