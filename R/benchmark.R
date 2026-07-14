# =============================================================================
# Engine benchmark harness (dev/DESIGN.md sec. 11: "engine as a performance
# lever"). Times the same model on each requested engine and reports runtime
# together with the engine-neutral classification diagnostics, so the fastest
# adequate backend can be picked per problem. Failures (missing package,
# unsupported family, non-uniform degrees on a uniform-degree engine, fit
# errors) are recorded as rows, never silently dropped.
# =============================================================================

#' Benchmark the estimation engines on a specification
#'
#' Fits the same model with each requested engine and reports wall-clock time
#' alongside the engine-neutral diagnostics (entropy, minimum APPA, effective
#' number of groups). Use it to pick a backend for a large problem: fit a
#' subsample first, then commit to the fastest engine whose classification
#' quality is adequate.
#'
#' BIC and log-likelihood are reported for completeness but are comparable
#' only *within* an engine -- each backend defines its likelihood differently.
#' Compare engines on time and on the classification diagnostics.
#'
#' @param spec A [gbtm_spec].
#' @param n_groups Number of latent groups.
#' @param degrees Integer vector of polynomial degrees, length `n_groups`.
#'   Engines without per-group degrees (see
#'   [gbtm_engine_per_group_degrees()]) are skipped -- with a note -- unless
#'   the degrees are uniform.
#' @param engines Engines to benchmark; defaults to all registered engines.
#'   Engines whose package is not installed or whose families do not include
#'   `spec$family` are recorded as skipped.
#' @param method Estimation method for engines that offer a choice (trajeR);
#'   ignored by single-optimiser engines.
#' @param hessian,itermax,seed,... Passed to [gbtm_fit()] (e.g. `n_starts`).
#' @return An object of class `gbtm_benchmark`: a data frame with one row per
#'   engine (`engine`, `ok`, `seconds`, `bic`, `loglik`, `entropy`,
#'   `min_appa`, `groups_effective`, `note`).
#' @examples
#' \donttest{
#' data("sim_binary", package = "gbtmkit")
#' spec <- gbtm_spec(sim_binary, paste0("y", 1:10),
#'                   paste0("t", 1:10), id = "id", family = "binomial")
#' benchmark_engines(spec, n_groups = 4, degrees = rep(2, 4), seed = 1)
#' }
#' @export
benchmark_engines <- function(spec,
                              n_groups,
                              degrees,
                              engines = gbtm_engines(),
                              method = NULL,
                              hessian = FALSE,
                              itermax = 100L,
                              seed = NULL,
                              ...) {
  if (!inherits(spec, "gbtm_spec")) {
    stop("`spec` must be a gbtm_spec.", call. = FALSE)
  }
  engines <- match.arg(engines, gbtm_engines(), several.ok = TRUE)

  skip_row <- function(engine, note) {
    data.frame(engine = engine, ok = FALSE, seconds = NA_real_,
               bic = NA_real_, loglik = NA_real_, entropy = NA_real_,
               min_appa = NA_real_, groups_effective = NA_integer_,
               note = note)
  }

  rows <- lapply(engines, function(eng) {
    if (!requireNamespace(eng, quietly = TRUE)) {
      return(skip_row(eng, "package not installed"))
    }
    if (!spec$family %in% gbtm_engine_families(eng)) {
      return(skip_row(eng, sprintf("family '%s' not supported", spec$family)))
    }
    if (!gbtm_engine_per_group_degrees(eng) &&
        length(unique(degrees)) != 1L) {
      return(skip_row(eng, "requires uniform degrees"))
    }
    eng_method <- if (all(is.na(gbtm_engine_methods(eng)))) NULL else method

    t0 <- Sys.time()
    fit <- tryCatch(
      gbtm_fit(spec, engine = eng, n_groups = n_groups, degrees = degrees,
               method = eng_method, hessian = hessian, itermax = itermax,
               seed = seed, ...),
      error = function(e) e
    )
    secs <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
    if (inherits(fit, "error")) {
      out <- skip_row(eng, conditionMessage(fit))
      out$seconds <- secs
      return(out)
    }

    d <- tryCatch(gbtm_diagnostics(fit), error = function(e) NULL)
    data.frame(
      engine  = eng,
      ok      = TRUE,
      seconds = secs,
      bic     = tryCatch(gbtm_bic(fit), error = function(e) NA_real_),
      loglik  = tryCatch(gbtm_loglik(fit), error = function(e) NA_real_),
      entropy = if (is.null(d)) NA_real_ else d$entropy,
      min_appa = if (is.null(d)) NA_real_ else
        min(ifelse(is.na(d$groups$appa), -Inf, d$groups$appa)),
      groups_effective = if (is.null(d)) NA_integer_ else
        sum(d$groups$n_assigned > 0),
      note    = ""
    )
  })

  structure(do.call(rbind, rows), class = c("gbtm_benchmark", "data.frame"))
}

#' @export
print.gbtm_benchmark <- function(x, digits = 2, ...) {
  cat("<gbtm_benchmark>  one model per engine, wall-clock seconds\n")
  df <- as.data.frame(x)
  num <- vapply(df, is.numeric, logical(1))
  df[num] <- lapply(df[num], round, digits = digits)
  print(df, row.names = FALSE)
  cat("Note: BIC/loglik are comparable only within an engine;\n")
  cat("compare engines on time and classification diagnostics.\n")
  invisible(x)
}
