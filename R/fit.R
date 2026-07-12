# =============================================================================
# Stage 4 (part 1): fit the final chosen model.
#
# fit_gbtm() is the convenience entry point for fitting the model you have
# settled on. Unlike gbtm_fit() (used throughout the search with the Hessian
# off), it computes the Hessian by default, so the fitted object carries the
# standard errors the GRoLTS / SAS-Traj report needs.
# =============================================================================

#' Fit the final chosen trajectory model
#'
#' A thin wrapper over [gbtm_fit()] intended for the final model, once the number
#' of groups and the polynomial shape have been chosen. It differs only in
#' defaulting `hessian = TRUE`, so the result includes standard errors.
#'
#' @inheritParams gbtm_fit
#' @param hessian Logical; compute the Hessian (standard errors). Default `TRUE`.
#' @return A [gbtm_fit] object.
#' @seealso [gbtm_fit()], [gbtm_diagnostics()], [gbtm_assign()],
#'   [plot_trajectories()]
#' @examples
#' \donttest{
#' data("sim_binary", package = "gbtmkit")
#' spec <- gbtm_spec(sim_binary, paste0("y", 1:10),
#'                   paste0("t", 1:10), id = "id", family = "binomial")
#' if (requireNamespace("trajeR", quietly = TRUE))
#'   fit_gbtm(spec, n_groups = 4, degrees = rep(3, 4), method = "L")
#' }
#' @export
fit_gbtm <- function(spec, n_groups, degrees, method = NULL,
                     engine = gbtm_engines(), hessian = TRUE,
                     itermax = 100L, seed = NULL, ...) {
  gbtm_fit(spec, engine = engine, n_groups = n_groups, degrees = degrees,
           method = method, hessian = hessian, itermax = itermax,
           seed = seed, ...)
}
