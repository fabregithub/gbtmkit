# =============================================================================
# Engine-agnostic interface.
#
# The pipeline never calls an estimation package directly. It calls `gbtm_fit()`
# to obtain a `gbtm_fit` object, then reads everything it needs through a small
# set of S3 generics defined here. Each backend (trajeR, later flexmix/lcmm)
# provides an adapter that (a) knows how to fit and (b) implements these
# generics for its own fit class. This file also holds the engine registry and
# the base-class methods for fields the wrapper stores identically for every
# engine.
# =============================================================================

#' Registered estimation engines
#'
#' @return Character vector of engine names usable as the `engine` argument to
#'   [gbtm_fit()].
#' @export
gbtm_engines <- function() {
  c("trajeR")
}

#' Outcome families supported by an engine
#'
#' @param engine Engine name; see [gbtm_engines()].
#' @return Character vector of supported [gbtm_families()].
#' @export
gbtm_engine_families <- function(engine = gbtm_engines()) {
  engine <- match.arg(engine, gbtm_engines())
  switch(engine,
    trajeR = c("binomial", "gaussian", "poisson", "beta")
  )
}

#' Estimation methods offered by an engine
#'
#' Engines that expose a choice of optimizer return the available method names;
#' engines with a single fixed optimizer return `NA_character_`, which the
#' algorithm-selection stage treats as a no-op.
#'
#' @param engine Engine name; see [gbtm_engines()].
#' @return Character vector of method names, or `NA_character_`.
#' @export
gbtm_engine_methods <- function(engine = gbtm_engines()) {
  engine <- match.arg(engine, gbtm_engines())
  switch(engine,
    trajeR = c("L", "EM", "EMIRLS")
  )
}

#' Fit a group-based trajectory model
#'
#' Dispatches to the adapter for `engine`, returning a `gbtm_fit` object that the
#' rest of the pipeline reads through the engine-agnostic accessors
#' ([gbtm_bic()], [gbtm_posterior()], [gbtm_group_sizes()], ...).
#'
#' @param spec A [gbtm_spec].
#' @param engine Engine name; see [gbtm_engines()].
#' @param n_groups Number of latent groups.
#' @param degrees Integer vector of polynomial degrees, length `n_groups`.
#' @param method Estimation method; must be one of [gbtm_engine_methods()] for
#'   the chosen engine (ignored by engines with a single optimizer).
#' @param hessian Logical; compute the Hessian (standard errors). Default
#'   `FALSE` for speed during model search -- set `TRUE` for the final model.
#' @param itermax Maximum optimizer iterations.
#' @param seed Optional integer seed for reproducibility.
#' @param ... Passed on to the underlying engine call.
#' @return A `gbtm_fit` object (subclassed per engine).
#' @export
gbtm_fit <- function(spec,
                     engine = gbtm_engines(),
                     n_groups,
                     degrees,
                     method = NULL,
                     hessian = FALSE,
                     itermax = 100L,
                     seed = NULL,
                     ...) {
  if (!inherits(spec, "gbtm_spec")) {
    stop("`spec` must be a gbtm_spec (see gbtm_spec()).", call. = FALSE)
  }
  engine <- match.arg(engine, gbtm_engines())
  if (!spec$family %in% gbtm_engine_families(engine)) {
    stop(sprintf("engine '%s' does not support family '%s'.",
                 engine, spec$family), call. = FALSE)
  }
  switch(engine,
    trajeR = .fit_trajer(spec, n_groups = n_groups, degrees = degrees,
                         method = method, hessian = hessian,
                         itermax = itermax, seed = seed, ...)
  )
}

# --- Generics the pipeline relies on -----------------------------------------

#' Engine-agnostic accessors for a fitted model
#'
#' Read the quantities the pipeline needs from a [gbtm_fit] without knowing
#' which engine produced it.
#'
#' @param fit A [gbtm_fit] object.
#' @param ... Unused.
#' @return
#'   * `gbtm_bic()`, `gbtm_aic()`, `gbtm_loglik()`: a single numeric.
#'   * `gbtm_posterior()`: a subjects x groups matrix of posterior
#'     probabilities (rows sum to 1).
#'   * `gbtm_group_sizes()`: a length-`n_groups` vector of model-implied group
#'     proportions (sums to 1).
#'   * `gbtm_n_groups()`: integer number of groups.
#'   * `gbtm_degrees()`: integer vector of polynomial degrees.
#' @name gbtm_accessors
NULL

#' @rdname gbtm_accessors
#' @export
gbtm_bic <- function(fit, ...) UseMethod("gbtm_bic")

#' @rdname gbtm_accessors
#' @export
gbtm_aic <- function(fit, ...) UseMethod("gbtm_aic")

#' @rdname gbtm_accessors
#' @export
gbtm_loglik <- function(fit, ...) UseMethod("gbtm_loglik")

#' @rdname gbtm_accessors
#' @export
gbtm_posterior <- function(fit, ...) UseMethod("gbtm_posterior")

#' @rdname gbtm_accessors
#' @export
gbtm_group_sizes <- function(fit, ...) UseMethod("gbtm_group_sizes")

#' @rdname gbtm_accessors
#' @export
gbtm_n_groups <- function(fit, ...) UseMethod("gbtm_n_groups")

#' @rdname gbtm_accessors
#' @export
gbtm_degrees <- function(fit, ...) UseMethod("gbtm_degrees")

#' Fitted group trajectories over time
#'
#' Returns each group's fitted trajectory on the outcome scale (probability for
#' binomial, mean for gaussian, rate for poisson) over a grid of times, computed
#' from the model coefficients -- engine-neutral, so it drives
#' [plot_trajectories()] for any backend.
#'
#' @param fit A [gbtm_fit] object.
#' @param times Optional numeric vector of times; defaults to a grid spanning the
#'   observed range.
#' @param n Number of grid points when `times` is `NULL`.
#' @param ... Unused.
#' @return A data frame with columns `group`, `time`, and `fitted`.
#' @export
gbtm_predict <- function(fit, times = NULL, n = 100L, ...) UseMethod("gbtm_predict")

# --- Base methods: fields the wrapper stores identically for every engine ----

#' @export
gbtm_n_groups.gbtm_fit <- function(fit, ...) fit$n_groups

#' @export
gbtm_degrees.gbtm_fit <- function(fit, ...) fit$degrees

#' @export
print.gbtm_fit <- function(x, ...) {
  cat(sprintf("<gbtm_fit> engine=%s family=%s\n", x$engine, x$family))
  cat(sprintf("  groups  : %d\n", x$n_groups))
  cat(sprintf("  degrees : %s\n", paste(x$degrees, collapse = ", ")))
  if (!is.null(x$method) && !is.na(x$method)) {
    cat(sprintf("  method  : %s\n", x$method))
  }
  bic <- tryCatch(gbtm_bic(x), error = function(e) NA_real_)
  if (is.finite(bic)) cat(sprintf("  BIC     : %.2f\n", bic))
  invisible(x)
}

# --- shared helper -----------------------------------------------------------

# Numerically stable softmax over a vector.
.softmax <- function(z) {
  z <- z - max(z)
  e <- exp(z)
  e / sum(e)
}
