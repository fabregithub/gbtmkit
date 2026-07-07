# =============================================================================
# Stage 3: polynomial-shape search (refactor of the original `trajectory()`).
#
# For a fixed number of groups, search over per-group polynomial degrees, fit
# each candidate (Hessian off -- selection needs only BIC and posteriors), and
# record the GRoLTS diagnostics. Returns one tidy row per evaluated shape.
#
# Designed to run unattended and bounded (see docs/DESIGN.md sec.11):
#   * strategy   : "stepwise" (greedy coordinate descent, ~linear in groups) by
#                  default, or "grid" (full Cartesian product) for small cases.
#   * max_degree : caps the per-group polynomial degree.
#   * time_budget/max_fits : hard stops; returns the best shape found so far.
#   * checkpoint : append each result to disk; resume skips done combinations.
#   * ETA        : after a short warm-up, prints an estimate of total run time.
# =============================================================================

# Parse a duration given as seconds (numeric) or a string like "2h"/"30m"/"90s".
.parse_duration <- function(x) {
  if (is.numeric(x)) return(x)
  if (is.character(x) && length(x) == 1L) {
    m <- regmatches(x, regexec("^\\s*([0-9.]+)\\s*([smhSMH]?)\\s*$", x))[[1]]
    if (length(m) == 3L) {
      val <- as.numeric(m[2])
      unit <- tolower(m[3])
      mult <- if (unit %in% c("", "s")) 1
              else if (unit == "m") 60
              else if (unit == "h") 3600
              else NA
      if (!is.na(mult)) return(val * mult)
    }
  }
  stop("`time_budget` must be a number of seconds or a string like '2h'.",
       call. = FALSE)
}

# Flatten one fit's degrees + diagnostics into a single wide row. Summary
# columns (min_pms/min_appa/min_occ) drive criteria filtering robustly, while
# the per-group PMS*/APPA*/OCC*/miss* columns are kept for reporting. An empty
# group (NA APPA/OCC) is treated as failing (-Inf), never silently ignored.
.diag_to_row <- function(degrees, d, ok) {
  g <- d$groups
  K <- d$n_groups
  appa_eff <- ifelse(is.na(g$appa), -Inf, g$appa)
  occ_eff  <- ifelse(is.na(g$occ),  -Inf, g$occ)

  row <- data.frame(
    matrix(degrees, nrow = 1,
           dimnames = list(NULL, paste0("deg", seq_len(K)))),
    n_groups = K,
    bic = d$bic, aic = d$aic, loglik = d$loglik, entropy = d$entropy,
    min_pms = min(g$prop_assigned),
    min_appa = min(appa_eff),
    min_occ = min(occ_eff),
    max_abs_mismatch = max(abs(g$mismatch)),
    ok = ok,
    check.names = FALSE
  )
  wide <- data.frame(
    matrix(c(g$prop_assigned, g$appa, g$occ, g$mismatch), nrow = 1,
           dimnames = list(NULL, c(paste0("PMS", seq_len(K)),
                                   paste0("APPA", seq_len(K)),
                                   paste0("OCC", seq_len(K)),
                                   paste0("miss", seq_len(K))))),
    check.names = FALSE
  )
  cbind(row, wide)
}

# Fit one shape and diagnose it. Internal seam: tests mock this to exercise the
# search logic without fitting real models.
.shape_fit_diag <- function(spec, engine, n_groups, degrees, method,
                            hessian, itermax, seed) {
  fit <- tryCatch(
    gbtm_fit(spec, engine = engine, n_groups = n_groups, degrees = degrees,
             method = method, hessian = hessian, itermax = itermax, seed = seed),
    error = function(e) e
  )
  if (inherits(fit, "error")) {
    return(list(bic = NA_real_, ok = FALSE, fit = NULL, row = NULL,
                degrees = degrees))
  }
  d <- gbtm_diagnostics(fit)
  ok <- is.finite(d$bic)
  list(bic = d$bic, ok = ok, fit = fit,
       row = .diag_to_row(degrees, d, ok), degrees = degrees)
}

# All degree vectors for the full grid.
.grid_degrees <- function(n_groups, min_degree, max_degree) {
  levs <- rep(list(min_degree:max_degree), n_groups)
  grid <- expand.grid(levs, KEEP.OUT.ATTRS = FALSE)
  lapply(seq_len(nrow(grid)), function(i) as.integer(grid[i, ]))
}

#' Stage 3: search polynomial shapes for a fixed number of groups
#'
#' Fits candidate per-group polynomial degrees and records the GRoLTS
#' diagnostics for each, returning one row per evaluated shape. The search runs
#' unattended and bounded: a greedy `"stepwise"` strategy by default, an
#' optional hard `time_budget`/`max_fits`, on-disk `checkpoint`ing with resume,
#' and an up-front run-time estimate.
#'
#' @param spec A [gbtm_spec].
#' @param n_groups Number of groups.
#' @param engine Engine name; see [gbtm_engines()].
#' @param method Estimation method (e.g. the winner of [select_algorithm()]).
#' @param strategy `"stepwise"` (default, greedy coordinate descent) or `"grid"`
#'   (full Cartesian product of degrees).
#' @param min_degree,max_degree Per-group polynomial degree bounds.
#' @param max_passes Maximum coordinate-descent passes for `"stepwise"`.
#' @param hessian Logical; keep `FALSE` during search (default).
#' @param itermax,seed Passed to [gbtm_fit()].
#' @param time_budget Wall-clock limit: seconds, or a string like `"2h"`.
#'   `Inf` for no limit.
#' @param max_fits Maximum number of model fits. `Inf` for no limit.
#' @param checkpoint Optional file path; results are appended here and a rerun
#'   resumes, skipping shapes already evaluated.
#' @param verbose Print the run-time estimate and progress messages.
#' @return An object of class `gbtm_shapes`: `$table` (one row per shape),
#'   `$best` (degrees with the lowest BIC), `$best_fit`, `$n_fits`,
#'   `$budget_hit`, and `$strategy`.
#' @seealso [apply_grolts_criteria()]
#' @export
evaluate_shapes <- function(spec,
                            n_groups,
                            engine = gbtm_engines(),
                            method = NULL,
                            strategy = c("stepwise", "grid"),
                            min_degree = 1L,
                            max_degree = 3L,
                            max_passes = 2L,
                            hessian = FALSE,
                            itermax = 100L,
                            seed = NULL,
                            time_budget = Inf,
                            max_fits = Inf,
                            checkpoint = NULL,
                            verbose = TRUE) {
  if (!inherits(spec, "gbtm_spec")) {
    stop("`spec` must be a gbtm_spec.", call. = FALSE)
  }
  engine <- match.arg(engine, gbtm_engines())
  strategy <- match.arg(strategy)
  n_groups <- as.integer(n_groups)
  min_degree <- as.integer(min_degree)
  max_degree <- as.integer(max_degree)
  if (min_degree < 0L || max_degree < min_degree) {
    stop("require 0 <= min_degree <= max_degree.", call. = FALSE)
  }
  budget_secs <- .parse_duration(time_budget)

  n_levels <- max_degree - min_degree + 1L
  grid_size <- n_levels^n_groups
  # Auto-downshift a huge grid to stepwise.
  if (strategy == "grid" && is.finite(max_fits) && grid_size > max_fits) {
    if (verbose) message(sprintf(
      "grid has %d shapes > max_fits (%g); switching to stepwise search.",
      grid_size, max_fits))
    strategy <- "stepwise"
  }

  st <- new.env(parent = emptyenv())
  st$n_fits <- 0L
  st$rows <- list()
  st$cache <- new.env(parent = emptyenv())   # key -> list(bic, ok)
  st$times <- numeric(0)
  st$budget_hit <- FALSE
  st$start <- Sys.time()
  st$eta_done <- FALSE
  st$best_bic <- Inf
  st$best_fit <- NULL
  st$best_degrees <- NULL

  # Resume from checkpoint.
  if (!is.null(checkpoint) && file.exists(checkpoint)) {
    prev <- readRDS(checkpoint)
    for (i in seq_len(nrow(prev))) {
      deg <- as.integer(prev[i, paste0("deg", seq_len(n_groups))])
      key <- paste(deg, collapse = ",")
      assign(key, list(bic = prev$bic[i], ok = prev$ok[i]), st$cache)
      st$rows[[length(st$rows) + 1L]] <- prev[i, , drop = FALSE]
    }
    if (verbose) message(sprintf("resumed %d evaluated shapes from checkpoint.",
                                 nrow(prev)))
  }

  elapsed <- function() as.numeric(Sys.time() - st$start, units = "secs")

  # Evaluate one degree vector (cached, budgeted, checkpointed). Returns
  # list(bic, ok) or NULL if the budget stopped us.
  evaluate <- function(deg) {
    key <- paste(deg, collapse = ",")
    if (exists(key, envir = st$cache, inherits = FALSE)) {
      return(get(key, envir = st$cache, inherits = FALSE))
    }
    if (st$n_fits >= max_fits || elapsed() >= budget_secs) {
      st$budget_hit <- TRUE
      return(NULL)
    }
    t0 <- Sys.time()
    res <- .shape_fit_diag(spec, engine, n_groups, deg, method,
                           hessian, itermax, seed)
    st$times <- c(st$times, as.numeric(Sys.time() - t0, units = "secs"))
    st$n_fits <- st$n_fits + 1L

    if (!is.null(res$row)) {
      st$rows[[length(st$rows) + 1L]] <- res$row
      if (!is.null(checkpoint)) {
        saveRDS(do.call(rbind, st$rows), checkpoint)
      }
      if (isTRUE(res$ok) && res$bic < st$best_bic) {
        st$best_bic <- res$bic
        st$best_fit <- res$fit
        st$best_degrees <- deg
      }
    }
    cached <- list(bic = res$bic, ok = res$ok)
    assign(key, cached, st$cache)

    # One-time ETA after a short warm-up.
    if (verbose && !st$eta_done && st$n_fits >= min(3L, max_fits)) {
      per <- mean(st$times)
      planned <- if (strategy == "grid") grid_size else
        min(max_passes * n_groups * n_levels, max_fits)
      remaining <- max(planned - st$n_fits, 0)
      message(sprintf(
        "~%d shapes planned, est. %.0f s remaining (%.2f s/fit).",
        planned, remaining * per, per))
      st$eta_done <- TRUE
    }
    cached
  }

  # --- run the chosen strategy ------------------------------------------------
  if (strategy == "grid") {
    for (deg in .grid_degrees(n_groups, min_degree, max_degree)) {
      if (is.null(evaluate(deg))) break            # budget hit
    }
  } else {
    current <- rep(min_degree, n_groups)
    r0 <- evaluate(current)
    cur_bic <- if (is.null(r0) || !isTRUE(r0$ok)) Inf else r0$bic
    for (pass in seq_len(max_passes)) {
      changed <- FALSE
      for (g in seq_len(n_groups)) {
        best_d <- current[g]; best_b <- cur_bic
        for (d in min_degree:max_degree) {
          if (d == current[g]) next
          cand <- current; cand[g] <- d
          r <- evaluate(cand)
          if (is.null(r)) break                    # budget hit
          if (isTRUE(r$ok) && is.finite(r$bic) && r$bic < best_b) {
            best_b <- r$bic; best_d <- d
          }
        }
        if (best_d != current[g]) {
          current[g] <- best_d; cur_bic <- best_b; changed <- TRUE
        }
        if (st$budget_hit) break
      }
      if (!changed || st$budget_hit) break
    }
  }

  table <- if (length(st$rows)) do.call(rbind, st$rows) else NULL
  # Recover best from the table (covers the resumed-checkpoint case).
  best_degrees <- st$best_degrees
  if (!is.null(table)) {
    ok_tab <- table[table$ok %in% TRUE & is.finite(table$bic), , drop = FALSE]
    if (nrow(ok_tab)) {
      bi <- which.min(ok_tab$bic)
      best_degrees <- as.integer(ok_tab[bi, paste0("deg", seq_len(n_groups))])
    }
  }
  if (verbose) {
    message(sprintf("evaluated %d shapes in %.0f s%s.",
                    st$n_fits, elapsed(),
                    if (st$budget_hit) " (budget reached)" else ""))
  }

  structure(
    list(table = table, best = best_degrees, best_fit = st$best_fit,
         n_groups = n_groups, n_fits = st$n_fits,
         budget_hit = st$budget_hit, strategy = strategy),
    class = "gbtm_shapes"
  )
}

#' @export
print.gbtm_shapes <- function(x, ...) {
  cat(sprintf("<gbtm_shapes> strategy=%s  groups=%d  fits=%d%s\n",
              x$strategy, x$n_groups, x$n_fits,
              if (x$budget_hit) "  [budget reached]" else ""))
  cat(sprintf("  best degrees: %s\n",
              if (is.null(x$best)) "<none>" else paste(x$best, collapse = ", ")))
  invisible(x)
}
