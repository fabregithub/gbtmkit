# =============================================================================
# The orchestrator: run the whole GRoLTS pipeline with one call.
#
#   stage 1  select_algorithm()      (skipped if `method` is given or the engine
#                                      has a single optimizer)
#   stage 2  select_n_groups()       -> number of groups
#   stage 3  evaluate_shapes()       -> per-group polynomial degrees
#            apply_grolts_criteria()  -> shapes meeting GRoLTS thresholds
#   stage 4  fit_gbtm() (Hessian on) + gbtm_assign() + gbtm_diagnostics()
#
# Returns a single `gbtm_result` bundling every stage's output.
# =============================================================================

`%||%` <- function(a, b) if (is.null(a)) b else a

#' Run the full group-based trajectory pipeline
#'
#' Executes algorithm selection (optional), group-number selection, polynomial
#' shape search with GRoLTS acceptance criteria, and the final Hessian-on fit,
#' returning all intermediate results in one object.
#'
#' If no shape meets the GRoLTS criteria, the pipeline falls back to the
#' lowest-BIC shape and records `criteria_met = FALSE`.
#'
#' @param spec A [gbtm_spec].
#' @param engine Engine name; see [gbtm_engines()].
#' @param candidates Integer vector of group numbers to consider (stage 2).
#' @param degree Polynomial degree used during group-number selection.
#' @param method Estimation method. If `NULL` and the engine offers a choice,
#'   stage 1 selects it; otherwise this method is used throughout.
#' @param algo_n_groups,algo_degree Group count and degree used for stage-1
#'   algorithm selection (defaults: `max(candidates)`, `degree`).
#' @param strategy,min_degree,max_degree,max_passes Shape-search controls, passed
#'   to [evaluate_shapes()].
#' @param pms_min,appa_min,occ_min GRoLTS thresholds, passed to
#'   [apply_grolts_criteria()].
#' @param itermax,seed Passed to the fitting stages.
#' @param time_budget,max_fits,checkpoint Bounds for the shape search.
#' @param verbose Print progress messages.
#' @param ... Passed to the underlying fitting calls.
#' @return An object of class `gbtm_result` with elements `spec`, `engine`,
#'   `method`, `algorithm_selection`, `group_selection`, `n_groups`, `shapes`,
#'   `criteria`, `chosen_degrees`, `criteria_met`, `final_fit`, `assignment`,
#'   `diagnostics`, and `call`.
#' @seealso [select_algorithm()], [select_n_groups()], [evaluate_shapes()],
#'   [apply_grolts_criteria()], [fit_gbtm()]
#' @examples
#' \donttest{
#' data("sim_binary", package = "gbtmkit")
#' spec <- gbtm_spec(sim_binary, paste0("y", 1:10),
#'                   paste0("t", 1:10), id = "id", family = "binomial")
#' if (requireNamespace("trajeR", quietly = TRUE)) {
#'   res <- run_gbtm_pipeline(spec, candidates = 2:5, method = "L")
#'   res
#' }
#' }
#' @export
run_gbtm_pipeline <- function(spec,
                              engine = gbtm_engines(),
                              candidates = 2:6,
                              degree = 3L,
                              method = NULL,
                              algo_n_groups = NULL,
                              algo_degree = NULL,
                              strategy = c("stepwise", "grid"),
                              min_degree = 1L,
                              max_degree = 3L,
                              max_passes = 2L,
                              pms_min = 0.05,
                              appa_min = 0.70,
                              occ_min = 5,
                              itermax = 100L,
                              seed = NULL,
                              time_budget = Inf,
                              max_fits = Inf,
                              checkpoint = NULL,
                              verbose = TRUE,
                              ...) {
  if (!inherits(spec, "gbtm_spec")) {
    stop("`spec` must be a gbtm_spec.", call. = FALSE)
  }
  engine <- match.arg(engine, gbtm_engines())
  strategy <- match.arg(strategy)
  cl <- match.call()
  say <- function(...) if (verbose) message(...)

  # --- stage 1: algorithm ----------------------------------------------------
  algo_sel <- NULL
  engine_methods <- gbtm_engine_methods(engine)
  engine_methods <- engine_methods[!is.na(engine_methods)]
  if (is.null(method) && length(engine_methods) > 1L) {
    ng  <- algo_n_groups %||% max(candidates)
    deg <- rep(algo_degree %||% degree, ng)
    say("Stage 1: selecting algorithm at ng = ", ng, " ...")
    algo_sel <- select_algorithm(spec, engine = engine, n_groups = ng,
                                 degrees = deg, itermax = itermax,
                                 seed = seed, ...)
    method <- algo_sel$best
  }
  method <- method %||% (if (length(engine_methods)) engine_methods[1] else NULL)

  # --- stage 2: number of groups ---------------------------------------------
  say("Stage 2: selecting number of groups over {", paste(candidates,
      collapse = ", "), "} ...")
  grp_sel <- select_n_groups(spec, engine = engine, candidates = candidates,
                             degree = degree, method = method,
                             itermax = itermax, seed = seed, ...)
  n_groups <- grp_sel$best
  if (is.na(n_groups)) {
    stop("group-number selection failed: no candidate produced a finite BIC.",
         call. = FALSE)
  }

  # --- stage 3: shapes + criteria --------------------------------------------
  say("Stage 3: searching shapes for ng = ", n_groups, " ...")
  shapes <- evaluate_shapes(spec, n_groups = n_groups, engine = engine,
                            method = method, strategy = strategy,
                            min_degree = min_degree, max_degree = max_degree,
                            max_passes = max_passes, itermax = itermax,
                            seed = seed, time_budget = time_budget,
                            max_fits = max_fits, checkpoint = checkpoint,
                            verbose = verbose)
  criteria <- apply_grolts_criteria(shapes, pms_min = pms_min,
                                    appa_min = appa_min, occ_min = occ_min)
  rec <- grolts_recommended(criteria)
  criteria_met <- !is.null(rec)
  if (criteria_met) {
    chosen_degrees <- as.integer(rec[paste0("deg", seq_len(n_groups))])
  } else {
    chosen_degrees <- shapes$best
    warning("No shape met the GRoLTS criteria; using the lowest-BIC shape.",
            call. = FALSE)
  }
  if (is.null(chosen_degrees)) {
    stop("shape search produced no usable model.", call. = FALSE)
  }

  # --- stage 4: final fit + outputs ------------------------------------------
  say("Stage 4: fitting final model (degrees ", paste(chosen_degrees,
      collapse = ","), ", Hessian on) ...")
  final_fit <- fit_gbtm(spec, n_groups = n_groups, degrees = chosen_degrees,
                        method = method, engine = engine, hessian = TRUE,
                        itermax = itermax, seed = seed, ...)
  assignment  <- gbtm_assign(final_fit)
  diagnostics <- gbtm_diagnostics(final_fit)

  structure(
    list(spec = spec, engine = engine, method = method,
         algorithm_selection = algo_sel, group_selection = grp_sel,
         n_groups = n_groups, shapes = shapes, criteria = criteria,
         chosen_degrees = chosen_degrees, criteria_met = criteria_met,
         final_fit = final_fit, assignment = assignment,
         diagnostics = diagnostics, call = cl),
    class = "gbtm_result"
  )
}

#' @export
print.gbtm_result <- function(x, ...) {
  cat("<gbtm_result>\n")
  cat(sprintf("  engine/family : %s / %s\n", x$engine, x$spec$family))
  cat(sprintf("  method        : %s\n", x$method %||% "<default>"))
  cat(sprintf("  groups        : %d\n", x$n_groups))
  cat(sprintf("  degrees       : %s\n", paste(x$chosen_degrees, collapse = ", ")))
  cat(sprintf("  GRoLTS criteria met: %s\n", x$criteria_met))
  cat(sprintf("  entropy       : %.3f  BIC: %.1f\n",
              x$diagnostics$entropy, x$diagnostics$bic))
  invisible(x)
}

#' @export
summary.gbtm_result <- function(object, ...) {
  cat("=== gbtm pipeline result ===\n")
  print(object)
  cat("\nGroup diagnostics:\n")
  g <- object$diagnostics$groups
  g[] <- lapply(g, function(c) if (is.numeric(c)) round(c, 3) else c)
  print(g, row.names = FALSE)
  cat("\nAssigned group sizes:\n")
  print(table(object$assignment$group))
  invisible(object)
}
