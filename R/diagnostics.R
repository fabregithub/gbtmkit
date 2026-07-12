# =============================================================================
# GRoLTS classification diagnostics -- engine-neutral.
#
# Every diagnostic here is a function of the posterior-probability matrix and the
# model-implied group proportions, both obtained through the engine-agnostic
# accessors. Nothing is engine-specific, so these work identically for any
# backend. This replaces the trajeR-specific AvePP()/OCC()/GroupProb() plumbing
# in the original script.
#
# Quantities (per group k, with hard assignment g_i = argmax_k P(k | i)):
#   * prop_assigned (PMS) : share of subjects hard-assigned to group k.
#   * prop_model    (pi)  : model-implied group proportion.
#   * mismatch            : pi_k - PMS_k (near 0 is good).
#   * appa                : average posterior prob. of assignment, i.e. the mean
#                           of P(k | i) over subjects assigned to k (>= 0.70 is
#                           the usual GRoLTS threshold).
#   * occ                 : odds of correct classification,
#                           (appa/(1-appa)) / (pi/(1-pi))   (>= 5 is the usual
#                           threshold).
# Overall:
#   * entropy             : normalized classification entropy in [0, 1],
#                           1 - sum_i sum_k -P_ik log P_ik / (N log K).
#                           1 = perfectly separated, 0 = uninformative.
# =============================================================================

# Normalized classification entropy (relative entropy of the posterior).
.entropy <- function(posterior) {
  K <- ncol(posterior); N <- nrow(posterior)
  if (K < 2L) return(NA_real_)
  plogp <- ifelse(posterior > 0, posterior * log(posterior), 0)
  ent_i <- -rowSums(plogp)
  1 - sum(ent_i) / (N * log(K))
}

# Core computation from posterior + model group sizes. Kept independent of any
# fit object so it can be unit-tested against hand-built toy posteriors.
.diagnostics <- function(posterior, group_sizes) {
  posterior <- as.matrix(posterior)
  K <- ncol(posterior)
  N <- nrow(posterior)
  if (length(group_sizes) != K) {
    stop("`group_sizes` length must equal ncol(posterior).", call. = FALSE)
  }

  assigned      <- max.col(posterior, ties.method = "first")
  prop_assigned <- tabulate(assigned, nbins = K) / N
  pi            <- as.numeric(group_sizes)

  appa <- vapply(seq_len(K), function(k) {
    idx <- assigned == k
    if (!any(idx)) NA_real_ else mean(posterior[idx, k])
  }, numeric(1))

  occ      <- (appa / (1 - appa)) / (pi / (1 - pi))
  mismatch <- pi - prop_assigned

  groups <- data.frame(
    group         = seq_len(K),
    n_assigned    = tabulate(assigned, nbins = K),
    prop_assigned = prop_assigned,
    prop_model    = pi,
    mismatch      = mismatch,
    appa          = appa,
    occ           = occ
  )

  structure(
    list(
      groups   = groups,
      entropy  = .entropy(posterior),
      n        = N,
      n_groups = K
    ),
    class = "gbtm_diagnostics"
  )
}

#' GRoLTS classification diagnostics for a fitted model
#'
#' Computes the group-based trajectory fit diagnostics used by the GRoLTS
#' checklist -- assigned and model-implied group proportions and their mismatch,
#' average posterior probability of assignment (APPA), odds of correct
#' classification (OCC), and the normalized classification entropy -- entirely
#' from the posterior matrix and model group sizes, so the result is identical
#' regardless of estimation engine.
#'
#' @param fit A [gbtm_fit] object.
#' @param ... Unused.
#' @return An object of class `gbtm_diagnostics`: a list with `groups` (a
#'   per-group data frame), scalar `entropy`, `n`, and `n_groups`. When called
#'   on a fit it also carries `bic`, `aic`, `loglik`, and `degrees`.
#' @examples
#' \donttest{
#' data("sim_binary", package = "gbtmkit")
#' spec <- gbtm_spec(sim_binary, paste0("y", 1:10),
#'                   paste0("t", 1:10), id = "id", family = "binomial")
#' if (requireNamespace("trajeR", quietly = TRUE)) {
#'   fit <- gbtm_fit(spec, n_groups = 4, degrees = rep(3, 4), seed = 1)
#'   gbtm_diagnostics(fit)
#' }
#' }
#' @export
gbtm_diagnostics <- function(fit, ...) UseMethod("gbtm_diagnostics")

#' @export
gbtm_diagnostics.gbtm_fit <- function(fit, ...) {
  d <- .diagnostics(gbtm_posterior(fit), gbtm_group_sizes(fit))
  d$bic     <- tryCatch(gbtm_bic(fit),    error = function(e) NA_real_)
  d$aic     <- tryCatch(gbtm_aic(fit),    error = function(e) NA_real_)
  d$loglik  <- tryCatch(gbtm_loglik(fit), error = function(e) NA_real_)
  d$degrees <- gbtm_degrees(fit)
  d
}

#' Hard group assignment for a fitted model
#'
#' Assigns each subject to the group with the highest posterior probability.
#'
#' @param fit A [gbtm_fit] object.
#' @return A data frame with `id`, the assigned `group`, and one posterior
#'   probability column per group.
#' @examples
#' data("sim_binary", package = "gbtmkit")
#' # (fit a model first, then:)  gbtm_assign(fit)
#' @export
gbtm_assign <- function(fit) {
  if (!inherits(fit, "gbtm_fit")) {
    stop("`fit` must be a gbtm_fit.", call. = FALSE)
  }
  post  <- gbtm_posterior(fit)
  group <- max.col(post, ties.method = "first")
  out <- data.frame(id = .spec_ids(fit$spec), group = group)
  post_df <- as.data.frame(post)
  names(post_df) <- paste0("p", seq_len(ncol(post)))
  cbind(out, post_df)
}

#' @export
print.gbtm_diagnostics <- function(x, ...) {
  cat(sprintf("<gbtm_diagnostics> groups=%d  n=%d  entropy=%.3f\n",
              x$n_groups, x$n, x$entropy))
  if (!is.null(x$bic)) {
    cat(sprintf("  BIC=%.2f  AIC=%.2f  logLik=%.2f\n", x$bic, x$aic, x$loglik))
  }
  g <- x$groups
  g[] <- lapply(g, function(col) if (is.numeric(col)) round(col, 3) else col)
  print(g, row.names = FALSE)
  invisible(x)
}
