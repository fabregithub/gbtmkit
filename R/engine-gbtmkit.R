# =============================================================================
# Native estimation engine ("gbtmkit").
#
# A clean-room, fully vectorized implementation of Nagin-style GBTM: direct
# maximum likelihood via stats::optim (BFGS) with analytic gradients. Written
# from the model equations (no code shared with trajeR, which is GPL): the
# mixture log-likelihood of per-group polynomial trajectories, optional
# class-membership covariates (multinomial logit) and time-varying trajectory
# covariates (group-specific coefficients).
#
# Why it exists: profiling showed trajeR spends ~99.7% of a fit inside its own
# C++ likelihood at ~130 ms per evaluation, while this vectorized R version
# evaluates the same quantity in under 1 ms -- the same models fit ~50-100x
# faster, with per-group degrees, exposed convergence tolerance (`reltol`),
# NA-tolerant outcomes, and native multi-start. The likelihood convention was
# validated against trajeR: evaluated at trajeR's fitted parameters it
# reproduces trajeR's log-likelihood exactly, and the analytic gradients match
# numDeriv to ~1e-8 (see tests).
#
# Parameter vector layout (in `optim` order):
#   [theta]  (K-1) x (1 + px) class-membership coefficients, group-major
#            (intercept, covariate effects), group 1 is the reference;
#            px = 0 without membership covariates.
#   [beta]   per group: (degree_k + 1) polynomial coefficients, then one
#            coefficient per time-varying covariate.
#   [sigma]  gaussian only: log residual sd, one per group (or a single shared
#            value when ssigma = TRUE).
# =============================================================================

# Precompute everything the likelihood needs: outcome/mask matrices, cached
# time powers, per-group tcov matrices, membership design.
.ngb_ctx <- function(spec, degrees) {
  Y <- .spec_Y(spec)
  A <- .spec_A(spec)
  M <- !is.na(Y)
  if (!all(rowSums(M) > 0)) {
    stop("engine 'gbtmkit' requires at least one observed outcome per subject.",
         call. = FALSE)
  }
  Wl <- .spec_W(spec)                       # named list of n x T matrices
  if (!is.null(Wl) && any(vapply(Wl, anyNA, logical(1)))) {
    stop("tcov matrices must not contain missing values.", call. = FALSE)
  }
  list(
    Y0      = ifelse(M, Y, 0),
    M       = M,
    P       = lapply(0:max(degrees), function(j) A^j),
    W       = Wl,
    X       = .spec_X(spec),                # membership design or NULL
    degrees = as.integer(degrees),
    family  = spec$family,
    ssigma  = isTRUE(spec$ssigma),
    n       = nrow(Y),
    K       = length(degrees),
    nw      = length(Wl),
    px      = if (is.null(.spec_X(spec))) 0L else ncol(.spec_X(spec))
  )
}

# Split the flat optim vector into theta / beta / log_sigma.
.ngb_unpack <- function(par, ctx) {
  K <- ctx$K
  ntheta <- (K - 1L) * (1L + ctx$px)
  theta <- if (ntheta) matrix(par[seq_len(ntheta)], ncol = K - 1L) else NULL
  i <- ntheta
  beta <- vector("list", K)
  for (k in seq_len(K)) {
    nb <- ctx$degrees[k] + 1L + ctx$nw
    beta[[k]] <- par[i + seq_len(nb)]
    i <- i + nb
  }
  log_sigma <- NULL
  if (ctx$family == "gaussian") {
    log_sigma <- if (ctx$ssigma) rep(par[i + 1L], K) else par[i + seq_len(K)]
  }
  list(theta = theta, beta = beta, log_sigma = log_sigma)
}

# Group linear predictor (n x T): polynomial part + tcov part.
.ngb_eta <- function(beta_k, k, ctx) {
  e <- 0
  npoly <- ctx$degrees[k] + 1L
  for (j in seq_len(npoly)) e <- e + beta_k[j] * ctx$P[[j]]
  for (w in seq_len(ctx$nw)) e <- e + beta_k[npoly + w] * ctx$W[[w]]
  e
}

# Per-subject log membership probabilities (n x K), stable.
.ngb_lpi <- function(theta, ctx) {
  eta <- matrix(0, ctx$n, ctx$K)
  if (!is.null(theta)) {
    for (k in 2:ctx$K) {
      tk <- theta[, k - 1L]
      eta[, k] <- tk[1L] + if (ctx$px) drop(ctx$X %*% tk[-1L]) else 0
    }
  }
  m <- apply(eta, 1, max)
  eta - m - log(rowSums(exp(eta - m)))
}

# Per-subject per-group conditional log-likelihood (n x K) and the residual
# matrices that drive the beta gradients.
.ngb_llgroups <- function(p, ctx) {
  L <- matrix(0, ctx$n, ctx$K)
  R <- vector("list", ctx$K)
  E <- vector("list", ctx$K)
  for (k in seq_len(ctx$K)) {
    e <- .ngb_eta(p$beta[[k]], k, ctx)
    E[[k]] <- e
    if (ctx$family == "binomial") {
      cell   <- ctx$Y0 * stats::plogis(e, log.p = TRUE) +
        (1 - ctx$Y0) * stats::plogis(-e, log.p = TRUE)
      R[[k]] <- (ctx$Y0 - stats::plogis(e)) * ctx$M
    } else if (ctx$family == "poisson") {
      cell   <- ctx$Y0 * e - exp(e) - lgamma(ctx$Y0 + 1)
      R[[k]] <- (ctx$Y0 - exp(e)) * ctx$M
    } else {
      s      <- exp(p$log_sigma[k])
      cell   <- stats::dnorm(ctx$Y0, e, s, log = TRUE)
      R[[k]] <- ((ctx$Y0 - e) / s^2) * ctx$M
    }
    L[, k] <- rowSums(cell * ctx$M)
  }
  list(L = L, R = R, E = E)
}

.ngb_loglik <- function(par, ctx) {
  p  <- .ngb_unpack(par, ctx)
  Z  <- .ngb_llgroups(p, ctx)$L + .ngb_lpi(p$theta, ctx)
  m  <- apply(Z, 1, max)
  sum(m + log(rowSums(exp(Z - m))))
}

.ngb_grad <- function(par, ctx) {
  p   <- .ngb_unpack(par, ctx)
  lg  <- .ngb_llgroups(p, ctx)
  lpi <- .ngb_lpi(p$theta, ctx)
  Z   <- lg$L + lpi
  m   <- apply(Z, 1, max)
  W   <- exp(Z - m)
  W   <- W / rowSums(W)                     # posteriors, n x K
  D   <- W - exp(lpi)                       # membership score, n x K

  g_theta <- c()
  if (ctx$K > 1L) {
    for (k in 2:ctx$K) {
      g_theta <- c(g_theta, sum(D[, k]),
                   if (ctx$px) drop(crossprod(ctx$X, D[, k])))
    }
  }
  g_beta <- c()
  for (k in seq_len(ctx$K)) {
    npoly <- ctx$degrees[k] + 1L
    gk <- vapply(seq_len(npoly), function(j)
      sum(W[, k] * rowSums(lg$R[[k]] * ctx$P[[j]])), numeric(1))
    gw <- vapply(seq_len(ctx$nw), function(w)
      sum(W[, k] * rowSums(lg$R[[k]] * ctx$W[[w]])), numeric(1))
    g_beta <- c(g_beta, gk, gw)
  }
  g_sig <- c()
  if (ctx$family == "gaussian") {
    for (k in seq_len(ctx$K)) {
      s <- exp(p$log_sigma[k])
      dcell <- (((ctx$Y0 - lg$E[[k]])^2 / s^2) - 1) * ctx$M
      g_sig <- c(g_sig, sum(W[, k] * rowSums(dcell)))
    }
    if (ctx$ssigma) g_sig <- sum(g_sig)
  }
  c(g_theta, g_beta, g_sig)
}

# Deterministic default start (quantile-spread intercepts, like the classic
# GBTM initialization) and k-means partition starts for multi-start.
.ngb_init <- function(ctx, start = c("default", "kmeans")) {
  start <- match.arg(start)
  K <- ctx$K
  yv <- ctx$Y0[ctx$M]
  theta0 <- rep(0, (K - 1L) * (1L + ctx$px))
  sig0 <- if (ctx$family == "gaussian") {
    rep(log(stats::sd(yv)), if (ctx$ssigma) 1L else K)
  } else NULL

  beta0 <- c()
  if (start == "default") {
    qs <- (2 * seq_len(K) - 1) / (2 * K)
    for (k in seq_len(K)) {
      icpt <- switch(ctx$family,
        binomial = stats::qlogis(pmin(pmax(qs[k], 0.05), 0.95)),
        poisson  = log(max(stats::quantile(yv, qs[k]), 0.1)),
        gaussian = stats::quantile(yv, qs[k]))
      beta0 <- c(beta0, icpt, rep(0, ctx$degrees[k] + ctx$nw))
    }
  } else {
    Yk <- ctx$Y0
    Yk[!ctx$M] <- mean(yv)
    cl <- stats::kmeans(Yk, centers = K, nstart = 1)$cluster
    for (k in seq_len(K)) {
      rows <- cl == k
      mk <- mean(ctx$Y0[rows, ][ctx$M[rows, ]])
      icpt <- switch(ctx$family,
        binomial = stats::qlogis(pmin(pmax(mk, 0.05), 0.95)),
        poisson  = log(max(mk, 0.1)),
        gaussian = mk)
      beta0 <- c(beta0, icpt, rep(0, ctx$degrees[k] + ctx$nw))
    }
    pr <- tabulate(cl, K) / ctx$n
    if (K > 1L) {
      th <- matrix(0, 1L + ctx$px, K - 1L)
      th[1L, ] <- log(pr[-1L] / pr[1L])
      theta0 <- as.vector(th)
    }
  }
  c(theta0, beta0, sig0)
}

# Fit and wrap. Called via gbtm_fit(spec, engine = "gbtmkit", ...).
.fit_gbtmkit <- function(spec, n_groups, degrees, method = NULL,
                         hessian = FALSE, itermax = 100L, seed = NULL,
                         n_starts = 1L, reltol = 1e-8, ...) {
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
  if (!is.null(method) && !is.na(method)) {
    stop("engine 'gbtmkit' has a single optimizer (BFGS); leave `method` unset.",
         call. = FALSE)
  }
  if (spec$family == "gaussian" && (!is.null(spec$ymin) || !is.null(spec$ymax))) {
    stop("engine 'gbtmkit' does not support censoring bounds (ymin/ymax) yet; ",
         "use engine 'trajeR' for censored-normal outcomes.", call. = FALSE)
  }
  ctx <- .ngb_ctx(spec, degrees)

  one_start <- function(s) {
    if (s == 1L) {
      if (!is.null(seed)) set.seed(seed)
      init <- .ngb_init(ctx, "default")
    } else {
      set.seed((if (is.null(seed)) 0L else seed) + s - 1L)
      init <- .ngb_init(ctx, "kmeans")
    }
    tryCatch(
      stats::optim(init, .ngb_loglik, .ngb_grad, ctx = ctx, method = "BFGS",
                   control = list(fnscale = -1, maxit = as.integer(itermax),
                                  reltol = reltol)),
      error = function(e) e
    )
  }
  runs <- .fit_map(seq_len(n_starts), one_start)
  if (inherits(runs[[1L]], "error")) stop(runs[[1L]])
  vals <- vapply(runs, function(r) {
    if (inherits(r, "error") || !is.finite(r$value)) NA_real_ else r$value
  }, numeric(1))
  best <- which.max(vals)
  if (!length(best)) {
    stop("no start produced a finite log-likelihood.", call. = FALSE)
  }
  o <- runs[[best]]
  if (o$convergence != 0L) {
    warning(sprintf(
      "optim did not converge (code %d); consider a larger `itermax`.",
      o$convergence), call. = FALSE)
  }

  npar <- length(o$par)
  # Posteriors at the optimum (reused by the accessors).
  p   <- .ngb_unpack(o$par, ctx)
  Z   <- .ngb_llgroups(p, ctx)$L + .ngb_lpi(p$theta, ctx)
  m   <- apply(Z, 1, max)
  W   <- exp(Z - m)
  W   <- W / rowSums(W)

  vcov <- NULL
  if (hessian) {
    H <- stats::optimHess(o$par, .ngb_loglik, .ngb_grad, ctx = ctx)
    vcov <- tryCatch(solve(-H), error = function(e) NULL)
    if (is.null(vcov)) {
      warning("Hessian is singular; standard errors unavailable.",
              call. = FALSE)
    }
  }

  structure(
    list(
      engine     = "gbtmkit",
      family     = spec$family,
      model      = spec$family,
      method     = NA_character_,
      n_groups   = n_groups,
      degrees    = degrees,
      hessian    = hessian,
      itermax    = as.integer(itermax),
      n_starts   = as.integer(n_starts),
      start_bics = -2 * vals + npar * log(ctx$n),
      loglik     = o$value,
      npar       = npar,
      par        = o$par,
      params     = p,
      posterior  = W,
      vcov       = vcov,
      spec       = spec
    ),
    class = c("gbtm_fit_gbtmkit", "gbtm_fit")
  )
}

# --- accessors ---------------------------------------------------------------

#' @export
gbtm_loglik.gbtm_fit_gbtmkit <- function(fit, ...) fit$loglik

#' @export
gbtm_bic.gbtm_fit_gbtmkit <- function(fit, ...) {
  -2 * fit$loglik + fit$npar * log(fit$spec$n_subjects)
}

#' @export
gbtm_aic.gbtm_fit_gbtmkit <- function(fit, ...) {
  -2 * fit$loglik + 2 * fit$npar
}

#' @export
gbtm_posterior.gbtm_fit_gbtmkit <- function(fit, ...) {
  post <- fit$posterior
  dimnames(post) <- list(NULL, paste0("group", seq_len(ncol(post))))
  post
}

#' @export
gbtm_group_sizes.gbtm_fit_gbtmkit <- function(fit, ...) {
  sizes <- if (is.null(fit$spec$covariates)) {
    if (fit$n_groups == 1L) 1 else {
      icpt <- c(0, fit$params$theta[1L, ])
      .softmax(icpt)
    }
  } else {
    colMeans(fit$posterior)
  }
  sizes <- as.numeric(sizes)
  names(sizes) <- paste0("group", seq_len(fit$n_groups))
  sizes
}

#' @export
gbtm_predict.gbtm_fit_gbtmkit <- function(fit, times = NULL, n = 100L, ...) {
  .warn_empty_groups(fit)
  A <- .spec_A(fit$spec)
  if (is.null(times)) times <- seq(min(A, na.rm = TRUE), max(A, na.rm = TRUE),
                                   length.out = n)
  inv_link <- switch(fit$family,
    binomial = stats::plogis,
    poisson  = exp,
    gaussian = function(x) x
  )
  out <- vector("list", fit$n_groups)
  for (k in seq_len(fit$n_groups)) {
    b <- fit$params$beta[[k]][seq_len(fit$degrees[k] + 1L)]  # tcov = 0
    eta <- vapply(times, function(t) sum(b * t^(seq_along(b) - 1L)), numeric(1))
    out[[k]] <- data.frame(group = k, time = times, fitted = inv_link(eta))
  }
  do.call(rbind, out)
}
