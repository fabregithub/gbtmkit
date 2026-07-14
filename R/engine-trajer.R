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

# Data-driven random starting values for one multi-start attempt: partition
# the subjects with k-means on their outcome vectors (RNG-dependent, so each
# attempt differs), then fit a per-cluster polynomial regression for the
# trajectory coefficients. trajeR's default initialisation is deterministic
# (quantile-based, seed-independent), so this is what makes n_starts > 1
# explore different basins. Layout of the returned `paraminit` (per trajeR
# source): the first ng entries are group-membership logits vs group 1 for
# Method "L", but plain probabilities for "EM"/"EMIRLS"; then the per-group
# trajectory coefficients; then (CNORM only) the per-group residual sd.
.trajer_kmeans_start <- function(spec, n_groups, degrees, method) {
  Y <- .spec_Y(spec)
  A <- .spec_A(spec)
  Yk <- Y
  if (anyNA(Yk)) {                     # impute column means for clustering only
    for (j in seq_len(ncol(Yk))) {
      Yk[is.na(Yk[, j]), j] <- mean(Yk[, j], na.rm = TRUE)
    }
  }
  cl <- stats::kmeans(Yk, centers = n_groups, nstart = 1)$cluster

  b <- c()
  sig <- c()
  for (k in seq_len(n_groups)) {
    yk <- as.vector(Y[cl == k, , drop = FALSE])
    tk <- as.vector(A[cl == k, , drop = FALSE])
    if (spec$family == "binomial") {
      co <- stats::coef(suppressWarnings(
        stats::glm(yk ~ poly(tk, degrees[k], raw = TRUE),
                   family = stats::binomial())))
      co[!is.finite(co)] <- 0
      b <- c(b, pmax(pmin(co, 5), -5))   # clamp separable-cluster extremes
    } else {
      fit <- stats::lm(yk ~ poly(tk, degrees[k], raw = TRUE))
      b <- c(b, stats::coef(fit))
      sig <- c(sig, stats::sd(stats::resid(fit)))
    }
  }

  pr <- tabulate(cl, n_groups) / length(cl)
  X  <- .spec_X(spec)
  first <- if (is.null(X)) {
    if (method == "L") log(pr / pr[1]) else pr
  } else {
    # With membership covariates theta is group-major blocks of
    # (intercept, covariate effects); start the effects at zero. Only reached
    # for Method "L" (see the guard in .fit_trajer).
    unlist(lapply(seq_len(n_groups), function(k) {
      c(log(pr[k] / pr[1]), rep(0, ncol(X)))
    }))
  }
  # Time-varying covariate effects (delta, per group) sit at the end of
  # trajeR's parameter vector; start them at zero.
  delta0 <- rep(0, n_groups * length(spec$tcov))
  c(first, b, sig, delta0)
}

# Fit and wrap. Called via gbtm_fit(spec, engine = "trajeR", ...).
.fit_trajer <- function(spec, n_groups, degrees, method = NULL,
                        hessian = FALSE, itermax = 100L, seed = NULL,
                        n_starts = 1L, ...) {
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
  # Class-membership covariates (multinomial "risk factor" model).
  X <- .spec_X(spec)
  if (!is.null(X)) args$Risk <- X
  # Time-varying (trajectory) covariates, covariate-major wide blocks.
  TC <- .spec_TCOV(spec)
  if (!is.null(TC)) args$TCOV <- TC
  # Continuous (CNORM) options.
  if (spec$family == "gaussian") {
    args$ssigma <- isTRUE(spec$ssigma)
    if (!is.null(spec$ymin)) args$ymin <- spec$ymin
    if (!is.null(spec$ymax)) args$ymax <- spec$ymax
  }
  args <- utils::modifyList(args, list(...))

  if (n_starts > 1L && !spec$family %in% c("binomial", "gaussian")) {
    warning(sprintf(
      "multi-start is not implemented for family '%s' with engine 'trajeR'; using the default initialisation.",
      spec$family), call. = FALSE)
    n_starts <- 1L
  }
  if (n_starts > 1L && !is.null(X) && method != "L") {
    # trajeR's user-supplied-paraminit path is only well-defined for Method
    # "L" when a Risk model is present.
    warning("multi-start with membership covariates is only supported for method 'L' with engine 'trajeR'; using the default initialisation.",
            call. = FALSE)
    n_starts <- 1L
  }

  # Start 1: trajeR's default (deterministic) initialisation. Further starts
  # use k-means partition starting values; the best finite BIC wins. The
  # starts are independent, so they run through .fit_map (parallel under a
  # future::plan()); per-start seeding keeps results identical to sequential.
  runs <- .fit_map(seq_len(n_starts), function(s) {
    a <- args
    if (s == 1L) {
      if (!is.null(seed)) set.seed(seed)
    } else {
      set.seed((if (is.null(seed)) 0L else seed) + s - 1L)
      a$paraminit <- .trajer_kmeans_start(spec, n_groups, degrees, method)
    }
    tryCatch(do.call(trajeR::trajeR, a), error = function(e) e)
  })
  # A failure of the default initialisation is a real error, not a bad start.
  if (inherits(runs[[1L]], "error")) stop(runs[[1L]])
  start_bics <- vapply(runs, function(r) {
    if (inherits(r, "error")) NA_real_ else
      tryCatch(as.numeric(trajeR::trajeRBIC(r)), error = function(e) NA_real_)
  }, numeric(1))
  best <- which.min(start_bics)
  if (!length(best)) {
    stop("no trajeR start produced a finite BIC.", call. = FALSE)
  }
  raw <- runs[[best]]

  structure(
    list(
      engine     = "trajeR",
      family     = spec$family,
      model      = model,
      method     = method,
      n_groups   = n_groups,
      degrees    = degrees,
      hessian    = hessian,
      itermax    = as.integer(itermax),
      n_starts   = n_starts,
      start_bics = start_bics,
      raw        = raw,
      spec       = spec
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
  # TCOV and X (membership covariates) must be passed again or GroupProb
  # evaluates the wrong likelihood/priors.
  args <- list(fit$raw, Y = .spec_Y(fit$spec), A = .spec_A(fit$spec))
  TC <- .spec_TCOV(fit$spec)
  if (!is.null(TC)) args$TCOV <- TC
  X <- .spec_X(fit$spec)
  if (!is.null(X)) args$X <- X
  gp <- do.call(trajeR::GroupProb, args)
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
