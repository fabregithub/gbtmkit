# =============================================================================
# GRoLTS acceptance criteria.
#
# Filters a shape table (from evaluate_shapes()) to the candidates whose *worst*
# group meets the standard GRoLTS adequacy thresholds, then ranks the survivors.
# Filtering on the pre-computed min_pms / min_appa / min_occ summary columns is
# robust to the number of groups and fixes the original script's brittle,
# duplicated per-group filters (which were also mutually inconsistent).
#
# Standard thresholds (Nagin; GRoLTS):
#   * PMS  (smallest group's assigned share)          > 0.05
#   * APPA (average posterior prob. of assignment)     > 0.70
#   * OCC  (odds of correct classification)           >= 5
# =============================================================================

#' Apply GRoLTS acceptance criteria to a shape table
#'
#' Keeps the candidate shapes whose worst group satisfies all of the GRoLTS
#' adequacy thresholds and orders the survivors by the chosen criterion. The
#' recommended model is the top row.
#'
#' @param shapes A `gbtm_shapes` object or its `$table` data frame (from
#'   [evaluate_shapes()]).
#' @param pms_min Minimum smallest-group assigned proportion (default `0.05`).
#' @param appa_min Minimum average posterior probability of assignment
#'   (default `0.70`).
#' @param occ_min Minimum odds of correct classification (default `5`).
#' @param order_by Column to sort survivors by, ascending (default `"bic"`).
#' @return A data frame of surviving shapes ordered by `order_by`, carrying an
#'   attribute `"recommended"` (its first row, or `NULL` if none qualify) and
#'   `"thresholds"`. Class `gbtm_criteria`.
#' @examples
#' \donttest{
#' data("sim_binary", package = "gbtmkit")
#' spec <- gbtm_spec(sim_binary, paste0("y", 1:10),
#'                   paste0("t", 1:10), id = "id", family = "binomial")
#' if (requireNamespace("trajeR", quietly = TRUE)) {
#'   sh <- evaluate_shapes(spec, n_groups = 4, method = "L", verbose = FALSE)
#'   apply_grolts_criteria(sh)
#' }
#' }
#' @export
apply_grolts_criteria <- function(shapes,
                                  pms_min = 0.05,
                                  appa_min = 0.70,
                                  occ_min = 5,
                                  order_by = "bic") {
  tab <- if (inherits(shapes, "gbtm_shapes")) shapes$table else shapes
  if (is.null(tab) || nrow(tab) == 0L) {
    stop("no shapes to evaluate (empty table).", call. = FALSE)
  }
  needed <- c("min_pms", "min_appa", "min_occ", "ok", order_by)
  miss <- setdiff(needed, names(tab))
  if (length(miss)) {
    stop("shape table is missing column(s): ", paste(miss, collapse = ", "),
         call. = FALSE)
  }

  keep <- tab$ok %in% TRUE &
    tab$min_pms > pms_min &
    tab$min_appa > appa_min &
    tab$min_occ >= occ_min
  keep[is.na(keep)] <- FALSE

  out <- tab[keep, , drop = FALSE]
  if (nrow(out)) {
    out <- out[order(out[[order_by]]), , drop = FALSE]
    rownames(out) <- NULL
  }

  recommended <- if (nrow(out)) out[1, , drop = FALSE] else NULL
  structure(
    out,
    recommended = recommended,
    thresholds = c(pms_min = pms_min, appa_min = appa_min, occ_min = occ_min),
    order_by = order_by,
    class = c("gbtm_criteria", "data.frame")
  )
}

#' @export
print.gbtm_criteria <- function(x, ...) {
  th <- attr(x, "thresholds")
  cat(sprintf("<gbtm_criteria> PMS>%g, APPA>%.2f, OCC>=%g | %d shape(s) pass\n",
              th["pms_min"], th["appa_min"], th["occ_min"], nrow(x)))
  rec <- attr(x, "recommended")
  if (is.null(rec)) {
    cat("  no shape meets all criteria\n")
  } else {
    degs <- grep("^deg", names(rec), value = TRUE)
    cat(sprintf("  recommended: degrees %s  (BIC %.1f, entropy %.3f)\n",
                paste(unlist(rec[degs]), collapse = ","),
                rec$bic, rec$entropy))
  }
  invisible(x)
}

#' The recommended shape from GRoLTS criteria
#'
#' @param x A `gbtm_criteria` object from [apply_grolts_criteria()].
#' @return A one-row data frame (the top-ranked surviving shape), or `NULL` if
#'   none qualified.
#' @export
grolts_recommended <- function(x) {
  if (!inherits(x, "gbtm_criteria")) {
    stop("`x` must be a gbtm_criteria object.", call. = FALSE)
  }
  attr(x, "recommended")
}
