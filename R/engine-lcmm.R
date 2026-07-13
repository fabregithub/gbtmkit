# =============================================================================
# lcmm adapter.
#
# Translates a `gbtm_spec` into an lcmm::hlme() (gaussian) or lcmm::lcmm()
# (binomial, via the thresholds link) call and wraps the result in a
# `gbtm_fit_lcmm` object, then implements the engine-agnostic accessors for
# that class. lcmm is an optional dependency (Suggests): this file only runs
# when the user actually fits with engine = "lcmm".
#
# Mapping notes (see dev/DESIGN.md sec. 4.3):
#   * GBTM = latent class growth analysis: `random = ~ -1` (no random effects)
#     with class-specific fixed effects via `mixture =`.
#   * lcmm's `mixture` formula is shared by all latent classes, so the
#     polynomial degree is uniform across groups
#     (`gbtm_engine_per_group_degrees()` returns FALSE and the shape search
#     sweeps uniform shapes only).
#   * Binary outcomes use lcmm() with `link = "thresholds"` (a 2-level ordinal
#     model, equivalent to a probit-type binary trajectory model).
#   * ng > 1 fits require starting values: the adapter first fits the 1-class
#     model and passes it as `B` -- lcmm's canonical, deterministic init.
#   * Single optimizer (Marquardt): `gbtm_engine_methods()` returns NA and the
#     algorithm-selection stage is a no-op. Standard errors always come with
#     the fit, so `hessian` is a no-op too.
# =============================================================================

# Fit and wrap. Called via gbtm_fit(spec, engine = "lcmm", ...).
.fit_lcmm <- function(spec, n_groups, degrees, method = NULL,
                      hessian = FALSE, itermax = 100L, seed = NULL,
                      n_starts = 1L, ...) {
  if (!requireNamespace("lcmm", quietly = TRUE)) {
    stop("engine 'lcmm' requires the 'lcmm' package to be installed.",
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
  if (length(unique(degrees)) != 1L) {
    stop("engine 'lcmm' fits one polynomial order shared by all groups; ",
         "`degrees` must be uniform (e.g. rep(2, n_groups)). Got: ",
         paste(degrees, collapse = ", "), ".", call. = FALSE)
  }
  if (!is.null(method) && !is.na(method)) {
    stop("engine 'lcmm' has a single optimizer (Marquardt); leave `method` unset.",
         call. = FALSE)
  }
  degree <- degrees[1L]

  long <- .spec_long(spec)
  rhs <- if (degree == 0L) "1" else sprintf("poly(t, %d, raw = TRUE)", degree)
  fixed   <- stats::as.formula(paste("y ~", rhs))
  mixture <- stats::as.formula(paste("~", rhs))

  fitter <- switch(spec$family,
    gaussian = function(ng, ...) {
      lcmm::hlme(fixed = fixed, random = ~ -1, subject = ".gid",
                 ng = ng, data = long, maxiter = as.integer(itermax),
                 verbose = FALSE, ...)
    },
    binomial = function(ng, ...) {
      lcmm::lcmm(fixed = fixed, random = ~ -1, subject = ".gid",
                 ng = ng, data = long, link = "thresholds",
                 maxiter = as.integer(itermax), verbose = FALSE, ...)
    },
    stop(sprintf("engine 'lcmm' does not support family '%s'.", spec$family),
         call. = FALSE)
  )

  # Class-membership covariates map to lcmm's classmb model (ng > 1 only; the
  # 1-class init fit has no membership model).
  classmb <- .spec_X_formula(spec)

  if (!is.null(seed)) set.seed(seed)
  if (n_groups == 1L) {
    raw <- fitter(1L, ...)
  } else if (n_starts == 1L) {
    # lcmm requires explicit starting values for ng > 1; the canonical init is
    # the 1-class fit.
    init <- fitter(1L)
    raw  <- if (is.null(classmb)) {
      fitter(n_groups, mixture = mixture, B = init, ...)
    } else {
      fitter(n_groups, mixture = mixture, classmb = classmb, B = init, ...)
    }
  } else {
    # Multi-start via lcmm's own gridsearch(): `rep` runs from random
    # perturbations of the 1-class fit, then a full fit from the best one.
    # gridsearch() re-parses the `m` call and evaluates it in this frame, so
    # the fitting function must be bound here under a plain name. (`random` in
    # the B = random(minit) it constructs is a syntactic sentinel that lcmm
    # detects from the unevaluated call -- it must NOT resolve to a function.)
    init      <- fitter(1L)
    FITFUN    <- if (spec$family == "gaussian") lcmm::hlme else lcmm::lcmm
    itermax_i <- as.integer(itermax)
    mcall <- if (spec$family == "gaussian") {
      quote(FITFUN(fixed = fixed, mixture = mixture, random = ~ -1,
                   subject = ".gid", ng = n_groups, data = long,
                   maxiter = itermax_i, verbose = FALSE))
    } else {
      quote(FITFUN(fixed = fixed, mixture = mixture, random = ~ -1,
                   subject = ".gid", ng = n_groups, data = long,
                   link = "thresholds", maxiter = itermax_i, verbose = FALSE))
    }
    if (!is.null(classmb)) mcall$classmb <- quote(classmb)
    gcall <- as.call(list(quote(lcmm::gridsearch), m = mcall,
                          rep = n_starts, maxiter = itermax_i, minit = init))
    raw <- eval(gcall)
  }
  # lcmm post-processing functions (predictY, ...) re-parse the stored call, so
  # the formula symbols must be replaced by the actual formula objects.
  raw$call$fixed   <- fixed
  raw$call$mixture <- if (n_groups > 1L) mixture else NULL
  if (n_groups > 1L && !is.null(classmb)) raw$call$classmb <- classmb

  if (raw$conv != 1) {
    warning(sprintf(
      paste0("lcmm did not converge cleanly (conv = %d%s). Consider a larger ",
             "`itermax` or fewer groups."),
      raw$conv, if (raw$conv == 2) ": maximum iterations reached" else ""),
      call. = FALSE)
  }

  structure(
    list(
      engine     = "lcmm",
      family     = spec$family,
      model      = if (spec$family == "gaussian") "hlme" else "lcmm-thresholds",
      method     = NA_character_,
      n_groups   = n_groups,
      degrees    = rep(degree, n_groups),
      hessian    = hessian,
      itermax    = as.integer(itermax),
      n_starts   = n_starts,
      start_bics = as.numeric(raw$BIC),
      raw        = raw,
      spec       = spec
    ),
    class = c("gbtm_fit_lcmm", "gbtm_fit")
  )
}

# --- accessors ---------------------------------------------------------------

#' @export
gbtm_bic.gbtm_fit_lcmm <- function(fit, ...) {
  as.numeric(fit$raw$BIC)
}

#' @export
gbtm_aic.gbtm_fit_lcmm <- function(fit, ...) {
  as.numeric(fit$raw$AIC)
}

#' @export
gbtm_loglik.gbtm_fit_lcmm <- function(fit, ...) {
  as.numeric(fit$raw$loglik)
}

#' @export
gbtm_posterior.gbtm_fit_lcmm <- function(fit, ...) {
  K  <- fit$n_groups
  pp <- fit$raw$pprob
  post <- if (K == 1L) {
    matrix(1, nrow = nrow(pp), ncol = 1L)
  } else {
    as.matrix(pp[, paste0("prob", seq_len(K)), drop = FALSE])
  }
  # pprob rows follow lcmm's subject sort; put them back in spec row order.
  post <- post[match(seq_len(fit$spec$n_subjects), pp[[1L]]), , drop = FALSE]
  dimnames(post) <- list(NULL, paste0("group", seq_len(K)))
  post
}

#' @export
gbtm_group_sizes.gbtm_fit_lcmm <- function(fit, ...) {
  K <- fit$n_groups
  sizes <- if (K == 1L) {
    1
  } else if (!is.null(fit$spec$covariates)) {
    # With membership covariates the model-implied proportions are
    # subject-specific; report their average, which equals the mean posterior.
    colMeans(gbtm_posterior(fit))
  } else {
    # Model-implied proportions: softmax of the class-membership intercepts
    # (the first K - 1 parameters; the last class is the reference).
    .softmax(c(fit$raw$best[seq_len(K - 1L)], 0))
  }
  sizes <- as.numeric(sizes)
  names(sizes) <- paste0("group", seq_len(K))
  sizes
}

#' @export
gbtm_predict.gbtm_fit_lcmm <- function(fit, times = NULL, n = 100L, ...) {
  .warn_empty_groups(fit)
  A <- .spec_A(fit$spec)
  if (is.null(times)) times <- seq(min(A), max(A), length.out = n)

  # predictY returns the marginal predicted outcome per class on the outcome
  # scale (for the thresholds link that is P(y = 1)). It insists on every
  # model covariate being present in newdata, even though class-membership
  # covariates do not enter the trajectories -- supply representative values.
  nd <- data.frame(t = times)
  for (v in fit$spec$covariates) {
    col <- fit$spec$data[[v]]
    nd[[v]] <- if (is.numeric(col)) mean(col) else
      rep(col[1], length(times))
  }
  pred <- lcmm::predictY(fit$raw, newdata = nd, var.time = "t")$pred
  pred <- as.matrix(pred)

  out <- vector("list", fit$n_groups)
  for (k in seq_len(fit$n_groups)) {
    out[[k]] <- data.frame(group = k, time = times, fitted = pred[, k])
  }
  do.call(rbind, out)
}
