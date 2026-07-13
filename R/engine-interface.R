# =============================================================================
# Engine-agnostic interface.
#
# The pipeline never calls an estimation package directly. It calls `gbtm_fit()`
# to obtain a `gbtm_fit` object, then reads everything it needs through a small
# set of S3 generics defined here. Each backend (trajeR, flexmix, lcmm)
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
  c("trajeR", "flexmix", "lcmm")
}

#' Outcome families supported by an engine
#'
#' @param engine Engine name; see [gbtm_engines()].
#' @return Character vector of supported [gbtm_families()].
#' @export
gbtm_engine_families <- function(engine = gbtm_engines()) {
  engine <- match.arg(engine, gbtm_engines())
  switch(engine,
    trajeR  = c("binomial", "gaussian", "poisson", "beta"),
    flexmix = c("binomial", "gaussian", "poisson"),
    lcmm    = c("binomial", "gaussian")
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
    trajeR  = c("L", "EM", "EMIRLS"),
    flexmix = NA_character_,
    lcmm    = NA_character_
  )
}

#' Does an engine support per-group polynomial degrees?
#'
#' trajeR fits a separate polynomial order per group. flexmix and lcmm fit one
#' model formula shared by all components/classes, so the degree is uniform
#' across groups; [evaluate_shapes()] then sweeps uniform shapes instead of
#' per-group combinations.
#'
#' @param engine Engine name; see [gbtm_engines()].
#' @return `TRUE` if `degrees` may differ across groups, `FALSE` otherwise.
#' @export
gbtm_engine_per_group_degrees <- function(engine = gbtm_engines()) {
  engine <- match.arg(engine, gbtm_engines())
  switch(engine,
    trajeR  = TRUE,
    flexmix = FALSE,
    lcmm    = FALSE
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
#' @param n_starts Number of initializations to try; the best fit by BIC is
#'   kept. The first start is the engine's default initialization; additional
#'   starts are engine-specific (trajeR: k-means partition starting values;
#'   flexmix: fresh random EM initializations; lcmm: [lcmm::gridsearch()]).
#'   Mixture fits can land in local optima -- empty or merged groups are the
#'   telltale sign -- and `n_starts` greater than 1 is the standard defense.
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
                     n_starts = 1L,
                     ...) {
  if (!inherits(spec, "gbtm_spec")) {
    stop("`spec` must be a gbtm_spec (see gbtm_spec()).", call. = FALSE)
  }
  engine <- match.arg(engine, gbtm_engines())
  if (!spec$family %in% gbtm_engine_families(engine)) {
    stop(sprintf("engine '%s' does not support family '%s'.",
                 engine, spec$family), call. = FALSE)
  }
  n_starts <- as.integer(n_starts)
  if (length(n_starts) != 1L || is.na(n_starts) || n_starts < 1L) {
    stop("`n_starts` must be a single positive integer.", call. = FALSE)
  }
  switch(engine,
    trajeR  = .fit_trajer(spec, n_groups = n_groups, degrees = degrees,
                          method = method, hessian = hessian,
                          itermax = itermax, seed = seed,
                          n_starts = n_starts, ...),
    flexmix = .fit_flexmix(spec, n_groups = n_groups, degrees = degrees,
                           method = method, hessian = hessian,
                           itermax = itermax, seed = seed,
                           n_starts = n_starts, ...),
    lcmm    = .fit_lcmm(spec, n_groups = n_groups, degrees = degrees,
                        method = method, hessian = hessian,
                        itermax = itermax, seed = seed,
                        n_starts = n_starts, ...)
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
  if (!is.null(x$n_starts) && x$n_starts > 1L) {
    cat(sprintf("  starts  : %d\n", x$n_starts))
  }
  bic <- tryCatch(gbtm_bic(x), error = function(e) NA_real_)
  if (is.finite(bic)) cat(sprintf("  BIC     : %.2f\n", bic))
  invisible(x)
}

# --- shared helpers ----------------------------------------------------------

# Numerically stable softmax over a vector.
.softmax <- function(z) {
  z <- z - max(z)
  e <- exp(z)
  e / sum(e)
}

# Long-format data for engines that model subject x occasion rows (flexmix,
# lcmm): `.gid` is the subject index (1..n in spec row order). Column-major
# flattening puts the first occasion's rows first, so `!duplicated(.gid)`
# recovers spec row order. Class-membership covariates (time-stable) are
# replicated across a subject's rows.
.spec_long <- function(spec) {
  Y <- .spec_Y(spec)
  A <- .spec_A(spec)
  long <- data.frame(
    .gid = rep(seq_len(nrow(Y)), times = ncol(Y)),
    y    = as.vector(Y),
    t    = as.vector(A)
  )
  for (v in spec$covariates) {
    long[[v]] <- rep(spec$data[[v]], times = ncol(Y))
  }
  # Time-varying covariates: same column-major flattening as y/t keeps rows
  # aligned.
  for (nm in names(spec$tcov)) {
    long[[nm]] <- as.vector(as.matrix(spec$data[, spec$tcov[[nm]],
                                                drop = FALSE]))
  }
  long[stats::complete.cases(long), , drop = FALSE]
}

# Indices of groups with no hard-assigned members. An empty group is a sign of a
# degenerate fit (often a local optimum): its trajectory is unconstrained and can
# look extreme. Engine-neutral -- works off the posterior accessor.
.empty_groups <- function(fit) {
  post     <- gbtm_posterior(fit)
  assigned <- max.col(post, ties.method = "first")
  which(tabulate(assigned, nbins = ncol(post)) == 0L)
}

# Warn (once) if a fit has empty groups. Called by prediction/plotting so a
# degenerate fit announces itself rather than silently drawing a wild line.
.warn_empty_groups <- function(fit) {
  empty <- .empty_groups(fit)
  if (length(empty)) {
    warning(sprintf(
      paste0("group(s) %s have no assigned members; their fitted trajectory is ",
             "unconstrained and may look extreme. This usually indicates a ",
             "degenerate fit -- try method = \"EM\" or a different number of groups."),
      paste(empty, collapse = ", ")), call. = FALSE)
  }
  invisible(empty)
}
