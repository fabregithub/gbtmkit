# =============================================================================
# flexmix adapter.
#
# Translates a `gbtm_spec` into a flexmix::flexmix() call and wraps the result
# in a `gbtm_fit_flexmix` object, then implements the engine-agnostic accessors
# for that class. flexmix is an optional dependency (Suggests): this file only
# runs when the user actually fits with engine = "flexmix".
#
# Mapping notes (see dev/DESIGN.md sec. 4.3):
#   * GBTM = mixture of GLMs on long-format data, grouped by subject: the
#     formula `y ~ poly(t, d, raw = TRUE) | subject` makes flexmix keep all of
#     a subject's rows in one component, so posteriors are per subject.
#   * flexmix fits ONE model formula shared by all components, so the polynomial
#     degree is uniform across groups (`gbtm_engine_per_group_degrees()` returns
#     FALSE and the shape search sweeps uniform shapes only). Component-specific
#     designs exist (FLXMRglmfix `nested`) but collapse in practice.
#   * Single optimizer (EM): `gbtm_engine_methods()` returns NA and the
#     algorithm-selection stage is a no-op.
#   * flexmix may drop components that empty out during EM; the wrapper warns
#     and reports the actual number of groups.
# =============================================================================

# Neutral family -> flexmix FLXMRglm family string.
.flexmix_family <- c(
  binomial = "binomial",
  gaussian = "gaussian",
  poisson  = "poisson"
)

# Fit and wrap. Called via gbtm_fit(spec, engine = "flexmix", ...).
.fit_flexmix <- function(spec, n_groups, degrees, method = NULL,
                         hessian = FALSE, itermax = 100L, seed = NULL,
                         n_starts = 1L, ...) {
  if (!requireNamespace("flexmix", quietly = TRUE)) {
    stop("engine 'flexmix' requires the 'flexmix' package to be installed.",
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
    stop("engine 'flexmix' fits one polynomial order shared by all groups; ",
         "`degrees` must be uniform (e.g. rep(2, n_groups)). Got: ",
         paste(degrees, collapse = ", "), ".", call. = FALSE)
  }
  if (!is.null(method) && !is.na(method)) {
    stop("engine 'flexmix' has a single optimizer (EM); leave `method` unset.",
         call. = FALSE)
  }
  degree <- degrees[1L]

  long <- .spec_long(spec)
  rhs <- if (degree == 0L) "1" else sprintf("poly(t, %d, raw = TRUE)", degree)
  lhs <- if (spec$family == "binomial") "cbind(y, 1 - y)" else "y"
  fml <- stats::as.formula(paste(lhs, "~", rhs, "| .gid"))

  # flexmix's EM initialization is random, so multi-start is simply a fresh
  # run per start; the best finite BIC wins. Start 1 uses `seed` itself, so
  # n_starts = 1 reproduces the single-start behavior exactly. Without a seed
  # the runs differ anyway (each consumes RNG state).
  # Class-membership covariates map to flexmix's concomitant-variable model.
  concomitant <- if (is.null(spec$covariates)) flexmix::FLXPconstant() else
    flexmix::FLXPmultinom(.spec_X_formula(spec))

  one_fit <- function(s) {
    if (!is.null(seed)) set.seed(seed + s - 1L)
    flexmix::flexmix(
      fml, data = long, k = n_groups,
      model       = flexmix::FLXMRglm(family = .flexmix_family[[spec$family]]),
      concomitant = concomitant,
      control     = utils::modifyList(list(iter.max = as.integer(itermax)),
                                      list(...))
    )
  }
  if (n_starts == 1L) {
    raw <- one_fit(1L)
    start_bics <- as.numeric(stats4::BIC(raw))
  } else {
    raw <- NULL
    best_bic <- Inf
    start_bics <- numeric(0)
    for (s in seq_len(n_starts)) {
      cand <- tryCatch(one_fit(s), error = function(e) NULL)
      bic <- if (is.null(cand)) NA_real_ else
        tryCatch(as.numeric(stats4::BIC(cand)), error = function(e) NA_real_)
      start_bics <- c(start_bics, bic)
      if (is.finite(bic) && bic < best_bic) {
        best_bic <- bic
        raw <- cand
      }
    }
    if (is.null(raw)) {
      stop("all flexmix starts failed to produce a finite BIC.", call. = FALSE)
    }
  }

  k_actual <- length(flexmix::prior(raw))
  if (k_actual < n_groups) {
    warning(sprintf(
      paste0("flexmix dropped %d component(s) that emptied out during EM; ",
             "the fit has %d groups (requested %d). This usually indicates ",
             "the data does not support that many groups at this shape."),
      n_groups - k_actual, k_actual, n_groups), call. = FALSE)
  }

  # Standard errors on request: flexmix computes them in a separate refit step.
  refit <- NULL
  if (hessian) {
    refit <- tryCatch(flexmix::refit(raw), error = function(e) {
      warning("flexmix::refit() failed; standard errors unavailable: ",
              conditionMessage(e), call. = FALSE)
      NULL
    })
  }

  structure(
    list(
      engine     = "flexmix",
      family     = spec$family,
      model      = unname(.flexmix_family[[spec$family]]),
      method     = NA_character_,
      n_groups   = k_actual,
      degrees    = rep(degree, k_actual),
      hessian    = hessian,
      itermax    = as.integer(itermax),
      n_starts   = n_starts,
      start_bics = start_bics,
      raw        = raw,
      refit      = refit,
      spec       = spec
    ),
    class = c("gbtm_fit_flexmix", "gbtm_fit")
  )
}

# --- accessors ---------------------------------------------------------------

# flexmix registers logLik/BIC/AIC as S4 methods on the stats4 generics, so
# they must be called through stats4:: (the stats:: S3 generics won't dispatch
# when the flexmix namespace is loaded but not attached).

#' @export
gbtm_bic.gbtm_fit_flexmix <- function(fit, ...) {
  as.numeric(stats4::BIC(fit$raw))
}

#' @export
gbtm_aic.gbtm_fit_flexmix <- function(fit, ...) {
  as.numeric(stats4::AIC(fit$raw))
}

#' @export
gbtm_loglik.gbtm_fit_flexmix <- function(fit, ...) {
  as.numeric(stats4::logLik(fit$raw))
}

#' @export
gbtm_posterior.gbtm_fit_flexmix <- function(fit, ...) {
  # flexmix posteriors are per data row; with the `| .gid` grouping they are
  # identical within a subject, so keep each subject's first row.
  long <- .spec_long(fit$spec)
  post <- flexmix::posterior(fit$raw)[!duplicated(long$.gid), , drop = FALSE]
  dimnames(post) <- list(NULL, paste0("group", seq_len(ncol(post))))
  post
}

#' @export
gbtm_group_sizes.gbtm_fit_flexmix <- function(fit, ...) {
  sizes <- as.numeric(flexmix::prior(fit$raw))
  names(sizes) <- paste0("group", seq_along(sizes))
  sizes
}

#' @export
gbtm_predict.gbtm_fit_flexmix <- function(fit, times = NULL, n = 100L, ...) {
  .warn_empty_groups(fit)
  A <- .spec_A(fit$spec)
  if (is.null(times)) times <- seq(min(A), max(A), length.out = n)

  # Coefficient rows (Intercept, t, t^2, ...) per component; gaussian fits also
  # carry a sigma row, which is not part of the trajectory.
  pars <- as.matrix(flexmix::parameters(fit$raw))
  B <- pars[grepl("^coef\\.", rownames(pars)), , drop = FALSE]

  inv_link <- switch(fit$family,
    binomial = stats::plogis,
    poisson  = exp,
    gaussian = function(x) x
  )

  out <- vector("list", fit$n_groups)
  for (k in seq_len(fit$n_groups)) {
    b   <- B[, k]
    eta <- vapply(times, function(t) sum(b * t^(seq_along(b) - 1L)), numeric(1))
    out[[k]] <- data.frame(group = k, time = times, fitted = inv_link(eta))
  }
  do.call(rbind, out)
}
