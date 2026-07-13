# =============================================================================
# grolts_report(): map a pipeline result onto the GRoLTS checklist.
#
# The GRoLTS checklist (van de Schoot et al. 2017, Structural Equation
# Modeling 24(3), doi:10.1080/10705511.2016.1247646) lists what a latent
# trajectory study must report. A `gbtm_result` already contains most of it;
# this file turns the result into a per-item report: items the pipeline can
# answer are auto-filled, items that need domain knowledge (missing-data
# mechanism, plots included in the manuscript, syntax availability) are
# flagged for the analyst, with whatever context the result can contribute.
# =============================================================================

# One report row. status: "auto" (fully answered from the result), "partial"
# (context supplied, analyst completes), "analyst" (only the analyst knows).
.grolts_item <- function(item, topic, status, detail) {
  data.frame(item = item, topic = topic, status = status, detail = detail)
}

# Compact per-wave summary of a numeric matrix column.
.wave_summary <- function(M, binary) {
  if (binary) {
    paste(sprintf("%.2f", colMeans(M, na.rm = TRUE)), collapse = ", ")
  } else {
    paste(sprintf("%.1f (%.1f)", colMeans(M, na.rm = TRUE),
                  apply(M, 2, stats::sd, na.rm = TRUE)), collapse = ", ")
  }
}

#' Map a pipeline result onto the GRoLTS checklist
#'
#' Produces a per-item reporting aid for the GRoLTS checklist (Guidelines for
#' Reporting on Latent Trajectory Studies; van de Schoot et al. 2017,
#' \doi{10.1080/10705511.2016.1247646}) from a [run_gbtm_pipeline()] result.
#' Items the pipeline can answer -- time metric, software, shape search,
#' starts and iterations, selection tools, class sizes, entropy -- are filled
#' in automatically; items that require knowledge the pipeline cannot have
#' (missing-data mechanism, what appears in the manuscript, syntax
#' availability) are flagged for the analyst, with whatever context the
#' result can contribute.
#'
#' Item wording is paraphrased; see the paper for the authoritative checklist.
#'
#' @param result A `gbtm_result` from [run_gbtm_pipeline()].
#' @param file Optional path; when supplied, the report is also written there
#'   as Markdown (for a supplementary-material appendix).
#' @return An object of class `gbtm_grolts_report`: a data frame with columns
#'   `item`, `topic`, `status` (`"auto"`, `"partial"`, `"analyst"`), and
#'   `detail`.
#' @seealso [apply_grolts_criteria()], [gbtm_diagnostics()]
#' @examples
#' \donttest{
#' data("sim_binary", package = "gbtmkit")
#' spec <- gbtm_spec(sim_binary, paste0("y", 1:10),
#'                   paste0("t", 1:10), id = "id", family = "binomial")
#' if (requireNamespace("trajeR", quietly = TRUE)) {
#'   res <- run_gbtm_pipeline(spec, candidates = 2:5, method = "L",
#'                            seed = 1, verbose = FALSE)
#'   grolts_report(res)
#' }
#' }
#' @export
grolts_report <- function(result, file = NULL) {
  if (!inherits(result, "gbtm_result")) {
    stop("`result` must be a gbtm_result from run_gbtm_pipeline().",
         call. = FALSE)
  }
  spec <- result$spec
  Y <- .spec_Y(spec)
  A <- .spec_A(spec)
  d <- result$diagnostics
  fit <- result$final_fit
  binary <- spec$family == "binomial"

  # -- time ---------------------------------------------------------------
  wave_var <- apply(A, 2, stats::var, na.rm = TRUE)
  time_detail <- sprintf(
    "%d occasions (columns %s .. %s); observed times span [%g, %g].",
    spec$n_occasions, spec$time[1], spec$time[spec$n_occasions],
    min(A, na.rm = TRUE), max(A, na.rm = TRUE))
  wave_detail <- if (all(wave_var == 0, na.rm = TRUE)) {
    sprintf("Fixed occasions: every subject shares the same times (%s); within-wave variance is 0.",
            paste(colMeans(A, na.rm = TRUE), collapse = ", "))
  } else {
    sprintf("Within-wave time means: %s; variances: %s.",
            paste(sprintf("%.2f", colMeans(A, na.rm = TRUE)), collapse = ", "),
            paste(sprintf("%.2f", wave_var), collapse = ", "))
  }

  # -- missingness ----------------------------------------------------------
  n_na <- sum(is.na(Y))
  miss_context <- if (n_na == 0L) {
    "No missing outcome values in the analysis data."
  } else {
    sprintf("%d of %d outcome cells missing (%.1f%%); per-wave counts: %s.",
            n_na, length(Y), 100 * n_na / length(Y),
            paste(colSums(is.na(Y)), collapse = ", "))
  }

  # -- software -------------------------------------------------------------
  sw_detail <- sprintf(
    "%s; gbtmkit %s; engine %s (%s %s)%s.",
    R.version.string,
    as.character(utils::packageVersion("gbtmkit")),
    result$engine, result$engine,
    tryCatch(as.character(utils::packageVersion(result$engine)),
             error = function(e) "version unknown"),
    if (!is.null(result$method) && !is.na(result$method))
      sprintf(", method '%s'", result$method) else "")

  # -- model structure --------------------------------------------------------
  het_detail <- paste(
    "Group-based trajectory model / latent class growth analysis:",
    "no within-class random effects. Alternatives with within-class",
    "heterogeneity (e.g. growth mixture models) were not fitted by this",
    "pipeline; state whether they were considered.")
  var_detail <- if (spec$family == "gaussian") {
    sprintf("Residual variance %s across groups (ssigma = %s).",
            if (isTRUE(spec$ssigma)) "shared" else "estimated per group",
            isTRUE(spec$ssigma))
  } else {
    sprintf("family = '%s': no free residual-variance structure to vary.",
            spec$family)
  }

  # -- shape search -----------------------------------------------------------
  sh <- result$shapes
  degcols <- grep("^deg", names(sh$table), value = TRUE)
  shape_detail <- sprintf(
    "%d polynomial shape%s fitted (%s search, degrees %d..%d per group); chosen degrees: %s.",
    sh$n_fits, if (sh$n_fits == 1L) "" else "s", sh$strategy,
    min(as.matrix(sh$table[degcols])), max(as.matrix(sh$table[degcols])),
    paste(result$chosen_degrees, collapse = ", "))

  # -- covariates ---------------------------------------------------------
  cov_parts <- c(
    if (!is.null(spec$covariates)) sprintf(
      "Class-membership covariates (multinomial model): %s.",
      paste(spec$covariates, collapse = ", ")),
    if (!is.null(spec$tcov)) sprintf(
      "Time-varying trajectory covariates (group-specific effects; trajectories reported at tcov = 0): %s.",
      paste(names(spec$tcov), collapse = ", "))
  )
  cov_detail <- if (length(cov_parts)) paste(cov_parts, collapse = " ") else
    "No covariates were used."

  # -- starts / iterations ------------------------------------------------
  starts_detail <- sprintf(
    "Final fit: %s initialization%s; iteration cap %s. (trajeR's default initialization is deterministic; additional starts are k-means-based.)",
    if (is.null(fit$n_starts) || fit$n_starts == 1L) "single (default)"
    else sprintf("best of %d", fit$n_starts),
    if (!is.null(fit$n_starts) && fit$n_starts > 1L)
      sprintf(" (per-start BICs recorded on the fit)") else "",
    if (is.null(fit$itermax)) "not recorded" else fit$itermax)

  # -- selection tools ------------------------------------------------------
  cand <- result$group_selection$table$n_groups
  th <- attr(result$criteria, "thresholds")
  sel_detail <- sprintf(
    "Group number selected by BIC over %s groups; shapes screened with GRoLTS acceptance criteria (min class share > %g, APPA > %g, OCC >= %g)%s.",
    paste(range(cand), collapse = ".."),
    th["pms_min"], th["appa_min"], th["occ_min"],
    if (isTRUE(result$criteria_met)) "" else
      " -- NO shape met the criteria; the lowest-BIC shape was used")

  # -- number of models -------------------------------------------------------
  n_algo <- if (is.null(result$algorithm_selection)) 0L else
    nrow(result$algorithm_selection$table)
  n_models <- n_algo + length(cand) + sh$n_fits + 1L
  one_class <- 1L %in% cand
  models_detail <- sprintf(
    "%d models fitted in total (%d algorithm comparison, %d group-number candidates, %d shape-search fits, 1 final fit). A one-class solution was %samong the candidates%s.",
    n_models, n_algo, length(cand), sh$n_fits,
    if (one_class) "" else "NOT ",
    if (one_class) "" else " -- consider adding candidates = 1:K")

  # -- classes / entropy ------------------------------------------------------
  size_detail <- sprintf(
    "Final %d-group model: n per class = %s (proportions %s). Per-candidate class sizes are not retained by the pipeline.",
    result$n_groups,
    paste(d$groups$n_assigned, collapse = ", "),
    paste(sprintf("%.2f", d$groups$prop_assigned), collapse = ", "))
  entropy_detail <- sprintf("Normalized classification entropy: %.3f (APPA per class: %s).",
                            d$entropy,
                            paste(sprintf("%.2f", d$groups$appa), collapse = ", "))

  items <- rbind(
    .grolts_item("1",  "Metric of time",              "auto",    time_detail),
    .grolts_item("2",  "Time within waves",           "auto",    wave_detail),
    .grolts_item("3a", "Missing-data mechanism",      "analyst", paste("Describe the assumed mechanism.", miss_context)),
    .grolts_item("3b", "Predictors of attrition",     "analyst", "Describe which variables relate to attrition/missingness."),
    .grolts_item("3c", "Handling of missing data",    "partial", paste(miss_context, "Long-format engines (flexmix, lcmm) drop missing occasions row-wise; trajeR receives the NA matrix.")),
    .grolts_item("4",  "Observed outcome distribution", "auto",
                 sprintf("Per-wave %s: %s.",
                         if (binary) "proportions" else "mean (sd)",
                         .wave_summary(Y, binary))),
    .grolts_item("5",  "Software",                    "auto",    sw_detail),
    .grolts_item("6a", "Within-class heterogeneity",  "partial", het_detail),
    .grolts_item("6b", "Variance structure across classes", "partial", var_detail),
    .grolts_item("7",  "Alternative trajectory shapes", "auto",  shape_detail),
    .grolts_item("8",  "Covariates",                  "auto",    cov_detail),
    .grolts_item("9",  "Starting values / iterations", "auto",   starts_detail),
    .grolts_item("10", "Model selection tools",       "auto",    sel_detail),
    .grolts_item("11", "Number of models fitted",     "auto",    models_detail),
    .grolts_item("12", "Cases per class",             "auto",    size_detail),
    .grolts_item("13", "Entropy",                     "auto",    entropy_detail),
    .grolts_item("14", "Plot of final trajectories",  "partial", "Available via plot_trajectories(result$final_fit) (fitted group trajectories with observed means); include it in the manuscript."),
    .grolts_item("15", "Plots for each model / individual trajectories", "analyst",
                 "The pipeline retains fits per candidate in result$group_selection$fits; plotting each model (or individual trajectories) is up to the analyst."),
    .grolts_item("16", "Syntax availability",         "analyst", "Share the analysis script (spec + run_gbtm_pipeline call) and sessionInfo() as supplementary material.")
  )

  out <- structure(items, class = c("gbtm_grolts_report", "data.frame"))
  if (!is.null(file)) {
    lines <- c(
      "# GRoLTS reporting aid",
      "",
      sprintf("Generated by gbtmkit %s on %s. Item wording paraphrased from van de Schoot et al. (2017), doi:10.1080/10705511.2016.1247646.",
              as.character(utils::packageVersion("gbtmkit")), Sys.Date()),
      "",
      unlist(lapply(seq_len(nrow(items)), function(i) {
        c(sprintf("## Item %s: %s [%s]", items$item[i], items$topic[i],
                  items$status[i]),
          "", items$detail[i], "")
      }))
    )
    writeLines(lines, file)
  }
  out
}

#' @export
print.gbtm_grolts_report <- function(x, ...) {
  cat("<gbtm_grolts_report> GRoLTS reporting aid (items paraphrased from")
  cat("\n  van de Schoot et al. 2017, doi:10.1080/10705511.2016.1247646)\n")
  lab <- c(auto = "auto-filled from the pipeline result",
           partial = "context supplied -- analyst completes",
           analyst = "analyst must supply")
  for (st in c("auto", "partial", "analyst")) {
    rows <- x[x$status == st, , drop = FALSE]
    if (!nrow(rows)) next
    cat(sprintf("\n-- %s --\n", lab[[st]]))
    for (i in seq_len(nrow(rows))) {
      cat(sprintf("  [%s] %s\n", rows$item[i], rows$topic[i]))
      cat(strwrap(rows$detail[i], width = 76, initial = "      ",
                  prefix = "      "), sep = "\n")
    }
  }
  invisible(x)
}
