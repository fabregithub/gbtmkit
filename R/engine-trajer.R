# =============================================================================
# trajeR adapter.
#
# Translates a `gbtm_spec` into a trajeR::trajeR() call and wraps the result in
# a `gbtm_fit_trajer` object, then implements the engine-agnostic accessors for
# that class. trajeR is an optional dependency (Suggests): this file only runs
# when the user actually fits with engine = "trajeR".
# =============================================================================

# Neutral family -> trajeR Model string.
.trajer_model <- c(
  binomial = "LOGIT",
  gaussian = "CNORM",
  poisson  = "POIS",
  beta     = "BETA"
)

# Fit and wrap. Called via gbtm_fit(spec, engine = "trajeR", ...).
.fit_trajer <- function(spec, n_groups, degrees, method = NULL,
                        hessian = FALSE, itermax = 100L, seed = NULL, ...) {
  if (!requireNamespace("trajeR", quietly = TRUE)) {
    stop("engine 'trajeR' requires the 'trajeR' package to be installed.",
         call. = FALSE)
  }
  n_groups <- as.integer(n_groups)
  if (length(n_groups) != 1L || is.na(n_groups) || n_groups < 1L) {
    stop("`n_groups` must be a single positive integer.", call. = FALSE)
  }
  if (length(degrees) != n_groups) {
    stop(sprintf("`degrees` must have length n_groups (%d); got %d.",
                 n_groups, length(degrees)), call. = FALSE)
  }
  degrees <- as.integer(degrees)
  if (anyNA(degrees) || any(degrees < 0L)) {
    stop("`degrees` must be non-negative integers.", call. = FALSE)
  }

  method <- if (is.null(method)) "L" else method
  methods_ok <- gbtm_engine_methods("trajeR")
  if (!method %in% methods_ok) {
    stop(sprintf("method '%s' not supported by trajeR; choose one of %s.",
                 method, paste(methods_ok, collapse = ", ")), call. = FALSE)
  }

  model <- unname(.trajer_model[[spec$family]])
  Y <- .spec_Y(spec)
  A <- .spec_A(spec)

  args <- list(
    Y = Y, A = A, ng = n_groups, degre = degrees,
    Model = model, Method = method,
    hessian = hessian, itermax = as.integer(itermax)
  )
  # Continuous (CNORM) options.
  if (spec$family == "gaussian") {
    args$ssigma <- isTRUE(spec$ssigma)
    if (!is.null(spec$ymin)) args$ymin <- spec$ymin
    if (!is.null(spec$ymax)) args$ymax <- spec$ymax
  }
  args <- utils::modifyList(args, list(...))

  if (!is.null(seed)) set.seed(seed)
  raw <- do.call(trajeR::trajeR, args)

  structure(
    list(
      engine   = "trajeR",
      family   = spec$family,
      model    = model,
      method   = method,
      n_groups = n_groups,
      degrees  = degrees,
      hessian  = hessian,
      raw      = raw,
      spec     = spec
    ),
    class = c("gbtm_fit_trajer", "gbtm_fit")
  )
}

# --- accessors ---------------------------------------------------------------

#' @export
gbtm_bic.gbtm_fit_trajer <- function(fit, ...) {
  as.numeric(trajeR::trajeRBIC(fit$raw))
}

#' @export
gbtm_aic.gbtm_fit_trajer <- function(fit, ...) {
  as.numeric(trajeR::trajeRAIC(fit$raw))
}

#' @export
gbtm_loglik.gbtm_fit_trajer <- function(fit, ...) {
  as.numeric(fit$raw$Likelihood)
}

#' @export
gbtm_posterior.gbtm_fit_trajer <- function(fit, ...) {
  gp <- trajeR::GroupProb(fit$raw,
                          Y = .spec_Y(fit$spec),
                          A = .spec_A(fit$spec))
  gp <- as.matrix(as.data.frame(gp))
  dimnames(gp) <- list(NULL, paste0("group", seq_len(ncol(gp))))
  gp
}

#' @export
gbtm_group_sizes.gbtm_fit_trajer <- function(fit, ...) {
  theta <- fit$raw$theta
  # Model-implied group proportions: softmax of the membership logits.
  if (is.numeric(theta) && length(theta) == fit$n_groups) {
    sizes <- .softmax(theta)
  } else {
    # Fallback: mean posterior probability per group.
    sizes <- colMeans(gbtm_posterior(fit))
  }
  sizes <- as.numeric(sizes)
  names(sizes) <- paste0("group", seq_len(fit$n_groups))
  sizes
}

#' @export
gbtm_predict.gbtm_fit_trajer <- function(fit, times = NULL, n = 100L, ...) {
  .warn_empty_groups(fit)
  degre <- as.integer(fit$raw$degre)
  beta  <- as.numeric(fit$raw$beta)
  K     <- fit$n_groups
  A     <- .spec_A(fit$spec)
  if (is.null(times)) times <- seq(min(A), max(A), length.out = n)

  # Inverse link mapping the polynomial predictor back to the outcome scale.
  inv_link <- switch(fit$family,
    binomial = stats::plogis,
    beta     = stats::plogis,
    poisson  = exp,
    gaussian = function(x) x
  )

  idx <- 1L
  out <- vector("list", K)
  for (k in seq_len(K)) {
    nc <- degre[k] + 1L
    b  <- beta[idx:(idx + nc - 1L)]
    idx <- idx + nc
    eta <- vapply(times, function(t) sum(b * t^(0:(nc - 1L))), numeric(1))
    out[[k]] <- data.frame(group = k, time = times, fitted = inv_link(eta))
  }
  do.call(rbind, out)
}
