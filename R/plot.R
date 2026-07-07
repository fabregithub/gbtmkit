# =============================================================================
# Stage 4 (part 2): plot fitted group trajectories.
#
# Uses the engine-neutral gbtm_predict() for the fitted lines and, optionally,
# overlays the observed mean outcome per assigned group at each occasion.
# ggplot2 is an optional dependency (Suggests).
# =============================================================================

.family_ylab <- function(family) {
  switch(family,
    binomial = "Probability",
    gaussian = "Mean outcome",
    poisson  = "Rate",
    beta     = "Proportion",
    "Outcome")
}

# Observed mean outcome per assigned group at each occasion.
.observed_means <- function(fit) {
  Y <- .spec_Y(fit$spec)
  A <- .spec_A(fit$spec)
  grp <- max.col(gbtm_posterior(fit), ties.method = "first")
  occ_time <- colMeans(A)
  rows <- list()
  for (k in sort(unique(grp))) {
    idx <- grp == k
    rows[[length(rows) + 1L]] <- data.frame(
      group = k,
      time  = occ_time,
      mean  = colMeans(Y[idx, , drop = FALSE])
    )
  }
  do.call(rbind, rows)
}

#' Plot fitted group trajectories
#'
#' Draws each group's fitted trajectory over time and, optionally, overlays the
#' observed mean outcome for the subjects assigned to that group at each
#' occasion. Requires the \pkg{ggplot2} package.
#'
#' @param fit A [gbtm_fit] object.
#' @param observed Logical; overlay observed per-group occasion means
#'   (default `TRUE`).
#' @param n Number of time grid points for the fitted lines.
#' @return A \pkg{ggplot2} object.
#' @examples
#' \donttest{
#' data("sim_binary", package = "gbtmkit")
#' spec <- gbtm_spec(sim_binary, c("y1","y2","y3","y4"),
#'                   c("t1","t2","t3","t4"), id = "id", family = "binomial")
#' if (requireNamespace("trajeR", quietly = TRUE) &&
#'     requireNamespace("ggplot2", quietly = TRUE)) {
#'   fit <- fit_gbtm(spec, n_groups = 4, degrees = c(1, 3, 3, 1), method = "L")
#'   plot_trajectories(fit)
#' }
#' }
#' @export
plot_trajectories <- function(fit, observed = TRUE, n = 100L) {
  if (!inherits(fit, "gbtm_fit")) {
    stop("`fit` must be a gbtm_fit.", call. = FALSE)
  }
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("plot_trajectories() requires the 'ggplot2' package.", call. = FALSE)
  }
  pred <- gbtm_predict(fit, n = n)
  pred$group <- factor(pred$group)

  p <- ggplot2::ggplot(
    pred, ggplot2::aes(x = time, y = fitted, colour = group)
  ) +
    ggplot2::geom_line(linewidth = 1) +
    ggplot2::labs(x = "Time", y = .family_ylab(fit$family), colour = "Group") +
    ggplot2::theme_minimal()

  if (observed) {
    obs <- .observed_means(fit)
    obs$group <- factor(obs$group)
    p <- p + ggplot2::geom_point(
      data = obs,
      ggplot2::aes(x = time, y = mean, colour = group),
      inherit.aes = FALSE, size = 2
    )
  }
  p
}

# Non-standard evaluation in ggplot2::aes() -- declare the column names.
utils::globalVariables(c("time", "fitted", "group", "mean"))
