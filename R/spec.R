# =============================================================================
# gbtm_spec(): the model specification object.
#
# Captures *what* to model -- data, outcome/time columns (by name), id, outcome
# family and family-specific options -- independent of *which* engine fits it.
# Every downstream stage and every engine adapter consumes a validated
# `gbtm_spec`, so column indices, family strings, and shape assumptions are
# checked once, here, rather than scattered through the pipeline.
# =============================================================================

#' Supported outcome families
#'
#' The neutral family names understood by [gbtm_spec()]. Each engine adapter
#' maps these to its own idiom (e.g. trajeR maps `"binomial"` to `LOGIT`,
#' `"gaussian"` to `CNORM`).
#'
#' @return A character vector of supported family names.
#' @export
gbtm_families <- function() {
  c("binomial", "gaussian", "poisson", "beta")
}

#' Create a group-based trajectory model specification
#'
#' Builds a validated `gbtm_spec` object describing the data and the model to
#' fit, without committing to an estimation engine. Columns are selected *by
#' name*, and the outcome values are checked against the declared `family`.
#'
#' @param data A data frame (or matrix with column names) in wide format: one
#'   row per subject, one column per outcome occasion.
#' @param outcomes Character vector of outcome column names, in time order.
#' @param time Character vector of time/occasion column names, the same length
#'   as `outcomes`.
#' @param id Optional name of a subject-identifier column. If `NULL`, row
#'   numbers are used. When supplied it must contain no duplicates.
#' @param family Outcome family; one of [gbtm_families()]. `"binomial"` for
#'   binary outcomes (LOGIT), `"gaussian"` for continuous (CNORM), `"poisson"`
#'   for counts, `"beta"` for proportions.
#' @param covariates Optional character vector of covariate column names
#'   (reserved for group-membership models; not used by the basic pipeline).
#' @param ymin,ymax Optional censoring bounds for continuous (`"gaussian"`)
#'   outcomes; passed through to engines that support censored-normal models.
#' @param ssigma Logical; for continuous outcomes, whether the residual
#'   variance is shared across groups. Default `FALSE`.
#'
#' @return An object of class `gbtm_spec`: a list with the validated `data`,
#'   `outcomes`, `time`, `id`, `family`, `covariates`, and options.
#'
#' @examples
#' data("sim_binary", package = "gbtmkit")
#' spec <- gbtm_spec(
#'   sim_binary,
#'   outcomes = c("y1", "y2", "y3", "y4"),
#'   time     = c("t1", "t2", "t3", "t4"),
#'   id       = "id",
#'   family   = "binomial"
#' )
#' spec
#' @export
gbtm_spec <- function(data,
                      outcomes,
                      time,
                      id = NULL,
                      family = gbtm_families(),
                      covariates = NULL,
                      ymin = NULL,
                      ymax = NULL,
                      ssigma = FALSE) {
  family <- match.arg(family, gbtm_families())

  # --- data ------------------------------------------------------------------
  if (is.matrix(data)) {
    if (is.null(colnames(data))) {
      stop("`data` is a matrix without column names; supply named columns.",
           call. = FALSE)
    }
    data <- as.data.frame(data)
  }
  if (!is.data.frame(data)) {
    stop("`data` must be a data frame or a matrix with column names.",
         call. = FALSE)
  }
  if (nrow(data) == 0L) {
    stop("`data` has no rows.", call. = FALSE)
  }

  # --- column-name arguments -------------------------------------------------
  .check_chr(outcomes, "outcomes")
  .check_chr(time, "time")
  if (length(outcomes) != length(time)) {
    stop(sprintf(
      "`outcomes` and `time` must have the same length (%d vs %d).",
      length(outcomes), length(time)), call. = FALSE)
  }
  if (length(outcomes) < 2L) {
    stop("At least two occasions are required (length(outcomes) >= 2).",
         call. = FALSE)
  }
  .check_present(data, outcomes, "outcomes")
  .check_present(data, time, "time")
  if (!is.null(covariates)) {
    .check_chr(covariates, "covariates")
    .check_present(data, covariates, "covariates")
  }

  # --- id --------------------------------------------------------------------
  if (!is.null(id)) {
    if (!is.character(id) || length(id) != 1L) {
      stop("`id` must be a single column name or NULL.", call. = FALSE)
    }
    .check_present(data, id, "id")
    if (anyDuplicated(data[[id]])) {
      stop(sprintf("`id` column '%s' contains duplicate values.", id),
           call. = FALSE)
    }
  }

  # --- outcome values must be numeric and match the family -------------------
  ymat <- as.matrix(data[, outcomes, drop = FALSE])
  if (!is.numeric(ymat)) {
    stop("Outcome columns must be numeric.", call. = FALSE)
  }
  tmat <- as.matrix(data[, time, drop = FALSE])
  if (!is.numeric(tmat)) {
    stop("Time columns must be numeric.", call. = FALSE)
  }
  .check_family_values(ymat, family)

  # --- continuous options ----------------------------------------------------
  if (!is.null(ymin) && (!is.numeric(ymin) || length(ymin) != 1L)) {
    stop("`ymin` must be a single number or NULL.", call. = FALSE)
  }
  if (!is.null(ymax) && (!is.numeric(ymax) || length(ymax) != 1L)) {
    stop("`ymax` must be a single number or NULL.", call. = FALSE)
  }
  if (!is.null(ymin) && !is.null(ymax) && ymin >= ymax) {
    stop("`ymin` must be less than `ymax`.", call. = FALSE)
  }
  if (!is.logical(ssigma) || length(ssigma) != 1L) {
    stop("`ssigma` must be a single logical value.", call. = FALSE)
  }

  structure(
    list(
      data       = data,
      outcomes   = outcomes,
      time       = time,
      id         = id,
      family     = family,
      covariates = covariates,
      ymin       = ymin,
      ymax       = ymax,
      ssigma     = ssigma,
      n_subjects = nrow(data),
      n_occasions = length(outcomes)
    ),
    class = "gbtm_spec"
  )
}

# --- internal validation helpers ---------------------------------------------

.check_chr <- function(x, arg) {
  if (!is.character(x) || length(x) == 0L || anyNA(x)) {
    stop(sprintf("`%s` must be a non-empty character vector of column names.",
                 arg), call. = FALSE)
  }
}

.check_present <- function(data, cols, arg) {
  missing <- setdiff(cols, names(data))
  if (length(missing)) {
    stop(sprintf("`%s` column(s) not found in data: %s",
                 arg, paste(missing, collapse = ", ")), call. = FALSE)
  }
}

.check_family_values <- function(ymat, family) {
  vals <- ymat[!is.na(ymat)]
  if (length(vals) == 0L) {
    stop("All outcome values are missing.", call. = FALSE)
  }
  switch(family,
    binomial = if (!all(vals %in% c(0, 1))) {
      stop("family = 'binomial' requires outcomes coded 0/1.", call. = FALSE)
    },
    poisson = if (any(vals < 0) || any(vals != round(vals))) {
      stop("family = 'poisson' requires non-negative integer outcomes.",
           call. = FALSE)
    },
    beta = if (any(vals <= 0) || any(vals >= 1)) {
      stop("family = 'beta' requires outcomes strictly within (0, 1).",
           call. = FALSE)
    },
    gaussian = invisible(NULL)
  )
  invisible(NULL)
}

# --- accessors (internal; used by engine adapters and diagnostics) -----------

# Outcome matrix (subjects x occasions).
.spec_Y <- function(spec) {
  as.matrix(spec$data[, spec$outcomes, drop = FALSE])
}

# Time matrix (subjects x occasions).
.spec_A <- function(spec) {
  as.matrix(spec$data[, spec$time, drop = FALSE])
}

# Subject ids (or row numbers if none supplied).
.spec_ids <- function(spec) {
  if (is.null(spec$id)) seq_len(spec$n_subjects) else spec$data[[spec$id]]
}

#' @export
print.gbtm_spec <- function(x, ...) {
  cat("<gbtm_spec>\n")
  cat(sprintf("  family     : %s\n", x$family))
  cat(sprintf("  subjects   : %d\n", x$n_subjects))
  cat(sprintf("  occasions  : %d\n", x$n_occasions))
  cat(sprintf("  outcomes   : %s\n", paste(x$outcomes, collapse = ", ")))
  cat(sprintf("  time       : %s\n", paste(x$time, collapse = ", ")))
  cat(sprintf("  id         : %s\n", if (is.null(x$id)) "<row number>" else x$id))
  if (!is.null(x$covariates)) {
    cat(sprintf("  covariates : %s\n", paste(x$covariates, collapse = ", ")))
  }
  if (x$family == "gaussian" && (!is.null(x$ymin) || !is.null(x$ymax))) {
    cat(sprintf("  censoring  : [%s, %s]\n",
                if (is.null(x$ymin)) "-Inf" else x$ymin,
                if (is.null(x$ymax)) "Inf" else x$ymax))
  }
  invisible(x)
}
