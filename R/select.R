# =============================================================================
# Stages 1-2 of the pipeline: model selection by information criterion.
#
#   select_algorithm() : given a fixed group number and shape, pick the
#                        estimation method (engines with a single optimiser are
#                        a no-op).
#   select_n_groups()  : sweep the number of groups, pick by BIC.
#
# Both return a `gbtm_selection` object: a tidy `$table` of candidates with
# their BIC/AIC and an `$best` choice. Fits that fail or fail to produce a
# finite criterion are recorded (with a warning), not silently dropped -- unlike
# the original script's `.errorhandling = "remove"`.
# =============================================================================

# Try a fit; return criteria and the fit, or NA on failure (never error out).
.try_fit <- function(spec, engine, n_groups, degrees, method,
                     hessian, itermax, seed, ...) {
  fit <- tryCatch(
    gbtm_fit(spec, engine = engine, n_groups = n_groups, degrees = degrees,
             method = method, hessian = hessian, itermax = itermax,
             seed = seed, ...),
    error = function(e) e
  )
  if (inherits(fit, "error")) {
    return(list(fit = NULL, bic = NA_real_, aic = NA_real_,
                ok = FALSE, message = conditionMessage(fit)))
  }
  bic <- tryCatch(gbtm_bic(fit), error = function(e) NA_real_)
  aic <- tryCatch(gbtm_aic(fit), error = function(e) NA_real_)
  list(fit = fit, bic = bic, aic = aic,
       ok = is.finite(bic), message = NA_character_)
}

.new_selection <- function(type, table, best, best_fit, fits, by) {
  structure(
    list(type = type, table = table, best = best,
         best_fit = best_fit, fits = fits, by = by),
    class = "gbtm_selection"
  )
}

# Pick the best candidate row by the chosen criterion (min), ignoring failures.
.pick_best <- function(table, by) {
  vals <- table[[by]]
  if (all(is.na(vals))) {
    warning("No candidate produced a finite ", by,
            "; selection is undefined.", call. = FALSE)
    return(NA_integer_)
  }
  which.min(vals)
}

#' Stage 1: select the estimation algorithm
#'
#' Fits a fixed group number and shape under each candidate estimation method
#' and picks the one with the lowest BIC. For engines with a single optimiser
#' (see [gbtm_engine_methods()]) this is a no-op that returns that method.
#' The candidate fits are independent and run in parallel under a
#' [future::plan()] when the future.apply package is installed.
#'
#' @param spec A [gbtm_spec].
#' @param engine Engine name; see [gbtm_engines()].
#' @param n_groups Number of groups to use for the comparison.
#' @param degrees Integer vector of polynomial degrees, length `n_groups`.
#' @param methods Character vector of methods to compare; defaults to all
#'   methods the engine offers.
#' @param by Criterion to minimise, `"bic"` (default) or `"aic"`.
#' @param hessian,itermax,seed,... Passed to [gbtm_fit()]. `hessian` defaults to
#'   `FALSE` (selection does not need standard errors).
#' @return A `gbtm_selection` object with `$table`, `$best` (the chosen method),
#'   and the fitted models.
#' @examples
#' \donttest{
#' data("sim_binary", package = "gbtmkit")
#' spec <- gbtm_spec(sim_binary, paste0("y", 1:10),
#'                   paste0("t", 1:10), id = "id", family = "binomial")
#' if (requireNamespace("trajeR", quietly = TRUE))
#'   select_algorithm(spec, engine = "trajeR", n_groups = 4,
#'                    degrees = rep(1, 4))
#' }
#' @export
select_algorithm <- function(spec,
                             engine = gbtm_engines(),
                             n_groups,
                             degrees,
                             methods = NULL,
                             by = c("bic", "aic"),
                             hessian = FALSE,
                             itermax = 100L,
                             seed = NULL,
                             ...) {
  engine <- match.arg(engine, gbtm_engines())
  by <- match.arg(by)
  if (is.null(methods)) methods <- gbtm_engine_methods(engine)
  methods <- methods[!is.na(methods)]
  if (length(methods) == 0L) {
    stop("engine '", engine, "' offers no selectable methods.", call. = FALSE)
  }

  # Method fits are independent: run through .fit_map (parallel under a
  # future::plan()); warnings for failures are emitted afterwards, in order.
  res <- .fit_map(seq_along(methods), function(i) {
    .try_fit(spec, engine, n_groups, degrees, methods[i],
             hessian, itermax, seed, ...)
  })
  fits <- lapply(res, `[[`, "fit")
  rows <- lapply(seq_along(methods), function(i) {
    data.frame(method = methods[i], bic = res[[i]]$bic, aic = res[[i]]$aic,
               ok = res[[i]]$ok)
  })
  for (i in seq_along(methods)) {
    if (!res[[i]]$ok) {
      warning(sprintf("method '%s' did not yield a finite criterion%s.",
                      methods[i],
                      if (!is.na(res[[i]]$message))
                        paste0(": ", res[[i]]$message) else ""),
              call. = FALSE)
    }
  }
  table <- do.call(rbind, rows)
  bi <- .pick_best(table, by)
  best <- if (is.na(bi)) NA_character_ else table$method[bi]
  .new_selection("algorithm", table, best,
                 if (is.na(bi)) NULL else fits[[bi]], fits, by)
}

#' Stage 2: select the number of groups
#'
#' Fits the model for each candidate number of groups and picks the one with the
#' lowest BIC. Each candidate uses a polynomial degree of `degree` for every
#' group unless a per-candidate `degrees` list is supplied. The candidate fits
#' are independent and run in parallel under a [future::plan()] when the
#' future.apply package is installed.
#'
#' @param spec A [gbtm_spec].
#' @param engine Engine name; see [gbtm_engines()].
#' @param candidates Integer vector of group numbers to try (default `2:6`).
#' @param degree Single polynomial degree applied to every group (default `3`,
#'   cubic). Ignored when `degrees` is supplied.
#' @param degrees Optional list, one integer vector per candidate, for full
#'   control of the shape at each group number.
#' @param method Estimation method to use (e.g. the winner of
#'   [select_algorithm()]).
#' @param by Criterion to minimise, `"bic"` (default) or `"aic"`.
#' @param hessian,itermax,seed,... Passed to [gbtm_fit()].
#' @return A `gbtm_selection` object with `$table`, `$best` (the chosen number
#'   of groups), and the fitted models.
#' @examples
#' \donttest{
#' data("sim_binary", package = "gbtmkit")
#' spec <- gbtm_spec(sim_binary, paste0("y", 1:10),
#'                   paste0("t", 1:10), id = "id", family = "binomial")
#' select_n_groups(spec, candidates = 2:5, degree = 2)
#' }
#' @export
select_n_groups <- function(spec,
                            engine = gbtm_engines(),
                            candidates = 2:6,
                            degree = 3L,
                            degrees = NULL,
                            method = NULL,
                            by = c("bic", "aic"),
                            hessian = FALSE,
                            itermax = 100L,
                            seed = NULL,
                            ...) {
  engine <- match.arg(engine, gbtm_engines())
  by <- match.arg(by)
  candidates <- as.integer(candidates)
  if (anyNA(candidates) || any(candidates < 1L)) {
    stop("`candidates` must be positive integers.", call. = FALSE)
  }
  if (!is.null(degrees)) {
    if (length(degrees) != length(candidates)) {
      stop("`degrees` must be a list with one entry per candidate.",
           call. = FALSE)
    }
  }

  # Candidate fits are independent: run through .fit_map (parallel under a
  # future::plan()); warnings for failures are emitted afterwards, in order.
  res <- .fit_map(seq_along(candidates), function(i) {
    ng  <- candidates[i]
    deg <- if (is.null(degrees)) rep(as.integer(degree), ng) else degrees[[i]]
    r <- .try_fit(spec, engine, ng, deg, method, hessian, itermax, seed, ...)
    r$row <- data.frame(n_groups = ng,
                        degrees = paste(deg, collapse = ","),
                        bic = r$bic, aic = r$aic, ok = r$ok)
    r
  })
  fits <- lapply(res, `[[`, "fit")
  rows <- lapply(res, `[[`, "row")
  for (i in seq_along(res)) {
    if (!res[[i]]$ok) {
      warning(sprintf("n_groups = %d did not yield a finite criterion%s.",
                      candidates[i],
                      if (!is.na(res[[i]]$message))
                        paste0(": ", res[[i]]$message) else ""),
              call. = FALSE)
    }
  }
  table <- do.call(rbind, rows)
  bi <- .pick_best(table, by)
  best <- if (is.na(bi)) NA_integer_ else table$n_groups[bi]
  .new_selection("n_groups", table, best,
                 if (is.na(bi)) NULL else fits[[bi]], fits, by)
}

#' @export
print.gbtm_selection <- function(x, ...) {
  cat(sprintf("<gbtm_selection> stage=%s  by=%s\n", x$type, toupper(x$by)))
  print(x$table, row.names = FALSE)
  cat(sprintf("  best: %s\n", as.character(x$best)))
  invisible(x)
}
